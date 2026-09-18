-- ToonAge/Modules/Settings.lua (Classic — MoP 50504)
-- Unified settings panel rendered as a tab in the main ToonAge frame.
-- Exposes features, toggles, and options in one place.
--
-- Classic adaptations:
--   • No Delves, no dynamic flight settings
--   • No DungeonGear (M+ keystones), no GearSets (no equipment manager in MoP)
--   • Simplified module list (Classic-available modules only)
--   • Keep: module toggles, log level, layout, safe mode
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
        if f.Hide then f:Hide() end
        if f.SetParent then f:SetParent(nil) end
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
        if A then A:Toggle() end
    end)

    y = MakeToggleRow(content, y, w, "NavHud (transparent FarmHud-style overlay with nodes & waypoints)", function()
        local NH = TA:GetModule("NavHud")
        return NH and NH:IsVisible()
    end, function()
        local NH = TA:GetModule("NavHud")
        if NH then NH:Toggle() end
    end)

    y = MakeToggleRow(content, y, w, "World Map Pins (numbered step markers on world map)", function()
        return TA.db and TA.db.modules and TA.db.modules.MapPins ~= false
    end, function()
        if TA.db and TA.db.modules then
            TA.db.modules.MapPins = not TA.db.modules.MapPins
        end
    end)

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

    y = MakeToggleRow(content, y, w, "Auto-Mount After Combat", function()
        return TA.db and TA.db.autoMount and TA.db.autoMount.enabled
    end, function()
        if TA.db then
            TA.db.autoMount = TA.db.autoMount or { enabled = true, delay = 1.5 }
            TA.db.autoMount.enabled = not TA.db.autoMount.enabled
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

    y = MakeToggleRow(content, y, w, "Group completed quests together", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.groupCompleted
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.groupCompleted = not TA.charDB.tracker.groupCompleted
        end
    end)

    y = MakeToggleRow(content, y, w, "Use TomTom waypoints (set waypoints via TomTom if installed)", function()
        return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.useTomTomWaypoints
    end, function()
        if TA.charDB and TA.charDB.tracker then
            TA.charDB.tracker.useTomTomWaypoints = not TA.charDB.tracker.useTomTomWaypoints
        end
    end)

    y = y - 8

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
            if QT and QT.UpdateBlizzardTrackerVisibility then
                QT:UpdateBlizzardTrackerVisibility()
            end
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- LOG LEVEL
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "LOG LEVEL")

    y = MakeChoiceRow(content, y, w, "Verbosity", {
        { value = 1, text = "|cFFFF4444ERROR|r" },
        { value = 2, text = "|cFFFF9A1AWARN|r" },
        { value = 3, text = "|cFFFFD100INFO|r" },
        { value = 4, text = "|cFF00CCFFDEBUG|r" },
    }, function()
        return (TA.db and TA.db.logLevel) or 2
    end, function(v)
        if TA.db then
            TA.db.logLevel = v
            TA.logLevel = v
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- SAFE MODE
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "SAFE MODE")

    y = MakeToggleRow(content, y, w, "Safe Mode (only load core modules on next /reload)", function()
        return TA.db and TA.db.safeMode
    end, function()
        if TA.db then
            TA.db.safeMode = not TA.db.safeMode
        end
    end)

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- NEW CHARACTERS
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

    y = y - 8

    -- ═══════════════════════════════════════════════════════════════════
    -- MODULES (toggle features — reload to apply)
    -- ═══════════════════════════════════════════════════════════════════
    y = MakeSection(content, y, w, "MODULES (toggle features — reload to apply)")

    local moduleList = {
        "NavHud", "MapPins", "CutsceneSkip", "AutoEquip",
        "AutoMount", "GatherTracker", "XPTracker", "RestOptimizer",
        "DeathRecovery",
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
    -- MODULE HEALTH
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

    if errored > 0 then
        for _, entry in ipairs(report) do
            if entry.status == "errored" then
                y = MakeInfoRow(content, y, w, "  ✗ " .. entry.name, "|cFFFF4444" .. (entry.error or "unknown") .. "|r")
            end
        end
    end

    y = y - 8
    y = MakeSection(content, y, w, "ABOUT")
    y = MakeInfoRow(content, y, w, "Version", TA.version or "1.0.0-classic")
    y = MakeInfoRow(content, y, w, "Author", "Chris")
    y = MakeInfoRow(content, y, w, "Modules", string.format("%d total (%d active)", loaded + disabled + errored, loaded))
    y = MakeInfoRow(content, y, w, "Guides loaded", tostring(U.TableLength and U.TableLength(TA.Guides or {}) or 0))

    y = y - 16
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    note:SetFont(STANDARD_TEXT_FONT, 9, "")
    note:SetText("|cFF888780Settings are saved per-character except where a section says otherwise. "
              .. "Module toggles require /reload to take effect.\nFeature toggles (Arrow, NavHud, Auto-Quest) apply instantly.|r")
    note:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y)
    note:SetWidth(w - 28)
    note:SetJustifyH("LEFT")
    table.insert(self.frames, note)
    y = y - 30

    content:SetHeight(math.abs(y) + 20)

    -- ── Sidebar: quick actions ────────────────────────────────────────
    if sidebar then
        self:RenderSidebar(sidebar)
    end
end

function Settings:RenderSidebar(parent)
    local y = -8

    local function AddBtn(label, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetHeight(26)
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
        if NH then NH:Toggle() end
    end)

    AddBtn("Toggle Arrow", function()
        local A = TA:GetModule("Arrow")
        if A then A:Toggle() end
    end)

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

    AddBtn("Switch Layout", function()
        if TA.db then
            TA.db.useUnifiedUI = not TA.db.useUnifiedUI
            if TA.ApplyLayout then TA:ApplyLayout() end
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
