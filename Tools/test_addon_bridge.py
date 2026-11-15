#!/usr/bin/env python3
"""AddonBridge phase 1: detect known addons and coexist. No reskin, no glow.

Runs the real Core/Compat/API.lua and Modules/Infrastructure/AddonBridge.lua
under Lua 5.1. A missing file, a thrown detection check, a tooltip clear, or
a write into a host restock table fails this suite.

Usage:  python3 Tools/test_addon_bridge.py [-v]
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

WANTED = [
    "blizzard", "elvui", "melloui", "bartender4", "dominos", "mellorest",
    "zygor", "mittenquest", "melloquest", "libdbicon", "tomtom",
]


def check(name, got, want=True):
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


def fresh():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, LOG = { OUTPUT = 1 } }
        function ToonAge:RegisterModule(name, module)
            self.modules[name] = module
            self[name] = module
        end
        function ToonAge:Print() end
        function ToonAge:Raw() end
        function ToonAge:ToggleUI() TOGGLED = (TOGGLED or 0) + 1 end
        function ToonAge:ApplyLayout() LAYOUTS = (LAYOUTS or 0) + 1 end
        UIParent = nil
        GameTooltip = nil
        C_AddOns = {
            IsAddOnLoaded = function(name) return false end,
            GetAddOnInfo = function(name) return name, name, "", true, true end,
        }
        IsAddOnLoaded = nil
        GetAddOnInfo = nil
        LibStub = nil
    """)
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(read("Modules/Infrastructure/AddonBridge.lua"))
    lua.execute("TA = ToonAge")
    return lua


def snap(lua):
    lua.execute(r"""
        _rows = TA.AddonBridge:Detect()
        _n = #_rows
        _ids, _notes, _loaded, _labels = {}, {}, {}, {}
        for i = 1, #_rows do
            local row = _rows[i]
            _ids[i] = row.id
            _labels[i] = row.label
            _notes[row.id] = row.note or ""
            _loaded[row.id] = row.loaded and true or false
        end
        _standalone = TA.AddonBridge:IsStandalone()
    """)
    g = lua.globals()
    return g


def test_catalog_and_standalone():
    lua = fresh()
    g = snap(lua)
    check("eleven detection rows", int(g._n), 11)
    ids = [g._ids[i] for i in range(1, 12)]
    check("detection order", ids, WANTED)
    check("standalone when nothing else is loaded", bool(g._standalone), True)
    check("blizzard is not loaded without a frame host", bool(g._loaded["blizzard"]), False)
    check("zygor note is verified", g._notes["zygor"], "")
    check("blizzard note is verified", g._notes["blizzard"], "")
    check("elvui folder is not marked unverified", "UNVERIFIED folder" in g._notes["elvui"], False)
    check("elvui global is unverified", "UNVERIFIED global ElvUI" in g._notes["elvui"], True)
    check("melloui folder is unverified", "UNVERIFIED folder MelloUI" in g._notes["melloui"], True)
    check("bartender is unverified", "UNVERIFIED" in g._notes["bartender4"], True)
    check("dominos is unverified", "UNVERIFIED" in g._notes["dominos"], True)
    check("restock folder is unverified", "UNVERIFIED folder" in g._notes["mellorest"], True)
    check("restock saved is unverified", "UNVERIFIED saved" in g._notes["mellorest"], True)
    check("mitten is unverified", "UNVERIFIED" in g._notes["mittenquest"], True)
    check("mello quest list is unverified", "UNVERIFIED" in g._notes["melloquest"], True)
    check("libdbicon lib is unverified", "UNVERIFIED lib LibDBIcon-1.0" in g._notes["libdbicon"], True)
    check("tomtom folder is verified", "UNVERIFIED folder" in g._notes["tomtom"], False)
    check("tomtom global is unverified", "UNVERIFIED global TomTom" in g._notes["tomtom"], True)
    check("phase 1 does not reskin", bool(lua.eval("TA.AddonBridge:Reskins()")), False)
    check("phase 1 does not hook glows", bool(lua.eval("TA.AddonBridge:GlowHooks()")), False)

    lua.execute("UIParent = {}")
    g = snap(lua)
    check("blizzard frame host counts as loaded", bool(g._loaded["blizzard"]), True)
    check("blizzard alone stays standalone", bool(g._standalone), True)


def test_detection_never_throws():
    lua = fresh()
    lua.execute(r"""
        C_AddOns = {
            IsAddOnLoaded = function() error("loaded-boom") end,
            GetAddOnInfo = function() error("info-boom") end,
        }
        IsAddOnLoaded = function() error("classic-boom") end
        GetAddOnInfo = function() error("classic-info") end
        LibStub = setmetatable({}, { __call = function() error("lib-boom") end })
        _G = _G
        THREW = false
        local ok = pcall(function() TA.AddonBridge:Detect() end)
        THREW = not ok
        _standalone = TA.AddonBridge:IsStandalone()
    """)
    g = lua.globals()
    check("throwing addon and lib checks are swallowed", bool(g.THREW), False)
    check("a broken check does not invent a host", bool(g._standalone), True)

    lua.execute(r"""
        C_AddOns = nil
        IsAddOnLoaded = function(name) return name == "TomTom" end
        LibStub = nil
    """)
    g = snap(lua)
    check("classic IsAddOnLoaded detects TomTom", bool(g._loaded["tomtom"]), True)
    check("tomtom loaded leaves standalone", bool(g._standalone), False)

    lua.execute(r"""
        IsAddOnLoaded = function() return false end
        ZygorGuidesViewer = {}
    """)
    g = snap(lua)
    check("zygor global is detected", bool(g._loaded["zygor"]), True)

    lua.execute(r"""
        ZygorGuidesViewer = nil
        IsAddOnLoaded = function(name) return name == "ElvUI" end
    """)
    g = snap(lua)
    check("elvui folder is detected", bool(g._loaded["elvui"]), True)
    check("elvui owns the host tooltip", bool(lua.eval("TA.AddonBridge:HostOwnsTooltip()")), True)
    check("elvui still does not reskin", bool(lua.eval("TA.AddonBridge:Reskins()")), False)
    check("elvui still does not glow", bool(lua.eval("TA.AddonBridge:GlowHooks()")), False)


def test_tooltip_append_only():
    lua = fresh()
    lua.execute(r"""
        LINES = { "Host title", "Host body" }
        CLEARED, SET = 0, 0
        tip = {
            AddLine = function(_, text) LINES[#LINES + 1] = text end,
            AddDoubleLine = function(_, left, right) LINES[#LINES + 1] = left .. "|" .. right end,
            ClearLines = function() CLEARED = CLEARED + 1; LINES = {} end,
            SetText = function() SET = SET + 1; LINES = { "replaced" } end,
        }
        OK = TA.AddonBridge:AppendTooltip(tip, {
            "ToonAge score",
            { left = "Score", right = "12", r = 1, g = 1, b = 1, r2 = 0, g2 = 1, b2 = 0 },
        })
        NIL_OK = TA.AddonBridge:AppendTooltip(nil, { "x" })
        FIRST = LINES[1]
        SECOND = LINES[2]
        THIRD = LINES[3]
        FOURTH = LINES[4]
    """)
    g = lua.globals()
    check("append returns true", bool(g.OK), True)
    check("nil tooltip is refused", bool(g.NIL_OK), False)
    check("host first line kept", g.FIRST, "Host title")
    check("host second line kept", g.SECOND, "Host body")
    check("toonage line follows the host", g.THIRD, "ToonAge score")
    check("double line is appended", g.FOURTH, "Score|12")
    check("clear was not called", int(g.CLEARED), 0)
    check("settext was not called", int(g.SET), 0)


def test_restock_readonly():
    lua = fresh()
    lua.execute(r"""
        TA.db = {}
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI_Restock" end
        MelloUI_RestockDB = { items = { { id = 123, qty = 2 } } }
        function snapshot()
            local db = MelloUI_RestockDB
            return db.items[1].id .. ":" .. db.items[1].qty .. ":" .. tostring(db.extra)
        end
        BEFORE = snapshot()
        LIST, SOURCE = TA.AddonBridge:ReadRestock()
        LIST.items[1].qty = 99
        LIST.extra = "written"
        AFTER_MUTATE = snapshot()
        WROTE = TA.AddonBridge:WriteStandalone({ { id = 9, qty = 4 } })
        AFTER_WRITE = snapshot()
        OWN = TA.db.addonBridge and TA.db.addonBridge.restock
        OWN_ID = OWN and OWN[1] and OWN[1].id
        STILL_HOST, STILL_SOURCE = TA.AddonBridge:ReadRestock()
        HOST_QTY = STILL_HOST.items[1].qty
    """)
    g = lua.globals()
    check("host restock is the read source", g.SOURCE, "melloui")
    check("write standalone reports success", bool(g.WROTE), True)
    check("mutating the copy misses the host", g.AFTER_MUTATE, g.BEFORE)
    check("standalone write misses the host", g.AFTER_WRITE, g.BEFORE)
    check("standalone row is stored on ToonAge", int(g.OWN_ID), 9)
    check("read stays on the host while it is loaded", g.STILL_SOURCE, "melloui")
    check("host quantity unchanged", int(g.HOST_QTY), 2)

    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function() return false end
        MelloUI_RestockDB = { items = { { id = 123, qty = 2 } } }
        BEFORE = snapshot()
        LIST, SOURCE = TA.AddonBridge:ReadRestock()
        FALLBACK_ID = LIST[1] and LIST[1].id
        TA.AddonBridge:WriteStandalone({ { id = 8, qty = 1 } })
        AFTER = snapshot()
        LIST2, SOURCE2 = TA.AddonBridge:ReadRestock()
        FALLBACK_ID2 = LIST2[1] and LIST2[1].id
    """)
    g = lua.globals()
    check("absent restock addon uses the standalone list", g.SOURCE, "standalone")
    check("standalone read sees the previous fallback", int(g.FALLBACK_ID), 9)
    check("undetected host saved variable is not read", int(g.FALLBACK_ID) != 123, True)
    check("fallback write still misses the host table", g.AFTER, g.BEFORE)
    check("fallback read returns the new row", g.SOURCE2, "standalone")
    check("fallback read returns the written id", int(g.FALLBACK_ID2), 8)


def test_guide_toggles():
    lua = fresh()
    lua.execute(r"""
        C_AddOns.IsAddOnLoaded = function() return false end
        NO_HOST = TA.AddonBridge:DeferOtherGuides()
        C_AddOns.IsAddOnLoaded = function(name) return name == "MittenQuest" end
        DEFAULT_ON = TA.AddonBridge:DeferOtherGuides()
        TA.charDB = { tracker = {} }
        STILL = TA.AddonBridge:DeferOtherGuides()
        TA.AddonBridge:ToggleGuideDefer("deferToMittenQuest")
        OFF = TA.charDB.tracker.deferToMittenQuest
        STEPPING = TA.AddonBridge:DeferOtherGuides()
        TA.AddonBridge:ToggleGuideDefer("deferToMittenQuest")
        BACK_ON = TA.AddonBridge:DeferOtherGuides()
        C_AddOns.IsAddOnLoaded = function(name) return name == "MelloUI_QuestList" end
        MELLO = TA.AddonBridge:DeferOtherGuides()
        TA.charDB.tracker.deferToMelloQuestList = false
        MELLO_OFF = TA.AddonBridge:DeferOtherGuides()
        TA.charDB = nil
        NO_CREATE = TA.AddonBridge:ToggleGuideDefer("deferToMittenQuest")
        STILL_NIL = TA.charDB == nil
    """)
    g = lua.globals()
    check("no guide addon means no extra step-back", bool(g.NO_HOST), False)
    check("mitten defers by default", bool(g.DEFAULT_ON), True)
    check("nil toggle still defers", bool(g.STILL), True)
    check("toggle stores false", bool(g.OFF), False)
    check("opt-out stops the step-back", bool(g.STEPPING), False)
    check("toggle flips back on", bool(g.BACK_ON), True)
    check("mello quest list defers by default", bool(g.MELLO), True)
    check("mello opt-out is per guide", bool(g.MELLO_OFF), False)
    check("toggle does not create charDB", bool(g.NO_CREATE), False)
    check("charDB stays nil", bool(g.STILL_NIL), True)

    lua.execute(read("Core/Utils.lua"))
    lua.execute(r"""
        C_AddOns = { IsAddOnLoaded = function() return false end }
        loaded = {}
        ZYGOR = TA.Utils.DeferToZygor()
        OTHER = TA.Utils.DeferToOtherGuides()
    """)
    g = lua.globals()
    check("utils zygor stays off with nothing loaded", bool(g.ZYGOR), False)
    check("utils other-guides stays off with nothing loaded", bool(g.OTHER), False)


def test_minimap_and_context_action():
    lua = fresh()
    lua.execute(r"""
        TA.db = { minimap = { minimized = false, position = 45 }, useUnifiedUI = true }
        NO_LIB = TA.AddonBridge:TryLibDBIcon()
        REGISTERED = nil
        LibStub = setmetatable({ libs = {} }, {
            __call = function(_, major, silent)
                if major ~= "LibDBIcon-1.0" then return nil end
                return {
                    Register = function(_, name, obj, db)
                        REGISTERED = { name = name, obj = obj, db = db }
                    end,
                    Refresh = function() REFRESHED = (REFRESHED or 0) + 1 end,
                }
            end,
        })
        USED = TA.AddonBridge:TryLibDBIcon()
        POS = TA.db.minimap.position
        MIN = TA.db.minimap.minimized
        REG_NAME = REGISTERED and REGISTERED.name
        REGISTERED.obj.OnTooltipShow({
            AddLine = function(_, text) TIP = text end,
            ClearLines = function() TIP_CLEARED = true end,
            SetText = function() TIP_SET = true end,
        })
        TOGGLED = 0
        REGISTERED.obj.OnClick(nil, "LeftButton")
        CLICKS = TOGGLED
        BOOM = false
        LibStub = setmetatable({}, { __call = function() error("missing") end })
        TA.minimapBtn = nil
        local ok, used = pcall(function() return TA.AddonBridge:TryLibDBIcon() end)
        BOOM = not ok
        USED_BOOM = used
    """)
    g = lua.globals()
    check("no libdbicon means no registration", bool(g.NO_LIB), False)
    check("libdbicon registers ToonAge", bool(g.USED), True)
    check("saved minimap angle is untouched", int(g.POS), 45)
    check("saved minimap minimized flag is untouched", bool(g.MIN), False)
    check("registration name", g.REG_NAME, "ToonAge")
    check("minimap tooltip is append-only", g.TIP, "ToonAge")
    check("minimap tooltip was not cleared", g.TIP_CLEARED == None, True)
    check("minimap tooltip was not set", g.TIP_SET == None, True)
    check("left click still opens the panel", int(g.CLICKS), 1)
    check("a throwing libstub does not escape", bool(g.BOOM), False)
    check("a throwing libstub falls back", bool(g.USED_BOOM), False)

    lua.execute(read("Modules/Infrastructure/ContextAction.lua"))
    lua.execute(r"""
        UIParent = {}
        local bar = {}
        local btn = {
            parent = bar,
            GetParent = function(self) return self.parent end,
            SetParent = function(self, parent) self.parent = parent; self.reparented = true end,
        }
        InCombatLockdown = function() return false end
        ToonAge.ContextAction:KeepIndependent(btn)
        PARENT_OK = btn.parent == UIParent
        MOVED = btn.reparented == true
        btn.parent = UIParent
        btn.reparented = false
        ToonAge.ContextAction:KeepIndependent(btn)
        QUIET = btn.reparented ~= true
    """)
    g = lua.globals()
    check("context action leaves a host bar", bool(g.PARENT_OK), True)
    check("context action reparents once", bool(g.MOVED), True)
    check("context action stays put on UIParent", bool(g.QUIET), True)


def test_sources_and_tocs():
    bridge = read("Modules/Infrastructure/AddonBridge.lua")
    for bad in ("ActionButton_ShowOverlayGlow", "LibCustomGlow", "hooksecurefunc",
                "ClearLines", "SetVertexColor", "ElvUI.media"):
        check(f"bridge source has no {bad}", bad in bridge, False)
    append = bridge[bridge.index("function B:AppendTooltip"):bridge.index("function B:DrawReport")]
    for bad in ("ClearLines", "SetText", "SetOwner"):
        check(f"tooltip append has no {bad}", bad in append, False)
    check("bridge wraps checks with pcall", "pcall" in bridge, True)
    check("bridge goes through Compat", "TA.Compat" in bridge, True)

    minimap = read("Core/MinimapButton.lua")
    init = minimap[minimap.index("function TA:InitMinimap"):]
    create_at = init.index('CreateFrame("Button", "ToonAgeMinimapButton", Minimap)')
    try_at = init.index("TryLibDBIcon")
    check("blizzard minimap button remains", create_at > 0, True)
    check("libdbicon is attempted first", try_at < create_at, True)

    button = read("Modules/Infrastructure/ContextAction.lua")
    check("context action drag is unchanged", 'RegisterForDrag("LeftButton")' in button, True)
    check("context action still moves itself", "StartMoving" in button, True)
    check("context action names no bar addon",
          ("Bartender" in button or "Dominos" in button or "ElvUI" in button), False)

    utils = read("Core/Utils.lua")
    check("other-guide deferral lives next to zygor", "function U.DeferToOtherGuides" in utils, True)

    for rel, needle in (
        ("Modules/Navigation/QuestTracker.lua", "function QT:HandleAutoQuest"),
        ("Modules/Gear/AutoEquip.lua", "local function ShouldAutoEquip"),
        ("Modules/TBC/AutoEquip.lua", "local function ShouldAutoEquip"),
        ("Modules/Navigation/Arrow.lua", "function Arrow:Tick"),
        ("Modules/Automation/AutoQuest.lua", "local function ShouldAct"),
        ("Modules/Mists/QuestTracker.lua", "function QT:HandleAutoQuest"),
        ("Modules/Mists/AutoEquip.lua", "local function ShouldAutoEquip"),
        ("Modules/Mists/Arrow.lua", "function Arrow:Tick"),
    ):
        body = read(rel)
        at = body.index(needle)
        window = body[at:at + 900]
        check(f"{rel} still defers to zygor", "DeferToZygor" in window, True)
        check(f"{rel} defers to the other guides", "DeferToOtherGuides" in window, True)

    mists_gear = read("Modules/Mists/Gear.lua")
    check("mists item name is not rewritten on a host tooltip",
          "HostOwnsTooltip" in mists_gear, True)

    settings = read("Modules/Infrastructure/Settings.lua")
    check("settings draws the detection report", "DrawReport" in settings, True)
    check("settings stores the mitten toggle", "deferToMittenQuest" in settings, True)
    check("settings stores the mello quest toggle", "deferToMelloQuestList" in settings, True)
    keys = settings.split("PROFILE_KEYS")[1]
    check("profile export keeps the zygor key", "tracker.deferToZygor" in keys[:800], True)
    check("profile export keeps the new guide keys",
          "tracker.deferToMittenQuest" in keys and "tracker.deferToMelloQuestList" in keys, True)

    mists_settings = read("Modules/Mists/Settings.lua")
    check("mists settings draws the detection report", "DrawReport" in mists_settings, True)
    check("mists settings has the guide toggles", "deferToMittenQuest" in mists_settings, True)

    harness = read("Modules/Infrastructure/TestHarness.lua")
    check("self-test has an addon bridge suite", 'id = "bridge"' in harness, True)

    init = read("Core/Init.lua")
    check("addon bridge is not engine-exempt",
          "AddonBridge = true" in init[init.index("local ENGINE_MODULES"):init.index("local SAFE_MODE_KEEP")],
          False)

    for toc in sorted(ROOT.glob("ToonAge*.toc")):
        text = toc.read_text(encoding="utf-8")
        check(f"{toc.name} loads AddonBridge", "Modules\\Infrastructure\\AddonBridge.lua" in text, True)
        if "TestHarness.lua" in text:
            check(f"{toc.name} loads the bridge before the self-test",
                  text.index("AddonBridge.lua") < text.index("TestHarness.lua"), True)


def main():
    test_catalog_and_standalone()
    test_detection_never_throws()
    test_tooltip_append_only()
    test_restock_readonly()
    test_guide_toggles()
    test_minimap_and_context_action()
    test_sources_and_tocs()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print(f"{passed}/{total} passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
