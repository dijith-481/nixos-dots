{ pkgs, ... }:
let
  # bemoji normally downloads Unicode's emoji-test.txt on first run. Pin it at
  # build time and convert to bemoji's "emoji name" list format so the picker
  # works offline and reproducibly. Rendered with Noto Color Emoji.
  emojiList = pkgs.runCommand "bemoji-emojis.txt" { } ''
    ${pkgs.gnused}/bin/sed -ne \
      's/^.*; fully-qualified.*# \(\S*\) \S* \(.*$\)/\1 \2/gp' \
      ${pkgs.fetchurl {
        url = "https://unicode.org/Public/emoji/15.1/emoji-test.txt";
        hash = "sha256-2HbuJJqijqp2z6bfqnAoR6jROwYqpIjUZdA5XugTftk=";
      }} > $out
  '';
in
{
  imports = [
    ./desktop/niri-config.nix
  ];

  # Pre-seed bemoji's database so it never needs the network at runtime.
  home.file.".local/share/bemoji/emojis.txt".source = emojiList;

  services.wlsunset = {
    enable = true;
    latitude = "10.77";
    longitude = "76.22";
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  services.awww.enable = true;
  services.dunst.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;
  # waybar lives in ./desktop/waybar.nix (full settings + style).
  # Fully declarative fuzzel (migrated from config/fuzzel/fuzzel.ini):
  # Nord colors, 20 lines x 50 width, 2px rounded border.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        show-actions = "yes";
        # also ensure terminal & layer match our source config
        terminal = "foot -e";
        layer = "overlay";
        lines = 20;
        width = 50;
        icon-theme = "Zafiro-Nord-Black";
        icons-enabled = "yes";
        sort-result = "yes";
        match-counter = "yes";
      };
      colors = {
        background = "2e3440ef";
        text = "d8dee9ff";
        prompt = "81a1c1ff";
        placeholder = "4c566aff";
        input = "d8dee9ff";
        match = "a3be8cff";
        selection = "81a1c1ff";
        selection-text = "2e3440ff";
        selection-match = "ffffffff";
        counter = "a3be8cff";
        border = "81a1c1ff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };


  home.packages = with pkgs;[
    ghostty
    niri
    wl-mirror
    fuzzel
    bemoji
    wtype
    proton-vpn
    anyrun
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
    kdePackages.qqc2-desktop-style
  ];
}
