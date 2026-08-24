{ pkgs, ... }:


{
  imports = [
    ./git.nix
    ./shell.nix
  ];
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
    opencode
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
