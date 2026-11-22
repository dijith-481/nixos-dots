#!/usr/bin/env bash

if [[ ${1:-} == --paste-file ]]; then
  target=$(niri msg -j focused-window | jq -er '.id') || exit 1
fi

selection=$(mktemp) || exit 1
trap 'rm -f -- "$selection"' EXIT

# Expand the home directory and selection file inside the terminal's shell.
# shellcheck disable=SC2016
foot --app-id=paste-file-picker --title="Paste file" bash -c '
  cd -- "$HOME" || exit 1
  fd --hidden --no-ignore --type f --type d --type l --print0 --strip-cwd-prefix |
    FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf --read0 --print0 --prompt="Home > " > "$1"
' bash "$selection" || exit $?

IFS= read -r -d '' selected < "$selection" || exit 0
rm -f -- "$selection"
trap - EXIT

selected=$HOME/${selected%/}
[[ -f "$selected" || -d "$selected" ]] || exit 0

if [[ ${1:-} == --paste-file ]]; then
  niri msg action focus-window --id "$target" || exit 1
  [[ $(niri msg -j focused-window | jq -er '.id') == "$target" ]] || exit 1

  # Offer the path as a file on the clipboard so the app can read its contents.
  uri=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())' "$selected") || exit 1
  printf '%s\r\n' "$uri" | wl-copy --type text/uri-list || exit 1
  [[ $(niri msg -j focused-window | jq -er '.id') == "$target" ]] || exit 1
  exec wtype -M ctrl -s 60 -k v -s 60 -m ctrl
fi

if [[ -f "$selected" ]]; then
  mime=$(file --brief --dereference --mime-type -- "$selected") || exit 1
  if [[ $mime == image/* ]]; then
    exec wl-copy --type "$mime" < "$selected"
  fi
fi

# Avoid the Vulkan drag icon buffer rejected by Smithay on Intel Meteor Lake.
GSK_RENDERER=cairo exec ripdrag --and-exit --no-click --basename --content-width 300 --content-height 100 -- "$selected"
