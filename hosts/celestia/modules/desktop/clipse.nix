{ config, lib, ... }:

let
  stateDir = "${config.xdg.stateHome}/clipse";
  cacheDir = "${config.xdg.cacheHome}/clipse";
  oldConfigDir = "${config.home.homeDirectory}/.config/clipse";
in
{
  services.clipse = {
    enable = true;
    settings = {
      maxHistory = 1300;
      historyFile = "${stateDir}/clipboard_history.json";
      logFile = "${stateDir}/clipse.log";
      themeFile = "custom_theme.json";
      tempDir = "${cacheDir}/tmp_files";
      keyBindings = {
        choose = "enter";
        clearSelected = "S";
        down = "down";
        end = "end";
        filter = "/";
        home = "home";
        more = "?";
        nextPage = "right";
        prevPage = "left";
        preview = " ";
        quit = "q";
        remove = "x";
        selectDown = "ctrl+down";
        selectSingle = "s";
        selectUp = "ctrl+up";
        togglePin = "p";
        togglePinned = "tab";
        up = "up";
        yankFilter = "ctrl+s";
      };
      imageDisplay = {
        type = "kitty";
        scaleX = 14;
        scaleY = 14;
        heightCut = 2;
      };
    };

    theme = {
      useCustomTheme = true;
      TitleFore = "#d8dee9";
      TitleBack = "#81a1c1";
      TitleInfo = "#88c0d0";
      NormalTitle = "#d8dee9";
      DimmedTitle = "#4c566a";
      SelectedTitle = "#81a1c1";
      NormalDesc = "#d8dee9";
      DimmedDesc = "#4c566a";
      SelectedDesc = "#81a1c1";
      StatusMsg = "#a3be8c";
      PinIndicatorColor = "#ebcb8b";
      SelectedBorder = "#88c0d0";
      SelectedDescBorder = "#88c0d0";
      FilteredMatch = "#d8dee9";
      FilterPrompt = "#a3be8c";
      FilterInfo = "#88c0d0";
      FilterText = "#d8dee9";
      FilterCursor = "#ebcb8b";
      HelpKey = "#d8dee9";
      HelpDesc = "#808080";
      PageActiveDot = "#88c0d0";
      PageInactiveDot = "#4c566a";
      DividerDot = "#88c0d0";
      PreviewedText = "#d8dee9";
      PreviewBorder = "#88c0d0";
    };
  };

  # Clipse writes its history itself.  Move the previous mutable file into
  # XDG state during the first activation; do not copy or inspect its content.
  # This also works when the old config directory contains HM-managed links.
  home.activation.migrateClipseHistory = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    oldHistory=${lib.escapeShellArg "${oldConfigDir}/clipboard_history.json"}
    newStateDir=${lib.escapeShellArg stateDir}
    newHistory=${lib.escapeShellArg "${stateDir}/clipboard_history.json"}

    if [ -f "$oldHistory" ] && [ ! -e "$newHistory" ]; then
      $DRY_RUN_CMD mkdir -p "$newStateDir"
      $DRY_RUN_CMD mv "$oldHistory" "$newHistory"
    fi
  '';
}
