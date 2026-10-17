{ config, pkgs, ... }:


{
  imports = [
    ./git.nix
    ./neovim.nix
    ./shell.nix
    ./terminal-configs.nix
  ];
  # Keep stray `npm i -g` out of the home directory root. Real CLIs are pinned
  # in pkgs/sources.toml instead (see `dots apps`).
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';

  # vp: use the Nix-provided node/npm/pnpm/yarn/bun instead of downloading its own
  # runtimes into ~/.local/share/vite-plus, and skip `vp upgrade` nags (Nix pins vp).
  xdg.configFile."vite-plus/config.json".text = builtins.toJSON {
    nodeShimMode = "system_first";
    packageManagerShimModes = {
      bun = "system_first";
      npm = "system_first";
      pnpm = "system_first";
      yarn = "system_first";
    };
  };
  home.sessionVariables.VP_NO_UPDATE_CHECK = "1";

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

    cloudflared # Cloudflare Tunnel daemon
    ngrok # ngrok tunneling
    wrangler # Cloudflare Workers CLI

    # gemini-cli removed — replaced by Antigravity CLI upstream
    figma-agent

    # --- Pinned upstream CLIs (pkgs/sources.toml, bumped by CI / `dots bump`) ---
    vp # vite-plus
    antigravity-cli # agy
    opencode # v2, also as `opencode2`
    vercel
    command-code
    loc

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
    github-cli
  ];
}
