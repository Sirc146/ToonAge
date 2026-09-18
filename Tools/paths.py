#!/usr/bin/env python3
"""
ToonAge -- shared repository paths for the Tools/ scripts
=========================================================
Every generator in this folder writes output somewhere. Before this module
existed they each hardcoded their own destination, and three of them pointed at
a personal Desktop folder outside the repository -- which contradicted
.rules.md's own rule for these scripts:

    Output: baked into static Lua data files, committed to repo

Resolving from __file__ means the scripts work from any working directory and
follow the repo if it moves, which a hardcoded absolute path does not.

Layout assumed:

    ToonAge/                 <- REPO_ROOT
      Data/                  <- DATA_DIR
        Guides/              <- GUIDES_DIR
      Tools/                 <- this file
"""

from pathlib import Path

# .resolve() first so that a symlinked or relative invocation still yields the
# real repo root rather than something containing "..".
TOOLS_DIR  = Path(__file__).resolve().parent
REPO_ROOT  = TOOLS_DIR.parent
DATA_DIR   = REPO_ROOT / "Data"
GUIDES_DIR = DATA_DIR / "Guides"

# Intermediate artifact shared between the quest fetcher and the stub generator.
# fetch_wow_quests.py writes it; gen_midnight_stubs.py reads it.
QUESTS_CSV = DATA_DIR / "quests_database.csv"


def ensure(directory: Path) -> Path:
    """Create `directory` if missing and return it, so callers can inline this."""
    directory.mkdir(parents=True, exist_ok=True)
    return directory


if __name__ == "__main__":
    # `python Tools/paths.py` prints what everything resolved to -- the quickest
    # way to check the layout assumption still holds after a move.
    for name in ("TOOLS_DIR", "REPO_ROOT", "DATA_DIR", "GUIDES_DIR", "QUESTS_CSV"):
        value = globals()[name]
        exists = "ok     " if value.exists() else "MISSING"
        print(f"  {exists}  {name:<11} {value}")
