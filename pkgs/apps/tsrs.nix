# tsrs — Rust port of the TypeScript 7 compiler and language server.
#
# The npm platform package (@tsrs/linux-x64-gnu) ships the native binary and
# the default lib.*.d.ts files beside it. The binary resolves those files
# relative to its own executable, so they must stay in the same directory.
{ lib, stdenv, dotsLib, autoPatchelfHook }:

let
  sources = dotsLib.sources;
in
stdenv.mkDerivation {
  pname = "tsrs";
  version = sources.version "tsrs";
  src = sources.fetch "tsrs" stdenv.hostPlatform.system;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf "$src" -C source
    cd source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/tsrs" "$out/bin"
    cp -r package/. "$out/libexec/tsrs/"
    # Symlink, not a wrapper: the binary finds lib.*.d.ts next to the real
    # executable (/proc/self/exe resolves the symlink).
    ln -s "$out/libexec/tsrs/tsrs" "$out/bin/tsrs"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/tsrs" --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Rust port of the TypeScript 7 compiler and language server";
    homepage = "https://github.com/oxc-project/tsrs";
    license = lib.licenses.asl20;
    mainProgram = "tsrs";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
