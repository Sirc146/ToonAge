-- ToonAge/Modules/CoordResolver.lua (Classic — MoP 50504)
-- Coordinate resolution for guide navigation.
-- Simplified for Classic: no C_Navigation, C_SuperTrack, C_QuestLog waypoint APIs.
--
-- Priority order (highest → lowest):
--   1. QuestPOIGetIconInfo (legacy POI system, available in MoP Classic)
--   2. ToonAge guide step coord (hand-authored)
--   3. Adjacent guide step coords (borrow from nearby steps)
--   4. Last known position from SavedVariables
--
-- Coordinates returned as NORMALIZED map coords {map=mapID, x=0-1, y=0-1}

local TA = ToonAge
local U  = TA.Utils

local CR = {}
TA:RegisterModule("CoordResolver", CR)

-- ── State ─────────────────────────────────────────────────────────────────────
CR.cache = {}          -- { [questID..":"..objectiveIdx] = {map, x, y, time, source} }
local CACHE_TTL = 30   -- seconds before re-querying live sources

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 1: QuestPOIGetIconInfo (legacy POI — available in MoP Classic)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryQuestPOI(questID)
    if not questID then return nil end
    if not QuestPOIGetIconInfo then return nil end

    -- QuestPOIGetIconInfo returns: completed, posX, posY, objectiveIndex
    local ok, completed, posX, posY = pcall(QuestPOIGetIconInfo, questID)
    if ok and posX and posY and (posX ~= 0 or posY ~= 0) then
        local mapID = C_Map.GetBestMapForUnit("player")
        return { map = mapID or 0, x = posX, y = posY, source = "QuestPOI" }
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 2: C_QuestLog basics (GetLogIndexForQuestID exists in MoP Classic)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryQuestLogBasic(questID)
    if not questID then return nil end
    if not C_QuestLog or not C_QuestLog.GetLogIndexForQuestID then return nil end

    local logIdx = C_QuestLog.GetLogIndexForQuestID(questID)
    if not logIdx then return nil end

    -- In MoP Classic, C_TaskQuest may have quest location data for bonus objectives
    if C_TaskQuest and C_TaskQuest.GetQuestLocation then
        local ok, mapID, x, y = pcall(C_TaskQuest.GetQuestLocation, questID)
        if ok and mapID and x and x > 0 then
            return { map = mapID, x = x, y = y, source = "TaskQuest" }
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 3: ToonAge guide step coord (hand-authored)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryGuideStep(step)
    if not step or not step.coord then return nil end
    local c = step.coord
    if c.map and c.map > 0 and (c.x > 0 or c.y > 0) then
        return { map = c.map, x = c.x, y = c.y, source = "Guide" }
    end
    -- Allow mapID=0 with real coords (assume current zone)
    if (c.x and c.x > 0) or (c.y and c.y > 0) then
        local mapID = C_Map.GetBestMapForUnit("player") or 0
        return { map = mapID, x = c.x or 0, y = c.y or 0, source = "Guide" }
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOURCE 4: Adjacent guide steps (borrow coordinates from nearby steps)
-- ═══════════════════════════════════════════════════════════════════════════════

local function QueryAdjacentSteps(questID, step)
    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return nil end

    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide or not guide.steps then return nil end

    local stepIdx = QT.stepIdx or 1

    -- Check previous step (often a turn-in at the same NPC)
    local prevStep = guide.steps[stepIdx - 1]
    if prevStep and prevStep.coord then
        local pm = prevStep.coord.map or 0
        local px, py = prevStep.coord.x or 0, prevStep.coord.y or 0
        if pm ~= 0 and (px ~= 0 or py ~= 0) then
            return { map = pm, x = px, y = py, source = "Adjacent" }
        end
    end

    -- Check next step
    local nextStep = guide.steps[stepIdx + 1]
    if nextStep and nextStep.coord then
        local nm = nextStep.coord.map or 0
        local nx, ny = nextStep.coord.x or 0, nextStep.coord.y or 0
        if nm ~= 0 and (nx ~= 0 or ny ~= 0) then
            return { map = nm, x = nx, y = ny, source = "Adjacent" }
        end
    end

    -- Check up to 3 steps back
    for back = 2, 4 do
        local backStep = guide.steps[stepIdx - back]
        if backStep and backStep.coord then
            local bm = backStep.coord.map or 0
            local bx, by = backStep.coord.x or 0, backStep.coord.y or 0
            if bm ~= 0 and (bx ~= 0 or by ~= 0) then
                return { map = bm, x = bx, y = by, source = "Adjacent" }
            end
        end
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
--- @return table|nil — { map, x, y, source } or nil
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
        -- 1. Quest POI (legacy system, works in MoP Classic)
        result = QueryQuestPOI(questID)

        -- 2. Basic quest log location data
        if not result then
            result = QueryQuestLogBasic(questID)
        end
    end

    -- 3. Guide step coord (hand-authored fallback)
    if not result and step then
        result = QueryGuideStep(step)
    end

    -- 4. Adjacent guide steps
    if not result then
        result = QueryAdjacentSteps(questID, step)
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
end

--- Get distance to a resolved coord using map coordinates
function CR:GetDistance(resolved)
    if not resolved then return nil end
    if not resolved.map or not resolved.x or resolved.x == 0 then return nil end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or mapID ~= resolved.map then return nil end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end

    local px, py = pos:GetXY()
    return U.ComputeDistance(px, py, resolved.x, resolved.y)
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
        local sources = {}
        if QuestPOIGetIconInfo then table.insert(sources, "QuestPOI") end
        if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then table.insert(sources, "C_QuestLog (basic)") end
        if C_TaskQuest and C_TaskQuest.GetQuestLocation then table.insert(sources, "C_TaskQuest") end
        table.insert(sources, "Guide coords")
        table.insert(sources, "Adjacent steps")
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge CoordResolver]|r Available sources: " .. table.concat(sources, ", "))
    end,
}
