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
  # The Yoga's fan curve is owned by firmware/EC and is not exposed as a
  # controllable hwmon device.  thermald cannot raise its fan speed here; it
  # would only add another CPU/power throttling policy on top of TLP and the
  # processor's hardware thermal protection.
  services.thermald.enable = false;

  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;


  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      # Keep the firmware's more aggressive AC fan curve while independently
      # limiting CPU heat below.  Balanced is preferable on battery.
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # Temporary safety limits until the firmware-controlled fan is repaired.
      CPU_MAX_PERF_ON_AC = 80;
      CPU_MAX_PERF_ON_BAT = 60;
      CPU_BOOST_ON_AC = 0;
      CPU_BOOST_ON_BAT = 0;
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
