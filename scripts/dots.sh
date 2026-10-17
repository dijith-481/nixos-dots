# dots: day-to-day driver for this NixOS flake.
# Packaged by pkgs/tools/dots.nix (writeShellApplication adds `set -euo pipefail`).

FLAKE="${DOTS_FLAKE:-@flake@}"
HOST="${DOTS_HOST:-@host@}"
BUMP_BRANCH="auto/update-sources"

say() { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mxx\033[0m %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
dots: manage the NixOS system at $FLAKE (host: $HOST)

System
  dots switch            build, show the package diff, activate, and make it the boot default
  dots test              activate without a boot entry (a reboot goes back to the old system)
  dots boot              build now, activate on the next boot
  dots build             build only and show what would change
  dots update [flags]    the full routine:
                           1. merge the open app-update PR (if CI opened one)
                           2. git pull
                           3. nix flake update (nixpkgs, home-manager, ...)
                           4. dots switch
                           5. commit flake.lock and push
                         flags: --no-merge  --no-push  --no-flake (apps only)

Pinned apps (pkgs/sources.toml -> pkgs/sources.lock.json)
  dots apps              list pinned app versions
  dots bump [APP...]     fetch the latest upstream versions locally (no CI needed)
  dots bump -n           dry run: only show what's new
  dots pr                show the open app-update PR
  dots try-pr            test-activate that PR's branch without merging it

Generations
  dots rollback          switch back to the previous system generation
  dots generations       list system generations
  dots gc [AGE]          delete generations older than AGE (default 10d, keeps the last 3) and collect garbage
  dots diff [A B]        compare two system closures (default: booted vs current)
EOF
}

in_flake() { cd "$FLAKE" || die "flake checkout not found at $FLAKE (set DOTS_FLAKE)"; }

require_clean() {
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    git status --short --untracked-files=no >&2
    die "uncommitted changes in $FLAKE; commit or stash them first"
  fi
}

os() {
  local verb="$1"
  shift
  nh os "$verb" "$FLAKE#nixosConfigurations.$HOST" "$@"
}

bump_pr_json() {
  gh pr list --head "$BUMP_BRANCH" --state open --limit 1 \
    --json number,title,url,mergeable,headRefOid --jq '.[0] // empty'
}

merge_bump_pr() {
  if ! command -v gh >/dev/null || ! gh auth status >/dev/null 2>&1; then
    warn "gh is not logged in; skipping the app-update PR (run: gh auth login)"
    return 0
  fi
  local pr number mergeable
  pr="$(bump_pr_json)" || {
    warn "could not query GitHub; skipping the app-update PR"
    return 0
  }
  if [ -z "$pr" ]; then
    say "no pending app-update PR"
    return 0
  fi
  number="$(jq -r .number <<<"$pr")"
  mergeable="$(jq -r .mergeable <<<"$pr")"
  say "app-update PR #$number: $(jq -r .title <<<"$pr")"
  if [ "$mergeable" = "CONFLICTING" ]; then
    warn "PR #$number conflicts with main; skipping it (CI rebuilds it on the next run)"
    return 0
  fi
  # CI only opens/updates the PR after every changed app built, so open == built.
  if ! gh pr merge "$number" --squash --delete-branch; then
    warn "could not merge PR #$number; continuing without it"
    return 0
  fi
  git pull --ff-only
}

cmd_update() {
  local merge=1 push=1 flake=1
  for arg in "$@"; do
    case "$arg" in
    --no-merge) merge=0 ;;
    --no-push) push=0 ;;
    --no-flake) flake=0 ;;
    *) die "unknown flag: $arg" ;;
    esac
  done
  in_flake
  require_clean
  say "pulling"
  git pull --ff-only
  [ "$merge" = 1 ] && merge_bump_pr
  if [ "$flake" = 1 ]; then
    say "updating flake inputs"
    nix flake update
  fi
  say "building and switching"
  if ! os switch; then
    git checkout -- flake.lock
    die "switch failed; flake.lock restored, system unchanged"
  fi
  if ! git diff --quiet -- flake.lock; then
    git commit -m "chore(flake): update inputs" -- flake.lock
    if [ "$push" = 1 ]; then git push; else say "committed flake.lock (not pushed)"; fi
  fi
  say "done"
}

cmd_try_pr() {
  in_flake
  local pr
  pr="$(bump_pr_json)"
  [ -n "$pr" ] || die "no open app-update PR"
  say "testing PR #$(jq -r .number <<<"$pr") without merging (reboot or 'dots switch' to undo)"
  git fetch origin "$BUMP_BRANCH"
  nh os test "git+file://$FLAKE?ref=refs/remotes/origin/$BUMP_BRANCH#nixosConfigurations.$HOST"
}

cmd_gc() {
  local age="${1:-10d}"
  nh clean all --keep-since "$age" --keep 3
  say "store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
}

cmd_diff() {
  local a="${1:-/run/booted-system}" b="${2:-/run/current-system}"
  nix store diff-closures "$a" "$b"
}

cmd="${1:-help}"
[ $# -gt 0 ] && shift
case "$cmd" in
switch | test | boot | build)
  in_flake
  os "$cmd" "$@"
  ;;
update) cmd_update "$@" ;;
apps)
  in_flake
  update-sources --list
  ;;
bump)
  in_flake
  update-sources "$@"
  ;;
pr)
  in_flake
  gh pr view "$BUMP_BRANCH" 2>/dev/null || say "no open app-update PR"
  ;;
try-pr) cmd_try_pr ;;
rollback) sudo nixos-rebuild switch --rollback ;;
generations) nixos-rebuild list-generations ;;
gc) cmd_gc "$@" ;;
diff) cmd_diff "$@" ;;
help | -h | --help) usage ;;
*)
  usage
  exit 1
  ;;
esac
