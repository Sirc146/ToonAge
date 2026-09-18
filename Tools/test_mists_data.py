#!/usr/bin/env python3
"""
ToonAge -- Mists of Pandaria Classic data accuracy tests
=======================================================
Locks in the corrections from the 2026-09-16 Mists accuracy audit:

  * caster hit cap is 15% combined hit + expertise (expertise counts as spell hit)
  * Balance/Elemental/Shadow weight Spirit like hit (Spirit -> hit conversion)
  * caps are percent based: boss caps at 90, same-level caps while leveling
  * healers are never reported hit/expertise capped
  * tanks' expertise cap is 15%, other melee/ranged 7.5%
  * armor: Plate/Mail proficiency at 40, Armor Specialization gate at 50
  * PvP stats (Resilience, PvP Power) weighted only in PvP mode
  * Gear.CalculateItemScore works without an explicit specID (AutoEquip path)

Usage:  python Tools/test_mists_data.py [-v]
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


def runtime(class_token="HUNTER", level=90, spec=253):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().CLASS = class_token
    lua.globals().LEVEL = level
    lua.globals().SPEC = spec
    lua.execute("""
        ToonAge = { modules = {}, Data = {}, charDB = { pvxMode = "pve" } }
        local TA = ToonAge
        TA.Utils = {}
        local U = TA.Utils
        function U.GetPlayerSpec() return SPEC end
        function U.GetItemIlvl() return 0 end
        function TA:RegisterModule(n, m) self.modules[n] = m end
        function TA:GetModule(n) return self.modules[n] end
        function UnitClass() return CLASS, CLASS end
        function UnitLevel() return LEVEL end
        function hooksecurefunc() end
        ITEMSTATS = {}
        function GetItemStats(link) return ITEMSTATS[link] end
        local stub = setmetatable({}, { __index = function() return function() return stub end end,
                                        __call = function() return stub end })
        setmetatable(_G, { __index = function(_, k) return stub end })
    """)
    lua.execute(read("Data/Mists/StatWeights.lua"))
    lua.execute(read("Modules/Mists/Gear.lua"))
    return lua


lua = runtime()
SW = lua.eval("ToonAge.Data.StatWeights or StatWeights")
if SW is None:
    SW = lua.eval("(function() for k,v in pairs(ToonAge.Data) do if type(v)=='table' and v.IsHitCapped then return v end end end)()")
check("StatWeights table found", SW is not None)

def f(expr):
    return lua.eval(expr)

swref = "(function() for k,v in pairs(ToonAge.Data) do if type(v)=='table' and v.IsHitCapped then return v end end end)()"
lua.execute(f"SWT = {swref}")

# Caster: 10% hit + 5% expertise = 15% -> capped at 90
check("caster 10% hit + 5% exp capped at 90", f("SWT:IsHitCapped(10, 262, 5, 90)"))
check("caster 10% hit alone not capped at 90", not f("SWT:IsHitCapped(10, 262, 0, 90)"))
check("caster expertise row shares combined cap", f("SWT:IsExpCapped(5, 262, 10, 90)"))
check("caster same-level cap 6% while leveling", f("SWT:IsHitCapped(4, 62, 2, 60)"))
check("melee 7.5% hit capped at 90", f("SWT:IsHitCapped(7.5, 71, 0, 90)"))
check("melee 7.4% hit not capped at 90", not f("SWT:IsHitCapped(7.4, 71, 0, 90)"))
check("melee 3% hit capped while leveling", f("SWT:IsHitCapped(3, 71, 0, 50)"))
check("DPS expertise 7.5% capped", f("SWT:IsExpCapped(7.5, 72, 0, 90)"))
check("tank expertise 7.5% NOT capped (15% hard cap)", not f("SWT:IsExpCapped(7.5, 73, 0, 90)"))
check("tank expertise 15% capped", f("SWT:IsExpCapped(15, 73, 0, 90)"))
check("healer never hit capped", not f("SWT:IsHitCapped(50, 65, 50, 90)"))

for sid in (62, 63, 64, 102, 262, 258, 265, 266, 267):
    for mode in ("pve", "pvp"):
        ok = f(f"SWT[{sid}].{mode}.EXP == SWT[{sid}].{mode}.HIT and SWT[{sid}].{mode}.HIT > 0")
        check(f"caster {sid} {mode} EXP weight equals HIT", ok)
for sid in (102, 262, 258):
    check(f"spirit-to-hit spec {sid} SPI weight equals HIT", f(f"SWT[{sid}].pve.SPI == SWT[{sid}].pve.HIT"))

# PvP stats
lua.execute('ITEMSTATS["pvp"] = { ITEM_MOD_RESILIENCE_RATING_SHORT = 100 }')
check("resilience worth 0 in PvE", f("SWT:ScoreItem({RESIL=100}, 253, 'pve')") == 0)
check("resilience weighted in PvP", f("SWT:ScoreItem({RESIL=100}, 253, 'pvp')") >= 100)

# Armor rules
G = "ToonAge.modules.Gear"
check("warrior level 39 max Mail", f(f"{G}.MaxArmorType('WARRIOR', 39)") == 3)
check("warrior level 40 max Plate", f(f"{G}.MaxArmorType('WARRIOR', 40)") == 4)
check("hunter level 39 max Leather", f(f"{G}.MaxArmorType('HUNTER', 39)") == 2)
check("hunter level 40 max Mail", f(f"{G}.MaxArmorType('HUNTER', 40)") == 3)
check("DK Plate", f(f"{G}.MaxArmorType('DEATHKNIGHT', 55)") == 4)
check("hunter 45 may wear leather (pre Armor Specialization)", f(f"{G}.ArmorSubclassAllowed(2, 'HUNTER', 45)"))
check("hunter 50 rejects leather (Armor Specialization)", not f(f"{G}.ArmorSubclassAllowed(2, 'HUNTER', 50)"))
check("hunter 30 rejects mail", not f(f"{G}.ArmorSubclassAllowed(3, 'HUNTER', 30)"))
check("paladin 20 may wear mail", f(f"{G}.ArmorSubclassAllowed(3, 'PALADIN', 20)"))
check("mage never wears leather", not f(f"{G}.ArmorSubclassAllowed(2, 'MAGE', 20)"))

# AutoEquip path: no specID argument
lua.execute('ITEMSTATS["agi"] = { ITEM_MOD_AGILITY_SHORT = 100 }')
check("CalculateItemScore without specID uses active spec", (f(f"{G}.CalculateItemScore('agi')") or 0) > 0)

# PetCare no longer references the removed quest as outstanding
pc = read("Modules/Mists/PetCare.lua")
check("PetCare does not tell players to complete Taming the Beast", "not completed" not in pc)

passed = sum(_results)
print(f"test_mists_data: {passed}/{len(_results)} passed")
sys.exit(0 if passed == len(_results) else 1)
