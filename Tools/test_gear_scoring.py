#!/usr/bin/env python3
"""
ToonAge -- Retail gear scoring regression test (2026-09-17 field report)
=======================================================================
In-game: an Assassination Rogue's Gear tab called Heart of Azeroth (ilvl 26:
6 Stam, 7 Crit, 7 Haste, 7 Mastery) a "+13% upgrade" over Gem-Studded Pendant
of the Harmonious (ilvl 75: 14 Stam, 28 Versatility, 19 Mastery).

Root cause: C_Item.GetItemStats returns Versatility under ITEM_MOD_VERSATILITY
(no _SHORT); the scorer read ITEM_MOD_VERSATILITY_SHORT, so Versatility scored 0.
Also locks in: the item being replaced is removed from the live rating before
DR, so an equipped item isn't double-counted.

Usage:  python Tools/test_gear_scoring.py [-v]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_tbc_boot as boot  # noqa: E402
import test_tbc_render as r    # noqa: E402
from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"  -> {detail}" if detail and not ok else ""))


lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(boot.TBC_PRELUDE)
lua.execute(r.OVERRIDES)
lua.execute(r"""
WOW_PROJECT_ID = 1
ToonAge = { modules = {}, Data = {}, LOG = { OUTPUT = 1, INFO = 2, WARN = 3, ERROR = 4 }, charDB = { pvxMode = "pve" }, db = {} }
local TA = ToonAge
function TA:RegisterModule(n, m) self.modules[n] = m end
function TA:GetModule(n) return self.modules[n] end
function TA:Raw() end function TA:Print() end function TA:Printf() end
WorldFrame = MockFrame("WorldFrame")
ITEMS = {
  pendant = { id = 224665, loc = "INVTYPE_NECK",
              stats = { ITEM_MOD_STAMINA_SHORT = 14, ITEM_MOD_VERSATILITY = 28, ITEM_MOD_MASTERY_RATING_SHORT = 19 } },
  heart   = { id = 158075, loc = "INVTYPE_NECK",
              stats = { ITEM_MOD_STAMINA_SHORT = 6, ITEM_MOD_CRIT_RATING_SHORT = 7, ITEM_MOD_HASTE_RATING_SHORT = 7, ITEM_MOD_MASTERY_RATING_SHORT = 7 } },
}
C_Item = { GetItemStats = function(link) return ITEMS[link] and ITEMS[link].stats end,
           GetDetailedItemLevelInfo = function() return 75 end }
GetItemInfoInstant = function(link) local it = ITEMS[link]; if it then return it.id, "Armor", "Misc", it.loc end end
GetItemInfo = function(link) local it = ITEMS[link]; if it then return link, link, 3, 75, 70, "Armor", "Misc", 1, it.loc end end
GetInventoryItemLink = function(unit, slot) if slot == 2 then return "pendant" end end
GetSpecialization = function() return 1 end
GetSpecializationInfo = function() return 259, "Assassination", "", "", "DAMAGER" end
RATINGS = { [9] = 120, [18] = 150, [26] = 300, [29] = 260 }
GetCombatRating = function(i) return RATINGS[i] or 0 end
GetCombatRatingBonus = function(i) return (RATINGS[i] or 0) / 10 end
UnitExists = function() return false end
UnitLevel = function() return 80 end
""")
for f in ["Core/Utils.lua", "Data/Retail/StatWeights.lua", "Core/StatEngine.lua", "Modules/Gear/Gear.lua"]:
    try:
        lua.execute((ROOT / f).read_text(encoding="utf-8"))
    except Exception as e:
        print("load", f, str(e).splitlines()[0])

U = lua.eval("ToonAge.Utils")
st = U.ReadItemStats("pendant")
check("Versatility read from ITEM_MOD_VERSATILITY", st.VERS == 28, st.VERS)
check("_SHORT fallback still accepted", lua.eval('(function() ITEMS.x = { id=1, loc="INVTYPE_NECK", stats = { ITEM_MOD_VERSATILITY_SHORT = 5 } } return ToonAge.Utils.ReadItemStats("x").VERS end)()') == 5)

Gear = lua.eval("ToonAge.modules.Gear")
p = Gear.CalculateItemScore("pendant", 259, "pve")
h = Gear.CalculateItemScore("heart", 259, "pve")
check("pendant (28 Vers, 19 Mastery) outscores Heart of Azeroth for Assassination", p > h, (p, h))
check("Heart of Azeroth is a big downgrade (>30%)", (p - h) / p > 0.30, (p, h))
for spec in (260, 261, 71, 62, 250):
    lua.execute(f'GetSpecializationInfo = function() return {spec}, "x", "", "", "DAMAGER" end')
    p = Gear.CalculateItemScore("pendant", spec, "pve")
    h = Gear.CalculateItemScore("heart", spec, "pve")
    check(f"spec {spec}: pendant beats Heart of Azeroth", p > h, (p, h))

# DR baseline: the equipped item and a stat-identical copy must score the same.
lua.execute('ITEMS.copy = { id = 999, loc = "INVTYPE_NECK", stats = ITEMS.pendant.stats }')
lua.execute('GetSpecializationInfo = function() return 259, "Assassination", "", "", "DAMAGER" end')
lua.execute("RATINGS[29] = 2000")   # deep in Versatility DR
a = Gear.CalculateItemScore("pendant", 259, "pve")
b = Gear.CalculateItemScore("copy", 259, "pve")
check("equipped item not double-counted under DR (equals an identical unequipped copy)", abs(a - b) < 0.01, (a, b))

passed = sum(_results)
print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
sys.exit(0 if passed == len(_results) else 1)
