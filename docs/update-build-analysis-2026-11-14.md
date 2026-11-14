# Slow dots updates: 2026-11-14

## Confirmed cause and fix

`pkgs/default.nix` overrode Anyrun, Scooter, Figma Agent and FFF's native
library to add missing native dependencies. Those fixes were necessary for
earlier recipes: retained November 11 build logs show missing AWS-LC,
libgit2, zstd/pkg-config and Oniguruma failures.

The current root nixpkgs pin, `d4f25a3e562008648d45bcf2d70bcc7422cad84e`,
already includes all four fixes. The overrides appended duplicate inputs,
changing derivations and output paths even though versions were unchanged.
Removed these redundant overrides to restore the upstream package paths.

Read-only HTTP checks against `https://cache.nixos.org/<hash>.narinfo`:

| Package | Overridden output | Upstream output |
| --- | --- | --- |
| Anyrun 26.10.0 | 404 | 200 |
| Scooter 0.10.0 | 404 | 200 |
| Figma Agent 0.4.3 | 404 | 200 |
| FFF Neovim plugin 0.11.0 | 404 | 200 |

FFF's upstream native library also returned HTTP 200. After removing the
overrides, evaluated the actual NixOS package set and verified all five
output paths exactly match a plain import of the same nixpkgs pin.

The full system `nix build --dry-run --no-link --no-update-lock-file`
completed successfully and selected these five outputs for fetching:
**45.9 MiB download, 135.4 MiB unpacked**, instead of rebuilding their Rust
code. Other configuration/wrapper derivations still need building normally.

## Measured compilation cost

November 14 local build logs under `/nix/var/log/nix/drvs` report:

| Package | Build phase | Check phase |
| --- | --- | --- |
| FFF native library | 16m 9s | 7m 49s |
| Anyrun | 3m 10s | release test compilation reported 9s |
| Scooter | 2m 31s | disabled by upstream |
| Figma Agent | 53s | release test compilation reported 2.6s |

This establishes roughly 31 minutes of Rust build/check work, not a measured
explanation of the entire reported 1–2 hour update. Downloads, other builds,
evaluation and activation need separate timing to account for the remainder.
The machine permits one Nix build at a time, with eight cores per build
(`max-jobs = 1`, `cores = 8`). This serializes these costs; the configuration
documents that limit as protection against laptop thermal throttling.

## Other findings from the initial investigation

- Previously, `dots update` ran `nix flake update` on every normal update. Changes to
  compilers, libraries and build hooks can change package paths even if the
  application version stays the same. A new Rust derivation starts a fresh
  Cargo build; previous derivations' temporary Cargo target directories are
  not reused as an incremental compilation cache.
- The active daemon already uses `cache.nixos.org` and `niri.cachix.org`.
  The problem above is output identity, not a disabled official cache.
- The app-update workflow builds custom packages but never uploads the
  results to a persistent binary cache. CI success therefore does not make
  those custom builds downloadable on the laptop.
- CI builds app pins against its existing `flake.lock`; the previous
  `dots update` then updated that lock locally, changing derivations again.
- `pkgs/lib/crate.nix` intentionally compiles custom crates such as `loc`.
  Those need a published matching cache entry or a recipe using an upstream
  release binary to avoid local compilation.

## Follow-up fixes

Routine `dots update` now preserves flake inputs, matching the inputs used
in CI. `dots update --flake` explicitly requests a full input upgrade;
`--no-flake` remains accepted for compatibility. Builds and activation use
`--no-update-lock-file`. `dots plan` provides a build/download preview.

A failed switch keeps its lockfile for diagnosis/retry and reports that
activation may have partially completed. It does not commit or push the
failed update. Four regression tests cover pinned updates, explicit upgrades,
failure recovery and the dry-run preview.

The flake check `upstream-rust-packages` asserts that the actual NixOS package
set uses the upstream outputs for these five packages/libraries. CI evaluates
it on pushes and PRs, and in the app-update workflow. This checks output
identity, not whether upstream has published a binary yet. Full flake
evaluation (`nix flake check --no-build --no-update-lock-file`) passed locally.

The user chose the official caches rather than provisioning a custom Cachix
cache. Custom packages can still require local builds; CI documentation now
makes clear that validation does not publish downloadable outputs. Signature
verification, upstream tests and the laptop CPU limits remain enabled.

The pre-existing `flake.lock` update is included with these fixes so the
removed dependency workarounds are paired with the verified nixpkgs revision.
No full system build or activation was performed.
