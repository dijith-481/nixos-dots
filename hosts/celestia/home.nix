{ config, pkgs, ... }:
let
  versions = import ../../versions.nix;
  dotfiles = "${config.home.homeDirectory}/nixos-dots/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  # niri & fish are now fully declarative (modules/desktop/niri-config.nix,
  # modules/development/shell.nix) — no out-of-store symlinks needed.
  configs = {
    helix = "helix";
    zellij = "zellij";
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
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;

    })
    configs;


}
