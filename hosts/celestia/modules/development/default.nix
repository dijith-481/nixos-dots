{ config, pkgs, ... }:


{
  imports = [
    ./git.nix
    ./shell.nix
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
    opencode2 # v2 beta via nix (opencode2, from @opencode-ai/cli@beta, curl alternative)
    antigravity-cli # agy (pinned in pkgs/antigravity-cli.nix)
    figma-agent

    vp # Vite+ unified web toolchain (pinned in pkgs/vp.nix)

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
