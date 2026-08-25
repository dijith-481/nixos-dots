{ lib, pkgs, writeShellApplication, bubblewrap, coreutils, bash, findutils, gawk }:
let
  binPath = lib.makeBinPath [ bubblewrap coreutils bash findutils gawk ];
in
writeShellApplication {
  name = "bwrap-dev";
  runtimeInputs = [ bubblewrap coreutils bash findutils gawk ];
  text = ''
    set -euo pipefail
    export PATH="${binPath}:$PATH"

    # --- defaults (node-focused, Frontend + Backend) ---
    ALLOW_NET=1
    ALLOW_SSH=0
    ALLOW_GPG=0
    ALLOW_DOCKER=0
    ALLOW_GUI=0
    DRY_RUN=0
    SHARE_CACHES=0
    PROJECT=""
    EXTRA_BINDS=()
    CMD=()

    usage() {
      cat <<'USAGE'
    Usage: bwrap-dev [options] [--] [command ...]
      Wraps `bwrap` so Node/UI projects run isolated by default.
      By default: project dir is the only RW host path, $HOME is tmpfs, /nix is ro, net is shared.
      Secrets (~/.ssh, ~/.gnupg, gh, .env) are hidden unless allowed.

    Options:
      --project DIR        Project root (default: git top-level or cwd)
      --offline            --unshare-net (no internet, for untrusted npm i review)
      --allow-net          Keep internet (default)
      --allow-ssh          Bind ~/.ssh (ro) + SSH_AUTH_SOCK if present
      --allow-gpg          Bind ~/.gnupg + gpg-agent socket
      --allow-docker       Bind /run/docker.sock (escape! use only for backend compose)
      --allow-gui          Bind WAYLAND_DISPLAY + XDG_RUNTIME_DIR (for UI preview that needs display)
      --share-caches       Use host ~/.npm/~/.cache/pnpm instead of per-project caches (faster, less safe)
      --bind DIR:DIR       Extra --bind (repeatable), e.g. --bind /home/dijith/.env.shared:/home/dijith/.env.shared:ro
      --dry-run            Print bwrap command and exit
      -h, --help           Show this help
    Example:
      bwrap-dev -- npm ci
      bwrap-dev --dry-run -- pnpm install
      bwrap-dev --allow-ssh -- git push
      bwrap-dev --offline -- npm install   # audit install without net
      dev                  # (fish wrapper) opens sandboxed fish
    USAGE
    }

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --project) PROJECT="$2"; shift 2;;
        --offline) ALLOW_NET=0; shift;;
        --allow-net) ALLOW_NET=1; shift;;
        --allow-ssh) ALLOW_SSH=1; shift;;
        --allow-gpg) ALLOW_GPG=1; shift;;
        --allow-docker) ALLOW_DOCKER=1; shift;;
        --allow-gui) ALLOW_GUI=1; shift;;
        --share-caches) SHARE_CACHES=1; shift;;
        --bind) EXTRA_BINDS+=("$2"); shift 2;;
        --dry-run) DRY_RUN=1; shift;;
        -h|--help) usage; exit 0;;
        --) shift; CMD=("$@"); break;;
        --*) echo "unknown option: $1" >&2; usage >&2; exit 1;;
        *) CMD=("$@"); break;;
      esac
    done

    # --- resolve project root ---
    if [[ -z "$PROJECT" ]]; then
      if git rev-parse --show-toplevel >/dev/null 2>&1; then
        PROJECT="$(git rev-parse --show-toplevel)"
      else
        PROJECT="$PWD"
      fi
    fi
    PROJECT="$(realpath -m "$PROJECT")"
    if [[ ! -d "$PROJECT" ]]; then
      echo "bwrap-dev: project dir not found: $PROJECT" >&2; exit 1
    fi

    # --- per-project cache dir (isolated by default) ---
    HASH="$(echo -n "$PROJECT" | sha256sum | cut -c1-12)"
    CACHE_BASE="$HOME/.cache/bwrap/$HASH"
    mkdir -p "$CACHE_BASE/cache" "$CACHE_BASE/share" "$CACHE_BASE/npm" "$CACHE_BASE/pnpm" "$CACHE_BASE/bun" "$CACHE_BASE/node-gyp" 2>/dev/null || true

    # --- build bwrap args ---
    BWRAP_ARGS=()

    # namespaces - keep net shared by default for npm
    BWRAP_ARGS+=(--unshare-pid --unshare-uts --unshare-ipc --die-with-parent --new-session)
    if [[ "$ALLOW_NET" -eq 0 ]]; then
      BWRAP_ARGS+=(--unshare-net)
    else
      BWRAP_ARGS+=(--share-net)
    fi

    # basic fs
    BWRAP_ARGS+=(--dev /dev --proc /proc --tmpfs /tmp)
    BWRAP_ARGS+=(--ro-bind /nix /nix)
    # ro-bind current system closure for PATH binaries
    if [[ -e /run/current-system ]]; then BWRAP_ARGS+=(--ro-bind /run/current-system /run/current-system); fi
    if [[ -e /run/wrappers ]]; then BWRAP_ARGS+=(--ro-bind /run/wrappers /run/wrappers); fi
    BWRAP_ARGS+=(--ro-bind /etc /etc)
    # keep /usr for FHS compat if present
    if [[ -e /usr ]]; then BWRAP_ARGS+=(--ro-bind /usr /usr); fi
    if [[ -e /bin ]]; then BWRAP_ARGS+=(--ro-bind /bin /bin); fi

    # hide host HOME, then re-expose only what we allow
    BWRAP_ARGS+=(--tmpfs /home/dijith)
    # also hide .Data mount that leaks sibling Dev projects; we re-bind only current project
    # project at original absolute path + /work + ~/work for compat
    BWRAP_ARGS+=(--bind "$PROJECT" "$PROJECT")
    if [[ "$PROJECT" != "/home/dijith/work" ]]; then
      BWRAP_ARGS+=(--bind "$PROJECT" /work)
      BWRAP_ARGS+=(--bind "$PROJECT" /home/dijith/work)
    fi
    # caches -> per-project (node-focused)
    if [[ "$SHARE_CACHES" -eq 1 ]]; then
      # share host caches (less safe)
      [[ -d "$HOME/.npm" ]] && BWRAP_ARGS+=(--bind "$HOME/.npm" /home/dijith/.npm) || BWRAP_ARGS+=(--dir /home/dijith/.npm)
      [[ -d "$HOME/.cache/pnpm" ]] && BWRAP_ARGS+=(--bind "$HOME/.cache/pnpm" /home/dijith/.cache/pnpm) || true
      [[ -d "$HOME/.pnpm-store" ]] && BWRAP_ARGS+=(--bind "$HOME/.pnpm-store" /home/dijith/.pnpm-store) || true
      [[ -d "$HOME/.local/share/pnpm" ]] && BWRAP_ARGS+=(--bind "$HOME/.local/share/pnpm" /home/dijith/.local/share/pnpm) || true
      [[ -d "$HOME/.bun" ]] && BWRAP_ARGS+=(--bind "$HOME/.bun" /home/dijith/.bun) || true
    else
      BWRAP_ARGS+=(--bind "$CACHE_BASE/npm" /home/dijith/.npm)
      BWRAP_ARGS+=(--bind "$CACHE_BASE/pnpm" /home/dijith/.local/share/pnpm)
      BWRAP_ARGS+=(--bind "$CACHE_BASE/bun" /home/dijith/.bun)
      BWRAP_ARGS+=(--bind "$CACHE_BASE/cache" /home/dijith/.cache)
      # keep node-gyp cache isolated too
      BWRAP_ARGS+=(--bind "$CACHE_BASE/node-gyp" /home/dijith/.cache/node-gyp)
      # ensure share dir exists for pnpm
      BWRAP_ARGS+=(--dir /home/dijith/.local/share)
    fi
    # keep .npm-global (npm -g prefix from home.file.".npmrc") per-project too
    BWRAP_ARGS+=(--dir /home/dijith/.npm-global)
    # vite-plus / codex / opencode2 manual installs — bind read-only so `vp dev`/`workerd`/`codex` work inside sandbox
    for p in ".local/share/vite-plus" ".local/bin" ".opencode" ".npm-global"; do
      if [[ -e "$HOME/$p" ]]; then BWRAP_ARGS+=(--ro-bind "$HOME/$p" "/home/dijith/$p"); fi
    done

    # shell + editor configs minimal (so fish/starship work but don't leak secrets)
    # bind read-only where safe, else empty
    for p in ".config/fish" ".config/starship" ".config/starship.toml"; do
      if [[ -e "$HOME/$p" ]]; then BWRAP_ARGS+=(--ro-bind "$HOME/$p" "/home/dijith/$p"); fi
    done

    # git config safe to expose ro (no tokens)
    if [[ -f "$HOME/.config/gh/hosts.yml" && "$ALLOW_SSH" -eq 0 ]]; then
      : # hide gh hosts
      :
    fi
    if [[ -f "$HOME/.gitconfig" ]]; then BWRAP_ARGS+=(--ro-bind "$HOME/.gitconfig" /home/dijith/.gitconfig); fi

    # secrets - only if allowed
    if [[ "$ALLOW_SSH" -eq 1 ]]; then
      [[ -d "$HOME/.ssh" ]] && BWRAP_ARGS+=(--ro-bind "$HOME/.ssh" /home/dijith/.ssh)
      if [[ -n "''${SSH_AUTH_SOCK:-}" && -e "$SSH_AUTH_SOCK" ]]; then
        BWRAP_ARGS+=(--bind "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK")
      fi
      # gcr ssh agent
      if [[ -e "/run/user/''${UID:-1000}/gcr/.ssh" ]]; then
        BWRAP_ARGS+=(--ro-bind "/run/user/''${UID:-1000}/gcr" "/run/user/''${UID:-1000}/gcr")
      fi
    fi
    if [[ "$ALLOW_GPG" -eq 1 ]]; then
      [[ -d "$HOME/.gnupg" ]] && BWRAP_ARGS+=(--bind "$HOME/.gnupg" /home/dijith/.gnupg)
      if [[ -n "''${GNUPGHOME:-}" && -e "$GNUPGHOME" ]]; then
        BWRAP_ARGS+=(--bind "$GNUPGHOME" "$GNUPGHOME")
      fi
      if [[ -e "/run/user/''${UID:-1000}/gnupg" ]]; then
        BWRAP_ARGS+=(--bind "/run/user/''${UID:-1000}/gnupg" "/run/user/''${UID:-1000}/gnupg")
      fi
    fi
    if [[ "$ALLOW_DOCKER" -eq 1 && -e /run/docker.sock ]]; then
      BWRAP_ARGS+=(--bind /run/docker.sock /run/docker.sock)
    fi
    if [[ "$ALLOW_GUI" -eq 1 && -n "''${WAYLAND_DISPLAY:-}" && -n "''${XDG_RUNTIME_DIR:-}" ]]; then
      BWRAP_ARGS+=(--ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY")
      if [[ -e "$XDG_RUNTIME_DIR" ]]; then BWRAP_ARGS+=(--ro-bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR"); fi
    fi

    # extra binds
    for eb in "''${EXTRA_BINDS[@]}"; do
      # eb is "src:dst[:ro]" or "src:dst"
      IFS=':' read -r src dst mode <<< "$eb"
      if [[ -z "$src" || -z "$dst" ]]; then src="$eb"; dst="$eb"; mode=""; fi
      if [[ "$mode" == "ro" ]]; then BWRAP_ARGS+=(--ro-bind "$src" "$dst"); else BWRAP_ARGS+=(--bind "$src" "$dst"); fi
    done

    # env - scrub and re-set minimal
    BWRAP_ARGS+=(--clearenv)
    BWRAP_ARGS+=(--setenv HOME /home/dijith)
    BWRAP_ARGS+=(--setenv USER dijith)
    BWRAP_ARGS+=(--setenv SHELL /run/current-system/sw/bin/fish)
    BWRAP_ARGS+=(--setenv PATH "/home/dijith/.local/share/vite-plus/current/bin:/home/dijith/.opencode/bin:/home/dijith/.npm-global/bin:/run/current-system/sw/bin:/run/wrappers/bin:/home/dijith/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/dijith/.local/bin")
    BWRAP_ARGS+=(--setenv XDG_CACHE_HOME /home/dijith/.cache)
    BWRAP_ARGS+=(--setenv XDG_CONFIG_HOME /home/dijith/.config)
    BWRAP_ARGS+=(--setenv XDG_DATA_HOME /home/dijith/.local/share)
    BWRAP_ARGS+=(--setenv XDG_STATE_HOME /home/dijith/.local/state)
    BWRAP_ARGS+=(--setenv NPM_CONFIG_CACHE /home/dijith/.npm)
    BWRAP_ARGS+=(--setenv PNPM_HOME /home/dijith/.local/share/pnpm)
    BWRAP_ARGS+=(--setenv BUN_INSTALL /home/dijith/.bun)
    # keep TERM for ghostty/foot
    [[ -n "''${TERM:-}" ]] && BWRAP_ARGS+=(--setenv TERM "$TERM")
    # pass through safe vars
    for v in LANG LC_ALL LC_CTYPE EDITOR VISUAL PAGER NO_COLOR FORCE_COLOR CI; do
      if [[ -n "''${!v:-}" ]]; then BWRAP_ARGS+=(--setenv "$v" "''${!v}"); fi
    done
    # inside mark
    BWRAP_ARGS+=(--setenv BWRAP_DEV 1 --setenv BWRAP_PROJECT "$PROJECT")

    # chdir to project (via /work)
    BWRAP_ARGS+=(--chdir /work)

    # command
    if [[ ''${#CMD[@]} -eq 0 ]]; then
      # interactive sandboxed fish
      CMD=(/run/current-system/sw/bin/fish --login)
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      # shellcheck disable=SC2145
      echo "bwrap ''${BWRAP_ARGS[*]} -- ''${CMD[*]}"
      exit 0
    fi

    exec bwrap "''${BWRAP_ARGS[@]}" -- "''${CMD[@]}"
  '';
}
