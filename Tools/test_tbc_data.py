#!/usr/bin/env python3
"""
ToonAge -- TBC Anniversary data accuracy tests
==============================================
Locks in the corrections from the 2026-09-16 TBC accuracy audit by executing
the real data files and cap engine in an embedded Lua 5.1 runtime:

  * Draenei hit racial is class-dependent (Heroic Presence melee/ranged for
    Warrior/Paladin/Hunter; Inspiring Presence spell for Mage/Priest/Shaman)
  * talent hit values: Surefooted 1%x3, Shaman Elemental Precision 2%x3,
    Nature's Guidance melee+spell, Prot Paladin Precision melee+spell
  * defense cap: 490 at 70 vs +3, 415 for a bear with 3/3 Survival of the Fittest
  * Warriors/Paladins wear Mail until 40, Plate from 40
  * pet food: 65-tier Outland food exists for every diet; food 30+ levels
    below the pet is rejected; at-level food outranks low food
  * no Wrath-only abilities in the DR table (Psychic Horror, Turn Evil)
  * ToonAge_TBC.toc does not load the MoP StatWeights copy

Usage:  python Tools/test_tbc_data.py [-v]
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"\n        {detail}" if detail and not ok else ""))


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8-sig")


def runtime(class_token="WARRIOR", level=70, talents=None, resil_pct=0):
    """talents: {name: rank}"""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = {}")
    lua.globals().CLASS = class_token
    lua.globals().LEVEL = level
    lua.globals().RESIL = resil_pct
    lua.execute("""
        local TA = ToonAge
        TA.Utils = {}
        local U = TA.Utils
        function U.GetPlayerClass() return CLASS end
        function U.GetPlayerLevel() return LEVEL end
        function U.GetPlayerRace() return "Draenei", "Draenei" end
        function U.SafeNum(v, d) return tonumber(v) or d or 0 end
        function U.SafeGetNum(fn, ...) local ok, v = pcall(fn, ...) return (ok and tonumber(v)) or 0 end
        function TA:RegisterModule() end
        UnitClass = function() return "x", CLASS end
        TALENTS = {}
        GetNumTalentTabs = function() return 1 end
        GetNumTalents = function() return #TALENTS end
        GetTalentInfo = function(tab, i) local t = TALENTS[i]; return t[1], nil, nil, nil, t[2] end
        GetCombatRating = function() return 0 end
        GetCombatRatingBonus = function() return RESIL end
        UnitDefense = function() return LEVEL * 5, 0 end
    """)
    if talents:
        t = lua.globals().TALENTS
        for i, (name, rank) in enumerate(talents.items(), start=1):
            t[i] = lua.table(name, rank)
    return lua


def main():
    print("-- racials")
    for cls, melee, spell in (("WARRIOR", 1, 0), ("HUNTER", 1, 0), ("PALADIN", 1, 0),
                              ("SHAMAN", 0, 1), ("MAGE", 0, 1), ("PRIEST", 0, 1)):
        lua = runtime(cls)
        lua.execute(read("Data/TBC/TBCRaces.lua"))
        m = lua.globals().ToonAge.Data.GetRaceMechanics("Draenei", cls)
        got = (m.meleeHitPercent or 0, m.spellHitPercent or 0)
        check(f"Draenei {cls} hit racial melee={melee} spell={spell}", got == (melee, spell), str(got))

    print("-- talent hit")
    cases = [
        ("HUNTER", {"Surefooted": 1}, 1, 0),
        ("HUNTER", {"Surefooted": 3}, 3, 0),
        ("SHAMAN", {"Elemental Precision": 3}, 0, 6),
        ("SHAMAN", {"Nature's Guidance": 3}, 3, 3),
        ("PALADIN", {"Precision": 3}, 3, 3),
        ("WARRIOR", {"Precision": 3}, 3, 0),
    ]
    for cls, tal, want_m, want_s in cases:
        lua = runtime(cls, talents=tal)
        lua.execute(read("Data/TBC/TBCTalentHit.lua"))
        m, s, _, ok = lua.globals().ToonAge.Data.DetectTalentHit()
        check(f"{cls} {tal} -> melee {want_m}% spell {want_s}%", ok and (m, s) == (want_m, want_s), f"got {m},{s}")

    lua = runtime("SHAMAN", talents={"Dual Wield Specialization": 3})
    lua.execute("GetInventoryItemLink = function() return nil end")
    lua.execute(read("Data/TBC/TBCTalentHit.lua"))
    m, s, _, _ = lua.globals().ToonAge.Data.DetectTalentHit()
    check("Dual Wield Specialization ignored without an off-hand weapon", m == 0, f"got {m}")

    print("-- defense cap")
    for cls, tal, resil, want in (("WARRIOR", None, 0, 490), ("DRUID", {"Survival of the Fittest": 3}, 0, 415),
                                  ("WARRIOR", None, 1.0, 465)):
        lua = runtime(cls, talents=tal, resil_pct=resil)
        lua.execute(read("Data/TBC/TBCTalentHit.lua"))
        lua.execute(read("Core/TBCStats.lua"))
        S = lua.globals().ToonAge.TBCStats
        cap = S.GetDefenseCap(S, lua.table_from({"contextKey": "plus3"})).cap
        check(f"defense cap {cls} tal={tal} resil={resil}% -> {want}", cap == want, f"got {cap}")

    print("-- armor")
    lua = runtime()
    lua.execute(read("Data/TBC/TBCArmor.lua"))
    D = lua.globals().ToonAge.Data
    for cls in ("WARRIOR", "PALADIN"):
        early = D.BestArmorFor(cls, 39)
        late = D.BestArmorFor(cls, 40)
        check(f"{cls} Mail at 39, Plate at 40", (early[0], late[0]) == ("Mail", "Plate"), f"{early[0]}/{late[0]}")

    print("-- pet food")
    lua = runtime()
    lua.execute(read("Data/TBC/PetFoods.lua"))
    F = lua.globals().ToonAge.Data.PetFoods
    for diet in ("Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus"):
        has65 = any(v.diet == diet and v.level == 65 for v in F.ITEMS.values())
        check(f"{diet} has a level-65 Outland vendor food", has65)
    low = F.ITEMS["Tough Jerky"]
    top = F.ITEMS["Smoked Talbuk Venison"]
    check("pet 70 refuses level-5 food", not F.IsEdible(F, low, 70))
    check("pet 70 eats level-65 food", F.IsEdible(F, top, 70))
    check("at-level food outranks below-level food for a level-60 pet",
          F.Rank(F, top, 60)[0] < F.Rank(F, F.ITEMS["Roasted Quail"], 60)[0])

    print("-- pvp / toc")
    import re as _re
    pvp = "\n".join(l for l in read("Data/TBC/TBCPvP.lua").splitlines() if not l.strip().startswith("--"))
    check("no Psychic Horror (Wrath) in TBC DR table", "Psychic Horror" not in pvp)
    check("no Turn Evil (Wrath) in TBC DR table", "Turn Evil" not in pvp)
    check("Kidney Shot has its own DR category", 'name = "Kidney Shot"' in pvp)
    toc = read("ToonAge_TBC.toc")
    check("TBC TOC does not load the MoP StatWeights copy", "Data\\TBC\\StatWeights.lua" not in toc)

    print("-- weights by class")
    from lupa import lua51 as _l
    wl = _l.LuaRuntime(unpack_returned_tuples=True)
    wl.execute('ToonAge = { Data = {}, Utils = {}, db = {} } CLASS = "WARRIOR" ToonAge.Utils.GetPlayerClass = function() return CLASS end')
    wl.execute(read("Data/TBC/TBCWeights.lua"))
    def w(cls, role="MELEE", pvp=False):
        wl.globals().CLASS = cls
        return wl.eval("ToonAge.Data.GetWeights")(role, pvp)
    check("Warrior melee is Strength-first", w("WARRIOR").primary == "STR")
    check("Rogue melee is Agility-first (Agility > Strength)", w("ROGUE").primary == "AGI" and w("ROGUE").AGI > w("ROGUE").STR)
    check("Feral cat is Agility-first", w("DRUID").primary == "AGI" and w("DRUID").AGI > w("DRUID").STR)
    check("Enhancement Shaman stays Strength-first", w("SHAMAN").primary == "STR")
    check("Rogue PvP table also Agility-first", w("ROGUE", pvp=True).primary == "AGI")
    check("Hunter ranged table unchanged", w("HUNTER", "RANGED").primary == "AGI")

    passed = sum(_results)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
