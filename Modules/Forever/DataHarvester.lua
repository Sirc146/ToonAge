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

-- v2 (2026-09-28): characters keyed by GUID with name/realm as fields, and
-- spell records carry their rank text. v1 records are upgraded in place when
-- the same character or spell is seen again; nothing is thrown away.
-- 2026-09-29: spell records gain a 6th field, the level the rank is trained
-- at (C_Spell.GetSpellLevelLearned), and a record whose rank text was stored
-- blank is rewritten once the client reports it. Same store version: every
-- older record is upgraded in place on the next scan.
--   spells["CLASS:spellID"] = name, first-seen level, spellbook line, rank text,
--                             "passive" or "", trained level
-- The store itself is the shared harvest core's (Modules/Infrastructure/
-- Harvester.lua, harvest spec T3): TA.db.harvest, store version 3, moved there
-- from TA.db.foreverHarvest on first use with every record kept.

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

local PROBE_SECRET_EARLY = _G.issecretvalue or function() return false end

-- ── Store ─────────────────────────────────────────────────────────────────

local function Store()
    local Hv = TA.Harvester
    return Hv and Hv:Store() or nil
end

-- A write stamps its section's first/last time (the export's harvest range).
local function Touched(tbl)
    local Hv = TA.Harvester
    if Hv then Hv:TouchTable(tbl) end
end

local function Touch(section)
    local Hv = TA.Harvester
    if Hv then Hv:Touch(section) end
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
    Touched(tbl)
    return true
end

--- Like Put, but replaces a record written by an older schema: one with fewer
--- than `minFields` tab-separated fields. Everything else stays first-seen.
local function PutOrUpgrade(tbl, key, line, cap, minFields)
    local old = tbl[key]
    if old ~= nil then
        local _, tabs = tostring(old):gsub("\t", "")
        if tabs + 1 >= minFields then return false end
        tbl[key] = line
        Touched(tbl)
        return true
    end
    return Put(tbl, key, line, cap)
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

-- ── Racials ───────────────────────────────────────────────────────────────
--
-- For the PvP tab's matchups (what your race counters, what theirs counters).
-- spells[] is keyed by CLASS, so it cannot say which race a racial belongs to;
-- this table can. Faction is part of the key because Forever splits racials by
-- it (measured 2026-09-29: Skyborne Alliance gets Read Ley Line, Skyborne Horde
-- gets Skysight, both Warriors). The tooltip is stored verbatim -- it is where
-- the effect and cooldown live ("2 min cooldown", "removes Fear effects");
-- nothing is interpreted here.
--   racials["RACE:FACTION:spellID"] = name, rank text, "passive" or "",
--                                     classes seen (comma list), tooltip text

local function TooltipText(spellID)
    local fn = C_TooltipInfo and C_TooltipInfo.GetSpellByID
    if type(fn) ~= "function" then return "" end
    local ok, data = pcall(fn, spellID)
    if not (ok and type(data) == "table" and type(data.lines) == "table") then return "" end
    local parts = {}
    for i = 2, #data.lines do          -- line 1 is the spell name
        local ln = data.lines[i]
        for _, t in ipairs({ ln.leftText, ln.rightText }) do
            if type(t) == "string" and t ~= "" and not PROBE_SECRET_EARLY(t) then
                parts[#parts + 1] = t
            end
        end
    end
    return table.concat(parts, " | ")
end

function H:RecordRacial(spellID, name, rank, passive)
    local s = Store()
    if not (s and spellID) then return end
    local race    = select(2, Try(UnitRace, "player")) or "?"
    local faction = Try(UnitFactionGroup, "player") or "?"
    local class   = select(2, Try(UnitClass, "player")) or "?"
    local key = race .. ":" .. faction .. ":" .. spellID
    local f = {}
    if s.racials[key] then
        for v in (s.racials[key] .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = v end
    end
    local classes = f[4] or ""
    if not ("," .. classes .. ","):find("," .. class .. ",", 1, true) then
        classes = (classes == "") and class or (classes .. "," .. class)
    end
    local tip = f[5]
    if not tip or tip == "" then tip = TooltipText(spellID) end
    s.racials[key] = table.concat({ Clean(name), Clean(rank),
        Clean(passive and "passive" or ""), Clean(classes), Clean(tip) }, "\t")
    Touch("racials")
end

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
                        -- Rank text ("Rank 2"), the same source the Spells tab
                        -- reads: the item's own subName, else C_Spell.GetSpellSubtext.
                        local rank = item.subName
                        if (not rank or rank == "") and C_Spell and C_Spell.GetSpellSubtext then
                            rank = Try(C_Spell.GetSpellSubtext, item.spellID)
                        end
                        local key = class .. ":" .. item.spellID
                        -- An upgraded record keeps the level it was first seen at.
                        local old = s.spells[key]
                        local seen = old and old:match("^[^\t]*\t([^\t]*)") or level
                        -- Trainer level for this rank (C_Spell.GetSpellLevelLearned,
                        -- measured working on Forever 2026-09-29: Fireball 1/6/12).
                        local learned = C_Spell and C_Spell.GetSpellLevelLearned
                            and Try(C_Spell.GetSpellLevelLearned, item.spellID) or nil
                        local line = table.concat({ Clean(item.name), Clean(seen),
                                              Clean(info.name), Clean(rank),
                                              Clean(item.isPassive and "passive" or ""),
                                              Clean(learned) }, "\t")
                        -- Rank text can come back blank when spell data is not
                        -- loaded yet (the first v2 scans stored "" for every
                        -- rank, although GetSpellSubtext answers "Rank 2" later).
                        -- So a record with a blank rank or learned level is
                        -- rewritten once the client has the value.
                        local oldRank, oldLearned
                        if old then
                            local f = {}
                            for v in (old .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = v end
                            oldRank, oldLearned = f[4] or "", f[6] or ""
                        end
                        local better = old and (
                               (oldRank == "" and Clean(rank) ~= "")
                            or (oldLearned == "" and Clean(learned) ~= ""))
                        if tostring(rank or ""):find("Racial") then
                            self:RecordRacial(item.spellID, item.name, rank, item.isPassive)
                        end
                        if better then
                            s.spells[key] = line
                            Touch("spells")
                            n = n + 1
                        elseif PutOrUpgrade(s.spells, key, line, MAX_SPELLS, 6) then
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
            local spellName, subName = Try(GetSpellBookItemName, i, "spell")
            local _, spellID = Try(GetSpellBookItemInfo, i, "spell")
            if spellID and spellName then
                local key = class .. ":" .. spellID
                local seen = s.spells[key] and s.spells[key]:match("^[^\t]*\t([^\t]*)") or level
                if PutOrUpgrade(s.spells, key,
                       table.concat({ Clean(spellName), Clean(seen),
                                      Clean(tabName), Clean(subName), "" }, "\t"),
                       MAX_SPELLS, 5) then
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

    local geoKeysSeen = false
    local geoWritten = false
    for _, treeID in ipairs(cfg.treeIDs) do
        -- Tree-level gates ("spend N points to unlock this row"), and the
        -- condition records nodes point at. Recorded raw, field names included.
        if C_Traits.GetTreeInfo then
            local ti = Try(C_Traits.GetTreeInfo, configID, treeID)
            if type(ti) == "table" then
                local gates = {}
                for _, g in ipairs(type(ti.gates) == "table" and ti.gates or {}) do
                    if type(g) == "table" then
                        gates[#gates + 1] = tostring(g.topLeftNodeID) .. ":" .. tostring(g.conditionID)
                    end
                end
                s.talentGates = s.talentGates or {}
                s.talentGates[class .. ":" .. tostring(treeID)] = table.concat(gates, ",")
                for _, g in ipairs(type(ti.gates) == "table" and ti.gates or {}) do
                    local ci = type(g) == "table" and g.conditionID and C_Traits.GetConditionInfo
                        and Try(C_Traits.GetConditionInfo, configID, g.conditionID)
                    if type(ci) == "table" then
                        s.talentConds = s.talentConds or {}
                        s.talentConds[class .. ":" .. tostring(g.conditionID)] =
                            tostring(ci.spentAmountRequired) .. "\t" .. tostring(ci.isMet)
                    end
                end
            end
        end
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
                    -- Geometry (2026-10-03): what a drawn tree and a point-path
                    -- planner need -- position, prerequisite edges, gating
                    -- conditions. UNVERIFIED on Forever; recorded only if the
                    -- fields come back, and the field names seen are logged
                    -- once per class so the next build reads what exists.
                    if not geoKeysSeen then
                        local ks = {}
                        for k in pairs(info) do ks[#ks + 1] = tostring(k) end
                        table.sort(ks)
                        s.talentApi = s.talentApi or {}
                        s.talentApi[class] = table.concat(ks, ",")
                        geoKeysSeen = true
                    end
                    local edges = {}
                    if type(info.visibleEdges) == "table" then
                        for _, e in ipairs(info.visibleEdges) do
                            if type(e) == "table" and e.targetNode then
                                edges[#edges + 1] = tostring(e.targetNode) .. ":" .. tostring(e.type or "")
                            end
                        end
                    end
                    local conds = {}
                    if type(info.conditionIDs) == "table" then
                        for _, c in ipairs(info.conditionIDs) do
                            conds[#conds + 1] = tostring(c)
                            local ci = C_Traits.GetConditionInfo and Try(C_Traits.GetConditionInfo, configID, c)
                            if type(ci) == "table" then
                                s.talentConds = s.talentConds or {}
                                s.talentConds[class .. ":" .. tostring(c)] =
                                    tostring(ci.spentAmountRequired) .. "\t" .. tostring(ci.isMet)
                            end
                        end
                    end
                    geoWritten = true
                    s.talentGeo[class .. ":" .. tostring(treeID) .. ":" .. tostring(nodeID)] = table.concat({
                        Clean(info.posX), Clean(info.posY), table.concat(edges, ","),
                        table.concat(conds, ","), Clean(info.type), Clean(info.subTreeID),
                        Clean(spellID and C_Spell and C_Spell.GetSpellTexture
                              and Try(C_Spell.GetSpellTexture, spellID)),
                    }, "\t")

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
    if geoWritten then Touch("talentGeo") end
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
    -- Keyed by GUID, not Name-Realm: the same Mage was recorded twice
    -- ("Eramali Stryfe" at 15, "Eramali" at 17) because the name the client
    -- reported changed between sessions. A GUID never does. Name and realm are
    -- kept as fields so the export still reads naturally.
    local guid = Try(UnitGUID, "player")
    -- (PROBE_SECRET is defined further down this file; ask Utils instead.)
    if guid and TA.Utils and TA.Utils.IsSecret and TA.Utils.IsSecret(guid) then guid = nil end
    local key = guid or (name .. "-" .. realm)
    s.chars[key] = table.concat({
        Clean(name), Clean(realm),
        Clean(cls), Clean(race), Clean(Try(UnitLevel, "player")),
        Clean(Try(UnitSex, "player")), Clean(select(4, Try(GetBuildInfo))),
    }, "\t")
    -- The v1 record for this character (Name-Realm key) is superseded.
    if guid then s.chars[name .. "-" .. realm] = nil end
    Touch("chars")
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

-- ── Trainer ───────────────────────────────────────────────────────────────
-- 2026-10-03. The spell catalog cannot get rank text for spells you don't know
-- (pass 2: "+0 ranks, 9815 still blank"). A class trainer lists every rank of
-- every spell with its required level -- in Vanilla it listed the ones you are
-- too low for as well, under the "Unavailable" filter. If Forever's does the
-- same, ONE visit per class gives the whole rank table at any level.
-- UNVERIFIED ON FOREVER: every call is guarded, and what the client answered
-- is recorded in s.trainerApi so the first visit settles it. Records only; it
-- never changes the trainer's filters or buys anything.
--
-- Record: s.trainer[CLASS][name .. "\t" .. rank] =
--   "levelReq \t category \t spellID \t when"   (category: available /
--   unavailable / used, as the trainer reports it)
function H:ScanTrainer()
    local s = Store()
    if not s then return end
    local api = {}
    for _, n in ipairs({ "GetNumTrainerServices", "GetTrainerServiceInfo",
                         "GetTrainerServiceLevelReq", "GetTrainerServiceTypeFilter" }) do
        api[#api + 1] = n .. "=" .. (type(_G[n]) == "function" and "yes" or "NO")
    end
    local tip = C_TooltipInfo and C_TooltipInfo.GetTrainerService
    api[#api + 1] = "C_TooltipInfo.GetTrainerService=" .. (tip and "yes" or "NO")

    local n = tonumber((Try(GetNumTrainerServices)))
    local _, class = Try(UnitClass, "player")
    if not (n and class) then
        s.trainerApi = table.concat(api, " ") .. " | services=nil"
        return
    end
    -- Profession trainers list recipes, not class spells (MEASURED 2026-10-03:
    -- a Blacksmithing trainer's 21 recipes were filed as MAGE spells, every
    -- level requirement 0). IsTradeskillTrainer() says which kind this is;
    -- a list whose every level requirement is 0 is treated the same way when
    -- that function is absent.
    if Try(_G.IsTradeskillTrainer) == true then
        s.trainerApi = table.concat(api, " ") .. " | profession trainer -- not recorded as class spells"
        return
    end
    if n == 0 then
        -- TRAINER_UPDATE also fires as the window closes, with 0 services.
        -- Recording that would overwrite the real visit's status line.
        return
    end
    local unavailShown = Try(GetTrainerServiceTypeFilter, "unavailable")
    -- Record format 2 (2026-10-03). Format 1 keyed rows by name + the 2nd
    -- return, assumed to be rank text. MEASURED on Forever build 70205: the
    -- returns are (name, category, texture, ...) -- no rank text -- so every
    -- rank of a spell shared one key and only the last survived (Fireball
    -- kept its level-60 rank only). Keyed by spell ID now.
    if s.trainerFormat ~= 2 then s.trainer = {}; s.trainerFormat = 2 end
    -- One-time clean-up of a profession trainer recorded before the check above.
    if not s.trainerProfPurged then
        for cls, rowsByID in pairs(s.trainer) do
            local ok = false
            for _, line in pairs(rowsByID) do
                local req = tonumber((tostring(line):match("^[^\t]*\t[^\t]*\t([^\t]*)")))
                if req and req > 0 then ok = true break end
            end
            if not ok then s.trainer[cls] = nil end
        end
        s.trainerProfPurged = true
    end
    s.trainer[class] = s.trainer[class] or {}
    local t, rows, unavailable, noID = s.trainer[class], 0, 0, 0
    local CATEGORY = { available = true, unavailable = true, used = true, header = true }
    for i = 1, n do
        local r = { Try(GetTrainerServiceInfo, i) }
        local name = r[1]
        -- Category is whichever early return is a category word, so a client
        -- that does return rank text (Classic Era's order) still parses.
        local category, rankText
        for k = 2, 4 do
            local v = r[k]
            if type(v) == "string" then
                if CATEGORY[v] then category = category or v
                elseif v:find("%d") then rankText = rankText or v end
            end
        end
        if type(name) == "string" and name ~= "" and category ~= "header"
           and not PROBE_SECRET_EARLY(name) then
            local req = tonumber((Try(GetTrainerServiceLevelReq, i))) or 0
            local id
            if tip then
                local data = Try(tip, i)
                if type(data) == "table" and type(data.id) == "number" then id = data.id end
            end
            -- name \t rankText \t levelReq \t category \t when
            local key = id and tostring(id) or (Clean(name) .. "@" .. req)
            if not id then noID = noID + 1 end
            t[key] = table.concat({ Clean(name), Clean(rankText), req, Clean(category),
                time and time() or 0 }, "\t")
            rows = rows + 1
            if category == "unavailable" then unavailable = unavailable + 1 end
        end
    end
    local anyLevel = false
    for _, line in pairs(t) do
        local req = tonumber((tostring(line):match("^[^\t]*\t[^\t]*\t([^\t]*)")))
        if req and req > 0 then anyLevel = true break end
    end
    if rows > 0 and not anyLevel then
        s.trainer[class] = nil
        s.trainerApi = table.concat(api, " ") .. " | every level requirement 0: profession trainer, discarded"
        return
    end
    if rows > 0 then Touch("trainer") end
    s.trainerApi = table.concat(api, " ")
        .. (" | %s: services=%d recorded=%d unavailable=%d noSpellID=%d filter(unavailable)=%s")
        :format(class, n, rows, unavailable, noID, tostring(unavailShown))
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
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        -- TRAINER_UPDATE fires on every filter click; one scan per second.
        if self._trainerPending then return end
        self._trainerPending = true
        C_Timer.After(1, function() self._trainerPending = nil; pcall(self.ScanTrainer, self) end)
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

-- ── Client probes ─────────────────────────────────────────────────────────
-- The questions the Forever brief still has open, answered in one click and
-- shown in the copyable window -- never chat, which is too small to read and
-- cannot be selected. Every call is guarded: a missing function prints
-- "missing", an error prints the error, a secret prints "secret".

local PROBE_SECRET = _G.issecretvalue or function() return false end

local function Show(v, depth)
    depth = depth or 0
    if v == nil then return "nil" end
    if PROBE_SECRET(v) then return "secret" end
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" then return tostring(v) end
    if depth >= 2 then return "{...}" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = tostring(k) .. "=" .. Show(v[k], depth + 1)
        if #out >= 40 then out[#out + 1] = "..." break end
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end

local function Call(lines, label, fn, ...)
    if type(fn) ~= "function" then
        lines[#lines + 1] = label .. "  ->  missing"
        return
    end
    local res = { pcall(fn, ...) }
    if not res[1] then
        lines[#lines + 1] = label .. "  ->  error: " .. tostring(res[2])
        return
    end
    local parts = {}
    for i = 2, math.max(#res, 2) do parts[#parts + 1] = Show(res[i]) end
    lines[#lines + 1] = label .. "  ->  " .. table.concat(parts, ", ")
end

local function NS(ns, fn) return type(ns) == "table" and ns[fn] or nil end

--- Every probe, as lines. RunProbes shows them; RunAll folds them into the
--- one combined report.
function H:BuildProbeLines()
    local L = {}
    local function head(t) L[#L + 1] = "" ; L[#L + 1] = "== " .. t .. " ==" end

    head("Client")
    Call(L, "GetBuildInfo()", GetBuildInfo)
    L[#L + 1] = "WOW_PROJECT_ID  ->  " .. Show(_G.WOW_PROJECT_ID)
    Call(L, "UnitClass(player)", UnitClass, "player")
    Call(L, "UnitLevel(player)", UnitLevel, "player")

    head("Professions and skills")
    local slots = { pcall(GetProfessions) }
    if slots[1] then
        for i = 2, 7 do
            if slots[i] then Call(L, "GetProfessionInfo(" .. tostring(slots[i]) .. ")", GetProfessionInfo, slots[i]) end
        end
    else
        L[#L + 1] = "GetProfessions()  ->  " .. (type(GetProfessions) == "function" and "error" or "missing")
    end
    Call(L, "C_TradeSkillUI.GetProfessionInfoBySkillLineID(3012) [Comprehension]",
        NS(C_TradeSkillUI, "GetProfessionInfoBySkillLineID"), 3012)
    Call(L, "IsSpellKnown(1296017) [Comprehend Scroll]", IsSpellKnown, 1296017)
    Call(L, "C_SpellBook.GetNumSpellBookSkillLines()", NS(C_SpellBook, "GetNumSpellBookSkillLines"))
    local okN, n = pcall(NS(C_SpellBook, "GetNumSpellBookSkillLines") or error)
    if okN and type(n) == "number" and not PROBE_SECRET(n) then
        for i = 1, math.min(n, 12) do
            local ok, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, i)
            L[#L + 1] = ("  skill line %d  ->  %s"):format(i,
                ok and type(info) == "table" and Show(info.name) or "n/a")
        end
    end

    head("Character sheet")
    Call(L, "UnitAttackBothHands(player) [weapon skill]", UnitAttackBothHands, "player")
    Call(L, "UnitRangedAttack(player)", UnitRangedAttack, "player")
    Call(L, "UnitDefense(player)", UnitDefense, "player")
    for school = 2, 7 do
        Call(L, "GetSpellBonusDamage(" .. school .. ")", GetSpellBonusDamage, school)
    end
    Call(L, "GetSpellBonusHealing()", GetSpellBonusHealing)
    Call(L, "GetManaRegen()", GetManaRegen)

    -- Forever folds Hit into one stat and adds Expertise (Forever/Character.lua
    -- note). Record what each of the classic stat getters answers here.
    Call(L, "GetHitModifier()", GetHitModifier)
    Call(L, "GetSpellHitModifier()", GetSpellHitModifier)
    Call(L, "GetExpertise()", GetExpertise)
    Call(L, "GetCritChance()", GetCritChance)
    Call(L, "GetDodgeChance()", GetDodgeChance)
    Call(L, "GetParryChance()", GetParryChance)
    Call(L, "GetBlockChance()", GetBlockChance)
    Call(L, "UnitAttackSpeed(player)", UnitAttackSpeed, "player")
    Call(L, "UnitDamage(player)", UnitDamage, "player")

    head("Skill lines: C_SkillInfo")
    -- FOUND 2026-09-28 by the API-discovery probe on a level 1 Hunter: the
    -- classic skill globals are gone, but C_SkillInfo carries their modern
    -- replacements, and UnitDefenseSkill / UnitWeaponAttackPower stand in for
    -- UnitDefense / UnitAttackBothHands (the client's own PaperDollFrame_SetDefense
    -- and PaperDollFrame_SetWeaponSkill exist, so the sheet reads them somehow).
    -- This records the exact return shapes before any tab is built on them.
    local SI = _G.C_SkillInfo
    Call(L, "C_SkillInfo.GetNumSkillLines()", NS(SI, "GetNumSkillLines"))
    local okSI, nSI = pcall(NS(SI, "GetNumSkillLines") or error)
    if okSI and type(nSI) == "number" and not PROBE_SECRET(nSI) then
        for i = 1, math.min(nSI, 40) do
            Call(L, ("  C_SkillInfo.GetSkillLineInfo(%d)"):format(i), SI.GetSkillLineInfo, i)
        end
    end
    Call(L, "C_SkillInfo.GetSkillLineInfoByID(95) [Defense]", NS(SI, "GetSkillLineInfoByID"), 95)
    Call(L, "C_SkillInfo.GetSkillLineInfoByID(45) [Bows]", NS(SI, "GetSkillLineInfoByID"), 45)
    Call(L, "C_SkillInfo.GetSkillLineInfoByID(43) [Swords]", NS(SI, "GetSkillLineInfoByID"), 43)
    Call(L, "C_SkillInfo.GetSelectedSkill()", NS(SI, "GetSelectedSkill"))
    Call(L, "UnitDefenseSkill(player)", UnitDefenseSkill, "player")
    Call(L, "UnitWeaponAttackPower(player)", UnitWeaponAttackPower, "player")
    Call(L, "C_PaperDollInfo.OffhandHasWeapon()", NS(C_PaperDollInfo, "OffhandHasWeapon"))

    head("Talent tree geometry")
    -- Does Forever's single tree carry what a drawn tree and a point planner
    -- need? Field names of one node, then counts across this class's nodes.
    do
        local ok = pcall(H.ScanTraitTree, H)
        local s = Store()
        local _, class = Try(UnitClass, "player")
        L[#L + 1] = "GetNodeInfo fields: " .. tostring(s and s.talentApi and s.talentApi[class or ""] or "(none)")
        local n, pos, edges, conds = 0, 0, 0, 0
        local xs, ys = {}, {}
        for key, line in pairs((s and s.talentGeo) or {}) do
            if tostring(key):find("^" .. tostring(class) .. ":") then
                n = n + 1
                local f = {}
                for v in (tostring(line) .. "\t"):gmatch("([^\t]*)\t") do f[#f + 1] = v end
                if tonumber(f[1]) and tonumber(f[2]) then
                    pos = pos + 1
                    xs[f[1]] = true; ys[f[2]] = true
                end
                if f[3] and f[3] ~= "" then edges = edges + 1 end
                if f[4] and f[4] ~= "" then conds = conds + 1 end
            end
        end
        local function CountKeys(t) local c = 0 for _ in pairs(t) do c = c + 1 end return c end
        L[#L + 1] = ("nodes %d | with position %d (%d distinct x, %d distinct y) | with edges %d | with conditions %d%s")
            :format(n, pos, CountKeys(xs), CountKeys(ys), edges, conds, ok and "" or " | scan error")
        local gates = s and s.talentGates or {}
        for k, v in pairs(gates) do
            if tostring(k):find("^" .. tostring(class) .. ":") then L[#L + 1] = "gates " .. k .. " = " .. (v ~= "" and v or "(none)") end
        end
        local cn = 0
        for k, v in pairs((s and s.talentConds) or {}) do
            if tostring(k):find("^" .. tostring(class) .. ":") and cn < 8 then
                cn = cn + 1
                L[#L + 1] = "condition " .. k .. " spentRequired/isMet = " .. tostring(v):gsub("\t", " / ")
            end
        end
        Call(L, "C_Traits.GetTreeInfo present", function() return C_Traits and C_Traits.GetTreeInfo ~= nil end)
        Call(L, "C_Traits.GetConditionInfo present", function() return C_Traits and C_Traits.GetConditionInfo ~= nil end)
        Call(L, "C_Spell.GetSpellTexture present", function() return C_Spell and C_Spell.GetSpellTexture ~= nil end)
    end

    head("Spell ranks")
    -- The Spells tab's lower-rank-on-bar check needs a rank order. The first
    -- full report showed EVERY spell with an empty rank field (item.subName and
    -- C_Spell.GetSpellSubtext both blank, even Fireball 133/143/145), so this
    -- looks for where Forever keeps it instead. Up to 4 spell names with more
    -- than one ID in the harvest store; C_Spell answers by ID, so this works on
    -- any character.
    do
        local s = Store()
        local byName = {}
        for key, line in pairs((s and s.spells) or {}) do
            local id = tonumber(tostring(key):match(":(%d+)$"))
            local name = tostring(line):match("^([^\t]*)")
            if id and name and name ~= "" then
                byName[name] = byName[name] or {}
                local seen = false
                for _, v in ipairs(byName[name]) do if v == id then seen = true end end
                if not seen then table.insert(byName[name], id) end
            end
        end
        local names = {}
        for n, ids in pairs(byName) do if #ids > 1 then names[#names + 1] = n end end
        table.sort(names, function(a, b)
            if a == "Fireball" then return true elseif b == "Fireball" then return false end
            return a < b end)
        if #names == 0 then L[#L + 1] = "(no spell with more than one ID in the store yet)" end
        for i = 1, math.min(4, #names) do
            local ids = byName[names[i]]
            table.sort(ids)
            L[#L + 1] = names[i] .. "  ids " .. table.concat(ids, "/")
            for _, id in ipairs(ids) do
                L[#L + 1] = "  -- " .. id
                Call(L, "    C_Spell.GetSpellSubtext", NS(C_Spell, "GetSpellSubtext"), id)
                Call(L, "    C_Spell.GetSpellLevelLearned", NS(C_Spell, "GetSpellLevelLearned"), id)
                Call(L, "    GetSpellLevelLearned", _G.GetSpellLevelLearned, id)
                Call(L, "    C_Spell.GetSpellPowerCost", NS(C_Spell, "GetSpellPowerCost"), id)
                Call(L, "    C_Spell.GetSpellInfo", NS(C_Spell, "GetSpellInfo"), id)
                Call(L, "    C_Spell.GetSpellRank", NS(C_Spell, "GetSpellRank"), id)
                local tipFn = NS(C_TooltipInfo, "GetSpellByID")
                if type(tipFn) ~= "function" then
                    L[#L + 1] = "    C_TooltipInfo.GetSpellByID  ->  missing"
                else
                    local ok, data = pcall(tipFn, id)
                    if ok and type(data) == "table" and type(data.lines) == "table" then
                        for li = 1, math.min(4, #data.lines) do
                            local ln = data.lines[li]
                            L[#L + 1] = ("    tooltip[%d]  ->  %s  |  %s"):format(li,
                                Show(ln.leftText), Show(ln.rightText))
                        end
                    else
                        L[#L + 1] = "    C_TooltipInfo.GetSpellByID  ->  "
                            .. (ok and Show(data) or ("error: " .. tostring(data)))
                    end
                end
            end
        end
    end

    head("Combat")
    L[#L + 1] = "C_AssistedCombat  ->  " .. (type(C_AssistedCombat) == "table" and "present" or "missing")
    Call(L, "C_AssistedCombat.GetNextCastSpell()", NS(C_AssistedCombat, "GetNextCastSpell"))
    local rec = TA:GetModule("CombatRecorder")
    L[#L + 1] = "CombatRecorder  ->  " .. (rec and "running" or "not running")
    if rec and rec.HasOutput then L[#L + 1] = "  combat log readable  ->  " .. tostring(rec:HasOutput()) end
    local store = TA.charDB and TA.charDB.combatLog
    if store then
        local casts = 0
        for _, row in pairs(store.spells or {}) do casts = casts + (row.casts or 0) end
        L[#L + 1] = ("  fights %d, casts recorded %d"):format(store.fights or 0, casts)
    end

    head("Map")
    Call(L, "C_Map.GetBestMapForUnit(player)", NS(C_Map, "GetBestMapForUnit"), "player")

    head("Scroll tooltips in your bags")
    local found = 0
    local lastBag = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4
    for bag = 0, lastBag do
        local slots2 = TA.Utils.SafeNum(TA.Utils.GetContainerNumSlots(bag), 0)
        for slot = 1, slots2 do
            local link = TA.Utils.GetContainerItemLink(bag, slot)
            if link and not PROBE_SECRET(link) and link:lower():find("scroll", 1, true) and found < 5 then
                found = found + 1
                L[#L + 1] = link:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                local ok, data = pcall(NS(C_TooltipInfo, "GetHyperlink") or error, link)
                if ok and type(data) == "table" and type(data.lines) == "table" then
                    for i, ln in ipairs(data.lines) do
                        L[#L + 1] = ("  %d: %s"):format(i, Show(type(ln) == "table" and ln.leftText or nil))
                    end
                else
                    L[#L + 1] = "  C_TooltipInfo.GetHyperlink  ->  " .. (ok and "no lines" or "missing or error")
                end
            end
        end
    end
    if found == 0 then L[#L + 1] = "(no item with \"Scroll\" in its name in your bags)" end

    table.remove(L, 1)
    return L
end

function H:RunProbes()
    TA:ShowCopyWindow("ToonAge client probes", table.concat(self:BuildProbeLines(), "\n"))
end

H.SlashCommands = H.SlashCommands or {}
H.SlashCommands.probe = function(self) self:RunProbes() end

-- ── Export ────────────────────────────────────────────────────────────────
--
-- The fallback path. Reading the saved file off disk is better in every way
-- -- complete, no clicking, no page limit -- but it needs access to the WoW
-- folder, and this works from anywhere.

-- T3 (harvest spec): exports go through the shared core and its one
-- formatter, so every export -- this tab's buttons and
-- Tools/export_harvest.lua alike -- carries the same stamp header (client,
-- build, interface, project, channel, harvest range, export time, versions).

--- One page of a section as lines. page = 0 means every record, one block.
function H:ExportLines(section, page)
    local Hv = TA.Harvester
    if not Hv then return nil end
    return Hv:ExportLines(section or "items", page)
end

function H:Export(section, page)
    local Hv = TA.Harvester
    if not Hv then return end
    section = section or "items"
    local p, pages = Hv:Export(section, page)
    if not p then return end
    self._page, self._pages, self._section = p, pages, section
end

-- ── Spell catalog ─────────────────────────────────────────────────────────
--
-- The spellbook lists only spells you know (measured 2026-09-29: a level-1
-- Priest shows Smite and Lesser Heal, nothing else). But C_Spell answers for
-- ANY spell ID, known or not -- the probes read Fireball's rank text, trained
-- level and cost on a Warrior. So every trainable rank of every spell can be
-- read by walking spell IDs, with no leveling.
--
-- Kept: IDs whose rank text is "Rank N" AND whose trained level is > 0. That
-- is the client's own definition of a trainable ranked spell; NPC copies of a
-- spell ("Fireball" cast by a mob) report no trained level and drop out.
-- Unranked trainable spells (Sprint, Evasion) are kept too when they carry a
-- trained level, with blank rank text.
--
-- Ranges walked: 1-60000 (Vanilla IDs), 400000-440000 (the Season of Discovery
-- block Forever reuses: Penance 402174, Divine Aegis 431622), 1220000-1330000
-- (Forever's own: 1259xxx racials, 1293xxx, 1309950). Each frame spends at
-- most FRAME_BUDGET_MS so the game never stutters; the whole walk takes a few
-- seconds. Class is NOT known per spell -- the Spells tab matches by name
-- against your own spellbook, which is always right for your class.
--   catalog["spellID"] = name, rank text, trained level

local CATALOG_RANGES = { { 1, 60000 }, { 400000, 440000 }, { 1220000, 1330000 } }
local FRAME_BUDGET_MS = 8
local RANK_PASSES     = 3    -- extra passes over spells whose rank text was blank
local RANK_PASS_DELAY = 3    -- seconds between passes, for the client to load them

function H:ScanCatalog(onDone)
    local s = Store()
    if not s or self._catalogRunning then return end
    if not (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellLevelLearned) then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r Spell catalog: C_Spell.GetSpellName / "
            .. "GetSpellLevelLearned are missing on this client.")
        return
    end
    s.catalog = {}
    s.catalogPasses = {}
    self._catalogRunning = true
    local getName, getLearned = C_Spell.GetSpellName, C_Spell.GetSpellLevelLearned
    local getSub = C_Spell.GetSpellSubtext
    local range, id, found = 1, CATALOG_RANGES[1][1], 0
    local blanks = {}
    local requestLoad = C_Spell.RequestLoadSpellData
    local RetryBlanks, Finish
    local clock = debugprofilestop or function() return GetTime() * 1000 end

    local function Step()
        local t0 = clock()
        while range <= #CATALOG_RANGES do
            local last = CATALOG_RANGES[range][2]
            while id <= last do
                local okN, name = pcall(getName, id)
                if okN and type(name) == "string" and name ~= "" then
                    local okL, learned = pcall(getLearned, id)
                    if okL and type(learned) == "number" and learned > 0 then
                        local rank = getSub and select(2, pcall(getSub, id)) or ""
                        if type(rank) ~= "string" then rank = "" end
                        if rank == "" or rank:find("^Rank %d+$") then
                            s.catalog[tostring(id)] = table.concat(
                                { Clean(name), Clean(rank), Clean(learned) }, "\t")
                            found = found + 1
                            if rank == "" then
                                blanks[#blanks + 1] = id
                                if requestLoad then pcall(requestLoad, id) end
                            end
                        end
                    end
                end
                id = id + 1
                if (id % 500) == 0 and clock() - t0 > FRAME_BUDGET_MS then
                    C_Timer.After(0, Step)
                    return
                end
            end
            range = range + 1
            id = CATALOG_RANGES[range] and CATALOG_RANGES[range][1]
        end
        -- Pass 2+. Rank text loads asynchronously: the first scan of
        -- 2026-09-29 stored 9891 spells and only 77 had "Rank N" -- Fireball
        -- 8400 read "Rank 5" but 10148 (its rank 8) read "". Asking once
        -- starts the load, so blanks are asked again after a pause, up to
        -- RANK_PASSES times, stopping early when a pass resolves nothing.
        RetryBlanks(1)
    end

    function RetryBlanks(pass)
        if #blanks == 0 or pass > RANK_PASSES then return Finish() end
        C_Timer.After(RANK_PASS_DELAY, function()
            local i, still, resolved = 1, {}, 0
            local function Chunk()
                local t0 = clock()
                while i <= #blanks do
                    local bid = blanks[i]
                    local okR, rank = pcall(getSub, bid)
                    if okR and type(rank) == "string" and rank:find("^Rank %d+$") then
                        local line = s.catalog[tostring(bid)]
                        if line then
                            local nm, _, lv = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)")
                            s.catalog[tostring(bid)] = table.concat({ nm, rank, lv }, "\t")
                        end
                        resolved = resolved + 1
                    else
                        still[#still + 1] = bid
                    end
                    i = i + 1
                    if (i % 500) == 0 and clock() - t0 > FRAME_BUDGET_MS then
                        C_Timer.After(0, Chunk)
                        return
                    end
                end
                blanks = still
                -- Pass results go to the store (shown in the Full report), not
                -- to chat: chat gets the start line and the final count only.
                s.catalogPasses = s.catalogPasses or {}
                s.catalogPasses[#s.catalogPasses + 1] = ("pass %d: +%d ranks, %d still blank")
                    :format(pass + 1, resolved, #blanks)
                if resolved == 0 then return Finish() end
                RetryBlanks(pass + 1)
            end
            Chunk()
        end)
    end

    function Finish()
        self._catalogRunning = false
        Touch("catalog")
        s.catalogBuild = select(2, Try(GetBuildInfo))
        -- Whatever is still blank after the retry passes is dropped: the
        -- Spells tab only reads ranked entries, and the blanks are mostly NPC
        -- copies of player spells (Fireball 9053 "level 20", no rank). Keeping
        -- them cost ~400 KB of saved file and ~2 MB of memory for nothing.
        local ranked = 0
        for k, line in pairs(s.catalog) do
            if line:find("\tRank %d+\t") then ranked = ranked + 1 else s.catalog[k] = nil end
        end
        TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r Spell catalog: %d spells, %d with rank text."):format(found, ranked))
        if TA.Layout and TA.Layout.RefreshUI then TA.Layout:RefreshUI() end
        if onDone then onDone(found, ranked) end
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Spell catalog: scanning spell IDs (a few seconds)...")
    C_Timer.After(0, Step)
end

H.SlashCommands = H.SlashCommands or {}
H.SlashCommands.catalog = function(self) self:ScanCatalog() end

-- ── Run all ───────────────────────────────────────────────────────────────
--
-- One click: rescan everything this character can show right now, run every
-- probe, and put the probes plus every harvested record into ONE copy window.
-- The scans normally run on their own (login, level-up, bags, loot, spells,
-- talents); forcing them first means the report is current even if an event
-- was missed. Each scan is pcall'd so one failing read cannot stop the rest --
-- the report says which one failed.

local SECTIONS = { "items", "spells", "talents", "chars", "racials" }

function H:RunAll()
    local s = Store()
    if not s then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFF4444[ToonAge]|r Harvest store not available yet.")
        return
    end

    local before = {}
    for _, k in ipairs(SECTIONS) do before[k] = Count(s[k]) end

    local scans = {
        { "character",  "RecordCharacter" },
        { "equipped",   "ScanEquipped" },
        { "bags",       "ScanBags" },
        { "spellbook",  "ScanSpellbook" },
        { "talents",    "ScanTalents" },
        { "trait tree", "ScanTraitTree" },
    }
    -- The same stamp every export carries (client, build, interface, project,
    -- channel, harvest range, report time, versions).
    local stamp = (TA.HarvestFormat and TA.Harvester)
        and TA.HarvestFormat.Header(TA.Harvester:Meta(), "full report", 0, 1, 0, 0, 0) or {}
    local out = {
        "ToonAge Forever -- full report",
        stamp[2] or "",
        stamp[3] or "",
        "",
        "== Rescan ==",
    }
    for _, sc in ipairs(scans) do
        local fn = self[sc[2]]
        local ok, err = true, nil
        if type(fn) == "function" then ok, err = pcall(fn, self) end
        out[#out + 1] = ("%-11s %s"):format(sc[1],
            type(fn) ~= "function" and "not available"
            or ok and "ok" or ("FAILED: " .. tostring(err)))
    end
    local ranked = 0
    for _, line in pairs(s.catalog or {}) do
        if tostring(line):find("\tRank %d+\t") then ranked = ranked + 1 end
    end
    out[#out + 1] = ("%-11s %d spells, %d with rank text%s"):format("catalog", Count(s.catalog or {}), ranked,
        next(s.catalog or {}) and "" or " (not scanned yet: Harvest -> Scan spell catalog)")
    for _, p in ipairs(s.catalogPasses or {}) do out[#out + 1] = "            " .. p end
    for _, k in ipairs(SECTIONS) do
        local now = Count(s[k])
        out[#out + 1] = ("%-11s %d records (%s)"):format(k, now,
            now > before[k] and ("+" .. (now - before[k]) .. " new") or "no new")
    end

    out[#out + 1] = ""
    out[#out + 1] = "== Probes =="
    local okP, probe = pcall(self.BuildProbeLines, self)
    if okP and type(probe) == "table" then
        for _, l in ipairs(probe) do out[#out + 1] = l end
    else
        out[#out + 1] = "probes FAILED: " .. tostring(probe)
    end

    for _, k in ipairs(SECTIONS) do
        out[#out + 1] = ""
        out[#out + 1] = "== Harvest: " .. k .. " =="
        local lines = self:ExportLines(k, 0)
        for _, l in ipairs(lines or { "(unavailable)" }) do out[#out + 1] = l end
    end

    TA:ShowCopyWindow("ToonAge -- full report", table.concat(out, "\n"))
    local L = TA.Layout
    if L and L.RefreshUI then L:RefreshUI() end
end

H.SlashCommands.report = function(self) self:RunAll() end

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
    y = L:DataRow(content, y, { label = "Racials (race + faction)",    value = tostring(Count(s.racials or {})) })
    do
        local classes, rows = 0, 0
        for _, t in pairs(s.trainer or {}) do classes = classes + 1; rows = rows + Count(t) end
        y = L:DataRow(content, y, { label = "Trainer ranks (open a class trainer)",
            value = (rows > 0) and string.format("%d from %d class%s", rows, classes,
                classes == 1 and "" or "es") or "none yet" })
        if s.trainerApi then
            y = L:Paragraph(content, y, "Last trainer visit: " .. s.trainerApi, { color = L.C_DIM })
        end
    end
    y = L:DataRow(content, y, { label = "Spell catalog (every trainable rank)",
        value = H._catalogRunning and "scanning..." or tostring(Count(s.catalog or {})) })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Full report")
    y = L:Paragraph(content, y,
        "Rescans this character now (gear, bags, spellbook, talents), runs every "
        .. "client probe, and opens one copy window with the probes and every "
        .. "harvested record. Paste that one window -- nothing else needed. Also /ta report.")
    y = L:ButtonRow(content, y, {
        { label = "Full report", onClick = function() H:RunAll() end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Export")
    y = L:Paragraph(content, y,
        "The saved file is the better path and needs none of these buttons: it "
        .. "lives under WTF\\Account\\<your account>\\SavedVariables\\ToonAge.lua "
        .. "and is written when you log out or /reload. Use the buttons when "
        .. "that file cannot be reached.")

    -- One button per registered section (harvest core registry), in order.
    do
        local row = {}
        for _, e in ipairs((TA.Harvester and TA.Harvester:Exports()) or {}) do
            local section = e.section
            row[#row + 1] = { label = e.label, onClick = function() H:Export(section, 1) end }
        end
        y = L:ButtonRow(content, y, row, { label = "Copy:" })
    end

    if (self._pages or 1) > 1 then
        y = L:ButtonRow(content, y, {
            { label = "< Prev", onClick = function()
                H:Export(H._section, math.max(1, (H._page or 1) - 1)) end },
            { label = "Next >", onClick = function()
                H:Export(H._section, math.min(H._pages or 1, (H._page or 1) + 1)) end },
        }, { label = ("Page %d of %d:"):format(self._page or 1, self._pages or 1) })
    end

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "World refresh")
    y = L:Paragraph(content, y,
        "Every \"world around you will refresh\" notice the beta has shown, with "
        .. "time, zone and the gap between them. Also /ta refreshlog.")
    y = L:ButtonRow(content, y, {
        { label = "World refresh log", onClick = function() TA:SlashCommand("refreshlog") end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Spell catalog")
    y = L:Paragraph(content, y,
        "Reads every trainable spell rank straight from the client -- name, rank "
        .. "and the level it is trained -- including spells no character of yours "
        .. "knows yet. Run it once per client build; it takes a few seconds and the "
        .. "game stays responsive. Also /ta catalog.")
    y = L:ButtonRow(content, y, {
        { label = H._catalogRunning and "Scanning..." or "Scan spell catalog",
          onClick = function() H:ScanCatalog() end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Client probes")
    y = L:Paragraph(content, y,
        "Runs every open check from the Forever brief -- professions and "
        .. "Comprehension, weapon skill, spell power, combat recording, scroll "
        .. "tooltips -- and opens the results in a copyable window.")
    y = L:ButtonRow(content, y, {
        { label = "Run probes", onClick = function() H:RunProbes() end },
    })

    y = L:Divider(content, y)
    y = L:SectionHeader(content, y, "Dev tools",
        "For building ToonAge: API mapping and the quest-coordinate recorder.")
    y = L:ButtonRow(content, y, {
        { label = "Missing APIs", onClick = function() TA:SlashCommand("apiprobe") end },
        { label = "Coord stats",  onClick = function() TA:SlashCommand("coordstats") end },
        { label = "Coord export", onClick = function() TA:SlashCommand("coordexport") end },
        { label = H._confirmCoord and "Really clear?" or "Coord clear", onClick = function()
            if H._confirmCoord then
                H._confirmCoord = nil
                TA:SlashCommand("coordclear")
            else
                H._confirmCoord = true
            end
            if TA.Layout and TA.Layout.RefreshUI then TA.Layout:RefreshUI() end
        end },
    })

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
                if TA.Harvester then TA.Harvester:Clear() end
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

    -- The Copy row (harvest core registry). Trainer ranks and the spell
    -- catalog are two of the richest sections and had no button (R8).
    local Hv = TA.Harvester
    if Hv then
        Hv:RegisterExport("items",   "Items")
        Hv:RegisterExport("spells",  "Spells")
        Hv:RegisterExport("talents", "Talents")
        Hv:RegisterExport("chars",   "Characters")
        Hv:RegisterExport("racials", "Racials")
        Hv:RegisterExport("trainer", "Trainer ranks")
        Hv:RegisterExport("catalog", "Spell catalog")
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
    TA:RegisterEvent("TRAINER_SHOW")      -- absorbed if the client lacks it
    TA:RegisterEvent("TRAINER_UPDATE")

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r DataHarvester recording.")
    end
end
