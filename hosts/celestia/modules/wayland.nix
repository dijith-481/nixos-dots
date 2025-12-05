{ pkgs, inputs, system, ... }:
let
  inherit (inputs.nfsm-flake.packages.${system}) nfsm nfsm-cli;
in
{
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    # inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];
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
  services.hyprlock.enable = true;
  services.syncthing.enable = true;
  # programs.waybar.enable = true;
  programs.niri.enable = true;
  programs.niri.useNautilus = false;
  programs.dankMaterialShell = {
    enable = true;
  };

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
  home.file.".config/niri/autostart.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP NIRI_SOCKET

      sleep 1

      swww restore 

      zen 
      brave --app=https://music.youtube.com &
      
    '';
  };

  home.packages = with pkgs;[
    niri
    fuzzel
    anyrun
    cham
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
    hyprpolkitagent
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    nfsm
    nfsm-cli
  ];
}
