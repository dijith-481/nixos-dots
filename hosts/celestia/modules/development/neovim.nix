{ pkgs, ... }:
let
  inherit (pkgs) vimPlugins;

  # Keep plugins in opt/ and let the small Lua loader activate each group on
  # demand. Nix still builds every source, parser and native library up front.
  optional = plugin: {
    inherit plugin;
    optional = true;
  };

  treesitter = vimPlugins.nvim-treesitter.withPlugins (parsers: with parsers; [
    angular
    astro
    bash
    c
    cpp
    css
    dart
    dockerfile
    fish
    gitignore
    html
    java
    javascript
    json
    kdl
    latex
    lua
    markdown
    markdown_inline
    ninja
    python
    query
    regex
    rust
    toml
    tsx
    typescript
    vim
    vimdoc
    yaml
    zig
    hyprlang
  ]);

  # Not generated in Nixpkgs yet; keep the exact revision from the old
  # nvim-pack-lock.json, now as a fixed-output Nix derivation.
  blink-chartoggle = pkgs.vimUtils.buildVimPlugin {
    pname = "blink.chartoggle";
    version = "unstable-2026-09-08";
    src = pkgs.fetchFromGitHub {
      owner = "saghen";
      repo = "blink.chartoggle";
      rev = "5be4af8e85e6a774990a3ec4cf5d7edda53aafc7";
      hash = "sha256-SYX7t4a6IRa3JzwJak2aCycWSfJu8cfQQEJM9fe+oZk=";
    };
  };
in
{
  programs.neovim = {
    enable = true;
    # Keep the user's existing EDITOR="hx" session preference. Enabling
    # Home Manager's defaultEditor would define EDITOR="nvim" and conflict
    # with hosts/celestia/session-variables.nix.
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # None of the configured plugins need remote provider hosts. Disabling
    # them avoids provider discovery and keeps the wrapper closure smaller.
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    withPerl = false;

    # Language servers, linters and formatters are resolved by Nix and are
    # only added to Neovim's PATH. Mason and per-plugin downloads are not used.
    extraPackages = with pkgs; [
      angular-language-server
      astro-language-server
      bash-language-server
      biome
      clang-tools
      deno
      fish-lsp
      git
      google-java-format
      hyprls
      jdt-language-server
      kdlfmt
      lua-language-server
      marksman
      nixd
      nixpkgs-fmt
      nodejs
      oxlint
      prettier
      ripgrep
      ruff
      rustywind
      shellcheck
      shfmt
      stylua
      tailwindcss-language-server
      ty
      typescript-language-server
      vscode-langservers-extracted
      zls

      # Utilities used by pickers and editor integrations.
      fd
      scooter
      eslint_d
    ];

    # Native components in fff, blink.cmp, blink.pairs and codediff are built
    # by their Nixpkgs derivations instead of downloaded into ~/.local/share.
    plugins = map optional (with vimPlugins; [
      mini-nvim
      nordic-nvim
      statuscol-nvim

      nvim-lspconfig
      fidget-nvim
      lazydev-nvim
      typescript-tools-nvim
      rustaceanvim
      flutter-tools-nvim
      roslyn-nvim

      treesitter
      nvim-ts-autotag
      nvim-treesitter-context
      nvim-ts-context-commentstring

      blink-cmp
      blink-pairs
      blink-indent
      blink-chartoggle
      blink-cmp-env
      blink-emoji-nvim
      blink-nerdfont-nvim
      blink-cmp-dictionary
      blink-cmp-conventional-commits
      colorful-menu-nvim
      luasnip
      friendly-snippets

      fff-nvim
      conform-nvim
      nvim-lint
      gitsigns-nvim
      oil-nvim
      oil-git-status-nvim
      oil-lsp-diagnostics-nvim

      snacks-nvim
      dressing-nvim
      plenary-nvim
      nui-nvim
      codediff-nvim
      render-markdown-nvim
      markdown-preview-nvim
      obsidian-nvim
      leetcode-nvim
      supermaven-nvim
    ]);

    initLua = builtins.readFile ../../../../config/nvim/init.lua;
  };

  # Lua modules and native Neovim 0.11+ LSP definitions remain ordinary
  # source files, but Home Manager now owns their complete store-backed tree.
  xdg.configFile = {
    "nvim/lua".source = ../../../../config/nvim/lua;
    "nvim/lsp".source = ../../../../config/nvim/lsp;
  };
}
