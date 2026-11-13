-- ToonAge/Modules/Forever/StatPriority.lua
--
-- Lookup for the Forever stat-priority table in Data/Forever/StatPriority.lua.
-- Stage 2 can build weights on TA.StatPriority:Get(classFile, specKey).
-- This file does not call the client. Gear.lua asks Compat for the class
-- and the existing spec helper for the tree with the most points.

local TA = ToonAge

local M = {}
TA.StatPriority = M

-- Item stat keys the Gear tab already totals, mapped to the names in the
-- priority table. A key that is not here stays uncoloured.
local ITEM_KEY = {
    ITEM_MOD_STRENGTH_SHORT           = "Strength",
    ITEM_MOD_AGILITY_SHORT            = "Agility",
    ITEM_MOD_STAMINA_SHORT            = "Stamina",
    ITEM_MOD_INTELLECT_SHORT          = "Intellect",
    ITEM_MOD_SPIRIT_SHORT             = "Spirit",
    ITEM_MOD_ATTACK_POWER_SHORT       = "AttackPower",
    ITEM_MOD_CRIT_RATING_SHORT        = "Crit",
    ITEM_MOD_HIT_RATING_SHORT         = "Hit",
    ITEM_MOD_EXPERTISE_RATING_SHORT   = "Expertise",
    ITEM_MOD_HASTE_RATING_SHORT       = "Haste",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense",
    ITEM_MOD_DODGE_RATING_SHORT       = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT       = "Parry",
    ITEM_MOD_BLOCK_RATING_SHORT       = "Block",
    ITEM_MOD_BLOCK_VALUE_SHORT        = "BlockValue",
    ITEM_MOD_SPELL_POWER_SHORT        = "SpellPower",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT  = "SpellPower",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "HealingPower",
    ITEM_MOD_MANA_REGENERATION_SHORT  = "MP5",
    ITEM_MOD_POWER_REGEN0_SHORT       = "MP5",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT  = "WeaponDPS",
    RESISTANCE0_NAME                  = "Armor",
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT   = "FireDamage",
    ITEM_MOD_FROST_DAMAGE_DONE_SHORT  = "FrostDamage",
    ITEM_MOD_NATURE_DAMAGE_DONE_SHORT = "NatureDamage",
    ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = "ShadowDamage",
    ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT = "ArcaneDamage",
    ITEM_MOD_HOLY_DAMAGE_DONE_SHORT   = "HolyDamage",
}

local function Data()
    return TA.Data and TA.Data.ForeverStatPriority
end

--- @return table|nil entry { status, sources, useless, sameAs }
function M:Get(classFile, specKey)
    local data = Data()
    if not data or type(classFile) ~= "string" or type(specKey) ~= "string" then
        return nil
    end
    local class = data[classFile]
    if type(class) ~= "table" then return nil end
    local entry = class[specKey]
    if type(entry) ~= "table" then return nil end
    return entry
end

local function StepNames(step)
    if type(step) == "table" then return step end
    return { step }
end

local function ListHas(list, stat)
    for _, step in ipairs(list.stats or {}) do
        for _, name in ipairs(StepNames(step)) do
            if name == stat then return true end
        end
    end
    return false
end

local function SourceHas(source, stat)
    for _, list in ipairs(source.lists or {}) do
        if ListHas(list, stat) then return true end
    end
    return false
end

--- True when one of this source's lists ranks the stat in its first three.
local function SourceHigh(source, stat)
    for _, list in ipairs(source.lists or {}) do
        local n = 0
        for _, step in ipairs(list.stats or {}) do
            n = n + 1
            if n > 3 then break end
            for _, name in ipairs(StepNames(step)) do
                if name == stat then return true end
            end
        end
    end
    return false
end

local function IsUseless(entry, stat)
    for _, row in ipairs(entry.useless or {}) do
        if row.stat == stat then return true end
    end
    return false
end

--- One comparable guide row. Feral is two rows (Cat and Bear); every other
--- spec is a single row.
function M:Rows(entry)
    if type(entry) ~= "table" then return {} end
    if type(entry.rows) == "table" and #entry.rows > 0 then return entry.rows end
    return { entry }
end

local function RowTone(row, stat)
    local sources = row.sources or {}
    if #sources == 0 then return "low" end
    local listed, high = false, true
    for _, source in ipairs(sources) do
        if SourceHas(source, stat) then listed = true end
        if not SourceHigh(source, stat) then high = false end
    end
    -- Red only when a stored quote says the stat is useless and no order ranks it.
    if IsUseless(row, stat) and not listed then return "useless" end
    if high and listed then return "high" end
    return "low"
end

--- "high", "low", or "useless".
--- high: the stat is in the top three of both guides (every row, when a spec
--- has more than one, such as Cat and Bear).
--- low: everything else. Grey on the Gear tab.
--- useless: a source explicitly says so. This table has no such quote.
function M:Tone(classFile, specKey, stat)
    local entry = self:Get(classFile, specKey)
    if not entry or type(stat) ~= "string" then return nil end
    local sawUseless, allHigh = false, true
    for _, row in ipairs(self:Rows(entry)) do
        local tone = RowTone(row, stat)
        if tone == "useless" then sawUseless = true end
        if tone ~= "high" then allHigh = false end
    end
    if sawUseless then return "useless" end
    if allHigh then return "high" end
    return "low"
end

local VIEWS = { both = true, iv = true, wh = true }

--- "both", "iv", or "wh". Missing or unknown values stay on both.
function M:View()
    local v = TA.db and TA.db.foreverStatView
    if VIEWS[v] then return v end
    return "both"
end

function M:SetView(mode)
    if not VIEWS[mode] or type(TA.db) ~= "table" then return end
    TA.db.foreverStatView = mode
end

function M:SourceVisible(name)
    local view = self:View()
    if view == "iv" then return name == "Icy Veins" end
    if view == "wh" then return name == "Wowhead" end
    return true
end

-- Weight rule
-- Licence: ForeverLevelingBiS and MaxDps are All Rights Reserved.
-- These weights are not copied from either addon. They are computed only
-- from the stored orders in Data/Forever/StatPriority.lua.
--
-- One list: the first time a stat name appears, it takes the next rank.
-- A later repeat of that name (for example "Hit after 8%") does not open
-- a new rank and does not change the first weight. Names written in the
-- same step share that rank. Rank 1 weighs 1. With N ranks, rank r weighs
-- (N - r + 1) / N, so the last rank weighs 1/N.
--
-- A source with several lists keeps the highest weight each stat earns on
-- any of its own lists. That is not an average. Two sources are never
-- combined into one weight.
--
-- The stored table is level 60 only. No leveling order is stored, so none
-- is invented. Per-bracket leveling weights are UNVERIFIED and pending data.
-- Every weight from this table is the level 60 guide order.
--
-- A percent written in a guide line (hit 8%, 9%, 17%) is text. It is not
-- a cap in the score. The stored rows do not carry a separate number that
-- can be applied as a cap.

function M:OrderLabel()
    return "level 60 guide order"
end

function M:BracketNote()
    return "Per-bracket leveling weights are UNVERIFIED and pending data. "
        .. "The suggestion uses the stored level 60 guide order."
end

--- Rank weights for one stored list. Empty when the list has no stats.
function M:WeightsForList(list)
    local seen, ranks = {}, {}
    if type(list) ~= "table" then return {} end
    for _, step in ipairs(list.stats or {}) do
        local fresh = {}
        for _, name in ipairs(StepNames(step)) do
            if type(name) == "string" and name ~= "" and not seen[name] then
                seen[name] = true
                fresh[#fresh + 1] = name
            end
        end
        if #fresh > 0 then
            ranks[#ranks + 1] = fresh
        end
    end
    local n = #ranks
    local weights = {}
    if n == 0 then return weights end
    for i, group in ipairs(ranks) do
        local w = (n - i + 1) / n
        for _, name in ipairs(group) do
            weights[name] = w
        end
    end
    return weights
end

--- Highest per-list weight for this source. Lists are not averaged.
function M:WeightsForSource(source)
    local best = {}
    if type(source) ~= "table" then return best end
    for _, list in ipairs(source.lists or {}) do
        local weights = self:WeightsForList(list)
        for stat, weight in pairs(weights) do
            if best[stat] == nil or weight > best[stat] then
                best[stat] = weight
            end
        end
    end
    return best
end

--- Percent phrases from this source's own lines, in list order.
--- Shown as text. Not applied to a score.
function M:CapPhrases(source)
    local notes, seen = {}, {}
    if type(source) ~= "table" then return notes end
    for _, list in ipairs(source.lists or {}) do
        local line = type(list) == "table" and list.line or nil
        if type(line) == "string" then
            for part in line:gmatch("[^>]+") do
                if part:find("%", 1, true) then
                    local phrase = part:gsub("^%s+", ""):gsub("%s+$", "")
                    if phrase ~= "" and not seen[phrase] then
                        seen[phrase] = true
                        notes[#notes + 1] = phrase
                    end
                end
            end
        end
    end
    return notes
end

--- Sum of amount * weight. A key with no stored stat, or a stat with no
--- weight, adds 0. Caps are not applied here.
function M:ScoreStats(statTable, weights)
    local total = 0
    if type(statTable) ~= "table" or type(weights) ~= "table" then return 0 end
    for key, amount in pairs(statTable) do
        local stat = ITEM_KEY[key]
        local n = tonumber(amount)
        if stat and n and weights[stat] then
            total = total + (n * weights[stat])
        end
    end
    return total
end

--- Layout status. good is green, dim is grey, bad is red.
function M:BarStatus(tone)
    if tone == "high" then return "good" end
    if tone == "low" then return "dim" end
    if tone == "useless" then return "bad" end
    return nil
end

--- Same tone as Tone, for an item-stat key the Gear tab already reads.
--- sameAs lets a school-damage key follow spell power when the guide's own
--- line bundles them ("Spell Damage (+ Fire Damage)").
function M:ToneForItemKey(classFile, specKey, key)
    local stat = ITEM_KEY[key]
    if not stat then return nil end
    local tone = self:Tone(classFile, specKey, stat)
    if tone then return tone end
    local entry = self:Get(classFile, specKey)
    local parent = entry and entry.sameAs and entry.sameAs[stat]
    if parent then return self:Tone(classFile, specKey, parent) end
    return nil
end

return M
