# OpenCode v2 CLI — the prebuilt binary from the @opencode/cli-linux-x64 npm package.
# Replaces `npm i -g @opencode/cli` and the old ~/.local/bin/opencode2 wrapper.
{
  dotsLib,
  lib,
  wayland,
  libxcb,
}:

dotsLib.mkPrebuiltBinary {
  pname = "opencode";
  binaries = {
    opencode = "package/bin/opencode";
    opencode2 = "package/bin/opencode";
  };
  # OpenTUI's clipboard backend dlopen()s these; without them image paste silently fails.
  wrapperArgs = [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    (lib.makeLibraryPath [
      wayland
      libxcb
    ])
  ];
  meta = {
    description = "OpenCode v2, the AI coding agent TUI";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
  };
}
