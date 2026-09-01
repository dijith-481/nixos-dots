{ lib, pkgs, ... }:
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
  # thermald can only add CPU/power throttling on this machine; it does not
  # control the Yoga's firmware/EC fan modes.
  services.thermald.enable = false;

  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;


  # Do not stack a userspace CPU limiter on top of the firmware profile and
  # Intel's hardware thermal protection.  TLP previously disabled turbo and
  # capped intel_pstate at 80% even while the firmware profile was performance.
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = false;

  # The BIOS binds its ACPI fan stages to the acpitz sensor, which remains
  # stuck near 28 C, instead of the working TCPU sensor.  Drive those existing
  # stages from TCPU with hysteresis so the fans respond before hardware
  # thermal throttling begins.  PNP0C0B:04 is the lowest stage and :01 the
  # highest normal stage; :00 remains available for the firmware's emergency
  # trip point.
  systemd.services.lenovo-acpi-fan-workaround = {
    description = "Drive Lenovo ACPI fan stages from the real CPU temperature";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
    };
    script = ''
      fan1=""
      fan2=""
      fan3=""
      fan4=""

      for coolingDevice in /sys/class/thermal/cooling_device*; do
        case "$(readlink -f "$coolingDevice/device")" in
          */PNP0C0B:04) fan1="$coolingDevice" ;;
          */PNP0C0B:03) fan2="$coolingDevice" ;;
          */PNP0C0B:02) fan3="$coolingDevice" ;;
          */PNP0C0B:01) fan4="$coolingDevice" ;;
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

      if [ -z "$fan1" ] || [ -z "$fan2" ] || [ -z "$fan3" ] ||
         [ -z "$fan4" ] || [ -z "$tempZone" ]; then
        echo "Required Lenovo ACPI fan stages or TCPU sensor not found" >&2
        exit 1
      fi

      setLevel() {
        level="$1"
        if [ "$level" -ge 1 ]; then echo 1 > "$fan1/cur_state"; else echo 0 > "$fan1/cur_state"; fi
        if [ "$level" -ge 2 ]; then echo 1 > "$fan2/cur_state"; else echo 0 > "$fan2/cur_state"; fi
        if [ "$level" -ge 3 ]; then echo 1 > "$fan3/cur_state"; else echo 0 > "$fan3/cur_state"; fi
        if [ "$level" -ge 4 ]; then echo 1 > "$fan4/cur_state"; else echo 0 > "$fan4/cur_state"; fi
      }

      level=0
      trap 'setLevel 0' EXIT INT TERM
      while true; do
        read -r temperature < "$tempZone/temp"
        case "$level" in
          0) if [ "$temperature" -ge 60000 ]; then level=1; fi ;;
          1)
            if [ "$temperature" -ge 70000 ]; then level=2
            elif [ "$temperature" -lt 55000 ]; then level=0
            fi
            ;;
          2)
            if [ "$temperature" -ge 80000 ]; then level=3
            elif [ "$temperature" -lt 65000 ]; then level=1
            fi
            ;;
          3)
            if [ "$temperature" -ge 90000 ]; then level=4
            elif [ "$temperature" -lt 75000 ]; then level=2
            fi
            ;;
          4) if [ "$temperature" -lt 85000 ]; then level=3; fi ;;
        esac
        setLevel "$level"
        sleep 2
      done
    '';
  };

  # Reproduce Fedora Workstation's power-management stack in isolated boot
  # entries.  Fedora maps the desktop Performance profile to TuneD's
  # throughput-performance profile.  Keep these as non-default A/B tests and
  # do not stack our ACPI fan workaround on top of TuneD.
  specialisation.fedora-tuned-performance.configuration = {
    system.nixos.tags = [ "fedora-tuned-performance" ];
    systemd.services.lenovo-acpi-fan-workaround.enable = lib.mkForce false;
    services.tuned = {
      enable = true;
      ppdSupport = true;
      ppdSettings = {
        main = {
          default = "performance";
          battery_detection = false;
        };
        profiles.performance = "throughput-performance";
      };
    };
  };

  specialisation.fedora-tuned-lts.configuration = {
    system.nixos.tags = [ "fedora-tuned-lts" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
    systemd.services.lenovo-acpi-fan-workaround.enable = lib.mkForce false;
    services.tuned = {
      enable = true;
      ppdSupport = true;
      ppdSettings = {
        main = {
          default = "performance";
          battery_detection = false;
        };
        profiles.performance = "throughput-performance";
      };
    };
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
