-- ToonAge/Modules/QuestRewardAdvisor.lua
-- Overlays stat-weight gear scores on quest reward items at the QUEST_COMPLETE
-- frame. Highlights the best reward choice with a green glow border and shows
-- percentage vs equipped for each equippable reward.
--
-- Design decisions:
--   • Uses ToonAge's Gear.CalculateItemScore for stat-weight scoring.
--   • Current spec only — uses GetSpecialization() / GetSpecializationInfo().
--   • Non-equipment rewards (gold, consumables) are skipped (no overlay).
--   • Items that haven't loaded yet use Item:CreateFromItemLink() retry pattern.
--   • Overlays are cleaned up on QUEST_FINISHED.
--   • All external calls wrapped in pcall for resilience.

local TA = ToonAge
local U  = TA.Utils

local QuestRewardAdvisor = {}
TA:RegisterModule("QuestRewardAdvisor", QuestRewardAdvisor)

-- ── Constants ─────────────────────────────────────────────────────────────────
local GOLD_COLOR     = { r = 1.0, g = 0.82, b = 0.0 }
local GREEN_COLOR    = { r = 0.29, g = 1.0, b = 0.48 }
local DIM_ALPHA      = 0.55
local MAX_RETRIES    = 5
local RETRY_INTERVAL = 0.1  -- seconds between item-load retries

-- ── Equip location lookup (mirrors TooltipScorer/AutoEquip) ───────────────────
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD            = { 1 },
    INVTYPE_NECK            = { 2 },
    INVTYPE_SHOULDER        = { 3 },
    INVTYPE_CHEST           = { 5 },
    INVTYPE_ROBE            = { 5 },
    INVTYPE_WAIST           = { 6 },
    INVTYPE_LEGS            = { 7 },
    INVTYPE_FEET            = { 8 },
    INVTYPE_WRIST           = { 9 },
    INVTYPE_HAND            = { 10 },
    INVTYPE_FINGER          = { 11, 12 },
    INVTYPE_TRINKET         = { 13, 14 },
    INVTYPE_CLOAK           = { 15 },
    INVTYPE_WEAPON          = { 16, 17 },
    INVTYPE_2HWEAPON        = { 16 },
    INVTYPE_WEAPONMAINHAND  = { 16 },
    INVTYPE_WEAPONOFFHAND   = { 17 },
    INVTYPE_HOLDABLE        = { 17 },
    INVTYPE_SHIELD          = { 17 },
    INVTYPE_RANGED          = { 16 },
    INVTYPE_RANGEDRIGHT     = { 16 },
}

-- ── State ─────────────────────────────────────────────────────────────────────
local overlayFrames = {}   -- { [index] = frame }
local retryTimer    = nil
local retryCount    = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function IsEnabled()
    return TA.db
        and TA.db.questRewardAdvisor
        and TA.db.questRewardAdvisor.enabled
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = GetSpecializationInfo(specIndex)
    return specID
end

--- Returns whether an item link corresponds to equippable gear.
local function IsEquipment(itemLink)
    if not itemLink then return false end
    local ok, _, _, _, _, _, _, _, _, equipLoc = pcall(C_Item.GetItemInfo or GetItemInfo, itemLink)
    if not ok then return false end
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_BAG" or equipLoc == "INVTYPE_AMMO" then
        return false
    end
    return EQUIP_LOC_TO_SLOT[equipLoc] ~= nil
end

--- Get the best equipped score across all slots that an item could go into.
local function GetEquippedScore(itemLink, specID)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    if not equipLoc then return 0 end
    local slots = EQUIP_LOC_TO_SLOT[equipLoc]
    if not slots then return 0 end

    local Gear = TA:GetModule("Gear")
    if not Gear or not Gear.CalculateItemScore then return 0 end

    local best = 0
    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            local ok, score = pcall(Gear.CalculateItemScore, equippedLink, specID, "pve")
            if ok and type(score) == "number" and score > best then
                best = score
            end
        end
    end
    return best
end

-- ── Overlay Frame Management ──────────────────────────────────────────────────

--- Creates or retrieves a cached overlay frame for a given reward button index.
local function GetOverlayFrame(index)
    if overlayFrames[index] then
        return overlayFrames[index]
    end

    local overlay = CreateFrame("Frame", "TAQuestRewardOverlay" .. index, UIParent, "BackdropTemplate")
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(10)

    -- Score text at the bottom
    overlay.scoreText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.scoreText:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 2)
    overlay.scoreText:SetTextColor(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b)

    -- Percentage text (upgrade/downgrade vs equipped)
    overlay.pctText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.pctText:SetPoint("TOP", overlay, "TOP", 0, -2)
    overlay.pctText:SetFont(overlay.pctText:GetFont(), 10)

    -- "★ BEST" label
    overlay.bestLabel = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    overlay.bestLabel:SetPoint("TOP", overlay, "TOP", 0, 12)
    overlay.bestLabel:SetTextColor(GREEN_COLOR.r, GREEN_COLOR.g, GREEN_COLOR.b)
    overlay.bestLabel:SetText("\226\152\133 BEST")
    overlay.bestLabel:Hide()

    -- Green glow border (highlight texture)
    overlay.glowBorder = overlay:CreateTexture(nil, "OVERLAY")
    overlay.glowBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    overlay.glowBorder:SetBlendMode("ADD")
    overlay.glowBorder:SetVertexColor(GREEN_COLOR.r, GREEN_COLOR.g, GREEN_COLOR.b, 0.7)
    overlay.glowBorder:SetAllPoints(overlay)
    overlay.glowBorder:Hide()

    -- Dim texture for non-best items
    overlay.dimTexture = overlay:CreateTexture(nil, "OVERLAY")
    overlay.dimTexture:SetColorTexture(0, 0, 0, 1 - DIM_ALPHA)
    overlay.dimTexture:SetAllPoints(overlay)
    overlay.dimTexture:Hide()

    overlay:Hide()
    overlayFrames[index] = overlay
    return overlay
end

--- Resets an overlay frame to a clean state.
local function ResetOverlay(overlay)
    overlay.scoreText:SetText("")
    overlay.pctText:SetText("")
    overlay.bestLabel:Hide()
    overlay.glowBorder:Hide()
    overlay.dimTexture:Hide()
    overlay:Hide()
end

--- Hides and resets all overlays.
local function HideAllOverlays()
    for _, overlay in pairs(overlayFrames) do
        ResetOverlay(overlay)
    end
end

-- ── Core Scoring Logic ────────────────────────────────────────────────────────

--- Scores all quest reward choices and applies overlays.
local function ScoreRewards()
    if not IsEnabled() then return end

    local specID = GetCurrentSpecID()
    if not specID then return end

    local Gear = TA:GetModule("Gear")
    if not Gear or not Gear.CalculateItemScore then return end

    local numChoices = GetNumQuestChoices()
    if not numChoices or numChoices == 0 then return end

    -- Gather scores for all equippable choices
    local scores = {}         -- { [index] = { score, pct, isEquip } }
    local bestIndex = nil
    local bestScore = -1
    local pendingLoad = false

    for i = 1, numChoices do
        local itemLink = GetQuestItemLink("choice", i)

        -- Item may not be cached yet
        if not itemLink then
            pendingLoad = true
            scores[i] = { score = 0, pct = 0, isEquip = false }
        elseif not IsEquipment(itemLink) then
            scores[i] = { score = 0, pct = 0, isEquip = false }
        else
            local ok, itemScore = pcall(Gear.CalculateItemScore, itemLink, specID, "pve")
            if not ok or type(itemScore) ~= "number" then
                itemScore = 0
            end

            local equippedScore = GetEquippedScore(itemLink, specID)
            local pct = 0
            if equippedScore > 0 then
                pct = ((itemScore - equippedScore) / equippedScore) * 100
            elseif itemScore > 0 then
                pct = 100  -- empty slot = guaranteed upgrade
            end

            scores[i] = { score = itemScore, pct = pct, isEquip = true }

            if itemScore > bestScore then
                bestScore = itemScore
                bestIndex = i
            end
        end
    end

    -- If any item links weren't loaded, retry
    if pendingLoad then
        RetryScoring()
        return
    end

    -- Apply overlays
    for i = 1, numChoices do
        local data = scores[i]
        if not data.isEquip then
            -- Non-equipment: no overlay
            local overlay = overlayFrames[i]
            if overlay then ResetOverlay(overlay) end
        else
            local button = _G["QuestInfoRewardsFrameQuestInfoItem" .. i]
            if not button then
                -- Fallback: try QuestInfoItem pattern
                button = QuestInfoRewardsFrame and QuestInfoRewardsFrame["QuestInfoItem" .. i]
            end

            if button and button:IsVisible() then
                local overlay = GetOverlayFrame(i)
                ResetOverlay(overlay)

                -- Anchor overlay to the reward button
                overlay:ClearAllPoints()
                overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
                overlay:SetParent(button)
                overlay:SetFrameLevel(button:GetFrameLevel() + 5)

                -- Score text
                overlay.scoreText:SetText(string.format("%.0f", data.score))
                overlay.scoreText:SetTextColor(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b)

                -- Percentage text
                if data.pct >= 100 then
                    overlay.pctText:SetText("|cFF4AFF7ANew slot!|r")
                elseif data.pct > 0 then
                    overlay.pctText:SetText(string.format("|cFF4AFF7A+%.1f%%|r", data.pct))
                elseif data.pct < -1 then
                    overlay.pctText:SetText(string.format("|cFFFF4444%.1f%%|r", data.pct))
                else
                    overlay.pctText:SetText("|cFFAAAAAAAA~0%%|r")
                end

                -- Best item highlight
                if i == bestIndex and numChoices > 1 then
                    overlay.bestLabel:Show()
                    overlay.glowBorder:Show()
                elseif data.isEquip then
                    -- Non-best equippable items get subtle dimming
                    overlay.dimTexture:Show()
                end

                overlay:Show()
            end
        end
    end
end

--- Retry scoring for items that haven't loaded yet.
function RetryScoring()
    retryCount = retryCount + 1
    if retryCount > MAX_RETRIES then
        retryCount = 0
        -- Give up gracefully — score with whatever data we have
        return
    end

    -- Try using Item:CreateFromItemLink for async load
    local numChoices = GetNumQuestChoices()
    local allLoaded = true

    for i = 1, numChoices do
        local itemLink = GetQuestItemLink("choice", i)
        if not itemLink then
            allLoaded = false
            -- Attempt async load via the quest item info API
            local ok, _ = pcall(function()
                GetQuestItemInfo("choice", i)
            end)
        end
    end

    if allLoaded then
        retryCount = 0
        ScoreRewards()
        return
    end

    -- Schedule another attempt
    if retryTimer then
        retryTimer:Cancel()
    end

    retryTimer = C_Timer.NewTimer(RETRY_INTERVAL, function()
        retryTimer = nil
        -- Re-check if frame is still visible
        if QuestFrame and QuestFrame:IsVisible() then
            ScoreRewards()
        else
            retryCount = 0
        end
    end)
end

-- ── Event Handling ────────────────────────────────────────────────────────────

function QuestRewardAdvisor:OnEvent(event, ...)
    if event == "QUEST_COMPLETE" then
        if not IsEnabled() then return end
        retryCount = 0
        -- Slight delay to let QuestInfoRewardsFrame populate its buttons
        C_Timer.After(0.05, function()
            local ok, err = pcall(ScoreRewards)
            if not ok and TA.Debug then
                TA.Debug("QuestRewardAdvisor: ScoreRewards error: " .. tostring(err))
            end
        end)
    elseif event == "QUEST_FINISHED" then
        -- Clean up all overlays when quest frame closes
        HideAllOverlays()
        retryCount = 0
        if retryTimer then
            retryTimer:Cancel()
            retryTimer = nil
        end
    end
end

-- ── Initialization ────────────────────────────────────────────────────────────

function QuestRewardAdvisor:Init()
    -- Ensure saved variable defaults
    if not TA.db then TA.db = {} end
    if not TA.db.questRewardAdvisor then
        TA.db.questRewardAdvisor = { enabled = true }
    end

    -- Register events via the shared ToonAge event frame
    TA.eventFrame:RegisterEvent("QUEST_COMPLETE")
    TA.eventFrame:RegisterEvent("QUEST_FINISHED")
end
