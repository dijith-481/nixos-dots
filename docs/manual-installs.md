# Manual installs — not via Nix flake (stub-ld / frequent build pain)

These tools are intentionally **not** in `flake.nix` overlays / `home.packages` for now.
They are installed imperatively and documented here for reproducibility. Revisit flake pinning later.

## Prerequisites

```nix
# hosts/celestia/configuration.nix
programs.nix-ld.enable = true; # required for dynamically linked binaries downloaded to $HOME (e.g. vite-plus bundled node at ~/.local/share/vite-plus/js_runtime/node/…/bin/node)
```

Ensure PATH contains npm/curl install dirs (already in `hosts/celestia/session-variables.nix`):
```
$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.opencode/bin:$PATH
```

`home.file.".npmrc".text = "prefix=\${config.home.homeDirectory}/.npm-global"` is kept in `hosts/celestia/modules/development/default.nix` for `npm -g`.

## 1. vp — Vite+ unified toolchain (voidzero-dev/vite-plus)

Flake `pkgs/vp.nix` exists but not wired to `home.packages` due to `stub-ld` for its `vp` binary + bundled `node` at `~/.local/share/vite-plus/js_runtime/node/24.19.0/bin/node`.

Manual (choose one):
```bash
# Option A — npm (if available)
npm i -g vp
# Option B — GitHub release tarball
curl -fsSL https://github.com/voidzero-dev/vite-plus/releases/download/v0.3.0/vp-x86_64-unknown-linux-gnu.tar.gz -o /tmp/vp.tgz
tar -xzf /tmp/vp.tgz -C /tmp && sudo install -Dm755 /tmp/vp /usr/local/bin/vp
vp --version
```
With `programs.nix-ld.enable=true`, both the `vp` binary (`/lib64/ld-linux-x86-64.so.2`) and its downloaded `node` (`libstdc++.so.6` etc.) will run without `autoPatchelfHook`.

## 2. agy — Antigravity CLI (Google)

Not in flake (`pkgs/antigravity-cli.nix` kept as reference, not used). Upstream install is `~/.local/bin/agy` and self-updates.

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
# installs to ~/.local/bin/agy
agy --version
# custom dir: curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir ~/.local/bin
```

Docs: https://antigravity.google/docs/cli/install/

## 3. opencode2 — OpenCode v2 beta (side-by-side with opencode v1)

`opencode` v1 stays via Nix (`pkgs.opencode` 1.18.21, `opencode --version`). `opencode2` v2 beta is **only** via npm/curl, not flake (`pkgs/opencode2.nix` kept as reference).

V2 runs as `opencode2`, not `opencode`, so both can coexist.

```bash
# Option A — npm (provides opencode2)
npm install -g @opencode-ai/cli@beta
opencode2 --version

# Option B — curl installer (used by docs, installs to ~/.opencode/bin/opencode2)
curl -fsSL https://opencode.ai/v2/install | bash
# optional: --version 0.0.0-beta-18155 or --no-modify-path
~/.opencode/bin/opencode2 --version
opencode2 --help
```

If `npm` beta fails with `EBADPLATFORM musl vs glibc`, use the `curl` installer which auto-detects `linux-x64` vs `linux-x64-musl`/`baseline` via `/proc/cpuinfo` and `ldd`.

Docs: https://opencode.ai/v2/docs/cli / https://opencode.ai/v2/docs/migrate-v1

## 4. codex — Muse

Not via Nix (upstream curl installer to `~/.local/bin/codex`).

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
# installs to ~/.local/bin/codex
codex --version
```

Docs: https://developers.openai.com/codex

## 5. zram

Already declarative, no manual install:

```nix
# hosts/celestia/configuration.nix
zramSwap = {
  enable = true;
  algorithm = "lz4";
  memoryPercent = 40; # 30Gi RAM -> 12.3G zram0, priority 5
};
```
Verify: `swapon --show`, `free -h`, `zramctl`.

## Notes

- `antigravity` IDE (not CLI) stays in flake (`pkgs/antigravity.nix`, `antigravity` package) — separate from `agy`.
- `figma-agent`, `opencode` v1, `zed-editor`, etc. remain in `home.packages`.
- When re-adding any of the above to flake later, pin `version` + `hash` in `pkgs/*.nix` and add to `flake.nix` `overlays.default` + `home.packages`, then `nix flake lock --update-input` as needed.
