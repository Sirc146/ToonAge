-- ToonAge/Modules/Infrastructure/Settings.lua
-- Unified settings panel rendered as a tab in the main ToonAge frame.
-- Exposes ALL features, toggles, and options in one place so users never
-- need to rely on slash commands.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U = TA.Utils

local Settings = {}
TA:RegisterModule("Settings", Settings)

Settings.frames = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function MakeSection(parent, y, width, title)
    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    hdr:SetText(title)
    hdr:SetTextColor(0.55, 0.40, 0.08, 1)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y - 14)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, y - 14)
    line:SetColorTexture(0.40, 0.32, 0.08, 0.5)

    table.insert(Settings.frames, hdr)
    table.insert(Settings.frames, line)
    return y - 22
end

local function MakeToggleRow(parent, y, width, label, getValue, onToggle)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width - 28, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    row:SetBackdropColor(0.06, 0.06, 0.06, 1)
    row:SetBackdropBorderColor(0.30, 0.25, 0.08, 0.4)

    local indicator = row:CreateTexture(nil, "ARTWORK")
    indicator:SetSize(10, 10)
    indicator:SetPoint("LEFT", row, "LEFT", 6, 0)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    lbl:SetText(label)
    lbl:SetTextColor(0.88, 0.83, 0.65, 1)
    lbl:SetPoint("LEFT", row, "LEFT", 22, 0)

    local statusLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    statusLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    local function Refresh()
        local on = getValue()
        if on then
            indicator:SetColorTexture(0.20, 0.92, 0.40, 1)
            statusLbl:SetText("|cFF4AFF7AON|r")
            row:SetBackdropBorderColor(0.20, 0.60, 0.30, 0.6)
        else
            indicator:SetColorTexture(0.65, 0.20, 0.15, 1)
            statusLbl:SetText("|cFFFF4444OFF|r")
            row:SetBackdropBorderColor(0.30, 0.25, 0.08, 0.4)
        end
    end

    row:SetScript("OnClick", function()
        onToggle()
        Refresh()
    end)
    row:SetScript("OnEnter", function(f)
        f:SetBackdropColor(0.12, 0.10, 0.04, 1)
    end)
    row:SetScript("OnLeave", function(f)
        f:SetBackdropColor(0.06, 0.06, 0.06, 1)
    end)

    Refresh()
    table.insert(Settings.frames, row)
    return y - 26
end

--- A row that cycles through a fixed set of values on click, for settings with
--- more than two states. Mirrors MakeToggleRow's (parent, y, width, ...) -> newY
--- convention so it drops into the same layout flow.
--- @param options table array of { value = string, text = string }
local function MakeChoiceRow(parent, y, width, label, options, getValue, setValue)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width - 28, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    row:SetBackdropColor(0.06, 0.06, 0.06, 1)
    row:SetBackdropBorderColor(0.30, 0.25, 0.08, 0.4)

    local indicator = row:CreateTexture(nil, "ARTWORK")
    indicator:SetSize(10, 10)
    indicator:SetPoint("LEFT", row, "LEFT", 6, 0)
    indicator:SetColorTexture(0.85, 0.70, 0.20, 1)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    lbl:SetText(label)
    lbl:SetTextColor(0.88, 0.83, 0.65, 1)
    lbl:SetPoint("LEFT", row, "LEFT", 22, 0)

    local statusLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    statusLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    local function IndexOf(value)
        for i, opt in ipairs(options) do
            if opt.value == value then
                return i
            end
        end
        return 1
    end

    local function Refresh()
        statusLbl:SetText(options[IndexOf(getValue())].text)
    end

    row:SetScript("OnClick", function()
        -- Wrap round to the first option past the end.
        local nextIdx = (IndexOf(getValue()) % #options) + 1
        setValue(options[nextIdx].value)
        Refresh()
    end)
    row:SetScript("OnEnter", function(f)
        f:SetBackdropColor(0.12, 0.10, 0.04, 1)
    end)
    row:SetScript("OnLeave", function(f)
        f:SetBackdropColor(0.06, 0.06, 0.06, 1)
    end)

    Refresh()
    table.insert(Settings.frames, row)
    return y - 26
end

--- A labeled slider row for numeric settings (scale, opacity, etc.).
--- Mirrors MakeToggleRow's (parent, y, width, ...) -> newY convention.
local function MakeSliderRow(parent, y, width, label, minVal, maxVal, step, getValue, setValue)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    lbl:SetTextColor(0.88, 0.83, 0.65, 1)
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    table.insert(Settings.frames, lbl)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(width - 100, 16)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y - 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    if slider.Low then
        slider.Low:SetText("")
    end
    if slider.High then
        slider.High:SetText("")
    end
    if slider.Text then
        slider.Text:SetText("")
    end
    table.insert(Settings.frames, slider)

    local function Refresh()
        local v = getValue()
        slider:SetValue(v)
        lbl:SetText(label .. "  |cFFFFD100" .. string.format("%.2f", v) .. "|r")
    end

    slider:SetScript("OnValueChanged", function(self, v)
        setValue(v)
        lbl:SetText(label .. "  |cFFFFD100" .. string.format("%.2f", v) .. "|r")
    end)

    Refresh()
    return y - 36
end

local function MakeInfoRow(parent, y, width, label, value)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    lbl:SetText("|cFF8B7040" .. label .. "|r  " .. (value or ""))
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    lbl:SetWidth(width - 28)
    table.insert(Settings.frames, lbl)
    return y - 16
end

-- ── Render ────────────────────────────────────────────────────────────────────

function Settings:Render(content, sidebar)
    -- Clear previous frames
    for _, f in ipairs(self.frames) do
        if f.Hide then
            f:Hide()
        end
        if f.SetParent then
            f:SetParent(nil)
        end
    end
    wipe(self.frames)

    local y = -10
    local w = content:GetWidth()

    -- ═══════════════════════════════════════════════════════════════════
    -- NAVIGATION & HUD
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "NAVIGATION & HUD")

    y = MakeToggleRow(content, y, w, "Navigation Arrow (compass arrow pointing to waypoint)", function()
        local A = TA:GetModule("Arrow")
        return A and A.frame and A.frame:IsVisible()
    end, function()
        local A = TA:GetModule("Arrow")
        if A then
            A:Toggle()
        end
    end)

    y = MakeToggleRow(content, y, w, "NavHud (transparent FarmHud-style overlay with nodes & waypoints)", function()
        local NH = TA:GetModule("NavHud")
        return NH and NH:IsVisible()
    end, function()
        local NH = TA:GetModule("NavHud")
        if NH then
            NH:Toggle()
        end
    end)

    -- NavHud sub-options — FarmHud-style controls, following it as the
    -- reference: scale/opacity sliders plus per-element visibility toggles,
    -- instead of the single on/off switch this used to be limited to.
    -- Wrapped in its own background card (below) so it reads as "these are
    -- NavHud's sub-settings" rather than 9 more rows in the general list.
    local navHudGroupTop = y + 4
    do
        local NH = TA:GetModule("NavHud")
        local function NHGet(key)
            return NH and NH.GetSetting and NH.GetSetting(key)
        end
        local function NHSet(key, v)
            if NH and NH.SetSetting then
                NH.SetSetting(key, v)
            end
            if NH and NH.ApplySettings then
                NH:ApplySettings()
            end
        end

        y = MakeSliderRow(content, y, w, "  NavHud Scale", 0.5, 2.5, 0.1, function()
            return NHGet("scale") or 1.4
        end, function(v)
            NHSet("scale", v)
        end)

        y = MakeSliderRow(content, y, w, "  NavHud Opacity", 0.1, 1.0, 0.05, function()
            return NHGet("opacity") or 0.85
        end, function(v)
            NHSet("opacity", v)
        end)

        y = MakeToggleRow(content, y, w, "  Show Cardinal Points (N/S/E/W)", function()
            return NHGet("showCardinals")
        end, function()
            NHSet("showCardinals", not NHGet("showCardinals"))
        end)

        y = MakeToggleRow(content, y, w, "  Show Coordinates", function()
            return NHGet("showCoords")
        end, function()
            NHSet("showCoords", not NHGet("showCoords"))
        end)

        y = MakeToggleRow(content, y, w, "  Show Distance to Waypoint", function()
            return NHGet("showDistance")
        end, function()
            NHSet("showDistance", not NHGet("showDistance"))
        end)

        y = MakeToggleRow(content, y, w, "  Show Step Description", function()
            return NHGet("showStepText")
        end, function()
            NHSet("showStepText", not NHGet("showStepText"))
        end)

        y = MakeToggleRow(content, y, w, "  Show Proximity Ring", function()
            return NHGet("showRing")
        end, function()
            NHSet("showRing", not NHGet("showRing"))
        end)

        y = MakeToggleRow(content, y, w, "  Show Waypoint Pins", function()
            return NHGet("showPins")
        end, function()
            NHSet("showPins", not NHGet("showPins"))
        end)
    end

    -- Background card behind the NavHud sub-options, drawn at BACKGROUND
    -- layer so the toggle/slider rows (separate Frames) sit on top of it.
    do
        local card = content:CreateTexture(nil, "BACKGROUND")
        card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, navHudGroupTop)
        card:SetPoint("BOTTOMRIGHT", content, "TOPRIGHT", -6, y - 2)
        card:SetColorTexture(1, 0.82, 0, 0.05)
        table.insert(Settings.frames, card)
    end

    y = MakeToggleRow(content, y, w, "World Map Pins (numbered step markers on world map)", function()
        return TA.db and TA.db.modules and TA.db.modules.MapPins ~= false
    end, function()
        if TA.db and TA.db.modules then
            TA.db.modules.MapPins = not TA.db.modules.MapPins
        end
    end)

    y = MakeToggleRow(
        content,
        y,
        w,
        "Travel Route Suggestions (portal/flight suggestions for cross-zone steps)",
        function()
            return TA.db and TA.db.modules and TA.db.modules.TravelRouter ~= false
        end,
        function()
            if TA.db and TA.db.modules then
                TA.db.modules.TravelRouter = not TA.db.modules.TravelRouter
            end
        end
    )

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- QUEST AUTOMATION
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "QUEST AUTOMATION")

    y = MakeToggleRow(content, y, w, "Auto-Accept & Auto-Turn-In (hold Shift to pause)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.autoQuest = not TA.charDB.tracker.autoQuest
        end
    end)

    y = MakeToggleRow(content, y, w, "  └ Only accept quests in active guide (stricter mode)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuestGuideOnly
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.autoQuestGuideOnly = not TA.charDB.tracker.autoQuestGuideOnly
        end
    end)

    y = MakeToggleRow(content, y, w, "Skip Cutscenes Automatically", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.cutsceneSkip
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.cutsceneSkip = not TA.charDB.tracker.cutsceneSkip
        end
    end)

    y = MakeToggleRow(content, y, w, "Auto-Equip Looted Upgrades (hold Shift to pause)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoEquip
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.autoEquip = not TA.charDB.tracker.autoEquip
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- GUIDE DISPLAY
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "GUIDE DISPLAY")

    y = MakeToggleRow(content, y, w, "Show available quests (unstarted quests from guide on map)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.showAvailableQuests
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.showAvailableQuests = not TA.charDB.tracker.showAvailableQuests
        end
    end)

    y = MakeToggleRow(content, y, w, "Use small icons for map pins", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.smallMapPins
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.smallMapPins = not TA.charDB.tracker.smallMapPins
        end
    end)

    y = MakeToggleRow(content, y, w, "Show category as grid (compact guide browser layout)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.showCategoryGrid
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.showCategoryGrid = not TA.charDB.tracker.showCategoryGrid
        end
    end)

    y = MakeToggleRow(content, y, w, "Show category headers in guide browser", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.showCategoryHeaders
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.showCategoryHeaders = not TA.charDB.tracker.showCategoryHeaders
        end
    end)

    y = MakeToggleRow(content, y, w, "Group completed quests together", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.groupCompleted
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.groupCompleted = not TA.charDB.tracker.groupCompleted
        end
    end)

    y = MakeToggleRow(content, y, w, "Group ignored/skipped quests together", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.groupIgnored
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.groupIgnored = not TA.charDB.tracker.groupIgnored
        end
    end)

    y = MakeToggleRow(content, y, w, "Show quest chain tooltip (prerequisite info on hover)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.showQuestChainTooltip
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.showQuestChainTooltip = not TA.charDB.tracker.showQuestChainTooltip
        end
    end)

    y = MakeToggleRow(content, y, w, "Spoiler free (hide quest text/objectives until accepted)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.spoilerFree
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.spoilerFree = not TA.charDB.tracker.spoilerFree
        end
    end)

    y = MakeToggleRow(content, y, w, "Use TomTom waypoints (set waypoints via TomTom if installed)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.useTomTomWaypoints
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.useTomTomWaypoints = not TA.charDB.tracker.useTomTomWaypoints
        end
    end)

    y = MakeToggleRow(content, y, w, "Account-Bound settings (share guide progress across characters)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.accountBound
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.accountBound = not TA.charDB.tracker.accountBound
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- COMBAT & ROTATION
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "COMBAT & ROTATION")

    y = MakeToggleRow(
        content,
        y,
        w,
        "Combat State Tracking (enables 'NEXT' ability highlighting in Rotation tab)",
        function()
            return TA.db and TA.db.modules and TA.db.modules.CombatState ~= false
        end,
        function()
            if TA.db and TA.db.modules then
                TA.db.modules.CombatState = not TA.db.modules.CombatState
            end
        end
    )

    y = MakeToggleRow(content, y, w, "Floating 'Next 3' Prediction Bar (shows next abilities during combat)", function()
        return TA.charDB and TA.charDB.predictBar and TA.charDB.predictBar.visible
    end, function()
        local Rot = TA:GetModule("Rotation")
        if Rot then
            Rot:TogglePredictBar()
        end
    end)

    y = MakeToggleRow(content, y, w, "Nameplate Quest Markers (X on kill targets, ★ on loot targets)", function()
        return TA.db and TA.db.modules and TA.db.modules.NameplateObjectives ~= false
    end, function()
        if TA.db and TA.db.modules then
            TA.db.modules.NameplateObjectives = not (TA.db.modules.NameplateObjectives ~= false)
        end
    end)

    y = MakeToggleRow(content, y, w, "Tooltip Upgrade Scoring (show +% upgrade on item hover)", function()
        return TA.db and TA.db.modules and TA.db.modules.TooltipScorer ~= false
    end, function()
        if TA.db and TA.db.modules then
            TA.db.modules.TooltipScorer = not (TA.db.modules.TooltipScorer ~= false)
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- GEAR & DUNGEONS
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "GEAR & DUNGEONS")

    y = MakeToggleRow(
        content,
        y,
        w,
        "Dungeon Gear Suggestions (shows best upgrade per slot from M+ dungeons)",
        function()
            return TA.db and TA.db.modules and TA.db.modules.DungeonGear ~= false
        end,
        function()
            if TA.db and TA.db.modules then
                TA.db.modules.DungeonGear = not TA.db.modules.DungeonGear
            end
        end
    )

    y = MakeToggleRow(content, y, w, "Gear Sets Auto-Swap (auto-equip sets on spec change or PvP entry)", function()
        return TA.db and TA.db.modules and TA.db.modules.GearSets ~= false
    end, function()
        if TA.db and TA.db.modules then
            TA.db.modules.GearSets = not (TA.db.modules.GearSets ~= false)
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- UI & LAYOUT
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "UI & LAYOUT")

    y = MakeToggleRow(
        content,
        y,
        w,
        "Unified HUD Layout (arrow + tracker in one frame vs. independent windows)",
        function()
            return TA.db and TA.db.useUnifiedUI
        end,
        function()
            if TA.db then
                TA.db.useUnifiedUI = not TA.db.useUnifiedUI
                if TA.ApplyLayout then
                    TA:ApplyLayout()
                end
            end
        end
    )

    y = MakeToggleRow(content, y, w, "Hide Default Blizzard Quest Tracker", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.replaceBlizzTracker
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.replaceBlizzTracker = not TA.charDB.tracker.replaceBlizzTracker
            local QT = TA:GetModule("QuestTracker")
            if QT then
                QT:UpdateBlizzardTrackerVisibility()
            end
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- NEW CHARACTERS (account-wide — governs alts you have not rolled yet)
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "NEW CHARACTERS (account-wide)")

    y = MakeChoiceRow(content, y, w, "On first login", {
        { value = "wizard", text = "|cFFFFD100SETUP WIZARD|r" },
        { value = "inherit", text = "|cFF4AFF7AINHERIT SILENTLY|r" },
        { value = "off", text = "|cFF888780DO NOTHING|r" },
    }, function()
        return (TA.db and TA.db.newCharBehavior) or "wizard"
    end, function(v)
        if TA.db then
            TA.db.newCharBehavior = v
        end
    end)

    y = MakeChoiceRow(content, y, w, "Preset new characters inherit", {
        { value = "auto", text = "|cFF4AFF7AFULL AUTO|r" },
        { value = "manual", text = "|cFFFFD100MANUAL|r" },
    }, function()
        return (TA.db and TA.db.defaultPreset) or "auto"
    end, function(v)
        if TA.db then
            TA.db.defaultPreset = v
        end
    end)

    y = y - 4
    local ncNote = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ncNote:SetFont(STANDARD_TEXT_FONT, 9, "")
    ncNote:SetText(
        "|cFF888780Inherit applies the preset above with no popup — automation, "
            .. "prediction bar and arrow only. Window positions and per-character tuning "
            .. "are not copied. |cFFFFD100/ta onboard|r|cFF888780 runs the wizard on any "
            .. "character on demand.|r"
    )
    ncNote:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y)
    ncNote:SetWidth(w - 28)
    ncNote:SetJustifyH("LEFT")
    table.insert(self.frames, ncNote)
    y = y - 34

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- MODULES (advanced — disable features you don't use)
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "MODULES (toggle features — reload to apply)")

    local moduleList = {
        "NavHud",
        "MapPins",
        "CombatState",
        "DungeonGear",
        "TravelRouter",
        "Onboarding",
        "CutsceneSkip",
        "AutoEquip",
        "GearSets",
        "NameplateObjectives",
        "TooltipScorer",
    }
    for _, modName in ipairs(moduleList) do
        y = MakeToggleRow(content, y, w, modName, function()
            return TA.db and TA.db.modules and TA.db.modules[modName] ~= false
        end, function()
            if TA.db and TA.db.modules then
                TA.db.modules[modName] = not (TA.db.modules[modName] ~= false)
            end
        end)
    end

    y = y - 16

    -- ═══════════════════════════════════════════════════════════════════
    -- INFO / ABOUT
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "MODULE HEALTH")

    local report = TA.GetHealthReport and TA:GetHealthReport() or {}
    local loaded, disabled, errored = 0, 0, 0
    for _, entry in ipairs(report) do
        if entry.status == "loaded" then
            loaded = loaded + 1
        elseif entry.status == "disabled" then
            disabled = disabled + 1
        elseif entry.status == "errored" then
            errored = errored + 1
        end
    end

    y = MakeInfoRow(
        content,
        y,
        w,
        "Status",
        string.format(
            "|cFF4AFF7A%d loaded|r  |cFF888780%d disabled|r  %s",
            loaded,
            disabled,
            errored > 0 and string.format("|cFFFF4444%d errored|r", errored) or ""
        )
    )

    -- Show errored modules with their error messages
    if errored > 0 then
        for _, entry in ipairs(report) do
            if entry.status == "errored" then
                y = MakeInfoRow(
                    content,
                    y,
                    w,
                    "  ✗ " .. entry.name,
                    "|cFFFF4444" .. (entry.error or "unknown") .. "|r"
                )
            end
        end
    end

    y = y - 8
    y = MakeSection(content, y, w, "ABOUT")
    y = MakeInfoRow(content, y, w, "Version", TA.version or "1.0.0")
    y = MakeInfoRow(content, y, w, "Author", "Chris")
    y = MakeInfoRow(
        content,
        y,
        w,
        "Modules",
        string.format("%d total (%d active)", loaded + disabled + errored, loaded)
    )
    y = MakeInfoRow(content, y, w, "Guides loaded", tostring(U.TableLength(TA.Guides or {})))

    y = y - 16
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    note:SetFont(STANDARD_TEXT_FONT, 9, "")
    note:SetText(
        "|cFF888780Settings are saved per-character except where a section says otherwise. Module toggles require /reload to take effect.\nFeature toggles (Arrow, NavHud, Auto-Quest) apply instantly.|r"
    )
    note:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y)
    note:SetWidth(w - 28)
    note:SetJustifyH("LEFT")
    table.insert(self.frames, note)
    y = y - 30

    content:SetHeight(math.abs(y) + 20)

    -- ── Sidebar: quick actions ────────────────────────────────────────
    self:RenderSidebar(sidebar)
end

function Settings:RenderSidebar(parent)
    local y = -8
    local w = parent:GetWidth()

    local function AddBtn(label, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetHeight(26)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.10, 0.08, 0.02, 1)
        btn:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.6)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        lbl:SetText(label)
        lbl:SetTextColor(1, 0.82, 0, 1)
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(f)
            f:SetBackdropColor(0.20, 0.15, 0.04, 1)
        end)
        btn:SetScript("OnLeave", function(f)
            f:SetBackdropColor(0.10, 0.08, 0.02, 1)
        end)
        table.insert(self.frames, btn)
        y = y - 30
    end

    local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    hdr:SetText("QUICK ACTIONS")
    hdr:SetTextColor(0.55, 0.40, 0.08, 1)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    table.insert(self.frames, hdr)
    y = y - 18

    AddBtn("Toggle NavHud", function()
        local NH = TA:GetModule("NavHud")
        if NH then
            NH:Toggle()
        end
    end)

    AddBtn("Toggle Arrow", function()
        local A = TA:GetModule("Arrow")
        if A then
            A:Toggle()
        end
    end)

    AddBtn("Toggle Tracker", function()
        local QT = TA:GetModule("QuestTracker")
        if QT then
            QT:ToggleWindow()
        end
    end)

    AddBtn("Re-sync Guide", function()
        local QT = TA:GetModule("QuestTracker")
        if QT then
            QT:FastForward(false)
        end
    end)

    AddBtn("Auto-Select Guide", function()
        local QT = TA:GetModule("QuestTracker")
        if QT then
            QT:AutoSelectGuide()
        end
    end)

    AddBtn("Dungeon Gear Check", function()
        local DG = TA:GetModule("DungeonGear")
        if DG and DG.SlashCommands and DG.SlashCommands.dungear then
            DG.SlashCommands.dungear(DG)
        end
    end)

    AddBtn("Switch Layout", function()
        if TA.db then
            TA.db.useUnifiedUI = not TA.db.useUnifiedUI
            if TA.ApplyLayout then
                TA:ApplyLayout()
            end
            local mode = TA.db.useUnifiedUI and "Unified HUD" or "Fragmented Windows"
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout: " .. mode)
        end
    end)

    AddBtn("Reset All Settings", function()
        StaticPopup_Show("TOONAGE_RESET_CONFIRM")
    end)

    -- Register static popup for reset confirmation
    if not StaticPopupDialogs["TOONAGE_RESET_CONFIRM"] then
        StaticPopupDialogs["TOONAGE_RESET_CONFIRM"] = {
            text = "Reset all ToonAge settings? This requires a /reload.",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                ToonAgeDB = nil
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
    end

    parent:SetHeight(math.abs(y) + 10)
end

-- ── Init (no-op — renders on demand when tab is selected) ─────────────────────

function Settings:Init() end

Settings.SlashCommands = {}
