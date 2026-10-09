-- ToonAge/Modules/Gear/Heirlooms.lua
-- Heirloom scan. Login and /ta heirlooms. Suggests a piece only when its
-- item level beats the item in that slot (an empty slot always loses).
--
-- API names checked against current Retail FrameXML
-- (Blizzard_HeirloomCollection.lua, HeirloomsMixin) and Warcraft Wiki, not
-- taken from the request alone:
--   C_Heirloom.GetHeirloomItemIDs()            -> itemIDs[]     (wiki, added 7.0.3)
--   C_Heirloom.PlayerHasHeirloom(itemID)       -> boolean       (FrameXML)
--   C_Heirloom.GetHeirloomInfo(itemID)         -> name, itemEquipLoc, isPvP,
--        itemTexture, upgradeLevel, source, searchFiltered, effectiveLevel,
--        minLevel, maxLevel                                    (wiki + FrameXML)
--   C_Heirloom.GetHeirloomMaxUpgradeLevel(itemID) -> number     (FrameXML)
--   C_Heirloom.GetHeirloomLink(itemID)         -> link          (FrameXML)
--   C_Heirloom.CreateHeirloom(itemID)          called from
--        HeirloomsJournalSpellButton_OnClick, which is Blizzard's own
--        untainted click. Addon code is tainted, so this is treated as
--        protected and is never called. The row offers "Open Heirloom Journal".
-- C_HeirloomInfo (9.2.5) is journal filters only. It is not the collection.
--
-- Experience, from https://warcraft.wiki.gg/wiki/Heirloom :
--   Since patch 9.0.1 heirlooms do not grant bonus experience. They scale
--   and add a set bonus while leveling. Before 9.0.1, shoulders, chest,
--   cloak, helm, legs and rings granted up to 55% bonus experience.
--   Mists Classic is before that change, so the bonus still applies there.
--   On Mists the bag fallback also reads the bank while it is open
--   (BANKFRAME_OPENED, PLAYERBANKSLOTS_CHANGED, and a close snapshot).
--   The main bank and the bank bags go through the C_Container wrappers.
--   What was seen is cached on the character, so a closed bank can still
--   say "in your bank". Those rows do not get an Equip button.
--
-- Forever: FOREVER_ENABLED stays false until heirlooms are confirmed there.
-- The Camelot TOC does not load this file. Era and TBC have no heirlooms.

local TA = ToonAge
local M = {}
TA:RegisterModule("Heirlooms", M)

-- Flip only after heirlooms are confirmed on WoW Forever.
M.FOREVER_ENABLED = false

M.HEIRLOOM_QUALITY = 7
M.NAME_COLOR = "|cFF00CCFF"
M.LOCK_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_lock_16.tga"
M.PIP_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_pip_8.tga"
M.PIP_RING_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\icons\\util_pip_8_ring.tga"
M.GLYPH_TEXTURE = "Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga"

local EQUIP_SLOTS = {
    INVTYPE_HEAD           = { 1 },
    INVTYPE_NECK           = { 2 },
    INVTYPE_SHOULDER       = { 3 },
    INVTYPE_CHEST          = { 5 },
    INVTYPE_ROBE           = { 5 },
    INVTYPE_WAIST          = { 6 },
    INVTYPE_LEGS           = { 7 },
    INVTYPE_FEET           = { 8 },
    INVTYPE_WRIST          = { 9 },
    INVTYPE_HAND           = { 10 },
    INVTYPE_FINGER         = { 11, 12 },
    INVTYPE_TRINKET        = { 13, 14 },
    INVTYPE_CLOAK          = { 15 },
    INVTYPE_WEAPON         = { 16 },
    INVTYPE_2HWEAPON       = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_RANGED         = { 16 },
    INVTYPE_RANGEDRIGHT    = { 16 },
    INVTYPE_SHIELD         = { 17 },
    INVTYPE_WEAPONOFFHAND  = { 17 },
    INVTYPE_HOLDABLE       = { 17 },
}

local SLOT_NAME = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest",
    [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist",
    [10] = "Hands", [11] = "Ring", [12] = "Ring", [13] = "Trinket",
    [14] = "Trinket", [15] = "Back", [16] = "Weapon", [17] = "Off hand",
}

local NEUTRAL = { 0.92, 0.90, 0.87 }
local DIM     = { 0.55, 0.52, 0.48 }
local GOLD    = { 1.00, 0.82, 0.00 }

-- ── Pure decisions (unit-tested) ─────────────────────────────────────────

function M.ScanMode(flavor, apiPresent, foreverEnabled)
    if flavor == "forever" and not foreverEnabled then return "off" end
    if flavor == "vanilla" or flavor == "tbc" then return "skip" end
    if flavor == "retail" then
        return apiPresent and "collection" or "missing-api"
    end
    if flavor == "mists" or flavor == "forever" then
        return apiPresent and "collection" or "bags"
    end
    return "skip"
end

function M.Advice(flavor)
    if flavor == "mists" then
        return "Heirlooms on this version still grant bonus experience while you wear them. A row appears only when the heirloom's item level is higher than what is equipped."
    end
    if flavor == "retail" then
        return "Heirlooms do not grant bonus experience. That ended in patch 9.0.1; they scale with your level and add a set bonus while leveling. A row appears only when the heirloom's item level is higher than what is equipped."
    end
    return nil
end

function M.EmptyCopy(mode, flavor, owned, suggested)
    owned = owned or 0
    suggested = suggested or 0
    if mode == "skip" and flavor == "vanilla" then
        return "No heirlooms here",
            "Classic Era has no heirloom items, so this scan stays off."
    end
    if mode == "skip" then
        return "No heirlooms here",
            "The Burning Crusade has no heirloom items, so this scan stays off."
    end
    if mode == "missing-api" then
        return "Heirloom collection unavailable",
            "This client has no heirloom collection API, so there is nothing to scan."
    end
    if mode == "off" then
        return "Heirlooms are off",
            "The heirloom scan stays off on this version until it is confirmed."
    end
    if owned == 0 and mode == "bags" then
        return "No heirlooms in your bags",
            "Heirlooms here still grant bonus experience, and none are in your bags or bank."
    end
    if owned == 0 then
        return "No heirlooms collected",
            "Heirlooms do not grant bonus experience, and nothing in your collection is learned yet."
    end
    if suggested == 0 and flavor == "mists" then
        return "No heirloom upgrades",
            "Heirlooms here still grant bonus experience, and none beat what is equipped."
    end
    if suggested == 0 then
        return "No heirloom upgrades",
            "Heirlooms do not grant bonus experience, and none beat what is equipped."
    end
    return nil, nil
end

--- Armor subclass 1-4 is cloth through plate. A shield (subclass 6) is kept.
--- Lower armor is wearable. Weapons are not filtered here.
--- Main bank first, then the purchased bank bags. Defaults match Mists:
--- BANK_CONTAINER is -1, four carried bags, seven bank bags (ids 5-11).
function M.BankContainers(numBagSlots, numBankBags, bankContainer)
    local bags = (type(numBagSlots) == "number") and numBagSlots or 4
    local bankBags = (type(numBankBags) == "number") and numBankBags or 7
    local main = (type(bankContainer) == "number") and bankContainer or -1
    local ids = { main }
    for i = 1, bankBags do
        ids[#ids + 1] = bags + i
    end
    return ids
end

--- nil live means the bank is closed (the container API returned no slots).
--- Keep the previous cache. A table, even an empty one, is a live read and
--- replaces the cache.
function M.NextBankCache(previous, live)
    if live == nil then return previous end
    return live
end

--- SavedVariables record. Bag and slot are omitted on purpose: a bank item
--- cannot be equipped, and a stale slot must not become a secure button.
function M.BankRecord(item)
    return {
        itemID = item.itemID,
        name = item.name,
        link = item.link,
        ilvl = item.ilvl,
        equipLoc = item.equipLoc,
        classID = item.classID,
        subclassID = item.subclassID,
    }
end

function M.DetailLine(slotName, ilvl, eqIlvl, where)
    local versus = (eqIlvl == nil) and "empty slot" or ("equipped " .. tostring(eqIlvl))
    local text = string.format("%s  ·  item level %s vs %s", slotName or "Slot",
        (ilvl == nil or ilvl == "") and "?" or tostring(ilvl), versus)
    if where == "bank" then
        text = text .. "  ·  in your bank"
    end
    return text
end

function M.CanWear(classID, subclassID, playerArmor)
    if classID ~= 4 then return true end
    if subclassID == 6 then return true end
    if type(subclassID) ~= "number" or subclassID < 1 or subclassID > 4 then return true end
    if type(playerArmor) ~= "number" then return true end
    return subclassID <= playerArmor
end

local function WhereRank(item)
    if item.where == "bag" then return 3 end
    if item.where == "bank" then return 2 end
    return 1
end

--- One row per item id. A bag copy wins over the bank, which wins over a
--- collection entry that is not in a bag (the bag copy is the one we can equip).
function M.Dedupe(items)
    local byID, out = {}, {}
    for _, item in ipairs(items or {}) do
        local id = item.itemID
        if not id then
            out[#out + 1] = item
        else
            local prev = byID[id]
            if not prev then
                byID[id] = item
                out[#out + 1] = item
            elseif WhereRank(item) > WhereRank(prev) then
                byID[id] = item
                for i, v in ipairs(out) do
                    if v == prev then out[i] = item end
                end
            end
        end
    end
    return out
end

--- items: { itemID, ilvl, slots = {n,...} }
--- equipped: [slot] = { ilvl = number|nil, itemID = number|nil } or absent (empty).
--- A missing equipped ilvl means the slot is occupied by something we could
--- not measure, so the heirloom is not suggested over it.
function M.Suggest(items, equipped)
    equipped = equipped or {}
    local pairsList = {}
    for index, item in ipairs(items or {}) do
        local slots = item.slots or {}
        for _, slot in ipairs(slots) do
            local eq = equipped[slot]
            local same = eq and item.itemID and eq.itemID == item.itemID
            if not same then
                if not eq then
                    local gain = (type(item.ilvl) == "number" and item.ilvl > 0) and item.ilvl or 1
                    pairsList[#pairsList + 1] = {
                        index = index, slot = slot, gain = gain, item = item, eqIlvl = nil,
                    }
                elseif type(eq.ilvl) == "number" and type(item.ilvl) == "number"
                    and item.ilvl > eq.ilvl then
                    pairsList[#pairsList + 1] = {
                        index = index, slot = slot, gain = item.ilvl - eq.ilvl,
                        item = item, eqIlvl = eq.ilvl,
                    }
                end
            end
        end
    end
    table.sort(pairsList, function(a, b)
        if a.gain ~= b.gain then return a.gain > b.gain end
        return a.slot < b.slot
    end)
    local used, taken, out = {}, {}, {}
    for _, pair in ipairs(pairsList) do
        if not used[pair.index] and not taken[pair.slot] then
            used[pair.index] = true
            taken[pair.slot] = true
            out[#out + 1] = {
                item = pair.item, slot = pair.slot, eqIlvl = pair.eqIlvl,
            }
        end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

-- ── Client reads ─────────────────────────────────────────────────────────

local function CollectionApiPresent()
    return type(C_Heirloom) == "table"
        and type(C_Heirloom.GetHeirloomItemIDs) == "function"
        and type(C_Heirloom.PlayerHasHeirloom) == "function"
        and type(C_Heirloom.GetHeirloomInfo) == "function"
end

function M.CreateHeirloomMode()
    if not (type(C_Heirloom) == "table" and type(C_Heirloom.CreateHeirloom) == "function") then
        return "absent"
    end
    -- See the file header. Never call it: a successful call would create an item.
    return "protected"
end

local function ItemLevel(link)
    if not link then return nil end
    if type(GetDetailedItemLevelInfo) == "function" then
        local ok, level = pcall(GetDetailedItemLevelInfo, link)
        if ok and type(level) == "number" and level > 0 then return level end
    end
    if C_Item and type(C_Item.GetDetailedItemLevelInfo) == "function" then
        local ok, level = pcall(C_Item.GetDetailedItemLevelInfo, link)
        if ok and type(level) == "number" and level > 0 then return level end
    end
    local U = TA.Utils
    if U and U.GetItemIlvl then
        local level = U.GetItemIlvl(link)
        if type(level) == "number" and level > 0 then return level end
    end
    return nil
end

local function PlayerArmor()
    local _, class = UnitClass and UnitClass("player")
    if class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then return 4 end
    if class == "HUNTER" or class == "SHAMAN" or class == "EVOKER" then return 3 end
    if class == "ROGUE" or class == "DRUID" or class == "MONK" or class == "DEMONHUNTER" then return 2 end
    return 1
end

local function Equippable(link, classID, subclassID)
    if link and type(IsEquippableItem) == "function" then
        local ok, yes = pcall(IsEquippableItem, link)
        if ok then return yes and true or false end
    end
    return M.CanWear(classID, subclassID, PlayerArmor())
end

local function Meta(linkOrID)
    if type(GetItemInfoInstant) ~= "function" or not linkOrID then
        return nil, nil, nil, nil
    end
    local ok, id, _, _, equipLoc, _, classID, subclassID = pcall(GetItemInfoInstant, linkOrID)
    if not ok then return nil, nil, nil, nil end
    return id, equipLoc, classID, subclassID
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

function M.OpenJournal()
    if type(CollectionsJournal_LoadUI) == "function" then
        pcall(CollectionsJournal_LoadUI)
    end
    local tab = _G.COLLECTIONS_JOURNAL_TAB_INDEX_HEIRLOOMS
    if type(tab) ~= "number" and type(Enum) == "table" and type(Enum.CollectionsJournalTab) == "table" then
        tab = Enum.CollectionsJournalTab.Heirlooms
    end
    if type(tab) ~= "number" then tab = 4 end
    if type(ToggleCollectionsJournal) ~= "function" then return false end
    local ok = pcall(ToggleCollectionsJournal, tab)
    return ok
end

local function Remember(list, item)
    if item.minLevel and UnitLevel and (UnitLevel("player") or 1) < item.minLevel then return end
    if not item.slots or not item.slots[1] then return end
    if item.where == "bank" then
        -- The link may not resolve once the bank is closed. The armor class
        -- was stored while it was open.
        if not M.CanWear(item.classID, item.subclassID, PlayerArmor()) then return end
        item.bag = nil
        item.slot = nil
    elseif not Equippable(item.link, item.classID, item.subclassID) then
        return
    end
    list[#list + 1] = item
end

local function FromCollection()
    local owned = {}
    if not CollectionApiPresent() then return owned, false end
    local ok, ids = pcall(C_Heirloom.GetHeirloomItemIDs)
    if not ok or type(ids) ~= "table" then return owned, true end
    for _, itemID in ipairs(ids) do
        local hasOk, has = pcall(C_Heirloom.PlayerHasHeirloom, itemID)
        if hasOk and has then
            local infoOk, name, equipLoc, _, texture, upgradeLevel, _, _, _, minLevel =
                pcall(C_Heirloom.GetHeirloomInfo, itemID)
            if infoOk and type(name) == "string" and name ~= "" then
                local link
                if type(C_Heirloom.GetHeirloomLink) == "function" then
                    local linkOk, value = pcall(C_Heirloom.GetHeirloomLink, itemID)
                    if linkOk and type(value) == "string" then link = value end
                end
                local _, instantLoc, classID, subclassID = Meta(link or itemID)
                local loc = equipLoc or instantLoc
                local maxUpgrade
                if type(C_Heirloom.GetHeirloomMaxUpgradeLevel) == "function" then
                    local maxOk, value = pcall(C_Heirloom.GetHeirloomMaxUpgradeLevel, itemID)
                    if maxOk and type(value) == "number" then maxUpgrade = value end
                end
                local ilvl = ItemLevel(link)
                if not ilvl then M._needItemInfo = true end
                Remember(owned, {
                    itemID = itemID, name = name, link = link, texture = texture,
                    ilvl = ilvl, slots = loc and EQUIP_SLOTS[loc], where = "collection",
                    upgradeLevel = tonumber(upgradeLevel), maxUpgrade = maxUpgrade,
                    minLevel = tonumber(minLevel), classID = classID, subclassID = subclassID,
                })
            end
        end
    end
    return owned, true
end

local function CarriedBags()
    local bags = { 0 }
    local equippedBags = _G.NUM_BAG_SLOTS or 4
    for i = 1, equippedBags do bags[#bags + 1] = i end
    return bags
end

local function ContainerAPI()
    local U = TA.Utils
    if not (U and U.GetContainerNumSlots and U.GetContainerItemLink) then return nil end
    return U
end

local function QualityOf(link)
    local U = TA.Utils
    if U and U.GetItemQuality then return U.GetItemQuality(link) end
    if type(GetItemInfo) == "function" then
        local _, _, quality = GetItemInfo(link)
        return quality
    end
    return nil
end

--- item table, false when the slot is occupied but its quality is not
--- known yet, nil when the slot is empty or not an heirloom.
local function ReadHeirloom(U, bag, slot, where)
    local link = U.GetContainerItemLink(bag, slot)
    local id = U.GetContainerItemID and U.GetContainerItemID(bag, slot)
    if not link and not id then return nil end
    if not link or QualityOf(link) == nil then
        M._needItemInfo = true
        if id and U.RequestItemInfo and (M._itemPasses or 0) < 2 then
            U.RequestItemInfo(id)
        end
        return false
    end
    local quality = QualityOf(link)
    if quality ~= M.HEIRLOOM_QUALITY then return nil end
    local _, equipLoc, classID, subclassID = Meta(link)
    if not equipLoc and type(GetItemInfo) == "function" then
        equipLoc = select(9, GetItemInfo(link))
    end
    local name = (type(GetItemInfo) == "function" and GetItemInfo(link)) or link
    local itemID = Meta(link)
    if not itemID and U.GetContainerItemID then
        itemID = U.GetContainerItemID(bag, slot)
    end
    local ilvl = ItemLevel(link)
    if not ilvl then M._needItemInfo = true end
    local item = {
        itemID = itemID, name = name, link = link,
        ilvl = ilvl, equipLoc = equipLoc,
        slots = equipLoc and EQUIP_SLOTS[equipLoc],
        where = where, classID = classID, subclassID = subclassID,
    }
    if where == "bag" then
        item.bag = bag
        item.slot = slot
    end
    return item
end

--- nil when the main bank reports no slots (it is closed). A list, possibly
--- empty, when the bank is open. Main bank plus bank bags, via the
--- C_Container wrappers on Utils (Compat picks C_Container on Mists).
local function ReadBank(U)
    local ids = M.BankContainers(_G.NUM_BAG_SLOTS, _G.NUM_BANKBAGSLOTS, _G.BANK_CONTAINER)
    local mainSlots = U.GetContainerNumSlots(ids[1]) or 0
    if mainSlots <= 0 then return nil end
    local found, unresolved = {}, false
    for _, bag in ipairs(ids) do
        local slots = U.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local item = ReadHeirloom(U, bag, slot, "bank")
            if item then
                found[#found + 1] = item
            elseif item == false then
                unresolved = true
            end
        end
    end
    return found, unresolved
end

local function LoadBankCache()
    local saved = TA.charDB and TA.charDB.heirloomBank
    if type(saved) ~= "table" then return {} end
    local out = {}
    for _, row in ipairs(saved) do
        if type(row) == "table" and row.equipLoc and EQUIP_SLOTS[row.equipLoc] then
            out[#out + 1] = {
                itemID = row.itemID, name = row.name, link = row.link,
                ilvl = row.ilvl, equipLoc = row.equipLoc,
                slots = EQUIP_SLOTS[row.equipLoc],
                where = "bank", classID = row.classID, subclassID = row.subclassID,
            }
        end
    end
    return out
end

local function SaveBankCache(items)
    if not TA.charDB then return end
    local out = {}
    for _, item in ipairs(items or {}) do
        if item.equipLoc then out[#out + 1] = M.BankRecord(item) end
    end
    TA.charDB.heirloomBank = out
end

local function FromBags()
    local owned = {}
    local U = ContainerAPI()
    if not U then return owned end
    for _, bag in ipairs(CarriedBags()) do
        local slots = U.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local item = ReadHeirloom(U, bag, slot, "bag")
            if item then Remember(owned, item) end
        end
    end
    local live, unresolved = ReadBank(U)
    if live == nil then
        -- Bank is closed. Suggest whatever the last open visit stored.
        for _, item in ipairs(LoadBankCache()) do Remember(owned, item) end
    elseif unresolved then
        -- The bank is open, but some links have not resolved. Keep the saved
        -- list until a later pass can tell an heirloom from an ordinary item.
        for _, item in ipairs(live) do Remember(owned, item) end
        for _, item in ipairs(LoadBankCache()) do Remember(owned, item) end
    else
        local accepted = {}
        for _, item in ipairs(live) do Remember(accepted, item) end
        SaveBankCache(M.NextBankCache(LoadBankCache(), accepted))
        for _, item in ipairs(accepted) do owned[#owned + 1] = item end
    end
    return owned
end

local function Equipped()
    local out = {}
    if type(GetInventoryItemLink) ~= "function" then return out end
    for slot = 1, 17 do
        if slot ~= 4 then
            local link = GetInventoryItemLink("player", slot)
            local id = type(GetInventoryItemID) == "function" and GetInventoryItemID("player", slot) or nil
            if link or id then
                local ilvl = ItemLevel(link)
                if link and not ilvl then M._needItemInfo = true end
                out[slot] = { ilvl = ilvl, itemID = id }
            end
        end
    end
    return out
end

function M:Scan()
    local flavor = TA.flavor
    self._mode = M.ScanMode(flavor, CollectionApiPresent(), M.FOREVER_ENABLED)
    self._createMode = M.CreateHeirloomMode()
    self._owned = 0
    self._suggestions = {}
    self._scanned = true
    if self._mode == "off" or self._mode == "skip" or self._mode == "missing-api" then
        return self._suggestions
    end
    if self._mode == "collection" and TA.RegisterEvent then
        TA:RegisterEvent("HEIRLOOMS_UPDATED")
    end
    self._needItemInfo = false
    local items
    if self._mode == "collection" then
        items = FromCollection()
    else
        items = FromBags()
    end
    items = M.Dedupe(items)
    self._owned = #items
    self._suggestions = M.Suggest(items, Equipped())
    if self._needItemInfo and (self._itemPasses or 0) < 2 then
        local U = TA.Utils
        if U and U.RequestItemInfo then
            for _, item in ipairs(items) do
                if not item.ilvl and item.itemID then U.RequestItemInfo(item.itemID) end
            end
        end
    else
        self._needItemInfo = false
    end
    return self._suggestions
end

function M:Status()
    local mode = self._mode or M.ScanMode(TA.flavor, CollectionApiPresent(), M.FOREVER_ENABLED)
    if mode == "off" then
        return "heirloom scan off (Forever flag, unconfirmed)"
    end
    if mode == "skip" then
        return "heirloom scan skipped: no heirlooms on this version"
    end
    local api = CollectionApiPresent() and "C_Heirloom" or "absent"
    local bankNote = ""
    if mode == "bags" then
        local saved = TA.charDB and TA.charDB.heirloomBank
        local n = (type(saved) == "table") and #saved or 0
        bankNote = string.format("; bank cache %d", n)
    end
    return string.format("heirloom scan %s via %s: %d owned, %d suggested; CreateHeirloom %s%s",
        mode, api, self._owned or 0, #(self._suggestions or {}),
        self._createMode or M.CreateHeirloomMode(), bankNote)
end

function M:Init()
    self._mode = M.ScanMode(TA.flavor, false, M.FOREVER_ENABLED)
    if self._mode == "off" or TA.flavor == "vanilla" or TA.flavor == "tbc" then
        self._mode = (TA.flavor == "forever") and "off" or M.ScanMode(TA.flavor, false, M.FOREVER_ENABLED)
        if self._mode == "off" or self._mode == "skip" then
            self._scanned = true
            self._suggestions = {}
            self._owned = 0
            self._createMode = "absent"
            return
        end
    end
    self:Scan()
end

function M:OnEnterWorld()
    if self._mode == "off" or self._mode == "skip" then return end
    self:Scan()
end

M.Events = {
    "BAG_UPDATE",
    "GET_ITEM_INFO_RECEIVED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED",
}

function M:OnEvent(event)
    if self._mode == "off" or self._mode == "skip" then return end
    if event == "PLAYER_REGEN_DISABLED" then
        self:LockEquipButtons()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if self._redrawAfterCombat then
            self._redrawAfterCombat = nil
            self:Redraw()
        else
            self:ConfigureEquipButtons()
        end
        return
    end
    if event == "GET_ITEM_INFO_RECEIVED" then
        if not self._needItemInfo then return end
        self._itemPasses = (self._itemPasses or 0) + 1
        self._needItemInfo = false
        self:Scan()
        return
    end
    if event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED"
        or event == "PLAYERBANKSLOTS_CHANGED" then
        if self._mode == "bags" then self:Scan() end
        return
    end
    if event == "BAG_UPDATE" or event == "HEIRLOOMS_UPDATED" then
        self:Scan()
    end
end

function M:Redraw()
    if InCombat() then
        self._redrawAfterCombat = true
        self:LockEquipButtons()
        return
    end
    local ui = TA.UI
    if ui and ui.IsShown and ui:IsShown() and ui.activeTab == "gear" and ui.SetTab then
        ui:SetTab("gear")
    end
end

M.SlashCommands = {
    heirlooms = function(mod)
        if mod._mode ~= "off" and mod._mode ~= "skip" then mod:Scan() end
        mod:Redraw()
        if TA.Print then
            TA:Print(TA.LOG.OUTPUT, nil, mod:Status())
        end
    end,
}

-- ── Row widgets ──────────────────────────────────────────────────────────

local function Font(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local face = _G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    if fs.SetFont then fs:SetFont(face, size or 11, "") end
    return fs
end

local function PaintSecondary(btn)
    if TA._ApplyBackdrop then
        TA._ApplyBackdrop(btn, 0.08, 0.07, 0.06, 1, 0.30, 0.28, 0.24, 1)
    elseif btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.08, 0.07, 0.06, 1)
        btn:SetBackdropBorderColor(0.30, 0.28, 0.24, 1)
    end
end

function M:FadeSecureButtons()
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.SetAlpha then btn:SetAlpha(0) end
        if btn.Disable then btn:Disable() end
    end
end

function M:ReleaseSecureButtons()
    if InCombat() then
        self:FadeSecureButtons()
        return
    end
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.Hide then btn:Hide() end
        if btn.SetParent then btn:SetParent(nil) end
    end
    self._secureButtons = {}
end

function M:LockEquipButtons()
    for _, btn in ipairs(self._secureButtons or {}) do
        if btn.Disable then btn:Disable() end
        if btn.label then btn.label:Hide() end
        if btn.lock then btn.lock:Show() end
    end
end

function M:ConfigureEquipButtons()
    if InCombat() then
        self._redrawAfterCombat = true
        return
    end
    for _, btn in ipairs(self._secureButtons or {}) do
        local setup = btn._setup
        if setup and btn.SetAttribute then
            btn:SetAttribute("type", "item")
            btn:SetAttribute("item", setup)
        end
        if btn.Enable then btn:Enable() end
        if btn.SetAlpha then btn:SetAlpha(1) end
        if btn.label then btn.label:Show() end
        if btn.lock then btn.lock:Hide() end
    end
end

local function MakeEquipButton(anchor, setup)
    -- Parented to UIParent so a combat tab rebuild can drop the row frame
    -- without calling SetParent on a secure button. Attributes are set only
    -- out of combat; PLAYER_REGEN_ENABLED runs ConfigureEquipButtons.
    local template = BackdropTemplateMixin and "SecureActionButtonTemplate,BackdropTemplate"
        or "SecureActionButtonTemplate"
    local btn = CreateFrame("Button", nil, UIParent, template)
    btn:SetSize(64, 22)
    btn:SetFrameStrata(anchor:GetFrameStrata() or "HIGH")
    btn:SetFrameLevel((anchor:GetFrameLevel() or 1) + 20)
    btn:RegisterForClicks("LeftButtonUp")
    btn._setup = setup
    PaintSecondary(btn)
    local label = Font(btn, 10)
    label:SetPoint("CENTER")
    label:SetText("Equip")
    label:SetTextColor(NEUTRAL[1], NEUTRAL[2], NEUTRAL[3])
    btn.label = label
    local lock = btn:CreateTexture(nil, "OVERLAY")
    lock:SetSize(16, 16)
    lock:SetPoint("CENTER")
    lock:SetTexture(M.LOCK_TEXTURE)
    lock:Hide()
    btn.lock = lock
    if not InCombat() and btn.SetAttribute then
        btn:SetAttribute("type", "item")
        btn:SetAttribute("item", setup)
    end
    M._secureButtons = M._secureButtons or {}
    M._secureButtons[#M._secureButtons + 1] = btn
    if InCombat() then
        btn:Disable()
        label:Hide()
        lock:Show()
        M._redrawAfterCombat = true
    end
    return btn
end

local function MakePlainButton(parent, text, onClick, disabled, lockInCombat)
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local btn = CreateFrame("Button", nil, parent, template)
    btn:SetSize(math.max(64, (#text * 6) + 18), 22)
    PaintSecondary(btn)
    local label = Font(btn, 10)
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(NEUTRAL[1], NEUTRAL[2], NEUTRAL[3])
    btn.label = label
    local lock = btn:CreateTexture(nil, "OVERLAY")
    lock:SetSize(16, 16)
    lock:SetPoint("CENTER")
    lock:SetTexture(M.LOCK_TEXTURE)
    lock:Hide()
    btn.lock = lock
    if disabled then btn:Disable() end
    if lockInCombat and InCombat() then
        btn:Disable()
        label:Hide()
        lock:Show()
        M._redrawAfterCombat = true
    end
    btn:SetScript("OnClick", function()
        if lockInCombat and InCombat() then return end
        if onClick then onClick() end
    end)
    return btn
end

function M:EmptyCard(parent, y, width, title, sentence, scanButton)
    width = width or 360
    local cardW = math.min(360, math.max(width, 220))
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local card = CreateFrame("Frame", nil, parent, template)
    card:SetSize(cardW, 108)
    card:SetPoint("TOP", parent, "TOP", 0, y)
    if TA._ApplyBackdrop then
        TA._ApplyBackdrop(card, 0.07, 0.07, 0.08, 0.94, 0.30, 0.28, 0.24, 1)
    end
    local glyph = card:CreateTexture(nil, "ARTWORK")
    glyph:SetSize(24, 24)
    glyph:SetPoint("TOP", 0, -12)
    glyph:SetTexture(M.GLYPH_TEXTURE)
    glyph:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
    local heading = Font(card, 14)
    heading:SetPoint("TOP", glyph, "BOTTOM", 0, -6)
    heading:SetWidth(cardW - 24)
    heading:SetJustifyH("CENTER")
    heading:SetText(title)
    heading:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    local body = Font(card, 11)
    body:SetPoint("TOP", heading, "BOTTOM", 0, -4)
    body:SetWidth(cardW - 28)
    body:SetJustifyH("CENTER")
    body:SetText(sentence)
    body:SetTextColor(NEUTRAL[1], NEUTRAL[2], NEUTRAL[3])
    local extra = 0
    if scanButton then
        local btn = MakePlainButton(card, "Scan again", function()
            self:Scan()
            self:Redraw()
        end, false, false)
        btn:SetPoint("TOP", body, "BOTTOM", 0, -8)
        extra = 28
        card:SetHeight(136)
    end
    return y - (108 + extra) - 8
end

function M:Draw(parent, y, width)
    if not parent then return y end
    width = (width and width > 40) and width or 480
    y = y or -8
    if not self._scanned then self:Scan() end
    self:ReleaseSecureButtons()

    local mode = self._mode or "skip"
    local suggestions = self._suggestions or {}
    local title, sentence = M.EmptyCopy(mode, TA.flavor, self._owned or 0, #suggestions)
    if title then
        local offerScan = (mode == "collection" or mode == "bags")
        return self:EmptyCard(parent, y, width, title, sentence, offerScan)
    end

    local header = Font(parent, 12)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    header:SetText("HEIRLOOMS")
    header:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    y = y - 16

    local advice = M.Advice(TA.flavor)
    if advice then
        local note = Font(parent, 10)
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        note:SetWidth(width - 8)
        note:SetJustifyH("LEFT")
        note:SetText(advice)
        note:SetTextColor(DIM[1], DIM[2], DIM[3])
        local noteH = 28
        if note.GetStringHeight then
            local h = note:GetStringHeight()
            if type(h) == "number" and h > 12 then noteH = h + 4 end
        end
        y = y - noteH
    end

    for _, row in ipairs(suggestions) do
        local item = row.item
        local line = CreateFrame("Frame", nil, parent)
        line:SetSize(width, 44)
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)

        local name = Font(line, 12)
        name:SetPoint("TOPLEFT", line, "TOPLEFT", 0, -2)
        local pips = tonumber(item.maxUpgrade) or 0
        if pips < 0 then pips = 0 end
        if pips > 16 then pips = 16 end
        name:SetWidth(math.max(80, width - 180 - (pips * 10)))
        name:SetJustifyH("LEFT")
        name:SetText(M.NAME_COLOR .. (item.name or "Heirloom") .. "|r")

        local filled = tonumber(item.upgradeLevel) or 0
        if filled < 0 then filled = 0 end
        if filled > pips then filled = pips end
        for i = 1, pips do
            local pip = line:CreateTexture(nil, "ARTWORK")
            pip:SetSize(8, 8)
            pip:SetPoint("LEFT", name, "RIGHT", 6 + (i - 1) * 10, 0)
            if i <= filled then
                pip:SetTexture(M.PIP_TEXTURE)
            else
                pip:SetTexture(M.PIP_RING_TEXTURE)
            end
        end

        local detail = Font(line, 10)
        detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        detail:SetWidth(math.max(80, width - 180))
        detail:SetJustifyH("LEFT")
        local ilvlText = (type(item.ilvl) == "number") and tostring(item.ilvl) or "?"
        detail:SetText(M.DetailLine(SLOT_NAME[row.slot], ilvlText, row.eqIlvl, item.where))
        detail:SetTextColor(NEUTRAL[1], NEUTRAL[2], NEUTRAL[3])

        local btn
        if item.where == "bag" and item.bag ~= nil and item.slot ~= nil and not InCombat() then
            btn = MakeEquipButton(line, tostring(item.bag) .. " " .. tostring(item.slot))
            -- The button lives on UIParent so a combat rebuild can drop this
            -- row. Hiding the row must take the button with it.
            line:SetScript("OnHide", function()
                if InCombat() then
                    btn:SetAlpha(0)
                    if btn.Disable then btn:Disable() end
                elseif btn.Hide then
                    btn:Hide()
                end
            end)
        elseif item.where == "bag" then
            btn = MakePlainButton(line, "Equip", nil, true, true)
        elseif item.where == "bank" then
            btn = MakePlainButton(line, "In bank", nil, true, false)
        else
            btn = MakePlainButton(line, "Open Heirloom Journal", function()
                if not M.OpenJournal() and TA.Print then
                    TA:Print(TA.LOG.OUTPUT, nil, "The Heirloom Journal is not available on this client.")
                end
            end, false, false)
            btn:SetSize(158, 22)
        end
        btn:SetPoint("RIGHT", line, "RIGHT", 0, 0)
        y = y - 48
    end

    local again = MakePlainButton(parent, "Scan again", function()
        self:Scan()
        self:Redraw()
    end, false, false)
    again:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    y = y - 30
    return y
end

return M
