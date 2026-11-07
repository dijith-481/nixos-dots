{ pkgs, lib, ... }:
{
  # Managed by `nix-helper --install`; JSON keeps package names out of Nix code.
  home.packages = map
    (name: lib.attrByPath (lib.splitString "." name)
      (throw "nix-helper: package ${name} is missing from the pinned nixpkgs")
      pkgs)
    (builtins.fromJSON (builtins.readFile ./helper-packages.json));
}
