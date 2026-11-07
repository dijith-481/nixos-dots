"""Find packages by name, description, typo, or the executable they provide."""

import argparse
import difflib
import fcntl
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PACKAGE_FILE = Path("hosts/celestia/modules/development/helper-packages.json")
ATTRIBUTE = re.compile(r"[A-Za-z_][A-Za-z0-9_+\-]*(?:\.[A-Za-z_][A-Za-z0-9_+\-]*)*")


def say(message):
    print(f"nix-helper: {message}", file=sys.stderr, flush=True)


def run(argv, *, capture=False, **kwargs):
    return subprocess.run(argv, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None, **kwargs)


def nix_string(value):
    # JSON string escapes are compatible here, except Nix interpolation.
    return json.dumps(str(value)).replace("${", r"\${")


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as out:
        temporary = Path(out.name)
        try:
            out.write(content)
            out.flush()
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


class Helper:
    def __init__(self, flake, host):
        self.flake = Path(flake).expanduser().resolve()
        self.host = host
        self.cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "nix-helper"
        self.cache.mkdir(parents=True, exist_ok=True)
        self.source = run([
            "nix", "eval", "--raw", "--impure", "--expr",
            f"(builtins.getFlake {nix_string(self.flake)}).inputs.nixpkgs.outPath",
        ], capture=True).stdout

    def expression(self, attr, *, shell=False):
        if not ATTRIBUTE.fullmatch(attr):
            raise ValueError(f"Unsupported package attribute: {attr!r}")
        path = json.dumps(attr.split(".")).replace(",", " ")
        package = f'pkgs.lib.attrByPath {path} (throw "Package unavailable") pkgs'
        return (f"let pkgs = import {nix_string(self.source)} {{ "
                f"config.allowUnfree = true; overlays = [ (import "
                f"{nix_string(self.flake / 'pkgs')}) ]; }}; "
                f"in " + (f"pkgs.mkShell {{ packages = [ ({package}) ]; }}" if shell else package))

    def validate(self, attr):
        run(["nix", "eval", "--impure", "--raw", "--expr",
             f"({self.expression(attr)}).drvPath"], capture=True)

    def catalog(self):
        key = hashlib.sha256(self.source.encode()).hexdigest()[:20]
        path = self.cache / f"packages-{key}.json"
        if not path.exists():
            say("Indexing package names and descriptions for your nixpkgs pin (cached after this run)…")
            data = run(["nix", "search", "--quiet", f"path:{self.source}", "--json", "^"], capture=True).stdout
            json.loads(data)
            atomic_write(path, data)
        data = json.loads(path.read_text())
        # Include this checkout's overlay packages, including pinned upstream apps.
        local = run(["nix", "search", "--quiet", str(self.flake), "--json", "^"], capture=True).stdout
        data.update(json.loads(local))
        return {key.split(".", 2)[2]: value for key, value in data.items()}

    def refresh_index(self):
        import platform
        import urllib.request

        system = f"{platform.machine()}-{platform.system().lower()}"
        directory = self.cache / "index"
        directory.mkdir(parents=True, exist_ok=True)
        say("Downloading the upstream nix-index executable/file database…")
        url = ("https://github.com/nix-community/nix-index-database/releases/"
               f"latest/download/index-{system}")
        # Download completely before replacing the old database.
        with tempfile.NamedTemporaryFile(dir=directory, delete=False) as out:
            temporary = Path(out.name)
            try:
                with urllib.request.urlopen(url, timeout=120) as response:
                    shutil.copyfileobj(response, out)
                out.flush()
                os.replace(temporary, directory / "files")
            finally:
                temporary.unlink(missing_ok=True)

    def providers(self, query, *, file=False):
        if not (self.cache / "index/files").exists():
            self.refresh_index()
        args = ["nix-locate", "--db", str(self.cache / "index"),
                "--minimal", "--no-group"]
        if file:
            args += ["--", query]
        else:
            args += ["--type", "x", "--type", "s", "--whole-name", "--at-root",
                     "--", f"/bin/{query}"]
        output = run(args, capture=True).stdout
        # nix-locate returns attributes with an output suffix, e.g. ripgrep.out.
        return {line.rsplit(".", 1)[0] for line in output.splitlines()
                if ATTRIBUTE.fullmatch(line)}

    def search(self, query, *, command=False, file=False):
        providers = set()
        if command or file or (" " not in query and "/" not in query):
            try:
                providers = self.providers(query, file=file)
            except (subprocess.CalledProcessError, OSError) as error:
                if command or file:
                    raise
                say(f"Executable lookup failed ({error}); continuing with package search.")
        catalog = self.catalog()
        results = []
        words = query.lower().split()
        for attr in providers | catalog.keys():
            metadata = catalog.get(attr)
            if metadata is None:
                # The rolling executable index may be newer than this checkout.
                continue
            description = metadata.get("description", "")
            name = attr.lower()
            text = name + " " + description.lower()
            score = 0
            reason = "related"
            if attr in providers:
                score, reason = 100, "provides file" if file else "provides command"
            if name == query.lower():
                score, reason = 120, "exact package"
            elif not command and not file:
                if all(word in text for word in words):
                    score = max(score, 80 if query.lower() in name else 60)
                else:
                    similarity = difflib.SequenceMatcher(None, query.lower(), name.split(".")[-1]).ratio()
                    if similarity >= 0.65:
                        score = max(score, similarity * 50)
            if score:
                results.append((score, attr, description, reason))
        return sorted(results, key=lambda item: (-item[0], len(item[1]), item[1]))

    def install(self, attr):
        # Serialize modifications and keep other work out of the automatic commit.
        git_dir = run(["git", "-C", str(self.flake), "rev-parse", "--absolute-git-dir"], capture=True).stdout.strip()
        with open(Path(git_dir) / "nix-helper.lock", "w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise ValueError("Another nix-helper installation is running.") from None
            status = run(["git", "-C", str(self.flake), "status", "--porcelain"], capture=True).stdout
            if status:
                raise ValueError("Commit or stash existing checkout changes before --install.\n" + status)
            destination = self.flake / PACKAGE_FILE
            packages = json.loads(destination.read_text())
            if not isinstance(packages, list) or not all(isinstance(p, str) for p in packages):
                raise ValueError(f"Expected a JSON list of package attributes in {destination}")
            if attr not in packages:
                atomic_write(destination, json.dumps(sorted(set(packages + [attr])), indent=2) + "\n")
                run(["git", "-C", str(self.flake), "add", "--", str(PACKAGE_FILE)])
                run(["git", "-C", str(self.flake), "commit", "-m", f"feat(packages): install {attr}",
                     "--", str(PACKAGE_FILE)])
            else:
                say(f"{attr} is already recorded; rebuilding to finish activation.")
            target = f"{self.flake}#{self.host}"
            say("Building the committed configuration…")
            try:
                run(["nixos-rebuild", "build", "--flake", target, "--no-update-lock-file"], cwd=self.flake)
                say("Activating the configuration; sudo may ask for your password…")
                run(["sudo", "nixos-rebuild", "switch", "--flake", target, "--no-update-lock-file"], cwd=self.flake)
            except subprocess.CalledProcessError:
                say(f"The package commit is retained. Retry: nix-helper --install --package {shlex.quote(attr)}")
                raise


def choose(results, query):
    if not results:
        raise ValueError("No matching packages. Try a broader keyword, --command NAME, or --file PATH.")
    # Exact package names are unambiguous; never auto-pick an approximate match.
    if results[0][1] == query:
        return results[0][1]
    if not sys.stdin.isatty():
        raise ValueError("Selection needs a terminal. Use --search, then --package ATTRIBUTE.")
    rows = "\n".join(f"{attr}\t{reason}\t{' '.join(description.split())}"
                     for _, attr, description, reason in results)
    picked = subprocess.run(["fzf", "--delimiter=\t", "--prompt=Package > ",
                             "--header=Enter: select package | Esc: cancel", "--height=70%"],
                            input=rows, text=True, stdout=subprocess.PIPE, check=False)
    if picked.returncode in (1, 130):
        raise SystemExit(130)
    picked.check_returncode()
    return picked.stdout.split("\t", 1)[0]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        "Default: select a package and open nix-shell. --install records it in the "
        "config, commits, builds, and switches (sudo may request your password)."))
    parser.add_argument("query", nargs="*", help="package, executable, keyword, or approximate name")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("-s", "--search", action="store_true", help="show matches without entering a shell")
    action.add_argument("-i", "--install", action="store_true", help="save, commit, build, and activate the selected package")
    lookup = parser.add_mutually_exclusive_group()
    lookup.add_argument("-c", "--command", action="store_true", help="find packages providing this executable")
    lookup.add_argument("--file", action="store_true", help="find packages containing this literal file path")
    lookup.add_argument("-p", "--package", help="use an exact package attribute; skip search and selection")
    parser.add_argument("--run", help="run a shell command inside nix-shell, then exit")
    parser.add_argument("--refresh-index", action="store_true", help="refresh the upstream executable/file database")
    parser.add_argument("--flake", default=os.environ.get("DOTS_FLAKE", "/home/dijith/.Data/nixos-dots"))
    parser.add_argument("--host", default=os.environ.get("DOTS_HOST", "nixos-celestia"))
    args = parser.parse_args(argv)
    query = " ".join(args.query).strip()
    if args.run is not None and (args.search or args.install):
        parser.error("--run is only available in shell mode")
    if args.package and query:
        parser.error("use either a query or --package ATTRIBUTE")
    helper = Helper(args.flake, args.host)
    if args.refresh_index:
        helper.refresh_index()
        if not query and not args.package:
            return
    if not query and not args.package:
        parser.error("provide a package, command, or keyword")
    if args.package:
        attr = args.package
    else:
        results = helper.search(query, command=args.command, file=args.file)
        if args.search:
            for _, attr, description, reason in results[:80]:
                print(f"{attr}\t{reason}\t{' '.join(description.split())}")
            if not results:
                raise ValueError("No matching packages.")
            say("Try: nix-helper --package ATTRIBUTE  |  nix-helper --install --package ATTRIBUTE")
            return
        attr = choose(results, query)
    helper.validate(attr)
    if args.search:
        print(attr)
    elif args.install:
        helper.install(attr)
    else:
        say(f"Opening nix-shell with {attr}. Permanent install: nix-helper --install --package {attr}")
        expression = helper.expression(attr, shell=True)
        command = ["nix-shell", "--expr", expression]
        if args.run is not None:
            command += ["--run", args.run]
        else:
            shell = os.environ.get("SHELL")
            if shell and Path(shell).is_file():
                command += ["--run", "exec " + shlex.quote(shell)]
        os.execvp(command[0], command)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        say(str(error))
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
