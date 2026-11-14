# Pinned apps

Apps that aren't in nixpkgs (or where nixpkgs lags) are pinned to exact
upstream releases, with every download hash-checked.

```
pkgs/sources.toml        recipes: where each app's releases come from (you edit this)
pkgs/sources.lock.json   resolved version + url + hash per system (generated)
pkgs/locks/<app>/        package-lock.json / Cargo.lock for npm and cargo apps (generated)
pkgs/apps/<app>.nix      how to package it (usually ~10 lines calling a builder)
pkgs/lib/                builders: mkElectronDeb, mkPrebuiltBinary, mkNpmCli, mkNodeModules, mkCrate
scripts/update-sources.py  the resolver (`dots bump`, run by CI every 6h)
```

## Flow

1. Every 6 hours `.github/workflows/update-sources.yml` resolves every recipe,
   builds each app whose derivation changed, evaluates the whole system, and
   opens or updates **one** PR from `auto/update-sources`.
2. `dots try-pr` test-activates that PR without merging (a reboot undoes it).
3. `dots update` merges the PR, pulls, and switches using the checked-in
   `flake.lock`, preserving the inputs used in CI. Or merge on GitHub and run
   `dots switch`.

`dots bump [app...]` does step 1 locally when you don't want to wait for CI.

## Updates and binary caches

- `dots plan` previews the derivations to build and cached paths to download.
  It does not build or activate anything.
- `dots update` preserves the checked-in flake inputs. `--no-flake` remains
  accepted as an alias for this default behavior.
- `dots update --flake` explicitly upgrades all inputs, then switches and
  commits/pushes the new lock after success. Upgrading compilers or native
  libraries can require rebuilding custom packages even without version changes.
- Switch/build/test/boot commands reject implicit lockfile updates. On a failed
  update, the new lock is kept so `dots plan` and `dots switch` can diagnose and
  retry the exact same inputs. Activation failure may leave a partially applied
  system; the script does not claim otherwise or push the failed update.

The system uses the official `cache.nixos.org` cache; the niri module also
configures its upstream cache. Keep standard nixpkgs packages unmodified to
reuse those binaries. `nix flake check --no-build` checks that Anyrun, Scooter,
Figma Agent, FFF and FFF's native library still match upstream output paths.
This guards output identity; cache availability still depends on upstream.

CI builds validate custom app recipes but **do not publish downloadable
binaries**. Apps in `pkgs/apps` may still build locally. Most download vendor
binaries and only package them; `loc` deliberately builds from a pinned crate.
Using official caches alone cannot supply builds of our custom recipes. We
retain Nix signature verification and tests, and keep the documented laptop
CPU limits rather than trading correctness or cooling for apparent speed.

## Adding an app

Add a recipe to `pkgs/sources.toml` (the header lists every strategy). An illustrative example:

```toml
[ripgrep-all]
arch = { x86_64-linux = "x86_64" }
[[ripgrep-all.source]]
type = "github-release"
repo = "phiresky/ripgrep-all"
asset = "ripgrep_all-v{version}-{arch}-unknown-linux-musl.tar.gz"
```

Add `pkgs/apps/ripgrep-all.nix`:

```nix
{ dotsLib, lib }:
dotsLib.mkPrebuiltBinary {
  pname = "ripgrep-all";
  binaries.rga = "ripgrep_all-v${dotsLib.sources.version "ripgrep-all"}-x86_64-unknown-linux-musl/rga";
  patch = "none";
  meta.license = lib.licenses.agpl3Plus;
}
```

Then:

```
git add pkgs && dots bump ripgrep-all && nix build .#ripgrep-all
```

Finally, add it to `home.packages` or `environment.systemPackages`. Files under
`pkgs/apps/` are picked up automatically; new files must be `git add`ed before
Nix can see them.

Which builder to use:

| upstream ships | builder | strategy |
|---|---|---|
| Electron `.deb` | `mkElectronDeb` | `apt` if there's a repo, else `github-release` / `json` / `probe` |
| a binary in a tarball (or curl\|bash installer) | `mkPrebuiltBinary` | `github-release`, `json` (installer manifest), `npm` (platform package) |
| JS CLI on npm | `mkNpmCli` | `npm` with `lockfile = true` |
| Rust crate | `mkCrate` | `crate` |

To hunt down a curl|bash installer, read the script: it nearly always fetches
a JSON manifest or a GitHub release. Point a `json` or `github-release`
strategy at that. When a vendor is unreliable (antigravity), list several
strategies and set `pick = "highest"`.

## Holding or reverting

- `hold = true` in a recipe freezes that app.
- `dots bump` never downgrades unless you pass `--force`.
- `update-sources --revert APP` restores an app's pin from git HEAD.
