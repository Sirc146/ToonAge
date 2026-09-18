#!/usr/bin/env python3
"""Mutation check: back each 2.0 fix out, prove the suite goes red, restore.

.rules.md: "A suite that has never been seen to fail is not evidence."
A mutation that leaves the suite green means the test does not actually
constrain the behaviour it claims to.
"""
import subprocess, sys
from pathlib import Path

ROOT = Path(r"C:\Program Files (x86)\World of Warcraft\_ptr_\Interface\AddOns\ToonAge")
TARGET = ROOT / "Rebuild-2.0" / "Core" / "Init.lua"
ORIGINAL = TARGET.read_text(encoding="utf-8")

MUTATIONS = [
    ("fail-open default -> fail-closed (undeclared modules get nothing)",
     "                wants = not coreOnly",
     "                wants = false"),

    ("dispatch order from pairs() instead of moduleOrder",
     "    for i = 1, #TA.moduleOrder do\n        local name = TA.moduleOrder[i]\n        local mod  = TA.modules[name]\n        local meta = modMeta[name]\n        if mod and mod.OnEvent and meta then",
     "    for name, mod in pairs(TA.modules) do\n        local meta = modMeta[name]\n        if mod and mod.OnEvent and meta then"),

    ("InitModules order from pairs() instead of moduleOrder",
     "    for i = 1, #self.moduleOrder do\n        local name = self.moduleOrder[i]\n        local mod  = self.modules[name]\n\n        -- Reset per-session failure state.",
     "    for name, mod in pairs(self.modules) do\n\n        -- Reset per-session failure state."),

    ("core-only guard removed (broadcast modules get lifecycle events)",
     "    local coreOnly = CORE_ONLY_EVENTS[event]",
     "    local coreOnly = false"),

    ("_disabled check hoisted out of the dispatch loop",
     "        if mod and mod.OnEvent and not mod._disabled then",
     "        if mod and mod.OnEvent then"),

    # Module Init, UI and the profession snapshot pulled forward to
    # PLAYER_LOGIN -- the scope-creep version of F-1 that an earlier 2.0 draft
    # actually shipped, and that TravelRouter:Init would have silently lost
    # hearthZoneID to.
    ("F-1 over-applied: module init pulled forward to PLAYER_LOGIN",
     '        TA:InitCharDB()\n        TA._bootPhase = "login"',
     '        TA:InitCharDB()\n        TA:OnLogin()\n        TA._bootPhase = "login"'),

    ("F-1 reverted: charKey built at ADDON_LOADED",
     "    self.db = db\n    -- No logLevel copy here.",
     "    self.db = db\n    self:InitCharDB()\n    -- No logLevel copy here."),

    ("F-2 reverted: second hardcoded command list that drifted",
     "    local names = {}\n    for name in pairs(BUILTIN) do names[#names + 1] = name end",
     '    local names = {"gear","talents","rotation","prof","pets","weekly","guide",\n'
     '                   "options","debug","reset","layout","help","toggle","open",\n'
     '                   "safemode","health"}\n    local _unused = BUILTIN'),

    ("F-4 reverted: no combat guard on frame-affecting commands",
     "    if not InCombatLockdown or not InCombatLockdown() then\n        fn()\n        return true\n    end",
     "    if true then\n        fn()\n        return true\n    end"),

    ("F-5 reverted: GetLogLevel ignores the DB",
     '    local db = rawget(self, "db")\n    if db and db.logLevel then return db.logLevel end\n    return BOOT_LOG_LEVEL',
     "    return BOOT_LOG_LEVEL"),

    ("F-6 reverted: unbounded fuzzy scoring",
     "    if shorter / longer < FUZZY_THRESHOLD then return 0 end",
     "    if false then return 0 end"),

    ("SafeRegisterEvent unwrapped: a bad event name kills Core",
     "    local ok, err = pcall(TA.eventFrame.RegisterEvent, TA.eventFrame, event)",
     "    local ok, err = true, nil; TA.eventFrame:RegisterEvent(event)"),

    ("varargs packed into a table on the way through",
     "            local ok, err = pcall(mod.OnEvent, mod, event, ...)",
     "            local ok, err = pcall(mod.OnEvent, mod, event, {...})"),

    ("PLAYER_ENTERING_WORLD no longer idempotent",
     '        if TA._bootPhase ~= "world" then',
     "        if true then"),

    # Surgical: keep both fallback assignments, delete ONLY the ERROR report.
    # The blunt version (deleting the whole `if`) left `name` nil and crashed on
    # the concat before the assertion could run -- so it proved the fallback
    # existed, not that the failure was loud.
    ("identity failure made silent again (the 1.x Unknown-Unknown bug)",
     '        TA:Printf(TA.LOG.ERROR, nil,\n            "Character identity unavailable at PLAYER_LOGIN (name=%s realm=%s). "\n            .. "Per-character settings will not persist correctly this session.",\n            tostring(name), tostring(server))',
     "        -- report removed by mutation"),

    ("InitDB compatibility shim removed",
     "function TA:InitDB()\n    self:InitAccountDB()\n    self:InitCharDB()\nend",
     "function TA:InitDB_removed()\n    self:InitAccountDB()\n    self:InitCharDB()\nend"),

    ("duplicate registration allowed to corrupt moduleOrder",
     "    if self.modules[name] then",
     "    if false and self.modules[name] then"),
]


def run_suite():
    r = subprocess.run([sys.executable, "Tools/test_dispatch.py"],
                       cwd=ROOT, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def main():
    rc, out = run_suite()
    if rc != 0:
        print("BASELINE IS ALREADY RED -- fix that before mutating.")
        print(out[-3000:])
        return 1
    print(f"baseline green: {out.strip().splitlines()[0]}\n")

    survivors = []
    for label, old, new in MUTATIONS:
        if old not in ORIGINAL:
            print(f"  SKIP   {label}\n         (anchor not found -- mutation is stale)")
            survivors.append((label, "stale anchor"))
            continue
        TARGET.write_text(ORIGINAL.replace(old, new, 1), encoding="utf-8")
        rc, out = run_suite()
        TARGET.write_text(ORIGINAL, encoding="utf-8")

        if rc != 0:
            failed = [l.strip() for l in out.splitlines() if l.strip().startswith("FAIL")]
            first = failed[0][6:].strip() if failed else "?"
            print(f"  caught {label}")
            print(f"         -> {len(failed)} check(s) red, first: {first}")
        else:
            print(f"  SURVIVED  {label}")
            survivors.append((label, "suite stayed green"))

    TARGET.write_text(ORIGINAL, encoding="utf-8")
    rc, out = run_suite()
    print(f"\nrestored, suite {'green' if rc == 0 else 'RED'}")

    if survivors:
        print(f"\n{len(survivors)} mutation(s) not caught:")
        for label, why in survivors:
            print(f"  - {label}  ({why})")
        return 1
    print(f"\nAll {len(MUTATIONS)} mutations caught.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
