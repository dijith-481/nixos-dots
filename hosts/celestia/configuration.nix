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
  powerManagement.cpuFreqGovernor = "performance";
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
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
      cores = 0;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    optimise.automatic = true;

  };

  hardware = {

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs;[
        mesa
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        intel-compute-runtime
        libvdpau-va-gl
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
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
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




  services.xserver.enable = true;
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
  # services.thermald.enable = true;

  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;


  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 1;
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
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
  # flake module provides session wiring + config validation;
  # package comes from nixpkgs so it tracks our (newest) nixpkgs
  programs.niri.package = pkgs.niri;
  programs.niri.enable = true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
    git
    vim
    curl
    wget
    rustup
    helix
    nh
  ];

  programs.gnupg.agent = {
    enable = true;
  };
  security.polkit.enable = true;
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
      chown -R dijith:users /home/dijith/.Data
    '';
  };

  system.stateVersion = versions.nixos;
}

