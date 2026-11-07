"""Regression checks for matching and the commit/build/activation boundary."""
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("helper", Path(__file__).with_name("nix-helper.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class HelperTests(unittest.TestCase):
    def helper(self):
        helper = object.__new__(module.Helper)
        helper.catalog = lambda: {
            "ripgrep": {"description": "Search text with regex"},
            "jq": {"description": "JSON formatter and processor"},
            "jaq": {"description": "JSON processor"},
        }
        helper.providers = lambda *a, **kw: {"ripgrep", "missing-from-pin"}
        return helper

    def test_command_package_mismatch_and_stale_index(self):
        matches = self.helper().search("rg", command=True)
        self.assertEqual([row[1] for row in matches], ["ripgrep"])
        self.assertEqual(matches[0][3], "provides command")

    def test_keyword_and_typo(self):
        helper = self.helper()
        helper.providers = lambda *a, **kw: set()
        self.assertEqual(helper.search("json formatter")[0][1], "jq")
        self.assertEqual(helper.search("ripgrepp")[0][1], "ripgrep")

    def test_provider_output_suffix_and_literal_query(self):
        with tempfile.TemporaryDirectory() as temp:
            helper = object.__new__(module.Helper)
            helper.cache = Path(temp)
            (helper.cache / "index").mkdir()
            (helper.cache / "index/files").touch()
            with patch.object(module, "run", return_value=subprocess.CompletedProcess(
                    [], 0, "ripgrep.out\npython3Packages.rich.bin\n(indirect.out)\n")) as call:
                self.assertEqual(helper.providers("rg"), {"ripgrep", "python3Packages.rich"})
                self.assertEqual(call.call_args.args[0][-2:], ["--", "/bin/rg"])

    def test_no_approximate_autoselection(self):
        with (patch.object(module.sys.stdin, "isatty", return_value=False),
              self.assertRaises(ValueError)):
            module.choose(self.helper().search("rg", command=True), "rg")

    def test_reject_nix_injection(self):
        helper = self.helper()
        with self.assertRaises(ValueError):
            helper.expression('hello; builtins.abort "bad"')
        self.assertEqual(module.nix_string('${bad}'), '"\\${bad}"')

    def test_install_commits_before_build_and_can_resume(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            for key, value in [("user.name", "Test"), ("user.email", "test@example.invalid"),
                               ("commit.gpgsign", "false")]:
                subprocess.run(["git", "-C", temp, "config", key, value], check=True)
            destination = root / module.PACKAGE_FILE
            destination.parent.mkdir(parents=True)
            destination.write_text("[]\n")
            subprocess.run(["git", "-C", temp, "add", "."], check=True)
            subprocess.run(["git", "-C", temp, "commit", "-qm", "initial"], check=True)
            helper = self.helper()
            helper.flake, helper.host = root, "test-host"
            real_run = module.run
            calls = []

            def intercepted(argv, **kwargs):
                if argv[0] == "git":
                    return real_run(argv, **kwargs)
                calls.append(argv)
                self.assertEqual(json.loads(destination.read_text()), ["ripgrep"])
                self.assertEqual(real_run(["git", "-C", temp, "status", "--porcelain"], capture=True).stdout, "")
                if argv[0] == "nixos-rebuild":
                    raise subprocess.CalledProcessError(1, argv)

            with (patch.object(module, "run", side_effect=intercepted),
                  self.assertRaises(subprocess.CalledProcessError)):
                helper.install("ripgrep")
            self.assertEqual(len(calls), 1)  # failed build must never switch
            head = real_run(["git", "-C", temp, "rev-parse", "HEAD"], capture=True).stdout
            calls.clear()
            with patch.object(module, "run", side_effect=lambda argv, **kw:
                              real_run(argv, **kw) if argv[0] == "git" else calls.append(argv)):
                helper.install("ripgrep")
            self.assertEqual([c[:2] for c in calls], [["nixos-rebuild", "build"], ["sudo", "nixos-rebuild"]])
            self.assertEqual(head, real_run(["git", "-C", temp, "rev-parse", "HEAD"], capture=True).stdout)
            (root / "unrelated").write_text("work")
            with self.assertRaisesRegex(ValueError, "Commit or stash"):
                helper.install("jq")
            self.assertEqual(json.loads(destination.read_text()), ["ripgrep"])


if __name__ == "__main__":
    unittest.main()
