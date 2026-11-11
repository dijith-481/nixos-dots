# Claude Desktop — official .deb from Anthropic's apt repo.
{ dotsLib, pkgs }:

dotsLib.mkElectronDeb {
  pname = "claude-desktop";
  appDir = "lib/claude-desktop";
  executable = "claude-desktop";
  extraLibs = with pkgs; [
    pipewire
    libseccomp
    libcap_ng
  ];
  runtimeLibs = [ pkgs.pipewire ];
  # Electron only auto-detects a keyring on desktops it knows (GNOME, KDE…).
  # Under niri it falls back to basic_text, safeStorage reports "encryption
  # not available", and the app never persists its login — forcing a fresh
  # email sign-in after every reboot. Point it at gnome-keyring explicitly.
  wrapperArgs = [ "--add-flags" "--password-store=gnome-libsecret" ];
  meta = {
    description = "Claude desktop app for Linux";
    homepage = "https://claude.ai/download";
  };
}
