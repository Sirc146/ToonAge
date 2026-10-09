#!/usr/bin/env python3
"""Retail Chromie Time guide selection, without a WoW client.

The active timeline comes from UnitChromieTimeID and the options list.
A missing API is no timeline, which selects the current expansion intro.
A timeline with no guide shows the empty card and the zones we do have.
Classic flavors never consult the API. Level brackets are not eligibility.
"""

import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


src = read("Modules/Navigation/ChromieTime.lua")
qt = read("Modules/Navigation/QuestTracker.lua")
ui = read("Core/UI.lua")
harness = read("Modules/Infrastructure/TestHarness.lua")

lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute("ToonAge = { flavor = 'retail' }")
lua.execute(src)

chunk = r"""
local M = ToonAge.Chromie
local fail = {}
local function eq(name, got, want)
    if got ~= want then
        fail[#fail + 1] = name .. " got=" .. tostring(got) .. " want=" .. tostring(want)
    end
end

local guides = {
    midnight_intro = { id = "midnight_intro", title = "Midnight: Quel'Thalas Intro", expansion = "midnight" },
    eversong = { id = "midnight_eversong_campaign", title = "Midnight: Eversong Woods", expansion = "midnight" },
    legion = { id = "Legion", title = "Legion", expansion = "legion", steps = {} },
    wrath = { id = "WrathOfTheLichKing", title = "Wrath", expansion = "wrath" },
    df = { id = "Dragonflight", title = "Dragonflight", expansion = "dragonflight" },
}
local expansions = {
    { key = "midnight", label = "Midnight" },
    { key = "legion", label = "Legion" },
    { key = "wrath", label = "Wrath of the Lich King" },
    { key = "dragonflight", label = "Dragonflight" },
    { key = "warwithin", label = "The War Within" },
}
local options = {
    { id = 10, name = "The Legion Invasion", recommended = false, alreadyOn = true },
    { id = 7, name = "Fall of the Lich King", recommended = true, alreadyOn = false },
    { id = 16, name = "Dragonflight", recommended = false, alreadyOn = false, completed = true },
}

eq("classic is skipped", M.Read("mists", 10, options).skipped, true)
eq("tbc is skipped", M.Read("tbc", 10, options).skipped, true)
eq("vanilla is skipped", M.Read("vanilla", 10, options).skipped, true)
eq("forever is skipped", M.Read("forever", 10, options).skipped, true)

local none = M.Read("retail", nil, nil)
eq("missing id is no timeline", none.active, false)
eq("missing id is the intro", none.intro, true)
eq("missing id keeps the intro key", none.guideKey, "midnight")

local zero = M.Read("retail", 0, options)
eq("id 0 is no timeline", zero.active, false)
eq("id 0 is the intro", zero.intro, true)
eq("id 0 still records eligibility", #zero.eligible, 3)
local recommended = nil
for _, opt in ipairs(zero.eligible) do
    if opt.recommended then recommended = opt.guideKey end
end
eq("recommended comes from the API", recommended, "wrath")

local legion = M.Read("retail", 10, options)
eq("legion is active", legion.active, true)
eq("legion uses the API name", legion.name, "The Legion Invasion")
eq("legion maps to the guide key", legion.guideKey, "legion")
local legionSet = M.Resolve(legion, guides)
eq("legion has a guide set", legionSet.mode, "timeline")
eq("legion selects legion", legionSet.key, "legion")
eq("legion header is the timeline name", legionSet.header, "The Legion Invasion")

local df = M.Read("retail", 16, options)
eq("dragonflight id maps", df.guideKey, "dragonflight")
local dfSet = M.Resolve(df, guides)
eq("dragonflight guides are used", dfSet.mode, "timeline")
eq("dragonflight header is the API name", dfSet.header, "Dragonflight")

local guidesNoDf = {
    midnight_intro = guides.midnight_intro,
    eversong = guides.eversong,
    legion = guides.legion,
}
local gap = M.Resolve(df, guidesNoDf)
eq("a timeline with no guide is a gap", gap.mode, "missing")
eq("a gap does not substitute another key", gap.key, nil)
eq("a gap names the timeline", gap.header, "Dragonflight")
eq("a gap card names the timeline", gap.cardTitle, "No guide for Dragonflight yet")
eq("a gap offers the zones we have", gap.cardBody, "These are the zones we do have.")

local unknown = M.Read("retail", 99, options)
eq("unknown id has no guide key", unknown.guideKey, nil)
eq("unknown id stays active", unknown.active, true)
local unknownSet = M.Resolve(unknown, guides)
eq("unknown id is a gap", unknownSet.mode, "missing")
eq("unknown id does not invent a key", unknownSet.key, nil)

local intro = M.Resolve(none, guides)
eq("no timeline opens the intro", intro.mode, "intro")
eq("intro key is midnight", intro.key, "midnight")
eq("intro header", intro.header, "Midnight intro")
eq("only the intro guide counts", M.IsIntroGuide(guides.midnight_intro), true)
eq("a midnight zone is not the intro", M.IsIntroGuide(guides.eversong), false)
eq("header says no timeline", M.HeaderLine(none), "No timeline")
eq("header says the timeline name", M.HeaderLine(legion), "The Legion Invasion")

local bare = {}
for _, zone in ipairs(M.ZonesWeHave(guidesNoDf, expansions)) do
    bare[#bare + 1] = zone.key
end
eq("offers midnight", bare[1], "midnight")
eq("offers legion", bare[2], "legion")
eq("does not offer the empty timeline", bare[3], nil)

local noIntro = M.Resolve(none, { legion = guides.legion })
eq("missing intro is a gap", noIntro.mode, "missing")
eq("missing intro does not point at legion", noIntro.key, nil)

local function boom() error("nope") end
local failed, api = M.FromApi("retail", boom, function() return options end)
eq("a throwing id function is no timeline", failed.active, false)
eq("a throwing id function still saw the API", api, true)
eq("that result is the intro", failed.intro, true)

local absent, absentApi = M.FromApi("retail", nil, nil)
eq("no functions is no timeline", absent.intro, true)
eq("no functions reports the API absent", absentApi, false)
eq("absent status", M.Status(absent, false), "Chromie Time: API absent, no timeline")
eq("none status", M.Status(none, true), "Chromie Time: no timeline")
eq("active status names the timeline", M.Status(legion, true), "Chromie Time: The Legion Invasion (id 10)")

local skipped = M.FromApi("mists", function() return 10 end, function() return options end)
eq("classic FromApi does not read the id", skipped.skipped, true)
eq("classic status", M.Status(skipped, true), "Chromie Time skipped (not Retail)")

if #fail > 0 then
    return table.concat(fail, "\n")
end
return ""
"""
errors = lua.execute(chunk)
check("timeline selection", errors, "")

check("calls UnitChromieTimeID", "UnitChromieTimeID" in src, True)
check("passes the player unit", '"player"' in src, True)
check("calls the options API", "C_ChromieTime.GetChromieTimeExpansionOptions" in src, True)
check("does not select a timeline", "SelectChromieTimeOption" not in src, True)
check("does not use the singular option API",
      re.search(r"GetChromieTimeExpansionOption(?!s)", src) is None, True)
check("does not read the player level", "UnitLevel" not in src, True)
check("names the open event", "CHROMIE_TIME_OPEN" in src, True)
check("names the close event", "CHROMIE_TIME_CLOSE" in src, True)

check("picker syncs the timeline", "function QT:SyncTimeline" in qt, True)
check("picker refreshes when chromie opens", 'TA:RegisterEvent("CHROMIE_TIME_OPEN")' in qt, True)
check("picker refreshes when chromie closes", 'TA:RegisterEvent("CHROMIE_TIME_CLOSE")' in qt, True)
check("level up re-reads the timeline", 'event == "PLAYER_LEVEL_UP" then self:SyncTimeline(true)' in qt, True)
check("open and close re-read the timeline", 'event == "CHROMIE_TIME_OPEN" or event == "CHROMIE_TIME_CLOSE"' in qt, True)
check("no singular option call",
      re.search(r"GetChromieTimeExpansionOption(?!s)", qt) is None, True)
detect = qt[qt.index("function QT:DetectBestExpansion"):qt.index("function QT:Render")]
check("picker does not use a level ladder", "playerLevel" not in detect and "UnitLevel" not in detect, True)
check("guide keys match the data", 'key = "dragonflight"' in qt and 'key = "wrath"' in qt, True)
check("empty card offers zones", "These are the zones we do have." in qt, True)
check("retail only registration", 'TA.flavor == "retail"' in qt, True)

guide = ui[ui.index("guide = {"):ui.index("character = {")]
check("guide tab refreshes on open", "CHROMIE_TIME_OPEN = true" in guide, True)
check("guide tab refreshes on close", "CHROMIE_TIME_CLOSE = true" in guide, True)

check("self-test skips classic", "Chromie Time skipped (not Retail)" in harness, True)
check("self-test records the id function", "UnitChromieTimeID " in harness, True)
check("self-test does not literal-scan the options API",
      "C_ChromieTime.GetChromieTimeExpansionOptions" not in harness, True)

for toc, want in (
    ("ToonAge_Mainline.toc", True),
    ("ToonAge.toc", True),
    ("ToonAge_Mists.toc", False),
    ("ToonAge_TBC.toc", False),
    ("ToonAge_Vanilla.toc", False),
    ("ToonAge_Camelot.toc", False),
):
    listed = "Modules\\Navigation\\ChromieTime.lua" in read(toc)
    check(f"{toc} lists Chromie Time", listed, want)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
