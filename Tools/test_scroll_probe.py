#!/usr/bin/env python3
"""Forever Settings > Debug Scroll Probe is read-only and Forever-only.

The button lives in the shared Settings sidebar, but the probe file loads
from ToonAge_Camelot.toc only. The report is built through Core/Compat/API.lua
(HasAPI + pcall). Setter APIs are typed and never called.

Usage:  python3 Tools/test_scroll_probe.py [-v]
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

PROBE = "Modules/Forever/ScrollProbe.lua"
API_NAMES = (
    "C_Map.SetUserWaypoint",
    "C_Map.CanSetUserWaypointOnMap",
    "C_SuperTrack.SetSuperTrackedUserWaypoint",
    "C_Map.GetBestMapForUnit",
    "C_Map.GetPlayerMapPosition",
    "GetItemCount",
    "C_Item.GetItemCount",
    "C_Container.GetItemCount",
)
IDS = ("1296017", "1302508", "1310041", "97286", "3012", "17056")
FORBIDDEN = (
    "SetUserWaypoint(",
    "SetSuperTrackedUserWaypoint(",
    "CastSpell",
    "UseItem",
    "RunMacro",
    "loadstring",
)


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")
    return ok


def finish():
    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if _results and passed == len(_results) else 1


def listed_in(toc_name):
    text = (ROOT / toc_name).read_text(encoding="utf-8")
    return "ScrollProbe.lua" in text


def test_static(src):
    for api in API_NAMES:
        check(f"probe names {api}", api in src, True)
    for spell_id in IDS:
        check(f"probe names id {spell_id}", spell_id in src, True)
    for bad in FORBIDDEN:
        check(f"probe has no {bad}", bad not in src, True)
    check("probe uses the copy window", "ShowCopyWindow" in src, True)
    check("probe goes through Compat", "TA.Compat" in src, True)
    check("header text is in the probe", "ToonAge Scroll Probe (read-only)" in src, True)

    for toc in sorted(ROOT.glob("ToonAge*.toc")):
        if toc.name == "ToonAge_Camelot.toc":
            check("Camelot TOC lists the probe", listed_in(toc.name), True)
        else:
            check(f"{toc.name} does not list the probe", listed_in(toc.name), False)

    settings = (ROOT / "Modules/Infrastructure/Settings.lua").read_text(encoding="utf-8")
    debug = settings.split('AddHdr("DEBUG")', 1)[1].split('AddHdr("SYSTEM")', 1)[0]
    check("Debug section has a Scroll Probe button", 'AddBtn("Scroll Probe"' in debug, True)
    check("Debug button is gated on the Forever probe", "TA.ScrollProbe" in debug and "IsForever" in debug, True)

    compat = (ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8")
    check("Compat guards probe calls with HasAPI", "function C.ProbeType" in compat and "HasAPI" in compat, True)
    for bad in ("SetUserWaypoint(", "SetSuperTrackedUserWaypoint("):
        check(f"Compat does not call {bad}", bad not in compat, True)


BASE = r"""
ToonAge = { modules = {}, IsForever = true, flavor = "forever" }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:HasAPI(path) return missing[path] ~= true end
missing = {}
calls = { set = 0, can = 0, super = 0, pos = 0, build = 0, container = 0 }
function date() return "Thu Nov 12 04:15:00 2026" end
function GetBuildInfo()
    calls.build = calls.build + 1
    return "1.60.1", "70888", "Nov 11 2026", 16001, "enUS"
end
C_Map = {
    SetUserWaypoint = function() calls.set = calls.set + 1; error("setter") end,
    CanSetUserWaypointOnMap = function() calls.can = calls.can + 1; error("query") end,
    GetBestMapForUnit = function(unit)
        if unit ~= "player" then error("unit") end
        return 1454
    end,
    GetPlayerMapPosition = function(mapID, unit)
        calls.pos = calls.pos + 1
        if mapID ~= 1454 or unit ~= "player" then error("pos args") end
        return { x = 0.5, y = 0.25 }
    end,
}
C_SuperTrack = nil
function IsSpellKnown(id) return id == 1296017 end
function IsPlayerSpell(id) return id == 1302508 end
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 97286 end }
function IsQuestFlaggedCompleted() error("quest boom") end
C_SkillInfo = {
    GetSkillLineInfoByID = function(id)
        if id ~= 3012 then error("skill id") end
        return { name = "Comprehension", rank = 4, maxRank = 75 }
    end,
}
C_Item = { GetItemCount = function(id, bank) banks.citem = bank; banks.citemId = id; return 3 end }
C_Container = { GetItemCount = function(id, bank) calls.container = calls.container + 1; banks.container = bank; banks.containerId = id; return 5 end }
function GetItemCount(id, bank) banks.plain = bank; banks.plainId = id; return 4 end
banks = {}
"""


def boot(extra=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BASE)
    if extra:
        lua.execute(extra)
    lua.execute((ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / PROBE).read_text(encoding="utf-8"))
    return lua


def report_of(lua):
    return lua.eval("ToonAge.ScrollProbe:Report()")


def test_report_shape():
    lua = boot()
    text = report_of(lua)
    check("header names the probe and the date() stamp",
          text.splitlines()[0],
          "ToonAge Scroll Probe (read-only)  Thu Nov 12 04:15:00 2026")
    check("build line keeps every GetBuildInfo return",
          "version=\"1.60.1\"" in text and "build=\"70888\"" in text
          and "date=\"Nov 11 2026\"" in text and "interface=16001" in text
          and "extra1=\"enUS\"" in text, True)
    for api, kind in (
        ("C_Map.SetUserWaypoint", "MISSING"),  # HasAPI false in the next test; here it is a function
        ("C_Map.CanSetUserWaypointOnMap", "function"),
        ("C_SuperTrack.SetSuperTrackedUserWaypoint", "MISSING"),
        ("C_Map.GetBestMapForUnit", "function"),
        ("C_Map.GetPlayerMapPosition", "function"),
        ("GetItemCount", "function"),
        ("C_Item.GetItemCount", "function"),
        ("C_Container.GetItemCount", "function"),
    ):
        if api == "C_Map.SetUserWaypoint":
            check("setter type is function when the API exists", f"type {api}: function" in text, True)
        else:
            check(f"type {api} is {kind}", f"type {api}: {kind}" in text, True)
    check("uiMapID is the player map", "uiMapID C_Map.GetBestMapForUnit(\"player\"): 1454" in text, True)
    check("position prints 4 decimals and 0-100",
          "0.5000, 0.2500 (50.0, 25.0)" in text, True)
    check("Comprehend Scroll known via IsSpellKnown",
          "IsSpellKnown(1296017) Comprehend Scroll: true" in text, True)
    check("Study known via IsPlayerSpell",
          "IsPlayerSpell(1302508) Study: true" in text, True)
    check("Research known is false on both",
          "IsSpellKnown(1310041) Research: false" in text
          and "IsPlayerSpell(1310041) Research: false" in text, True)
    check("quest namespace result is labeled",
          "C_QuestLog.IsQuestFlaggedCompleted(97286) Research Access: true" in text, True)
    check("quest global error is labeled and does not drop the namespace line",
          "IsQuestFlaggedCompleted(97286) Research Access: ERROR:" in text
          and "quest boom" in text, True)
    check("comprehension rank and max rank",
          "rank: 4" in text and "maxRank: 75" in text, True)
    check("comprehension raw fields",
          'name="Comprehension"' in text and "rank=4" in text and "maxRank=75" in text, True)
    check("each bag counter is labeled",
          "C_Item.GetItemCount Light Feather 17056" in text
          and "C_Container.GetItemCount Light Feather 17056" in text
          and "GetItemCount Light Feather 17056" in text, True)
    check("bag counts stay distinct",
          ": 3" in text and ": 5" in text and ": 4" in text, True)
    banks = lua.globals().banks
    check("C_Item count is bags only", banks.citem is False and banks.citemId == 17056, True)
    check("C_Container count is bags only", banks.container is False and banks.containerId == 17056, True)
    check("global count is bags only", banks.plain is False and banks.plainId == 17056, True)
    calls = lua.globals().calls
    check("SetUserWaypoint was not called", calls.set, 0)
    check("CanSetUserWaypointOnMap was not called", calls.can, 0)
    check("position was read once", calls.pos, 1)

    lua.execute(r"""
        shownTitle = nil
        shownText = nil
        function ToonAge:ShowCopyWindow(title, body)
            shownTitle = title
            shownText = body
        end
        ToonAge.ScrollProbe:Open()
    """)
    g = lua.globals()
    check("Open uses ShowCopyWindow", g.shownTitle, "ToonAge Scroll Probe")
    check("window text is the report", g.shownText, text)


def test_guards_and_edges():
    lua = boot(r"""
        missing["C_Map.SetUserWaypoint"] = true
        missing["C_Container.GetItemCount"] = true
        GetBuildInfo = function() calls.build = calls.build + 1; error("build broke") end
        C_Map.GetPlayerMapPosition = function() calls.pos = calls.pos + 1; return nil end
    """)
    text = report_of(lua)
    check("HasAPI miss is MISSING and the setter is not called",
          "type C_Map.SetUserWaypoint: MISSING" in text and lua.globals().calls.set == 0, True)
    check("HasAPI miss does not call C_Container.GetItemCount",
          "C_Container.GetItemCount Light Feather 17056: MISSING" in text
          and lua.globals().calls.container == 0, True)
    check("a build error stays on its own line", "Client build: ERROR:" in text and "build broke" in text, True)
    check("skill line still reports after the build error", "rank: 4" in text, True)
    check("nil position prints nil", "player x,y C_Map.GetPlayerMapPosition(1454, \"player\"): nil" in text, True)
    check("nil position still invoked the reader", lua.globals().calls.pos, 1)

    lua = boot(r"""
        C_Map.GetBestMapForUnit = function() return nil end
        C_Map.GetPlayerMapPosition = function() calls.pos = calls.pos + 1; error("no map") end
        IsPlayerSpell = nil
    """)
    text = report_of(lua)
    check("nil uiMapID prints nil", 'uiMapID C_Map.GetBestMapForUnit("player"): nil' in text, True)
    check("position is not called without a map id", lua.globals().calls.pos, 0)
    check("missing IsPlayerSpell is MISSING",
          "IsPlayerSpell(1296017) Comprehend Scroll: MISSING" in text, True)
    check("IsSpellKnown still reports when IsPlayerSpell is missing",
          "IsSpellKnown(1296017) Comprehend Scroll: true" in text, True)

    lua = boot(r"""
        ToonAge.IsForever = false
        ToonAge.flavor = "retail"
    """)
    text = report_of(lua)
    check("non-Forever report does not read the client", lua.globals().calls.build, 0)
    check("non-Forever report says why", "Forever" in text, True)
    check("non-Forever report keeps the header",
          text.startswith("ToonAge Scroll Probe (read-only)"), True)


def main():
    path = ROOT / PROBE
    check("probe file exists", path.is_file(), True)
    if not path.is_file():
        return finish()
    src = path.read_text(encoding="utf-8")
    test_static(src)
    if "function M:Report" not in src or "function C.ProbeType" not in (
            ROOT / "Core/Compat/API.lua").read_text(encoding="utf-8"):
        check("probe report and Compat guard are implemented", False, True)
        return finish()
    test_report_shape()
    test_guards_and_edges()
    return finish()


if __name__ == "__main__":
    sys.exit(main())
