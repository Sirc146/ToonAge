-- ToonAge/Modules/QuestTracker.lua (Classic — MoP 50504)
-- Floating tracker window showing the current guide step with live objectives.
--
-- MoP Classic API adaptations:
--   - GetNumQuestLogEntries / GetQuestLogTitle for quest log scanning
--   - SelectQuestLogEntry / GetNumQuestLeaderBoards / GetQuestLogLeaderBoard for objectives
--   - IsQuestComplete / IsQuestFlaggedCompleted for completion checks
--   - No C_QuestLog namespace used as primary (may partially exist)
--   - No C_SuperTrack integration
--   - UIDropDownMenu for context menus (via GuideContextMenu module)
--
-- Keeps: tracker window, step display, auto-quest, fast-forward sync, guide auto-select

local TA = ToonAge
local U  = TA.Utils

local QT = {}
TA:RegisterModule("QuestTracker", QT)

QT.window        = nil
QT.optionsFrame  = nil
QT.guideID       = nil
QT.stepIdx       = 1
QT.statusThrottle = 0
QT.stickySteps   = {}
QT.skippedSteps  = {}
local STATUS_UPDATE_HZ = 0.2

-- Debounce timer for quest log events
local logSyncTimer = nil
local LOG_SYNC_DELAY = 0.15

-- ══════════════════════════════════════════════════════════════════════════════
-- QUEST STATE HELPERS (MoP Classic APIs)
-- ══════════════════════════════════════════════════════════════════════════════

--- Find the quest log index for a given questID by scanning the log.
--- In MoP Classic, GetQuestLogTitle returns questID as the 8th return value.
local function GetLogIndexForQuestID(questID)
    if not questID then return nil end
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries do
        local _, _, _, isHeader, _, _, _, qID = GetQuestLogTitle(i)
        if not isHeader and qID == questID then
            return i
        end
    end
    return nil
end

--- Check if a quest is flagged as completed (ever turned in on this character).
local function IsQuestDone(questID)
    if not questID then return false end
    -- IsQuestFlaggedCompleted exists in MoP Classic
    if IsQuestFlaggedCompleted then
        return IsQuestFlaggedCompleted(questID) == true
            or IsQuestFlaggedCompleted(questID) == 1
    end
    return false
end

--- Check if a quest is currently in the quest log.
local function IsInLog(questID)
    return GetLogIndexForQuestID(questID) ~= nil
end

--- Check if a quest in the log is ready for turn-in.
local function IsReadyForTurnIn(questID)
    if not questID then return false end
    local idx = GetLogIndexForQuestID(questID)
    if not idx then return false end
    SelectQuestLogEntry(idx)
    -- In MoP, GetQuestLogTitle's 7th return (isComplete) indicates turn-in ready
    local _, _, _, _, _, isComplete = GetQuestLogTitle(idx)
    if isComplete and isComplete ~= 0 then return true end
    -- Fallback: IsQuestComplete may exist
    if IsQuestComplete and IsQuestComplete(questID) then return true end
    return false
end

function QT:GetQuestStatus(questID)
    if not questID then return "available" end
    if IsQuestDone(questID)       then return "complete"   end
    if IsReadyForTurnIn(questID)  then return "turnin"     end
    if IsInLog(questID)           then return "inprogress" end
    return "available"
end

--- Get objective text for a quest using classic APIs.
--- Returns { {text=string, finished=boolean}, ... }
local function GetQuestObjectives(questID)
    local idx = GetLogIndexForQuestID(questID)
    if not idx then return nil end
    SelectQuestLogEntry(idx)
    local numObjectives = GetNumQuestLeaderBoards(idx)
    if not numObjectives or numObjectives == 0 then return nil end

    local objectives = {}
    for i = 1, numObjectives do
        local text, objType, finished = GetQuestLogLeaderBoard(i, idx)
        table.insert(objectives, {
            text = text or "",
            type = objType,
            finished = (finished == 1 or finished == true),
        })
    end
    return objectives
end

--- Check if a specific quest objective is finished.
local function IsObjectiveFinished(questID, objectiveIndex)
    if not questID or not objectiveIndex then return false end
    local objectives = GetQuestObjectives(questID)
    if not objectives then return false end
    local obj = objectives[objectiveIndex]
    return obj and obj.finished == true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STEP EVALUATION
-- ══════════════════════════════════════════════════════════════════════════════

function QT:IsStepApplicable(step)
    local GP = TA:GetModule("GuideParser")
    if GP and GP.IsStepApplicable then
        return GP:IsStepApplicable(step)
    end
    -- Fallback
    if step.class then
        local _, pClass = UnitClass("player")
        if pClass ~= step.class then return false end
    end
    if step.minLevel then
        local lvl = UnitLevel("player") or 1
        if lvl < step.minLevel then return false end
    end
    return true
end

function QT:IsStepComplete(step)
    if not self:IsStepApplicable(step) then return true end
    if step.type == "text"             then return true end
    if step._manualDone                then return true end

    local sType = step.type or "quest"

    if sType == "pickup" or sType == "accept" then
        if step.questID then
            return IsInLog(step.questID) or IsQuestDone(step.questID)
        end
        return false
    end

    if sType == "turnin" then
        if step.questID then return IsQuestDone(step.questID) end
        return false
    end

    if sType == "objective" then
        if step.questID and step.objectiveIndex then
            return IsObjectiveFinished(step.questID, step.objectiveIndex)
                or IsQuestDone(step.questID)
        end
        return false
    end

    if sType == "waypoint" then
        if IsFlying and IsFlying() then return true end
        if UnitOnTaxi and UnitOnTaxi("player") then return true end
        return false
    end

    if sType == "quest" then
        if step.questID then
            if IsQuestDone(step.questID) then return true end
            local text = (step.text or ""):lower()
            local isAcceptStep = text:match("^accept")
                              or text:match("^speak")
                              or text:match("^talk")
            if isAcceptStep and IsInLog(step.questID) then return true end
        end
        return false
    end

    if sType == "travel" then return false end

    if sType == "flyto" then
        if step.coord and step.coord.map and step.coord.map ~= 0 then
            local currentMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if currentMap then return currentMap == step.coord.map end
        end
        return false
    end

    return false
end

-- ── Prerequisite / rank / filter helpers ──────────────────────────────

function QT:IsPrerequisiteMet(step)
    if not step.pre and not step.preOr then return true end
    if step.pre then
        local pre = type(step.pre) == "table" and step.pre or { step.pre }
        for _, qid in ipairs(pre) do
            if not IsQuestDone(qid) then return false end
        end
    end
    if step.preOr then
        local anyDone = false
        for _, qid in ipairs(step.preOr) do
            if IsQuestDone(qid) then anyDone = true; break end
        end
        if not anyDone then return false end
    end
    return true
end

function QT:PassesRankFilter(step)
    if not step.rank then return true end
    local playerRank = (TA.charDB and TA.charDB.tracker and TA.charDB.tracker.rank) or 2
    if step.rank > 0 then
        return playerRank >= step.rank
    else
        return playerRank == math.abs(step.rank)
    end
end

function QT:IsActiveConditionMet(step)
    if not step.active then return true end
    return IsInLog(step.active)
end

function QT:ShouldShowStep(step, stepIdx)
    if self.skippedSteps[stepIdx] then return false end
    if not self:IsStepApplicable(step) then return false end
    if not self:IsPrerequisiteMet(step) then return false end
    if not self:PassesRankFilter(step) then return false end
    if not self:IsActiveConditionMet(step) then return false end
    return true
end

function QT:SetSticky(stepIdx)
    for _, idx in ipairs(self.stickySteps) do
        if idx == stepIdx then return end
    end
    table.insert(self.stickySteps, stepIdx)
end

function QT:RemoveSticky(stepIdx)
    for i, idx in ipairs(self.stickySteps) do
        if idx == stepIdx then
            table.remove(self.stickySteps, i)
            return
        end
    end
end

function QT:SkipStep(stepIdx)
    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    if not guide then return end
    self.skippedSteps[stepIdx] = true
    local skippedQID = guide.steps[stepIdx] and guide.steps[stepIdx].questID
    if skippedQID then
        for i = stepIdx + 1, #guide.steps do
            local s = guide.steps[i]
            if s and s.pre then
                local preList = type(s.pre) == "table" and s.pre or { s.pre }
                for _, pqid in ipairs(preList) do
                    if pqid == skippedQID then
                        self.skippedSteps[i] = true
                        break
                    end
                end
            end
        end
    end
end


-- ══════════════════════════════════════════════════════════════════════════════
-- FAST FORWARD
-- ══════════════════════════════════════════════════════════════════════════════

function QT:FastForward(silent)
    if not self.guideID then return end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return end

    -- Pass 1: find last genuinely complete step
    local lastDoneIdx = 0
    for i = 1, #guide.steps do
        local step = guide.steps[i]
        if not self:ShouldShowStep(step, i) then
            -- invisible
        elseif step.questID then
            if IsQuestDone(step.questID) then
                lastDoneIdx = i
            end
        elseif step.type == "text" then
            lastDoneIdx = i
        elseif step._manualDone then
            lastDoneIdx = i
        end
    end

    -- Pass 2: find first incomplete step after anchor
    local startIdx = lastDoneIdx + 1
    for i = startIdx, #guide.steps do
        local step = guide.steps[i]
        if not self:ShouldShowStep(step, i) then
            -- filtered, skip
        elseif not self:IsStepComplete(step) then
            self.stepIdx = i
            self:SaveState()
            self:UpdateWindow()
            if not silent then
                self:ShowToast("Step " .. self.stepIdx .. " / " .. #guide.steps)
            end
            return
        end
    end

    -- All steps complete
    self.stepIdx = math.max(1, #guide.steps)
    self:SaveState()
    self:UpdateWindow()

    -- Route chaining
    if #guide.steps > 0 and guide.nextGuide and TA.Guides[guide.nextGuide] then
        local GP = TA:GetModule("GuideParser")
        local nextGuide = TA.Guides[guide.nextGuide]
        if not GP or GP:IsGuideApplicable(nextGuide) then
            if not silent then
                self:ShowToast("Guide complete! Next: " .. (nextGuide.title or guide.nextGuide))
            end
            self.guideID = guide.nextGuide
            self.stepIdx = 1
            self:FastForward(silent)
            return
        end
    end

    if not silent then
        self:ShowToast("Guide complete!")
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUIDE MANAGEMENT
-- ══════════════════════════════════════════════════════════════════════════════

function QT:GetSortedGuideList()
    local list = {}
    for id, g in pairs(TA.Guides or {}) do
        table.insert(list, { id = id, title = g.title, minLevel = g.minLevel or 1 })
    end
    table.sort(list, function(a, b)
        return a.minLevel < b.minLevel or (a.minLevel == b.minLevel and a.id < b.id)
    end)
    return list
end

function QT:SetGuide(guideID)
    local guide = TA.Guides and TA.Guides[guideID]
    if not guide then return end
    self.guideID = guideID
    self.stepIdx = 1
    self:FastForward(true)
    self:SaveState()
    self:UpdateWindow()
    if self.window and not self.window:IsVisible() then
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
    end
end

function QT:SmartMatchGuideFromLog()
    if not TA.Guides then return false end
    local numEntries = GetNumQuestLogEntries()
    if numEntries == 0 then return false end

    local activeIDs = {}
    for i = 1, numEntries do
        local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
        if not isHeader and questID and questID > 0 then
            activeIDs[questID] = true
        end
    end

    local bestID, bestCount = nil, 0
    for id, guide in pairs(TA.Guides) do
        local count = 0
        for _, step in ipairs(guide.steps) do
            if step.questID and activeIDs[step.questID] then count = count + 1 end
        end
        if count > bestCount then bestCount = count; bestID = id end
    end

    if bestID and bestCount >= 2 then
        self:SetGuide(bestID)
        return true
    end

    if bestID and bestCount == 1 then
        local ambiguous = false
        for id, guide in pairs(TA.Guides) do
            if id ~= bestID then
                for _, step in ipairs(guide.steps) do
                    if step.questID and activeIDs[step.questID] then
                        ambiguous = true; break
                    end
                end
            end
            if ambiguous then break end
        end
        if not ambiguous then
            self:SetGuide(bestID)
            return true
        end
    end

    return false
end

function QT:AutoSelectGuide()
    if self:SmartMatchGuideFromLog() then return end

    local level = UnitLevel("player") or 1
    local list  = self:GetSortedGuideList()

    -- Level match — pick the best level-range fit
    local bestLevelID, bestLevelDiff = nil, math.huge
    for _, entry in ipairs(list) do
        local g = TA.Guides[entry.id]
        local gMin = g.minLevel or 1
        local gMax = g.maxLevel or 999
        if level >= gMin and level <= gMax then
            local mid  = (gMin + gMax) / 2
            local diff = math.abs(level - mid)
            if diff < bestLevelDiff then
                bestLevelDiff = diff
                bestLevelID   = entry.id
            end
        end
    end
    if bestLevelID then
        self:SetGuide(bestLevelID)
        return
    end

    -- Fallback: first guide
    if #list > 0 then
        self:SetGuide(list[1].id)
        return
    end

    self.guideID = nil
    self.stepIdx = 1
end

function QT:CycleGuide(dir)
    local list = self:GetSortedGuideList()
    if #list == 0 then return end
    local cur = 1
    for i, entry in ipairs(list) do
        if entry.id == self.guideID then cur = i; break end
    end
    cur = ((cur - 1 + dir + #list) % #list) + 1
    self:SetGuide(list[cur].id)
end

function QT:SaveState()
    if not TA.charDB then return end
    TA.charDB.tracker = TA.charDB.tracker or {}
    TA.charDB.tracker.guideID = self.guideID
    TA.charDB.tracker.stepIdx = self.stepIdx
end

-- ══════════════════════════════════════════════════════════════════════════════
-- AUTO-QUEST ENGINE
-- ══════════════════════════════════════════════════════════════════════════════

function QT:HandleAutoQuest(event)
    if not (TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest) then return end
    if IsShiftKeyDown() then return end

    if event == "QUEST_DETAIL" then
        AcceptQuest()
        if QuestFrame and QuestFrame:IsShown() then
            HideUIPanel(QuestFrame)
        end

    elseif event == "QUEST_PROGRESS" then
        if IsQuestCompletable() then CompleteQuest() end

    elseif event == "QUEST_COMPLETE" then
        local numChoices = GetNumQuestChoices()
        if numChoices <= 1 then
            GetQuestReward(numChoices == 1 and 1 or nil)
            return
        end
        -- Multiple choices: pick highest ilvl
        local bestIdx, bestIlvl = 1, 0
        for i = 1, numChoices do
            local link = GetQuestItemLink("choice", i)
            if link then
                local _, _, _, ilvl = GetItemInfo(link)
                ilvl = ilvl or 0
                if ilvl > bestIlvl then
                    bestIlvl = ilvl
                    bestIdx = i
                end
            end
        end
        GetQuestReward(bestIdx)

    elseif event == "QUEST_GREETING" then
        -- Try to turn in completed quests first
        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            if isComplete then
                SelectActiveQuest(i)
                return
            end
        end
        if GetNumAvailableQuests() > 0 then
            SelectAvailableQuest(1)
        end
    end
end


-- ══════════════════════════════════════════════════════════════════════════════
-- BLIZZARD TRACKER VISIBILITY
-- ══════════════════════════════════════════════════════════════════════════════

function QT:UpdateBlizzardTrackerVisibility()
    if not (TA.charDB and TA.charDB.tracker) then return end
    local shouldHide = TA.charDB.tracker.replaceBlizzTracker
                    and self.window and self.window:IsVisible()
    -- MoP Classic uses WatchFrame (not ObjectiveTrackerFrame)
    if WatchFrame then
        if shouldHide then WatchFrame:Hide() else WatchFrame:Show() end
    elseif ObjectiveTrackerFrame then
        if shouldHide then ObjectiveTrackerFrame:Hide() else ObjectiveTrackerFrame:Show() end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ══════════════════════════════════════════════════════════════════════════════

function QT:OnEvent(event, ...)
    if event == "QUEST_DETAIL"   or event == "QUEST_PROGRESS"
    or event == "QUEST_COMPLETE" or event == "QUEST_GREETING" then
        self:HandleAutoQuest(event)
        return
    end

    if event == "QUEST_ACCEPTED"       or event == "QUEST_TURNED_IN"
    or event == "QUEST_LOG_UPDATE"     or event == "UNIT_QUEST_LOG_CHANGED" then
        if not self.guideID then return end
        if logSyncTimer then return end
        logSyncTimer = C_Timer.After(LOG_SYNC_DELAY, function()
            logSyncTimer = nil
            if QT.guideID then QT:FastForward(true) end
        end)

    elseif event == "PLAYER_LEVEL_UP" then
        self:UpdateWindow()
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════════════════════════════════════════

function QT:Init()
    TA.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    TA.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    TA.eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    TA.eventFrame:RegisterEvent("QUEST_DETAIL")
    TA.eventFrame:RegisterEvent("QUEST_PROGRESS")
    TA.eventFrame:RegisterEvent("QUEST_COMPLETE")
    TA.eventFrame:RegisterEvent("QUEST_GREETING")

    -- Init saved settings
    TA.charDB.tracker = TA.charDB.tracker or {}
    local t = TA.charDB.tracker
    if t.autoQuest           == nil then t.autoQuest           = false end
    if t.replaceBlizzTracker == nil then t.replaceBlizzTracker = false end
    if t.rank                == nil then t.rank                = 2     end

    -- Restore guide
    if t.guideID and TA.Guides and TA.Guides[t.guideID] then
        self.guideID = t.guideID
        self.stepIdx = t.stepIdx or 1
        self:FastForward(true)
    else
        self:AutoSelectGuide()
    end

    self:InitWindow()

    -- Show tracker if guide is active
    if self.guideID then
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
        self:UpdateBlizzardTrackerVisibility()
    elseif t.visible then
        self.window:Show()
        self:UpdateBlizzardTrackerVisibility()
    else
        self.window:Show()
        if TA.charDB then TA.charDB.tracker.visible = true end
    end
end


-- ══════════════════════════════════════════════════════════════════════════════
-- WINDOW LAYOUT
-- ══════════════════════════════════════════════════════════════════════════════

local W, H = 310, 230
local PAD  = 8

local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 2,
}

local function ApplyBD(f, br, bg, bb, ba, er, eg, eb)
    f:SetBackdrop(BD)
    f:SetBackdropColor(br, bg, bb, ba or 0.96)
    f:SetBackdropBorderColor(er or 0.55, eg or 0.40, eb or 0.08, 0.85)
end

local function Divider(parent, yOfs)
    local d = parent:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.55, 0.40, 0.08, 0.50)
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD, yOfs)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, yOfs)
end

local function MakeBtn(parent, w, h, label, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    ApplyBD(btn, 0.18, 0.13, 0.01, 0.90, 0.55, 0.40, 0.08)
    btn:EnableMouse(true)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    lbl:SetText(label)
    lbl:SetTextColor(1.00, 0.82, 0.00, 1.00)
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    btn:SetScript("OnClick",  onClick)
    btn:SetScript("OnEnter",  function(f) f:SetBackdropColor(0.30, 0.22, 0.03, 0.95) end)
    btn:SetScript("OnLeave",  function(f) f:SetBackdropColor(0.18, 0.13, 0.01, 0.90) end)
    btn._lbl = lbl
    return btn
end

local BADGE = {
    quest     = "|cFFFFD100", travel    = "|cFF1EBCFF", npc       = "|cFF78FF78",
    item      = "|cFFBB99FF", action    = "|cFFFF8833", text      = "|cFF999999",
    accept    = "|cFF4AFF7A", pickup    = "|cFF4AFF7A", turnin    = "|cFFFFD100",
    objective = "|cFFFFAA33", waypoint  = "|cFF1EBCFF", flyto     = "|cFF55CCFF",
    sethearth = "|cFFCC66FF",
}

local QUEST_STATUS = {
    complete   = "|cFF1EFF00[Complete]|r",
    turnin     = "|cFFFFD100[Ready to Turn In]|r",
    inprogress = "|cFF888780[In Progress]|r",
    available  = "|cFFAAAAAA[Not Started]|r",
}

function QT:InitWindow()
    local win = CreateFrame("Frame", "TATrackerWindow", UIParent, "BackdropTemplate")
    win:SetSize(W, H)
    win:SetFrameStrata("HIGH")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetClampedToScreen(true)
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if TA.charDB then
            TA.charDB.tracker.x = f:GetLeft()
            TA.charDB.tracker.y = f:GetTop()
        end
    end)

    -- Right-click for context menu
    win:SetScript("OnMouseUp", function(f, button)
        if button == "RightButton" then
            local GCM = TA:GetModule("GuideContextMenu")
            if GCM and GCM.ShowTrackerMenu then
                GCM:ShowTrackerMenu(f)
            end
        end
    end)

    ApplyBD(win, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)

    local saved = TA.charDB and TA.charDB.tracker
    if saved and saved.x and saved.y then
        win:ClearAllPoints()
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    win:Hide()

    -- ── Title bar ────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, win, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(28)
    ApplyBD(titleBar, 0.18, 0.13, 0.01, 1.00, 0.55, 0.40, 0.08)

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    titleLabel:SetText("|cFFEBE8DEToonAge|r")
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)

    local xBtn = MakeBtn(titleBar, 22, 22, "x", function() self:ToggleWindow() end)
    xBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    xBtn._lbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    xBtn._lbl:SetTextColor(0.85, 0.30, 0.15, 1)

    -- ── Guide navigation row ─────────────────────────────────────────
    local prevBtn = MakeBtn(win, 24, 20, "<", function() self:CycleGuide(-1) end)
    prevBtn:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -34)

    local nextBtn = MakeBtn(win, 24, 20, ">", function() self:CycleGuide(1) end)
    nextBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -34)

    win.guideTitleF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.guideTitleF:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    win.guideTitleF:SetTextColor(1.00, 0.95, 0.75, 1)
    win.guideTitleF:SetPoint("LEFT",  prevBtn, "RIGHT", 4, 0)
    win.guideTitleF:SetPoint("RIGHT", nextBtn, "LEFT", -4, 0)
    win.guideTitleF:SetJustifyH("CENTER")

    -- ── Step area ────────────────────────────────────────────────────
    Divider(win, -58)

    win.stepNumF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepNumF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepNumF:SetTextColor(0.70, 0.55, 0.25, 1)
    win.stepNumF:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -64)

    win.stepBadgeF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepBadgeF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepBadgeF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -64)

    win.stepTextF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepTextF:SetFont(STANDARD_TEXT_FONT, 11, "")
    win.stepTextF:SetTextColor(0.92, 0.92, 0.88, 1)
    win.stepTextF:SetPoint("TOPLEFT",  win, "TOPLEFT",  PAD,  -80)
    win.stepTextF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -80)
    win.stepTextF:SetHeight(65)
    win.stepTextF:SetJustifyH("LEFT")
    win.stepTextF:SetWordWrap(true)

    -- ── Quest status area ────────────────────────────────────────────
    Divider(win, -150)

    win.questStatusF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.questStatusF:SetFont(STANDARD_TEXT_FONT, 10, "")
    win.questStatusF:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, 38)
    win.questStatusF:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, 38)
    win.questStatusF:SetJustifyH("LEFT")

    -- ── Bottom buttons ───────────────────────────────────────────────
    local backBtn = MakeBtn(win, 60, 22, "< Back", function()
        if not self.guideID then return end
        self.stepIdx = math.max(1, self.stepIdx - 1)
        self:SaveState()
        self:UpdateWindow()
    end)
    backBtn:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, PAD)

    win.doneBtn = MakeBtn(win, 108, 22, "Mark Done >", function()
        if not self.guideID then return end
        local guide = TA.Guides and TA.Guides[self.guideID]
        if not guide then return end
        local step = guide.steps[self.stepIdx]
        if step then step._manualDone = true end
        for i = self.stepIdx, #guide.steps do
            if not self:IsStepComplete(guide.steps[i]) then
                self.stepIdx = i; break
            end
        end
        self:SaveState()
        self:UpdateWindow()
    end)
    win.doneBtn:SetPoint("BOTTOM", win, "BOTTOM", 0, PAD)

    local ffwdBtn = MakeBtn(win, 60, 22, ">> Sync", function()
        self:FastForward()
    end)
    ffwdBtn:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, PAD)

    -- OnUpdate for proximity checks
    win:SetScript("OnUpdate", function(_, elapsed)
        self.statusThrottle = self.statusThrottle + elapsed
        if self.statusThrottle < STATUS_UPDATE_HZ then return end
        self.statusThrottle = 0
        self:CheckProximityAdvance()
    end)

    self.window = win
    self:UpdateWindow()
end
