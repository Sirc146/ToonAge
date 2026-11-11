#!/usr/bin/env python3
"""Forever character health and mana secrecy.

The 2026-09-23 probe measured UnitHealth mid-combat: issecretvalue was
true and arithmetic raised. Nothing in that probe, and nothing about
Blizzard's own frames drawing a number, shows that an out-of-combat
192/330 is readable by the addon. This test does not claim that.

A value is shown only after canaccessvalue (when present) and
issecretvalue both allow it, and the result of arithmetic is checked
again. A true secrecy flag on an ordinary number stays a dash.
tostring is not a bypass. The combat sentence is only used while
InCombatLockdown is true.

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

adds = 0
function Plain(n)
    return n
end
function Trap(n)
    return setmetatable({}, {
        __add = function()
            adds = adds + 1
            error("arithmetic on a withheld value")
        end,
    })
end

issecretvalue = function() return false end
canaccessvalue = nil
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
-- Accessible: predicates say the numbers may be used. This is not a
-- claim about the live 192/330 screenshot.
issecretvalue = function() return false end
canaccessvalue = nil
inCombat = false
adds = 0
UnitHealth = function() return 192 end
UnitHealthMax = function() return 192 end
UnitPower = function() return 330 end
UnitPowerMax = function() return 330 end
render()
openHealth = row("Health")
openMana = row("Mana")
openNote = noteText()

-- The same numbers with issecretvalue true. Arithmetic would succeed.
-- The flag is still a refusal. Do not display them.
issecretvalue = function() return true end
canaccessvalue = nil
render()
flagHealth = row("Health")
flagMana = row("Mana")
flagNote = noteText()

-- Restricted: canaccessvalue false. Addition must not run.
issecretvalue = function() return true end
canaccessvalue = function() return false end
adds = 0
UnitHealth = function() return Trap(192) end
UnitHealthMax = function() return Trap(192) end
UnitPower = function() return Trap(330) end
UnitPowerMax = function() return Trap(330) end
render()
restrictedHealth = row("Health")
restrictedAdds = adds
restrictedNote = noteText()

-- Predicate error is not permission, and it must not fall through to arithmetic.
canaccessvalue = function() error("canaccessvalue failed") end
adds = 0
render()
accessErrorHealth = row("Health")
accessErrorAdds = adds

canaccessvalue = nil
issecretvalue = function() error("issecretvalue failed") end
adds = 0
render()
secretErrorHealth = row("Health")
secretErrorAdds = adds
secretErrorNote = noteText()

-- Permission to touch the value, but the result is still secret.
local still = 192
canaccessvalue = function(v) return true end
issecretvalue = function(v) return v == still or v == 330 or type(v) == "table" end
UnitHealth = function()
    return setmetatable({}, { __add = function() return still end })
end
UnitHealthMax = function()
    return setmetatable({}, { __add = function() return still end })
end
UnitPower = function()
    return setmetatable({}, { __add = function() return 330 end })
end
UnitPowerMax = function()
    return setmetatable({}, { __add = function() return 330 end })
end
render()
remainsHealth = row("Health")
remainsMana = row("Mana")

-- In combat, the withheld row uses the combat sentence.
inCombat = true
issecretvalue = function() return true end
canaccessvalue = function() return false end
UnitHealth = function() return 192 end
UnitHealthMax = function() return 192 end
UnitPower = function() return 330 end
UnitPowerMax = function() return 330 end
render()
combatHealth = row("Health")
combatNote = noteText()

-- Out of combat, the same refusal must not say the player is in combat.
inCombat = false
render()
oocHealth = row("Health")
oocNote = noteText()

-- Accessible again, including an explicit canaccessvalue true.
issecretvalue = function() return false end
canaccessvalue = function() return true end
inCombat = false
UnitHealth = function() return 192 end
UnitHealthMax = function() return 192 end
UnitPower = function() return 330 end
UnitPowerMax = function() return 330 end
render()
allowedHealth = row("Health")
allowedMana = row("Mana")
allowedNote = noteText()

-- Zero mana is an empty pool, not a secret.
issecretvalue = function() return false end
canaccessvalue = nil
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
check("an accessible health value is shown", g.openHealth.value, "192 / 192")
check("an accessible mana value is shown", g.openMana.value, "330 / 330")
check("an accessible value has no withheld note",
      "withheld by the client" not in g.openNote and "secret in combat" not in g.openNote, True)
check("issecretvalue true on 192 stays a dash", g.flagHealth.value, "—")
check("issecretvalue true on 330 stays a dash", g.flagMana.value, "—")
check("a true secrecy flag out of combat does not say in combat",
      "in combat" not in g.flagNote, True)
check("a true secrecy flag out of combat says the client withheld it",
      "withheld by the client" in g.flagNote, True)
check("canaccessvalue false stays a dash", g.restrictedHealth.value, "—")
check("canaccessvalue false does not attempt arithmetic", g.restrictedAdds, 0)
check("a throwing canaccessvalue stays a dash", g.accessErrorHealth.value, "—")
check("a throwing canaccessvalue does not attempt arithmetic", g.accessErrorAdds, 0)
check("a throwing issecretvalue stays a dash", g.secretErrorHealth.value, "—")
check("a throwing issecretvalue does not attempt arithmetic", g.secretErrorAdds, 0)
check("a throwing predicate out of combat does not say in combat",
      "in combat" not in g.secretErrorNote, True)
check("a result that stays secret is not shown as health", g.remainsHealth.value, "—")
check("a result that stays secret is not shown as mana", g.remainsMana.value, "—")
check("in combat a withheld value is a dash", g.combatHealth.value, "—")
check("in combat the note says secret in combat", "secret in combat" in g.combatNote, True)
check("out of combat a withheld value is a dash", g.oocHealth.value, "—")
check("out of combat the note does not say in combat", "in combat" not in g.oocNote, True)
check("out of combat the note says the client withheld it",
      "withheld by the client" in g.oocNote, True)
check("canaccessvalue true and not secret shows health", g.allowedHealth.value, "192 / 192")
check("canaccessvalue true and not secret shows mana", g.allowedMana.value, "330 / 330")
check("an allowed value has no withheld note",
      "withheld by the client" not in g.allowedNote and "secret in combat" not in g.allowedNote, True)
check("a zero mana pool draws no mana row", g.rageMana, None)
check("a zero mana pool does not claim secret combat",
      "in combat" not in g.rageNote, True)
check("missing health calls draw no health row", g.absentHealth, None)
check("missing calls do not claim secret combat",
      "in combat" not in g.absentNote, True)

passed = sum(_results)
total = len(_results)
print(f"\n{passed}/{total} passed")
sys.exit(0 if passed == total else 1)
