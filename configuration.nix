{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

 nix.settings.experimental-features = [ "nix-command" "flakes" ];
#environment.etc.crypttab = {
#	mode = "0600";
#	text = ''
#	luks  UUID="ad230d1a-d8e0-4130-acd1-a2646df639af" /boot/data-decrypt-key luks
#	'';
#};
fileSystems."/home/dijith/.Data" = {
    device = "/dev/mapper/luks"; 
    fsType = "ext4";             
    options = [ "nofail" ];      
  };
  boot.loader.systemd-boot = {
	enable = true;
	extraEntries = {
		"arch.conf" ="
		title Arch Linux
		efi /efi/GRUB/grubx64.efi
		";
	};
  };

hardware.cpu.intel.updateMicrocode = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.secrets = {
    "/data-decrypt-key" ="/boot/data-decrypt-key";
    
  };
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs;[
        mesa
        intel-media-driver
        libvdpau-va-gl
      ];
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General ={
          Experimental = true;
        };
      };
    };

boot.initrd.luks.devices."luks".keyFile = "/data-decrypt-key"; 
boot.initrd.luks.devices."luks".fallbackToPassword = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-celestia";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";

    services.xserver.enable = true;
    services.keyd ={
      enable = true;
      keyboards ={
        default = {
        ids = ["*"];
        settings = {
          main ={
            capslock ="overload(control,esc)";
            esc ="capslock";
          };
        };
      };
      };
    };
    services.displayManager.ly.enable=true;

  fonts.packages = with pkgs;[
    nerd-fonts.iosevka
  ];


  

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  services.libinput.enable = true;

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

programs.niri.enable = true;
programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    git
    vim 
    wget
    helix
    rustup
    bash
  ];

   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
   security.polkit.enable = true;
   services.gnome.gnome-keyring.enable = true;
   programs.kdeconnect.enable=true;

services.tlp = {
    enable = true;
    settings = {
      #TODO may change to balanceperformance and balance power
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

  services.blueman.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

networking.firewall = rec {
  allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  allowedUDPPortRanges = allowedTCPPortRanges;
};

  system.stateVersion = "25.11"; # Did you read the comment?

}

