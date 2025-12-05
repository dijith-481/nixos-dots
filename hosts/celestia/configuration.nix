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
    enable = true;
    extraEntries = {
      "arch.conf" = "
		  title Arch Linux
		  efi /efi/GRUB/grubx64.efi
		  ";
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd = {
    secrets = {
      "/data-decrypt-key" = "/boot/data-decrypt-key";
    };
    luks.devices."luks" = {
      fallbackToPassword = true;
      keyFile = "/data-decrypt-key";
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  boot.plymouth = {
    enable = true;
    theme = "lone";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "lone" ];
      })
    ];
  };

  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
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
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

  };

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs;[
        mesa
        intel-media-driver
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


  networking = {
    hostName = locals.hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 5173 3000 3001 4321 8000 8080 ];
    };
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
  services.thermald.enable = true;

  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;


  services.tlp = {
    enable = true;
    settings = {
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 60;
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 1;
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  programs.dconf.enable = true;
  programs.niri.enable = true;
  programs.niri.useNautilus = false;
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
    enableSSHSupport = true;
  };
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.kdeconnect.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
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

  system.stateVersion = versions.nixos;
}

