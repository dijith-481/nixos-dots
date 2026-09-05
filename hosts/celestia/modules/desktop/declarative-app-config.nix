# Declarative configuration for small desktop applications.
#
# Each application is managed individually below (native HM options where
# they exist, otherwise explicit per-file entries). There is intentionally
# no bulk "link all of config/" mapping anymore: config/ now only holds
# nvim (excluded from this migration by request).
#
# Raw trees too large or stateful to inline live next to this module in
# ./files (hypr scripts, cava, binary-adjacent theme assets). Short text
# configs are inlined as `text` so the module is the source of truth.
#
# Do not add application state here. Zed's settings_backup.json, Cava's
# shader downloads, and Home Manager's *.backup files are not read as
# active configuration and are intentionally not deployed.
{ config, lib, ... }:

{
  xdg.configFile = {
    # Cava reads this file at startup. The shaders/ directory rides along
    # next to it in ./files but is untracked runtime downloads, not config.
    "cava/config".source = ./files/cava/config;

    # htop rewrites htoprc when settings are changed interactively. Keeping
    # the baseline declarative is intentional; interactive changes are reset
    # on the next Home Manager activation unless committed here.
    "htop/htoprc".text = ''
      # Beware! This file is rewritten by htop when settings are changed in the interface.
      # The parser is also very primitive, and not human-friendly.
      htop_version=3.4.1-3.4.1
      config_reader_min_version=3
      fields=0 48 17 18 38 39 40 2 46 47 49 1
      hide_kernel_threads=1
      hide_userland_threads=0
      hide_running_in_container=0
      shadow_other_users=0
      show_thread_names=0
      show_program_path=1
      highlight_base_name=0
      highlight_deleted_exe=1
      shadow_distribution_path_prefix=0
      highlight_megabytes=1
      highlight_threads=1
      highlight_changes=0
      highlight_changes_delay_secs=5
      find_comm_in_cmdline=1
      strip_exe_from_cmdline=1
      show_merged_command=0
      header_margin=1
      screen_tabs=1
      detailed_cpu_time=0
      cpu_count_from_one=0
      show_cpu_usage=1
      show_cpu_frequency=0
      show_cpu_temperature=0
      degree_fahrenheit=0
      show_cached_memory=1
      update_process_names=0
      account_guest_in_cpu_meter=0
      color_scheme=0
      enable_mouse=1
      delay=15
      hide_function_bar=0
      header_layout=two_50_50
      column_meters_0=LeftCPUs4 Memory Swap
      column_meter_modes_0=1 1 1
      column_meters_1=RightCPUs4 Tasks LoadAverage Uptime
      column_meter_modes_1=1 2 2 2
      tree_view=0
      sort_key=46
      tree_sort_key=47
      sort_direction=-1
      tree_sort_direction=-1
      tree_view_always_by_pid=0
      all_branches_collapsed=0
      screen:Main=PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE PERCENT_CPU PERCENT_MEM TIME Command
      .sort_key=PERCENT_CPU
      .tree_sort_key=PERCENT_MEM
      .tree_view_always_by_pid=0
      .tree_view=0
      .sort_direction=-1
      .tree_sort_direction=-1
      .all_branches_collapsed=0
      screen:I/O=PID USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE PERCENT_SWAP_DELAY PERCENT_IO_DELAY Command
      .sort_key=IO_RATE
      .tree_sort_key=PID
      .tree_view_always_by_pid=0
      .tree_view=0
      .sort_direction=-1
      .tree_sort_direction=1
      .all_branches_collapsed=0
    '';

    # Hyprland, hypridle, hyprlock, their include files, and helper scripts
    # are one configuration tree. This is independent of the Niri module,
    # whose keybindings call into ~/.config/hypr/scripts at runtime.
    # Scripts are deployed executable so niri bindings keep working.
    "hypr".source = ./files/hypr;

    # Nord zathura theme (recolor=true). The OLED-black zathuradark variant
    # is kept beside it for manual use; it is not auto-loaded.
    "zathura/zathurarc".text = ''
      set selection-clipboard clipboard
      set incremental-search true


      #color scheme

      set notification-error-bg       "#2E3440"
      set notification-error-fg       "#BF616A"
      set notification-warning-bg     "#2E3440"
      set notification-warning-fg     "#D08770"
      set notification-bg             "#2E3440"
      set notification-fg             "#D8DEE9"

      set completion-bg               "#2E3440"
      set completion-fg               "#D8DEE9"
      set completion-group-bg         "#3B4252"
      set completion-group-fg         "#D8DEE9"
      set completion-highlight-bg     "#88C0D0"
      set completion-highlight-fg     "#3B4252"

      set index-bg                    "#2E3440"
      set index-fg                    "#8FBCBB"
      set index-active-bg             "#8FBCBB"
      set index-active-fg             "#2E3440"

      set inputbar-bg                 "#2E3440"
      set inputbar-fg                 "#E5E9F0"

      set statusbar-bg                "#2E3440"
      set statusbar-fg                "#E5E9F0"

      set highlight-color             "#D08770"
      set highlight-active-color      "#BF616A"

      set default-bg                  "#2E3440"
      set default-fg                  "#D8DEE9"
      set render-loading              "true"
      set render-loading-bg           "#2E3440"
      set render-loading-fg           "#434C5E"

      set recolor-lightcolor          "#2E3440"
      set recolor-darkcolor           "#ECEFF4"
      set recolor                     "true"
    '';
    "zathura/zathuradark".source = ./files/zathuradark;

    "wofi/config".text = ''
      [config]
      allow_images=false
      width=700
      show=drun
      prompt=Search
      height=388
      always_parse_args=true
      show_all=true
      term=foot
      hide_scroll=true
      print_command=true
      insensitive=true
      columns=1
    '';
    # The old file imported /home/dijith/dotfiles/colors/nord-colors.css,
    # which no longer exists. Import the HM-deployed copy instead.
    "wofi/style.css".text = ''
      @import url("${config.home.homeDirectory}/.config/colors/nord-colors.css");

      @keyframes fadeIn {
        0% {
        }
        100% {
        }
      }

      * {
        font-family: "MesloLGS Nerd Font", monospace;
        font-size: 12px;
        outline: none;
        text-shadow: none;
      }

      window {
        border: 3px solid;
        border-radius: 8px;
        background-color: @background;
        border-color: @nord3;
      }
      #inner-box {
        /* padding: 10px; */
        /* background-color: ; */
      }
      #outer-box {
        /* border: none; */
      }
      #scroll {
        /* margin: 0px; */
        padding: 20px;
        border: none;
      }
      #input {
        margin-left: 10px;
        margin-right: 10px;
        margin-top: 10px;
        padding: 10px;
        border: none;
        outline: none;
        color: @nord4;

        /* box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.5); */
        border-radius: 8px;
        background-color: @nord3;
      }
      #input image {
        background-color: transparent;
        border: none;
        color: @nord4;
      }
      #input * {
        border: none;
        outline: none;
      }

      #input:focus {
        outline: none;
        border: 3px solid;
        border-color: @nord9;
        border-radius: 8;
      }
      #text {
        margin: 5px;
        border: none;
        color: @nord4;
        outline: none;
      }
      #entry {
        border: none;
        border-radius: 8px;
        margin: 5px;
        padding-left: 10px;
      }
      #entry arrow {
        border: none;
        color: @nord4;
      }
      #entry:selected {
        border-color: @nord9;
        padding: 10px;
        background-color: @nord3;
      }
      #entry:selected #text {
        background-color: transparent;
        color: @nord4;
      }

      #entry:selected image {
        background-color: transparent;
      }
      /* #entry:drop(active) { */
      /*   background-color: @nord11 !important; */
      /* } */
    '';

    # paru is an Arch-only helper (not installed on NixOS); keep its
    # BottomUp + yazi file-manager config verbatim for Arch machines.
    "paru/paru.conf".text = ''
      #
      # $PARU_CONF
      # /etc/paru.conf
      # ~/.config/paru/paru.conf
      #
      # See the paru.conf(5) manpage for options

      #
      # GENERAL OPTIONS
      #
      [options]
      # PgpFetch
      # Devel
      # Provides
      # DevelSuffixes = -git -cvs -svn -bzr -darcs -always -hg -fossil
      #AurOnly
      BottomUp
      #RemoveMake
      #SudoLoop
      #UseAsk
      #SaveChanges
      #CombinedUpgrade
      #CleanAfter
      #UpgradeMenu
      #NewsOnUpgrade

      #LocalRepo
      #Chroot
      #Sign
      #SignDb
      #KeepRepoCache

      #
      # Binary OPTIONS
      #
      [bin]
      FileManager = yazi
      #MFlags = --skippgpcheck
      #Sudo = doas
    '';

    # Zed only consumes these two files. settings_backup.json was a manual
    # backup and is intentionally not installed as part of the live config.
    "zed/settings.json".text = ''
      {
        "edit_predictions": {
          "mode": "eager",
          "copilot": {
            "proxy": null,
            "proxy_no_verify": null,
            "enterprise_uri": null
          },
          "enabled_in_text_threads": false
        },
        "agent": {
          "model_parameters": [],
          "default_model": {
            "provider": "zed.dev",
            "model": "claude-sonnet-4"
          }
        },
        "project_panel": {
          "dock": "left"
        },
        "features": {
          "edit_prediction_provider": "supermaven"
        },
        "icon_theme": "Material Icon Theme",
        "telemetry": {
          "metrics": false,
          "diagnostics": false
        },
        "vim_mode": true,
        "base_keymap": "VSCode",
        "ui_font_size": 16,
        "buffer_font_size": 16,
        "theme": {
          "mode": "system",
          "light": "Nord",
          "dark": "Nord"
        }
      }
    '';
    "zed/keymap.json".text = ''
      // Zed keymap
      //
      // For information on binding keys, see the Zed
      // documentation: https://zed.dev/docs/key-bindings
      //
      // To see the default key bindings run `zed: open default keymap`
      // from the command palette.
      [
        {
          "context": "Workspace",
          "bindings": {
            // "shift shift": "file_finder::Toggle"
          }
        },
        {
          "context": "vim_mode == insert && showing_completions",
          "bindings": {
            "ctrl-y": "editor::ComposeCompletion"
          }
        },
        {
          "context": "vim_mode == normal",
          "bindings": {
            "space f f": "file_finder::Toggle",
            "space f r": "projects::OpenRecent",

            "space w h": "pane::SplitHorizontal", // split window horizontally
            "space w v": "pane::SplitVertical", // split window vertically
            "ctrl-l": "workspace::ActivatePaneRight",
            "ctrl-h": "workspace::ActivatePaneLeft",
            "ctrl-k": "workspace::ActivatePaneUp",
            "ctrl-j": "workspace::ActivatePaneDown",

            // "space": "command_palette::Toggle", // leader key
            "space f o": "workspace::Open", // open a project in a new window
            "space f s": "workspace::Save", // save file
            "space b b": "tab_switcher::Toggle", // switch to another open file
            "space b l": "pane::AlternateFile", // switch to last focused buffer
            "space s p": "workspace::NewSearch", // search the current project
            "space a c": "agent::ToggleFocus", // open assistant chat
            "space p s": "project_panel::ToggleFocus", // open project structure
            "space s v": "outline::Toggle", // find variables in the current file
            "space w m m": "workspace::ToggleZoom", // maximize current buffer
            "space t t": "terminal_panel::ToggleFocus", // open terminal
            "space w d": "pane::CloseActiveItem", // close current window
            "space s s": "buffer_search::Deploy" // search current buffer
          }
        },
        {
          "context": "Terminal",
          "bindings": {
            "space t t": "pane::CloseActiveItem" // close the terminal
          }
        },
        {
          "context": "Editor && vim_mode == normal",
          "bindings": {
            " f f": "file_finder::Toggle",
            "  f g": "pane::DeploySearch"
          }
        },

        {
          "context": "Editor && vim_mode == normal",
          "bindings": {
            " c r": "editor::Rename",
            ", c a": "editor::ToggleCodeActions",
            "shift-k": "editor::Hover",
            "g d": "editor::GoToDefinition"
          }
        },
        {
          "context": "Editor",
          "bindings": {
            // "j k": ["workspace::SendKeystrokes", "escape"]
          }
        }
      ]
    '';

    # Shared theme assets. Use individual files so ignored *.backup copies
    # can never be deployed accidentally.
    "colors/nord-colors.css".source = ./files/nord-colors.css;
    "colors/colors.txt".source = ./files/colors.txt;
    "colors/ytm.json".source = ./files/ytm.json;

    "opencode/opencode.jsonc".text = ''
      {
        "$schema": "https://opencode.ai/config.json",
        "lsp": false,
        "mcp": {
          "clickup": {
            "type": "remote",
            "url": "https://mcp.clickup.com/mcp",
            "enabled": true
          }
        }
      }
    '';
    "fum/config.jsonc".text = ''
      {
      	"use_active_player": true,
      	"debug": false,
      	"width": 40,
      	"height": 10,
      	"layout": [
      		{
      			"type": "container",
      			// "width": 20,
      			// "height": 20,
      			// "border": false,
      			// "padding": [
      			// 0,
      			// 0
      			// ],
      			"direction": "horizontal",
      			"flex": "start",
      			"children": [
      				{
      					"type": "cover-art",
      					"padding": [
      						5,
      						5
      					]
      				},
      				{
      					"type": "empty",
      					"size": 1
      				},
      				{
      					"type": "container",
      					"direction": "vertical",
      					"children": [
      						{
      							"type": "label",
      							"text": "$title",
      							"align": "center"
      						},
      						{
      							"type": "label",
      							"text": "$artists",
      							"align": "center"
      						},
      						{
      							"type": "empty",
      							"size": 1
      						},
      						{
      							"type": "container",
      							"height": 1,
      							"flex": "space-around",
      							"children": [
      								{
      									"type": "button",
      									"text": "󰒮",
      									"action": "prev()"
      								},
      								{
      									"type": "button",
      									"text": "$status-icon",
      									"action": "play_pause()"
      								},
      								{
      									"type": "button",
      									"text": "󰒭",
      									"action": "next()"
      								}
      							]
      						},
      						{
      							"type": "empty",
      							"size": 1
      						},
      						{
      							"type": "progress",
      							"progress": {
      								"char": "󰝤"
      							},
      							"empty": {
      								"char": "󰁱"
      							}
      						},
      						{
      							"type": "container",
      							"height": 1,
      							"flex": "space-between",
      							"children": [
      								{
      									"type": "label",
      									"text": "$position",
      									"align": "left"
      								},
      								{
      									"type": "label",
      									"text": "$length",
      									"align": "right"
      								}
      							]
      						}
      					]
      				}
      			]
      		}
      	]
      }
    '';

    # Rewrite rules for the niri taskbar module. No in-repo consumer
    # references it besides the old bulk link; keep the bytes verbatim so
    # any external consumer keeps working.
    "niri_taskbar_module/config.json".text = ''
      {
        "rewrite-rules": {
          "^(foot)$": "  Foot",
          "^.*tmux.*$": " ",
          "^.*zathura.*$": " ",
          "^.*nvim.*$": "",
          "^.*Brave.*$": " ",
          "^.*(Zen Browser).*$": " ",
          "^(.*Google AI Studio.*)$": " ",
          ".*YouTube Music.*": "YT Music",
          "^~$": " "
        },
        "ignore-list": ["Peek", "some_other_app_to_ignore"],
        "app-ids-mapping": {
          "firefoxdeveloperedition": "firefox-developer-edition",
          "org.mozilla.firefox": "firefox"
        }
      }
    '';

    # qt5ct/qt6ct .conf files were dangling symlinks into a dead
    # home-manager generation (machine-generated GUI state, content lost).
    # Only the hand-written Nord style colors are worth keeping.
    "qt5ct/style-colors.conf".text = ''
      [ColorScheme]
      active_colors=#ffeceff4, #ff4c566a, #ffeceff4, #ffeceff4, #ff2e3440, #ff2e3440, #ffeceff4, #ffffffff, #ffeceff4, #ff2e3440, #ff2e3440, #ff000000, #ff5e81ac, #ffeceff4, #ff81a1c1, #ff8fbcbb, #ff2e3440, #ffffffff, #ff000000, #ffeceff4, #80eceff4
      disabled_colors=#ffd8dee9, #ff4c566a, #ffeceff4, #ffeceff4, #ff2e3440, #ff2e3440, #ffd8dee9, #ffffffff, #ffd8dee9, #ff2e3440, #ff2e3440, #ff000000, #ff5e81ac, #66eceff4, #ff81a1c1, #ff8fbcbb, #ff2e3440, #ffffffff, #ff000000, #ffeceff4, #80eceff4
      inactive_colors=#ffeceff4, #ff4c566a, #ffeceff4, #ffeceff4, #ff2e3440, #ff2e3440, #ffeceff4, #ffffffff, #ffeceff4, #ff2e3440, #ff2e3440, #ff000000, #ff5e81ac, #ffeceff4, #ff81a1c1, #ff8fbcbb, #ff2e3440, #ffffffff, #ff000000, #ffeceff4, #80eceff4
    '';
    "qt6ct/style-colors.conf".text = ''
      [ColorScheme]
      active_colors=#ffeceff4, #ff4c566a, #ffeceff4, #ffeceff4, #ff2e3440, #ff2e3440, #ffeceff4, #ffffffff, #ffeceff4, #ff2e3440, #ff2e3440, #ff000000, #ff5e81ac, #ffeceff4, #ff81a1c1, #ff8fbcbb, #ff2e3440, #ff000000, #ff000000, #ffeceff4, #80eceff4, #ff308cc6
      disabled_colors=#ffbebebe, #ffefefef, #ffffffff, #ffcacaca, #ffbebebe, #ffb8b8b8, #ffbebebe, #ffffffff, #ffbebebe, #ffefefef, #ffefefef, #ffb1b1b1, #ff919191, #ffffffff, #ff0000ff, #ffff00ff, #fff7f7f7, #ff000000, #ffffffdc, #ff000000, #80000000, #ff919191
      inactive_colors=#ffeceff4, #ff4c566a, #ffeceff4, #ffeceff4, #ff2e3440, #ff2e3440, #ffeceff4, #ffffffff, #ffeceff4, #ff2e3440, #ff2e3440, #ff000000, #ff5e81ac, #ffeceff4, #ff81a1c1, #ff8fbcbb, #ff2e3440, #ff000000, #ff000000, #ffeceff4, #80eceff4, #ff308cc6
    '';
  };

  # OpenCode writes history, logs, and runtime state (such as
  # service.json.tmp) inside its config directory, so give it a writable
  # directory with immutable per-file links (moved here from home.nix so
  # this module fully owns the app).
  home.activation.prepareWritableConfigDirectories =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      cfgPath="${config.home.homeDirectory}/.config/opencode"
      if [ -L "$cfgPath" ]; then
        $DRY_RUN_CMD unlink "$cfgPath"
      fi
      $DRY_RUN_CMD mkdir -p "$cfgPath"
    '';
}
