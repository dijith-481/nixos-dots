#!/usr/bin/env bash
c=$(brightnessctl g)
step=0
if [[ c -lt 4 ]]; then
  step=1
else
  if [[ c -lt 40 ]]; then
    step=8
  else
    if [[ c -lt 100 ]]; then
      step=20
    else
      if [[ c -lt 300 ]]; then
        step=40
      else
        step=50
      fi
    fi
  fi
fi
if [[ $1 == "up" ]]; then
  brightnessctl s +$step
else
  brightnessctl s $step-
fi
