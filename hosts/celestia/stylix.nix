{ pkgs, ... }:
let
  locals = import ./locals.nix { inherit pkgs; };
in
{
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml";
  stylix.image = locals.wallpapers.main;
  stylix.cursor = {
    package = pkgs.everforest-cursors;
    name = "Everforest-cursors-dark";
    size = 16;
  };
  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.iosevka;
      name = "Iosevka Nerd Font";
    };
    sansSerif = {
      package = pkgs.inter;
      name = "Inter";
    };
    serif = {
      package = pkgs.corefonts;
      name = "Times New Roman";
    };
    sizes = {
      applications = 12;
      terminal = 12;
      desktop = 12;
      popups = 12;
    };
  };
  stylix.targets = {
    gtk.enable = true;
    qt.enable = true;
  };
}
