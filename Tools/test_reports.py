#!/usr/bin/env python3
"""Long output goes to a selectable window, not to chat.

Chat holds a couple of dozen visible lines, cannot be selected, and shares
scrollback with combat spam. Anything longer than a few lines has to end up
somewhere the player can copy it from.
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


ui = open(os.path.join(ROOT, "Core/UI.lua"), encoding="utf-8").read()
check("copy window exists", "function TA:ShowCopyWindow" in ui)
check("copy window strips colour codes", "local function Plain" in ui)
check("copy window is escape-closable", 'tinsert(UISpecialFrames, "ToonAgeCopyWindow")' in ui)
check("report writer exists", "function TA:BeginReport" in ui)
check("report has Add/Addf/Finish",
      all(f"function r:{fn}" in ui for fn in ("Add", "Addf", "Finish")))
check("report opens the window past its threshold",
      "#self.lines > self.threshold and TA.ShowCopyWindow" in ui)

init = open(os.path.join(ROOT, "Core/Init.lua"), encoding="utf-8").read()
health = init[init.index("health   = function()"):init.index("help     = function()")]
check("health builds a report", "BeginReport" in health)
# The output window is bound as `win`. It used to be `report`, which is also
# what the module list was called, and the second declaration shadowed the
# first -- that is what made /ta health print "0 loaded" on a healthy client.
# Tools/test_health.py pins the whole shape; this line just tracks the name.
check("health always uses the window", "win.threshold = 0" in health)
check("health names the client and build", "interface %s" in health)
# No stray direct chat writes left inside the health command.
# The only direct chat write allowed is the fallback inside Say(), for the
# case where the report writer is somehow unavailable.
strays = re.findall(r"TA:Raw\(TA\.LOG\.OUTPUT", health)
check("health writes no report lines straight to chat", len(strays), 1)

qt = open(os.path.join(ROOT, "Modules/Navigation/QuestTracker.lua"), encoding="utf-8").read()
diag = qt[qt.index("function QT:Diagnose"):]
diag = diag[:diag.index("\nfunction QT:")]
check("Diagnose builds a report", "BeginReport" in diag)
# Both exits must flush, or the window silently never opens.
check("Diagnose flushes on every exit", diag.count("report:Finish()"), 2)

dev = open(os.path.join(ROOT, "Modules/Infrastructure/DevHelpers.lua"), encoding="utf-8").read()
check("spell audit already uses the export window", 'DH:ShowExport("Spell Audit"' in dev)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
