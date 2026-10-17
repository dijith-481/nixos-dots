# Build a crates.io binary reproducibly — the Nix replacement for `cargo install`.
#
#   mkCrate { pname = "loc"; }
#
# The .crate tarball is pinned by the checksum crates.io publishes. If the
# crate doesn't ship a Cargo.lock, `dots bump` generates one into
# pkgs/locks/<pname>/Cargo.lock; every dependency in it is checksum-pinned too.
{
  lib,
  rustPlatform,
  sources,
  stdenv,
}:

{
  pname,
  meta ? { },
  ...
}@args:

let
  lockFile = sources.lockDir pname + "/Cargo.lock";
in
rustPlatform.buildRustPackage (
  {
    inherit pname;
    version = sources.version pname;
    src = sources.fetch pname stdenv.hostPlatform.system;
    # .crate files are gzipped tarballs with a non-standard extension.
    unpackCmd = "tar -xzf $curSrc";

    cargoLock = { inherit lockFile; };
    postPatch = ''
      ln -sf ${lockFile} Cargo.lock
    '';

    meta = {
      mainProgram = pname;
      platforms = lib.platforms.linux;
    }
    // meta;
  }
  // removeAttrs args [ "meta" ]
)
