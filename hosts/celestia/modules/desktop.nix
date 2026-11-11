{ config, lib, pkgs, inputs, ... }:
{

  home.packages = with pkgs;[
    obsidian
    # Native Wayland is selected by NIXOS_OZONE_WL. Keep Chromium's tested GPU
    # defaults instead of forcing Vulkan, syncobj, multiplane and blocklist bypasses.
    brave
    google-chrome

    # zen twilight only — stable removed (twilight supersedes it)
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".twilight
    inputs.delta.packages."${pkgs.stdenv.hostPlatform.system}".delta
    zathura
    localsend
    seahorse
    libsecret
    nautilus
    helvum




    gtk3
    gtk4
    glib

    vulkan-tools

    xwayland-satellite

    zip
    xz
    unzip
    p7zip

    jq

    bluez
    bluetui
    powertop
    yazi
    xdg-desktop-portal-termfilechooser
    qview
    # inkscape
    mpv
    ffmpeg
    v4l-utils
  ];

  # Shadow Zen's upstream desktop entry (Exec=zen-twilight, a bare name) with one
  # that uses an absolute store path. Apps launched with a minimal PATH (e.g. the
  # Claude desktop app's xdg-open calls) can't find the per-user profile bin, so
  # xdg-open skipped Zen and fell back to Brave, whose entry is absolute.
  xdg.desktopEntries.zen-twilight =
    let
      zenBin = "${inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".twilight}/bin/zen-twilight";
    in
    {
      name = "Zen Browser (Twilight)";
      genericName = "Web Browser";
      exec = "${zenBin} --name zen-twilight %U";
      icon = "zen-twilight";
      terminal = false;
      startupNotify = true;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      settings.StartupWMClass = "zen-twilight";
      actions = {
        new-private-window = { name = "New Private Window"; exec = "${zenBin} --private-window %U"; };
        new-window = { name = "New Window"; exec = "${zenBin} --new-window %U"; };
        profile-manager-window = { name = "Profile Manager"; exec = "${zenBin} --ProfileManager"; };
      };
    };
}
