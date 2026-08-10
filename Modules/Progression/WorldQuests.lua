-- ToonAge/Modules/Progression/WorldQuests.lua
-- World quest scanner and filter for the Weekly tab sidebar.
-- Surfaces active WQs filtered by reward type, sorted by value.
--
-- Uses C_TaskQuest.GetQuestsOnMap (preferred, 11.0.5+) with fallback to
-- C_TaskQuest.GetQuestsForPlayerByMapID (deprecated but present on 12.0.x).

local TA = ToonAge
local U  = TA.Utils

local WQ = {}
TA:RegisterModule("WorldQuests", WQ)

-- ── Constants ─────────────────────────────────────────────────────────────────
local FILTER = {
    ALL   = "all",
    GEAR  = "gear",
    GOLD  = "gold",
    REP   = "rep",
    MATS  = "mats",
}

local COL_GOLD  = "|cFFFFD100"
local COL_GREEN = "|cFF4AFF7A"
local COL_GREY  = "|cFF888780"
local COL_BLUE  = "|cFF0070DD"
local CLOSE     = "|r"

-- ── API detection ─────────────────────────────────────────────────────────────
local function GetQuestsOnMap(mapID)
    if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
        local ok, result = pcall(C_TaskQuest.GetQuestsOnMap, mapID)
        if ok and result then return result end
    end
    -- Fallback to deprecated API
    if C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID then
        local ok, result = pcall(C_TaskQuest.GetQuestsForPlayerByMapID, mapID)
        if ok and result then return result end
    end
    return nil
end

-- ── Reward detection ──────────────────────────────────────────────────────────
-- Returns: { type = "gear"|"gold"|"rep"|"mats"|"other", value = number, text = string }
local function ClassifyReward(questID)
    if not questID then return { type = "other", value = 0, text = "" } end

    -- Check gold reward
    local money = 0
    if GetQuestLogRewardMoney then
        local ok, val = pcall(GetQuestLogRewardMoney, questID)
        if ok and val then money = val end
    end

    -- Check item rewards
    local hasGear = false
    local itemIlvl = 0
    local itemName = ""
    local numItems = 0
    if GetNumQuestLogRewards then
        local ok, n = pcall(GetNumQuestLogRewards, questID)
        if ok and n then numItems = n end
    end
    for i = 1, numItems do
        if GetQuestLogRewardInfo then
            local ok, name, texture, count, quality, isUsable, itemID = pcall(GetQuestLogRewardInfo, i, questID)
            if ok and itemID then
                local _, _, _, ilvl, _, _, subType, _, equipLoc = GetItemInfo(itemID)
                if equipLoc and equipLoc ~= "" then
                    hasGear = true
                    itemIlvl = ilvl or 0
                    itemName = name or ""
                end
            end
        end
    end

    -- Check currency rewards (reputation tokens, profession mats)
    local hasCurrency = false
    local currText = ""
    if C_QuestLog and C_QuestLog.GetQuestRewardCurrencies then
        local ok, currencies = pcall(C_QuestLog.GetQuestRewardCurrencies, questID)
        if ok and currencies and #currencies > 0 then
            hasCurrency = true
            local first = currencies[1]
            currText = first.name or "Currency"
        end
    end

    -- Classify
    if hasGear then
        return { type = "gear", value = itemIlvl, text = itemName .. " (" .. itemIlvl .. ")" }
    elseif money > 10000 then  -- more than 1g
        local goldAmt = math.floor(money / 10000)
        return { type = "gold", value = goldAmt, text = goldAmt .. "g" }
    elseif hasCurrency then
        return { type = "rep", value = 1, text = currText }
    else
        return { type = "other", value = 0, text = "" }
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Scan world quests on the current map (or specified map).
--- Returns sorted array of { questID, title, x, y, timeLeft, reward, tagType }
--- @param mapID number|nil — defaults to player's current map
--- @param filter string|nil — "all", "gear", "gold", "rep", "mats"
--- @return table[] quests
function WQ:GetFilteredQuests(mapID, filter)
    mapID = mapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if not mapID then return {} end

    filter = filter or FILTER.ALL

    local raw = GetQuestsOnMap(mapID)
    if not raw or #raw == 0 then return {} end

    local results = {}
    for _, poi in ipairs(raw) do
        local qid = poi.questID
        if qid and not poi.inProgress then
            -- Get title
            local title = ""
            if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
                local ok, t = pcall(C_TaskQuest.GetQuestInfoByQuestID, qid)
                if ok and t then title = t end
            elseif C_QuestLog and C_QuestLog.GetTitleForQuestID then
                local ok, t = pcall(C_QuestLog.GetTitleForQuestID, qid)
                if ok and t then title = t end
            end

            -- Get time remaining
            local timeLeft = 0
            if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftMinutes then
                local ok, mins = pcall(C_TaskQuest.GetQuestTimeLeftMinutes, qid)
                if ok and mins then timeLeft = mins end
            end

            -- Classify reward
            local reward = ClassifyReward(qid)

            -- Apply filter
            local passFilter = (filter == FILTER.ALL)
                            or (filter == reward.type)
            if passFilter then
                table.insert(results, {
                    questID  = qid,
                    title    = title ~= "" and title or ("World Quest #" .. qid),
                    x        = poi.x or 0,
                    y        = poi.y or 0,
                    timeLeft = timeLeft,
                    reward   = reward,
                    tagType  = poi.questTagType,
                    mapID    = poi.mapID or mapID,
                })
            end
        end
    end

    -- Sort by value descending (best rewards first)
    table.sort(results, function(a, b)
        return (a.reward.value or 0) > (b.reward.value or 0)
    end)

    return results
end

--- Get a count summary per reward type for the current zone.
function WQ:GetZoneSummary(mapID)
    mapID = mapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if not mapID then return {} end

    local raw = GetQuestsOnMap(mapID)
    if not raw then return {} end

    local summary = { gear = 0, gold = 0, rep = 0, mats = 0, other = 0, total = 0 }
    for _, poi in ipairs(raw) do
        if poi.questID and not poi.inProgress then
            local reward = ClassifyReward(poi.questID)
            summary[reward.type] = (summary[reward.type] or 0) + 1
            summary.total = summary.total + 1
        end
    end
    return summary
end

-- ── Render (called from Weekly tab's sidebar) ─────────────────────────────────
function WQ:RenderSidebar(sidebar, filter)
    if not sidebar then return end
    filter = filter or FILTER.ALL

    local y = -10
    local w = sidebar:GetWidth() - 16

    -- Header
    local hdr = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    hdr:SetText(COL_GOLD .. "WORLD QUESTS" .. CLOSE)
    hdr:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
    y = y - 16

    -- Zone summary
    local summary = self:GetZoneSummary()
    local sumText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sumText:SetFont(STANDARD_TEXT_FONT, 9, "")
    sumText:SetText(COL_GREY .. summary.total .. " available" .. CLOSE)
    sumText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
    y = y - 14

    -- Filter buttons
    local filters = {
        { id = FILTER.ALL,  label = "All" },
        { id = FILTER.GEAR, label = "Gear" },
        { id = FILTER.GOLD, label = "Gold" },
        { id = FILTER.REP,  label = "Rep" },
    }
    local bx = 8
    for _, filt in ipairs(filters) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(38, 16)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", bx, y)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        if filt.id == filter then
            btn:SetBackdropColor(0.55, 0.40, 0.08, 0.8)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.9)
        else
            btn:SetBackdropColor(0.06, 0.06, 0.06, 1)
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)
        end
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 8, "")
        lbl:SetText(filt.label)
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        bx = bx + 42
    end
    y = y - 22

    -- Quest list
    local quests = self:GetFilteredQuests(nil, filter)
    if #quests == 0 then
        local empty = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetFont(STANDARD_TEXT_FONT, 9, "")
        empty:SetText(COL_GREY .. "No world quests found.\nTravel to a max-level zone." .. CLOSE)
        empty:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
        empty:SetWidth(w)
        y = y - 30
    else
        local maxShow = math.min(#quests, 8)
        for i = 1, maxShow do
            local q = quests[i]

            -- Title (truncated)
            local titleF = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleF:SetFont(STANDARD_TEXT_FONT, 9, "")
            local displayTitle = #q.title > 28 and q.title:sub(1, 28) .. "..." or q.title
            titleF:SetText(displayTitle)
            titleF:SetTextColor(0.88, 0.83, 0.65, 1)
            titleF:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)

            -- Reward badge (right)
            local rewardF = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rewardF:SetFont(STANDARD_TEXT_FONT, 8, "")
            local rCol = q.reward.type == "gear" and COL_BLUE
                      or q.reward.type == "gold" and COL_GOLD
                      or COL_GREY
            rewardF:SetText(rCol .. q.reward.text .. CLOSE)
            rewardF:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -8, y)

            y = y - 12

            -- Time remaining
            if q.timeLeft and q.timeLeft > 0 then
                local timeStr
                if q.timeLeft > 1440 then
                    timeStr = math.floor(q.timeLeft / 1440) .. "d"
                elseif q.timeLeft > 60 then
                    timeStr = math.floor(q.timeLeft / 60) .. "h"
                else
                    timeStr = q.timeLeft .. "m"
                end
                local timeF = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                timeF:SetFont(STANDARD_TEXT_FONT, 8, "")
                timeF:SetText(COL_GREY .. "  " .. timeStr .. " left" .. CLOSE)
                timeF:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
                y = y - 10
            end

            y = y - 4
        end

        if #quests > maxShow then
            local more = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            more:SetFont(STANDARD_TEXT_FONT, 8, "")
            more:SetText(COL_GREY .. "+" .. (#quests - maxShow) .. " more..." .. CLOSE)
            more:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, y)
            y = y - 12
        end
    end

    sidebar:SetHeight(math.abs(y) + 10)
end

-- ── Slash commands ────────────────────────────────────────────────────────────
WQ.SlashCommands = {
    wq = function(self, args)
        local filter = args ~= "" and args or "all"
        local quests = self:GetFilteredQuests(nil, filter)
        TA:Raw(TA.LOG.OUTPUT, COL_GOLD .. "[ToonAge World Quests]" .. CLOSE
            .. " " .. #quests .. " found (filter: " .. filter .. ")")
        for i, q in ipairs(quests) do
            if i > 10 then
                TA:Raw(TA.LOG.OUTPUT, COL_GREY .. "  +" .. (#quests - 10) .. " more..." .. CLOSE)
                break
            end
            local timeStr = ""
            if q.timeLeft and q.timeLeft > 0 then
                if q.timeLeft > 1440 then timeStr = " (" .. math.floor(q.timeLeft / 1440) .. "d)"
                elseif q.timeLeft > 60 then timeStr = " (" .. math.floor(q.timeLeft / 60) .. "h)"
                else timeStr = " (" .. q.timeLeft .. "m)" end
            end
            TA:Raw(TA.LOG.OUTPUT, string.format("  %s%s%s — %s",
                q.title, COL_GREY .. timeStr .. CLOSE,
                "",
                q.reward.text ~= "" and q.reward.text or q.reward.type))
        end
        TA:Raw(TA.LOG.OUTPUT, COL_GREY .. "Filters: all, gear, gold, rep, mats" .. CLOSE)
    end,
}
