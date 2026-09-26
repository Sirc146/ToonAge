#!/usr/bin/env python3
"""A module that never initialised must be unreachable.

Four things switch a module off — the flavor profile, Safe Mode, /ta toggle,
and auto-disable after errors — and all four mean Init never ran. Anything that
then calls into it is calling a module whose state was never set up. That is
how QuestTracker's dungeon tip crashed on WoW Forever: the profile skipped
SpecAdaptive, GetModule handed it over anyway, and it hit an API a specless
client does not have.
"""
import sys, os
from lupa import LuaRuntime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


init = open(os.path.join(ROOT, "Core/Init.lua"), encoding="utf-8").read()

# Behavioural: run the real GetModule against a stub registry.
lua = LuaRuntime()
body = init[init.index("function TA:GetModule(name)"):init.index("--- Returns a health report")]
lua.execute("TA = { modules = {} }")
lua.execute(body)
lua.execute("""
TA.modules.Running     = { name = "Running" }
TA.modules.UserOff     = { name = "UserOff",  _disabled = true }
TA.modules.NotThisFlavor = { name = "NotThisFlavor", _profileSkipped = true, _profileReason = "not in WoW Forever (beta)" }
""")
g = lua.globals()
check("a running module is returned", g.TA.GetModule(g.TA, "Running") is not None)
check("a user-disabled module is not", g.TA.GetModule(g.TA, "UserOff") is None)
check("a profile-skipped module is not", g.TA.GetModule(g.TA, "NotThisFlavor") is None)
check("an unknown module is nil", g.TA.GetModule(g.TA, "Nope") is None)
check("raw access still available",
      g.TA.GetRegisteredModule(g.TA, "NotThisFlavor") is not None)

# Slash commands must not reach them either — this is how /ta spellaudit ran on
# Forever with DevHelpers switched off.
slash = init[init.index("-- ── Module slash commands"):init.index("-- ── Prefix / fuzzy match")]
check("slash dispatch checks _disabled", "_disabled" in slash)
check("slash dispatch checks _profileSkipped", "_profileSkipped" in slash)
check("slash dispatch explains rather than failing silently",
      "which is not running here" in slash)

# The specific crash: SpecAdaptive must never call the spec API raw.
sa = open(os.path.join(ROOT, "Modules/Combat/SpecAdaptive.lua"), encoding="utf-8").read()
role = sa[sa.index("function SA:GetRoleInfo"):]
role = role[:role.index("\nend")]
check("SpecAdaptive checks the API exists", 'type(GetSpecialization) ~= "function"' in role)
check("SpecAdaptive cannot throw", "pcall(GetSpecialization)" in role)
check("SpecAdaptive returns a sane default", 'return "DAMAGER", "Unknown", "melee"' in role)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
