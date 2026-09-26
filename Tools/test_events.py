#!/usr/bin/env python3
"""RegisterEvent throws on an event the client does not define.

Module Init calls it directly, so one bad name takes the whole module down.
That is what happened to DataHarvester on WoW Forever: it asked for
LEARNED_SPELL_IN_TAB -- the classic-era name, replaced on modern clients by
LEARNED_SPELL_IN_SKILL_LINE -- and died at Init, taking the item, spell and
talent recording that client exists to collect. Every other event it wanted
was fine.

Same shape as calling an absent API, same treatment: try it, survive the miss,
record what was missing so /ta health can say it.
"""
import sys, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


init = read("Core/Init.lua")

check("the guarded helper exists", "function TA:RegisterEvent(event)" in init)
check("it never lets a throw escape", "pcall(self.eventFrame.RegisterEvent" in init)
check("it records what the client refused", "self.unknownEvents[event] = true" in init)
check("the record starts empty", "TA.unknownEvents = {}" in init)
check("/ta health reports them", "event(s) this client does not define" in init)

# The point of the exercise: no module may call the raw frame method, because
# that is the one that throws.
raw = []
for base in ("Core", "Modules"):
    for dirpath, _, files in os.walk(os.path.join(ROOT, base)):
        for fn in files:
            if not fn.endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            src = open(path, encoding="utf-8").read()
            # The helper's own body legitimately touches the frame, by dot.
            if re.search(r"TA\.eventFrame:RegisterEvent\(", src):
                raw.append(rel)
check("no module registers on the raw frame", sorted(raw), [])

# DataHarvester must ask for both spellbook event names.
dh = read("Modules/Forever/DataHarvester.lua")
check("harvester asks for the classic name", 'TA:RegisterEvent("LEARNED_SPELL_IN_TAB")' in dh)
check("harvester asks for the modern name",
      'TA:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")' in dh)
check("harvester handles the modern name", "LEARNED_SPELL_IN_SKILL_LINE" in
      dh[dh.index("function H:OnEvent"):])

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
