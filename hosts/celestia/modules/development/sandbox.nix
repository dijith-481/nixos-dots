{ pkgs, ... }:
let
  bwrap-dev = pkgs.callPackage ../../../../pkgs/bwrap-dev.nix { };
in
{
  home.packages = [
    pkgs.bubblewrap
    bwrap-dev
    pkgs.xdg-dbus-proxy # for future SSH_AUTH_SOCK proxy if needed
  ];

  programs.fish.functions = {
    # dev — sandboxed shell for Node/UI projects (frontend + backend)
    # Usage: dev [--offline] [--allow-ssh] [--allow-gpg] [--dry-run] [--] [cmd]
    # Bare `dev` drops into sandboxed fish at project root. `dev -- npm ci`, `dev -- pnpm dev`, `dev --allow-ssh -- git push`
    dev = {
      body = ''
        # If already inside bwrap-dev, don't nest (just exec)
        if test -n "$BWRAP_DEV"
            echo "already inside bwrap-dev ($BWRAP_PROJECT), exec $argv" >&2
            exec $argv
            return
        end
        exec bwrap-dev $argv
      '';
      wraps = "bwrap-dev";
    };
    # convenience: dnpm/dpnpm/dbun for quick sandboxed npm
    dnpm = {
      body = ''exec bwrap-dev -- npm $argv'';
      wraps = "npm";
    };
    dpnpm = {
      body = ''exec bwrap-dev -- pnpm $argv'';
      wraps = "pnpm";
    };
    dbun = {
      body = ''exec bwrap-dev -- bun $argv'';
      wraps = "bun";
    };
    dopencode = {
      body = ''exec bwrap-dev -- opencode $argv'';
      wraps = "opencode";
    };
    dopencode2 = {
      body = ''exec bwrap-dev -- opencode2 $argv'';
      wraps = "opencode2";
    };
  };

  # auto sandbox: feels normal, no extra command — cd into ~/Dev/* or Node project auto-enters bwrap
  # default: only project dir is RW, outside needs --allow-* (privileged). Set BWRAP_AUTO=0 to disable.
  programs.fish.interactiveShellInit = ''
    # already inside sandbox: show lock in prompt and auto-exit when leaving project
    if test -n "$BWRAP_DEV"
        # prompt lock
        if functions -q fish_prompt
            functions -c fish_prompt _host_fish_prompt
            function fish_prompt
                echo -n "🔒 "
                _host_fish_prompt
            end
        end
        function __bwrap_auto_exit --on-variable PWD
            set -l realpwd (realpath -m "$PWD" 2>/dev/null; or echo "$PWD")
            if not string match -q "$BWRAP_PROJECT*" "$PWD"; and not string match -q "$BWRAP_PROJECT*" "$realpwd"
                echo -e "\e[33m🔓 Leaving sandbox $BWRAP_PROJECT — back to host shell.\e[0m" >&2
                exit
            end
        end
    else
        function __bwrap_auto_enter --on-variable PWD
            if not status is-interactive; return; end
            if test -n "$BWRAP_DEV"; return; end
            if test "$BWRAP_AUTO" = "0"; return; end
            set -l realpwd (realpath -m "$PWD" 2>/dev/null; or echo "$PWD")
            set -l is_dev 0
            if string match -q "$HOME/Dev/*" "$PWD"; or string match -q "$HOME/.Data/Dev/*" "$realpwd"
                set is_dev 1
            else if test -f "$PWD/package.json"; or test -f "$PWD/pnpm-lock.yaml"; or test -f "$PWD/bun.lockb"; or test -f "$PWD/package-lock.json"; or test -f "$PWD/deno.json"; or test -f "$PWD/yarn.lock"
                set is_dev 1
            end
            if test $is_dev -eq 1
                echo -e "\e[33m🔒 Auto-entering bwrap sandbox for $PWD — only this dir is writable. Outside needs --allow-* or exit. (BWRAP_AUTO=0 to disable)\e[0m" >&2
                exec bwrap-dev
            end
        end
        # if shell starts already inside a project, enter immediately (no cd needed)
        if status is-interactive
            __bwrap_auto_enter
        end
        function __bwrap_nudge --on-event fish_preexec
            if test -n "$BWRAP_DEV"; return; end
            if test "$BWRAP_AUTO" = "0"; return; end
            set -l cmd (string split " " -- $argv[1])[1]
            if contains -- $cmd npm pnpm bun yarn node vp codex opencode opencode2
                if test -f package.json -o -f pnpm-lock.yaml -o -f bun.lockb -o -f yarn.lock
                    echo -e "\e[33m⚠  Tip: cd into project auto-sandboxes. Or use: dev -- $cmd ...\e[0m" >&2
                end
            end
        end
    end
  '';
}
