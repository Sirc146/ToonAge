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
