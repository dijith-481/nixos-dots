# OpenCode Desktop — official .deb from opencode.ai (electron-builder layout in /opt/OpenCode).
{ dotsLib, lib }:

dotsLib.mkElectronDeb {
  pname = "opencode-desktop";
  appDir = "opt/OpenCode";
  # Upstream renamed the Electron binary in 2.3.0 (was ai.opencode.desktop).
  executable = "ai.opencode";
  # Upstream desktop entries and scripts call the electron-builder executableName.
  binAliases = [ "ai.opencode.desktop" ];
  meta = {
    description = "OpenCode Desktop, the AI coding agent GUI";
    homepage = "https://opencode.ai/download";
    license = lib.licenses.mit;
  };
}
