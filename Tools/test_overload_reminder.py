#!/usr/bin/env python3
"""
ToonAge -- retail gathering Overload reminder
==============================================
The button appears only for the soft target or the mouseover, and only when
that object's name or GUID matches the data file and the Overload spell is
known and ready. Cooldown numbers are refused when issecretvalue says so.

Usage:  python3 Tools/test_overload_reminder.py [-v]
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


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("ToonAge = { modules = {} }")
    lua.execute(r"""
        function ToonAge:RegisterModule(name, module)
            self.modules[name] = module
        end
        function ToonAge:GetModule(name)
            return self.modules[name]
        end
    """)
    lua.execute(read("Data/Retail/professions_retail.lua"))
    lua.execute(read("Modules/Character/ProfessionOverload.lua"))
    return lua


FIXTURE = r"""
DATA = {
    unverified = true,
    spells = {
        { profession = 182, name = "Herbalism", spellID = 9001 },
        { profession = 186, name = "Mining", spellID = 9002 },
    },
    nodes = {
        { name = "Lush Rose", objectID = 45678, profession = 182 },
        { name = "Rich Ore", profession = 186 },
    },
}
function known(id) return id == 9001 or id == 9002 end
function ready(id)
    if id == 9002 then return "cooldown" end
    return "ready"
end
SOFT = { name = "Lush Rose", guid = "GameObject-0-1-2-3-45678-9" }
MOUSE = { name = "Rich Ore", guid = "GameObject-0-1-2-3-99-1" }
"""


def test_sources_and_shipped_list():
    src = read("Modules/Character/ProfessionOverload.lua")
    for banned in ("C_NamePlate", "ObjectPosition", "GetPlayerMapPosition",
                   "C_Map.GetPlayerMapPosition"):
        check(f"no distance scan via {banned}", banned in src, False)
    check("cooldown is read from C_Spell.GetSpellCooldown",
          "C_Spell.GetSpellCooldown" in src, True)
    check("cooldown values go through issecretvalue", "issecretvalue" in src, True)
    check("placeholder icon is named", "PLACEHOLDER_ICON" in src, True)
    check("no spell id baked into the module",
          any(ch.isdigit() and len(ch) >= 5 for ch in __import__("re").findall(r"\d+", src)), False)
    camelot = read("ToonAge_Camelot.toc")
    check("forever toc skips the reminder", "ProfessionOverload.lua" in camelot, False)
    for toc in ("ToonAge.toc", "ToonAge_Mainline.toc"):
        check(f"{toc} lists the reminder",
              "Modules\\Character\\ProfessionOverload.lua" in read(toc), True)
    settings = read("Modules/Infrastructure/Settings.lua")
    check("settings can turn the reminder off",
          "Gathering Overload reminder" in settings, True)
    check("settings row only exists with the module",
          'Has("ProfessionOverload")' in settings, True)
    health = read("Core/Init.lua")
    check("diagnostics calls the overload status line",
          "ProfessionOverload:StatusLine" in health, True)

    lua = runtime()
    check("midnight node list is unverified",
          lua.eval("ToonAge.Data.Overloads.unverified"), True)
    check("shipped node list is empty",
          lua.eval("#ToonAge.Data.Overloads.nodes"), 0)
    check("herbalism spell id is not invented",
          lua.eval("ToonAge.Data.Overloads.spells[1].spellID"), None)
    check("mining spell id is not invented",
          lua.eval("ToonAge.Data.Overloads.spells[2].spellID"), None)


def test_match_and_readiness():
    lua = runtime()
    lua.execute(FIXTURE)
    lua.execute(r"""
        OID = ToonAge.ProfessionOverload.ObjectID(SOFT.guid)
        CREATURE = ToonAge.ProfessionOverload.ObjectID("Creature-0-1-2-3-45678-9")
        BY_ID = ToonAge.ProfessionOverload.Match(DATA, "Localized Name", SOFT.guid)
        BY_NAME = ToonAge.ProfessionOverload.Match(DATA, "rich ore", "GameObject-0-1-2-3-1-1")
        MISS = ToonAge.ProfessionOverload.Match(DATA, "Stone", "GameObject-0-1-2-3-5-1")
        SPELL = ToonAge.ProfessionOverload.SpellFor(DATA, BY_ID)
        node, sight, via = ToonAge.ProfessionOverload.BestMatch(DATA, SOFT, MOUSE)
        VIA = via
        SOFT_NAME = node.name
        node2 = ToonAge.ProfessionOverload.BestMatch(DATA, { name = "Wolf", guid = "Creature-0-1-2-3-8-1" }, MOUSE)
        MOUSE_NAME = node2 and node2.name
    """)
    check("object id is the sixth GUID field", lua.eval("OID"), 45678)
    check("creatures are not nodes", lua.eval("CREATURE"), None)
    check("object id matches a renamed node", lua.eval("BY_ID.name"), "Lush Rose")
    check("name match ignores case", lua.eval("BY_NAME.name"), "Rich Ore")
    check("unknown node does not match", lua.eval("MISS"), None)
    check("spell id comes from the profession row", lua.eval("SPELL"), 9001)
    check("soft target wins over the mouseover", lua.eval("VIA"), "soft")
    check("soft target node", lua.eval("SOFT_NAME"), "Lush Rose")
    check("mouseover is used when the soft target is not a node",
          lua.eval("MOUSE_NAME"), "Rich Ore")

    lua.execute(r"""
        SECRET = {}
        function issecretvalue(v) return v == SECRET or type(v) == "table" and v == SECRET end
        READY = ToonAge.ProfessionOverload.CooldownState({ startTime = 0, duration = 0, isEnabled = true }, 100)
        WAIT = ToonAge.ProfessionOverload.CooldownState({ startTime = 10, duration = 5, isEnabled = true }, 12)
        BACK = ToonAge.ProfessionOverload.CooldownState({ startTime = 10, duration = 5, isEnabled = true }, 16)
        HIDDEN = ToonAge.ProfessionOverload.CooldownState({ startTime = 0, duration = SECRET, isEnabled = true }, 100)
        OFF = ToonAge.ProfessionOverload.CooldownState({ startTime = 0, duration = 0, isEnabled = false }, 100)
    """)
    check("zero duration is ready", lua.eval("READY"), "ready")
    check("remaining time is cooldown", lua.eval("WAIT"), "cooldown")
    check("elapsed cooldown is ready", lua.eval("BACK"), "ready")
    check("a secret duration is not compared", lua.eval("HIDDEN"), "secret")
    check("a disabled spell is not ready", lua.eval("OFF"), "cooldown")


def test_show_hide_and_diagnostics():
    lua = runtime()
    lua.execute(FIXTURE)
    lua.execute(r"""
        local OL = ToonAge.ProfessionOverload
        local function plan(opts)
            return OL.Consider(DATA, SOFT, nil, known, ready, opts)
        end
        SHOW = plan({ enabled = true, combat = false })
        COMBAT = plan({ enabled = true, combat = true })
        OFF = plan({ enabled = false, combat = false })
        HELD = plan({ enabled = true, combat = false, pending = true, pendingGuid = SOFT.guid })
        CLEARED = OL.Consider(DATA, nil, nil, known, ready, { enabled = true })
        MINING = OL.Consider(DATA, nil, MOUSE, known, ready, { enabled = true })
    """)
    check("ready known node shows", lua.eval("SHOW.show"), True)
    check("combat hides the button", lua.eval("COMBAT.show"), False)
    check("the option hides the button", lua.eval("OFF.show"), False)
    check("the same node stays hidden just after the cast", lua.eval("HELD.show"), False)
    check("cast hold stays until the cooldown or the target changes",
          lua.eval("HELD.clearPending"), False)
    check("no target does not show", lua.eval("CLEARED.show"), False)
    check("a spell on cooldown does not show", lua.eval("MINING.show"), False)
    check("cooldown state is reported for that spell", lua.eval("MINING.cooldown"), "cooldown")

    lua.execute(r"""
        local OL = ToonAge.ProfessionOverload
        OL._lastNode = "none"
        OL._lastCooldown = "unknown"
        local result = OL.Consider(DATA, SOFT, nil, known, ready, { enabled = true })
        if result.node then
            OL._lastNode = result.label
            OL._lastCooldown = result.cooldown
        end
        LINE = OL:StatusLine()
        ToonAge.db = { overloadReminder = false }
        OFFLINE = OL:StatusLine()
        local r, g, b, live = OL.GlowColor(0)
        GLOW = { r, g, b, live }
        local r2, g2, b2, live2 = OL.GlowColor(OL.GLOW_SECONDS)
        REST = { r2, g2, b2, live2 }
    """)
    check("diagnostics name the node and the cooldown",
          lua.eval("LINE"), "Overload: last node Lush Rose, cooldown ready (unverified)")
    check("diagnostics still report when the reminder is off",
          lua.eval("OFFLINE"), "Overload off: last node Lush Rose, cooldown ready (unverified)")
    check("the flash starts in the finisher gold",
          (lua.eval("GLOW[1]"), lua.eval("GLOW[2]"), lua.eval("GLOW[3]"), lua.eval("GLOW[4]")),
          (0.910, 0.702, 0.353, True))
    check("the flash ends after one interval", lua.eval("REST[4]"), False)


def test_button_locks_in_combat():
    lua = runtime()
    lua.execute(r"""
        local function Mock(name)
            local f = { _name = name, _shown = false }
            function f:SetSize() end
            function f:SetFrameStrata() end
            function f:RegisterForClicks() end
            function f:Hide() self._shown = false end
            function f:Show() self._shown = true end
            function f:IsShown() return self._shown end
            function f:SetBackdrop() end
            function f:SetBackdropColor() end
            function f:SetBackdropBorderColor(r, g, b) self._rgb = { r, g, b } end
            function f:SetPoint() end
            function f:ClearAllPoints() end
            function f:SetScript(which, fn) self[which] = fn end
            function f:CreateTexture()
                return { SetPoint = function() end, SetTexCoord = function() end,
                         SetTexture = function(_, path) f._icon = path end }
            end
            function f:SetAttribute(k, v) self._attrs = self._attrs or {}; self._attrs[k] = v; self._set = true end
            return f
        end
        UIParent = Mock("parent")
        CreateFrame = function() return Mock("button") end
        GameTooltip = Mock("tip")
        InCombatLockdown = function() return true end
        local OL = ToonAge.ProfessionOverload
        OL:Apply({ show = true, spellID = 9001 })
        SET = OL._button and OL._button._set
        SHOWN = OL._button and OL._button._shown
        InCombatLockdown = function() return false end
        OL._shown = false
        OL:Apply({ show = true, spellID = 9001 })
        ATTR = OL._button._attrs.spell
        KIND = OL._button._attrs.type
        ICON = OL._button._icon
        GOLD = OL._button._rgb[1]
    """)
    check("combat does not arm the spell", lua.eval("SET"), None)
    check("combat keeps the button hidden", lua.eval("SHOWN"), False)
    check("out of combat the button casts the data-file spell", lua.eval("ATTR"), 9001)
    check("the secure button type is spell", lua.eval("KIND"), "spell")
    check("the icon is the placeholder", lua.eval("ICON"),
          "Interface\\Icons\\INV_Misc_QuestionMark")
    check("showing the button starts the gold border", lua.eval("GOLD"), 0.910)


def main():
    test_sources_and_shipped_list()
    test_match_and_readiness()
    test_show_hide_and_diagnostics()
    test_button_locks_in_combat()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
