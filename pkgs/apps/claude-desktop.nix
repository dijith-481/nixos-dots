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
  meta = {
    description = "Claude desktop app for Linux";
    homepage = "https://claude.ai/download";
  };
}
