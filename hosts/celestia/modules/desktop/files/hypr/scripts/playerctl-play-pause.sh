#!/usr/bin/env bash
players=($(playerctl -l))
current_player="${players[0]}"
is_other_player_playing=false
for player in "${players[@]:1}"; do
  if [[ $(playerctl -p "$player" status) == Playing ]]; then
    is_other_player_playing=true
    playerctl -p "$player" pause
  fi
done
if [[ $is_other_player_playing == "false" ]]; then
  playerctl -p "$current_player" play-pause
else
  playerctl -p "$current_player" pause
  playerctl -p "$current_player" play
fi
