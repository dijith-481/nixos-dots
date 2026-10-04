{ config, ... }:

let
  # OpenSSH sets IP_TOS 0xb8 (DSCP 46 / CS6) on its socket; the mobile carrier
  # blackholes those packets, so the SYN never gets a reply and git hangs with
  # no output. Let bash (not OpenSSH) create the TCP socket, then relay it.
  proxyCmd = "bash -c 'exec 3<>/dev/tcp/%h/%p; cat <&3 & cat >&3'";
in
{

  programs.git = {
    enable = true;

    settings = {
      user.name = "dijith-481";
      user.email = "dijithdinesh481@gmail.com";

      init.defaultBranch = "main";
      commit.gpgSign = true;
      tag.gpgSign = true;

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
  #
  # NOTE: This network (phone tether -> mobile carrier) silently DROPS any TCP
  # packet with IP_TOS DSCP 46 (CS6, 0xb8), which OpenSSH sets on every socket.
  # The SYN is blackholed, so the connection sits in SYN-SENT forever with no
  # output. Toggling Wi-Fi appeared to "fix" it because it rebuilt the mobile
  # data bearer. We bypass OpenSSH's socket by making ProxyCommand create the
  # TCP connection instead, then tunnel the SSH session over its stdio.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      # Applied to every host below: fail fast instead of hanging silently.
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/github";
        identitiesOnly = true;
        proxyCommand = proxyCmd;
        connectTimeout = "15";
        serverAliveInterval = "30";
      };
      "bitbucket-clyentra" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/bitbucket-clyentra";
        identitiesOnly = true;
        proxyCommand = proxyCmd;
        connectTimeout = "15";
        serverAliveInterval = "30";
      };

      "github-logai" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/github-logai";
        identitiesOnly = true;
        proxyCommand = proxyCmd;
        connectTimeout = "15";
        serverAliveInterval = "30";
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/bitbucket";
        identitiesOnly = true;
        proxyCommand = proxyCmd;
        connectTimeout = "15";
        serverAliveInterval = "30";
      };
    };
  };
}
