{ config, ... }:

{

  programs.git = {
    enable = true;

    settings = {
      user.name = "dijith-481";
      user.email = "dijithdinesh481@gmail.com";

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
      key = "34F7623C3D4EB56B6365350A54EE82784BE29F43";
      signByDefault = true;
    };
  };
  # git diff pager — replaces the deprecated programs.git.delta module
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Nord";
    };
  };

  # SSH config — matchBlocks renamed to settings in current home-manager
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/github";
        identitiesOnly = true;
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/bitbucket";
        identitiesOnly = true;
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
