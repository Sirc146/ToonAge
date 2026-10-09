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
lua.execute("ToonAge = { flavor = 'retail', GuideData = {} }")
lua.execute(read("Data/Retail/Guides/TAG_Dragonflight_Chromie.lua"))
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
    legion_chromie = { id = "legion_chromie", title = "Legion Chromie", expansion = "legion", steps = {} },
    wrath = { id = "WrathOfTheLichKing", title = "Wrath", expansion = "wrath" },
    df = { id = "Dragonflight", title = "Dragonflight", expansion = "dragonflight" },
    df_chromie = { id = "dragonflight_chromie_campaign", title = "Dragonflight Chromie", expansion = "dragonflight" },
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
eq("legion short name", legion.short, "Legion")
eq("legion maps to the guide key", legion.guideKey, "legion")
eq("pill uses the in-game name", M.PillText(legion), "Chromie Time · The Legion Invasion")
local legionSet = M.Resolve(legion, guides)
eq("a chromie file selects that timeline", legionSet.mode, "timeline")
eq("legion selects legion", legionSet.key, "legion")
eq("legion header is the short name", legionSet.header, "Legion")

local ordinary = {
    midnight_intro = guides.midnight_intro,
    eversong = guides.eversong,
    legion = guides.legion,
    df = guides.df,
}
local ordinarySet = M.Resolve(legion, ordinary)
eq("a regular legion guide is not the timeline guide", ordinarySet.mode, "missing")
eq("coming copy names legion", ordinarySet.cardBody, "Legion timeline guide is coming. Your game is fine.")
eq("card title is the short name", ordinarySet.cardTitle, "Legion")

local df = M.Read("retail", 16, options)
eq("dragonflight id maps", df.guideKey, "dragonflight")
eq("dragonflight short name", df.short, "Dragonflight")
local dfSet = M.Resolve(df, guides)
eq("dragonflight_chromie_campaign is the timeline guide", dfSet.mode, "timeline")
eq("dragonflight header is the short name", dfSet.header, "Dragonflight")
local dfGap = M.Resolve(df, ordinary)
eq("without dragonflight_chromie the card says it is coming", dfGap.mode, "missing")
eq("dragonflight coming copy", dfGap.cardBody, "Dragonflight timeline guide is coming. Your game is fine.")

local guidesNoDf = {
    midnight_intro = guides.midnight_intro,
    eversong = guides.eversong,
    legion = guides.legion,
}
local gap = M.Resolve(df, guidesNoDf)
eq("a timeline with no guide is a gap", gap.mode, "missing")
eq("a gap does not substitute another key", gap.key, nil)
eq("a gap names the timeline", gap.header, "Dragonflight")
eq("a gap card names the timeline", gap.cardTitle, "Dragonflight")
eq("a gap says the guide is coming", gap.cardBody, "Dragonflight timeline guide is coming. Your game is fine.")

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
eq("no pill without a timeline", M.PillText(none) == nil, true)
eq("priority starts with the campaign file", M.GUIDE_PRIORITY[1].id, "dragonflight_chromie_campaign")
eq("priority then legion", M.GUIDE_PRIORITY[2].id, "legion_chromie")
eq("priority then bfa", M.GUIDE_PRIORITY[3].short, "BfA")
eq("priority then shadowlands", M.GUIDE_PRIORITY[4].key, "shadowlands")
eq("regular guide is not a timeline guide", M.IsTimelineGuide(guides.legion, "legion"), false)
eq("chromie file is a timeline guide", M.IsTimelineGuide(guides.legion_chromie, "legion"), true)

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

local campaign = ToonAge.GuideData and ToonAge.GuideData["dragonflight_chromie_campaign"]
eq("campaign file is loaded", type(campaign), "table")
eq("campaign has 1139 steps", campaign and #campaign.steps or 0, 1139)
eq("fourteen unverified steps", M.MarkUnverified(campaign), 14)
local est, decoy = 0, 0
for _, step in ipairs(campaign.steps) do
    if step.estimated then est = est + 1 end
    if step.questID == 77345 and step.type == "accept" and step.estimated then decoy = decoy + 1 end
    if step.questID == 77345 and step.type == "turnin" and step.estimated then decoy = decoy + 10 end
end
eq("only those fourteen are estimated", est, 14)
eq("the other 77345 step stays exact", decoy, 10)

local shores = M.ZoneStartIndex(campaign.steps, M.SKIP_ZONES[1], "Alliance")
local shoresH = M.ZoneStartIndex(campaign.steps, M.SKIP_ZONES[1], "Horde")
eq("alliance lands in the waking shores", type(shores), "number")
eq("horde lands in the waking shores", type(shoresH), "number")
eq("faction changes the shores landing", shores ~= shoresH, true)
eq("thaldraszus lands on the anchor quest", campaign.steps[M.ZoneStartIndex(campaign.steps, M.SKIP_ZONES[4], "Alliance")].questID, 66159)

local skip = M.SkipSteps()
eq("skip starts at 72293", skip[1].questID, 72293)
eq("skip turn-in is 72293", skip[2].questID, 72293)
eq("skip then offers the zone pick", skip[3]._zonePick, true)
eq("zone pick names 72266", M.ZoneByQuest(72266).text, "The Waking Shores")
eq("zone pick names 72269", M.ZoneByQuest(72269).text, "Thaldraszus")
eq("account completion from a table", M.AchievementCompleted({ completed = true }), true)
eq("missing completion is false", M.AchievementCompleted(false), false)
eq("skip card when the account is done", M.ShouldShowSkipCard(M.DF_GUIDE_ID, true, false, false, false), true)
eq("dismissed card stays hidden", M.ShouldShowSkipCard(M.DF_GUIDE_ID, true, true, false, false), false)
eq("card while the skip is already running stays hidden", M.ShouldShowSkipCard(M.DF_GUIDE_ID, true, false, true, false), false)
eq("card on the guide list", M.ShouldShowSkipCard("other", true, false, false, true), true)
eq("no card without the achievement", M.ShouldShowSkipCard(M.DF_GUIDE_ID, false, false, false, true), false)

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
check("empty card names the timeline", "timeline guide is coming. Your game is fine." in src, True)
check("pill is plain text", 'return "Chromie Time · " .. name' in src, True)
check("pill prefers the api name", "local name = timeline.name" in src, True)
check("pill sits to the right of the zone name", 'pill:SetPoint("LEFT", hdr, "RIGHT", 8, 0)' in qt, True)
check("pill text is neutral", 'lab:SetTextColor(0.92, 0.90, 0.87, 1)' in qt, True)
header_fn = qt[qt.index("function QT:DrawZoneHeader"):qt.index("function QT:RenderMiddlePanel")]
check("pill does not use an expansion logo", "SetAtlas" not in header_fn, True)
check("empty card still offers the zones we have", "ZonesWeHave" in qt, True)
check("retail only registration", 'TA.flavor == "retail"' in qt, True)
check("skip button is secondary", 'sl:SetText("Skip campaign")' in qt, True)
check("skip button is not gold", "sl:SetTextColor(1.00, 0.82, 0.00" not in qt, True)
check("mark done stays the primary", 'MakeBtn(win, 108, 22, "Mark Done >"' in qt, True)
check("achievement 16326 gates the card", "M.SKIP_ACHIEVEMENT = 16326" in src, True)
check("skip path starts at 72293", "questID = 72293" in src, True)
check("zone pick includes 72266", "questID = 72266" in src, True)
check("zone pick includes 72269", "questID = 72269" in src, True)
utils = read("Core/Utils.lua")
arrow = read("Modules/Navigation/Arrow.lua")
pins = read("Modules/Navigation/MapPins.lua")
marrow = read("Modules/Mists/Arrow.lua")
mpins = read("Modules/Mists/MapPins.lua")
check("estimated tip is shared", 'U.ESTIMATED_TIP = "Approximate. Not checked yet."' in utils, True)
check("arrow uses the hollow ring", "U.TEX_RING" in arrow and "U.AddEstimatedTip" in arrow, True)
check("pins use the hollow ring", "U.PaintWaypointMark" in pins and "U.AddEstimatedTip" in pins, True)
check("mists arrow uses the same ring", "U.TEX_RING" in marrow and "U.AddEstimatedTip" in marrow, True)
check("mists pins use the same ring", "U.PaintWaypointMark" in mpins and "U.AddEstimatedTip" in mpins, True)
guide_txt = read("Data/Retail/Guides/TAG_Dragonflight_Chromie.lua")
check("guide id is unchanged", 'TA.GuideData["dragonflight_chromie_campaign"]' in guide_txt, True)
check("guide keeps faction tags", 'faction = "Alliance"' in guide_txt and 'faction = "Horde"' in guide_txt, True)
check("guide was not given an estimated field", "estimated = true" not in guide_txt, True)

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
    body = read(toc)
    listed = "Modules\\Navigation\\ChromieTime.lua" in body
    check(f"{toc} lists Chromie Time", listed, want)
    check(f"{toc} lists the campaign guide", "Data\\Retail\\Guides\\TAG_Dragonflight_Chromie.lua" in body, want)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
