{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fzf
    fishPlugins.grc
    grc
    # CLI tools for aliases
    bat
    ripgrep
    fd
    zoxide
    starship
    fastfetch
    cmatrix
    cava
    fum
    scooter
    eslint_d

    delta # Better git diff
    lazygit # TUI for git
    lazydocker # TUI for docker

    zellij
    neovim
    btop

    tree

    killall

    antigravity
  ];

  programs.zoxide = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--border" ];
  };

  programs.bat = {
    enable = true;
  };

  programs.starship.enable = true;

  # Declarative fish — replaces config/fish (symlink removed from home.nix)
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting

      bind -M insert ctrl-y accept-autosuggestion

      kdlfmt completions fish | source

      function print_osc7 --on-variable=PWD
          printf "\033]7;file://$HOSTNAME/$PWD\033\\"
      end
    '';
    shellAliases = {
      ff = "fastfetch";
      ll = "ls -al";
      la = "ls -a";
      vi = "nvim";
    };
  };
}
