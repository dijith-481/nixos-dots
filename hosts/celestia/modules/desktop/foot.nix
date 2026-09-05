# Declarative foot terminal configuration.
#
# Migrated from config/foot/foot.ini. Only the active (uncommented) settings
# are declared; everything else was upstream commented defaults.
# tplay.ini is a separate alternate profile used by the fish `tplay`
# function (foot -c ~/.config/foot/tplay.ini) and is kept byte-for-byte.
{ ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        title = "foot";
        font = "Iosevka Nerd Font:size=12";
        dpi-aware = "no";
      };
      scrollback = {
        lines = "10000";
      };
      cursor = {
        style = "beam";
        blink = "no";
        beam-thickness = "1.5";
      };
      colors = {
        alpha = "1";
        foreground = "d8dee9";
        background = "191d24";
        # The file set selection-background twice (81a1c1, then 2F4135);
        # the later value wins and is the one declared here.
        selection-foreground = "D8E9DC";
        selection-background = "2F4135";
        regular0 = "3b4252";
        regular1 = "bf616a";
        regular2 = "81a1c1";
        regular3 = "ebcb8b";
        regular4 = "a3be8c";
        regular5 = "b48ead";
        regular6 = "88c0d0";
        regular7 = "e5e9f0";
        bright0 = "4c566a";
        bright1 = "bf616a";
        bright2 = "a3be8c";
        bright3 = "ebcb8b";
        bright4 = "81a1c1";
        bright5 = "b48ead";
        bright6 = "8fbcbb";
        bright7 = "eceff4";
        dim0 = "373e4d";
        dim1 = "94545d";
        dim2 = "809575";
        dim3 = "b29e75";
        dim4 = "68809a";
        dim5 = "8c738c";
        dim6 = "6d96a5";
        dim7 = "aeb3bb";
        search-box-no-match = "11111b f38ba8";
        search-box-match = "cdd6f4 313244";
        jump-labels = "11111b fab387";
        urls = "89BFEB";
      };
    };
  };

  xdg.configFile."foot/tplay.ini".source = ./files/foot-tplay.ini;
}
