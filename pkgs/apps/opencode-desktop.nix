# OpenCode Desktop — official .deb from opencode.ai (electron-builder layout in /opt/OpenCode).
{ dotsLib, lib }:

dotsLib.mkElectronDeb {
  pname = "opencode-desktop";
  appDir = "opt/OpenCode";
  executable = "ai.opencode.desktop";
  # Upstream desktop entries and scripts call the electron-builder executableName.
  binAliases = [ "ai.opencode.desktop" ];
  meta = {
    description = "OpenCode Desktop, the AI coding agent GUI";
    homepage = "https://opencode.ai/download";
    license = lib.licenses.mit;
  };
}
