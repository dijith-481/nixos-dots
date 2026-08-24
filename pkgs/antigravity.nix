# Antigravity IDE — pinned official Google tarball
# nixpkgs' package tracks a dead 1.x line; this follows antigravity-hub stable.
# Bump `version` + `buildId` + `hash` together on updates.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libuuid,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libxkbcommon,
  libXrandr,
  libxshmfence,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  udev,
}:

stdenv.mkDerivation rec {
  pname = "antigravity";
  version = "2.9.1";
  buildId = "4871453687021568";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${version}-${buildId}/linux-x64/Antigravity.tar.gz";
    hash = "sha256-AW2/akLFpJqsT6QD16iSBKPHyTN5nJXsuRrCwW+jTe0=";
  };

  sourceRoot = "Antigravity-x64";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libuuid
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libxkbcommon
    libXrandr
    libxshmfence
    mesa
    nspr
    nss
    pango
    systemd
    udev
  ];

  runtimeDependencies = [ udev ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/antigravity $out/bin
    cp -r . $out/share/antigravity/

    # icons if shipped anywhere in the tree
    icon=$(find . -iname '*.png' | head -n1 || true)
    if [ -n "$icon" ]; then
      for s in 16 24 32 48 64 128 256; do
        mkdir -p $out/share/icons/hicolor/''${s}x''${s}/apps
        cp "$icon" $out/share/icons/hicolor/''${s}x''${s}/apps/antigravity.png
      done
    fi

    makeWrapper $out/share/antigravity/antigravity $out/bin/antigravity \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "antigravity";
      exec = "antigravity %F";
      icon = "antigravity";
      desktopName = "Antigravity";
      comment = "Agentic development platform by Google";
      categories = [ "Development" "IDE" ];
      startupWMClass = "Antigravity";
      terminal = false;
      startupNotify = true;
    })
  ];

  meta = with lib; {
    description = "Google Antigravity — agentic IDE (pinned official build)";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
