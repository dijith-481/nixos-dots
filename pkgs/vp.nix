# Vite+ unified web toolchain (vp CLI) — pinned release
# https://viteplus.dev — bump `version` + `hash` together on updates
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "vp";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/voidzero-dev/vite-plus/releases/download/v${version}/vp-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-aOAquir4d8OPGepADnMB0IPqGOrYdx3IB1eBLCSsxNA=";
  };

  sourceRoot = ".";

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
