{config,pkgs,zen-browser,...}:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dots/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    niri = "niri";
  };

in

{
  home.username = "dijith";
  home.homeDirectory = "/home/dijith";
  programs.ssh.enable = true;
  programs.git = {
    enable = true;
    userName = "dijith-481";
    userEmail = "dijithdinesh@protonmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;
      core.editor = "hx";
      column.ui = "auto";
      
      
    };
    signing ={
      key ="FB73ACE9832782B3";
      signByDefault = true;
    };
  };
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    zen-browser.packages."${pkgs.system}".default
    starship
    zoxide
    foot
    fzf
    kdlfmt
    brave
    btop
    qt6.qtbase              # Core Qt6 framework (includes qtwayland)
    qt6.qttools             # Qt6 development tools
    qt6.qtwayland           # Wayland support for Qt6
    qt5.qtbase              # Core Qt5 framework (many apps still use Qt5)
    qt5.qtwayland  

    seahorse
    gtk3
    gtk4
    glib
    xwayland-satellite
    libsecret

    
    niri
    waybar
    fuzzel
    swww
    wl-clipboard
    wf-recorder
    satty
    brightnessctl
    wlsunset
    dunst
    dua
    ripgrep
    unzip
    go
    nodejs_24
    python3
    lldb_20
    nushell
    fd
    zathura

    clipse
    neovim
    kitty
    fum
    cava
    zellij
    yazi
    tlp
    blueman
    pavucontrol
    lm_sensors
    fanctl
    nbfc-linux
    powertop
    acpi
    fastfetch
    inkscape
    lazygit
    qview
    bluetui
    bluez
    deno
    bun
    pnpm
    gcc
    shellcheck
    shfmt
    prettier
    docker
    docker-compose
    lazydocker
    ffmpeg
    hyprpicker
    hyprshot
    syncthing
    rustmission
    keepassxc
    playerctl
    ghostty
    ripdrag
    swaylock
    
    

    kdePackages.kdeconnect-kde
  ];

  xdg.configFile = builtins.mapAttrs (name: subpath:{
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
    
  })configs;
  
  
}
