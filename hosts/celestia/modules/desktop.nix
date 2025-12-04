{ config, lib, pkgs, inputs, ... }:
{
  home.packages = with pkgs;[
    brave
    inputs.zen-browser.packages."${pkgs.system}".default
    zathura
    localsend
    seahorse
    libsecret


    qt6.qtbase
    qt6.qttools
    qt6.qtwayland
    qt5.qtbase
    qt5.qtwayland

    libsForQt5.qt5ct
    qt6Packages.qt6ct

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
    qview
    inkscape
    mpv
    ffmpeg
    v4l-utils
  ];
}
