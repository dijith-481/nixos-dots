# `update-sources`: resolve pkgs/sources.toml into pkgs/sources.lock.json.
{
  lib,
  runCommand,
  makeWrapper,
  python3,
  nodejs_24,
  cargo,
  git,
}:

runCommand "update-sources"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta.mainProgram = "update-sources";
  }
  ''
    makeWrapper ${lib.getExe python3} $out/bin/update-sources \
      --add-flags ${../../scripts/update-sources.py} \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs_24
          cargo
          git
        ]
      }
  ''
