-- ToonAge/Modules/MapPins.lua (Classic — MoP 50504)
-- World map pin overlay showing upcoming guide step waypoints.
--
-- Classic adaptation:
--   - MoP Classic's WorldMapFrame exists but may NOT have the full
--     MapCanvasDataProviderMixin / AddDataProvider pattern.
--   - Uses simple CreateFrame pins parented to WorldMapFrame instead.
--   - Pins are positioned using WorldMapFrame:GetCanvas() or direct
--     SetPoint with normalized coordinates on the map's scroll child.
--   - Refreshes when the map opens or step advances.
--   - No taint concerns (Classic is more permissive with map manipulation).
--
-- Pin positioning strategy:
--   MoP Classic WorldMapFrame uses WorldMapDetailFrame as the canvas area.
--   Pins are placed at normalized (x, y) coordinates within that frame.

local TA = ToonAge

local MapPins = {}
TA:RegisterModule("MapPins", MapPins)

-- ── Constants ─────────────────────────────────────────────────────────────────

local MAX_PINS       = 8       -- max pins shown on world map
local PIN_SIZE_BASE  = 20      -- pixel size of each pin

-- Pin colors by step type
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

-- ── State ─────────────────────────────────────────────────────────────────────

MapPins._pins = {}        -- pool of reusable pin frames
MapPins._activePinCount = 0
MapPins._mapCanvas = nil  -- the frame we parent pins to

-- ── Pin creation ──────────────────────────────────────────────────────────────

local function CreatePin(index, parent)
    local pin = CreateFrame("Frame", "TAMapPin" .. index, parent)
    pin:SetSize(PIN_SIZE_BASE, PIN_SIZE_BASE)
    pin:SetFrameStrata("TOOLTIP")  -- above map elements
    pin:SetFrameLevel(100 + index)

    -- Background dot
    local bg = pin:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints()
    pin.bg = bg

    -- Border (slightly larger, dark)
    local border = pin:CreateTexture(nil, "BORDER")
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetVertexColor(0, 0, 0, 0.7)
    pin.border = border

    -- Number label
    local numLabel = pin:CreateFontString(nil, "OVERLAY")
    numLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    numLabel:SetPoint("CENTER")
    numLabel:SetTextColor(1, 1, 1, 1)
    pin.numLabel = numLabel

    -- Tooltip support
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        if not self.stepData then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local title = self.stepData.text or "Guide Step"
        if #title > 50 then title = title:sub(1, 47) .. "..." end
        local typeLabel = (self.stepData.type or "quest")
        typeLabel = typeLabel:sub(1,1):upper() .. typeLabel:sub(2)
        GameTooltip:SetText(string.format("|cFFFFD100[%d]|r %s", self.relNum or 1, title), 1, 1, 1)
        GameTooltip:AddLine(typeLabel, 0.7, 0.7, 0.7)
        if self.stepData.questID and C_QuestLog and C_QuestLog.GetTitleForQuestID then
            local qTitle = C_QuestLog.GetTitleForQuestID(self.stepData.questID)
            if qTitle then
                GameTooltip:AddLine("Quest: " .. qTitle, 0.4, 0.78, 1.0)
            end
        end
        if self.isCurrent then
            GameTooltip:AddLine("|cFF4AFF7A← Current Step|r")
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    pin:Hide()
    return pin
end

local function GetPin(index, parent)
    if not MapPins._pins[index] then
        MapPins._pins[index] = CreatePin(index, parent)
    end
    return MapPins._pins[index]
end

-- ── Get the map canvas frame ──────────────────────────────────────────────────
-- In MoP Classic, the world map structure varies. Try multiple approaches:
--   1. WorldMapFrame.ScrollContainer.Child (modern Classic)
--   2. WorldMapFrame:GetCanvas() (if MapCanvasMixin present)
--   3. WorldMapDetailFrame (legacy)
--   4. WorldMapFrame directly as fallback

local function GetMapCanvasFrame()
    if MapPins._mapCanvas then return MapPins._mapCanvas end

    if WorldMapFrame then
        -- Modern Classic (Cata+) often has ScrollContainer
        if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
            MapPins._mapCanvas = WorldMapFrame.ScrollContainer.Child
            return MapPins._mapCanvas
        end
        -- MapCanvasMixin style
        if WorldMapFrame.GetCanvas then
            local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
            if ok and canvas then
                MapPins._mapCanvas = canvas
                return MapPins._mapCanvas
            end
        end
        -- Legacy WorldMapDetailFrame
        if WorldMapDetailFrame then
            MapPins._mapCanvas = WorldMapDetailFrame
            return MapPins._mapCanvas
        end
        -- Last resort: parent to WorldMapFrame itself
        MapPins._mapCanvas = WorldMapFrame
        return MapPins._mapCanvas
    end
    return nil
end

-- ── Get current map ID from WorldMapFrame ─────────────────────────────────────

local function GetWorldMapID()
    if WorldMapFrame and WorldMapFrame.GetMapID then
        return WorldMapFrame:GetMapID()
    end
    -- Fallback: use player's current map
    return C_Map.GetBestMapForUnit("player")
end

-- ── Refresh pins ──────────────────────────────────────────────────────────────

function MapPins:Refresh()
    -- Hide all current pins
    for i = 1, self._activePinCount do
        if self._pins[i] then self._pins[i]:Hide() end
    end
    self._activePinCount = 0

    -- Check if WorldMapFrame is open
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    local canvas = GetMapCanvasFrame()
    if not canvas then return end

    local mapID = GetWorldMapID()
    if not mapID then return end

    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide or not guide.steps then return end

    local canvasW = canvas:GetWidth()
    local canvasH = canvas:GetHeight()
    if canvasW == 0 or canvasH == 0 then return end

    local pinCount = 0

    for i = QT.stepIdx, #guide.steps do
        local step = guide.steps[i]
        if not step then break end
        if pinCount >= MAX_PINS then break end

        repeat  -- continue wrapper
            if step.type == "text" then break end
            if step.noArrow then break end

            -- Only use pre-stored guide coords (safe, no taint)
            local coordMap, cx, cy = 0, 0, 0
            if step.coord then
                coordMap = step.coord.map or 0
                cx = step.coord.x or 0
                cy = step.coord.y or 0
            end

            if coordMap == 0 and cx == 0 and cy == 0 then break end
            if coordMap ~= 0 and coordMap ~= mapID then break end

            pinCount = pinCount + 1

            local pin = GetPin(pinCount, canvas)
            local relNum = i - QT.stepIdx + 1
            local color = PIN_COLORS[step.type] or PIN_COLORS.default
            local isCurrent = (i == QT.stepIdx)
            local size = isCurrent and (PIN_SIZE_BASE * 1.4) or PIN_SIZE_BASE

            -- Position pin at normalized coordinates on the canvas
            pin:SetParent(canvas)
            pin:SetSize(size, size)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", cx * canvasW, -cy * canvasH)

            -- Apply color
            pin.bg:SetVertexColor(color[1], color[2], color[3], color[4] * 0.85)

            -- Number label
            pin.numLabel:SetText(tostring(relNum))

            -- Store data for tooltip
            pin.stepData = step
            pin.relNum = relNum
            pin.isCurrent = isCurrent

            pin:Show()
        until true
    end

    self._activePinCount = pinCount
end

-- ── Hide all pins ─────────────────────────────────────────────────────────────

function MapPins:HideAll()
    for i = 1, #self._pins do
        if self._pins[i] then self._pins[i]:Hide() end
    end
    self._activePinCount = 0
end

-- ── Module lifecycle ──────────────────────────────────────────────────────────

function MapPins:Init()
    -- Hook into world map show/hide events
    local hookFrame = CreateFrame("Frame")
    hookFrame:RegisterEvent("ADDON_LOADED")

    -- In MoP Classic, WorldMapFrame may already exist
    if WorldMapFrame then
        -- Hook the map's Show
        hooksecurefunc(WorldMapFrame, "Show", function()
            -- Delay slightly to let the map finish rendering
            C_Timer.After(0.1, function()
                MapPins:Refresh()
            end)
        end)

        -- Also hook OnShow for cases where Show() isn't called directly
        if WorldMapFrame:GetScript("OnShow") then
            WorldMapFrame:HookScript("OnShow", function()
                C_Timer.After(0.1, function()
                    MapPins:Refresh()
                end)
            end)
        else
            WorldMapFrame:SetScript("OnShow", function()
                C_Timer.After(0.1, function()
                    MapPins:Refresh()
                end)
            end)
        end

        -- Hook OnHide to clean up
        WorldMapFrame:HookScript("OnHide", function()
            MapPins:HideAll()
        end)

        hookFrame:UnregisterEvent("ADDON_LOADED")
    else
        -- Wait for Blizzard_WorldMap to load
        hookFrame:SetScript("OnEvent", function(f, event, addon)
            if addon == "Blizzard_WorldMap" or (WorldMapFrame and WorldMapFrame.Show) then
                if WorldMapFrame then
                    hooksecurefunc(WorldMapFrame, "Show", function()
                        C_Timer.After(0.1, function()
                            MapPins:Refresh()
                        end)
                    end)
                    WorldMapFrame:HookScript("OnHide", function()
                        MapPins:HideAll()
                    end)
                end
                f:UnregisterAllEvents()
            end
        end)
    end

    -- Refresh on map zone change.
    --
    -- WORLD_MAP_UPDATE was removed in the Legion 7.0 world-map rewrite, and MoP
    -- Classic (50504) runs the modern engine, so registering it raised
    -- "Attempt to register unknown event" -- measured live 2026-08-02.
    --
    -- That threw *before* the SetScript below ever ran, so the OnEvent handler
    -- was never installed and the ADDON_LOADED branch never fired: one bad
    -- event name silently disabled the entire MapPins module, not just the
    -- zone-change refresh.
    --
    -- Not replaced with a guessed substitute. The map-open path is already
    -- covered by the WorldMapFrame Show/OnHide hooks in the ADDON_LOADED branch
    -- below, so the only loss is refresh-on-zone-change while the map stays
    -- open. The correct modern replacement is unmeasured -- resolve it from a
    -- live /dump before writing one.
    hookFrame:SetScript("OnEvent", function(f, event, ...)
        if event == "ADDON_LOADED" then
            local addon = ...
            if addon == "Blizzard_WorldMap" or (WorldMapFrame and WorldMapFrame.Show) then
                if WorldMapFrame then
                    hooksecurefunc(WorldMapFrame, "Show", function()
                        C_Timer.After(0.1, function()
                            MapPins:Refresh()
                        end)
                    end)
                    WorldMapFrame:HookScript("OnHide", function()
                        MapPins:HideAll()
                    end)
                end
                f:UnregisterEvent("ADDON_LOADED")
            end
        end
    end)
end

MapPins.SlashCommands = {}
