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

  update-sources = final.callPackage ./tools/update-sources.nix { };
  dots = final.callPackage ./tools/dots.nix { };
}
// apps
