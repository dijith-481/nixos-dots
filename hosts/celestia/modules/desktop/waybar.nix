{ config, lib, pkgs, ... }:

let
  dunstScript = pkgs.writeShellScript "waybar-dunst" ''
    count=$(${pkgs.dunst}/bin/dunstctl count waiting)
    enabled="   "
    disabled="   "
    if [ "$count" != 0 ]; then
      disabled=" 󰂝  $count"
    fi
    if ${pkgs.dunst}/bin/dunstctl is-paused | ${pkgs.gnugrep}/bin/grep -q "false"; then
      echo "$enabled"
    else
      echo "$disabled"
    fi
  '';

  # Keep the bar's Nord palette self-contained.  The old CSS imported this
  # from ../colors/nord-colors.css, which made the Waybar config depend on a
  # second mutable config tree.
  nordColors = ''
    @define-color foreground #81a1c1;
    @define-color background #191d24;
    @define-color cursor #d8dee9;
    @define-color nord0 #2e3440;
    @define-color nord1 #3b4252;
    @define-color nord2 #434c5e;
    @define-color nord3 #4c566a;
    @define-color nord4 #d8dee9;
    @define-color nord5 #e5e9f0;
    @define-color nord6 #eceff4;
    @define-color nord7 #8fbcbb;
    @define-color nord8 #88c0d0;
    @define-color nord9 #81a1c1;
    @define-color nord10 #5e81ac;
    @define-color nord11 #bf616a;
    @define-color nord12 #d08770;
    @define-color nord13 #ebcb8b;
    @define-color nord14 #a3be8c;
    @define-color nord15 #b48ead;
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        reload_style_on_change = true;
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "mpris" ];
        modules-right = [
          "custom/dunst"
          "tray"
          "clock"
          "backlight"
          "wireplumber"
          "bluetooth"
          "network"
          "power-profiles-daemon"
          "battery"
        ];

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            browser = "󰈹";
            ytmusic = "󱖏";
            nvim = "<b></b>";
            active = "";
            default = "";
          };
        };

        # Kept for easy compositor switching, as in the original JSONC.
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "";
            empty = "";
            active = "";
          };
          persistent-workspaces."*" = [ 1 2 3 4 ];
        };

        wireplumber = {
          format = "{volume}% {icon} ";
          format-muted = "  ";
          on-click = "helvum";
          max-volume = 150;
          scroll-step = 0.2;
          format-icons = [ "" "" ];
        };

        clock = {
          format = "󰥔 {:%H:%M 󰃭 %e %b}";
          format-alt = "󰥔 {:%H:%M 󰃭 %e %b %a}";
          interval = 60;
          tooltip-format = "<tt>{calendar}</tt>";
          calendar.format = {
            months = "<span color='#4c566a'><b>{}</b></span>";
            weekdays = "<span color='#81a1c1'><b>{}</b></span>";
            days = "<span color='#d8dee9'><b>{}</b></span>";
            today = "<span  color='#a3be8c'><b>{}</b></span>";
          };
          actions = {
            on-click-right = "shift_down";
            on-click = "shift_up";
          };
        };

        network = {
          format-wifi = " ";
          format-ethernet = " 󰛳 ";
          format-disconnected = "  ";
          tooltip-format-disconnected = "Error";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          tooltip-format-ethernet = "{ifname} 🖧 ";
          on-click = "kitty --class float -e 'nmtui'";
        };

        bluetooth = {
          format-on = " 󰂯 ";
          format-off = "BT-off";
          format-disabled = " 󰂲 ";
          format-connected = "󰂱 ";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\n{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias} {device_battery_percentage}%";
          on-click = "kitty --class float -e 'bluetui'";
        };

        backlight = {
          device = "intel_backlight";
          format = " {percent}% {icon} ";
          scroll-step = 3;
          format-icons = [ "󰃞" "󰃝" "󰃠" ];
        };

        battery = {
          interval = 30;
          states = {
            good = 75;
            warning = 30;
            critical = 20;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% 󰂄";
          format-plugged = " 󰚥 ";
          tooltip-format = "{capacity}% {power} 󱐋 {timeTo} {cycles} 󰤁 {health} 󱈑 ";
          format-alt = "{time} {icon}";
          format-icons = [ "󰁻" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
        };

        # This remains a live Waybar module backed by power-profiles-daemon.
        "power-profiles-daemon" = {
          format = "{icon} {profile}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}\nClick to cycle profiles; Fn+Q also updates live";
          format-icons = {
            performance = "󰓅";
            balanced = "󰾅";
            power-saver = "󰌪";
            default = "󰾅";
          };
        };

        mpris = {
          format = "{player_icon}{artist} | {title}";
          player-icons = {
            kdeconnect = " ";
            brave = " ";
            default = "";
          };
          format-paused = " {artist} {title}";
          on-click-right = "playerctld shift";
          tooltip-format = "{album}|{player}";
        };

        "custom/dnd" = {
          exec = "dunstctl is-paused | jq --unbuffered --compact-output '{alt: ., class: .}'";
          return-type = "json";
          interval = "once";
          on-click = "dunstctl set-paused toggle && sleep 5";
          exec-on-event = true;
          tooltip = false;
          format = "{icon}";
          format-icons = {
            true = " ";
            false = "󰪑 ";
            default = "󱙏 ";
          };
        };

        "wlr/taskbar" = {
          format = "{title}";
          tooltip-format = "{title}";
          on-click = "activate";
          all-outputs = false;
          on-click-middle = "close";
          ignore-list = [ "Alacritty" ];
          app_ids-mapping.firefoxdeveloperedition = "firefox-developer-edition";
          rewrite."^.*nvim.*$" = "";
        };

        "custom/dunst" = {
          exec = dunstScript;
          on-click = "dunstctl set-paused toggle";
          restart-interval = 1;
        };
      };
    };

    style = ''
      ${nordColors}

      * {
        font-size: 14px;
        font-family: "MesloLGS Nerd Font";
      }
      #waybar {
        font-weight: bold;
      }
      window#waybar {
        all: unset;
        background-color: @background;
      }
      /* #clock:hover, */
      /* #bluetooth:hover, */
      /* #network:hover, */
      /* #backlight:hover, */
      /* #battery:hover, */
      /* #tray:hover { */
      /* background-color: @nord3; */
      /* } */
      .modules-left {
      }
      .modules-center {
      }
      .modules-right {
      }
      tooltip {
        background: @background;
        color: @color7;
      }
      #clock,
      #bluetooth,
      #custom-dunst,
      #network,
      #backlight,
      #battery,
      #power-profiles-daemon,
      #workspaces,
      #tray,
      #wireplumber {
        margin: 4px 2px;
        padding: 2px 4px;
        border-radius: 3px;
        background-color: @nord0;
        color: @color7;
        transition: all 0.3s ease;
      }

      #mpris {
        margin: 0 2px;
        font-weight: 800;
        color: @nord9;
      }

      #custom-niri-taskbar,
      #workspaces {
        padding: 2px 4px;
        background-color: transparent;
      }
      #workspaces button {
        all: unset;
        padding: 0 8px;
        color: @nord3;
      }
      #workspaces button:hover {
        color: @nord4;
        border: none;
        transition: all 1s ease;
      }
      #workspaces button.active {
        color: @nord9;
        border: none;
      }
      #workspaces button.empty {
        color: @nord2;
        border: none;
      }
      #workspaces button.empty:hover {
        color: @nord4;
        border: none;
        transition: all 1s ease;
      }
      #workspaces button.empty.active {
        color: @nord12;
        border: none;
      }
      #bluetooth {
        color: @nord4;
      }
      #wireplumber.muted {
        background-color: @nord11;
      }
      #wireplumber {
        color: @nord4;
      }
      #bluetooth.connected {
        color: @nord1;
        background-color: @nord4;
      }
      #network.ethernet,
      #network.wifi {
        color: @nord1;
        background-color: @nord4;
      }
      #network.disconnected {
        color: @nord1;
        background-color: @nord11;
      }
      #battery {
        margin-right: 8px;
        background-color: @nord15;
        color: @nord0;
      }
      #battery.good {
        background-color: @nord14;
      }
      #battery.warning {
        background-color: @nord12;
      }
      #battery.critical {
        background-color: @nord11;
      }
      #battery.plugged {
        background-color: @nord9;
      }
      #battery.charging {
        background-color: @nord13;
      }

      #power-profiles-daemon.performance {
        background-color: @nord11;
        color: @nord0;
      }
      #power-profiles-daemon.balanced {
        background-color: @nord13;
        color: @nord0;
      }
      #power-profiles-daemon.power-saver {
        background-color: @nord14;
        color: @nord0;
      }
    '';
  };
}
