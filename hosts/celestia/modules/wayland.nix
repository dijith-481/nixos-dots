{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config.common.default = "gtk";
  };

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
  services.swww.enable = true;
  services.dunst.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;
  services.syncthing.enable = true;
  programs.waybar.enable = true;


  home.packages = with pkgs;[
    niri
    wl-mirror
    fuzzel
    anyrun
    waybar
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
    hyprpolkitagent
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
  ];
}
