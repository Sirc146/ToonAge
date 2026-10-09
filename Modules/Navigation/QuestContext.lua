-- ToonAge/Modules/Navigation/QuestContext.lua
-- Offers the current guide step's quest item to the shared context button.
--
-- GetQuestLogSpecialItemInfo is checked first. When that global is missing,
-- C_QuestLog.GetQuestLogSpecialItemInfo is the same lookup. When neither
-- returns an item, the item id on the guide step is the fallback.
-- The button shows only while the player is near that objective or targeting it.
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

function QC.CurrentStep()
    local QT = TA.GetModule and TA:GetModule("QuestTracker")
    if not QT then return nil end
    if type(QT.View) == "function" then
        local _, steps, idx = QT:View()
        if steps and idx then return steps[idx] end
    end
    local guide = QT.guideID and TA.Guides and TA.Guides[QT.guideID]
    local steps = guide and guide.steps
    if not steps then return nil end
    return steps[QT.stepIdx or 1]
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
    if type(step) ~= "table" then
        CA:Set("quest item", nil)
        return
    end
    local logIndex = QC.LogIndex(step.questID)
    local special = QC.ReadSpecial(logIndex)
    local cand = CA.QuestCandidate({
        special = special,
        fallbackID = step.questItem,
        fallbackCount = QC.Count(step.questItem),
        near = QC.IsNear(step, logIndex),
        targeting = QC.IsTargeting(step, logIndex),
    })
    if cand then
        local id = (special and special.itemID) or step.questItem
        local start, duration = QC.ItemCooldown(id)
        if start then cand.cooldown = { start = start, duration = duration } end
    end
    CA:Set("quest item", cand)
end

function QC:OnEvent(event)
    if event == "QUEST_LOG_UPDATE" or event == "PLAYER_TARGET_CHANGED" then
        self:Refresh()
    end
end

QC.Events = { "QUEST_LOG_UPDATE", "PLAYER_TARGET_CHANGED" }

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
