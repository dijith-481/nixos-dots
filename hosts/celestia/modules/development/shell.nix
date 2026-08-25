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

  # Declarative fish — pure Nix, mirrors config/fish/config.fish + config/fish/functions/*
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting

      bind -M insert ctrl-y accept-autosuggestion

      kdlfmt completions fish | source

      # theme — mirrors config/fish/conf.d/fish_frozen_theme.fish
      set --global fish_color_autosuggestion 434c5e
      set --global fish_color_cancel -r
      set --global fish_color_command green
      set --global fish_color_comment 434c5e
      set --global fish_color_cwd green
      set --global fish_color_cwd_root red
      set --global fish_color_end brblack
      set --global fish_color_error red
      set --global fish_color_escape yellow
      set --global fish_color_history_current --bold
      set --global fish_color_host normal
      set --global fish_color_match --background=brblue
      set --global fish_color_normal normal
      set --global fish_color_operator blue
      set --global fish_color_param 60728a
      set --global fish_color_quote yellow
      set --global fish_color_redirection cyan
      set --global fish_color_search_match bryellow --background=2e3440
      set --global fish_color_selection white --bold --background=2e3440
      set --global fish_color_status red
      set --global fish_color_user brgreen
      set --global fish_color_valid_path --underline
      set --global fish_pager_color_completion normal
      set --global fish_pager_color_description yellow --dim
      set --global fish_pager_color_prefix white --bold
      set --global fish_pager_color_progress brwhite --background=cyan
      set --global fish_pager_color_selected_background --background=434c5e

      # key bindings — mirrors config/fish/conf.d/fish_frozen_key_bindings.fish
      set --global fish_key_bindings fish_vi_key_bindings
      set --erase --universal fish_key_bindings 2>/dev/null; or true

      # navigation helpers — mirrors cd.fish's .. / ... etc
      function ..; cd ..; end
      function ...; cd ../..; end
      function ....; cd ../../..; end
      function .....; cd ../../../..; end
      function ......; cd ../../../../..; end

      # auto fastfetch — mirrors config/fish/config.fish:23 ff + config/fish/functions/ff.fish
      if status is-interactive
          ff
      end
    '';
    shellAliases = {
      # ff/ll/la/vi now as functions to mirror config/fish exactly (functions needed for $argv handling)
    };
    functions = {
      # mirrors config/fish/functions/cd.fish
      cd = {
        body = ''
          if z $argv
              set -l num_items (count *)
              if test $num_items -lt 15
                  ls
              end
          end
        '';
        wraps = "z";
      };

      # mirrors config/fish/functions/print_osc7.fish
      print_osc7 = {
        body = ''printf "\033]7;file://$HOSTNAME/$PWD\033\\"'';
        onVariable = "PWD";
      };

      # mirrors config/fish/functions/ff.fish
      ff = ''
        set -l width (tput cols)
        set -l height (tput lines)
        set -l term (basename "/"(ps -o cmd -f -p (cat /proc/(echo %self)/stat | cut -d \  -f 4) | tail -1 | sed 's/ .*$//'))
        if test $term = foot
            if test $width -ge 70 -a $height -ge 8
                eval fastfetch
            end
        else if test $term = ghostty
            if test $width -ge 70 -a $height -ge 8
                eval fastfetch -c ~/.config/fastfetch/ghostty.jsonc
            end
        end
      '';

      # mirrors config/fish/functions/fish_prompt.fish
      fish_prompt = ''
        set -l __last_command_exit_status $status

        if not set -q -g __fish_arrow_functions_defined
            set -g __fish_arrow_functions_defined
            function _git_branch_name
                set -l branch (git symbolic-ref --quiet HEAD 2>/dev/null)
                if set -q branch[1]
                    echo (string replace -r '^refs/heads/' "" $branch)
                else
                    echo (git rev-parse --short HEAD 2>/dev/null)
                end
            end

            function _is_git_dirty
                not command git diff-index --cached --quiet HEAD -- &>/dev/null
                or not command git diff --no-ext-diff --quiet --exit-code &>/dev/null
            end

            function _is_git_repo
                type -q git
                or return 1
                git rev-parse --git-dir >/dev/null 2>&1
            end

            function _hg_branch_name
                echo (hg branch 2>/dev/null)
            end

            function _is_hg_dirty
                set -l stat (hg status -mard 2>/dev/null)
                test -n "$stat"
            end

            function _is_hg_repo
                fish_print_hg_root >/dev/null
            end

            function _repo_branch_name
                _$argv[1]_branch_name
            end

            function _is_repo_dirty
                _is_$argv[1]_dirty
            end

            function _repo_type
                if _is_hg_repo
                    echo hg
                    return 0
                else if _is_git_repo
                    echo git
                    return 0
                end
                return 1
            end
        end

        set -l cyan (set_color -o cyan)
        set -l yellow (set_color -o yellow)
        set -l red (set_color -o red)
        set -l green (set_color -o green)
        set -l blue (set_color -o blue)
        set -l normal (set_color normal)

        set -l arrow_color "$green"
        if test $__last_command_exit_status != 0
            set arrow_color "$red"
        end

        set -l arrow "$arrow_color➜ "
        if fish_is_root_user
            set arrow "$arrow_color# "
        end

        set -l cwd $cyan(basename (prompt_pwd))

        set -l repo_info
        if set -l repo_type (_repo_type)
            set -l repo_branch $red(_repo_branch_name $repo_type)
            set repo_info "$blue $repo_type:($repo_branch$blue)"

            if _is_repo_dirty $repo_type
                set -l dirty "$yellow ✗"
                set repo_info "$repo_info$dirty"
            end
        end

        echo -n -s $arrow ' '$cwd $repo_info $normal ' '
      '';

      # mirrors config/fish/functions/ls.fish
      ls = "command ls --color=auto $argv";

      # mirrors config/fish/functions/hx.fish
      hx = ''
        if set -q ZELLIJ
            command hx $argv
        else
            set -x HX_ARGS "$argv"
            zellij --layout helix
        end
      '';

      # mirrors config/fish/functions/dotenv.fish
      dotenv = ''
        set -l config_file .env
        if test -n "$argv[1]"
            set config_file $argv[1]
        end

        if not test -f "$config_file"
            return 1
        end

        while read -l line
            set -l clean_line (string trim -- $line)
            if test -z "$clean_line"; or string match -q -- "#*" $clean_line
                continue
            end

            set -l kv (string split -m 1 = -- $clean_line)
            set -l key (string trim -- $kv[1])
            set -l val (string trim -- $kv[2])

            if string match -q -r "^'.*'\$" -- $val
                set val (string sub -s 2 -e -1 -- $val)
            else if string match -q -r '^".*"$' -- $val
                set val (string sub -s 2 -e -1 -- $val)
            end

            set -gx "$key" $val
            echo "Exported $key"
        end <$config_file
      '';

      # mirrors config/fish/functions/extract.fish
      extract = ''
        if test -f $argv[1]
            switch $argv[1]
                case '*.tar.bz2'
                    tar xjf $argv[1]
                case '*.tar.gz'
                    tar xzf $argv[1]
                case '*.bz2'
                    bunzip2 $argv[1]
                case '*.rar'
                    unrar x $argv[1]
                case '*.gz'
                    gunzip $argv[1]
                case '*.tar'
                    tar xf $argv[1]
                case '*.tbz2'
                    tar xjf $argv[1]
                case '*.tgz'
                    tar xzf $argv[1]
                case '*.zip'
                    unzip $argv[1]
                case '*.Z'
                    uncompress $argv[1]
                case '*.7z'
                    7z x $argv[1]
                case '*'
                    echo "🤔 '$argv[1]' cannot be extracted via extract()"
            end
        else
            echo "🚫 '$argv[1]' is not a valid file"
        end
      '';

      # mirrors config/fish/functions/py.fish
      py = "python3 $argv";

      # mirrors config/fish/functions/gcc.fish
      gcc = ''
        if test (count $argv) -eq 1
            set filename (basename $argv[1] .c)
            mkdir -p output && gcc "$argv[1]" -o "output/$filename"
        else
            command gcc $argv
        end
      '';

      # mirrors config/fish/functions/tplay.fish
      tplay = "command foot -c ~/.config/foot/tplay.ini tplay --browser brave $argv";

      # mirrors config/fish/functions/fk.fish
      fk = "fuck";

      # shellAliases already cover ll/la/vi, but keep functions for exact mirror if needed
      ll = "ls -al $argv";
      la = "ls -a $argv";
      vi = "nvim $argv";
    };
  };
}
