"""Tests for linkcheck.py. Run: python3 -m unittest test_linkcheck.py (from this folder)."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("linkcheck.py")


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)


def write(root: Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


class LinkCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        write(self.home, "AGENTS.md", "# Home\n")
        write(self.home, "repo/CONTEXT.md", "# Context\n")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_valid_links_pass(self) -> None:
        write(self.home, "repo/AGENTS.md", "See [context](CONTEXT.md#purpose) and [web](https://example.com).\n")
        result = run(str(self.home / "repo"))
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(result.stdout, "")

    def test_broken_link_fails_with_location(self) -> None:
        write(self.home, "repo/AGENTS.md", "line one\nSee [glossary](GLOSSARY.md).\n")
        result = run(str(self.home / "repo"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("AGENTS.md:2: missing: GLOSSARY.md", result.stdout)

    def test_import_line_is_checked(self) -> None:
        write(self.home, "repo/CLAUDE.md", "@AGENTS.md\n")
        result = run(str(self.home / "repo"))
        self.assertIn("CLAUDE.md:1: missing: AGENTS.md", result.stdout)

    def test_link_outside_root_fails_only_with_root_flag(self) -> None:
        write(self.home, "repo/AGENTS.md", "Read [home](../AGENTS.md).\n")
        self.assertEqual(run(str(self.home / "repo")).returncode, 0)
        result = run("--root", str(self.home / "repo"), str(self.home / "repo"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("AGENTS.md:1: leaves root: ../AGENTS.md", result.stdout)

    def test_links_inside_code_fences_are_ignored(self) -> None:
        write(self.home, "repo/AGENTS.md", "```md\n[x](missing.md)\n@missing.md\n```\n")
        self.assertEqual(run(str(self.home / "repo")).returncode, 0)

    def test_leaks_in_every_link_form_are_found(self) -> None:
        write(self.home, "repo/AGENTS.md", "\n".join([
            'A [titled](../AGENTS.md "Home") link.',
            "[ref]: ../AGENTS.md",
            "See @../AGENTS.md for more.",
            "An [angle](<../AGENTS.md>) link.",
        ]) + "\n")
        result = run("--root", str(self.home / "repo"), str(self.home / "repo"))
        self.assertEqual([line.split(": ", 1)[0].rsplit(":", 1)[1] for line in result.stdout.splitlines()], ["1", "2", "3", "4"])

    def test_valid_forms_are_not_reported(self) -> None:
        write(self.home, "repo/my file.md", "# x\n")
        write(self.home, "repo/AGENTS.md", "\n".join([
            "[spaced](my%20file.md)",
            "@~/.claude/CLAUDE.md",
            "Install @types/node and mail me@example.com.",
            "Run `[x](missing.md)` in code.",
            "~~~",
            "[x](missing.md)",
            "~~~",
        ]) + "\n")
        result = run("--root", str(self.home / "repo"), str(self.home / "repo"))
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.returncode, 0)

    def test_dependency_and_git_folders_are_skipped(self) -> None:
        write(self.home, "repo/node_modules/pkg/README.md", "[x](missing.md)\n")
        self.assertEqual(run(str(self.home / "repo")).returncode, 0)


if __name__ == "__main__":
    unittest.main()
