-- ToonAge/Modules/Progression/DungeonGuide.lua
-- Dungeon boss strategy guide: detects instance transitions, displays
-- role-specific boss strategies in a compact collapsible panel.
--
-- Architecture:
--   • PLAYER_ENTERING_WORLD → detect dungeon entry/exit
--   • ENCOUNTER_START / ENCOUNTER_END → track current boss, auto-advance
--   • Role-aware strategy text (TANK/HEALER/DAMAGER)
--   • Manual Prev/Next boss navigation
--   • Graceful degradation when no data exists for an instance
--
-- Data source: TA.Data.Dungeons[instanceID] (see Data/Dungeons.lua)
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U = TA.Utils

local DungeonGuide = {}
TA:RegisterModule("DungeonGuide", DungeonGuide)

-- ── Constants ─────────────────────────────────────────────────────────────────
local ROLE_COLORS = {
    TANK = { r = 0.2, g = 0.6, b = 1.0 }, -- blue
    HEALER = { r = 0.2, g = 0.9, b = 0.3 }, -- green
    DAMAGER = { r = 1.0, g = 0.3, b = 0.3 }, -- red
}

local FRAME_WIDTH = 280
local FRAME_HEIGHT = 180
local HEADER_H = 24
local NAV_H = 22
local PADDING = 8

local FLAT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- ── State ─────────────────────────────────────────────────────────────────────
DungeonGuide.currentInstanceID = nil
DungeonGuide.currentBossIndex = 1
DungeonGuide.inEncounter = false
DungeonGuide.encounterBossIdx = nil
DungeonGuide.frame = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Safely get the player's current role.
--- @return string — "TANK", "HEALER", or "DAMAGER"
local function GetPlayerRole()
    local ok, role = pcall(function()
        local specIndex = GetSpecialization()
        if not specIndex then
            return "DAMAGER"
        end
        return GetSpecializationRole(specIndex) or "DAMAGER"
    end)
    if not ok or not role then
        return "DAMAGER"
    end
    return role
end

--- Safely look up dungeon data for the given instanceID.
--- @return table|nil — dungeon data table or nil
local function GetDungeonData(instanceID)
    local dungeonData = TA.Data and TA.Data.Dungeons and TA.Data.Dungeons[instanceID]
    return dungeonData
end

--- Find boss index by encounterID in the dungeon data.
--- @return number|nil
local function FindBossIndex(dungeonData, encounterID)
    if not dungeonData or not dungeonData.bosses then
        return nil
    end
    for i, boss in ipairs(dungeonData.bosses) do
        if boss.encounterID == encounterID then
            return i
        end
    end
    return nil
end

-- ── DB defaults ───────────────────────────────────────────────────────────────

local function EnsureDB()
    if not TA.db then
        return
    end
    if not TA.db.dungeonGuide then
        TA.db.dungeonGuide = { enabled = true, collapsed = false }
    end
end

-- ── UI Creation ───────────────────────────────────────────────────────────────

local function CreateGuideFrame()
    if DungeonGuide.frame then
        return DungeonGuide.frame
    end

    local f = CreateFrame("Frame", "ToonAgeDungeonGuideFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    f:SetBackdrop(FLAT_BACKDROP)
    f:SetBackdropColor(0.05, 0.04, 0.02, 0.95)
    f:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.70)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    f:Hide()

    -- ── Title bar ─────────────────────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    header:SetBackdrop(FLAT_BACKDROP)
    header:SetBackdropColor(0.12, 0.10, 0.06, 1.0)
    header:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.70)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", header, "LEFT", PADDING, 0)
    title:SetText("Dungeon Guide")
    f.titleText = title

    -- Collapse/expand button
    local collapseBtn = CreateFrame("Button", nil, header)
    collapseBtn:SetSize(16, 16)
    collapseBtn:SetPoint("RIGHT", header, "RIGHT", -PADDING, 0)
    collapseBtn:SetNormalFontObject("GameFontNormalSmall")
    collapseBtn:SetText("-")

    local collapseBtnText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    collapseBtnText:SetPoint("CENTER")
    collapseBtnText:SetText("−")
    collapseBtn.text = collapseBtnText

    collapseBtn:SetScript("OnClick", function()
        EnsureDB()
        if TA.db and TA.db.dungeonGuide then
            TA.db.dungeonGuide.collapsed = not TA.db.dungeonGuide.collapsed
        end
        DungeonGuide:UpdateCollapse()
    end)
    f.collapseBtn = collapseBtn

    -- ── Content area ──────────────────────────────────────────────────────────
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", PADDING, -PADDING)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, NAV_H + PADDING)
    f.content = content

    -- Dungeon name
    local dungeonName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonName:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    dungeonName:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    dungeonName:SetJustifyH("LEFT")
    dungeonName:SetWordWrap(false)
    f.dungeonNameText = dungeonName

    -- Boss name (role-colored)
    local bossName = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bossName:SetPoint("TOPLEFT", dungeonName, "BOTTOMLEFT", 0, -4)
    bossName:SetPoint("TOPRIGHT", dungeonName, "BOTTOMRIGHT", 0, -4)
    bossName:SetJustifyH("LEFT")
    bossName:SetWordWrap(false)
    f.bossNameText = bossName

    -- Role label
    local roleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleLabel:SetPoint("TOPLEFT", bossName, "BOTTOMLEFT", 0, -6)
    roleLabel:SetJustifyH("LEFT")
    f.roleLabel = roleLabel

    -- Strategy text
    local strategy = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    strategy:SetPoint("TOPLEFT", roleLabel, "BOTTOMLEFT", 0, -4)
    strategy:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    strategy:SetJustifyH("LEFT")
    strategy:SetWordWrap(true)
    strategy:SetSpacing(2)
    f.strategyText = strategy

    -- ── Navigation bar ────────────────────────────────────────────────────────
    local nav = CreateFrame("Frame", nil, f)
    nav:SetHeight(NAV_H)
    nav:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PADDING, PADDING)
    nav:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    f.nav = nav

    -- Prev button
    local prevBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    prevBtn:SetSize(60, 20)
    prevBtn:SetPoint("LEFT", nav, "LEFT", 0, 0)
    prevBtn:SetText("< Prev")
    prevBtn:SetScript("OnClick", function()
        DungeonGuide:NavigateBoss(-1)
    end)
    f.prevBtn = prevBtn

    -- Boss counter text
    local bossCounter = nav:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bossCounter:SetPoint("CENTER", nav, "CENTER", 0, 0)
    f.bossCounter = bossCounter

    -- Next button
    local nextBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nextBtn:SetSize(60, 20)
    nextBtn:SetPoint("RIGHT", nav, "RIGHT", 0, 0)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
        DungeonGuide:NavigateBoss(1)
    end)
    f.nextBtn = nextBtn

    DungeonGuide.frame = f
    return f
end

-- ── Frame updates ─────────────────────────────────────────────────────────────

function DungeonGuide:UpdateCollapse()
    local f = self.frame
    if not f then
        return
    end

    EnsureDB()
    local collapsed = TA.db and TA.db.dungeonGuide and TA.db.dungeonGuide.collapsed

    if collapsed then
        f.content:Hide()
        f.nav:Hide()
        f:SetHeight(HEADER_H)
        if f.collapseBtn and f.collapseBtn.text then
            f.collapseBtn.text:SetText("+")
        end
    else
        f.content:Show()
        f.nav:Show()
        f:SetHeight(FRAME_HEIGHT)
        if f.collapseBtn and f.collapseBtn.text then
            f.collapseBtn.text:SetText("−")
        end
    end
end

function DungeonGuide:UpdateDisplay()
    local f = self.frame
    if not f then
        return
    end

    local instanceID = self.currentInstanceID
    if not instanceID then
        f:Hide()
        return
    end

    -- Ensure DB state
    EnsureDB()
    if TA.db and TA.db.dungeonGuide and not TA.db.dungeonGuide.enabled then
        f:Hide()
        return
    end

    local dungeonData = GetDungeonData(instanceID)

    -- Graceful degradation: no data for this instance
    if not dungeonData or not dungeonData.bosses or #dungeonData.bosses == 0 then
        f.dungeonNameText:SetText("Unknown Instance")
        f.bossNameText:SetText("")
        f.roleLabel:SetText("")
        f.strategyText:SetText("No guide data available for this instance.")
        f.bossCounter:SetText("")
        f.prevBtn:Disable()
        f.nextBtn:Disable()
        f:Show()
        self:UpdateCollapse()
        return
    end

    -- Clamp boss index
    local bossCount = #dungeonData.bosses
    if self.currentBossIndex < 1 then
        self.currentBossIndex = 1
    end
    if self.currentBossIndex > bossCount then
        self.currentBossIndex = bossCount
    end

    local boss = dungeonData.bosses[self.currentBossIndex]
    local role = GetPlayerRole()
    local roleColor = ROLE_COLORS[role] or ROLE_COLORS.DAMAGER

    -- Dungeon name
    f.dungeonNameText:SetText(dungeonData.name or "Dungeon")

    -- Boss name with role-colored prefix
    local bossLabel = boss and boss.name or "Unknown Boss"
    if self.inEncounter and self.encounterBossIdx == self.currentBossIndex then
        bossLabel = "|cFFFFFF00>> " .. bossLabel .. " <<|r"
    end
    f.bossNameText:SetText(bossLabel)

    -- Role label
    local roleText = role or "DAMAGER"
    f.roleLabel:SetText(
        string.format(
            "|cFF%02x%02x%02x%s|r",
            math.floor(roleColor.r * 255),
            math.floor(roleColor.g * 255),
            math.floor(roleColor.b * 255),
            roleText
        )
    )

    -- Strategy text
    local strategyText = "No strategy available."
    if boss and boss.strategies and boss.strategies[role] then
        strategyText = boss.strategies[role]
    end
    f.strategyText:SetText(strategyText)

    -- Navigation state
    f.bossCounter:SetText(self.currentBossIndex .. " / " .. bossCount)
    f.prevBtn:SetEnabled(self.currentBossIndex > 1)
    f.nextBtn:SetEnabled(self.currentBossIndex < bossCount)

    -- Title bar color by role
    f.titleText:SetTextColor(roleColor.r, roleColor.g, roleColor.b, 1.0)

    f:Show()
    self:UpdateCollapse()
end

-- ── Navigation ────────────────────────────────────────────────────────────────

function DungeonGuide:NavigateBoss(direction)
    local dungeonData = GetDungeonData(self.currentInstanceID)
    if not dungeonData or not dungeonData.bosses then
        return
    end

    local bossCount = #dungeonData.bosses
    local newIndex = self.currentBossIndex + direction
    if newIndex >= 1 and newIndex <= bossCount then
        self.currentBossIndex = newIndex
        self:UpdateDisplay()
    end
end

-- ── Instance detection ────────────────────────────────────────────────────────

function DungeonGuide:CheckInstance()
    local ok, inInstance, instanceType = pcall(IsInInstance)
    if not ok then
        return
    end

    if inInstance and (instanceType == "party" or instanceType == "raid") then
        -- Entered a dungeon/raid
        local ok2, instanceName, _, _, _, _, _, instanceID = pcall(GetInstanceInfo)
        if ok2 and instanceID then
            if self.currentInstanceID ~= instanceID then
                -- New instance — reset boss tracking
                self.currentInstanceID = instanceID
                self.currentBossIndex = 1
                self.inEncounter = false
                self.encounterBossIdx = nil
            end
            -- Create frame if needed and update display
            CreateGuideFrame()
            self:UpdateDisplay()
        end
    else
        -- Not in an instance — hide the frame
        self.currentInstanceID = nil
        self.currentBossIndex = 1
        self.inEncounter = false
        self.encounterBossIdx = nil
        if self.frame then
            self.frame:Hide()
        end
    end
end

-- ── Encounter tracking ────────────────────────────────────────────────────────

function DungeonGuide:OnEncounterStart(encounterID, encounterName)
    local dungeonData = GetDungeonData(self.currentInstanceID)
    if not dungeonData then
        return
    end

    local bossIdx = FindBossIndex(dungeonData, encounterID)
    if bossIdx then
        self.inEncounter = true
        self.encounterBossIdx = bossIdx
        self.currentBossIndex = bossIdx
        self:UpdateDisplay()
    end
end

function DungeonGuide:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    self.inEncounter = false
    self.encounterBossIdx = nil

    -- Auto-advance to next boss on kill
    if success and success == 1 then
        local dungeonData = GetDungeonData(self.currentInstanceID)
        if dungeonData and dungeonData.bosses then
            local bossCount = #dungeonData.bosses
            local killedIdx = FindBossIndex(dungeonData, encounterID)
            if killedIdx and killedIdx < bossCount then
                self.currentBossIndex = killedIdx + 1
            end
        end
    end

    self:UpdateDisplay()
end

-- ── Event handler ─────────────────────────────────────────────────────────────

function DungeonGuide:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:CheckInstance()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Also check on zone changes (handles portal transitions)
        self:CheckInstance()
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName = ...
        local ok, err = pcall(self.OnEncounterStart, self, encounterID, encounterName)
        if not ok and TA.ErrorLog then
            TA.ErrorLog:Log("DungeonGuide ENCOUNTER_START", tostring(err), "")
        end
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        local ok, err = pcall(self.OnEncounterEnd, self, encounterID, encounterName, difficultyID, groupSize, success)
        if not ok and TA.ErrorLog then
            TA.ErrorLog:Log("DungeonGuide ENCOUNTER_END", tostring(err), "")
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Role may have changed — refresh display
        if self.currentInstanceID then
            self:UpdateDisplay()
        end
    end
end

-- ── Initialization ────────────────────────────────────────────────────────────

function DungeonGuide:Init()
    -- Ensure saved state
    EnsureDB()

    -- Create a private event frame for dungeon-specific events
    -- (ENCOUNTER_START/END are not in the global persistent list)
    local eventFrame = CreateFrame("Frame", "ToonAgeDungeonGuideEvents")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        local ok, err = pcall(DungeonGuide.OnEvent, DungeonGuide, event, ...)
        if not ok then
            if TA.ErrorLog then
                TA.ErrorLog:Log("DungeonGuide OnEvent", tostring(err), event or "")
            end
        end
    end)

    self.eventFrame = eventFrame

    -- Check if already in a dungeon on login/reload
    self:CheckInstance()
end
