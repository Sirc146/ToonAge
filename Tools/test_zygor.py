"""Zygor companion mode: detection, opt-out, and that each automation path checks it."""
import re, sys, os
from lupa import LuaRuntime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
fails = 0; n = 0
def check(name, cond):
    global fails, n
    n += 1
    if not cond: fails += 1; print("FAIL", name)

lua = LuaRuntime()
load = lua.eval('function(s,n) local f,e=load(s,n) return e end')
for f in ["Core/Utils.lua","Modules/Navigation/QuestTracker.lua","Modules/Gear/AutoEquip.lua",
          "Modules/TBC/AutoEquip.lua","Modules/Navigation/Arrow.lua","Modules/Infrastructure/Settings.lua"]:
    src = open(os.path.join(ROOT, f), encoding="utf-8").read()
    err = load(src, "@"+f)
    check("syntax "+f, err is None or "goto" in str(err))
    if err: print(f, err)

src = open(os.path.join(ROOT, "Core/Utils.lua"), encoding="utf-8").read()
block = src[src.index("-- ── Addon-presence utilities"):src.index("--- Returns the addon's display title")]
lua.execute("TA = {}; U = {}; loaded = {}; C_AddOns = {IsAddOnLoaded=function(n) return loaded[n] == true end}")
lua.execute(block)
g = lua.globals()
check("no zygor -> no defer", g.U.DeferToZygor() is False)
lua.execute('loaded["ZygorGuidesViewerClassic"] = true')
check("classic folder detected", g.U.ZygorLoaded() is True)
check("defer on by default (no charDB)", g.U.DeferToZygor() is True)
lua.execute('TA.charDB = {tracker = {}}')
check("defer on when setting nil", g.U.DeferToZygor() is True)
lua.execute('TA.charDB.tracker.deferToZygor = false')
check("opt-out respected", g.U.DeferToZygor() is False)
lua.execute('loaded = {}; ZygorGuidesViewer = {}; TA.charDB.tracker.deferToZygor = nil')
check("global table detected", g.U.DeferToZygor() is True)

def body(path, fn):
    s = open(os.path.join(ROOT, path), encoding="utf-8").read()
    i = s.index(fn); return s[i:i+2500]
check("quest automation gated", "DeferToZygor" in body("Modules/Navigation/QuestTracker.lua", "function QT:HandleAutoQuest")[:600])
qt = open(os.path.join(ROOT, "Modules/Navigation/QuestTracker.lua"), encoding="utf-8").read()
check("reward picker no longer calls ScoreItem", "GearMod:ScoreItem" not in qt and "GearMod.CalculateItemScore" in qt)
for ae in ("Modules/Gear/AutoEquip.lua", "Modules/TBC/AutoEquip.lua"):
    check("autoequip gated "+ae, "DeferToZygor" in body(ae, "local function ShouldAutoEquip")[:300])
check("arrow tick gated", "DeferToZygor" in body("Modules/Navigation/Arrow.lua", "function Arrow:Tick")[:900])
check("settings toggle + export key", "deferToZygor" in open(os.path.join(ROOT,"Modules/Infrastructure/Settings.lua"),encoding="utf-8").read().split("PROFILE_KEYS")[1][:600])
print(f"{n-fails}/{n} passed"); sys.exit(1 if fails else 0)
