{ pkgs, ... }:
{
  home.packages = with pkgs;[
    niri
    fuzzel
    waybar
    swww
    imagemagick
    hyprpicker
    hyprshot
    hyprcursor
    syncthing
    transmission_4
    keepassxc

    playerctl
    ripdrag
    wl-clipboard
    wf-recorder
    satty
    swaylock-effects
    swayidle
    gammastep
    wlsuset
    brightnessctl
    swaynotificationcenter
    libnotify
    dunst
    kdePackages.kdeconnect-kde
  ];
}
