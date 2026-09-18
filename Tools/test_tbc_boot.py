#!/usr/bin/env python3
r"""
ToonAge -- TBC flavor boot test (Task 7)
========================================
Loads the ToonAge_TBC.toc file set, in TOC order, in an embedded Lua 5.1
runtime under a stubbed TBC client (WOW_PROJECT_ID = 5, Interface 20506, the
old tab-based talent API and classic globals present, retail C_* absent), then:

  * asserts every TBC file loads without a Lua error,
  * asserts TA.flavor == "tbc" and the tbc profile is active,
  * runs TA:InitModules() and asserts the TBC modules initialise while
    retail-only assumptions do not blow up,
  * asserts the profile allows the TBC module set and would deny an arbitrary
    retail-only module.

This is the guarantee that the shared Core + TBC-specific files + Modules/TBC
actually run together on a TBC client -- the core risk of folding a
separately-authored build onto the shared engine.

Usage:  python Tools/test_tbc_boot.py [-v]
"""

import sys
import re
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

# A stubbed TBC client: classic globals + old talent-tab API, no retail C_*.
TBC_PRELUDE = r"""
WOW_PROJECT_ID = 5
GetBuildInfo = function() return "2.5.6", "00000", "date", 20506 end

_printed = {}
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts+1] = tostring((select(i, ...))) end
    _printed[#_printed+1] = table.concat(parts, " ")
end

-- Frames: respond to any method, return self.
function MockFrame(name)
    local f = { _name = name, _shown = false, _scripts = {}, _children = {} }
    setmetatable(f, { __index = function(s, k)
        local fn = function(...) return s end
        rawset(s, k, fn); return fn
    end })
    f.Show = function(s) rawset(s,"_shown",true) return s end
    f.Hide = function(s) rawset(s,"_shown",false) return s end
    f.IsShown = function(s) return rawget(s,"_shown") end
    f.SetScript = function(s,e,fn) rawget(s,"_scripts")[e]=fn return s end
    f.GetScript = function(s,e) return rawget(s,"_scripts")[e] end
    f.CreateFontString = function(s) return MockFrame(name.."_fs") end
    f.CreateTexture = function(s) return MockFrame(name.."_tex") end
    return f
end
CreateFrame = function(kind, name, parent, tmpl) return MockFrame(name) end
C_Timer = { After = function(d, fn) end, NewTicker = function() return MockFrame("ticker") end }
UIParent = MockFrame("UIParent")
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

-- Player / unit
UnitName  = function() return "Tbctest" end
GetRealmName = function() return "Tbcrealm" end
UnitLevel = function() return 65 end
UnitClass = function() return "Mage", "MAGE" end
UnitRace  = function() return "Gnome", "Gnome" end
GetTime = function() return 0 end
InCombatLockdown = function() return false end
time = function() return 1750000000 end

-- Old tab-based talent API (classic family)
GetNumTalentTabs = function() return 3 end
GetTalentTabInfo = function(tab)
    local names = { "Arcane", "Fire", "Frost" }
    return names[tab] or "Tab"..tab, "icon", (tab == 3 and 56 or 0), nil
end
GetTalentInfo = function(t, i) return "Talent", "icon", 5, 5, 0, 5 end

-- Spellbook / action bars (classic ranks)
GetNumSpellTabs = function() return 1 end
GetSpellTabInfo = function() return "General", "icon", 0, 10 end
GetSpellBookItemName = function(slot) return "Frostbolt", "Rank 13" end
GetSpellBookItemInfo = function() return "SPELL", 116 end
IsPassiveSpell = function() return false end
GetActionInfo = function(slot) return "spell", 116 end
GetSpellInfo = function(id) return "Frostbolt", nil, 135846, 2500 end
GetShapeshiftFormInfo = function() return nil end
GetNumShapeshiftForms = function() return 0 end

-- Items / inventory (classic globals; no C_Container/C_Item)
GetInventoryItemLink = function(unit, slot) return nil end
GetItemInfo = function(item) return "Item", "link", 4, 100, 60, "Weapon", "Staves", 1, "INVTYPE_2HWEAPON" end
GetContainerNumSlots = function(bag) return 16 end
GetContainerItemLink = function(bag, slot) return nil end
GetContainerItemID = function(bag, slot) return nil end
GetContainerItemInfo = function(bag, slot) return nil end

-- Combat rating APIs present on TBC
GetCombatRating = function() return 0 end
GetCombatRatingBonus = function() return 0 end
GetExpertise = function() return 0, 0 end
GetDodgeChance = function() return 5 end
GetParryChance = function() return 5 end
GetBlockChance = function() return 5 end
GetSpellBonusDamage = function() return 0 end
GetSpellCritChance = function() return 0 end
GetInventoryItemsForSlot = function() return {} end
IsAddOnLoaded = function() return false end
GetAddOnInfo = function() return nil, "Title" end
hooksecurefunc = function() end
geterrorhandler = function() return function(err) end end
seterrorhandler = function() end
"""


def toc_lua_files(toc_name):
    toc = ROOT / toc_name
    out = []
    for line in toc.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        token = s.split("[")[0].strip()
        if token.lower().endswith(".lua"):
            out.append(token.replace("\\", "/"))
    return out


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


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(TBC_PRELUDE)

    files = toc_lua_files("ToonAge_TBC.toc")
    load_errors = []
    for rel in files:
        path = ROOT / rel
        if not path.exists():
            load_errors.append(f"{rel}: MISSING FILE")
            continue
        try:
            lua.execute(path.read_text(encoding="utf-8"))
        except Exception as e:
            first = str(e).splitlines()[0]
            load_errors.append(f"{rel}: {first}")

    check("all TBC files load without error", load_errors, [])
    if load_errors and VERBOSE:
        for e in load_errors:
            print("      LOAD ERROR:", e)

    ta = lua.globals().ToonAge
    check("flavor detected as tbc", ta.flavor, "tbc")
    check("tbc profile active", ta.GetProfile(ta).data, "TBC")

    # Profile gating: TBC set allowed, a retail-only module denied.
    check("profile allows Character", ta.ModuleInProfile(ta, "Character"), True)
    check("profile allows StatCaps",  ta.ModuleInProfile(ta, "StatCaps"), True)
    check("profile denies retail-only Delves", ta.ModuleInProfile(ta, "Delves"), False)

    # Boot: InitDB + InitModules should run the TBC modules without throwing.
    boot_error = None
    try:
        lua.execute("ToonAgeDB = {}")
        ta.InitDB(ta)
        ta.InitModules(ta)
    except Exception as e:
        boot_error = str(e).splitlines()[0]
    check("InitDB + InitModules run without error", boot_error, None)

    # Every TBC module that registered should be present and not init-errored.
    tbc_modules = ["Character", "StatCaps", "WeaponSkill", "RaceAdvisor",
                   "ProfessionAdvisor", "TalentBuilds", "Rotation", "Spells",
                   "PetCare", "Gear", "AutoEquip", "PvPAdvisor"]
    modules = ta.modules
    for name in tbc_modules:
        mod = modules[name]
        check(f"{name}: registered", mod is not None, True)
        if mod is not None:
            check(f"{name}: no init error", mod._initError, None)

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
