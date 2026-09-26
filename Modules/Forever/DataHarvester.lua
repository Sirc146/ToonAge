-- ToonAge/Modules/Forever/DataHarvester.lua  (WoW Forever — ground-truth collector)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Forever is Vanilla content on Midnight's API, and no outside source has
-- numbers for it. Wowhead, Icy Veins and the theorycrafting sites all cover
-- Retail or Classic Era; none of them describe this game. Copying Vanilla
-- values across would produce advice that LOOKS researched and is quietly
-- wrong, which is worse than the honest "n/a" the Character tab prints today.
--
-- So the client is the only source, and the player is the only instrument.
-- This module is the instrument's recorder: it watches what passes through
-- your bags, your character sheet, your spellbook and your talent trees, and
-- writes down exactly what the client said. Nothing here interprets anything.
-- No weights, no rankings, no thresholds -- those come later, built ON this,
-- once there is enough of it to be worth trusting.
--
-- Design rules it holds to:
--   * SILENT. No frames, no timers you can feel, no chat spam. If you notice
--     this module while playing, it is doing something wrong.
--   * IDEMPOTENT. An item already recorded is skipped, so a full bag scan
--     after the first is nearly free and the store does not grow with playtime.
--   * BOUNDED. Hard caps on every table. SavedVariables that grow forever
--     eventually corrupt on write, and a lost store costs weeks of play.
--   * FLAT STRINGS. Each record is one tab-separated line, not a nested
--     table. It keeps the saved file small, diffable, and trivial to parse
--     outside the game.
--   * FOREVER ONLY. Retail loads this file too (shared Mainline TOC), so Init
--     stands the module down anywhere else. Retail already has real data; it
--     does not need a recorder and must not pay for one.
--
-- HOW THE DATA GETS OUT: the saved file is the primary path --
--   <WoW>\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables\ToonAge.lua
-- read it directly, no player action needed beyond logging out or /reload
-- (WoW only flushes SavedVariables then). The Export button on the Harvest
-- tab is the fallback for when that file is not reachable.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local H = {}
TA:RegisterModule("DataHarvester", H)

local STORE_VERSION = 1

-- Caps. Chosen so the saved file stays well under a megabyte: Vanilla-era
-- content has a few thousand distinct items in levelling range, so 20k is
-- generous, and the spell/talent sets are small and finite by nature.
local MAX_ITEMS   = 20000
local MAX_SPELLS  = 6000
local MAX_TALENTS = 2000

-- Bag scans are debounced: BAG_UPDATE_DELAYED can fire several times for one
-- loot, and a scan that walks five bags per fire is the kind of thing players
-- feel as a stutter.
local SCAN_DELAY = 1.0

local EQUIP_SLOTS = 19   -- 1..19 covers every equippable slot on this client

-- ── Guarded client calls ──────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h, i, j, k, l, m, n
end

-- ── Store ─────────────────────────────────────────────────────────────────

local function Store()
    if not TA.db then return nil end
    local s = TA.db.foreverHarvest
    if not s then
        s = { version = STORE_VERSION, items = {}, spells = {},
              talents = {}, chars = {}, counts = {} }
        TA.db.foreverHarvest = s
    end
    -- Backfill rather than reset: a store written by an older version still
    -- holds real observations and must not be thrown away over a schema bump.
    s.items   = s.items   or {}
    s.spells  = s.spells  or {}
    s.talents = s.talents or {}
    s.chars   = s.chars   or {}
    s.counts  = s.counts  or {}
    return s
end

local function Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Writes key -> line if the key is new and the table is under its cap.
--- Returns true when something was actually recorded.
local function Put(tbl, key, line, cap)
    if tbl[key] ~= nil then return false end
    if cap and Count(tbl) >= cap then return false end
    tbl[key] = line
    return true
end

-- Tabs separate fields, so any tab inside a value would corrupt the record.
local function Clean(v)
    v = tostring(v or "")
    return (v:gsub("[\t\r\n]", " "))
end

-- ── Items ─────────────────────────────────────────────────────────────────

--- The stat block, flattened to "KEY=value,KEY=value". This is the whole
--- point of the exercise: it is the client stating, for a real Forever item,
--- which stats exist and at what magnitude. Everything a future gear score
--- needs is downstream of this one string.
local function StatString(link)
    local stats
    if C_Item and C_Item.GetItemStats then
        stats = Try(C_Item.GetItemStats, link)
    end
    if type(stats) ~= "table" then
        stats = Try(GetItemStats, link)
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
    if C_Item and C_Item.GetItemInfo then
        return Try(C_Item.GetItemInfo, link)
    end
    return Try(GetItemInfo, link)
end

--- Item ID for a link, whatever this client exposes.
---
--- The global GetItemInfoInstant is NIL on Forever (measured 2026-09-23, see
--- Modules/Farming/GatherTracker.lua ItemClass). Calling only the global made
--- Try() return nil for every item, so RecordItem exited before writing
--- anything and the item store stayed empty on the one client it exists for.
--- The link itself carries the id ("|Hitem:12345:..."), so parsing it is the
--- final route and needs no API at all.
local function ItemID(link)
    if C_Item and C_Item.GetItemInfoInstant then
        local id = Try(C_Item.GetItemInfoInstant, link)
        if id then return id end
    end
    if GetItemInfoInstant then
        local id = Try(GetItemInfoInstant, link)
        if id then return id end
    end
    if type(link) == "string" then
        return tonumber(link:match("item:(%d+)"))
    end
    return nil
end

function H:RecordItem(link)
    if not link then return false end

    local itemID = ItemID(link)
    if not itemID then return false end

    local s = Store()
    if not s then return false end
    if s.items[itemID] ~= nil then return false end   -- already known, cheap exit

    local name, _, quality, ilvl, minLevel, itemType, itemSubType,
          _, equipLoc, _, _, classID, subclassID, bindType = ItemInfo(link)

    -- No name means the client has not cached this item yet. Skip it rather
    -- than writing a half-record: GET_ITEM_INFO_RECEIVED or the next scan
    -- will catch it once the data lands.
    if not name then return false end

    return Put(s.items, itemID, table.concat({
        Clean(name), Clean(ilvl), Clean(quality), Clean(minLevel),
        Clean(classID), Clean(subclassID), Clean(itemType), Clean(itemSubType),
        Clean(equipLoc), Clean(bindType), StatString(link),
    }, "\t"), MAX_ITEMS)
end

function H:ScanEquipped()
    local n = 0
    for slot = 1, EQUIP_SLOTS do
        local link = Try(GetInventoryItemLink, "player", slot)
        if link and self:RecordItem(link) then n = n + 1 end
    end
    return n
end

function H:ScanBags()
    local n = 0
    for bag = 0, 4 do
        local slots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            slots = Try(C_Container.GetContainerNumSlots, bag) or 0
        else
            slots = Try(GetContainerNumSlots, bag) or 0
        end
        for slot = 1, slots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = Try(C_Container.GetContainerItemLink, bag, slot)
            else
                link = Try(GetContainerItemLink, bag, slot)
            end
            if link and self:RecordItem(link) then n = n + 1 end
        end
    end
    return n
end

function H:ScanLoot()
    local n = 0
    local num = Try(GetNumLootItems) or 0
    for i = 1, num do
        local link = Try(GetLootSlotLink, i)
        if link and self:RecordItem(link) then n = n + 1 end
    end
    return n
end

-- ── Spells ────────────────────────────────────────────────────────────────
--
-- Two spellbook APIs exist depending on client generation. Forever runs the
-- Midnight API, so C_SpellBook is tried first, but the legacy globals are
-- kept because this client's API set is only partly mapped and guessing wrong
-- would silently collect nothing.

function H:ScanSpellbook()
    local s = Store()
    if not s then return 0 end

    local _, class = Try(UnitClass, "player")
    class = class or "UNKNOWN"
    local level = Try(UnitLevel, "player") or 0
    local n = 0

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
       and C_SpellBook.GetSpellBookItemInfo then
        local lines = Try(C_SpellBook.GetNumSpellBookSkillLines) or 0
        for line = 1, lines do
            local info = Try(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if type(info) == "table" and info.numSpellBookItems then
                for i = info.itemIndexOffset + 1,
                        info.itemIndexOffset + info.numSpellBookItems do
                    local item = Try(C_SpellBook.GetSpellBookItemInfo, i,
                                     Enum and Enum.SpellBookSpellBank
                                          and Enum.SpellBookSpellBank.Player)
                    if type(item) == "table" and item.spellID then
                        if Put(s.spells, class .. ":" .. item.spellID,
                               table.concat({ Clean(item.name), Clean(level),
                                              Clean(info.name) }, "\t"),
                               MAX_SPELLS) then
                            n = n + 1
                        end
                    end
                end
            end
        end
        if n > 0 then return n end
    end

    -- Legacy path.
    local numTabs = Try(GetNumSpellTabs) or 0
    for tab = 1, numTabs do
        local tabName, _, offset, numSpells = Try(GetSpellTabInfo, tab)
        for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
            local spellName = Try(GetSpellBookItemName, i, "spell")
            local _, spellID = Try(GetSpellBookItemInfo, i, "spell")
            if spellID and spellName then
                if Put(s.spells, class .. ":" .. spellID,
                       table.concat({ Clean(spellName), Clean(level),
                                      Clean(tabName) }, "\t"), MAX_SPELLS) then
                    n = n + 1
                end
            end
        end
    end
    return n
end

-- ── Talents ───────────────────────────────────────────────────────────────
--
-- Forever uses Vanilla-style trees (Core/Profile.lua calls the rule set
-- "vanilla-trees"), so the legacy talent globals are the expected path. The
-- tree SHAPE is what matters here -- tier, column, max rank -- not what this
-- character happened to spend points on.

function H:ScanTalents()
    local s = Store()
    if not s then return 0 end

    local _, class = Try(UnitClass, "player")
    class = class or "UNKNOWN"
    local n = 0

    local numTabs = Try(GetNumTalentTabs) or 0
    for tab = 1, numTabs do
        local tabName = Try(GetTalentTabInfo, tab)
        local numTalents = Try(GetNumTalents, tab) or 0
        for i = 1, numTalents do
            local name, _, tier, column, _, maxRank = Try(GetTalentInfo, tab, i)
            if name then
                if Put(s.talents, class .. ":" .. tab .. ":" .. i,
                       table.concat({ Clean(tabName), Clean(name), Clean(tier),
                                      Clean(column), Clean(maxRank) }, "\t"),
                       MAX_TALENTS) then
                    n = n + 1
                end
            end
        end
    end
    return n
end

--- The MODERN talent system, which is what this client actually runs.
---
--- ScanTalents above reads the Vanilla globals and returns 0 here, because
--- Forever's talent window is the trait UI (three trees, loadout tabs, Apply
--- Changes) -- confirmed on the live client 2026-09-22. This records the same
--- ground truth from C_Traits: every node, what it defines, and what rank YOU
--- put in it.
---
--- Why it is worth recording: a recommendation engine needs to know what a
--- talent is worth in this game, and nobody has published that. What CAN be
--- known is what people actually pick at each level. That is observation, and
--- it starts here.
---
--- One line per node: tree, node, entry, spellID, name, yourRank, maxRank, level.
function H:ScanTraitTree()
    local s = Store()
    if not s then return 0 end
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits) then return 0 end

    local configID = Try(C_ClassTalents.GetActiveConfigID)
    if not configID then return 0 end

    local cfg = Try(C_Traits.GetConfigInfo, configID)
    if type(cfg) ~= "table" or type(cfg.treeIDs) ~= "table" then return 0 end

    local _, class = Try(UnitClass, "player")
    class = class or "UNKNOWN"
    local level = Try(UnitLevel, "player") or 0
    local n = 0

    for _, treeID in ipairs(cfg.treeIDs) do
        local nodes = Try(C_Traits.GetTreeNodes, treeID)
        if type(nodes) == "table" then
            for _, nodeID in ipairs(nodes) do
                local info = Try(C_Traits.GetNodeInfo, configID, nodeID)
                if type(info) == "table" then
                    local rank = info.activeRank or info.ranksPurchased or 0
                    local entryID = info.activeEntry and info.activeEntry.entryID
                    if not entryID and type(info.entryIDs) == "table" then
                        entryID = info.entryIDs[1]
                    end

                    local spellID, name
                    if entryID then
                        local entry = Try(C_Traits.GetEntryInfo, configID, entryID)
                        if type(entry) == "table" and entry.definitionID then
                            local def = Try(C_Traits.GetDefinitionInfo, entry.definitionID)
                            if type(def) == "table" then
                                spellID = def.spellID
                                if spellID and C_Spell and C_Spell.GetSpellName then
                                    name = Try(C_Spell.GetSpellName, spellID)
                                end
                            end
                        end
                    end

                    -- Keyed by class + node, so the same node seen on two
                    -- characters of a class is one record. Per-character builds
                    -- are a separate, larger question; this is the vocabulary.
                    local key = class .. ":T:" .. tostring(treeID) .. ":" .. tostring(nodeID)
                    if Put(s.talents, key, table.concat({
                            Clean(treeID), Clean(nodeID), Clean(entryID),
                            Clean(spellID), Clean(name), Clean(rank),
                            Clean(info.maxRanks), Clean(level),
                        }, "\t"), MAX_TALENTS) then
                        n = n + 1
                    end
                end
            end
        end
    end
    return n
end

-- ── Character snapshot ────────────────────────────────────────────────────
--
-- One line per character, overwritten each login. Not a log -- just enough
-- context to know which class and level a spell or talent record came from.

function H:RecordCharacter()
    local s = Store()
    if not s then return end
    local name  = Try(UnitName, "player") or "?"
    local realm = Try(GetRealmName) or "?"
    local cls   = select(2, Try(UnitClass, "player")) or "?"
    local race  = select(2, Try(UnitRace, "player")) or "?"
    s.chars[name .. "-" .. realm] = table.concat({
        Clean(cls), Clean(race), Clean(Try(UnitLevel, "player")),
        Clean(Try(UnitSex, "player")), Clean(select(4, Try(GetBuildInfo))),
    }, "\t")
end

-- ── Scheduling ────────────────────────────────────────────────────────────

function H:QueueScan()
    if self._scanQueued then return end
    self._scanQueued = true
    C_Timer.After(SCAN_DELAY, function()
        self._scanQueued = false
        self:ScanBags()
        self:ScanEquipped()
    end)
end

function H:OnEvent(event)
    if event == "LOOT_OPENED" then
        self:ScanLoot()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" then
        self:QueueScan()
    elseif event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED"
        or event == "LEARNED_SPELL_IN_SKILL_LINE" then
        self:ScanSpellbook()
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE"
        or event == "TRAIT_CONFIG_UPDATED" then
        self:ScanTalents()
        self:ScanTraitTree()
    elseif event == "PLAYER_LEVEL_UP" then
        self:RecordCharacter()
        self:ScanSpellbook()
        self:ScanTalents()
        self:ScanTraitTree()
    end
end

function H:OnEnterWorld()
    self:RecordCharacter()
    self:QueueScan()
    self:ScanSpellbook()
    self:ScanTalents()
    self:ScanTraitTree()
end

-- ── Export ────────────────────────────────────────────────────────────────
--
-- The fallback path. Reading the saved file off disk is better in every way
-- -- complete, no clicking, no page limit -- but it needs access to the WoW
-- folder, and this works from anywhere.

local EXPORT_PAGE = 400   -- records per page; a copy window past this scrolls badly

function H:Export(section, page)
    local s = Store()
    if not s then return end
    section = section or "items"
    page    = page or 1

    local tbl = s[section]
    if type(tbl) ~= "table" then return end

    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    local total = #keys
    local pages = math.max(1, math.ceil(total / EXPORT_PAGE))
    if page > pages then page = pages end
    local first = (page - 1) * EXPORT_PAGE + 1
    local last  = math.min(total, page * EXPORT_PAGE)

    local out = {
        ("-- ToonAge Forever harvest · %s · page %d/%d · records %d-%d of %d")
            :format(section, page, pages, first, last, total),
        ("-- build %s · store v%s")
            :format(tostring(select(4, Try(GetBuildInfo))), tostring(s.version)),
        "",
    }
    for i = first, last do
        out[#out + 1] = tostring(keys[i]) .. "\t" .. tostring(tbl[keys[i]])
    end

    if TA.ShowCopyWindow then
        TA:ShowCopyWindow(("ToonAge harvest — %s (%d/%d)"):format(section, page, pages),
                          table.concat(out, "\n"))
    end
    self._page = page
    self._pages = pages
    self._section = section
end

-- ── Tab ───────────────────────────────────────────────────────────────────

function H:Render(content, side)
    local L = TA.Layout
    if not L then return end
    local s = Store()
    local y = -14

    y = L:SectionHeader(content, y, "Harvested so far",
        "Everything below is what the client said, recorded verbatim. Nothing "
        .. "here is interpreted, weighted or ranked.")

    if not s then
        y = L:Paragraph(content, y, "|cFFFF4444The database is not available yet.|r")
        L:Finish(content, y)
        return
    end

    local items, spells, talents, chars =
        Count(s.items), Count(s.spells), Count(s.talents), Count(s.chars)

    y = L:DataRow(content, y, { label = "Items with full stat blocks", value = tostring(items) })
    y = L:DataRow(content, y, { label = "Spells seen in spellbooks",   value = tostring(spells) })
    y = L:DataRow(content, y, { label = "Talent tree nodes",           value = tostring(talents) })
    y = L:DataRow(content, y, { label = "Characters contributing",     value = tostring(chars) })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Export")
    y = L:Paragraph(content, y,
        "The saved file is the better path and needs none of these buttons: it "
        .. "lives under WTF\\Account\\<your account>\\SavedVariables\\ToonAge.lua "
        .. "and is written when you log out or /reload. Use the buttons when "
        .. "that file cannot be reached.")

    y = L:ButtonRow(content, y, {
        { label = "Items",    onClick = function() H:Export("items", 1)   end },
        { label = "Spells",   onClick = function() H:Export("spells", 1)  end },
        { label = "Talents",  onClick = function() H:Export("talents", 1) end },
        { label = "Characters", onClick = function() H:Export("chars", 1) end },
    }, { label = "Copy:" })

    if (self._pages or 1) > 1 then
        y = L:ButtonRow(content, y, {
            { label = "< Prev", onClick = function()
                H:Export(H._section, math.max(1, (H._page or 1) - 1)) end },
            { label = "Next >", onClick = function()
                H:Export(H._section, math.min(H._pages or 1, (H._page or 1) + 1)) end },
        }, { label = ("Page %d of %d:"):format(self._page or 1, self._pages or 1) })
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Reset")
    y = L:Paragraph(content, y,
        "|cFF888780Clearing throws away every observation collected so far and "
        .. "cannot be undone. There is no reason to do it unless a store is "
        .. "corrupt -- re-recording an item costs nothing, so the table never "
        .. "needs pruning.|r")
    y = L:ButtonRow(content, y, {
        { label = self._confirmClear and "Really clear?" or "Clear store",
          onClick = function()
            if H._confirmClear then
                TA.db.foreverHarvest = nil
                H._confirmClear = nil
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Harvest store cleared.")
            else
                H._confirmClear = true
            end
            if L.RefreshUI then L:RefreshUI() end
          end },
    })

    L:Finish(content, y)
end

-- ── Init ──────────────────────────────────────────────────────────────────

function H:Init()
    -- Retail loads this file too, through the shared Mainline TOC. Retail has
    -- real, researched data and must not pay for a recorder it cannot use.
    if not TA.IsForever then
        self._disabled = true
        return
    end

    TA:RegisterEvent("LOOT_OPENED")
    TA:RegisterEvent("BAG_UPDATE_DELAYED")
    TA:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    TA:RegisterEvent("SPELLS_CHANGED")
    -- Both names on purpose. LEARNED_SPELL_IN_TAB is the classic-era event and
    -- LEARNED_SPELL_IN_SKILL_LINE the modern one; Forever answers to the
    -- second and threw on the first, which is what killed this module's Init
    -- before TA:RegisterEvent started absorbing that. Asking for both costs
    -- nothing now and means the recorder works on either client.
    TA:RegisterEvent("LEARNED_SPELL_IN_TAB")
    TA:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
    TA:RegisterEvent("CHARACTER_POINTS_CHANGED")
    -- The modern talent system's change events. Registering one this client
    -- does not define is absorbed by TA:RegisterEvent, same as the classic
    -- spell events above.
    TA:RegisterEvent("PLAYER_TALENT_UPDATE")
    TA:RegisterEvent("TRAIT_CONFIG_UPDATED")
    TA:RegisterEvent("PLAYER_LEVEL_UP")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r DataHarvester recording.")
    end
end
