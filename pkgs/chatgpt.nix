# ChatGPT Desktop for Linux — official .deb (Electron)
# https://learn.chatgpt.com/docs/linux/linux-app
#
# Packaged for NixOS via dpkg + autoPatchelfHook.
#
# IMPORTANT:
# - Keep version + hashes in sync when updating.
# - Uses versioned URLs for reproducibility.
# - Includes NixOS Git repo watcher SIGILL workaround.
# - Removes incompatible musl/native prebuilds before autoPatchelf.

{
  lib,
  stdenv,
  fetchurl,

  # Native build tools
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,

  # Runtime/build libraries
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  libnotify,
  libsecret,
  libuuid,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxshmfence,
  libgbm,
  libusb1,
  libXScrnSaver,
  libXtst,
}:

stdenv.mkDerivation rec {
  pname = "chatgpt";
  version = "26.820.60940";

  src =
    let
      system = stdenv.hostPlatform.system;

      hashes = {
        x86_64-linux =
          "sha256-MdlWqMbFFfjYfgt6zZ7JGffmhbpZMxtLl6pF+FOv39c=";

        aarch64-linux =
          "sha256-j02sv/XwVKT2nCoCHxOWxXl2lygpphBB/rrBtCPyfIY=";
      };

      urls = {
        x86_64-linux =
          "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";

        aarch64-linux =
          "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_arm64.deb";
      };
    in
    if builtins.hasAttr system hashes then
      fetchurl {
        url = urls.${system};
        hash = hashes.${system};
      }
    else
      throw ''
        chatgpt: unsupported system ${system}
        Supported systems: x86_64-linux, aarch64-linux
      '';

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3

    libdrm
    libGL
    libxkbcommon
    libnotify
    libsecret
    libuuid
    mesa
    nspr
    nss
    pango
    systemd

    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxshmfence
    libgbm
    libusb1
    libXScrnSaver
    libXtst
  ];

  # Libraries that Electron / native modules may dlopen at runtime.
  runtimeDependencies = [
    systemd
    libnotify
    libsecret
    libGL
  ];

  /*
    Qt shims are optional fallbacks.

    Musl entries below are also ignored as a last-resort safety net.
    We remove musl prebuilds during installPhase, so normally
    autoPatchelf should never encounter them.
  */
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

  dontWrapGApps = true;

  /*
    Extract the Debian package directly into the build directory.

    The package layout becomes:

      usr/bin/
      usr/lib/chatgpt/
      usr/share/
  */
  unpackPhase = ''
    runHook preUnpack

    dpkg-deb -x "$src" .

    runHook postUnpack
  '';

  /*
    NixOS / autoPatchelf Git watcher SIGILL workaround.

    autoPatchelf changes the ELF PT_INTERP location. The bundled
    detect-libc package only scans the first ~2 KiB of the executable.

    When it fails to find glibc, detect-libc falls back to
    process.report. Electron's CFI rejects that path and intentionally
    traps, resulting in:

      SIGILL
      thread: git
      [git-repo-watcher] Starting git repo watcher

    Force @parcel/watcher to select the glibc backend directly.

    CRITICAL:
    app.asar is modified in-place without rebuilding its index.

    The replacement therefore MUST have exactly the same byte length
    as the original string.

      const family = familySync();
      const family = 'glibc'     ;

    The spaces before ";" are intentional padding.
  */
  postPatch = ''
    asar="usr/lib/chatgpt/resources/app.asar"
    needle='const family = familySync();'

    if [ ! -f "$asar" ]; then
      echo "ERROR: ChatGPT app.asar not found at: $asar" >&2
      exit 1
    fi

    count="$(
      grep -aoF "$needle" "$asar" | wc -l
    )"

    if [ "$count" -ne 1 ]; then
      echo "ERROR: expected exactly one detect-libc pattern in app.asar, found $count" >&2
      exit 1
    fi

    size_before="$(stat -c '%s' "$asar")"

    sed -i \
      "s|const family = familySync();|const family = 'glibc'     ;|" \
      "$asar"

    size_after="$(stat -c '%s' "$asar")"

    if [ "$size_before" -ne "$size_after" ]; then
      echo "ERROR: app.asar size changed after SIGILL patch" >&2
      echo "before=$size_before after=$size_after" >&2
      exit 1
    fi

    if grep -aFq "$needle" "$asar"; then
      echo "ERROR: detect-libc pattern was not replaced" >&2
      exit 1
    fi

    if ! grep -aFq "const family = 'glibc'     ;" "$asar"; then
      echo "ERROR: glibc watcher override was not installed" >&2
      exit 1
    fi
  '';

    installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    # Preserve permissions and symlinks from the Debian package.
    cp -a usr/. "$out/"

    resources="$out/lib/chatgpt/resources"

    if [ ! -d "$resources" ]; then
      echo "ERROR: ChatGPT resources directory missing: $resources" >&2
      exit 1
    fi

    # Keep only native prebuilds compatible with this host.
    #
    # For example, on x86_64-linux this removes:
    #
    #   HID-linux-x64-musl
    #   HID_hidraw-linux-x64-musl
    #   darwin-arm64
    #   win32-x64
    #   linux-arm64
    #
    # while keeping the matching Linux/glibc prebuild.

    find "$resources" \
      -type d \
      -name prebuilds \
      -print0 \
      | while IFS= read -r -d "" prebuildsPath; do

          find "$prebuildsPath" \
            -mindepth 1 \
            -maxdepth 1 \
            ! -name "*${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}" \
            -exec rm -rf -- {} +
        done

    # Catch packages using filenames such as foo.musl.node.
    find "$resources" \
      -type f \
      -name '*.musl.node' \
      -delete

    # Catch musl directories outside a conventional prebuilds directory.
    find "$resources" \
      -depth \
      -type d \
      -name '*-musl' \
      -exec rm -rf -- {} +

    # The .deb may include AppArmor/etc files. Don't install these
    # directly into the immutable Nix package output.
    rm -rf "$out/etc"

    if [ -f "$out/share/pixmaps/chatgpt.png" ]; then
      mkdir -p "$out/share/icons/hicolor/512x512/apps"

      ln -sfn \
        "$out/share/pixmaps/chatgpt.png" \
        "$out/share/icons/hicolor/512x512/apps/chatgpt.png"
    fi

    # Point the desktop entry at the Nix-store wrapper.
    if [ -f "$out/share/applications/chatgpt.desktop" ]; then
      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace "Exec=chatgpt" "Exec=$out/bin/chatgpt"
    fi

    rm -f "$out/bin/chatgpt"

    makeWrapper \
      "$out/lib/chatgpt/ChatGPT" \
      "$out/bin/chatgpt" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set ELECTRON_DISABLE_SANDBOX 1

    wrapProgram "$out/lib/chatgpt/ChatGPT" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    chmod +x "$out/lib/chatgpt/ChatGPT"
    chmod +x "$out/bin/chatgpt"

    runHook postInstall
  '';
  /*
    Electron/Chromium binaries contain intentionally retained symbols and
    metadata. Avoid stripping the upstream executable further.
  */
  dontStrip = true;

  meta = with lib; {
    description = "ChatGPT desktop app for Linux";
    homepage = "https://chatgpt.com/download";
    downloadPage = "https://learn.chatgpt.com/docs/linux/linux-app";

    license = licenses.unfree;

    mainProgram = "chatgpt";

    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    sourceProvenance = with sourceTypes; [
      binaryNativeCode
    ];

    maintainers = [ ];
  };
}
