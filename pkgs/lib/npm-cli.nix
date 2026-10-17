# Package a JavaScript CLI from npm, reproducibly — the Nix replacement for `npm i -g`.
#
#   mkNpmCli { pname = "vercel"; }
#
# `dots bump <pname>` writes pkgs/locks/<pname>/package-lock.json: the whole
# dependency tree resolved from the registry, every tarball pinned by its
# sha512 integrity. Nix fetches exactly those tarballs, installs them with
# lifecycle scripts disabled, and wraps each `bin` from the package's
# package.json with a pinned Node.js.
{
  lib,
  stdenv,
  mkNodeModules,
  makeWrapper,
  nodejs_24,
}:

{
  pname,
  # npm package name, if it differs from pname.
  npmPackage ? pname,
  nodejs ? nodejs_24,
  wrapperArgs ? [ ],
  # Shell run inside the installed node_modules (e.g. to swap a postinstall download for a Nix package).
  nodeModulesFixup ? "",
  meta ? { },
}:

let
  nodeModules = mkNodeModules {
    name = pname;
    inherit nodejs;
    fixup = nodeModulesFixup;
  };
  inherit (nodeModules) lock;

  pkgDir = "${nodeModules}/node_modules/${npmPackage}";
in
stdenv.mkDerivation {
  inherit pname;
  version = lock.packages."node_modules/${npmPackage}".version;

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  # Wrap every entry of package.json "bin" with the pinned Node.js.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ${lib.getExe nodejs} -e '
      const p = require(process.argv[1] + "/package.json");
      const bin = typeof p.bin === "string" ? { [p.name.split("/").pop()]: p.bin } : (p.bin || {});
      for (const [name, file] of Object.entries(bin)) console.log(name + "\t" + file);
    ' ${pkgDir} | while IFS=$'\t' read -r name file; do
      makeWrapper ${lib.getExe nodejs} "$out/bin/$name" \
        --add-flags "${pkgDir}/$file" \
        ${lib.escapeShellArgs wrapperArgs}
    done
    [ -n "$(ls -A $out/bin)" ] || { echo "ERROR: ${npmPackage} declares no bin" >&2; exit 1; }
    runHook postInstall
  '';

  passthru = { inherit nodeModules; };

  meta = {
    mainProgram = pname;
    platforms = lib.platforms.linux;
  }
  // meta;
}
