# Repackage an upstream Electron .deb for NixOS.
#
#   mkElectronDeb {
#     pname = "claude-desktop";
#     appDir = "lib/claude-desktop";     # app directory inside the .deb, relative to usr/ or /
#     executable = "claude-desktop";     # Electron binary inside appDir
#     meta = { ... };
#   }
#
# The source, version and supported systems all come from pkgs/sources.lock.json.
{
  lib,
  stdenv,
  pkgs,
  sources,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
}:

{
  pname,
  appDir,
  executable,
  binName ? pname,
  # Extra names in $out/bin that point at the wrapper (e.g. upstream's own binary name).
  binAliases ? [ ],
  extraLibs ? [ ],
  runtimeLibs ? [ ],
  wrapperArgs ? [ ],
  postPatch ? "",
  postInstall ? "",
  meta ? { },
}:

let
  libs = import ./electron-libs.nix pkgs ++ extraLibs;
in
stdenv.mkDerivation {
  inherit pname postPatch;
  version = sources.version pname;
  src = sources.fetch pname stdenv.hostPlatform.system;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = libs;

  # Libraries Electron / native modules dlopen at runtime.
  runtimeDependencies =
    with pkgs;
    [
      systemd
      libnotify
      libsecret
      libGL
    ]
    ++ runtimeLibs;

  # Optional Qt shims and musl prebuilds (deleted below) are never loaded.
  autoPatchelfIgnoreMissingDeps = [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libc.musl-x86_64.so.1"
    "libc.musl-aarch64.so.1"
  ];

  # dpkg-deb -x would keep chrome-sandbox's setuid bit, which the Nix sandbox rejects.
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    [ -d usr ] && cp -a usr/. "$out/"
    [ -d opt ] && cp -a opt "$out/"
    # AppArmor profiles etc. have no place in an immutable store path.
    rm -rf "$out/etc"

    app="$out/${appDir}"
    main="$app/${executable}"
    if [ ! -x "$main" ] || [ ! -d "$app/resources" ]; then
      echo "ERROR: unexpected ${pname} layout, expected $main and $app/resources" >&2
      find "$out" -maxdepth 4 >&2
      exit 1
    fi

    # Keep only native prebuilds for this platform.
    find "$app/resources" -type d -name prebuilds -print0 \
      | while IFS= read -r -d "" dir; do
          find "$dir" -mindepth 1 -maxdepth 1 \
            ! -name "*${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}" \
            -exec rm -rf -- {} +
        done
    find "$app/resources" -type f -name '*.musl.node' -delete
    find "$app/resources" -depth -type d -name '*-musl' -exec rm -rf -- {} +

    # Upstream bin/ entries are symlinks into /opt or ../lib; replace them with a wrapper.
    rm -rf "$out/bin"
    mkdir -p "$out/bin"
    makeWrapper "$main" "$out/bin/${binName}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libs}" \
      --set ELECTRON_DISABLE_SANDBOX 1 \
      ${lib.escapeShellArgs wrapperArgs}
    ${lib.concatMapStrings (a: ''ln -s ${binName} "$out/bin/${a}"'' + "\n") binAliases}

    # Electron relaunches itself via the real binary on updates/restarts.
    wrapProgram "$main" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libs}"

    # Point every desktop entry (and its actions) at the wrapper.
    for desktop in "$out"/share/applications/*.desktop; do
      [ -f "$desktop" ] || continue
      sed -i -E \
        -e "s|^Exec=[^ ]+|Exec=$out/bin/${binName}|" \
        -e "s|^TryExec=.*|TryExec=$out/bin/${binName}|" \
        "$desktop"
    done

    if [ -f "$out/share/pixmaps/${pname}.png" ] && [ ! -e "$out/share/icons/hicolor/512x512/apps/${pname}.png" ]; then
      mkdir -p "$out/share/icons/hicolor/512x512/apps"
      ln -s "$out/share/pixmaps/${pname}.png" "$out/share/icons/hicolor/512x512/apps/${pname}.png"
    fi

    runHook postInstall
  '';
  inherit postInstall;

  # Electron binaries keep symbols on purpose.
  dontStrip = true;

  meta = {
    license = lib.licenses.unfree;
    mainProgram = binName;
    platforms = sources.systems pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  }
  // meta;
}
