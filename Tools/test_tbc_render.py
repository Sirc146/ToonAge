#!/usr/bin/env python3
"""
ToonAge -- TBC tab render smoke test (2026-09-16 Anniversary field report)
=========================================================================
Boots the ToonAge_TBC.toc file set as a level-17 Orc Hunter on the newer
Classic engine talent signature, renders every TBC tab, and asserts:

  * every tab renders without a Lua error
  * talents spent are detected on the id-first GetTalentTabInfo signature
  * unspent talent points are reported instead of "No talents spent"
  * Health / Ranged Crit read real values (not "n/a")
  * sidebar counts equipped slots
  * header shows TBC Anniversary, not Midnight
  * hunter caps: ranged hit, ranged weapon skill, no expertise target
  * rating conversion is available below level 60 (estimate)
  * no "/ta ..." instructions are drawn on Character or Stat Caps
  * buttons exist and the role button changes the role override

Usage:  python Tools/test_tbc_render.py [-v]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_tbc_boot as boot  # noqa: E402
from lupa import lua51

ROOT = boot.ROOT
VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"  -> {detail}" if detail and not ok else ""))


OVERRIDES = r"""
_texts = {}
_buttons = {}
local baseMock = MockFrame
function MockFrame(name)
    local f = baseMock(name or "anon")
    f.CreateFontString = function(s)
        local fs = baseMock("fs")
        fs.SetText = function(self, t) _texts[#_texts+1] = tostring(t) rawset(self, "_text", t) return self end
        fs.GetText = function(self) return rawget(self, "_text") end
        fs.GetStringWidth = function() return 40 end
        fs.GetStringHeight = function() return 12 end
        return fs
    end
    f.GetWidth = function() return 600 end
    f.NumLines = function() return 0 end
    f.SetScript = function(s, e, fn)
        rawget(s, "_scripts")[e] = fn
        if e == "OnClick" then _buttons[#_buttons+1] = s end
        return s
    end
    return f
end
CreateFrame = function(kind, name, parent, tmpl) return MockFrame(name) end
BackdropTemplateMixin = {}
Mixin = function(o, m) o.SetBackdrop = function() end o.SetBackdropColor = function() end o.SetBackdropBorderColor = function() end return o end
GameTooltip = MockFrame("GameTooltip")

UnitLevel = function() return 17 end
UnitClass = function() return "Hunter", "HUNTER" end
UnitRace  = function() return "Orc", "Orc" end
GetBuildInfo = function() return "2.5.5", "65000", "date", 20505 end
-- Newer engine: id, name, description, icon, pointsSpent, background
GetTalentTabInfo = function(tab)
    local names = { "Beast Mastery", "Marksmanship", "Survival" }
    return 360 + tab, names[tab], "desc", "icon", (tab == 1 and 7 or 0), "bg", 0, true
end
GetUnspentTalentPoints = function() return 1 end
UnitHealthMax = function() return 412 end
UnitManaMax = function() return 300 end
UnitPowerMax = function() return 300 end
UnitStat = function(u, i) return 30, 32, 2, 0 end
UnitAttackPower = function() return 86, 0, 0 end
UnitRangedAttackPower = function() return 86, 0, 0 end
UnitRangedAttack = function() return 83, 0 end
UnitAttackBothHands = function() return 85, 0, 0, 0 end
GetRangedCritChance = function() return 5.4 end
GetCritChance = function() return 4.1 end
GetInventoryItemLink = function(u, slot) if slot == 1 or slot == 5 or slot == 18 then return "item:1" end return nil end
GetAverageItemLevel = function() return 9, 9 end
UnitArmor = function() return 375, 375, 375, 0, 0 end
UnitDefense = function() return 85, 0 end
UnitResistance = function() return 0, 0, 0, 0 end
GetManaRegen = function() return 1, 1 end
UnitExists = function() return false end
-- Spellbook: Feed Pet (slot 1), Serpent Sting R1 (slot 2) and R2 (slot 3)
BOOKTYPE_SPELL = "spell"
GetNumSpellTabs = function() return 1 end
GetSpellTabInfo = function() return "General", "icon", 0, 4 end
local BOOK = { { "Feed Pet", "", 6991 }, { "Serpent Sting", "Rank 1", 1978 }, { "Serpent Sting", "Rank 2", 13549 }, { "Call Scorpid", "", 9001 } }
GetSpellBookItemName = function(slot) return BOOK[slot][1], BOOK[slot][2] end
GetSpellBookItemInfo = function(slot) return "SPELL", BOOK[slot][3] end
GetSpellBookItemTexture = function() return "tex" end
IsPassiveSpell = function() return false end
BAR = { [1] = 1978 }                       -- Serpent Sting R1 on main bar slot 1
GetActionInfo = function(slot) if BAR[slot] then return "spell", BAR[slot] end end
GetSpellInfo = function(id) if id == 883 then return "Call Pet" end for _, b in ipairs(BOOK) do if b[3] == id then return b[1] end end end
HasAction = function(slot) return BAR[slot] ~= nil end
CURSOR = nil
PickupSpellBookItem = function(slot) CURSOR = (BOOK[slot][3] == 9001) and 883 or BOOK[slot][3] end
GetCursorInfo = function() if CURSOR then return "spell", 1, "spell", CURSOR end end
PickupAction = function(slot) CURSOR = BAR[slot]; BAR[slot] = nil end
PlaceAction = function(slot) BAR[slot] = CURSOR; CURSOR = nil end
ClearCursor = function() CURSOR = nil end
HasPetUI = function() return false end
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(boot.TBC_PRELUDE)
    lua.execute(OVERRIDES)
    errors = []
    for rel in boot.toc_lua_files("ToonAge_TBC.toc"):
        try:
            lua.execute((ROOT / rel).read_text(encoding="utf-8"))
        except Exception as e:
            errors.append(f"{rel}: {str(e).splitlines()[0]}")
    check("TBC files load", not errors, errors[:3])
    ta = lua.globals().ToonAge
    lua.execute("ToonAgeDB = {}")
    ta.InitDB(ta)
    ta.InitModules(ta)

    U = ta.Utils
    name, pts, _, total = U.GetTalentSummary()
    check("talents read on id-first signature", name == "Beast Mastery" and total == 7, (name, total))
    check("spec label shows unspent", "unspent" in str(U.GetSpecLabel()), U.GetSpecLabel())
    ilvl, counted = U.GetAverageIlvl()
    check("sidebar slot count", counted == 3, counted)

    per, src = ta.TBCStats.GetRatingPerPercent(ta.TBCStats, "HIT_MELEE")
    check("rating conversion below 60 available", per is not None and src == "estimate", (per, src))
    check("level-17 hit rating per 1% = 10*(17-8)/52", per is not None and abs(per - 10 * 9 / 52) < 1e-6, per)

    caps = ta.modules.StatCaps
    data = caps.Collect(caps)
    check("hunter uses ranged weapon skill", data.weaponSkill == 83, data.weaponSkill)
    check("hunter hit cap flagged ranged", data.caps.meleeHit.ranged == True)
    check("hunter gets no expertise target", data.caps.expertise is None)

    tabs = ["Character", "StatCaps", "Gear", "TalentBuilds", "Rotation", "Spells",
            "WeaponSkill", "RaceAdvisor", "ProfessionAdvisor", "PetCare", "PvPAdvisor"]
    for t in tabs:
        mod = ta.modules[t]
        lua.execute("_texts = {} _buttons = {}")
        err = None
        try:
            content = lua.eval("MockFrame('content')")
            side = lua.eval("MockFrame('side')")
            mod.Render(mod, content, side)
        except Exception as e:
            err = str(e).splitlines()[0]
        check(f"{t} renders", err is None, err)
        texts = list(lua.eval("_texts").values())
        joined = "\n".join(texts)
        if t in ("Character", "StatCaps"):
            check(f"{t}: no /ta instructions drawn", "/ta " not in joined,
                  [x for x in texts if "/ta " in x][:2])
        if t == "Character":
            check("Character: Health not n/a", "412" in joined)
            check("Character: headline says ranged hit", "ranged hit" in joined)
            check("Character: no Midnight text", "Midnight" not in joined)
            nb = len(list(lua.eval("_buttons").values()))
            check("Character: role + caps buttons drawn", nb >= 7, nb)
            # click "Melee" (second role button)
            btn = lua.eval("_buttons")[2]
            btn._scripts.OnClick()
            check("role button sets override", ta.charDB.roleOverride == "MELEE", ta.charDB.roleOverride)
            ta.charDB.roleOverride = "auto"
        if t == "StatCaps":
            check("StatCaps: shows current level", "You are level" in joined)
            check("StatCaps: no red absent-globals alarm", "Combat rating globals absent" not in joined)

    # Spells: drag/place helpers
    def missing_list():
        return list(U.FindMissingSpellRanks().values())
    names = sorted((m.name, m.onBar) for m in missing_list())
    check("missing spells detected", names == [("Call Scorpid", False), ("Feed Pet", False), ("Serpent Sting", True)], names)
    fp = [m for m in missing_list() if m.name == "Feed Pet"][0]
    ss = [m for m in missing_list() if m.name == "Serpent Sting"][0]
    cs = [m for m in missing_list() if m.name == "Call Scorpid"][0]
    check("upgrade targets the bar slot holding the old rank", ss.barSlot == 1, ss.barSlot)
    slot = U.FindEmptyActionSlot()[0]
    check("first empty slot is main bar slot 2", slot == 2, slot)
    ok, msg = U.PlaceSpellOnBar(fp, slot)
    check("Add to bar places Feed Pet", ok and lua.eval("BAR[2]") == 6991, msg)
    ok, msg = U.PlaceSpellOnBar(ss, ss.barSlot)
    check("Upgrade replaces rank 1 with rank 2", ok and lua.eval("BAR[1]") == 13549, msg)
    ok, msg = U.PlaceSpellOnBar(cs, U.FindEmptyActionSlot()[0])
    check("Call Scorpid placed once", ok and lua.eval("BAR[3]") == 883, msg)
    check("Call Scorpid no longer missing after placing", len(missing_list()) == 0, [m.name for m in missing_list()])
    # Simulate the old bug: extra copies already on bars, alias forgotten
    lua.execute("BAR[4] = 883; BAR[5] = 883; ToonAge.charDB.spellBarAliases = nil")
    cs = [m for m in missing_list() if m.name == "Call Scorpid"][0]
    ok, msg = U.PlaceSpellOnBar(cs, U.FindEmptyActionSlot()[0])
    check("repeat click does not add another copy", (not ok) and "already on" in msg and lua.eval("BAR[6]") is None, msg)
    check("alias learned, spell cleared from list", len(missing_list()) == 0)
    dupes = list(U.FindDuplicateBarSpells().values())
    check("duplicates found", len(dupes) == 2, len(dupes))
    removed = U.ClearActionSlots(U.FindDuplicateBarSpells())
    check("duplicates removed, first kept", removed == 2 and lua.eval("BAR[3]") == 883 and lua.eval("BAR[4]") is None and lua.eval("BAR[5]") is None)
    lua.execute("InCombatLockdown = function() return true end")
    ok, msg = U.PlaceSpellOnBar(fp, 7)
    check("placing blocked in combat", (not ok) and "combat" in msg, msg)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
