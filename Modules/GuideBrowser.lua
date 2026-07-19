-- ToonAge/Modules/GuideBrowser.lua
-- Guide Browser: organized expansion → zone shelf for selecting guides.
-- Also hooks into quest log tracking to suggest guide switches.
--
-- Features:
--   • /ta browser — opens the guide selection panel
--   • Organized by expansion, then zone name
--   • Shows quest count, completion %, and "active" badge
--   • Click to switch guide instantly
--   • Quest log hook: when you track/click a quest, suggests matching guide
--
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local GB = {}
TA:RegisterModule("GuideBrowser", GB)

GB.frame = nil

-- ── Expansion ordering ────────────────────────────────────────────────────────
local EXPANSION_ORDER = {
    "Midnight", "TheWarWithin", "Dragonflight", "Shadowlands",
    "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria",
    "Cataclysm", "WrathOfTheLichKing", "TheBurningCrusade", "Classic",
}

local EXPANSION_LABELS = {
    Midnight = "Midnight (12.0)",
    TheWarWithin = "The War Within (11.x)",
    Dragonflight = "Dragonflight (10.x)",
    Shadowlands = "Shadowlands (9.x)",
    BattleForAzeroth = "Battle for Azeroth (8.x)",
    Legion = "Legion (7.x)",
    WarlordsOfDraenor = "Warlords of Draenor (6.x)",
    MistsOfPandaria = "Mists of Pandaria (5.x)",
    Cataclysm = "Cataclysm (4.x)",
    WrathOfTheLichKing = "Wrath of the Lich King (3.x)",
    TheBurningCrusade = "The Burning Crusade (2.x)",
    Classic = "Classic (1.x)",
}

-- ── Organize guides by expansion ──────────────────────────────────────────────

function GB:OrganizeGuides()
    local organized = {}  -- { [expansion] = { {id, title, zone, questCount, completedCount}, ... } }

    for id, guide in pairs(TA.Guides or {}) do
        -- Determine expansion from guide ID or title
        local expansion = "Other"
        local title = guide.title or id

        for _, exp in ipairs(EXPANSION_ORDER) do
            if id:lower():find(exp:lower()) or title:lower():find(exp:lower())
               or title:find(EXPANSION_LABELS[exp] or "") then
                expansion = exp
                break
            end
        end

        -- Fallback: guess from level range
        if expansion == "Other" then
            local minLv = guide.minLevel or 1
            if minLv >= 80 then expansion = "Midnight"
            elseif minLv >= 70 then expansion = "TheWarWithin"
            elseif minLv >= 60 then expansion = "Dragonflight"
            elseif minLv >= 50 then expansion = "Shadowlands"
            elseif minLv >= 1 and (guide.maxLevel or 999) <= 10 then expansion = "Classic"
            end
        end

        -- Count quest completion
        local questCount, completedCount = 0, 0
        for _, step in ipairs(guide.steps or {}) do
            if step.questID then
                questCount = questCount + 1
                if C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
                    completedCount = completedCount + 1
                end
            end
        end

        organized[expansion] = organized[expansion] or {}
        table.insert(organized[expansion], {
            id        = id,
            title     = title:gsub(" %(auto%)$", ""),  -- strip (auto) suffix for display
            zone      = guide.zone,
            quests    = questCount,
            completed = completedCount,
            pct       = questCount > 0 and math.floor(completedCount / questCount * 100) or 0,
            imported  = guide._imported or false,
        })
    end

    -- Sort within each expansion by title
    for _, list in pairs(organized) do
        table.sort(list, function(a, b) return a.title < b.title end)
    end

    return organized
end

-- ── Browser frame ─────────────────────────────────────────────────────────────

function GB:ShowBrowser()
    if self.frame then
        if self.frame:IsShown() then self.frame:Hide(); return end
        self:RefreshBrowser()
        self.frame:Show()
        return
    end

    -- Create the browser frame
    local f = CreateFrame("Frame", "TAGuideBrowser", UIParent, "BackdropTemplate")
    f:SetSize(420, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    f:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
    f:SetBackdropBorderColor(0.55, 0.40, 0.08, 1)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    title:SetText("|cFFFFD100ToonAge Guide Browser|r")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    -- Guide count
    f.countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.countLabel:SetFont(STANDARD_TEXT_FONT, 9, "")
    f.countLabel:SetTextColor(0.55, 0.50, 0.40, 1)
    f.countLabel:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -8, -8)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "TAGuideBrowserScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -34)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(scroll:GetWidth() - 4)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    f.scroll = scroll
    f.content = content
    f.rows = {}
    self.frame = f

    self:RefreshBrowser()
    f:Show()
end

function GB:RefreshBrowser()
    if not self.frame then return end
    local content = self.frame.content
    local w = content:GetWidth()

    -- Clear existing rows
    for _, row in ipairs(self.frame.rows) do
        row:Hide()
        row:SetParent(nil)
    end
    self.frame.rows = {}

    local organized = self:OrganizeGuides()
    local y = -4
    local totalGuides = 0

    local QT = TA:GetModule("QuestTracker")
    local activeGuideID = QT and QT.guideID

    for _, exp in ipairs(EXPANSION_ORDER) do
        local guides = organized[exp]
        if guides and #guides > 0 then
            -- Expansion header
            local hdr = CreateFrame("Frame", nil, content)
            hdr:SetSize(w, 20)
            hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            local hdrText = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            hdrText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
            hdrText:SetText((EXPANSION_LABELS[exp] or exp) .. " |cFF888780(" .. #guides .. ")|r")
            hdrText:SetTextColor(1, 0.82, 0, 1)
            hdrText:SetPoint("LEFT", hdr, "LEFT", 4, 0)
            table.insert(self.frame.rows, hdr)
            y = y - 22

            -- Guide entries
            for _, g in ipairs(guides) do
                totalGuides = totalGuides + 1
                local isActive = (g.id == activeGuideID)

                local row = CreateFrame("Button", nil, content, "BackdropTemplate")
                row:SetSize(w - 8, 24)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
                row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})

                if isActive then
                    row:SetBackdropColor(0.08, 0.15, 0.05, 1)
                    row:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.8)
                else
                    row:SetBackdropColor(0.06, 0.06, 0.06, 1)
                    row:SetBackdropBorderColor(0.25, 0.20, 0.08, 0.4)
                end

                -- Title
                local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                titleText:SetFont(STANDARD_TEXT_FONT, 10, "")
                local displayTitle = g.title
                if #displayTitle > 35 then displayTitle = displayTitle:sub(1, 32) .. "..." end
                titleText:SetText((isActive and "|cFF4AFF7A► " or "  ") .. displayTitle .. "|r")
                titleText:SetPoint("LEFT", row, "LEFT", 6, 0)
                titleText:SetWidth(w - 120)
                titleText:SetJustifyH("LEFT")

                -- Quest count / completion %
                local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                infoText:SetFont(STANDARD_TEXT_FONT, 9, "")
                local pctColor = g.pct >= 100 and "|cFF4AFF7A" or g.pct > 0 and "|cFFFFD100" or "|cFF888780"
                infoText:SetText(string.format("%s%d%%|r |cFF888780(%d quests)|r", pctColor, g.pct, g.quests))
                infoText:SetPoint("RIGHT", row, "RIGHT", -6, 0)

                -- Click to select
                row:SetScript("OnClick", function()
                    if QT then
                        QT:SetGuide(g.id)
                        print(string.format("|cFFFFD100[ToonAge]|r Guide switched to: |cFFFFFFFF%s|r", g.title))
                        GB:RefreshBrowser()
                    end
                end)
                row:SetScript("OnEnter", function(f) f:SetBackdropColor(0.12, 0.10, 0.04, 1) end)
                row:SetScript("OnLeave", function(f)
                    if isActive then
                        f:SetBackdropColor(0.08, 0.15, 0.05, 1)
                    else
                        f:SetBackdropColor(0.06, 0.06, 0.06, 1)
                    end
                end)

                table.insert(self.frame.rows, row)
                y = y - 26
            end

            y = y - 6  -- gap between expansions
        end
    end

    -- Handle "Other" category
    if organized["Other"] and #organized["Other"] > 0 then
        local hdr = CreateFrame("Frame", nil, content)
        hdr:SetSize(w, 20)
        hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        local hdrText = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdrText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        hdrText:SetText("Other |cFF888780(" .. #organized["Other"] .. ")|r")
        hdrText:SetTextColor(0.7, 0.7, 0.7, 1)
        hdrText:SetPoint("LEFT", hdr, "LEFT", 4, 0)
        table.insert(self.frame.rows, hdr)
        y = y - 22

        for _, g in ipairs(organized["Other"]) do
            totalGuides = totalGuides + 1
            local row = CreateFrame("Button", nil, content, "BackdropTemplate")
            row:SetSize(w - 8, 24)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
            row:SetBackdropColor(0.06, 0.06, 0.06, 1)
            row:SetBackdropBorderColor(0.25, 0.20, 0.08, 0.4)

            local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleText:SetFont(STANDARD_TEXT_FONT, 10, "")
            titleText:SetText("  " .. g.title)
            titleText:SetPoint("LEFT", row, "LEFT", 6, 0)

            row:SetScript("OnClick", function()
                local QT2 = TA:GetModule("QuestTracker")
                if QT2 then QT2:SetGuide(g.id) end
                GB:RefreshBrowser()
            end)

            table.insert(self.frame.rows, row)
            y = y - 26
        end
    end

    content:SetHeight(math.abs(y) + 20)
    self.frame.countLabel:SetText(totalGuides .. " guides available")
end

-- ── Quest Log Hook — suggest guide when quest is tracked ──────────────────────

function GB:CheckTrackedQuest()
    -- Get the supertracked quest (the one the player clicked/focused)
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
                if step.questID == questID then return end  -- quest is in active guide
            end
        end
    end

    -- Find which guide has this quest
    local guideID = GI:FindGuideForQuest(questID)
    if guideID and guideID ~= QT.guideID then
        local guide = TA.Guides[guideID]
        local title = guide and guide.title or guideID
        print(string.format(
            "|cFFFFD100[ToonAge]|r Quest #%d belongs to |cFFFFFFFF%s|r — type |cFFFFD100/ta switchto %d|r or open Guide Browser.",
            questID, title, questID))
    end
end

-- ── Event handling ────────────────────────────────────────────────────────────

function GB:OnEvent(event, ...)
    if event == "SUPER_TRACKING_CHANGED" then
        self:CheckTrackedQuest()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function GB:Init()
    -- Register for super-tracking changes (when player clicks a quest in log)
    if C_SuperTrack then
        TA.eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────

GB.SlashCommands = {
    browser = function(self)
        self:ShowBrowser()
    end,

    switchto = function(self, msg)
        -- /ta switchto 12345 — switch to the guide containing quest 12345
        local questID = msg and tonumber(msg:match("%d+"))
        if not questID then
            print("|cFFFFD100[ToonAge]|r Usage: /ta switchto <questID>")
            return
        end
        local GI = TA:GetModule("GuideImporter")
        if not GI then return end
        local guideID = GI:FindGuideForQuest(questID)
        if guideID then
            local QT = TA:GetModule("QuestTracker")
            if QT then
                QT:SetGuide(guideID)
                local guide = TA.Guides[guideID]
                print(string.format("|cFFFFD100[ToonAge]|r Switched to: |cFFFFFFFF%s|r", guide and guide.title or guideID))
            end
        else
            print("|cFFFFD100[ToonAge]|r No guide found containing quest #" .. questID)
        end
    end,
}
