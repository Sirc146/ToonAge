#!/usr/bin/env python3
"""
ToonAge -- /ta spellaudit smoke test
Runs the real audit against the Retail data files with a stubbed client that is
missing one condition aura (Brain Freeze) and one currency, and checks every
report section is produced and the planted problems are found.
Usage:  python Tools/test_spellaudit.py [-v]
"""
import sys
from lupa import lua51
sys.path.insert(0,str(__import__('pathlib').Path(__file__).resolve().parent))
import test_tbc_boot as boot, test_tbc_render as r
R=str(__import__('pathlib').Path(__file__).resolve().parent.parent)+'/'
lua=lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(boot.TBC_PRELUDE); lua.execute(r.OVERRIDES)
lua.execute(r'''
WOW_PROJECT_ID = 1
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
StaticPopupDialogs = {}
ToonAge = { modules = {}, Data = {}, LOG = { OUTPUT = 1, INFO = 2, WARN = 3 }, flavor = "retail", charDB = {}, db = {} }
local TA = ToonAge
TA.Utils = setmetatable({}, { __index = function() return function() end end })
function TA:RegisterModule(n, m) self.modules[n] = m end
function TA:GetModule(n) return self.modules[n] end
function TA:Raw() end function TA:Print() end function TA:Printf() end
date = os.date
GetBuildInfo = function() return "12.1.0", "69814", "d", 120100 end
NAMES = { [44614] = "Flurry", [190446] = "Brain Freeze", [3561] = "Teleport: Stormwind", [61304] = "Global Cooldown" }
C_Spell = { GetSpellName = function(id) if id == 190446 then return nil end return NAMES[id] or ("Spell " .. id) end }
C_CurrencyInfo = { GetCurrencyInfo = function(id) local n = { [3442]="Adventurer Mistcrest", [3443]="Veteran Mistcrest", [3444]="Champion Mistcrest", [3445]="Hero Mistcrest", [3446]="Myth Mistcrest" } return n[id] and { name = n[id] } end }
GetSpecialization = function() return 3 end
GetSpecializationInfo = function() return 64, "Frost" end
C_ClassTalents = { GetActiveConfigID = function() return 1 end, GetHeroTalentSpecsForClassSpec = function() return { 39, 40 } end }
C_Traits = { GetConfigInfo = function() return { treeIDs = { 5 } } end, GetTreeNodes = function() return { 10 } end,
  GetNodeInfo = function() return { isVisible = true, entryIDs = { 20 } } end, GetEntryInfo = function() return { definitionID = 30 } end,
  GetDefinitionInfo = function() return { spellID = 44614 } end,
  GetSubTreeInfo = function(_, id) return { name = (id == 39) and "Frostfire" or "Spellslinger" } end }
IsPlayerSpell = function(id) return id == 116 end
''')
for f in ["Data/Retail/RotationConditions.lua","Data/Retail/Rotations.lua","Data/Retail/Spells.lua","Data/Retail/TalentsPvP.lua","Data/Retail/Talents.lua","Modules/Combat/CombatState.lua","Modules/Navigation/TravelRouter.lua"]:
    try: lua.execute(open(R+f,encoding='utf-8').read())
    except Exception as e: print("load", f, str(e).splitlines()[0])
lua.execute("ToonAge.modules.Gear = { UPGRADE_CURRENCIES = { {id=3442,name=\"Adventurer Mistcrest\"}, {id=9999,name=\"Fake Crest\"} } }")
try:
    lua.execute(open(R+"Modules/Infrastructure/DevHelpers.lua",encoding='utf-8').read())
except Exception as e: print("load DH", str(e).splitlines()[0])
lua.execute("_EXPORT = nil; local DH = ToonAge.modules.DevHelpers; DH.ShowExport = function(_, label, body) _EXPORT = body end")
lua.execute("ToonAge.modules.DevHelpers.SlashCommands.spellaudit(ToonAge.modules.DevHelpers)")
out = lua.eval("_EXPORT")
lines = [out[i] for i in range(1, len(out)+1)]
text = "\n".join(lines)
results = []
def check(name, ok):
    results.append(ok)
    if not ok or "-v" in sys.argv: print(("  ok    " if ok else "  FAIL  ") + name)
def section(title):
    i = next(k for k, l in enumerate(lines) if title in l)
    body = []
    for l in lines[i+1:]:
        if l.startswith("== "): break
        body.append(l)
    return [b for b in body if b.strip()]
check("report has all sections", all(s in text for s in ["Upgrade currencies", "Current spec check", "Condition aura IDs that do not exist", "condition aura references"]))
check("missing condition aura (Brain Freeze 190446) reported", any("190446" in l for l in section("Condition aura IDs that do not exist")))
check("missing currency reported", any("9999" in l and "MISSING" in l for l in section("Upgrade currencies")))
check("hero tree names read for current spec", "Frostfire, Spellslinger" in text)
check("rotation spells not in spec reported", any("Frozen Orb" in l for l in section("Current spec check")))
import re as _re
n = int(_re.search(r"(\d+) IDs checked", text).group(1))
check("module IDs (teleports, GCD, currencies) counted in total", n > 600)
print(f"[{'OK' if all(results) else 'FAIL'}] {sum(results)}/{len(results)} assertions passed.")
sys.exit(0 if all(results) else 1)
