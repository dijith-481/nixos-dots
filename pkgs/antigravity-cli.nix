# Antigravity CLI (agy) — pinned official Google tarball
# https://antigravity.google/docs/cli/install/ — bump `version` + `buildId` + `hash` together.
# Manifest: https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "antigravity-cli";
  version = "1.1.20";
  buildId = "5830032204103680";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${buildId}/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha512-bNx/yQViukDIvwZY8w7eAW5qzQMIN3m+jVTUv2PdmYADk+M8AK3flD9sK3m02s78b7SpY7KwL2zmNjXvVKQoaA==";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Antigravity CLI — agentic development platform terminal client (agy)";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    mainProgram = "agy";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
