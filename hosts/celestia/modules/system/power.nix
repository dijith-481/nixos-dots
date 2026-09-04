{ pkgs, ... }:

{
  # Keep one owner for each layer: thermald handles Intel thermal protection,
  # while power-profiles-daemon handles CPU EPP and the firmware profile.
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  powerManagement.powertop.enable = false;

  # Use Balanced on mains power and Power Saver on battery. Fn+Q or the Waybar
  # profile control can temporarily select another profile, and both update live.
  systemd.services.celestia-power-profile = {
    description = "Select a sane power profile for the current power source";
    # PPD's upstream unit is ordered after multi-user.target. Starting this
    # dependent service from that same target creates a boot-only ordering
    # cycle, so apply the initial policy as part of the graphical boot instead.
    wantedBy = [ "graphical.target" ];
    wants = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    path = [ pkgs.coreutils pkgs.power-profiles-daemon ];
    serviceConfig.Type = "oneshot";
    script = ''
      case "$(powerprofilesctl query-battery-aware)" in
        *True) ;;
        *) powerprofilesctl configure-battery-aware --enable ;;
      esac

      if [ "$(cat /sys/class/power_supply/ADP1/online)" = 1 ]; then
        powerprofilesctl set balanced
      else
        powerprofilesctl set power-saver
      fi

      # Use Lenovo's kernel-supported Efficient Thermal Dissipation policy.
      # The EC remains the fan controller; there is no userspace fan loop.
      if [ -w /sys/bus/platform/devices/VPC2004:00/fan_mode ]; then
        echo 4 > /sys/bus/platform/devices/VPC2004:00/fan_mode
      fi
    '';
  };

  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ADP1", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart celestia-power-profile.service"
  '';

  # Preserve battery health while the laptop spends long periods docked.
  systemd.services.lenovo-conservation-mode = {
    description = "Enable Lenovo battery conservation mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ -w /sys/class/power_supply/BAT0/charge_types ]; then
        echo Long_Life > /sys/class/power_supply/BAT0/charge_types
      fi
    '';
  };
}
