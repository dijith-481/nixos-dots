{ pkgs, inputs, ... }:
let
  inherit (inputs.nfsm-flake.packages.${pkgs.system}) nfsm nfsm-cli;
  chameleos = pkgs.callPackage ../../../pkgs/chameleos.nix { };
in
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

  systemd.user.services = {
    hyprpolkitagent = {
      Unit = { Description = "Hyprland Polkit Agent"; };
      Service = {
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "always";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
    xwayland-satellite = {
      Unit = { Description = "Xwayland Satellite"; };
      Service = {
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        Restart = "always";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };

  };

  home.packages = with pkgs;[
    niri
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
    nfsm
    nfsm-cli
    chameleos
  ];
}
