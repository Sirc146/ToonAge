-- ToonAge/Modules/Forever/PvP.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of the character's standing in Forever's honor system: current
-- rank, progress toward the next rank, and the honorable-kill / honor tallies
-- for this week, last week, this session and lifetime — exactly what the
-- default Blizzard "Player vs. Player" pane shows (Civilian, Rank Points X/Y,
-- weekly cap climbing to 24750 for Rank 14).
--
-- WHY THIS TAB EXISTS (and why an earlier draft wrongly skipped it). Forever
-- was assumed to have no meaningful PvP at its level-20 cap, on the reasoning
-- that Vanilla's rank grind was a level-60 endgame. That assumption was wrong:
-- the live client runs the full 14-rank honor ladder now, so this is real data
-- to report, not empty theatre. Lesson kept in the code: verify the client,
-- do not infer mechanics from retail-era lore.
--
-- STILL A READOUT, NOT ADVICE. No "grind X honor", no rank projections, no
-- battleground tactics — those need Forever-specific honor rates that only the
-- server knows. This reports the standing the client reports.
--
-- API REALITY: the Vanilla honor globals back that pane — UnitPVPRank /
-- GetPVPRankInfo (rank name + number), GetPVPRankProgress (0..1 toward next),
-- and the stat calls GetPVPThisWeekStats / GetPVPLastWeekStats /
-- GetPVPSessionStats / GetPVPLifetimeStats. Forever is custom, so every call is
-- guarded; a section whose calls return nothing is simply omitted rather than
-- shown as zero.
--
-- MEASURED 2026-09-28/30 (build 70124): UnitPVPRank, GetPVPRankInfo,
-- GetPVPRankProgress, GetPVPThisWeekStats and GetPVPLastWeekStats are ABSENT
-- to addons, so the rank and weekly blocks never draw. Present and drawn:
-- GetPVPSessionStats, GetPVPLifetimeStats, plus the racial matchup sections.
-- The paragraphs above describe the pane this tab was modelled on, not what
-- the API lets it show.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverPvP", M)

-- When this login started: the clock for the session honor rate. Session
-- stats count from LOGIN, not from a /reload, so the time is taken only on
-- PLAYER_ENTERING_WORLD with isInitialLogin and kept in charDB across reloads.
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, _, isInitialLogin)
        self:UnregisterAllEvents()
        if not TA.charDB then return end
        if isInitialLogin or not TA.charDB.pvpLoginAt then
            TA.charDB.pvpLoginAt = time and time() or nil
        end
        M._sessionStart = TA.charDB.pvpLoginAt
    end)
end

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Num(v)
    return tonumber(v)
end

local function Show(value, fmt)
    if value == nil then return "n/a" end
    if fmt then return string.format(fmt, value) end
    return tostring(value)
end

--- Current rank name and number.
--- UnitPVPRank returns an index; GetPVPRankInfo(index) -> (name, number).
--- The client offsets rank indices by 4 in the classic API, but Forever may
--- differ, so trust whatever the pair returns and fall back gracefully.
local function ReadRank()
    local rankIndex = Num(Try(UnitPVPRank, "player"))
    if not rankIndex then return nil end

    local name, number = Try(GetPVPRankInfo, rankIndex, "player")
    if not name then
        -- Some clients want the index without the unit argument.
        name, number = Try(GetPVPRankInfo, rankIndex)
    end
    return {
        name    = name and tostring(name) or nil,
        number  = Num(number),
        -- GetPVPRankProgress is a 0..1 fraction toward the next rank.
        progress = Num(Try(GetPVPRankProgress)),
    }
end

-- ─── RACIAL MATCHUPS ─────────────────────────────────────────────────────
--
-- Source: Data/Forever/Racials.lua, generated from the harvest -- every racial
-- measured on this client, per race and faction, tooltip verbatim, with the
-- removes / inflicts / detects / burst tags read from that tooltip text.
-- Measured 2026-09-29, all nine races on build 70124.
--
-- What this section can say from that data alone:
--   * what YOUR racials break, and on what cooldown
--   * what each enemy race brings: what it breaks, what it inflicts, whether
--     it sees stealth, and its burst window
--   * where the two meet: your racial answers their racial CC (Will to
--     Survive vs War Stomp), or theirs answers yours
-- What it does NOT say yet: which CLASS abilities each racial counters. That
-- needs every class's spell kit with its CC type, which comes from the spell
-- catalog scan, not from racials. No class matchups are guessed until then.

local RACE_NAMES = {
    Scourge = "Undead", NightElf = "Night Elf",
}
local function RaceName(key) return RACE_NAMES[key] or key end

local TAG_TEXT = {
    stun = "stuns", fear = "fear", charm = "charm", sleep = "sleep",
    snare = "roots and slows", bleed = "bleeds", poison = "poisons",
    disease = "diseases", curse = "curses",
}
local function TagText(list)
    local out = {}
    for i, t in ipairs(list or {}) do out[i] = TAG_TEXT[t] or t end
    return table.concat(out, ", ")
end

local function Cooldown(sec)
    if not sec then return nil end
    if sec >= 60 then return string.format("%d min", math.floor(sec / 60)) end
    return string.format("%d sec", sec)
end

--- The racials of one race and faction, one per name. A racial with class
--- variants (Gnome Eureka!, Undead Touch of the Grave) keeps the variant for
--- `class` when given, else the first -- the PvP tags are the same across
--- variants, only resource wording and proc chance differ.
local function RacialsFor(race, faction, class)
    local data = TA.Data and TA.Data.ForeverRacials
    local list = data and data[race] and data[race][faction]
    if not list then return nil end
    local byName, order = {}, {}
    for _, r in ipairs(list) do
        local mine = r.classes == nil
        if not mine and class then
            for _, c in ipairs(r.classes) do if c == class then mine = true end end
        end
        local cur = byName[r.name]
        if not cur then
            byName[r.name] = r; order[#order + 1] = r.name
        elseif mine and cur.classes then
            byName[r.name] = r
        end
    end
    local out = {}
    for _, n in ipairs(order) do out[#out + 1] = byName[n] end
    return out
end
M._RacialsFor = RacialsFor

--- PvP-relevant racials only: anything that removes, inflicts, detects or bursts.
local function PvPOnly(list)
    local out = {}
    for _, r in ipairs(list or {}) do
        if r.removes or r.inflicts or r.detects or r.burst then out[#out + 1] = r end
    end
    return out
end

--- One line per racial: what it does in a fight.
local function Describe(r)
    local bits = {}
    if r.removes then bits[#bits + 1] = "breaks " .. TagText(r.removes) end
    if r.inflicts then bits[#bits + 1] = "inflicts " .. TagText(r.inflicts) end
    if r.detects == "stealth" then bits[#bits + 1] = "reveals stealth" end
    if r.burst then bits[#bits + 1] = "burst" end
    local cd = Cooldown(r.cooldown)
    return table.concat(bits, "; ") .. (cd and ("  ·  " .. cd) or "")
end

--- Where an enemy race's racials meet yours.
--- @return table notes list of strings
local function Clashes(mine, theirs, myClass)
    local notes = {}
    local myRemoves, theirRemoves = {}, {}
    for _, r in ipairs(mine) do for _, t in ipairs(r.removes or {}) do myRemoves[t] = r end end
    for _, r in ipairs(theirs) do for _, t in ipairs(r.removes or {}) do theirRemoves[t] = r end end
    for _, r in ipairs(theirs) do
        for _, t in ipairs(r.inflicts or {}) do
            if myRemoves[t] then
                notes[#notes + 1] = { good = true, text = string.format(
                    "Your %s breaks their %s.", myRemoves[t].name, r.name) }
            else
                notes[#notes + 1] = { good = false, text = string.format(
                    "Their %s (%s) -- you have no racial that breaks it.", r.name, TagText(r.inflicts)) }
            end
        end
        if r.detects == "stealth" and (myClass == "ROGUE" or myClass == "DRUID") then
            notes[#notes + 1] = { good = false, text = string.format(
                "Their %s reveals stealth -- open from further out.", r.name) }
        end
    end
    for _, r in ipairs(mine) do
        for _, t in ipairs(r.inflicts or {}) do
            if theirRemoves[t] then
                notes[#notes + 1] = { good = false, text = string.format(
                    "Their %s breaks your %s.", theirRemoves[t].name, r.name) }
            end
        end
    end
    return notes
end
M._Clashes = Clashes

local function RenderYourRacials(content, y, race, faction, class)
    local mine = RacialsFor(race, faction, class)
    if not mine then return y, nil end
    local pvp = PvPOnly(mine)
    y = L:SectionHeader(content, y, "Your racials in PvP",
        string.format("%s · %s", RaceName(race), faction))
    if #pvp == 0 then
        y = L:Paragraph(content, y, "None of your racials break, inflict or reveal "
            .. "anything; their value is passive.", { color = L.C_DIM })
    end
    for _, r in ipairs(pvp) do
        y = L:DataRow(content, y, {
            label = r.name, value = Describe(r),
            status = r.removes and "good" or (r.burst and "warn" or "neutral"),
            tooltipTitle = r.name, tooltip = { r.tooltip },
        })
    end
    return y, mine
end

local function RenderMatchups(content, y, race, faction, class, mine)
    local data = TA.Data and TA.Data.ForeverRacials
    if not data then return y end
    local enemy = (faction == "Alliance") and "Horde" or "Alliance"
    local races = {}
    for r, byFaction in pairs(data) do
        if byFaction[enemy] then races[#races + 1] = r end
    end
    table.sort(races, function(a, b) return RaceName(a) < RaceName(b) end)
    if #races == 0 then return y end

    y = L:SectionHeader(content, y, "Enemy races (" .. enemy .. ")",
        "What each brings to a fight, and where it meets your racials.")
    for _, r in ipairs(races) do
        local theirs = PvPOnly(RacialsFor(r, enemy, nil))
        local parts = {}
        for _, x in ipairs(theirs) do parts[#parts + 1] = x.name end
        local notes = Clashes(PvPOnly(mine or {}), theirs, class)
        local bad, good = 0, 0
        for _, n in ipairs(notes) do if n.good then good = good + 1 else bad = bad + 1 end end
        local tip = {}
        for _, x in ipairs(theirs) do tip[#tip + 1] = x.name .. ": " .. Describe(x) end
        for _, n in ipairs(notes) do tip[#tip + 1] = (n.good and "+ " or "- ") .. n.text end
        local noteText
        if #notes > 0 then
            local lines = {}
            for i, n in ipairs(notes) do
                if i > 2 then lines[#lines + 1] = "..." break end
                lines[#lines + 1] = n.text
            end
            noteText = table.concat(lines, "  ")
        end
        y = L:DataRow(content, y, {
            label = RaceName(r),
            value = #parts > 0 and table.concat(parts, ", ") or "nothing active",
            status = (bad > good) and "warn" or ((good > 0) and "good" or "neutral"),
            note = noteText,
            noteColor = (bad > good) and "warn" or nil,
            tooltipTitle = RaceName(r) .. " (" .. enemy .. ")",
            tooltip = tip,
        })
    end
    y = L:Paragraph(content, y,
        "Racials only, measured on this client. Class matchups -- which of your "
        .. "abilities their racials break, and theirs yours -- arrive with the "
        .. "spell catalog.", { color = L.C_DIM })
    return y
end

--- Your current target, when it is an enemy player: its race's racials first,
--- since that is the fight in front of you.
local function RenderTarget(content, y, faction, class, mine)
    if not (Try(UnitExists, "target") and Try(UnitIsPlayer, "target")) then return y end
    if not Try(UnitIsEnemy, "player", "target") then return y end
    local _, tRace = Try(UnitRace, "target")
    local tFaction = Try(UnitFactionGroup, "target")
    local tName = Try(UnitName, "target")
    local isSecret = _G.issecretvalue
    if not tRace or not tFaction or (isSecret and (isSecret(tRace) or isSecret(tFaction))) then
        return y
    end
    local _, tClass = Try(UnitClass, "target")
    if tClass and isSecret and isSecret(tClass) then tClass = nil end
    local theirs = PvPOnly(RacialsFor(tRace, tFaction, tClass) or {})
    y = L:SectionHeader(content, y, "Your target",
        string.format("%s · %s", RaceName(tRace), tFaction))
    for _, x in ipairs(theirs) do
        y = L:DataRow(content, y, { label = x.name, value = Describe(x),
            tooltipTitle = x.name, tooltip = { x.tooltip } })
    end
    for _, n in ipairs(Clashes(PvPOnly(mine or {}), theirs, class)) do
        y = L:Paragraph(content, y, n.text, { color = n.good and L.C_SUCCESS or L.C_WARNING })
    end
    return y
end

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderStanding(content, y, rank)
    y = L:SectionHeader(content, y, "Standing",
        rank.number and string.format("Rank %d", rank.number) or nil)

    y = L:DataRow(content, y, {
        label = "Rank",
        value = rank.name or "n/a",
        bold  = true,
    })
    if rank.number ~= nil then
        y = L:DataRow(content, y, { label = "Rank number", value = Show(rank.number) })
    end

    -- Progress toward the next rank, as the pane's "Rank Points X / Y" bar.
    -- CapBar fills from current/cap, so feed the 0..1 fraction as current with
    -- a cap of 1; the percentage in the value text mirrors the fill.
    if rank.progress ~= nil then
        local pct = math.max(0, math.min(1, rank.progress))
        y = L:CapBar(content, y, {
            label   = "Progress to next rank",
            value   = string.format("%.0f%%", pct * 100),
            current = pct,
            cap     = 1,
            capped  = pct >= 1,
        })
    end
    return y
end

--- One tally block: (honorableKills, [dishonorable], honor).
--- The classic stat calls return several numbers; positions differ slightly by
--- client, so read defensively and only show what is a number.
local function RenderTally(content, y, title, fn)
    local hk, arg2, arg3 = Try(fn)
    hk = Num(hk)
    -- Honor is the last meaningful number in every variant; prefer arg3, then
    -- arg2, when present.
    local honor = Num(arg3) or Num(arg2)
    if hk == nil and honor == nil then return y, false end

    y = L:SectionHeader(content, y, title)
    if hk ~= nil then
        y = L:DataRow(content, y, { label = "Honorable kills", value = Show(hk) })
    end
    if honor ~= nil then
        y = L:DataRow(content, y, { label = "Honor", value = Show(honor) })
    end
    -- Your rate, measured (2026-10-03). The server's honor rules are unknown;
    -- what you earned over the time you have been logged in is not. Session
    -- stats count from login, so the clock is this UI session's: a /reload
    -- restarts it, and the line is withheld until 10 minutes have passed.
    if fn == GetPVPSessionStats and M._sessionStart and time then
        local minutes = (time() - M._sessionStart) / 60
        if minutes >= 10 and ((honor or 0) > 0 or (hk or 0) > 0) then
            local perHour = 60 / minutes
            y = L:DataRow(content, y, { label = "Per hour (this session)",
                value = string.format("%s honor, %s kills  (%d min)",
                    honor and string.format("%.0f", honor * perHour) or "?",
                    hk and string.format("%.1f", hk * perHour) or "?", math.floor(minutes)) })
        end
    end
    return y, true
end

local function RenderUnavailable(content, y)
    y = L:SectionHeader(content, y, "Player vs. Player")
    y = L:Paragraph(content, y,
        "The honor API did not answer on this client, so ToonAge shows nothing "
        .. "rather than a wrong or zero standing. If the in-game PvP pane shows a "
        .. "rank but this does not, the honor calls are named differently here.",
        { color = L.C_WARNING })
    y = L:Paragraph(content, y,
        "Worth reporting with /ta apiprobe so the honor globals can be mapped.")
    return y
end

local function RenderFooter(content, y)
    y = L:Divider(content, y)
    y = L:Paragraph(content, y,
        "Facts only — the standing the client reports. No honor-per-hour "
        .. "targets or rank projections; Forever's honor rates are the server's "
        .. "to define, not ToonAge's to guess.",
        { color = L.C_DIM })
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    -- Same identity sidebar as the other Forever tabs, when available.
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local rank = ReadRank()

    local y = -8
    local anyStat = false

    -- Racial matchups first: they are the part of this tab that helps in a
    -- fight. The honor standing below is a readout.
    local _, race = Try(UnitRace, "player")
    local faction = Try(UnitFactionGroup, "player")
    local _, class = Try(UnitClass, "player")
    if race and faction and TA.Data and TA.Data.ForeverRacials then
        local mine
        y, mine = RenderYourRacials(content, y, race, faction, class)
        y = RenderTarget(content, y, faction, class, mine)
        y = L:Divider(content, y)
        y = RenderMatchups(content, y, race, faction, class, mine)
        y = L:Divider(content, y)
    end

    if rank then
        y = RenderStanding(content, y, rank)
        y = L:Divider(content, y)
    end

    -- Tallies, each omitted if the client does not answer it.
    local shown
    y, shown = RenderTally(content, y, "This week",    GetPVPThisWeekStats)
    anyStat = anyStat or shown
    y, shown = RenderTally(content, y, "Last week",    GetPVPLastWeekStats)
    anyStat = anyStat or shown
    y, shown = RenderTally(content, y, "This session", GetPVPSessionStats)
    anyStat = anyStat or shown
    y, shown = RenderTally(content, y, "Lifetime",     GetPVPLifetimeStats)
    anyStat = anyStat or shown

    -- Nothing at all answered — not even a rank. Say so honestly.
    if not rank and not anyStat then
        y = RenderUnavailable(content, y)
    else
        y = RenderFooter(content, y)
    end

    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "PLAYER_TARGET_CHANGED",
    "PLAYER_PVP_RANK_CHANGED",
    "PLAYER_PVP_KILLS_CHANGED",
    "HONOR_CURRENCY_UPDATE",
    "PLAYER_FLAGS_CHANGED",
    "UNIT_FACTION",
}

return M
