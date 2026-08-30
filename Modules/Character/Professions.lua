-- ToonAge/Modules/Professions.lua
-- Dynamic UI Renderer pulling from Data/Professions_Data.lua

local TA = ToonAge
local U = TA.Utils
local P = TA.Data.Professions

local Professions = {}
TA:RegisterModule("Professions", Professions)

Professions.frames = {}
Professions.sideFrames = {}
Professions.selectedSkillLine = nil

-- ── Event handling ───────────────────────────────────────────────────────

function Professions:OnEvent(event, ...)
    -- PLAYER_ENTERING_WORLD is intentionally NOT handled here.
    -- At that point TA:InitUI() has not yet been called, so TA.UI is nil and
    -- the render attempt would be a silent no-op (or worse, an error).
    -- Initial profession data is captured via OnLogin's charDB snapshot instead.
    if event == "SKILL_LINES_CHANGED" then
        if TA.UI and TA.UI.activeTab == "professions" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end
end

-- ── Render pipeline ──────────────────────────────────────────────────────

function Professions:Render(content, sidebar)
    for _, f in ipairs(self.frames) do
        f:Hide()
        f:SetParent(nil)
    end
    self.frames = {}

    local playerProfs = U.GetProfessions()

    -- Default selection to the first available profession if none selected
    if #playerProfs > 0 and not self.selectedSkillLine then
        self.selectedSkillLine = playerProfs[1].skillLine
    elseif #playerProfs == 0 then
        self.selectedSkillLine = nil
    end

    self:RenderSidebar(sidebar, playerProfs)
    self:RenderContent(content)
end

-- ── Sidebar: profession list ─────────────────────────────────────────────

function Professions:RenderSidebar(parent, playerProfs)
    for _, f in ipairs(self.sideFrames) do
        f:Hide()
        f:SetParent(nil)
    end
    self.sideFrames = {}

    local y = -8
    local w = parent:GetWidth() - 12

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    title:SetText("YOUR PROFESSIONS")
    title:SetTextColor(0.55, 0.40, 0.08, 1)
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    y = y - 16
    table.insert(self.sideFrames, title)

    if #playerProfs == 0 then
        local noProf = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noProf:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        noProf:SetText("No professions learned.")
        noProf:SetTextColor(0.5, 0.5, 0.5, 1)
        noProf:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        table.insert(self.sideFrames, noProf)
        return
    end

    for _, prof in ipairs(playerProfs) do
        local isSelected = (prof.skillLine == self.selectedSkillLine)

        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(w, 42)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        if isSelected then
            btn:SetBackdropColor(0.12, 0.09, 0.02, 1)
            btn:SetBackdropBorderColor(1, 0.82, 0, 0.8)
        else
            btn:SetBackdropColor(0.04, 0.04, 0.04, 1)
            btn:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.25)
        end

        local ico = btn:CreateTexture(nil, "ARTWORK")
        ico:SetSize(24, 24)
        ico:SetPoint("LEFT", btn, "LEFT", 8, 0)
        ico:SetTexture(prof.icon)
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        lbl:SetText(prof.name)
        lbl:SetTextColor(isSelected and 1 or 0.78, isSelected and 0.82 or 0.73, isSelected and 0 or 0.48, 1)
        lbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 40, -8)

        local rankLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rankLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        rankLbl:SetText("Skill: " .. prof.rank .. " / " .. prof.maxRank)
        rankLbl:SetTextColor(0.55, 0.44, 0.25, 1)
        rankLbl:SetPoint("TOPLEFT", btn, "TOPLEFT", 40, -22)

        btn:SetScript("OnClick", function()
            self.selectedSkillLine = prof.skillLine
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end)

        y = y - 46
        table.insert(self.sideFrames, btn)
    end
end

-- ── Content: era-specific advisor panel ──────────────────────────────────

function Professions:RenderContent(parent)
    if not self.selectedSkillLine then
        return
    end

    local y = -10
    local padL = 10
    local w = parent:GetWidth() - 20

    local profData = P:GetBySkillLine(self.selectedSkillLine) or P:GetSecondaryBySkillLine(self.selectedSkillLine)

    local function AddLabel(text, size, r, g, b, indent, wrapWidth)
        local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 11, "OUTLINE")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", padL + (indent or 0), y)
        f:SetWidth(wrapWidth or w - (indent or 0))
        f:SetJustifyH("LEFT")
        f:SetWordWrap(true)
        y = y - f:GetStringHeight() - 4
        table.insert(self.frames, f)
        return f
    end

    if not profData then
        AddLabel("Database metrics for this profession are currently unsupported or pending update.", 12, 1, 0.27, 0.27)
        return
    end

    -- Determine expansion era for this profession
    local era = profData.expansion or P:GetExpansionEra(self.selectedSkillLine)
    local eraInfo = P.EXPANSION_ERAS[era]
    local hasSpecs = eraInfo and eraInfo.hasSpecializations or false
    local hasGear = eraInfo and eraInfo.hasGear or false

    -- Title & Benefit
    AddLabel(string.upper(profData.name) .. " ADVISOR", 13, 1, 0.82, 0)
    if eraInfo then
        local eraNote = "|cFF4AAFFF" .. (eraInfo.label or era) .. " Profession System|r"
        if eraInfo.specUnlock then
            eraNote = eraNote .. "  |cFF888780(Specializations unlock at skill " .. eraInfo.specUnlock .. ")|r"
        end
        AddLabel(eraNote, 9, 0.4, 0.6, 0.9)
    end
    y = y - 4
    AddLabel(
        "|cFFFFD100Strategic Benefit:|r " .. (profData.personalBenefit or profData.benefit or "Utility profession."),
        10,
        0.78,
        0.73,
        0.48
    )
    y = y - 10

    -- Pre-Dragonflight professions: no specialization trees
    if not hasSpecs then
        AddLabel("|cFF888780" .. (eraInfo.label or era) .. " Profession System|r", 10, 0.5, 0.5, 0.5)
        AddLabel(
            "Linear skill progression (1–"
                .. (eraInfo.maxSkill or "?")
                .. "). No specialization trees, profession gear, or crafting stats.",
            9,
            0.4,
            0.4,
            0.4
        )
        if eraInfo.note then
            AddLabel("|cFF4AAFFF" .. eraInfo.note .. "|r", 9, 0.4, 0.6, 0.9)
        end
        AddLabel("", 6)
        AddLabel(
            "Specialization trees, profession gear (tool + accessories), and crafting stats (Resourcefulness, Inspiration, Multicraft) were introduced in |cFFFFD100Dragonflight|r and carry through |cFFFFD100The War Within|r and |cFFFFD100Midnight|r.",
            9,
            0.55,
            0.55,
            0.55
        )
        AddLabel("Specializations unlock at |cFFFFD100skill 25|r in those expansion tiers.", 9, 0.55, 0.55, 0.55)
        y = y - 10
        parent:SetHeight(math.abs(y) + 20)
        return
    end

    -- Standard vs Secondary Profession Fork
    if profData.type == "secondary" then
        AddLabel("Secondary Profession Logic", 11, 0.55, 0.40, 0.08)
        AddLabel(profData.firstPath, 10, 0.29, 1.00, 0.48)
        return
    end

    -- Gear Slots Array Mapping (Dragonflight+ only)
    if hasGear and profData.gearSlots then
        AddLabel("PROFESSION EQUIPMENT", 10, 0.55, 0.40, 0.08)
        y = y - 2

        -- Detect currently equipped profession gear via C_ProfSpec or profession slots
        local equippedGear = {}
        if C_TradeSkillUI and C_TradeSkillUI.GetProfessionSlots then
            local ok, slots = pcall(C_TradeSkillUI.GetProfessionSlots)
            if ok and slots then
                for _, slotInfo in ipairs(slots) do
                    local link = GetInventoryItemLink("player", slotInfo.slotIndex)
                    if link then
                        equippedGear[slotInfo.slotType or "unknown"] = {
                            link = link,
                            name = GetItemInfo(link) or "?",
                        }
                    end
                end
            end
        end

        for slotKey, slotInfo in pairs(profData.gearSlots) do
            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetSize(w, 48)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })

            -- Check if this slot has the right gear for the chosen path
            local isBestForPath = (slotInfo.bestForPath == nil) or (slotInfo.bestForPath == profData.firstPath)
            local equipped = equippedGear[slotKey]

            if isBestForPath then
                row:SetBackdropColor(0.02, 0.06, 0.02, 1)
                row:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.4)
            else
                row:SetBackdropColor(0.04, 0.04, 0.04, 1)
                row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.3)
            end
            table.insert(self.frames, row)

            local sTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sTitle:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            sTitle:SetText(slotInfo.name or slotKey:upper())
            sTitle:SetTextColor(0.55, 0.44, 0.25, 1)
            sTitle:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

            -- Show "Best for: [Path]" badge if applicable
            if slotInfo.bestForPath then
                local pathBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                pathBadge:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
                pathBadge:SetText("|cFF4AAFFF★ Best for: " .. slotInfo.bestForPath .. "|r")
                pathBadge:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
            end

            local sRec = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sRec:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            sRec:SetText("|cFFFFD100" .. slotInfo.recommended .. "|r")
            sRec:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -20)

            local sStats = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sStats:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            sStats:SetText(slotInfo.bonuses .. "  |cFF888780(" .. slotInfo.source .. ")|r")
            sStats:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -34)
            sStats:SetWidth(w - 20)

            y = y - 52
        end
        y = y - 10
    end

    -- Skill Milestone Progress (Dragonflight+ only)
    if hasSpecs and P.SPEC_MILESTONES then
        AddLabel("SKILL MILESTONES", 10, 0.55, 0.40, 0.08)
        y = y - 2

        -- Get current skill for this profession
        local currentSkill = 0
        local playerProfs = U.GetProfessions()
        for _, prof in ipairs(playerProfs) do
            if prof.skillLine == self.selectedSkillLine then
                currentSkill = prof.rank or 0
                break
            end
        end

        for _, milestone in ipairs(P.SPEC_MILESTONES) do
            local reached = (currentSkill >= milestone.skill)
            local isCurrent = not reached
                and (currentSkill < milestone.skill)
                and (milestone == P.SPEC_MILESTONES[1] or currentSkill >= (P.SPEC_MILESTONES[1].skill or 0))

            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetSize(w, 22)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            if reached then
                row:SetBackdropColor(0.02, 0.05, 0.02, 0.8)
                row:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.3)
            else
                row:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
                row:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.2)
            end
            table.insert(self.frames, row)

            local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            badge:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            if reached then
                badge:SetText("|cFF4AFF7A✓|r")
            elseif currentSkill > 0 and milestone.skill <= currentSkill + 25 then
                badge:SetText("|cFFFF9A1A→|r")
            else
                badge:SetText("|cFF555555○|r")
            end
            badge:SetPoint("LEFT", row, "LEFT", 6, 0)

            local skillLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            skillLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
            skillLbl:SetText("|cFFFFD100Skill " .. milestone.skill .. "|r  " .. milestone.label)
            skillLbl:SetTextColor(reached and 0.6 or 0.45, reached and 0.6 or 0.45, reached and 0.6 or 0.45, 1)
            skillLbl:SetPoint("LEFT", row, "LEFT", 22, 0)
            skillLbl:SetWidth(w - 30)

            y = y - 24
        end
        y = y - 8
    end

    -- Talent Nodes Priority Tracker (Dragonflight+ only)
    if hasSpecs and profData.talentTree then
        -- Use expansion-specific terminology if available
        local expTerms = profData.expansionTerms and profData.expansionTerms[profData.expansion or "Midnight"]
        local kpLabel = expTerms and expTerms.kpName or "Knowledge Points"
        AddLabel(string.upper(kpLabel) .. " DEPLOYMENT PATH", 10, 0.55, 0.40, 0.08)

        -- Show available specialization paths with correct expansion names
        if expTerms and expTerms.specPaths then
            local pathStr = "|cFF4AAFFF" .. table.concat(expTerms.specPaths, " · ") .. "|r"
            AddLabel("Paths: " .. pathStr, 9, 0.45, 0.45, 0.45)
            y = y - 2
        end

        if profData.talentTree.permanenceWarning then
            AddLabel("⚠ " .. profData.talentTree.permanenceWarning, 9, 1, 0.4, 0.4)
            y = y - 6
        end

        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(w, 40)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", padL, y)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        card:SetBackdropColor(0.04, 0.08, 0.04, 1)
        card:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.4)
        table.insert(self.frames, card)

        local pTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pTitle:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        pTitle:SetText("First Path Priority: " .. (profData.firstPath or "General Mastery"))
        pTitle:SetTextColor(0.29, 1.00, 0.48, 1)
        pTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -6)

        local pDesc = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pDesc:SetFont(STANDARD_TEXT_FONT, 9)
        pDesc:SetText(profData.firstPathReason or "Critical early expansion progression.")
        pDesc:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -20)
        pDesc:SetWidth(w - 20)
        pDesc:SetWordWrap(true)
        pDesc:SetJustifyH("LEFT")

        y = y - math.max(46, pDesc:GetStringHeight() + 30)
    end

    parent:SetHeight(math.abs(y) + 20)
end
