-- ToonAge/Modules/CoordResolver.lua
-- Definitive coordinate resolution system.
-- Uses a priority cascade of ALL available data sources to find the best
-- coordinates for any quest step. Powers the Arrow, NavHud, and ant-trail.
--
-- Priority order (highest → lowest):
--   1. Blizzard C_QuestLog POI (live waypoint for active quests)
--   2. APR RouteQuestStepList (pre-computed world coords from Azeroth Pilot)
--   3. C_Map.GetMapInfoAtPosition + C_SuperTrack (super-tracked quest)
--   4. C_TaskQuest.GetQuestLocation (world quests, bonus objectives)
--   5. QuestPOIGetIconInfo (legacy POI system)
--   6. ToonAge guide coord (hand-authored or BtWQuests stub)
--   7. Last known position from SavedVariables (gathered over time)
--
-- Coordinates are returned as NORMALIZED map coords {map=mapID, x=0-1, y=0-1}
-- which is what ToonAge's Arrow/NavHud expect.
--
-- World coords (from UnitPosition/APR) are converted to map coords via
-- C_Map.GetMapPosFromWorldPos() or manual zone-bounds math.

local TA = ToonAge
local U  = TA.Utils

local CR = {}
TA:RegisterModule("CoordResolver", CR)

-- ── State ─────────────────────────────────────────────────────────────────────
CR.cache = {}          -- { [questID..":"..objectiveIdx] = {map, x, y, time, source} }
CR.aprRouteCache = nil -- parsed APR routes for fast lookup
local CACHE_TTL = 30   -- seconds before re-querying live sources

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 1: Blizzard C_QuestLog POI (active quests only)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryBlizzardPOI(questID, objectiveIdx)
    if not C_QuestLog then return nil end

    -- Method A: C_QuestLog.GetNextWaypointForMap (best, gives exact quest waypoint)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    if C_QuestLog.GetNextWaypointForMap then
        local ok, waypoints = pcall(C_QuestLog.GetNextWaypointForMap, questID, mapID)
        if ok and type(waypoints) == "table" and #waypoints > 0 then
            local wp = waypoints[1]
            if type(wp) == "table" and wp.x and wp.y then
                return { map = mapID, x = wp.x, y = wp.y, source = "BlizzardPOI" }
            end
        end
    end

    -- Method B: C_QuestLog.GetNextWaypoint (map-independent)
    if C_QuestLog.GetNextWaypoint then
        local ok, waypointMapID, waypointX, waypointY = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and waypointMapID and waypointX then
            return { map = waypointMapID, x = waypointX, y = waypointY, source = "BlizzardWaypoint" }
        end
    end

    -- Method C: Quest POI on map (icon position)
    if C_QuestLog.GetQuestAdditionalHighlights then
        local ok, highlights = pcall(C_QuestLog.GetQuestAdditionalHighlights, questID)
        if ok and type(highlights) == "table" then
            for _, h in ipairs(highlights) do
                if type(h) == "table" and h.x and h.y then
                    return { map = mapID, x = h.x, y = h.y, source = "BlizzardHighlight" }
                end
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 2: APR RouteQuestStepList (world coords → normalized map coords)
-- ═══════════════════════════════════════════════════════════════════════════════

--- Convert APR world coords to normalized map coords.
--- APR uses UnitPosition-style coords (yards in world space).
--- We convert via C_Map.GetMapPosFromWorldPos if available.
local function WorldToMapCoord(worldX, worldY, zoneMapID)
    -- Try the modern API (may not exist or may fail for some zones)
    if C_Map and C_Map.GetMapPosFromWorldPos then
        local ok, mapPos = pcall(C_Map.GetMapPosFromWorldPos, worldX, worldY, zoneMapID)
        if ok and mapPos and type(mapPos) == "table" and mapPos.GetXY then
            local x, y = mapPos:GetXY()
            if x and y and x > 0 and y > 0 and x <= 1 and y <= 1 then
                return x, y
            end
        end
    end

    -- Conversion failed — caller should use world coords directly with UnitPosition
    return nil, nil
end

local function QueryAPR(questID, stepType)
    if not APR or not APR.RouteQuestStepList then return nil end

    -- Build lookup cache on first call
    if not CR.aprRouteCache then
        CR.aprRouteCache = {}  -- { [questID] = { coord, zone, stepType } }
        for routeID, routeData in pairs(APR.RouteQuestStepList) do
            local steps = routeData.steps
            if steps then
                for _, step in ipairs(steps) do
                    local coord = step.Coord
                    local zone  = step.Zone or (routeData.mapID)
                    if coord and coord.x and coord.y then
                        -- Index by quest IDs in this step
                        local questIDs = {}
                        if step.PickUp then
                            for _, qid in ipairs(step.PickUp) do questIDs[qid] = "pickup" end
                        end
                        if step.Done then
                            for _, qid in ipairs(step.Done) do questIDs[qid] = "turnin" end
                        end
                        if step.Qpart then
                            for qid, _ in pairs(step.Qpart) do questIDs[qid] = "objective" end
                        end
                        for qid, sType in pairs(questIDs) do
                            -- Store the FIRST coord for each quest (pickup location priority)
                            if not CR.aprRouteCache[qid] or sType == "pickup" then
                                CR.aprRouteCache[qid] = {
                                    worldX = coord.x,
                                    worldY = coord.y,
                                    zone   = zone,
                                    type   = sType,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    local aprData = CR.aprRouteCache[questID]
    if not aprData then return nil end

    -- Convert world coords to map coords
    local mapX, mapY = WorldToMapCoord(aprData.worldX, aprData.worldY, aprData.zone)
    if mapX and mapY then
        return { map = aprData.zone, x = mapX, y = mapY, source = "APR" }
    end

    -- If conversion failed, still return with raw coords flagged
    -- (Arrow module can use UnitPosition distance math directly)
    return {
        map     = aprData.zone,
        x       = 0,
        y       = 0,
        worldX  = aprData.worldX,
        worldY  = aprData.worldY,
        source  = "APR_world",
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 3: C_TaskQuest (world quests, bonus objectives)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryTaskQuest(questID)
    if not C_TaskQuest or not C_TaskQuest.GetQuestLocation then return nil end
    local ok, mapID, x, y = pcall(C_TaskQuest.GetQuestLocation, questID)
    if ok and mapID and x and x > 0 then
        return { map = mapID, x = x, y = y, source = "TaskQuest" }
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 4: Super-tracked quest (whatever Blizzard's UI is pointing at)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QuerySuperTrack(questID)
    if not C_SuperTrack or not C_SuperTrack.GetSuperTrackedQuestID then return nil end
    local tracked = C_SuperTrack.GetSuperTrackedQuestID()
    if tracked ~= questID then return nil end

    -- ⚠ DEAD ON 12.1.0 — C_Navigation.GetDestination was verified nil by live
    -- dump on 2026-07-26. Because the call sits behind an existence check, this
    -- whole source has been returning nil silently, not erroring. Every step
    -- that should have resolved via SuperTrack has been falling through to APR
    -- and then to the guide's stored coord for as long as that has been true.
    --
    -- NOT yet rewritten, deliberately. C_Navigation gained GetNextWaypointForMap,
    -- but its signature is unknown and every other member of that namespace
    -- (GetFrame/GetDistance/GetTargetState/HasValidScreenPosition) operates on
    -- the single active arrow rather than an arbitrary questID — so it may take
    -- (uiMapID) and not (questID, uiMapID).
    --
    -- To settle it, supertrack a quest and dump these. Check the FIRST one first:
    -- C_QuestLog.GetNextWaypointForMap is the API that takes a questID, so if it
    -- survived 12.1.0 this source rewires to C_QuestLog and C_Navigation stays
    -- arrow-only, and the signature question above is moot.
    --   /dump C_QuestLog.GetNextWaypointForMap(C_SuperTrack.GetSuperTrackedQuestID(), C_Map.GetBestMapForUnit("player"))
    --   /dump C_QuestLog.GetNextWaypoint(C_SuperTrack.GetSuperTrackedQuestID())
    --   /run print(pcall(C_Navigation.GetNextWaypointForMap, C_Map.GetBestMapForUnit("player")))
    if C_Navigation and C_Navigation.GetDestination then
        local ok, destMapID, destX, destY = pcall(C_Navigation.GetDestination)
        if ok and destMapID and destX then
            return { map = destMapID, x = destX, y = destY, source = "SuperTrack" }
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 5: ToonAge guide step coord (hand-authored or BtWQuests stub)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryGuideStep(step)
    if not step or not step.coord then return nil end
    local c = step.coord
    if c.map and c.map > 0 and (c.x > 0 or c.y > 0) then
        return { map = c.map, x = c.x, y = c.y, source = "Guide" }
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PUBLIC API: Resolve coordinates for a quest step
-- ═══════════════════════════════════════════════════════════════════════════════

--- Resolve the best available coordinates for a quest/step.
--- @param questID number|nil — quest ID (if available)
--- @param step table|nil — ToonAge guide step table (optional, for fallback coord)
--- @param objectiveIdx number|nil — specific objective index
--- @return table|nil — { map, x, y, source, worldX?, worldY? } or nil
function CR:Resolve(questID, step, objectiveIdx)
    -- Check cache first
    local cacheKey = tostring(questID or 0) .. ":" .. tostring(objectiveIdx or 0)
    local cached = self.cache[cacheKey]
    if cached and (GetTime() - cached.time) < CACHE_TTL then
        return cached
    end

    local result = nil

    -- Priority cascade
    if questID then
        -- 1. Blizzard live POI (only works for quests in your log)
        if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID) then
            result = QueryBlizzardPOI(questID, objectiveIdx)
        end

        -- 2. Super-tracked quest
        if not result then
            result = QuerySuperTrack(questID)
        end

        -- 3. APR pre-computed coords
        if not result then
            result = QueryAPR(questID, step and step.type)
        end

        -- 4. Task/world quest
        if not result then
            result = QueryTaskQuest(questID)
        end
    end

    -- 5. Guide step coord (fallback)
    if not result and step then
        result = QueryGuideStep(step)
    end

    -- Cache the result
    if result then
        result.time = GetTime()
        self.cache[cacheKey] = result
    end

    return result
end

--- Clear the cache (call on zone change or guide switch)
function CR:ClearCache()
    self.cache = {}
    self.aprRouteCache = nil  -- rebuild APR cache on next query
end

--- Get world-space distance to a resolved coord (for Arrow/NavHud)
--- Uses UnitPosition for accurate yard distance when world coords available.
function CR:GetWorldDistance(resolved)
    if not resolved then return nil end

    -- If we have world coords (from APR), use UnitPosition for accurate distance
    if resolved.worldX and resolved.worldY then
        local playerY, playerX = UnitPosition("player")
        if playerX and playerY then
            local dx = playerX - resolved.worldX
            local dy = playerY - resolved.worldY
            return math.sqrt(dx * dx + dy * dy)
        end
    end

    -- Otherwise fall back to map-coord distance estimation
    if resolved.map and resolved.x and resolved.y and resolved.x > 0 then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID == resolved.map then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local px, py = pos:GetXY()
                return U.ComputeDistance(px, py, resolved.x, resolved.y)
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════════

function CR:Init()
    -- Clear cache on zone changes
end

function CR:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        self:ClearCache()
    end
end

CR.SlashCommands = {
    coord = function(self)
        -- Debug: show what sources are available
        local sources = {}
        if C_QuestLog and C_QuestLog.GetNextWaypointForMap then table.insert(sources, "C_QuestLog POI") end
        if APR and APR.RouteQuestStepList then
            local routeCount = 0
            for _ in pairs(APR.RouteQuestStepList) do routeCount = routeCount + 1 end
            table.insert(sources, "APR (" .. routeCount .. " routes)")
        end
        if C_TaskQuest then table.insert(sources, "C_TaskQuest") end
        if C_SuperTrack then table.insert(sources, "C_SuperTrack") end
        -- Test the MEMBER, not the namespace. `if C_Navigation then` was true on
        -- 12.1.0 even though the function this module actually calls
        -- (GetDestination) had been removed -- so this line reported a working
        -- source while QuerySuperTrack silently returned nil every time.
        if C_Navigation and C_Navigation.GetNextWaypointForMap then
            table.insert(sources, "C_Navigation (arrow only)")
        end
        print("|cFFFFD100[ToonAge CoordResolver]|r Available sources: " .. table.concat(sources, ", "))
    end,
}
