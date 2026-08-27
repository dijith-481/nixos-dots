{ config, lib, pkgs, inputs, ... }:
{

  home.packages = with pkgs;[
    # Native Wayland is selected by NIXOS_OZONE_WL. Keep Chromium's tested GPU
    # defaults instead of forcing Vulkan, syncobj, multiplane and blocklist bypasses.
    brave
    google-chrome

    # zen twilight only — stable removed (twilight supersedes it)
    inputs.zen-browser.packages."${pkgs.system}".twilight
    zathura
    localsend
    seahorse
    libsecret
    nautilus
    helvum




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
    # inkscape
    mpv
    ffmpeg
    v4l-utils
  ];
}
