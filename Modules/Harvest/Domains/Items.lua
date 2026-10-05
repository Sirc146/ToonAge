-- ToonAge/Modules/Harvest/Domains/Items.lua  (harvest domain: item stat blocks)
--
-- What passes through your bags, your equipment slots and your loot window,
-- recorded once per item: the client's own stat block for it. Every client API
-- call goes through TA.Caps (Docs/SPEC_HARVEST_SENSOR_ARRAY.md R2); the record
-- helpers and the store are the harvest core's (Modules/Infrastructure/
-- Harvester.lua). Moved here from Modules/Forever/DataHarvester.lua in T4.
--
--   items[itemID] = name, ilvl, quality, minLevel, classID, subclassID,
--                   itemType, itemSubType, equipLoc, bindType, stat block

local TA = ToonAge
local Hv, Caps = TA.Harvester, TA.Caps

local Try, Put, Clean = Hv.Try, Hv.Put, Hv.Clean

-- Chosen so the saved file stays well under a megabyte: Vanilla-era content
-- has a few thousand distinct items in levelling range, so 20k is generous.
local MAX_ITEMS = 20000

-- Bag scans are debounced: BAG_UPDATE_DELAYED can fire several times for one
-- loot, and a scan that walks five bags per fire is the kind of thing players
-- feel as a stutter.
local SCAN_DELAY = 1.0

local EQUIP_SLOTS = 19   -- 1..19 covers every equippable slot

local D = {
    id = "items",
    events = { "LOOT_OPENED", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED" },
    rescan = { { "equipped", "ScanEquipped" }, { "bags", "ScanBags" } },
    export = { { section = "items", label = "Items" } },
    summary = { { section = "items", label = "Items with full stat blocks" } },
}

--- The stat block, flattened to "KEY=value,KEY=value". This is the whole
--- point of the exercise: it is the client stating, for a real item, which
--- stats exist and at what magnitude. Everything a future gear score needs is
--- downstream of this one string.
local function StatString(link)
    local stats = Try("C_Item.GetItemStats", link)
    if type(stats) ~= "table" then
        stats = Try("GetItemStats", link)
    end
    if type(stats) ~= "table" then return "" end

    -- Sorted, so the same item always produces a byte-identical record and a
    -- diff between two harvests shows real change rather than table order.
    local keys = {}
    for k in pairs(stats) do keys[#keys + 1] = k end
    table.sort(keys)

    local parts = {}
    for _, k in ipairs(keys) do
        parts[#parts + 1] = Clean(k) .. "=" .. Clean(stats[k])
    end
    return table.concat(parts, ",")
end

local function ItemInfo(link)
    if Caps.State("C_Item.GetItemInfo") == "present" then
        return Try("C_Item.GetItemInfo", link)
    end
    return Try("GetItemInfo", link)
end

--- Item ID for a link, whatever this client exposes.
---
--- The global GetItemInfoInstant is NIL on Forever (measured 2026-09-23, see
--- Modules/Farming/GatherTracker.lua ItemClass). Calling only the global made
--- every lookup return nil, so RecordItem exited before writing anything and
--- the item store stayed empty on the one client it existed for. The link
--- itself carries the id ("|Hitem:12345:..."), so parsing it is the final
--- route and needs no API at all.
local function ItemID(link)
    local id = Try("C_Item.GetItemInfoInstant", link)
    if id then return id end
    id = Try("GetItemInfoInstant", link)
    if id then return id end
    if type(link) == "string" then
        return tonumber(link:match("item:(%d+)"))
    end
    return nil
end

function D:RecordItem(link)
    if not link then return false end

    local itemID = ItemID(link)
    if not itemID then return false end

    local s = Hv:Store()
    if not s then return false end
    if s.items[itemID] ~= nil then return false end   -- already known, cheap exit

    local name, _, quality, ilvl, minLevel, itemType, itemSubType,
          _, equipLoc, _, _, classID, subclassID, bindType = ItemInfo(link)

    -- No name means the client has not cached this item yet. Skip it rather
    -- than writing a half-record: the next scan will catch it once the data
    -- lands.
    if not name then return false end

    return Put(s.items, itemID, table.concat({
        Clean(name), Clean(ilvl), Clean(quality), Clean(minLevel),
        Clean(classID), Clean(subclassID), Clean(itemType), Clean(itemSubType),
        Clean(equipLoc), Clean(bindType), StatString(link),
    }, "\t"), MAX_ITEMS)
end

function D:ScanEquipped()
    local n = 0
    for slot = 1, EQUIP_SLOTS do
        local link = Try("GetInventoryItemLink", "player", slot)
        if link and self:RecordItem(link) then n = n + 1 end
    end
    return n
end

function D:ScanBags()
    local n = 0
    local modern = Caps.State("C_Container.GetContainerNumSlots") == "present"
    local modernLink = Caps.State("C_Container.GetContainerItemLink") == "present"
    for bag = 0, 4 do
        local slots
        if modern then
            slots = Try("C_Container.GetContainerNumSlots", bag)
        else
            slots = Try("GetContainerNumSlots", bag)
        end
        slots = tonumber(slots) or 0
        for slot = 1, slots do
            local link
            if modernLink then
                link = Try("C_Container.GetContainerItemLink", bag, slot)
            else
                link = Try("GetContainerItemLink", bag, slot)
            end
            if link and self:RecordItem(link) then n = n + 1 end
        end
    end
    return n
end

function D:ScanLoot()
    local n = 0
    local num = tonumber((Try("GetNumLootItems"))) or 0
    for i = 1, num do
        local link = Try("GetLootSlotLink", i)
        if link and self:RecordItem(link) then n = n + 1 end
    end
    return n
end

--- Bags and equipment, once per SCAN_DELAY however many events asked.
function D:QueueScan()
    Hv:Once("items", SCAN_DELAY, function()
        self:ScanBags()
        self:ScanEquipped()
    end)
end

function D:OnEvent(event)
    if event == "LOOT_OPENED" then
        self:ScanLoot()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" then
        self:QueueScan()
    end
end

function D:OnEnterWorld()
    self:QueueScan()
end

Hv:RegisterDomain(D)
