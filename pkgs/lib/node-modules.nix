# node_modules for a pinned npm package, built from pkgs/locks/<name>/package-lock.json.
#
#   mkNodeModules { name = "vercel"; }   # -> $out/node_modules/...
#
# Every tarball is fetched by the sha512 integrity recorded in the lock and
# installed with lifecycle scripts disabled. Optional packages for other
# platforms stay in the lock but are never downloaded.
{
  lib,
  stdenv,
  sources,
  importNpmLock,
  runCommand,
  nodejs_24,
}:

{
  name,
  nodejs ? nodejs_24,
  # Shell run inside the installed node_modules (e.g. swap a postinstall download for a Nix package).
  fixup ? "",
}:

let
  npmRoot = sources.lockDir name;
  lock = lib.importJSON (npmRoot + "/package-lock.json");

  # npm's os/cpu/libc fields: a list of allowed values, or "!value" exclusions.
  allows =
    value: list:
    !(lib.elem "!${value}" list) && (lib.all (lib.hasPrefix "!") list || lib.elem value list);
  platform = stdenv.hostPlatform;
  compatible =
    m:
    allows platform.node.platform (m.os or [ ])
    && allows platform.node.arch (m.cpu or [ ])
    && allows (if platform.isMusl then "musl" else "glibc") (m.libc or [ ]);

  stub = runCommand "npm-foreign-platform-stub" { } ''
    mkdir $out
    echo '{"name":"stub","version":"0.0.0"}' > $out/package.json
  '';
  skipped = lib.mapAttrs (_: _: stub) (
    lib.filterAttrs (path: m: path != "" && (m.optional or false) && !compatible m) lock.packages
  );
in
importNpmLock.buildNodeModules {
  inherit npmRoot nodejs;
  derivationArgs = {
    npmDeps = importNpmLock {
      inherit npmRoot;
      packageSourceOverrides = skipped;
    };
    postInstall = lib.optionalString (fixup != "") ''
      pushd $out/node_modules
      ${fixup}
      popd
    '';
    passthru = { inherit lock; };
  };
}
