#!/usr/bin/env bash
if hyprctl activeworkspace | grep -q "workspace ID 2"; then
  foot -T nvim nvim
else
  if hyprctl clients | pcregrep -M "workspace: 2(.|\n){10,50}class: nvim"; then
    hyprctl dispatch workspace 2
  else
    foot -T nvim nvim
  fi
fi
