# opencode2 (v2 beta) — pinned npm tarball for linux-x64 glibc
# https://opencode.ai/v2/docs/cli / https://opencode.ai/v2/install
# Bump `version` + `hash` together. Source is @opencode-ai/cli-linux-x64 from npm.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "opencode2";
  version = "0.0.0-beta-18155";

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
    hash = "sha256-1Bf8t3ay5Nj5m53ZlEWNK2Mk8BAI8FsfC37pqsRkzlc=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 package/bin/opencode2 $out/bin/opencode2
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode 2 (beta) — `opencode2` TUI, side-by-side with opencode v1";
    homepage = "https://opencode.ai/v2/docs";
    license = licenses.mit;
    mainProgram = "opencode2";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
