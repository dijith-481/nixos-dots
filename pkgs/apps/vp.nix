# Vite+ (`vp`) — replaces the curl|bash installer.
#
# Upstream installs two halves into ~/.local/share/vite-plus/<version>/:
#   bin/vp          static musl launcher (GitHub release, lock entry "vp")
#   node_modules/   the `vite-plus` npm package (lock entry "vite-plus")
# This rebuilds that exact layout in the Nix store, so `vp upgrade` is never needed.
{
  lib,
  stdenv,
  dotsLib,
  nodejs_24,
}:

let
  inherit (dotsLib) sources;
  version = sources.version "vp";
  nodeModules = dotsLib.mkNodeModules { name = "vite-plus"; };
in
assert lib.assertMsg (sources.version "vite-plus" == version)
  "vp ${version} needs vite-plus ${version} (pinned: ${sources.version "vite-plus"}); run `dots bump vp vite-plus`";
stdenv.mkDerivation {
  pname = "vp";
  inherit version;
  src = sources.fetch "vp" stdenv.hostPlatform.system;

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf "$src" -C source
    cd source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    home=$out/share/vite-plus
    install -Dm755 vp $home/bin/vp
    touch $home/bin/.vp-setup-complete
    cp ${sources.lockDir "vite-plus"}/package.json $home/package.json
    ln -s ${nodeModules}/node_modules $home/node_modules
    mkdir -p $out/bin
    ln -s $home/bin/vp $out/bin/vp
    ln -s $home/bin/vp $out/bin/vpr
    ln -s $home/bin/vp $out/bin/vpx
    runHook postInstall
  '';

  dontStrip = true;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ nodejs_24 ];
  installCheckPhase = ''
    export HOME=$TMPDIR
    $out/bin/vp --version
  '';

  meta = {
    description = "Vite+, the unified web toolchain (Vite, Rolldown, Vitest, Oxlint, Oxfmt)";
    homepage = "https://viteplus.dev";
    license = lib.licenses.unfreeRedistributable;
    mainProgram = "vp";
    platforms = sources.systems "vp";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
