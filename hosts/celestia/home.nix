{ config, ... }:
let
  versions = import ../../versions.nix;
  dotfiles = "${config.home.homeDirectory}/nixos-dots/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    niri = "niri";
  };

in

{
  imports = [
    ../../globals.nix
    ./session-variables.nix
    ./modules/development
    ./modules/desktop.nix
    ./modules/wayland.nix
    ./modules/system
  ];
  home.username = "dijith";
  home.homeDirectory = "/home/dijith";
  home.stateVersion = versions.homeManager;
  stylix.targets.zen-browser =
    {
      enableCss = true;
      profileNames = [
        "zen"
      ];

    };



  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;

    })
    configs;


}
