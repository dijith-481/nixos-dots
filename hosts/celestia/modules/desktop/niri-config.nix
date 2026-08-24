# Declarative niri configuration via niri-flake
# Translated from config/niri/config.kdl — build-time validated against niri's schema.
# Stylix auto-themes borders/cursor via its niri target.
{ pkgs, lib, ... }:

{
  programs.niri.settings = {
    # --- Named workspaces ---
    workspaces = {
      "browser".name = "browser";
      "ytmusic".name = "ytmusic";
    };

    # --- Environment for compositor-spawned processes ---
    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      QT_QPA_PLATFORMTHEME = "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    input = {
      # false = let logind own the power key (see services.logind.settings)
      power-key-handling.enable = false;
      keyboard = {
        repeat-delay = 240;
        repeat-rate = 50;
        xkb.layout = "us";
      };
      touchpad = {
        tap = true;
        dwt = true;
        drag-lock = true;
        accel-speed = 0.2;
        scroll-method = "two-finger";
        tap-button-map = "left-right-middle";
        scroll-factor = 1.0;
      };
      mouse.accel-speed = 0.2;
      warp-mouse-to-focus.mode = "center-xy";
      focus-follows-mouse.max-scroll-amount = "10%";
    };

    outputs."eDP-1" = {
      mode.width = 1920;
      mode.height = 1200;
      scale = 1.0;
      background-color = "#191d24";
    };

    layout = {
      gaps = 0;
      center-focused-column = "never";
      always-center-single-column = true;
      default-column-display = "tabbed";
      background-color = "transparent";
      preset-column-widths = map (p: { proportion = p; }) [ 0.33333 0.5 0.66667 0.9 ];
      preset-window-heights = map (p: { proportion = p; }) [ 0.33333 0.5 0.66667 1.0 ];
      default-column-width.proportion = 0.5;

      focus-ring.enable = false;
      border.enable = false;

      tab-indicator = {
        hide-when-single-tab = true;
        width = 3;
        gap = -2;
        length.total-proportion = 0.999;
        corner-radius = 0;
        position = "left";
        active.color = "#a3be8c";
        inactive.color = "#2e3440";
      };

      shadow = {
        softness = 0;
        spread = 0;
        offset.x = 0;
        offset.y = 0;
        color = "#81a1c2";
      };
    };

    overview = {
      zoom = 0.3;
      backdrop-color = "#2e3440";
      workspace-shadow.enable = false;
    };

    # NOTE: recent-windows (alt-tab switcher) not yet in niri-flake's schema —
    # it's newer than the flake's pinned niri. Re-add once sodiboo's bot picks it up.
    # Until then Mod+Tab binds below are inert.
    # recent-windows = {
    #   debounce-ms = 750;
    #   open-delay-ms = 150;
    #   highlight = {
    #     active-color = "#999999ff";
    #     urgent-color = "#ff9999ff";
    #     padding = 30;
    #     corner-radius = 0;
    #   };
    #   previews = {
    #     max-height = 480;
    #     max-scale = 0.5;
    #   };
    # };

    spawn-at-startup = [
      { argv = [ "systemctl" "--user" "start" "hyprpolkitagent" ]; }
      { argv = [ "xwayland-satellite" ]; }
      { sh = "sleep 1 && (awww restore || swww restore)"; }
      { sh = "(zen-beta || zen-twilight || zen)"; }
      { argv = [ "brave" "--app=https://music.youtube.com" ]; }
    ];

    prefer-no-csd = true;
    screenshot-path = "~/Downloads/screenshots/ from %Y-%m-%d %H-%M-%S.png";

    cursor = {
      theme = "Nordzy-cursors";
      size = 10;
      hide-when-typing = true;
    };

    hotkey-overlay.skip-at-startup = true;

    layer-rules = [
      {
        matches = [
          { namespace = "^waybar$"; at-startup = true; }
        ];
        shadow = {
          softness = 40;
          spread = 5;
          offset = { x = 0; y = 5; };
          draw-behind-window = true;
          color = "#00000064";
        };
      }
    ];

    window-rules = [
      {
        matches = [ { app-id = "^floatingfoot$"; } ];
        open-floating = true;
        default-column-width.fixed = 784;
        default-window-height.fixed = 464;
      }
      {
        matches = [ { app-id = "^.*music.youtube.*$"; at-startup = true; } ];
        open-maximized = true;
        open-on-workspace = "ytmusic";
      }
      {
        matches = [ { app-id = "^org\\.kde\\.kdeconnect\\.daemon$"; } ];
        open-floating = true;
        default-floating-position = { x = 600; y = 0; relative-to = "top-left"; };
      }
      {
        matches = [ { title = "fzf-picker"; } ];
        open-floating = true;
        default-column-width.fixed = 600;
        default-window-height.fixed = 600;
      }
      {
        matches = [ { title = ".*md$"; } ];
      }
      {
        matches = [ { title = "^.*(qView).*$"; } ];
        open-floating = true;
        default-column-width.fixed = 700;
        default-window-height.fixed = 438;
      }
      {
        matches = [ { app-id = "zen$"; at-startup = true; } ];
        open-on-workspace = "browser";
        open-maximized = true;
        draw-border-with-background = false;
      }
      {
        matches = [
          { app-id = "^clipse$"; }
          { app-id = "^selectwebsite$"; }
        ];
        open-floating = true;
        default-column-width.fixed = 622;
        default-window-height.fixed = 652;
      }
      {
        matches = [ { app-id = "float"; } ];
        open-floating = true;
        default-column-width.fixed = 622;
        default-window-height.fixed = 652;
      }
      {
        matches = [ { app-id = "^fum$"; } ];
        default-floating-position = { x = 600; y = 0; relative-to = "top-left"; };
        open-floating = true;
        border.enable = false;
        baba-is-float = true;
        focus-ring.enable = false;
        shadow.enable = false;
        open-focused = false;
        default-column-width.fixed = 420;
        default-window-height.fixed = 260;
      }
      {
        matches = [
          { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
          { app-id = "^org\\.gnome\\.World\\.Secrets$"; }
        ];
        block-out-from = "screen-capture";
      }
      {
        matches = [ { app-id = "^org\\.gnome\\.Nautilus$"; title = "^.*(wants to open).*$"; } ];
        default-column-width.proportion = 0.33333;
        default-window-height.proportion = 0.66667;
        default-floating-position = { x = 0; y = 0; relative-to = "top-right"; };
      }
      {
        matches = [ { is-floating = true; } ];
        shadow.enable = true;
      }
      {
        geometry-corner-radius = {
          top-left = 0.0;
          top-right = 0.0;
          bottom-left = 0.0;
          bottom-right = 0.0;
        };
        clip-to-geometry = true;
      }
    ];

    switch-events.lid-close.action.spawn = [ "hyprlock" ];

    binds =
      let
        spawn = cmd: { action.spawn = cmd; };
        sh = s: { action.spawn-sh = s; };
      in
      {
        "Mod+Shift+Slash".action.show-hotkey-overlay = { };

        # touchpad scroll gestures
        "Mod+Alt+TouchpadScrollUp".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.01+" ];
        "Mod+Alt+TouchpadScrollDown".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.01-" ];
        "Mod+TouchpadScrollLeft".action.focus-column-left = { };
        "Mod+TouchpadScrollRight".action.focus-column-right = { };
        "Mod+TouchpadScrollUp".cooldown-ms = 200;
        "Mod+TouchpadScrollUp".action.focus-workspace-up = { };
        "Mod+TouchpadScrollDown".cooldown-ms = 200;
        "Mod+TouchpadScrollDown".action.focus-workspace-down = { };

        # media / volume / brightness
        "XF86AudioPlay" = { allow-when-locked = true; action.spawn = [ "playerctl" "play-pause" ]; };
        "XF86AudioPause" = { allow-when-locked = true; action.spawn = [ "playerctl" "play-pause" ]; };
        "XF86AudioPrev" = { allow-when-locked = true; action.spawn = [ "playerctl" "next" ]; };
        "XF86AudioNext" = { allow-when-locked = true; action.spawn = [ "playerctl" "previous" ]; };
        "XF86AudioRaiseVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+" ]; };
        "XF86AudioLowerVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-" ]; };
        "XF86AudioMute" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ]; };
        "XF86AudioMicMute" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ]; };
        "XF86MonBrightnessUp" = { allow-when-locked = true; action.spawn = [ "brightnessctl" "set" "+5%" ]; };
        "XF86MonBrightnessDown" = { allow-when-locked = true; action.spawn = [ "brightnessctl" "set" "5%-" ]; };

        # playerctl extras
        "Mod+Alt+space" = { repeat = false; } // (sh "~/.config/hypr/scripts/playerctl-play-pause.sh");
        "Mod+Alt+slash" = { repeat = false; action.spawn = [ "playerctld" "shift" ]; };
        "Mod+Alt+period" = { repeat = false; action.spawn = [ "playerctl" "next" ]; };
        "Mod+Alt+comma" = { repeat = false; action.spawn = [ "playerctl" "previous" ]; };

        # wallpaper
        "Mod+U" = { repeat = false; } // (sh "~/.config/hypr/scripts/wallpaper.sh");
        "Mod+Control+U" = { repeat = false; } // (sh "~/.config/hypr/scripts/live-wallpaper.sh");

        # windows & terminals
        "Mod+W" = { repeat = false; action.close-window = { }; };
        "Mod+Q".action.spawn = [ "foot" ];
        "Mod+Return" = { repeat = false; action.spawn = [ "foot" "-a" "floatingfoot" ]; };
        "Mod+Alt+Return" = { repeat = false; action.spawn = [ "kitty" ]; };

        # notifications
        "Mod+C".action.spawn = [ "dunstctl" "close" ];
        "Mod+Shift+C".action.spawn = [ "dunstctl" "set-paused" "toggle" ];

        # bluetooth + night light
        "Mod+Alt+b".action.spawn = [ "bluetoothctl" "connect" "68:4A:E9:01:FC:C4" ];
        "Mod+Alt+E" = { repeat = false; } // (sh "pkill wlsunset || wlsunset -l 10.77 -L 76.22");

        # apps & tools
        "Mod+space".action.spawn = [ "fuzzel" ];
        "Mod+F2".action.spawn = [ "hyprlock" ];
        "Mod+E".action.spawn = [ "kitty" "--class" "yazi" "-e" "yazi" ];
        "Mod+Control+E".action.spawn = [ "foot" "-a" "floatingfoot" "-e" "yazi" ];
        "Mod+V".action.spawn = [ "kitty" "--class" "clipse" "-e" "clipse" ];
        "Mod+Control+space" = { repeat = false; } // (sh "pkill fum || kitty --class fum -e 'fum'");

        # screenshots & recording
        "Mod+XF86Favorites".action.screenshot-screen = { };
        "Mod+Control+XF86Favorites".action.screenshot = { };
        "Mod+Shift+XF86Favorites".action.screenshot-window = { };
        "Mod+Alt+XF86Favorites" = { repeat = false; } // (sh ''
          pkill wf-recorder || wf-recorder \
            --geometry "$(slurp)" \
            -f ~/Downloads/screenshots/record_$(date +%Y%m%d_%H%M%S)_wf.mkv'');
        "XF86Favorites" = { repeat = false; } // (sh "~/.config/hypr/scripts/screenshot.sh region --clipboard-only");
        "Print" = { action.screenshot.show-pointer = false; };
        "Ctrl+Print" = { action.screenshot-screen.show-pointer = false; };
        "Alt+Print".action.screenshot-window = { };

        # web / misc
        "Mod+B" = { repeat = false; action.spawn-sh = "zen-beta || zen-twilight || zen"; };
        "Mod+Control+B" = { repeat = false; action.spawn = [ "./Dev/history-website-appmode/target/release/history-website-appmode" ]; };
        "Mod+Control+Shift+B" = { repeat = false; action.spawn = [ "./Dev/history-website-appmode/target/release/history-website-appmode" "-i" ]; };
        "Mod+Alt+Y".action.spawn = [ "brave" "--app=https://music.youtube.com" ];
        "Mod+g".action.spawn = [ "brave" "--app=https://aistudio.google.com" ];
        "Mod+Control+f" = { repeat = false; } // (sh "~/.config/hypr/scripts/kde-fileshare.sh");
        "Mod+Control+c" = { repeat = false; } // (sh "~/.config/hypr/scripts/copy-file.sh");
        "Mod+Control+Shift+c" = { repeat = false; } // (sh "~/.config/hypr/scripts/rip-drag.sh");
        "Mod+z".action.spawn = [ "foot" "nvim" ];
        "Mod+x" = { repeat = false; } // (sh "foot -T md ~/.config/hypr/scripts/mdToday.sh");
        "Mod+Control+X" = { repeat = false; } // (sh "foot -T md ~/.config/hypr/scripts/todolist.sh");
        "Mod+Alt+c".action.spawn = [ "hyprpicker" "-a" ];
        "Mod+Y".action.focus-workspace = "ytmusic";
        "Mod+grave".action.toggle-overview = { };
        "Alt+Space".action.toggle-overview = { };
        "Mod+Alt+P" = { repeat = false; } // (sh "wl-mirror $(niri msg --json focused-output | jq -r .name)");

        # focus navigation
        "Mod+Left".action.focus-column-left = { };
        "Mod+Down".action.focus-window-down = { };
        "Mod+Up".action.focus-window-up = { };
        "Mod+Right".action.focus-column-right = { };
        "Mod+H".action.focus-column-left = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right = { };

        "Mod+Ctrl+Left".action.move-column-left = { };
        "Mod+Ctrl+Down".action.move-window-down = { };
        "Mod+Ctrl+Up".action.move-window-up = { };
        "Mod+Ctrl+Right".action.move-column-right = { };
        "Mod+Ctrl+H".action.move-column-left = { };
        "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = { };
        "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = { };
        "Mod+Ctrl+L".action.move-column-right = { };

        "Mod+Home".action.focus-column-first = { };
        "Mod+End".action.focus-column-last = { };
        "Mod+Ctrl+Home".action.move-column-to-first = { };
        "Mod+Ctrl+End".action.move-column-to-last = { };

        # workspaces
        "Mod+N".action.focus-workspace-down = { };
        "Mod+P".action.focus-workspace-up = { };
        "Mod+Control+N".action.move-workspace-down = { };
        "Mod+Control+P".action.move-workspace-up = { };
        "Mod+Shift+N".action.move-column-to-workspace-down = { };
        "Mod+Shift+P".action.move-column-to-workspace-up = { };

        "Mod+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = { }; };
        "Mod+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = { }; };
        "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action.move-column-to-workspace-down = { }; };
        "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action.move-column-to-workspace-up = { }; };
        "Mod+WheelScrollRight".action.focus-column-right = { };
        "Mod+WheelScrollLeft".action.focus-column-left = { };
        "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
        "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
        "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
        "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };
      }
      # numbered workspace keys: focus / move-column / move-to-index / focus-column
      // builtins.listToAttrs (map
        (i: {
          name = "Mod+${toString i}";
          value.action.focus-workspace = i;
        }) (lib.range 1 9))
      // builtins.listToAttrs (map
        (i: {
          name = "Mod+Ctrl+${toString i}";
          value.action.move-column-to-workspace = i;
        }) (lib.range 1 9))
      // builtins.listToAttrs (map
        (i: {
          name = "Mod+Shift+${toString i}";
          value.action.move-column-to-index = i;
        }) (lib.range 1 9))
      // builtins.listToAttrs (map
        (i: {
          name = "Mod+Alt+${toString i}";
          value.action.focus-column = i;
        }) (lib.range 1 9))
      // {
        "Mod+Shift+I".action.focus-column-first = { };
        "Mod+Shift+A".action.focus-column-last = { };
        "Mod+Control+Shift+I".action.move-column-to-first = { };
        "Mod+Control+Shift+A".action.move-column-to-last = { };

        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };
        "Mod+Comma".action.consume-window-into-column = { };
        "Mod+Period".action.expel-window-from-column = { };

        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.switch-preset-window-height = { };
        "Mod+Shift+Q".action.set-column-width = "33%";
        "Mod+Shift+W".action.set-column-width = "50%";
        "Mod+Control+R".action.reset-window-height = { };
        "Mod+Shift+E".action.set-column-width = "66%";
        "Mod+D".action.maximize-column = { };
        "Mod+F".action.fullscreen-window = { };
        "Mod+Shift+F".action.toggle-windowed-fullscreen = { };
        "Mod+Control+D".action.expand-column-to-available-width = { };
        "Mod+Minus".action.set-column-width = "-4%";
        "Mod+Equal".action.set-column-width = "+4%";
        "Mod+Shift+Minus".action.set-window-height = "-4%";
        "Mod+Shift+Equal".action.set-window-height = "+4%";
        "Mod+Shift+D".action.maximize-window-to-edges = { };
        "Mod+A".action.toggle-window-floating = { };
        "Mod+Control+Tab".action.switch-focus-between-floating-and-tiling = { };
        "Mod+T".action.toggle-column-tabbed-display = { };

        "Mod+Escape" = { allow-inhibiting = false; action.toggle-keyboard-shortcuts-inhibit = { }; };
        "Ctrl+Alt+Delete".action.quit = { };
        "Mod+F3".action.power-off-monitors = { };
      };
  };
}
