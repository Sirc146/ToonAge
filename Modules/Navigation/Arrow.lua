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
    if not (QT and QT.guideID and QT.stepIdx) then return nil end
    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return nil end
    return guide.steps[QT.stepIdx]
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

    -- Scroll-wheel resize (0.5x – 3.0x)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(fr, delta)
        local s = math.max(0.5, math.min(fr:GetScale() + delta * 0.1, 3.0))
        fr:SetScale(s)
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.scale = s end
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
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Restore saved state
    local saved = TA.charDB and TA.charDB.arrow
    if saved and saved.scale then f:SetScale(saved.scale) end
    if saved and saved.x and saved.y then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
    if saved and saved.locked then f:RegisterForDrag() else f:RegisterForDrag("LeftButton") end
    f:Hide()

    -- Gold arrow (active, rotated each tick)
    local arrowTex = f:CreateTexture(nil, "ARTWORK")
    arrowTex:SetSize(52, 52)
    arrowTex:SetPoint("TOP", f, "TOP", 0, -4)
    arrowTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    arrowTex:SetVertexColor(1, 0.82, 0, 1)
    f.arrowTex = arrowTex

    -- Grey arrow (inactive — no coord or wrong zone)
    local greyTex = f:CreateTexture(nil, "ARTWORK")
    greyTex:SetSize(52, 52)
    greyTex:SetPoint("TOP", f, "TOP", 0, -4)
    greyTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    greyTex:SetVertexColor(0.35, 0.30, 0.20, 0.45)
    greyTex:Hide()
    f.greyTex = greyTex

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

-- ── Color gradient helper ─────────────────────────────────────────────────
local function ColorGradient(t, br,bg,bb, mr,mg,mb, gr,gg,gb)
    if t >= 1 then return gr, gg, gb end
    if t <= 0 then return br, bg, bb end
    if t < 0.5 then
        local p = t * 2
        return br + (mr - br) * p, bg + (mg - bg) * p, bb + (mb - bb) * p
    else
        local p = (t - 0.5) * 2
        return mr + (gr - mr) * p, mg + (gg - mg) * p, mb + (gb - mb) * p
    end
end

-- ETA speed smoothing state
local speedSamples = { 0, 0 }
local lastDist     = nil
local lastTime     = 0
local ARRIVAL_DIST = 10   -- yards — threshold for arrival state
local ARRIVAL_PULSE_RATE = 3  -- pulses per second

-- ── Per-tick update ───────────────────────────────────────────────────────

function Arrow:Tick(f)
    -- ── MANUAL WAYPOINT (from /ta way) takes priority over guide step ──
    local coordMap, cx, cy, label
    local isManualWP = false

    if self.manualWaypoint then
        coordMap = self.manualWaypoint.map
        cx       = self.manualWaypoint.x
        cy       = self.manualWaypoint.y
        label    = self.manualWaypoint.title or "Waypoint"
        isManualWP = true
    else
        local step = GetTargetStep()

        if not step or not step.coord then
            f.arrowTex:Hide()
            f.greyTex:Show()
            f.distF:SetText("---")
            f.etaF:SetText("")
            f.titleF:SetText("No Waypoint")
            self._arrived = false
            return
        end

        -- Narrative / no-location steps
        if step.type == "text" then
            f.arrowTex:Hide()
            f.greyTex:Hide()
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
            f.arrowTex:Hide()
            f.greyTex:Show()
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
    if not currentMap then return end

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
            f.arrowTex:Hide()
            f.greyTex:Show()
            f.distF:SetText("Diff Zone")
            f.etaF:SetText("")
            self._arrived = false
            return
        end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or not py or (px == 0 and py == 0) then return end

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

    -- ── ARRIVAL STATE ─────────────────────────────────────────────────
    if yards <= ARRIVAL_DIST then
        if not self._arrived then
            self._arrived = true
            self._arrivedTime = GetTime()
            self.currentAngle = nil
        end
        f.greyTex:Hide()
        f.arrowTex:Show()
        f.arrowTex:SetRotation(0)

        local pulse = 0.6 + 0.4 * math.sin(GetTime() * ARRIVAL_PULSE_RATE * math.pi * 2)
        f.arrowTex:SetVertexColor(0.20, 0.92, 0.40, pulse)

        f.distF:SetText("|cFF4AFF7AArrived|r")
        f.etaF:SetText("")

        -- Auto-clear manual waypoints 3 seconds after arrival
        if isManualWP and self._arrivedTime and (GetTime() - self._arrivedTime > 3) then
            self.manualWaypoint = nil
            self._arrived = false
            self._arrivedTime = nil
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Waypoint reached — cleared.")
        end
        return
    end

    self._arrived = false
    f.greyTex:Hide()
    f.arrowTex:Show()

    -- ── DIRECTIONAL COLOR GRADIENT ────────────────────────────────────
    local perc = math.abs((math.pi - math.abs(targetAngle)) / math.pi)
    perc = math.max(0, math.min(1, perc))

    local r, g, b = ColorGradient(perc,
        0.90, 0.20, 0.15,   -- red (facing away)
        1.00, 0.80, 0.10,   -- yellow (sideways)
        0.20, 0.92, 0.40    -- green (facing toward)
    )

    -- ── ROTATION (direct) ─────────────────────────────────────────────
    f.arrowTex:SetRotation(targetAngle)
    f.arrowTex:SetVertexColor(r, g, b, 1)

    -- ── DISTANCE ──────────────────────────────────────────────────────
    f.distF:SetText(U.FormatDistance(yards))

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
