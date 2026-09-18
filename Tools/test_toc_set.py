#!/usr/bin/env python3
r"""
ToonAge -- Multi-TOC set tests (Task 6)
=======================================
Verifies the flavor-suffixed TOC set follows Blizzard's client rules
(warcraft.wiki.gg/wiki/.toc) and the per-flavor isolation this project needs:

  * Valid flavor suffixes only (_Mainline, _TBC, _Mists, _Cata, _Vanilla,
    _Forever) plus the generic fallback ToonAge.toc.
  * Each TOC declares an ## Interface line with the right number(s) for its
    flavor.
  * Mainline lists the retail test/live build numbers (live + PTR/Test + Beta).
  * Bindings.xml is NOT listed in any TOC (WoW auto-loads it; listing double-
    parses and errors).
  * The TBC TOC excludes retail-only Core (StatEngine) and all Data/Retail/.
  * Every file a TOC lists exists on disk.

This is the packaging backstop for "install for Retail -> retail files only":
if a TOC leaks another flavor's files, per-flavor downloads would ship the
wrong content.

Usage:  python Tools/test_toc_set.py [-v]
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

# Valid client suffixes per Warcraft Wiki .toc (subset we ship / scaffold).
VALID_SUFFIXES = {"Standard", "Mainline", "Mists", "Cata", "Wrath",
                  "TBC", "Vanilla", "WoWLabs", "Classic", "Forever"}

# Expected primary interface number per flavor (current values from Warcraft
# Wiki's interface table; Mainline additionally carries PTR/Beta builds).
EXPECTED_INTERFACE = {
    "ToonAge_Mainline.toc": {"120100"},   # live; also lists 120105 (PTR) + 120001 (beta)
    "ToonAge_TBC.toc":      {"20506"},
    "ToonAge_Mists.toc":    {"50504"},
    "ToonAge_Cata.toc":     {"40402"},
    "ToonAge_Vanilla.toc":  {"11509"},
    "ToonAge_Wrath.toc":    {"30405"},
    "ToonAge_Forever.toc":  {"16001"},
}

# Flavors with no researched Data/<Flavor> yet: their TOC must list the shared
# Core engine and ErrorLog only, so a client that matches one cannot load
# another expansion's numbers.
SCAFFOLD_TOCS = ("ToonAge_Vanilla.toc", "ToonAge_Cata.toc",
                 "ToonAge_Wrath.toc", "ToonAge_Forever.toc")

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


def read_lines(p):
    return p.read_text(encoding="utf-8").splitlines()


def interface_numbers(p):
    for ln in read_lines(p):
        s = ln.strip()
        if s.startswith("## Interface:"):
            vals = s.split(":", 1)[1]
            return {v.strip() for v in vals.split(",") if v.strip()}
    return set()


def listed_files(p):
    out = []
    for ln in read_lines(p):
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        # strip any per-file conditional [ ... ] directive
        token = s.split("[")[0].strip()
        if token.lower().endswith((".lua", ".xml")):
            out.append(token.replace("\\", "/"))
    return out


def all_tocs():
    return sorted(ROOT.glob("ToonAge*.toc"))


def test_suffixes_valid():
    for toc in all_tocs():
        name = toc.name
        if name == "ToonAge.toc":
            continue  # generic fallback, no suffix
        suffix = name[len("ToonAge_"):-len(".toc")]
        check(f"{name}: valid flavor suffix", suffix in VALID_SUFFIXES, True)


def test_interface_present_and_correct():
    for toc in all_tocs():
        nums = interface_numbers(toc)
        check(f"{toc.name}: has ## Interface", len(nums) > 0, True)
        expected = EXPECTED_INTERFACE.get(toc.name)
        if expected:
            check(f"{toc.name}: interface includes {expected}",
                  expected.issubset(nums), True)


def test_mainline_covers_test_targets():
    p = ROOT / "ToonAge_Mainline.toc"
    if not p.exists():
        check("Mainline TOC exists", False, True)
        return
    nums = interface_numbers(p)
    # live + PTR/Test + Beta so PTR/XPTR/Beta test clients all load one product.
    for build in ("120100", "120105", "120001"):
        check(f"Mainline interface lists {build}", build in nums, True)


def test_no_bindings_listed():
    for toc in all_tocs():
        files = listed_files(toc)
        has_bindings = any(f.lower().endswith("bindings.xml") for f in files)
        check(f"{toc.name}: does NOT list Bindings.xml", has_bindings, False)


def test_all_listed_files_exist():
    for toc in all_tocs():
        missing = [f for f in listed_files(toc) if not (ROOT / f).exists()]
        check(f"{toc.name}: all listed files exist", missing, [])


def test_tbc_excludes_retail():
    p = ROOT / "ToonAge_TBC.toc"
    if not p.exists():
        check("TBC TOC exists", False, True)
        return
    files = listed_files(p)
    # No retail-only Core, no Data/Retail/, no retail module tree leakage.
    check("TBC excludes StatEngine",
          any("StatEngine" in f for f in files), False)
    check("TBC lists no Data/Retail/",
          any(f.startswith("Data/Retail/") for f in files), False)
    # Shared Core must be present (it boots on TBC).
    check("TBC includes shared Core/Environment",
          any(f.endswith("Core/Environment.lua") for f in files), True)
    check("TBC includes shared Core/Compat/API",
          any(f.endswith("Core/Compat/API.lua") for f in files), True)


def test_mainline_matches_generic_body():
    """The generic fallback should carry the same file set as Mainline, so an
    unrecognized retail client still gets the full addon."""
    m = ROOT / "ToonAge_Mainline.toc"
    g = ROOT / "ToonAge.toc"
    if not (m.exists() and g.exists()):
        check("both Mainline + generic exist", False, True)
        return
    check("generic fallback == Mainline file set",
          set(listed_files(g)), set(listed_files(m)))


def test_scaffold_tocs_are_core_only():
    for name in SCAFFOLD_TOCS:
        p = ROOT / name
        if not p.exists():
            check(f"{name} exists", False, True)
            continue
        files = listed_files(p)
        check(f"{name}: lists no Data/", [f for f in files if f.startswith("Data/")], [])
        mods = [f for f in files if f.startswith("Modules/")]
        check(f"{name}: only ErrorLog module", mods, ["Modules/Infrastructure/ErrorLog.lua"])
        check(f"{name}: includes Core/Environment",
              any(f.endswith("Core/Environment.lua") for f in files), True)
        check(f"{name}: includes Core/Profile",
              any(f.endswith("Core/Profile.lua") for f in files), True)


def test_titles_name_the_flavor():
    """Every flavor TOC names its game version in the addon list, so the client
    itself tells you which build loaded."""
    seen = {}
    for toc in all_tocs():
        title = next((l.split(":", 1)[1].strip() for l in read_lines(toc)
                      if l.strip().startswith("## Title:")), "")
        check(f"{toc.name}: has a title", bool(title), True)
        check(f"{toc.name}: title starts with ToonAge", "ToonAge" in title, True)
        seen[toc.name] = title
    # No two flavor TOCs share a title, or the addon list can't disambiguate.
    flavored = {k: v for k, v in seen.items() if k != "ToonAge.toc"}
    check("flavor titles are unique", len(set(flavored.values())), len(flavored))


def main():
    test_suffixes_valid()
    test_interface_present_and_correct()
    test_mainline_covers_test_targets()
    test_no_bindings_listed()
    test_all_listed_files_exist()
    test_tbc_excludes_retail()
    test_mainline_matches_generic_body()
    test_scaffold_tocs_are_core_only()
    test_titles_name_the_flavor()

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
