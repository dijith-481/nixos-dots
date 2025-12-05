{ pkgs, ... }:


{
  imports = [
    ./git.nix
    ./shell.nix
  ];
  home.packages = with pkgs; [
    zed

    pnpm

    nodejs_24
    bun
    deno
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # dbeaver-bin             # Universal database tool (80+ databases)

    gcc # GNU Compiler Collection
    tree-sitter

    #TODO move mason imports here
    shellcheck # Shell script linting
    shfmt # Shell script formatting
    biome
    stylua
    prettier
    kdlfmt
    nixd
    nixpkgs-fmt


    lldb_20
    docker
    docker-compose

    httpie # Better curl alternative
    #todo test it
    yaak # API testing tool

    gemini-cli
    opencode

  ];
}
