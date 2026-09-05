#!/usr/bin/env bash
if hyprctl activeworkspace | grep -q "workspace ID 3"; then
  hyprctl dispatch exec zen-browser
else
  if hyprctl clients | pcregrep -M "workspace: 3(.|\n){10,50}class: zen"; then
    hyprctl dispatch workspace 3
  else
    hyprctl dispatch exec zen-browser
  fi
fi
