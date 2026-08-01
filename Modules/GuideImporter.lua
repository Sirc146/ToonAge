-- ToonAge/Modules/GuideImporter.lua (Classic — MoP 50504)
-- Import guides from text input or BtWQuests (if available).
-- Pure string parsing + UI. No retail-specific API dependencies.

local TA = ToonAge
local U  = TA.Utils

local GI = {}
TA:RegisterModule("GuideImporter", GI)

-- ── State ─────────────────────────────────────────────────────────────
GI.questToGuide = {}   -- { [questID] = guideID }
GI.imported     = 0

-- ── Text-based guide import (paste from clipboard) ────────────────────
-- Format: one step per line
--   HEADER: title=Guide Title|zone=123|minLevel=1|maxLevel=90|faction=Horde
--   pickup|questID=12345|Accept the quest|x=0.5|y=0.3|map=123
--   turnin|questID=12345|Turn in quest|x=0.6|y=0.4|map=123
--   waypoint|Go to the cave|x=0.45|y=0.55|map=123

local function ParseHeaderLine(line)
    local guide = { steps = {} }
    for key, val in line:gmatch("(%w+)=([^|]+)") do
        if key == "title" then guide.title = val
        elseif key == "zone" then guide.zone = tonumber(val) or 0
        elseif key == "minLevel" then guide.minLevel = tonumber(val) or 1
        elseif key == "maxLevel" then guide.maxLevel = tonumber(val) or 90
        elseif key == "faction" then guide.faction = val
        elseif key == "id" then guide.id = val
        elseif key == "nextGuide" then guide.nextGuide = val
        end
    end
    return guide
end

local function ParseStepLine(line)
    -- Format: type|key=val|key=val|text
    local parts = {}
    for part in line:gmatch("[^|]+") do
        table.insert(parts, part)
    end
    if #parts < 1 then return nil end

    local step = {}
    step.type = parts[1]:match("^%s*(.-)%s*$")  -- trim

    local textParts = {}
    for i = 2, #parts do
        local key, val = parts[i]:match("^(%w+)=(.+)$")
        if key then
            if key == "questID" then step.questID = tonumber(val)
            elseif key == "x" then
                step.coord = step.coord or { map = 0, x = 0, y = 0 }
                step.coord.x = tonumber(val) or 0
            elseif key == "y" then
                step.coord = step.coord or { map = 0, x = 0, y = 0 }
                step.coord.y = tonumber(val) or 0
            elseif key == "map" then
                step.coord = step.coord or { map = 0, x = 0, y = 0 }
                step.coord.map = tonumber(val) or 0
            elseif key == "objectiveIndex" then step.objectiveIndex = tonumber(val)
            elseif key == "range" then step.range = tonumber(val)
            elseif key == "questItem" then step.questItem = tonumber(val)
            elseif key == "class" then step.class = val
            elseif key == "race" then step.race = val
            elseif key == "faction" then step.faction = val
            elseif key == "spec" then step.spec = val
            elseif key == "minLevel" then step.minLevel = tonumber(val)
            elseif key == "reward" then step.reward = tonumber(val)
            end
        else
            table.insert(textParts, parts[i])
        end
    end

    step.text = table.concat(textParts, " ")
    if step.text == "" then step.text = step.type or "Step" end

    return step
end

function GI:ImportFromText(text)
    if not text or text == "" then return nil, "Empty input" end

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")  -- trim
        if line ~= "" and not line:match("^#") and not line:match("^%-%-") then
            table.insert(lines, line)
        end
    end

    if #lines == 0 then return nil, "No valid lines found" end

    -- First line should be header
    local firstLine = lines[1]
    local guide
    if firstLine:match("^HEADER:") or firstLine:match("title=") then
        guide = ParseHeaderLine(firstLine)
        table.remove(lines, 1)
    else
        guide = { steps = {}, title = "Imported Guide", minLevel = 1, maxLevel = 90 }
    end

    if not guide.title or guide.title == "" then
        guide.title = "Imported Guide"
    end
    guide.id = guide.id or ("imported_" .. time())

    -- Parse step lines
    for _, line in ipairs(lines) do
        local step = ParseStepLine(line)
        if step and step.type then
            table.insert(guide.steps, step)
        end
    end

    if #guide.steps == 0 then
        return nil, "No valid steps parsed"
    end

    -- Register the guide
    guide._imported = true
    guide._source = "TextImport"
    TA.Guides[guide.id] = guide
    TA.GuideData = TA.GuideData or {}
    TA.GuideData[guide.id] = guide

    -- Build reverse lookup
    for _, step in ipairs(guide.steps) do
        if step.questID then
            self.questToGuide[step.questID] = guide.id
        end
    end

    self.imported = self.imported + 1
    return guide, nil
end

-- ── Quest-to-Guide lookup ─────────────────────────────────────────────

function GI:FindGuideForQuest(questID)
    if self.questToGuide[questID] then
        return self.questToGuide[questID]
    end

    -- Fallback: scan all guides
    for id, guide in pairs(TA.Guides or {}) do
        for _, step in ipairs(guide.steps) do
            if step.questID == questID then
                self.questToGuide[questID] = id
                return id
            end
        end
    end

    return nil
end

-- ── Import UI (paste box) ─────────────────────────────────────────────

function GI:ShowImportUI()
    if self.importFrame then
        self.importFrame:Show()
        return
    end

    local f = CreateFrame("Frame", "TAGuideImportFrame", UIParent, "BackdropTemplate")
    f:SetSize(450, 350)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
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
    title:SetText("|cFFFFD100Import Guide from Text|r")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)

    -- Instructions
    local instr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instr:SetFont(STANDARD_TEXT_FONT, 9, "")
    instr:SetText("|cFF888780Paste guide text below. First line: HEADER with title=...|zone=...|r")
    instr:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -28)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    -- Scroll frame for edit box
    local scrollFrame = CreateFrame("ScrollFrame", "TAGuideImportScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -46)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 44)

    local editBox = CreateFrame("EditBox", "TAGuideImportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)

    -- Status line
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status:SetFont(STANDARD_TEXT_FONT, 10, "")
    status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 14)
    status:SetTextColor(0.6, 0.6, 0.6)
    f.statusLabel = status

    -- Import button
    local importBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    importBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    importBtn:SetBackdropColor(0.18, 0.13, 0.01, 0.90)
    importBtn:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.85)

    local importLbl = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    importLbl:SetText("|cFFFFD100Import|r")
    importLbl:SetAllPoints(importBtn)
    importLbl:SetJustifyH("CENTER")

    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local guide, err = GI:ImportFromText(text)
        if guide then
            status:SetText("|cFF4AFF7AImported: " .. guide.title .. " (" .. #guide.steps .. " steps)|r")
            -- Auto-select the imported guide
            local QT = TA:GetModule("QuestTracker")
            if QT then QT:SetGuide(guide.id) end
        else
            status:SetText("|cFFFF4444Error: " .. (err or "unknown") .. "|r")
        end
    end)

    self.importFrame = f
end

-- ── Init ──────────────────────────────────────────────────────────────

function GI:Init()
    -- Build reverse quest-to-guide lookup from existing guides
    for id, guide in pairs(TA.Guides or {}) do
        for _, step in ipairs(guide.steps or {}) do
            if step.questID then
                self.questToGuide[step.questID] = id
            end
        end
    end
end

-- ── Slash commands ────────────────────────────────────────────────────

GI.SlashCommands = {
    import = function(self)
        self:ShowImportUI()
    end,

    suggest = function(self)
        -- Suggest guide from quest log using classic API
        local activeQuests = {}
        local numEntries = GetNumQuestLogEntries()
        for i = 1, numEntries do
            local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            if not isHeader and questID and questID > 0 then
                activeQuests[questID] = true
            end
        end

        local bestID, bestCount = nil, 0
        for id, guide in pairs(TA.Guides or {}) do
            local matches = 0
            for _, step in ipairs(guide.steps) do
                if step.questID and activeQuests[step.questID] then
                    matches = matches + 1
                end
            end
            if matches > bestCount then
                bestCount = matches
                bestID = id
            end
        end

        if bestID then
            local guide = TA.Guides[bestID]
            TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[ToonAge]|r Best match: |cFFFFFFFF%s|r (%d overlaps)",
                guide and guide.title or bestID, bestCount))
            local QT = TA:GetModule("QuestTracker")
            if QT then QT:SetGuide(bestID) end
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r No matching guide for your quest log.")
        end
    end,
}
