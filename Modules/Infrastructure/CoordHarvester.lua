-- ToonAge/Modules/CoordHarvester.lua
-- Passive coordinate collection system.
--
-- Records quest waypoint coordinates as you play, building a database that
-- can be exported as guide coordinate data. Solves the "87% stubs" problem
-- without requiring dedicated mapping sessions.
--
-- How it works:
--   1. On QUEST_ACCEPTED / QUEST_LOG_UPDATE, scans active quests
--   2. For each quest, calls C_QuestLog.GetNextWaypoint (real waypoint data)
--   3. Stores { questID → { mapID, x, y, title, zone, timestamp } }
--   4. On QUEST_TURNED_IN, records the turn-in NPC location
--   5. /ta coordexport generates paste-ready guide steps from harvested data
--
-- Data is stored in ToonAgeDB.coordHarvest (account-wide, persists across sessions).
-- Multiple characters contribute to the same pool.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local CH = {}
TA:RegisterModule("CoordHarvester", CH)

local MAX_ENTRIES = 2000  -- cap to prevent unbounded SV growth

-- ── Init ──────────────────────────────────────────────────────────────────────

function CH:Init()
    TA.db.coordHarvest = TA.db.coordHarvest or {}

    -- Register quest events on our own schedule (piggyback on TA.eventFrame)
    TA.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    TA.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
end

-- ── Event handling ────────────────────────────────────────────────────────────

function CH:OnEvent(event, ...)
    if event == "QUEST_ACCEPTED" then
        -- Slight delay to let the quest log populate
        C_Timer.After(0.5, function() CH:ScanActiveQuests() end)

    elseif event == "QUEST_LOG_UPDATE" then
        -- Throttle: only scan every 5 seconds max
        local now = GetTime()
        if (CH._lastScan or 0) + 5 > now then return end
        CH._lastScan = now
        CH:ScanActiveQuests()

    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        if questID then
            CH:RecordTurnIn(questID)
        end
    end
end

-- ── Core harvesting ───────────────────────────────────────────────────────────

--- Scan all active quests and record their waypoints.
function CH:ScanActiveQuests()
    if not TA.db or not TA.db.coordHarvest then return end
    if not C_QuestLog.GetNextWaypoint then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            self:HarvestQuestCoord(info.questID, info.title, mapID)
        end
    end
end

--- Try to get the waypoint for a specific quest and store it.
function CH:HarvestQuestCoord(questID, title, playerMapID)
    if not questID or questID == 0 then return end

    -- Try C_QuestLog.GetNextWaypoint first (gives the REAL objective location)
    local wpMap, wpX, wpY
    if C_QuestLog.GetNextWaypoint then
        local ok, m, x, y = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and m and x and y and (x ~= 0 or y ~= 0) then
            wpMap, wpX, wpY = m, x, y
        end
    end

    -- Fallback: try GetNextWaypointForMap with player's current map
    if not wpMap and C_QuestLog.GetNextWaypointForMap then
        local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questID, playerMapID)
        if ok and x and y and (x ~= 0 or y ~= 0) then
            wpMap, wpX, wpY = playerMapID, x, y
        end
    end

    -- If we got a coord, store it
    if wpMap and wpX and wpY then
        self:Store("waypoint", questID, title, wpMap, wpX, wpY)
    end
end

--- Record the player's position as the turn-in location for a quest.
function CH:RecordTurnIn(questID)
    if not questID or questID == 0 then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if px == 0 and py == 0 then return end

    local title = C_QuestLog.GetTitleForQuestID(questID) or ("Quest " .. questID)
    self:Store("turnin", questID, title, mapID, px, py)
end

--- Store a coordinate entry.
function CH:Store(stepType, questID, title, mapID, x, y)
    if not TA.db.coordHarvest then return end
    local db = TA.db.coordHarvest

    -- Key by questID + type to avoid duplicates
    local key = questID .. "_" .. stepType
    db[key] = {
        questID   = questID,
        title     = title or "",
        type      = stepType,
        map       = mapID,
        x         = math.floor(x * 10000) / 10000,  -- 4 decimal precision
        y         = math.floor(y * 10000) / 10000,
        timestamp = time(),
        charName  = UnitName("player") or "?",
    }

    -- Cap total entries
    local count = 0
    for _ in pairs(db) do count = count + 1 end
    if count > MAX_ENTRIES then
        -- Remove oldest entries
        local entries = {}
        for k, v in pairs(db) do table.insert(entries, { key = k, ts = v.timestamp or 0 }) end
        table.sort(entries, function(a, b) return a.ts < b.ts end)
        for i = 1, count - MAX_ENTRIES do
            db[entries[i].key] = nil
        end
    end
end

-- ── Export ─────────────────────────────────────────────────────────────────────

--- Export harvested coordinates as guide-ready Lua steps.
--- @param zoneFilter number|nil — filter by mapID
--- @return string — formatted Lua code
function CH:Export(zoneFilter)
    if not TA.db or not TA.db.coordHarvest then return "No data." end

    local entries = {}
    for _, v in pairs(TA.db.coordHarvest) do
        if not zoneFilter or v.map == zoneFilter then
            table.insert(entries, v)
        end
    end

    -- Sort by questID then type
    table.sort(entries, function(a, b)
        if a.questID ~= b.questID then return a.questID < b.questID end
        return (a.type or "") < (b.type or "")
    end)

    if #entries == 0 then
        return zoneFilter
            and ("No harvested coords for map " .. zoneFilter .. ".")
            or "No harvested coords yet. Play the game and they'll accumulate."
    end

    local lines = {
        "-- ═══════════════════════════════════════════════════════════",
        "-- ToonAge Coordinate Harvest Export",
        "-- " .. #entries .. " entries" .. (zoneFilter and (" (map " .. zoneFilter .. ")") or ""),
        "-- Generated: " .. date("%Y-%m-%d %H:%M"),
        "-- ═══════════════════════════════════════════════════════════",
        "",
    }

    local lastQID = nil
    for _, e in ipairs(entries) do
        if e.questID ~= lastQID then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "    -- " .. (e.title or "Unknown") .. " (QID " .. e.questID .. ")"
            lastQID = e.questID
        end

        local stepType = e.type == "turnin" and "turnin" or "quest"
        lines[#lines + 1] = string.format(
            '    { type = "%s", questID = %d, text = "%s",',
            stepType, e.questID, (e.title or ""):gsub('"', '\\"'))
        lines[#lines + 1] = string.format(
            '      coord = { map = %d, x = %.2f, y = %.2f } },',
            e.map, e.x * 100, e.y * 100)
    end

    return table.concat(lines, "\n")
end

--- Get stats on harvested data.
function CH:GetStats()
    if not TA.db or not TA.db.coordHarvest then return 0, 0, {} end
    local total = 0
    local zones = {}
    for _, v in pairs(TA.db.coordHarvest) do
        total = total + 1
        zones[v.map or 0] = (zones[v.map or 0] or 0) + 1
    end
    local zoneCount = 0
    for _ in pairs(zones) do zoneCount = zoneCount + 1 end
    return total, zoneCount, zones
end

-- ── Slash commands ────────────────────────────────────────────────────────────

CH.SlashCommands = {
    coordexport = function(self, args)
        local zoneFilter = nil
        if args and args ~= "" then
            zoneFilter = tonumber(args)
            if not zoneFilter then
                -- Try current zone
                zoneFilter = C_Map.GetBestMapForUnit("player")
            end
        end

        local text = self:Export(zoneFilter)

        -- Use DevHelpers export frame if available
        local DH = TA:GetModule("DevHelpers")
        if DH and DH.ShowExport then
            local total = select(1, self:GetStats())
            DH:ShowExport("Coord Harvest (" .. total .. " entries)", { text })
        else
            TA:Raw(TA.LOG.OUTPUT, text)
        end
    end,

    coordstats = function(self)
        local total, zoneCount, zones = self:GetStats()
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA Coord Harvest]|r %d coords across %d zones.", total, zoneCount))
        if total > 0 then
            -- Show top 5 zones
            local sorted = {}
            for mapID, count in pairs(zones) do
                local mapInfo = C_Map.GetMapInfo(mapID)
                table.insert(sorted, { map = mapID, name = mapInfo and mapInfo.name or ("Map " .. mapID), count = count })
            end
            table.sort(sorted, function(a, b) return a.count > b.count end)
            for i = 1, math.min(5, #sorted) do
                TA:Raw(TA.LOG.OUTPUT, string.format("  %s (map %d): %d coords", sorted[i].name, sorted[i].map, sorted[i].count))
            end
        end
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780Coords are harvested passively as you quest. /ta coordexport to export.|r")
    end,

    coordclear = function(self)
        if TA.db then TA.db.coordHarvest = {} end
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Coordinate harvest cleared.")
    end,
}
