# Manual installs

Everything that used to be installed with curl|bash, `npm i -g` or
`cargo install` is now pinned in `pkgs/sources.toml` (see `docs/pinned-apps.md`):
vp, agy (antigravity-cli), opencode (v2), vercel, command-code, loc.

Still imperative (candidates to move next):

- codex (`~/.codex/packages/standalone`): `codex` exists in nixpkgs, or add a recipe
- hermes (hermes-agent wrapper scripts in `~/.local/bin`)
- fx, git-filter-repo (`~/.local/bin`): both are in nixpkgs

`programs.nix-ld.enable = true` stays on for runtimes vp downloads per project
(`vp env`), and for one-off binaries.
