-- ToonAge/Modules/Settings.lua
-- Unified settings panel rendered as a tab in the main ToonAge frame.
-- Exposes ALL features, toggles, and options in one place so users never
-- need to rely on slash commands.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

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
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  14, y - 14)
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
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
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
    row:SetScript("OnEnter", function(f) f:SetBackdropColor(0.12, 0.10, 0.04, 1) end)
    row:SetScript("OnLeave", function(f) f:SetBackdropColor(0.06, 0.06, 0.06, 1) end)

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
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
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
            if opt.value == value then return i end
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
    row:SetScript("OnEnter", function(f) f:SetBackdropColor(0.12, 0.10, 0.04, 1) end)
    row:SetScript("OnLeave", function(f) f:SetBackdropColor(0.06, 0.06, 0.06, 1) end)

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
    if slider.Low  then slider.Low:SetText("")  end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end
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

-- ── Which sections this client actually has ───────────────────────────────
--
-- Settings.lua is shared: retail, TBC and Forever all render this same file.
-- Rows for modules a flavour does not ship used to draw anyway -- on Forever
-- that meant toggles for the guide stack, the arrow, dungeon gear and combat
-- state, none of which exist here, several of which silently did nothing when
-- clicked. Deleting them was not an option: retail ships every one.
--
-- So each section asks whether ANY of the modules it controls is actually
-- registered on this client. A module only registers when its file is in the
-- TOC, so this is a fact about the running build rather than a guess about the
-- flavour, and it needs no maintenance when a flavour's module set changes.
local function Has(...)
    if not TA.GetRegisteredModule then return true end   -- can't tell: show, don't hide
    -- Registered and part of this flavor's product -- NOT "currently running".
    -- GetModule returns nil for a module the player switched off, which made its
    -- own toggle row vanish after the reload, leaving only /ta toggle to undo it.
    for i = 1, select("#", ...) do
        local m = TA:GetRegisteredModule((select(i, ...)))
        if m and not m._profileSkipped then return true end
    end
    return false
end

function Settings:Render(content, sidebar)
    -- Clear previous frames
    for _, f in ipairs(self.frames) do
        if f.Hide then f:Hide() end
        if f.SetParent then f:SetParent(nil) end
    end
    wipe(self.frames)

    local y = -10
    local w = content:GetWidth()

    -- Waypoints, HUD and map pins: guide-era navigation, not shipped on every flavour.
    if Has("Arrow", "NavHud", "MapPins", "TravelRouter") then
        -- ═══════════════════════════════════════════════════════════════════
        -- NAVIGATION & HUD
        -- ═══════════════════════════════════════════════════════════════════
        y = MakeSection(content, y, w, "NAVIGATION & HUD")

        y = MakeToggleRow(content, y, w, "Navigation Arrow (compass arrow pointing to waypoint)", function()
            local A = TA:GetModule("Arrow")
            return A and A.frame and A.frame:IsVisible()
        end, function()
            local A = TA:GetModule("Arrow")
            if A then A:Toggle() end
        end)

        y = MakeToggleRow(content, y, w, "NavHud (transparent FarmHud-style overlay with nodes & waypoints)", function()
            local NH = TA:GetModule("NavHud")
            return NH and NH:IsVisible()
        end, function()
            local NH = TA:GetModule("NavHud")
            if NH then NH:Toggle() end
        end)

        -- NavHud sub-options — FarmHud-style controls, following it as the
        -- reference: scale/opacity sliders plus per-element visibility toggles,
        -- instead of the single on/off switch this used to be limited to.
        -- Wrapped in its own background card (below) so it reads as "these are
        -- NavHud's sub-settings" rather than 9 more rows in the general list.
        local navHudGroupTop = y + 4
        do
            local NH = TA:GetModule("NavHud")
            local function NHGet(key) return NH and NH.GetSetting and NH.GetSetting(key) end
            local function NHSet(key, v)
                if NH and NH.SetSetting then NH.SetSetting(key, v) end
                if NH and NH.ApplySettings then NH:ApplySettings() end
            end

            y = MakeSliderRow(content, y, w, "  NavHud Scale", 0.5, 2.5, 0.1,
                function() return NHGet("scale") or 1.4 end,
                function(v) NHSet("scale", v) end)

            y = MakeSliderRow(content, y, w, "  NavHud Opacity", 0.1, 1.0, 0.05,
                function() return NHGet("opacity") or 0.85 end,
                function(v) NHSet("opacity", v) end)

            y = MakeToggleRow(content, y, w, "  Show Cardinal Points (N/S/E/W)", function() return NHGet("showCardinals") end,
                function() NHSet("showCardinals", not NHGet("showCardinals")) end)

            y = MakeToggleRow(content, y, w, "  Show Coordinates", function() return NHGet("showCoords") end,
                function() NHSet("showCoords", not NHGet("showCoords")) end)

            y = MakeToggleRow(content, y, w, "  Show Distance to Waypoint", function() return NHGet("showDistance") end,
                function() NHSet("showDistance", not NHGet("showDistance")) end)

            y = MakeToggleRow(content, y, w, "  Show Step Description", function() return NHGet("showStepText") end,
                function() NHSet("showStepText", not NHGet("showStepText")) end)

            y = MakeToggleRow(content, y, w, "  Show Proximity Ring", function() return NHGet("showRing") end,
                function() NHSet("showRing", not NHGet("showRing")) end)

            y = MakeToggleRow(content, y, w, "  Show Waypoint Pins", function() return NHGet("showPins") end,
                function() NHSet("showPins", not NHGet("showPins")) end)
        end

        -- Background card behind the NavHud sub-options, drawn at BACKGROUND
        -- layer so the toggle/slider rows (separate Frames) sit on top of it.
        do
            local card = content:CreateTexture(nil, "BACKGROUND")
            card:SetPoint("TOPLEFT",     content, "TOPLEFT",  6, navHudGroupTop)
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

        y = MakeToggleRow(content, y, w, "Travel Route Suggestions (portal/flight suggestions for cross-zone steps)", function()
            return TA.db and TA.db.modules and TA.db.modules.TravelRouter ~= false
        end, function()
            if TA.db and TA.db.modules then
                TA.db.modules.TravelRouter = not TA.db.modules.TravelRouter
            end
        end)

        y = y - 8
    end


    -- ═══════════════════════════════════════════════════════════════════
    -- QUEST AUTOMATION
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeToggleRow(content, y, w, "Share anonymous usage stats (only if you run the Wago App)", function()
        return not (TA.db and TA.db.analytics == false)
    end, function()
        if TA.db then TA.db.analytics = (TA.db.analytics == false) end
    end)

    y = y - 8

    -- Quest automation: the protected-action features. Absent from builds that removed them.
    if Has("AutoQuest", "AutoEquip", "QuestTracker", "VendorAssist") then
        y = MakeSection(content, y, w, "QUEST AUTOMATION")

        y = MakeToggleRow(content, y, w, "Let Zygor handle questing, arrow and auto-equip when it's loaded", function()
            local t = TA.charDB and TA.charDB.tracker
            return not (t and t.deferToZygor == false)
        end, function()
            if TA.charDB and TA.charDB.tracker then
                local on = TA.charDB.tracker.deferToZygor ~= false
                TA.charDB.tracker.deferToZygor = not on
            end
        end)

        -- QuestTracker reads tracker.autoRewardPick and its paused message
        -- tells the player to turn this on "in Settings" -- so it must be here.
        if Has("QuestTracker") then
            y = MakeToggleRow(content, y, w, "Auto-pick quest rewards (off = pause on the choice and show the best pick)", function()
                return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoRewardPick == true
            end, function()
                if TA.charDB and TA.charDB.tracker then
                    TA.charDB.tracker.autoRewardPick = not (TA.charDB.tracker.autoRewardPick == true)
                end
            end)
        end

        y = y - 8
    end


    -- Guide display: nothing to display without the guide stack.
    if Has("GuideBrowser", "GuideParser", "QuestTracker", "MapPins") then
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
    end


    if Has("ContextAction") then
        y = MakeSection(content, y, w, "CONTEXT ACTION")
        local CA = TA.ContextAction
        if CA and CA.DrawKeybindRow then
            y = CA:DrawKeybindRow(content, y, w, function(f)
                self.frames[#self.frames + 1] = f
            end)
        end
        y = y - 8
    end

    -- Combat: rotation prediction and nameplate markers.
    if Has("CombatState", "SpecAdaptive", "NameplateObjectives", "TooltipScorer") then
        -- ═══════════════════════════════════════════════════════════════════
        -- COMBAT & ROTATION
        -- ═══════════════════════════════════════════════════════════════════
        y = MakeSection(content, y, w, "COMBAT & ROTATION")

        y = MakeToggleRow(content, y, w, "Combat State Tracking (enables 'NEXT' ability highlighting in Rotation tab)", function()
            return TA.db and TA.db.modules and TA.db.modules.CombatState ~= false
        end, function()
            if TA.db and TA.db.modules then
                TA.db.modules.CombatState = not TA.db.modules.CombatState
            end
        end)

        y = MakeToggleRow(content, y, w, "Floating 'Next 3' Prediction Bar (shows next abilities during combat)", function()
            return TA.charDB and TA.charDB.predictBar and TA.charDB.predictBar.visible
        end, function()
            local Rot = TA:GetModule("Rotation")
            if Rot then Rot:TogglePredictBar() end
        end)

        if Has("ProfessionOverload") then
            y = MakeToggleRow(content, y, w, "Gathering Overload reminder (context action button above the action bars)", function()
                return not (TA.db and TA.db.overloadReminder == false)
            end, function()
                if not TA.db then return end
                local on = not (TA.db.overloadReminder == false)
                TA.db.overloadReminder = not on
                local mod = TA:GetModule("ProfessionOverload")
                if mod and mod.Refresh then mod:Refresh() end
            end)
        end

        y = MakeToggleRow(content, y, w, ("Nameplate Quest Markers (X on kill targets, " .. ToonAge.Utils.Glyph("star") .. " on loot targets)"), function()
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
    end


    -- Gear automation: dungeon suggestions and set swapping.
    if Has("DungeonGear", "GearSets") then
        -- ═══════════════════════════════════════════════════════════════════
        -- GEAR & DUNGEONS
        -- ═══════════════════════════════════════════════════════════════════
        y = MakeSection(content, y, w, "GEAR & DUNGEONS")

        y = MakeToggleRow(content, y, w, "Dungeon Gear Suggestions (shows best upgrade per slot from M+ dungeons)", function()
            return TA.db and TA.db.modules and TA.db.modules.DungeonGear ~= false
        end, function()
            if TA.db and TA.db.modules then
                TA.db.modules.DungeonGear = not TA.db.modules.DungeonGear
            end
        end)

        y = MakeToggleRow(content, y, w, "Gear Sets Auto-Swap (auto-equip sets on spec change or PvP entry)", function()
            return TA.db and TA.db.modules and TA.db.modules.GearSets ~= false
        end, function()
            if TA.db and TA.db.modules then
                TA.db.modules.GearSets = not (TA.db.modules.GearSets ~= false)
            end
        end)

        y = y - 8
    end


    -- Layout: both rows describe the arrow/tracker windows.
    if Has("Arrow", "QuestTracker") then
        -- ═══════════════════════════════════════════════════════════════════
        -- UI & LAYOUT
        -- ═══════════════════════════════════════════════════════════════════
        y = MakeSection(content, y, w, "UI & LAYOUT")

        y = MakeToggleRow(content, y, w, "Unified HUD Layout (arrow + tracker in one frame vs. independent windows)", function()
            return TA.db and TA.db.useUnifiedUI
        end, function()
            if TA.db then
                TA.db.useUnifiedUI = not TA.db.useUnifiedUI
                if TA.ApplyLayout then TA:ApplyLayout() end
            end
        end)

        y = MakeToggleRow(content, y, w, "Hide Default Blizzard Quest Tracker", function()
            return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.replaceBlizzTracker
        end, function()
            if TA.charDB and TA.charDB.tracker then
                TA.charDB.tracker.replaceBlizzTracker = not TA.charDB.tracker.replaceBlizzTracker
                local QT = TA:GetModule("QuestTracker")
                if QT then QT:UpdateBlizzardTrackerVisibility() end
            end
        end)

        y = y - 8
    end


    -- Every row in this section drives the Onboarding module: the first-login
    -- behaviour, the preset it applies, and a button whose whole job is to run
    -- /ta onboard. On a build that does not ship Onboarding the choices save a
    -- setting nothing reads, and the button answers "Unknown command: onboard"
    -- in chat -- which is what it did on Forever.
    if Has("Onboarding") then
        -- ═══════════════════════════════════════════════════════════════════
        -- NEW CHARACTERS (account-wide — governs alts you have not rolled yet)
        -- ═══════════════════════════════════════════════════════════════════
        y = MakeSection(content, y, w, "NEW CHARACTERS (account-wide)")

        y = MakeChoiceRow(content, y, w, "On first login", {
            { value = "wizard",  text = "|cFFFFD100SETUP WIZARD|r" },
            { value = "inherit", text = "|cFF4AFF7AINHERIT SILENTLY|r" },
            { value = "off",     text = "|cFF888780DO NOTHING|r" },
        }, function()
            return (TA.db and TA.db.newCharBehavior) or "wizard"
        end, function(v)
            if TA.db then TA.db.newCharBehavior = v end
        end)

        y = MakeChoiceRow(content, y, w, "Preset new characters inherit", {
            { value = "auto",   text = "|cFF4AFF7AFULL AUTO|r" },
            { value = "manual", text = "|cFFFFD100MANUAL|r" },
        }, function()
            return (TA.db and TA.db.defaultPreset) or "auto"
        end, function(v)
            if TA.db then TA.db.defaultPreset = v end
        end)

        y = y - 4
        local ncNote = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ncNote:SetFont(STANDARD_TEXT_FONT, 9, "")
        ncNote:SetText("|cFF888780Inherit applies the preset above with no popup — automation, "
                     .. "prediction bar and arrow only. Window positions and per-character tuning "
                     .. "are not copied. The button runs the setup wizard on this character now.|r")
        ncNote:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y)
        ncNote:SetWidth(w - 28)
        ncNote:SetJustifyH("LEFT")
        table.insert(self.frames, ncNote)
        y = y - 34

        local wizBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        wizBtn:SetSize(150, 22)
        wizBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y)
        wizBtn:SetText("Run setup wizard")
        wizBtn:SetScript("OnClick", function() TA:SlashCommand("onboard") end)
        table.insert(self.frames, wizBtn)
        y = y - 28

        y = y - 8
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- MODULES (advanced — disable features you don't use)
    -- ═══════════════════════════════════════════════════════════════════
    -- Filtered to what this build registered. The full list is every module
    -- that has ever been toggleable; a toggle for a module the client never
    -- loaded is a switch wired to nothing. The HEADER is drawn only if at least
    -- one survives -- a section title over empty space, which is what Forever
    -- showed, reads as a feature that failed to load.
    local moduleList = {}
    for _, name in ipairs({ "NavHud", "MapPins", "CombatState", "DungeonGear",
                            "TravelRouter", "Onboarding", "GearSets",
                            "NameplateObjectives", "TooltipScorer" }) do
        if Has(name) then moduleList[#moduleList + 1] = name end
    end

    if #moduleList > 0 then
        y = MakeSection(content, y, w, "MODULES (toggle features — reload to apply)")
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
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- INFO / ABOUT
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "MODULE HEALTH")

    local report = TA.GetHealthReport and TA:GetHealthReport() or {}
    local loaded, disabled, errored = 0, 0, 0
    for _, entry in ipairs(report) do
        if entry.status == "loaded" then loaded = loaded + 1
        elseif entry.status == "disabled" then disabled = disabled + 1
        elseif entry.status == "errored" then errored = errored + 1 end
    end

    y = MakeInfoRow(content, y, w, "Status",
        string.format("|cFF4AFF7A%d loaded|r  |cFF888780%d disabled|r  %s",
            loaded, disabled,
            errored > 0 and string.format("|cFFFF4444%d errored|r", errored) or ""))

    -- Show errored modules with their error messages
    if errored > 0 then
        for _, entry in ipairs(report) do
            if entry.status == "errored" then
                y = MakeInfoRow(content, y, w, ("  " .. ToonAge.Utils.Glyph("cross") .. " ") .. entry.name, "|cFFFF4444" .. (entry.error or "unknown") .. "|r")
            end
        end
    end

    -- Module switches, the same list /ta toggle prints. As rows here they can
    -- be clicked; as a list in the copy window they could not (the window
    -- shows plain text, so /ta toggle's links were dead there).
    do
        local names = {}
        for name in pairs((TA.db and TA.db.modules) or {}) do names[#names + 1] = name end
        table.sort(names)
        if #names > 0 then
            y = y - 8
            y = MakeSection(content, y, w, "MODULES (reload to apply)")
            for _, name in ipairs(names) do
                y = MakeToggleRow(content, y, w, name,
                    function() return TA.db.modules[name] and true or false end,
                    function() TA.db.modules[name] = not TA.db.modules[name] end)
            end
        end
    end

    y = y - 8
    y = MakeSection(content, y, w, "ABOUT")
    y = MakeInfoRow(content, y, w, "Version", TA.version or "1.0.0")
    -- From the TOC, which is the one place the author is actually declared
    -- (## Author: Sirc). A second copy in here is a second thing to get wrong,
    -- and it was wrong -- it said "Chris".
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local author = getMeta and getMeta("ToonAge", "Author")
    y = MakeInfoRow(content, y, w, "Author", (author ~= nil and author ~= "") and author or "Sirc")
    y = MakeInfoRow(content, y, w, "Modules", string.format("%d total (%d active)", loaded + disabled + errored, loaded))
    -- Only where a guide stack ships. TBC and Forever have none, and a
    -- permanent "Guides loaded: 0" reads as something that failed to load.
    if Has("QuestTracker", "GuideParser") then
        y = MakeInfoRow(content, y, w, "Guides loaded", tostring(U.TableLength(TA.Guides or {})))
    end

    y = y - 16
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    note:SetFont(STANDARD_TEXT_FONT, 9, "")
    note:SetText("|cFF888780Settings are saved per-character except where a section says otherwise. Module toggles require /reload to take effect.\nFeature toggles (Arrow, NavHud, Auto-Quest) apply instantly.|r")
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
        btn:SetHeight(20)
        btn:SetPoint("TOPLEFT",  parent, "TOPLEFT",  4, y)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        btn:SetBackdropColor(0.10, 0.08, 0.02, 1)
        btn:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.6)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        lbl:SetText(label)
        lbl:SetTextColor(1, 0.82, 0, 1)
        lbl:SetAllPoints()
        lbl:SetJustifyH("CENTER")
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(f) f:SetBackdropColor(0.20, 0.15, 0.04, 1) end)
        btn:SetScript("OnLeave", function(f) f:SetBackdropColor(0.10, 0.08, 0.02, 1) end)
        table.insert(self.frames, btn)
        y = y - 23
    end

    local function AddHdr(text)
        y = y - 4
        local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        h:SetText(text)
        h:SetTextColor(0.55, 0.40, 0.08, 1)
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        table.insert(self.frames, h)
        y = y - 14
    end

    -- Feature shortcuts only exist on clients that ship those features;
    -- Forever has none, so it gets no empty heading.
    if Has("NavHud") or Has("Arrow") or Has("QuestTracker") or Has("DungeonGear") then
        AddHdr("QUICK ACTIONS")
    end

    -- Each button only when the module it drives ships on this client. On
    -- Forever every one of these used to draw and do nothing.
    if Has("NavHud") then
        AddBtn("Toggle NavHud", function()
            local NH = TA:GetModule("NavHud")
            if NH then NH:Toggle() end
        end)
    end

    if Has("Arrow") then
        AddBtn("Toggle Arrow", function()
            local A = TA:GetModule("Arrow")
            if A then A:Toggle() end
        end)
    end

    if Has("QuestTracker") then
        AddBtn("Toggle Tracker", function()
            local QT = TA:GetModule("QuestTracker")
            if QT then QT:ToggleWindow() end
        end)

        AddBtn("Re-sync Guide", function()
            local QT = TA:GetModule("QuestTracker")
            if QT then QT:FastForward(false) end
        end)

        AddBtn("Auto-Select Guide", function()
            local QT = TA:GetModule("QuestTracker")
            if QT then QT:AutoSelectGuide() end
        end)
    end

    if Has("DungeonGear") then
        AddBtn("Dungeon Gear Check", function()
            local DG = TA:GetModule("DungeonGear")
            if DG and DG.SlashCommands and DG.SlashCommands.dungear then
                DG.SlashCommands.dungear(DG)
            end
        end)
    end

    if Has("Arrow", "QuestTracker") then
        AddBtn("Switch Layout", function()
            if TA.db then
                TA.db.useUnifiedUI = not TA.db.useUnifiedUI
                if TA.ApplyLayout then TA:ApplyLayout() end
                local mode = TA.db.useUnifiedUI and "Unified HUD" or "Fragmented Windows"
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout: " .. mode)
            end
        end)
    end

    -- ── Options ───────────────────────────────────────────────────
    AddHdr("OPTIONS")
    do
        -- One button walks the four levels; the label shows the current one.
        local ORDER = { "error", "warn", "info", "debug" }
        local cur = ORDER[TA.logLevel or 2] or "warn"
        AddBtn("Chat: " .. cur, function()
            local i = (TA.logLevel or 2) % #ORDER + 1
            TA:SlashCommand("verbose " .. ORDER[i])
            if TA.ToggleOptionsPanel then TA:ToggleOptionsPanel(); TA:ToggleOptionsPanel() end
        end)
    end
    AddBtn("Safe Mode", function() TA:SlashCommand("safemode") end)
    -- Profile copy between characters: previously /ta profile only.
    AddBtn("Export Settings", function() self:ShowExportFrame() end)
    AddBtn("Import Settings", function() self:ShowImportFrame() end)

    -- ── Debug ─────────────────────────────────────────────────────
    AddHdr("DEBUG")
    AddBtn("Module Health", function() TA:SlashCommand("health") end)
    if TA.TestHarness and TA.TestHarness.Run then
        AddBtn("Run Self-test", function() TA.TestHarness:Run() end)
    end
    AddBtn("Error Log", function() TA:SlashCommand("errors copy") end)
    AddBtn("Debug Mode", function() TA:SlashCommand("debug") end)
    AddBtn("State Keys", function() TA:SlashCommand("state") end)

    -- ── System ────────────────────────────────────────────────────
    AddHdr("SYSTEM")
    AddBtn("Reload UI", function() ReloadUI() end)

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
                -- Tell the reset tripwire this was deliberate (Core/Init.lua).
                if ToonAge and ToonAge.GuardSnapshot then pcall(ToonAge.GuardSnapshot, ToonAge, "Settings: Reset All Settings") end
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

-- ══════════════════════════════════════════════════════════════════════════════
-- PROFILE IMPORT/EXPORT
-- Serializes player settings to a compact string for sharing between characters
-- or accounts. Uses a simple key=value format that's human-readable.
-- ══════════════════════════════════════════════════════════════════════════════

--- Keys exported in a profile (subset of charDB that constitutes "preferences")
local PROFILE_KEYS = {

    "tracker.deferToZygor",
    "tracker.autoRewardPick",
    "tracker.replaceBlizzTracker",
    "tracker.showAvailableQuests",
    "tracker.smallMapPins",
    "tracker.spoilerFree",
    "predictBar.visible",
    "arrow.visible",
    "pvxMode",
    "navhud.visible",
    "navhud.scale",
    "navhud.opacity",
    "navhud.showCardinals",
    "navhud.showCoords",
    "navhud.showDistance",
    "navhud.showRing",
    "navhud.showPins",
}

--- Read a dotted key from charDB (e.g. "tracker.autoQuest" → charDB.tracker.autoQuest)
local function ReadKey(key)
    local parts = { strsplit(".", key) }
    local tbl = TA.charDB
    for i = 1, #parts - 1 do
        tbl = tbl and tbl[parts[i]]
    end
    return tbl and tbl[parts[#parts]]
end

--- Write a dotted key to charDB
local function WriteKey(key, value)
    local parts = { strsplit(".", key) }
    local tbl = TA.charDB
    for i = 1, #parts - 1 do
        tbl[parts[i]] = tbl[parts[i]] or {}
        tbl = tbl[parts[i]]
    end
    tbl[parts[#parts]] = value
end

--- Export current settings as a profile string.
function Settings:ExportProfile()
    if not TA.charDB then return "" end
    local lines = { "TOONAGE_PROFILE_V1" }
    for _, key in ipairs(PROFILE_KEYS) do
        local val = ReadKey(key)
        if val ~= nil then
            table.insert(lines, key .. "=" .. tostring(val))
        end
    end
    -- Also export account-wide module toggles
    if TA.db and TA.db.modules then
        for name, enabled in pairs(TA.db.modules) do
            table.insert(lines, "mod." .. name .. "=" .. tostring(enabled))
        end
    end
    return table.concat(lines, "\n")
end

--- Import a profile string, overwriting current settings.
--- @param str string — the profile data
--- @return boolean success, string message
function Settings:ImportProfile(str)
    if not str or str == "" then return false, "Empty profile string." end
    if not TA.charDB then return false, "Character data not loaded." end

    local lines = { strsplit("\n", str) }
    if lines[1] ~= "TOONAGE_PROFILE_V1" then
        return false, "Invalid profile format (missing header)."
    end

    local applied = 0
    for i = 2, #lines do
        local line = lines[i]
        if line and line ~= "" then
            local key, val = line:match("^(.-)=(.+)$")
            if key and val then
                -- Parse value
                local parsed
                if val == "true" then parsed = true
                elseif val == "false" then parsed = false
                elseif tonumber(val) then parsed = tonumber(val)
                else parsed = val end

                -- Module toggles go to TA.db.modules
                if key:match("^mod%.") then
                    local modName = key:sub(5)
                    if TA.db and TA.db.modules then
                        TA.db.modules[modName] = parsed
                        applied = applied + 1
                    end
                else
                    WriteKey(key, parsed)
                    applied = applied + 1
                end
            end
        end
    end

    return true, applied .. " settings imported. /reload to apply fully."
end

--- Show a copy frame with the exported profile.
function Settings:ShowExportFrame()
    local text = self:ExportProfile()
    if text == "" then
        TA:Print(TA.LOG.OUTPUT, nil, "Nothing to export.")
        return
    end

    -- Reuse ErrorLog's copy frame pattern
    local EL = TA:GetModule("ErrorLog")
    if EL and EL.ShowCopyFrame then
        -- Temporarily override the format function
        local origFn = EL.FormatLog
        EL.FormatLog = function() return text end
        EL:ShowCopyFrame()
        EL.FormatLog = origFn
    else
        -- Fallback: print to chat
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Profile Export]|r")
        TA:Raw(TA.LOG.OUTPUT, text)
    end
end

Settings.SlashCommands = {
    profile = function(self, args)
        args = args and args:lower():match("^%s*(.-)%s*$") or ""
        if args == "export" then
            self:ShowExportFrame()
        elseif args == "import" then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Paste your profile string into the edit box that appears.")
            TA:Raw(TA.LOG.OUTPUT, "|cFF888780Use /ta profile export on the source character to get the string.|r")
            -- Show import frame (simple editbox)
            self:ShowImportFrame()
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Profile]|r")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta profile export|r — copy settings to clipboard")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta profile import|r — paste settings from another character")
        end
    end,
}

--- Show an import frame (edit box for pasting).
function Settings:ShowImportFrame()
    if self._importFrame then self._importFrame:Show(); return end

    local f = CreateFrame("Frame", "TAProfileImportFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 300)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.97)
    f:SetBackdropBorderColor(0.55, 0.40, 0.08, 1)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetText("|cFFFFD100ToonAge|r — Import Profile")
    title:SetPoint("TOP", f, "TOP", 0, -12)

    local scroll = CreateFrame("ScrollFrame", "TAProfileImportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 50)

    local editBox = CreateFrame("EditBox", "TAProfileImportEditBox", scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)
    editBox:SetWidth(scroll:GetWidth())
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(editBox)

    local importBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    importBtn:SetSize(120, 28)
    importBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 12)
    importBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    importBtn:SetBackdropColor(0.05, 0.15, 0.05, 1)
    importBtn:SetBackdropBorderColor(0.20, 0.92, 0.40, 0.9)
    local btnLbl = importBtn:CreateFontString(nil, "OVERLAY")
    btnLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    btnLbl:SetText("|cFF4AFF7AImport|r")
    btnLbl:SetAllPoints(importBtn)
    btnLbl:SetJustifyH("CENTER")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local ok, msg = Settings:ImportProfile(text)
        if ok then
            TA:Print(TA.LOG.OUTPUT, nil, "|cFF4AFF7A" .. msg .. "|r")
        else
            TA:Print(TA.LOG.ERROR, nil, msg)
        end
    end)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    self._importFrame = f
end

