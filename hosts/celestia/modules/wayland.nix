{ pkgs, ... }:
{
  imports = [
    ./desktop/niri-config.nix
  ];

  services.wlsunset = {
    enable = true;
    latitude = "10.77";
    longitude = "76.22";
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  services.clipse.enable = true;
  services.awww.enable = true;
  services.dunst.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;
  programs.waybar.systemd.targets = [ "graphical-session.target" ];
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        show-actions = "yes";
        # also ensure terminal & layer match our source config
        terminal = "foot -e";
        layer = "overlay";
        lines = 20;
        width = 50;
        icon-theme = "Zafiro-Nord-Black";
        icons-enabled = "yes";
        sort-result = "yes";
        match-counter = "yes";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };


  home.packages = with pkgs;[
    ghostty
    niri
    wl-mirror
    fuzzel
    proton-vpn
    anyrun
    imagemagick
    hyprpicker
    hyprshot
    hyprcursor
    transmission_4
    keepassxc
    playerctl
    ripdrag
    wl-clipboard
    wf-recorder
    satty
    wlsunset
    brightnessctl
    swaynotificationcenter
    libnotify
    kdePackages.kdeconnect-kde
    kdePackages.qqc2-desktop-style
  ];
}
