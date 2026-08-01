-- CharacterAdvisor/Modules/Gear.lua
-- Pawn x GearLens Hybrid: Armor Strictness, API Cache Fallbacks, & Target Scouter

local CA = CharacterAdvisor
local U  = CA.Utils
local SW = CA.Data.StatWeights

local Gear = {}
CA:RegisterModule("Gear", Gear)

Gear.frames       = {}
Gear.sideFrames   = {}
Gear.pvxMode      = "pve"
Gear.viewMode     = "player"
Gear.selectedSlot = nil

local CORE_GRID_SLOTS = {
    { slotID = 1,  name = "Head" },
    { slotID = 2,  name = "Neck" },
    { slotID = 3,  name = "Shoulder" },
    { slotID = 15, name = "Back", isEnchantable = true },
    { slotID = 5,  name = "Chest", isEnchantable = true },
    { slotID = 8,  name = "Wrist", isEnchantable = true },
    { slotID = 9,  name = "Hands" },
    { slotID = 10, name = "Waist" },
    { slotID = 11, name = "Legs", isEnchantable = true },
    { slotID = 12, name = "Feet", isEnchantable = true },
    { slotID = 11, name = "Ring 1", isRing = true, ringIdx = 1, isEnchantable = true },
    { slotID = 12, name = "Ring 2", isRing = true, ringIdx = 2, isEnchantable = true },
    { slotID = 13, name = "Trinket 1", isTrinket = true, triIdx = 1 },
    { slotID = 14, name = "Trinket 2", isTrinket = true, triIdx = 2 },
    { slotID = 16, name = "Main Hand", isEnchantable = true },
    { slotID = 17, name = "Off Hand", isEnchantable = true },
}

-- Strict Armor Proficiency Logic
local _, playerClass = UnitClass("player")
local PRIMARY_ARMOR_TYPE = 1 
if playerClass == "WARRIOR" or playerClass == "PALADIN" or playerClass == "DEATHKNIGHT" then PRIMARY_ARMOR_TYPE = 4
elseif playerClass == "HUNTER" or playerClass == "SHAMAN" or playerClass == "EVOKER" then PRIMARY_ARMOR_TYPE = 3
elseif playerClass == "ROGUE" or playerClass == "DRUID" or playerClass == "MONK" or playerClass == "DEMONHUNTER" then PRIMARY_ARMOR_TYPE = 2 end

function Gear:OnEvent(event, ...)
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
        if CA.UI and CA.UI.activeTab == "gear" and self.viewMode == "player" then
            self:Render(CA.UI.contentChild, CA.UI.sideChild)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if self.viewMode == "target" and UnitIsPlayer("target") and CanInspect("target") then
            NotifyInspect("target")
        elseif self.viewMode == "target" then
            if CA.UI and CA.UI.activeTab == "gear" then self:Render(CA.UI.contentChild, CA.UI.sideChild) end
        end
    elseif event == "INSPECT_READY" then
        local guid = ...
        if self.viewMode == "target" and UnitGUID("target") == guid then
            if CA.UI and CA.UI.activeTab == "gear" then self:Render(CA.UI.contentChild, CA.UI.sideChild) end
        end
    end
end

function Gear:Init()
    CA.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    CA.eventFrame:RegisterEvent("INSPECT_READY")
end

local function CleanProxyValue(val)
    if not val then return 0 end
    if type(val) == "number" then return val end
    return tonumber(tostring(val):match("([%d%.%-]+)")) or 0
end

-- Safely compute the total score, incorporating an API Cache Fallback
local function CalculateItemScore(itemLink, specID, mode)
    if not itemLink then return 0 end
    
    local rawStats = C_Item.GetItemStats(itemLink) or {}
    local stats = {
        INT     = CleanProxyValue(rawStats["ITEM_MOD_INTELLECT_SHORT"]),
        AGI     = CleanProxyValue(rawStats["ITEM_MOD_AGILITY_SHORT"]),
        STR     = CleanProxyValue(rawStats["ITEM_MOD_STRENGTH_SHORT"]),
        STAM    = CleanProxyValue(rawStats["ITEM_MOD_STAMINA_SHORT"]),
        CRIT    = CleanProxyValue(rawStats["ITEM_MOD_CRIT_RATING_SHORT"]),
        HASTE   = CleanProxyValue(rawStats["ITEM_MOD_HASTE_RATING_SHORT"]),
        MASTERY = CleanProxyValue(rawStats["ITEM_MOD_MASTERY_RATING_SHORT"]),
        VERS    = CleanProxyValue(rawStats["ITEM_MOD_VERSATILITY_SHORT"])
    }
    
    local totalStats = stats.INT + stats.AGI + stats.STR + stats.STAM + stats.CRIT + stats.HASTE + stats.MASTERY + stats.VERS
    
    -- API Cache Fallback: If stats return 0, fallback to heavy ilvl weighting
    if totalStats == 0 then
        local fallbackIlvl = U.GetItemIlvl(itemLink)
        return fallbackIlvl * 100 
    end
    
    return CleanProxyValue(SW:ScoreItem(stats, specID, mode))
end

local function FindBestItemInBags(slotID, specID, mode, currentScore, itemDef)
    local bestLink, bestBag, bestSlot = nil, nil, nil
    local bestScore = currentScore or 0

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.hyperlink then
                local link = containerInfo.hyperlink
                local _, _, _, _, _, _, _, _, equipLoc, _, _, itemClassID, itemSubClassID = GetItemInfo(link)
                local isValid = false
                
                if C_Item.IsUsableItem(link) then
                    if slotID == 1 and equipLoc == "INVTYPE_HEAD" then isValid = true
                    elseif slotID == 2 and equipLoc == "INVTYPE_NECK" then isValid = true
                    elseif slotID == 3 and equipLoc == "INVTYPE_SHOULDER" then isValid = true
                    elseif slotID == 15 and equipLoc == "INVTYPE_CLOAK" then isValid = true
                    elseif slotID == 5 and (equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE") then isValid = true
                    elseif slotID == 8 and equipLoc == "INVTYPE_WRIST" then isValid = true
                    elseif slotID == 9 and equipLoc == "INVTYPE_HAND" then isValid = true
                    elseif slotID == 10 and equipLoc == "INVTYPE_WAIST" then isValid = true
                    elseif slotID == 11 and equipLoc == "INVTYPE_LEGS" then isValid = true
                    elseif slotID == 12 and equipLoc == "INVTYPE_FEET" then isValid = true
                    elseif itemDef.isRing and equipLoc == "INVTYPE_FINGER" then isValid = true
                    elseif itemDef.isTrinket and equipLoc == "INVTYPE_TRINKET" then isValid = true
                    elseif slotID == 16 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT") then isValid = true
                    elseif slotID == 17 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE") then isValid = true
                    end
                end

                -- Reject wrong armor types (e.g. Plate for Hunters)
                if isValid and itemClassID == 4 then
                    if equipLoc ~= "INVTYPE_NECK" and equipLoc ~= "INVTYPE_CLOAK" and equipLoc ~= "INVTYPE_FINGER" and equipLoc ~= "INVTYPE_TRINKET" and equipLoc ~= "INVTYPE_HOLDABLE" and equipLoc ~= "INVTYPE_SHIELD" then
                        if itemSubClassID ~= PRIMARY_ARMOR_TYPE then isValid = false end
                    end
                end

                if isValid then
                    local score = CalculateItemScore(link, specID, mode)
                    if score > bestScore then
                        bestScore = score; bestLink = link; bestBag = bag; bestSlot = slot
                    end
                end
            end
        end
    end
    return bestLink, bestScore, bestBag, bestSlot
end

local function GetLiveEquippedLink(itemDef, unit)
    unit = unit or "player"
    if itemDef.isRing then return GetInventoryItemLink(unit, itemDef.ringIdx == 1 and 11 or 12)
    elseif itemDef.isTrinket then return GetInventoryItemLink(unit, itemDef.triIdx == 1 and 13 or 14)
    else return GetInventoryItemLink(unit, itemDef.slotID) end
end

local function AuditItemEnchants(itemLink, isEnchantable)
    if not itemLink or not isEnchantable then return true, "" end
    local itemString = string.match(itemLink, "item[%-?%d:]+")
    if not itemString then return true, "" end
    local _, _, enchantID = strsplit(":", itemString)
    if not enchantID or enchantID == "" or enchantID == "0" then
        return false, "|cFFFF4444[!] Missing Enchant|r"
    end
    return true, "|cFF888780[✓] Enchanted|r"
end

function Gear:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    local padL, y = 20, -10
    local w = content:GetWidth() - 40

    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 14, "")
    hdr:SetText(self.viewMode == "player" and "GEAR ADVISOR: BAG SCANNER" or "GEAR ADVISOR: TARGET SCOUTER")
    hdr:SetTextColor(1, 0.82, 0, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, hdr)

    local viewBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    viewBtn:SetSize(120, 22)
    viewBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y + 4)
    viewBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    viewBtn:SetBackdropColor(0.10, 0.08, 0.00, 1)
    viewBtn:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    table.insert(self.frames, viewBtn)

    local vLbl = viewBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    vLbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    vLbl:SetText(self.viewMode == "player" and "[*] Scan Target" or "[*] View Player")
    vLbl:SetTextColor(1, 1, 1, 1)
    vLbl:SetAllPoints(viewBtn)
    viewBtn:SetScript("OnClick", function()
        self.viewMode = self.viewMode == "player" and "target" or "player"
        if self.viewMode == "target" and UnitIsPlayer("target") and CanInspect("target") then NotifyInspect("target") end
        self:Render(content, sidebar)
    end)

    y = y - 32

    if self.viewMode == "target" then
        if not UnitIsPlayer("target") then
            local errF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errF:SetFont(STANDARD_TEXT_FONT, 12, "")
            errF:SetText("|cFF888780No valid player targeted for inspection.|r")
            errF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y - 20)
            table.insert(self.frames, errF)
            return
        end
        self:RenderTargetGrid(content, sidebar, padL, y, w)
    else
        self:RenderPlayerGrid(content, sidebar, padL, y, w)
    end
end

function Gear:RenderPlayerGrid(content, sidebar, padL, y, w)
    local specID = U.GetPlayerSpec()
    if not specID then return end
    local colW, col = math.floor((w - 8) / 2), 0

    for _, slotDef in ipairs(CORE_GRID_SLOTS) do
        local currentLink = GetLiveEquippedLink(slotDef, "player")
        local currentScore = CalculateItemScore(currentLink, specID, self.pvxMode)

        local bestBagLink, bestBagScore, bBag, bSlot = FindBestItemInBags(slotDef.slotID, specID, self.pvxMode, currentScore, slotDef)
        local hasUpgrade = (bestBagLink ~= nil and bestBagScore > currentScore)

        local cx = padL + col * (colW + 8)
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(colW, 52)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", cx, y)
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})

        if hasUpgrade then
            row:SetBackdropColor(0.02, 0.06, 0.02, 0.9)
            row:SetBackdropBorderColor(0.12, 1.00, 0.00, 0.5) 
        else
            row:SetBackdropColor(0.02, 0.02, 0.02, 0.9)
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
        end
        table.insert(self.frames, row)

        local slNameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slNameF:SetFont(STANDARD_TEXT_FONT, 9, "")
        slNameF:SetText(slotDef.name:upper())
        slNameF:SetTextColor(0.55, 0.44, 0.25, 1)
        slNameF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        local nameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameF:SetFont(STANDARD_TEXT_FONT, 11, "")
        if currentLink then
            local itemName, _, quality = GetItemInfo(currentLink)
            local r, g, b = GetItemQualityColor(quality or 1)
            nameF:SetText(U.Truncate(itemName or "Loading...", 24))
            nameF:SetTextColor(r, g, b, 1)
        else
            nameF:SetText("|cFFFF4444Empty Slot|r")
        end
        nameF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -18)

        local statusF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusF:SetFont(STANDARD_TEXT_FONT, 10, "") 
        statusF:SetText(hasUpgrade and "|cFF1EFF00[▲] Ready to Swap|r" or "|cFF888780[✓] Optimized|r")
        statusF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -34)

        row:SetScript("OnClick", function()
            local targetID = slotDef.slotID
            if slotDef.isRing then targetID = (slotDef.ringIdx == 1 and 11 or 12)
            elseif slotDef.isTrinket then targetID = (slotDef.triIdx == 1 and 13 or 14) end

            if hasUpgrade and bBag and bSlot then
                C_Container.PickupContainerItem(bBag, bSlot)
                EquipCursorItem(targetID)
            else
                self.selectedSlot = targetID
                self:RenderSidebarDetails(sidebar, targetID, currentLink, bestBagLink, currentScore, bestBagScore, false)
            end
        end)

        row:SetScript("OnEnter", function(s)
            row:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            if currentLink then GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(currentLink); GameTooltip:Show() end
        end)
        row:SetScript("OnLeave", function()
            row:SetBackdropBorderColor(hasUpgrade and 0.12 or 0.35, hasUpgrade and 1.00 or 0.28, hasUpgrade and 0.00 or 0.06, hasUpgrade and 0.5 or 0.4)
            GameTooltip:Hide()
        end)

        col = col + 1
        if col >= 2 then col = 0; y = y - 58 end
    end

    y = y - 10
    local curHdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    curHdr:SetFont(STANDARD_TEXT_FONT, 11, "")
    curHdr:SetText("MIDNIGHT UPGRADE CURRENCIES")
    curHdr:SetTextColor(0.55, 0.44, 0.25, 1)
    curHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, curHdr)
    y = y - 20

    local currencies = {
        { id = 3108, name = "Weathered Harbinger Crest", color = "|cFF1EFF00" }, 
        { id = 3109, name = "Carved Harbinger Crest", color = "|cFF0070DD" },    
        { id = 3110, name = "Runed Harbinger Crest", color = "|cFFA335EE" },     
        { id = 3111, name = "Gilded Harbinger Crest", color = "|cFFFF8000" },    
        { id = 3112, name = "Voidforged Shard", color = "|cFF0CF4EC" }           
    }

    local cx = padL
    for _, c in ipairs(currencies) do
        local info = C_CurrencyInfo.GetCurrencyInfo(c.id)
        local count = info and info.quantity or 0
        local max = info and info.maxQuantity or 90

        local curBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
        curBox:SetSize(115, 36)
        curBox:SetPoint("TOPLEFT", content, "TOPLEFT", cx, y)
        curBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        curBox:SetBackdropColor(0.02, 0.02, 0.02, 0.9)
        curBox:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
        table.insert(self.frames, curBox)

        local cVal = curBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cVal:SetFont(STANDARD_TEXT_FONT, 12, "")
        cVal:SetText(c.color .. count .. "|r / " .. max)
        cVal:SetPoint("TOPLEFT", curBox, "TOPLEFT", 8, -6)

        local cName = curBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cName:SetFont(STANDARD_TEXT_FONT, 8, "")
        cName:SetText(U.Truncate(c.name, 22))
        cName:SetTextColor(0.7, 0.7, 0.7, 1)
        cName:SetPoint("TOPLEFT", curBox, "TOPLEFT", 8, -20)
        cx = cx + 122
    end
    content:SetHeight(math.abs(y) + 60)
end

function Gear:RenderTargetGrid(content, sidebar, padL, y, w)
    local tName = UnitName("target")
    local _, tClass = UnitClass("target")
    local tLevel = UnitLevel("target")
    
    local statText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statText:SetFont(STANDARD_TEXT_FONT, 12, "")
    statText:SetText(string.format("Inspecting: |cFFFFFFFF%s|r  |cFF888780(Level %d %s)|r", tName, tLevel, tClass:lower():gsub("^%l", string.upper)))
    statText:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, statText)
    
    y = y - 30
    local colW, col = math.floor((w - 8) / 2), 0
    local totalIlvl, count = 0, 0

    for _, slotDef in ipairs(CORE_GRID_SLOTS) do
        local currentLink = GetLiveEquippedLink(slotDef, "target")
        local isEnchanted, auditStr = AuditItemEnchants(currentLink, slotDef.isEnchantable)
        
        if currentLink then
            local ilvl = U.GetItemIlvl(currentLink)
            totalIlvl = totalIlvl + ilvl
            count = count + 1
        end

        local cx = padL + col * (colW + 8)
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(colW, 52)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", cx, y)
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})

        if currentLink and not isEnchanted then
            row:SetBackdropColor(0.06, 0.02, 0.02, 0.9)
            row:SetBackdropBorderColor(1.0, 0.27, 0.27, 0.6) 
        else
            row:SetBackdropColor(0.02, 0.02, 0.02, 0.9)
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
        end
        table.insert(self.frames, row)

        local slNameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slNameF:SetFont(STANDARD_TEXT_FONT, 9, "")
        slNameF:SetText(slotDef.name:upper())
        slNameF:SetTextColor(0.55, 0.44, 0.25, 1)
        slNameF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        local nameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameF:SetFont(STANDARD_TEXT_FONT, 11, "")
        if currentLink then
            local itemName, _, quality = GetItemInfo(currentLink)
            local r, g, b = GetItemQualityColor(quality or 1)
            nameF:SetText(U.Truncate(itemName or "Loading...", 24))
            nameF:SetTextColor(r, g, b, 1)
        else
            nameF:SetText("|cFF888780Empty Slot|r")
        end
        nameF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -18)

        local statusF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusF:SetFont(STANDARD_TEXT_FONT, 10, "") 
        statusF:SetText(auditStr)
        statusF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -34)

        row:SetScript("OnEnter", function(s)
            row:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            if currentLink then GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(currentLink); GameTooltip:Show() end
        end)
        row:SetScript("OnLeave", function()
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function()
            self:RenderSidebarDetails(sidebar, slotDef.slotID, currentLink, nil, 0, 0, true)
        end)

        col = col + 1
        if col >= 2 then col = 0; y = y - 58 end
    end
    
    local avgText = "True Average iLvl: " .. (count > 0 and math.floor(totalIlvl/count) or 0)
    local ilvlBox = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlBox:SetFont(STANDARD_TEXT_FONT, 14, "")
    ilvlBox:SetText(avgText)
    ilvlBox:SetTextColor(0.64, 0.21, 0.93, 1)
    ilvlBox:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, -10)
    table.insert(self.frames, ilvlBox)

    content:SetHeight(math.abs(y) + 20)
end

function Gear:RenderSidebarDetails(parent, slotID, curLink, upLink, curScore, upScore, isTarget)
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}
    local y, w = -8, parent:GetWidth() - 12

    local function SLabel(text, size, r, g, b)
        local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetFont(STANDARD_TEXT_FONT, size or 10, "")
        f:SetText(text)
        f:SetTextColor(r or 0.78, g or 0.73, b or 0.48, 1)
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        f:SetWidth(w)
        y = y - f:GetStringHeight() - 6
        table.insert(self.sideFrames, f)
    end

    if isTarget then
        SLabel("TARGET INSPECTION", 11, 1, 0.82, 0)
        if curLink then SLabel(GetItemInfo(curLink) or "Equipped Item", 10, 1, 1, 1)
        else SLabel("Empty Slot", 10, 0.5, 0.5, 0.5) end
        parent:SetHeight(math.abs(y) + 10)
        return
    end

    SLabel("GEAR SCORE COMPARISON", 11, 1, 0.82, 0)
    if curLink then
        SLabel("|cFF8B7040Equipped Score:|r " .. curScore, 10)
        SLabel(GetItemInfo(curLink) or "Equipped Item", 9, 0.55, 0.44, 0.25)
    else
        SLabel("|cFF8B7040Equipped Score:|r 0 (Empty)", 10)
    end

    y = y - 8
    if upLink then
        SLabel("|cFF1EFF00[▲] Upgrade Ready:|r", 10, 0.12, 1.0, 0.0)
        SLabel(GetItemInfo(upLink) or "Target Item", 10, 1, 1, 1)
        SLabel("Calculated Score Tier: " .. upScore .. " (+ " .. (upScore - curScore) .. ")", 9, 0.12, 1.0, 0.0)
    else
        SLabel("[✓] Current slot mathematically optimized.", 10, 0.5, 0.5, 0.5)
    end
    parent:SetHeight(math.abs(y) + 10)
end