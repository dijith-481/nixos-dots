#!/usr/bin/env bash
header=$(clipse -p | head -c 8 | xxd -p)
if [[ "$header" == "89504e470d0a1a0a" ]]; then
  tempfile=$(mktemp --suffix .png)
  clipse -p >"$tempfile"
  kdeconnect-cli -n "Galaxy A52s 5G" --share "$tempfile"
else
  selected=$(clipse -p)
  if [[ ! -f "$selected" && ! "$selected" =~ ^(http|https|ftp):// ]]; then
    tempfile=$(mktemp)
    kitty -T="fzf-picker" sh -c "fzf > '$tempfile'" || exit 1
    selected=$(cat "$tempfile")
    rm -f "$tempfile"
  fi
  if [[ -n "$selected" ]]; then
    kdeconnect-cli -n "Galaxy A52s 5G" --share "$selected"
  fi
fi
