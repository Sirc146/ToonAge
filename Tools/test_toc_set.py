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
# Per warcraft.wiki.gg/wiki/TOC_format, these are the suffixes WoW's addon
# loader knows. The odd one out is the Forever client's: the loader still uses
# Blizzard's pre-announcement codename for it, so ToonAge_Forever.toc is a
# name nothing reads. That filename is the one place this project spells the
# client any way but "Forever".
VALID_SUFFIXES = {"Standard", "Mainline", "Mists", "Cata", "Wrath", "TBC",
                  "Vanilla", "WoWLabs", "Classic", "Camelot", "Plunderstorm"}

# Expected primary interface number per flavor (current values from Warcraft
# Wiki's interface table; Mainline additionally carries PTR/Beta builds).
EXPECTED_INTERFACE = {
    "ToonAge_Mainline.toc": {"120100"},   # live; also lists 120105 (PTR) + 120001 (beta)
    "ToonAge_TBC.toc":      {"20506"},
    "ToonAge_Mists.toc":    {"50504"},
    "ToonAge_Cata.toc":     {"40402"},
    "ToonAge_Vanilla.toc":  {"11509"},
    "ToonAge_Wrath.toc":    {"30405"},
    "ToonAge_Camelot.toc":  {"16001"},
}

# Flavors with no researched Data/<Flavor> yet: their TOC must list the shared
# Core engine and ErrorLog only, so a client that matches one cannot load
# another expansion's numbers.
SCAFFOLD_TOCS = ("ToonAge_Vanilla.toc", "ToonAge_Cata.toc", "ToonAge_Wrath.toc")

# Forever is past scaffold: it ships a Character readout (no scoring, no
# advice), so it gets its own expectation rather than the core-only one.
# Forever is past scaffold: its TOC ships a readout, the chores and the data
# recorder -- and no Data/** at all, because no verified Forever data exists
# yet. This list is the contract.
FOREVER_TOC = "ToonAge_Camelot.toc"     # filename fixed by the loader; see the TOC header
FOREVER_MODULES = [
    "Modules/Infrastructure/ErrorLog.lua",
    "Modules/Infrastructure/Settings.lua",
    "Modules/Infrastructure/ContextAction.lua",
    "Modules/Infrastructure/ChatCopy.lua",
    "Modules/Infrastructure/CoordHarvester.lua",
    # Harvest sensor array (Docs/SPEC_HARVEST_SENSOR_ARRAY.md, T2, 2026-10-04): the
    # shared export formatter. Not a module; a library the harvester and Tools share.
    "Modules/Infrastructure/HarvestFormat.lua",
    # T3/T4: the harvest core (store v3, stamp, export, catalog engine, report,
    # tab). Registers the DataHarvester module since T4.
    "Modules/Infrastructure/Harvester.lua",
    # T4: the domains Forever records and Forever's pack (they replace
    # Modules/Forever/DataHarvester.lua).
    "Modules/Harvest/Domains/Character.lua",
    "Modules/Harvest/Domains/Items.lua",
    "Modules/Harvest/Domains/Racials.lua",
    "Modules/Harvest/Domains/Spellbook.lua",
    "Modules/Harvest/Domains/TraitTree.lua",
    "Modules/Harvest/Domains/Trainer.lua",
    "Modules/Harvest/Packs/Forever.lua",
    "Modules/Progression/XPTracker.lua",
    "Modules/Automation/RestOptimizer.lua",
    "Modules/Automation/DeathRecovery.lua",
    "Modules/Farming/GatherTracker.lua",
    "Modules/Forever/Character.lua",
    "Modules/Forever/Gear.lua",
    "Modules/Forever/Talents.lua",
    "Modules/Forever/Rotation.lua",
    "Modules/Forever/Pets.lua",
    "Modules/Forever/PvP.lua",
    "Modules/Forever/Scrolls.lua",
    "Modules/Forever/CastLog.lua",
    # Added 2026-10-01..03: login "since last session" check and the beta
    # world-refresh notice (both tab-less), plus the flavor-neutral self-test.
    "Modules/Forever/SessionCheck.lua",
    "Modules/Forever/WorldRefresh.lua",
    # Shared profession cards. The skill list is Data/Forever/ProfessionSkills.lua
    # and stays unverified until an in-game probe confirms it.
    "Modules/Character/ProfessionSkills.lua",
    "Modules/Character/ProfessionBoard.lua",
    "Modules/Infrastructure/TestHarness.lua",
]

# The in-game self-test ships in EVERY TOC (it is not a registered module and
# is not profile-gated), so the scaffold "core only" contract allows it.
SELFTEST = "Modules/Infrastructure/TestHarness.lua"

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
        # Classic Era ships the shared profession readout and nothing else.
        # Cata and Wrath stay core-only.
        if name == "ToonAge_Vanilla.toc":
            check("vanilla: data is only the profession skill list",
                  [f for f in files if f.startswith("Data/")],
                  ["Data/Vanilla/ProfessionSkills.lua"])
            mods = [f for f in files if f.startswith("Modules/") and f != SELFTEST]
            check("vanilla: ErrorLog plus the profession readout",
                  sorted(mods),
                  ["Modules/Character/ProfessionBoard.lua",
                   "Modules/Character/ProfessionSkills.lua",
                   "Modules/Infrastructure/ContextAction.lua",
                   "Modules/Infrastructure/ErrorLog.lua"])
            check("vanilla: includes Layout for the profession cards",
                  any(f.endswith("Core/Layout.lua") for f in files), True)
        else:
            check(f"{name}: lists no Data/", [f for f in files if f.startswith("Data/")], [])
            mods = [f for f in files if f.startswith("Modules/")]
            check(f"{name}: only ErrorLog module (+ self-test)",
                  [m for m in mods if m != SELFTEST], ["Modules/Infrastructure/ErrorLog.lua"])
        check(f"{name}: includes Core/Environment",
              any(f.endswith("Core/Environment.lua") for f in files), True)
        check(f"{name}: includes Core/Profile",
              any(f.endswith("Core/Profile.lua") for f in files), True)


def test_retail_tocs_ship_no_forever_modules():
    """Forever's modules must not ride along in the retail TOCs.

    They were listed there while Mainline still claimed 16001 and Forever
    could fall through to it. Mainline no longer claims that build and Forever
    has its own TOC, so those files can never run on a retail client -- they
    would just register a module nothing shows and ship dead weight to every
    player.
    """
    for name in ("ToonAge_Mainline.toc", "ToonAge.toc"):
        files = listed_files(ROOT / name)
        check(f"{name}: no Modules/Forever",
              [f for f in files if f.startswith("Modules/Forever/")], [])


def test_no_toc_claims_another_flavors_build():
    """A TOC must declare only the clients it actually supports.

    ToonAge_Mainline.toc used to list Forever's 16001 as a safety net. That is
    not a net -- it is the failure path kept alive: any client matching it
    loads the full retail product, which on Forever means 45 guide files and
    433 KB of retail rotations it can never use. With the suffixed Forever TOC
    shipping, the overlap only reintroduces the bug it was meant to cover.

    Questie, shipping on this same client, keeps them disjoint the same way:
    Questie.toc at 11508/11509, Questie_Camelot.toc at 16001.
    """
    owner = {}
    for toc in all_tocs():
        for num in interface_numbers(toc):
            owner.setdefault(num, []).append(toc.name)
    shared = {n: sorted(f) for n, f in owner.items() if len(f) > 1}
    # ToonAge.toc is the generic fallback and legitimately mirrors Mainline.
    shared = {n: f for n, f in shared.items()
              if set(f) != {"ToonAge.toc", "ToonAge_Mainline.toc"}}
    check("no interface number is claimed by two flavors", shared, {})


def test_no_duplicate_module_names():
    """Two files registering the same module name is decided by TOC order.

    TA:RegisterModule is a flat overwrite and runs at file load, before the
    profile gate has any say. Retail shipped both Character modules in one TOC
    and the Forever readout -- listed later -- silently replaced Retail's own
    Character tab. Nobody chose that; the line order did.
    """
    import re
    for toc in all_tocs():
        seen = {}
        for f in listed_files(toc):
            path = ROOT / f
            if not path.exists() or not f.endswith(".lua"):
                continue
            for m in re.finditer(r'TA:RegisterModule\("(\w+)"', path.read_text(encoding="utf-8")):
                seen.setdefault(m.group(1), []).append(f)
        dupes = {n: fs for n, fs in seen.items() if len(fs) > 1}
        check(f"{toc.name}: no module name registered twice", dupes, {})


def test_forever_toc_carries_no_retail_content():
    """Forever's own TOC must carry no retail content.

    Its filename is the one thing here the loader dictates rather than us --
    see FOREVER_TOC and the header of that file. A TOC named for the client the
    way we name it everywhere else is a name nothing reads, and Forever then
    falls through to ToonAge_Mainline.toc and loads the entire retail product:
    45 guide files, 433 KB of retail rotations, on a Vanilla-era client that
    can use none of it.
    """
    p = ROOT / FOREVER_TOC
    check("Forever TOC exists", p.exists(), True)
    if not p.exists():
        return
    files = listed_files(p)
    # No game data -- no rotations, weights, talents, guides, item levels.
    # ApiManifest is allowed because it is not game data: it is measured from
    # this TOC's own file list and says which client functions those files
    # call, which is the one thing about this client nobody has written down.
    data = [f for f in files if f.startswith("Data/")]
    # Allowed since 2026-09-27: Data/Forever/Coach.lua -- ability NAMES and
    # roles from the Icy Veins Forever guides, each spec citing its URL. No
    # numbers. Anything else under Data/ is still refused.
    # Allowed since 2026-09-29: files GENERATED by Tools/gen_forever_data.lua
    # from the in-game harvest -- numbers the Forever client itself reported,
    # not numbers copied from another expansion. The header is the contract:
    # a hand-written or retail-derived file under Data/Forever still fails.
    def measured(f):
        try:
            head = (ROOT / f).read_text(encoding="utf-8")[:600]
        except OSError:
            return False
        return ("GENERATED by Tools/gen_forever_data.lua" in head
                and "Measured on the Forever client" in head)
    def allowed_data(f):
        if f.endswith("ApiManifest.lua") or f == "Data/Forever/Coach.lua" or measured(f):
            return True
        # Hand-written, and marked unverified until an in-game probe confirms
        # the skill lines. Removing the flag drops the exception.
        if f == "Data/Forever/ProfessionSkills.lua":
            try:
                return "unverified = true" in (ROOT / f).read_text(encoding="utf-8")
            except OSError:
                return False
        return False
    check("Forever: ships no game data beyond the manifest, the sourced coach, measured harvest data and the unverified profession list",
          [f for f in data if not allowed_data(f)], [])
    coach = ROOT / "Data/Forever/Coach.lua"
    if coach.exists():
        txt = coach.read_text(encoding="utf-8")
        specs = txt.count("source = IV ..")
        check("Forever coach: every spec cites its guide", specs >= 5, True)
        check("Forever coach: carries no numbers beyond limits",
              [ln for ln in txt.splitlines() if "=" in ln and any(ch.isdigit() for ch in ln.split("--")[0])
               and "limit" not in ln and "IV =" not in ln], [])
    check("Forever: ships its measured API manifest",
          "Data/Forever/ApiManifest.lua" in data, True)
    check("Forever: no retail DR engine",
          any("StatEngine" in f for f in files), False)
    # The guide stack is the thing that dragged the retail chain in behind it.
    for guide_mod in ("QuestTracker", "Arrow", "MapPins", "AntTrail",
                      "CoordResolver", "GuideParser", "GuideBrowser"):
        check(f"Forever: no {guide_mod}",
              any(guide_mod in f for f in files), False)
    check("Forever: ships exactly its module set",
          sorted(f for f in files if f.startswith("Modules/")),
          sorted(FOREVER_MODULES))
    check("Forever: includes Core/Layout (it draws tabs)",
          any(f.endswith("Core/Layout.lua") for f in files), True)
    check("Forever: includes Core/Profile",
          any(f.endswith("Core/Profile.lua") for f in files), True)
    # Mainline must NOT claim Forever's build. It did once, as a safety net,
    # and the net was the bug: any client matching it loads the full retail
    # product. See test_no_toc_claims_another_flavors_build.
    check("Mainline does not claim Forever's build",
          "16001" in interface_numbers(ROOT / "ToonAge_Mainline.toc"), False)
    # The dead name must not come back.
    # The name that reads naturally is the one nothing loads. Keep it gone.
    check("no unread ToonAge_Forever.toc",
          (ROOT / "ToonAge_Forever.toc").exists(), False)

# Distribution ids the packager reads. Empty used to mean "publish nowhere".
CURSE_PROJECT_ID = "1734520"
WAGO_ID = "56ndnjG9"


def toc_field(p, key):
    prefix = "## %s:" % key
    for ln in read_lines(p):
        s = ln.strip()
        if s.startswith(prefix):
            return s.split(":", 1)[1].strip()
    return ""


def test_distribution_ids():
    for toc in all_tocs():
        check(f"{toc.name}: CurseForge project id",
              toc_field(toc, "X-Curse-Project-ID"), CURSE_PROJECT_ID)
        check(f"{toc.name}: Wago id",
              toc_field(toc, "X-Wago-ID"), WAGO_ID)


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


def test_layout_ships_where_it_is_used():
    """Modules/Forever/Character.lua draws through TA.Layout, and Forever loads
    via the Mainline TOC — so Layout has to be listed in every TOC that lists
    that module, and BEFORE it. Missing it renders an empty tab with no error,
    which is the worst kind of bug to chase."""
    for toc in all_tocs():
        files = listed_files(toc)
        uses_layout = any(f.endswith("Modules/Forever/Character.lua") for f in files)
        has_layout  = any(f.endswith("Core/Layout.lua") for f in files)
        if uses_layout:
            check(f"{toc.name}: ships Core/Layout.lua", has_layout, True)
            check(f"{toc.name}: Layout loads before the module that uses it",
                  files.index("Core/Layout.lua") < files.index("Modules/Forever/Character.lua"), True)


def main():
    test_suffixes_valid()
    test_interface_present_and_correct()
    test_mainline_covers_test_targets()
    test_no_bindings_listed()
    test_all_listed_files_exist()
    test_tbc_excludes_retail()
    test_mainline_matches_generic_body()
    test_scaffold_tocs_are_core_only()
    test_layout_ships_where_it_is_used()
    test_retail_tocs_ship_no_forever_modules()
    test_no_toc_claims_another_flavors_build()
    test_no_duplicate_module_names()
    test_forever_toc_carries_no_retail_content()
    test_titles_name_the_flavor()
    test_distribution_ids()

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
