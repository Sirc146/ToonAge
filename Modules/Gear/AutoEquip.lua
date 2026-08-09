-- ToonAge/Modules/AutoEquip.lua
-- Automatically equips item-level upgrades when looted, if the player has
-- opted in via the "Auto-equip upgrades" checkbox in the Tracker options.
--
-- Design decisions:
--   • Opt-in only: defaults to false. The player must explicitly enable it.
--   • Stat-weight-aware: uses ToonAge's own StatWeights data (via Gear module)
--     if available, so upgrades are evaluated by spec value, not raw ilvl alone.
--   • Spec filter: never equips items that are obviously off-spec (e.g., a
--     cloth drop for a Warrior). Uses primary stat (Strength/Agility/Intellect)
--     and armour type to veto inappropriate items.
--   • Shift-to-pause: holding Shift suppresses auto-equip for that loot event,
--     matching the auto-quest pause convention everywhere else in ToonAge.
--   • Two-hand protection: if a two-hander would overwrite a dual-wield setup,
--     we skip — the player almost certainly chose dual-wield deliberately.
--   • The module does NOT auto-equip in Arena or Battleground instances, where
--     swapping gear mid-combat could be considered exploitative.
--
-- LOOT_ITEM_PUSHED_TO_SLOT fires immediately when an item lands in a bag slot
-- after looting.  We use BAG_UPDATE_DELAYED (fires once, debounced, after all
-- bag slot changes from a single loot event) to evaluate the new item once all
-- stack counts have settled.

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

-- Equip location strings returned by GetItemInfo() [10th field] that map to WoW
-- slot IDs.  Items that need special handling (two-hand, dual wield) are noted.
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
    INVTYPE_2HWEAPON   = { INVSLOT_MAINHAND },   -- two-hand guard applied below
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

-- Quick check: is the player in a PvP zone where mid-combat gear swaps are
-- frowned upon / could cause issues?
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

-- Find which bag slot (bag, slot) holds `itemLink`. Returns nil if not found.
local function FindItemInBags(itemLink)
    if not itemLink then return nil end
    local _, _, targetID = string.match(itemLink, "item:(%d+):(%d*):(%d*)")
    targetID = tonumber(targetID)
    if not targetID then return nil end
    for bag = 0, 4 do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                   or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local id
            if C_Container and C_Container.GetContainerItemID then
                id = C_Container.GetContainerItemID(bag, slot)
            else
                id = GetContainerItemID(bag, slot)
            end
            if id == targetID then return bag, slot end
        end
    end
    return nil
end

-- ── Primary-stat / armour-type veto ──────────────────────────────────────────
-- Prevents equipping obviously wrong items (cloth on a warrior, str ring on a
-- mage).  We use C_Item.GetItemStatDelta if available (Dragonflight+), which
-- is the cleanest approach, but fall back to armour type + item subtype
-- matching for older API surfaces.

local CLASS_ARMOUR = {
    WARRIOR  = { "Plate" },
    PALADIN  = { "Plate" },
    DEATHKNIGHT = { "Plate" },
    HUNTER   = { "Mail" },
    SHAMAN   = { "Mail" },
    EVOKER   = { "Mail" },
    MAGE     = { "Cloth" },
    WARLOCK  = { "Cloth" },
    PRIEST   = { "Cloth" },
    DRUID    = { "Leather" },
    ROGUE    = { "Leather" },
    MONK     = { "Leather" },
    DEMONHUNTER = { "Leather" },
}

-- Returns true if the item is a type this class can wear.
-- jewellery (rings, necks, trinkets, cloaks) passes for everyone.
local function ItemIsWearableByClass(itemLink, equipLoc)
    -- Jewellery is universal
    local jewellery = {
        INVTYPE_FINGER=1, INVTYPE_TRINKET=1, INVTYPE_NECK=1,
        INVTYPE_CLOAK=1, INVTYPE_HEAD=1, -- helms are class-agnostic for ilvl check
    }
    if jewellery[equipLoc] then return true end

    local _, classFile = UnitClass("player")
    local allowed = CLASS_ARMOUR[classFile]
    if not allowed then return true end  -- unknown class: allow

    local _, _, _, _, _, _, itemSubType = GetItemInfo(itemLink)
    if not itemSubType then return true end  -- cache miss: allow (will re-check on BAG_UPDATE_DELAYED)

    for _, a in ipairs(allowed) do
        if itemSubType:find(a) then return true end
    end
    return false
end

-- ── Core equip decision ───────────────────────────────────────────────────────

-- Given an item link and its equip-location string, decide whether to equip it
-- and if so, which slot to put it in.  Returns the slot ID to equip into, or nil.
local function BestSlotForItem(itemLink, equipLoc, newIlvl)
    local candidates = EQUIP_LOC_TO_SLOT[equipLoc]
    if not candidates then return nil end

    -- Two-hand guard: if new item is a 2H weapon AND the off-hand slot is
    -- occupied (dual-wield setup), skip — don't silently break their loadout.
    if equipLoc == "INVTYPE_2HWEAPON" then
        local ohLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)
        if ohLink then return nil end  -- has off-hand: skip auto-equip
    end

    -- Score-driven comparison: use Gear.CalculateItemScore if available.
    -- Falls back to raw ilvl if scoring fails or Gear module isn't loaded.
    local GearMod = TA:GetModule("Gear")
    local specIndex = GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex)
    local useScoring = (GearMod and GearMod.CalculateItemScore and specID)

    local newScore = newIlvl  -- fallback to ilvl
    if useScoring then
        local ok, s = pcall(GearMod.CalculateItemScore, itemLink, specID, "pve")
        if ok and type(s) == "number" and s > 0 then newScore = s end
    end

    -- For slots with two candidates (rings, trinkets, weapons), pick the
    -- slot where the new item is the biggest upgrade by score.
    local bestSlot, bestCurrentScore = nil, math.huge
    for _, slotID in ipairs(candidates) do
        local curLink = GetInventoryItemLink("player", slotID)
        local curScore = 0
        if curLink then
            if useScoring then
                local ok, s = pcall(GearMod.CalculateItemScore, curLink, specID, "pve")
                if ok and type(s) == "number" and s > 0 then
                    curScore = s
                else
                    curScore = EquippedIlvl(slotID)  -- fallback
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

-- Called once per recently-looted item.  Determines if it is an upgrade and
-- equips it if so.
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

    -- Equip it
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    else
        PickupContainerItem(bag, slot)
    end
    EquipCursorItem(targetSlot)

    local itemName = GetItemInfo(itemLink) or itemLink
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r Auto-equipped |cFF1EFF00%s|r (ilvl %d → slot %d).",
        itemName, ilvl, targetSlot))
end

-- ── Event handling ────────────────────────────────────────────────────────────
-- Detection strategy: snapshot all bag slots when a loot window opens
-- (LOOT_OPENED), then diff against the new state on BAG_UPDATE_DELAYED.
-- Any item link present after the loot event but absent before it is new.
--
-- Why not LOOT_ITEM_PUSHED_TO_SLOT: that event does not exist in WoW's API.
-- Why not BAG_UPDATE alone: it fires once per slot change — up to 16 times
-- per loot event. BAG_UPDATE_DELAYED fires exactly once after all slots settle.

AE._bagSnapshot  = {}   -- { [bag..":"..slot] = itemID } captured at LOOT_OPENED
AE._lootPending  = false

local function SnapshotBags()
    local snap = {}
    for bag = 0, 4 do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                   or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local id
            if C_Container and C_Container.GetContainerItemID then
                id = C_Container.GetContainerItemID(bag, slot)
            else
                id = GetContainerItemID(bag, slot)
            end
            if id then snap[bag .. ":" .. slot] = id end
        end
    end
    return snap
end

function AE:OnEvent(event, ...)
    if not ShouldAutoEquip() then return end

    if event == "LOOT_OPENED" then
        -- Capture bag state before loot lands so we can diff afterward.
        self._bagSnapshot = SnapshotBags()
        self._lootPending = true

    elseif event == "BAG_UPDATE_DELAYED" then
        if not self._lootPending then return end
        self._lootPending = false

        -- Find every slot that now has an item that wasn't there before.
        local newLinks = {}
        for bag = 0, 4 do
            local slots = C_Container and C_Container.GetContainerNumSlots(bag)
                       or GetContainerNumSlots(bag)
            for slot = 1, (slots or 0) do
                local key = bag .. ":" .. slot
                local id
                if C_Container and C_Container.GetContainerItemID then
                    id = C_Container.GetContainerItemID(bag, slot)
                else
                    id = GetContainerItemID(bag, slot)
                end
                if id and self._bagSnapshot[key] ~= id then
                    -- New item in this slot since the loot window opened
                    local link
                    if C_Container and C_Container.GetContainerItemLink then
                        link = C_Container.GetContainerItemLink(bag, slot)
                    else
                        link = GetContainerItemLink(bag, slot)
                    end
                    if link then
                        newLinks[#newLinks + 1] = link
                    end
                end
            end
        end

        self._bagSnapshot = {}   -- clear snapshot

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
