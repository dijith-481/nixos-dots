# Declarative yazi file-manager configuration.
#
# Migrated from config/yazi. The three TOML files are short enough to inline;
# the vendored plugins (gvfs, system-clipboard) live in ./files and are
# linked as a directory. The timestamped keymap.toml-* backup is ignored.
{ ... }:

{
  xdg.configFile = {
    "yazi/keymap.toml".text = ''
      [mgr]
      prepend_keymap = [
          { on = "<C-y>", run = ["plugin system-clipboard"], desc = "Yank image and copy it to clipboard" },
        { on = [ "M" ], run = "plugin gvfs -- select-then-mount --jump", desc = "Select device to mount and jump to its mount" },
      { on = ["C-b"], run = "b", desc = "Bookmarks" },
        { on = [ "g", "m" ], run = "cd /run/user/1000/gvfs", desc = "Go to MTP Device" },
      ]
    '';
    "yazi/package.toml".text = ''
      [[plugin.deps]]
      use = "orhnk/system-clipboard"
      rev = "4f6942d"
      hash = "8e81a147e8ddfd992b10dd957d51a199"

      [[plugin.deps]]
      use = "boydaihungst/gvfs"
      rev = "f07b496"
      hash = "162bf7326809fb2b831d7fac7525b067"

      [flavor]
      deps = []
    '';
    "yazi/bookmarks.toml".text = ''
      [bookmarks]
      "gvfs" = "/run/user/$UID/gvfs"
    '';
    "yazi/plugins".source = ./files/yazi-plugins;
  };
}
