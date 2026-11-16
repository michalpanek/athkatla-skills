#!/usr/bin/env python3
"""Check relative links in Markdown files.

Usage: python3 linkcheck.py [--root DIR] PATH...   (Python 3.10 or later)

PATH is a Markdown file or a folder (searched for *.md). The script checks
inline links (also with a title or <angle> target), reference definitions and
@path imports (CLAUDE.md style; inline @ words count only when they look like a
path). It skips URLs, absolute and ~ paths, anchors, code fences and inline
code. It does not check paths written only in backticks. With --root, a link that resolves
outside DIR is also a problem: use it on a child repo that must not point at
the Home. Prints one "file:line: problem: target" row per problem. Exit code 1
when it finds a problem.
"""
import argparse
import re
import sys
from pathlib import Path
from urllib.parse import unquote
from typing import Iterator, NamedTuple

LINK = re.compile(r"\]\(\s*<?([^)\s#>]+)>?(?:#[^)\s]*)?(?:\s+\"[^\"]*\")?\s*\)")
REFDEF = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*<?([^\s>#]+)")
IMPORT = re.compile(r"(?:^|(?<=\s))@([^\s`]+)")
INLINE_CODE = re.compile(r"`[^`]*`")
EXTERNAL = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")
SKIPPED_DIRS = {".git", "node_modules", "vendor", "build", "dist", "target", ".venv"}


class Problem(NamedTuple):
    file: Path
    line: int
    kind: str
    target: str


def markdown_files(path: Path) -> Iterator[Path]:
    if path.is_file():
        yield path
        return
    yield from (
        p for p in sorted(path.rglob("*.md"))
        if not SKIPPED_DIRS.intersection(p.relative_to(path).parts)
    )


def targets(text: str) -> Iterator[tuple[int, str]]:
    in_fence = False
    for number, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        prose = INLINE_CODE.sub("", line)
        imports = [t for t in IMPORT.findall(prose) if looks_like_path(t)]
        found = imports + LINK.findall(prose) + REFDEF.findall(prose)
        yield from ((number, unquote(target)) for target in found)


def looks_like_path(word: str) -> bool:
    return word.endswith(".md") or word.startswith(("./", "../", "~/"))


def check(file: Path, root: Path | None) -> Iterator[Problem]:
    text = file.read_text(encoding="utf-8", errors="ignore")
    for number, target in targets(text):
        if EXTERNAL.match(target) or target.startswith(("/", "~")):
            continue
        resolved = (file.parent / target).resolve()
        if root is not None and not resolved.is_relative_to(root):
            yield Problem(file, number, "leaves root", target)
        elif not resolved.exists():
            yield Problem(file, number, "missing", target)


def main() -> int:
    parser = argparse.ArgumentParser(description="Check relative links in Markdown files.")
    parser.add_argument("--root", type=Path, help="report links that resolve outside this folder")
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()
    root = args.root.resolve() if args.root else None
    problems = [
        problem
        for path in args.paths
        for file in markdown_files(path)
        for problem in check(file, root)
    ]
    print("".join(f"{p.file}:{p.line}: {p.kind}: {p.target}\n" for p in problems), end="")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
