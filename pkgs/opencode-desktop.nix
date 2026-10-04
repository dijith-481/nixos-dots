# OpenCode Desktop for Linux — pinned official .deb (Electron)
# https://opencode.ai/download
# e.g. https://opencode.ai/files/bin/2.0.6/opencode-desktop-linux-amd64.deb
#
# Packaged for NixOS via dpkg + autoPatchelfHook, mirroring pkgs/chatgpt.nix.
#
# IMPORTANT:
# - Keep version + hash in sync when updating.
# - Uses a versioned URL for reproducibility.
# - Removes incompatible musl/foreign prebuilds before autoPatchelf.
# - The upstream electron-builder config uses productName "OpenCode" and
#   executableName "ai.opencode.desktop", so the app lands in /opt/OpenCode.
{
  lib,
  stdenv,
  fetchurl,

  # Native build tools
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,

  # Runtime/build libraries
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
}:

stdenv.mkDerivation rec {
  pname = "opencode-desktop";
  version = "2.0.6";

  src = fetchurl {
    url = "https://opencode.ai/files/bin/${version}/opencode-desktop-linux-amd64.deb";
    hash = "sha256-Ze8EVYV7upzvdvh2uf5xFUenvSlF58Tvby+PYvYW5Ig=";
  };

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

  # Libraries Electron / native modules may dlopen at runtime.
  runtimeDependencies = [
    systemd
    libnotify
    libsecret
    libGL
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"

    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"

    "libc.musl-x86_64.so.1"
    "libc.musl-aarch64.so.1"
  ];

  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack

    dpkg-deb -x "$src" .

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    # The .deb extracts to ./opt/OpenCode and ./usr/share (+ ./usr/bin symlink).
    if [ -d usr ]; then
      cp -a usr/. "$out/"
    fi
    if [ -d opt ]; then
      cp -a opt "$out/"
    fi

    appdir="$out/opt/OpenCode"
    mainbin="$appdir/ai.opencode.desktop"
    resources="$appdir/resources"

    if [ ! -x "$mainbin" ] || [ ! -d "$resources" ]; then
      echo "ERROR: unexpected OpenCode Desktop layout" >&2
      echo "expected mainbin=$mainbin resources=$resources" >&2
      ls -R "$out/opt" >&2 || true
      exit 1
    fi

    # Keep only native prebuilds compatible with this host.
    find "$resources" \
      -type d \
      -name prebuilds \
      -print0 \
      | while IFS= read -r -d "" prebuildsPath; do

          find "$prebuildsPath" \
            -mindepth 1 \
            -maxdepth 1 \
            ! -name "*${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}" \
            -exec rm -rf -- {} +
        done

    # Catch packages using filenames such as foo.musl.node.
    find "$resources" \
      -type f \
      -name '*.musl.node' \
      -delete

    # Catch musl directories outside a conventional prebuilds directory.
    find "$resources" \
      -depth \
      -type d \
      -name '*-musl' \
      -exec rm -rf -- {} +

    # The .deb may include AppArmor/etc files. Don't install these directly
    # into the immutable Nix package output.
    rm -rf "$out/etc"

    # Upstream ships /usr/bin/ai.opencode.desktop as an absolute symlink into
    # /opt; replace it with a Nix-store aware wrapper.
    rm -f "$out/bin/ai.opencode.desktop"
    mkdir -p "$out/bin"

    makeWrapper \
      "$mainbin" \
      "$out/bin/opencode-desktop" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set ELECTRON_DISABLE_SANDBOX 1

    # Upstream desktop entries use Exec=ai.opencode.desktop (the electron-builder
    # executableName). Provide that name too so they resolve without patching.
    ln -sfn opencode-desktop "$out/bin/ai.opencode.desktop"

    wrapProgram "$mainbin" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    chmod +x "$mainbin"
    chmod +x "$out/bin/opencode-desktop"

    if [ -f "$appdir/chrome-sandbox" ]; then
      chmod +x "$appdir/chrome-sandbox" || true
    fi

    # Point any upstream desktop entries at the Nix-store wrapper.
    find "$out/share/applications" -name '*.desktop' -type f 2>/dev/null \
      | while IFS= read -r desktop; do
          substituteInPlace "$desktop" \
            --replace "Exec=ai.opencode.desktop" "Exec=$out/bin/opencode-desktop" \
            --replace "Exec=/opt/OpenCode/ai.opencode.desktop" "Exec=$out/bin/opencode-desktop" \
            --replace "Icon=ai.opencode.desktop" "Icon=opencode-desktop" || true
        done

    # Make sure an icon matching our icon name exists for shells that don't
    # honour the upstream app-id icon basename.
    icon="$(find "$out/share/icons" -type f -name 'ai.opencode.desktop.png' 2>/dev/null | head -n1 || true)"
    if [ -n "$icon" ]; then
      mkdir -p "$out/share/icons/hicolor/512x512/apps"
      ln -sfn "$icon" "$out/share/icons/hicolor/512x512/apps/opencode-desktop.png"
    fi

    runHook postInstall
  '';

  # Electron/Chromium binaries contain intentionally retained symbols;
  # don't strip them further.
  dontStrip = true;

  meta = with lib; {
    description = "OpenCode Desktop — AI coding agent GUI (pinned official build)";
    homepage = "https://opencode.ai/download";
    downloadPage = "https://opencode.ai/files/bin/${version}/opencode-desktop-linux-amd64.deb";

    license = licenses.mit;

    mainProgram = "opencode-desktop";

    platforms = [ "x86_64-linux" ];

    sourceProvenance = with sourceTypes; [
      binaryNativeCode
    ];

    maintainers = [ ];
  };
}
