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

  # optional soft nudge: warn if npm/pnpm/bun run outside sandbox in a Node project
  programs.fish.interactiveShellInit = ''
    function __bwrap_nudge --on-event fish_preexec
        if test -n "$BWRAP_DEV"
            return
        end
        set -l cmd (string split " " -- $argv[1])[1]
        if contains -- $cmd npm pnpm bun yarn
            if test -f package.json -o -f pnpm-lock.yaml -o -f bun.lockb -o -f yarn.lock
                echo -e "\e[33m⚠  Running $cmd outside bwrap-dev — secrets & sibling projects visible. Use: dev -- $cmd ... or dnpm/dpnpm/dbun\e[0m" >&2
            end
        end
    end
  '';
}
