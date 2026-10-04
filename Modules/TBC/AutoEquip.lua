-- ToonAge/Modules/TBC/AutoEquip.lua (TBC Anniversary — 20506; originally ported from the MoP build)
-- Automatically equips item-level upgrades when looted, if the player has
-- opted in via the "Auto-equip upgrades" checkbox in the Tracker options.
--
-- Classic adaptations:
--   • Container API via U.GetContainerItemLink/U.GetContainerNumSlots/U.GetContainerItemID
--   • No domination sockets, no tertiary stats
--   • Corrected 2026-09-06: this module does NOT call GetSpecialization
--     itself (the earlier comment here was stale/inaccurate). Spec-aware
--     scoring is delegated entirely to the Gear module: BestSlotForItem()
--     calls GearMod.CalculateItemScore(itemLink), which takes a specID
--     parameter — the actual GetSpecialization()/GetSpecializationInfo()
--     call lives in Core/Utils.lua's U.GetPlayerSpec().
--   • Stat-weight comparison via Modules/TBC/Gear.lua CalculateItemScore (cap-aware
--     TBC role weights from Data/TBC/TBCWeights.lua). Data/TBC/StatWeights.lua was a
--     copy of the MoP table (Mastery, Monks, Death Knights) and is no longer loaded.
--   • TBC classes only (no Death Knight, Monk, Demon Hunter or Evoker)
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
    -- Zygor can equip gear too; two addons swapping items fight each other.
    if U.DeferToZygor and U.DeferToZygor() then return false end
    return TA.charDB
        and TA.charDB.tracker
        and TA.charDB.tracker.autoEquip
end

local function InPvPInstance()
    local _, iType = IsInInstance()
    return iType == "pvp" or iType == "arena"
end

-- Effective item level: GetItemInfo's 4th return is the BASE level, which is
-- wrong for scaled/upgraded/timewalking items on Retail. GetDetailedItemLevelInfo
-- reads the link's bonus IDs; used when the client has it, base level otherwise.
local function EffectiveIlvl(link)
    local detailed = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
    if detailed then
        local ok, eff = pcall(detailed, link)
        if ok and type(eff) == "number" and eff > 0 then return eff end
    end
    -- TBC has no item upgrades or scaling: the base level IS the level.
    local _, _, _, ilvl = GetItemInfo(link)
    return ilvl or 0
end

local function EquippedIlvl(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return 0 end
    return EffectiveIlvl(link) or 0
end

-- Find the bag slot holding THIS item (2026-10-03). Exact link first: two
-- copies of one item ID can differ in bonus IDs (upgrade track, crafted rank,
-- scaling), and matching on ID alone could equip the other copy. Falls back
-- to item ID only when exactly one copy of that ID is in the bags.
local function FindItemInBags(itemLink)
    if not itemLink then return nil end
    local targetID = tonumber(itemLink:match("item:(%d+)"))
    if not targetID then return nil end
    local idBag, idSlot, idCount = nil, nil, 0
    for bag = 0, 4 do
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
                   or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for slot = 1, slots do
            local link = (C_Container and C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot))
                      or (GetContainerItemLink and GetContainerItemLink(bag, slot))
            if link then
                if link == itemLink then return bag, slot end
                if tonumber(link:match("item:(%d+)")) == targetID then
                    idCount = idCount + 1
                    idBag, idSlot = bag, slot
                end
            end
        end
    end
    if idCount == 1 then return idBag, idSlot end
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

-- ── Safety rules (G5, 2026-10-03) ─────────────────────────────────────────────
-- 1. Never in combat. Armour can't be equipped in combat at all (the item would
--    sit on the cursor); weapons can, but a mid-fight swap is never wanted.
--    The link is queued and retried on PLAYER_REGEN_ENABLED.
-- 2. Never a Bind-on-Equip / Bind-on-Use item. Everything evaluated here was
--    just looted, so a BoE item is still unbound and sellable: equipping it
--    would bind it (behind the game's own confirm, which is one reflex click
--    away). bindType is GetItemInfo's 14th return (0 none, 1 BoP, 2 BoE,
--    3 BoU, 4 quest). If it can't be read, the item is skipped -- the
--    gold-costing mistake is worse than a missed upgrade.
-- 3. Never over something the player is holding, and never leave the cursor
--    loaded: if the equip didn't take, the cursor is cleared.
local BIND_ON_EQUIP, BIND_ON_USE = 2, 3
AE._combatQueue = AE._combatQueue or {}

local function BindType(itemLink)
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not getInfo then return nil end
    local info = { pcall(getInfo, itemLink) }
    if not info[1] then return nil end
    return info[15]   -- pcall's ok flag shifts GetItemInfo's 14th return to 15
end

local function EvaluateItem(itemLink)
    if not itemLink then return end
    if IsShiftKeyDown() then return end
    if InPvPInstance() then return end

    local _, _, _, ilvl, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    if ilvl then ilvl = EffectiveIlvl(itemLink) end
    if not ilvl then return end   -- level unknown on this client: skip, don't guess
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

    if InCombatLockdown() then
        AE._combatQueue[#AE._combatQueue + 1] = itemLink
        return
    end
    local bind = BindType(itemLink)
    if bind == nil or bind == BIND_ON_EQUIP or bind == BIND_ON_USE then
        if bind ~= nil then
            TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r %s is an upgrade but binds when equipped -- "
                .. "left in your bags so it can still be sold. Equip it yourself to keep it.",
                itemLink))
        end
        return
    end
    if CursorHasItem and CursorHasItem() then return end

    -- Equip: C_Container first (the container globals are gone on the modern
    -- Classic clients), global as the fallback for clients that still have it.
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then
        PickupContainerItem(bag, slot)
    else
        return
    end
    EquipCursorItem(targetSlot)
    if CursorHasItem and CursorHasItem() then
        ClearCursor()
        return
    end

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

    if event == "PLAYER_REGEN_ENABLED" then
        local q = self._combatQueue
        if #q == 0 then return end
        self._combatQueue = {}
        for _, link in ipairs(q) do EvaluateItem(link) end
        return
    end

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
    TA:RegisterEvent("LOOT_OPENED")
    TA:RegisterEvent("BAG_UPDATE_DELAYED")
    TA:RegisterEvent("PLAYER_REGEN_ENABLED")   -- retry upgrades looted in combat

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
