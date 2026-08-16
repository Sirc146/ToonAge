-- ToonAge/Modules/Arrow.lua
-- Draggable, scroll-to-resize, right-click-lockable HUD arrow.
-- Layout: gold arrow -> white distance -> grey ETA -> gold objective title
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
local LERP_RATE  = 0.35   -- fraction of the remaining angle closed per tick (higher = more responsive)

local ARROW_W, ARROW_H = 80, 100

-- Shortest-path angle interpolation (avoids spinning the long way around
-- when the target bearing crosses the -pi/pi wrap boundary).
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

-- Distance/ETA math lives in Core/Utils.lua (TA.Utils) so QuestTracker.lua
-- can show identical numbers for the same step without duplicating it here.
local function GetTravelSpeed()
    local TM = TA:GetModule("TravelModes")
    return (TM and TM:GetSpeed()) or 7
end

-- Resolve a step's map/x/y, falling back to Blizzard's own live quest
-- waypoint API when the guide's stored coord is an unrecorded stub
-- (map=0,x=0,y=0). C_QuestLog.GetNextWaypoint is the same data source that
-- powers the default UI's built-in supertracking arrow — real, verified
-- per-quest data instead of a guessed zone-center/last-NPC fallback.
local function GetEffectiveCoord(step)
    -- PRIORITY 1: Blizzard's live quest waypoint system.
    -- GetNextWaypoint only works for supertracked/watched quests.
    if step.questID and C_QuestLog.GetNextWaypoint then
        -- Make sure the quest is tracked so waypoint data is available
        local questID = step.questID
        local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIdx then
            local wpMap, wpX, wpY = C_QuestLog.GetNextWaypoint(questID)
            if wpMap and wpX and wpY and (wpX ~= 0 or wpY ~= 0) then
                return wpMap, wpX, wpY
            end
        end
    end

    -- PRIORITY 2: Quest POI markers on the map (works for most tracked quests)
    if step.questID and C_QuestLog.GetLogIndexForQuestID then
        local questID = step.questID
        local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
        if logIdx then
            local currentMap = C_Map.GetBestMapForUnit("player")
            if currentMap and C_Map.GetMapPosFromWorldPos then
                -- Try to get quest POI via the map system
                if QuestPOIGetIconInfo then
                    local completed, posX, posY = QuestPOIGetIconInfo(questID)
                    if posX and posY and (posX ~= 0 or posY ~= 0) then
                        return currentMap, posX, posY
                    end
                end
            end
        end
    end

    -- PRIORITY 2.5: Quest NOT in log — try to find the quest giver location.
    -- For "pick up" steps where the quest hasn't been accepted yet, use:
    -- (a) Map quest offer POIs via C_Map / C_AreaPoiInfo
    -- (b) Adjacent guide steps that share the same NPC/location
    if step.questID and not C_QuestLog.GetLogIndexForQuestID(step.questID) then
        -- 2.5a: Check if Blizzard's map system knows where this quest is offered
        local currentMap = C_Map.GetBestMapForUnit("player")
        if currentMap and C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID then
            local ok, tasks = pcall(C_TaskQuest.GetQuestsForPlayerByMapID, currentMap)
            if ok and tasks then
                for _, task in ipairs(tasks) do
                    if task.questId == step.questID and task.x and task.y then
                        return currentMap, task.x, task.y
                    end
                end
            end
        end

        -- 2.5b: Try GetQuestLocation (available in some builds)
        if C_QuestLog.GetQuestStartLocation then
            local ok, locMap, locX, locY = pcall(C_QuestLog.GetQuestStartLocation, step.questID)
            if ok and locMap and locX and locY and (locX ~= 0 or locY ~= 0) then
                return locMap, locX, locY
            end
        end

        -- 2.5c: Borrow coordinates from adjacent guide steps.
        -- If the previous step was a turn-in at the same NPC, or the next step
        -- shares coordinates, use those as the pickup location (NPCs that give
        -- AND receive quests are usually in the same spot).
        local QT = TA:GetModule("QuestTracker")
        if QT and QT.guideID then
            local guide = TA.Guides and TA.Guides[QT.guideID]
            if guide and guide.steps then
                local stepIdx = QT.stepIdx or 1
                -- Check previous step (often a turn-in at the same NPC)
                local prevStep = guide.steps[stepIdx - 1]
                if prevStep and prevStep.coord then
                    local pm, px, py = prevStep.coord.map or 0, prevStep.coord.x or 0, prevStep.coord.y or 0
                    if pm ~= 0 and (px ~= 0 or py ~= 0) then
                        return pm, px, py
                    end
                end
                -- Check next step (sometimes the quest objective is nearby)
                local nextStep = guide.steps[stepIdx + 1]
                if nextStep and nextStep.coord then
                    local nm, nx, ny = nextStep.coord.map or 0, nextStep.coord.x or 0, nextStep.coord.y or 0
                    if nm ~= 0 and (nx ~= 0 or ny ~= 0) then
                        return nm, nx, ny
                    end
                end
                -- Check up to 3 steps back for any valid coord in this guide
                for back = 2, 4 do
                    local backStep = guide.steps[stepIdx - back]
                    if backStep and backStep.coord then
                        local bm, bx, by = backStep.coord.map or 0, backStep.coord.x or 0, backStep.coord.y or 0
                        if bm ~= 0 and (bx ~= 0 or by ~= 0) then
                            return bm, bx, by
                        end
                    end
                end
            end
        end
    end

    -- PRIORITY 3: CoordResolver (pulls from APR RouteQuestStepList + other sources)
    local CR = TA:GetModule("CoordResolver")
    if CR and step.questID then
        local resolved = CR:Resolve(step.questID, step, step.objectiveIndex)
        if resolved and resolved.map and resolved.map > 0
           and resolved.x and resolved.x > 0 and resolved.x <= 1
           and resolved.y and resolved.y > 0 and resolved.y <= 1 then
            return resolved.map, resolved.x, resolved.y
        end
    end

    -- PRIORITY 4: Manual guide coords
    local coordMap = step.coord.map or 0
    local cx, cy   = step.coord.x, step.coord.y
    if coordMap ~= 0 or cx ~= 0 or cy ~= 0 then
        return coordMap, cx, cy
    end

    -- Nothing available
    return 0, 0, 0
end
-- Exposed on the module table so QuestTracker.lua can reuse the exact same
-- resolution (including the live-waypoint fallback) for its distance/ETA
-- display, instead of duplicating this logic.
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
-- Interpolates between 3 colors based on t (0..1): bad → mid → good
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

        -- Narrative / no-location steps (e.g. cutscene or flavor text): nothing
        -- to point at, so hide the arrow entirely rather than showing "No Loc".
        if step.type == "text" then
            f.arrowTex:Hide()
            f.greyTex:Hide()
            f.distF:SetText("")
            f.etaF:SetText("")
            f.titleF:SetText(step.text or "")
            self._arrived = false
            return
        end

        -- Objective label: live quest name > step text
        label = step.text or ""
        if step.questID then
            local qTitle = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(step.questID)
            if qTitle and qTitle ~= "" then label = qTitle end
        end

        coordMap, cx, cy = GetEffectiveCoord(step)

        -- Still nothing after trying the live quest-waypoint fallback — stub
        -- coords (map=0, x=0, y=0) must NOT be treated as a real waypoint, or
        -- the arrow would point at the map's top-left corner.
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

    -- Cross-zone detection (coordMap=0 with real coords = assume same zone)
    if coordMap ~= 0 and coordMap ~= currentMap then
        -- Check parent-zone containment — sub-zones shouldn't trigger travel redirect
        local isSameArea = false
        local checkMap = currentMap
        for _ = 1, 5 do  -- max 5 levels of parent traversal
            local mapInfo = C_Map.GetMapInfo(checkMap)
            if not mapInfo then break end
            if mapInfo.parentMapID == coordMap then isSameArea = true; break end
            if mapInfo.parentMapID and mapInfo.parentMapID > 0 then
                checkMap = mapInfo.parentMapID
            else
                break
            end
        end
        -- Also check reverse: target might be a sub-zone of current
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
            -- Same area — treat coordMap as current map for bearing calculation
            coordMap = currentMap
        else
            -- ── TRAVEL ROUTER INTERCEPT ───────────────────────────────────
            local TR = TA:GetModule("TravelRouter")
            local route = TR and TR:FindRoute(currentMap, coordMap)

            if route and route.method == "fly" then
                local fmX, fmY, fmName = self:FindNearestFlightMaster(currentMap)
                if fmX and fmY then
                    coordMap = currentMap
                    cx, cy = fmX, fmY
                    f.titleF:SetText("|cFF55CCFF✈|r " .. (fmName or "Flight Master"))
                else
                    f.arrowTex:Hide()
                    f.greyTex:Show()
                    f.distF:SetText("|cFF55CCFFDiff Zone|r")
                    f.etaF:SetText(route.label or "")
                    self._arrived = false
                    return
                end
            elseif route then
                f.arrowTex:Hide()
                f.greyTex:Show()
                f.distF:SetText("|cFF55CCFFTravel|r")
                f.etaF:SetText(route.label or "")
                f.titleF:SetText(label)
                self._arrived = false
                return
            else
                f.arrowTex:Hide()
                f.greyTex:Show()
                f.distF:SetText("Diff Zone")
                f.etaF:SetText("")
                self._arrived = false
                return
            end
        end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    -- 12.0 PTR: GetXY() can return tainted "secret number" values.
    -- Force through tonumber(tostring()) to strip the secret flag.
    local rawPx, rawPy = pos:GetXY()
    local px = tonumber(tostring(rawPx))
    local py = tonumber(tostring(rawPy))
    if not px or not py or (px == 0 and py == 0) then return end

    local dx          = cx - px
    local dy          = cy - py
    -- WoW map: Y increases southward. atan2(dx, -dy) gives clockwise bearing.
    -- GetPlayerFacing() returns counter-clockwise radians from north.
    -- The difference gives the screen-space rotation for the arrow texture.
    local bearing     = math.atan2(dx, -dy)
    
    -- ── Player facing detection ───────────────────────────────────────
    -- 12.0 PTR: GetPlayerFacing() is often restricted (returns nil or secret).
    -- Fallback chain: GetPlayerFacing → Minimap rotation → movement inference.
    local facing = nil
    
    -- Method 1: Direct API (works in open world on most builds)
    local rawFacing = GetPlayerFacing()
    if rawFacing then
        facing = tonumber(tostring(rawFacing))
    end
    
    -- Method 2: Minimap rotation (always available, same coordinate space)
    if not facing and Minimap and Minimap.GetFacing then
        local ok, rot = pcall(Minimap.GetFacing, Minimap)
        if ok and rot then
            facing = tonumber(tostring(rot))
        end
    end
    
    -- Method 3: Infer from movement direction
    if not facing then
        -- Infer facing from movement direction
        if self._lastPx and self._lastPy then
            local mdx = px - self._lastPx
            local mdy = py - self._lastPy
            local moved = math.sqrt(mdx * mdx + mdy * mdy)
            if moved > 0.0001 then
                -- Player moved — use movement direction as facing
                facing = math.atan2(mdx, -mdy)
            else
                -- Standing still — use last known facing or 0
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
            self.currentAngle = nil  -- reset lerp on next non-arrived tick
        end
        f.greyTex:Hide()
        f.arrowTex:Show()
        f.arrowTex:SetRotation(0)  -- point straight up

        -- Pulsing green glow to indicate arrival
        local pulse = 0.6 + 0.4 * math.sin(GetTime() * ARRIVAL_PULSE_RATE * math.pi * 2)
        f.arrowTex:SetVertexColor(0.20, 0.92, 0.40, pulse)

        f.distF:SetText("|cFF4AFF7AArrived|r")
        f.etaF:SetText("")

        -- Auto-clear manual waypoints 3 seconds after arrival
        if isManualWP and self._arrivedTime and (GetTime() - self._arrivedTime > 3) then
            self.manualWaypoint = nil
            self._arrived = false
            self._arrivedTime = nil
            TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA Arrow]|r Waypoint reached — cleared.")
        end
        return
    end

    self._arrived = false
    f.greyTex:Hide()
    f.arrowTex:Show()

    -- ── DIRECTIONAL COLOR GRADIENT ────────────────────────────────────
    -- perc = 1.0 when facing the waypoint, 0.0 when facing directly away
    local perc = math.abs((math.pi - math.abs(targetAngle)) / math.pi)
    -- Clamp to 0..1 (angles can slightly exceed pi due to lerp overshoot)
    perc = math.max(0, math.min(1, perc))

    local r, g, b = ColorGradient(perc,
        0.90, 0.20, 0.15,   -- red (facing away)
        1.00, 0.80, 0.10,   -- yellow (sideways)
        0.20, 0.92, 0.40    -- green (facing toward)
    )

    -- ── ROTATION (direct, no lerp) ───────────────────────────────────
    -- Set arrow rotation directly each frame so it responds instantly
    -- when the player turns. TomTom/APR use the same approach.
    f.arrowTex:SetRotation(targetAngle)
    f.arrowTex:SetVertexColor(r, g, b, 1)

    -- ── DISTANCE ──────────────────────────────────────────────────────
    f.distF:SetText(U.FormatDistance(yards))

    -- ── SPEED-SMOOTHED ETA ────────────────────────────────────────────
    -- Track distance changes over time and average over 2 samples to
    -- prevent ETA jitter from micro-movement and position snapping.
    local now = GetTime()
    local dt  = now - lastTime
    if dt > 0.1 and lastDist then
        local moved = lastDist - yards  -- positive if getting closer
        local instantSpeed = moved / dt
        -- Shift samples
        speedSamples[1] = speedSamples[2]
        speedSamples[2] = instantSpeed
    end
    lastDist = yards
    lastTime = now

    local avgSpeed = (speedSamples[1] + speedSamples[2]) / 2
    if avgSpeed > 0.5 then
        -- Player is actually moving toward the target
        local eta = yards / avgSpeed
        if eta < 3600 then
            local mins = math.floor(eta / 60)
            local secs = math.floor(eta % 60)
            f.etaF:SetText(string.format("|cFFCCCCCC%d:%02d ETA|r", mins, secs))
        else
            f.etaF:SetText("")
        end
    elseif avgSpeed < -0.5 then
        -- Moving away
        f.etaF:SetText("|cFFFF6666moving away|r")
    else
        -- Standing still or moving perpendicular — use fallback speed
        local fallbackSpeed = GetTravelSpeed()
        if fallbackSpeed > 0 then
            f.etaF:SetText(U.FormatETA(yards, fallbackSpeed))
        else
            f.etaF:SetText("")
        end
    end
end

-- ── Flight Master Locator ──────────────────────────────────────────────────
-- Used by the TravelRouter intercept to redirect the arrow toward the
-- nearest known Flight Master on the player's current map.

function Arrow:FindNearestFlightMaster(currentMap)
    local TR = TA:GetModule("TravelRouter")
    if not TR or not TR.knownFlightPaths then return nil, nil, nil end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return nil, nil, nil end
    local px, py = pos:GetXY()

    local bestDist = math.huge
    local bestX, bestY, bestName = nil, nil, nil

    for _, node in pairs(TR.knownFlightPaths) do
        if node.mapID == currentMap and node.x and node.y and node.x > 0 then
            local dx = node.x - px
            local dy = node.y - py
            local dist = dx * dx + dy * dy  -- squared distance (no sqrt needed for comparison)
            if dist < bestDist then
                bestDist = dist
                bestX    = node.x
                bestY    = node.y
                bestName = node.name
            end
        end
    end

    -- Also try C_TaxiMap.GetAllTaxiNodes for live data if TR didn't have it
    if not bestX and C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
        local nodes = C_TaxiMap.GetTaxiNodesForMap(currentMap)
        if nodes then
            for _, node in ipairs(nodes) do
                if node.position and (node.state == Enum.FlightPathState.Current or
                   node.state == Enum.FlightPathState.Reachable) then
                    local nx, ny = node.position.x, node.position.y
                    local dx = nx - px
                    local dy = ny - py
                    local dist = dx * dx + dy * dy
                    if dist < bestDist then
                        bestDist = dist
                        bestX    = nx
                        bestY    = ny
                        bestName = node.name
                    end
                end
            end
        end
    end

    return bestX, bestY, bestName
end

-- ── Public API ────────────────────────────────────────────────────────────

--- Set a manual waypoint that the arrow will point to, overriding guide navigation.
--- @param mapID number — map ID (use 0 or nil for current map)
--- @param x number — x coordinate (0–1 fraction, i.e. percentage / 100)
--- @param y number — y coordinate (0–1 fraction)
--- @param title string|nil — optional label shown on the arrow
function Arrow:SetWaypoint(mapID, x, y, title)
    -- If mapID is 0/nil, resolve to current map
    if not mapID or mapID == 0 then
        mapID = C_Map.GetBestMapForUnit("player") or 0
    end
    self.manualWaypoint = {
        map   = mapID,
        x     = x,
        y     = y,
        title = title or string.format("%.2f, %.2f", x * 100, y * 100),
    }
    self._arrived = false
    self._arrivedTime = nil

    -- Auto-show the arrow when setting a waypoint
    if self.frame and not self.frame:IsVisible() then
        self.frame:Show()
        if TA.charDB then TA.charDB.arrow = TA.charDB.arrow or {}; TA.charDB.arrow.visible = true end
    end
end

--- Clear the current manual waypoint, returning to guide-driven navigation.
function Arrow:ClearWaypoint()
    self.manualWaypoint = nil
    self._arrived = false
    self._arrivedTime = nil
end

--- Parse a TomTom-compatible /way string and set the arrow.
--- Supported formats:
---   /ta way 45.2 67.8              — current map, TomTom coords (divided by 100)
---   /ta way 45.2 67.8 My Place     — with description
---   /ta way 2393 45.2 67.8         — explicit mapID + coords
---   /ta way 2393 45.2 67.8 My Spot — mapID + coords + description
---   /ta way clear                  — remove manual waypoint
function Arrow:ParseWayCommand(args)
    if not args or args == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Usage:")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way <x> <y> [description]|r — set waypoint on current map")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way <mapID> <x> <y> [description]|r — set waypoint on specific map")
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way clear|r — remove manual waypoint")
        if self.manualWaypoint then
            local wp = self.manualWaypoint
            TA:Raw(TA.LOG.OUTPUT, string.format("  Current: map %d — %.2f, %.2f (%s)",
                wp.map, wp.x * 100, wp.y * 100, wp.title or ""))
        end
        return
    end

    -- Normalize separators: "45,2" → "45.2", "45.2, 67.8" → "45.2 67.8"
    args = args:gsub("(%d),(%d)", "%1.%2")    -- comma as decimal separator
    args = args:gsub(",%s*", " ")             -- comma + space between coords

    local tokens = {}
    for token in args:gmatch("%S+") do
        table.insert(tokens, token)
    end

    -- Handle subcommands
    local first = tokens[1] and tokens[1]:lower()
    if first == "clear" or first == "remove" or first == "off" then
        self:ClearWaypoint()
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Arrow]|r Manual waypoint cleared.")
        return
    end

    -- Determine if first token is a mapID or an X coordinate.
    -- Heuristic: mapIDs are integers > 100 (all WoW map IDs are well above 100),
    -- while display coords are typically < 100 (percentage values 0–100).
    -- TomTom also uses #mapID format — support that too.
    local mapID = nil
    local xRaw, yRaw, descStart

    -- Check for #mapID format (TomTom compatibility)
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
            -- Three numbers: first is mapID if it's an integer > 100
            if n1 == math.floor(n1) and n1 > 100 then
                mapID = n1
                xRaw  = n2
                yRaw  = n3
                descStart = 4
            else
                -- All three are probably coords or something else; treat first two as x,y
                xRaw = n1
                yRaw = n2
                descStart = 3
            end
        elseif n1 and n2 then
            -- Two numbers: x, y on current map
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

    -- Validate coordinate ranges (TomTom format: 0–100 percentage display values)
    if xRaw < 0 or xRaw > 100 or yRaw < 0 or yRaw > 100 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Coordinates must be 0–100 (e.g. 45.2 67.8).")
        return
    end

    -- Convert from display percentage (0–100) to map fraction (0–1)
    local x = xRaw / 100
    local y = yRaw / 100

    -- Build description from remaining tokens
    local desc = nil
    if descStart and tokens[descStart] then
        desc = table.concat(tokens, " ", descStart)
    end

    self:SetWaypoint(mapID, x, y, desc)

    -- Confirmation message
    local mapStr = ""
    if mapID and mapID > 0 then
        local mapInfo = C_Map.GetMapInfo(mapID)
        mapStr = mapInfo and mapInfo.name or ("map " .. mapID)
        mapStr = " in " .. mapStr
    end
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA Arrow]|r Waypoint set: |cFF4AFF7A%.2f, %.2f|r%s%s",
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

    -- Register vehicle/pet-battle events to auto-hide HUD
    TA.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    TA.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
    TA.eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
    TA.eventFrame:RegisterEvent("PET_BATTLE_OVER")
end

function Arrow:OnEvent(event, ...)
    if event == "UNIT_ENTERED_VEHICLE" or event == "PET_BATTLE_OPENING_START" or event == "ENCOUNTER_START" then
        if self.frame and self.frame:IsShown() then
            self._hiddenByEvent = true
            self.frame:Hide()
        end
    elseif event == "UNIT_EXITED_VEHICLE" or event == "PET_BATTLE_OVER" or event == "ENCOUNTER_END" then
        if self._hiddenByEvent then
            self._hiddenByEvent = false
            if self.frame then self.frame:Show() end
        end
    end
end

Arrow.SlashCommands = {
    arrow = function(self) self:Toggle() end,
}
