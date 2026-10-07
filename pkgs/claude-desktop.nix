# Claude Desktop for Linux — official .deb (Electron)
# https://code.claude.com/docs/en/desktop-linux
#
# Packaged for NixOS via dpkg + autoPatchelfHook, mirroring pkgs/chatgpt.nix.
#
# IMPORTANT:
# - Keep version + hashes in sync when updating.
# - Uses versioned URLs for reproducibility.
# - Removes incompatible musl/foreign prebuilds before autoPatchelf.

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
  pipewire,
  libseccomp,
  libcap_ng,
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
  pname = "claude-desktop";
  version = "2.26454.0";

  src =
    let
      system = stdenv.hostPlatform.system;

      hashes = {
        x86_64-linux =
          "sha256-bT5Jc9yxFRHd2WIECzBztDXRWSsxdKgu9S5QN3p1pj8=";

        aarch64-linux =
          "sha256-Ab3/hz0843tNzFbNLfvEcRucj5q85HnnWlL5RqCD2YE=";
      };

      urls = {
        x86_64-linux =
          "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";

        aarch64-linux =
          "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_arm64.deb";
      };
    in
    if builtins.hasAttr system hashes then
      fetchurl {
        url = urls.${system};
        hash = hashes.${system};
      }
    else
      throw ''
        claude-desktop: unsupported system ${system}
        Supported systems: x86_64-linux, aarch64-linux
      '';

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
    pipewire
    libseccomp
    libcap_ng
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

  # Libraries that Electron / native modules may dlopen at runtime.
  runtimeDependencies = [
    systemd
    libnotify
    libsecret
    libGL
    pipewire
  ];

  /*
    Qt shims are optional fallbacks.

    Musl entries below are also ignored as a last-resort safety net.
    We remove musl prebuilds during installPhase, so normally
    autoPatchelf should never encounter them.
  */
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

  /*
    Extract the Debian package directly into the build directory.

    The package layout becomes:

      usr/bin/claude-desktop -> ../lib/claude-desktop/claude-desktop
      usr/lib/claude-desktop/
      usr/share/
  */
  unpackPhase = ''
    runHook preUnpack

    # dpkg-deb -x preserves the upstream chrome-sandbox setuid bit,
    # which fails inside the Nix sandbox (Operation not permitted).
    # Extract without same permissions; we chmod +x later and run
    # with ELECTRON_DISABLE_SANDBOX=1 like pkgs/chatgpt.nix.
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    # Preserve permissions and symlinks from the Debian package.
    cp -a usr/. "$out/"

    resources="$out/lib/claude-desktop/resources"

    if [ ! -d "$resources" ]; then
      echo "ERROR: Claude Desktop resources directory missing: $resources" >&2
      exit 1
    fi

    if [ ! -x "$out/lib/claude-desktop/claude-desktop" ]; then
      echo "ERROR: Claude Desktop main binary missing" >&2
      ls -R "$out/lib/claude-desktop" >&2 || true
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

    # The .deb may include AppArmor/etc files. Don't install these
    # directly into the immutable Nix package output.
    rm -rf "$out/etc"

    # Point desktop entries (main + NewChat/NewCode actions) at the wrapper.
    if [ -f "$out/share/applications/com.anthropic.Claude.desktop" ]; then
      substituteInPlace "$out/share/applications/com.anthropic.Claude.desktop" \
        --replace "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"
    fi

    rm -f "$out/bin/claude-desktop"

    makeWrapper \
      "$out/lib/claude-desktop/claude-desktop" \
      "$out/bin/claude-desktop" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set ELECTRON_DISABLE_SANDBOX 1

    wrapProgram "$out/lib/claude-desktop/claude-desktop" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    chmod +x "$out/lib/claude-desktop/claude-desktop"
    chmod +x "$out/bin/claude-desktop"

    if [ -f "$out/lib/claude-desktop/chrome-sandbox" ]; then
      chmod +x "$out/lib/claude-desktop/chrome-sandbox" || true
    fi

    runHook postInstall
  '';

  /*
    Electron/Chromium binaries contain intentionally retained symbols and
    metadata. Avoid stripping the upstream executable further.
  */
  dontStrip = true;

  meta = with lib; {
    description = "Claude desktop app for Linux";
    homepage = "https://claude.ai/download";
    downloadPage = "https://code.claude.com/docs/en/desktop-linux";

    license = licenses.unfree;

    mainProgram = "claude-desktop";

    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    sourceProvenance = with sourceTypes; [
      binaryNativeCode
    ];

    maintainers = [ ];
  };
}
