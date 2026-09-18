-- ToonAge/Modules/DevHelpers.lua (Classic — MoP 5.4.x / Interface 50504)
-- Developer tools: coordinate recorder, quest log scanner.
-- Adapted from Retail version — uses Classic quest log APIs and removes
-- C_QuestLog, C_SpellBook, and other retail-only namespaces.
--
-- Slash commands:
--   /coord           -- print current map position as a guide coord line
--   /coord dump      -- open the accumulated map-ID log in the export window
--   /taquestscan     -- export active quest log as paste-ready guide steps
--   /tarecord        -- show recorder status
--   /tarecord start [Guide Title]   -- begin recording quests in play order
--   /tarecord stop                  -- pause recording
--   /tarecord undo                  -- remove the last recorded step
--   /tarecord dump                  -- print the recorded guide stub
--   /tarecord clear                 -- wipe the recording and start fresh

local TA = ToonAge

local DH = {}
TA:RegisterModule("DevHelpers", DH)

DH.recording = false

local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF4AFF7A[TA-Dev]|r " .. msg)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Universal Export Window
-- ══════════════════════════════════════════════════════════════════════════════
local EXPORT_W, EXPORT_H = 720, 440

local function ExportFrame()
    if DH._export then return DH._export end

    local f = CreateFrame("Frame", "TADevExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(EXPORT_W, EXPORT_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({ bgFile   = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.06, 0.97)
    f:SetBackdropBorderColor(0.35, 0.32, 0.28, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    f.heading = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.heading:SetPoint("TOPLEFT", 12, -10)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -28)
    hint:SetText("Ctrl+C copy  ·  Esc close")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 2)

    local selectAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selectAll:SetSize(80, 20)
    selectAll:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, -4)
    selectAll:SetText("Select All")

    local scroll = CreateFrame("ScrollFrame", "TADevExportScroll", f,
                               "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -46)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)

    local EB_INSET = 4
    local function WrapWidth(w)
        w = (w and w > 0) and w or scroll:GetWidth()
        if not w or w <= 0 then w = EXPORT_W - 12 - 32 end
        return math.max(1, w - EB_INSET)
    end

    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetAutoFocus(false)
    eb:SetWidth(WrapWidth())
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(eb)

    selectAll:SetScript("OnClick", function()
        eb:SetFocus()
        eb:HighlightText()
    end)

    scroll:SetScript("OnSizeChanged", function(_, w)
        eb:SetWidth(WrapWidth(w))
    end)

    -- Resize grip (SetResizable exists in MoP Classic)
    if f.SetResizable then
        f:SetResizable(true)
        if f.SetMinResize then f:SetMinResize(420, 240) end
        local grip = CreateFrame("Button", nil, f)
        grip:SetSize(16, 16)
        grip:SetPoint("BOTTOMRIGHT", -4, 4)
        grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
        grip:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)
    end

    tinsert(UISpecialFrames, "TADevExportFrame")

    f.editBox = eb
    f.scroll  = scroll
    DH._export = f
    return f
end

--- Show text in the shared export window, selected and ready to copy.
function DH:ShowExport(label, body)
    if type(body) == "table" then body = table.concat(body, "\n") end
    body = body or ""

    local f = ExportFrame()
    local _, newlines = body:gsub("\n", "")
    f.heading:SetText(string.format("|cFFFFD100%s|r  |cFF888888(%d lines)|r",
                                    label or "ToonAge Export", newlines + 1))
    f.editBox:SetText(body)
    f:Show()
    f.scroll:UpdateScrollChildRect()
    f.editBox:SetCursorPosition(0)
    f.editBox:HighlightText()
    f.editBox:SetFocus()
    return f
end

-- ── Quest Recorder ────────────────────────────────────────────────────────────
-- Records quests using Classic quest log APIs.

local function RecorderDB()
    TA.charDB.recorder = TA.charDB.recorder or {}
    local r = TA.charDB.recorder
    r.title  = r.title  or "Untitled Zone"
    r.zone   = r.zone   or 0
    r.steps  = r.steps  or {}
    return r
end

function DH:RecordQuest(questID)
    local r = RecorderDB()

    -- In MoP Classic, quest title from the log
    local title = "Quest " .. questID
    local numEntries = GetNumQuestLogEntries() or 0
    for i = 1, numEntries do
        local qTitle, _, _, isHeader, _, _, _, qID = GetQuestLogTitle(i)
        if not isHeader and qID == questID then
            title = qTitle or title
            break
        end
    end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or 0
    local x, y  = 0, 0
    if mapID and mapID > 0 and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then x, y = pos:GetXY() end
    end

    if #r.steps == 0 and mapID and mapID > 0 then
        r.zone = mapID
    end

    table.insert(r.steps, {
        questID = questID,
        text    = title,
        map     = mapID or 0,
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

    local text = table.concat(lines, "\n")
    TA.charDB.recorder.lastDump = text

    DH:ShowExport(string.format("Guide Stub — %s (%d steps)", r.title, #r.steps), text)
    p(string.format("Exported %d step(s). Also saved to ToonAgeDB.lua under 'recorder.lastDump'.", #r.steps))
end

-- ── /tarecord ────────────────────────────────────────────────────────────────

SLASH_TARECORD1 = "/tarecord"
SlashCmdList["TARECORD"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd  = (cmd  or ""):lower()
    rest = (rest or ""):match("^%s*(.-)%s*$")

    if cmd == "start" then
        if rest == "" then rest = "Untitled Zone" end

        local r   = RecorderDB()
        r.steps   = {}
        r.title   = rest
        r.zone    = 0
        DH.recording = true

        p('Recording started for: "|cFFFFD100' .. r.title .. '|r"')
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
        local r     = RecorderDB()
        local state = DH.recording and "|cFF1EFF00RECORDING|r" or "|cFFFF8800paused|r"
        p("Quest Recorder  [" .. state .. "]")
        p("  Guide: |cFFFFD100" .. (r.title or "?") .. "|r  |  Steps captured: " .. #r.steps)
        p("  /tarecord start <title> — begin recording")
        p("  /tarecord stop          — pause recording")
        p("  /tarecord undo          — remove last step")
        p("  /tarecord dump          — export Lua stub")
        p("  /tarecord clear         — wipe everything")
    end
end

-- ── /taquestscan — snapshot active quest log (Classic API) ────────────────────
-- Uses GetNumQuestLogEntries/GetQuestLogTitle/SelectQuestLogEntry

SLASH_TAQUESTSCAN1 = "/taquestscan"
SlashCmdList["TAQUESTSCAN"] = function()
    local numEntries, numQuests = GetNumQuestLogEntries()
    if not numEntries or numEntries == 0 then p("Quest log is empty."); return end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local mapInfo = mapID and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local zone = mapInfo and mapInfo.name or GetRealZoneText() or "Unknown"

    local px, py = 0, 0
    if mapID and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then px, py = pos:GetXY() end
    end

    local steps, count = {}, 0
    for i = 1, numEntries do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
              frequency, questID = GetQuestLogTitle(i)

        if not isHeader and questID and questID > 0 then
            -- Select the entry to read objectives if needed
            SelectQuestLogEntry(i)
            local status = isComplete and isComplete > 0 and "complete" or "inprogress"
            count = count + 1
            steps[#steps + 1] = string.format(
                '    { type = "quest", questID = %d, text = "%s",\n' ..
                '      coord = { map = %d, x = %.2f, y = %.2f } },  -- %s (lvl %d)',
                questID, EscLua(title or "?"), mapID or 0, px, py, status, level or 0)
        end
    end

    if count == 0 then p("No active quests (only headers)."); return end

    local out = {
        "-- ==============================================================",
        string.format("-- TA Quest Scan — %s (map %s)", zone, tostring(mapID)),
        string.format("-- %d active quest(s), captured at player position %.2f, %.2f",
                      count, px, py),
        "--",
        "-- NOTE: All coords are the PLAYER'S position at scan time.",
        "-- They are NOT each quest's objective location. Correct by hand.",
        "--",
        "-- Paste the entries into a guide's `steps = { ... }` block.",
        "-- ==============================================================",
        "",
    }
    for _, line in ipairs(steps) do out[#out + 1] = line end

    DH:ShowExport(string.format("Quest Scan — %s (%d quests)", zone, count), out)
    p(string.format("Exported %d quest(s) from %s.", count, zone))
end

-- ── /coord — print current position as a guide coord line ─────────────────────

local function CoordLog()
    if not TA.db then return nil end
    TA.db.coordLog = TA.db.coordLog or {}
    return TA.db.coordLog
end

local function CoordLogDump()
    local log = CoordLog()
    if not log or #log == 0 then
        p("Coord log is empty. Run /coord in each zone first.")
        return
    end
    local lines = {}
    for i, e in ipairs(log) do
        lines[#lines + 1] = string.format("%2d. %-28s map=%-6d %s",
            i, e.zone or "?", e.map or 0, e.parents or "")
    end

    DH:ShowExport(string.format("Coord Log — %d zone(s)", #log), lines)
end

SLASH_TACOORD1 = "/coord"
SlashCmdList["TACOORD"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "dump" or msg == "list" then CoordLogDump(); return end
    if msg == "clear" or msg == "wipe" then
        if TA.db then TA.db.coordLog = {} end
        p("Coord log cleared.")
        return
    end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not mapID then p("No map data available here."); return end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then p("Cannot read position on this map."); return end
    local x, y = pos:GetXY()
    local info = C_Map.GetMapInfo(mapID) or {}
    local zoneName = info.name or "Unknown"
    p(string.format("[%s  map=%d]  coord = { map = %d, x = %.2f, y = %.2f },",
        zoneName, mapID, mapID, x, y))

    -- Parent chain
    local chain, cur, guard = {}, info.parentMapID, 0
    while cur and cur > 0 and guard < 12 do
        local pInfo = C_Map.GetMapInfo(cur)
        if not pInfo then break end
        chain[#chain + 1] = string.format("%s (%d)", pInfo.name or "?", cur)
        cur = pInfo.parentMapID
        guard = guard + 1
    end
    local parentStr = #chain > 0 and table.concat(chain, "  >  ")
                                  or "none (top-level map)"
    p("  parents: " .. parentStr)

    -- Record it (replace earlier reading for same map)
    local log = CoordLog()
    if log then
        for i, e in ipairs(log) do
            if e.map == mapID then table.remove(log, i); break end
        end
        log[#log + 1] = { map = mapID, zone = zoneName, parents = parentStr }
        p(string.format("  |cFF888888logged (%d total) — /coord dump to copy them all|r", #log))
    end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function DH:Init()
    if TA.charDB.recorder and TA.charDB.recorder.steps and #TA.charDB.recorder.steps > 0 then
        p(string.format("Quest recorder has %d step(s) from a previous session.  /tarecord dump to export, /tarecord clear to reset.", #TA.charDB.recorder.steps))
    end
end
