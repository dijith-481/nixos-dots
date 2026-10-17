# Command Code CLI (`cmd`, `commandcode`) — replaces `npm i -g command-code`.
{
  dotsLib,
  lib,
  ripgrep,
}:

dotsLib.mkNpmCli {
  pname = "command-code";
  # @vscode/ripgrep normally downloads rg in a postinstall script; use nixpkgs' instead.
  nodeModulesFixup = ''
    if [ -d @vscode/ripgrep ]; then
      mkdir -p @vscode/ripgrep/bin
      ln -sf ${lib.getExe ripgrep} @vscode/ripgrep/bin/rg
    fi
  '';
  meta = {
    description = "Command Code, an AI coding agent CLI";
    homepage = "https://commandcode.ai";
    license = lib.licenses.unfree;
  };
}
