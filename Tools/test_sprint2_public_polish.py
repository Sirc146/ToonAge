#!/usr/bin/env python3
"""Tests for Sprint 2 Cross-Flavor Public Polish:
1. Reputation-style Professions layout (Modules/Character/ProfessionBoard.lua)
   - Primary Professions & Secondary Skills grouping
   - Single-row L:StatBar alignment with %, tier badges (Expert/Journeyman/Scaled/CAPPED), and rank/max
   - FormatGatherBreakdown omits zero counts (no '0 herbs · 0 ore ·...' truncation)
   - Suppresses stale 'unverified' banner once live cards are returned
2. Developer Tools gate (Core/UI.lua + Modules/Infrastructure/TestHarness.lua)
   - TA:IsDevMode() defaults to false across all flavors
   - Harvest tab hidden when devMode=false, shown immediately on TA:SetDevMode(true)
   - Self-test title-bar button hidden when devMode=false, shown on SetDevMode(true)
3. Flavor-Aware Quick Start card (? button in Core/UI.lua)
   - Distinct 5-bullet Quick Start copy for Forever, Retail, TBC, and Mists
   - TA:ShowQuickStart() opens & toggles ToonAgeQuickStartFrame cleanly
4. Inline Settings state rows (Settings.lua) & -Release scaffold filter (build_flavors.ps1)

Usage:  python3 Tools/test_sprint2_public_polish.py [-v]
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


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def test_profession_board_layout():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = {
        modules = {}, Data = {}, flavor = "forever", IsForever = true, db = {}, charDB = {},
        ProfessionSkills = {
            Collect = function()
                return {
                    reader = "skillinfo",
                    unverified = true,
                    cards = {
                        { name = "Skinning", skillID = 393, rank = 148, max = 225, secondary = false },
                        { name = "Tailoring", skillID = 197, rank = 70, max = 150, secondary = false },
                        { name = "Comprehension", skillID = 3012, rank = 42, max = 110, secondary = true },
                        { name = "Cooking", skillID = 185, rank = 75, max = 75, secondary = true },
                    },
                }
            end,
        },
    }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    ToonAge:RegisterModule("GatherTracker", {
        GetSummary = function() return { total = 2, zones = 1, herbs = 0, ore = 0, skin = 2, hereNodes = 2 } end,
    })
    UnitLevel = function() return 22 end

    _headers = {}
    _statBars = {}
    _paragraphs = {}
    _dataRows = {}
    ToonAge.Layout = {
        C_DIM = { 0.6, 0.6, 0.6 },
        SectionHeader = function(_, _, y, title) _headers[#_headers + 1] = title; return y - 22 end,
        Paragraph = function(_, _, y, text) _paragraphs[#_paragraphs + 1] = text; return y - 16 end,
        Divider = function(_, _, y) return y - 8 end,
        Spacer = function(_, y, h) return y - (h or 6) end,
        StatBar = function(_, _, y, opts) _statBars[#_statBars + 1] = opts; return y - 20 end,
        DataRow = function(_, _, y, opts) _dataRows[#_dataRows + 1] = opts; return y - 20 end,
        Finish = function() end,
    }
    """)
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    r = lua.eval(r"""
    (function()
        local B = ToonAge:GetModule("ProfessionBoard")
        B:Render({}, nil)

        local hasPrimaryHdr, hasSecondaryHdr = false, false
        for _, h in ipairs(_headers) do
            if h == "Primary Professions" then hasPrimaryHdr = true end
            if h == "Secondary Skills" then hasSecondaryHdr = true end
        end

        local hasUnverifiedPara = false
        for _, p in ipairs(_paragraphs) do
            if p:find("unverified until", 1, true) then hasUnverifiedPara = true end
        end

        local barBadges = {}
        local barTexts = {}
        for _, b in ipairs(_statBars) do
            barBadges[b.label] = b.badge
            barTexts[b.label] = b.barText .. "|" .. b.displayText
        end

        local gatherVal = ""
        for _, d in ipairs(_dataRows) do
            if d.label == "Logged nodes" then gatherVal = d.value or "" end
        end

        return {
            hasPrimaryHdr = hasPrimaryHdr,
            hasSecondaryHdr = hasSecondaryHdr,
            hasUnverifiedPara = hasUnverifiedPara,
            barCount = #_statBars,
            skinBadge = barBadges["Skinning"] or "",
            tailorBadge = barBadges["Tailoring"] or "",
            compBadge = barBadges["Comprehension"] or "",
            cookBadge = barBadges["Cooking"] or "",
            skinText = barTexts["Skinning"] or "",
            gatherVal = gatherVal,
        }
    end)()
    """)
    check("ProfessionBoard groups into Primary Professions and Secondary Skills headers",
          (r["hasPrimaryHdr"], r["hasSecondaryHdr"]), (True, True))
    check("ProfessionBoard renders 4 Reputation-style horizontal L:StatBar rows", r["barCount"], 4)
    check("ProfessionBoard badges show Expert, Journeyman, Scaled (Comprehension), and CAPPED (75/75 Cooking)",
          (r["skinBadge"], r["tailorBadge"], r["compBadge"], r["cookBadge"]),
          ("Expert", "Journeyman", "Scaled", "CAPPED"))
    check("Skinning StatBar shows 66% centered barText and 148 / 225 displayText",
          r["skinText"], "66%|148 / 225")
    check("Stale 'unverified until probed' paragraph is hidden once live cards load",
          r["hasUnverifiedPara"], False)
    check("Gathering log omits zero counts ('2 skinned', no truncation)",
          r["gatherVal"], "2 skinned")


def test_dev_mode_and_quick_start():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = {
        modules = {}, Data = {}, flavor = "forever", IsForever = true, version = "2.0.0-dev.1",
        db = {}, charDB = {}, debug = false,
        Utils = { IsSecret = function() return false end, Glyph = function() return "*" end },
    }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    function ToonAge:ModuleAllowed() return true end
    function ToonAge:ProfileTabs()
        return {
            { id = "now", label = "Now", module = "ForeverNow" },
            { id = "character", label = "Character", module = "ForeverCharacter" },
            { id = "harvest", label = "Harvest", module = "DataHarvester" },
        }
    end
    ToonAge:RegisterModule("ForeverNow", {})
    ToonAge:RegisterModule("ForeverCharacter", {})
    ToonAge:RegisterModule("DataHarvester", {})

    STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    UIParent = {}
    UISpecialFrames = {}
    function CreateFrame(kind, name)
        local f = { kind = kind, name = name, _shown = true, _scripts = {}, _text = "" }
        function f:SetSize() end
        function f:SetHeight() end
        function f:SetWidth() end
        function f:SetPoint() end
        function f:ClearAllPoints() end
        function f:SetAllPoints() end
        function f:SetFrameStrata() end
        function f:SetFrameLevel() end
        function f:GetFrameLevel() return 1 end
        function f:SetMovable() end
        function f:EnableMouse() end
        function f:RegisterForDrag() end
        function f:SetBackdrop() end
        function f:SetBackdropColor() end
        function f:SetBackdropBorderColor() end
        function f:Show() self._shown = true end
        function f:Hide() self._shown = false end
        function f:IsShown() return self._shown end
        function f:SetScript(k, fn) self._scripts[k] = fn end
        function f:SetJustifyH() end
        function f:SetWordWrap() end
        function f:SetTextColor() end
        function f:SetFont() end
        function f:SetText(t) self._text = t or "" end
        function f:GetText() return self._text end
        function f:GetStringHeight() return 24 end
        function f:CreateFontString() return CreateFrame("FontString") end
        function f:CreateTexture() return CreateFrame("Texture") end
        if name then _G[name] = f end
        return f
    end
    """)
    lua.execute(read("Core/UI.lua"))
    lua.execute(read("Modules/Infrastructure/TestHarness.lua"))

    r = lua.eval(r"""
    (function()
        -- Dev Mode defaults to false -> harvest tab hidden & Self-test button not shown
        local devDefault = ToonAge:IsDevMode()
        local harvestOff = ToonAge:IsTabAvailable("harvest")
        local nowOn = ToonAge:IsTabAvailable("now")

        ToonAge.UI = CreateFrame("Frame", "MockMainUI")
        local rebuilds = 0
        ToonAge.UI.RebuildTabs = function() rebuilds = rebuilds + 1 end
        ToonAge.TestHarness:SyncTitleButton()
        local btnBeforeDev = (ToonAge.TestHarness.button ~= nil)

        -- Turning Dev Mode ON shows harvest tab, triggers RebuildTabs, and creates/shows Self-test button
        ToonAge:SetDevMode(true)
        local harvestOn = ToonAge:IsTabAvailable("harvest")
        local btnShownOn = ToonAge.TestHarness.button and ToonAge.TestHarness.button:IsShown() or false

        -- Turning Dev Mode OFF hides both again immediately
        ToonAge:SetDevMode(false)
        local harvestOffAgain = ToonAge:IsTabAvailable("harvest")
        local btnShownOff = ToonAge.TestHarness.button and ToonAge.TestHarness.button:IsShown() or false

        -- Flavor-aware Quick Start lines
        local fTitle, fLines = ToonAge.QuickStartLines("forever")
        local tTitle, tLines = ToonAge.QuickStartLines("tbc")
        local mTitle, mLines = ToonAge.QuickStartLines("mists")
        local rTitle, rLines = ToonAge.QuickStartLines("retail")

        -- ShowQuickStart toggles frame open -> closed
        local qs = ToonAge:ShowQuickStart()
        local qsOpen = qs and qs:IsShown() or false
        ToonAge:ShowQuickStart()
        local qsClosed = qs and (not qs:IsShown()) or false

        return {
            devDefault = devDefault, harvestOff = harvestOff, nowOn = nowOn,
            btnBeforeDev = btnBeforeDev, harvestOn = harvestOn, btnShownOn = btnShownOn,
            harvestOffAgain = harvestOffAgain, btnShownOff = btnShownOff, rebuilds = rebuilds,
            fTitle = fTitle, fCount = #fLines, fBlob = table.concat(fLines, " "),
            tTitle = tTitle, mTitle = mTitle, rTitle = rTitle,
            qsOpen = qsOpen, qsClosed = qsClosed,
        }
    end)()
    """)
    check("Developer Tools defaults OFF: Harvest tab hidden, Now tab visible, Self-test button uncreated",
          (r["devDefault"], r["harvestOff"], r["nowOn"], r["btnBeforeDev"]),
          (False, False, True, False))
    check("SetDevMode(true) immediately enables Harvest tab, rebuilds tabs, and shows Self-test button",
          (r["harvestOn"], r["btnShownOn"], r["rebuilds"] >= 1), (True, True, True))
    check("SetDevMode(false) immediately hides Harvest tab and Self-test button",
          (r["harvestOffAgain"], r["btnShownOff"]), (False, False))
    check("QuickStartLines returns tailored 5-bullet guide for Forever (Now, Talents, Dungeon Map Pins, Vendors, Combat HUD)",
          ("Forever" in r["fTitle"], r["fCount"], "Dungeon Map Pins" in r["fBlob"], "Vendors" in r["fBlob"]),
          (True, 5, True, True))
    check("QuickStartLines returns distinct titles for TBC, Mists, and Retail",
          ("TBC" in r["tTitle"], "Mists" in r["mTitle"], "Quick Start" in r["rTitle"]),
          (True, True, True))
    check("ShowQuickStart toggles ToonAgeQuickStartFrame open and closed cleanly",
          (r["qsOpen"], r["qsClosed"]), (True, True))


def test_settings_and_packaging():
    settings_src = read("Modules/Infrastructure/Settings.lua")
    build_src = read("Tools/build_flavors.ps1")
    check("Settings exposes Gear Guide Source inline MakeChoiceRow",
          'MakeChoiceRow(content, y, w, "Gear Guide Source' in settings_src)
    check("Settings exposes Dungeon Quest Map Pins inline MakeChoiceRow",
          'MakeChoiceRow(content, y, w, "Dungeon Quest Map Pins' in settings_src)
    check("Settings exposes cross-flavor Developer Tools toggle",
          'DEVELOPER TOOLS' in settings_src and 'TA:SetDevMode' in settings_src)
    check("build_flavors.ps1 supports -Release switch excluding scaffold flavors",
          '[switch] $Release' in build_src and "$ScaffoldFlavors = @('Classic Era')" in build_src)


def main():
    test_profession_board_layout()
    test_dev_mode_and_quick_start()
    test_settings_and_packaging()

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
