# Overlay: every pinned app in pkgs/apps/<name>.nix becomes pkgs.<name>.
#
# Versions/hashes live in pkgs/sources.lock.json (see pkgs/sources.toml);
# the app files only describe *how* to package each upstream artifact.
final: prev:

let
  appFiles = prev.lib.filterAttrs (n: t: t == "regular" && prev.lib.hasSuffix ".nix" n) (
    builtins.readDir ./apps
  );
  apps = prev.lib.mapAttrs' (
    file: _: prev.lib.nameValuePair (prev.lib.removeSuffix ".nix" file) (final.callPackage (./apps + "/${file}") { })
  ) appFiles;
in
{
  dotsLib = {
    sources = final.callPackage ./lib/sources.nix { };
    mkElectronDeb = final.callPackage ./lib/electron-deb.nix { inherit (final.dotsLib) sources; };
    mkPrebuiltBinary = final.callPackage ./lib/prebuilt-binary.nix { inherit (final.dotsLib) sources; };
    mkNodeModules = final.callPackage ./lib/node-modules.nix { inherit (final.dotsLib) sources; };
    mkNpmCli = final.callPackage ./lib/npm-cli.nix { inherit (final.dotsLib) mkNodeModules; };
    mkCrate = final.callPackage ./lib/crate.nix { inherit (final.dotsLib) sources; };
  };

  # Names of the pinned apps (used by the flake's `packages` output and CI).
  dotsApps = builtins.attrNames apps;

  # Backport nixpkgs #581089 (merged 2026-11-02, after our 20261101 nix
  # snapshot): wasm-pack 0.15.1 no longer sets the wasm target itself, so
  # yaak's build-wasm.cjs scripts built for the host target and wasm-pack
  # failed with "Expected exactly one .wasm file in the compiler artifact".
  # Drop this override once nixpkgs is updated past the fix.
  yaak = prev.yaak.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''

      substituteInPlace crates/yaak-templates/build-wasm.cjs crates/yaak-wasm/build-wasm.cjs \
        --replace-fail 'execSync("wasm-pack build' 'execSync("CARGO_BUILD_TARGET=wasm32-unknown-unknown wasm-pack build'
    '';
  });

  update-sources = final.callPackage ./tools/update-sources.nix { };
  dots = final.callPackage ./tools/dots.nix { };
}
// apps
