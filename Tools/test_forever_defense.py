#!/usr/bin/env python3
"""
ToonAge -- Forever character sheet combat reads
================================================
UnitDefense, UnitAttackBothHands and UnitRangedAttack are absent on Forever.
Defense comes from UnitDefenseSkill, then skill line 95, then a line named
Defense. A reading far from 5 per level is hidden. The ranged row stays.
Attack power comes from UnitRangedAttackPower. Damage comes from
UnitRangedDamage (speed, min, max). A missing value is n/a on its own.
UnitRangedAttack stays unused. A missing speed is never shown as 0.0.

UnitDefenseSkill, UnitWeaponAttackPower, UnitRangedAttackPower and
UnitRangedDamage are UNVERIFIED on live build 70790.

Usage:  python3 Tools/test_forever_defense.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def load(lua, rel):
    lua.execute((ROOT / rel).read_text(encoding="utf-8"))


lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(r"""
ToonAge = { flavor = "forever", IsForever = true, modules = {} }
function ToonAge:RegisterModule(name, mod)
    self.modules[name] = mod
    return mod
end
function ToonAge:GetModule(name)
    return self.modules[name]
end

called = { UnitDefense = 0, UnitAttackBothHands = 0, UnitRangedAttack = 0 }
UnitDefense = function()
    called.UnitDefense = called.UnitDefense + 1
    return 999, 1
end
UnitAttackBothHands = function()
    called.UnitAttackBothHands = called.UnitAttackBothHands + 1
    return 1, 1, 1, 1
end
UnitRangedAttack = function()
    called.UnitRangedAttack = called.UnitRangedAttack + 1
    return 1, 1
end
UnitRangedAttackPower = function() return 80, 0, 0 end

UnitName = function() return "Tester" end
UnitClass = function() return "Rogue", "ROGUE" end
UnitRace = function() return "Human", "Human" end
level = 9
UnitLevel = function() return level end

rows = {}
local L = { C_DIM = { 0.5, 0.5, 0.5 }, PAD = 8 }
function L:Width() return 420 end
function L:StatScale() return 100 end
setmetatable(L, { __index = function()
    return function(_, _, y, opts)
        if type(opts) == "table" and opts.label then
            rows[#rows + 1] = opts
        end
        if type(y) ~= "number" then y = 0 end
        return y - 1
    end
end })
ToonAge.Layout = L

local function widget()
    return {
        SetHeight = function() end,
        CreateFontString = function() return { SetPoint = function() end, SetWidth = function() end, SetText = function() end } end,
    }
end
content = widget()

function render()
    rows = {}
    ToonAge.modules.ForeverCharacter:Render(content, nil)
end

function row(label)
    for i = 1, #rows do
        if rows[i].label == label then return rows[i] end
    end
end

function has(label)
    return row(label) ~= nil
end
""")

load(lua, "Core/Compat/API.lua")
load(lua, "Core/Utils.lua")
load(lua, "Core/TBCStats.lua")
load(lua, "Modules/Forever/Character.lua")

lua.execute(r"""
-- UnitDefenseSkill is present. Forever must not call UnitDefense.
-- UNVERIFIED return: base, modifier. No max, so the sheet uses level * 5
-- when the base sits inside that band.
UnitDefenseSkill = function() return 42, 0 end
UnitWeaponAttackPower = function() return 10, 2, 4, 1 end
C_SkillInfo = nil
level = 9
ToonAge.IsForever = true
ToonAge.flavor = "forever"
render()
fromSkill = row("Defense Skill")
melee = row("Melee Attack")
rapRow = row("Ranged Attack Power")
dmgRow = row("Ranged Damage")
traps = called.UnitDefense + called.UnitAttackBothHands + called.UnitRangedAttack

-- Level 1 is 1/5, still inside the band.
UnitDefenseSkill = function() return 1, 0 end
level = 1
render()
atOne = row("Defense Skill")

-- A modifier is shown, and the base is what the range check sees.
UnitDefenseSkill = function() return 40, 2 end
level = 9
render()
withMod = row("Defense Skill")

-- Clearly outside 5 per level: hide the row. Do not fall through to a
-- saner skill-line reading, and do not call UnitDefense.
UnitDefenseSkill = function() return 300, 0 end
C_SkillInfo = {
    GetSkillLineInfoByID = function(id)
        if id == 95 then return { name = "Defense", rank = 42, maxRank = 45, modifier = 0 } end
    end,
}
level = 9
render()
hiddenWild = row("Defense Skill")

-- UnitDefenseSkill absent: skill line 95.
UnitDefenseSkill = nil
level = 1
C_SkillInfo = {
    GetSkillLineInfoByID = function(id)
        if id == 95 then return { name = "Defense", rank = 1, maxRank = 5, modifier = 0 } end
    end,
}
render()
fromID = row("Defense Skill")

-- Skill 95 absent: a line named Defense.
C_SkillInfo = {
    GetSkillLineInfoByID = function() return nil end,
    GetNumSkillLines = function() return 2 end,
    GetSkillLineInfo = function(i)
        if i == 1 then return { name = "Weapon Skills", isHeader = true } end
        return { name = "Defense", isHeader = false, rank = 42, maxRank = 45, modifier = 0, skillID = 95 }
    end,
}
level = 9
render()
fromName = row("Defense Skill")

-- Skill 95 present but the max is nowhere near 5 per level.
UnitDefenseSkill = nil
C_SkillInfo = {
    GetSkillLineInfoByID = function(id)
        if id == 95 then return { name = "Defense", rank = 300, maxRank = 900, modifier = 0 } end
    end,
}
level = 9
render()
hiddenCap = row("Defense Skill")

-- No melee function: no melee row. The ranged rows stay.
UnitWeaponAttackPower = nil
UnitDefenseSkill = function() return 42, 0 end
C_SkillInfo = nil
render()
noMelee = row("Melee Attack")
rapStill = row("Ranged Attack Power")
dmgStill = row("Ranged Damage")
speedStill = row("Ranged Speed")
dpsStill = row("Ranged DPS")

-- A full ranged read. Power is base + pos + neg. Damage is speed, min, max.
UnitRangedAttackPower = function() return 72, 5, -1 end
UnitRangedDamage = function() return 2.8, 45, 62, 0, 0, 1 end
render()
rapFull = row("Ranged Attack Power")
dmgFull = row("Ranged Damage")
speedFull = row("Ranged Speed")
dpsFull = row("Ranged DPS")

-- One damage return is nil. That piece is n/a. The row and the other
-- numbers stay. Nothing is formatted as 0.0.
UnitRangedDamage = function() return 2.8, nil, 62 end
render()
dmgPartial = row("Ranged Damage")
speedPartial = row("Ranged Speed")
dpsPartial = row("Ranged DPS")
rapPartial = row("Ranged Attack Power")

-- A zero swing speed is not a real reading.
UnitRangedDamage = function() return 0, 10, 12 end
render()
dmgZeroSpeed = row("Ranged Damage")
speedZero = row("Ranged Speed")
dpsZero = row("Ranged DPS")

-- Both functions missing or throwing. Both rows stay, both values are
-- unavailable, and UnitRangedAttack is still not called.
UnitRangedAttackPower = function() error("absent") end
UnitRangedDamage = nil
local beforeRanged = called.UnitRangedAttack
render()
rapDown = row("Ranged Attack Power")
dmgDown = row("Ranged Damage")
speedDown = row("Ranged Speed")
dpsDown = row("Ranged DPS")
rangedAttackCalls = called.UnitRangedAttack - beforeRanged

-- No ranged weapon: zeros are not a reading.
UnitRangedAttackPower = function() return 0, 0, 0 end
UnitRangedDamage = function() return 0, 0, 0 end
render()
bareAp = row("Ranged Attack Power")
bareDmg = row("Ranged Damage")
bareSpeed = row("Ranged Speed")
bareDps = row("Ranged DPS")

-- A wand-shaped read. 19 and 20.4 over 1.0s is 19.7 DPS. Not 0.0.
UnitRangedAttackPower = function() return 12, 0, 0 end
UnitRangedDamage = function() return 1, 19, 20.4 end
render()
wandDps = row("Ranged DPS")
wandSpeed = row("Ranged Speed")
wandDmg = row("Ranged Damage")

-- A later render with the APIs gone must not keep the wand numbers.
UnitAttackPower = function() return 100, 10, 0 end
GetCritChance = function() return 4.5 end
UnitArmor = function() return 40, 55 end
render()
UnitAttackPower = nil
GetCritChance = nil
UnitArmor = nil
UnitRangedAttackPower = nil
UnitRangedDamage = nil
render()
staleAp = row("Attack Power")
staleCrit = row("Critical Strike")
staleArmor = row("Armor")
staleRap = row("Ranged Attack Power")
staleDps = row("Ranged DPS")

-- Another client still reads UnitDefense and still shows ranged power.
ToonAge.IsForever = false
ToonAge.flavor = "tbc"
UnitDefense = function()
    called.UnitDefense = called.UnitDefense + 1
    return 350, 5
end
UnitDefenseSkill = nil
C_SkillInfo = nil
local before = called.UnitDefense
local total, base, mod = ToonAge.modules.TBCStats:GetDefenseSkill()
tbcTotal, tbcBase, tbcMod = total, base, mod
tbcCalled = called.UnitDefense - before
ToonAge.IsForever = true
ToonAge.flavor = "forever"
""")

g = lua.globals()
check("level 9 defense from UnitDefenseSkill is 42/45", g.fromSkill.value, "42 / 45")
check("level 1 defense is 1/5", g.atOne.value, "1 / 5")
check("a modifier is kept on the defense row", g.withMod.value, "40 (+2) / 45")
check("an out-of-range UnitDefenseSkill is unavailable",
      "n/a" in g.hiddenWild.value and "300" not in g.hiddenWild.value, True)
check("defense falls back to skill line 95", g.fromID.value, "1 / 5")
check("defense falls back to a line named Defense", g.fromName.value, "42 / 45")
check("a skill-line cap far from 5 per level is unavailable",
      "n/a" in g.hiddenCap.value and "300" not in g.hiddenCap.value and "900" not in g.hiddenCap.value, True)
check("Forever never called UnitDefense, UnitAttackBothHands or UnitRangedAttack", g.traps, 0)
check("melee attack is main base plus main mod", g.melee.value, 12)
check("ranged attack power stays on the sheet", g.rapRow.text, "80")
check("missing ranged damage is n/a, not 0.0",
      "0.0" not in g.dmgRow.value and "n/a" in g.dmgRow.value, True)
check("the ranged damage row is present when damage was not read", g.dmgRow.label, "Ranged Damage")
check("a missing melee attack read stays on the sheet as n/a", g.noMelee.text, "|cFF6E6A62n/a|r")
check("ranged attack power stays when melee is absent", g.rapStill.text, "80")
check("ranged damage stays when melee is absent", "n/a" in g.dmgStill.value, True)
check("ranged speed stays unavailable when damage was not read", "n/a" in g.speedStill.value, True)
check("ranged dps stays unavailable when damage was not read", g.dpsStill.value, "|cFF6E6A62n/a|r")
check("ranged attack power adds the buffs", g.rapFull.text, "76")
check("ranged damage shows min and max", g.dmgFull.value, "45-62")
check("ranged speed shows the swing", g.speedFull.value, "2.80")
check("ranged dps is the average over the speed", g.dpsFull.value, "19.1")
check("a nil damage bound stays n/a and the row remains",
      g.dmgPartial.value, "|cFF6E6A62n/a|r-62")
check("a nil damage bound does not blank the speed", g.speedPartial.value, "2.80")
check("dps is unavailable when a damage bound is missing", g.dpsPartial.value, "|cFF6E6A62n/a|r")
check("attack power is unchanged when only damage is partial", g.rapPartial.text, "76")
check("a zero swing speed is not shown as 0.0",
      "0.0" not in g.speedZero.value and "n/a" in g.speedZero.value, True)
check("positive damage stays when the speed is zero", g.dmgZeroSpeed.value, "10-12")
check("dps is unavailable when the speed is zero", g.dpsZero.value, "|cFF6E6A62n/a|r")
check("a failed ranged power read keeps the row as n/a", g.rapDown.text, "|cFF6E6A62n/a|r")
check("a missing ranged damage read keeps the row", "n/a" in g.dmgDown.value, True)
check("a missing ranged speed read is n/a", "n/a" in g.speedDown.value and "0.0" not in g.speedDown.value, True)
check("a missing ranged dps read is n/a", g.dpsDown.value, "|cFF6E6A62n/a|r")
check("UnitRangedAttack stays unused", g.rangedAttackCalls, 0)
check("no ranged weapon does not print 0.0 damage",
      "0.0" not in g.bareDmg.value and "n/a" in g.bareDmg.value, True)
check("no ranged weapon does not print 0.0 speed",
      "0.0" not in g.bareSpeed.value and "n/a" in g.bareSpeed.value, True)
check("no ranged weapon does not print 0.0 dps", g.bareDps.value, "|cFF6E6A62n/a|r")
check("a wand-shaped read shows 19.7 dps", g.wandDps.value, "19.7")
check("a wand-shaped speed is not 0.0", g.wandSpeed.value, "1.00")
check("a wand-shaped damage span is not 0", g.wandDmg.value, "19-20")
check("a dropped attack power read does not keep 100", g.staleAp.text, "|cFF6E6A62n/a|r")
check("a dropped crit read does not keep 4.50", g.staleCrit.text, "|cFF6E6A62n/a|r")
check("a dropped armor read does not keep 55", g.staleArmor.text, "|cFF6E6A62n/a|r")
check("a dropped ranged attack power read does not keep 12", g.staleRap.text, "|cFF6E6A62n/a|r")
check("a dropped ranged dps read does not keep 19.7", g.staleDps.value, "|cFF6E6A62n/a|r")
check("TBC still reads UnitDefense", g.tbcCalled, 1)
check("TBC defense total keeps the modifier", g.tbcTotal, 355)
check("TBC defense base is the UnitDefense base", g.tbcBase, 350)
check("TBC defense modifier is the UnitDefense modifier", g.tbcMod, 5)

# /ta probe prints every raw return, including a nil in the middle.
load(lua, "Core/Caps.lua")
load(lua, "Modules/Infrastructure/Harvester.lua")
load(lua, "Modules/Harvest/Packs/Forever.lua")
lua.execute(r"""
UnitDefenseSkill = function() return 7, nil, "tail" end
UnitWeaponAttackPower = function() return 3, 1, nil, 9 end
UnitRangedAttackPower = function() return 72, nil, 4 end
UnitRangedDamage = function() return 2.5, nil, 40, nil end
C_SkillInfo = {
    GetNumSkillLines = function() return 0 end,
    GetSkillLineInfoByID = function(id)
        if id == 95 then return { rank = 1, maxRank = 5, name = "Defense" } end
    end,
    GetSelectedSkill = function() return nil end,
}
probeLines = {}
ToonAge.Harvester:Pack().probes.skillinfo.run(ToonAge.Harvester.Probe, probeLines)
probeText = table.concat(probeLines, "\n")
""")
text = lua.eval("probeText")
check("probe names the three unverified reads",
      "UNVERIFIED raw returns" in text, True)
check("probe prints every UnitDefenseSkill return",
      'UNVERIFIED UnitDefenseSkill(player)  ->  7, nil, "tail"' in text, True)
check("probe prints every UnitWeaponAttackPower return",
      "UNVERIFIED UnitWeaponAttackPower(player)  ->  3, 1, nil, 9" in text, True)
check("probe prints skill line 95",
      "maxRank=5" in text and "rank=1" in text and "GetSkillLineInfoByID(95)" in text, True)
check("probe prints every UnitRangedAttackPower return",
      "UNVERIFIED UnitRangedAttackPower(player)  ->  72, nil, 4" in text, True)
check("probe prints every UnitRangedDamage return",
      "UNVERIFIED UnitRangedDamage(player)  ->  2.5, nil, 40, nil" in text, True)

passed = sum(_results)
total = len(_results)
print(f"\n{passed}/{total} passed")
sys.exit(0 if passed == total else 1)
