-- Faction progress toward max.
--
-- reputations.lua marks each faction renown, standing (or standard), or
-- friendship. That field picks the read on Retail and on Forever.
-- Mists, TBC and Era use GetFactionInfoByID only: no Renown, no paragon.
-- Forever calls the same functions as Retail, each one guarded, and labels
-- the result unverified until Harvest probes them.
--
-- The bar is the stat bar with the value drawn inside the track, one line:
-- "<Standing> · cur / max". The fill is an existing palette token, mixed
-- toward the bar track so the white label stays readable. Hated uses the
-- dim token and Hostile the secondary token, so neither reads as the
-- warning or error red. A maxed Exalted row and a paragon row with no
-- positive threshold show the name only. The ratio is the progress inside
-- the current standing. The tooltip keeps that ratio and the absolute total.

local TA = ToonAge

local FT = {}
TA.FactionTracker = FT
TA:RegisterModule("FactionTracker", FT)

local function Secret(v)
    if v == nil or type(issecretvalue) ~= "function" then return false end
    local ok, res = pcall(issecretvalue, v)
    if not ok then return true end
    return res == true
end

local function CleanNum(v)
    if Secret(v) then return nil, "secret" end
    if type(v) ~= "number" then return nil, nil end
    return v, nil
end

function FT.Flavor()
    return TA.flavor or "retail"
end

function FT.Family(flavor)
    flavor = flavor or FT.Flavor()
    if flavor == "mists" or flavor == "tbc" or flavor == "vanilla" then return "classic" end
    if flavor == "forever" then return "forever" end
    return "retail"
end

function FT.System(faction)
    local system = type(faction) == "table" and faction.system or nil
    if system == "renown" then return "renown" end
    if system == "friendship" then return "friendship" end
    return "standing"
end

function FT.RouteID(faction)
    local id = type(faction) == "table" and faction.factionID or nil
    if type(id) ~= "number" then return nil end
    return "midnight_rep_" .. tostring(id)
end

local function Invoke(path, arg)
    local fn
    if FT._fn then fn = FT._fn(path) end
    if type(fn) ~= "function" then
        local Caps = TA.Caps
        if Caps and Caps.Fn then fn = Caps.Fn(path) end
    end
    if type(fn) ~= "function" then return false, "missing" end
    return pcall(fn, arg)
end

local function Unavailable(unverified, system)
    return {
        current = nil,
        cap = nil,
        atMax = false,
        paragon = false,
        unverified = unverified and true or false,
        text = "n/a",
        system = system,
        secret = false,
    }
end

local function Hidden(unverified, system)
    local row = Unavailable(unverified, system)
    row.secret = true
    return row
end

-- English names are the fallback when the client global is absent. A present
-- FACTION_STANDING_LABEL wins, so a localised client keeps its own word.
local STANDING_FALLBACK = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

function FT.StandingName(read)
    if type(read) ~= "table" then return nil end
    local id = read.reaction
    if Secret(id) or type(id) ~= "number" then return nil end
    local C = TA.Compat
    if C and type(C.FactionStandingName) == "function" then
        local ok, name = pcall(C.FactionStandingName, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return STANDING_FALLBACK[math.floor(id)]
end

--- Full in-bar line, and the standing alone for a bar that is too narrow.
--- No ratio when the band is missing or not positive, so a maxed or paragon
--- row never divides by zero.
function FT.BarLabel(read)
    if type(read) ~= "table" then return "n/a", "n/a" end
    local name = read.standingName
    if type(name) ~= "string" or name == "" then name = nil end
    local ratio
    local cur, maxv = read.bandCur, read.bandMax
    if type(cur) == "number" and type(maxv) == "number" and maxv > 0 then
        ratio = string.format("%d / %d", math.floor(math.max(0, cur)), math.floor(maxv))
    end
    if name and ratio then return name .. " · " .. ratio, name end
    if name then return name, name end
    if ratio then return ratio, ratio end
    return "n/a", "n/a"
end

function FT.BarTooltip(read)
    local lines = {}
    if type(read) ~= "table" then return lines end
    local name = read.standingName
    if type(name) ~= "string" or name == "" then name = "Unknown" end
    lines[#lines + 1] = "Standing: " .. name
    local cur, maxv = read.bandCur, read.bandMax
    if type(cur) == "number" and type(maxv) == "number" and maxv > 0 then
        lines[#lines + 1] = string.format("Progress: %d / %d",
            math.floor(math.max(0, cur)), math.floor(maxv))
    elseif read.atMax and not read.paragon then
        lines[#lines + 1] = "Progress: at max"
    elseif read.paragon then
        lines[#lines + 1] = "Progress: unavailable"
    end
    if type(read.total) == "number" then
        lines[#lines + 1] = string.format("Total: %d", math.floor(read.total))
    end
    return lines
end

--- Value and scale for the fill. Nil scale means "do not divide".
function FT.BarFill(read)
    if type(read) ~= "table" then return nil, nil end
    local cur, maxv = read.bandCur, read.bandMax
    if type(cur) == "number" and type(maxv) == "number" and maxv > 0 then
        return math.max(0, cur), maxv
    end
    if read.atMax and not read.paragon then return 1, 1 end
    return nil, nil
end

local function ApplyBar(read)
    if type(read) ~= "table" then return read end
    if read.paragon then
        read.standingName = "Paragon"
        if type(read.current) == "number" and type(read.cap) == "number" and read.cap > 0 then
            read.bandCur = read.current
            read.bandMax = read.cap
        else
            read.bandCur, read.bandMax = nil, nil
        end
    elseif read.system == "renown" then
        read.standingName = "Renown"
        if read.total == nil then read.total = read.current end
        if type(read.current) == "number" and type(read.cap) == "number" and read.cap > 0 then
            read.bandCur = read.current
            read.bandMax = read.cap
        end
    elseif read.system == "friendship" then
        local rank = read.rankName
        if type(rank) ~= "string" or rank == "" then rank = "Friendship" end
        read.standingName = rank
        if read.total == nil then read.total = read.current end
        if type(read.current) == "number" and type(read.cap) == "number" and read.cap > 0 then
            read.bandCur = read.current
            read.bandMax = read.cap
        else
            read.bandCur, read.bandMax = nil, nil
        end
    else
        read.standingName = FT.StandingName(read)
    end
    local full, short = FT.BarLabel(read)
    read.barText = full
    read.barShort = short
    return read
end

local function ParagonID(faction)
    local para = faction.paragon
    if type(para) == "table" and type(para.factionID) == "number" then
        return para.factionID
    end
    return faction.factionID
end

--- nil when this faction is not paragon. A table when the bar should show
--- paragon progress (neutral, including when the numbers are missing).
local function ReadParagon(faction, unverified)
    local pid = ParagonID(faction)
    local okFlag, flag = Invoke("C_Reputation.IsFactionParagon", pid)
    if not okFlag then flag = nil end
    if Secret(flag) then return Hidden(unverified, "paragon") end
    if flag ~= true and pid ~= faction.factionID then
        local ok2, flag2 = Invoke("C_Reputation.IsFactionParagon", faction.factionID)
        if ok2 and Secret(flag2) then return Hidden(unverified, "paragon") end
        if ok2 and flag2 == true then
            flag = true
            pid = faction.factionID
        end
    end
    if flag ~= true then return nil end

    local ok, currentValue, threshold = Invoke("C_Reputation.GetFactionParagonInfo", pid)
    if not ok or Secret(currentValue) or Secret(threshold) then
        if Secret(currentValue) or Secret(threshold) then
            local row = Hidden(unverified, "paragon")
            row.paragon = true
            return row
        end
        local row = Unavailable(unverified, "paragon")
        row.paragon = true
        return row
    end
    local cur = type(currentValue) == "number" and currentValue or nil
    local cap = type(threshold) == "number" and threshold or nil
    local capOut = (cap and cap > 0) and cap or nil
    local shown = cur
    if cur and capOut then shown = cur % capOut end
    local text = "n/a"
    if shown and capOut then text = string.format("%d/%d", shown, capOut) end
    return {
        current = shown,
        cap = capOut,
        total = cur,
        atMax = false,
        paragon = true,
        unverified = unverified and true or false,
        text = text,
        system = "paragon",
        scale = "paragon",
        secret = false,
    }
end

local function ReadRenown(faction, unverified)
    local ok, data = Invoke("C_MajorFactions.GetMajorFactionData", faction.factionID)
    if not ok or Secret(data) or type(data) ~= "table" then
        if Secret(data) then return Hidden(unverified, "renown") end
        return Unavailable(unverified, "renown")
    end
    local level, badL = CleanNum(data.renownLevel)
    if badL == "secret" then return Hidden(unverified, "renown") end
    local earned, badE = CleanNum(data.renownReputationEarned)
    if badE == "secret" then return Hidden(unverified, "renown") end
    local apiMax, badM = CleanNum(data.maxLevel)
    if badM == "secret" then return Hidden(unverified, "renown") end

    local info = type(faction.renown) == "table" and faction.renown or {}
    local per, badP = CleanNum(info.repPerLevel)
    if badP == "secret" then return Hidden(unverified, "renown") end
    local maxLevel = CleanNum(info.maxLevel)
    if not maxLevel then maxLevel = apiMax end

    local current, cap, scale
    if per and per > 0 and maxLevel and level then
        current = (level - 1) * per + (earned or 0)
        cap = maxLevel * per
        scale = "rep"
    elseif level and maxLevel then
        current = level
        cap = maxLevel
        scale = "levels"
    end
    local atMax = (level and maxLevel and level >= maxLevel) and true or false
    local text = "n/a"
    if current and cap then text = string.format("%d/%d", current, cap) end

    local para = ReadParagon(faction, unverified)
    if para then
        para.system = "renown"
        return para
    end
    return {
        current = current,
        cap = cap,
        atMax = atMax,
        paragon = false,
        unverified = unverified and true or false,
        text = text,
        system = "renown",
        scale = scale,
        secret = false,
    }
end

local function ExaltedMin(faction)
    local rows = faction.standings
    if type(rows) ~= "table" then return nil end
    for _, row in ipairs(rows) do
        if type(row) == "table" and row.standing == "Exalted" then
            local n, bad = CleanNum(row.min)
            if bad == "secret" then return nil, "secret" end
            return n, nil
        end
    end
    return nil, nil
end

local function ReadStanding(faction, unverified)
    local ok, data = Invoke("C_Reputation.GetFactionDataByID", faction.factionID)
    if not ok or Secret(data) or type(data) ~= "table" then
        if Secret(data) then return Hidden(unverified, "standing") end
        return Unavailable(unverified, "standing")
    end
    local reaction, badR = CleanNum(data.reaction)
    if badR == "secret" then return Hidden(unverified, "standing") end
    local current, badC = CleanNum(data.currentStanding)
    if badC == "secret" then return Hidden(unverified, "standing") end
    local exalted, badX = ExaltedMin(faction)
    if badX == "secret" then return Hidden(unverified, "standing") end
    local cap = exalted
    if not cap then
        local nxt, badN = CleanNum(data.nextReactionThreshold)
        if badN == "secret" then return Hidden(unverified, "standing") end
        cap = nxt
    end
    local atMax = ((reaction and reaction >= 8) or (current and exalted and current >= exalted)) and true or false
    local text = "n/a"
    if current and cap and cap > 0 then text = string.format("%d/%d", current, cap) end
    local lo, badLo = CleanNum(data.currentReactionThreshold)
    local hiBand, badHi = CleanNum(data.nextReactionThreshold)
    local bandCur, bandMax
    if badLo ~= "secret" and badHi ~= "secret"
        and type(current) == "number" and type(lo) == "number"
        and type(hiBand) == "number" and hiBand > lo then
        bandCur = current - lo
        bandMax = hiBand - lo
    end
    local para = ReadParagon(faction, unverified)
    if para then
        para.system = "standing"
        return para
    end
    return {
        current = current,
        cap = cap,
        total = current,
        bandCur = bandCur,
        bandMax = bandMax,
        reaction = reaction,
        atMax = atMax,
        paragon = false,
        unverified = unverified and true or false,
        text = text,
        system = "standing",
        scale = "rep",
        secret = false,
    }
end

local function ReadFriendship(faction, unverified)
    local ok, info = Invoke("C_GossipInfo.GetFriendshipReputation", faction.factionID)
    if not ok or Secret(info) or type(info) ~= "table" then
        if Secret(info) then return Hidden(unverified, "friendship") end
        return Unavailable(unverified, "friendship")
    end
    local standing, badS = CleanNum(info.standing)
    if badS == "secret" then return Hidden(unverified, "friendship") end
    local maxRep, badM = CleanNum(info.maxRep)
    if badM == "secret" then return Hidden(unverified, "friendship") end
    local _, badN = CleanNum(info.nextThreshold)
    if badN == "secret" then return Hidden(unverified, "friendship") end
    local atMax = false
    if standing and maxRep and standing >= maxRep then atMax = true end
    if standing and info.nextThreshold == nil then atMax = true end
    local rank = info.reaction
    if Secret(rank) or type(rank) ~= "string" or rank == "" then rank = nil end
    local text = "n/a"
    if standing and maxRep and maxRep > 0 then text = string.format("%d/%d", standing, maxRep) end
    return {
        current = standing,
        cap = (maxRep and maxRep > 0) and maxRep or nil,
        total = standing,
        rankName = rank,
        atMax = atMax,
        paragon = false,
        unverified = unverified and true or false,
        text = text,
        system = "friendship",
        scale = "rep",
        secret = false,
    }
end

--- Classic standings. barValue/barMax are the numbers. The name comes from
--- the standing id, and the bar shows the band inside that standing.
local function ReadClassic(faction)
    local ok, _, _, standingID, barMin, barMax, barValue =
        Invoke("GetFactionInfoByID", faction.factionID)
    if not ok then return Unavailable(false, "standing") end
    if Secret(standingID) or Secret(barMin) or Secret(barMax) or Secret(barValue) then
        return Hidden(false, "standing")
    end
    local standing = type(standingID) == "number" and standingID or nil
    local lo = type(barMin) == "number" and barMin or nil
    local hi = type(barMax) == "number" and barMax or nil
    local value = type(barValue) == "number" and barValue or nil
    local span = (lo and hi) and (hi - lo) or nil
    local into = (value and type(lo) == "number" and span and span > 0) and (value - lo) or nil
    local text = "n/a"
    if value and hi and hi > 0 then text = string.format("%d/%d", value, hi) end
    local bandCur, bandMax
    if span and span > 0 and type(value) == "number" and type(lo) == "number" then
        bandCur = value - lo
        bandMax = span
    end
    return {
        current = into or value,
        cap = (span and span > 0) and span or hi,
        total = value,
        bandCur = bandCur,
        bandMax = bandMax,
        reaction = standing,
        atMax = (standing and standing >= 8) and true or false,
        paragon = false,
        unverified = false,
        text = text,
        system = "standing",
        scale = "rep",
        secret = false,
    }
end

function FT.Read(faction, flavor)
    flavor = flavor or FT.Flavor()
    local family = FT.Family(flavor)
    local unverified = family == "forever"
    if type(faction) ~= "table" or type(faction.factionID) ~= "number" then
        return Unavailable(unverified, nil)
    end
    if family == "classic" then return ApplyBar(ReadClassic(faction)) end
    local system = FT.System(faction)
    local read
    if system == "renown" then
        read = ReadRenown(faction, unverified)
    elseif system == "friendship" then
        read = ReadFriendship(faction, unverified)
    else
        read = ReadStanding(faction, unverified)
    end
    if unverified then read.unverified = true end
    return ApplyBar(read)
end

--- Palette key for a standing. Hated is dim and Hostile is secondary so the
--- fill is not the warning orange or the error red. Friendly through Exalted
--- share the good token, which is then toned down before it is painted.
function FT.ColorToken(read)
    if type(read) ~= "table" then return "neutral" end
    if read.paragon then return "accent" end
    if read.system == "renown" then return "stat" end
    if read.system == "friendship" then
        return read.atMax and "good" or "accent"
    end
    local id = tonumber(read.reaction)
    if id == 1 then return "dim" end
    if id == 2 then return "secondary" end
    if id == 3 then return "warn" end
    if id == 4 then return "header" end
    if id and id >= 5 and id <= 8 then return "good" end
    if read.atMax then return "good" end
    return "neutral"
end

function FT.BaseColor(read)
    local L = TA.Layout or {}
    local token = FT.ColorToken(read)
    local map = {
        dim = L.C_DIM,
        secondary = L.C_SECONDARY,
        warn = L.C_WARNING,
        header = L.C_HEADER,
        good = L.C_SUCCESS,
        accent = L.C_ACCENT,
        stat = L.C_STAT_BASE,
        neutral = (L.STATUS and L.STATUS.neutral) or L.C_PRIMARY,
    }
    return map[token], token
end

--- Mix a palette colour toward the bar track and drop the alpha. Both the
--- mix and the alpha are theme tokens. No new colour is introduced.
function FT.Tone(rgb)
    if type(rgb) ~= "table" then return rgb end
    local theme = TA.Theme and TA.Theme.active or nil
    local keep = theme and tonumber(theme.cap_dim) or nil
    local track = theme and theme.bar_track_bg or nil
    local alpha = theme and tonumber(theme.slot_current_a) or nil
    if not keep or type(track) ~= "table" or not alpha then
        return { rgb[1], rgb[2], rgb[3] }
    end
    local function ch(i)
        local src = tonumber(rgb[i]) or 0
        local dst = tonumber(track[i]) or 0
        return src * keep + dst * (1 - keep)
    end
    return { ch(1), ch(2), ch(3), alpha }
end

function FT.FillColor(read, active)
    -- `active` stays in the signature. The standing colour replaces the old
    -- gold highlight, so an active route no longer recolours the fill.
    local _ = active
    local base, token = FT.BaseColor(read)
    if type(base) ~= "table" then return token end
    return FT.Tone(base)
end

function FT.QuestDone(questID)
    if type(questID) ~= "number" then return false end
    local fn
    if FT._fn then fn = FT._fn("C_QuestLog.IsQuestFlaggedCompleted") end
    if type(fn) ~= "function" then
        local Caps = TA.Caps
        if Caps and Caps.Fn then fn = Caps.Fn("C_QuestLog.IsQuestFlaggedCompleted") end
    end
    if type(fn) ~= "function" and type(C_QuestLog) == "table" then
        fn = C_QuestLog.IsQuestFlaggedCompleted
    end
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, questID)
    if not ok or Secret(res) then return false end
    return res == true
end

function FT.QuestsLeft(faction, read, doneFn)
    local out = { count = nil, covered = 0, gap = nil, short = false }
    if type(read) ~= "table" then return out end
    if read.secret then return out end
    if read.paragon or read.atMax then
        out.count = 0
        out.gap = 0
        return out
    end
    if read.scale ~= "rep" or type(read.current) ~= "number" or type(read.cap) ~= "number" then
        out.note = "Per-level renown is not in the data, so quests left are not estimated."
        return out
    end
    local gap = read.cap - read.current
    out.gap = gap
    if gap <= 0 then
        out.count = 0
        return out
    end
    local quests = type(faction) == "table" and faction.earn and faction.earn.quests or nil
    if type(quests) ~= "table" then
        out.count = 0
        out.short = true
        return out
    end
    if not doneFn then doneFn = FT.QuestDone end
    local covered, count = 0, 0
    for _, quest in ipairs(quests) do
        if type(quest) == "table" and quest.frequency == "once" and covered < gap then
            local done = false
            if quest.questID and doneFn then done = doneFn(quest.questID) and true or false end
            if not done then
                if Secret(quest.amount) then
                    out.note = "A rep amount is hidden, so quests left are not estimated."
                    out.count = nil
                    return out
                end
                local amt = type(quest.amount) == "number" and quest.amount or 0
                count = count + 1
                covered = covered + amt
            end
        end
    end
    out.count = count
    out.covered = covered
    out.short = covered < gap
    return out
end

function FT.LeftLine(read, left)
    if type(read) == "table" and read.paragon then return "Paragon." end
    if type(read) == "table" and read.atMax then return "At max." end
    if type(left) ~= "table" or left.count == nil then
        return left and left.note or nil
    end
    if left.short then
        return string.format("Listed one-time quests cover %d of %d.", left.covered or 0, left.gap or 0)
    end
    if left.count == 1 then return "1 quest left." end
    return string.format("%d quests left.", left.count)
end

function FT.IsActive(faction)
    local QT = TA.GetModule and TA:GetModule("QuestTracker")
    local route = FT.RouteID(faction)
    return QT and route and QT.guideID == route or false
end

function FT.Run(faction)
    local QT = TA.GetModule and TA:GetModule("QuestTracker")
    if not QT or type(QT.SetGuide) ~= "function" then return false end
    local route = FT.RouteID(faction)
    if not route then return false end
    QT:SetGuide(route)
    return true
end

--- Factions currently shown in the reputation list. Nil when the count
--- cannot be read. An empty table means the displayed list had no faction
--- rows. Headers are not factions.
--- GetFactionInfo's index, and C_Reputation.GetFactionDataByIndex's sort
--- index, omit factions hidden by a collapsed parent. ExpandAllFactionHeaders
--- opens those headers, including nested ones that were not visible to
--- snapshot, and CollapseFactionHeader has no success return. This walk
--- does not call either. list.collapsed is true when a displayed header
--- is collapsed. list.unreadable is true when a row, its header flag, or
--- its name cannot be read. list.capped is true when the client count was
--- above 200 and the rest was not read. None of these open or close a header.
function FT.WalkClientFactions()
    local C = TA.Compat
    if not (C and type(C.GetNumFactions) == "function" and type(C.GetFactionDataByIndex) == "function") then
        return nil
    end

    local capped = false
    local function count()
        local ok, n = pcall(C.GetNumFactions)
        if not ok or Secret(n) or type(n) ~= "number" then return nil end
        if n > 200 then
            capped = true
            return 200
        end
        return n
    end

    local function rowAt(i)
        local ok, row = pcall(C.GetFactionDataByIndex, i)
        if not ok or type(row) ~= "table" then return nil end
        return row
    end

    -- Nil means the name cannot be shown. Secret and non-strings are
    -- rejected before any comparison. A blank check that throws is the
    -- same refusal.
    local function plainName(name)
        if Secret(name) then return nil end
        if type(name) ~= "string" then return nil end
        local ok, blank = pcall(function() return name == "" end)
        if not ok or blank then return nil end
        return name
    end

    local n = count()
    if not n then return nil end

    local list = {}
    local collapsed, unreadable = false, false
    for i = 1, n do
        local row = rowAt(i)
        if not row then
            unreadable = true
        elseif Secret(row.isHeader) or Secret(row.isCollapsed) then
            unreadable = true
        elseif row.isHeader == true then
            if row.isCollapsed == true then collapsed = true end
        else
            local name = plainName(row.name)
            if name then
                row.name = name
                row.observed = true
                list[#list + 1] = row
            else
                unreadable = true
            end
        end
    end
    list.collapsed = collapsed
    list.unreadable = unreadable
    list.capped = capped
    return list
end

local function ReadObserved(row)
    local reaction = row.reaction
    if Secret(reaction) or type(reaction) ~= "number" then reaction = nil end
    local factionID = row.factionID
    if Secret(factionID) or type(factionID) ~= "number" then factionID = nil end

    -- Paragon is retail-shaped. Forever only uses it when the guarded Compat
    -- wrapper can see the call. A missing API is not paragon.
    local C = TA.Compat
    if factionID and C and type(C.GetFactionParagon) == "function" then
        local ok, para = pcall(C.GetFactionParagon, factionID)
        if ok and type(para) == "table" and para.paragon then
            local cap = para.cap
            local shown = para.current
            local text = "n/a"
            if type(shown) == "number" and type(cap) == "number" and cap > 0 then
                text = string.format("%d/%d", shown, cap)
            end
            return ApplyBar({
                current = shown,
                cap = (type(cap) == "number" and cap > 0) and cap or nil,
                total = para.total,
                atMax = false,
                paragon = true,
                unverified = true,
                text = text,
                system = "paragon",
                scale = "paragon",
                secret = para.secret and true or false,
                reaction = reaction,
            })
        end
    end

    local value, badV = CleanNum(row.currentStanding)
    local hi, badH = CleanNum(row.nextReactionThreshold)
    local lo = CleanNum(row.currentReactionThreshold)
    if badV == "secret" or badH == "secret" then
        return ApplyBar(Hidden(true, "standing"))
    end
    local text = "n/a"
    if value and hi and hi > 0 then text = string.format("%d/%d", value, hi) end
    local span = (type(lo) == "number" and type(hi) == "number") and (hi - lo) or nil
    local bandCur, bandMax
    if type(value) == "number" and type(lo) == "number" and span and span > 0 then
        bandCur = value - lo
        bandMax = span
    end
    return ApplyBar({
        current = bandCur or value,
        cap = (span and span > 0) and span or hi,
        total = value,
        bandCur = bandCur,
        bandMax = bandMax,
        reaction = reaction,
        atMax = (reaction and reaction >= 8) and true or false,
        paragon = false,
        unverified = true,
        text = text,
        system = "standing",
        scale = "rep",
        secret = false,
    })
end

local function SortedFactions()
    local bag = TA.Reputations and TA.Reputations.midnight
    if type(bag) ~= "table" then return nil end
    local list = {}
    for _, faction in pairs(bag) do
        if type(faction) == "table" then list[#list + 1] = faction end
    end
    table.sort(list, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return list
end

function FT:Render(content, side)
    local L = TA.Layout
    if not L then return end
    local y = -8
    y = L:SectionHeader(content, y, "Reputation")
    if FT.Family() == "forever" then
        y = L:Paragraph(content, y,
            "Reputation reads are unverified until Harvest probes them.")
    end
    local list = SortedFactions()
    local observed = false
    if FT.Family() == "forever" then
        local walked = FT.WalkClientFactions()
        if type(walked) == "table" then
            list = walked
            observed = true
        end
    end
    if not list then
        local missing = FT.Family() == "forever"
            and "This client did not return a faction list."
            or  "No reputation routes on this client."
        y = L:Paragraph(content, y, missing)
        L:Finish(content, y)
        return
    end
    if observed and #list == 0 then
        if list.collapsed then
            y = L:Paragraph(content, y,
                "Faction headers are collapsed, so their factions were not read. "
                .. "The reputation window was not changed.")
        end
        if list.unreadable then
            y = L:Paragraph(content, y,
                "The faction list could not be read. The reputation window was not changed.")
        end
        if list.capped then
            y = L:Paragraph(content, y,
                "The faction list was longer than 200 rows. No faction was in the rows "
                .. "that were read, and the rest was not read.")
        end
        if not list.collapsed and not list.unreadable and not list.capped then
            y = L:Paragraph(content, y, "The client returned an empty faction list.")
        end
        L:Finish(content, y)
        return
    end
    for _, faction in ipairs(list) do
        local read = observed and ReadObserved(faction) or FT.Read(faction)
        local active = (not observed) and FT.IsActive(faction)
        local left = observed and nil or FT.QuestsLeft(faction, read)
        local full = read.barText or read.text or "n/a"
        local short = read.barShort or full
        local value, scale = FT.BarFill(read)
        y = L:StatBar(content, y, {
            label = faction.name or "Faction",
            value = value,
            scale = scale,
            color = FT.FillColor(read, active),
            text = full,
            shortText = short,
            inside = true,
            status = "neutral",
            tooltipTitle = faction.name or "Faction",
            tooltip = FT.BarTooltip(read),
        })
        local line = (not observed) and FT.LeftLine(read, left) or nil
        if line then y = L:Paragraph(content, y, line) end
        if not observed then
            local captured = faction
            y = L:ButtonRow(content, y, {
                { label = "Run this faction", onClick = function() FT.Run(captured) end },
            })
        end
    end
    if observed and list.collapsed then
        y = L:Paragraph(content, y,
            "Collapsed faction headers were left closed, so factions under them are not listed.")
    end
    if observed and list.unreadable then
        y = L:Paragraph(content, y,
            "A faction row could not be read and was skipped. The reputation window was not changed.")
    end
    if observed and list.capped then
        y = L:Paragraph(content, y,
            "The faction list was longer than 200 rows. Only the first 200 were read.")
    end
    L:Finish(content, y)
end
