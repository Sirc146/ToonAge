-- ToonAge/Modules/MapPins.lua
-- World map pin overlay showing upcoming guide step waypoints.
-- Uses Blizzard's MapCanvasDataProviderMixin pattern (same as HandyNotes).
--
-- Shows numbered pins on the world map for the next N guide steps that have
-- coordinates in the current zone. Pins are color-coded by step type.
-- Refreshes automatically when the QuestTracker advances a step.
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local MapPins = {}
TA:RegisterModule("MapPins", MapPins)

-- ── Constants ─────────────────────────────────────────────────────────────────

local MAX_PINS       = 8       -- max pins shown on world map
local PIN_SIZE_BASE  = 24      -- pixel size of each pin
local PIN_TEMPLATE   = "TAMapPinTemplate"

-- Pin colors by step type (same palette as NavHud for consistency)
local PIN_COLORS = {
    pickup    = { 0.29, 1.00, 0.48, 1.0 },
    turnin    = { 1.00, 0.82, 0.00, 1.0 },
    objective = { 1.00, 0.67, 0.20, 1.0 },
    waypoint  = { 0.12, 0.74, 1.00, 1.0 },
    quest     = { 1.00, 0.82, 0.00, 1.0 },
    accept    = { 0.29, 1.00, 0.48, 1.0 },
    travel    = { 0.12, 0.74, 1.00, 1.0 },
    npc       = { 0.47, 1.00, 0.47, 1.0 },
    item      = { 0.73, 0.60, 1.00, 1.0 },
    action    = { 1.00, 0.53, 0.20, 1.0 },
    flyto     = { 0.33, 0.80, 1.00, 1.0 },
    sethearth = { 0.80, 0.40, 1.00, 1.0 },
    default   = { 0.88, 0.83, 0.65, 1.0 },
}

-- ── DataProvider (Blizzard MapCanvas pattern) ─────────────────────────────────

MapPins.DataProvider = CreateFromMixins(MapCanvasDataProviderMixin)

-- Frame pool for pin recycling (avoids GC pressure from creating/destroying pins)
MapPins._pinPool = {}
MapPins._activePins = {}

function MapPins.DataProvider:RemoveAllData()
    -- Release all active pins back to the pool
    for _, pin in ipairs(MapPins._activePins) do
        pin:Hide()
        pin:ClearAllPoints()
        table.insert(MapPins._pinPool, pin)
    end
    wipe(MapPins._activePins)
    self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
end

function MapPins.DataProvider:RefreshAllData(fromOnShow)
    self:RemoveAllData()

    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return end

    -- Guard: don't place pins if the map canvas is in a bad state
    local map = self:GetMap()
    if not map then return end
    local mapID = map:GetMapID()
    if not mapID then return end
    -- Additional safety: check the canvas is actually shown and ready
    if not map:IsVisible() then return end

    local Arrow = TA:GetModule("Arrow")
    local GP    = TA:GetModule("GuideParser")
    local pinCount = 0

    for i = QT.stepIdx, #guide.steps do
        local step = guide.steps[i]
        if not step then break end  -- stop scanning (real break)
        if pinCount >= MAX_PINS then break end  -- stop scanning (real break)

        repeat  -- continue wrapper
            if step.type == "text" then break end
            if step.noArrow then break end
            if GP and not GP:IsStepApplicable(step) then break end

            -- Resolve coordinates — use step.coord ONLY (not CoordResolver/Arrow)
            -- IMPORTANT: DataProvider runs inside Blizzard's secureexecuterange.
            -- Calling addon APIs here (CoordResolver, C_QuestLog queries, etc.)
            -- taints the entire execution chain and breaks the world map.
            -- Only use pre-stored coordinates from the guide step itself.
            local coordMap, cx, cy = 0, 0, 0
            if step.coord then
                coordMap = step.coord.map or 0
                cx = step.coord.x or 0
                cy = step.coord.y or 0
            end

            -- Skip pins with no valid coordinates
            if coordMap == 0 and cx == 0 and cy == 0 then break end

            -- Only show pins for the current map zone
            -- Allow coordMap=0 (placeholder) to show on any map
            if coordMap ~= 0 and coordMap ~= mapID then break end

            -- Valid pin — place it
            pinCount = pinCount + 1

            local relNum = i - QT.stepIdx + 1
            local color  = PIN_COLORS[step.type] or PIN_COLORS.default
            local isCurrent = (i == QT.stepIdx)

            local pinMap = self:GetMap()
            if pinMap and pinMap.AcquirePin then
                pcall(pinMap.AcquirePin, pinMap, PIN_TEMPLATE, cx, cy, step, relNum, color, isCurrent)
            end
        until true
    end
end

-- ── Pin Mixin ─────────────────────────────────────────────────────────────────

TAMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function TAMapPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 0.5, 1.5)
end

function TAMapPinMixin:OnAcquired(x, y, step, relNum, color, isCurrent)
    self:SetPosition(x, y)

    local size = isCurrent and (PIN_SIZE_BASE * 1.4) or PIN_SIZE_BASE
    self:SetSize(size, size)

    -- Store for tooltip
    self.step     = step
    self.relNum   = relNum
    self.isCurrent = isCurrent

    -- Background dot
    if not self.bg then
        self.bg = self:CreateTexture(nil, "BACKGROUND")
        self.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.bg:SetAllPoints()
    end
    self.bg:SetVertexColor(color[1], color[2], color[3], color[4] * 0.85)

    -- Border (slightly larger, dark)
    if not self.border then
        self.border = self:CreateTexture(nil, "BORDER")
        self.border:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.border:SetPoint("TOPLEFT", -1, 1)
        self.border:SetPoint("BOTTOMRIGHT", 1, -1)
    end
    self.border:SetVertexColor(0, 0, 0, 0.7)

    -- Number label
    if not self.numLabel then
        self.numLabel = self:CreateFontString(nil, "OVERLAY")
        self.numLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        self.numLabel:SetPoint("CENTER")
    end
    self.numLabel:SetText(tostring(relNum))
    self.numLabel:SetTextColor(1, 1, 1, 1)

    self:Show()
end

function TAMapPinMixin:OnMouseEnter()
    if not self.step then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    local stepType = self.step.type or "quest"
    local typeLabel = stepType:sub(1,1):upper() .. stepType:sub(2)
    local title = self.step.text or "Guide Step"
    if #title > 50 then title = title:sub(1, 47) .. "..." end

    GameTooltip:SetText(string.format("|cFFFFD100[%d]|r %s", self.relNum, title), 1, 1, 1)
    GameTooltip:AddLine(typeLabel, 0.7, 0.7, 0.7)

    if self.step.questID then
        local questTitle = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(self.step.questID)
        if questTitle then
            GameTooltip:AddLine("Quest: " .. questTitle, 0.4, 0.78, 1.0)
        end
    end

    if self.isCurrent then
        GameTooltip:AddLine("|cFF4AFF7A← Current Step|r")
    end

    GameTooltip:Show()
end

function TAMapPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

-- ── Module lifecycle ──────────────────────────────────────────────────────────

function MapPins:Init()
    -- Wait for WorldMapFrame to exist (it's load-on-demand)
    -- Hook into it when it first opens
    if WorldMapFrame and WorldMapFrame.AddDataProvider then
        WorldMapFrame:AddDataProvider(self.DataProvider)
    else
        -- WorldMapFrame may not exist yet — hook ADDON_LOADED
        local hookFrame = CreateFrame("Frame")
        hookFrame:RegisterEvent("ADDON_LOADED")
        hookFrame:SetScript("OnEvent", function(f, event, addon)
            if addon == "Blizzard_WorldMap" or (WorldMapFrame and WorldMapFrame.AddDataProvider) then
                WorldMapFrame:AddDataProvider(MapPins.DataProvider)
                f:UnregisterAllEvents()
            end
        end)
        -- Also try immediately in case it's already loaded
        if WorldMapFrame and WorldMapFrame.AddDataProvider then
            WorldMapFrame:AddDataProvider(self.DataProvider)
            hookFrame:UnregisterAllEvents()
        end
    end
end

--- Called by QuestTracker when step advances to refresh pins
function MapPins:Refresh()
    if WorldMapFrame and WorldMapFrame:IsShown() and self.DataProvider.RefreshAllData then
        self.DataProvider:RefreshAllData()
    end
end

MapPins.SlashCommands = {}
