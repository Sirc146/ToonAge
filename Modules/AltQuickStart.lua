-- ToonAge/Modules/AltQuickStart.lua
-- "Quick Start" panel for altaholics: shows everything you need to know about
-- your current character on ONE screen, immediately on login.
--
-- Displays: spec/role, talent build with one-click import, top 5 rotation
-- spells as icons, gear ilvl + next upgrade path, and "what to do next" guidance.
--
-- Auto-shows on login if the character has been seen before but hasn't logged
-- in for 24+ hours (the "returning alt" heuristic). Can also be triggered
-- via right-click menu or /ta quickstart.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local AQS = {}
TA:RegisterModule("AltQuickStart", AQS)

-- ── Constants ─────────────────────────────────────────────────────────────────
local PANEL_W = 360
local PANEL_H = 420
local ICON_SIZE = 36
local MAX_ROTATION_ICONS = 5
local RETURNING_ALT_THRESHOLD = 86400  -- 24 hours in seconds

-- ── State ─────────────────────────────────────────────────────────────────────
AQS.frame = nil
AQS.shown = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetSpecDisplayInfo()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID, specName, _, specIcon, role = GetSpecializationInfo(specIndex)
    local _, className = UnitClass("player")
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]
    return {
        specID    = specID,
        specName  = specName,
        specIcon  = specIcon,
        role      = role,
        className = className,
        classHex  = classColor and classColor.colorStr or "ffffffff",
        level     = UnitLevel("player") or 1,
    }
end

local function GetGearSummary()
    local _, equipped = GetAverageItemLevel()
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80

    -- Determine gear milestone
    local milestone = "Leveling"
    local nextGoal  = "Reach max level"
    local playerLvl = UnitLevel("player") or 1

    if playerLvl >= maxLevel then
        if equipped >= 610 then
            milestone = "Mythic Raid Ready"
            nextGoal  = "Push M+ keys and raid"
        elseif equipped >= 590 then
            milestone = "Heroic Raid Ready"
            nextGoal  = "Normal raid or M+ for upgrades"
        elseif equipped >= 580 then
            milestone = "M+ / Delves Ready"
            nextGoal  = "Run Delves Tier 8+ and M0 dungeons"
        elseif equipped >= 560 then
            milestone = "Gearing Up"
            nextGoal  = "World quests, LFR, and Delves for ilvl"
        else
            milestone = "Fresh Max Level"
            nextGoal  = "Do world quests and heroic dungeons"
        end
    else
        nextGoal = string.format("Level to %d (currently %d)", maxLevel, playerLvl)
    end

    return {
        ilvl      = math.floor(equipped),
        milestone = milestone,
        nextGoal  = nextGoal,
        level     = playerLvl,
        maxLevel  = maxLevel,
    }
end

local function IsReturningAlt()
    if not TA.charDB then return false end
    local lastSeen = TA.charDB.lastLoginTime or 0
    local elapsed = time() - lastSeen
    return elapsed > RETURNING_ALT_THRESHOLD
end

-- ── Panel Creation ────────────────────────────────────────────────────────────

function AQS:CreatePanel()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "ToonAgeAltQuickStart", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    -- Apply modern glass backdrop
    if TA.Modern and TA.Modern.ApplyGlassBackdrop then
        TA.Modern:ApplyGlassBackdrop(f)
    else
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        f:SetBackdropColor(0.05, 0.05, 0.06, 0.95)
        f:SetBackdropBorderColor(0.30, 0.30, 0.35, 1.00)
    end

    f:Hide()
    self.frame = f
    return f
end

function AQS:PopulatePanel()
    local f = self.frame
    if not f then return end

    -- Clear previous content
    for _, region in ipairs({ f:GetRegions() }) do
        if region ~= f._glassFrost and region ~= f._glassShadow then
            region:Hide()
        end
    end
    for _, child in ipairs({ f:GetChildren() }) do
        if child ~= f._glassFrost and child ~= f._glassShadow then
            child:Hide()
            child:SetParent(nil)
        end
    end

    local spec = GetSpecDisplayInfo()
    local gear = GetGearSummary()
    if not spec then return end

    local y = -12
    local padL = 14
    local w = PANEL_W - 28

    -- ── Header: "Welcome back, [Class] [Spec]" ───────────────────────────────
    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    header:SetText(string.format("|c%s%s|r %s", spec.classHex, spec.className, spec.specName))
    header:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 18

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetFont(STANDARD_TEXT_FONT, 10, "")
    subtitle:SetText(string.format("Level %d  ·  %d ilvl  ·  %s", spec.level, gear.ilvl, gear.milestone))
    subtitle:SetTextColor(0.62, 0.59, 0.55, 1)
    subtitle:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 20

    -- ── Close button ──────────────────────────────────────────────────────────
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- "Don't show on login" — an actual checkbox.
    --
    -- Was a bare Button carrying a 9pt label coloured |cFF888780, the same grey
    -- this codebase uses everywhere for de-emphasised hint text, with no box, no
    -- border and no hover state. It read as a caption rather than a control, so
    -- the way to stop the panel appearing was effectively hidden on the panel
    -- itself. It was also one-way: clicking only ever set disabled = true, and
    -- nothing in the UI could turn it back on.
    local dontShow = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    dontShow:SetSize(22, 22)
    dontShow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)

    local dsLbl = dontShow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dsLbl:SetFont(STANDARD_TEXT_FONT, 11, "")
    dsLbl:SetText("Don't show on login")
    dsLbl:SetTextColor(0.88, 0.88, 0.86)
    dsLbl:SetPoint("RIGHT", dontShow, "LEFT", -2, 0)

    -- Reflect the stored value rather than always rendering unchecked, so the
    -- box shows the current setting when the panel is reopened.
    dontShow:SetChecked(
        (TA.charDB and TA.charDB.altQuickStart and TA.charDB.altQuickStart.disabled) and true or false)

    dontShow:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:SetText("Don't show on login", 1, 0.82, 0)
        GameTooltip:AddLine("Stops this panel opening by itself for this character.",
                            0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("You can still open it any time with /ta quickstart.",
                            0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    dontShow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    dontShow:SetScript("OnClick", function(selfBtn)
        local off = selfBtn:GetChecked() and true or false
        if TA.charDB then
            TA.charDB.altQuickStart = TA.charDB.altQuickStart or {}
            TA.charDB.altQuickStart.disabled = off
        end
        if off then
            f:Hide()
            local QT = TA:GetModule("QuestTracker")
            if QT and QT.ShowToast then QT:ShowToast("Quick Start disabled for this character") end
        end
    end)

    -- ── Divider ───────────────────────────────────────────────────────────────
    local div1 = f:CreateTexture(nil, "ARTWORK")
    div1:SetHeight(1)
    div1:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    div1:SetPoint("TOPRIGHT", f, "TOPRIGHT", -padL, y)
    div1:SetColorTexture(0.30, 0.30, 0.35, 0.5)
    y = y - 10

    -- ══════════════════════════════════════════════════════════════════════════
    -- SECTION 1: TALENT BUILD
    -- ══════════════════════════════════════════════════════════════════════════
    local talentHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    talentHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    talentHdr:SetText("RECOMMENDED BUILD")
    talentHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    talentHdr:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 16

    -- Get talent build from Data
    local T = TA.Data and TA.Data.Talents
    local buildName = "No build data"
    local buildDesc = ""
    local buildString = nil
    local matchPct = nil

    if T and T.GetBySpecID then
        local dbSpec = T:GetBySpecID(spec.specID)
        if dbSpec then
            -- Pick the best build for solo/leveling context
            local build = dbSpec.builds.solo or dbSpec.builds.mplus or dbSpec.builds.raid
            if build then
                buildName = build.name or "Recommended"
                buildDesc = build.desc or ""
                buildString = build.string

                -- Calculate match % against current talents
                if build.nodes and #build.nodes > 0 then
                    local TAPI = TA.TalentsAPI
                    if TAPI and TAPI.GetActiveTalentIDs then
                        local activeIDs = TAPI.GetActiveTalentIDs()
                        local activeSet = {}
                        for _, id in ipairs(activeIDs) do activeSet[id] = true end
                        local hits = 0
                        for _, id in ipairs(build.nodes) do
                            if activeSet[id] then hits = hits + 1 end
                        end
                        matchPct = math.floor((hits / #build.nodes) * 100)
                    end
                end
            end
        end
    end

    -- Check for user-saved custom build
    if TA.charDB and TA.charDB.customBuilds
       and TA.charDB.customBuilds[spec.specID]
       and TA.charDB.customBuilds[spec.specID].solo then
        buildString = TA.charDB.customBuilds[spec.specID].solo
        buildName = buildName .. " |cFF4AFF7A(Your Saved)|r"
    end

    local buildF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildF:SetFont(STANDARD_TEXT_FONT, 11, "")
    buildF:SetText(buildName)
    buildF:SetTextColor(1, 0.82, 0, 1)
    buildF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 14

    if buildDesc ~= "" then
        local descF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descF:SetFont(STANDARD_TEXT_FONT, 9, "")
        descF:SetText(buildDesc)
        descF:SetTextColor(0.62, 0.59, 0.55, 1)
        descF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        descF:SetWidth(w)
        descF:SetWordWrap(false)
        y = y - 12
    end

    if matchPct then
        local mColor = matchPct >= 80 and "|cFF4AFF7A" or matchPct >= 50 and "|cFFFFD100" or "|cFFFF4444"
        local matchF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        matchF:SetFont(STANDARD_TEXT_FONT, 9, "")
        matchF:SetText(mColor .. matchPct .. "% match|r with your current talents")
        matchF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        y = y - 14
    end

    -- One-click import button
    if buildString and buildString ~= "" then
        local importBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        importBtn:SetSize(140, 22)
        importBtn:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        importBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        importBtn:SetBackdropColor(0.06, 0.10, 0.06, 1)
        importBtn:SetBackdropBorderColor(0.29, 1.00, 0.48, 0.7)

        local impLbl = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        impLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        impLbl:SetText("\226\154\161 Load This Build")
        impLbl:SetTextColor(0.29, 1.00, 0.48, 1)
        impLbl:SetAllPoints(importBtn)
        impLbl:SetJustifyH("CENTER")

        local capturedString = buildString
        importBtn:SetScript("OnClick", function()
            if InCombatLockdown() then
                local QT = TA:GetModule("QuestTracker")
                if QT and QT.ShowToast then QT:ShowToast("Can't change talents in combat") end
                return
            end
            -- Try direct import via C_ClassTalents (Dragonflight+)
            if C_ClassTalents and C_ClassTalents.ImportLoadout then
                local configID = C_ClassTalents.GetActiveConfigID()
                if configID then
                    local ok, err = pcall(C_ClassTalents.ImportLoadout, capturedString)
                    if ok then
                        impLbl:SetText("\226\156\147 Loaded!")
                        impLbl:SetTextColor(0.29, 1.00, 0.48, 1)
                        C_Timer.After(2, function() impLbl:SetText("\226\154\161 Load This Build") end)
                    else
                        -- Fallback: copy to clipboard
                        AQS:CopyStringToClipboard(capturedString)
                    end
                else
                    AQS:CopyStringToClipboard(capturedString)
                end
            else
                AQS:CopyStringToClipboard(capturedString)
            end
        end)
        importBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.10, 0.16, 0.10, 1) end)
        importBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.06, 0.10, 0.06, 1) end)

        y = y - 28
    end

    y = y - 6

    -- ══════════════════════════════════════════════════════════════════════════
    -- SECTION 2: ROTATION PRIORITY (Top 5 spells as icons)
    -- ══════════════════════════════════════════════════════════════════════════
    local rotHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    rotHdr:SetText("ROTATION PRIORITY")
    rotHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    rotHdr:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 16

    local R = TA.Data and TA.Data.Rotations
    local rotData = R and R.Get and R:Get(spec.specID, "solo")
    local priorities = rotData and rotData.priorities or {}

    -- Show tip line if available
    if rotData and rotData.tip then
        local tipF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tipF:SetFont(STANDARD_TEXT_FONT, 9, "")
        tipF:SetText(rotData.tip)
        tipF:SetTextColor(0.55, 0.75, 0.90, 1)
        tipF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        tipF:SetWidth(w)
        tipF:SetWordWrap(true)
        local tipH = tipF:GetStringHeight() or 12
        y = y - tipH - 6
    end

    -- Render top 5 priority spell icons in a row
    local iconX = padL
    local shown = 0
    for _, entry in ipairs(priorities) do
        if shown >= MAX_ROTATION_ICONS then break end
        if not entry.isCD and not entry.isMajorCD then  -- skip cooldowns, show core rotation
            shown = shown + 1

            local iconFrame = CreateFrame("Frame", nil, f)
            iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
            iconFrame:SetPoint("TOPLEFT", f, "TOPLEFT", iconX, y)

            local tex = iconFrame:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints(iconFrame)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim icon borders

            -- Get spell icon (handles both modern C_Spell and legacy GetSpellInfo)
            local icon = nil
            if C_Spell and C_Spell.GetSpellInfo then
                local ok, info = pcall(C_Spell.GetSpellInfo, entry.spellID)
                if ok and info then icon = info.iconID end
            elseif GetSpellInfo then
                local ok, _, _, tex2 = pcall(GetSpellInfo, entry.spellID)
                if ok then icon = tex2 end
            end
            if not icon and C_Spell and C_Spell.GetSpellTexture then
                local ok2, tex3 = pcall(C_Spell.GetSpellTexture, entry.spellID)
                if ok2 then icon = tex3 end
            end
            tex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")

            -- Priority number badge
            local numBadge = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            numBadge:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            numBadge:SetText(tostring(shown))
            numBadge:SetTextColor(1, 0.82, 0, 1)
            numBadge:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)

            -- Tooltip on hover
            iconFrame:EnableMouse(true)
            iconFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(entry.name or "Spell", 1, 0.82, 0)
                if entry.why then
                    GameTooltip:AddLine(entry.why, 0.8, 0.8, 0.8, true)
                end
                if entry.condition then
                    GameTooltip:AddLine("When: " .. entry.condition, 0.55, 0.75, 0.90)
                end
                GameTooltip:Show()
            end)
            iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

            iconX = iconX + ICON_SIZE + 6
        end
    end

    if shown == 0 then
        local noRot = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noRot:SetFont(STANDARD_TEXT_FONT, 10, "")
        noRot:SetText("No rotation data for this spec yet.")
        noRot:SetTextColor(0.55, 0.50, 0.40, 1)
        noRot:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    end

    y = y - ICON_SIZE - 10

    -- Spell names below icons
    local nameRow = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameRow:SetFont(STANDARD_TEXT_FONT, 8, "")
    local names = {}
    local nameCount = 0
    for _, entry in ipairs(priorities) do
        if nameCount >= MAX_ROTATION_ICONS then break end
        if not entry.isCD and not entry.isMajorCD then
            nameCount = nameCount + 1
            names[#names + 1] = entry.name or "?"
        end
    end
    nameRow:SetText("|cFF888780" .. table.concat(names, "  →  ") .. "|r")
    nameRow:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    nameRow:SetWidth(w)
    nameRow:SetJustifyH("LEFT")
    y = y - 14

    -- ══════════════════════════════════════════════════════════════════════════
    -- SECTION 3: GEAR STATUS
    -- ══════════════════════════════════════════════════════════════════════════
    local div2 = f:CreateTexture(nil, "ARTWORK")
    div2:SetHeight(1)
    div2:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    div2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -padL, y)
    div2:SetColorTexture(0.30, 0.30, 0.35, 0.5)
    y = y - 10

    local gearHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gearHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    gearHdr:SetText("GEAR STATUS")
    gearHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    gearHdr:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 16

    local ilvlF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlF:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    ilvlF:SetText(tostring(gear.ilvl))
    ilvlF:SetTextColor(0.40, 0.75, 1.00, 1)
    ilvlF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)

    local ilvlLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
    ilvlLabel:SetText("  ilvl  ·  " .. gear.milestone)
    ilvlLabel:SetTextColor(0.62, 0.59, 0.55, 1)
    ilvlLabel:SetPoint("LEFT", ilvlF, "RIGHT", 4, 0)
    y = y - 24

    -- ══════════════════════════════════════════════════════════════════════════
    -- SECTION 4: WHAT TO DO NEXT (Cross-Module Intelligence)
    -- Pulls data from: Weekly, Gear, DungeonGear, Delves, QuestTracker, Rotation
    -- ══════════════════════════════════════════════════════════════════════════
    local div3 = f:CreateTexture(nil, "ARTWORK")
    div3:SetHeight(1)
    div3:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    div3:SetPoint("TOPRIGHT", f, "TOPRIGHT", -padL, y)
    div3:SetColorTexture(0.30, 0.30, 0.35, 0.5)
    y = y - 10

    local nextHdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nextHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    nextHdr:SetText("WHAT TO DO NEXT")
    nextHdr:SetTextColor(0.55, 0.40, 0.08, 1)
    nextHdr:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
    y = y - 16

    -- Build prioritized action list from cross-module data
    local actions = {}

    -- From QuestTracker: Is there an active guide? What step?
    local QT = TA:GetModule("QuestTracker")
    if QT and QT.guideID and TA.Guides and TA.Guides[QT.guideID] then
        local guide = TA.Guides[QT.guideID]
        local step = guide.steps[QT.stepIdx]
        local stepText = step and step.text or "Continue your guide"
        table.insert(actions, {
            priority = 1,
            icon = "|cFF4AFF7A→|r",
            text = "Guide: " .. (guide.title or ""),
            sub  = stepText,
        })
    elseif spec.level < gear.maxLevel then
        table.insert(actions, {
            priority = 1,
            icon = "|cFF4AFF7A→|r",
            text = "Level to " .. gear.maxLevel,
            sub  = "Open the Guide tab to pick a leveling guide.",
        })
    end

    -- From Weekly: Vault progress (max level only)
    if spec.level >= gear.maxLevel then
        local Weekly = TA:GetModule("Weekly")
        if Weekly and C_WeeklyRewards and C_WeeklyRewards.GetActivities then
            local vaultTypes = { {1, "Dungeons"}, {2, "Raid"}, {3, "Delves"} }
            local vaultDone = 0
            local vaultNeeded = nil
            for _, vt in ipairs(vaultTypes) do
                local ok, activities = pcall(C_WeeklyRewards.GetActivities, vt[1])
                if ok and activities and #activities > 0 then
                    -- Check first tier (easiest vault slot)
                    local tier1 = activities[1]
                    if tier1 and tier1.progress >= tier1.threshold then
                        vaultDone = vaultDone + 1
                    elseif not vaultNeeded then
                        local remaining = tier1.threshold - tier1.progress
                        vaultNeeded = string.format("%d more %s for vault slot", remaining, vt[2]:lower())
                    end
                end
            end
            if vaultDone < 3 and vaultNeeded then
                table.insert(actions, {
                    priority = 2,
                    icon = "|cFFFFD100★|r",
                    text = "Weekly Vault: " .. vaultDone .. "/3 slots filled",
                    sub  = vaultNeeded,
                })
            elseif vaultDone >= 3 then
                table.insert(actions, {
                    priority = 10,
                    icon = "|cFF4AFF7A✓|r",
                    text = "Weekly Vault: All 3 slots earned!",
                    sub  = "Check vault on reset day.",
                })
            end
        end

        -- From DungeonGear: biggest upgrade available
        local DG = TA:GetModule("DungeonGear")
        if DG and DG.GetBestUpgradeDungeon then
            local ok, dungeonName, upgradePct = pcall(DG.GetBestUpgradeDungeon, DG)
            if ok and dungeonName then
                table.insert(actions, {
                    priority = 3,
                    icon = "|cFF1EBCFF↑|r",
                    text = "Best dungeon for upgrades: " .. dungeonName,
                    sub  = string.format("+%d%% potential gear improvement", upgradePct or 0),
                })
            end
        end

        -- From Gear: any empty/very low slots?
        --
        -- Off Hand (17) is skipped when the Main Hand holds something that
        -- physically occupies both hands. A Survival Hunter with a polearm, or
        -- any Hunter with a bow, has no off hand to fill — reporting "Empty
        -- slot! Equip anything." there is advice that cannot be followed, and
        -- because an empty slot scores 0 and breaks the loop immediately, it
        -- also masked whatever the genuinely weakest slot was.
        --
        -- Gear.lua's RenderPlayerGrid already suppresses off-hand *upgrade
        -- suggestions* for the same reason (see its twoHandEquipped guard);
        -- this warning path was never given the same check.
        local mhLink = GetInventoryItemLink("player", 16)
        local mhEquipLoc = mhLink and select(9, U.GetItemInfo(mhLink)) or nil
        local twoHanded = mhEquipLoc == "INVTYPE_2HWEAPON"
                       or mhEquipLoc == "INVTYPE_RANGED"
                       or mhEquipLoc == "INVTYPE_RANGEDRIGHT"

        local lowestSlot = nil
        local lowestIlvl = 9999
        for slotID = 1, 17 do
            if slotID ~= 4                          -- skip shirt
               and not (slotID == 17 and twoHanded) -- no off hand to fill
            then
                local link = GetInventoryItemLink("player", slotID)
                if not link then
                    lowestSlot = slotID
                    lowestIlvl = 0
                    break
                else
                    local ilvl = GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(link) or 0
                    if ilvl < lowestIlvl then
                        lowestIlvl = ilvl
                        lowestSlot = slotID
                    end
                end
            end
        end
        if lowestSlot and lowestIlvl < gear.ilvl - 20 then
            local slotNames = {
                [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",
                [7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",[11]="Ring 1",
                [12]="Ring 2",[13]="Trinket 1",[14]="Trinket 2",[15]="Cloak",
                [16]="Main Hand",[17]="Off Hand",
            }
            local slotName = slotNames[lowestSlot] or ("Slot " .. lowestSlot)
            table.insert(actions, {
                priority = 4,
                icon = "|cFFFF9A1A!|r",
                text = "Weak slot: " .. slotName .. " (" .. lowestIlvl .. " ilvl)",
                sub  = lowestIlvl == 0 and "Empty slot! Equip anything." or "Prioritize replacing this piece.",
            })
        end
    end

    -- From Rotation: Is the prediction bar enabled?
    local Rotation = TA:GetModule("Rotation")
    if Rotation and TA.charDB and TA.charDB.predictBar and not TA.charDB.predictBar.visible then
        table.insert(actions, {
            priority = 8,
            icon = "|cFF888780⚡|r",
            text = "Rotation helper is hidden",
            sub  = "Right-click tracker → Show Arrow for combat guidance.",
        })
    end

    -- Sort by priority
    table.sort(actions, function(a, b) return a.priority < b.priority end)

    -- Render actions (max 4)
    local shownActions = 0
    for _, action in ipairs(actions) do
        if shownActions >= 4 then break end
        shownActions = shownActions + 1

        local actionF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        actionF:SetFont(STANDARD_TEXT_FONT, 10, "")
        actionF:SetText(action.icon .. " " .. action.text)
        actionF:SetTextColor(0.92, 0.90, 0.87, 1)
        actionF:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        actionF:SetWidth(w)
        actionF:SetWordWrap(false)
        y = y - 14

        if action.sub then
            local subF = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            subF:SetFont(STANDARD_TEXT_FONT, 9, "")
            subF:SetText("  " .. action.sub)
            subF:SetTextColor(0.55, 0.52, 0.45, 1)
            subF:SetPoint("TOPLEFT", f, "TOPLEFT", padL + 12, y)
            subF:SetWidth(w - 12)
            subF:SetWordWrap(true)
            local subH = subF:GetStringHeight() or 11
            y = y - subH - 4
        end
    end

    if shownActions == 0 then
        local noAction = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noAction:SetFont(STANDARD_TEXT_FONT, 10, "")
        noAction:SetText("|cFF4AFF7A→|r " .. gear.nextGoal)
        noAction:SetTextColor(0.92, 0.90, 0.87, 1)
        noAction:SetPoint("TOPLEFT", f, "TOPLEFT", padL, y)
        y = y - 16
    end

    -- Resize panel to fit content
    f:SetHeight(math.abs(y) + 30)
end

-- ── Clipboard helper (opens an edit box for copying talent strings) ────────────
function AQS:CopyStringToClipboard(str)
    if not str then return end
    -- Use the Talents module's safe copy frame if available
    local Talents = TA:GetModule("Talents")
    if Talents and Talents.OpenSafeCopyFrame then
        Talents:OpenSafeCopyFrame("Talent Build", str)
        return
    end
    -- Fallback: print to chat
    print("|cFFFFD100[ToonAge]|r Talent string (copy from chat):")
    print(str)
end

-- ── Show / Hide / Toggle ──────────────────────────────────────────────────────

function AQS:Show()
    self:CreatePanel()
    self:PopulatePanel()
    self.frame:Show()
    self.shown = true
end

function AQS:Hide()
    if self.frame then self.frame:Hide() end
    self.shown = false
end

function AQS:Toggle()
    if self.frame and self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function AQS:Init()
    -- Record login time for returning-alt detection
    if TA.charDB then
        TA.charDB.altQuickStart = TA.charDB.altQuickStart or {}
    end

    -- Check if this is a returning alt and auto-show the panel
    C_Timer.After(2, function()
        -- Skip if disabled by user
        if TA.charDB and TA.charDB.altQuickStart and TA.charDB.altQuickStart.disabled then
            return
        end

        -- Skip if player is in combat (shouldn't happen 2s after login but guard)
        if InCombatLockdown() then return end

        -- Check if this is a returning alt
        if IsReturningAlt() then
            AQS:Show()
        end

        -- Update last login time
        if TA.charDB then
            TA.charDB.lastLoginTime = time()
        end
    end)
end

-- ── Slash commands ────────────────────────────────────────────────────────────
AQS.SlashCommands = {
    quickstart = function(self) self:Toggle() end,
    qs         = function(self) self:Toggle() end,
}
