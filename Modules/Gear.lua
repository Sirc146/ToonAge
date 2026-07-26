-- ToonAge/Modules/Gear.lua
-- Caching, PvP/PvE persistence, tooltip injection, bag-claim logic, enchant audit

local TA   = ToonAge
local U    = TA.Utils
local SW   = TA.Data.StatWeights
local EMap = TA.Data.EnchantProfessionMap or {}

local Gear = {}
TA:RegisterModule("Gear", Gear)

-- ── State ─────────────────────────────────────────────────────────────
Gear.frames       = {}
Gear.sideFrames   = {}
Gear.viewMode     = "player"
Gear.selectedSlot = nil
Gear.pvpIlvlCache     = {}
Gear.heirloomCapCache = {}
Gear.bagCache         = { time = 0, items = {} }

local HEIRLOOM_QUALITY = 7

-- ── Slot definitions (canonical WoW inventory slot IDs) ───────────────
-- Head=1 Neck=2 Shoulder=3 Shirt=4 Chest=5 Waist=6 Legs=7 Feet=8
-- Wrist=9 Hands=10 Ring1=11 Ring2=12 Trinket1=13 Trinket2=14
-- Back=15 MainHand=16 OffHand=17 Tabard=19
local CORE_GRID_SLOTS = {
    { slotID = 1,  name = "Head" },
    { slotID = 2,  name = "Neck" },
    { slotID = 3,  name = "Shoulder" },
    { slotID = 15, name = "Back",      isEnchantable = true },
    { slotID = 5,  name = "Chest",     isEnchantable = true },
    { slotID = 4,  name = "Shirt" },
    { slotID = 19, name = "Tabard" },
    { slotID = 9,  name = "Wrist",     isEnchantable = true },
    { slotID = 10, name = "Hands" },
    { slotID = 6,  name = "Waist" },
    { slotID = 7,  name = "Legs",      isEnchantable = true },
    { slotID = 8,  name = "Feet",      isEnchantable = true },
    { slotID = 11, name = "Ring 1",    isRing = true,    ringIdx = 1, isEnchantable = true },
    { slotID = 12, name = "Ring 2",    isRing = true,    ringIdx = 2, isEnchantable = true },
    { slotID = 13, name = "Trinket 1", isTrinket = true, triIdx  = 1 },
    { slotID = 14, name = "Trinket 2", isTrinket = true, triIdx  = 2 },
    { slotID = 16, name = "Main Hand", isEnchantable = true },
    { slotID = 17, name = "Off Hand",  isEnchantable = true },
}

-- ── Armor proficiency ─────────────────────────────────────────────────
-- Resolved in Gear:Init() after PLAYER_ENTERING_WORLD guarantees UnitClass
-- returns real data. Accessing it at file-load scope is unsafe because the
-- player unit may not yet be fully initialised during the TOC load phase.
local PRIMARY_ARMOR_TYPE = 1   -- default (Cloth); overwritten in Init()

local function ResolveArmorType()
    local _, cls = UnitClass("player")
    if     cls == "WARRIOR" or cls == "PALADIN" or cls == "DEATHKNIGHT" then return 4   -- Plate
    elseif cls == "HUNTER"  or cls == "SHAMAN"  or cls == "EVOKER"      then return 3   -- Mail
    elseif cls == "ROGUE"   or cls == "DRUID"   or cls == "MONK"
        or cls == "DEMONHUNTER"                                          then return 2   -- Leather
    end
    return 1  -- Cloth
end

-- ── Helpers ───────────────────────────────────────────────────────────
local function CleanProxyValue(val)
    if not val then return 0 end
    if type(val) == "number" then return val end
    return tonumber(tostring(val):match("([%d%.%-]+)")) or 0
end

-- ── Tooltip scanner for PvP iLvl detection ────────────────────────────
local ScanTT = CreateFrame("GameTooltip", "TAGearScannerTT", nil, "GameTooltipTemplate")
ScanTT:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetItemIlvls(itemLink)
    if not itemLink then return 0, nil, nil end
    local worldIlvl = U.GetItemIlvl(itemLink) or 0

    if Gear.pvpIlvlCache[itemLink] and Gear.heirloomCapCache[itemLink] ~= nil then
        local cap = Gear.heirloomCapCache[itemLink]
        return worldIlvl, Gear.pvpIlvlCache[itemLink], (cap ~= false) and cap or nil
    end

    local pvpIlvl, heirloomCap = nil, nil
    local isHeirloom = U.GetItemQuality(itemLink) == HEIRLOOM_QUALITY

    ScanTT:ClearLines()
    ScanTT:SetHyperlink(itemLink)
    for i = 2, ScanTT:NumLines() do
        local line = _G["TAGearScannerTTTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local m = text:match("PvP Item Level (%d+)")
                       or text:match("Equips to (%d+)")
                       or text:match("Increases item level.-(%d+) in")
                if m then pvpIlvl = tonumber(m) end

                -- Heirloom scaling cap. NOTE: exact tooltip wording for this
                -- expansion isn't verified — these patterns match historically
                -- common phrasings ("Scales with your level up to level X" /
                -- "Scales to level X"). Adjust if the real tooltip text differs.
                if isHeirloom and not heirloomCap then
                    local cap = text:match("[Ss]cales with your level up to level (%d+)")
                             or text:match("[Ss]cales to level (%d+)")
                             or text:match("[Uu]p to level (%d+)")
                    if cap then heirloomCap = tonumber(cap) end
                end
            end
        end
    end

    if pvpIlvl then Gear.pvpIlvlCache[itemLink] = pvpIlvl end
    -- Cache `false` (not nil) for "checked, not a capped heirloom" so the
    -- cache-hit branch above can distinguish "not scanned yet" from "scanned,
    -- no cap found".
    Gear.heirloomCapCache[itemLink] = heirloomCap or false

    return worldIlvl, pvpIlvl, heirloomCap
end

-- ── Item scoring ──────────────────────────────────────────────────────
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
        VERS    = CleanProxyValue(rawStats["ITEM_MOD_VERSATILITY_SHORT"]),
    }
    local total = stats.INT + stats.AGI + stats.STR + stats.STAM
                + stats.CRIT + stats.HASTE + stats.MASTERY + stats.VERS

    if total == 0 then
        -- No recognized stat budget on this item (common for pure on-use/proc
        -- trinkets, or occasionally an item whose data hasn't finished caching).
        local wIlvl, pIlvl = GetItemIlvls(itemLink)
        local baseIlvl = (mode == "pvp" and pIlvl) or wIlvl or 0
        return baseIlvl * 3
    end

    local src = TA.charDB and TA.charDB.weightSource or "built-in"
    if src == "pawn" and Pawn and Pawn.GetSingleItemValue then
        local ok, val = pcall(function() return Pawn.GetSingleItemValue(itemLink, false) end)
        if ok and val then return CleanProxyValue(val) end
    end

    local baseScore = CleanProxyValue(SW:ScoreItem(stats, specID, mode))

    -- PvP ilvl scaling: In instanced PvP (arena/BG), items with a PvP ilvl
    -- receive a proportional stat budget increase.  C_Item.GetItemStats() only
    -- returns world-mode stats, so we approximate the PvP effective score by
    -- scaling the weighted score proportionally to the ilvl uplift.
    -- This ensures PvP-intended gear (Gladiator, Aspirant etc.) is correctly
    -- recommended over PvE gear of equal world ilvl when pvxMode == "pvp".
    if mode == "pvp" then
        local wIlvl, pIlvl = GetItemIlvls(itemLink)
        if pIlvl and wIlvl and wIlvl > 0 and pIlvl > wIlvl then
            -- Stat budgets scale roughly linearly with ilvl in Midnight.
            -- A PvP item at world ilvl 217 with PvP ilvl 233 gets ~7.4% more
            -- effective stats in PvP content: (233/217) = 1.074
            baseScore = math.floor(baseScore * (pIlvl / wIlvl))
        end
    end

    return baseScore
end

-- Expose for tooltip hook usage
Gear.CalculateItemScore = CalculateItemScore

-- ── Throttled bag scan with claim tracking ────────────────────────────
-- Returns bestLink, bestScore, bestBag, bestSlot, claimedBy, claimedLink, claimedBag, claimedSlot
-- claimedBy/claimedLink/Bag/Slot describe the best item that was already claimed by another slot.
local function ScanBagsForUpgrades(slotID, specID, mode, currentScore, itemDef, claimedBags)
    local bestLink, bestBag, bestSlot = nil, nil, nil
    local bestScore = currentScore or 0
    local claimedLink, claimedBag, claimedSlot, claimedBy = nil, nil, nil, nil
    local bestClaimedScore = currentScore or 0

    if GetTime() - Gear.bagCache.time > 2.0 then
        Gear.bagCache.items = {}
        for bag = 0, 4 do
            for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.hyperlink then
                    table.insert(Gear.bagCache.items, { bag = bag, slot = slot, link = info.hyperlink })
                end
            end
        end
        Gear.bagCache.time = GetTime()
    end

    for _, item in ipairs(Gear.bagCache.items) do
        local bagSlotKey = item.bag .. "_" .. item.slot
        local _, _, _, _, _, _, _, _, equipLoc, _, _, itemClassID, itemSubClassID = GetItemInfo(item.link)

        if equipLoc then
            local isValid = false
            if     slotID == 1  and equipLoc == "INVTYPE_HEAD"     then isValid = true
            elseif slotID == 2  and equipLoc == "INVTYPE_NECK"     then isValid = true
            elseif slotID == 3  and equipLoc == "INVTYPE_SHOULDER"  then isValid = true
            elseif slotID == 15 and equipLoc == "INVTYPE_CLOAK"    then isValid = true
            elseif slotID == 5  and (equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE") then isValid = true
            elseif slotID == 9  and equipLoc == "INVTYPE_WRIST"    then isValid = true
            elseif slotID == 10 and equipLoc == "INVTYPE_HAND"     then isValid = true
            elseif slotID == 6  and equipLoc == "INVTYPE_WAIST"    then isValid = true
            elseif slotID == 7  and equipLoc == "INVTYPE_LEGS"     then isValid = true
            elseif slotID == 8  and equipLoc == "INVTYPE_FEET"     then isValid = true
            elseif itemDef.isRing    and equipLoc == "INVTYPE_FINGER"  then isValid = true
            elseif itemDef.isTrinket and equipLoc == "INVTYPE_TRINKET" then isValid = true
            elseif slotID == 16 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_2HWEAPON"
                                  or equipLoc == "INVTYPE_WEAPONMAINHAND"
                                  or equipLoc == "INVTYPE_RANGED"  or equipLoc == "INVTYPE_RANGEDRIGHT") then isValid = true
            elseif slotID == 17 and (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND"
                                  or equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE") then isValid = true
            end

            -- Reject wrong armor types (accessories bypass this check)
            if isValid and itemClassID == 4 then
                local isAccessory = equipLoc == "INVTYPE_NECK"    or equipLoc == "INVTYPE_CLOAK"
                                 or equipLoc == "INVTYPE_FINGER"  or equipLoc == "INVTYPE_TRINKET"
                                 or equipLoc == "INVTYPE_SHIELD"  or equipLoc == "INVTYPE_HOLDABLE"
                if not isAccessory and itemSubClassID ~= PRIMARY_ARMOR_TYPE then isValid = false end
            end

            if isValid then
                local score = CalculateItemScore(item.link, specID, mode)
                if score > bestScore then
                    if claimedBags[bagSlotKey] then
                        if score > bestClaimedScore then
                            bestClaimedScore = score
                            claimedLink = item.link; claimedBag = item.bag; claimedSlot = item.slot
                            claimedBy = claimedBags[bagSlotKey]
                        end
                    else
                        bestScore = score; bestLink = item.link; bestBag = item.bag; bestSlot = item.slot
                    end
                end
            end
        end
    end
    return bestLink, bestScore, bestBag, bestSlot, claimedBy, claimedLink, claimedBag, claimedSlot
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

-- ── Profession cache ───────────────────────────────────────────────────
local PlayerProfessionsCache = {}
local function RebuildProfessionsCache()
    wipe(PlayerProfessionsCache)
    local p1, p2, arch, fish, cook, fa = GetProfessions()
    for _, idx in ipairs({ p1, p2, arch, fish, cook, fa }) do
        if idx then
            local name = GetProfessionInfo(idx)
            if name then PlayerProfessionsCache[name:upper()] = true end
        end
    end
end

-- ── Enchant audit (profession + recipe ownership) ─────────────────────
local function AuditItemEnchants(itemLink, isEnchantable)
    if not itemLink or not isEnchantable then return true, "" end
    local itemString = string.match(itemLink, "item[%-?%d:]+")
    if not itemString then return true, "" end
    local _, _, enchantID = strsplit(":", itemString)
    enchantID = tonumber(enchantID) or 0

    if enchantID == 0 then return false, "|cFFFF4444Missing Enchant|r" end

    local eInfo = EMap[enchantID]
    if eInfo and eInfo.profession then
        local pKey = eInfo.profession:upper()
        if not PlayerProfessionsCache[pKey] then
            return false, "|cFFFF4444Needs " .. eInfo.profession .. "|r"
        end
        if eInfo.spellID and not U.IsSpellKnown(eInfo.spellID) then
            return false, "|cFFFF4444Recipe not learned|r"
        end
    end
    return true, "|cFF888780Enchanted|r"
end

-- Debounced re-render for the bag-change events, which can fire many times
-- in a single loot/vendor action — each full render rescans every bag slot
-- against all 18 grid slots, so batching avoids repeating that scan per event.
-- Mirrors the same C_Timer.After debounce pattern Talents.lua already uses.
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

-- ── Events ────────────────────────────────────────────────────────────
function Gear:OnEvent(event, ...)
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" or event == "GET_ITEM_INFO_RECEIVED" then
        self.bagCache.time = 0
        ScheduleBagRender()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if self.viewMode == "target" then
            if UnitIsPlayer("target") and CanInspect("target") then NotifyInspect("target") end
            if TA.UI and TA.UI.activeTab == "gear" then self:Render(TA.UI.contentChild, TA.UI.sideChild) end
        end
    elseif event == "INSPECT_READY" then
        local guid = ...
        if self.viewMode == "target" and UnitGUID("target") == guid then
            if TA.UI and TA.UI.activeTab == "gear" then self:Render(TA.UI.contentChild, TA.UI.sideChild) end
        end
    elseif event == "SKILL_LINES_CHANGED" then
        RebuildProfessionsCache()
    end
end

function Gear:Init()
    -- Resolve class-dependent armor type now that the player unit is ready
    PRIMARY_ARMOR_TYPE = ResolveArmorType()
    TA.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    TA.eventFrame:RegisterEvent("INSPECT_READY")
    -- SKILL_LINES_CHANGED is already registered globally in Core/Init.lua's
    -- PERSISTENT_EVENTS list; no need to register it again here.
    if TA.charDB then
        TA.charDB.pvxMode      = TA.charDB.pvxMode      or "pve"
        TA.charDB.weightSource = TA.charDB.weightSource or "built-in"
    end
    RebuildProfessionsCache()
end

-- ── Render ────────────────────────────────────────────────────────────
function Gear:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    -- Place a hint in the sidebar so the dynamic resizing logic doesn't
    -- hide the sidebar (Gear uses on-demand sidebar via click).
    local hint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hint:SetText("Click a gear slot\nfor details")
    hint:SetTextColor(0.50, 0.47, 0.42, 1)
    hint:SetPoint("TOP", sidebar, "TOP", 0, -20)
    hint:SetWidth(sidebar:GetWidth() - 12)
    hint:SetJustifyH("CENTER")

    -- ── GearSets UI ───────────────────────────────────────────────────
    local sideY = -60
    local sideW = sidebar:GetWidth() - 12

    local gsHeader = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gsHeader:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    gsHeader:SetText("|cFF8B7040GEAR SETS|r")
    gsHeader:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, sideY)
    gsHeader:SetWidth(sideW)
    table.insert(self.sideFrames, gsHeader)
    sideY = sideY - 14

    -- Divider line
    local gsLine = sidebar:CreateTexture(nil, "ARTWORK")
    gsLine:SetHeight(1)
    gsLine:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  4, sideY)
    gsLine:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -4, sideY)
    gsLine:SetColorTexture(0.30, 0.30, 0.35, 0.4)
    sideY = sideY - 8
    table.insert(self.sideFrames, gsLine)

    -- "Save Current" button
    local saveBtn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
    saveBtn:SetHeight(22)
    saveBtn:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  4, sideY)
    saveBtn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -4, sideY)
    saveBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    saveBtn:SetBackdropColor(0.06, 0.10, 0.04, 1)
    saveBtn:SetBackdropBorderColor(0.20, 0.72, 0.30, 0.7)
    local saveLbl = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    saveLbl:SetText("|cFF4AFF7A+|r Save Current Gear")
    saveLbl:SetPoint("LEFT", saveBtn, "LEFT", 8, 0)
    saveLbl:SetTextColor(0.82, 0.80, 0.75, 1)
    saveBtn:SetScript("OnClick", function()
        -- Prompt for set name via a simple StaticPopup
        local GS = TA:GetModule("GearSets")
        if not GS then return end
        -- Generate a default name from spec
        local _, specName = U.GetPlayerSpec()
        local defaultName = specName or "Set"
        -- Use a timestamp-based unique name if one already exists
        if TA.charDB.gearSets and TA.charDB.gearSets[defaultName] then
            defaultName = defaultName .. " " .. date("%H%M")
        end
        GS:SaveSet(defaultName)
        -- Refresh to show the new set
        C_Timer.After(0.1, function()
            if TA.UI and TA.UI.activeTab == "gear" then
                Gear:Render(TA.UI.contentChild, TA.UI.sideChild)
            end
        end)
    end)
    sideY = sideY - 26
    table.insert(self.sideFrames, saveBtn)

    -- List existing sets as clickable rows
    local GS = TA:GetModule("GearSets")
    local gearSets = TA.charDB and TA.charDB.gearSets or {}
    local setCount = 0
    for setName, setData in pairs(gearSets) do
        setCount = setCount + 1
        local row = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        row:SetHeight(20)
        row:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  4, sideY)
        row:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -4, sideY)
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        row:SetBackdropColor(0.05, 0.05, 0.05, 1)
        row:SetBackdropBorderColor(0.40, 0.32, 0.08, 0.4)

        -- Count items in set
        local itemCount = 0
        if setData.slots then for _ in pairs(setData.slots) do itemCount = itemCount + 1 end end

        local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        rowLbl:SetText(setName)
        rowLbl:SetPoint("LEFT", row, "LEFT", 6, 0)
        rowLbl:SetWidth(row:GetWidth() - 50)
        rowLbl:SetJustifyH("LEFT")
        rowLbl:SetWordWrap(false)
        rowLbl:SetTextColor(0.80, 0.78, 0.70, 1)

        local countLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        countLbl:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        countLbl:SetText("|cFF888780" .. itemCount .. " pc|r")
        countLbl:SetPoint("RIGHT", row, "RIGHT", -6, 0)

        -- Left-click to equip
        row:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                -- Right-click to delete
                if GS then
                    GS:DeleteSet(setName)
                    C_Timer.After(0.1, function()
                        if TA.UI and TA.UI.activeTab == "gear" then
                            Gear:Render(TA.UI.contentChild, TA.UI.sideChild)
                        end
                    end)
                end
            else
                if GS then GS:EquipSet(setName) end
            end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        row:SetScript("OnEnter", function(self2)
            self2:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(setName, 1, 0.82, 0)
            GameTooltip:AddLine("Left-click: Equip this set", 1, 1, 1)
            GameTooltip:AddLine("Right-click: Delete this set", 0.7, 0.3, 0.3)
            if setData.specID then
                local _, sn = GetSpecializationInfoByID(setData.specID)
                GameTooltip:AddLine("Auto-equip: " .. (sn or "spec change"), 0.5, 0.8, 1)
            end
            if setData.pvp then
                GameTooltip:AddLine("Auto-equip: PvP instances", 0.5, 0.8, 1)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self2)
            self2:SetBackdropBorderColor(0.40, 0.32, 0.08, 0.4)
            GameTooltip:Hide()
        end)

        sideY = sideY - 22
        table.insert(self.sideFrames, row)
    end

    if setCount == 0 then
        local emptyLbl = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLbl:SetFont(STANDARD_TEXT_FONT, 9, "")
        emptyLbl:SetText("No saved sets yet")
        emptyLbl:SetTextColor(0.45, 0.42, 0.38, 1)
        emptyLbl:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, sideY)
        sideY = sideY - 14
        table.insert(self.sideFrames, emptyLbl)
    end

    sidebar:SetHeight(math.abs(sideY) + 10)

    -- Auto-detect PvP mode: if the player is in a PvP instance (arena/BG)
    -- or has War Mode enabled, default to PvP scoring so PvP gear surfaces
    -- correctly. Manual toggle always overrides this auto-detection.
    local inInstance, instanceType = IsInInstance()
    local isPvPContext = (instanceType == "pvp" or instanceType == "arena")
                      or (C_PvP and C_PvP.IsWarModeDesired and C_PvP.IsWarModeDesired())
    if isPvPContext then
        if TA.charDB then TA.charDB.pvxMode = "pvp" end
    end

    local pvxMode      = (TA.charDB and TA.charDB.pvxMode)      or "pve"
    local weightSource = (TA.charDB and TA.charDB.weightSource) or "built-in"
    local padL, y     = 20, -10
    local w           = content:GetWidth() - 40

    -- Header
    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 14, "")
    hdr:SetText((self.viewMode == "player" and "GEAR ADVISOR: BAG SCANNER"
                                           or  "GEAR ADVISOR: TARGET SCOUTER")
                .. " |cFF888780(Weights: " .. weightSource:upper() .. ")|r")
    hdr:SetTextColor(1, 0.82, 0, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, hdr)

    -- View Mode toggle
    local viewBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    viewBtn:SetSize(110, 22)
    viewBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y + 4)
    viewBtn:SetText(self.viewMode == "player" and "Scan Target" or "View Player")
    viewBtn:SetScript("OnClick", function()
        self.viewMode = self.viewMode == "player" and "target" or "player"
        if self.viewMode == "target" and UnitIsPlayer("target") and CanInspect("target") then
            NotifyInspect("target")
        end
        self:Render(content, sidebar)
    end)
    table.insert(self.frames, viewBtn)

    -- PvP toggle
    local pvpBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    pvpBtn:SetSize(90, 22)
    pvpBtn:SetPoint("TOPRIGHT", viewBtn, "TOPLEFT", -4, 0)
    pvpBtn:SetText(pvxMode == "pvp" and "PvP: ON" or "PvP: OFF")
    pvpBtn:SetScript("OnClick", function()
        local next = (pvxMode == "pve") and "pvp" or "pve"
        if TA.charDB then TA.charDB.pvxMode = next end
        self:Render(content, sidebar)
    end)
    table.insert(self.frames, pvpBtn)

    -- Weight source cycling
    local srcBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    srcBtn:SetSize(110, 22)
    srcBtn:SetPoint("TOPRIGHT", pvpBtn, "TOPLEFT", -4, 0)
    srcBtn:SetText("Src: " .. weightSource)
    srcBtn:SetScript("OnClick", function()
        local next = weightSource == "built-in" and "pawn"
                  or weightSource == "pawn"     and "custom"
                  or "built-in"
        if TA.charDB then TA.charDB.weightSource = next end
        self:Render(content, sidebar)
    end)
    table.insert(self.frames, srcBtn)

    -- Constrain the header to stop before the button row (anchored to
    -- srcBtn, the left-most button) so long weight-source labels don't
    -- run underneath the buttons; wrap instead of overflowing.
    hdr:SetPoint("RIGHT", srcBtn, "LEFT", -10, 0)
    hdr:SetWordWrap(true)

    y = y - 30
    local disc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disc:SetFont(STANDARD_TEXT_FONT, 10, "")
    disc:SetText("|cFFAAAAAAPvP gear shows world ilvl + PvP ilvl (green) when available. Click any slot to see score details.|r")
    disc:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, disc)
    y = y - 20

    if self.viewMode == "target" then
        if not UnitIsPlayer("target") then
            local errF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errF:SetFont(STANDARD_TEXT_FONT, 12, "")
            errF:SetText("|cFF888780No valid player targeted for inspection.|r")
            errF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y - 20)
            table.insert(self.frames, errF)
            content:SetHeight(math.abs(y) + 60)
            return
        end
        self:RenderTargetGrid(content, sidebar, padL, y, w)
    else
        self:RenderPlayerGrid(content, sidebar, padL, y, w, pvxMode)
    end
end

-- ── Player Grid ───────────────────────────────────────────────────────
function Gear:RenderPlayerGrid(content, sidebar, padL, y, w, pvxMode)
    local specID = U.GetPlayerSpec()
    if not specID then return end
    local colW, col = math.floor((w - 8) / 2), 0
    local claimedBags = {}
    local playerLevel = UnitLevel("player") or 1
    local pendingUpgrades = {}  -- collected for "Equip All" button

    -- Tracks the currently-equipped Main Hand state. CORE_GRID_SLOTS always
    -- lists Main Hand (16) immediately before Off Hand (17), so this is set
    -- before the Off Hand iteration reads it. Off Hand is meaningless without
    -- checking Main Hand first — a two-handed weapon makes it physically
    -- unusable, and an EMPTY Main Hand means gearing Off Hand is putting the
    -- cart before the horse. Without this, Main Hand and Off Hand were scored
    -- as fully independent slots and would perpetually suggest swapping into
    -- each other (equip an Off Hand "upgrade" -> game auto-unequips the 2H,
    -- or sits oddly next to an empty Main Hand -> next render flags Main Hand
    -- as needing attention -> repeat).
    local twoHandEquipped = false
    local mainHandEmpty   = false

    for _, slotDef in ipairs(CORE_GRID_SLOTS) do
        local currentLink  = GetLiveEquippedLink(slotDef, "player")
        local currentScore = CalculateItemScore(currentLink, specID, pvxMode)
        local wIlvl, pIlvl, heirloomCap = GetItemIlvls(currentLink)
        local heirloomWarn = heirloomCap and playerLevel >= (heirloomCap - 2)

        if slotDef.slotID == 16 then
            local _, _, _, _, _, _, _, _, mhEquipLoc = currentLink and GetItemInfo(currentLink)
            twoHandEquipped = (mhEquipLoc == "INVTYPE_2HWEAPON")
            mainHandEmpty   = (currentLink == nil)
        end

        local bestBagLink, bestBagScore, bBag, bSlot, claimedBy, claimedLink, claimedBag, claimedSlot =
            ScanBagsForUpgrades(slotDef.slotID, specID, pvxMode, currentScore, slotDef, claimedBags)
        local hasUpgrade = bestBagLink ~= nil and (bestBagScore - currentScore) > 0.0001

        -- Off Hand is inert while a two-handed weapon is equipped, and
        -- premature while Main Hand is empty — don't suggest swapping it in
        -- either case, and don't flag its own empty state as a problem.
        local offHandBlockedByTwoHand = (slotDef.slotID == 17 and twoHandEquipped)
        local offHandBlockedByEmptyMH = (slotDef.slotID == 17 and mainHandEmpty)
        if offHandBlockedByTwoHand or offHandBlockedByEmptyMH then
            hasUpgrade = false
        end

        if hasUpgrade and bBag and bSlot then
            claimedBags[bBag .. "_" .. bSlot] = slotDef.name
        end

        local targetSlotID = slotDef.slotID
        if slotDef.isRing    then targetSlotID = (slotDef.ringIdx == 1 and 11 or 12) end
        if slotDef.isTrinket then targetSlotID = (slotDef.triIdx  == 1 and 13 or 14) end

        local cx = padL + col * (colW + 8)
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(colW, 52)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", cx, y)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        table.insert(self.frames, row)

        local isEnchantWarning = false

        if hasUpgrade then
            row:SetBackdropColor(0.02, 0.06, 0.02, 0.9)
            row:SetBackdropBorderColor(0.12, 1.00, 0.00, 0.5)
        else
            row:SetBackdropColor(0.02, 0.02, 0.02, 0.9)
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
        end

        -- Slot name (top-left)
        local slNameF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slNameF:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        slNameF:SetText(slotDef.name:upper())
        slNameF:SetTextColor(0.62, 0.59, 0.55, 1)
        slNameF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        -- iLvl display (top-right)
        local slIlvlF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slIlvlF:SetFont(STANDARD_TEXT_FONT, 9, "")
        if currentLink and wIlvl > 0 then
            if pIlvl then
                slIlvlF:SetText(wIlvl .. " |cFF00FF00(PvP " .. pIlvl .. ")|r")
            else
                slIlvlF:SetText(wIlvl .. " |cFF555555(no PvP)|r")
            end
        end
        slIlvlF:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -6)

        -- Item name
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

        -- Status line + modern visual indicators (glow border + status strip)
        -- Right edge reserves room for the inline Equip button (42px wide,
        -- anchored -6 from row's right) so status text never renders under it.
        local statusF = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusF:SetFont(STANDARD_TEXT_FONT, 10, "")
        statusF:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -34)
        statusF:SetPoint("RIGHT", row, "RIGHT", -54, 0)

        local M = TA.Modern  -- may be nil if UIModern not loaded

        if hasUpgrade then
            local pct = currentScore > 0 and math.floor(((bestBagScore - currentScore) / currentScore) * 100) or 0
            statusF:SetText("|cFF1EFF00Ready to Swap (+" .. pct .. "% score)|r")
            if M then
                M:ApplyGlowBorder(row, 0.12, 1.00, 0.00, 0.6)
                M:ApplyStatusStrip(row, "upgrade")
            end
        elseif claimedBy then
            statusF:SetText("|cFFAAAAAAClaimed by " .. claimedBy .. "|r")
            if M then M:ApplyStatusStrip(row, "warning") end
        elseif currentLink then
            if slotDef.isEnchantable then
                local ok, auditStr = AuditItemEnchants(currentLink, true)
                if not ok then
                    isEnchantWarning = true
                    -- Modern: red glow border + danger strip
                    statusF:SetText(auditStr)
                    row:SetBackdropColor(0.06, 0.02, 0.02, 0.9)
                    row:SetBackdropBorderColor(1.0, 0.27, 0.27, 0.6)
                    if M then
                        M:ApplyGlowBorder(row, 1.0, 0.30, 0.25, 0.7)
                        M:ApplyStatusStrip(row, "danger")
                    end
                else
                    statusF:SetText("|cFF888780Enchanted|r")
                    if M then M:ApplyStatusStrip(row, "ok") end
                end
            else
                statusF:SetText("|cFF888780Equipped|r")
                if M then M:ApplyStatusStrip(row, "ok") end
            end
        elseif offHandBlockedByTwoHand then
            -- Empty Off Hand is correct, not a problem, while wielding a 2H weapon.
            statusF:SetText("|cFF888780Two-Handed weapon equipped|r")
            if M then M:ApplyStatusStrip(row, "ok") end
        elseif offHandBlockedByEmptyMH then
            -- Off Hand isn't the real problem here — Main Hand being empty is.
            statusF:SetText("|cFFFF9A1AEquip a Main Hand weapon first|r")
            row:SetBackdropBorderColor(1.0, 0.60, 0.10, 0.5)
            if M then M:ApplyStatusStrip(row, "warning") end
        else
            statusF:SetText("|cFFFF4444Missing Item|r")
            row:SetBackdropBorderColor(1.0, 0.27, 0.27, 0.6)
            if M then
                M:ApplyGlowBorder(row, 1.0, 0.30, 0.25, 0.8)
                M:ApplyStatusStrip(row, "danger")
            end
        end

        -- Tooltip injection
        local capScore       = currentScore
        local capBestScore   = bestBagScore
        local capHasUp       = hasUpgrade
        local capPvxMode     = pvxMode
        local capHeirloomCap = heirloomCap
        local capHeirloomWarn= heirloomWarn
        row:SetScript("OnEnter", function(s)
            row:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            if currentLink then
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(currentLink)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("ToonAge:", 1, 0.82, 0)
                GameTooltip:AddLine("Mode: " .. capPvxMode:upper(), 0.55, 0.44, 0.25)
                GameTooltip:AddLine("Score: " .. capScore, 1, 1, 1)
                if capHasUp then
                    GameTooltip:AddLine("Bag upgrade: +" .. math.floor(capBestScore - capScore) .. " score", 0.12, 1.0, 0.0)
                end
                if capHeirloomCap then
                    if capHeirloomWarn then
                        GameTooltip:AddLine("[!] Heirloom scales to level " .. capHeirloomCap .. " — upgrade soon", 1.0, 0.53, 0.0)
                    else
                        GameTooltip:AddLine("Heirloom — scales to level " .. capHeirloomCap, 0.05, 0.96, 0.93)
                    end
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            if capHasUp then
                row:SetBackdropBorderColor(0.12, 1.00, 0.00, 0.5)
            elseif isEnchantWarning then
                row:SetBackdropBorderColor(1.0, 0.27, 0.27, 0.6)
            else
                row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
            end
            GameTooltip:Hide()
        end)

        local capSlotID       = targetSlotID
        local capCurLink      = currentLink
        local capUpLink       = bestBagLink
        local capCurScore     = currentScore
        local capUpScore      = bestBagScore
        local capBBag         = bBag
        local capBSlot        = bSlot
        local capClaimedBy    = claimedBy
        local capClaimedLink  = claimedLink
        local capClaimedBag   = claimedBag
        local capClaimedSlot  = claimedSlot
        row:SetScript("OnClick", function()
            self.selectedSlot = capSlotID
            self:RenderSidebarDetails(
                sidebar, capSlotID, capCurLink, capUpLink,
                capCurScore, capUpScore, false,
                capBBag, capBSlot, capClaimedBy,
                capClaimedLink, capClaimedBag, capClaimedSlot
            )
        end)

        -- Inline Equip button (only shown when an upgrade is available)
        if hasUpgrade and bBag and bSlot then
            local eqBag, eqSlot, eqTargetSlot = bBag, bSlot, targetSlotID
            local equipBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
            equipBtn:SetSize(42, 16)
            equipBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 4)
            equipBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            equipBtn:SetBackdropColor(0.08, 0.20, 0.08, 1)
            equipBtn:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.8)
            local eqLbl = equipBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            eqLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            eqLbl:SetText("Equip")
            eqLbl:SetTextColor(0.30, 0.92, 0.40, 1)
            eqLbl:SetAllPoints(equipBtn)
            eqLbl:SetJustifyH("CENTER")
            equipBtn:SetScript("OnClick", function(_, btn2)
                if btn2 == "LeftButton" or btn2 == nil then
                    if C_Container and C_Container.PickupContainerItem then
                        C_Container.PickupContainerItem(eqBag, eqSlot)
                    else
                        PickupContainerItem(eqBag, eqSlot)
                    end
                    EquipCursorItem(eqTargetSlot)
                end
            end)
            equipBtn:SetScript("OnEnter", function(f)
                f:SetBackdropColor(0.12, 0.30, 0.12, 1)
            end)
            equipBtn:SetScript("OnLeave", function(f)
                f:SetBackdropColor(0.08, 0.20, 0.08, 1)
            end)
            table.insert(self.frames, equipBtn)

            -- Track for Equip All
            table.insert(pendingUpgrades, { bag = eqBag, slot = eqSlot, target = eqTargetSlot, name = slotDef.name })
        end

        col = col + 1
        if col >= 2 then col = 0; y = y - 58 end
    end

    -- ── Equip All Upgrades button ─────────────────────────────────────
    if #pendingUpgrades > 0 then
        y = y - 12
        local equipAllBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
        equipAllBtn:SetSize(w, 26)
        equipAllBtn:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        equipAllBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        equipAllBtn:SetBackdropColor(0.06, 0.18, 0.06, 1)
        equipAllBtn:SetBackdropBorderColor(0.20, 0.80, 0.30, 0.9)

        local eaLbl = equipAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        eaLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        eaLbl:SetText("\226\156\147 Equip All Upgrades (" .. #pendingUpgrades .. ")")
        eaLbl:SetTextColor(0.30, 0.92, 0.40, 1)
        eaLbl:SetAllPoints(equipAllBtn)
        eaLbl:SetJustifyH("CENTER")

        equipAllBtn:SetScript("OnClick", function()
            for _, up in ipairs(pendingUpgrades) do
                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(up.bag, up.slot)
                else
                    PickupContainerItem(up.bag, up.slot)
                end
                EquipCursorItem(up.target)
            end
            -- Brief delay then re-render to reflect changes
            C_Timer.After(0.5, function()
                if TA.UI and TA.UI.activeTab == "gear" then
                    self:Render(TA.UI.contentChild, TA.UI.sideChild)
                end
            end)
        end)
        equipAllBtn:SetScript("OnEnter", function(f)
            f:SetBackdropColor(0.10, 0.28, 0.10, 1)
            GameTooltip:SetOwner(f, "ANCHOR_TOP")
            GameTooltip:SetText("Equip All Upgrades", 0.30, 0.92, 0.40)
            for _, up in ipairs(pendingUpgrades) do
                GameTooltip:AddLine("  " .. up.name, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        equipAllBtn:SetScript("OnLeave", function(f)
            f:SetBackdropColor(0.06, 0.18, 0.06, 1)
            GameTooltip:Hide()
        end)
        table.insert(self.frames, equipAllBtn)
        y = y - 32
    end

    -- Currency section
    y = y - 10
    local curHdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    curHdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    curHdr:SetText("MIDNIGHT UPGRADE CURRENCIES")
    curHdr:SetTextColor(0.62, 0.59, 0.55, 1)
    curHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, curHdr)
    y = y - 20

    local currencies = {
        { id = 3108, name = "Weathered Harbinger Crest", color = "|cFF1EFF00" },
        { id = 3109, name = "Carved Harbinger Crest",    color = "|cFF0070DD" },
        { id = 3110, name = "Runed Harbinger Crest",     color = "|cFFA335EE" },
        { id = 3111, name = "Gilded Harbinger Crest",    color = "|cFFFF8000" },
        { id = 3112, name = "Voidforged Shard",          color = "|cFF0CF4EC" },
    }

    local cx = padL
    for _, c in ipairs(currencies) do
        local info  = C_CurrencyInfo.GetCurrencyInfo(c.id)
        local count = info and info.quantity    or 0
        local max   = info and info.maxQuantity or 90

        local curBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
        curBox:SetSize(115, 36)
        curBox:SetPoint("TOPLEFT", content, "TOPLEFT", cx, y)
        curBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
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
    -- ── Dungeon Gear Suggestions ─────────────────────────────────────────────
    local DG = TA:GetModule("DungeonGear")
    if DG and DG.GetFormattedSuggestions then
        local suggestions = DG:GetFormattedSuggestions()
        if #suggestions > 0 then
            y = y - 16
            local dgHdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dgHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            dgHdr:SetText("DUNGEON UPGRADES — Your weakest slots")
            dgHdr:SetTextColor(0.55, 0.40, 0.08, 1)
            dgHdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            table.insert(self.frames, dgHdr)
            y = y - 4

            local dgLine = content:CreateTexture(nil, "ARTWORK")
            dgLine:SetHeight(1)
            dgLine:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
            dgLine:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
            dgLine:SetColorTexture(0.40, 0.32, 0.08, 0.5)
            table.insert(self.frames, dgLine)
            y = y - 8

            for _, line in ipairs(suggestions) do
                local sF = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                sF:SetFont(STANDARD_TEXT_FONT, 10, "")
                sF:SetText("  " .. line)
                sF:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                sF:SetWidth(w)
                sF:SetJustifyH("LEFT")
                table.insert(self.frames, sF)
                y = y - 14
            end
        end
    end

    content:SetHeight(math.abs(y) + 60)
end

-- ── Target Grid ───────────────────────────────────────────────────────
function Gear:RenderTargetGrid(content, sidebar, padL, y, w)
    local tName  = UnitName("target")
    local _, tClass = UnitClass("target")
    local tLevel = UnitLevel("target")

    local statText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statText:SetFont(STANDARD_TEXT_FONT, 12, "")
    statText:SetText(string.format("Inspecting: |cFFFFFFFF%s|r  |cFF888780(Level %d %s)|r",
        tName, tLevel, tClass:lower():gsub("^%l", string.upper)))
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
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

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

        local capLink = currentLink
        row:SetScript("OnEnter", function(s)
            row:SetBackdropBorderColor(1, 0.82, 0, 0.8)
            if capLink then GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(capLink); GameTooltip:Show() end
        end)
        row:SetScript("OnLeave", function()
            row:SetBackdropBorderColor(0.35, 0.28, 0.06, 0.4)
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function()
            self:RenderSidebarDetails(sidebar, slotDef.slotID, capLink, nil, 0, 0, true)
        end)

        col = col + 1
        if col >= 2 then col = 0; y = y - 58 end
    end

    local ilvlBox = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlBox:SetFont(STANDARD_TEXT_FONT, 14, "")
    ilvlBox:SetText("True Average iLvl: " .. (count > 0 and math.floor(totalIlvl / count) or 0))
    ilvlBox:SetTextColor(0.64, 0.21, 0.93, 1)
    ilvlBox:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, -10)
    table.insert(self.frames, ilvlBox)

    content:SetHeight(math.abs(y) + 20)
end

-- ── Sidebar details ───────────────────────────────────────────────────
function Gear:RenderSidebarDetails(parent, slotID, curLink, upLink, curScore, upScore, isTarget,
                                    bag, slot, claimedBy, claimedLink, claimedBag, claimedSlot)
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
        y = y - (f:GetStringHeight() or 14) - 6
        table.insert(self.sideFrames, f)
    end

    local function SButton(label, onClick)
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(w - 6, 22)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
        btn:SetText(label)
        btn:SetScript("OnClick", onClick)
        table.insert(self.sideFrames, btn)
        y = y - 28
    end

    if isTarget then
        SLabel("TARGET INSPECTION", 11, 1, 0.82, 0)
        SLabel(curLink and (GetItemInfo(curLink) or "Equipped Item") or "Empty Slot",
               10, curLink and 1 or 0.5, curLink and 1 or 0.5, curLink and 1 or 0.5)
        parent:SetHeight(math.abs(y) + 10)
        return
    end

    SLabel("GEAR SCORE COMPARISON", 11, 1, 0.82, 0)
    if curLink then
        local wI, pI = GetItemIlvls(curLink)
        SLabel("|cFF8B7040Score:|r " .. curScore, 10)
        SLabel("iLvl: " .. wI .. (pI and ("  |cFF00FF00PvP: " .. pI .. "|r") or "  |cFF555555(no PvP)|r"), 9)
        SLabel(GetItemInfo(curLink) or "Equipped Item", 9, 0.55, 0.44, 0.25)
    else
        SLabel("|cFF8B7040Score:|r 0 (Empty)", 10)
    end

    y = y - 4
    if upLink then
        SLabel("|cFF1EFF00[+] Upgrade Ready|r", 10, 0.12, 1.0, 0.0)
        SLabel(GetItemInfo(upLink) or "Upgrade Item", 10, 1, 1, 1)
        SLabel("Score: " .. upScore .. "  |cFF1EFF00(+" .. math.floor(upScore - curScore) .. ")|r", 9, 0.12, 1.0, 0.0)
        SButton("Equip Now", function()
            C_Container.PickupContainerItem(bag, slot)
            EquipCursorItem(slotID)
        end)
    elseif claimedBy then
        SLabel("|cFFAAAAAA[!] Best upgrade claimed by " .. claimedBy .. "|r", 10)
        if claimedLink and claimedBag and claimedSlot then
            SLabel(GetItemInfo(claimedLink) or "Claimed Item", 9, 0.8, 0.8, 0.8)
            SButton("Force Override", function()
                C_Container.PickupContainerItem(claimedBag, claimedSlot)
                EquipCursorItem(slotID)
            end)
        end
    else
        SLabel("[OK] Slot is optimized.", 10, 0.5, 0.5, 0.5)
    end

    -- Enchant sidebar audit
    if curLink then
        y = y - 4
        local isOk, auditStr = AuditItemEnchants(curLink, true)
        SLabel(auditStr ~= "" and auditStr or "|cFF555555[OK] No enchant slot|r", 9)
        if not isOk and auditStr:find("Needs") then
            SButton("Open Professions", function()
                pcall(ToggleSpellBook, BOOKTYPE_PROFESSION)
            end)
        end
    end

    parent:SetHeight(math.abs(y) + 10)
end


-- =============================================================================
-- TOOLTIP INJECTION — ToonAge Score + Upgrade Arrow
-- =============================================================================
-- Hooks GameTooltip to show the item's ToonAge weighted score and whether
-- it's an upgrade over the currently equipped item in that slot.
-- Inspired by Pawn's approach but using ToonAge's own stat weight system.

local TOOLTIP_INJECTED_KEY = "TA_INJECTED"  -- prevent double-injection

-- Slot ID lookup from equip location strings returned by GetItemInfoInstant
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD      = 1,  INVTYPE_NECK      = 2,  INVTYPE_SHOULDER  = 3,
    INVTYPE_BODY      = 4,  INVTYPE_CHEST     = 5,  INVTYPE_ROBE      = 5,
    INVTYPE_WAIST     = 6,  INVTYPE_LEGS      = 7,  INVTYPE_FEET      = 8,
    INVTYPE_WRIST     = 9,  INVTYPE_HAND      = 10,
    INVTYPE_FINGER    = 11, INVTYPE_TRINKET   = 13,
    INVTYPE_CLOAK     = 15, INVTYPE_WEAPON    = 16,
    INVTYPE_SHIELD    = 17, INVTYPE_2HWEAPON  = 16,
    INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE  = 17, INVTYPE_RANGED    = 16,
    INVTYPE_RANGEDRIGHT = 16,
}

local function InjectTooltipScore(tooltip, itemLink)
    if not itemLink then return end
    if not TA.charDB then return end

    -- Prevent double injection (tooltip can fire multiple times for same item)
    if tooltip[TOOLTIP_INJECTED_KEY] == itemLink then return end
    tooltip[TOOLTIP_INJECTED_KEY] = itemLink

    local specID = U.GetPlayerSpec()
    if not specID then return end

    local pvxMode = (TA.charDB and TA.charDB.pvxMode) or "pve"
    local score   = CalculateItemScore(itemLink, specID, pvxMode)
    if not score or score <= 0 then return end

    -- Determine the equip slot to compare against
    local _, _, _, equipLoc = GetItemInfoInstant(itemLink)
    if not equipLoc or equipLoc == "" then return end
    local slotID = EQUIP_LOC_TO_SLOT[equipLoc]
    if not slotID then return end

    -- Get currently equipped item score for comparison
    local equippedLink = GetInventoryItemLink("player", slotID)
    local equippedScore = 0
    if equippedLink then
        equippedScore = CalculateItemScore(equippedLink, specID, pvxMode)
    end

    -- For rings/trinkets, check both slots and use the lower score
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

    -- Build the tooltip line
    tooltip:AddLine(" ")
    tooltip:AddLine("ToonAge Score", 0.40, 0.75, 1.00)

    local diff = score - equippedScore
    if equippedScore > 0 and diff > 0 then
        local pct = math.floor((diff / equippedScore) * 100)
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            "|TInterface\\Buttons\\UI-GroupLoot-Dice-Up:14:14:0:0|t |cFF4AFF7A+" .. pct .. "% upgrade|r",
            0.92, 0.90, 0.87,
            0.30, 0.92, 0.40
        )
    elseif equippedScore > 0 and diff < 0 then
        local pct = math.floor((math.abs(diff) / equippedScore) * 100)
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            "|cFFFF6666-" .. pct .. "% downgrade|r",
            0.92, 0.90, 0.87,
            1.00, 0.40, 0.40
        )
    else
        tooltip:AddDoubleLine(
            string.format("Score: %d", math.floor(score)),
            equippedScore > 0 and "|cFFAAAAAAAAequal|r" or "|cFFAAAAAAAAno comparison|r",
            0.92, 0.90, 0.87,
            0.60, 0.60, 0.60
        )
    end

    tooltip:Show()
end

-- ── Hook GameTooltip methods ──────────────────────────────────────────────────
-- We hook after the tooltip is populated (hooksecurefunc runs AFTER the
-- original), extract the item link, and inject our score line.

local function OnTooltipSetItem(tooltip)
    if not tooltip or not tooltip.GetItem then return end
    local _, itemLink = tooltip:GetItem()
    if itemLink then
        InjectTooltipScore(tooltip, itemLink)
    end
end

-- Clear injection flag when tooltip is cleared
local function OnTooltipCleared(tooltip)
    if tooltip then
        tooltip[TOOLTIP_INJECTED_KEY] = nil
    end
end

-- Register hooks on Gear:Init() — deferred so we don't hook before the game
-- has fully loaded tooltip infrastructure.
local origInit = Gear.Init
function Gear:Init()
    origInit(self)

    -- Hook the primary GameTooltip
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- Retail 10.0.2+ tooltip data system
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                local _, itemLink = tooltip:GetItem()
                if itemLink then
                    InjectTooltipScore(tooltip, itemLink)
                end
            end
        end)
    else
        -- Legacy hook path
        hooksecurefunc(GameTooltip, "SetBagItem", function(tt, bag, slot)
            local itemLink = C_Container and C_Container.GetContainerItemLink(bag, slot)
                          or GetContainerItemLink(bag, slot)
            if itemLink then InjectTooltipScore(tt, itemLink) end
        end)
        hooksecurefunc(GameTooltip, "SetInventoryItem", function(tt, unit, slot)
            local itemLink = GetInventoryItemLink(unit, slot)
            if itemLink then InjectTooltipScore(tt, itemLink) end
        end)
        hooksecurefunc(GameTooltip, "SetHyperlink", function(tt, link)
            if link and link:match("^item:") then
                InjectTooltipScore(tt, link)
            end
        end)
        hooksecurefunc(GameTooltip, "SetMerchantItem", function(tt, index)
            local itemLink = GetMerchantItemLink(index)
            if itemLink then InjectTooltipScore(tt, itemLink) end
        end)
        hooksecurefunc(GameTooltip, "SetQuestItem", function(tt, type, index)
            local itemLink = GetQuestItemLink(type, index)
            if itemLink then InjectTooltipScore(tt, itemLink) end
        end)
        hooksecurefunc(GameTooltip, "SetQuestLogItem", function(tt, type, index)
            local itemLink = GetQuestLogItemLink(type, index)
            if itemLink then InjectTooltipScore(tt, itemLink) end
        end)
    end

    -- Clear flag on tooltip hide
    GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    if ItemRefTooltip then
        ItemRefTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    end
end
