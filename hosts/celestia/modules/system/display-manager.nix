{ config, lib, pkgs, ... }:
let
  locals = import ../../locals.nix { inherit pkgs; };
in
{
  #TODO switch to tuigreet
  services.displayManager.ly = {
    settings = {
      battery_id = "BAT0";

    };
  };
}
