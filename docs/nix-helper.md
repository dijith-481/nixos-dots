`nix-helper` finds tools and opens a temporary `nix-shell` by default, using
the nixpkgs revision in this checkout's `flake.lock` and its package overlay.
The shell uses your `$SHELL`, including Fish. Exit it normally to leave.

```sh
nix-helper ripgrep                    # exact package: open immediately
nix-helper rg                         # find the package providing rg; pick with fzf
nix-helper 'json formatter'           # search descriptions and suggest related packages
nix-helper ripgrepp                   # suggest approximate package names
nix-helper --search video            # print matches without opening a shell
nix-helper --command rg --search      # only executable providers
nix-helper --file /include/openssl/ssl.h --search
nix-helper --package ripgrep --run 'rg --version'
nix-helper --install rg               # choose, save, commit, build, switch
nix-helper --install --package ripgrep # skip the search/picker
```

Multiple query words form one search. An exact package name is selected
automatically; other queries open an fzf picker (Esc cancels). Search results
show why each package matched. Without a terminal, use `--search`, then
`--package ATTRIBUTE`. Use nested attributes such as `python3Packages.rich`.

The first search caches package metadata under `$XDG_CACHE_HOME/nix-helper`
(normally `~/.cache/nix-helper`); updating the nixpkgs pin creates a fresh cache.
Executable/file lookup downloads the upstream
[nix-index database](https://github.com/nix-community/nix-index-database).
It can lag or lead your pin, and doesn't index every package. Results are filtered
against the pinned catalog and selected packages are evaluated before use.
Use `--refresh-index` to fetch a newer database. Keyword searches still work if
automatic executable lookup is unavailable; explicit `--command` / `--file`
requests report that failure. Description/typo suggestions use local matching;
they aren't an AI or a general web search.

`--install` writes the attribute to
`hosts/celestia/modules/development/helper-packages.json`, imported by Home
Manager. It requires a clean checkout and commits only that file, then runs
`nixos-rebuild build` followed by `sudo nixos-rebuild switch`. Sudo may ask for
your password in the terminal. It does not push or update flake inputs. A failed
build/switch keeps the commit; retry the same command to finish activation.
To remove a helper-managed package, edit the JSON list, commit, and run `dots switch`.

`DOTS_FLAKE` / `--flake` and `DOTS_HOST` / `--host` override the existing defaults
(`/home/dijith/.Data/nixos-dots`, `nixos-celestia`). The managed package file is
specific to this checkout's Celestia Home Manager module. Before activation, run
the helper with `nix run .#nix-helper -- QUERY`.
