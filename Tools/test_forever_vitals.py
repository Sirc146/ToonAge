#!/usr/bin/env python3
"""Forever character health and mana.

Blizzard can show 192 health and 330 mana out of combat while this tab
draws a dash. A value that supports arithmetic is a plain number, even
if issecretvalue says otherwise. A value that cannot be added is withheld.
The combat footnote is only for a withheld value while actually in combat.
A class with no mana pool does not get a 0 / 0 bar.

Usage:  python3 Tools/test_forever_vitals.py [-v]
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
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule() return nil end

UnitName = function() return "Vespera" end
UnitClass = function() return "Mage", "MAGE" end
UnitRace = function() return "Undead", "Scourge" end
UnitLevel = function() return 7 end
inCombat = false
function InCombatLockdown() return inCombat end

-- The flag can be wrong. Arithmetic is the test that the number is usable.
issecretvalue = function() return true end
UnitHealth = function() return 192 end
UnitHealthMax = function() return 192 end
UnitPower = function(_, powerType) if powerType == 0 then return 330 end end
UnitPowerMax = function(_, powerType) if powerType == 0 then return 330 end end

rows = {}
notes = {}
local L = { C_DIM = { 0.5, 0.5, 0.5 }, PAD = 8 }
function L:Width() return 420 end
function L:StatScale() return 100 end
setmetatable(L, { __index = function()
    return function(_, _, y, opts, extra)
        if type(opts) == "table" and opts.label then
            rows[#rows + 1] = opts
        elseif type(opts) == "string" then
            notes[#notes + 1] = opts
        end
        if type(y) ~= "number" then y = 0 end
        return y - 1
    end
end })
ToonAge.Layout = L

content = {}
function render()
    rows = {}
    notes = {}
    ToonAge.modules.ForeverCharacter:Render(content, nil)
end
function row(label)
    for i = 1, #rows do
        if rows[i].label == label then return rows[i] end
    end
end
function noteText()
    return table.concat(notes, "\n")
end
""")
load(lua, "Modules/Forever/Character.lua")
lua.execute(r"""
render()
health = row("Health")
mana = row("Mana")
flagNote = noteText()

-- A real secret: addition throws. In combat the dash and the combat note are right.
local function Secret(n)
    return setmetatable({}, { __add = function() error("secret arithmetic") end })
end
inCombat = true
UnitHealth = function() return Secret(1) end
UnitHealthMax = function() return Secret(1) end
UnitPower = function() return Secret(1) end
UnitPowerMax = function() return Secret(1) end
render()
secretHealth = row("Health")
secretNote = noteText()

-- Out of combat, a withheld number must not claim the player is in combat.
inCombat = false
render()
oocSecretNote = noteText()

-- Warrior: the client answers a mana pool of 0. No mana bar and no footnote
-- when health itself is a plain number.
issecretvalue = function() return false end
inCombat = false
UnitHealth = function() return 100 end
UnitHealthMax = function() return 100 end
UnitPower = function() return 0 end
UnitPowerMax = function() return 0 end
render()
rageMana = row("Mana")
rageNote = noteText()

-- The calls are absent. No dash that pretends the numbers were secret.
UnitHealth = nil
UnitHealthMax = nil
UnitPower = nil
UnitPowerMax = nil
render()
absentHealth = row("Health")
absentNote = noteText()
""")

g = lua.globals()
check("out-of-combat health is the plain number", g.health.value, "192 / 192")
check("out-of-combat mana is the plain number", g.mana.value, "330 / 330")
check("a usable number does not get the combat footnote",
      "secret in combat" not in g.flagNote, True)
check("a real secret in combat is a dash", g.secretHealth.value, "—")
check("combat footnote only while in combat", "secret in combat" in g.secretNote, True)
check("withheld out of combat does not claim combat",
      "secret in combat" not in g.oocSecretNote, True)
check("a zero mana pool draws no mana row", g.rageMana, None)
check("a zero mana pool does not claim secret combat",
      "secret in combat" not in g.rageNote, True)
check("missing health calls draw no health row", g.absentHealth, None)
check("missing calls do not claim secret combat",
      "secret in combat" not in g.absentNote, True)

passed = sum(_results)
total = len(_results)
print(f"\n{passed}/{total} passed")
sys.exit(0 if passed == total else 1)
