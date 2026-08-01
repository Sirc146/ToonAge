-- ToonAge/Modules/GuideBrowser.lua (Classic — MoP 50504)
-- Guide Browser: organized expansion/zone shelf for selecting guides.
-- Minimal API dependencies: CreateFrame, font strings, scroll frame.

local TA = ToonAge
local U  = TA.Utils

local GB = {}
TA:RegisterModule("GuideBrowser", GB)

GB.frame = nil

-- ── Expansion ordering ────────────────────────────────────────────────
local EXPANSION_ORDER = {
    "MistsOfPandaria", "Cataclysm", "WrathOfTheLichKing",
    "TheBurningCrusade", "Classic",
}

local EXPANSION_LABELS = {
    MistsOfPandaria = "Mists of Pandaria (5.x)",
    Cataclysm = "Cataclysm (4.x)",
    WrathOfTheLichKing = "Wrath of the Lich King (3.x)",
    TheBurningCrusade = "The Burning Crusade (2.x)",
    Classic = "Classic (1.x)",
}

-- ── Organize guides by expansion ──────────────────────────────────────

function GB:OrganizeGuides()
    local organized = {}

    for id, guide in pairs(TA.Guides or {}) do
        local expansion = "Other"
        local title = guide.title or id

        -- Guess expansion from guide metadata
        if guide.expansion then
            expansion = guide.expansion
        else
            local minLv = guide.minLevel or 1
            if minLv >= 85 then expansion = "MistsOfPandaria"
            elseif minLv >= 80 then expansion = "Cataclysm"
            elseif minLv >= 68 then expansion = "WrathOfTheLichKing"
            elseif minLv >= 58 then expansion = "TheBurningCrusade"
            else expansion = "Classic"
            end
        end

        -- Count quest completion using classic APIs
        local questCount, completedCount = 0, 0
        for _, step in ipairs(guide.steps or {}) do
            if step.questID then
                questCount = questCount + 1
                if IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(step.questID) then
                    completedCount = completedCount + 1
                end
            end
        end

        organized[expansion] = organized[expansion] or {}
        table.insert(organized[expansion], {
            id        = id,
            title     = title:gsub(" %(auto%)$", ""),
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

-- ── Browser frame ─────────────────────────────────────────────────────

function GB:ShowBrowser()
    if TA.UI then
        if not TA.UI:IsVisible() then TA.UI:Show() end
        TA.UI:SetTab("guide")
        return
    end

    -- Fallback standalone browser if main UI not available
    if self.frame then
        if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
        if self.frame:IsShown() then self:RefreshBrowser() end
        return
    end

    self:CreateBrowserFrame()
    self.frame:Show()
    self:RefreshBrowser()
end

function GB:CreateBrowserFrame()
    local f = CreateFrame("Frame", "TAGuideBrowserFrame", UIParent, "BackdropTemplate")
    f:SetSize(340, 420)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    f:SetBackdropColor(0.05, 0.04, 0.02, 0.97)
    f:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.85)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    title:SetText("|cFFFFD100ToonAge Guide Browser|r")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    -- Count label
    local countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countLabel:SetFont(STANDARD_TEXT_FONT, 9, "")
    countLabel:SetTextColor(0.6, 0.6, 0.6)
    countLabel:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, -8)
    f.countLabel = countLabel

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "TAGuideBrowserScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)

    f.scrollFrame = scrollFrame
    f.content = content
    f.rows = {}

    self.frame = f
end

function GB:RefreshBrowser()
    if not self.frame then return end
    local content = self.frame.content
    local w = content:GetWidth()

    -- Clear existing rows
    for _, row in ipairs(self.frame.rows or {}) do
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

                local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                titleText:SetFont(STANDARD_TEXT_FONT, 10, "")
                local displayTitle = g.title
                if #displayTitle > 35 then displayTitle = displayTitle:sub(1, 32) .. "..." end
                titleText:SetText((isActive and "|cFF4AFF7A> " or "  ") .. displayTitle .. "|r")
                titleText:SetPoint("LEFT", row, "LEFT", 6, 0)
                titleText:SetWidth(w - 120)
                titleText:SetJustifyH("LEFT")

                local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                infoText:SetFont(STANDARD_TEXT_FONT, 9, "")
                local pctColor = g.pct >= 100 and "|cFF4AFF7A" or g.pct > 0 and "|cFFFFD100" or "|cFF888780"
                infoText:SetText(string.format("%s%d%%|r |cFF888780(%d)|r", pctColor, g.pct, g.quests))
                infoText:SetPoint("RIGHT", row, "RIGHT", -6, 0)

                local guideID = g.id
                row:SetScript("OnClick", function()
                    if QT then
                        QT:SetGuide(guideID)
                        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[ToonAge]|r Guide: |cFFFFFFFF%s|r", g.title))
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
            y = y - 6
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

            local guideID = g.id
            row:SetScript("OnClick", function()
                local QT2 = TA:GetModule("QuestTracker")
                if QT2 then QT2:SetGuide(guideID) end
                GB:RefreshBrowser()
            end)

            table.insert(self.frame.rows, row)
            y = y - 26
        end
    end

    content:SetHeight(math.abs(y) + 20)
    if self.frame.countLabel then
        self.frame.countLabel:SetText(totalGuides .. " guides")
    end
end

-- ── Init ──────────────────────────────────────────────────────────────
function GB:Init()
    -- No event hooks needed for Classic browser (no C_SuperTrack)
end

-- ── Slash commands ────────────────────────────────────────────────────
GB.SlashCommands = {
    browser = function(self)
        self:ShowBrowser()
    end,
}
