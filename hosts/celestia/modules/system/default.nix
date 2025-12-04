{ pkgs, ... }:

{
  home.packages = with pkgs; [
    foot
    nushell
    kitty
    ghostty
    clipse
    dysk
    dua

    dust
    procs
    hyperfine

    pwvucontrol
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


  ];
  programs.nh.enable = true;
}
