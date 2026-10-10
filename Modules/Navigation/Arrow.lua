-- ToonAge/Modules/Arrow.lua
-- Draggable, scroll-to-resize, right-click-lockable HUD arrow.
-- Layout: arrow -> distance ("249 yd", one weight) -> typed label -> ETA ("18s").
-- Distance and the ETA are body text. A typed /way label sits 2px under the
-- distance, and the ETA is the third line under that label. It hides on arrival.
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

-- Classic Arathi Highlands (uiMap 14) and the current-era Arathi map (2372)
-- are one zone. Arator's Journey stores the same x,y on both. A client that
-- does not return GetMapInfo for one of them still resolves the name.
Arrow.MAP_NAMES = {
    [14]   = "Arathi Highlands",
    [2372] = "Arathi Highlands",
}
Arrow.MAP_SAME = {
    [14] = 2372,
    [2372] = 14,
}

function Arrow.SameMap(a, b)
    if a == nil or b == nil then return false end
    if a == b then return true end
    return Arrow.MAP_SAME[a] == b
end

function Arrow.MapName(mapID)
    if C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(mapID)
        if type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            return info.name
        end
    end
    return Arrow.MAP_NAMES[mapID]
end

function Arrow.TokenIsMapID(n)
    if type(n) ~= "number" or n ~= math.floor(n) or n <= 0 then return false end
    if Arrow.MAP_NAMES[n] then return true end
    if n > 100 then return true end
    if C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(n)
        if type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            return true
        end
    end
    return false
end

--- uiMap id for a zone name the player typed, such as "Stormwind City".
--- Prefers a zone map (mapType 3) and, among those, the lowest id.
function Arrow.MapIDForZone(name)
    if type(name) ~= "string" or name == "" then return nil end
    local want = name:lower()
    local bestId, bestZone = nil, false
    local function consider(id, infoName, mapType)
        if type(id) ~= "number" or type(infoName) ~= "string" then return end
        if infoName:lower() ~= want then return end
        local isZone = mapType == 3
        if bestId == nil or (isZone and not bestZone) or (isZone == bestZone and id < bestId) then
            bestId, bestZone = id, isZone
        end
    end
    if Arrow.MAP_NAMES then
        for id, n in pairs(Arrow.MAP_NAMES) do consider(id, n, 3) end
    end
    if C_Map and type(C_Map.GetMapInfo) == "function" then
        for id = 1, 2500 do
            local ok, info = pcall(C_Map.GetMapInfo, id)
            if ok and type(info) == "table" then
                consider(id, info.name, info.mapType)
            end
        end
    end
    return bestId
end

local function ParentMatches(startMap, targetMap)
    if not (C_Map and C_Map.GetMapInfo) then return false end
    local checkMap = startMap
    for _ = 1, 5 do
        local mapInfo = C_Map.GetMapInfo(checkMap)
        if not mapInfo then return false end
        if mapInfo.parentMapID == targetMap then return true end
        if mapInfo.parentMapID and mapInfo.parentMapID > 0 then
            checkMap = mapInfo.parentMapID
        else
            return false
        end
    end
    return false
end

function Arrow.SameArea(currentMap, coordMap)
    if Arrow.SameMap(currentMap, coordMap) then return true end
    if ParentMatches(currentMap, coordMap) then return true end
    if ParentMatches(coordMap, currentMap) then return true end
    return false
end

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
    if not QT then return nil end
    if QT.CampaignSkipStep then
        local skip = QT:CampaignSkipStep()
        if skip then return skip end
    end
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
    -- A scenario or dungeon step is tagged noArrow: show the step, draw nothing.
    if not step or step.noArrow then return 0, 0, 0 end
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
    if type(step.coord) ~= "table" then return 0, 0, 0 end
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

    -- Scroll-wheel resize, 32–64 px on the texture itself. The frame scale
    -- stays 1: the art is already the size it should be drawn.
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

    -- One string, one weight (style guide §19). OUTLINE is this project's bold,
    -- and on Friz it makes the digits look heavier than "yd".
    local distF = f:CreateFontString(nil, "OVERLAY")
    distF:SetFont(STANDARD_TEXT_FONT, 14, "")
    distF:SetTextColor(0.92, 0.90, 0.87, 1)
    distF:SetPoint("TOP", arrowTex, "BOTTOM", 0, 0)
    distF:SetJustifyH("CENTER")
    f.distF = distF

    -- Same body text. Under a typed label this is the third line ("18s").
    local etaF = f:CreateFontString(nil, "OVERLAY")
    etaF:SetFont(STANDARD_TEXT_FONT, 10, "")
    etaF:SetTextColor(0.92, 0.90, 0.87, 1)
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

-- Guide titles stay under the ETA. A typed /way label is 2px under the
-- distance line, and the ETA moves below that label so the two do not stack.
local function AnchorWayCaption(f, belowDistance)
    if belowDistance and f.distF and f.titleF and f.titleF.SetPoint then
        f.titleF:SetPoint("TOP", f.distF, "BOTTOM", 0, -2)
        if f.etaF and f.etaF.SetPoint then
            f.etaF:SetPoint("TOP", f.titleF, "BOTTOM", 0, -2)
        end
    else
        if f.etaF and f.etaF.SetPoint and f.distF then
            f.etaF:SetPoint("TOP", f.distF, "BOTTOM", 0, -2)
        end
        if f.titleF and f.titleF.SetPoint and f.etaF then
            f.titleF:SetPoint("TOP", f.etaF, "BOTTOM", 0, -4)
        end
    end
end

-- ── Per-tick update ───────────────────────────────────────────────────────

function Arrow:Tick(f)
    -- Guide-step titles are gold. A /way label overrides this below.
    if f.titleF and f.titleF.SetTextColor then
        f.titleF:SetTextColor(1, 0.82, 0, 1)
    end
    AnchorWayCaption(f, false)
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
        -- Zygor draws its own arrow; don't put a second one on screen.
        if U.DeferToZygor and U.DeferToZygor() then
            f:Hide()
            return
        end
        step = GetTargetStep()
        PaintEstimate(f, (step and step.coord) and step or nil)

        if step and step.noArrow then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("")
            f.etaF:SetText("")
            local label = step.text or ""
            if #label > 35 then label = label:sub(1, 32) .. "..." end
            f.titleF:SetText(label)
            self._arrived = false
            return
        end

        if not step or not step.coord then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("---")
            f.etaF:SetText("")
            f.titleF:SetText("No Waypoint")
            self._arrived = false
            return
        end

        -- Narrative / no-location steps (e.g. cutscene or flavor text): nothing
        -- to point at, so hide the arrow entirely rather than showing "No Loc".
        if step.type == "text" then
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
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
            U.RevealWaypoint(f, true)
            HideArrowArt(f)
            f.distF:SetText("No Loc")
            f.etaF:SetText("")
            self._arrived = false
            return
        end
    end

    -- Truncate long labels. Guide steps stay gold. A /way label is body text
    -- (UIModern CLR_TEXT_PRIMARY), the same warm white as other body copy.
    if #label > 35 then label = label:sub(1, 32) .. "..." end
    if isManualWP and self.manualWaypoint.labeled then
        f.titleF:SetTextColor(0.92, 0.90, 0.87, 1)
        AnchorWayCaption(f, true)
    else
        f.titleF:SetTextColor(1, 0.82, 0, 1)
    end
    f.titleF:SetText(label)

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then
        U.RevealWaypoint(f, false)
        return
    end

    -- Cross-zone detection (coordMap=0 with real coords = assume same zone).
    -- Map 14 and 2372 are both Arathi Highlands, so they count as one area.
    if coordMap ~= 0 and coordMap ~= currentMap then
        local isSameArea = Arrow.SameArea(currentMap, coordMap)

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
                    f.titleF:SetText((ToonAge.Utils.Glyph("flight", "55CCFF") .. " ") .. (fmName or "Flight Master"))
                else
                    U.RevealWaypoint(f, true)
                    HideArrowArt(f)
                    f.distF:SetText("|cFF55CCFFDiff Zone|r")
                    f.etaF:SetText(route.label or "")
                    self._arrived = false
                    return
                end
            elseif route then
                U.RevealWaypoint(f, true)
                HideArrowArt(f)
                f.distF:SetText("|cFF55CCFFTravel|r")
                f.etaF:SetText(route.label or "")
                f.titleF:SetText(label)
                self._arrived = false
                return
            else
                U.RevealWaypoint(f, true)
                HideArrowArt(f)
                f.distF:SetText("Diff Zone")
                f.etaF:SetText("")
                self._arrived = false
                return
            end
        end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then
        U.RevealWaypoint(f, false)
        return
    end
    -- 12.0 PTR: GetXY() can return tainted "secret number" values.
    -- Force through tonumber(tostring()) to strip the secret flag.
    local rawPx, rawPy = pos:GetXY()
    local px = tonumber(tostring(rawPx))
    local py = tonumber(tostring(rawPy))
    if not px or not py or (px == 0 and py == 0) then
        U.RevealWaypoint(f, false)
        return
    end
    U.RevealWaypoint(f, true)

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
    local hollow = U.WaypointHollow(step)
    local _, arrived = U.WaypointArrowAlpha(yards)

    -- Full-colour art. Fades between 8 and 5 yards, then the arrived ring.
    -- SetRotation turns the arrow around its centre. No vertex tint.
    U.PaintQuestArrow(f.arrowTex, f.arrivedTex, {
        yards = yards, angle = targetAngle, hollow = hollow, size = f._arrowSize,
    })

    if arrived then
        if not self._arrived then
            self._arrived = true
            self._arrivedTime = GetTime()
            self.currentAngle = nil
        end
        -- Arrived ring only. Distance and the caption go away together.
        f.distF:SetText("")
        f.etaF:SetText("")
        if f.titleF then f.titleF:SetText("") end
        if isManualWP and self._arrivedTime and (GetTime() - self._arrivedTime > 3) then
            self.manualWaypoint = nil
            self._arrived = false
            self._arrivedTime = nil
            TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA Arrow]|r Waypoint reached — cleared.")
        end
        return
    end

    f.distF:SetText(U.FormatDistance(yards, hollow))

    self._arrived = false

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
            -- Same body string as a standing ETA ("18s"), not a tinted clock.
            f.etaF:SetText(U.FormatETA(yards, avgSpeed))
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
    local labeled = type(title) == "string" and title ~= ""
    self.manualWaypoint = {
        map   = mapID,
        x     = x,
        y     = y,
        title = title or string.format("%.2f, %.2f", x * 100, y * 100),
        -- A player-typed label is body text. The coordinate fallback is not.
        labeled = labeled,
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

--- A display coordinate is 0-100. "45,2" is 45.2. A token outside that range
--- (a map id) is not a coordinate.
local function WayTokenNumber(token)
    if type(token) ~= "string" then return nil end
    local n = tonumber(token)
    if n then return n end
    if token:match("^%d+,%d+$") then
        return tonumber((token:gsub(",", ".", 1)))
    end
    return nil
end

local function WayTokenInRange(token)
    local n = WayTokenNumber(token)
    return n ~= nil and n >= 0 and n <= 100
end

--- Turn TomTom coordinate spellings into plain number tokens.
---   "45,67"           -> 45, 67          one token, no second coordinate
---   "45.2,67.8"       -> 45.2, 67.8
---   "45,2" "67,8"     -> 45.2, 67.8      two tokens, decimal commas
function Arrow.NormalizeWayTokens(list)
    local out = {}
    local i = 1
    while i <= #list do
        local token = list[i]
        local nxt = list[i + 1]
        local a, b = token:match("^([%d%.]+),([%d%.]+)$")
        local ax, ay = tonumber(a), tonumber(b)
        local pair = ax and ay and ax >= 0 and ax <= 100 and ay >= 0 and ay <= 100
        local nextIsCoord = WayTokenInRange(nxt)
        if pair and not nextIsCoord then
            out[#out + 1] = a
            out[#out + 1] = b
            i = i + 1
        elseif WayTokenInRange(token) and nextIsCoord then
            local n = WayTokenNumber(token)
            local thirdIsCoord = WayTokenInRange(list[i + 2])
            -- "14 68.9 37.7": 14 is a map id with two coordinates after it.
            local asMap = n and n == math.floor(n) and (
                n > 100 or (Arrow.TokenIsMapID and Arrow.TokenIsMapID(n) and thirdIsCoord)
            )
            if asMap then
                out[#out + 1] = token
                i = i + 1
            else
                out[#out + 1] = tostring(WayTokenNumber(token))
                out[#out + 1] = tostring(WayTokenNumber(nxt))
                i = i + 2
            end
        else
            out[#out + 1] = token
            i = i + 1
        end
    end
    return out
end

--- Parse a TomTom-compatible /way string and set the arrow.
--- Supported formats:
---   /ta way 45.2 67.8              — current map, TomTom coords (divided by 100)
---   /ta way 45.2 67.8 My Place     — with description
---   /ta way 2393 45.2 67.8         — explicit mapID + coords
---   /ta way Stormwind City 45.2 67.8 Bank — zone name, or a mapID, plus a label
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

    -- "45.2, 67.8" is two tokens. A comma with no space stays in the token
    -- so a lone "45,67" can be read as x,y the way TomTom does.
    args = args:gsub(",%s+", " ")

    local rawTokens = {}
    for token in args:gmatch("%S+") do
        rawTokens[#rawTokens + 1] = token
    end
    local tokens = Arrow.NormalizeWayTokens(rawTokens)

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
            -- Three numbers: first is a map id when it is a known map.
            -- Integers above 100 are map ids. 14 (Arathi) is below that
            -- cutoff, so named maps and GetMapInfo resolve it too.
            if Arrow.TokenIsMapID(n1) then
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
            -- "Stormwind City 45.2 67.8 The Bank": the first two coordinates
            -- are x y, the words before them are the zone, the rest is the label.
            local zx, zy, zi
            for i = 1, #tokens - 1 do
                local a = tonumber(tokens[i])
                local b = tonumber(tokens[i + 1])
                if a and b and a >= 0 and a <= 100 and b >= 0 and b <= 100 then
                    zx, zy, zi = a, b, i
                    break
                end
            end
            if zx and zi and zi > 1 then
                local zone = table.concat(tokens, " ", 1, zi - 1)
                mapID = Arrow.MapIDForZone(zone)
                if not mapID then
                    TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Unknown zone: " .. zone)
                    return
                end
                xRaw, yRaw = zx, zy
                descStart = zi + 2
            else
                TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Invalid format. Examples:")
                TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way 45.2 67.8|r")
                TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta way 2393 45.2 67.8 My Spot|r")
                return
            end
        end
    end

    if not xRaw or not yRaw then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Could not parse coordinates.")
        return
    end

    -- Validate coordinate ranges (TomTom format: 0–100 percentage display values)
    if xRaw < 0 or xRaw > 100 or yRaw < 0 or yRaw > 100 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA Arrow]|r Coordinates must be 0-100 (e.g. 45.2 67.8).")
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
        local name = Arrow.MapName(mapID)
        mapStr = " in " .. (name or ("map " .. mapID))
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
    if saved and saved.visible and not (U.DeferToZygor and U.DeferToZygor()) then
        self.frame:Show()
    end

    -- Register vehicle/pet-battle events to auto-hide HUD
    TA:RegisterEvent("UNIT_ENTERED_VEHICLE")
    TA:RegisterEvent("UNIT_EXITED_VEHICLE")
    TA:RegisterEvent("PET_BATTLE_OPENING_START")
    TA:RegisterEvent("PET_BATTLE_OVER")
    -- /way is claimed on PLAYER_LOGIN, not here. Setup runs later.
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

--- True when TomTom is already loaded. Either API may be missing; a throw
--- must not become a false "not loaded", which would let us take /way.
function Arrow.TomTomLoaded()
    local function ask(fn)
        if type(fn) ~= "function" then return false end
        local ok, loaded = pcall(fn, "TomTom")
        return ok and not not loaded
    end
    if C_AddOns and ask(C_AddOns.IsAddOnLoaded) then return true end
    if ask(IsAddOnLoaded) then return true end
    return false
end

--- Another SlashCmdList entry already bound /way. Only that entry's
--- SLASH_<KEY>n globals are checked. Our own TOONAGEWAY key does not count.
function Arrow.ForeignWaySlash()
    if type(SlashCmdList) ~= "table" then return false end
    for key in pairs(SlashCmdList) do
        if type(key) == "string" and key ~= "TOONAGEWAY" then
            local i = 1
            while true do
                local cmd = _G["SLASH_" .. key .. i]
                if type(cmd) ~= "string" then break end
                if cmd:lower() == "/way" then return true end
                i = i + 1
            end
        end
    end
    return false
end

--- True once this module has bound /way. A nil SlashCmdList is not ours.
function Arrow.OwnsBareWay()
    if type(_G.SLASH_TOONAGEWAY1) == "string" and _G.SLASH_TOONAGEWAY1:lower() == "/way" then
        return true
    end
    return type(SlashCmdList) == "table" and SlashCmdList["TOONAGEWAY"] ~= nil
end

--- Drop our /way binding. The chat hash is cleared only when it exists:
--- ImportListToHash stores the uppercased tag, so the key is "/WAY".
function Arrow.ClearBareWay()
    _G.SLASH_TOONAGEWAY1 = nil
    if type(SlashCmdList) == "table" then
        SlashCmdList["TOONAGEWAY"] = nil
    end
    if hash_SlashCmdList then
        hash_SlashCmdList["/WAY"] = nil
    end
end

--- True when this arrow is part of the running client: not switched off,
--- not skipped by the profile, and allowed for this flavor. Checked at
--- PLAYER_LOGIN, which is before InitModules copies those flags, so the
--- saved toggle and ModuleAllowed are read here as well.
function Arrow:WayRunnable()
    if self._disabled or self._profileSkipped then return false end
    if TA.TocFlavorMismatch and TA:TocFlavorMismatch() then return false end
    if TA.ModuleAllowed then
        local ok, allowed = pcall(TA.ModuleAllowed, TA, "Arrow")
        if not ok or not allowed then return false end
    end
    local db = (type(TA.db) == "table" and TA.db) or (type(ToonAgeDB) == "table" and ToonAgeDB)
    if type(db) == "table" and type(db.modules) == "table" and db.modules.Arrow == false then
        return false
    end
    return true
end

--- Bare /way enters the same dispatch as /ta way, so a disabled, safe-skipped
--- or wrong-client arrow prints the not-running message and does not run.
--- The text after /way is not lowercased; Dispatch keeps it for the label.
function Arrow:RunBareWay(msg)
    local rest = type(msg) == "string" and msg:match("^%s*(.-)%s*$") or ""
    local text = (rest ~= "") and ("way " .. rest) or "way"
    if TA.SlashCommand then TA:SlashCommand(text) end
end

--- Bare /way, only when this arrow is running and nobody else owns it.
--- /ta way is unaffected: it already goes through dispatch.
function Arrow:RegisterBareWay()
    if not self:WayRunnable() then
        if Arrow.OwnsBareWay() then Arrow.ClearBareWay() end
        return
    end
    if Arrow.TomTomLoaded() or Arrow.ForeignWaySlash() then
        if Arrow.OwnsBareWay() then Arrow.ClearBareWay() end
        return
    end
    if type(SlashCmdList) ~= "table" then return end
    _G.SLASH_TOONAGEWAY1 = "/way"
    SlashCmdList["TOONAGEWAY"] = function(msg)
        self:RunBareWay(msg)
    end
end

--- A later addon claimed /way. Give the command back, including the hash.
function Arrow:GiveUpBareWay()
    if not Arrow.OwnsBareWay() then return end
    if not (Arrow.TomTomLoaded() or Arrow.ForeignWaySlash()) then return end
    Arrow.ClearBareWay()
end

function Arrow:OnWayWatch(event)
    if event == "PLAYER_LOGIN" then
        self:RegisterBareWay()
    elseif event == "ADDON_LOADED" then
        self:GiveUpBareWay()
    end
end

Arrow.SlashCommands = {
    arrow = function(self) self:Toggle() end,
    way   = function(self, args) self:ParseWayCommand(args) end,
}

-- File load is before PLAYER_LOGIN, so this runs after every login addon.
-- Arrow:Init is later (PLAYER_ENTERING_WORLD) and must not register /way.
-- The private frame keeps ADDON_LOADED: core unregisters that event on its
-- own frame once ToonAge itself has loaded.
if type(CreateFrame) == "function" then
    local wayWatch = CreateFrame("Frame")
    wayWatch:RegisterEvent("PLAYER_LOGIN")
    wayWatch:RegisterEvent("ADDON_LOADED")
    wayWatch:SetScript("OnEvent", function(_, event)
        Arrow:OnWayWatch(event)
    end)
end
