{ writeShellApplication, python3, nix, nix-index, git, fzf, nixos-rebuild, cacert }:
writeShellApplication {
  name = "nix-helper";
  runtimeInputs = [ python3 nix nix-index git fzf nixos-rebuild ];
  text = ''
    export SSL_CERT_FILE="''${SSL_CERT_FILE:-${cacert}/etc/ssl/certs/ca-bundle.crt}"
    exec python3 ${../../scripts/nix-helper.py} "$@"
  '';
}
