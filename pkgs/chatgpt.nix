# ChatGPT Desktop for Linux — official .deb (Electron)
# https://learn.chatgpt.com/docs/linux/linux-app
# Supported: Ubuntu 24.04/26.04, Debian 13, Fedora 43/44
# Here packaged for NixOS via dpkg + autoPatchelfHook.
# Bump `version` + both hashes together on updates.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  libnotify,
  libsecret,
  libuuid,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxshmfence,
  libgbm,
  libusb1,
  libXScrnSaver,
  libXtst,
  # optional trash providers mapped from Depends alternatives
  glibSupport ? true,
}:

stdenv.mkDerivation rec {
  pname = "chatgpt";
  version = "26.820.60940";

  # Prefer "latest" URLs — they are stable and always point to current release.
  # Hashes pinned via `nix store prefetch-file`.
  src =
    let
      hashes = {
        x86_64-linux = "sha256-MdlWqMbFFfjYfgt6zZ7JGffmhbpZMxtLl6pF+FOv39c=";
        aarch64-linux = "sha256-j02sv/XwVKT2nCoCHxOWxXl2lygpphBB/rrBtCPyfIY=";
      };
      urls = {
        x86_64-linux = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
        aarch64-linux = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_arm64.deb";
      };
      system = stdenv.hostPlatform.system;
    in
    if builtins.hasAttr system hashes then
      fetchurl {
        url = urls.${system};
        hash = hashes.${system};
      }
    else
      throw "chatgpt: unsupported system ${system} (only x86_64-linux and aarch64-linux)";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libxkbcommon
    libnotify
    libsecret
    libuuid
    mesa
    nspr
    nss
    pango
    systemd
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxshmfence
    libgbm
    libusb1
    libXScrnSaver
    libXtst
  ];

  # autoPatchelfHook needs runtime deps that are dlopened
  runtimeDependencies = [
    systemd
    libnotify
    libsecret
  ];

  # Qt shims and musl prebuilds are optional dlopens — not required for normal launch
  autoPatchelfIgnoreMissingDeps = [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libc.musl-x86_64.so.1"
  ];

  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    # The deb extracts to ./usr — move to $out
    cp -r usr/* $out/
    # Also keep lib at $out/lib (deb uses /usr/lib/chatgpt)
    # $out now has bin/ share/ lib/
    # dpkg also extracts ./etc (apparmor) — we don't install it system-wide
    # Clean up etc if present
    rm -rf $out/etc 2>/dev/null || true

    # Icons already at $out/share/pixmaps/chatgpt.png — also link to hicolor
    mkdir -p $out/share/icons/hicolor/512x512/apps
    if [ -f $out/share/pixmaps/chatgpt.png ]; then
      ln -sf $out/share/pixmaps/chatgpt.png $out/share/icons/hicolor/512x512/apps/chatgpt.png
    fi

    # Fix desktop file Exec path and add Wayland flags comment
    if [ -f $out/share/applications/chatgpt.desktop ]; then
      substituteInPlace $out/share/applications/chatgpt.desktop \
        --replace "Exec=chatgpt" "Exec=$out/bin/chatgpt"
    fi

    # The original binary is $out/lib/chatgpt/ChatGPT (ELF)
    # and $out/bin/chatgpt is a symlink -> ../lib/chatgpt/codex-launcher (-> ChatGPT)
    # Replace the symlink with a wrapper that handles Wayland/Ozone and sandbox
    rm -f $out/bin/chatgpt
    makeWrapper $out/lib/chatgpt/ChatGPT $out/bin/chatgpt \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --set ELECTRON_DISABLE_SANDBOX 1

    # Also wrap the actual binary so direct exec works (autoPatchelf already patched rpath)
    # Keep ChatGPT binary wrapped for LD_LIBRARY_PATH fallback
    wrapProgram $out/lib/chatgpt/ChatGPT \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # Chromium helper needs suid sandbox — we disable sandbox via flag above; ensure no setuid needed
    # Fix permissions
    chmod +x $out/lib/chatgpt/*.so* 2>/dev/null || true
    chmod +x $out/lib/chatgpt/ChatGPT 2>/dev/null || true

    runHook postInstall
  '';

  meta = with lib; {
    description = "ChatGPT desktop app for Linux (official Electron build)";
    homepage = "https://chatgpt.com/download";
    downloadPage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [];
  };
}
