{ config, pkgs, ... }:


{
  imports = [
    ./git.nix
    ./shell.nix
    ./sandbox.nix
  ];
  # npm global prefix for opencode v2 (and any npm -g) — reproducible, not nix store
  home.file.".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-global";

  home.packages = with pkgs; [
    zed-editor

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
    lua-language-server
    typescript-language-server
    typescript
    # typescript-go removed — its `tsc` collides with typescript's in buildEnv

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

    # gemini-cli removed — replaced by Antigravity CLI upstream
    opencode # v1 stable via nix (opencode)
    figma-agent

    # vp, antigravity-cli (agy), opencode2 removed from nix — see docs/manual-installs.md for curl/npm manual installs (stub-ld pain, use nix-ld instead)

    # --- Languages & runtimes ---
    go
    gopls
    beamPackages.elixir
    beamPackages.erlang
    elixir-ls
    ghc
    cabal-install
    uv
    ruff

    # --- Apps ---
    libreoffice-stable
    # cursor: not in nixpkgs; CDN unreachable — install AppImage manually, then pin in pkgs/
    github-desktop
  ];
}
