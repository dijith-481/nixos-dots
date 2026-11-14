"""Exercise update pinning and failure recovery without touching the host system."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("dots.sh")
FAKE_COMMAND = """#!PYTHON
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as log:
    log.write(json.dumps([name, *args]) + '\\n')
lock = pathlib.Path(os.environ['DOTS_FLAKE']) / 'flake.lock'
if name == 'nix' and args == ['flake', 'update']:
    lock.write_text('updated\\n')
if name == 'git' and args[:2] == ['diff', '--quiet']:
    sys.exit(lock.read_text() != 'original\\n')
if name == 'nh':
    sys.exit(int(os.environ.get('FAIL_SWITCH', '0')))
"""


class DotsTests(unittest.TestCase):
    def run_dots(self, args, fail=False):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            bindir = root / "bin"
            bindir.mkdir()
            fake = bindir / "fake"
            fake.write_text(FAKE_COMMAND.replace("PYTHON", sys.executable, 1))
            fake.chmod(0o755)
            for name in ["git", "nix", "nh"]:
                (bindir / name).symlink_to(fake)
            lock = root / "flake.lock"
            lock.write_text("original\n")
            calls = root / "calls.jsonl"
            env = dict(os.environ, PATH=f"{bindir}:{os.environ['PATH']}",
                       DOTS_FLAKE=temp, DOTS_HOST="test-host", CALLS=str(calls),
                       FAIL_SWITCH=str(int(fail)))
            result = subprocess.run(["bash", "-euo", "pipefail", str(SCRIPT), *args],
                                    env=env, text=True, capture_output=True)
            return result, [json.loads(line) for line in calls.read_text().splitlines()], lock.read_text()

    def test_routine_update_keeps_validated_pins(self):
        result, calls, lock = self.run_dots(["update", "--no-merge", "--no-push"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(lock, "original\n")
        self.assertFalse(any(c[0] == "nix" for c in calls))
        switch = next(c for c in calls if c[0] == "nh")
        self.assertIn("--no-update-lock-file", switch)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in calls))

    def test_explicit_upgrade_commits_only_after_switch(self):
        result, calls, lock = self.run_dots(["update", "--flake", "--no-merge", "--no-push"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(lock, "updated\n")
        self.assertEqual(calls.count(["nix", "flake", "update"]), 1)
        switch = next(i for i, c in enumerate(calls) if c[0] == "nh")
        commit = next(i for i, c in enumerate(calls) if c[:2] == ["git", "commit"])
        self.assertLess(switch, commit)
        self.assertFalse(any(c[:2] == ["git", "push"] for c in calls))

    def test_failed_switch_keeps_pins_and_does_not_commit_or_push(self):
        result, calls, lock = self.run_dots(["update", "--flake", "--no-merge"], fail=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(lock, "updated\n")
        self.assertIn("activation may have partially completed", result.stderr)
        self.assertFalse(any(c[:2] in [["git", "commit"], ["git", "push"],
                                      ["git", "checkout"]] for c in calls))

    def test_plan_is_a_locked_dry_run(self):
        result, calls, lock = self.run_dots(["plan"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(lock, "original\n")
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][:2], ["nix", "build"])
        for arg in ["--dry-run", "--no-link", "--no-update-lock-file"]:
            self.assertIn(arg, calls[0])


if __name__ == "__main__":
    unittest.main()
