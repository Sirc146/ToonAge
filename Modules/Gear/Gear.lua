-- ToonAge/Modules/Gear.lua (Classic — MoP 5.4.x / Interface 50504)
-- Gear scoring with stat weights. Core gear evaluation.
-- Adapted from Retail version:
--   - No corruption/domination sockets (retail-only systems)
--   - No C_Container (uses Classic globals)
--   - No C_Item.GetItemStats (uses GetItemStats global)
--   - No C_CurrencyInfo (MoP currencies handled differently)
--   - No Versatility stat
--   - Added Hit/Expertise to stat scoring
--   - No TooltipDataProcessor (uses legacy tooltip hooks)
--   - Uses TA.Data.StatWeights for weights

local TA   = ToonAge
local U    = TA.Utils
local SW   = TA.Data.StatWeights

local Gear = {}
TA:RegisterModule("Gear", Gear)

-- ── State ─────────────────────────────────────────────────────────────
Gear.frames       = {}
Gear.sideFrames   = {}
Gear.viewMode     = "player"
Gear.selectedSlot = nil
Gear.bagCache     = { time = 0, items = {} }

-- ── Slot definitions (canonical WoW inventory slot IDs) ───────────────
local CORE_GRID_SLOTS = {
    { slotID = 1,  name = "Head" },
    { slotID = 2,  name = "Neck" },
    { slotID = 3,  name = "Shoulder" },
    { slotID = 15, name = "Back",      isEnchantable = true },
    { slotID = 5,  name = "Chest",     isEnchantable = true },
    { slotID = 9,  name = "Wrist",     isEnchantable = true },
    { slotID = 10, name = "Hands",     isEnchantable = true },
    { slotID = 6,  name = "Waist" },
    { slotID = 7,  name = "Legs",      isEnchantable = true },
    { slotID = 8,  name = "Feet",      isEnchantable = true },
    { slotID = 11, name = "Ring 1",    isRing = true,    ringIdx = 1 },
    { slotID = 12, name = "Ring 2",    isRing = true,    ringIdx = 2 },
    { slotID = 13, name = "Trinket 1", isTrinket = true, triIdx  = 1 },
    { slotID = 14, name = "Trinket 2", isTrinket = true, triIdx  = 2 },
    { slotID = 16, name = "Main Hand", isEnchantable = true },
    { slotID = 17, name = "Off Hand",  isEnchantable = true },
}

-- ── Armor proficiency ─────────────────────────────────────────────────
local PRIMARY_ARMOR_TYPE = 1

local function ResolveArmorType()
    local _, cls = UnitClass("player")
    if     cls == "WARRIOR" or cls == "PALADIN" or cls == "DEATHKNIGHT" then return 4
    elseif cls == "HUNTER"  or cls == "SHAMAN"                          then return 3
    elseif cls == "ROGUE"   or cls == "DRUID"   or cls == "MONK"        then return 2
    end
    return 1  -- Cloth (Mage, Warlock, Priest)
end

-- ── Helpers ───────────────────────────────────────────────────────────
local function CleanProxyValue(val)
    if not val then return 0 end
    if type(val) == "number" then return val end
    return tonumber(tostring(val):match("([%d%.%-]+)")) or 0
end


-- ── Item scoring ──────────────────────────────────────────────────────
-- MoP stats: STR, AGI, INT, SPI, STAM, HIT, EXP, CRIT, HASTE, MASTERY
-- No Versatility, no Corruption, no Domination sockets.
local function CalculateItemScore(itemLink, specID, mode)
    if not itemLink then return 0 end

    -- GetItemStats is a global in Classic, returns a table of stat keys
    local rawStats = GetItemStats(itemLink) or {}
    local stats = {
        INT     = CleanProxyValue(rawStats["ITEM_MOD_INTELLECT_SHORT"]),
        AGI     = CleanProxyValue(rawStats["ITEM_MOD_AGILITY_SHORT"]),
        STR     = CleanProxyValue(rawStats["ITEM_MOD_STRENGTH_SHORT"]),
        SPI     = CleanProxyValue(rawStats["ITEM_MOD_SPIRIT_SHORT"]),
        STAM    = CleanProxyValue(rawStats["ITEM_MOD_STAMINA_SHORT"]),
        CRIT    = CleanProxyValue(rawStats["ITEM_MOD_CRIT_RATING_SHORT"]),
        HASTE   = CleanProxyValue(rawStats["ITEM_MOD_HASTE_RATING_SHORT"]),
        MASTERY = CleanProxyValue(rawStats["ITEM_MOD_MASTERY_RATING_SHORT"]),
        HIT     = CleanProxyValue(rawStats["ITEM_MOD_HIT_RATING_SHORT"]),
        EXP     = CleanProxyValue(rawStats["ITEM_MOD_EXPERTISE_RATING_SHORT"]),
    }

    local total = 0
    for _, v in pairs(stats) do total = total + v end

    if total == 0 then
        -- No recognized stat budget (proc trinkets, etc.) — fall back to ilvl
        local ilvl = U.GetItemIlvl(itemLink) or 0
        return ilvl * 3
    end

    return CleanProxyValue(SW:ScoreItem(stats, specID, mode))
end

-- Expose for tooltip hook
Gear.CalculateItemScore = CalculateItemScore


-- ── Bag scan for upgrades ─────────────────────────────────────────────
-- Classic uses global GetContainerNumSlots/GetContainerItemLink/GetContainerItemInfo
local function ScanBagsForUpgrades(slotID, specID, mode, currentScore, itemDef, claimedBags)
    local bestLink, bestBag, bestSlot = nil, nil, nil
    local bestScore = currentScore or 0

    if GetTime() - Gear.bagCache.time > 2.0 then
        Gear.bagCache.items = {}
        for bag = 0, 4 do
            local numSlots = U.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local link = U.GetContainerItemLink(bag, slot)
                if link then
                    local _, _, _, _, _, _, _, _, eLoc, _, _, cID, scID = GetItemInfo(link)
                    table.insert(Gear.bagCache.items, {
                        bag  = bag,
                        slot = slot,
                        link = link,
                        equipLoc       = eLoc,
                        itemClassID    = cID,
                        itemSubClassID = scID,
                    })
                end
            end
        end
        Gear.bagCache.time = GetTime()
    end

    for _, item in ipairs(Gear.bagCache.items) do
        local bagSlotKey = item.bag .. "_" .. item.slot
        local equipLoc = item.equipLoc

        if equipLoc then
            local isValid = false
            if     slotID == 1  and equipLoc == "INVTYPE_HEAD"      then isValid = true
            elseif slotID == 2  and equipLoc == "INVTYPE_NECK"      then isValid = true
            elseif slotID == 3  and equipLoc == "INVTYPE_SHOULDER"  then isValid = true
            elseif slotID == 15 and equipLoc == "INVTYPE_CLOAK"     then isValid = true
            elseif slotID == 5  and (equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE") then isValid = true
            elseif slotID == 9  and equipLoc == "INVTYPE_WRIST"     then isValid = true
            elseif slotID == 10 and equipLoc == "INVTYPE_HAND"      then isValid = true
            elseif slotID == 6  and equipLoc == "INVTYPE_WAIST"     then isValid = true
            elseif slotID == 7  and equipLoc == "INVTYPE_LEGS"      then isValid = true
            elseif slotID == 8  and equipLoc == "INVTYPE_FEET"      then isValid = true
            elseif itemDef.isRing    and equipLoc == "INVTYPE_FINGER"  then isValid = true
            elseif itemDef.isTrinket and equipLoc == "INVTYPE_TRINKET" then isValid = true
            elseif slotID == 16 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_2HWEAPON"
                                  or equipLoc == "INVTYPE_WEAPONMAINHAND"
                                  or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT") then isValid = true
            elseif slotID == 17 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND"
                                  or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE") then isValid = true
            end

            -- Reject wrong armor types (accessories bypass)
            if isValid and item.itemClassID == 4 then
                local isAccessory = equipLoc == "INVTYPE_NECK"    or equipLoc == "INVTYPE_CLOAK"
                                 or equipLoc == "INVTYPE_FINGER"  or equipLoc == "INVTYPE_TRINKET"
                                 or equipLoc == "INVTYPE_SHIELD"  or equipLoc == "INVTYPE_HOLDABLE"
                if not isAccessory and item.itemSubClassID ~= PRIMARY_ARMOR_TYPE then isValid = false end
            end

            if isValid then
                local score = CalculateItemScore(item.link, specID, mode)
                if score > bestScore and not claimedBags[bagSlotKey] then
                    bestScore = score
                    bestLink  = item.link
                    bestBag   = item.bag
                    bestSlot  = item.slot
                end
            end
        end
    end
    return bestLink, bestScore, bestBag, bestSlot
end

local function GetLiveEquippedLink(itemDef, unit)
    unit = unit or "player"
    if itemDef.isRing then
        return GetInventoryItemLink(unit, itemDef.ringIdx == 1 and 11 or 12)
    elseif itemDef.isTrinket then
        return GetInventoryItemLink(unit, itemDef.triIdx == 1 and 13 or 14)
    else
        return GetInventoryItemLink(unit, itemDef.slotID)
    end
end


-- ── Events ────────────────────────────────────────────────────────────
local bagRenderTimer = nil
local function ScheduleBagRender()
    if bagRenderTimer then return end
    bagRenderTimer = C_Timer.After(0.3, function()
        bagRenderTimer = nil
        if TA.UI and TA.UI.activeTab == "gear" and Gear.viewMode == "player" then
            Gear:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end)
end

function Gear:OnEvent(event, ...)
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE"
       or event == "UNIT_INVENTORY_CHANGED" or event == "GET_ITEM_INFO_RECEIVED" then
        self.bagCache.time = 0
        ScheduleBagRender()
    end
end

function Gear:Init()
    PRIMARY_ARMOR_TYPE = ResolveArmorType()
    if TA.charDB then
        TA.charDB.pvxMode = TA.charDB.pvxMode or "pve"
    end

    -- Legacy tooltip hooks (no TooltipDataProcessor in MoP)
    hooksecurefunc(GameTooltip, "SetBagItem", function(tt, bag, slot)
        local itemLink = U.GetContainerItemLink(bag, slot)
        if itemLink then self:InjectTooltipScore(tt, itemLink) end
    end)
    hooksecurefunc(GameTooltip, "SetInventoryItem", function(tt, unit, slot)
        local itemLink = GetInventoryItemLink(unit, slot)
        if itemLink then self:InjectTooltipScore(tt, itemLink) end
    end)
    hooksecurefunc(GameTooltip, "SetHyperlink", function(tt, link)
        if link and link:match("^item:") then
            self:InjectTooltipScore(tt, link)
        end
    end)
    hooksecurefunc(GameTooltip, "SetMerchantItem", function(tt, index)
        local itemLink = GetMerchantItemLink(index)
        if itemLink then self:InjectTooltipScore(tt, itemLink) end
    end)
    GameTooltip:HookScript("OnTooltipCleared", function(tt)
        tt._taInjected = nil
    end)
end


-- ── Tooltip Injection ──────────────────────────────────────────────────
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD      = 1,  INVTYPE_NECK      = 2,  INVTYPE_SHOULDER  = 3,
    INVTYPE_CHEST     = 5,  INVTYPE_ROBE      = 5,
    INVTYPE_WAIST     = 6,  INVTYPE_LEGS      = 7,  INVTYPE_FEET      = 8,
    INVTYPE_WRIST     = 9,  INVTYPE_HAND      = 10,
    INVTYPE_FINGER    = 11, INVTYPE_TRINKET   = 13,
    INVTYPE_CLOAK     = 15, INVTYPE_WEAPON    = 16,
    INVTYPE_SHIELD    = 17, INVTYPE_2HWEAPON  = 16,
    INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE  = 17, INVTYPE_RANGED    = 16,
    INVTYPE_RANGEDRIGHT = 16,
}

function Gear:InjectTooltipScore(tooltip, itemLink)
    if not itemLink then return end
    if not TA.charDB then return end
    if tooltip._taInjected == itemLink then return end
    tooltip._taInjected = itemLink

    local specID = U.GetPlayerSpec()
    if not specID then return end

    local pvxMode = (TA.charDB and TA.charDB.pvxMode) or "pve"
    local score   = CalculateItemScore(itemLink, specID, pvxMode)
    if not score or score <= 0 then return end

    local _, _, _, equipLoc = GetItemInfoInstant(itemLink)
    if not equipLoc or equipLoc == "" then return end
    local slotID = EQUIP_LOC_TO_SLOT[equipLoc]
    if not slotID then return end

    local equippedLink = GetInventoryItemLink("player", slotID)
    local equippedScore = 0
    if equippedLink then
        equippedScore = CalculateItemScore(equippedLink, specID, pvxMode)
    end

    -- For rings/trinkets, compare against the lower-scored slot
    if equipLoc == "INVTYPE_FINGER" then
        local link2 = GetInventoryItemLink("player", 12)
        if link2 then
            local score2 = CalculateItemScore(link2, specID, pvxMode)
            equippedScore = math.min(equippedScore, score2)
        end
    elseif equipLoc == "INVTYPE_TRINKET" then
        local link2 = GetInventoryItemLink("player", 14)
        if link2 then
            local score2 = CalculateItemScore(link2, specID, pvxMode)
            equippedScore = math.min(equippedScore, score2)
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("ToonAge Score", 0.40, 0.75, 1.00)

    local diff = score - equippedScore
    if equippedScore > 0 and diff > 0 then
        local pct = math.floor((diff / equippedScore) * 100)
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            "|cFF4AFF7A+" .. pct .. "% upgrade|r",
            0.92, 0.90, 0.87, 0.30, 0.92, 0.40)
    elseif equippedScore > 0 and diff < 0 then
        local pct = math.floor((math.abs(diff) / equippedScore) * 100)
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            "|cFFFF6666-" .. pct .. "% downgrade|r",
            0.92, 0.90, 0.87, 1.00, 0.40, 0.40)
    else
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            equippedScore > 0 and "|cFFAAAAAAAAequal|r" or "|cFFAAAAAAAAno comparison|r",
            0.92, 0.90, 0.87, 0.60, 0.60, 0.60)
    end

    tooltip:Show()
end


-- ══════════════════════════════════════════════════════════════════════════════
-- ── Render (Gear tab in the ToonAge panel) ────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════

function Gear:Render(content, sidebar)
    if not content then return end

    local specID = U.GetPlayerSpec()
    local pvxMode = (TA.charDB and TA.charDB.pvxMode) or "pve"

    -- Header
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Equipped Gear")

    local modeText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    modeText:SetText("Mode: " .. pvxMode:upper() .. (specID and (" | Spec: " .. specID) or ""))
    modeText:SetTextColor(0.6, 0.6, 0.6)

    -- List equipped items with scores
    local yOff = -50
    for slot = 1, 17 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local name, _, quality = GetItemInfo(link)
            if name then
                local score = CalculateItemScore(link, specID, pvxMode)
                local colour = U.QualityColour(quality or 1)

                local line = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                line:SetPoint("TOPLEFT", 10, yOff)
                line:SetText(string.format("%s%s|r  %s%d|r",
                    colour, name,
                    U.GREY, score and math.floor(score) or 0))
                yOff = yOff - 18
            end
        end
    end

    if yOff == -50 then
        local empty = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOPLEFT", 10, yOff)
        empty:SetText("No gear equipped.")
        empty:SetTextColor(0.6, 0.6, 0.6)
    end
end
