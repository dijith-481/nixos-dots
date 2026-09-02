{ config, lib, pkgs, ... }:
let
  versions = import ../../versions.nix;
  locals = import ./locals.nix { inherit pkgs; };
in
{
  imports =
    [
      ../../globals.nix
      ./stylix.nix
      ./hardware-configuration.nix
      ./modules/system/display-manager.nix
    ];

  boot.loader.systemd-boot = {

    configurationLimit = 5;
    consoleMode = "max";
    enable = true;
    extraEntries = {
      "arch.conf" = "
		  title Arch Linux
		  efi /efi/GRUB/grubx64.efi
		  ";
    };
  };
  security.tpm2.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd = {
    availableKernelModules = [ "tpm_crb" ];
    kernelModules = [
      "i915"
    ];
    systemd = {
      enable = true;
    };
    systemd.tpm2.enable = true;
  };
  # Use the nixpkgs default kernel for an A/B test. The latest kernel produced
  # persistent i915 page-flip waits and an atomic-update failure on this GPU.
  boot.kernelPackages = pkgs.linuxPackages;
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.plymouth = {
    enable = true;
    theme = lib.mkForce "lone";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "lone" ];
      })
    ];
  };

  boot.kernelParams = [
    "quiet"
    # The internal eDP panel's PSR1 sink repeatedly remains in timing re-sync
    # while i915_flip workers wait in drm_atomic_helper_wait_for_flip_done,
    # producing system-wide I/O PSI despite almost no NVMe activity.
    "i915.enable_psr=0"
  ];
  # Hide the OS choice for bootloaders.
  # It's still possible to open the bootloader list by pressing any key
  # It will just not appear on screen unless a key is pressed
  boot.loader.timeout = 0;
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 40;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      # Avoid letting a single build occupy every logical CPU while the laptop
      # cooling system is unable to keep the package below its throttle point.
      max-jobs = 1;
      cores = 8;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };

  hardware = {

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };


  networking = {
    hostName = locals.hostname;
    networkmanager.enable = true;
    firewall = rec{
      enable = true;
      allowedTCPPorts = [ 22 80 443 5173 3000 3001 4321 8000 8080 45325 22000 ];
      allowedUDPPorts = allowedTCPPorts;
    };
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };




  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "overload(control,esc)";
            esc = "capslock";
          };
        };
      };
    };
  };


  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", MODE="0666"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ADP1", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart apply-power-source-profile.service"
  '';

  systemd.user.services.mic-led-sync = {
    description = "Sync Microphone Mute LED with WirePlumber status";
    
    after = [ "pipewire.service" "wireplumber.service" ];
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    path = with pkgs; [ 
      wireplumber 
      pulseaudio 
      brightnessctl 
      gnugrep 
      bash 
      coreutils 
    ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      set -e
      
      update_led() {
        STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null) || return 0

        if echo "$STATUS" | grep -q "MUTED"; then
          brightnessctl -d "platform::micmute" set 0
        else
          brightnessctl -d "platform::micmute" set 1
        fi
      }

      update_led

      pactl subscribe | grep --line-buffered "source" | while read -r line; do 
        update_led
      done
    '';
  };

# DNS will be handled automatically by NetworkManager
  # Optional: Custom DNS servers (uncomment if you want to override ISP DNS)
  # networking.nameservers = [ "8.8.8.8" "1.1.1.1" "1.0.0.1" "9.9.9.9" ];
  # Enable systemd-resolved for better DNS handling
  # services.resolved = {
  #   enable = true;
  #   dnssec = "true";
  #   domains = [ "~." ];
  #   fallbackDns = [ "8.8.8.8" "1.1.1.1" ];
  #   extraConfig = ''
  #     DNS=8.8.8.8 1.1.1.1 1.0.0.1
  #     FallbackDNS=9.9.9.9 149.112.112.112
  #   '';
  # };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };
  # PipeWire and browser screen capture need RTKit to schedule real-time media
  # threads without falling back to normal priority under CPU load.
  security.rtkit.enable = true;

  # Keep one portal stack at the system layer. Niri supplies the GNOME backend
  # for ScreenCast; GTK handles generic dialogs and power-inhibit requests.
  xdg.portal = {
    enable = true;
    config = {
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
      };
      common.default = [ "gtk" ];
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.syncthing = {
    enable = true;
    user = "dijith"; # Run as your user
    dataDir = "/home/dijith"; # Default folder for new syncs
    configDir = "/home/dijith/.config/syncthing"; # Use your user config
    overrideDevices = false; # Don't wipe your manual config changes
    overrideFolders = false; # Don't wipe your manual folders
    openDefaultPorts = true;
  };

  services.libinput.enable = true;
  # The firmware exposes a broken default RAPL cooling range ending at 125 mW.
  # Define a safe 20-40 W PPCC range and explicit passive target states so
  # thermald can prevent prolonged operation near TjMax without ever collapsing
  # package power or disabling turbo.  The fan policies below act first.
  services.thermald = {
    enable = true;
    configFile = pkgs.writeText "thermal-conf-celestia.xml" ''
      <?xml version="1.0"?>
      <ThermalConfiguration>
        <Platform>
          <Name>Lenovo Yoga Slim 7 14IMH9</Name>
          <ProductName>83CV</ProductName>
          <Preference>QUIET</Preference>
          <PPCC>
            <PowerLimitIndex>0</PowerLimitIndex>
            <PowerLimitMaximum>40000</PowerLimitMaximum>
            <PowerLimitMinimum>20000</PowerLimitMinimum>
            <TimeWindowMinimum>2000</TimeWindowMinimum>
            <TimeWindowMaximum>28000</TimeWindowMaximum>
            <StepSize>2000</StepSize>
          </PPCC>
          <ThermalZones>
            <ThermalZone>
              <Type>celestia_cpu</Type>
              <TripPoints>
                <TripPoint>
                  <SensorType>x86_pkg_temp</SensorType>
                  <Temperature>90000</Temperature>
                  <Hyst>3000</Hyst>
                  <type>passive</type>
                  <ControlType>PARALLEL</ControlType>
                  <CoolingDevice>
                    <type>rapl_controller</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>32000000</TargetState>
                  </CoolingDevice>
                  <CoolingDevice>
                    <type>rapl_controller_mmio</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>32000000</TargetState>
                  </CoolingDevice>
                </TripPoint>
                <TripPoint>
                  <SensorType>x86_pkg_temp</SensorType>
                  <Temperature>95000</Temperature>
                  <Hyst>3000</Hyst>
                  <type>passive</type>
                  <ControlType>PARALLEL</ControlType>
                  <CoolingDevice>
                    <type>rapl_controller</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>26000000</TargetState>
                  </CoolingDevice>
                  <CoolingDevice>
                    <type>rapl_controller_mmio</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>26000000</TargetState>
                  </CoolingDevice>
                </TripPoint>
                <TripPoint>
                  <SensorType>x86_pkg_temp</SensorType>
                  <Temperature>100000</Temperature>
                  <Hyst>3000</Hyst>
                  <type>passive</type>
                  <ControlType>PARALLEL</ControlType>
                  <CoolingDevice>
                    <type>rapl_controller</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>20000000</TargetState>
                  </CoolingDevice>
                  <CoolingDevice>
                    <type>rapl_controller_mmio</type>
                    <SamplingPeriod>5</SamplingPeriod>
                    <TargetState>20000000</TargetState>
                  </CoolingDevice>
                </TripPoint>
              </TripPoints>
            </ThermalZone>
          </ThermalZones>
        </Platform>
      </ThermalConfiguration>
    '';
  };

  # The default firmware TCPU zone is additive even with a manual XML and can
  # independently disable turbo.  Run only the reviewed policy above.
  systemd.services.thermald.serviceConfig.ExecStart = lib.mkForce ''
    ${config.services.thermald.package}/sbin/thermald \
      --no-daemon \
      --ignore-default-control \
      --config-file ${config.services.thermald.configFile} \
      --dbus-enable
  '';

  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;


  # TLP previously disabled turbo and capped intel_pstate at 80% even while
  # the firmware profile was performance, so use power-profiles-daemon as the
  # single profile manager instead.
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # This Yoga exposes a second, independent Lenovo EC fan policy control.
  # platform_profile=performance does not update it: it remained in mode 1
  # (Standard) at 102 C.  Mode 4 is the kernel-documented "Efficient Thermal
  # Dissipation" policy and is the most aggressive firmware-managed mode.
  systemd.services.lenovo-efficient-thermal-dissipation = {
    description = "Select Lenovo Efficient Thermal Dissipation fan mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      fanMode=/sys/bus/platform/devices/VPC2004:00/fan_mode
      if [ ! -w "$fanMode" ]; then
        echo "Lenovo fan_mode interface is unavailable" >&2
        exit 1
      fi
      echo 4 > "$fanMode"
    '';
  };

  # The EC may reset its fan policy across suspend.  Reapply mode 4 after the
  # machine has resumed, when the platform device is available again.
  environment.etc."systemd/system-sleep/lenovo-efficient-thermal-dissipation".source =
    pkgs.writeShellScript "lenovo-efficient-thermal-dissipation-resume" ''
      if [ "$1" = post ] &&
         [ -w /sys/bus/platform/devices/VPC2004:00/fan_mode ]; then
        echo 4 > /sys/bus/platform/devices/VPC2004:00/fan_mode
      fi
    '';

  # Keep the compositor, input path and session services responsive when a
  # test runner or type checker fills all 22 logical CPUs.  CPUWeight affects
  # contention only; it does not cap build performance while CPUs are free.
  systemd.user.slices.session.sliceConfig.CPUWeight = 1000;
  systemd.user.slices.app.sliceConfig.CPUWeight = 100;

  # Prefer full performance on external power and balanced operation on
  # battery.  A udev event reapplies the policy whenever the AC state changes.
  systemd.services.apply-power-source-profile = {
    description = "Select the platform profile for the current power source";
    wantedBy = [ "graphical.target" ];
    wants = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    path = [ pkgs.coreutils pkgs.power-profiles-daemon ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ "$(cat /sys/class/power_supply/ADP1/online)" = 1 ]; then
        powerprofilesctl set performance
      else
        powerprofilesctl set balanced
      fi
    '';
  };

  # Lenovo conservation mode stops charging at roughly 80% to reduce battery
  # wear while the laptop spends long periods connected to AC power.
  systemd.services.lenovo-conservation-mode = {
    description = "Enable Lenovo battery conservation mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo Long_Life > /sys/class/power_supply/BAT0/charge_types
    '';
  };

  # The BIOS binds its ACPI fan policy to acpitz, which remains stuck near
  # 28 C, instead of the working TCPU sensor.  DSDT/SSDT inspection shows that
  # only PNP0C0B:01 and :00 reach the EC: 01 alone selects AC1F (normal), and
  # 01+00 selects AC0F (maximum).  The other three exposed objects only update
  # unused firmware variables and are not additional fan-speed levels.
  systemd.services.lenovo-acpi-fan-workaround = {
    description = "Drive Lenovo ACPI fan policy from the real CPU temperature";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
    };
    script = ''
      fanNormal=""
      fanMaximum=""

      for coolingDevice in /sys/class/thermal/cooling_device*; do
        case "$(readlink -f "$coolingDevice/device")" in
          */PNP0C0B:01) fanNormal="$coolingDevice" ;;
          */PNP0C0B:00) fanMaximum="$coolingDevice" ;;
        esac
      done

      tempZone=""
      for zone in /sys/class/thermal/thermal_zone*; do
        read -r zoneType < "$zone/type"
        if [ "$zoneType" = TCPU ]; then
          tempZone="$zone"
          break
        fi
      done

      if [ -z "$fanNormal" ] || [ -z "$fanMaximum" ] || [ -z "$tempZone" ]; then
        echo "Required Lenovo ACPI fan controls or TCPU sensor not found" >&2
        exit 1
      fi

      setLevel() {
        level="$1"
        if [ "$level" -ge 1 ]; then echo 1 > "$fanNormal/cur_state"; else echo 0 > "$fanNormal/cur_state"; fi
        if [ "$level" -ge 2 ]; then echo 1 > "$fanMaximum/cur_state"; else echo 0 > "$fanMaximum/cur_state"; fi
      }

      # Select the appropriate real EC policy immediately.  Full cooling starts
      # well below TjMax so the fan gets time to work before CPU throttling.
      read -r temperature < "$tempZone/temp"
      if [ "$temperature" -ge 75000 ]; then level=2
      elif [ "$temperature" -ge 55000 ]; then level=1
      else level=0
      fi

      setLevel "$level"
      appliedLevel="$level"
      trap 'setLevel 0' EXIT INT TERM
      while true; do
        read -r temperature < "$tempZone/temp"
        case "$level" in
          0) if [ "$temperature" -ge 55000 ]; then level=1; fi ;;
          1)
            if [ "$temperature" -ge 75000 ]; then level=2
            elif [ "$temperature" -lt 50000 ]; then level=0
            fi
            ;;
          2) if [ "$temperature" -lt 70000 ]; then level=1; fi ;;
        esac
        # ACPI fan writes call into the EC, so write only on a real transition.
        if [ "$level" -ne "$appliedLevel" ]; then
          setLevel "$level"
          appliedLevel="$level"
        fi
        sleep 2
      done
    '';
  };

  security.enableWrappers = true;
  security.wrappers.intel_gpu_top = {
    owner = "root";
    group = "root";
    source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
    capabilities = "cap_perfmon+ep";
  };
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    source = "${pkgs.btop}/bin/btop";
    capabilities = "cap_perfmon+ep";
  };

  programs.dconf.enable = true;
  programs.nix-ld.enable = true; # for dynamically linked binaries in $HOME (vp's vite-plus node at ~/.local/share/vite-plus/js_runtime/node/…/bin/node, manual installs)
  # flake module provides session wiring + config validation;
  # package comes from nixpkgs so it tracks our (newest) nixpkgs
  programs.niri.package = pkgs.niri;
  programs.niri.enable = true;
  programs.appimage.enable=true;
  programs.appimage.binfmt=true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
    bubblewrap
    git
    vim
    curl
    wget
    rustup
    helix
    nh
    chatgpt
    zcode
  ];

  programs.gnupg.agent = {
    enable = true;
  };
  security.polkit.enable = true;

  # niri-flake's KDE agent crashes while opening its authentication dialog
  # because its QML runtime cannot load the Kvantum module. It also races with
  # hyprpolkitagent for the single per-session polkit-agent registration.
  # Keep polkit itself enabled, but run exactly one working Wayland agent.
  systemd.user.services.niri-flake-polkit.enable = false;
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Slice = "session.slice";
      TimeoutStopSec = "5s";
      Restart = "on-failure";
    };
  };

  services.gnome.gnome-keyring.enable = true;
  programs.kdeconnect.enable = true;
  systemd.services.docker = {
    requires = [ "var-lib-vms.mount" ];
    after = [ "var-lib-vms.mount" ];
  };

  virtualisation.docker = {
    enable = true;
    daemon = {
      settings = {
        data-root = "/var/lib/vms/docker";
      };
    };
    # enableOnBoot = true;
  };

  time.timeZone = "Asia/Kolkata";
  #i18n.defaultLocale = "en_US.UTF-8";

  fonts = {
    packages = with pkgs;[
      nerd-fonts.iosevka
      inter
      noto-fonts
      noto-fonts-color-emoji
      corefonts
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Inter" "Noto Sans" ];
        serif = [ "Times New Roman" ];
        monospace = [ "Iosevka" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  users.users.dijith = {
    isNormalUser = true;
    packages = with pkgs; [
      tree
    ];
    extraGroups = [
      "wheel"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.fish;
  };

  # Bind the encrypted data volume into the user's home.
  fileSystems."/home/dijith/.Data" = {
    device = "/mnt/data";
    fsType = "none";
    options = [ "bind" "nofail" "x-systemd.make-directory" ];
    neededForBoot = false;
  };

  # Ensure the user owns the mounted data volume.
  systemd.services.data-access = {
    description = "Set ownership of /home/dijith/.Data";
    wantedBy = [ "multi-user.target" ];
    after = [ "home-dijith-.Data.mount" ];
    requires = [ "home-dijith-.Data.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Only the mount root needs ownership correction. Recursing through the
      # whole encrypted data volume caused a large metadata scan every boot.
      chown dijith:users /home/dijith/.Data
    '';
  };

  system.stateVersion = versions.nixos;
}
