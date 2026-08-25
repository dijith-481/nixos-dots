#!/usr/bin/env bash
wallpapers=("$HOME/Images/wallpapers/static/"*) # Create array of file paths
if [ ${#wallpapers[@]} -gt 0 ]; then            # Check if any wallpapers found
  random_index=$((RANDOM % ${#wallpapers[@]}))
  wallpaper="${wallpapers[$random_index]}"
  tempfile="$HOME/.cache/currwallpaper.png"
  cp "$wallpaper" "$tempfile"

else
  echo "Error: No wallpapers found in $HOME/wallpapers/" >&2
  exit 1 #Exit with error code
fi
# transition_type="wave"
#transition_type="wipe"
transition_type="outer"
#transition_type="random"

swww img $wallpaper \
  --transition-type=$transition_type \
  --transition-pos 0.74,0.34 \
  --transition-duration 0.8 \
  --transition-fps 60 --transition-step 8
