-- ToonAge/Modules/DevHelpers.lua
-- Developer tools: quest recorder, coordinate capture, quest log scanner, talent scanner.
--
-- Every command that produces data you need OUT of the game writes to the shared
-- export window (TADevExportFrame) instead of the chat frame. Chat is for status
-- only. See the Universal Export Window section below for why.
--
-- Slash commands:
--   /coord           -- print current map position as a guide coord line
--   /coord dump      -- open the accumulated map-ID log in the export window
--   /taquestscan     -- export active quest log as paste-ready guide steps
--   /tateleports     -- export known teleports as CLASS_TELEPORTS entries
--   /tarecord        -- show recorder status
--   /tarecord start [Guide Title]   -- begin recording quests in play order
--   /tarecord stop                  -- pause recording
--   /tarecord undo                  -- remove the last recorded step
--   /tarecord dump                  -- print the recorded guide stub to chat
--   /tarecord clear                 -- wipe the recording and start fresh
--   /ta talentscan   -- export all saved talent loadouts for the current spec

local TA = ToonAge

-- Register as a module so OnEvent receives QUEST_ACCEPTED from TA.eventFrame
local DH = {}
TA:RegisterModule("DevHelpers", DH)

DH.recording = false

local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF4AFF7A[TA-Dev]|r " .. msg)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Universal Export Window
-- ══════════════════════════════════════════════════════════════════════════════
-- One selectable, scrollable text box shared by every dev command that produces
-- data meant to leave the game.
--
-- This generalises the old TACoordCopyFrame, which was built inline inside
-- CoordLogDump and therefore reachable only from `/coord dump`. Every other
-- command printed to DEFAULT_CHAT_FRAME, which is actively hostile to Lua:
-- it wraps long lines mid-token, strips leading whitespace (so nesting is
-- lost), and silently drops the top of the dump once the buffer's line cap is
-- hit — which a 400-line quest scan reaches immediately.
--
-- Single instance, created on first use and reused forever; per .rules.md the
-- addon never abandons frames.

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

    -- Select All. WoW gives addons no way to write the system clipboard, so
    -- this focuses the box and selects everything instead -- one click plus
    -- Ctrl+C, rather than click-into-box, Ctrl+A, Ctrl+C. This window is how
    -- captured data leaves the game, so the keystrokes are worth saving.
    local selectAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selectAll:SetSize(80, 20)
    selectAll:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, -4)
    selectAll:SetText("Select All")

    local scroll = CreateFrame("ScrollFrame", "TADevExportScroll", f,
                               "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -46)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)

    -- The scroll frame is sized by two anchors rather than SetSize, so
    -- GetWidth() can still be 0 on the frame it was created in -- layout has
    -- not run yet. Fall back to the width those anchors will resolve to
    -- (EXPORT_W minus the left inset and the scrollbar gutter) so the edit box
    -- is never handed a zero or negative width.
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

    -- Attached here rather than at creation: the button is anchored above, but
    -- `eb` does not exist until this point, so the handler could not close over
    -- it any earlier.
    selectAll:SetScript("OnClick", function()
        eb:SetFocus()
        eb:HighlightText()
    end)

    -- Keep the edit box's wrap width in step with the window, or resizing just
    -- reveals empty space while the text stays at its original wrap point.
    scroll:SetScript("OnSizeChanged", function(_, w)
        eb:SetWidth(WrapWidth(w))
    end)

    -- Resize grip. SetResizeBounds replaced SetMinResize/SetMaxResize in 10.0;
    -- both calls are guarded so a client lacking them still gets a usable
    -- fixed-size window rather than an error at frame construction.
    if f.SetResizable then
        f:SetResizable(true)
        if f.SetResizeBounds then f:SetResizeBounds(420, 240) end
        local grip = CreateFrame("Button", nil, f)
        grip:SetSize(16, 16)
        grip:SetPoint("BOTTOMRIGHT", -4, 4)
        grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
        grip:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)
    end

    tinsert(UISpecialFrames, "TADevExportFrame")   -- Esc closes the window

    f.editBox = eb
    f.scroll  = scroll
    DH._export = f
    return f
end

-- Show text in the shared export window, selected and ready to copy.
--   label — heading, e.g. "Quest Scan — Hallowfall"
--   body  — string, or a list of lines which is joined with newlines
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

    local text = table.concat(lines, "\n")

    -- Stash in SavedVariables first, so the export survives a /reload or a
    -- disconnect even if the window is closed without copying.
    TA.charDB.recorder.lastDump = text

    DH:ShowExport(string.format("Guide Stub — %s (%d steps)", r.title, #r.steps), text)
    p(string.format("Exported %d step(s). Also saved to ToonAgeDB.lua under 'recorder.lastDump'.", #r.steps))
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
    local numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
    if numEntries == 0 then p("Quest log is empty."); return end

    local mapID   = C_Map.GetBestMapForUnit("player")
    local mapInfo = mapID and C_Map.GetMapInfo(mapID)
    local zone    = mapInfo and mapInfo.name or "Unknown"

    -- Read the player's position ONCE. The old version called this per quest
    -- inside the loop, which cost N calls to return the same answer N times --
    -- there is one player and they are in one place for the whole scan.
    local px, py = 0, 0
    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then px, py = pos:GetXY() end
    end

    local steps, count = {}, 0
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local qid    = info.questID
            local status = C_QuestLog.IsQuestFlaggedCompleted(qid) and "complete"
                        or (info.isComplete and "turnin" or "inprogress")
            count = count + 1
            steps[#steps + 1] = string.format(
                '    { type = "quest", questID = %d, text = "%s",\n' ..
                '      coord = { map = %d, x = %.2f, y = %.2f } },  -- %s',
                qid, EscLua(info.title or "?"), mapID or 0, px, py, status)
        end
    end

    if count == 0 then p("No active quests (only headers)."); return end

    local out = {
        "-- ==============================================================",
        string.format("-- TA Quest Scan -- %s (map %s)", zone, tostring(mapID)),
        string.format("-- %d active quest(s), captured at player position %.2f, %.2f",
                      count, px, py),
        "--",
        "-- READ THIS BEFORE PASTING: every coord below is the PLAYER'S position",
        "-- at scan time, so they are all identical. They are NOT each quest's",
        "-- objective location. Either stand at the objective and re-scan one",
        "-- quest at a time, or treat these as placeholders and correct by hand.",
        "--",
        "-- TODO(pending API dump): C_QuestLog.GetNextWaypointForMap would give a",
        "-- real per-quest waypoint here. Not wired up -- that namespace is not yet",
        "-- verified on 12.1.0 and this file does not guess at APIs.",
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

-- Readings accumulate so a multi-zone verification trip survives zoning,
-- reloads, and logouts. `/coord dump` shows them all in one selectable box;
-- `/coord clear` wipes it.
--
-- Stored account-wide in TA.db, deliberately NOT per-character. A map ID is a
-- fact about the world, not about a character, and a verification run usually
-- spans several alts — one to reach a level-gated zone, a mage for the portal
-- room. Keying this per-character silently split those readings into separate
-- logs, so /coord dump only ever showed the current character's handful.
local function CoordLog()
    if not TA.db then return nil end
    TA.db.coordLog = TA.db.coordLog or {}

    -- One-time migration: fold any per-character logs from the original
    -- implementation into the shared one.
    if TA.db.char then
        for _, cdb in pairs(TA.db.char) do
            if type(cdb) == "table" and type(cdb.coordLog) == "table" then
                for _, e in ipairs(cdb.coordLog) do
                    local dup = false
                    for _, x in ipairs(TA.db.coordLog) do
                        if x.map == e.map then dup = true; break end
                    end
                    if not dup then TA.db.coordLog[#TA.db.coordLog + 1] = e end
                end
                cdb.coordLog = nil
            end
        end
    end

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

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then p("No map data available here."); return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then p("Cannot read position on this map."); return end
    local x, y = pos:GetXY()
    local info = C_Map.GetMapInfo(mapID) or {}
    local zoneName = info.name or "Unknown"
    p(string.format("[%s  map=%d]  coord = { map = %d, x = %.2f, y = %.2f },",
        zoneName, mapID, mapID, x, y))

    -- Parent chain. Two reasons this matters:
    --   1. Guide `zone` fields are matched by MapIsInZone(), which walks parents
    --      upward — so a guide keyed to a parent also matches inside its children.
    --      If two guides sit on a parent/child pair, the one with the LOWER
    --      minLevel wins the AutoSelectGuide loop regardless of which is more
    --      specific. Knowing the chain tells you whether that can happen.
    --   2. It's how you confirm a suspected parent ID (e.g. 2434) actually
    --      exists, rather than inferring it from a child's data.
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

    -- Record it. Replace any earlier reading for the same map so walking back
    -- through a zone doesn't fill the log with duplicates.
    local log = CoordLog()
    if log then
        for i, e in ipairs(log) do
            if e.map == mapID then table.remove(log, i); break end
        end
        log[#log + 1] = { map = mapID, zone = zoneName, parents = parentStr }
        p(string.format("  |cFF888888logged (%d total) — /coord dump to copy them all|r", #log))
    end
end

-- ── /tateleports — dump known teleport/portal spells with IDs ────────────────
-- TravelRouter.CLASS_TELEPORTS is hand-written and badly incomplete (three mage
-- entries, when a max-level mage has a dozen). Run this on each class you play
-- and paste the output into that table. Prints spellID so no lookup is needed.

SLASH_TATELEPORTS1 = "/tateleports"
SlashCmdList["TATELEPORTS"] = function()
    local _, class = UnitClass("player")

    local found  = 0
    local seen   = {}
    local hits   = {}

    local function report(name, spellID)
        if not name or not spellID or seen[spellID] then return end
        if not (name:find("Teleport") or name:find("Portal") or name:find("Dreamwalk")
                or name:find("Recall") or name:find("Death Gate")
                or name:find("Zen Pilgrimage")) then
            return
        end
        seen[spellID] = true
        found = found + 1
        -- toZone is nil, not `?`. The old version emitted a bare `?`, which is
        -- not a Lua expression -- every dump this command ever produced failed
        -- to parse on paste and had to be hand-edited first.
        hits[#hits + 1] = string.format(
            '    { spellID = %d, toZone = nil, class = "%s", label = "%s" },  -- TODO: toZone',
            spellID, class or "?", EscLua(name))
    end

    -- 11.0+ spellbook API, with a guard so this still runs on older clients.
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        local numLines = C_SpellBook.GetNumSpellBookSkillLines() or 0
        for i = 1, numLines do
            local line = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if line then
                local from = (line.itemIndexOffset or 0) + 1
                local to   = (line.itemIndexOffset or 0) + (line.numSpellBookItems or 0)
                for j = from, to do
                    local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo,
                                           j, Enum.SpellBookSpellBank.Player)
                    if ok and info then report(info.name, info.spellID) end
                end
            end
        end
    end

    if found == 0 then
        p("No teleports found. If you know you have some, the spellbook API may have")
        p("changed again — check C_SpellBook in /api or report the client build.")
        return
    end

    local out = {
        "-- ==============================================================",
        string.format("-- TA Teleport Scan -- %s (%s)", UnitName("player") or "?", class or "?"),
        string.format("-- %d spell(s) matched. Paste into TravelRouter.CLASS_TELEPORTS.", found),
        "--",
        "-- spellID and label are read straight from the spellbook and are exact.",
        "-- toZone is nil on purpose: fill it by casting each teleport and running",
        "-- /coord on arrival, then /coord dump to read the map IDs back out.",
        "--",
        "-- Matching is by English name substring (Teleport/Portal/Dreamwalk/Recall/",
        "-- Death Gate/Zen Pilgrimage), so this finds nothing on a localised client.",
        "-- ==============================================================",
        "",
    }
    for _, line in ipairs(hits) do out[#out + 1] = line end

    DH:ShowExport(string.format("Teleports — %s (%d)", class or "?", found), out)
    p(string.format("Exported %d teleport(s). Fill toZone via /coord on arrival.", found))
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

-- ── /ta talentscan — bulk export all talent loadouts for all specs ─────────────
-- Iterates through every spec the player can access and exports their saved
-- loadout strings. This is the fastest way to populate Data/Talents.lua with
-- real, validated import strings for your class.
--
-- Usage: /ta talentscan
-- Output: prints ready-to-paste Lua snippets to chat + saves to SavedVariables

local function TalentScan()
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
        p("C_ClassTalents API not available on this client.")
        return
    end

    local _, className = UnitClass("player")
    local activeSpecIdx = GetSpecialization()
    local numSpecs = GetNumSpecializations() or 0

    p("=== TALENT SCAN: " .. className .. " ===")
    p("Scanning " .. numSpecs .. " specialization(s)...")

    -- Store results in SavedVariables for easy external copy
    TA.charDB.talentExport = TA.charDB.talentExport or {}
    local export = TA.charDB.talentExport

    -- For the active spec, we can get the live export string + all saved loadouts
    local activeSpecID = GetSpecializationInfo(activeSpecIdx)
    local cfgID = C_ClassTalents.GetActiveConfigID()

    if cfgID then
        -- Active loadout
        if C_Traits and C_Traits.GenerateImportString then
            local str = C_Traits.GenerateImportString(cfgID)
            if str and str ~= "" then
                export[activeSpecID] = export[activeSpecID] or {}
                export[activeSpecID].active = str
                p(string.format("  [%d] Active loadout: %s", activeSpecID, str:sub(1, 50) .. "..."))
            end
        end

        -- All saved loadout names + strings (if API exposes them)
        if C_ClassTalents.GetConfigIDsBySpecID then
            for specIdx = 1, numSpecs do
                local specID = GetSpecializationInfo(specIdx)
                if specID then
                    export[specID] = export[specID] or {}
                    local ok, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, specID)
                    if ok and configIDs then
                        for _, cid in ipairs(configIDs) do
                            if C_Traits and C_Traits.GetConfigInfo then
                                local ok2, info = pcall(C_Traits.GetConfigInfo, cid)
                                if ok2 and info then
                                    local loadoutName = info.name or ("Loadout " .. cid)
                                    -- Try to generate export string for this config
                                    if C_Traits.GenerateImportString then
                                        local ok3, expStr = pcall(C_Traits.GenerateImportString, cid)
                                        if ok3 and expStr and expStr ~= "" then
                                            export[specID][loadoutName] = expStr
                                            p(string.format("  [%d] %s: %s", specID, loadoutName, expStr:sub(1, 50) .. "..."))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Summary
    local total = 0
    for specID, data in pairs(export) do
        for _ in pairs(data) do total = total + 1 end
    end
    p(string.format("=== Done. %d loadout string(s) captured. ===", total))
    p("Strings saved to ToonAgeDB (char section). Copy from SavedVariables file,")
    p("or use the 'Save Current as X Build' button in /ta talents to set them per content type.")
    p("")
    p("|cFF888780To populate ALL content types for this spec:|r")
    p("  1. Switch to your M+ loadout in Blizzard UI → open /ta talents → click Mythic+ tab → 'Save Current'")
    p("  2. Switch to Raid loadout → Raid tab → 'Save Current'")
    p("  3. Repeat for PvP, Delves, Leveling")
    p("  4. Each save persists in SavedVariables — available next session.")
end

-- Register as a module slash command so /ta talentscan works
DH.SlashCommands = DH.SlashCommands or {}
DH.SlashCommands["talentscan"] = function(self) TalentScan() end

-- ── Init ─────────────────────────────────────────────────────────────────────

function DH:Init()
    -- QUEST_ACCEPTED is now in Core/Init.lua's PERSISTENT_EVENTS list and is
    -- guaranteed registered before any module Init() runs. No re-registration
    -- needed here.
    -- Restore recording state across reloads
    if TA.charDB.recorder and TA.charDB.recorder.steps and #TA.charDB.recorder.steps > 0 then
        p(string.format("Quest recorder has %d step(s) from a previous session.  /tarecord dump to export, /tarecord clear to reset.", #TA.charDB.recorder.steps))
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- /ta secretprobe -- what do 12.0 secret values actually become?
--
-- CombatState coerces aura fields with U.SafeNum (tonumber(tostring(v))) before
-- using them as table keys, because a raw secret cannot be a key. That fix
-- stopped the crash. It does NOT prove the coercion produced the right number:
-- if tostring() on a secret yields something unparseable, SafeNum returns 0, the
-- `id > 0` guard drops the aura, and s.buffs stays empty -- silently. From the
-- outside that is indistinguishable from the original bug, except the error log
-- is clean.
--
-- This prints the raw type, the tostring() form, and the SafeNum result for a
-- live aura, plus how many entries actually landed in the state tables. Run it
-- while in combat with a buff up.
-- ══════════════════════════════════════════════════════════════════════════════
DH.SlashCommands = DH.SlashCommands or {}
DH.SlashCommands["secretprobe"] = function()
    local U = TA.Utils
    local out = function(msg) TA:Raw(TA.LOG.OUTPUT, msg) end

    out("|cFFFFD100━━━ Secret Value Probe ━━━|r")

    local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", 1)
    if not ok or not aura then
        out("  |cFFFF9A1ANo buff in slot 1.|r Get a buff up and re-run.")
    else
        local raw = aura.spellId
        out(("  spellId type      : |cFFFFD100%s|r"):format(type(raw)))
        out(("  tostring(spellId) : |cFFFFD100%s|r"):format(tostring(raw)))
        out(("  U.SafeNum(spellId): |cFFFFD100%s|r"):format(tostring(U.SafeNum(raw))))
        -- The verdict line. This is the whole reason the command exists.
        if U.SafeNum(raw) > 0 then
            out("  |cFF4AFF7A✓ Coercion works -- the real spellID survived.|r")
        else
            out("  |cFFFF4444✗ Coercion FAILED -- SafeNum returned 0, so auras are")
            out("     being dropped by the id > 0 guard. AlreadyActive can never")
            out("     see them and the prediction cannot change.|r")
        end

        -- ── Coercion matrix ───────────────────────────────────────────────
        -- Measured 12.0.7: type(v)=="number" and tostring(v)=="466904", yet
        -- tonumber(tostring(v)) is nil. Those cannot all hold for an ordinary
        -- Lua number, so one of the three is not what it appears to be. Rather
        -- than reason about which, try every route to an integer separately and
        -- let the client answer. Each runs under its own pcall because a secret
        -- value is expected to ERROR on some of these, and one error must not
        -- hide the results of the routes after it.
        out("|cFFFFD100  -- coercion matrix --|r")
        local function try(label, fn)
            local pok, res = pcall(fn)
            if pok then
                out(("    %-24s |cFF4AFF7A%s|r"):format(label, tostring(res)))
            else
                out(("    %-24s |cFFFF4444ERROR|r |cFF888780%s|r"):format(label, tostring(res)))
            end
        end

        try("tonumber(v)",           function() return tonumber(raw) end)
        try("tonumber(tostring(v))", function() return tonumber(tostring(raw)) end)
        try("v + 0",                 function() return raw + 0 end)
        try("math.floor(v)",         function() return math.floor(raw) end)
        try("format('%d', v)",       function() return string.format("%d", raw) end)
        try("v > 0",                 function() return raw > 0 end)
        -- The decisive one. If tostring(v) really is the 6-character string
        -- "466904" then tonumber on it cannot fail, so a length that is not 6
        -- means the string carries something the chat frame is not rendering.
        try("#tostring(v)",          function() return #tostring(raw) end)
        try("tostring(v):match(%d+)",function() return tostring(raw):match("%d+") end)
        try("tonumber(match)",       function() return tonumber(tostring(raw):match("%d+")) end)
        try("byte(1..3)",            function()
            local s = tostring(raw)
            return string.format("%s %s %s", tostring(s:byte(1)), tostring(s:byte(2)), tostring(s:byte(3)))
        end)
        try("as table key",          function()
            local t = {}
            t[raw] = true
            for k in pairs(t) do return type(k) .. " / " .. tostring(k) end
        end)
        out("|cFF888780  Paste this block back -- whichever route returns 466904 is")
        out("  the one U.SafeNum must use.|r")

        -- ── Per-aura sweep ────────────────────────────────────────────────
        -- Two runs of this command disagreed: 466904 coerced to 0 while
        -- inCombat was true, and 222202 coerced correctly while it was false.
        -- Two readings fit that. Either specific auras are secret and the rest
        -- are not, or ALL aura data goes secret for the duration of combat.
        -- They demand different fixes, and one slot-1 sample cannot tell them
        -- apart -- so walk every buff in a single run and count.
        out(("|cFFFFD100  -- all buffs (inCombat=%s) --|r")
            :format(tostring(InCombatLockdown() and true or false)))
        local total, failed = 0, 0
        for i = 1, 40 do
            local aok, a = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
            if not aok or not a then break end
            total = total + 1
            local id = U.SafeNum(a.spellId)
            if id == 0 then failed = failed + 1 end
            out(("    %2d  tostring=|cFFFFD100%-9s|r SafeNum=%s%s|r  %s")
                :format(i, tostring(a.spellId),
                        id == 0 and "|cFFFF4444" or "|cFF4AFF7A", tostring(id),
                        tostring(a.name or "?")))
        end
        -- The verdict that actually decides the fix.
        if total > 0 and failed == total then
            out(("  |cFFFF4444ALL %d failed -- coercion is gated on state, not on the aura.|r"):format(total))
        elseif failed > 0 then
            out(("  |cFFFF9A1A%d of %d failed -- it is per-aura, not a blanket rule.|r"):format(failed, total))
        else
            out(("  |cFF4AFF7AAll %d coerced cleanly.|r"):format(total))
        end
        out("|cFF888780  Run this once IN combat and once OUT of combat.|r")
    end

    local CS = TA:GetModule("CombatState")
    if CS and CS.state then
        local nb, nd = 0, 0
        for _ in pairs(CS.state.buffs   or {}) do nb = nb + 1 end
        for _ in pairs(CS.state.debuffs or {}) do nd = nd + 1 end
        out(("  state.buffs       : |cFFFFD100%d|r entries"):format(nb))
        out(("  state.debuffs     : |cFFFFD100%d|r entries"):format(nd))
        out(("  inCombat          : |cFFFFD100%s|r"):format(tostring(CS.state.inCombat)))
        if nb == 0 then
            out("  |cFFFF9A1Astate.buffs is empty -- if you have buffs up, that is the bug.|r")
        end
    end

    -- Cooldowns take the same path in GetNextN. If duration coerces to 0 the
    -- `dur > 1.5` test never fires, every spell looks off cooldown, and the
    -- same three entries win every evaluation.
    local cdOk, cd = pcall(C_Spell.GetSpellCooldown, 61304)   -- 61304 = global cooldown
    if cdOk and cd then
        out(("  cd.duration       : raw=|cFFFFD100%s|r  SafeNum=|cFFFFD100%s|r")
            :format(tostring(cd.duration), tostring(U.SafeNum(cd.duration))))
    end
    out("|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━|r")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- /ta auradump -- capture live buff/debuff IDs for authoring `when` predicates.
--
-- Data/RotationConditions.lua can express "only suggest Aimed Shot while Precise
-- Shots is up", but that needs the proc's real spellID. Those IDs exist nowhere
-- in this repo -- only in prose in Data/Rotations.lua ("empowered by Tip of the
-- Spear"). Guessing one produces a predicate that silently never fires, which is
-- indistinguishable from no predicate at all and is the same silent-no-op class
-- of bug ApiGuard was built to catch.
--
-- So: read them off the running client instead. Get the proc up, run this, and
-- paste the ID into the entry's when= clause.
-- ══════════════════════════════════════════════════════════════════════════════
DH.SlashCommands["auradump"] = function()
    local U = TA.Utils
    local out = function(msg) TA:Raw(TA.LOG.OUTPUT, msg) end

    out("|cFFFFD100━━━ Aura Dump ━━━|r")

    local function dump(label, getter, unit, filter)
        out(("|cFF888780%s|r"):format(label))
        local found = 0
        for i = 1, 40 do
            local ok, a = pcall(getter, unit, i, filter)
            if not ok or not a then break end
            local id = U.SafeNum(a.spellId)
            if id > 0 then
                found = found + 1
                local stacks = U.SafeNum(a.applications)
                out(("  |cFFFFD100%-7d|r %s%s"):format(
                    id,
                    tostring(a.name or "?"),
                    stacks > 1 and (" |cFF888780x" .. stacks .. "|r") or ""))
            end
        end
        if found == 0 then out("  |cFF888780(none)|r") end
    end

    dump("PLAYER BUFFS", C_UnitAuras.GetBuffDataByIndex, "player")
    if UnitExists("target") then
        dump("YOUR DEBUFFS ON TARGET", C_UnitAuras.GetDebuffDataByIndex, "target", "PLAYER")
    else
        out("|cFF888780(no target -- debuffs skipped)|r")
    end

    out("|cFF888780Paste an ID into Data/Rotations.lua, e.g.|r")
    out("|cFF888780  when=C.HasBuff(12345)  or  C.BuffStacks(12345, 2)|r")
    out("|cFFFFD100━━━━━━━━━━━━━━━━━|r")
end
