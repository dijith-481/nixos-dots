{ pkgs, ... }:

{
  home.packages = with pkgs; [
    foot
    nushell
    kitty
    ghostty
    dysk
    dua

    dust
    procs
    hyperfine

    pulseaudio
    pavucontrol
    lm_sensors
    powertop
    acpi
    tlp

    usbutils # Provides lsusb command
    pciutils # Provides lspci command
    lshw # Hardware lister
    ethtool # Ethernet tool


    wlr-randr
    drm_info
    wayland-utils
    wdisplays
    pkg-config


  ];
  programs.nh.enable = true;
}
