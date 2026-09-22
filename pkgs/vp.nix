# Vite+ unified web toolchain (vp CLI) — pinned release
# https://viteplus.dev — bump `version` + `hash` together on updates
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "vp";
  version = "1.0.0-rc.0";

  src = fetchurl {
    url = "https://github.com/voidzero-dev/vite-plus/releases/download/v${version}/vp-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-XDtHXNJI8K8NhprEqtOiUNJ8PYC/B7kVCn6ezqAYKs0=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 vp $out/bin/vp
    runHook postInstall
  '';

  meta = with lib; {
    description = "Vite+ — unified toolchain for the web (Vite, Rolldown, Vitest, Oxlint, Oxfmt)";
    homepage = "https://viteplus.dev";
    license = licenses.unfreeRedistributable;
    mainProgram = "vp";
    platforms = [ "x86_64-linux" ];
  };
}
