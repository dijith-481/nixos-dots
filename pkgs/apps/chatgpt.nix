# ChatGPT Desktop — official .deb from OpenAI's apt repo.
{ dotsLib }:

dotsLib.mkElectronDeb {
  pname = "chatgpt";
  appDir = "lib/chatgpt";
  executable = "ChatGPT";

  # SIGILL in the git repo watcher: autoPatchelf moves PT_INTERP past the first
  # ~2 KiB that detect-libc scans, so it falls back to process.report, which
  # Electron's CFI traps. Force @parcel/watcher's glibc backend instead.
  # app.asar is patched in place without rebuilding its index, so the
  # replacement must be exactly as long as the original (hence the spaces).
  postPatch = ''
    asar=usr/lib/chatgpt/resources/app.asar
    needle='const family = familySync();'
    patched="const family = 'glibc'     ;"

    count=$(grep -aoF "$needle" "$asar" | wc -l)
    if [ "$count" -ne 1 ]; then
      echo "ERROR: expected one detect-libc pattern in app.asar, found $count" >&2
      exit 1
    fi
    size=$(stat -c %s "$asar")
    sed -i "s|$needle|$patched|" "$asar"
    if [ "$(stat -c %s "$asar")" -ne "$size" ] || ! grep -aFq "$patched" "$asar"; then
      echo "ERROR: app.asar SIGILL patch failed" >&2
      exit 1
    fi
  '';

  meta = {
    description = "ChatGPT desktop app for Linux";
    homepage = "https://chatgpt.com/download";
  };
}
