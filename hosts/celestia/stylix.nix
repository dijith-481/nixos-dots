{ pkgs, ... }:
let
  locals = import ./locals.nix { inherit pkgs; };
in
{
  stylix.enable = true;
  # Keep the source palette available during evaluation on clean CI runners.
  stylix.base16Scheme = {
    system = "base16";
    name = "Nord";
    author = "arcticicestudio";
    variant = "dark";
    palette = {
      base00 = "2E3440";
      base01 = "3B4252";
      base02 = "434C5E";
      base03 = "4C566A";
      base04 = "D8DEE9";
      base05 = "E5E9F0";
      base06 = "ECEFF4";
      base07 = "8FBCBB";
      base08 = "BF616A";
      base09 = "D08770";
      base0A = "EBCB8B";
      base0B = "A3BE8C";
      base0C = "88C0D0";
      base0D = "81A1C1";
      base0E = "B48EAD";
      base0F = "5E81AC";
    };
  };
  stylix.image = locals.wallpapers.main;
  stylix.cursor = {
    name = "Nordzy-cursors";
    package = pkgs.nordzy-cursor-theme;
    size = 10;
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
  stylix.polarity = "dark";
  stylix.targets = {
    gtk.enable = true;
    qt.enable = true;


  };

  stylix.override = {
    # --- Deep Black Backgrounds ---
    base00 = "191D24"; # black0 (Main Background - True Black)

    base01 = "#1E222A"; # black2 (Lighter BG / Status Bars - Popups)
    base02 = "2E3440"; # gray1  (Selection / Highlight - Polar Night)
    base03 = "434C5E"; # gray3  (Comments / UI Elements)
    base04 = "60728A"; # gray5  (Dark FG / Line Numbers - from Nightfox)

    # --- Foregrounds ---
    base05 = "BBC3D4"; # white0_normal (Default Text)
    base06 = "D8DEE9"; # white1 (Light Text)
    base07 = "ECEFF4"; # white3 (Highlight Text)

    # --- Syntax Colors (Unchanged) ---
    base08 = "BF616A"; # red.base
    base09 = "D08770"; # orange.base
    base0A = "EBCB8B"; # yellow.base
    base0B = "A3BE8C"; # green.base
    base0C = "8FBCBB"; # cyan.base
    base0D = "81A1C1"; # blue1
    base0E = "B48EAD"; # magenta.base
    base0F = "5E81AC"; # blue0
  };
}
