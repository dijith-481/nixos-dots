# Antigravity CLI (`agy`) — replaces the curl|bash installer into ~/.local/bin.
{ dotsLib, lib }:

dotsLib.mkPrebuiltBinary {
  pname = "antigravity-cli";
  binaries.agy = "antigravity";
  meta = {
    description = "Google Antigravity CLI (agy)";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfree;
  };
}
