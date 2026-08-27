{ config, lib, pkgs, ... }:
{
  home.sessionVariables = {
    XCURSOR_THEME = "Everforest-Dark";
    XCURSOR_SIZE = "28";
    EDITOR = "hx";
    BROWSER = "zen-twilight";
    TERMINAL = "ghostty";
    TERM = "xterm-256color";
    COLORTERM = "truecolor";

    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    QT_QPA_PLATFORM = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0";

    SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    # Development environment
    DEVELOPMENT_MODE = "1";

    # Rust
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    RUST_BACKTRACE = "1";

    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";

    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";

    PATH = "$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$PATH:$HOME/.npm-global/bin";
  };
}
