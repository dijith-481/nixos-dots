{ ... }:

{
  # Helix has a native Home Manager module. The TOML sources live next to
  # this module in ./files so the flake stays self-contained.
  # Helix has a native Home Manager module.  Reading the existing TOML keeps
  # the editor settings, language server setup, and custom theme unchanged
  # while making the generated files part of the HM generation.
  programs.helix = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./files/helix/config.toml);
    languages = builtins.fromTOML (builtins.readFile ./files/helix/languages.toml);
    themes.nordic = builtins.fromTOML (builtins.readFile ./files/helix/themes/nordic.toml);
  };

  # The picker is referenced by Helix's space-e binding.  It is a separate
  # executable because the Helix module only owns Helix's TOML files.
  xdg.configFile."helix/scripts/yazi-picker.sh" = {
    source = ./files/helix/scripts/yazi-picker.sh;
    executable = true;
  };

  # Zellij's KDL keybind tree is not representable by the module's typed
  # settings option.  Keep the complete, reviewed KDL files in the flake and
  # install only the active files (not the editor's backup copies).
  xdg.configFile = {
    "zellij/config.kdl".source = ./files/zellij-config.kdl;
    "zellij/kdlfmt.kdl".source = ./files/zellij-kdlfmt.kdl;
    "zellij/layouts/helix.kdl".source = ./files/zellij-layouts/helix.kdl;

    # Ghostty's config syntax permits repeated keybind directives, which the
    # current HM settings type cannot express without changing semantics.
    "ghostty/config".source = ./files/ghostty-config;

    # Fastfetch accepts JSONC (comments and trailing commas), while the HM
    # JSON settings generator accepts strict JSON.  Preserve both profiles as
    # store-backed files until a JSONC-aware native option exists.
    "fastfetch/config.jsonc".source = ./files/fastfetch/config.jsonc;
    "fastfetch/ghostty.jsonc".source = ./files/fastfetch/ghostty.jsonc;

    # cava.conf is an auxiliary kitty profile kept beside kitty.conf.
    "kitty/cava.conf".source = ./files/kitty-cava.conf;
  };

  # Kitty's 2,600-line file is generated documentation from kitty's template;
  # only these settings are active.  Declare the effective Nordfox palette
  # and options directly so the generated kitty.conf is concise and native.
  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.7";

      foreground = "#cdcecf";
      background = "#2e3440";
      selection_foreground = "#cdcecf";
      selection_background = "#3e4a5b";
      cursor = "#cdcecf";
      cursor_text_color = "#2e3440";
      url_color = "#a3be8c";
      active_border_color = "#81a1c1";
      inactive_border_color = "#5a657d";
      bell_border_color = "#c9826b";
      active_tab_foreground = "#232831";
      active_tab_background = "#81a1c1";
      inactive_tab_foreground = "#60728a";
      inactive_tab_background = "#3e4a5b";

      color0 = "#3b4252";
      color8 = "#465780";
      color1 = "#bf616a";
      color9 = "#d06f79";
      color2 = "#a3be8c";
      color10 = "#b1d196";
      color3 = "#ebcb8b";
      color11 = "#f0d399";
      color4 = "#81a1c1";
      color12 = "#8cafd2";
      color5 = "#b48ead";
      color13 = "#c895bf";
      color6 = "#88c0d0";
      color14 = "#93ccdc";
      color7 = "#e5e9f0";
      color15 = "#e7ecf4";
      color16 = "#c9826b";
      color17 = "#bf88bc";
    };
  };

  # Keep tmux's existing plugin declarations and keybindings byte-for-byte in
  # the native HM extraConfig option.  The explicit reload target is retained
  # because the config itself binds `r` to ~/.config/tmux.conf.
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./files/tmux.conf;
  };
  home.file.".config/tmux.conf".source = ./files/tmux.conf;
}
