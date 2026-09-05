{ config, pkgs, lib, ... }:
let
  versions = import ../../versions.nix;
in
{
  imports = [
    ./session-variables.nix
    ./modules/development
    ./modules/desktop.nix
    ./modules/desktop/waybar.nix
    ./modules/desktop/clipse.nix
    ./modules/desktop/declarative-app-config.nix
    ./modules/desktop/foot.nix
    ./modules/desktop/yazi.nix
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
    # keep ghostty/helix manual nord themes — don't let stylix overwrite our configs
    ghostty.enable = false;
    helix.enable = false;
    # kitty is fully declared in modules/development/terminal-configs.nix
    # (Nordfox palette + opacity) — stylix must not merge its own values in.
    kitty.enable = false;
    # foot + fuzzel are fully declared in our HM modules (foot.nix, wayland.nix)
    # with the same nord palette — stylix must not merge its own colors in.
    foot.enable = false;
    fuzzel.enable = false;
    # yazi has no theme files of its own here; let stylix theme it.
    yazi.enable = true;
    zen-browser = {
      enable = true;
      enableCss = true;
      profileNames = [
        "dijith-twilight"
        "dijith"
      ];

    };
  };



  # nvim is intentionally NOT migrated (per request) — it stays as the
  # only remaining consumer of config/, as a reproducible store copy.
  xdg.configFile."nvim".source = ../../config/nvim;

  # This workstation has enough memory to restore the full Zen session. Load
  # pinned and ordinary tabs eagerly so a restored workspace is immediately
  # ready; normal browser background throttling still limits idle CPU use.
  home.file.".config/zen/dijith-twilight/user.js".text = ''
    user_pref("browser.tabs.unloadOnLowMemory", false);
    user_pref("browser.sessionstore.restore_on_demand", false);
    user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", false);
    user_pref("browser.sessionstore.interval", 60000);
    user_pref("dom.min_background_timeout_value", 2000);
    user_pref("dom.min_background_timeout_value_without_budget_throttling", 2000);
  '';

  # Reproducible: no out-of-store ~/nixos-dots symlink — repo is at ~/nixos-dots (store-copied via home.file is not needed)
  # home.file."nixos-dots" removed for pure declarative reproducibility

}
