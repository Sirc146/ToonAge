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
local U  = TA.Utils

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

-- The map canvas mixin is part of the world map addon. A client without it
-- still loads this file; the arrow pin does not need the canvas.
if type(CreateFromMixins) == "function" and type(MapCanvasDataProviderMixin) == "table" then
    MapPins.DataProvider = CreateFromMixins(MapCanvasDataProviderMixin)
else
    MapPins.DataProvider = {}
end

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

--- One manual pin, used when Forever has no guide. Returns true when that
--- pin was placed, so the guide loop does not also run.
function MapPins.DataProvider:PlaceForeverPin()
    if TA.flavor ~= "forever" then return false end
    local Arrow = TA:GetModule("Arrow")
    local wp = Arrow and Arrow.manualWaypoint
    if type(wp) ~= "table" or type(wp.x) ~= "number" or type(wp.y) ~= "number" then
        return false
    end
    if type(self.GetMap) ~= "function" then return false end
    local map = self:GetMap()
    if type(map) ~= "table" or type(map.GetMapID) ~= "function" then return false end
    local okID, mapID = pcall(map.GetMapID, map)
    if not okID or type(mapID) ~= "number" then return false end
    local same = mapID == wp.map
    if not same and type(wp.zone) == "string" and type(Arrow.MapName) == "function" then
        local openName = Arrow.MapName(mapID)
        same = type(openName) == "string" and openName:lower() == wp.zone:lower()
    end
    if not same then return false end
    if type(map.AcquirePin) ~= "function" then return false end
    local step = {
        type = wp.quest and "quest" or "npc",
        text = wp.title or "Pin",
        questID = wp.questID,
    }
    local color = PIN_COLORS[step.type] or PIN_COLORS.default
    step.foreverPin = true
    -- Acquire from Lua, not pcall(fn, ...). This client's AcquirePin forwards
    -- its coordinates through the Lua 5.0 `arg` table, and a C pcall does not
    -- install that table, so OnAcquired used to run with no x,y.
    local pin
    local function acquire()
        pin = map:AcquirePin(PIN_TEMPLATE, wp.x, wp.y, step, 1, color, true)
    end
    local ok = pcall(acquire)
    if ok and type(pin) == "table" then
        -- OnAcquired may already have anchored. Do it again from the stored
        -- target: a dropped `arg` leaves SetPosition(nil), which this canvas
        -- draws at its center, on top of the player the view is following.
        MapPins.FinishForeverPin(pin, wp.x, wp.y)
    end
    return true
end

--- Pixel offset from the canvas TOPLEFT. x,y are 0-1, or 0-100 display
--- coords. Nil when the canvas has no size, so the caller does not anchor at 0,0.
function MapPins.CanvasOffset(width, height, x, y)
    if type(width) ~= "number" or type(height) ~= "number" then return nil end
    if width <= 0 or height <= 0 then return nil end
    if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y then return nil end
    if math.abs(x) > 1 then x = x / 100 end
    if math.abs(y) > 1 then y = y / 100 end
    return x * width, -y * height
end

function MapPins.PinCanvas(pin)
    if type(pin) ~= "table" or type(pin.GetMap) ~= "function" then return nil end
    local ok, map = pcall(pin.GetMap, pin)
    if not ok or type(map) ~= "table" or type(map.GetCanvas) ~= "function" then return nil end
    local okC, canvas = pcall(map.GetCanvas, map)
    if not okC or type(canvas) ~= "table" or type(canvas.GetWidth) ~= "function" then
        return nil
    end
    return canvas
end

--- CENTER on the canvas TOPLEFT at the target. False when the canvas is not sized.
function MapPins.AnchorPin(pin, x, y)
    local canvas = MapPins.PinCanvas(pin)
    if not canvas or type(pin.SetPoint) ~= "function" then return false end
    local okW, width = pcall(canvas.GetWidth, canvas)
    local okH, height = pcall(canvas.GetHeight, canvas)
    if not okW or not okH then return false end
    local ox, oy = MapPins.CanvasOffset(width, height, x, y)
    if ox == nil then return false end
    if type(pin.ClearAllPoints) == "function" then pin:ClearAllPoints() end
    pin:SetPoint("CENTER", canvas, "TOPLEFT", ox, oy)
    return true
end

--- Remember the target and anchor it once the canvas has a size. Scale stays 1:
--- on this canvas a counter-scale moves the SetPoint offset.
function MapPins.FinishForeverPin(pin, x, y)
    if type(pin) ~= "table" then return false end
    if type(x) == "number" and math.abs(x) > 1 then x = x / 100 end
    if type(y) == "number" and math.abs(y) > 1 then y = y / 100 end
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    pin._taX, pin._taY = x, y
    MapPins._foreverPin = pin
    if type(pin.SetScalingLimits) == "function" then
        pcall(pin.SetScalingLimits, pin, 0, 1, 1)
    end
    if type(pin.SetScale) == "function" then
        pcall(pin.SetScale, pin, 1)
    end
    local placed = MapPins.AnchorPin(pin, x, y)
    if placed and type(pin.SetPosition) == "function" then
        pcall(pin.SetPosition, pin, x, y)
        MapPins.AnchorPin(pin, x, y)
    elseif not placed and type(pin.ClearAllPoints) == "function" then
        -- A 0x0 canvas would have anchored at the origin. Drop that point
        -- until a later size change can place the target.
        pin:ClearAllPoints()
    end
    return placed
end

function MapPins.DataProvider:OnCanvasSizeChanged()
    local pin = MapPins._foreverPin
    if type(pin) ~= "table" or type(pin._taX) ~= "number" then return end
    MapPins.FinishForeverPin(pin, pin._taX, pin._taY)
end

function MapPins.DataProvider:OnShow()
    self:OnCanvasSizeChanged()
end

function MapPins.DataProvider:RefreshAllData(fromOnShow)
    self:RemoveAllData()

    if self.PlaceForeverPin and self:PlaceForeverPin() then return end

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

if type(CreateFromMixins) == "function" and type(MapCanvasPinMixin) == "table" then
    TAMapPinMixin = CreateFromMixins(MapCanvasPinMixin)
else
    TAMapPinMixin = {}
end

function TAMapPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    if TA.flavor == "forever" then
        -- Offsets are in the pin's own units on this canvas. scaleFactor 0
        -- keeps scale at 1 so the anchor is not pulled toward the corner.
        self:SetScalingLimits(0, 1, 1)
    else
        self:SetScalingLimits(1, 0.5, 1.5)
    end
end

function TAMapPinMixin:OnAcquired(x, y, step, relNum, color, isCurrent)
    if type(x) == "number" and math.abs(x) > 1 then x = x / 100 end
    if type(y) == "number" and math.abs(y) > 1 then y = y / 100 end
    if step and step.foreverPin and type(x) == "number" and type(y) == "number" then
        MapPins.FinishForeverPin(self, x, y)
    elseif type(x) == "number" and type(y) == "number" and type(self.SetPosition) == "function" then
        self:SetPosition(x, y)
    end

    local size = isCurrent and (PIN_SIZE_BASE * 1.4) or PIN_SIZE_BASE
    self:SetSize(size, size)

    -- Store for tooltip
    self.step     = step
    self.relNum   = relNum
    self.isCurrent = isCurrent

    -- Background dot. Estimated coordinates use the hollow ring instead.
    if not self.bg then
        self.bg = self:CreateTexture(nil, "BACKGROUND")
        self.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.bg:SetAllPoints()
    end
    if not self._ring then
        self._ring = self:CreateTexture(nil, "ARTWORK")
        self._ring:SetAllPoints()
        self._ring:SetTexture(U.TEX_RING)
    end

    -- Border (slightly larger, dark)
    if not self.border then
        self.border = self:CreateTexture(nil, "BORDER")
        self.border:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.border:SetPoint("TOPLEFT", -1, 1)
        self.border:SetPoint("BOTTOMRIGHT", 1, -1)
    end

    local estimated = U.CoordsEstimated(step)
    if estimated then
        self.bg:Hide()
        self.border:Hide()
        self._ring:Show()
        U.PaintWaypointMark(self._ring, true)
    else
        self._ring:Hide()
        self.bg:Show()
        self.border:Show()
        self.bg:SetVertexColor(color[1], color[2], color[3], color[4] * 0.85)
        self.border:SetVertexColor(0, 0, 0, 0.7)
    end

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

    if self.step.questID and C_QuestLog and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local okTitle, questTitle = pcall(C_QuestLog.GetTitleForQuestID, self.step.questID)
        if okTitle and type(questTitle) == "string" and questTitle ~= "" then
            GameTooltip:AddLine("Quest: " .. questTitle, 0.4, 0.78, 1.0)
        end
    end

    if self.isCurrent then
        GameTooltip:AddLine(("|cFF4AFF7A" .. ToonAge.Utils.Glyph("arrowLeft", "4AFF7A") .. " Current Step|r"))
    end
    U.AddEstimatedTip(GameTooltip, self.step)

    GameTooltip:Show()
end

function TAMapPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

-- ── Module lifecycle ──────────────────────────────────────────────────────────

function MapPins:Init()
    if type(MapCanvasDataProviderMixin) ~= "table" then return end
    if type(self.DataProvider) ~= "table" or type(self.DataProvider.RefreshAllData) ~= "function" then
        return
    end
    -- Wait for WorldMapFrame to exist (it's load-on-demand)
    -- Hook into it when it first opens
    if WorldMapFrame and type(WorldMapFrame.AddDataProvider) == "function" then
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
