Neovim performance profiling and optimization — 25 October 2026

The largest confirmed startup hang is synchronous LSP file-watcher registration inside Neovim. Language servers run in separate processes, but their client handlers, directory walks, Tree-sitter work, plugin callbacks and drawing run on Neovim's main thread. Moving a callback into `vim.schedule()` or `vim.defer_fn()` changes when it runs; it does not move that work to another thread.

The baseline measurements below were taken before changing the workspace configuration. A follow-up profile after the changes used the same 160×48 embedded UI, Rust and TypeScript files, LSP combinations, 240 paced motions/keystrokes, and isolated Neovim state under `/tmp/nvim-perf`. No edited buffer was saved.

Detailed JSON, startup logs and reproduction scripts are saved in:

`/home/dijith/.codex/visualizations/2026/10/25/01a171f1-abcc-7431-a275-015e1e9d458d/neovim-profile/`

The live Lua configuration matched `config/nvim/lua` when inspected. The running installation also contains an old downloaded plugin tree in addition to the Nix-managed plugins, which is important to the findings below.

The final post-change measurements are saved beside the baseline data as `post-optimization-final.json`.

1. **LSP file watchers cause multi-second main-thread stalls. Highest priority.**

   `inotifywait` is absent from Neovim's PATH. In the installed runtime, `lua/vim/lsp/_watchfiles.lua:50` selects the Linux `vim._watch.watchdirs` fallback when that executable is missing. `lua/vim/_watch.lua:222` recursively enumerates directories with `vim.fs.dir(path, { depth = 100 })` synchronously. Exclusion checks happen after traversal has yielded directory entries, so they do not prevent the iterator from descending into dependency trees.

   LuaJIT sampling during typing in `bots-v2-ui` showed `vim.fs.dir` and path construction as the leading sampled stacks. Instrumenting the actual watcher backend measured three registrations over the same project root taking **4,533 ms, 2,811 ms and 2,990 ms**. Those are direct durations of blocking backend calls, not language-server response times.

   A separate comparison disabled dynamic watcher registration for Biome and Tailwind while preserving **Biome, Tailwind and typescript-tools**, all confirmed initialized. No client-side watcher registrations occurred in that run. The worst input/RPC response fell from **5,838 ms** in the instrumented baseline to **192 ms**. These are individual runs under changing system load, not a guaranteed speedup ratio.

   Recommended first change: add `inotify-tools` to `programs.neovim.extraPackages` in `hosts/celestia/modules/development/neovim.nix`. The installed Neovim then selects its external `inotifywait` backend and avoids this synchronous Lua directory walk. That backend change has not yet been benchmarked because the executable is not installed. Disabling dynamic watchers is a verified diagnostic workaround, but affects notifications about external filesystem changes; the external backend is the preferred first fix.

The following input measurements used 240 paced motions/keystrokes, including insert-mode typing, while servers started. Each measurement includes sending input and receiving a subsequent RPC response. An independent 10 ms main-loop timer corroborated the long stalls. These are responsiveness proxies, not terminal-to-screen hardware measurements. p95 means 95% of samples were at or below that value.

| Repository / comparison | Median input response | p95 | Worst response |
| --- | ---: | ---: | ---: |
| `learn-linux`, LSP enabled | 9.8 ms | 53.1 ms | 280 ms |
| `learn-linux`, LSP disabled | 6.8 ms | 36.9 ms | 274 ms |
| `bots-v2-ui`, LSP enabled | 8.8 ms | 53.8 ms | 2,403 ms |
| `bots-v2-ui`, LSP disabled | 6.0 ms | 22.1 ms | 175 ms |
| `bots-v2-ui`, instrumented watcher baseline | 30.7 ms | 141.1 ms | 5,838 ms |
| `bots-v2-ui`, watchers disabled, all three LSP clients enabled | 13.7 ms | 42.7 ms | 192 ms |

2. **The custom status column adds significant redraw work.**

   In `config/nvim/lua/plugins/statuscol.lua`, `get_current_fold_range` walks upward and downward through fold levels. Moving the cursor changes its cache key, so a new position can repeat a scan over a large scope. This happens in the rendering path. The shared caches are keyed by line number and changedtick without consistently including buffer/window identity; some invalidations also leave the derived context cache intact. This can produce stale display state as well as unnecessary work.

   Across four alternating trials of 100 cursor jumps in the 3,900-line `learn-tui/src/lib.rs`, median cursor-move-plus-redraw time was **7.66 ms** with the current column and **3.00 ms** with it disabled. p95 was 22.35 ms versus 16.41 ms. Tree-sitter and LSP remained enabled. Replace scope-wide scanning with a bounded/cached scope lookup, or use a simpler status column. Preserve buffer/window identity and invalidate derived state correctly.

3. **Snacks deliberately searches ignored dependency and build output.**

   `config/nvim/lua/plugins/snacks.lua:59` sets `picker.sources.files.ignored = true`, affecting the secondary `,f` file picker. This is separate from FFF on `<leader>f`.

| Repository | Snacks with ignored files | Time until finder idle | Respecting ignore rules | Time until finder idle |
| --- | ---: | ---: | ---: | ---: |
| `bots-v2-ui` | 182,750 entries | 1,026 ms | 1,700 entries | 297 ms |
| `learn-linux` | 46,790 entries | 249 ms | 58 entries | 16 ms |

   These timings include collecting picker entries, not just running `rg`. The first run also bears some cold picker initialization. The candidate-count explosion is independently confirmed by file inventory. Set `ignored = false` by default and expose an explicit action for searching ignored output.

4. **FFF's matching is fast; its first-use UI path has a noticeable pause.**

| Repository | FFF indexed files | Native search median / p95 | First picker open | Warm picker open | First insert setup |
| --- | ---: | ---: | ---: | ---: | ---: |
| `personal/file-manager` | 27 | 0.33 / 0.68 ms | 160 ms | 33 ms | 153 ms |
| `foss/learn-linux` | 58 | 0.55 / 0.77 ms | 85 ms | 44 ms | 55 ms |
| `logai/bots-v2-ui` | 2,487 | 1.99 / 2.81 ms | 124 ms | 44 ms | 122 ms |
| `logai/logai-ui-v2` | 10,350 | 3.80 / 7.58 ms | 74 ms | 38 ms | 135 ms |

   Native search timings cover 100 calls across `main`, `lib`, `src`, `index` and `config`. Picker timings include a forced redraw. Preview caches and OS caches were not flushed. These figures do not indicate a broken fuzzy matcher. FFF's default `lazy_sync = true` and your lazy plugin setup put initialization on first use. Completion similarly loads a substantial group synchronously on `InsertEnter` in `plugins/init.lua`.

   FFF's `logai-ui-v2` index includes 5,156 files under `.claude` and 2,576 under the nested `logai-ecom` tree. Its broader candidate set explains part of the difference from the 2,604-file ripgrep inventory. Add a project `.ignore` for worktrees or nested projects you do not want in the picker; FFF's installed documentation supports this. Warm the native module/index after the first frame if first-open responsiveness matters, and measure that initialization separately from typing. Deferred synchronous initialization still blocks when it executes.

5. **Supermaven performs full-buffer copying on the UI thread.**

   Its installed `util.get_text()` reads every line and concatenates the whole buffer. The sampled stacks repeatedly reached that function from document updates and background submission. `binary_handler.lua:87` copies the buffer before checking its size limit. Supermaven remained prominent even with language servers disabled, so removing LSP alone does not remove this workload.

   Scope Supermaven away from large/generated buffers, or reduce/disable automatic background work there. Stopping Supermaven did not eliminate the multi-second watcher scans in the additional comparison; these are independent sources of work. Tree-sitter highlighting also appears prominently in the typing profiles. Avoid treating all typing lag as LSP computation.

6. **Large-file protection misses files opened on the command line.**

   Snacks, including `bigfile`, initializes after `UIEnter`. Opening `logai-ui-v2/src/api/generated/types.gen.ts` after that event classified the 1.77 MB / 77,430-line file as `bigfile` and took 48 ms in the open/redraw measurement. Launching `nvim src/api/generated/types.gen.ts` classified the same file as `typescript`; first screen took 613 ms and the language/syntax integrations were eligible to start normally.

   Initialize the large-file guard before initial buffer detection and make Tree-sitter, LSP, completion and AI integrations honor it. This timing is not directly comparable to the 48 ms open measurement because CLI startup also includes editor initialization; the confirmed bug is the different filetype/protection behavior.

7. **Old plugins and Nix plugins are both activated.**

   `~/.local/share/nvim/site/pack/core/opt` contains the previous downloaded plugins; `pack/hm/opt` contains Nix plugins. `Config.packadd` invokes `:packadd`, which finds both matching packages. `:scriptnames` confirmed plugin scripts from both trees, including lspconfig, Blink, Snacks, Tree-sitter-related plugins and FFF. This mixes plugin generations and runtime queries, even when the required Lua module comes from the Nix tree.

   Restrict activation to the Nix-managed pack tree or retire the old tree after preserving anything needed. No plugin directories were removed during profiling. A specific fraction of the total latency has not been attributed to duplication, so this is a confirmed runtime consistency problem rather than a quantified speedup claim.

8. **TypeScript services have substantial memory overhead.**

   At the 12-second snapshots, Neovim and its descendant processes used approximately **3.49 GiB RSS** for `bots-v2-ui` and **3.70 GiB RSS** for `logai-ui-v2`. RSS totals can double-count shared pages. In the latter, the two TypeScript processes were each around 1.5 GiB RSS. typescript-tools defaults to a separate diagnostic server, alongside Tailwind and other services; these two TypeScript processes are intentional, not evidence of duplicate LSP clients.

   Evaluate `settings.separate_diagnostic_server = false` on the larger repos and compare completion/diagnostic latency before making it universal. This option has not been benchmarked here. One successful `logai-ui-v2` completion request took 2,326 ms while document symbols took 21 ms; server response latency and main-thread blocking are different measurements. A request sequence in `bots-v2-ui` exceeded the harness's RPC timeout, so it is not reported as a reliable completion-latency measurement.

9. **LSP event hooks have reproducible scope/lifetime bugs.**

   `config/nvim/lua/lsp.lua` installs document-highlight and clear-reference hooks for every supporting client attachment, with no per-buffer deduplication. A controlled three-attachment reproduction produced three highlight calls for one `CursorHold`. Reattachments or multiple supporting servers can multiply requests. Inlay hints are enabled globally in the same hook.

   Its `LspProgress` handler updates the current window's folding on every supported client's progress-end event, regardless of the buffer that client serves. A controlled reproduction changed an unrelated window's `foldexpr` to the LSP expression with zero clients attached to that buffer. Configure folding once for the attached buffer and its windows, and create one highlight hook set per buffer with cleanup on detach.

10. **Other synchronous work and language-selection issues deserve follow-up.**

   Rust Analyzer explicitly enabled all Cargo features in `plugins/rustaceanvim.lua`; rust-analyzer documents an empty feature list as its default, so forcing `all` can expand dependency work. Build scripts were also enabled, though rust-analyzer already enables them by default. Rustaceanvim selects Clippy for save checks when available; Clippy activity was observed. No controlled save-time comparison was run for features, build scripts or Clippy.

   `autocmd.lua` runs `silent !dx fmt --file %` synchronously after Rust saves when the current directory contains `Dioxus.toml`. Conform also uses synchronous format-on-save with a 500 ms timeout. Save actions were inspected but deliberately not benchmarked against working source files. The Dioxus hook has no explicit timeout.

   `nvim-lint.lua` and `conform.lua` computed project-specific choices from the Neovim launch directory. Linting also ran on every `BufEnter` and `InsertLeave`. `typescript-tools.lua` checked `deno.json` only under the launch directory and placed `expose_as_code_action` and `complete_function_calls` outside its `settings` table.

11. **Follow-up changes and post-change profile.**

   The Nix Neovim wrapper now includes `inotify-tools`. I rebuilt the wrapper and confirmed that `inotifywait` resolves from its store path. On `bots-v2-ui`, Biome, Tailwind and typescript-tools all initialized; the three watcher registrations took **5.8 ms, 4.6 ms and 5.9 ms**. The previous runs measured multi-second registrations. In the paced typing comparison, the TypeScript LSP run's worst response fell from **2,403 ms to 236 ms**. Its median/p95 changed from **8.8/53.8 ms to 12.9/87.1 ms**, so ordinary latency varied between runs even though the multi-second stall disappeared.

   | Repository / mode | Before median / p95 / max | After median / p95 / max |
   | --- | ---: | ---: |
   | `learn-linux`, Rust Analyzer enabled | 9.8 / 53.1 / 280 ms | 11.4 / 53.3 / 322 ms |
   | `learn-linux`, LSP disabled | 6.8 / 36.9 / 274 ms | 5.9 / 28.6 / 315 ms |
   | `bots-v2-ui`, three LSP clients enabled | 8.8 / 53.8 / 2,403 ms | 12.9 / 87.1 / 236 ms |
   | `bots-v2-ui`, LSP disabled | 5.9 / 22.1 / 175 ms | 5.6 / 32.2 / 168 ms |

   The status-column scope lookup now caches a fold range per buffer/change tick instead of rescanning at each cursor position. Blink uses its built-in renderer and the Rust/TypeScript hot path is limited to LSP, path, snippets and the current buffer. Shell, Markdown and commit-only sources load for their matching filetypes. Supermaven reuses buffer text for cursor-only events and checks a size bound before copying; large/generated files skip it. Large-file detection now runs before command-line filetype detection, and Tree-sitter stays unloaded until a non-large buffer needs it. Snacks respects repository ignore rules while still showing hidden files.

   FFF's native matcher needed no change: its baseline median was **1.99 ms** in the 2,487-file `bots-v2-ui` repository and **3.80 ms** in a 10,350-file project. The noticeable secondary picker path was Snacks traversing ignored files, which the new configuration avoids.

   TypeScript server selection, Conform and nvim-lint now use the current buffer's project root. Deno projects avoid tsserver attachment, and lint no longer starts on every buffer switch. Rust Analyzer no longer forces all Cargo features; it still uses rust-analyzer's default build-script behavior, and rustaceanvim's default Clippy-on-save behavior remains. Dioxus formatting runs asynchronously after save. LSP reference hooks are deduplicated by buffer, inlay hints are enabled only for supporting clients, and folding updates apply only to windows showing attached buffers. `Config.packadd` selects the Home Manager plugin path directly so stale `pack/core` copies do not load alongside Nix-managed plugins.

   A one-off **168 ms** input response remained on the TypeScript file with LSP disabled, and the maximum Rust response was **322 ms** with LSP disabled. The strongest remaining samples were Tree-sitter parsing/highlighting and initial UI work, also present with LSP disabled. A separate warmed insert-mode check measured **132 ms** to enter insert mode in the Rust file and **12 ms** for the next key; the TypeScript file measured **168 ms** and then **18 ms**. This isolates a one-time parse/redraw cost from steady-state LSP typing.

   Blink setup is scheduled shortly after the first UI frame to keep it out of the first typed character. The completion source set follows Blink's built-in providers, with optional providers limited by filetype. Home Manager's declarative Nix package configuration remains in place. The built wrapper still uses Neovim 0.12.6; official 0.13 notes describe unreleased HEAD features, so this change does not move the system to a development build. See [Blink source configuration](https://cmp.saghen.dev/configuration/sources.html), [Home Manager's Neovim module](https://home-manager.dev/manual/unstable/options/home-manager/programs/neovim.html), and [Neovim development notes](https://neovim.io/doc/user/news/).

   The wrapper build and Lua syntax/config startup checks passed. The Nix generation was not activated; the running system needs the usual Home Manager/NixOS switch to pick up the new package and config.

The initial recommendations are reflected in the follow-up changes above. One remaining tuning choice is reducing TypeScript's separate diagnostic server; it can lower memory use but may change diagnostic/completion latency, and this run did not compare those modes.

Measurement limits: this was a set of local snapshots, not an isolated-machine benchmark. Host I/O pressure and memory availability varied, and caches warmed between trials. The initial filesystem sandbox suppressed Node output on Neovim's subprocess handles; a normal-I/O control confirmed that artifact. TypeScript baseline measurements and all paced typing comparisons were rerun outside the sandbox. Initial Rust picker/redraw measurements were sandboxed; the later Rust typing/LSP comparison used normal subprocess I/O with Cargo offline. These runs do not establish fully cold Cargo build performance. Large synchronous batches in `profile.py` intentionally delay its timer, so only the paced `startup_latency.py` results are used for main-loop/input stall claims. One early watcher experiment accidentally prevented TypeScript attachment; its raw result is marked invalid and superseded by `watcher-fixed.json`, which confirms all three clients remained active.
