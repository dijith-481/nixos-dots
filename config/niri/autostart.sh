#!/bin/sh
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP NIRI_SOCKET

sleep 1

swww restore

zen &
brave --app=https://music.youtube.com &
