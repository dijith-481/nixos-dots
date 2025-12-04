{ config, lib, pkgs, ... }:
let
  locals = import ../../locals.nix { inherit pkgs; };
in
{
  #TODO switch to tuigreet
  services.displayManger.ly = {
    animation = "gameoflife";
    battery_id = "BAT0";

  };
}
