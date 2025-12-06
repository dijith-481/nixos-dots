{ config, lib, pkgs, inputs, ... }:
{

  home.packages = with pkgs;[
    brave
    inputs.zen-browser.packages."${pkgs.system}".default
    zathura
    localsend
    seahorse
    libsecret
    nautilus




    gtk3
    gtk4
    glib

    vulkan-tools

    xwayland-satellite

    zip
    xz
    unzip
    p7zip

    jq

    bluez
    bluetui
    powertop
    yazi
    xdg-desktop-portal-termfilechooser
    qview
    inkscape
    mpv
    ffmpeg
    v4l-utils
  ];
}
