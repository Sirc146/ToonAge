-- ToonAge/Modules/QuestTracker.lua
-- Floating tracker window showing the current guide step with live objectives.
--
-- Features:
--   Live Objectives   — injects real C_QuestLog objective text into the step display
--   FFWD Catch-up     — backward+forward sync against the quest log on every log change
--   Smart Phrase Parse— accept/speak/talk steps auto-complete when the quest enters the log
--   Auto-Quest Engine — opt-in auto-accept and auto-turn-in (hold Shift to pause any step)
--   Blizzard Replace  — optionally hides the default Objective Tracker while active
--   Arrow Integration — live distance/ETA from Arrow.lua displayed inline in the status bar

local TA = ToonAge
local U  = TA.Utils

local QT = {}
TA:RegisterModule("QuestTracker", QT)

QT.window        = nil
QT.optionsFrame  = nil
QT.guideID       = nil
QT.stepIdx       = 1
QT.statusThrottle = 0
local STATUS_UPDATE_HZ = 0.2   -- distance/ETA refresh rate, matches Arrow's own tick budget

-- Debounce timer for high-frequency quest log events.
-- QUEST_LOG_UPDATE and UNIT_QUEST_LOG_CHANGED can fire 10-20 times in a single
-- turn-in or loot sequence. FastForward() scans every guide step backward then
-- forward — doing that 20 times in one frame wastes CPU and violates the
-- Blizzard "no negative impact on realm performance" policy rule.
-- We coalesce all log-change firings within a 0.15s window into one sync.
local logSyncTimer = nil
local LOG_SYNC_DELAY = 0.15

-- ── Quest state helpers ───────────────────────────────────────────────────────

local function IsComplete(questID)
    if not questID then return false end
    return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
end

local function IsInLog(questID)
    if not questID then return false end
    return C_QuestLog.GetLogIndexForQuestID(questID) ~= nil
end

local function IsReadyForTurnIn(questID)
    if not questID then return false end
    if C_QuestLog.ReadyForTurnIn then
        return C_QuestLog.ReadyForTurnIn(questID) == true
    end
    local idx = C_QuestLog.GetLogIndexForQuestID(questID)
    if not idx then return false end
    local info = C_QuestLog.GetInfo(idx)
    return info ~= nil and info.isComplete == true
end

function QT:GetQuestStatus(questID)
    if not questID then return "available" end
    if IsComplete(questID)       then return "complete"   end
    if IsReadyForTurnIn(questID) then return "turnin"     end
    if IsInLog(questID)          then return "inprogress" end
    return "available"
end

-- ── Step evaluation & Smart Phrase Parsing ────────────────────────────────────

function QT:IsStepApplicable(step)
    if step.class then
        local _, pClass = UnitClass("player")
        if pClass ~= step.class then return false end
    end
    if step.spec then
        local specID = GetSpecializationInfo(GetSpecialization())
        if specID ~= step.spec then return false end
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

    if step.questID then
        if IsComplete(step.questID) then return true end

        -- Smart Phrase Parsing: "accept/speak/talk" steps finish the moment
        -- the quest appears in the log — no need to wait for turn-in.
        local text = (step.text or ""):lower()
        local isAcceptStep = step.type == "accept"
                          or text:match("^accept")
                          or text:match("^speak")
                          or text:match("^talk")
        if isAcceptStep and IsInLog(step.questID) then return true end
    end

    return false
end

-- ── Fast Forward ─────────────────────────────────────────────────────────────
-- Scans the entire guide against the quest log and quest-completion flags to
-- find the first step that isn't done yet.
--
-- Two-pass strategy:
--   Pass 1 — walk every step and find the LAST step that is fully complete
--             (IsQuestFlaggedCompleted). This is the true progress anchor.
--             IsInLog alone is NOT used as an anchor — a quest being in-progress
--             means the player is ON that step, not past it.
--   Pass 2 — from the step after the last-complete anchor, find the first step
--             that IsStepComplete() returns false for. That's where we land.
--
-- If no completed quest is found at all (fresh guide), Pass 2 starts from
-- step 1 and lands on the first applicable incomplete step.

function QT:FastForward(silent)
    if not self.guideID then return end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return end

    -- Pass 1: find the index of the last step that is fully complete.
    -- We walk forward (not backward) so we get the highest index whose quest
    -- is flagged done, giving the most accurate progress anchor.
    local lastDoneIdx = 0
    for i = 1, #guide.steps do
        if self:IsStepComplete(guide.steps[i]) then
            lastDoneIdx = i
        end
    end

    -- Pass 2: starting from the step after the anchor, find the first
    -- incomplete step. If everything is done, land on the last step.
    local startIdx = lastDoneIdx + 1
    for i = startIdx, #guide.steps do
        if not self:IsStepComplete(guide.steps[i]) then
            self.stepIdx = i
            self:SaveState()
            self:UpdateWindow()
            if not silent then
                print("|cFF4AFF7A[TA Tracker]|r Synced to step " .. i
                    .. " / " .. #guide.steps .. ".")
            end
            return
        end
    end

    -- All steps complete (or guide has no quest steps at all)
    self.stepIdx = #guide.steps
    self:SaveState()
    self:UpdateWindow()
    if not silent then
        print("|cFF4AFF7A[TA Tracker]|r Guide appears complete.")
    end
end

-- ── Guide management ──────────────────────────────────────────────────────────

-- Walk map hierarchy so a sub-zone player map still matches the guide's parent zone.
local function MapIsInZone(playerMapID, guideZone)
    if not guideZone or guideZone == 0 then return false end
    if playerMapID == guideZone then return true end
    local info = C_Map.GetMapInfo(playerMapID)
    while info and info.parentMapID and info.parentMapID > 0 do
        if info.parentMapID == guideZone then return true end
        info = C_Map.GetMapInfo(info.parentMapID)
    end
    return false
end

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
    self:FastForward(true)   -- silently snap to the player's real position
    self:SaveState()
end

function QT:SmartMatchGuideFromLog()
    if not TA.Guides then return false end
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    if numEntries == 0 then return false end

    local activeIDs = {}
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            activeIDs[info.questID] = true
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

    -- Require at least 2 matching quests. A single match could be a quest that
    -- appears across multiple guides or a coincidental questID overlap — not
    -- strong enough signal to commit the player to a specific guide.
    if bestID and bestCount >= 2 then
        self:SetGuide(bestID)
        return true
    end

    -- Single match: accept it only if it's the ONLY guide with any match
    -- (unambiguous even at count=1).
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

    local level      = UnitLevel("player") or 1
    local currentMap = C_Map.GetBestMapForUnit("player")
    local list       = self:GetSortedGuideList()

    -- Pass 1: level + zone match (most specific)
    for _, entry in ipairs(list) do
        local g = TA.Guides[entry.id]
        local levelMatch = level >= (g.minLevel or 1) and level <= (g.maxLevel or 999)
        local zoneMatch  = currentMap and MapIsInZone(currentMap, g.zone)
        if levelMatch and zoneMatch then
            self:SetGuide(entry.id)
            return
        end
    end

    -- Pass 2: level match only — zone IDs on PTR guides are often placeholder
    -- map IDs (0 or wrong zone). If the zone doesn't match but the level does,
    -- pick the best level-range fit rather than leaving the player with nothing.
    local bestLevelID, bestLevelDiff = nil, math.huge
    for _, entry in ipairs(list) do
        local g = TA.Guides[entry.id]
        local gMin = g.minLevel or 1
        local gMax = g.maxLevel or 999
        if level >= gMin and level <= gMax then
            -- Prefer the guide whose midpoint is closest to the player's level
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

    self.guideID = nil
    self.stepIdx = 1
end

-- ── Tracker diagnostic ────────────────────────────────────────────────────────
-- Prints to chat exactly what AutoSelectGuide sees: player level, current map,
-- loaded guides, and how many active quest log entries each guide matches.
-- Run /ta diagnose or /ta diag when the tracker shows "No Active Guide".
function QT:Diagnose()
    local p = function(msg) print("|cFFFFD100[TA Tracker]|r " .. msg) end

    local level      = UnitLevel("player") or 1
    local currentMap = C_Map.GetBestMapForUnit("player")
    local mapInfo    = currentMap and C_Map.GetMapInfo(currentMap)
    local mapName    = mapInfo and mapInfo.name or "unknown"

    p(string.format("Player: level %d  |  map %s (ID %s)",
        level, mapName, tostring(currentMap)))

    -- Active quest log
    local activeIDs = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            activeIDs[info.questID] = true
        end
    end
    p(string.format("Quest log: %d active quest(s)", #(function() local t={} for k in pairs(activeIDs) do t[#t+1]=k end return t end)()))

    -- Loaded guides
    local guides = TA.Guides or {}
    local count  = 0
    for _ in pairs(guides) do count = count + 1 end
    if count == 0 then
        p("|cFFFF4444No guides loaded. Check GuideParser output at login for errors.|r")
        return
    end
    p(string.format("%d guide(s) loaded:", count))

    local list = self:GetSortedGuideList()
    for _, entry in ipairs(list) do
        local g          = TA.Guides[entry.id]
        local gMin       = g.minLevel or 1
        local gMax       = g.maxLevel or 999
        local levelMatch = level >= gMin and level <= gMax
        local zoneMatch  = currentMap and MapIsInZone(currentMap, g.zone)

        -- Count quest log matches
        local matches = 0
        for _, step in ipairs(g.steps) do
            if step.questID and activeIDs[step.questID] then matches = matches + 1 end
        end

        local flags = {}
        if levelMatch then flags[#flags+1] = "|cFF4AFF7Alevel✓|r"  else flags[#flags+1] = "|cFFFF4444level✗|r" end
        if zoneMatch  then flags[#flags+1] = "|cFF4AFF7Azone✓|r"   else flags[#flags+1] = "|cFF888780zone✗|r"  end
        if matches > 0 then flags[#flags+1] = string.format("|cFFFFD100%d quest match(es)|r", matches) end

        p(string.format("  [%s] '%s'  lvl %d-%d  zone=%d  %s",
            entry.id, g.title, gMin, gMax, g.zone or 0,
            table.concat(flags, "  ")))
    end

    if self.guideID then
        p("Active guide: '" .. (TA.Guides[self.guideID] and TA.Guides[self.guideID].title or self.guideID) .. "'  step " .. self.stepIdx)
    else
        p("|cFFFF8800No guide selected. Use /ta autoselect or < > arrows in the tracker.|r")
    end
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

-- ── Auto-Quest Engine ─────────────────────────────────────────────────────────
-- Guide-contextual helpers: extract the questID the current (and nearby) guide
-- steps are expecting so gossip selection can target them specifically rather
-- than blindly taking whatever NPC quest comes first.
local function GetGuideExpectedQuestIDs(self)
    if not self.guideID then return {} end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return {} end

    local ids = {}
    local startIdx = math.max(1, self.stepIdx - 1)
    local endIdx   = math.min(#guide.steps, self.stepIdx + 3)
    for i = startIdx, endIdx do
        local step = guide.steps[i]
        if step and step.questID then
            ids[step.questID] = true
        end
    end
    return ids
end

function QT:HandleAutoQuest(event)
    if not (TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest) then return end
    if IsShiftKeyDown() then return end

    if event == "QUEST_DETAIL" then
        -- Auto-accept the presented quest unconditionally.
        -- QUEST_DETAIL only fires when a specific quest's detail frame is already
        -- open, meaning the player or gossip engine has already selected it.
        AcceptQuest()
        HideUIPanel(QuestFrame)

    elseif event == "QUEST_PROGRESS" then
        if IsQuestCompletable() then CompleteQuest() end

    elseif event == "QUEST_COMPLETE" then
        -- Auto-select the best reward when there is only one choice.
        -- When there are multiple choices let the player decide (holding shift
        -- is irrelevant here — the whole point of multiple choices is player
        -- agency). The guide can add an 'action' step recommending which reward
        -- to pick if the route cares about a specific one.
        if GetNumQuestChoices() <= 1 then
            GetQuestReward(1)
        end

    elseif event == "GOSSIP_SHOW" then
        if not C_GossipInfo then return end
        local expectedIDs = GetGuideExpectedQuestIDs(self)

        -- Phase 1: check active (in-progress) quests — try to turn in guide quests first.
        local active = C_GossipInfo.GetActiveQuests()
        if active then
            -- Guide-matching turn-in: prefer a quest the current guide expects.
            for _, q in ipairs(active) do
                if q.isComplete and expectedIDs[q.questID] then
                    C_GossipInfo.SelectActiveQuest(q.questID)
                    return
                end
            end
            -- Fallback: any complete quest (non-guide NPC with a completable quest).
            for _, q in ipairs(active) do
                if q.isComplete then
                    C_GossipInfo.SelectActiveQuest(q.questID)
                    return
                end
            end
        end

        -- Phase 2: accept an available quest — guide-expected quests first.
        local available = C_GossipInfo.GetAvailableQuests()
        if available then
            -- Prefer a quest the guide is currently pointing at.
            for _, q in ipairs(available) do
                if expectedIDs[q.questID] then
                    C_GossipInfo.SelectAvailableQuest(q.questID)
                    return
                end
            end
            -- Fallback: first available quest (same as before, only reached when
            -- none of the available quests match the guide's lookahead window).
            if available[1] then
                C_GossipInfo.SelectAvailableQuest(available[1].questID)
            end
        end

    elseif event == "QUEST_GREETING" then
        -- Legacy multi-quest NPC frame (pre-Cataclysm gossip style, still used
        -- in some Exile's Reach scripted sequences).
        local expectedIDs = GetGuideExpectedQuestIDs(self)

        -- Phase 1: turn in guide-expected active quests.
        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            if isComplete then
                -- Try to match by quest ID if the API surface allows it.
                -- GetActiveTitle doesn't return questID directly; rely on the
                -- same order heuristic as the original for now, but still prefer
                -- any complete quest over an incomplete one.
                SelectActiveQuest(i)
                return
            end
        end
        -- Phase 2: accept first available.
        if GetNumAvailableQuests() > 0 then
            SelectAvailableQuest(1)
        end
    end
end

-- ── Blizzard tracker ─────────────────────────────────────────────────────────

function QT:UpdateBlizzardTrackerVisibility()
    if not (TA.charDB and TA.charDB.tracker) then return end
    local shouldHide = TA.charDB.tracker.replaceBlizzTracker
                    and self.window and self.window:IsVisible()
    if ObjectiveTrackerFrame then
        if shouldHide then ObjectiveTrackerFrame:Hide() else ObjectiveTrackerFrame:Show() end
    end
end

-- ── Events ────────────────────────────────────────────────────────────────────

function QT:OnEvent(event, ...)
    if event == "QUEST_DETAIL"   or event == "QUEST_PROGRESS"
    or event == "QUEST_COMPLETE" or event == "GOSSIP_SHOW"
    or event == "QUEST_GREETING" then
        self:HandleAutoQuest(event)
        return
    end

    if event == "QUEST_ACCEPTED"           or event == "QUEST_TURNED_IN"
    or event == "QUEST_LOG_UPDATE"         or event == "UNIT_QUEST_LOG_CHANGED"
    or event == "QUEST_WATCH_LIST_CHANGED" then
        if not self.guideID then return end
        -- QUEST_LOG_UPDATE and UNIT_QUEST_LOG_CHANGED fire repeatedly during
        -- a single turn-in/loot/zone-change sequence (often 10-20 times in one
        -- frame). Coalesce them into one FastForward via a 0.15s debounce so
        -- we do one guide-step scan per real event cluster, not one per firing.
        if logSyncTimer then return end
        logSyncTimer = C_Timer.After(LOG_SYNC_DELAY, function()
            logSyncTimer = nil
            if QT.guideID then QT:FastForward(true) end
        end)

    elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdateWindow()
    end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function QT:Init()
    -- QUEST_ACCEPTED is in Core/Init.lua PERSISTENT_EVENTS — no re-registration needed.
    TA.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    TA.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    TA.eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    TA.eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    TA.eventFrame:RegisterEvent("QUEST_DETAIL")
    TA.eventFrame:RegisterEvent("QUEST_PROGRESS")
    TA.eventFrame:RegisterEvent("QUEST_COMPLETE")
    TA.eventFrame:RegisterEvent("GOSSIP_SHOW")
    TA.eventFrame:RegisterEvent("QUEST_GREETING")

    -- Preserve existing saved settings; only apply defaults for missing keys
    TA.charDB.tracker = TA.charDB.tracker or {}
    local t = TA.charDB.tracker
    if t.autoQuest           == nil then t.autoQuest           = false end
    if t.replaceBlizzTracker == nil then t.replaceBlizzTracker = false end
    if t.cutsceneSkip        == nil then t.cutsceneSkip        = false end
    if t.autoEquip           == nil then t.autoEquip           = false end

    if t.guideID and TA.Guides and TA.Guides[t.guideID] then
        self.guideID = t.guideID
        self.stepIdx = t.stepIdx or 1
        self:FastForward(true)   -- re-sync on login in case progress happened offline
    else
        self:AutoSelectGuide()
    end

    self:InitWindow()

    if t.visible then
        self.window:Show()
        self:UpdateBlizzardTrackerVisibility()
    end
end

-- ── Window layout constants ───────────────────────────────────────────────────

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

local function MakeCheckbox(parent, x, y, label, dbKey, onChange)
    local cb = CreateFrame("Button", nil, parent, "BackdropTemplate")
    cb:SetSize(14, 14)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    ApplyBD(cb, 0.05, 0.05, 0.05, 1, 0.55, 0.40, 0.08)
    local chk = cb:CreateTexture(nil, "OVERLAY")
    chk:SetColorTexture(1, 0.82, 0, 1)
    chk:SetPoint("CENTER")
    chk:SetSize(8, 8)
    if TA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
    local lblStr = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblStr:SetFont(STANDARD_TEXT_FONT, 10, "")
    lblStr:SetText(label)
    lblStr:SetTextColor(0.88, 0.83, 0.65, 1)
    lblStr:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    cb:SetScript("OnClick", function()
        TA.charDB.tracker[dbKey] = not TA.charDB.tracker[dbKey]
        if TA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
        if onChange then onChange(TA.charDB.tracker[dbKey]) end
    end)
    return cb
end

local BADGE = {
    quest  = "|cFFFFD100", travel = "|cFF1EBCFF", npc    = "|cFF78FF78",
    item   = "|cFFBB99FF", action = "|cFFFF8833", text   = "|cFF999999",
    accept = "|cFF4AFF7A",  -- green — complete once the quest is in the log
}
local QUEST_STATUS = {
    complete   = "|cFF1EFF00[Complete]|r",
    turnin     = "|cFFFFD100[Ready to Turn In]|r",
    inprogress = "|cFF888780[In Progress]|r",
    available  = "|cFFAAAAAA[Not Started]|r",
}

-- ── InitWindow ────────────────────────────────────────────────────────────────

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
    ApplyBD(win, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)

    local saved = TA.charDB and TA.charDB.tracker
    if saved and saved.x and saved.y then
        win:ClearAllPoints()
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    win:Hide()

    -- ── Title bar ────────────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, win, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, 0)
    titleBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(28)
    ApplyBD(titleBar, 0.18, 0.13, 0.01, 1.00, 0.55, 0.40, 0.08)

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    titleLabel:SetText("|cFFFFD100CA Guide Tracker|r")
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)

    local xBtn = MakeBtn(titleBar, 22, 22, "x", function() self:ToggleWindow() end)
    xBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    xBtn._lbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    xBtn._lbl:SetTextColor(0.85, 0.30, 0.15, 1)

    -- "=" options button (Unicode gear glyphs don't render in STANDARD_TEXT_FONT)
    local optBtn = MakeBtn(titleBar, 22, 22, "=", function()
        if self.optionsFrame:IsShown() then self.optionsFrame:Hide()
        else self.optionsFrame:Show() end
    end)
    optBtn:SetPoint("RIGHT", xBtn, "LEFT", -3, 0)

    -- ── Options panel ────────────────────────────────────────────────────────
    local optPanel = CreateFrame("Frame", nil, win, "BackdropTemplate")
    optPanel:SetSize(W, 102)
    optPanel:SetFrameStrata("HIGH")
    optPanel:SetPoint("TOP", win, "BOTTOM", 0, -2)
    ApplyBD(optPanel, 0.04, 0.03, 0.01, 0.98, 0.55, 0.40, 0.08)
    optPanel:Hide()
    self.optionsFrame = optPanel

    -- Note: WoW setter methods return nil, so method chains like
    -- CreateFontString():SetFont():SetText() silently discard the string.
    -- Each call must be on a separate line.
    local optTitle = optPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optTitle:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    optTitle:SetText("TRACKER SETTINGS")
    optTitle:SetTextColor(0.55, 0.40, 0.08, 1)
    optTitle:SetPoint("TOPLEFT", optPanel, "TOPLEFT", PAD, -8)

    MakeCheckbox(optPanel, PAD, -24,
        "Hide default Blizzard Quest Tracker",
        "replaceBlizzTracker",
        function() self:UpdateBlizzardTrackerVisibility() end)

    MakeCheckbox(optPanel, PAD, -46,
        "Auto-accept & auto-turn-in quests  (hold Shift to pause)",
        "autoQuest", nil)

    MakeCheckbox(optPanel, PAD, -62,
        "Skip cutscenes automatically",
        "cutsceneSkip", nil)

    MakeCheckbox(optPanel, PAD, -78,
        "Auto-equip looted upgrades  (hold Shift to pause)",
        "autoEquip", nil)

    -- ── Guide navigation row ─────────────────────────────────────────────────
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

    -- ── Step area ────────────────────────────────────────────────────────────
    Divider(win, -58)

    win.stepNumF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepNumF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepNumF:SetTextColor(0.70, 0.55, 0.25, 1)
    win.stepNumF:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -64)

    win.stepBadgeF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepBadgeF:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    win.stepBadgeF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -64)

    -- Step text + injected objectives, capped above the second divider.
    -- SetHeight(65): -80 top + 65px = -145, five pixels before the -150 divider.
    win.stepTextF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.stepTextF:SetFont(STANDARD_TEXT_FONT, 11, "")
    win.stepTextF:SetTextColor(0.92, 0.92, 0.88, 1)
    win.stepTextF:SetPoint("TOPLEFT",  win, "TOPLEFT",  PAD,  -80)
    win.stepTextF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -80)
    win.stepTextF:SetHeight(65)
    win.stepTextF:SetJustifyH("LEFT")
    win.stepTextF:SetWordWrap(true)
    win.stepTextF:SetNonSpaceWrap(false)

    -- ── Quest status / objective area ─────────────────────────────────────────
    Divider(win, -150)

    -- Next-step preview: sits in the unused gap between the divider (-150)
    -- and questStatusF's occupied area (~-178 upward from its y=38 anchor).
    win.nextStepF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.nextStepF:SetFont(STANDARD_TEXT_FONT, 9, "")
    win.nextStepF:SetTextColor(0.52, 0.48, 0.34, 1)
    win.nextStepF:SetPoint("TOPLEFT",  win, "TOPLEFT",  PAD,  -156)
    win.nextStepF:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -156)
    win.nextStepF:SetJustifyH("LEFT")
    win.nextStepF:SetWordWrap(false)

    win.questStatusF = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.questStatusF:SetFont(STANDARD_TEXT_FONT, 10, "")
    win.questStatusF:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, 38)
    win.questStatusF:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, 38)
    win.questStatusF:SetJustifyH("LEFT")

    -- ── Bottom buttons ────────────────────────────────────────────────────────
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
        -- Signal the step advance: fade the new step text in rather than
        -- having it just snap into place.
        UIFrameFadeIn(win.stepTextF, 0.25, 0, 1)
    end)
    win.doneBtn:SetPoint("BOTTOM", win, "BOTTOM", 0, PAD)

    -- >> Sync: cross-references entire guide against quest log and snaps to position
    local ffwdBtn = MakeBtn(win, 60, 22, ">> Sync", function()
        self:FastForward()
    end)
    ffwdBtn:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, PAD)

    -- Throttled live distance/ETA refresh. WoW only fires OnUpdate while the
    -- frame is shown, so this naturally does nothing while the tracker is hidden.
    win:SetScript("OnUpdate", function(_, elapsed)
        self.statusThrottle = self.statusThrottle + elapsed
        if self.statusThrottle < STATUS_UPDATE_HZ then return end
        self.statusThrottle = 0
        self:RenderStatusLine()
        self:UpdateQuestItemButton()
        self:CheckProximityAdvance()
    end)

    -- ── Quest Item Button ─────────────────────────────────────────────────────
    -- A floating, click-to-use button that appears when the current guide step
    -- specifies a questItem (itemID).  Mirrors WoW-Pro's "quest item button"
    -- feature: the player clicks it instead of hunting for the item in bags.
    --
    -- The button is parented to UIParent (not the tracker window) so it can be
    -- independently positioned and remains visible even if the tracker is closed.
    -- Saved position: charDB.questItem.x / .y (TOPLEFT relative to BOTTOMLEFT).
    local qib = CreateFrame("Button", "TAQuestItemButton", UIParent, "BackdropTemplate")
    qib:SetSize(46, 46)
    qib:SetFrameStrata("HIGH")
    qib:SetMovable(true)
    qib:EnableMouse(true)
    qib:RegisterForDrag("LeftButton")
    qib:SetClampedToScreen(true)
    qib:SetScript("OnDragStart", qib.StartMoving)
    qib:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        TA.charDB.questItem = TA.charDB.questItem or {}
        TA.charDB.questItem.x = f:GetLeft()
        TA.charDB.questItem.y = f:GetTop()
    end)

    -- Restore saved position or default below the tracker.
    local qibSaved = TA.charDB and TA.charDB.questItem
    if qibSaved and qibSaved.x and qibSaved.y then
        qib:ClearAllPoints()
        qib:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", qibSaved.x, qibSaved.y)
    else
        qib:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    end

    ApplyBD(qib, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)

    local qibTex = qib:CreateTexture(nil, "ARTWORK")
    qibTex:SetPoint("TOPLEFT",  qib, "TOPLEFT",  3, -3)
    qibTex:SetPoint("BOTTOMRIGHT", qib, "BOTTOMRIGHT", -3, 3)
    qib.iconTex = qibTex

    -- Cooldown overlay (standard WoW cooldown swipe)
    local qibCD = CreateFrame("Cooldown", nil, qib, "CooldownFrameTemplate")
    qibCD:SetAllPoints(qibTex)
    qibCD:SetDrawEdge(true)
    qib.cooldownFrame = qibCD

    -- Count / stack text
    local qibCount = qib:CreateFontString(nil, "OVERLAY")
    qibCount:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    qibCount:SetTextColor(1, 1, 1, 1)
    qibCount:SetPoint("BOTTOMRIGHT", qib, "BOTTOMRIGHT", -3, 3)
    qibCount:SetJustifyH("RIGHT")
    qib.countF = qibCount

    qib:SetScript("OnEnter", function(f)
        if not f._itemID then return end
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(f._itemID)
        GameTooltip:Show()
    end)
    qib:SetScript("OnLeave", function() GameTooltip:Hide() end)

    qib:SetScript("OnClick", function(f, btn)
        if btn ~= "LeftButton" then return end
        if not f._itemID then return end
        -- Find the item in bags and use it
        for bag = 0, 4 do
            local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                       or GetContainerNumSlots(bag)
            for slot = 1, (slots or 0) do
                local itemID
                if C_Container and C_Container.GetContainerItemID then
                    itemID = C_Container.GetContainerItemID(bag, slot)
                else
                    itemID = GetContainerItemID(bag, slot)
                end
                if itemID == f._itemID then
                    if C_Container and C_Container.UseContainerItem then
                        C_Container.UseContainerItem(bag, slot)
                    else
                        UseContainerItem(bag, slot)
                    end
                    return
                end
            end
        end
    end)

    qib:Hide()
    win.questItemBtn = qib

    self.window = win
    self:UpdateWindow()
end

-- ── UpdateQuestItemButton ─────────────────────────────────────────────────────
-- Called on the OnUpdate throttle. Shows the quest-item button when the current
-- step has a questItem field AND that item exists in the player's bags.

function QT:UpdateQuestItemButton()
    local win = self.window
    if not (win and win.questItemBtn) then return end
    local qib = win.questItemBtn

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local step  = guide and guide.steps[self.stepIdx]
    local itemID = step and step.questItem

    if not itemID then
        qib:Hide()
        qib._itemID = nil
        return
    end

    -- Count how many we have in bags
    local count = 0
    for bag = 0, 4 do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                   or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local id
            if C_Container and C_Container.GetContainerItemID then
                id = C_Container.GetContainerItemID(bag, slot)
            else
                id = GetContainerItemID(bag, slot)
            end
            if id == itemID then
                if C_Container and C_Container.GetContainerItemInfo then
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    count = count + (info and info.stackCount or 1)
                else
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    count = count + (itemCount or 1)
                end
            end
        end
    end

    if count == 0 then
        qib:Hide()
        qib._itemID = nil
        return
    end

    qib._itemID = itemID

    -- Set icon from item cache (may require a server round-trip on first call)
    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if itemTexture then
        qib.iconTex:SetTexture(itemTexture)
    else
        qib.iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    qib.countF:SetText(count > 1 and tostring(count) or "")

    -- Cooldown sweep
    local start, duration = GetItemCooldown(itemID)
    if start and start > 0 then
        qib.cooldownFrame:SetCooldown(start, duration)
    else
        qib.cooldownFrame:SetCooldown(0, 0)
    end

    qib:Show()
end

-- ── UpdateWindow ──────────────────────────────────────────────────────────────

function QT:UpdateWindow()
    local win = self.window
    if not win then return end

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]

    if not guide then
        win.guideTitleF:SetText("|cFFFF8800No Active Guide|r")
        win.stepNumF:SetText("")
        win.stepBadgeF:SetText("")

        -- Show diagnostic context inline so the player knows what the tracker
        -- sees without having to open the console. This is the most common
        -- point of confusion when guides have placeholder zone IDs.
        local level   = UnitLevel("player") or 1
        local mapID   = C_Map.GetBestMapForUnit("player")
        local mapInfo = mapID and C_Map.GetMapInfo(mapID)
        local zone    = mapInfo and mapInfo.name or ("map " .. tostring(mapID))
        local loaded  = 0
        for _ in pairs(TA.Guides or {}) do loaded = loaded + 1 end

        local body
        if loaded == 0 then
            body = "|cFFFF4444No guides loaded.|r\n"
               .. "Check for GuideParser errors at login."
        else
            body = string.format(
                "|cFF888780Level %d  ·  %s|r\n"
              .. "%d guide(s) loaded — none matched your zone or level.\n\n"
              .. "Use |cFFFFD100< >|r to pick a guide manually, "
              .. "|cFFFFD100>> Sync|r after selecting, "
              .. "or |cFFFFD100/ta diag|r to see why matching failed.",
                level, zone, loaded)
        end

        win.stepTextF:SetText(body)
        win.questStatusF:SetText("")
        win.nextStepF:SetText("")
        win.doneBtn._lbl:SetText("Mark Done >")
        win.doneBtn:SetBackdropColor(0.10, 0.08, 0.01, 0.70)
        return
    end

    local total = #guide.steps
    self.stepIdx = math.max(1, math.min(total, self.stepIdx))
    local step = guide.steps[self.stepIdx]

    local titleStr = guide.title
    if #titleStr > 30 then titleStr = titleStr:sub(1, 27) .. "..." end
    win.guideTitleF:SetText(titleStr)
    win.stepNumF:SetText("Step " .. self.stepIdx .. " / " .. total)

    local sType = step.type or "text"
    self._badgeBase = (BADGE[sType] or "|cFFFFFFFF") .. "[" .. sType:upper() .. "]|r"
    win.stepBadgeF:SetText(self._badgeBase)

    if not self:IsStepApplicable(step) then
        win.stepTextF:SetText("|cFF888780(Not applicable to your spec/class — skipped)|r")
    else
        -- Fixed-height text region (see stepTextF setup in InitWindow): title,
        -- step prose, and the stub-coord hint always fit and always show.
        -- Live objectives are the one open-ended part (a quest can have 4-5
        -- sub-objectives), so they're the part we trim if the text overflows
        -- the box, rather than letting it spill into the divider below.
        local headLines = {}

        -- Line 1: live quest title from client (gold) if available
        if step.questID then
            local liveTitle = C_QuestLog.GetTitleForQuestID
                           and C_QuestLog.GetTitleForQuestID(step.questID)
            if liveTitle and liveTitle ~= "" then
                headLines[#headLines + 1] = "|cFFFFD100" .. liveTitle .. "|r"
            end
        end

        -- Line 2: guide step prose
        headLines[#headLines + 1] = step.text or ""

        -- Live objectives (injected when quest is in log)
        local objLines = {}
        if step.questID and IsInLog(step.questID) then
            local objectives = C_QuestLog.GetQuestObjectives
                            and C_QuestLog.GetQuestObjectives(step.questID)
            if objectives and #objectives > 0 then
                for _, obj in ipairs(objectives) do
                    local color = obj.finished and "|cFF888780" or "|cFFFFFFFF"
                    objLines[#objLines + 1] = color .. "  - " .. (obj.text or "") .. "|r"
                end
            end
        end

        -- Stub coord hint
        local tailLines = {}
        local coord = step.coord
        if coord and coord.map == 0 and coord.x == 0 and coord.y == 0 then
            tailLines[#tailLines + 1] = "|cFF888780[No waypoint — use /coord at the NPC]|r"
        end

        local function Assemble(shownObjCount)
            local lines = {}
            for _, l in ipairs(headLines) do lines[#lines + 1] = l end
            for i = 1, shownObjCount do lines[#lines + 1] = objLines[i] end
            if shownObjCount < #objLines then
                lines[#lines + 1] = string.format(
                    "|cFF888780  ... +%d more objective(s) — see quest log|r",
                    #objLines - shownObjCount)
            end
            for _, l in ipairs(tailLines) do lines[#lines + 1] = l end
            return table.concat(lines, "\n")
        end

        local BOX_HEIGHT = 65
        local shown = #objLines
        win.stepTextF:SetText(Assemble(shown))
        while shown > 0 and win.stepTextF:GetStringHeight() > BOX_HEIGHT do
            shown = shown - 1
            win.stepTextF:SetText(Assemble(shown))
        end
        win.stepTextF:SetTextColor(0.92, 0.92, 0.88, 1)
    end

    -- Quest status line (base text; RenderStatusLine appends live distance/ETA)
    if step.questID then
        local st = QUEST_STATUS[self:GetQuestStatus(step.questID)] or ""
        self._statusBase = "|cFFAAAAAA#" .. step.questID .. "|r  " .. st
    elseif step._manualDone then
        self._statusBase = "|cFF1EFF00Marked as done|r"
    else
        self._statusBase = ""
    end
    self:RenderStatusLine()

    -- Next-step preview
    local nextStep = guide.steps[self.stepIdx + 1]
    if nextStep then
        local nextText = nextStep.text or ""
        if #nextText > 42 then nextText = nextText:sub(1, 39) .. "..." end
        win.nextStepF:SetText("|cFF8B7040Next:|r " .. nextText)
    else
        win.nextStepF:SetText(self.stepIdx >= total and "|cFF8B7040Final step|r" or "")
    end

    -- Done button state
    local isLast = self.stepIdx >= total
    win.doneBtn._lbl:SetText(self:IsStepComplete(step) and "Done >" or "Mark Done >")
    if isLast then
        win.doneBtn:SetBackdropColor(0.10, 0.08, 0.01, 0.70)
        win.doneBtn._lbl:SetTextColor(0.45, 0.35, 0.10, 1)
    else
        win.doneBtn:SetBackdropColor(0.18, 0.13, 0.01, 0.90)
        win.doneBtn._lbl:SetTextColor(1.00, 0.82, 0.00, 1.00)
    end
end

-- ── RenderStatusLine ──────────────────────────────────────────────────────────
-- Rebuilds just the quest-status line (base text + live distance/ETA), so the
-- throttled ticker can refresh distance without re-running all of UpdateWindow.
function QT:RenderStatusLine()
    local win = self.window
    if not win then return end

    -- No active guide: UpdateWindow() already blanked these fields directly
    -- (its "No Active Guide" branch) — don't let a stale cached _statusBase/
    -- _badgeBase from a previously-selected guide bleed back in on the next tick.
    if not (self.guideID and TA.Guides and TA.Guides[self.guideID]) then
        win.questStatusF:SetText("")
        if win.stepBadgeF then win.stepBadgeF:SetText("") end
        return
    end

    local base = self._statusBase or ""
    local distStr = ""
    local hasLiveTarget = false

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local step  = guide and guide.steps[self.stepIdx]
    if step and step.coord and step.type ~= "text" then
        local Arrow = TA:GetModule("Arrow")
        if Arrow and Arrow.GetEffectiveCoord then
            local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
            local currentMap = C_Map.GetBestMapForUnit("player")
            if not (coordMap == 0 and cx == 0 and cy == 0)
               and currentMap and (coordMap == 0 or coordMap == currentMap) then
                local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
                if pos then
                    hasLiveTarget = true
                    local px, py = pos:GetXY()
                    local yards  = U.ComputeDistance(px, py, cx, cy)
                    local TM     = TA:GetModule("TravelModes")
                    local speed  = (TM and TM:GetSpeed()) or 7
                    distStr = "  |cFF888780" .. U.FormatDistance(yards)
                              .. "  " .. U.FormatETA(yards, speed) .. "|r"
                end
            end
        end
    end

    -- Arrow-status indicator: a soft-pulsing green dot next to the step
    -- badge when the HUD arrow has a real live target for this step, a
    -- static grey dot otherwise — ties the tracker and arrow together
    -- visually without needing a whole new UI element.
    if win.stepBadgeF then
        local dot
        if hasLiveTarget then
            local glow = 0.5 + 0.5 * math.sin(GetTime() * 4)   -- 0..1
            local g    = math.floor(140 + glow * 115)          -- brightness pulse, 140-255
            dot = string.format("|cFF1E%02X30●|r ", g)
        else
            dot = "|cFF555555●|r "
        end
        win.stepBadgeF:SetText(dot .. (self._badgeBase or ""))
    end

    win.questStatusF:SetText(base .. distStr)
end

-- ── ToggleWindow ──────────────────────────────────────────────────────────────

function QT:ToggleWindow()
    -- Always toggle the floating tracker window. The side-drawer is a
    -- supplementary view inside the main ToonAge frame, not a replacement
    -- for the always-visible HUD tracker.
    if not self.window then
        print("|cFFFF4444[TA]|r Tracker window not initialised — check for errors at login.")
        return
    end
    if self.window:IsVisible() then
        self.window:Hide()
        if self.optionsFrame then self.optionsFrame:Hide() end
        if TA.charDB then TA.charDB.tracker.visible = false end
        self:UpdateBlizzardTrackerVisibility()
    else
        self.window:Show()
        self:UpdateWindow()
        if TA.charDB then TA.charDB.tracker.visible = true end
        self:UpdateBlizzardTrackerVisibility()
        if self.guideID and TA.Guides and TA.Guides[self.guideID] then
            local g = TA.Guides[self.guideID]
            print(string.format("|cFFFFD100[TA Tracker]|r '%s' — step %d/%d",
                g.title, self.stepIdx, #g.steps))
        end
    end
end

QT.SlashCommands = {
    tracker = function(self) self:ToggleWindow() end,

    autoselect = function(self)
        self:AutoSelectGuide()
        self:UpdateWindow()
        if self.guideID and TA.Guides and TA.Guides[self.guideID] then
            local g = TA.Guides[self.guideID]
            print(string.format("|cFFFFD100[TA Tracker]|r Auto-selected: '%s' — step %d/%d",
                g.title, self.stepIdx, #g.steps))
            print("|cFF888780Use /ta diag to see why this guide was chosen.|r")
        else
            print("|cFFFFD100[TA Tracker]|r No guide matched. Run |cFFFFD100/ta diag|r to see what the tracker sees.")
        end
    end,

    -- /ta diag  or  /ta diagnose — dump matching details to chat
    diag     = function(self) self:Diagnose() end,
    diagnose = function(self) self:Diagnose() end,
}


-- =============================================================================
-- PROXIMITY-BASED AUTO-ADVANCE (APR-style)
-- =============================================================================
-- When the current step is a 'travel' or 'Waypoint'-type step (no quest
-- action, just movement), auto-advance to the next step when the player
-- arrives within range. This eliminates manual "Mark Done" for travel steps.

local PROXIMITY_RANGE = 15  -- yards — advance when within this distance

function QT:CheckProximityAdvance()
    if not self.guideID then return end
    local guide = TA.Guides and TA.Guides[self.guideID]
    if not guide then return end
    local step = guide.steps[self.stepIdx]
    if not step then return end

    -- Only auto-advance travel/waypoint steps (not quest pickup/turnin/action)
    local stepType = step.type or ""
    if stepType ~= "travel" and stepType ~= "waypoint" and stepType ~= "run" then
        return
    end

    -- Need a coord to measure distance against
    if not step.coord then return end
    local Arrow = TA:GetModule("Arrow")
    if not Arrow or not Arrow.GetEffectiveCoord then return end

    local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
    if coordMap == 0 and cx == 0 and cy == 0 then return end

    local currentMap = C_Map.GetBestMapForUnit("player")
    if not currentMap then return end
    if coordMap ~= 0 and coordMap ~= currentMap then return end

    local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
    if not pos then return end
    local px, py = pos:GetXY()

    local yards = TA.Utils.ComputeDistance(px, py, cx, cy)
    if yards <= PROXIMITY_RANGE then
        -- Auto-advance: mark current step done and move to next incomplete
        step._manualDone = true
        for i = self.stepIdx + 1, #guide.steps do
            if not self:IsStepComplete(guide.steps[i]) then
                self.stepIdx = i
                self:SaveState()
                self:UpdateWindow()
                -- Subtle chat notification
                print(string.format("|cFF4AFF7A[TA]|r Arrived — advancing to step %d.", i))
                return
            end
        end
        -- All subsequent steps done
        self.stepIdx = #guide.steps
        self:SaveState()
        self:UpdateWindow()
    end
end



-- =============================================================================
-- SIDE-DRAWER INTEGRATION
-- =============================================================================
-- When the modern UI drawer is available (TA.Modern.drawer), QuestTracker
-- renders a compact tracker view inside the drawer panel. The floating window
-- is hidden in this mode but remains available if the user switches to
-- fragmented layout.

function QT:InitDrawerMode()
    local M = TA.Modern
    if not M or not M.drawer then return end

    -- The floating window remains the primary always-visible tracker.
    -- The drawer provides a secondary view when the main ToonAge frame is open.
    -- Show the floating window if a guide is active.
    if self.guideID and TA.Guides and TA.Guides[self.guideID] then
        if self.window then
            self.window:Show()
            self:UpdateWindow()
            if TA.charDB then TA.charDB.tracker.visible = true end
        end
    end

    -- Render into the drawer (will only display when main frame is shown)
    self:UpdateDrawer()
end

--- Render the current guide step into the side-drawer content area.
--- Called from InitDrawerMode and hooked into UpdateWindow.
function QT:UpdateDrawer()
    local M = TA.Modern
    if not M or not M.drawer or not M.drawer:IsVisible() then return end

    local content = M:RebuildDrawerChild()
    if not content then return end

    local guide = self.guideID and TA.Guides and TA.Guides[self.guideID]
    local PAD = 8
    local contentW = M.DRAWER_WIDTH - 28

    if not guide then
        local noGuide = M:CreateBody(content, "No active guide.")
        noGuide:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -PAD)
        noGuide:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
        content:SetHeight(40)
        return
    end

    local total = #guide.steps
    local step  = guide.steps[self.stepIdx] or {}
    local y = -PAD

    -- Guide title
    local titleF = M:CreateCaption(content, guide.title or "Guide")
    titleF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    titleF:SetWidth(contentW - PAD * 2)
    titleF:SetJustifyH("LEFT")
    y = y - 14

    -- Step progress
    local progressF = M:CreateData(content, string.format("Step %d / %d", self.stepIdx, total))
    progressF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    y = y - 16

    -- Progress bar
    local barBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
    barBg:SetSize(contentW - PAD * 2, 4)
    barBg:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    barBg:SetBackdrop(M.BACKDROP_FLAT)
    barBg:SetBackdropColor(0.15, 0.15, 0.18, 1)
    barBg:SetBackdropBorderColor(0, 0, 0, 0)

    local barFill = barBg:CreateTexture(nil, "OVERLAY")
    barFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
    local pct = total > 0 and (self.stepIdx / total) or 0
    barFill:SetWidth(math.max(1, (contentW - PAD * 2) * pct))
    barFill:SetVertexColor(0.30, 0.80, 0.45, 0.9)
    y = y - 12

    -- Divider
    local div = content:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(0.30, 0.30, 0.35, 0.50)
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    div:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, y)
    y = y - 8

    -- Step type badge
    local typeBadge = step.type or "quest"
    local badgeColors = {
        quest  = M.CLR_TEXT_WARNING,
        travel = M.CLR_TEXT_ACCENT,
        npc    = M.CLR_TEXT_SUCCESS,
        item   = { 0.73, 0.60, 1.00, 1.00 },
        action = M.CLR_TEXT_WARNING,
        text   = M.CLR_TEXT_SECONDARY,
        accept = M.CLR_TEXT_SUCCESS,
    }
    local badgeF = M:CreateCaption(content, string.upper(typeBadge))
    badgeF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    local bClr = badgeColors[typeBadge] or M.CLR_TEXT_SECONDARY
    badgeF:SetTextColor(unpack(bClr))
    y = y - 14

    -- Step text
    local stepTextF = M:CreateBody(content, step.text or "")
    stepTextF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
    stepTextF:SetWidth(contentW - PAD * 2)
    stepTextF:SetWordWrap(true)
    stepTextF:SetJustifyH("LEFT")
    local textH = stepTextF:GetStringHeight() or 14
    y = y - math.max(textH, 14) - 6

    -- Live objectives (if quest is in log)
    if step.questID and IsInLog(step.questID) then
        local objectives = C_QuestLog.GetQuestObjectives
                        and C_QuestLog.GetQuestObjectives(step.questID)
        if objectives and #objectives > 0 then
            for _, obj in ipairs(objectives) do
                local objF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                objF:SetFont(M.FONT_BODY, M.SIZE_CAPTION, "")
                objF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + 8, y)
                objF:SetWidth(contentW - PAD * 2 - 8)
                objF:SetJustifyH("LEFT")
                if obj.finished then
                    objF:SetText("✓ " .. (obj.text or ""))
                    objF:SetTextColor(unpack(M.CLR_TEXT_SUCCESS))
                else
                    objF:SetText("○ " .. (obj.text or ""))
                    objF:SetTextColor(unpack(M.CLR_TEXT_PRIMARY))
                end
                y = y - 13
            end
            y = y - 4
        end
    end

    -- Quest status
    if step.questID then
        local statusText = ""
        local statusClr = M.CLR_TEXT_SECONDARY
        local qs = self:GetQuestStatus(step.questID)
        if qs == "complete"   then statusText = "Complete";       statusClr = M.CLR_TEXT_SUCCESS end
        if qs == "turnin"     then statusText = "Ready to Turn In"; statusClr = M.CLR_TEXT_WARNING end
        if qs == "inprogress" then statusText = "In Progress";    statusClr = M.CLR_TEXT_SECONDARY end
        if qs == "available"  then statusText = "Not Started";    statusClr = M.CLR_TEXT_SECONDARY end

        local stF = M:CreateCaption(content, statusText)
        stF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
        stF:SetTextColor(unpack(statusClr))
        y = y - 14
    end

    -- Distance / ETA from arrow
    local Arrow = TA:GetModule("Arrow")
    if Arrow and Arrow.GetEffectiveCoord and step.coord and step.type ~= "text" then
        local coordMap, cx, cy = Arrow.GetEffectiveCoord(step)
        local currentMap = C_Map.GetBestMapForUnit("player")
        if currentMap and not (coordMap == 0 and cx == 0 and cy == 0) then
            local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
            if pos then
                local px, py = pos:GetXY()
                local yards = TA.Utils.ComputeDistance(px, py, cx, cy)
                local TM    = TA:GetModule("TravelModes")
                local speed = (TM and TM:GetSpeed()) or 7
                local distF = M:CreateCaption(content,
                    TA.Utils.FormatDistance(yards) .. "  " .. TA.Utils.FormatETA(yards, speed))
                distF:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
                distF:SetTextColor(unpack(M.CLR_TEXT_SECONDARY))
                y = y - 14
            end
        end
    end

    -- Final height
    content:SetHeight(math.abs(y) + PAD)
end

-- Hook UpdateWindow to also update the drawer when in unified mode.
-- This is done by wrapping the original UpdateWindow.
do
    local origUpdateWindow = QT.UpdateWindow
    if origUpdateWindow then
        QT.UpdateWindow = function(self)
            origUpdateWindow(self)
            -- Also update drawer if in unified mode
            if TA.db and TA.db.useUnifiedUI and TA.Modern and TA.Modern.drawer then
                self:UpdateDrawer()
            end
        end
    end
end
