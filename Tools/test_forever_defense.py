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
hiddenWild = has("Defense Skill")

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
hiddenCap = has("Defense Skill")

-- No melee function: no melee row. The ranged rows stay.
UnitWeaponAttackPower = nil
UnitDefenseSkill = function() return 42, 0 end
C_SkillInfo = nil
render()
noMelee = has("Melee Attack")
rapStill = row("Ranged Attack Power")
dmgStill = row("Ranged Damage")

-- A full ranged read. Power is base + pos + neg. Damage is speed, min, max.
UnitRangedAttackPower = function() return 72, 5, -1 end
UnitRangedDamage = function() return 2.8, 45, 62, 0, 0, 1 end
render()
rapFull = row("Ranged Attack Power")
dmgFull = row("Ranged Damage")

-- One damage return is nil. That piece is n/a. The row and the other
-- numbers stay. Nothing is formatted as 0.0.
UnitRangedDamage = function() return 2.8, nil, 62 end
render()
dmgPartial = row("Ranged Damage")
rapPartial = row("Ranged Attack Power")

-- A zero swing speed is not a real reading.
UnitRangedDamage = function() return 0, 10, 12 end
render()
dmgZeroSpeed = row("Ranged Damage")

-- Both functions missing or throwing. Both rows stay, both values are
-- unavailable, and UnitRangedAttack is still not called.
UnitRangedAttackPower = function() error("absent") end
UnitRangedDamage = nil
local beforeRanged = called.UnitRangedAttack
render()
rapDown = row("Ranged Attack Power")
dmgDown = row("Ranged Damage")
rangedAttackCalls = called.UnitRangedAttack - beforeRanged

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
check("an out-of-range UnitDefenseSkill hides the row", g.hiddenWild, False)
check("defense falls back to skill line 95", g.fromID.value, "1 / 5")
check("defense falls back to a line named Defense", g.fromName.value, "42 / 45")
check("a skill-line cap far from 5 per level hides the row", g.hiddenCap, False)
check("Forever never called UnitDefense, UnitAttackBothHands or UnitRangedAttack", g.traps, 0)
check("melee attack is main base plus main mod", g.melee.value, 12)
check("ranged attack power stays on the sheet", g.rapRow.text, "80")
check("missing ranged damage is n/a, not 0.0",
      "0.0" not in g.dmgRow.value and "n/a" in g.dmgRow.value, True)
check("the ranged damage row is present when damage was not read", g.dmgRow.label, "Ranged Damage")
check("no UnitWeaponAttackPower means no melee row", g.noMelee, False)
check("ranged attack power stays when melee is absent", g.rapStill.text, "80")
check("ranged damage stays when melee is absent", "n/a" in g.dmgStill.value, True)
check("ranged attack power adds the buffs", g.rapFull.text, "76")
check("ranged damage shows speed, min and max", g.dmgFull.value, "2.80  45-62")
check("a nil damage bound stays n/a and the row remains",
      g.dmgPartial.value, "2.80  |cFF6E6A62n/a|r-62")
check("attack power is unchanged when only damage is partial", g.rapPartial.text, "76")
check("a zero swing speed is not shown as 0.0",
      "0.0" not in g.dmgZeroSpeed.value and g.dmgZeroSpeed.value.endswith("10-12"), True)
check("a failed ranged power read keeps the row as n/a", g.rapDown.text, "|cFF6E6A62n/a|r")
check("a missing ranged damage read keeps the row", "n/a" in g.dmgDown.value, True)
check("UnitRangedAttack stays unused", g.rangedAttackCalls, 0)
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
