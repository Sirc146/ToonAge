-- ToonAge/Modules/Gear/GearSets.lua
-- Named equipment profiles saved per-character with automatic swap triggers.
--
-- Features:
--   • Save current equipped gear as a named set
--   • Equip a saved set by name
--   • List all saved sets for this character
--   • Auto-swap triggers: entering BG → PvP set, spec change → assigned set
--   • Delete a saved set
--
-- Storage: TA.charDB.gearSets = { [setName] = { slots = {[slotID] = itemID}, specID = number|nil, pvp = bool|nil } }
-- Slash: /ta gear save <name>, /ta gear equip <name>, /ta gear list, /ta gear delete <name>
--        /ta gear assign <name> <spec|pvp> — auto-swap trigger binding

local TA = ToonAge
local U = TA.Utils

local GS = {}
TA:RegisterModule("GearSets", GS)

-- All equippable slot IDs (modern WoW — no ranged slot)
local SLOT_IDS = {
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_SHOULDER,
    INVSLOT_BACK,
    INVSLOT_CHEST,
    INVSLOT_WRIST,
    INVSLOT_HAND,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
    INVSLOT_TABARD,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Snapshot currently equipped items by slot.
--- @return table — { [slotID] = itemLink }
local function SnapshotEquipped()
    local snapshot = {}
    for _, slotID in ipairs(SLOT_IDS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            snapshot[slotID] = link
        end
    end
    return snapshot
end

--- Find an item in bags matching the given item link.
--- Returns bag, slot if found, nil otherwise.
--- @param itemLink string
--- @return number|nil, number|nil
local function FindInBags(itemLink)
    if not itemLink then
        return nil, nil
    end
    local targetID = GetItemInfoInstant(itemLink)
    if not targetID then
        return nil, nil
    end

    -- First pass: exact link match (catches enchant/gem differences)
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == targetID then
                local bagLink = C_Container.GetContainerItemLink(bag, slot)
                if bagLink == itemLink then
                    return bag, slot
                end
            end
        end
    end

    -- Second pass: match by itemID only (good enough for most gear)
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == targetID then
                return bag, slot
            end
        end
    end

    return nil, nil
end

--- Check if the player is in a state where gear swapping is safe.
--- @return boolean, string|nil — true if safe, or false + reason
local function CanSwapGear()
    if InCombatLockdown() then
        return false, "Cannot swap gear in combat."
    end
    if UnitIsDeadOrGhost("player") then
        return false, "Cannot swap gear while dead."
    end
    return true, nil
end

-- ── Core API ──────────────────────────────────────────────────────────────────

--- Save the currently equipped gear as a named set.
--- @param name string
function GS:SaveSet(name)
    if not name or name == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r Set name required.")
        return
    end

    local db = TA.charDB.gearSets
    local snapshot = SnapshotEquipped()

    -- Count items to verify we have something to save
    local count = 0
    for _ in pairs(snapshot) do
        count = count + 1
    end

    if count == 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r No gear equipped — nothing to save.")
        return
    end

    local isNew = db[name] == nil
    db[name] = db[name] or {}
    db[name].slots = snapshot

    if isNew then
        TA:Raw(
            TA.LOG.OUTPUT,
            string.format("|cFFFFD100[TA GearSets]|r Saved new set: |cFF4AFF7A%s|r (%d items)", name, count)
        )
    else
        TA:Raw(
            TA.LOG.OUTPUT,
            string.format("|cFFFFD100[TA GearSets]|r Updated set: |cFF4AFF7A%s|r (%d items)", name, count)
        )
    end
end

--- Equip a saved gear set by name.
--- @param name string
--- @return boolean — true if equip was attempted
function GS:EquipSet(name)
    if not name or name == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r Set name required.")
        return false
    end

    local db = TA.charDB.gearSets
    local set = db[name]
    if not set or not set.slots then
        TA:Raw(TA.LOG.OUTPUT, string.format('|cFFFF4444[TA GearSets]|r Set "%s" not found.', name))
        return false
    end

    local canSwap, reason = CanSwapGear()
    if not canSwap then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r " .. reason)
        return false
    end

    local equipped = 0
    local skipped = 0

    for slotID, itemLink in pairs(set.slots) do
        -- Check if already wearing this item in this slot
        local currentLink = GetInventoryItemLink("player", slotID)
        if currentLink == itemLink then
            -- Already equipped — skip
        else
            -- Try to find the item in bags and equip it
            local bag, slot = FindInBags(itemLink)
            if bag and slot then
                -- Pickup from bag, then place into equipment slot
                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(bag, slot)
                else
                    PickupContainerItem(bag, slot)
                end
                EquipCursorItem(slotID)
                equipped = equipped + 1
            else
                -- Item not in bags — it might be equipped in a different slot,
                -- or not in inventory at all. Skip silently.
                skipped = skipped + 1
            end
        end
    end

    local msg = string.format("|cFFFFD100[TA GearSets]|r Equipping |cFF4AFF7A%s|r", name)
    if equipped > 0 then
        msg = msg .. string.format(" — %d items swapped", equipped)
    end
    if skipped > 0 then
        msg = msg .. string.format(" (%d unavailable)", skipped)
    end
    TA:Raw(TA.LOG.OUTPUT, msg)

    return true
end

--- Delete a saved gear set.
--- @param name string
function GS:DeleteSet(name)
    if not name or name == "" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r Set name required.")
        return
    end

    local db = TA.charDB.gearSets
    if not db[name] then
        TA:Raw(TA.LOG.OUTPUT, string.format('|cFFFF4444[TA GearSets]|r Set "%s" not found.', name))
        return
    end

    db[name] = nil
    TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA GearSets]|r Deleted set: |cFFFF6666%s|r", name))
end

--- List all saved gear sets for this character.
function GS:ListSets()
    local db = TA.charDB.gearSets
    local count = 0
    for name, set in pairs(db) do
        count = count + 1
        local slotCount = 0
        if set.slots then
            for _ in pairs(set.slots) do
                slotCount = slotCount + 1
            end
        end

        local tags = {}
        if set.specID then
            local _, specName = GetSpecializationInfoByID(set.specID)
            table.insert(tags, "spec:" .. (specName or tostring(set.specID)))
        end
        if set.pvp then
            table.insert(tags, "|cFFFF4444PvP auto|r")
        end

        local tagStr = #tags > 0 and (" [" .. table.concat(tags, ", ") .. "]") or ""
        TA:Raw(TA.LOG.OUTPUT, string.format("  |cFF4AFF7A%s|r — %d items%s", name, slotCount, tagStr))
    end

    if count == 0 then
        TA:Raw(
            TA.LOG.OUTPUT,
            "|cFFFFD100[TA GearSets]|r No saved sets. Use |cFFFFD100/ta gear save <name>|r to create one."
        )
    else
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA GearSets]|r %d set(s) saved.", count))
    end
end

--- Assign a set to automatically equip on spec change or BG entry.
--- @param name string — set name
--- @param trigger string — "spec" (assigns to current spec) or "pvp"
function GS:AssignTrigger(name, trigger)
    local db = TA.charDB.gearSets
    if not db[name] then
        TA:Raw(TA.LOG.OUTPUT, string.format('|cFFFF4444[TA GearSets]|r Set "%s" not found.', name))
        return
    end

    if trigger == "pvp" then
        -- Clear any other set's PvP flag
        for _, set in pairs(db) do
            set.pvp = nil
        end
        db[name].pvp = true
        TA:Raw(
            TA.LOG.OUTPUT,
            string.format('|cFFFFD100[TA GearSets]|r Set "%s" will auto-equip when entering PvP.', name)
        )
    elseif trigger == "spec" then
        -- Assign to the player's current active spec
        local specIndex = GetSpecialization()
        local specID = specIndex and GetSpecializationInfo(specIndex)
        if not specID then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r Cannot detect current spec.")
            return
        end
        -- Clear any other set assigned to this specID
        for _, set in pairs(db) do
            if set.specID == specID then
                set.specID = nil
            end
        end
        db[name].specID = specID
        local _, specName = GetSpecializationInfoByID(specID)
        TA:Raw(
            TA.LOG.OUTPUT,
            string.format(
                '|cFFFFD100[TA GearSets]|r Set "%s" will auto-equip for %s spec.',
                name,
                specName or "current"
            )
        )
    else
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[TA GearSets]|r Usage: /ta gear assign <name> spec|pvp")
    end
end

-- ── Event Triggers ────────────────────────────────────────────────────────────

function GS:OnEvent(event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:OnSpecChange()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        self:OnZoneChange()
    end
end

function GS:OnSpecChange()
    if InCombatLockdown() then
        return
    end

    local specIndex = GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex)
    if not specID then
        return
    end

    local db = TA.charDB.gearSets
    for name, set in pairs(db) do
        if set.specID == specID then
            -- Small delay to let spec change finish
            C_Timer.After(0.5, function()
                if not InCombatLockdown() then
                    GS:EquipSet(name)
                end
            end)
            return
        end
    end
end

function GS:OnZoneChange()
    if InCombatLockdown() then
        return
    end

    -- Detect if entering a PvP instance
    local _, instanceType = IsInInstance()
    local isPvP = (instanceType == "pvp") or (instanceType == "arena")

    if isPvP then
        local db = TA.charDB.gearSets
        for name, set in pairs(db) do
            if set.pvp then
                C_Timer.After(0.5, function()
                    if not InCombatLockdown() then
                        GS:EquipSet(name)
                    end
                end)
                return
            end
        end
    end
end

-- ── Slash command parsing ─────────────────────────────────────────────────────

function GS:HandleSlash(args)
    if not args or args == "" then
        self:ListSets()
        return
    end

    local cmd, rest = args:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or ""
    rest = rest and rest:match("^%s*(.-)%s*$") or ""

    if cmd == "save" then
        self:SaveSet(rest)
    elseif cmd == "equip" or cmd == "wear" or cmd == "use" then
        self:EquipSet(rest)
    elseif cmd == "delete" or cmd == "remove" or cmd == "del" then
        self:DeleteSet(rest)
    elseif cmd == "list" then
        self:ListSets()
    elseif cmd == "assign" then
        local name, trigger = rest:match("^(.-)%s+(%S+)$")
        if name and trigger then
            self:AssignTrigger(name, trigger:lower())
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA GearSets]|r Usage: /ta gear assign <setname> spec|pvp")
        end
    else
        -- Maybe they typed the set name directly: /ta gear <name> → equip it
        if TA.charDB.gearSets[args] then
            self:EquipSet(args)
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA GearSets]|r Commands:")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta gear save <name>|r — save current gear as named set")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta gear equip <name>|r — equip a saved set")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta gear list|r — list all saved sets")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta gear delete <name>|r — remove a saved set")
            TA:Raw(TA.LOG.OUTPUT, "  |cFFFFD100/ta gear assign <name> spec|pvp|r — auto-swap trigger")
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function GS:Init()
    -- Ensure DB exists
    TA.charDB.gearSets = TA.charDB.gearSets or {}

    -- Events for auto-swap triggers are already registered in Core/Init.lua
    -- as PERSISTENT_EVENTS: PLAYER_SPECIALIZATION_CHANGED, ZONE_CHANGED_NEW_AREA
end
