#!/usr/bin/env python3
"""
ToonAge -- Retail (Mainline) data integrity tests
=================================================
Guards the class/spec data the Retail tabs render from the failure modes found
in the 2026-09-16 accuracy audit:

  * every playable spec (40, incl. Devourer 1480) present in StatWeights,
    Rotations, Talents and TalentsPvP
  * talent import strings either empty or decoding to THEIR OWN spec with the
    current serialization version (24 of 26 old strings decoded to another spec)
  * rotation entries carry a spellID + name; no ability removed from the game is
    still listed (Mind Sear, Void Eruption)
  * known-wrong spellIDs stay fixed (271788 = Serpent Sting, not Kill Shot;
    368847 = Firestorm, not Eternity Surge; 303832 = NPC Tentacle Slam)
  * Delve tiers: recommended ilvl strictly rises and the estimate reads it
  * Gear enchant slots match Midnight (Head/Shoulder yes, Back/Wrist no)

Setup:  python -m pip install --user lupa
Usage:  python Tools/test_retail_data.py [-v]
"""

import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

SPECS = {
    71, 72, 73, 65, 66, 70, 250, 251, 252, 577, 581, 1480, 102, 103, 104, 105,
    253, 254, 255, 62, 63, 64, 268, 269, 270, 256, 257, 258, 259, 260, 261,
    262, 263, 264, 265, 266, 267, 1467, 1468, 1473,
}
LOADOUT_VERSION = 2
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def check(name, ok, detail=""):
    _results.append((bool(ok), name))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"\n        {detail}" if detail and not ok else ""))


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8-sig")


def loadout_header(s):
    def bits():
        for ch in s:
            v = B64.index(ch)
            for i in range(6):
                yield (v >> i) & 1
    g = bits()
    def take(n):
        return sum(next(g) << i for i in range(n))
    return take(8), take(16)


def lua_keys(t):
    return {k for k in t.keys() if isinstance(k, int)}


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    for f in ("Data/Retail/RotationConditions.lua", "Data/Retail/StatWeights.lua",
              "Data/Retail/Rotations.lua", "Data/Retail/Talents.lua",
              "Data/Retail/TalentsPvP.lua"):
        lua.execute(read(f))
    D = lua.globals().ToonAge.Data

    print("-- spec coverage")
    for label, tbl in (("StatWeights", D.StatWeights), ("Rotations", D.Rotations),
                       ("TalentsPvP", D.TalentsPvP)):
        missing = SPECS - lua_keys(tbl)
        check(f"{label} covers all 40 specs", not missing, f"missing {sorted(missing)}")
    tal_missing = [s for s in SPECS if D.Talents.GetBySpecID(D.Talents, s) is None]
    check("Talents covers all 40 specs", not tal_missing, f"missing {sorted(tal_missing)}")

    print("-- talent import strings")
    src = read("Data/Retail/Talents.lua")
    cur = None
    for line in src.splitlines():
        m = re.match(r"^DB\[(\d+)\]", line)
        if m:
            cur = int(m.group(1))
        for s in re.findall(r'string = "([A-Za-z0-9+/]+)"', line):
            ver, spec = loadout_header(s)
            check(f"Talents[{cur}] string decodes to its own spec, v{LOADOUT_VERSION}",
                  spec == cur and ver == LOADOUT_VERSION, f"decoded spec {spec} version {ver}")

    print("-- rotations")
    rot_src = read("Data/Retail/Rotations.lua")
    for removed in ("Mind Sear", "Void Eruption"):
        check(f"no rotation entry named {removed}",
              not re.search(r'name = "%s"' % re.escape(removed), rot_src))
    for bad_id, label in ((271788, "Serpent Sting as Kill Shot"),
                          (303832, "NPC Tentacle Slam")):
        check(f"spellID {bad_id} not used ({label})", str(bad_id) not in rot_src)
    check("368847 never labelled Eternity Surge",
          not re.search(r'368847,\s*\n?\s*name = "Eternity Surge', rot_src))
    bad_entries = []
    for sid in SPECS:
        spec = D.Rotations[sid]
        for view in ("solo", "st", "aoe"):
            v = spec[view]
            if v is None or v.priorities is None:
                continue
            for i in range(1, len(v.priorities) + 1):
                e = v.priorities[i]
                if not (isinstance(e.spellID, int) and e.spellID > 0 and e.name):
                    bad_entries.append((sid, view, i))
    check("every rotation entry has spellID + name", not bad_entries, str(bad_entries[:5]))

    print("-- delves")
    dsrc = read("Modules/Progression/Delves.lua")
    recs = [int(x) for x in re.findall(r"recIlvl=(\d+)", dsrc)]
    check("11 delve tiers", len(recs) == 11, str(recs))
    check("recommended ilvl strictly rises", all(b > a for a, b in zip(recs, recs[1:])), str(recs))
    check("EstimateTier reads recIlvl", "iLvl >= TIERS[i].recIlvl" in dsrc)
    check("companion is Valeera, not Brann", "Brann" not in dsrc and "Valeera" in dsrc)

    print("-- gear enchant slots")
    gsrc = read("Modules/Gear/Gear.lua")
    m = re.search(r"local ENCHANTABLE_SLOT = \{(.*?)\}", gsrc, re.S)
    slots = {int(x) for x in re.findall(r"\[(\d+)\]=true", m.group(1))} if m else set()
    check("enchantable slots = Head, Shoulder, Chest, Legs, Feet, Rings, Weapons",
          slots == {1, 3, 5, 7, 8, 11, 12, 16, 17}, str(sorted(slots)))

    # 2026-09-16 in-game /ta spellaudit (build 69814): IDs missing on the client
    # or pointing at a different spell must not come back.
    rot = read("Data/Retail/Rotations.lua") + read("Data/Retail/Spells.lua")
    bad = {121411: "Crimson Tempest (old)", 246287: "Evangelism (old)", 316099: "Unstable Affliction (old)",
           370452: "Tip the Scales (wrong)", 470053: "Voltaic Blaze (old)", 112965: "Fingers of Frost as Flurry",
           194311: "Festering Wound as Festering Strike",
           269752: "Flanking Strike as Wildfire Bomb", 370462: "phial as Shattering Star"}
    present = [f"{k} {v}" for k, v in bad.items() if re.search(r"(?<!\d)%d(?!\d)" % k, rot)]
    check("spellaudit-flagged IDs removed", not present, "; ".join(present))
    check("259489 (Survival Kill Command) never labelled Raptor Strike",
          re.search(r'spellID = 259489,\s*name = "Raptor Strike"', rot) is None)
    check("Scourge Strike is 55090, Festering Strike is 85948",
          re.search(r'spellID = 55090,\s*name = "Scourge Strike"', rot) is not None
          and re.search(r'spellID = 85948,\s*name = "Festering Strike"', rot) is not None)

    # 2026-09-17 spellaudit review: conditions must use the AURA id, not the cast id.
    cast_not_aura = {"C.DebuffRefresh(8921,": "Moonfire debuff is 164812", "C.DebuffRefresh(93402,": "Sunfire debuff is 164815",
                     "C.DebuffRefresh(1822,": "Rake bleed is 155722", "C.DebuffRefresh(77758,": "Thrash bleed is 192090",
                     "C.DebuffRefresh(172,": "Corruption debuff is 146739", "C.DebuffRefresh(348,": "Immolate debuff is 157736",
                     "C.HasBuff(185313)": "Shadow Dance buff is 185422", "C.HasBuff(77756)": "Lava Surge proc is 77762",
                     "C.HasBuff(269650)": "Pyroclasm proc is 269651", "C.HasBuff(53576)": "Infusion of Light proc is 54149",
                     "C.BuffRefresh(395152,": "Ebon Might buff is 395296", "C.HasBuff(447444)": "Entropic Rift is a ground effect",
                     "C.DebuffRefresh(445465,": "Wither debuff is 445474"}
    rot_only = read("Data/Retail/Rotations.lua")
    bad = [v for k, v in cast_not_aura.items() if k in rot_only]
    check("conditions use aura IDs, not cast IDs", not bad, "; ".join(bad))
    check("Firestorm removed from Devastation (not in 12.1 tree)", "368847" not in rot_only)

    # 2026-09-17 Survival spec check: Midnight Survival has no Coordinated Assault,
    # Fury of the Eagle or Flanking Strike (Takedown replaced them); its Kill Command
    # is 259489 and its Kill Shot 320976 (34026/53351 are the BM/MM versions).
    import re as _re
    m = _re.search(r"^R\[255\].*?(?=^R\[\d+\])", rot_only, _re.S | _re.M)
    sv = m.group(0) if m else ""
    check("Survival uses its own Kill Command/Kill Shot IDs", sv and "34026" not in sv and "53351" not in sv)
    check("Survival has no removed cooldowns", sv and not any(x in sv for x in ("Coordinated Assault", "Fury of the Eagle", "Flanking Strike")))

    passed = sum(1 for ok, _ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
