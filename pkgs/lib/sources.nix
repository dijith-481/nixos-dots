# Read pinned sources from pkgs/sources.lock.json (written by `dots bump`).
{ lib, fetchurl }:

let
  lock = lib.importJSON ../sources.lock.json;

  entry =
    name: lock.${name} or (throw "pkgs/sources.lock.json has no '${name}' entry. Run `dots bump ${name}`.");
in
rec {
  inherit lock entry;

  version = name: (entry name).version;

  # Extra values a strategy captured (e.g. antigravity's buildId).
  vars = name: (entry name).vars or { };

  systems = name: builtins.attrNames (entry name).sources;

  # Directory holding generated dependency locks (package-lock.json / Cargo.lock).
  lockDir = name: ../.. + "/${(entry name).lockfile or (throw "${name}: no dependency lockfile pinned")}";

  fetch =
    name: system:
    let
      s =
        (entry name).sources.${system}
          or (throw "${name}: no pinned source for ${system} (pinned: ${toString (systems name)})");
    in
    fetchurl {
      inherit (s) url hash;
      name = lib.strings.sanitizeDerivationName (baseNameOf s.url);
    };
}
