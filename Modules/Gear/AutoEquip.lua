-- ToonAge/Modules/AutoEquip.lua (Classic — MoP 50504)
-- Automatically equips item-level upgrades when looted, if the player has
-- opted in via the "Auto-equip upgrades" checkbox in the Tracker options.
--
-- Classic adaptations:
--   • Container API via U.GetContainerItemLink/U.GetContainerNumSlots/U.GetContainerItemID
--   • No domination sockets, no tertiary stats
--   • No GetSpecialization/GetSpecializationInfo — use GetActiveSpecGroup + GetSpecializationInfo
--   • Stat-weight comparison via TA.Data.StatWeights
--   • No Evoker or Demon Hunter classes
--   • Uses GetItemInfo for item stats
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local AE = {}
TA:RegisterModule("AutoEquip", AE)

-- WoW inventory slot IDs we can auto-equip into.
local EQUIP_SLOTS = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK,
    INVSLOT_CHEST, INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_WAIST,
    INVSLOT_LEGS, INVSLOT_FEET,
    INVSLOT_FINGER1, INVSLOT_FINGER2,
    INVSLOT_TRINKET1, INVSLOT_TRINKET2,
    INVSLOT_MAINHAND, INVSLOT_OFFHAND,
}

-- Equip location strings returned by GetItemInfo() mapped to slot IDs.
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD       = { INVSLOT_HEAD },
    INVTYPE_NECK       = { INVSLOT_NECK },
    INVTYPE_SHOULDER   = { INVSLOT_SHOULDER },
    INVTYPE_CLOAK      = { INVSLOT_BACK },
    INVTYPE_CHEST      = { INVSLOT_CHEST },
    INVTYPE_ROBE       = { INVSLOT_CHEST },
    INVTYPE_WRIST      = { INVSLOT_WRIST },
    INVTYPE_HAND       = { INVSLOT_HAND },
    INVTYPE_WAIST      = { INVSLOT_WAIST },
    INVTYPE_LEGS       = { INVSLOT_LEGS },
    INVTYPE_FEET       = { INVSLOT_FEET },
    INVTYPE_FINGER     = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    INVTYPE_TRINKET    = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_WEAPON     = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_2HWEAPON   = { INVSLOT_MAINHAND },
    INVTYPE_SHIELD     = { INVSLOT_OFFHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND  = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE   = { INVSLOT_OFFHAND },
    INVTYPE_RANGED     = { INVSLOT_MAINHAND },
    INVTYPE_RANGEDRIGHT = { INVSLOT_MAINHAND },
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function ShouldAutoEquip()
    return TA.charDB
        and TA.charDB.tracker
        and TA.charDB.tracker.autoEquip
end

local function InPvPInstance()
    local _, iType = IsInInstance()
    return iType == "pvp" or iType == "arena"
end

-- Return the equipped ilvl for a specific slot (0 if empty).
local function EquippedIlvl(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return 0 end
    local _, _, _, ilvl = GetItemInfo(link)
    return ilvl or 0
end

-- Find which bag slot (bag, slot) holds an item with the given itemID.
local function FindItemInBags(itemLink)
    if not itemLink then return nil end
    -- Extract itemID from the link
    local targetID = tonumber(itemLink:match("item:(%d+)"))
    if not targetID then return nil end
    for bag = 0, 4 do
        local slots = U.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local id = U.GetContainerItemID(bag, slot)
            if id == targetID then return bag, slot end
        end
    end
    return nil
end

-- ── Armour-type veto ──────────────────────────────────────────────────────────
-- Prevents equipping obviously wrong items (cloth on a warrior, etc.)

local CLASS_ARMOUR = {
    WARRIOR     = { "Plate" },
    PALADIN     = { "Plate" },
    DEATHKNIGHT = { "Plate" },
    HUNTER      = { "Mail" },
    SHAMAN      = { "Mail" },
    MAGE        = { "Cloth" },
    WARLOCK     = { "Cloth" },
    PRIEST      = { "Cloth" },
    DRUID       = { "Leather" },
    ROGUE       = { "Leather" },
    MONK        = { "Leather" },
}

local function ItemIsWearableByClass(itemLink, equipLoc)
    -- Jewellery is universal
    local jewellery = {
        INVTYPE_FINGER=1, INVTYPE_TRINKET=1, INVTYPE_NECK=1,
        INVTYPE_CLOAK=1,
    }
    if jewellery[equipLoc] then return true end

    local _, classFile = UnitClass("player")
    local allowed = CLASS_ARMOUR[classFile]
    if not allowed then return true end  -- unknown class: allow

    local _, _, _, _, _, _, itemSubType = GetItemInfo(itemLink)
    if not itemSubType then return true end  -- cache miss: allow

    for _, a in ipairs(allowed) do
        if itemSubType:find(a) then return true end
    end
    return false
end

-- ── Core equip decision ───────────────────────────────────────────────────────

local function BestSlotForItem(itemLink, equipLoc, newIlvl)
    local candidates = EQUIP_LOC_TO_SLOT[equipLoc]
    if not candidates then return nil end

    -- Two-hand guard: if new item is a 2H weapon AND the off-hand slot is
    -- occupied, skip — don't silently break their loadout.
    if equipLoc == "INVTYPE_2HWEAPON" then
        local ohLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)
        if ohLink then return nil end
    end

    -- Stat-weight scoring via Gear module if available
    local GearMod = TA:GetModule("Gear")
    local useScoring = (GearMod and GearMod.CalculateItemScore)

    local newScore = newIlvl  -- fallback to ilvl
    if useScoring then
        local ok, s = pcall(GearMod.CalculateItemScore, itemLink)
        if ok and type(s) == "number" and s > 0 then newScore = s end
    end

    -- For slots with two candidates (rings, trinkets, weapons), pick the
    -- slot where the new item is the biggest upgrade.
    local bestSlot, bestCurrentScore = nil, math.huge
    for _, slotID in ipairs(candidates) do
        local curLink = GetInventoryItemLink("player", slotID)
        local curScore = 0
        if curLink then
            if useScoring then
                local ok, s = pcall(GearMod.CalculateItemScore, curLink)
                if ok and type(s) == "number" and s > 0 then
                    curScore = s
                else
                    curScore = EquippedIlvl(slotID)
                end
            else
                curScore = EquippedIlvl(slotID)
            end
        end

        -- Only equip if new item scores HIGHER than what's in the slot
        if newScore > curScore and curScore < bestCurrentScore then
            bestCurrentScore = curScore
            bestSlot = slotID
        end
    end

    return bestSlot
end

-- ── Item evaluation ───────────────────────────────────────────────────────────

local function EvaluateItem(itemLink)
    if not itemLink then return end
    if IsShiftKeyDown() then return end
    if InPvPInstance() then return end

    local _, _, _, ilvl, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    if not ilvl or ilvl == 0 then return end
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then return end

    -- Armour-type veto
    if not ItemIsWearableByClass(itemLink, equipLoc) then return end

    -- Find the best slot (ilvl upgrade check included)
    local targetSlot = BestSlotForItem(itemLink, equipLoc, ilvl)
    if not targetSlot then return end

    -- Locate the item in bags
    local bag, slot = FindItemInBags(itemLink)
    if not bag then return end

    -- Equip it via PickupContainerItem + EquipCursorItem
    PickupContainerItem(bag, slot)
    EquipCursorItem(targetSlot)

    local itemName = GetItemInfo(itemLink) or itemLink
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r Auto-equipped |cFF1EFF00%s|r (ilvl %d → slot %d).",
        itemName, ilvl, targetSlot))
end

-- ── Event handling ────────────────────────────────────────────────────────────
-- Snapshot bags at LOOT_OPENED, diff on BAG_UPDATE_DELAYED

AE._bagSnapshot  = {}
AE._lootPending  = false

local function SnapshotBags()
    local snap = {}
    for bag = 0, 4 do
        local slots = U.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local id = U.GetContainerItemID(bag, slot)
            if id then snap[bag .. ":" .. slot] = id end
        end
    end
    return snap
end

function AE:OnEvent(event, ...)
    if not ShouldAutoEquip() then return end

    if event == "LOOT_OPENED" then
        -- Capture bag state before loot lands
        self._bagSnapshot = SnapshotBags()
        self._lootPending = true

    elseif event == "BAG_UPDATE_DELAYED" then
        if not self._lootPending then return end
        self._lootPending = false

        -- Find every slot that now has an item that wasn't there before
        local newLinks = {}
        for bag = 0, 4 do
            local slots = U.GetContainerNumSlots(bag)
            for slot = 1, slots do
                local key = bag .. ":" .. slot
                local id = U.GetContainerItemID(bag, slot)
                if id and self._bagSnapshot[key] ~= id then
                    local link = U.GetContainerItemLink(bag, slot)
                    if link then
                        newLinks[#newLinks + 1] = link
                    end
                end
            end
        end

        self._bagSnapshot = {}

        for _, link in ipairs(newLinks) do
            EvaluateItem(link)
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function AE:Init()
    TA.eventFrame:RegisterEvent("LOOT_OPENED")
    TA.eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

    -- Default opt-in flag
    if TA.charDB and TA.charDB.tracker then
        if TA.charDB.tracker.autoEquip == nil then
            TA.charDB.tracker.autoEquip = false
        end
    end

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r AutoEquip module loaded.")
    end
end
