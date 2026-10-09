-- ToonAge/Modules/Arrow.lua (Classic — MoP 50504)
-- Draggable, scroll-to-resize, right-click-lockable HUD arrow.
-- Layout: gold arrow -> white distance -> grey ETA -> gold objective title
--
-- Classic adaptation:
--   - Removed C_QuestLog.GetNextWaypoint (doesn't exist in MoP Classic)
--   - Removed C_SuperTrack references
--   - Removed C_Navigation references
--   - Resolves coords from guide steps + CoordResolver only
--   - GetPlayerFacing() works in MoP Classic
--   - C_Map.GetBestMapForUnit exists in MoP Classic
--
-- Bearing math (WoW specifics):
--   Map-y increases SOUTHWARD, so atan2(dx, -dy) gives a clockwise bearing
--   where 0 = North, matching GetPlayerFacing() conventions.

local TA = ToonAge
local U  = TA.Utils

local Arrow = {}
TA:RegisterModule("Arrow", Arrow)

Arrow.frame        = nil
Arrow.throttle     = 0
Arrow.currentAngle = nil   -- lerped rotation state; nil = snap on next Tick
Arrow.manualWaypoint = nil -- { map=mapID, x=0-1, y=0-1, title=string } — set by /ta way
local UPDATE_HZ  = 0.03   -- ~33 Hz for smooth rotation
local LERP_RATE  = 0.35   -- fraction of the remaining angle closed per tick

local ARROW_W, ARROW_H = 80, 100

-- Shortest-path angle interpolation
local function LerpAngle(current, target, factor)
    local twoPi = math.pi * 2
    local diff  = (target - current + math.pi) % twoPi - math.pi
    return current + diff * factor
end

-- ── Helpers ───────────────────────────────────────────────────────────────

local function GetTargetStep()
    local QT = TA:GetModule("QuestTracker")
    if not QT then return nil end
    if not (QT.guideID and QT.stepIdx) then return nil end
    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return nil end
    return guide.steps[QT.stepIdx]
end

local function PaintEstimate(f, step)
    f._estimateStep = step
end

local function HideArrowArt(f)
    if f.arrowTex then f.arrowTex:Hide() end
    if f.arrivedTex then f.arrivedTex:Hide() end
end

local function GetTravelSpeed()
    local TM = TA:GetModule("TravelModes")
    return (TM and TM:GetSpeed()) or 7
end

-- Resolve a step's map/x/y using CoordResolver (Classic priority chain)
-- No C_QuestLog.GetNextWaypoint or C_SuperTrack in MoP Classic.
local function GetEffectiveCoord(step)
    -- PRIORITY 1: CoordResolver (QuestPOI + guide coords + adjacent steps)
    local CR = TA:GetModule("CoordResolver")
    if CR and step.questID then
        local resolved = CR:Resolve(step.questID, step, step.objectiveIndex)
        if resolved and resolved.map and resolved.map > 0
           and resolved.x and (resolved.x > 0 or resolved.y > 0)
           and resolved.x <= 1 and resolved.y <= 1 then
            return resolved.map, resolved.x, resolved.y
        end
    end

    -- PRIORITY 2: Manual guide coords
    if step.coord then
        local coordMap = step.coord.map or 0
        local cx, cy   = step.coord.x or 0, step.coord.y or 0
        if coordMap ~= 0 or cx ~= 0 or cy ~= 0 then
            return coordMap, cx, cy
        end
    end

    -- Nothing available
    return 0, 0, 0
end

-- Exposed so QuestTracker can reuse the same resolution
Arrow.GetEffectiveCoord = GetEffectiveCoord

-- ── Frame construction ────────────────────────────────────────────────────

function Arrow:InitFrame()
    local f = CreateFrame("Button", "TAWaypointArrow", UIParent)
    f:SetSize(ARROW_W, ARROW_H)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(fr)
        fr:StopMovingOrSizing()
        if TA.charDB then
            TA.charDB.arrow   = TA.charDB.arrow or {}
            TA.charDB.arrow.x = fr:GetLeft()
            TA.charDB.arrow.y = fr:GetTop()
        end
    end)

    -- Scroll-wheel resize, 32–64 px on the texture itself.
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(fr, delta)
        local size = U.WaypointSize((fr._arrowSize or U.WAYPOINT_SIZE_DEFAULT) + delta * 4, false)
        fr._arrowSize = size
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.size = size end
    end)

    -- Right-click to toggle drag lock
    f:RegisterForClicks("RightButtonUp")
    f:SetScript("OnClick", function(fr, button)
        if button ~= "RightButton" then return end
        TA.charDB.arrow = TA.charDB.arrow or {}
        TA.charDB.arrow.locked = not TA.charDB.arrow.locked
        if TA.charDB.arrow.locked then
            fr:RegisterForDrag()
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Locked. Right-click to unlock.")
        else
            fr:RegisterForDrag("LeftButton")
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Unlocked. Drag to move.")
        end
    end)

    f:SetScript("OnEnter", function(fr)
        GameTooltip:SetOwner(fr, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Guide Arrow", 1, 0.82, 0)
        GameTooltip:AddLine("Right-click: Lock / Unlock", 1, 1, 1)
        GameTooltip:AddLine("Scroll: Resize", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move", 0.7, 0.7, 0.7)
        U.AddEstimatedTip(GameTooltip, fr._estimateStep)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Restore saved state. Size is pixels (default 48), not the old frame scale.
    local saved = TA.charDB and TA.charDB.arrow
    f._arrowSize = U.WaypointSize(saved and saved.size, false)
    f:SetScale(1)
    if saved and saved.x and saved.y then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
    if saved and saved.locked then f:RegisterForDrag() else f:RegisterForDrag("LeftButton") end
    f:Hide()

    -- Full-colour waypoint. SetRotation turns it around its centre.
    -- No SetVertexColor: the texture is already the colour it should be.
    local arrowTex = f:CreateTexture(nil, "ARTWORK")
    arrowTex:SetSize(U.WAYPOINT_SIZE_DEFAULT, U.WAYPOINT_SIZE_DEFAULT)
    arrowTex:SetPoint("TOP", f, "TOP", 0, -4)
    arrowTex:SetTexture(U.TEX_WAYPOINT)
    f.arrowTex = arrowTex

    local arrivedTex = f:CreateTexture(nil, "ARTWORK")
    arrivedTex:SetSize(U.WAYPOINT_SIZE_DEFAULT, U.WAYPOINT_SIZE_DEFAULT)
    arrivedTex:SetPoint("TOP", f, "TOP", 0, -4)
    arrivedTex:SetTexture(U.TEX_WAYPOINT_ARRIVED)
    arrivedTex:Hide()
    f.arrivedTex = arrivedTex

    local distF = f:CreateFontString(nil, "OVERLAY")
    distF:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    distF:SetTextColor(1, 1, 1, 1)
    distF:SetPoint("TOP", arrowTex, "BOTTOM", 0, 0)
    distF:SetJustifyH("CENTER")
    f.distF = distF

    local etaF = f:CreateFontString(nil, "OVERLAY")
    etaF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    etaF:SetTextColor(0.80, 0.80, 0.80, 1)
    etaF:SetPoint("TOP", distF, "BOTTOM", 0, -2)
    etaF:SetJustifyH("CENTER")
    f.etaF = etaF

    local titleF = f:CreateFontString(nil, "OVERLAY")
    titleF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    titleF:SetTextColor(1, 0.82, 0, 1)
    titleF:SetPoint("TOP", etaF, "BOTTOM", 0, -4)
    titleF:SetWidth(180)
    titleF:SetWordWrap(false)
    titleF:SetJustifyH("CENTER")
    f.titleF = titleF

    f:SetScript("OnUpdate", function(_, elapsed)
        self.throttle = self.throttle + elapsed
        if self.throttle < UPDATE_HZ then return end
        self.throttle = 0
        self:Tick(f)
    end)

    self.frame = f
end

-- ETA speed smoothing state
local speedSamples = { 0, 0 }
local lastDist     = nil
local lastTime     = 0

-- ── Per-tick update ───────────────────────────────────────────────────────

function Arrow:Tick(f)
    if U.InInstance() then
        U.RevealWaypoint(f, false)
        return
    end

    -- ── MANUAL WAYPOINT (from /ta way) takes priority over guide step ──
    local coordMap, cx, cy, label
    local isManualWP = false
    local step
    PaintEstimate(f, nil)

    if self.manualWaypoint then
        coordMap = self.manualWaypoint.map
        cx       = self.manualWaypoint.x
        cy       = self.manualWaypoint.y
        label    = self.manualWaypoint.title or "Waypoint"
        isManualWP = true
    else
        step = GetTargetStep()
        PaintEstimate(f, (step and step.coord) and step or nil)

        if not step or not step.coord then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("---")
            f.etaF:SetText("")
            f.titleF:SetText("No Waypoint")
            self._arrived = false
            return
        end

        -- Narrative / no-location steps
        if step.type == "text" then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("")
            f.etaF:SetText("")
            f.titleF:SetText(step.text or "")
            self._arrived = false
            return
        end

        -- Objective label: quest title if available, else step text
        label = step.text or ""
        if step.questID and C_QuestLog and C_QuestLog.GetTitleForQuestID then
            local qTitle = C_QuestLog.GetTitleForQuestID(step.questID)
            if qTitle and qTitle ~= "" then label = qTitle end
        end

        coordMap, cx, cy = GetEffectiveCoord(step)

        if coordMap == 0 and cx == 0 and cy == 0 then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("No Loc")
            f.etaF:SetText("")
            self._arrived = false
            return
        end
    end

    -- Truncate long labels
    if #label > 35 then label = label:sub(1, 32) .. "..." end
    f.titleF:SetText(label)

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then
        U.RevealWaypoint(f, false)
        return
    end

    -- Cross-zone detection
    if coordMap ~= 0 and coordMap ~= currentMap then
        -- Check parent-zone containment
        local isSameArea = false
        local checkMap = currentMap
        for _ = 1, 5 do
            local mapInfo = C_Map.GetMapInfo(checkMap)
            if not mapInfo then break end
            if mapInfo.parentMapID == coordMap then isSameArea = true; break end
            if mapInfo.parentMapID and mapInfo.parentMapID > 0 then
                checkMap = mapInfo.parentMapID
            else
                break
            end
        end
        if not isSameArea then
            checkMap = coordMap
            for _ = 1, 5 do
                local mapInfo = C_Map.GetMapInfo(checkMap)
                if not mapInfo then break end
                if mapInfo.parentMapID == currentMap then isSameArea = true; break end
                if mapInfo.parentMapID and mapInfo.parentMapID > 0 then
                    checkMap = mapInfo.parentMapID
                else
                    break
                end
            end
        end

        if isSameArea then
            coordMap = currentMap
        else
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("Diff Zone")
            f.etaF:SetText("")
            self._arrived = false
            return
        end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then
        U.RevealWaypoint(f, false)
        return
    end
    local px, py = pos:GetXY()
    if not px or not py or (px == 0 and py == 0) then
        U.RevealWaypoint(f, false)
        return
    end
    U.RevealWaypoint(f, true)

    local dx          = cx - px
    local dy          = cy - py
    local bearing     = math.atan2(dx, -dy)

    -- GetPlayerFacing() works in MoP Classic
    local facing = GetPlayerFacing()
    if not facing then
        -- Fallback: infer from movement direction
        if self._lastPx and self._lastPy then
            local mdx = px - self._lastPx
            local mdy = py - self._lastPy
            local moved = math.sqrt(mdx * mdx + mdy * mdy)
            if moved > 0.0001 then
                facing = math.atan2(mdx, -mdy)
            else
                facing = self._lastFacing or 0
            end
        else
            facing = 0
        end
    end
    self._lastPx = px
    self._lastPy = py
    self._lastFacing = facing

    local targetAngle = bearing - facing
    local yards = U.ComputeDistance(px, py, cx, cy)
    local hollow = U.WaypointHollow(step)
    local _, arrived = U.WaypointArrowAlpha(yards)

    U.PaintQuestArrow(f.arrowTex, f.arrivedTex, {
        yards = yards, angle = targetAngle, hollow = hollow, size = f._arrowSize,
    })
    f.distF:SetText(U.FormatDistance(yards, hollow))

    if arrived then
        if not self._arrived then
            self._arrived = true
            self._arrivedTime = GetTime()
            self.currentAngle = nil
        end
        f.etaF:SetText("")
        if isManualWP and self._arrivedTime and (GetTime() - self._arrivedTime > 3) then
            self.manualWaypoint = nil
            self._arrived = false
            self._arrivedTime = nil
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Waypoint reached — cleared.")
        end
        return
    end

    self._arrived = false

    -- ── SPEED-SMOOTHED ETA ────────────────────────────────────────────
    local now = GetTime()
    local dt  = now - lastTime
    if dt > 0.1 and lastDist then
        local moved = lastDist - yards
        local instantSpeed = moved / dt
        speedSamples[1] = speedSamples[2]
        speedSamples[2] = instantSpeed
    end
    lastDist = yards
    lastTime = now

    local avgSpeed = (speedSamples[1] + speedSamples[2]) / 2
    if avgSpeed > 0.5 then
        local eta = yards / avgSpeed
        if eta < 3600 then
            local mins = math.floor(eta / 60)
            local secs = math.floor(eta % 60)
            f.etaF:SetText(string.format("|cFFCCCCCC%d:%02d ETA|r", mins, secs))
        else
            f.etaF:SetText("")
        end
    elseif avgSpeed < -0.5 then
        f.etaF:SetText("|cFFFF6666moving away|r")
    else
        local fallbackSpeed = GetTravelSpeed()
        if fallbackSpeed > 0 then
            f.etaF:SetText(U.FormatETA(yards, fallbackSpeed))
        else
            f.etaF:SetText("")
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────

--- Set a manual waypoint that the arrow will point to, overriding guide navigation.
function Arrow:SetWaypoint(mapID, x, y, title)
    if not mapID or mapID == 0 then
        mapID = C_Map.GetBestMapForUnit("player") or 0
    end
    self.manualWaypoint = {
        map   = mapID,
        x     = x,
        y     = y,
        title = title or string.format("%.1f, %.1f", x * 100, y * 100),
    }
    self._arrived = false
    self._arrivedTime = nil

    if self.frame and not self.frame:IsVisible() then
        self.frame:Show()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = true end
    end
end

--- Clear the current manual waypoint
function Arrow:ClearWaypoint()
    self.manualWaypoint = nil
    self._arrived = false
    self._arrivedTime = nil
end

--- Parse a TomTom-compatible /way string and set the arrow.
function Arrow:ParseWayCommand(args)
    if not args or args == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Usage:")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way <x> <y> [description]|r — set waypoint on current map")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way <mapID> <x> <y> [description]|r — set waypoint on specific map")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way clear|r — remove manual waypoint")
        if self.manualWaypoint then
            local wp = self.manualWaypoint
            TA:Raw(TA.LOG.OUTPUT, string.format("  Current: map %d — %.1f, %.1f (%s)",
                wp.map, wp.x * 100, wp.y * 100, wp.title or ""))
        end
        return
    end

    args = args:gsub("(%d),(%d)", "%1.%2")
    args = args:gsub(",%s*", " ")

    local tokens = {}
    for token in args:gmatch("%S+") do
        table.insert(tokens, token)
    end

    local first = tokens[1] and tokens[1]:lower()
    if first == "clear" or first == "remove" or first == "off" then
        self:ClearWaypoint()
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Manual waypoint cleared.")
        return
    end

    local mapID = nil
    local xRaw, yRaw, descStart

    if tokens[1] and tokens[1]:match("^#(%d+)$") then
        mapID = tonumber(tokens[1]:match("^#(%d+)$"))
        xRaw = tonumber(tokens[2])
        yRaw = tonumber(tokens[3])
        descStart = 4
    else
        local n1 = tonumber(tokens[1])
        local n2 = tonumber(tokens[2])
        local n3 = tonumber(tokens[3])

        if n1 and n2 and n3 then
            if n1 == math.floor(n1) and n1 > 100 then
                mapID = n1
                xRaw  = n2
                yRaw  = n3
                descStart = 4
            else
                xRaw = n1
                yRaw = n2
                descStart = 3
            end
        elseif n1 and n2 then
            xRaw = n1
            yRaw = n2
            descStart = 3
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Invalid format. Examples:")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way 45.2 67.8|r")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way 2393 45.2 67.8 My Spot|r")
            return
        end
    end

    if not xRaw or not yRaw then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Could not parse coordinates.")
        return
    end

    if xRaw < 0 or xRaw > 100 or yRaw < 0 or yRaw > 100 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Coordinates must be 0–100 (e.g. 45.2 67.8).")
        return
    end

    local x = xRaw / 100
    local y = yRaw / 100

    local desc = nil
    if descStart and tokens[descStart] then
        desc = table.concat(tokens, " ", descStart)
    end

    self:SetWaypoint(mapID, x, y, desc)

    local mapStr = ""
    if mapID and mapID > 0 then
        local mapInfo = C_Map.GetMapInfo(mapID)
        mapStr = mapInfo and mapInfo.name or ("map " .. mapID)
        mapStr = " in " .. mapStr
    end
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA Arrow]|r Waypoint set: |cFF4AFF7A%.1f, %.1f|r%s%s",
        xRaw, yRaw, mapStr, desc and (" — " .. desc) or ""))
end

function Arrow:Toggle()
    if not self.frame then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA]|r Arrow frame not initialised.")
        return
    end
    if self.frame:IsVisible() then
        self.frame:Hide()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = false end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Hidden.")
    else
        self.frame:Show()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = true end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Visible.")
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────

function Arrow:Init()
    self:InitFrame()
    local saved = TA.charDB and TA.charDB.arrow
    if saved and saved.visible then self.frame:Show() end
end

Arrow.SlashCommands = {
    arrow = function(self) self:Toggle() end,
}
