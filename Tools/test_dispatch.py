#!/usr/bin/env python3
"""
ToonAge -- core event dispatch tests (replaces the Rebuild-2.0 dispatcher test)
==============================================================================
Runs the real Core/Init.lua under the onboarding test's stub WoW API and checks:

  * EVENT_ROUTES in Core/Init.lua matches Tools/gen_event_routes.py (not stale)
  * a routed high-frequency event reaches only the modules in its route
  * an unrouted event is still broadcast to every module
  * one module erroring does not stop the others, and repeat offenders are
    auto-disabled (Safe Mode)
  * PLAYER_ENTERING_WORLD: first fire logs in; later fires call OnEnterWorld
    and queue a UI refresh instead of logging in again
  * a batch of only noisy events (QUEST_LOG_UPDATE) is throttled; a batch with
    any other event refreshes on the normal short delay

Usage:  python Tools/test_dispatch.py [-v]
"""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_onboarding import PRELUDE, _read  # noqa: E402
from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}" + (f"  -> {detail}" if detail and not ok else ""))


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(r"""
        ToonAgeDB = {}
        local TA = ToonAge
        TA.InitDB(TA)
        _calls = {}
        local function mk(name, fail)
            local m = { OnEvent = function(self, ev)
                _calls[#_calls + 1] = name .. ":" .. ev
                if fail then error("boom") end
            end }
            TA.modules[name] = m
            return m
        end
        mk("Gear"); mk("Character"); mk("Delves"); mk("QuestTracker"); mk("Broken", true)
        TA.modules.Delves.OnEnterWorld = function() _calls[#_calls + 1] = "Delves:OnEnterWorld" end
        _refreshes = {}
        TA.UI = { IsVisible = function() return true end,
                  Refresh = function(_, events)
                      local names = {}
                      for e in pairs(events or {}) do names[#names + 1] = e end
                      table.sort(names)
                      _refreshes[#_refreshes + 1] = { at = _now, ev = table.concat(names, ",") }
                  end }
        _logins = 0
        TA.OnLogin = function() _logins = _logins + 1 end
        function Fire(ev, ...) TA.eventFrame:GetScript("OnEvent")(TA.eventFrame, ev, ...) end
    """)
    return lua


def calls(lua):
    c = lua.eval("_calls")
    return [c[i] for i in range(1, len(c) + 1)]


def main():
    r = subprocess.run([sys.executable, str(ROOT / "Tools" / "gen_event_routes.py"), "--check"],
                       capture_output=True, text=True)
    check("EVENT_ROUTES up to date with module sources", r.returncode == 0, r.stdout.strip())

    lua = runtime()
    lua.execute('Fire("BAG_UPDATE", 0)')
    got = calls(lua)
    check("routed BAG_UPDATE reaches only its route (Gear)", got == ["Gear:BAG_UPDATE"], got)

    lua.execute("_calls = {}")
    lua.execute('Fire("GROUP_ROSTER_UPDATE")')
    got = sorted(calls(lua))
    check("unrouted event broadcast to every module",
          got == sorted(["Gear:GROUP_ROSTER_UPDATE", "Character:GROUP_ROSTER_UPDATE", "Delves:GROUP_ROSTER_UPDATE",
                         "QuestTracker:GROUP_ROSTER_UPDATE", "Broken:GROUP_ROSTER_UPDATE"]), got)
    check("a failing module does not stop the others", len(got) == 5)

    for _ in range(12):
        lua.execute('Fire("GROUP_ROSTER_UPDATE")')
    check("repeat offender auto-disabled (Safe Mode)", lua.eval("ToonAge.modules.Broken._disabled") is True)

    # PLAYER_ENTERING_WORLD
    lua.execute("_calls = {} _refreshes = {}")
    lua.execute('Fire("PLAYER_ENTERING_WORLD", true, false)')
    check("first PLAYER_ENTERING_WORLD logs in", lua.eval("_logins") == 1)
    check("PLAYER_ENTERING_WORLD stays registered", lua.eval('ToonAge.eventFrame:IsEventRegistered("PLAYER_ENTERING_WORLD")') is not False)
    lua.execute('Fire("PLAYER_ENTERING_WORLD", false, false)')
    check("zone-in does not log in again", lua.eval("_logins") == 1)
    check("zone-in calls OnEnterWorld", "Delves:OnEnterWorld" in calls(lua), calls(lua))
    check("zone-in is not broadcast through OnEvent", not any(c.endswith(":PLAYER_ENTERING_WORLD") for c in calls(lua)))
    lua.execute("AdvanceTo(_now + 0.2)")
    check("zone-in refreshes the open tab", lua.eval("#_refreshes") == 1)

    # Throttle
    lua.execute("_refreshes = {}; ToonAge._lastUIRefresh = _now")
    lua.execute('Fire("QUEST_LOG_UPDATE")')
    lua.execute("AdvanceTo(_now + 0.2)")
    check("noisy-only batch held inside the throttle window", lua.eval("#_refreshes") == 0)
    lua.execute("AdvanceTo(_now + 2.0)")
    check("noisy-only batch flushes after the throttle window", lua.eval("#_refreshes") == 1)
    lua.execute("_refreshes = {}; ToonAge._lastUIRefresh = _now")
    lua.execute('Fire("QUEST_LOG_UPDATE"); Fire("PLAYER_EQUIPMENT_CHANGED")')
    lua.execute("AdvanceTo(_now + 0.2)")
    check("mixed batch refreshes on the short delay", lua.eval("#_refreshes") == 1)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
