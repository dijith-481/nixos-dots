#!/usr/bin/env python3
"""Resolve pkgs/sources.toml recipes into pinned versions + hashes.

Reads   pkgs/sources.toml       (recipes, hand-written)
Writes  pkgs/sources.lock.json  (version/url/hash per app per system)
        pkgs/locks/<app>/       (npm package-lock.json / Cargo.lock when needed)

Usage:
  update-sources [APP ...]          bump the given apps (default: all)
  update-sources --dry-run          show what would change, write nothing
  update-sources --list             show pinned versions
  update-sources --revert APP ...   restore APP's lock entry from git HEAD
  update-sources --force            allow downgrades / re-resolve unchanged apps

Only the standard library is used, plus `nix`, `npm` and `cargo` on PATH for
hashing files and generating dependency lockfiles.
"""

from __future__ import annotations

import argparse
import base64
import gzip
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import tomllib
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def repo_root() -> Path:
    if env := os.environ.get("DOTS_ROOT"):
        return Path(env)
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    if out.returncode != 0:
        sys.exit("update-sources: run inside the nixos-dots checkout (or set DOTS_ROOT)")
    return Path(out.stdout.strip())


ROOT = repo_root()
RECIPES = ROOT / "pkgs" / "sources.toml"
LOCK = ROOT / "pkgs" / "sources.lock.json"
LOCKS_DIR = ROOT / "pkgs" / "locks"
LOCK_REL = "pkgs/sources.lock.json"

USER_AGENT = "nixos-dots-update-sources (+https://github.com/dijith-481/nixos-dots)"


class SourceError(Exception):
    pass


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


# ─── versions ───────────────────────────────────────────────────────────────


def _tokens(s: str) -> list[tuple[int, int | str]]:
    return [(1, int(t)) if t.isdigit() else (0, t) for t in re.findall(r"\d+|[A-Za-z]+", s)]


def vkey(v: str):
    """Sort key: numeric-aware, releases above their pre-releases (1.0.0-rc.1 < 1.0.0)."""
    v = v.strip().lstrip("vV")
    main, sep, pre = v.partition("-")
    return (_tokens(main), 0 if sep else 1, _tokens(pre))


def newer(a: str, b: str) -> bool:
    return vkey(a) > vkey(b)


# ─── http ───────────────────────────────────────────────────────────────────


def _request(url: str, method: str = "GET", headers: dict | None = None):
    h = {"User-Agent": USER_AGENT, **(headers or {})}
    host = urllib.parse.urlparse(url).hostname or ""
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token and host == "api.github.com":
        h["Authorization"] = f"Bearer {token}"
    return urllib.request.Request(url, method=method, headers=h)


def fetch(url: str, *, retries: int = 3) -> bytes:
    last: Exception | None = None
    for _ in range(retries):
        try:
            with urllib.request.urlopen(_request(url), timeout=60) as r:
                data = r.read()
                if url.endswith(".gz") or r.headers.get("Content-Encoding") == "gzip":
                    data = gzip.decompress(data)
                return data
        except urllib.error.HTTPError as e:
            if 400 <= e.code < 500 and e.code != 429:
                raise SourceError(f"GET {url}: HTTP {e.code}") from e
            last = e
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            last = e
    raise SourceError(f"GET {url}: {last}")


def fetch_json(url: str):
    try:
        return json.loads(fetch(url))
    except json.JSONDecodeError as e:
        raise SourceError(f"{url}: not JSON ({e})") from e


def url_exists(url: str) -> bool:
    for method in ("HEAD", "GET"):
        req = _request(url, method, {"Range": "bytes=0-0"} if method == "GET" else None)
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return 200 <= r.status < 300
        except urllib.error.HTTPError as e:
            if e.code in (403, 405) and method == "HEAD":
                continue  # some CDNs reject HEAD
            return False
        except (urllib.error.URLError, TimeoutError, OSError):
            return False
    return False


# ─── hashes ─────────────────────────────────────────────────────────────────


def to_sri(value: str, algo: str = "sha256") -> str:
    """Accept SRI, `algo:hex`, bare hex or bare base64 and return SRI."""
    value = value.strip()
    if re.fullmatch(r"sha(256|512)-[A-Za-z0-9+/=]+", value):
        return value
    if ":" in value:
        algo, value = value.split(":", 1)
    if re.fullmatch(r"[0-9a-fA-F]+", value):
        raw = bytes.fromhex(value)
    else:
        raw = base64.b64decode(value)
    expected = {"sha256": 32, "sha512": 64}[algo]
    if len(raw) != expected:
        raise SourceError(f"hash {value!r} is not a {algo} digest")
    return f"{algo}-{base64.b64encode(raw).decode()}"


def store_name(url: str) -> str:
    base = urllib.parse.unquote(url.rsplit("/", 1)[-1].split("?", 1)[0])
    return re.sub(r"[^A-Za-z0-9+\-._?=]", "-", base).lstrip(".") or "source"


def prefetch(url: str) -> str:
    log(f"    hashing {url}")
    out = subprocess.run(
        ["nix", "store", "prefetch-file", "--json", "--hash-type", "sha256",
         "--name", store_name(url), url],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise SourceError(f"prefetch {url} failed:\n{out.stderr.strip()}")
    return json.loads(out.stdout)["hash"]


# ─── helpers ────────────────────────────────────────────────────────────────


def dig(obj, path: str):
    """Tiny JSON path: 'a.b.0.c'. Empty path = the object itself."""
    if path in ("", "."):
        return obj
    for part in path.split("."):
        if isinstance(obj, list):
            obj = obj[int(part)]
        elif isinstance(obj, dict) and part in obj:
            obj = obj[part]
        else:
            raise SourceError(f"field {path!r} not found")
    return obj


def render(template: str, vars: dict) -> str:
    try:
        return template.format(**vars)
    except KeyError as e:
        raise SourceError(f"template {template!r} uses unknown var {e}") from e


class App:
    def __init__(self, name: str, spec: dict, current: dict | None):
        self.name = name
        self.spec = spec
        self.current = current or {}
        self.systems: list[str] = spec.get("systems", ["x86_64-linux"])
        self.arch: dict = spec.get("arch", {})
        self.pick: str = spec.get("pick", "first")
        self.strategies: list[dict] = spec.get("source", [])
        if not self.strategies:
            raise SystemExit(f"sources.toml: [{name}] has no [[{name}.source]]")

    def arch_of(self, system: str) -> str:
        return self.arch.get(system, system.split("-")[0])


# A strategy returns: {"version", "vars", "sources": {system: {"url", "hash"|None}}}


def s_apt(app: App, src: dict) -> dict:
    per_system: dict[str, dict[str, dict]] = {}
    for system in app.systems:
        base = f"{src['repo'].rstrip('/')}/dists/{src['dist']}/{src.get('component', 'main')}/binary-{app.arch_of(system)}"
        try:
            text = fetch(base + "/Packages").decode()
        except SourceError:
            text = fetch(base + "/Packages.gz").decode()
        found = {}
        for stanza in text.split("\n\n"):
            fields = dict(
                (k.strip(), v.strip())
                for k, _, v in (line.partition(":") for line in stanza.splitlines() if line and not line[0].isspace())
            )
            if fields.get("Package") == src["package"] and "Filename" in fields:
                found[fields["Version"]] = {
                    "url": f"{src['repo'].rstrip('/')}/{fields['Filename']}",
                    "hash": to_sri(fields["SHA256"]) if "SHA256" in fields else None,
                }
        if not found:
            raise SourceError(f"package {src['package']} not in {base}/Packages")
        per_system[system] = found
    common = set.intersection(*(set(v) for v in per_system.values()))
    if not common:
        raise SourceError("no version published for every system")
    version = max(common, key=vkey)
    return {"version": version, "vars": {}, "sources": {s: per_system[s][version] for s in app.systems}}


def s_github_release(app: App, src: dict) -> dict:
    repo = src["repo"]
    if src.get("prerelease", False):
        releases = [r for r in fetch_json(f"https://api.github.com/repos/{repo}/releases?per_page=30") if not r["draft"]]
        if not releases:
            raise SourceError(f"{repo}: no releases")
        release = releases[0]
    else:
        release = fetch_json(f"https://api.github.com/repos/{repo}/releases/latest")
    tag = release["tag_name"]
    prefix = src.get("tag-prefix", "v")
    version = tag[len(prefix):] if tag.startswith(prefix) else tag
    assets = {a["name"]: a for a in release["assets"]}
    sources = {}
    for system in app.systems:
        name = render(src["asset"], {"version": version, "arch": app.arch_of(system), "tag": tag})
        if name not in assets:
            raise SourceError(f"{repo} {tag}: no asset {name}")
        a = assets[name]
        sources[system] = {
            "url": a["browser_download_url"],
            "hash": to_sri(a["digest"]) if a.get("digest") else None,
        }
    return {"version": version, "vars": {"tag": tag}, "sources": sources}


def _npm_meta(package: str) -> dict:
    return fetch_json("https://registry.npmjs.org/" + urllib.parse.quote(package, safe="@"))


def s_npm(app: App, src: dict) -> dict:
    tag = src.get("tag", "latest")
    sources, version = {}, None
    for system in app.systems:
        pkg = render(src["package"], {"arch": app.arch_of(system)})
        meta = _npm_meta(pkg)
        v = meta.get("dist-tags", {}).get(tag)
        if not v:
            raise SourceError(f"npm {pkg}: no dist-tag {tag!r}")
        if version and v != version:
            raise SourceError(f"npm {pkg}: {v} differs from {version} on another system")
        version = v
        dist = meta["versions"][v]["dist"]
        sources[system] = {"url": dist["tarball"], "hash": to_sri(dist["integrity"]) if "integrity" in dist else None}
    return {"version": version, "vars": {}, "sources": sources}


def s_crate(app: App, src: dict) -> dict:
    crate = src["crate"]
    meta = fetch_json(f"https://crates.io/api/v1/crates/{crate}")["crate"]
    version = meta.get("max_stable_version") or meta["max_version"]
    info = fetch_json(f"https://crates.io/api/v1/crates/{crate}/{version}")["version"]
    url = f"https://static.crates.io/crates/{crate}/{crate}-{version}.crate"
    return {
        "version": version,
        "vars": {},
        "sources": {s: {"url": url, "hash": to_sri(info["checksum"])} for s in app.systems},
    }


def s_json(app: App, src: dict) -> dict:
    sources, version, vars_out = {}, None, {}
    for system in app.systems:
        doc = fetch_json(render(src["url"], {"arch": app.arch_of(system)}))
        vpath = src.get("version", "version")
        if "items" in src:
            items = dig(doc, src["items"])
            if not isinstance(items, list) or not items:
                raise SourceError("`items` is not a non-empty list")
            item = max(items, key=lambda i: vkey(str(dig(i, vpath))))
        else:
            item = doc
        v = str(dig(item, vpath)).lstrip("v")
        if version and v != version:
            raise SourceError(f"{v} differs from {version} on another system")
        version = v
        vars_out = {k: str(dig(item, p)) for k, p in src.get("vars", {}).items()}
        entry = {"url": None, "hash": None}
        if "url-field" in src:
            entry["url"] = dig(item, src["url-field"])
        if "hash-field" in src:
            entry["hash"] = to_sri(str(dig(item, src["hash-field"])), src.get("hash-algo", "sha256"))
        sources[system] = entry
    return {"version": version, "vars": vars_out, "sources": sources}


def _bumps(v: str) -> list[str]:
    m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", v)
    if not m:
        return []
    a, b, c = map(int, m.groups())
    return [f"{a}.{b}.{c + i}" for i in (1, 2, 3)] + [f"{a}.{b + 1}.0", f"{a + 1}.0.0"]


def s_probe(app: App, src: dict) -> dict:
    current = app.current.get("version")
    if not current:
        raise SourceError("probe needs an existing pinned version to start from")
    system = app.systems[0]
    best = current
    while True:
        for cand in _bumps(best):
            if url_exists(render(src["url"], {"version": cand, "arch": app.arch_of(system)})):
                best = cand
                break
        else:
            break
    sources = {
        s: {"url": render(src["url"], {"version": best, "arch": app.arch_of(s)}), "hash": None}
        for s in app.systems
    }
    return {"version": best, "vars": {}, "sources": sources}


STRATEGIES = {
    "apt": s_apt,
    "github-release": s_github_release,
    "npm": s_npm,
    "crate": s_crate,
    "json": s_json,
    "probe": s_probe,
}


def run_strategy(app: App, src: dict) -> dict:
    kind = src.get("type")
    if kind not in STRATEGIES:
        raise SystemExit(f"sources.toml: [{app.name}] unknown source type {kind!r}")
    res = STRATEGIES[kind](app, src)
    if "download" in src:
        for system in app.systems:
            url = render(src["download"], {**res["vars"], "version": res["version"], "arch": app.arch_of(system)})
            res["sources"][system] = {"url": url, "hash": None}
    for system, entry in res["sources"].items():
        if not entry.get("url"):
            raise SourceError(f"no download URL for {system}")
    if src.get("verify", "download" in src or kind == "json"):
        for entry in res["sources"].values():
            if not url_exists(entry["url"]):
                raise SourceError(f"{entry['url']} does not exist (yet)")
    res["type"] = kind
    res["spec"] = src
    return res


def resolve(app: App) -> dict:
    results, errors = [], []
    for i, src in enumerate(app.strategies, 1):
        label = f"{src.get('type')}#{i}"
        try:
            res = run_strategy(app, src)
            log(f"    {label}: {res['version']}")
            results.append(res)
            if app.pick == "first":
                break
        except SourceError as e:
            log(f"    {label}: failed — {e}")
            errors.append(f"{label}: {e}")
    if not results:
        raise SourceError("every strategy failed:\n      " + "\n      ".join(errors))
    return max(results, key=lambda r: vkey(r["version"]))


# ─── dependency lockfiles ───────────────────────────────────────────────────


def npm_lockfile(app: App, package: str, version: str) -> str:
    dest = LOCKS_DIR / app.name
    with tempfile.TemporaryDirectory() as tmp:
        pkg_json = {
            "name": f"{app.name}-pinned",
            "version": "0.0.0",
            "private": True,
            "dependencies": {package: version},
        }
        Path(tmp, "package.json").write_text(json.dumps(pkg_json, indent=2) + "\n")
        log(f"    npm: locking {package}@{version} and its dependency tree")
        out = subprocess.run(
            ["npm", "install", "--package-lock-only", "--ignore-scripts", "--no-audit",
             "--no-fund", "--registry", "https://registry.npmjs.org/"],
            cwd=tmp, capture_output=True, text=True,
            env={**os.environ, "npm_config_cache": str(Path(tmp, ".npm-cache"))},
        )
        if out.returncode != 0:
            raise SourceError(f"npm lockfile generation failed:\n{out.stderr.strip()}")
        lock = json.loads(Path(tmp, "package-lock.json").read_text())
        missing = [p for p, m in lock.get("packages", {}).items()
                   if p and not m.get("link") and not (m.get("resolved") and m.get("integrity"))]
        if missing:
            raise SourceError(f"npm lock has unpinned entries: {missing[:5]}")
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy(Path(tmp, "package.json"), dest / "package.json")
        shutil.copy(Path(tmp, "package-lock.json"), dest / "package-lock.json")
    return str(dest.relative_to(ROOT))


def cargo_lockfile(app: App, url: str, crate: str, version: str) -> str:
    dest = LOCKS_DIR / app.name
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp, "crate.tar.gz")
        archive.write_bytes(fetch(url))
        with tarfile.open(archive) as tf:
            tf.extractall(tmp, filter="data")
        srcdir = Path(tmp, f"{crate}-{version}")
        if not (srcdir / "Cargo.lock").exists():
            log(f"    cargo: {crate} {version} ships no Cargo.lock, generating one")
            out = subprocess.run(
                ["cargo", "generate-lockfile"], cwd=srcdir, capture_output=True, text=True,
                env={**os.environ, "CARGO_HOME": str(Path(tmp, ".cargo"))},
            )
            if out.returncode != 0:
                raise SourceError(f"cargo generate-lockfile failed:\n{out.stderr.strip()}")
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy(srcdir / "Cargo.lock", dest / "Cargo.lock")
    return str(dest.relative_to(ROOT))


def write_dep_locks(app: App, res: dict) -> str | None:
    spec = res["spec"]
    if res["type"] == "npm" and spec.get("lockfile"):
        return npm_lockfile(app, spec["package"], res["version"])
    if res["type"] == "crate":
        url = next(iter(res["sources"].values()))["url"]
        return cargo_lockfile(app, url, spec["crate"], res["version"])
    return None


# ─── main ───────────────────────────────────────────────────────────────────


def load_lock() -> dict:
    return json.loads(LOCK.read_text()) if LOCK.exists() else {}


def save_lock(lock: dict) -> None:
    LOCK.write_text(json.dumps(dict(sorted(lock.items())), indent=2) + "\n")


def lock_from_git(ref: str = "HEAD") -> dict:
    out = subprocess.run(["git", "show", f"{ref}:{LOCK_REL}"], cwd=ROOT, capture_output=True, text=True)
    return json.loads(out.stdout) if out.returncode == 0 else {}


def update_app(app: App, args) -> dict | None:
    """Return the new lock entry, or None when nothing changed."""
    if app.spec.get("hold") and not args.force:
        log(f"  {app.name}: held at {app.current.get('version')}")
        return None
    res = resolve(app)
    cur_v = app.current.get("version")
    cur_systems = set(app.current.get("sources", {}))
    complete = cur_systems == set(app.systems)
    if app.current.get("lockfile") and not (ROOT / app.current["lockfile"]).exists():
        complete = False  # dependency lock went missing: regenerate it
    if cur_v and complete and not args.force:
        if res["version"] == cur_v:
            return None
        if newer(cur_v, res["version"]):
            log(f"  {app.name}: upstream reports {res['version']}, keeping newer pinned {cur_v}")
            return None
    if args.dry_run:
        return {"version": res["version"], "type": res["type"], "dry": True}
    for entry in res["sources"].values():
        if not entry.get("hash"):
            entry["hash"] = prefetch(entry["url"])
    entry = {
        "version": res["version"],
        "type": res["type"],
        "sources": {s: {"url": e["url"], "hash": e["hash"]} for s, e in sorted(res["sources"].items())},
    }
    if res["vars"]:
        entry["vars"] = res["vars"]
    if lockdir := write_dep_locks(app, res):
        entry["lockfile"] = lockdir
    return entry


def cmd_list(recipes: dict, lock: dict) -> None:
    width = max(map(len, recipes), default=10)
    for name in sorted(recipes):
        e = lock.get(name)
        print(f"{name:<{width}}  {e['version'] if e else '(not pinned)':<24} {e['type'] if e else ''}")


def cmd_revert(names: list[str], lock: dict) -> None:
    head = lock_from_git()
    for name in names:
        if name in head:
            lock[name] = head[name]
        else:
            lock.pop(name, None)
        if (LOCKS_DIR / name).exists():
            subprocess.run(["git", "checkout", "HEAD", "--", f"pkgs/locks/{name}"], cwd=ROOT, capture_output=True)
        log(f"reverted {name}")
    save_lock(lock)


def main() -> int:
    ap = argparse.ArgumentParser(prog="update-sources", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("apps", nargs="*")
    ap.add_argument("--dry-run", "-n", action="store_true")
    ap.add_argument("--force", "-f", action="store_true")
    ap.add_argument("--list", "-l", action="store_true")
    ap.add_argument("--revert", action="store_true")
    ap.add_argument("--summary", metavar="FILE", help="write a JSON summary of changes (for CI)")
    args = ap.parse_args()

    recipes = tomllib.loads(RECIPES.read_text())
    lock = load_lock()

    if args.list:
        cmd_list(recipes, lock)
        return 0
    if args.revert:
        cmd_revert(args.apps, lock)
        return 0

    unknown = [a for a in args.apps if a not in recipes]
    if unknown:
        sys.exit(f"unknown app(s): {', '.join(unknown)} — known: {', '.join(sorted(recipes))}")
    names = args.apps or sorted(recipes)

    changes, failures = [], []
    for name in names:
        log(f"• {name}")
        app = App(name, recipes[name], lock.get(name))
        try:
            entry = update_app(app, args)
        except SourceError as e:
            log(f"  {name}: FAILED — {e}")
            failures.append({"name": name, "error": str(e)})
            continue
        if entry is None:
            log(f"  {name}: up to date ({app.current.get('version')})")
            continue
        old = app.current.get("version")
        log(f"  {name}: {old or '∅'} → {entry['version']}")
        changes.append({"name": name, "old": old, "new": entry["version"], "type": entry["type"],
                        "url": next(iter(entry.get("sources", {}).values()), {}).get("url")})
        if not args.dry_run:
            lock[name] = entry
            save_lock(lock)  # save as we go so a later failure keeps earlier work

    if args.summary:
        Path(args.summary).write_text(json.dumps({"changes": changes, "failures": failures}, indent=2) + "\n")

    print()
    if changes:
        print(("would update" if args.dry_run else "updated") + ":")
        for c in changes:
            print(f"  {c['name']:<20} {c['old'] or '∅':>20} → {c['new']}")
    else:
        print("everything is up to date")
    if failures:
        print("failed:")
        for f in failures:
            print(f"  {f['name']}: {f['error'].splitlines()[0]}")
    return 1 if failures and not changes else 0


if __name__ == "__main__":
    sys.exit(main())
