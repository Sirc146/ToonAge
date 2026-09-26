#!/usr/bin/env python3
"""The combat recorder: measured play, bounded storage, cheap hot path.

Nothing in this addon had ever read the combat log, so two questions could not
be answered at all -- "what should I press now" and "which of my buttons are
dead". Both need the same record: what you cast, in what state, and what came
of it. CombatState knows the present perfectly and has no memory.

Three properties make this safe to ship, and each is pinned here:

  AGGREGATED   A raw event log would fill SavedVariables in an evening. The
               store grows with the number of abilities you own, not with the
               hours you play.
  CHEAP        COMBAT_LOG_EVENT_UNFILTERED is the highest-frequency event in
               the game. Anything not cast by the player must cost one string
               compare and nothing else.
  SILENT       It records. It does not rank, weight or advise -- judgement has
               to earn its numbers from this record first.
"""
import sys, os
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


r = read("Modules/Combat/CombatRecorder.lua")

check("it registers itself", 'TA:RegisterModule("CombatRecorder", R)' in r)
check("it reads the combat log", "CombatLogGetCurrentEventInfo" in r)
check("it uses the guarded event registration", 'TA:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")' in r)

# ── Cheap: the player check must come before any real work ──────────────
h = r[r.index("function R:OnCombatLog"):r.index("-- ── Bars and spellbook")]
check("it filters to the player", "if sourceGUID ~= playerGUID then return end" in h)
check("the filter precedes the store lookup",
      h.index("sourceGUID ~= playerGUID") < h.index("local s = Store()"))
check("it recognises events by table lookup, not a comparison chain",
      "local kind = INTERESTING[subEvent]" in r)
check("an uninteresting event exits immediately", "if not kind then return end" in h)
# One call per event. Calling the log twice on the hot path is the mistake this
# file made first time round, in the swing branch.
check("the log is read once per event", h.count("CombatLogGetCurrentEventInfo()"), 1)

# ── Aggregated: no raw event list anywhere ──────────────────────────────
check("no raw event log is appended", "table.insert" not in r)
check("casts are counted", "row.casts   = (row.casts or 0) + 1" in r)
check("damage is summed", "row.damage  = (row.damage or 0) + (tonumber(amount) or 0)" in r)
check("healing is summed", "row.healing = (row.healing or 0) + (tonumber(amount) or 0)" in r)

# ── Bounded ─────────────────────────────────────────────────────────────
check("the spell table is capped", "MAX_SPELLS" in r)
check("the bar scan is capped", "MAX_BARS" in r)
check("an older store is backfilled, not reset", "s.spells  = s.spells  or {}" in r)

# ── The three sets the waste audit needs ────────────────────────────────
check("it records what is on your bars", "function R:ScanBars" in r)
check("it records what you know", "function R:ScanSpellbook" in r)
check("bars come from the action slots", "Try(GetActionInfo, slot)" in r)
check("both spellbook APIs are probed",
      "C_SpellBook.GetSpellBookItemInfo" in r and "Try(GetSpellBookItemInfo" in r)

# ── Fights ──────────────────────────────────────────────────────────────
check("fight length is measured", "MIN_FIGHT_SECONDS" in r)
check("scraps do not count as fights", "if dur < MIN_FIGHT_SECONDS then return end" in r)

# ── Silent ──────────────────────────────────────────────────────────────
# The only chat write allowed is the debug line.
check("it does not chatter", r.count("TA:Raw(") <= 1)
# Check the CODE, not the prose -- the header legitimately says "no weights,
# no rankings", and a test that trips over its own documentation is a test
# nobody will trust the next time it fires.
code = "\n".join(l.split("--")[0] for l in r.split("\n")).lower()
check("the code ranks nothing",
      "priority" not in code and "weight" not in code and "score" not in code)

# ── Wiring ──────────────────────────────────────────────────────────────
for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_Camelot.toc"):
    check(f"{toc} ships it", "Modules\\Combat\\CombatRecorder.lua" in read(toc))
check("forever allows it", "CombatRecorder   = true," in read("Core/Profile.lua"))


rep = read("Modules/Combat/CombatReport.lua")
check("report registers", 'TA:RegisterModule("CombatReport", M)' in rep)
check("report refuses to rank below a fight minimum", "if (s.fights or 0) < MIN_FIGHTS then" in rep)
check("thinly-cast abilities are not judged", "if (row.casts or 0) < MIN_CASTS then" in rep)
check("dead bar slots are bars minus casts", "a.dead[#a.dead + 1]" in rep)
check("forgotten abilities are known minus bars", "a.forgotten[#a.forgotten + 1]" in rep)
check("reset needs two clicks", "_confirmReset" in rep)
for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_Camelot.toc"):
    t_ = read(toc)
    check(f"{toc} loads the report after the recorder",
          t_.index("CombatRecorder.lua") < t_.index("CombatReport.lua"))

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
