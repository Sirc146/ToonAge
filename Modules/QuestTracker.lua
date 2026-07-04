-- CharacterAdvisor/Modules/QuestTracker.lua
-- Floating tracker window showing current guide step.
-- Features: Live Objectives, FFWD Catch-up, Smart Phrase Parsing,
--           Auto-Questing, Blizzard Tracker Replacement.

local CA = CharacterAdvisor
local U  = CA.Utils

local QT = {}
CA:RegisterModule("QuestTracker", QT)

QT.window        = nil
QT.optionsFrame  = nil
QT.guideID       = nil
QT.stepIdx       = 1
QT.statusThrottle = 0
local STATUS_UPDATE_HZ = 0.2   -- distance/ETA refresh rate, matches Arrow's own tick budget

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

function QT:FastForward(silent)
    if not self.guideID then return end
    local guide = CA.Guides and CA.Guides[self.guideID]
    if not guide then return end

    -- Pass 1: scan backwards to find the furthest quest that's active or done
    local anchorIdx = 1
    for i = #guide.steps, 1, -1 do
        local step = guide.steps[i]
        if step.questID then
            if IsComplete(step.questID) or IsInLog(step.questID) then
                anchorIdx = i
                break
            end
        end
    end

    -- Pass 2: from that anchor, find the first step not yet complete
    for i = anchorIdx, #guide.steps do
        if not self:IsStepComplete(guide.steps[i]) then
            self.stepIdx = i
            self:SaveState()
            self:UpdateWindow()
            if not silent then
                print("|cFF4AFF7A[CA Tracker]|r Fast-forwarded to step " .. i .. ".")
            end
            return
        end
    end

    -- All steps from anchor onward are done — land on the last step
    self.stepIdx = #guide.steps
    self:SaveState()
    self:UpdateWindow()
    if not silent then
        print("|cFF4AFF7A[CA Tracker]|r Guide appears complete.")
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
    for id, g in pairs(CA.Guides or {}) do
        table.insert(list, { id = id, title = g.title, minLevel = g.minLevel or 1 })
    end
    table.sort(list, function(a, b)
        return a.minLevel < b.minLevel or (a.minLevel == b.minLevel and a.id < b.id)
    end)
    return list
end

function QT:SetGuide(guideID)
    local guide = CA.Guides and CA.Guides[guideID]
    if not guide then return end
    self.guideID = guideID
    self.stepIdx = 1
    self:FastForward(true)   -- silently snap to the player's real position
    self:SaveState()
end

function QT:SmartMatchGuideFromLog()
    if not CA.Guides then return false end
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
    for id, guide in pairs(CA.Guides) do
        local count = 0
        for _, step in ipairs(guide.steps) do
            if step.questID and activeIDs[step.questID] then count = count + 1 end
        end
        if count > bestCount then bestCount = count; bestID = id end
    end

    if bestID then
        self:SetGuide(bestID)
        return true
    end
    return false
end

function QT:AutoSelectGuide()
    if self:SmartMatchGuideFromLog() then return end

    local level      = UnitLevel("player") or 1
    local currentMap = C_Map.GetBestMapForUnit("player")
    local list       = self:GetSortedGuideList()
    for _, entry in ipairs(list) do
        local g = CA.Guides[entry.id]
        local levelMatch = level >= (g.minLevel or 1) and level <= (g.maxLevel or 999)
        local zoneMatch  = currentMap and MapIsInZone(currentMap, g.zone)
        if levelMatch and zoneMatch then
            self:SetGuide(entry.id)
            return
        end
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
    if not CA.charDB then return end
    CA.charDB.tracker = CA.charDB.tracker or {}
    CA.charDB.tracker.guideID = self.guideID
    CA.charDB.tracker.stepIdx = self.stepIdx
end

-- ── Auto-Quest Engine ─────────────────────────────────────────────────────────

function QT:HandleAutoQuest(event)
    if not (CA.charDB and CA.charDB.tracker and CA.charDB.tracker.autoQuest) then return end
    if IsShiftKeyDown() then return end

    if event == "QUEST_DETAIL" then
        AcceptQuest()
        HideUIPanel(QuestFrame)

    elseif event == "QUEST_PROGRESS" then
        if IsQuestCompletable() then CompleteQuest() end

    elseif event == "QUEST_COMPLETE" then
        if GetNumQuestChoices() <= 1 then GetQuestReward(1) end

    elseif event == "GOSSIP_SHOW" then
        if C_GossipInfo then
            local active = C_GossipInfo.GetActiveQuests()
            if active then
                for _, q in ipairs(active) do
                    if q.isComplete then C_GossipInfo.SelectActiveQuest(q.questID); return end
                end
            end
            local available = C_GossipInfo.GetAvailableQuests()
            if available and available[1] then
                C_GossipInfo.SelectAvailableQuest(available[1].questID)
            end
        end

    elseif event == "QUEST_GREETING" then
        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            if isComplete then SelectActiveQuest(i); return end
        end
        for i = 1, GetNumAvailableQuests() do SelectAvailableQuest(i); return end
    end
end

-- ── Blizzard tracker ─────────────────────────────────────────────────────────

function QT:UpdateBlizzardTrackerVisibility()
    if not (CA.charDB and CA.charDB.tracker) then return end
    local shouldHide = CA.charDB.tracker.replaceBlizzTracker
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
        -- Full backward+forward sync on every log change — handles skipped
        -- quests, side-quests, and out-of-order completions automatically.
        self:FastForward(true)

    elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdateWindow()
    end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function QT:Init()
    CA.eventFrame:RegisterEvent("QUEST_ACCEPTED")
    CA.eventFrame:RegisterEvent("QUEST_TURNED_IN")
    CA.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    CA.eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    CA.eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    CA.eventFrame:RegisterEvent("QUEST_DETAIL")
    CA.eventFrame:RegisterEvent("QUEST_PROGRESS")
    CA.eventFrame:RegisterEvent("QUEST_COMPLETE")
    CA.eventFrame:RegisterEvent("GOSSIP_SHOW")
    CA.eventFrame:RegisterEvent("QUEST_GREETING")

    -- Preserve existing saved settings; only apply defaults for missing keys
    CA.charDB.tracker = CA.charDB.tracker or {}
    local t = CA.charDB.tracker
    if t.autoQuest           == nil then t.autoQuest           = false end
    if t.replaceBlizzTracker == nil then t.replaceBlizzTracker = false end

    if t.guideID and CA.Guides and CA.Guides[t.guideID] then
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
    if CA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
    local lblStr = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblStr:SetFont(STANDARD_TEXT_FONT, 10, "")
    lblStr:SetText(label)
    lblStr:SetTextColor(0.88, 0.83, 0.65, 1)
    lblStr:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    cb:SetScript("OnClick", function()
        CA.charDB.tracker[dbKey] = not CA.charDB.tracker[dbKey]
        if CA.charDB.tracker[dbKey] then chk:Show() else chk:Hide() end
        if onChange then onChange(CA.charDB.tracker[dbKey]) end
    end)
    return cb
end

local BADGE = {
    quest  = "|cFFFFD100", travel = "|cFF1EBCFF", npc    = "|cFF78FF78",
    item   = "|cFFBB99FF", action = "|cFFFF8833", text   = "|cFF999999",
}
local QUEST_STATUS = {
    complete   = "|cFF1EFF00[Complete]|r",
    turnin     = "|cFFFFD100[Ready to Turn In]|r",
    inprogress = "|cFF888780[In Progress]|r",
    available  = "|cFFAAAAAA[Not Started]|r",
}

-- ── InitWindow ────────────────────────────────────────────────────────────────

function QT:InitWindow()
    local win = CreateFrame("Frame", "CATrackerWindow", UIParent, "BackdropTemplate")
    win:SetSize(W, H)
    win:SetFrameStrata("HIGH")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetClampedToScreen(true)
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if CA.charDB then
            CA.charDB.tracker.x = f:GetLeft()
            CA.charDB.tracker.y = f:GetTop()
        end
    end)
    ApplyBD(win, 0.05, 0.04, 0.02, 0.97, 0.55, 0.40, 0.08)

    local saved = CA.charDB and CA.charDB.tracker
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
    optPanel:SetSize(W, 74)
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
        local guide = CA.Guides and CA.Guides[self.guideID]
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
    end)

    self.window = win
    self:UpdateWindow()
end

-- ── UpdateWindow ──────────────────────────────────────────────────────────────

function QT:UpdateWindow()
    local win = self.window
    if not win then return end

    local guide = self.guideID and CA.Guides and CA.Guides[self.guideID]

    if not guide then
        win.guideTitleF:SetText("|cFFFF8800No Active Guide|r")
        win.stepNumF:SetText("")
        win.stepBadgeF:SetText("")
        win.stepTextF:SetText(
            "No guide matches your current zone or quest log.\n\n"
            .. "Use the |cFFFFD100< >|r arrows to manually cycle guides, "
            .. "or |cFFFFD100FFWD >>|r to sync after selecting one.")
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
        -- Build step display text
        local parts = {}

        -- Line 1: live quest title from client (gold) if available
        if step.questID then
            local liveTitle = C_QuestLog.GetTitleForQuestID
                           and C_QuestLog.GetTitleForQuestID(step.questID)
            if liveTitle and liveTitle ~= "" then
                parts[#parts + 1] = "|cFFFFD100" .. liveTitle .. "|r"
            end
        end

        -- Line 2: guide step prose
        parts[#parts + 1] = step.text or ""

        -- Live objectives (injected when quest is in log)
        if step.questID and IsInLog(step.questID) then
            local objectives = C_QuestLog.GetQuestObjectives
                            and C_QuestLog.GetQuestObjectives(step.questID)
            if objectives and #objectives > 0 then
                for _, obj in ipairs(objectives) do
                    local color = obj.finished and "|cFF888780" or "|cFFFFFFFF"
                    parts[#parts + 1] = color .. "  - " .. (obj.text or "") .. "|r"
                end
            end
        end

        -- Stub coord hint
        local coord = step.coord
        if coord and coord.map == 0 and coord.x == 0 and coord.y == 0 then
            parts[#parts + 1] = "|cFF888780[No waypoint — use /coord at the NPC]|r"
        end

        win.stepTextF:SetText(table.concat(parts, "\n"))
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
    if not (self.guideID and CA.Guides and CA.Guides[self.guideID]) then
        win.questStatusF:SetText("")
        if win.stepBadgeF then win.stepBadgeF:SetText("") end
        return
    end

    local base = self._statusBase or ""
    local distStr = ""
    local hasLiveTarget = false

    local guide = self.guideID and CA.Guides and CA.Guides[self.guideID]
    local step  = guide and guide.steps[self.stepIdx]
    if step and step.coord and step.type ~= "text" then
        local Arrow = CA:GetModule("Arrow")
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
                    local TM     = CA:GetModule("TravelModes")
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
    if not self.window then
        print("|cFFFF4444[CA]|r Tracker window not initialised — check for errors at login.")
        return
    end
    if self.window:IsVisible() then
        self.window:Hide()
        if self.optionsFrame then self.optionsFrame:Hide() end
        if CA.charDB then CA.charDB.tracker.visible = false end
        self:UpdateBlizzardTrackerVisibility()
    else
        self.window:Show()
        self:UpdateWindow()
        if CA.charDB then CA.charDB.tracker.visible = true end
        self:UpdateBlizzardTrackerVisibility()
        if self.guideID and CA.Guides and CA.Guides[self.guideID] then
            local g = CA.Guides[self.guideID]
            print(string.format("|cFFFFD100[CA Tracker]|r '%s' — step %d/%d",
                g.title, self.stepIdx, #g.steps))
        end
    end
end

QT.SlashCommands = {
    tracker = function(self) self:ToggleWindow() end,
    autoselect = function(self)
        self:AutoSelectGuide()
        self:UpdateWindow()
        if self.guideID and CA.Guides and CA.Guides[self.guideID] then
            local g = CA.Guides[self.guideID]
            print("|cFFFFD100[CA Tracker]|r Auto-selected: '" .. g.title .. "' — step " .. self.stepIdx .. "/" .. #g.steps)
        else
            print("|cFFFFD100[CA Tracker]|r No guide matches your current zone, level, or quest log.")
        end
    end,
}
