-- ToonAge/Modules/AltTracker.lua
-- Alt Roster & Multi-Character Task Grid (BtWTodo-style)
-- Snapshots current character's data on login, reads all alts from SavedVariables,
-- renders a grid: columns = characters, rows = tasks/stats.
-- Displayed in Weekly tab sidebar or as a sub-view.

local TA = ToonAge
local U  = TA.Utils

local AltTracker = {}
TA:RegisterModule("AltTracker", AltTracker)

AltTracker.frames = {}

-- ── Color helpers ─────────────────────────────────────────────────────────────
local COL_GOLD  = "|cFFFFD100"
local COL_GREEN = "|cFF4AFF7A"
local COL_GREY  = "|cFF888780"
local COL_RED   = "|cFFFF4444"
local CLOSE     = "|r"

local function GetClassHex(class)
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if cc then return cc.colorStr or "ffffffff" end
    return "ffffffff"
end

local function FormatTimeSince(ts)
    if not ts or ts == 0 then return COL_GREY .. "—" .. CLOSE end
    local elapsed = time() - ts
    if elapsed < 60 then return COL_GREEN .. "Now" .. CLOSE end
    if elapsed < 3600 then return string.format("%dm ago", math.floor(elapsed / 60)) end
    if elapsed < 86400 then return string.format("%dh ago", math.floor(elapsed / 3600)) end
    if elapsed < 604800 then return string.format("%dd ago", math.floor(elapsed / 86400)) end
    return string.format("%dw ago", math.floor(elapsed / 604800))
end

-- ── Built-in task definitions ─────────────────────────────────────────────────
local BUILTIN_TASKS = {
    { id = "vault_dungeons", name = "Vault: Dungeons" },
    { id = "vault_raid",     name = "Vault: Raid" },
    { id = "vault_world",    name = "Vault: Delves" },
    { id = "weekly_quest",   name = "Weekly Quest" },
    { id = "world_boss",     name = "World Boss" },
    { id = "catalyst",       name = "Catalyst Charge" },
}

-- ── Snapshot ──────────────────────────────────────────────────────────────────
function AltTracker:SnapshotCurrentCharacter()
    if not TA.db or not TA.charKey then return end

    TA.db.altRoster = TA.db.altRoster or {}

    local _, class = UnitClass("player")
    local avgIlvl = 0
    if GetAverageItemLevel then
        avgIlvl = select(2, GetAverageItemLevel()) or 0
    end

    local entry = {
        name     = UnitName("player") or "Unknown",
        class    = class,
        level    = UnitLevel("player") or 0,
        ilvl     = math.floor(avgIlvl),
        lastSeen = time(),
        tasks    = {},
    }

    -- Auto-detect vault progress
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
        local actTypes = { 1, 2, 3 }  -- dungeon, raid, world
        local taskIDs  = { "vault_dungeons", "vault_raid", "vault_world" }
        for i, typeID in ipairs(actTypes) do
            local ok, activities = pcall(C_WeeklyRewards.GetActivities, typeID)
            if ok and type(activities) == "table" then
                -- Check if the highest tier (last activity) is unlocked
                local maxTier = activities[#activities]
                if maxTier and maxTier.progress and maxTier.threshold then
                    entry.tasks[taskIDs[i]] = (maxTier.progress >= maxTier.threshold)
                else
                    entry.tasks[taskIDs[i]] = false
                end
            end
        end
    end

    -- Also pull from charDB.weeklyTasks if Weekly module stored anything
    if TA.charDB and TA.charDB.weeklyTasks then
        for k, v in pairs(TA.charDB.weeklyTasks) do
            if entry.tasks[k] == nil then
                entry.tasks[k] = v
            end
        end
    end

    TA.db.altRoster[TA.charKey] = entry

    -- Also mirror into taskHistory for cross-module access
    TA.db.taskHistory = TA.db.taskHistory or {}
    TA.db.taskHistory[TA.charKey] = entry.tasks
end

-- ── Render: Full grid ─────────────────────────────────────────────────────────
-- Called when this module's tab/view is displayed.
function AltTracker:Render(content, sidebar)
    -- Cleanup previous frames
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local padL = 10
    local y    = -10
    local w    = content:GetWidth() - 20

    local function Track(f) table.insert(self.frames, f); return f end

    -- ── Header ────────────────────────────────────────────────────────────
    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    hdr:SetText(COL_GOLD .. "ACCOUNT ROSTER & WEEKLY TASKS" .. CLOSE)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 24

    local sep = Track(content:CreateTexture(nil, "ARTWORK"))
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
    sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    sep:SetColorTexture(0.55, 0.40, 0.08, 0.25)
    y = y - 12

    -- ── Collect characters ────────────────────────────────────────────────
    local roster = TA.db.altRoster or {}
    local chars = {}
    for key, data in pairs(roster) do
        table.insert(chars, { key = key, data = data })
    end
    -- Sort: current char first, then by lastSeen descending
    table.sort(chars, function(a, b)
        if a.key == TA.charKey then return true end
        if b.key == TA.charKey then return false end
        return (a.data.lastSeen or 0) > (b.data.lastSeen or 0)
    end)

    if #chars == 0 then
        local nodata = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        nodata:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        nodata:SetText(COL_GREY .. "No alts tracked yet. Log into other characters to populate." .. CLOSE)
        nodata:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        nodata:SetWidth(w)
        content:SetHeight(80)
        return
    end

    -- ── Grid layout ───────────────────────────────────────────────────────
    local COL_NAME_W  = 130
    local COL_DATA_W  = 55
    local ROW_H       = 28

    -- Column headers (character names)
    local headerRow = Track(CreateFrame("Frame", nil, content))
    headerRow:SetSize(w, ROW_H)
    headerRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

    -- Label column
    local cornerLbl = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cornerLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    cornerLbl:SetText(COL_GREY .. "Character →" .. CLOSE)
    cornerLbl:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 0, -6)

    for ci, charInfo in ipairs(chars) do
        local data = charInfo.data
        local hex  = GetClassHex(data.class)
        local lbl  = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        local displayName = data.name or charInfo.key:match("^(.-)%-")
        lbl:SetText("|c" .. hex .. displayName .. CLOSE)
        lbl:SetPoint("TOPLEFT", headerRow, "TOPLEFT", COL_NAME_W + (ci - 1) * COL_DATA_W, -6)
    end
    y = y - ROW_H

    -- ── Info rows: Level, iLvl, Last Login ────────────────────────────────
    local infoRows = {
        { label = "Level",    fn = function(d) return tostring(d.level or "?") end },
        { label = "iLvl",     fn = function(d) return tostring(d.ilvl or "—") end },
        { label = "Last Seen", fn = function(d) return FormatTimeSince(d.lastSeen) end },
    }

    for _, rowDef in ipairs(infoRows) do
        local row = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
        row:SetSize(w, ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.06, 0.05, 0.03, 0.5)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        lbl:SetText(COL_GREY .. rowDef.label .. CLOSE)
        lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -7)

        for ci, charInfo in ipairs(chars) do
            local val = rowDef.fn(charInfo.data)
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cell:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            cell:SetText(val)
            cell:SetPoint("TOPLEFT", row, "TOPLEFT", COL_NAME_W + (ci - 1) * COL_DATA_W, -7)
        end

        y = y - ROW_H
    end

    -- ── Task rows ─────────────────────────────────────────────────────────
    y = y - 6
    local taskHdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    taskHdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    taskHdr:SetText(COL_GOLD .. "WEEKLY TASKS" .. CLOSE)
    taskHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 16

    for _, taskDef in ipairs(BUILTIN_TASKS) do
        local row = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
        row:SetSize(w, ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.04, 0.04, 0.04, 0.5)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        lbl:SetText(taskDef.name)
        lbl:SetTextColor(0.78, 0.73, 0.48, 1)
        lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -7)

        for ci, charInfo in ipairs(chars) do
            local tasks = charInfo.data.tasks or {}
            local done  = tasks[taskDef.id]
            local sym
            if done == true then
                sym = COL_GREEN .. "✓" .. CLOSE
            elseif done == false then
                sym = COL_RED .. "○" .. CLOSE
            else
                sym = COL_GREY .. "—" .. CLOSE
            end
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cell:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            cell:SetText(sym)
            cell:SetPoint("TOPLEFT", row, "TOPLEFT", COL_NAME_W + (ci - 1) * COL_DATA_W + 10, -6)
        end

        y = y - ROW_H
    end

    -- Set content height for scroll
    content:SetHeight(math.abs(y) + 20)
end

-- ── Inline render for embedding in Weekly tab ─────────────────────────────────
-- Returns the new Y offset so Weekly can continue below
function AltTracker:RenderInline(content, startY)
    local padL = 10
    local y    = startY or -10
    local w    = content:GetWidth() - 20
    local ROW_H = 22
    local COL_W = 50
    local NAME_W = 100

    local function Track(f) table.insert(self.frames, f); return f end

    -- Section header
    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    hdr:SetText(COL_GOLD .. "ALT TASK OVERVIEW" .. CLOSE)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    y = y - 18

    local roster = TA.db.altRoster or {}
    for key, data in pairs(roster) do
        local hex = GetClassHex(data.class)
        local displayName = data.name or key:match("^(.-)%-") or key

        local row = Track(CreateFrame("Frame", nil, content))
        row:SetSize(w, ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

        local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        nameLbl:SetText("|c" .. hex .. displayName .. CLOSE)
        nameLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)

        local xOff = NAME_W
        for _, taskDef in ipairs(BUILTIN_TASKS) do
            local done = data.tasks and data.tasks[taskDef.id]
            local sym
            if done == true then sym = COL_GREEN .. "✓" .. CLOSE
            elseif done == false then sym = COL_RED .. "○" .. CLOSE
            else sym = COL_GREY .. "—" .. CLOSE
            end
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cell:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
            cell:SetText(sym)
            cell:SetPoint("TOPLEFT", row, "TOPLEFT", xOff, -4)
            xOff = xOff + COL_W
        end

        y = y - ROW_H
    end

    return y
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function AltTracker:Init()
    TA.db.altRoster   = TA.db.altRoster or {}
    TA.db.taskHistory = TA.db.taskHistory or {}

    -- Snapshot this character on every login
    self:SnapshotCurrentCharacter()
end

-- ── Slash commands ────────────────────────────────────────────────────────────
AltTracker.SlashCommands = {
    alts = function(self)
        if TA.UI then
            TA.UI:Show()
            TA.UI:SetTab("weekly")  -- renders inside weekly tab
        else
            -- Fallback: print summary to chat
            local roster = TA.db.altRoster or {}
            TA:Raw(TA.LOG.OUTPUT, COL_GOLD .. "[ToonAge] Alt Roster:" .. CLOSE)
            for key, data in pairs(roster) do
                local hex = GetClassHex(data.class)
                local name = data.name or key
                TA:Raw(TA.LOG.OUTPUT, string.format("  |c%s%s|r  Lv%d  iLvl %d  %s",
                    hex, name, data.level or 0, data.ilvl or 0, FormatTimeSince(data.lastSeen)))
            end
        end
    end,
}
