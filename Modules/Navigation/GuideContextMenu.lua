-- ToonAge/Modules/GuideContextMenu.lua
-- Seamless guide switching via native Blizzard UI integration.
--
-- Three integrated features:
--   1. Context Menu Hook — injects "ToonAge: Find Guide" into quest right-click
--      menus (Objective Tracker + Quest Log).
--   2. Confirmation Popup — StaticPopupDialogs prompt before switching guides.
--   3. Clickable Chat Hyperlinks — replaces "/ta switchto" text commands with
--      native WoW hyperlinks that trigger the same popup on click.
--
-- Design: Zero friction. Right-click → confirm → guide loads. One click in chat → confirm → guide loads.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local GCM = {}
TA:RegisterModule("GuideContextMenu", GCM)

-- ── Constants ─────────────────────────────────────────────────────────────────

local POPUP_NAME       = "TOONAGE_SWITCH_GUIDE"
local HYPERLINK_PREFIX = "toonage"  -- garble: |Htoonage:questID|h[text]|h
local MENU_BUTTON_TEXT = "ToonAge: Find Guide for Quest"

-- ── Core switching logic ──────────────────────────────────────────────────────

--- Attempt to find and switch to a guide containing the given quest.
--- @param questID number
--- @param skipPopup boolean|nil — if true, switch immediately without confirmation
local function SwitchToGuideForQuest(questID, skipPopup)
    if not questID or questID == 0 then return end

    local GI = TA:GetModule("GuideImporter")
    if not GI or not GI.FindGuideForQuest then return end

    local guideID = GI:FindGuideForQuest(questID)
    if not guideID then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r No guide found containing quest #" .. questID .. ".")
        return
    end

    -- Check if already on this guide
    local QT = TA:GetModule("QuestTracker")
    if QT and QT.guideID == guideID then
        -- Already on correct guide — jump to the quest's step silently
        if QT.guideID then
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
        end
        return
    end

    local guide = TA.Guides and TA.Guides[guideID]
    local guideName = guide and guide.title or guideID

    -- Shift-click fast-path: bypass confirmation popup entirely
    if skipPopup or IsShiftKeyDown() then
        if QT then
            QT:SetGuide(guideID)
            -- Jump to exact step if possible
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
            if QT.ShowToast then
                QT:ShowToast("Following: " .. guideName)
            end
        end
        return
    end

    -- Show confirmation popup
    GCM._pendingGuideID   = guideID
    GCM._pendingGuideName = guideName
    GCM._pendingQuestID   = questID

    -- Find target step for jump-on-accept
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

-- ══════════════════════════════════════════════════════════════════════════════
-- SECTION 1 — STATIC POPUP (Confirmation Dialog)
-- ══════════════════════════════════════════════════════════════════════════════

StaticPopupDialogs[POPUP_NAME] = {
    text = "ToonAge found a guide containing this quest:\n\n|cFFFFD100%s|r\n\nWould you like to load this guide now?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid taint from sharing index with Blizzard popups

    OnShow = function(self)
        -- Inject the guide name into the text
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

            -- Jump to exact step if requested (from "Continue from here")
            if GCM._jumpToStep then
                QT.stepIdx = GCM._jumpToStep
                QT:SaveState()
                QT:UpdateWindow()
            end

            -- Show toast instead of chat spam
            if QT.ShowToast then
                local stepInfo = GCM._jumpToStep and (" — Step " .. GCM._jumpToStep) or ""
                QT:ShowToast("Following: " .. (GCM._pendingGuideName or guideID) .. stepInfo)
            end
        end

        -- Clean up pending state
        GCM._pendingGuideID   = nil
        GCM._pendingGuideName = nil
        GCM._pendingQuestID   = nil
        GCM._jumpToStep       = nil
    end,

    OnCancel = function()
        GCM._pendingGuideID   = nil
        GCM._pendingGuideName = nil
        GCM._pendingQuestID   = nil
    end,
}


-- ══════════════════════════════════════════════════════════════════════════════
-- SECTION 2 — CONTEXT MENU HOOK (Quest Right-Click Menus)
-- ══════════════════════════════════════════════════════════════════════════════

--- Hook into Blizzard's modern Menu API (10.0+) to add a ToonAge button
--- to quest context menus in the Objective Tracker and Quest Map.
local function SetupMenuHooks()
    -- The modern WoW menu system (11.0+) uses Menu.ModifyMenu with string tags.
    -- Quest context menus use "MENU_QUEST_TRACKING" for the objective tracker
    -- and "MENU_QUEST_MAP_LOG" for the quest map log.
    if not Menu or not Menu.ModifyMenu then
        -- Fallback: try the older UIDropDownMenu approach for pre-11.0 builds
        SetupLegacyMenuHook()
        return
    end

    -- Hook the Objective Tracker quest context menu
    local function AddToonAgeButton(ownerRegion, rootDescription, contextData)
        -- contextData contains questID for quest menus
        local questID = contextData and contextData.questID
        if TA.debug then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA GCM]|r AddToonAgeButton fired. questID=" .. tostring(questID))
        end
        if not questID then return end

        local GI = TA:GetModule("GuideImporter")
        if not GI then return end
        local QT = TA:GetModule("QuestTracker")
        if not QT then return end

        local guideID = GI:FindGuideForQuest(questID)
        if not guideID then return end

        local guide = TA.Guides and TA.Guides[guideID]
        if not guide then return end

        -- Find the exact step index for this quest
        local targetStepIdx = nil
        for i, step in ipairs(guide.steps) do
            if step.questID == questID then
                targetStepIdx = i
                break
            end
        end

        rootDescription:CreateDivider()

        if QT.guideID == guideID and targetStepIdx then
            -- Already on this guide — offer to jump to exact step
            rootDescription:CreateButton("ToonAge: Continue from Here", function()
                QT.stepIdx = targetStepIdx
                QT:SaveState()
                QT:UpdateWindow()
                QT:ShowToast("Jumped to step " .. targetStepIdx)
            end)
        elseif QT.guideID ~= guideID then
            -- Different guide — offer to switch AND jump to step
            local guideName = guide.title or guideID
            rootDescription:CreateButton("ToonAge: Follow This Quest", function()
                -- Store target step so we jump to it after switching
                GCM._jumpToStep = targetStepIdx
                SwitchToGuideForQuest(questID)
            end)
        end
    end

    -- Hook both quest tracking menus
    local ok1, err1 = pcall(function()
        Menu.ModifyMenu("MENU_QUEST_TRACKING", AddToonAgeButton)
    end)

    local ok2, err2 = pcall(function()
        Menu.ModifyMenu("MENU_QUEST_MAP_LOG", AddToonAgeButton)
    end)

    -- Also try the older tag names used in some builds
    if not ok1 then
        pcall(function()
            Menu.ModifyMenu("MENU_QUEST_TRACKER", AddToonAgeButton)
        end)
    end

    if not ok2 then
        pcall(function()
            Menu.ModifyMenu("MENU_QUEST_LOG", AddToonAgeButton)
        end)
    end

    if TA.debug then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA GuideContextMenu]|r Menu hooks registered."
            .. (not ok1 and (" Tracker: " .. tostring(err1)) or "")
            .. (not ok2 and (" QuestLog: " .. tostring(err2)) or ""))
    end
end

--- Legacy fallback for pre-11.0 builds using UIDropDownMenu.
local function SetupLegacyMenuHook()
    -- In older builds (pre-11.0), we can hook QuestMapQuestOptions_Show
    -- or hooksecurefunc the dropdown initialization. However, this is
    -- increasingly deprecated. We attempt it but don't error if it fails.
    if not hooksecurefunc then return end

    -- Hook the dropdown initialization for quest options
    local function TryHookDropDown()
        -- QuestMapQuestOptions uses UIDropDownMenu_Initialize
        if not UIDropDownMenu_AddButton then return end

        -- Hook the Objective Tracker right-click
        if ObjectiveTrackerBlockDropDown then
            local origInit = UIDropDownMenu_Initialize
            hooksecurefunc("UIDropDownMenu_Initialize", function(frame, initFunc, ...)
                if frame ~= ObjectiveTrackerBlockDropDown then return end

                -- Add our button at the end of the menu
                C_Timer.After(0, function()
                    local questID = frame.activeFrame and frame.activeFrame.id
                    if not questID then return end

                    local GI = TA:GetModule("GuideImporter")
                    if not GI then return end
                    local guideID = GI:FindGuideForQuest(questID)
                    if not guideID then return end

                    local QT = TA:GetModule("QuestTracker")
                    if QT and QT.guideID == guideID then return end

                    local info = UIDropDownMenu_CreateInfo()
                    info.text = MENU_BUTTON_TEXT
                    info.notCheckable = true
                    info.func = function()
                        SwitchToGuideForQuest(questID)
                    end
                    UIDropDownMenu_AddButton(info)
                end)
            end)
        end
    end

    pcall(TryHookDropDown)
end


-- ══════════════════════════════════════════════════════════════════════════════
-- SECTION 3 — CLICKABLE CHAT HYPERLINKS
-- ══════════════════════════════════════════════════════════════════════════════

--- Generate a clickable hyperlink string for chat output.
--- Format: |Htoonage:questID:guideID|h[Click Here to Load Guide]|h
--- @param questID number
--- @param guideID string
--- @param guideName string
--- @return string — formatted hyperlink string
function GCM:CreateHyperlink(questID, guideID, guideName)
    -- WoW hyperlink format: |Htype:data|h[visible text]|h
    -- The |cFF...|r color codes wrap around the full hyperlink for styling
    local linkData = string.format("%s:%d:%s", HYPERLINK_PREFIX, questID, guideID)
    local linkText = "|cFF4AE0FF|H" .. linkData .. "|h[Click to Load Guide]|h|r"
    return linkText
end

--- Print a guide-found message to chat with a clickable hyperlink instead of
--- the old "/ta switchto <id>" command text.
--- @param questID number
--- @param guideID string
--- @param guideName string
function GCM:PrintGuideFoundMessage(questID, guideID, guideName)
    local hyperlink = self:CreateHyperlink(questID, guideID, guideName)
    TA:Raw(TA.LOG.OUTPUT, string.format(
        "|cFFFFD100[ToonAge]|r Quest #%d belongs to |cFFFFFFFF%s|r — %s",
        questID, guideName, hyperlink
    ))
end

--- Hook SetItemRef to intercept clicks on our custom hyperlinks.
--- SetItemRef is called by WoW when any hyperlink in chat is clicked.
local function SetupHyperlinkHook()
    -- hooksecurefunc ensures we don't break other addon hyperlink handlers
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        -- SetItemRef fires for every hyperlink click of any kind, and can
        -- be called with a nil link in some cases — always guard first.
        if not link then return end
        -- Parse our custom hyperlink format: "toonage:questID:guideID"
        local prefix, questIDStr, guideID = link:match("^(%a+):(%d+):(.+)$")
        if prefix ~= HYPERLINK_PREFIX then return end

        local questID = tonumber(questIDStr)
        if not questID then return end

        -- Validate the guide still exists
        if not guideID or not (TA.Guides and TA.Guides[guideID]) then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Guide no longer available.")
            return
        end

        -- Trigger the confirmation popup (same flow as right-click menu)
        SwitchToGuideForQuest(questID)
    end)
end

--- Hook ChatFrame hyperlink tooltip to show a tooltip on hover.
local function SetupHyperlinkTooltip()
    -- Hook all chat frames for OnHyperlinkEnter/Leave
    local function OnHyperlinkEnter(chatFrame, link)
        if not link then return end
        local prefix, questIDStr, guideID = link:match("^(%a+):(%d+):(.+)$")
        if prefix ~= HYPERLINK_PREFIX then return end

        local guide = guideID and TA.Guides and TA.Guides[guideID]
        local guideName = guide and guide.title or guideID

        GameTooltip:SetOwner(chatFrame, "ANCHOR_CURSOR")
        GameTooltip:SetText("ToonAge Guide Switch", 1, 0.82, 0)
        GameTooltip:AddLine("Click to load: " .. (guideName or "Unknown"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Quest #" .. (questIDStr or "?"), 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end

    local function OnHyperlinkLeave(chatFrame, link)
        if not link then return end
        local prefix = link:match("^(%a+):")
        if prefix == HYPERLINK_PREFIX then
            GameTooltip:Hide()
        end
    end

    -- Hook all existing chat frames
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:HookScript("OnHyperlinkEnter", OnHyperlinkEnter)
            frame:HookScript("OnHyperlinkLeave", OnHyperlinkLeave)
        end
    end
end


-- ══════════════════════════════════════════════════════════════════════════════
-- SECTION 4 — INTEGRATION WITH EXISTING SYSTEMS
-- ══════════════════════════════════════════════════════════════════════════════

--- Override the GuideBrowser's CheckTrackedQuest message to use hyperlinks.
--- Called once during Init to patch the existing GuideBrowser behavior.
local function PatchGuideBrowserMessage()
    local GB = TA:GetModule("GuideBrowser")
    if not GB then return end

    -- Replace the CheckTrackedQuest function with a version that uses hyperlinks
    local origCheck = GB.CheckTrackedQuest
    GB.CheckTrackedQuest = function(self)
        -- Get the supertracked quest
        local questID = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID
                     and C_SuperTrack.GetSuperTrackedQuestID()
        if not questID or questID == 0 then return end

        -- Check if this quest belongs to a different guide than the active one
        local QT = TA:GetModule("QuestTracker")
        local GI = TA:GetModule("GuideImporter")
        if not QT or not GI then return end

        -- Already in the right guide?
        if QT.guideID then
            local guide = TA.Guides[QT.guideID]
            if guide then
                for _, step in ipairs(guide.steps) do
                    if step.questID == questID then return end
                end
            end
        end

        -- Find which guide has this quest
        local guideID = GI:FindGuideForQuest(questID)
        if guideID and guideID ~= QT.guideID then
            local guide = TA.Guides[guideID]
            local title = guide and guide.title or guideID
            -- Use the new clickable hyperlink instead of "/ta switchto" text
            GCM:PrintGuideFoundMessage(questID, guideID, title)
        end
    end
end


-- ══════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════════════

function GCM:Init()
    -- 1. Register the context menu hooks (quest right-click menus)
    SetupMenuHooks()

    -- 2. Register the hyperlink click handler
    SetupHyperlinkHook()

    -- 3. Register hyperlink tooltip hover
    SetupHyperlinkTooltip()

    -- 4. Patch the GuideBrowser's chat message to use hyperlinks
    PatchGuideBrowserMessage()

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r GuideContextMenu module loaded: context menus + hyperlinks active.")
    end
end
