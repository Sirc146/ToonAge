-- ToonAge/Modules/Forever/DungeonPins.lua  (WoW Forever)
--
-- Dungeon Quest Item, Object, NPC & Boss Map Pin resolver + Quest-Log cache.
-- Feeds Modules/Navigation/MapPins.lua (World Map dungeon pins) and
-- Modules/Forever/Now.lua (in-dungeon quest checklist) without calling any
-- quest or map query API inside Blizzard's secureexecuterange.
--
-- Modes (TA.db.dungeonPinMode):
--   "all"    (default) — Active quests in bright gold + available faction
--                        quest items/bosses in muted blue; completed hidden.
--   "active"           — Only pins for quests currently in your Quest Log.
--   "off"              — Disabled.
--
-- Slash command: /ta dpins [all|active|off]

local TA = ToonAge
local U  = TA.Utils

local DP = {}
TA:RegisterModule("ForeverDungeonPins", DP)

DP._activeByID      = {}   -- questID -> { title = str, progress = str|nil }
DP._activeByTitle   = {}   -- lower(title) -> { questID = num, title = str, progress = str|nil }
DP._completedByID   = {}   -- questID -> true
DP._encountersByMap = {}   -- uiMapID -> { [lower(bossName)] = { name=, x=, y= } }
DP._playerFaction   = nil

local PIN_COLORS = {
    active_item = { 1.00, 0.82, 0.16, 1.00 }, -- bright gold
    active_boss = { 0.28, 0.95, 0.54, 1.00 }, -- bright emerald
    active_npc  = { 0.80, 0.56, 1.00, 1.00 }, -- bright violet
    ref_item    = { 0.35, 0.72, 0.96, 0.82 }, -- muted sky blue
    ref_boss    = { 0.44, 0.78, 0.62, 0.78 }, -- muted teal
    ref_npc     = { 0.66, 0.54, 0.86, 0.80 }, -- muted lavender
}

local KIND_BADGE = {
    item = "Q",
    boss = "B",
    npc  = "N",
}

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Secret(v)
    if v == nil then return false end
    if U and U.IsSecret and U.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function PlainStr(v)
    if v == nil or Secret(v) or type(v) ~= "string" then return nil end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    return v ~= "" and v or nil
end

local function Clamp01(v)
    if type(v) ~= "number" or v ~= v then return 0.5 end
    if v < 0.04 then return 0.04 end
    if v > 0.96 then return 0.96 end
    return v
end

function DP.GetMode()
    local m = TA.db and TA.db.dungeonPinMode
    if m == "active" or m == "off" or m == "all" then return m end
    return "all"
end

function DP.SetMode(mode)
    if mode ~= "all" and mode ~= "active" and mode ~= "off" then return DP.GetMode() end
    if TA.db then TA.db.dungeonPinMode = mode end
    local MP = TA.GetModule and TA:GetModule("MapPins")
    if MP and MP.Refresh then pcall(MP.Refresh, MP) end
    return mode
end

function DP.CycleMode()
    local cur = DP.GetMode()
    local nxt = (cur == "all") and "active" or ((cur == "active") and "off" or "all")
    return DP.SetMode(nxt)
end

--- Snapshot the player's current Quest Log, objective progress, completion flags,
--- and faction into plain Lua tables (safe to read during WorldMap refresh).
function DP:RefreshQuestCache()
    local activeByID, activeByTitle, completedByID = {}, {}, {}

    local fac = nil
    if TA.Compat and type(TA.Compat.PlayerFaction) == "function" then
        fac = PlainStr(TA.Compat.PlayerFaction())
    end
    if not fac and type(UnitFactionGroup) == "function" then
        fac = PlainStr(Try(UnitFactionGroup, "player"))
    end
    self._playerFaction = fac

    -- 1. Active quests + objective progress
    if C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries) == "function"
        and type(C_QuestLog.GetInfo) == "function" then
        local n = tonumber(Try(C_QuestLog.GetNumQuestLogEntries)) or 0
        for i = 1, n do
            local info = Try(C_QuestLog.GetInfo, i)
            if type(info) == "table" and not info.isHeader and type(info.questID) == "number" and info.questID > 0 then
                local qid = info.questID
                local title = PlainStr(info.title) or ("Quest " .. tostring(qid))
                local progParts = {}
                if type(C_QuestLog.GetQuestObjectives) == "function" then
                    local objs = Try(C_QuestLog.GetQuestObjectives, qid)
                    if type(objs) == "table" then
                        for _, o in ipairs(objs) do
                            if type(o) == "table" then
                                local txt = PlainStr(o.text)
                                if txt then
                                    progParts[#progParts + 1] = txt
                                elseif type(o.numFulfilled) == "number" and type(o.numRequired) == "number" and o.numRequired > 0 then
                                    progParts[#progParts + 1] = string.format("%d/%d", o.numFulfilled, o.numRequired)
                                end
                            end
                        end
                    end
                end
                local rec = {
                    questID = qid,
                    title = title,
                    progress = #progParts > 0 and table.concat(progParts, "; ") or nil,
                }
                activeByID[qid] = rec
                activeByTitle[string.lower(title)] = rec
            end
        end
    end

    -- 2. Check completion flags for known dungeon quests
    local list = TA.Data and TA.Data.DungeonQuests
    if type(list) == "table" then
        local isDone = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
        if type(isDone) == "function" then
            for _, d in ipairs(list) do
                for _, p in ipairs(d.pins or {}) do
                    if type(p.questID) == "number" and not activeByID[p.questID] and not completedByID[p.questID] then
                        local done = Try(isDone, p.questID)
                        if done == true then
                            completedByID[p.questID] = true
                        end
                    end
                end
            end
        end
    end

    self._activeByID = activeByID
    self._activeByTitle = activeByTitle
    self._completedByID = completedByID
end

--- Snapshot live boss encounter coordinates for a uiMapID via Compat.DungeonMapEncounters.
--- Called outside secureexecuterange (on SetMapID / zone change).
function DP:CacheMapEncounters(mapID)
    if type(mapID) ~= "number" or mapID <= 0 then return nil end
    local C = TA.Compat
    if not (C and type(C.DungeonMapEncounters) == "function") then return nil end
    local list = C.DungeonMapEncounters(mapID)
    if type(list) ~= "table" or #list == 0 then return nil end
    local byName = {}
    for _, e in ipairs(list) do
        if type(e) == "table" and type(e.name) == "string" and e.name ~= "" then
            byName[string.lower(e.name)] = e
        end
    end
    self._encountersByMap[mapID] = byName
    return byName
end

--- Match a map/zone name against TA.Data.DungeonQuests.
function DP.MatchDungeon(mapName)
    local name = PlainStr(mapName)
    if not name then return nil end
    local list = TA.Data and TA.Data.DungeonQuests
    if type(list) ~= "table" then return nil end
    local low = string.lower(name)
    for _, d in ipairs(list) do
        if type(d.dungeon) == "string" and string.lower(d.dungeon) == low then
            return d
        end
        if type(d.aliases) == "table" then
            for _, a in ipairs(d.aliases) do
                if type(a) == "string" and string.lower(a) == low then
                    return d
                end
            end
        end
    end
    -- Substring fallback (e.g. "Scarlet Monastery - Library" -> "Scarlet Monastery")
    for _, d in ipairs(list) do
        if type(d.dungeon) == "string" and low:find(string.lower(d.dungeon), 1, true) then
            return d
        end
    end
    return nil
end

local function MatchActiveQuest(pin, activeByID, activeByTitle)
    if type(pin.questID) == "number" and activeByID[pin.questID] then
        return activeByID[pin.questID]
    end
    if type(pin.questName) == "string" and pin.questName ~= "" then
        local low = string.lower(pin.questName)
        if activeByTitle[low] then return activeByTitle[low] end
        for qTitle, rec in pairs(activeByTitle) do
            if low:find(qTitle, 1, true) or qTitle:find(low, 1, true) then
                return rec
            end
        end
    end
    return nil
end

--- Pure resolver: produce all visible dungeon quest pins for a mapID + mapName.
--- Reads ONLY cached tables (zero WoW API calls), so MapPins:RefreshAllData stays taint-free.
function DP.ResolvePinsForMap(mapID, mapName, modeOverride)
    local mode = modeOverride or DP.GetMode()
    if mode == "off" then return {}, nil end
    local dungeon = DP.MatchDungeon(mapName)
    if not dungeon then return {}, nil end

    local faction = DP._playerFaction
    local encounters = (type(mapID) == "number" and DP._encountersByMap[mapID]) or nil
    local out = {}

    for _, p in ipairs(dungeon.pins or {}) do
        local fOk = (not p.faction) or (p.faction == "Both") or (not faction) or (p.faction == faction)
        if fOk then
            local activeRec = MatchActiveQuest(p, DP._activeByID, DP._activeByTitle)
            local isDone = (not activeRec) and type(p.questID) == "number" and DP._completedByID[p.questID] == true
            if not isDone and (mode == "all" or activeRec ~= nil) then
                -- Resolve coordinates: prefer live client boss position + offset, else fallback
                local x, y = nil, nil
                local liveAnchored = false
                if encounters and type(p.bossAnchor) == "string" then
                    local enc = encounters[string.lower(p.bossAnchor)]
                    if not enc then
                        local needle = string.lower(p.bossAnchor)
                        for k, v in pairs(encounters) do
                            if k:find(needle, 1, true) or needle:find(k, 1, true) then
                                enc = v
                                break
                            end
                        end
                    end
                    if enc and type(enc.x) == "number" and type(enc.y) == "number" then
                        local dx = (tonumber(p.dx) or 0) / 100
                        local dy = (tonumber(p.dy) or 0) / 100
                        x = Clamp01(enc.x + dx)
                        y = Clamp01(enc.y + dy)
                        liveAnchored = true
                    end
                end
                if x == nil and type(p.x) == "number" and type(p.y) == "number" then
                    x = Clamp01(p.x > 1 and (p.x / 100) or p.x)
                    y = Clamp01(p.y > 1 and (p.y / 100) or p.y)
                end

                if x ~= nil and y ~= nil then
                    local kind = p.kind or "item"
                    local cKey = (activeRec and "active_" or "ref_") .. kind
                    out[#out + 1] = {
                        id = p.id,
                        dungeon = dungeon.dungeon,
                        kind = kind,
                        badge = KIND_BADGE[kind] or "Q",
                        color = PIN_COLORS[cKey] or PIN_COLORS.ref_item,
                        active = activeRec ~= nil,
                        x = x,
                        y = y,
                        title = p.name,
                        questID = p.questID,
                        questName = (activeRec and activeRec.title) or p.questName,
                        progress = activeRec and activeRec.progress or nil,
                        faction = p.faction or "Both",
                        minLevel = dungeon.minLevel,
                        note = p.note,
                        bossAnchor = p.bossAnchor,
                        liveAnchored = liveAnchored,
                        estimated = p.estimated and true or false,
                    }
                end
            end
        end
    end

    return out, dungeon
end

--- Checklist summary for Now.lua when the player is currently inside a dungeon.
function DP.GetCurrentDungeonChecklist()
    if type(IsInInstance) ~= "function" then return nil end
    local ok, inInst, instType = pcall(IsInInstance)
    if not ok or not inInst or instType ~= "party" then return nil end

    local mapID, zoneName
    if TA.Compat and type(TA.Compat.PlayerMap) == "function" then
        mapID, zoneName = TA.Compat.PlayerMap()
    end
    if not zoneName and type(GetRealZoneText) == "function" then
        zoneName = PlainStr(Try(GetRealZoneText))
    end
    if not zoneName then return nil end

    local pins, dungeon = DP.ResolvePinsForMap(mapID, zoneName, "all")
    if not dungeon or #pins == 0 then return nil end

    local activeNames, refNames, seenQ = {}, {}, {}
    for _, p in ipairs(pins) do
        local qk = tostring(p.questName or p.title)
        if not seenQ[qk] then
            seenQ[qk] = true
            if p.active then
                local label = p.progress and (p.questName .. " (" .. p.progress .. ")") or p.questName
                activeNames[#activeNames + 1] = label
            else
                refNames[#refNames + 1] = p.questName or p.title
            end
        end
    end

    return {
        dungeon = dungeon.dungeon,
        pinCount = #pins,
        activeCount = #activeNames,
        activeNames = activeNames,
        refNames = refNames,
    }
end

function DP:HookWorldMap()
    if self._mapHooked then return end
    if WorldMapFrame and type(hooksecurefunc) == "function" and type(WorldMapFrame.SetMapID) == "function" then
        self._mapHooked = true
        hooksecurefunc(WorldMapFrame, "SetMapID", function(_, mapID)
            if type(mapID) == "number" then
                DP:CacheMapEncounters(mapID)
            end
        end)
    end
end

function DP:Init()
    self:RefreshQuestCache()
    self:HookWorldMap()

    if type(CreateFrame) == "function" then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("QUEST_LOG_UPDATE")
        f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        f:RegisterEvent("QUEST_TURNED_IN")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(_, event, arg1)
            if event == "ADDON_LOADED" then
                if arg1 == "Blizzard_WorldMap" then DP:HookWorldMap() end
                return
            end
            DP:RefreshQuestCache()
            if TA.Compat and type(TA.Compat.PlayerMap) == "function" then
                local mid = TA.Compat.PlayerMap()
                if type(mid) == "number" then DP:CacheMapEncounters(mid) end
            end
            local MP = TA.GetModule and TA:GetModule("MapPins")
            if MP and MP.Refresh then pcall(MP.Refresh, MP) end
        end)
        self._eventFrame = f
    end
end

DP.SlashCommands = {
    dpins = function(arg)
        local a = type(arg) == "string" and string.lower(arg:gsub("^%s+", ""):gsub("%s+$", "")) or ""
        local mode
        if a == "all" or a == "active" or a == "off" then
            mode = DP.SetMode(a)
        else
            mode = DP.CycleMode()
        end
        if TA.Print and TA.LOG then
            local desc = (mode == "all") and "All faction dungeon quest items & bosses (active in gold)"
                or ((mode == "active") and "Active Quest Log items only" or "Off")
            TA:Print(TA.LOG.OUTPUT, "DungeonPins", "Dungeon map pins: " .. mode .. " -- " .. desc)
        end
    end,
}

return DP
