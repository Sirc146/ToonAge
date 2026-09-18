-- ToonAge/Modules/GuideContextMenu.lua (Classic — MoP 50504)
-- Right-click context menu for guide steps using UIDropDownMenu.
-- In MoP Classic, UIDropDownMenu is the standard menu system (no MenuUtil).
--
-- Features:
--   1. Context menu on quest tracker steps — "Find Guide" option
--   2. Confirmation popup before switching guides
--   3. Right-click on QuestTracker step rows for step actions

local TA = ToonAge
local U  = TA.Utils

local GCM = {}
TA:RegisterModule("GuideContextMenu", GCM)

-- ── Constants ─────────────────────────────────────────────────────────
local POPUP_NAME = "TOONAGE_SWITCH_GUIDE"

-- ── Core switching logic ──────────────────────────────────────────────

local function SwitchToGuideForQuest(questID, skipPopup)
    if not questID or questID == 0 then return end

    local GI = TA:GetModule("GuideImporter")
    if not GI or not GI.FindGuideForQuest then return end

    local guideID = GI:FindGuideForQuest(questID)
    if not guideID then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r No guide found for quest #" .. questID)
        return
    end

    local QT = TA:GetModule("QuestTracker")
    if QT and QT.guideID == guideID then
        -- Already on correct guide — jump to the quest's step
        local guide = TA.Guides and TA.Guides[guideID]
        if guide then
            for i, step in ipairs(guide.steps) do
                if step.questID == questID then
                    QT.stepIdx = i
                    QT:SaveState()
                    QT:UpdateWindow()
                    if QT.ShowToast then QT:ShowToast("Jumped to step " .. i) end
                    return
                end
            end
        end
        return
    end

    local guide = TA.Guides and TA.Guides[guideID]
    local guideName = guide and guide.title or guideID

    if skipPopup or IsShiftKeyDown() then
        if QT then
            QT:SetGuide(guideID)
            if guide then
                for i, step in ipairs(guide.steps) do
                    if step.questID == questID then
                        QT.stepIdx = i
                        QT:SaveState()
                        break
                    end
                end
            end
            QT:UpdateWindow()
            if QT.ShowToast then QT:ShowToast("Following: " .. guideName) end
        end
        return
    end

    -- Show confirmation popup
    GCM._pendingGuideID   = guideID
    GCM._pendingGuideName = guideName
    GCM._pendingQuestID   = questID
    GCM._jumpToStep       = nil

    if guide then
        for i, step in ipairs(guide.steps) do
            if step.questID == questID then
                GCM._jumpToStep = i
                break
            end
        end
    end

    StaticPopup_Show(POPUP_NAME)
end

-- ── Static Popup ──────────────────────────────────────────────────────

StaticPopupDialogs[POPUP_NAME] = {
    text = "ToonAge found a guide for this quest:\n\n|cFFFFD100%s|r\n\nLoad this guide?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,

    OnShow = function(self)
        local guideName = GCM._pendingGuideName or "Unknown Guide"
        self.text:SetFormattedText(
            StaticPopupDialogs[POPUP_NAME].text,
            guideName
        )
    end,

    OnAccept = function()
        local guideID = GCM._pendingGuideID
        if not guideID then return end

        local QT = TA:GetModule("QuestTracker")
        if QT then
            QT:SetGuide(guideID)
            if GCM._jumpToStep then
                QT.stepIdx = GCM._jumpToStep
                QT:SaveState()
                QT:UpdateWindow()
            end
            if QT.ShowToast then
                local stepInfo = GCM._jumpToStep and (" - Step " .. GCM._jumpToStep) or ""
                QT:ShowToast("Following: " .. (GCM._pendingGuideName or guideID) .. stepInfo)
            end
        end

        GCM._pendingGuideID   = nil
        GCM._pendingGuideName = nil
        GCM._pendingQuestID   = nil
        GCM._jumpToStep       = nil
    end,

    OnCancel = function()
        GCM._pendingGuideID   = nil
        GCM._pendingGuideName = nil
        GCM._pendingQuestID   = nil
        GCM._jumpToStep       = nil
    end,
}

-- ── Step Context Menu (UIDropDownMenu) ────────────────────────────────
-- Called when right-clicking a step in the ToonAge tracker

local contextMenuFrame = nil

function GCM:ShowStepMenu(anchor, stepIdx)
    if not contextMenuFrame then
        contextMenuFrame = CreateFrame("Frame", "TAStepContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local QT = TA:GetModule("QuestTracker")
    if not QT or not QT.guideID then return end
    local guide = TA.Guides and TA.Guides[QT.guideID]
    if not guide then return end
    local step = guide.steps[stepIdx]
    if not step then return end

    local function InitMenu(self, level)
        level = level or 1
        if level ~= 1 then return end

        local info

        -- Header: step type + number
        info = UIDropDownMenu_CreateInfo()
        info.text = string.format("Step %d [%s]", stepIdx, (step.type or "?"):upper())
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Mark Done
        info = UIDropDownMenu_CreateInfo()
        info.text = "Mark as Done"
        info.notCheckable = true
        info.func = function()
            step._manualDone = true
            QT:FastForward(true)
            QT:UpdateWindow()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Skip step
        info = UIDropDownMenu_CreateInfo()
        info.text = "Skip This Step"
        info.notCheckable = true
        info.func = function()
            if QT.SkipStep then
                QT:SkipStep(stepIdx)
            else
                QT.skippedSteps[stepIdx] = true
            end
            QT:FastForward(true)
            QT:UpdateWindow()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Set as sticky
        if step.type ~= "text" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "Pin as Sticky"
            info.notCheckable = true
            info.func = function()
                if QT.SetSticky then QT:SetSticky(stepIdx) end
            end
            UIDropDownMenu_AddButton(info, level)
        end

        -- Separator
        info = UIDropDownMenu_CreateInfo()
        info.text = ""
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Quest info (if step has a questID)
        if step.questID then
            info = UIDropDownMenu_CreateInfo()
            info.text = "Quest ID: " .. step.questID
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            -- Abandon quest option
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cFFFF4444Abandon Quest|r"
            info.notCheckable = true
            info.func = function()
                -- Find quest in log and abandon
                local numEntries = GetNumQuestLogEntries()
                for i = 1, numEntries do
                    local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
                    if not isHeader and questID == step.questID then
                        SelectQuestLogEntry(i)
                        SetAbandonQuest()
                        AbandonQuest()
                        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Quest abandoned.")
                        break
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end

        -- Cancel
        info = UIDropDownMenu_CreateInfo()
        info.text = CANCEL
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    end

    UIDropDownMenu_Initialize(contextMenuFrame, InitMenu, "MENU")
    ToggleDropDownMenu(1, nil, contextMenuFrame, anchor, 0, 0)
end

-- ── Tracker right-click menu ──────────────────────────────────────────
-- Shows guide-level options when right-clicking the tracker window itself

local trackerMenuFrame = nil

function GCM:ShowTrackerMenu(anchor)
    if not trackerMenuFrame then
        trackerMenuFrame = CreateFrame("Frame", "TATrackerContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local QT = TA:GetModule("QuestTracker")

    local function InitMenu(self, level)
        level = level or 1
        if level ~= 1 then return end

        local info

        -- Header
        info = UIDropDownMenu_CreateInfo()
        info.text = "ToonAge Tracker"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Open main panel
        info = UIDropDownMenu_CreateInfo()
        info.text = "Open ToonAge Panel"
        info.notCheckable = true
        info.func = function() TA:ToggleUI() end
        UIDropDownMenu_AddButton(info, level)

        -- Browse guides
        info = UIDropDownMenu_CreateInfo()
        info.text = "Browse All Guides"
        info.notCheckable = true
        info.func = function()
            local GB = TA:GetModule("GuideBrowser")
            if GB then GB:ShowBrowser() end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Re-sync
        info = UIDropDownMenu_CreateInfo()
        info.text = "Re-Sync Position"
        info.notCheckable = true
        info.func = function()
            if QT then QT:FastForward(false) end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Auto-select
        info = UIDropDownMenu_CreateInfo()
        info.text = "Auto-Select Best Guide"
        info.notCheckable = true
        info.func = function()
            if QT then
                QT:AutoSelectGuide()
                QT:UpdateWindow()
            end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Separator
        info = UIDropDownMenu_CreateInfo()
        info.text = ""
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Auto-Quest toggle
        info = UIDropDownMenu_CreateInfo()
        info.text = "Auto-Accept/Turn-In"
        info.checked = TA.charDB and TA.charDB.tracker and TA.charDB.tracker.autoQuest
        info.isNotRadio = true
        info.func = function()
            if TA.charDB and TA.charDB.tracker then
                TA.charDB.tracker.autoQuest = not TA.charDB.tracker.autoQuest
            end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Replace tracker toggle
        info = UIDropDownMenu_CreateInfo()
        info.text = "Replace Blizzard Tracker"
        info.checked = TA.charDB and TA.charDB.tracker and TA.charDB.tracker.replaceBlizzTracker
        info.isNotRadio = true
        info.func = function()
            if TA.charDB and TA.charDB.tracker then
                TA.charDB.tracker.replaceBlizzTracker = not TA.charDB.tracker.replaceBlizzTracker
                if QT then QT:UpdateBlizzardTrackerVisibility() end
            end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Separator
        info = UIDropDownMenu_CreateInfo()
        info.text = ""
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        -- Hide tracker
        info = UIDropDownMenu_CreateInfo()
        info.text = "Hide Tracker"
        info.notCheckable = true
        info.func = function()
            if QT then QT:ToggleWindow() end
        end
        UIDropDownMenu_AddButton(info, level)

        -- Cancel
        info = UIDropDownMenu_CreateInfo()
        info.text = CANCEL
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    end

    UIDropDownMenu_Initialize(trackerMenuFrame, InitMenu, "MENU")
    ToggleDropDownMenu(1, nil, trackerMenuFrame, anchor, 0, 0)
end

-- ── Init ──────────────────────────────────────────────────────────────

function GCM:Init()
    -- In MoP Classic, there's no modern Menu API.
    -- Context menus are invoked from QuestTracker:ShowTrackerMenu() which
    -- calls GCM:ShowTrackerMenu() directly.
    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r GuideContextMenu loaded (UIDropDownMenu mode).")
    end
end
