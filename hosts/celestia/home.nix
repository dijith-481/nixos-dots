{ config, pkgs, lib, ... }:
let
  versions = import ../../versions.nix;
  # Reproducible store path — no mkOutOfStoreSymlink
  configDir = ../../config;
  # niri & fish are now fully declarative (modules/desktop/niri-config.nix,
  # modules/development/shell.nix) — no out-of-store symlinks needed.
  # Other dotfiles kept as direct store copies — will be migrated to Nix options later.
  configs = {
    helix = "helix";
    zellij = "zellij";
    # --- direct store copy --- waybar + remaining dotfiles from .Data/dotfiles ---
    waybar = "waybar";
    fastfetch = "fastfetch";
    foot = "foot";
    fuzzel = "fuzzel";
    cava = "cava";
    clipse = "clipse";
    fum = "fum";
    htop = "htop";
    hypr = "hypr";
    kitty = "kitty";
    yazi = "yazi";
    zathura = "zathura";
    wofi = "wofi";
    tmux = "tmux";
    niri_taskbar_module = "niri_taskbar_module";
    paru = "paru";
    zed = "zed";
    colors = "colors";
  };

in

{
  imports = [
    ./session-variables.nix
    ./modules/development
    ./modules/desktop.nix
    ./modules/wayland.nix
    ./modules/system
  ];
  home.username = "dijith";
  home.homeDirectory = "/home/dijith";
  home.stateVersion = versions.homeManager;

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
  };


  stylix.targets = {
    waybar.enable = false;
    dunst.enable = false;
    hyprlock.enable = false;
    zen-browser = {
      enable = true;
      enableCss = true;
      profileNames = [
        "dijith"
      ];

    };
  };



  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = configDir + "/${subpath}";
      recursive = true;
    })
    configs;

  # Reproducible: no out-of-store ~/nixos-dots symlink — repo is at ~/nixos-dots (store-copied via home.file is not needed)
  # home.file."nixos-dots" removed for pure declarative reproducibility

}
