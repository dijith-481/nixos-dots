# ZCode Desktop for Linux — official .deb (Electron)
# https://cdn-zcode.z.ai/zcode/electron/releases/3.10.2/linux-x64/ZCode-3.10.2-linux-x64.deb
#
# Packaged for NixOS via dpkg + autoPatchelfHook, mirroring pkgs/chatgpt.nix.
#
# IMPORTANT:
# - Keep version + hashes in sync when updating.
# - Uses versioned URLs for reproducibility.
# - Removes incompatible prebuilds before autoPatchelf.
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
  pname = "zcode";
  version = "3.10.2";

  src =
    let
      system = stdenv.hostPlatform.system;

      hashes = {
        x86_64-linux = "sha256-thjPpwyPfIoabilQVlzEQcKYuAG7I4nCkusNOt1r8MA=";
      };

      urls = {
        x86_64-linux = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.deb";
      };
    in
    if builtins.hasAttr system hashes then
      fetchurl {
        url = urls.${system};
        hash = hashes.${system};
      }
    else
      throw ''
        zcode: unsupported system ${system}
        Supported systems: x86_64-linux
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

    # The .deb extracts to ./opt/ZCode and ./usr/share
    # Flatten usr/share into $out/share and preserve opt/ZCode
    if [ -d usr ]; then
      cp -a usr/. "$out/"
    fi
    if [ -d opt ]; then
      cp -a opt "$out/"
    fi

    resources="$out/opt/ZCode/resources"

    if [ ! -d "$resources" ]; then
      echo "ERROR: ZCode resources directory missing: $resources" >&2
      ls -R "$out" >&2 || true
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

    # Sharp's libvips etc: keep only the linux-x64 variant if multiple archs ever appear
    # (currently only linux-x64 is shipped, so this is a no-op but future-proofs)
    # No extra cleanup needed for koffi (linux_x64 only) — handled by prebuilds logic above.

    # The .deb may include AppArmor/etc files. Don't install these
    # directly into the immutable Nix package output.
    rm -rf "$out/etc"

    # Point the desktop entry at the Nix-store wrapper.
    if [ -f "$out/share/applications/zcode.desktop" ]; then
      substituteInPlace "$out/share/applications/zcode.desktop" \
        --replace "Exec=/opt/ZCode/zcode" "Exec=$out/bin/zcode" \
        --replace "Exec=/opt/ZCode/zcode %U" "Exec=$out/bin/zcode %U"
    fi

    rm -f "$out/bin/zcode"
    mkdir -p "$out/bin"

    makeWrapper \
      "$out/opt/ZCode/zcode" \
      "$out/bin/zcode" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set ELECTRON_DISABLE_SANDBOX 1

    wrapProgram "$out/opt/ZCode/zcode" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    chmod +x "$out/opt/ZCode/zcode"
    chmod +x "$out/bin/zcode"

    # Ensure chrome-sandbox is executable but not setuid (sandbox disabled via wrapper)
    if [ -f "$out/opt/ZCode/chrome-sandbox" ]; then
      chmod +x "$out/opt/ZCode/chrome-sandbox" || true
    fi

    runHook postInstall
  '';

  dontStrip = true;

  meta = with lib; {
    description = "ZCode desktop app for Linux (Electron)";
    homepage = "https://zcode.z.ai";
    downloadPage = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.deb";

    license = licenses.unfree;

    mainProgram = "zcode";

    platforms = [
      "x86_64-linux"
    ];

    sourceProvenance = with sourceTypes; [
      binaryNativeCode
    ];

    maintainers = [ ];
  };
}
