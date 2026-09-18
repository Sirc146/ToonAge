#!/usr/bin/env python3
r"""
ToonAge -- Data layout / namespace tests
=========================================
Guards the per-flavor Data reorganization (Task 5):

  1. Every Data\ file listed in a flavor's TOC lives under that flavor's own
     Data/<Flavor>/ namespace (or Data/Shared/) -- a flavor must never load
     another flavor's game-design data.
  2. Data files register their TA.Data.* table by NAME, independent of path, so
     moving them between folders cannot break consumers.

Why this matters: the whole per-flavor-download model (install for Retail ->
retail files only) depends on each flavor's TOC referencing only its own Data.
A stray Data\TBC\ line in the Mainline TOC would ship TBC data to retail users
and vice versa. This is the automated check for that.

Usage:  python Tools/test_data_layout.py [-v]
        python Tools/test_data_layout.py --toc ToonAge_TBC.toc  (once it exists)
"""

import sys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

# Flavor -> the Data/<sub> namespace its TOC is allowed to reference. Shared is
# always allowed. Update as flavors are added (Tasks 7-9).
TOC_NAMESPACE = {
    "ToonAge.toc":          "Retail",   # generic fallback == Mainline for now
    "ToonAge_Mainline.toc": "Retail",
    "ToonAge_TBC.toc":      "TBC",
    "ToonAge_Mists.toc":    "Mists",
    "ToonAge_Cata.toc":     "Cata",
    "ToonAge_Vanilla.toc":  "Vanilla",
    "ToonAge_Forever.toc":  "Forever",
}

_results = []


def check(name, got, want):
    ok = got == want
    _results.append((ok, name, got, want))
    if VERBOSE or not ok:
        mark = "  ok  " if ok else " FAIL "
        print(f"[{mark}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def toc_data_lines(toc_path):
    r"""Return the Data\... file references in a TOC, normalized to forward slash."""
    out = []
    for line in toc_path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.lower().endswith(".lua") and s.replace("\\", "/").startswith("Data/"):
            out.append(s.replace("\\", "/"))
    return out


def test_toc_namespace_isolation():
    """Every Data line in a TOC must be under that flavor's namespace or Shared."""
    for toc_name, ns in TOC_NAMESPACE.items():
        toc = ROOT / toc_name
        if not toc.exists():
            continue  # flavor TOC not authored yet (Tasks 6-9)
        allowed_prefixes = (f"Data/{ns}/", "Data/Shared/")
        bad = [ln for ln in toc_data_lines(toc)
               if not ln.startswith(allowed_prefixes)]
        check(f"{toc_name}: only Data/{ns}/ or Data/Shared/ referenced", bad, [])


def test_no_foreign_flavor_data():
    """Explicit cross-contamination check: no TOC references a DIFFERENT
    flavor's Data folder."""
    all_flavor_dirs = {"Retail", "TBC", "Mists", "Cata", "Vanilla", "Forever"}
    for toc_name, ns in TOC_NAMESPACE.items():
        toc = ROOT / toc_name
        if not toc.exists():
            continue
        foreign = all_flavor_dirs - {ns}
        lines = toc_data_lines(toc)
        for other in foreign:
            hits = [ln for ln in lines if ln.startswith(f"Data/{other}/")]
            check(f"{toc_name}: no Data/{other}/ leakage", hits, [])


def test_files_exist_at_new_paths():
    """Every Data line resolves to a real file on disk."""
    for toc_name in TOC_NAMESPACE:
        toc = ROOT / toc_name
        if not toc.exists():
            continue
        missing = [ln for ln in toc_data_lines(toc)
                   if not (ROOT / ln).exists()]
        check(f"{toc_name}: all Data files exist on disk", missing, [])


def test_data_registers_by_name():
    """Data files register TA.Data.<Name> regardless of path -- load a few in
    lupa and confirm the table name is present after execution."""
    try:
        from lupa import lua51
    except ImportError:
        if VERBOSE:
            print("[skip] lupa not installed; skipping table-name check")
        return
    # Self-contained files only (no cross-file load-order deps): these register
    # their table with no reference to another Data table. Rotations.lua, for
    # example, needs RotationConditions loaded first, so it is not a valid
    # standalone-load case -- that is a load-order fact, not a path problem.
    cases = [
        ("Data/Retail/StatWeights.lua", "StatWeights"),
        ("Data/Retail/Spells.lua",      "Spells"),
        ("Data/Retail/Dungeons.lua",    "Dungeons"),
    ]
    for rel, tbl in cases:
        path = ROOT / rel
        if not path.exists():
            check(f"{rel} exists", False, True)
            continue
        lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        lua.execute("ToonAge = {}")
        lua.execute(path.read_text(encoding="utf-8"))
        data = lua.globals().ToonAge.Data
        present = data is not None and data[tbl] is not None
        check(f"{rel} -> TA.Data.{tbl} registered", present, True)


def main():
    test_toc_namespace_isolation()
    test_no_foreign_flavor_data()
    test_files_exist_at_new_paths()
    test_data_registers_by_name()

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if total == 0:
        print("[WARN] no assertions ran (no TOCs found?).")
        return 1
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
