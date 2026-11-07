-- Faction progress toward max.
--
-- reputations.lua marks each faction renown, standing (or standard), or
-- friendship. That field picks the read on Retail and on Forever.
-- Mists, TBC and Era use GetFactionInfoByID only: no Renown, no paragon.
-- Forever calls the same functions as Retail, each one guarded, and labels
-- the result unverified until Harvest probes them.
--
-- The bar is the existing stat bar. Neutral fill, gold while that faction's
-- route is the active guide, green only at max. Paragon past max stays
-- neutral. The number is never a colored standing name.

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
    local shown = cur
    if cur and cap and cap > 0 then shown = cur % cap end
    local text = "n/a"
    if shown and cap then text = string.format("%d/%d", shown, cap) end
    return {
        current = shown,
        cap = cap,
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
    if current and cap then text = string.format("%d/%d", current, cap) end
    local para = ReadParagon(faction, unverified)
    if para then
        para.system = "standing"
        return para
    end
    return {
        current = current,
        cap = cap,
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
    local text = "n/a"
    if standing and maxRep then text = string.format("%d/%d", standing, maxRep) end
    return {
        current = standing,
        cap = maxRep,
        atMax = atMax,
        paragon = false,
        unverified = unverified and true or false,
        text = text,
        system = "friendship",
        scale = "rep",
        secret = false,
    }
end

--- Classic standings. barValue/barMax are the numbers. The standing name
--- from the client is not shown and is not colored.
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
    local into = (value and lo and span and span > 0) and (value - lo) or nil
    local text = "n/a"
    if value and hi then text = string.format("%d/%d", value, hi) end
    return {
        current = into or value,
        cap = (span and span > 0) and span or hi,
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
    if family == "classic" then return ReadClassic(faction) end
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
    return read
end

function FT.FillColor(read, active)
    if type(read) == "table" and read.paragon then return "neutral" end
    if type(read) == "table" and read.atMax then return "good" end
    if active then
        local L = TA.Layout
        if L and L.C_HEADER then return L.C_HEADER end
        return { 1.00, 0.82, 0.00 }
    end
    return "neutral"
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

--- Factions the client itself lists. Nil when the walk cannot run.
--- An empty table means the client returned no rows. Headers are not factions.
--- Collapsed headers are opened only when they can be closed again afterwards.
function FT.WalkClientFactions()
    local C = TA.Compat
    if not (C and type(C.GetNumFactions) == "function" and type(C.GetFactionDataByIndex) == "function") then
        return nil
    end

    local function count()
        local ok, n = pcall(C.GetNumFactions)
        if not ok or Secret(n) or type(n) ~= "number" then return nil end
        if n > 200 then return 200 end
        return n
    end

    local function rowAt(i)
        local ok, row = pcall(C.GetFactionDataByIndex, i)
        if not ok or type(row) ~= "table" then return nil end
        return row
    end

    local function plainName(name)
        if Secret(name) or type(name) ~= "string" or name == "" then return nil end
        return name
    end

    local n = count()
    if not n then return nil end

    local saved = {}
    for i = 1, n do
        local row = rowAt(i)
        if row and not Secret(row.isHeader) and not Secret(row.isCollapsed) and row.isHeader == true then
            local name = plainName(row.name)
            if name and row.isCollapsed == true then
                saved[#saved + 1] = name
            end
        end
    end

    local canExpand, canCollapse = false, false
    if type(C.FactionHeadersCanToggle) == "function" then
        canExpand, canCollapse = C.FactionHeadersCanToggle()
    end
    if #saved > 0 and canExpand and canCollapse then
        C.ExpandAllFactionHeaders()
        local expanded = count()
        if expanded then n = expanded end
    end

    local list = {}
    for i = 1, n do
        local row = rowAt(i)
        if row and not Secret(row.isHeader) and row.isHeader ~= true then
            local name = plainName(row.name)
            if name then
                row.name = name
                row.observed = true
                list[#list + 1] = row
            end
        end
    end

    if #saved > 0 and canExpand and canCollapse then
        local restoreN = count() or n
        local wanted = {}
        for _, name in ipairs(saved) do wanted[name] = true end
        for i = restoreN, 1, -1 do
            local row = rowAt(i)
            if row and not Secret(row.isHeader) and not Secret(row.isCollapsed)
                and row.isHeader == true and row.isCollapsed ~= true then
                local name = plainName(row.name)
                if name and wanted[name] then
                    C.CollapseFactionHeader(i)
                end
            end
        end
    end
    return list
end

local function ReadObserved(row)
    local value, badV = CleanNum(row.currentStanding)
    local hi, badH = CleanNum(row.nextReactionThreshold)
    local lo = CleanNum(row.currentReactionThreshold)
    if badV == "secret" or badH == "secret" then
        return Hidden(true, "standing")
    end
    local text = "n/a"
    if value and hi then text = string.format("%d/%d", value, hi) end
    local span = (type(lo) == "number" and type(hi) == "number") and (hi - lo) or nil
    local into = value
    if value and type(lo) == "number" and span and span > 0 then into = value - lo end
    return {
        current = into,
        cap = (span and span > 0) and span or hi,
        atMax = false,
        paragon = false,
        unverified = true,
        text = text,
        system = "standing",
        scale = "rep",
        secret = false,
    }
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
        y = L:Paragraph(content, y, "The client returned an empty faction list.")
        L:Finish(content, y)
        return
    end
    for _, faction in ipairs(list) do
        local read = observed and ReadObserved(faction) or FT.Read(faction)
        local active = (not observed) and FT.IsActive(faction)
        local left = observed and nil or FT.QuestsLeft(faction, read)
        y = L:StatBar(content, y, {
            label = faction.name or "Faction",
            value = read.current,
            scale = read.cap,
            color = FT.FillColor(read, active),
            text = read.text,
            status = "neutral",
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
    L:Finish(content, y)
end
