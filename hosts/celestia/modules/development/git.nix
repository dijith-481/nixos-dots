{ config, ... }:

{

  programs.git = {
    enable = true;

    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "Nord";
      };
    };

    settings = {
      user.name = "dijith-481";
      user.email = "dijithdinesh@protonmail.com";

      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;
      push.autoSetupRemote = true;

      include.path = "~/.config/delta/theme.gitconfig";
      core = {
        editor = "hx";
        # 'pager' is removed here because delta.enable = true handles it
      };

      # 'interactive.diffFilter' is removed; handled by delta module

      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      column.ui = "auto";

      diff.algorithm = "patience";
      merge.conflictstyle = "zdiff3";
    };

    signing = {
      key = "FB73ACE9832782B3";
      signByDefault = true;
    };
  };
  #TODO write comments on setup gpg and ssh on install
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/github_rsa";
      };
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };
}
