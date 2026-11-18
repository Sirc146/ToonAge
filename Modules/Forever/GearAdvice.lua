-- ToonAge/Modules/Forever/GearAdvice.lua
--
-- Suggestions for equippable items on WoW Forever. Not a merged gear score.
--
-- Licence: ForeverLevelingBiS and MaxDps are All Rights Reserved.
-- This file does not copy their code, data, weights, strings or assets.
-- Weights come only from TA.StatPriority and Data/Forever/StatPriority.lua.
--
-- Each guide is scored from its own stored order. When the view is both,
-- both scores are shown and labeled. They are never averaged. The order
-- used here is the level 60 guide order: no leveling list is stored.
-- ToonAge does not print a percent. When Polestar or Forever Leveling BiS
-- is loaded, and otherwise when Pawn is loaded, one dim line names that
-- scorer and ToonAge adds nothing else. The check is C.IsAddOnLoaded only.
-- Their globals are not called. With neither loaded, or with the defer
-- setting off, the line is the stat trade in neutral text, then the stored
-- Icy Veins order labeled as the level 60 order. Below level 60 that order
-- is marked UNVERIFIED for leveling. No leveling order is stored or invented.
-- Cap text is still only for an item that carries Hit, and it is hidden
-- below level 60 because those phrases are the level 60 guide.
--
-- Addon folder names, read 18 Nov 2026 from the public release zips.
-- Only the top-level folder, the .toc name, and ## Title / dependency lines.
-- No code from those addons is copied here.
--   Pawn: folder Pawn, file Pawn.toc, ## Title: Pawn.
--     https://github.com/VgerMods/Pawn/releases/download/Pawn-2.14.4/Pawn-2.14.4-Forever.zip
--     (CurseForge project 4646, Forever file 2.14.4, 17 Nov 2026).
--   Polestar: folder Polestar, file Polestar.toc, ## Title: Polestar,
--     ## OptionalDeps includes ForeverLevelingBiS.
--     https://github.com/fitzforge/polestar/releases/download/v0.4.1.1/Polestar-0.4.1.1.zip
--     (18 Nov 2026).
--   Forever Leveling BiS: folder ForeverLevelingBiS,
--     file ForeverLevelingBiS.toc, ## Title: Forever Leveling BiS.
--     https://www.curseforge.com/wow/addons/forever-leveling-bis/files/9671768
--     zip ForeverLevelingBiS-v1.3.3-forever.zip (17 Nov 2026).
--
-- Tooltip lines are append-only. This file never clears the host tooltip
-- and never rewrites a host line. The hook matches Modules/Forever/Scrolls.lua:
-- TooltipDataProcessor when that global exists, otherwise OnTooltipSetItem.
-- AddonBridge is not in this branch.
--
-- Arrows are plain textures parented to bag, loot and quest buttons.
-- Secure attributes are not touched. In combat a protected frame is skipped.
-- A Blizzard frame or global that is missing on Forever is skipped.
-- Button names below are UNVERIFIED on client 1.60.1.

local TA = ToonAge

local M = {}
TA.GearAdvice = M

local GREEN = { 0.30, 0.92, 0.40 }
local GREY  = { 0.62, 0.59, 0.55 }
local RED   = { 1.00, 0.35, 0.30 }
-- Neutral is equal channels, never the upgrade green or the downgrade red.
local NEUTRAL = { 0.93, 0.93, 0.93 }

-- IsAddOnLoaded folder names verified above. Polestar wins over Pawn.
-- ForeverLevelingBiS is the gear addon Polestar names in OptionalDeps, and
-- its own title is "Forever Leveling BiS", so that load uses the same line.
local SCORER_POLESTAR = "Polestar"
local SCORER_FLBIS = "ForeverLevelingBiS"
local SCORER_PAWN = "Pawn"

-- Inventory slots for an equip location. Same ids as Modules/Forever/Gear.lua.
-- Shirt, tabard and bag slots are absent on purpose: they are not scored.
local EQUIP_SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}

local HOOKED_TOOLTIPS = { GameTooltip = true, ItemRefTooltip = true }

-- Nil or false means the suggestion is on. Settings stores an explicit false
-- only after the player turns it off.
function M:TooltipsOn()
    return not (TA.db and TA.db.foreverGearTooltip == false)
end

function M:ArrowsOn()
    return not (TA.db and TA.db.foreverGearArrows == false)
end

-- Nil or true means defer. Settings stores an explicit false only after
-- the player turns "Defer gear scoring to Polestar/Pawn" off.
function M:DeferOn()
    return not (TA.db and TA.db.foreverGearDefer == false)
end

--- "Polestar (Forever Leveling BiS)", "Pawn", or nil when ToonAge speaks.
function M:ScorerInCharge()
    if not self:DeferOn() then return nil end
    if self:AddonLoaded(SCORER_POLESTAR) or self:AddonLoaded(SCORER_FLBIS) then
        return "Polestar (Forever Leveling BiS)"
    end
    if self:AddonLoaded(SCORER_PAWN) then return "Pawn" end
    return nil
end

function M:PlayerLevel()
    local C = TA.Compat
    if not (C and type(C.UnitLevel) == "function") then return nil end
    local ok, level = pcall(C.UnitLevel, "player")
    if not ok or type(level) ~= "number" then return nil end
    return level
end

function M:BelowLevel60()
    local level = self:PlayerLevel()
    return type(level) == "number" and level < 60
end

function M:InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked and true or false
end

--- False for a protected frame while in combat, and for a value that is not a frame.
function M:FrameOk(btn)
    local kind = type(btn)
    if kind ~= "table" and kind ~= "userdata" then return false end
    if not self:InCombat() then return true end
    if type(btn.IsProtected) ~= "function" then return false end
    local ok, prot = pcall(btn.IsProtected, btn)
    if not ok or prot then return false end
    return true
end

local function BothApis(nsPath, globalPath)
    if not (TA.HasAPI) then return true end
    return TA:HasAPI(nsPath) or TA:HasAPI(globalPath)
end

function M:AddonLoaded(name)
    local C = TA.Compat
    if type(name) ~= "string" or name == "" then return false end
    if not (C and type(C.IsAddOnLoaded) == "function") then return false end
    if not BothApis("C_AddOns.IsAddOnLoaded", "IsAddOnLoaded") then return false end
    local ok, loaded = pcall(C.IsAddOnLoaded, name)
    return ok and loaded and true or false
end

function M:ReadItemStats(link)
    local C = TA.Compat
    if type(link) ~= "string" or link == "" then return nil end
    if not (C and type(C.GetItemStats) == "function") then return nil end
    if not BothApis("C_Item.GetItemStats", "GetItemStats") then return nil end
    local ok, stats = pcall(C.GetItemStats, link)
    if not ok or type(stats) ~= "table" then return nil end
    return stats
end

function M:EquipSlots(link)
    local C = TA.Compat
    if not (C and type(C.GetItemInfo) == "function") then return nil end
    if not BothApis("C_Item.GetItemInfo", "GetItemInfo") then return nil end
    local ok, _name, _link, _quality, _ilvl, _req, _itemType, _subType, _stack, equipLoc =
        pcall(C.GetItemInfo, link)
    if not ok or type(equipLoc) ~= "string" or equipLoc == "" then return nil end
    local slots = EQUIP_SLOTS[equipLoc]
    if type(slots) ~= "table" then return nil end
    return slots
end

function M:Equippable(link)
    local C = TA.Compat
    if C and type(C.IsEquippableItem) == "function"
        and BothApis("C_Item.IsEquippableItem", "IsEquippableItem") then
        local ok, value = pcall(C.IsEquippableItem, link)
        if ok and value == false then return false end
    end
    return self:EquipSlots(link) ~= nil
end

local function PlayerSpec()
    local classToken, specName
    if TA.Compat and type(TA.Compat.UnitClass) == "function" then
        if not (TA.HasAPI and not TA:HasAPI("UnitClass")) then
            local ok, _localized, token = pcall(TA.Compat.UnitClass, "player")
            if ok and type(token) == "string" and token ~= "" then classToken = token end
        end
    end
    if TA.Utils and type(TA.Utils.GetPlayerSpec) == "function" then
        local ok, _index, name = pcall(TA.Utils.GetPlayerSpec)
        if ok and type(name) == "string" and name ~= "" then specName = name end
    end
    return classToken, specName
end

function M:SlotScore(slot, weights)
    local C = TA.Compat
    local SP = TA.StatPriority
    if not (C and type(C.GetInventoryItemLink) == "function" and SP and SP.ScoreStats) then
        return nil, false
    end
    if TA.HasAPI and not TA:HasAPI("GetInventoryItemLink") then return nil, false end
    local ok, link = pcall(C.GetInventoryItemLink, "player", slot)
    if not ok then return nil, false end
    if type(link) ~= "string" or link == "" then return 0, true end
    local stats = self:ReadItemStats(link)
    if stats == nil then return nil, false end
    return SP:ScoreStats(stats, weights), false
end

--- Best (highest) rounded percent against the slots this item can fill.
--- Nil when none of those slots could be read.
function M:BestRounded(slots, weights, itemScore)
    local best, bestEmpty, any = nil, false, false
    for _, slot in ipairs(slots) do
        local score, empty = self:SlotScore(slot, weights)
        if score ~= nil then
            any = true
            local pct
            if score > 0 then
                pct = (itemScore - score) / score * 100
            elseif itemScore > 0 then
                pct = 100
            else
                pct = 0
            end
            local rounded = math.floor(pct + 0.5)
            if best == nil or rounded > best then
                best = rounded
                bestEmpty = empty and true or false
            end
        end
    end
    if not any then return nil, false end
    return best, bestEmpty
end

local function CapLine(srcName, phrases)
    if type(phrases) ~= "table" or #phrases == 0 then return nil end
    local text = "ToonAge: suggestion, " .. tostring(srcName or "Guide")
        .. " names these caps as text only (not in the score): "
        .. table.concat(phrases, "; ")
    if #text > 220 then text = text:sub(1, 217) .. "..." end
    return text
end

-- Tooltip Hit check only. This does not change StatPriority weights.
-- ITEM_MOD_HIT_RATING_SHORT is the key that map already uses.
-- Spell hit and the short Hit global count only when the client defines
-- them. The 1.60.1 key is UNVERIFIED pending an in-game
-- /dump C_Item.GetItemStats(link).
local function HitKeys()
    local keys = { ITEM_MOD_HIT_RATING_SHORT = true }
    local function add(globalName)
        local value = _G[globalName]
        if type(value) ~= "string" or value == "" then return end
        keys[globalName] = true
        keys[value] = true
    end
    add("ITEM_MOD_HIT_SPELL_RATING_SHORT")
    add("ITEM_MOD_HIT_SHORT")
    local rated = _G.ITEM_MOD_HIT_RATING_SHORT
    if type(rated) == "string" and rated ~= "" then keys[rated] = true end
    return keys
end

--- True when stats from C.GetItemStats include a key that counts as Hit.
local function ItemCarriesHit(stats)
    if type(stats) ~= "table" then return false end
    local keys = HitKeys()
    for key, amount in pairs(stats) do
        if keys[key] and tonumber(amount) ~= nil then
            return true
        end
    end
    return false
end

-- Same reading order as Modules/Forever/Gear.lua. Keys not listed sort after.
local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_HIT_RATING_SHORT",
    "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_HIT_SHORT",
    "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_POWER_REGEN0_SHORT",
    "RESISTANCE0_NAME", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT",
}

local STAT_FALLBACK = {
    ITEM_MOD_STRENGTH_SHORT = "Strength",
    ITEM_MOD_AGILITY_SHORT = "Agility",
    ITEM_MOD_STAMINA_SHORT = "Stamina",
    ITEM_MOD_INTELLECT_SHORT = "Intellect",
    ITEM_MOD_SPIRIT_SHORT = "Spirit",
    ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
    ITEM_MOD_SPELL_POWER_SHORT = "Spell Power",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Damage",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing Power",
    ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike",
    ITEM_MOD_HIT_RATING_SHORT = "Hit",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "Spell Hit",
    ITEM_MOD_HIT_SHORT = "Hit",
    ITEM_MOD_HASTE_RATING_SHORT = "Haste",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mana per 5s",
    ITEM_MOD_POWER_REGEN0_SHORT = "Mana per 5s",
    ITEM_MOD_MASTERY_SHORT = "Mastery",
    RESISTANCE0_NAME = "Armor",
}

local function StatName(key)
    local g = _G[key]
    if type(g) == "string" and g ~= "" and g ~= key and not g:find("%", 1, true) then
        return g
    end
    if STAT_FALLBACK[key] then return STAT_FALLBACK[key] end
    local t = tostring(key):gsub("^ITEM_MOD_", ""):gsub("_SHORT$", ""):gsub("_NAME$", "")
    t = t:gsub("_DONE$", ""):gsub("_RATING$", ""):gsub("_", " ")
    return (t:lower():gsub("(%a)(%w*)", function(a, b) return a:upper() .. b end))
end

local function Amount(stats, key)
    if type(stats) ~= "table" then return 0 end
    return tonumber(stats[key]) or 0
end

--- Hovered minus equipped. Only nonzero stats, signed, stable order.
local function TradeLine(itemStats, equippedStats)
    local seen, keys = {}, {}
    local function add(key)
        if type(key) ~= "string" or seen[key] then return end
        seen[key] = true
        keys[#keys + 1] = key
    end
    for _, key in ipairs(STAT_ORDER) do
        if Amount(itemStats, key) ~= 0 or Amount(equippedStats, key) ~= 0 then
            add(key)
        end
    end
    local rest = {}
    local function collect(stats)
        if type(stats) ~= "table" then return end
        for key in pairs(stats) do rest[#rest + 1] = key end
    end
    collect(itemStats)
    collect(equippedStats)
    table.sort(rest)
    for _, key in ipairs(rest) do
        if Amount(itemStats, key) ~= 0 or Amount(equippedStats, key) ~= 0 then
            add(key)
        end
    end
    local parts = {}
    for _, key in ipairs(keys) do
        local diff = Amount(itemStats, key) - Amount(equippedStats, key)
        if diff ~= 0 then
            local shown
            if diff == math.floor(diff) then
                shown = string.format("%d", diff)
            else
                shown = tostring(diff)
            end
            if diff > 0 then shown = "+" .. shown end
            parts[#parts + 1] = shown .. " " .. StatName(key)
        end
    end
    if #parts == 0 then return "ToonAge: same stats as equipped" end
    return "ToonAge: " .. table.concat(parts, ", ")
end

function M:CompareStats(slots)
    local C = TA.Compat
    if type(slots) ~= "table" then return {}, true end
    if not (C and type(C.GetInventoryItemLink) == "function") then return {}, true end
    if TA.HasAPI and not TA:HasAPI("GetInventoryItemLink") then return {}, true end
    for _, slot in ipairs(slots) do
        local ok, link = pcall(C.GetInventoryItemLink, "player", slot)
        if ok and type(link) == "string" and link ~= "" then
            local stats = self:ReadItemStats(link)
            if type(stats) == "table" then return stats, false end
        end
    end
    return {}, true
end

local GUIDE_WORDS = {
    Hit = "Hit", SpellPower = "Spell Power", Crit = "Critical Strike",
    Intellect = "Intellect", Spirit = "Spirit", MP5 = "Mana per 5",
    Stamina = "Stamina", Strength = "Strength", Agility = "Agility",
    Haste = "Haste", Expertise = "Expertise", AttackPower = "Attack Power",
    HealingPower = "Healing", Armor = "Armor", Defense = "Defense",
    Dodge = "Dodge", Parry = "Parry", Block = "Block", BlockValue = "Block Value",
    WeaponDPS = "Weapon DPS", WeaponDamage = "Weapon Damage",
    WeaponSkill = "Weapon Skill", SpellPierce = "Spell Penetration",
    FireDamage = "Fire Damage", FrostDamage = "Frost Damage",
    NatureDamage = "Nature Damage", ShadowDamage = "Shadow Damage",
    ArcaneDamage = "Arcane Damage", HolyDamage = "Holy Damage",
}

local function GuideWord(name)
    if GUIDE_WORDS[name] then return GUIDE_WORDS[name] end
    return (tostring(name):gsub("(%l)(%u)", "%1 %2"))
end

local function StepNames(step)
    if type(step) == "table" then return step end
    return { step }
end

--- Stored Icy Veins order for this spec. No percents. Nil when that source is absent.
function M:IcyVeinsLine(classToken, specName, below)
    local SP = TA.StatPriority
    if not (SP and SP.Get and SP.Rows) then return nil end
    local entry = SP:Get(classToken, specName)
    if type(entry) ~= "table" then return nil end
    local lines = {}
    for _, row in ipairs(SP:Rows(entry)) do
        local src
        for _, one in ipairs(row.sources or {}) do
            if type(one) == "table" and one.name == "Icy Veins" then src = one end
        end
        if src then
            local seen, parts = {}, {}
            for _, list in ipairs(src.lists or {}) do
                for _, step in ipairs(list.stats or {}) do
                    for _, name in ipairs(StepNames(step)) do
                        if type(name) == "string" and name ~= "" and not seen[name] then
                            seen[name] = true
                            parts[#parts + 1] = GuideWord(name)
                        end
                    end
                end
            end
            if #parts > 0 then
                local label = "ToonAge: Icy Veins order"
                if type(row.label) == "string" and row.label ~= "" then
                    label = label .. ", " .. row.label
                end
                label = label .. ", level 60 guide order"
                if below then label = label .. ", UNVERIFIED for leveling" end
                lines[#lines + 1] = label .. ": " .. table.concat(parts, " > ")
            end
        end
    end
    return lines
end

--- One result per visible source. No combined score.
function M:Suggestions(link)
    local out = {}
    if not self:Equippable(link) then return out end
    local SP = TA.StatPriority
    if not (SP and SP.Get and SP.WeightsForSource and SP.ScoreStats and SP.Rows and SP.SourceVisible and SP.OrderLabel) then
        return out
    end
    local classToken, specName = PlayerSpec()
    if not (classToken and specName) then return out end
    local entry = SP:Get(classToken, specName)
    if type(entry) ~= "table" then return out end
    local slots = self:EquipSlots(link)
    if not slots then return out end
    local itemStats = self:ReadItemStats(link)
    if itemStats == nil then return out end
    local equippedStats = self:CompareStats(slots)
    local trade = TradeLine(itemStats, equippedStats)
    local showCaps = ItemCarriesHit(itemStats) and not self:BelowLevel60()
    for _, row in ipairs(SP:Rows(entry)) do
        for _, src in ipairs(row.sources or {}) do
            if type(src) == "table" and SP:SourceVisible(src.name) then
                local weights = SP:WeightsForSource(src)
                local itemScore = SP:ScoreStats(itemStats, weights)
                local rounded = self:BestRounded(slots, weights, itemScore)
                if rounded ~= nil then
                    local verdict, r, g, b = "same", GREY[1], GREY[2], GREY[3]
                    if rounded > 0 then
                        verdict, r, g, b = "upgrade", GREEN[1], GREEN[2], GREEN[3]
                    elseif rounded < 0 then
                        verdict, r, g, b = "downgrade", RED[1], RED[2], RED[3]
                    end
                    local phrases = SP.CapPhrases and SP:CapPhrases(src) or {}
                    out[#out + 1] = {
                        name = src.name,
                        rowLabel = row.label,
                        rounded = rounded,
                        verdict = verdict,
                        text = trade,
                        cap = showCaps and CapLine(src.name, phrases) or nil,
                        r = r, g = g, b = b,
                    }
                end
            end
        end
    end
    return out
end

--- True only when every source the current view shows calls this an upgrade.
--- With both guides visible, one disagreeing source hides the arrow.
function M:IsUpgrade(link)
    local rows = self:Suggestions(link)
    if #rows == 0 then return false end
    for _, row in ipairs(rows) do
        if row.verdict ~= "upgrade" then return false end
    end
    return true
end

--- Lines ToonAge may print. A loaded scorer replaces every other line.
--- No percent is included. Colors are neutral for the trade and dim after that.
function M:DisplayLines(link)
    local lines = {}
    local who = self:ScorerInCharge()
    if who then
        lines[1] = {
            text = "ToonAge: " .. who .. " is scoring gear",
            r = GREY[1], g = GREY[2], b = GREY[3],
        }
        return lines
    end
    if not self:Equippable(link) then return lines end
    local itemStats = self:ReadItemStats(link)
    if itemStats == nil then return lines end
    local slots = self:EquipSlots(link)
    if not slots then return lines end
    local equippedStats = self:CompareStats(slots)
    lines[#lines + 1] = {
        text = TradeLine(itemStats, equippedStats),
        r = NEUTRAL[1], g = NEUTRAL[2], b = NEUTRAL[3],
    }
    local below = self:BelowLevel60()
    if not below then
        local seen = {}
        for _, row in ipairs(self:Suggestions(link)) do
            if row.cap and not seen[row.cap] then
                seen[row.cap] = true
                lines[#lines + 1] = {
                    text = row.cap, r = GREY[1], g = GREY[2], b = GREY[3],
                }
            end
        end
    end
    local classToken, specName = PlayerSpec()
    if classToken and specName then
        local orders = self:IcyVeinsLine(classToken, specName, below)
        for _, text in ipairs(orders or {}) do
            lines[#lines + 1] = { text = text, r = GREY[1], g = GREY[2], b = GREY[3] }
        end
    end
    return lines
end

--- Adds lines after the host tooltip. Does not clear or rewrite host lines.
function M:AppendSuggestions(tooltip, link)
    if not self:TooltipsOn() then return end
    local kind = type(tooltip)
    if kind ~= "table" and kind ~= "userdata" then return end
    if type(tooltip.AddLine) ~= "function" then return end
    for _, line in ipairs(self:DisplayLines(link)) do
        tooltip:AddLine(line.text, line.r, line.g, line.b, true)
    end
end

local function LinkFromTooltip(tooltip, data)
    if type(data) == "table" then
        if type(data.hyperlink) == "string" and data.hyperlink ~= "" then
            return data.hyperlink
        end
        if data.id ~= nil and TA.Compat and type(TA.Compat.GetItemInfo) == "function"
            and BothApis("C_Item.GetItemInfo", "GetItemInfo") then
            local ok, _name, itemLink = pcall(TA.Compat.GetItemInfo, data.id)
            if ok and type(itemLink) == "string" and itemLink ~= "" then return itemLink end
        end
    end
    if tooltip and type(tooltip.GetItem) == "function" then
        local ok, _name, itemLink = pcall(tooltip.GetItem, tooltip)
        if ok and type(itemLink) == "string" and itemLink ~= "" then return itemLink end
    end
    return nil
end

local function OnItemTooltip(tooltip, data)
    local tname = tooltip and tooltip.GetName and tooltip:GetName()
    if tname and not HOOKED_TOOLTIPS[tname] then return end
    local link = LinkFromTooltip(tooltip, data)
    if not link then return end
    M:AppendSuggestions(tooltip, link)
end

local function HookTooltips()
    if M._tipHooked then return end
    if type(TooltipDataProcessor) == "table"
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and type(Enum) == "table" and type(Enum.TooltipDataType) == "table"
        and Enum.TooltipDataType.Item ~= nil then
        local ok = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tooltip, data)
            pcall(OnItemTooltip, tooltip, data)
        end)
        if ok then
            M._tipHooked = "TooltipDataProcessor"
            return
        end
    end
    local tipKind = type(GameTooltip)
    if tipKind ~= "table" and tipKind ~= "userdata" then return end
    if type(GameTooltip.HookScript) ~= "function" then return end
    for tname in pairs(HOOKED_TOOLTIPS) do
        local tip = _G[tname]
        if tip and type(tip.HookScript) == "function" then
            pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self)
                pcall(OnItemTooltip, self, nil)
            end)
        end
    end
    M._tipHooked = "OnTooltipSetItem"
end

function M:EnsureArrow(btn)
    if btn._taGearArrow then return btn._taGearArrow end
    if not self:FrameOk(btn) then return nil end
    if type(btn.CreateTexture) ~= "function" then return nil end
    local ok, tex = pcall(btn.CreateTexture, btn, nil, "OVERLAY")
    if not ok or not tex then return nil end
    pcall(function()
        if tex.SetSize then tex:SetSize(12, 12) end
        if tex.SetPoint then tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -1, -1) end
        -- Blizzard file, not an asset from another addon. UNVERIFIED on Forever:
        -- a missing texture leaves the overlay blank.
        if tex.SetTexture then tex:SetTexture("Interface\\Buttons\\UI-MicroStream-Green") end
        if tex.SetVertexColor then tex:SetVertexColor(GREEN[1], GREEN[2], GREEN[3]) end
        if tex.Hide then tex:Hide() end
    end)
    btn._taGearArrow = tex
    return tex
end

function M:SetArrow(btn, on)
    if not self:FrameOk(btn) then return end
    local tex = btn._taGearArrow
    if on then
        tex = tex or self:EnsureArrow(btn)
        if tex and tex.Show then pcall(tex.Show, tex) end
    elseif tex and tex.Hide then
        pcall(tex.Hide, tex)
    end
end

function M:BagLink(bag, slot)
    local C = TA.Compat
    if type(bag) ~= "number" or type(slot) ~= "number" then return nil end
    if not (C and type(C.GetContainerItemLink) == "function") then return nil end
    if not BothApis("C_Container.GetContainerItemLink", "GetContainerItemLink") then return nil end
    local ok, link = pcall(C.GetContainerItemLink, bag, slot)
    if not ok or type(link) ~= "string" or link == "" then return nil end
    return link
end

function M:RefreshBags()
    if self:InCombat() then return end
    local nFrames = 13
    if type(_G.NUM_CONTAINER_FRAMES) == "number" and _G.NUM_CONTAINER_FRAMES > 0 then
        nFrames = _G.NUM_CONTAINER_FRAMES
    end
    local show = self:ArrowsOn()
    for i = 1, nFrames do
        local frame = _G["ContainerFrame" .. i]
        if frame and type(frame.GetName) == "function" and type(frame.GetID) == "function" then
            local okN, name = pcall(frame.GetName, frame)
            local okB, bag = pcall(frame.GetID, frame)
            if okN and okB and type(name) == "string" and type(bag) == "number" then
                local slots
                if TA.Compat and type(TA.Compat.GetContainerNumSlots) == "function"
                    and BothApis("C_Container.GetContainerNumSlots", "GetContainerNumSlots") then
                    local okS, n = pcall(TA.Compat.GetContainerNumSlots, bag)
                    if okS and type(n) == "number" then slots = n end
                end
                if slots and slots > 0 then
                    for slot = 1, slots do
                        local btn = _G[name .. "Item" .. slot]
                        if btn then
                            local link = show and self:BagLink(bag, slot) or nil
                            local mark = show and type(link) == "string" and self:IsUpgrade(link)
                            self:SetArrow(btn, mark and true or false)
                        end
                    end
                end
            end
        end
    end
end

function M:RefreshLoot()
    if self:InCombat() then return end
    if not _G.LootFrame then return end
    local C = TA.Compat
    if not (C and type(C.GetNumLootItems) == "function" and type(C.GetLootSlotLink) == "function") then
        return
    end
    local n = C.GetNumLootItems()
    if type(n) ~= "number" or n < 1 then return end
    if n > 20 then n = 20 end
    local show = self:ArrowsOn()
    for i = 1, n do
        local btn = _G["LootButton" .. i] or _G["LootFrameItem" .. i]
        if not btn and type(_G.LootFrame) == "table" then
            btn = _G.LootFrame["Item" .. i]
        end
        if btn then
            local link = show and C.GetLootSlotLink(i) or nil
            local mark = show and type(link) == "string" and self:IsUpgrade(link)
            self:SetArrow(btn, mark and true or false)
        end
    end
end

function M:ChoiceButton(index)
    local named = _G["QuestInfoRewardsFrameQuestInfoItem" .. index]
    if named then return named end
    local parent = _G.QuestInfoRewardsFrame
    if parent then
        local ok, btn = pcall(function() return parent["QuestInfoItem" .. index] end)
        if ok and btn then return btn end
    end
    return _G["QuestRewardItem" .. index]
end

function M:RewardButton(index)
    local parent = _G.QuestInfoRewardsFrame
    if parent then
        local ok, buttons = pcall(function() return parent.RewardButtons end)
        if ok and type(buttons) == "table" and buttons[index] then return buttons[index] end
    end
    return _G["QuestProgressItem" .. index]
end

function M:RefreshQuestKind(kind, countFn, buttonFn)
    local C = TA.Compat
    if not (C and type(countFn) == "function" and type(C.GetQuestItemLink) == "function") then
        return
    end
    local n = countFn()
    if type(n) ~= "number" or n < 1 then return end
    if n > 10 then n = 10 end
    local show = self:ArrowsOn()
    for i = 1, n do
        local btn = buttonFn(self, i)
        if btn then
            local link = show and C.GetQuestItemLink(kind, i) or nil
            local mark = show and type(link) == "string" and self:IsUpgrade(link)
            self:SetArrow(btn, mark and true or false)
        end
    end
end

function M:RefreshQuest()
    if self:InCombat() then return end
    local C = TA.Compat
    if not C then return end
    if type(C.GetNumQuestChoices) == "function" then
        self:RefreshQuestKind("choice", C.GetNumQuestChoices, self.ChoiceButton)
    end
    if type(C.GetNumQuestRewards) == "function" then
        self:RefreshQuestKind("reward", C.GetNumQuestRewards, self.RewardButton)
    end
end

function M:RefreshArrows()
    if self:InCombat() then
        self._arrowPending = true
        return
    end
    self._arrowPending = nil
    self:RefreshBags()
    self:RefreshLoot()
    self:RefreshQuest()
end

function M:OnGearEvent(event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:RefreshArrows()
        return
    end
    if self:InCombat() then
        self._arrowPending = true
        return
    end
    if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED"
        or event == "UNIT_INVENTORY_CHANGED" or event == "GET_ITEM_INFO_RECEIVED" then
        self:RefreshBags()
    elseif event == "LOOT_OPENED" or event == "LOOT_SLOT_CHANGED" then
        self:RefreshLoot()
    elseif event == "QUEST_COMPLETE" or event == "QUEST_ITEM_UPDATE" then
        self:RefreshQuest()
    end
end

local function HookNamed(name, method)
    if M._hooks and M._hooks[name] then return end
    if type(hooksecurefunc) ~= "function" then return end
    if type(_G[name]) ~= "function" then return end
    local ok = pcall(hooksecurefunc, name, function()
        pcall(method, M)
    end)
    if ok then
        M._hooks = M._hooks or {}
        M._hooks[name] = true
    end
end

local function HookFrames()
    -- Each name is skipped when this client does not define it.
    HookNamed("ContainerFrame_Update", M.RefreshBags)
    HookNamed("ContainerFrame_UpdateAll", M.RefreshBags)
    HookNamed("LootFrame_Update", M.RefreshLoot)
    HookNamed("QuestInfo_ShowRewards", M.RefreshQuest)
    HookNamed("QuestFrameItems_Update", M.RefreshQuest)
end

if TA.IsForever then
    HookTooltips()
    HookFrames()
end

return M
