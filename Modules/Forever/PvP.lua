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
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverPvP", M)

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
    "PLAYER_PVP_RANK_CHANGED",
    "PLAYER_PVP_KILLS_CHANGED",
    "HONOR_CURRENCY_UPDATE",
    "PLAYER_FLAGS_CHANGED",
    "UNIT_FACTION",
}

return M
