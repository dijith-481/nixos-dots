# Vercel CLI — replaces `npm i -g vercel`.
{ dotsLib, lib }:

dotsLib.mkNpmCli {
  pname = "vercel";
  meta = {
    description = "Vercel CLI";
    homepage = "https://vercel.com/docs/cli";
    license = lib.licenses.asl20;
  };
}
