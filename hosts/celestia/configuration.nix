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
      ./modules/system/power.nix
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
  # Track the newest kernel available in the pinned nixpkgs revision. Meteor
  # Lake graphics, scheduling and power-management fixes land here first.
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
    # Wi-Fi power saving parks the radio between beacons, adding latency and
    # jitter to every round trip (DNS, SSH, interactive web traffic).
    networkmanager.wifi.powersave = false;
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

  # Without a local resolver every lookup went straight to the upstream
  # (often a phone hotspot): NixOS's nsncd does not cache, and resolvconf
  # wrote the DHCP servers directly into /etc/resolv.conf. systemd-resolved
  # gives a local cache on 127.0.0.53; NetworkManager feeds it per-link DNS
  # automatically. Upstream servers stay DHCP-provided so captive portals and
  # hotspot-local names keep working. DNSSEC is off because many hotspot and
  # ISP forwarders mangle it, which turns into slow SERVFAIL retries.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "false";
      FallbackDNS = [ "1.1.1.1" "9.9.9.9" "2606:4700:4700::1111" ];
      # Avahi already answers mDNS; LLMNR only adds lookup delay.
      MulticastDNS = "false";
      LLMNR = "false";
    };
  };

  # BBR copes far better than cubic with the lossy, variable-latency links of
  # Wi-Fi and phone tethering; fq is the qdisc BBR is designed to pace with.
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_mtu_probing" = 1;
  };

  # Docker logs to journald, and a chatty container under load test wrote
  # ~3k lines/min; the journal had grown to 3.4G.
  services.journald.settings.Journal.SystemMaxUse = "1G";

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
  services.printing.enable = lib.mkDefault true;
  services.avahi.enable = lib.mkDefault true;
  services.udisks2.enable = true;
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
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
    bubblewrap
    git
    vim
    curl
    wget
    htop
    socat
    rustup
    helix
    nh
    chatgpt
    claude-desktop
    claude-code
    opencode-desktop
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
  # wait-online held multi-user.target for ~4.3s on every boot only because
  # docker.service orders after network-online.target. Nothing here needs a
  # routable network before login, and Wi-Fi association is slowest of all.
  systemd.services.NetworkManager-wait-online.enable = false;

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
    # Socket-activated: dockerd starts on the first docker command instead of
    # at boot, so dev stacks only come up when run manually.
    enableOnBoot = false;
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
      # networking/networkmanager.nix grants a passwordless polkit.Result.YES
      # for every org.freedesktop.NetworkManager.* action to members of this
      # group. Proton VPN's WireGuard kill switch needs it: it commits a /32
      # route onto the existing system-owned NetworkManager profile, which
      # otherwise fails polkit auth with "Insufficient privileges".
      "networkmanager"
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
