#!/usr/bin/env bash
wallpapers=("$HOME/Images/wallpapers/live/"*) # Create array of file paths
if [ ${#wallpapers[@]} -gt 0 ]; then          # Check if any wallpapers found
  random_index=$((RANDOM % ${#wallpapers[@]}))
  wallpaper="${wallpapers[$random_index]}"
  tempfile=".cache/currwallpaper.png"
  echo "$wallpaper"
  ffmpeg -y -i "$wallpaper" -vframes 1 "$tempfile"

else
  echo "Error: No wallpapers found in $HOME/wallpapers/" >&2
  exit 1 #Exit with error code
fi
transition_type="wave"
#transition_type="wipe"
#transition_type="random"

swww img $wallpaper \
  --transition-type=$transition_type \
  --transition-pos top-right \
  --transition-fps 60 --transition-step 2 --transition-angle 50
