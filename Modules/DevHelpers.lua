-- ToonAge/Modules/DevHelpers.lua
-- Developer tools: quest recorder, coordinate capture, quest log scanner.
--
-- Slash commands:
--   /coord           -- print current map position as a guide coord line
--   /taquestscan     -- dump active quest log with IDs and positions
--   /tarecord        -- show recorder status
--   /tarecord start [Guide Title]   -- begin recording quests in play order
--   /tarecord stop                  -- pause recording
--   /tarecord undo                  -- remove the last recorded step
--   /tarecord dump                  -- print the recorded guide stub to chat
--   /tarecord clear                 -- wipe the recording and start fresh

local TA = ToonAge

-- Register as a module so OnEvent receives QUEST_ACCEPTED from TA.eventFrame
local DH = {}
TA:RegisterModule("DevHelpers", DH)

DH.recording = false

local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF4AFF7A[TA-Dev]|r " .. msg)
end

-- ── Quest Recorder ────────────────────────────────────────────────────────────
-- Records quests in the exact order they enter the log, with the player's map
-- position at the moment of acceptance.  Stored in SavedVariables so the
-- recording survives a /reload.

local function RecorderDB()
    TA.charDB.recorder = TA.charDB.recorder or {}
    local r = TA.charDB.recorder
    r.title  = r.title  or "Untitled Zone"
    r.zone   = r.zone   or 0
    r.steps  = r.steps  or {}
    return r
end

function DH:RecordQuest(questID)
    local r     = RecorderDB()
    local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
                  or ("Quest " .. questID)

    local mapID = C_Map.GetBestMapForUnit("player") or 0
    local x, y  = 0, 0
    if mapID > 0 then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then x, y = pos:GetXY() end
    end

    -- Auto-fill zone on first quest
    if #r.steps == 0 and mapID > 0 then
        r.zone = mapID
    end

    table.insert(r.steps, {
        questID = questID,
        text    = title,
        map     = mapID,
        x       = x,
        y       = y,
    })

    p(string.format("Recorded #%d: [%d] %s  (%.2f, %.2f)", #r.steps, questID, title, x, y))
end

function DH:OnEvent(event, questID)
    if event == "QUEST_ACCEPTED" and self.recording then
        self:RecordQuest(questID)
    end
end

-- ── Dump ─────────────────────────────────────────────────────────────────────

local function EscLua(s)
    return s:gsub("\\", "\\\\"):gsub('"', '\\"')
end

function DH:DumpRecording()
    local r = RecorderDB()
    if #r.steps == 0 then
        p("Nothing recorded yet.  Run: /tarecord start My Zone Name")
        return
    end

    local guideID = r.title:lower():gsub("[^%a%d]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    local lines   = {}

    lines[#lines+1] = "-- =============================================="
    lines[#lines+1] = "-- TA Guide Stub — recorded in-game"
    lines[#lines+1] = "-- Title:  " .. r.title
    lines[#lines+1] = "-- Steps:  " .. #r.steps
    lines[#lines+1] = "-- =============================================="
    lines[#lines+1] = "local TA = ToonAge"
    lines[#lines+1] = "TA.GuideData = TA.GuideData or {}"
    lines[#lines+1] = 'TA.GuideData["' .. guideID .. '"] = {'
    lines[#lines+1] = '    id       = "' .. guideID .. '",'
    lines[#lines+1] = '    title    = "' .. EscLua(r.title) .. '",'
    lines[#lines+1] = "    zone     = " .. r.zone .. ","
    lines[#lines+1] = "    minLevel = 1,    -- TODO"
    lines[#lines+1] = "    maxLevel = 999,  -- TODO"
    lines[#lines+1] = "    steps = {"

    for i, step in ipairs(r.steps) do
        lines[#lines+1] = "        -- Step " .. i
        lines[#lines+1] = "        {"
        lines[#lines+1] = "            type    = " .. '"quest",'
        lines[#lines+1] = "            questID = " .. step.questID .. ","
        lines[#lines+1] = '            text    = "' .. EscLua(step.text) .. '",'
        lines[#lines+1] = string.format(
            "            coord   = { map = %d, x = %.2f, y = %.2f },",
            step.map, step.x, step.y)
        lines[#lines+1] = "        },"
    end

    lines[#lines+1] = "    },"
    lines[#lines+1] = "}"

    -- Print to chat (scrollable; copy from here or from SavedVariables)
    p("===== GUIDE STUB START (" .. #r.steps .. " steps) =====")
    for _, line in ipairs(lines) do
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
    p("===== GUIDE STUB END =====")

    -- Also stash the full text in SavedVariables so it survives a /reload
    -- and can be copied from WTF/Account/.../ToonAgeDB.lua
    TA.charDB.recorder.lastDump = table.concat(lines, "\n")
    p("Full stub also saved to ToonAgeDB.lua under key 'recorder.lastDump'.")
    p("Find it at: WTF/Account/<name>/<server>/<char>/ToonAgeDB.lua")
end

-- ── Guide list helper ────────────────────────────────────────────────────────

local function GetGuideList()
    -- Returns sorted list of { id, title, zone, minLevel, maxLevel }
    local list = {}
    for id, g in pairs(TA.Guides or {}) do
        table.insert(list, {
            id       = id,
            title    = g.title    or id,
            zone     = g.zone     or 0,
            minLevel = g.minLevel or 1,
            maxLevel = g.maxLevel or 999,
        })
    end
    table.sort(list, function(a, b)
        return a.minLevel < b.minLevel or (a.minLevel == b.minLevel and a.id < b.id)
    end)
    return list
end

local function PrintGuideList()
    local list = GetGuideList()
    if #list == 0 then
        p("No guides loaded.  Add .lua files to Data/Guides/ and the TOC, then /reload.")
        return
    end
    p("Available guides — type the number to start recording:")
    for i, g in ipairs(list) do
        p(string.format("  |cFFFFD100%d.|r  %-36s  lvl %d-%d  map=%d",
            i, g.title, g.minLevel, g.maxLevel, g.zone))
    end
    p("Usage:  /tarecord start 1   or   /tarecord start exiles_reach")
end

-- ── /tarecord ────────────────────────────────────────────────────────────────

SLASH_TARECORD1 = "/tarecord"
SlashCmdList["TARECORD"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")   -- trim
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd  = (cmd  or ""):lower()
    rest = (rest or ""):match("^%s*(.-)%s*$")

    if cmd == "start" then
        -- No argument → show guide list
        if rest == "" then
            PrintGuideList()
            return
        end

        -- Numeric argument → pick by index from sorted list
        local list = GetGuideList()
        local chosen = nil
        local idx = tonumber(rest)
        if idx then
            chosen = list[idx]
            if not chosen then
                p("No guide at index " .. idx .. ".  Run /tarecord start to see the list.")
                return
            end
        else
            -- String argument — match by id or partial title
            local lower = rest:lower()
            for _, g in ipairs(list) do
                if g.id == lower or g.id:find(lower, 1, true) or g.title:lower():find(lower, 1, true) then
                    chosen = g
                    break
                end
            end
            if not chosen then
                -- Treat the full string as a new guide title (no existing guide)
                chosen = { id = "", title = rest, zone = 0, minLevel = 1, maxLevel = 999 }
            end
        end

        local r   = RecorderDB()
        r.steps   = {}
        r.title   = chosen.title
        r.zone    = chosen.zone or 0
        r.guideID = chosen.id
        DH.recording = true

        p('Recording started for: "|cFFFFD100' .. r.title .. '|r"')
        if r.zone > 0 then
            p("  Zone map ID: " .. r.zone .. "  (auto-filled from guide definition)")
        else
            p("  Zone not set — will be captured from your position on first quest.")
        end
        p("Accept quests normally.  /tarecord stop  when done,  /tarecord dump  to export.")

    elseif cmd == "stop" then
        DH.recording = false
        local n = #RecorderDB().steps
        p("Recording paused.  " .. n .. " quest(s) captured.  /tarecord dump  to export.")

    elseif cmd == "undo" then
        local r = RecorderDB()
        if #r.steps == 0 then p("Nothing to undo."); return end
        local removed = table.remove(r.steps)
        p("Removed step #" .. (#r.steps + 1) .. ": [" .. removed.questID .. "] " .. removed.text)

    elseif cmd == "dump" then
        DH:DumpRecording()

    elseif cmd == "clear" then
        TA.charDB.recorder = { title = "Untitled Zone", zone = 0, steps = {} }
        DH.recording   = false
        p("Recording cleared.")

    elseif cmd == "title" and rest ~= "" then
        RecorderDB().title = rest
        p('Guide title set to: "' .. rest .. '"')

    else
        -- Status + help
        local r     = RecorderDB()
        local state = DH.recording and "|cFF1EFF00RECORDING|r" or "|cFFFF8800paused|r"
        p("Quest Recorder  [" .. state .. "]")
        p("  Guide: |cFFFFD100" .. (r.title or "?") .. "|r  |  Steps captured: " .. #r.steps)
        p("  /tarecord start     — show guide list to pick from")
        p("  /tarecord start 2   — start recording guide #2")
        p("  /tarecord stop      — pause recording")
        p("  /tarecord undo      — remove last step")
        p("  /tarecord dump      — print Lua stub to chat")
        p("  /tarecord clear     — wipe everything")
    end
end

-- ── /taquestscan — snapshot active quest log ──────────────────────────────────

SLASH_TAQUESTSCAN1 = "/taquestscan"
SlashCmdList["TAQUESTSCAN"] = function()
    local mapID   = C_Map.GetBestMapForUnit("player")
    local mapInfo = mapID and C_Map.GetMapInfo(mapID)
    local zone    = mapInfo and mapInfo.name or "Unknown"

    p(string.format("=== Quest Scan  [%s  map=%s] ===", zone, tostring(mapID)))

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    if numEntries == 0 then p("Quest log is empty."); return end

    local count = 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local qid  = info.questID
            local done = C_QuestLog.IsQuestFlaggedCompleted(qid) and "complete"
                      or (info.isComplete and "turnin" or "inprogress")
            local pos  = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
            local px, py = "?", "?"
            if pos then px = string.format("%.2f", (pos:GetXY())); py = select(2, string.format("%.2f", pos:GetXY())) end
            p(string.format("  %d  %-40s  %-10s", qid, info.title or "?", done))
            count = count + 1
        end
    end
    if count == 0 then p("No active quests (only headers).")
    else p("--- " .. count .. " quest(s) ---") end
end

-- ── /coord — print current position as a guide coord line ─────────────────────

SLASH_TACOORD1 = "/coord"
SlashCmdList["TACOORD"] = function()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then p("No map data available here."); return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then p("Cannot read position on this map."); return end
    local x, y = pos:GetXY()
    local zoneName = (C_Map.GetMapInfo(mapID) or {}).name or "Unknown"
    p(string.format("[%s  map=%d]  coord = { map = %d, x = %.2f, y = %.2f },",
        zoneName, mapID, mapID, x, y))
end

-- ── /taweekly — dump raw C_WeeklyRewards data for schema verification ─────────
-- Weekly.lua currently checks fake questIDs for Great Vault progress, which is
-- wrong -- Great Vault isn't quest-based. This dumps the REAL API's raw shape
-- so Weekly.lua can be rebuilt against confirmed field names instead of guesses.

SLASH_TAWEEKLY1 = "/taweekly"
SlashCmdList["TAWEEKLY"] = function()
    if not C_WeeklyRewards then
        p("C_WeeklyRewards does not exist on this client at all.")
        return
    end

    local ok, hasRewards = pcall(C_WeeklyRewards.HasAvailableRewards)
    p("HasAvailableRewards(): " .. tostring(ok and hasRewards or ("ERROR: " .. tostring(hasRewards))))

    if not C_WeeklyRewards.GetActivities then
        p("C_WeeklyRewards.GetActivities does not exist.")
        return
    end

    -- Try the Enum first; fall back to raw integers 1/2/3 if the Enum name
    -- turns out to be wrong or missing on this client.
    local typeList = {}
    if Enum and Enum.WeeklyRewardChestThresholdType then
        for name, value in pairs(Enum.WeeklyRewardChestThresholdType) do
            table.insert(typeList, { label = "Enum." .. name, value = value })
        end
    else
        p("|cFFFF8800Enum.WeeklyRewardChestThresholdType not found — trying raw ints 1/2/3 as a guess.|r")
        for i = 1, 3 do table.insert(typeList, { label = "raw " .. i, value = i }) end
    end

    for _, t in ipairs(typeList) do
        local ok2, activities = pcall(C_WeeklyRewards.GetActivities, t.value)
        if ok2 and activities then
            p(string.format("--- GetActivities(%s = %s): %d entries ---", t.label, tostring(t.value), #activities))
            for i, act in ipairs(activities) do
                local parts = {}
                for k, v in pairs(act) do
                    table.insert(parts, k .. "=" .. tostring(v))
                end
                p("  [" .. i .. "] " .. table.concat(parts, ", "))
            end
        else
            p(string.format("--- GetActivities(%s = %s): ERROR: %s ---", t.label, tostring(t.value), tostring(activities)))
        end
    end
end

-- ── /tadev — spec/talent debug ────────────────────────────────────────────────

SLASH_TADEV1 = "/tadev"
SlashCmdList["TADEV"] = function()
    local specIndex = GetSpecialization()
    if not specIndex then p("No active specialization detected."); return end
    local _, specName, _, specID = GetSpecializationInfo(specIndex)
    p("Spec: " .. tostring(specName) .. "  specID: " .. tostring(specID))
    local ids = {}
    if TA and TA.TalentsAPI and TA.TalentsAPI.GetActiveTalentIDs then
        ids = TA.TalentsAPI.GetActiveTalentIDs() or {}
    end
    if #ids == 0 then
        p("No talent IDs found. Open the Blizzard talent UI first, then run /tadev.")
        return
    end
    table.sort(ids)
    p("Active talent IDs: " .. table.concat(ids, ", "))
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function DH:Init()
    -- QUEST_ACCEPTED is already registered by QuestTracker; no duplicate needed.
    -- If DevHelpers loads before QuestTracker (unlikely but possible), register it.
    TA.eventFrame:RegisterEvent("QUEST_ACCEPTED")
    -- Restore recording state across reloads
    if TA.charDB.recorder and TA.charDB.recorder.steps and #TA.charDB.recorder.steps > 0 then
        p(string.format("Quest recorder has %d step(s) from a previous session.  /tarecord dump to export, /tarecord clear to reset.", #TA.charDB.recorder.steps))
    end
end
