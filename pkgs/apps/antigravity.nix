# Antigravity — Google's agentic IDE, official linux-x64 tarball (antigravity-hub).
{
  lib,
  stdenv,
  pkgs,
  dotsLib,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
}:

let
  libs = import ../lib/electron-libs.nix pkgs;
in
stdenv.mkDerivation {
  pname = "antigravity";
  version = dotsLib.sources.version "antigravity";
  src = dotsLib.sources.fetch "antigravity" stdenv.hostPlatform.system;

  sourceRoot = "Antigravity-x64";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];
  buildInputs = libs;
  runtimeDependencies = [ pkgs.udev ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/antigravity $out/bin
    cp -r . $out/share/antigravity/

    icon=$(find . -iname '*.png' | head -n1 || true)
    if [ -n "$icon" ]; then
      for s in 16 24 32 48 64 128 256; do
        install -Dm644 "$icon" $out/share/icons/hicolor/''${s}x''${s}/apps/antigravity.png
      done
    fi

    makeWrapper $out/share/antigravity/antigravity $out/bin/antigravity \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "antigravity";
      exec = "antigravity %F";
      icon = "antigravity";
      desktopName = "Antigravity";
      comment = "Agentic development platform by Google";
      categories = [
        "Development"
        "IDE"
      ];
      startupWMClass = "Antigravity";
      startupNotify = true;
    })
  ];

  dontStrip = true;

  meta = {
    description = "Google Antigravity, the agentic IDE (pinned official build)";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfree;
    mainProgram = "antigravity";
    platforms = dotsLib.sources.systems "antigravity";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
