{ config, ... }:

{
  programs.git = {
    enable = true;
    userName = "dijith-481";
    userEmail = "dijithdinesh@protonmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;
      push.autoSetupRemote = true;
      core.editor = "hx";
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      column.ui = "auto";


      diff.algorithm = "patience";
      merge.conflictstyle = "diff3";
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
