# loc — fast lines-of-code counter; replaces `cargo install loc`.
{ dotsLib, lib }:

dotsLib.mkCrate {
  pname = "loc";
  doCheck = false;
  meta = {
    description = "Count lines of code, fast";
    homepage = "https://github.com/cgag/loc";
    license = lib.licenses.mit;
  };
}
