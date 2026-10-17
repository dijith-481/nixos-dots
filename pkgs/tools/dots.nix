# `dots`: switch / update / bump / rollback / gc for this flake. See `dots help`.
{
  lib,
  writeShellApplication,
  git,
  gh,
  jq,
  nh,
  coreutils,
  update-sources,
  # Where the flake checkout lives and which nixosConfiguration to build.
  dotsFlake ? "/home/dijith/.Data/nixos-dots",
  dotsHost ? "nixos-celestia",
}:

writeShellApplication {
  name = "dots";
  runtimeInputs = [
    git
    gh
    jq
    nh
    coreutils
    update-sources
  ];
  text =
    builtins.replaceStrings [ "@flake@" "@host@" ] [ dotsFlake dotsHost ]
      (builtins.readFile ../../scripts/dots.sh);
}
