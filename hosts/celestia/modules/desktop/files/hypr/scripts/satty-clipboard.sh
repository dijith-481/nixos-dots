#!/usr/bin/env bash
# Edit the image currently on the Wayland clipboard in Satty, then put the
# annotated result back on the clipboard.
#
# Bound to Ctrl+XF86Favorites in the niri config, next to the XF86Favorites
# screenshot binds.
set -euo pipefail

if ! command -v wl-paste >/dev/null 2>&1 || ! command -v satty >/dev/null 2>&1; then
  notify-send "Satty" "wl-clipboard and satty are required" 2>/dev/null || true
  exit 1
fi

tmp=$(mktemp --suffix=.png satty-clip-XXXXXX)
trap 'rm -f "$tmp"' EXIT

# Pick the best image type the clipboard offers. PNG first so we feed Satty a
# lossless source whenever one is available.
types=$(wl-paste --list-types 2>/dev/null || true)
mime=""
for candidate in image/png image/webp image/jpeg image/jpg image/bmp image/gif image/tiff; do
  if printf '%s\n' "$types" | grep -qxF "$candidate"; then
    mime=$candidate
    break
  fi
done

if [ -z "$mime" ]; then
  notify-send "Satty" "No image in the clipboard" 2>/dev/null || true
  exit 1
fi

wl-paste --type "$mime" >"$tmp"

# Satty streams the annotated PNG to --copy-command. Early-exit closes the
# window once the copy action fires (Enter or Ctrl+C), leaving the edited
# image on the clipboard.
satty \
  --filename "$tmp" \
  --copy-command "wl-copy --type image/png" \
  --actions-on-enter save-to-clipboard \
  --early-exit copy
