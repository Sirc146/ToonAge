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
