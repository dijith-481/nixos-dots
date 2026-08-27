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
  programs.fuzzel.enable = true;


  home.packages = with pkgs;[
    ghostty
    niri
    wl-mirror
    fuzzel
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
