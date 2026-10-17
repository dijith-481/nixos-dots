# Package a prebuilt CLI binary from a tarball (GitHub release, npm platform package, vendor CDN).
#
#   mkPrebuiltBinary {
#     pname = "vp";
#     binaries = { vp = "vp"; };          # name in $out/bin -> path inside the archive
#     patch = "none";                     # "autopatchelf" | "none" (static binaries)
#   }
#
# The source, version and supported systems all come from pkgs/sources.lock.json.
{
  lib,
  stdenv,
  sources,
  autoPatchelfHook,
  makeWrapper,
}:

{
  pname,
  binaries,
  patch ? "autopatchelf",
  libs ? [ ],
  # Extra makeWrapper args (e.g. --prefix LD_LIBRARY_PATH for dlopen'ed libs).
  wrapperArgs ? [ ],
  # Run `<bin> <versionArg>` after install to catch a broken binary at build time.
  versionArg ? "--version",
  meta ? { },
}:

assert lib.elem patch [
  "autopatchelf"
  "none"
];

stdenv.mkDerivation {
  inherit pname;
  version = sources.version pname;
  src = sources.fetch pname stdenv.hostPlatform.system;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional (patch == "autopatchelf") autoPatchelfHook;
  buildInputs = lib.optionals (patch == "autopatchelf") ([ stdenv.cc.cc.lib ] ++ libs);

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf "$src" -C source
    cd source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/${pname}" "$out/bin"
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: path: ''
      install -Dm755 ${lib.escapeShellArg path} "$out/libexec/${pname}/${name}"
      makeWrapper "$out/libexec/${pname}/${name}" "$out/bin/${name}" ${lib.escapeShellArgs wrapperArgs}
    '') binaries
  )
  + ''
    runHook postInstall
  '';

  # Single-file executables (bun/node SEA) embed their payload; stripping corrupts it.
  dontStrip = true;

  doInstallCheck = versionArg != null;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR"
  ''
  + lib.concatMapStrings (name: ''
    "$out/bin/${name}" ${versionArg}
  '') (lib.attrNames binaries)
  + ''
    runHook postInstallCheck
  '';

  meta = {
    mainProgram = lib.head (lib.attrNames binaries);
    platforms = sources.systems pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  }
  // meta;
}
