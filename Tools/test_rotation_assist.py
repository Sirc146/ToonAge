#!/usr/bin/env python3
"""Unverified specs show one Assisted Combat spell, not a priority list.

C_AssistedCombat.GetNextCastSpell is called with no arguments on any client
where the function exists. A secret or a failed call is not a suggestion.
Slots 2 and 3 stay empty until VERIFIED_SPEC has the spec. The /ta probe
line reports present, called, nil, secret, or error, and does not throw.
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, Data = { Rotations = {}, Spells = {} }, Utils = {} }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
        ToonAge.Utils.IsSecret = function(v) return v == "secret" end
        ToonAge.Utils.GetSpellName = function(id) return "Spell " .. tostring(id) end
        ToonAge.IsRetail = false
        ToonAge.IsForever = false
    """)
    lua.execute((ROOT / "Modules/Combat/Rotation.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
        local R = ToonAge.modules.Rotation
        ARGS = -1
        C_AssistedCombat = {
            GetNextCastSpell = function(...)
                ARGS = select("#", ...)
                return 361469
            end,
        }
        local row = R:AssistedNext()
        GOT_ID = row and row.entry.spellID
        GOT_NAME = row and row.entry.name
        local slots = R:FallbackSlots(1468)
        N = slots and #slots or -1
        SLOT1 = slots and slots[1] and slots[1].spellID
        VERIFIED = R:FallbackSlots(259)
        C_AssistedCombat.GetNextCastSpell = function() return "secret" end
        SECRET = R:AssistedNext()
        C_AssistedCombat.GetNextCastSpell = function() error("nope") end
        local ok = pcall(function() ERR = R:AssistedNext() end)
        ERR_OK = ok
        C_AssistedCombat.GetNextCastSpell = function() return nil end
        NIL = R:AssistedNext()
        EMPTY = R:FallbackSlots(1468)
        EMPTY_N = EMPTY and #EMPTY or -1
        C_AssistedCombat = nil
        MISSING = R:AssistedNext()
    """)
    check("assist is called with no arguments", lua.eval("ARGS"), 0)
    check("an unverified client still gets the spell", lua.eval("GOT_ID"), 361469)
    check("the spell name is filled", lua.eval("GOT_NAME"), "Spell 361469")
    check("an unverified spec has one slot", lua.eval("N"), 1)
    check("slot 1 is the assisted spell", lua.eval("SLOT1"), 361469)
    check("a verified spec keeps its list", lua.eval("VERIFIED"), None)
    check("a secret id is not a suggestion", lua.eval("SECRET"), None)
    check("a throwing assist call does not escape", lua.eval("ERR_OK"), True)
    check("a throwing assist call is no suggestion", lua.eval("ERR"), None)
    check("a nil assist call is no suggestion", lua.eval("NIL"), None)
    check("no assist spell is an empty fallback", lua.eval("EMPTY_N"), 0)
    check("a missing function is no suggestion", lua.eval("MISSING"), None)

    lua.execute(r"""
        function ToonAge:GetModule(name) return self.modules[name] end
        local R = ToonAge.modules.Rotation
        local sizeCalls, widthCalls = 0, 0
        local bar = { w = 200, h = 99, shown = true, alpha = 1 }
        function bar:SetSize(w, h) sizeCalls = sizeCalls + 1; self.w, self.h = w, h end
        function bar:SetWidth() widthCalls = widthCalls + 1 end
        function bar:SetAlpha(a) self.alpha = a end
        function bar:Show() self.shown = true end
        function bar:Hide() self.shown = false end
        function bar:IsShown() return self.shown end
        R.predictBar = bar
        R.predictIcons = {}
        ToonAge.Utils.GetPlayerSpec = function() return 1468 end
        ToonAge.Utils.GetPlayerLevel = function() return 80 end
        UnitGroupRolesAssigned = function() return "DAMAGER" end
        InCombatLockdown = function() return true end
        R.currentSpecID = 1468
        R:FitPredictBar(1, false)
        R:ApplyCombatWidth()
        R:OnBarEvent("PLAYER_REGEN_ENABLED")
        R:OnEvent("PLAYER_SPECIALIZATION_CHANGED")
        LOCKED_SIZE, LOCKED_WIDTH = sizeCalls, widthCalls
        InCombatLockdown = function() return false end
        R.currentSpecID = 1468
        R:ApplyCombatWidth()
        R:OnBarEvent("PLAYER_REGEN_ENABLED")
        R:OnEvent("PLAYER_SPECIALIZATION_CHANGED")
        UNVERIFIED_W = bar.w
        -- Verified, but every spell is above this level, so combat has one slot.
        R.currentSpecID = 259
        R.currentLevel = 10
        R.currentView = "solo"
        ToonAge.Data.Rotations = { Get = function(_, specID)
            if specID == 260 then
                return { priorities = { { spellID = 1 }, { spellID = 2 } } }
            end
            return { priorities = {
                { spellID = 1, unlockLv = 60 },
                { spellID = 2, unlockLv = 60 },
                { spellID = 3, unlockLv = 60 },
            } }
        end }
        R:ApplyCombatWidth()
        EMPTY_W = bar.w
        ToonAge.Utils.GetPlayerLevel = function() return 10 end
        ToonAge.Utils.GetPlayerSpec = function() return 259 end
        R:OnEvent("PLAYER_LEVEL_UP")
        LEVEL_STILL = bar.w
        ToonAge.Utils.GetPlayerLevel = function() return 70 end
        R:OnEvent("PLAYER_LEVEL_UP")
        LEVEL_UP_W = bar.w
        ToonAge.Utils.GetPlayerSpec = function() return 260 end
        R:OnEvent("PLAYER_SPECIALIZATION_CHANGED")
        SPEC_W = bar.w
        R.currentSpecID = 259
        R.currentLevel = 70
        R:OnBarEvent("PLAYER_REGEN_ENABLED")
        REGEN_W = bar.w
    """)
    check("combat lockdown never resizes the bar", lua.eval("LOCKED_SIZE"), 0)
    check("combat lockdown never calls SetWidth", lua.eval("LOCKED_WIDTH"), 0)
    check("an unverified spec is 88 out of combat", lua.eval("UNVERIFIED_W"), 88)
    check("a verified spec with nothing usable yet is 88", lua.eval("EMPTY_W"), 88)
    check("level up below the gates stays 88", lua.eval("LEVEL_STILL"), 88)
    check("level up into the list widens to three slots", lua.eval("LEVEL_UP_W"), 200)
    check("spec change recomputes the tray", lua.eval("SPEC_W"), 144)
    check("leaving combat recomputes the tray", lua.eval("REGEN_W"), 200)

    lua.execute(r"""
        local function widget()
            local f = { sized = 0, widthCalls = 0, sizes = {} }
            local function noop() end
            setmetatable(f, { __index = function() return noop end })
            function f:SetSize(w, h)
                self.sized = self.sized + 1
                self.sizes[#self.sizes + 1] = w
                self.w, self.h = w, h
            end
            function f:SetWidth(w)
                self.widthCalls = self.widthCalls + 1
                self.w = w
            end
            function f:CreateFontString() return widget() end
            function f:CreateTexture() return widget() end
            return f
        end
        local buttons = {}
        CreateFrame = function(kind)
            local f = widget()
            if kind == "Button" then buttons[#buttons + 1] = f end
            return f
        end
        UIParent = {}
        STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        GameTooltip = nil
        local R = ToonAge.modules.Rotation
        InCombatLockdown = function() return true end
        R.predictBar = nil
        R.currentSpecID = 259
        R:InitPredictBar()
        local lockedBar = buttons[1]
        LOCK_CALLS = lockedBar.sized
        LOCK_WIDTH_CALLS = lockedBar.widthCalls
        LOCK_W = lockedBar.w or 0
        InCombatLockdown = function() return false end
        R.predictBar = nil
        R.currentLevel = 10
        R:InitPredictBar()
        local born = buttons[2]
        BORN_FIRST = born.sizes[1]
        BORN_W = born.w
    """)
    check("creating the bar in combat does not resize it", lua.eval("LOCK_CALLS"), 0)
    check("creating the bar in combat does not SetWidth", lua.eval("LOCK_WIDTH_CALLS"), 0)
    check("a bar created in combat is not 200 px", lua.eval("LOCK_W") != 200)
    check("a new bar starts at 88", lua.eval("BORN_FIRST"), 88)
    check("an empty verified list stays 88 after creation", lua.eval("BORN_W"), 88)

    lua.execute((ROOT / "Modules/Forever/Rotation.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
        local F = ToonAge.modules.ForeverRotation
        local sized = {}
        local bar = {}
        function bar:SetSize(w, h) sized.w, sized.h = w, h end
        function bar:Show() self.shown = true end
        function bar:Hide() self.shown = false end
        local icons = {}
        for i = 1, 3 do
            icons[i] = {
                shown = false,
                Hide = function(self) self.shown = false end,
                Show = function(self) self.shown = true end,
                icon = { SetTexture = function() end },
                nameLabel = { SetText = function(self, t) self.text = t end },
                SetBackdropBorderColor = function(self, r, g, b, a) self.a = a end,
            }
        end
        F._bar = bar
        F._barIcons = icons
        ToonAge.Utils.GetSpellTexture = function() return "tex" end
        C_AssistedCombat = { GetNextCastSpell = function() return 133 end }
        F:PaintBar()
        FOREVER_W, FOREVER_H = sized.w, sized.h
        FOREVER_SHOWN = bar.shown
        SLOT2 = icons[2].shown
        SLOT3 = icons[3].shown
        BORDER_A = icons[1].a
    """)
    check("the forever bar shrinks to one slot", lua.eval("FOREVER_W"), 56)
    check("the forever bar keeps its height", lua.eval("FOREVER_H"), 68)
    check("the forever bar is shown for one spell", lua.eval("FOREVER_SHOWN"), True)
    check("forever slot 2 stays hidden", lua.eval("SLOT2"), False)
    check("forever slot 3 stays hidden", lua.eval("SLOT3"), False)
    check("the assisted slot border is fully gold", lua.eval("BORDER_A"), 1)

    lua.execute((ROOT / "Modules/Infrastructure/Harvester.lua").read_text(encoding="utf-8"))
    lua.execute(r"""
        C_AssistedCombat = nil
        ABSENT = ToonAge.AssistCastLine()
        C_AssistedCombat = { GetNextCastSpell = function() return 42 end }
        CALLED = ToonAge.AssistCastLine()
        C_AssistedCombat.GetNextCastSpell = function() return nil end
        NONE = ToonAge.AssistCastLine()
        ToonAge.Caps = { Fn = function(path)
            if path == "issecretvalue" then return function(v) return v == "secret" end end
        end }
        C_AssistedCombat.GetNextCastSpell = function() return "secret" end
        SEC = ToonAge.AssistCastLine()
        C_AssistedCombat.GetNextCastSpell = function() error("boom") end
        local ok, line = pcall(ToonAge.AssistCastLine)
        BAD_OK, BAD = ok, line
    """)
    check("probe says the function is absent", lua.eval("ABSENT"),
          "C_AssistedCombat.GetNextCastSpell  ->  absent")
    check("probe reports the returned id", lua.eval("CALLED"),
          "C_AssistedCombat.GetNextCastSpell  ->  present, called, 42")
    check("probe reports a nil id", lua.eval("NONE"),
          "C_AssistedCombat.GetNextCastSpell  ->  present, called, nil")
    check("probe reports a secret id", lua.eval("SEC"),
          "C_AssistedCombat.GetNextCastSpell  ->  present, called, secret")
    check("probe survives an error", lua.eval("BAD_OK"), True)
    bad = lua.eval("BAD") or ""
    check("probe records the error",
          bad.startswith("C_AssistedCombat.GetNextCastSpell  ->  present, error:") and "boom" in bad)

    harness = (ROOT / "Modules/Infrastructure/TestHarness.lua").read_text(encoding="utf-8")
    check("the self-test reports the assist call", "TA.AssistCastLine" in harness)

    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
