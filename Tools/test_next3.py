#!/usr/bin/env python3
"""
ToonAge -- Next-3 prediction bar tests (Modules/Combat/CombatState.lua)
======================================================================
  * a long cooldown used in slot 1 does not reappear in slot 3
    (the live cooldown is 0 for a ready spell; the sim now uses the base cooldown)
  * mana fillers may repeat back-to-back; resource spenders may not
  * override spells (e.g. Vampiric Strike replacing Scourge Strike) are shown
    when active, and hidden when not
  * AoE count ignores unpulled hostile nameplates
  * the live view switches to single target on 1 engaged enemy and AoE on 3+

Usage:  python Tools/test_next3.py [-v]
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
ToonAge = { modules = {}, Data = {}, LOG = { OUTPUT = 1, INFO = 2, WARN = 3, ERROR = 4 }, charDB = {}, db = {} }
local TA = ToonAge
function TA:RegisterModule(n, m) self.modules[n] = m end
function TA:GetModule(n) return self.modules[n] end
function TA:Raw() end
_now = 100
GetTime = function() return _now end
KNOWN = { [1] = true, [2] = true, [3] = true, [4] = true, [10] = true }
BASECD = { [1] = 90000 }                     -- spell 1: 90s cooldown
COST = { [3] = { { type = 3, cost = 35, minCost = 35 } },  -- 3: energy spender
         [2] = { { type = 0, cost = 500, minCost = 500 } } } -- 2: mana filler
OVERRIDE = {}
C_SpellBook = { IsSpellKnown = function(id) return KNOWN[id] or false end }
IsPlayerSpell = function(id) return false end
GetSpellBaseCooldown = function(id) return BASECD[id] or 0, 1500 end
C_Spell = {
  GetSpellCooldown = function(id) return { startTime = 0, duration = 0 } end,
  GetSpellCharges = function(id) return nil end,
  IsSpellUsable = function(id) return true end,
  GetSpellPowerCost = function(id) return COST[id] end,
  GetOverrideSpell = function(id) return OVERRIDE[id] or id end,
}
GetHaste = function() return 0 end
UnitExists = function(u) return NP[u] ~= nil end
UnitCanAttack = function() return true end
UnitIsDead = function() return false end
UnitThreatSituation = function(_, u) return NP[u] and NP[u].threat or nil end
UnitAffectingCombat = function(u) return NP[u] and NP[u].combat or false end
UnitIsUnit = function() return false end
IsInGroup = function() return true end
C_NamePlate = { GetNumNamePlates = function() return 0 end }
NP = {}
""")
for f in ["Core/Utils.lua", "Data/Retail/RotationConditions.lua", "Modules/Combat/CombatState.lua"]:
    lua.execute((ROOT / f).read_text(encoding="utf-8"))

CS = lua.eval("ToonAge.modules.CombatState")


def names(prio_lua):
    res = CS.GetNextN(CS, lua.eval(prio_lua), 90, 3)
    return [res[i].entry.name for i in range(1, len(res) + 1)]


# 1) long cooldown not repeated in slot 3
got = names('{ {spellID=1,name="BigCD"}, {spellID=3,name="Spender"}, {spellID=2,name="Filler"} }')
check("90s cooldown shown once, not again in slot 3", got.count("BigCD") == 1, got)

# 2) filler repeats, spender does not
got = names('{ {spellID=2,name="Filler"}, {spellID=4,name="Other"} }')
check("mana filler can repeat back-to-back", got[:2] == ["Filler", "Filler"], got)
got = names('{ {spellID=3,name="Spender"}, {spellID=4,name="Other"} }')
check("resource spender does not repeat back-to-back", got[:2] == ["Spender", "Other"], got)

# 3) overrides
prio = '{ {spellID=11,name="Vampiric Strike"}, {spellID=10,name="Scourge Strike"} }'
got = names(prio)
check("override hidden when not active", "Vampiric Strike" not in got, got)
lua.execute("OVERRIDE[10] = 11")
got = names(prio)
check("override shown when its base spell is replaced", got and got[0] == "Vampiric Strike", got)
lua.execute("OVERRIDE = {}")

# 4) AoE count
lua.execute('NP = { nameplate1 = { threat = 1 }, nameplate2 = {}, nameplate3 = {}, nameplate4 = { threat = 0 } }')
lua.execute("ToonAge.modules.CombatState:Snapshot()")
check("AoE count ignores unpulled nameplates", lua.eval("ToonAge.modules.CombatState.state.aoeCount") == 2,
      lua.eval("ToonAge.modules.CombatState.state.aoeCount"))

# 5) live view
src = (ROOT / "Modules/Combat/Rotation.lua").read_text(encoding="utf-8")
start = src.index("function Rotation:LiveView(CS)")
end = src.index("\nend", start) + 4
lua.execute("Rotation = {}\n" + src[start:end])
lua.execute('RV = function(view, inCombat, n) Rotation.currentView = view; return Rotation:LiveView({ state = { inCombat = inCombat, aoeCount = n } }) end')
check("dungeon boss (1 enemy) uses single target", lua.eval('RV("aoe", true, 1)') == "st")
check("open-world pack (3+) uses AoE", lua.eval('RV("solo", true, 4)') == "aoe")
check("out of combat keeps the content view", lua.eval('RV("aoe", false, 1)') == "aoe")
check("2 enemies keep the content view", lua.eval('RV("st", true, 2)') == "st")

# 6) healers: group health gates and triage
lua.execute(r"""
    HP = { player = {100,100}, party1 = {100,100}, party2 = {100,100}, party3 = {100,100}, party4 = {100,100} }
    ROLE = { party1 = "TANK" }
    NAME = { party1 = "Tanky", party2 = "Dps" }
    UnitHealth = function(u) return HP[u] and HP[u][1] or 0 end
    UnitHealthMax = function(u) return HP[u] and HP[u][2] or 0 end
    local oldExists = UnitExists
    UnitExists = function(u) if HP[u] then return true end return oldExists(u) end
    UnitIsDeadOrGhost = function() return false end
    UnitIsConnected = function() return true end
    UnitIsUnit = function() return false end
    UnitGroupRolesAssigned = function(u) return ROLE[u] or "DAMAGER" end
    UnitName = function(u) return NAME[u] or u end
    IsInRaid = function() return false end
    IsInGroup = function() return true end
    KNOWN[19750] = true; KNOWN[20473] = true
""")
lua.execute((ROOT / "Data/Retail/Rotations.lua").read_text(encoding="utf-8"))
st = lua.eval("ToonAge.modules.CombatState.state")


def holy_pal_names():
    lua.execute("ToonAge.modules.CombatState._UpdateGroup()")
    prio = lua.eval("{ {spellID=20473,name='Holy Shock-ish'} }")
    fol = None
    R = lua.eval("ToonAge.Data.Rotations")
    for view in ("st", "aoe", "solo"):
        v = R[65][view]
        for i in range(1, len(v.priorities) + 1):
            if v.priorities[i].name == "Flash of Light":
                fol = v.priorities[i]
    return fol


fol = holy_pal_names()
check("Holy Paladin Flash of Light has a group-health gate", fol is not None and fol.when is not None)
lua.execute("BUFFS_IOL = true")
st.buffs[54149] = lua.eval("{ stacks = 1, expires = 0 }")   # Infusion of Light up
check("full health group: Flash of Light not suggested", fol.when(st, fol) is False)
lua.execute("HP.party2 = {60,100}")
lua.execute("ToonAge.modules.CombatState._UpdateGroup()")
check("ally at 60%: Flash of Light suggested", fol.when(st, fol) is True)
check("triage picks the hurt ally", st.group.triage is not None and st.group.triage.name == "Dps", st.group.triage and st.group.triage.name)
lua.execute("HP.party1 = {55,100}")
lua.execute("ToonAge.modules.CombatState._UpdateGroup()")
check("triage prefers the tank at similar health", st.group.triage.name == "Tanky", st.group.triage.name)
lua.execute('UnitHealth = function() error("secret") end')
lua.execute("ToonAge.modules.CombatState._UpdateGroup()")
check("unreadable health: heal gates stay permissive", fol.when(st, fol) is True)

passed = sum(_results)
print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
sys.exit(0 if passed == len(_results) else 1)
