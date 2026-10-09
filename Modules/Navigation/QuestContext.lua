-- ToonAge/Modules/Navigation/QuestContext.lua
-- Offers the current guide step's quest item to the shared context button.
--
-- GetQuestLogSpecialItemInfo is checked first. When that global is missing,
-- C_QuestLog.GetQuestLogSpecialItemInfo is the same lookup. The guide step's
-- useItem is the fallback, and it may be unverified. The game's own quest
-- item always wins over useItem.
--
-- UPDATE_MOUSEOVER_UNIT and PLAYER_SOFT_INTERACT_CHANGED are the trigger.
-- C_TooltipInfo.GetUnit is used when it exists; otherwise a hidden tooltip
-- is scanned. The button glows when that unit or object is an objective of
-- a quest in the log. The cursor is left to the game.
-- This file stays off Forever: it names quest-log APIs that client does not ship.

local TA = ToonAge
TA.modules = TA.modules or {}

local QC = {}
TA.QuestContext = QC
TA:RegisterModule("QuestContext", QC)

function QC.ParseSpecial(a, b)
    if type(a) == "table" then
        local name = a.name or a.itemName or a.link or a.itemLink
        local texture = a.texture or a.icon or a.itemTexture
        local itemID = a.itemID
        if not itemID and type(name) == "string" then
            itemID = tonumber(name:match("item:(%d+)"))
        end
        if not itemID and not (type(name) == "string" and name ~= "") then return nil end
        return { itemID = itemID, name = name, texture = texture }
    end
    if type(a) == "number" then
        return { itemID = a, texture = b }
    end
    if type(a) ~= "string" or a == "" then return nil end
    return {
        name = a,
        texture = b,
        itemID = tonumber(a:match("item:(%d+)")),
    }
end

function QC.LogIndex(questID)
    if type(questID) ~= "number" then return nil end
    if type(GetQuestLogIndexByID) == "function" then
        local ok, idx = pcall(GetQuestLogIndexByID, questID)
        if ok and type(idx) == "number" and idx > 0 then return idx end
    end
    local fn = C_QuestLog and C_QuestLog.GetLogIndexForQuestID
    if type(fn) == "function" then
        local ok, idx = pcall(fn, questID)
        if ok and type(idx) == "number" and idx > 0 then return idx end
    end
    return nil
end

--- The global first. The C_QuestLog form only when the global is absent.
function QC.ReadSpecial(logIndex)
    if not logIndex then return nil end
    if type(GetQuestLogSpecialItemInfo) == "function" then
        local ok, a, b = pcall(GetQuestLogSpecialItemInfo, logIndex)
        if not ok then return nil end
        return QC.ParseSpecial(a, b)
    end
    local fn = C_QuestLog and C_QuestLog.GetQuestLogSpecialItemInfo
    if type(fn) == "function" then
        local ok, a, b = pcall(fn, logIndex)
        if not ok then return nil end
        return QC.ParseSpecial(a, b)
    end
    return nil
end

function QC.SpecialInRange(logIndex)
    if not logIndex or type(IsQuestLogSpecialItemInRange) ~= "function" then return nil end
    local ok, v = pcall(IsQuestLogSpecialItemInRange, logIndex)
    if not ok or v == nil then return nil end
    if v == 1 or v == true then return true end
    if v == 0 or v == false then return false end
    return nil
end

function QC.Count(itemID)
    if type(itemID) ~= "number" then return nil end
    if C_Item and type(C_Item.GetItemCount) == "function" then
        local ok, n = pcall(C_Item.GetItemCount, itemID)
        if ok and type(n) == "number" then return n end
    end
    if type(GetItemCount) == "function" then
        local ok, n = pcall(GetItemCount, itemID)
        if ok and type(n) == "number" then return n end
    end
    return nil
end

function QC.ItemCooldown(itemID)
    if not itemID then return nil end
    local start, duration
    if type(GetItemCooldown) == "function" then
        local ok, a, b = pcall(GetItemCooldown, itemID)
        if ok then start, duration = a, b end
    end
    if start == nil and C_Container and type(C_Container.GetItemCooldown) == "function" then
        local ok, a, b = pcall(C_Container.GetItemCooldown, itemID)
        if ok then start, duration = a, b end
    end
    local CA = TA.ContextAction
    if not CA or type(CA.SafeCooldown) ~= "function" then return nil end
    return CA.SafeCooldown(start, duration)
end

--- Guide fallback. A number, or { id = n, unverified = true }. The step's
--- own unverified flag marks the id unverified too.
function QC.UseItem(step)
    if type(step) ~= "table" then return nil end
    local raw = step.useItem
    local id, unverified
    if type(raw) == "number" then
        id = raw
    elseif type(raw) == "string" then
        id = tonumber(raw)
    elseif type(raw) == "table" then
        id = tonumber(raw.id or raw.itemID)
        unverified = raw.unverified and true or false
    end
    if type(id) ~= "number" or id <= 0 then return nil end
    if step.useItemUnverified or step.unverified then unverified = true end
    return { id = id, unverified = unverified and true or false }
end

function QC.Plain(text)
    local CA = TA.ContextAction
    if CA and CA.Secret(text) then return nil end
    if type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end
    return text:lower()
end

function QC.LineKind(typeValue)
    local E = Enum and Enum.TooltipDataLineType
    if not E or typeValue == nil then return nil end
    if typeValue == E.QuestTitle then return "title" end
    if typeValue == E.QuestObjective then return "objective" end
    if typeValue == E.QuestPlayer then return "player" end
    return nil
end

function QC.LinesFromData(data)
    if type(data) ~= "table" then return nil end
    local raw = data.lines
    if type(raw) ~= "table" then return {} end
    local CA = TA.ContextAction
    local lines = {}
    for _, ln in ipairs(raw) do
        if type(ln) == "string" then
            lines[#lines + 1] = { text = ln }
        elseif type(ln) == "table" then
            local text = ln.leftText or ln.text
            if CA and CA.Secret(text) then text = nil end
            if type(text) ~= "string" then text = nil end
            local id = ln.id
            if id == nil then id = ln.tooltipID end
            if CA and CA.Secret(id) then id = nil end
            if type(id) ~= "number" then id = tonumber(id) end
            lines[#lines + 1] = { text = text, id = id, kind = QC.LineKind(ln.type) }
        end
    end
    return lines
end

function QC.TextHit(lineText, title, objectives)
    local text = QC.Plain(lineText)
    if not text or #text < 3 then return false end
    local titlePlain = QC.Plain(title)
    if titlePlain and #titlePlain >= 3 then
        if text == titlePlain or text:find(titlePlain, 1, true) or titlePlain:find(text, 1, true) then
            return true
        end
    end
    if type(objectives) == "table" then
        for _, obj in ipairs(objectives) do
            local plain = QC.Plain(obj)
            if plain and #plain >= 3 then
                if text == plain or text:find(plain, 1, true) or plain:find(text, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

--- questID when a tooltip line belongs to a quest in `owned`.
--- A quest-typed line whose id is in the log wins. Otherwise the line text
--- has to match that quest's title or objective.
function QC.MatchQuest(lines, owned, preferID)
    if type(lines) ~= "table" or type(owned) ~= "table" then return nil end
    for _, line in ipairs(lines) do
        if type(line) == "table" and line.kind and line.id and owned[line.id] then
            return line.id
        end
    end
    local found, first = {}, nil
    for _, line in ipairs(lines) do
        if type(line) == "table" then
            for id, quest in pairs(owned) do
                if type(quest) == "table" and not found[id]
                    and QC.TextHit(line.text, quest.title, quest.objectives) then
                    found[id] = true
                    if not first then first = id end
                end
            end
        end
    end
    if preferID and found[preferID] then return preferID end
    return first
end

function QC.UnitPresent(token)
    if type(UnitExists) ~= "function" then return false end
    local ok, exists = pcall(UnitExists, token)
    return ok and exists and true or false
end

function QC.ReadTipLines(tip, prefix)
    if not tip or type(tip.NumLines) ~= "function" then return nil end
    local okN, n = pcall(tip.NumLines, tip)
    if not okN or type(n) ~= "number" then return nil end
    local CA = TA.ContextAction
    local lines = {}
    for i = 1, n do
        local fs = _G[prefix .. "TextLeft" .. i]
        local text = fs and fs.GetText and fs:GetText()
        if not (CA and CA.Secret(text)) and type(text) == "string" and text ~= "" then
            lines[#lines + 1] = { text = text }
        end
    end
    return lines
end

--- Hidden scanner. The live GameTooltip is only read, and only when a
--- private tooltip cannot be created. The cursor is never changed.
function QC.ScanTooltip(token)
    if type(CreateFrame) ~= "function" then
        return QC.ReadTipLines(GameTooltip, "GameTooltip")
    end
    local tip = QC._scanTip
    if not tip then
        local ok, frame = pcall(CreateFrame, "GameTooltip", "TAContextScanTip", nil, "GameTooltipTemplate")
        if ok and frame then
            local owner = UIParent or WorldFrame
            if owner and frame.SetOwner then
                pcall(frame.SetOwner, frame, owner, "ANCHOR_NONE")
            end
            QC._scanTip = frame
            tip = frame
        end
    end
    if not tip or type(tip.SetUnit) ~= "function" then
        return QC.ReadTipLines(GameTooltip, "GameTooltip")
    end
    local ok = pcall(function()
        if tip.ClearLines then tip:ClearLines() end
        tip:SetUnit(token)
    end)
    if tip.Hide then pcall(tip.Hide, tip) end
    if not ok then return nil end
    return QC.ReadTipLines(tip, "TAContextScanTip")
end

function QC.TooltipLines(token)
    if not QC.UnitPresent(token) then return nil end
    local fn = C_TooltipInfo and C_TooltipInfo.GetUnit
    if type(fn) == "function" then
        local ok, data = pcall(fn, token)
        if ok then return QC.LinesFromData(data) or {} end
    end
    return QC.ScanTooltip(token)
end

--- Soft target first, then the mouseover.
function QC.HoveredQuest(owned, preferID)
    local soft = QC.TooltipLines("softinteract")
    local id = soft and QC.MatchQuest(soft, owned, preferID)
    if id then return id end
    local mouse = QC.TooltipLines("mouseover")
    return mouse and QC.MatchQuest(mouse, owned, preferID) or nil
end

function QC.ObjectiveTexts(questID)
    local texts = {}
    local fn = C_QuestLog and C_QuestLog.GetQuestObjectives
    if type(fn) == "function" and questID then
        local ok, objectives = pcall(fn, questID)
        if ok and type(objectives) == "table" then
            for _, obj in ipairs(objectives) do
                if type(obj) == "table" and type(obj.text) == "string" then
                    texts[#texts + 1] = obj.text
                end
            end
        end
    end
    return texts
end

function QC.OwnedQuests()
    local out = {}
    local CA = TA.ContextAction
    local numFn = C_QuestLog and C_QuestLog.GetNumQuestLogEntries
    local infoFn = C_QuestLog and C_QuestLog.GetInfo
    if type(numFn) == "function" and type(infoFn) == "function" then
        local ok, n = pcall(numFn)
        if ok and type(n) == "number" then
            for i = 1, n do
                local okI, info = pcall(infoFn, i)
                if okI and type(info) == "table" and not info.isHeader and type(info.questID) == "number" then
                    local title = info.title
                    if CA and CA.Secret(title) then title = nil end
                    if type(title) ~= "string" then title = nil end
                    out[info.questID] = {
                        title = title,
                        objectives = QC.ObjectiveTexts(info.questID),
                    }
                end
            end
            return out
        end
    end
    if type(GetNumQuestLogEntries) == "function" and type(GetQuestLogTitle) == "function" then
        local ok, n = pcall(GetNumQuestLogEntries)
        if ok and type(n) == "number" then
            for i = 1, n do
                local okT, title, _, _, isHeader, _, _, _, questID = pcall(GetQuestLogTitle, i)
                if okT and not isHeader and type(questID) == "number" then
                    if CA and CA.Secret(title) then title = nil end
                    if type(title) ~= "string" then title = nil end
                    out[questID] = { title = title, objectives = QC.ObjectiveTexts(questID) }
                end
            end
        end
    end
    return out
end

function QC.GuideView()
    local QT = TA.GetModule and TA:GetModule("QuestTracker")
    if not QT then return nil, nil end
    if type(QT.View) == "function" then
        local _, steps, idx = QT:View()
        return steps, idx
    end
    local guide = QT.guideID and TA.Guides and TA.Guides[QT.guideID]
    local steps = guide and guide.steps
    if not steps then return nil, nil end
    return steps, QT.stepIdx or 1
end

function QC.CurrentStep()
    local steps, idx = QC.GuideView()
    if not steps or not idx then return nil end
    return steps[idx]
end

--- The guide step for this quest. A step that carries an item wins, and the
--- current step wins when it is that quest and it has one.
function QC.StepForQuest(questID)
    local steps, idx = QC.GuideView()
    if not steps or not questID then return nil end
    local current = idx and steps[idx]
    local function carries(step)
        return QC.UseItem(step) or (type(step) == "table" and type(step.questItem) == "number")
    end
    if carries(current) and current.questID == questID then return current end
    local any
    for _, step in ipairs(steps) do
        if type(step) == "table" and step.questID == questID then
            if carries(step) then return step end
            any = any or step
        end
    end
    if type(current) == "table" and current.questID == questID then return current end
    return any
end

function QC.Texts(step, logIndex)
    local texts = {}
    if type(step) == "table" and type(step.text) == "string" then
        texts[#texts + 1] = step.text
    end
    local questID = step and step.questID
    local fn = C_QuestLog and C_QuestLog.GetQuestObjectives
    if type(fn) == "function" and questID then
        local ok, objectives = pcall(fn, questID)
        if ok and type(objectives) == "table" then
            for _, obj in ipairs(objectives) do
                if type(obj) == "table" and type(obj.text) == "string" then
                    texts[#texts + 1] = obj.text
                end
            end
        end
    end
    if logIndex and type(GetNumQuestLeaderBoards) == "function"
        and type(GetQuestLogLeaderBoard) == "function" then
        local okN, n = pcall(GetNumQuestLeaderBoards, logIndex)
        if okN and type(n) == "number" then
            for i = 1, n do
                local okT, text = pcall(GetQuestLogLeaderBoard, i, logIndex)
                if okT and type(text) == "string" then
                    texts[#texts + 1] = text
                end
            end
        end
    end
    return texts
end

function QC.CreatureIDs(questID)
    local ids = {}
    local objectivesFn = C_QuestLog and C_QuestLog.GetQuestObjectives
    local creaturesFn = C_QuestLog and C_QuestLog.GetQuestObjectiveCreatures
    if type(objectivesFn) ~= "function" or type(creaturesFn) ~= "function" or not questID then
        return ids
    end
    local ok, objectives = pcall(objectivesFn, questID)
    if not ok or type(objectives) ~= "table" then return ids end
    for i, obj in ipairs(objectives) do
        if type(obj) == "table" and not obj.finished then
            local okC, list = pcall(creaturesFn, questID, i)
            if okC and type(list) == "table" then
                for _, id in ipairs(list) do
                    if type(id) == "number" then ids[#ids + 1] = id end
                end
            end
        end
    end
    return ids
end

function QC.Yards(step)
    if type(step) ~= "table" then return nil end
    local Arrow = TA.GetModule and TA:GetModule("Arrow")
    if not Arrow or type(Arrow.GetEffectiveCoord) ~= "function" then return nil end
    local ok, coordMap, cx, cy = pcall(Arrow.GetEffectiveCoord, step)
    if not ok or not cx or not cy then return nil end
    if coordMap == 0 and cx == 0 and cy == 0 then return nil end
    local mapFn = C_Map and C_Map.GetBestMapForUnit
    local posFn = C_Map and C_Map.GetPlayerMapPosition
    if type(mapFn) ~= "function" or type(posFn) ~= "function" then return nil end
    local okMap, currentMap = pcall(mapFn, "player")
    if not okMap or not currentMap then return nil end
    local okPos, pos = pcall(posFn, currentMap, "player")
    if not okPos or not pos or type(pos.GetXY) ~= "function" then return nil end
    local okXY, px, py = pcall(pos.GetXY, pos)
    if not okXY or not px or not py then return nil end
    local U = TA.Utils
    if not U or type(U.ComputeDistance) ~= "function" then return nil end
    local okD, yards = pcall(U.ComputeDistance, px, py, cx, cy)
    if not okD then return nil end
    return yards
end

function QC.IsNear(step, logIndex)
    if QC.SpecialInRange(logIndex) == true then return true end
    local CA = TA.ContextAction
    if not CA or type(CA.WithinRange) ~= "function" then return false end
    return CA.WithinRange(QC.Yards(step), step and step.range) and true or false
end

function QC.IsTargeting(step, logIndex)
    if type(UnitExists) == "function" then
        local ok, exists = pcall(UnitExists, "target")
        if ok and not exists then return false end
    end
    local CA = TA.ContextAction
    if not CA then return false end
    local name, guid
    if type(UnitName) == "function" then
        local ok, n = pcall(UnitName, "target")
        if ok and not CA.Secret(n) then name = n end
    end
    if type(UnitGUID) == "function" then
        local ok, g = pcall(UnitGUID, "target")
        if ok and not CA.Secret(g) then guid = g end
    end
    return CA.TargetMatches(
        name,
        CA.UnitID(guid),
        CA.ObjectiveNames(QC.Texts(step, logIndex)),
        QC.CreatureIDs(step and step.questID)
    )
end

function QC:Refresh()
    local CA = TA.ContextAction
    if not CA or type(CA.Set) ~= "function" or type(CA.QuestCandidate) ~= "function" then
        return
    end
    local step = QC.CurrentStep()
    local owned = QC.OwnedQuests()
    local hoverID = QC.HoveredQuest(owned, step and step.questID)
    local questID = hoverID
    local hover = hoverID ~= nil
    local near, targeting = false, false
    if not hover and type(step) == "table" then
        local logIndex = QC.LogIndex(step.questID)
        near = QC.IsNear(step, logIndex) and true or false
        targeting = QC.IsTargeting(step, logIndex) and true or false
        if near or targeting then questID = step.questID or questID end
    end
    if not hover and not near and not targeting then
        CA:Set("quest item", nil)
        return
    end
    -- A hovered quest uses its own guide step. The current step is only the
    -- fallback for the near/target path, so its item cannot leak onto another quest.
    local guideStep = step
    if hover then guideStep = QC.StepForQuest(questID) end
    local special
    if questID then special = QC.ReadSpecial(QC.LogIndex(questID)) end
    local fromGame = special and (special.itemID or (type(special.name) == "string" and special.name ~= ""))
    local use = QC.UseItem(guideStep)
    local fallbackID, unverified
    if fromGame then
        unverified = false
    elseif use then
        fallbackID = use.id
        unverified = use.unverified
        special = nil
    elseif type(guideStep) == "table" and type(guideStep.questItem) == "number" then
        fallbackID = guideStep.questItem
        unverified = guideStep.unverified and true or false
        special = nil
    end
    local cand = CA.QuestCandidate({
        special = fromGame and special or nil,
        fallbackID = fallbackID,
        fallbackCount = QC.Count(fallbackID),
        near = near,
        targeting = targeting,
        hover = hover,
    })
    if cand then
        cand.unverified = unverified and true or false
        local id = (fromGame and special and special.itemID) or fallbackID
        local start, duration = QC.ItemCooldown(id)
        if start then cand.cooldown = { start = start, duration = duration } end
    end
    CA:Set("quest item", cand)
end

function QC:OnEvent(event)
    if event == "QUEST_LOG_UPDATE" or event == "PLAYER_TARGET_CHANGED"
        or event == "UPDATE_MOUSEOVER_UNIT" or event == "PLAYER_SOFT_INTERACT_CHANGED" then
        self:Refresh()
    end
end

QC.Events = {
    "QUEST_LOG_UPDATE",
    "PLAYER_TARGET_CHANGED",
    "UPDATE_MOUSEOVER_UNIT",
    "PLAYER_SOFT_INTERACT_CHANGED",
}

function QC:Init()
    if type(C_Timer) == "table" and type(C_Timer.NewTicker) == "function" then
        self._ticker = C_Timer.NewTicker(0.25, function() QC:Refresh() end)
        return
    end
    if type(CreateFrame) ~= "function" then return end
    local pulse = CreateFrame("Frame")
    pulse:SetScript("OnUpdate", function(_, elapsed)
        QC._acc = (QC._acc or 0) + (elapsed or 0)
        if QC._acc < 0.25 then return end
        QC._acc = 0
        QC:Refresh()
    end)
    self._pulse = pulse
end
