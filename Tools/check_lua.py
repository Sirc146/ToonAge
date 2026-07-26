#!/usr/bin/env python3
"""
ToonAge -- Lua syntax check
===========================
Parses every .lua file listed in ToonAge.toc (or the files you name) and
reports syntax errors.

There is no Lua interpreter on this machine, so until this existed the only way
to find a syntax error was to /reload in-game and read the error -- which costs
a client reload per typo and, worse, means a broken file ships if nobody happens
to reload before committing.

This does NOT run the code or check semantics. A file can parse cleanly and
still be wrong. It catches the class of mistake that is otherwise invisible
outside the game: unbalanced end, missing then, a stray brace after an edit.

Setup
-----
    python -m pip install --user luaparser

Usage
-----
    python Tools/check_lua.py                 # every file in the TOC
    python Tools/check_lua.py Core/State.lua  # specific files
    python Tools/check_lua.py --all           # every .lua in the repo,
                                              # including ones not in the TOC
"""

import sys
from pathlib import Path

try:
    from luaparser import ast
except ImportError:
    print("[ERR] luaparser is not installed.")
    print("      python -m pip install --user luaparser")
    sys.exit(3)

from paths import REPO_ROOT


def toc_lua_files():
    """The .lua files the game actually loads, in load order."""
    toc = REPO_ROOT / "ToonAge.toc"
    if not toc.exists():
        return []
    files = []
    for line in toc.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.lower().endswith(".lua"):
            files.append(REPO_ROOT / line.replace("\\", "/"))
    return files


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    scan_all = "--all" in sys.argv

    if args:
        files = [Path(a) if Path(a).is_absolute() else REPO_ROOT / a for a in args]
        label = f"{len(files)} file(s)"
    elif scan_all:
        files = sorted(REPO_ROOT.rglob("*.lua"))
        label = f"{len(files)} .lua files in the repo"
    else:
        files = toc_lua_files()
        label = f"{len(files)} files listed in ToonAge.toc"

    if not files:
        print("[ERR] Nothing to check.")
        return 3

    print(f"Checking {label} ...\n")

    failures, missing = [], []
    for path in files:
        rel = path.relative_to(REPO_ROOT) if path.is_relative_to(REPO_ROOT) else path
        if not path.exists():
            # A TOC entry pointing at a file that does not exist is its own bug:
            # the game silently skips it, so the addon loads "fine" and behaves
            # as though the module was never written.
            missing.append(rel)
            print(f"  MISSING  {rel}")
            continue
        try:
            ast.parse(path.read_text(encoding="utf-8"))
        except Exception as e:
            failures.append((rel, e))
            print(f"  SYNTAX   {rel}")
            print(f"           {str(e).splitlines()[0][:200]}")
        else:
            print(f"  ok       {rel}")

    print()
    if failures or missing:
        if failures:
            print(f"[FAIL] {len(failures)} file(s) with syntax errors.")
        if missing:
            print(f"[FAIL] {len(missing)} TOC entr(ies) point at files that do not exist.")
            print("       The game skips these silently -- the addon will load without them.")
        return 1

    print(f"[OK] All {len(files)} files parsed.")
    print("     Syntax only. This proves nothing about whether the code is correct.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
