-- ToonAge/Modules/Forever/MageSuggest.lua
--
-- Live spec-aware Combat Suggest HUD for WoW Forever (all 9 classes, with
-- verified Frost / Fire / Arcane Mage specializations and Playbook-backed
-- multi-class fallback). Drawn as a compact Liquid Glass capsule in its own
-- frame. The frame does not cast, does not sit on an action button, and does
-- not glow one.
--
-- Frost Mage priority is the Forever Frost leveling guide already cited by
-- MageGuidance.lua:
--   https://www.icy-veins.com/wow-forever/frost-mage-leveling
-- Read 2026-11-13 (page updated 2026-11-10). Spell ids are never invented here:
-- BuildSpells copies them from Data/Forever/SpellRanks.lua, Spells.lua,
-- Talents.lua (measured Ice Lance spell 1312002), TA_Rotations.forever, and
-- the player's own live spellbook.
-- Learned ranks use IsPlayerSpell and IsSpellKnown by spell id through
-- Compat.SpellLearned. Unknown is not "unlearned".
--
-- A secret or nil cooldown, mana value, or aura list makes that rule
-- unknown. The other rules still run. issecretvalue and canaccessvalue are
-- both consulted when the client has them, before any arithmetic.

local TA = ToonAge

local M = {}
TA:RegisterModule("ForeverMageSuggest", M)

local UPDATE_INTERVAL = 0.15
-- The guide says to use the wand when mana is the problem. It does not
-- give a fraction. MageGuidance.lua records that an older example percent
-- is not a cutoff. This is only where the suggestion switches to Shoot.
local WAND_MANA_FRACTION = 0.20
-- A shorter return is the global cooldown, so the icon does not go blank
-- between casts. A longer return is the spell's own cooldown.
local GCD_SECONDS = 1.5
-- The guide: Cone of Cold when Winter's Chill reaches 5 stacks.
local WINTERS_CHILL_STACKS = 5

local WANTED = {
    ["Frostbolt"] = "frostbolt",
    ["Fire Blast"] = "fireBlast",
    ["Frost Nova"] = "frostNova",
    ["Cone of Cold"] = "cone",
    ["Shoot"] = "shoot",
    ["Frost Armor"] = "frostArmor",
    ["Ice Armor"] = "iceArmor",
    ["Mage Armor"] = "mageArmor",
    ["Arcane Intellect"] = "intellect",
    ["Arcane Brilliance"] = "arcaneBrilliance",
    ["Ice Lance"] = "iceLance",
    ["Fireball"] = "fireball",
    ["Scorch"] = "scorch",
    ["Arcane Missiles"] = "arcaneMissiles",
    ["Arcane Explosion"] = "arcaneExplosion",
    ["Flamestrike"] = "flamestrike",
    ["Blizzard"] = "blizzard",
    ["Arcane Blast"] = "arcaneBlast",
    ["Pyroblast"] = "pyroblast",
    ["Combustion"] = "combustion",
    ["Presence of Mind"] = "presenceOfMind",
    ["Arcane Power"] = "arcanePower",
    ["Ice Barrier"] = "iceBarrier",
}

local FROZEN = { ["Frostbite"] = true, ["Frost Nova"] = true, ["Freeze"] = true }

local FALLBACK_BUFF_GROUPS = {
    MAGE = {
        { label = "Armor",     spells = { "Ice Armor", "Mage Armor", "Frost Armor" } },
        { label = "Intellect", spells = { "Arcane Brilliance", "Arcane Intellect" } },
    },
    PRIEST = {
        { label = "Fortitude",  spells = { "Prayer of Fortitude", "Power Word: Fortitude" } },
        { label = "Inner Fire", spells = { "Inner Fire" } },
    },
    DRUID = {
        { label = "Mark",   spells = { "Gift of the Wild", "Mark of the Wild" } },
        { label = "Thorns", spells = { "Thorns" } },
    },
    WARLOCK = {
        { label = "Armor", spells = { "Demon Armor", "Demon Skin" } },
    },
    WARRIOR = {
        { label = "Shout", spells = { "Battle Shout" } },
    },
    PALADIN = {
        { label = "Aura",     spells = { "Devotion Aura", "Retribution Aura", "Sanctity Aura", "Concentration Aura" } },
        { label = "Blessing", spells = { "Blessing of Kings", "Blessing of Might", "Blessing of Wisdom" } },
    },
    SHAMAN = {
        { label = "Shield", spells = { "Lightning Shield" } },
    },
    HUNTER = {
        { label = "Aspect", spells = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Cheetah" } },
    },
}

local WAND_CLASSES = {
    MAGE = true,
    PRIEST = true,
    WARLOCK = true,
}

M._blocked = 0
M._forbidden = 0

function M.ValueKnown(value)
    if value == nil then return false end
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret == true then return false end
    end
    if type(canaccessvalue) == "function" then
        local ok, access = pcall(canaccessvalue, value)
        if not ok or access ~= true then return false end
    end
    return true
end

function M.ManaState(current, maxValue)
    if not M.ValueKnown(current) or not M.ValueKnown(maxValue) then return "unknown" end
    if type(current) ~= "number" or type(maxValue) ~= "number" then return "unknown" end
    if current ~= current or maxValue ~= maxValue then return "unknown" end
    if maxValue <= 0 then return "unknown" end
    if current / maxValue <= WAND_MANA_FRACTION then return "low" end
    return "ok"
end

function M.CooldownState(start, duration)
    if not M.ValueKnown(start) or not M.ValueKnown(duration) then return "unknown" end
    if type(start) ~= "number" or type(duration) ~= "number" then return "unknown" end
    if start ~= start or duration ~= duration then return "unknown" end
    if duration <= 0 then return "ready" end
    if duration <= GCD_SECONDS then return "ready" end
    return "down"
end

function M.MeleeState(dist)
    if not M.ValueKnown(dist) then return nil end
    if dist == true or dist == 1 then return true end
    if dist == false or dist == 0 then return false end
    return nil
end

local function AddSpell(bucket, name, spellID, learned)
    local key = WANTED[name]
    if not key or type(spellID) ~= "number" then return end
    local row = bucket[key]
    if not row then
        row = { name = name, ids = {}, learned = {} }
        bucket[key] = row
    end
    for _, have in ipairs(row.ids) do
        if have == spellID then return end
    end
    row.ids[#row.ids + 1] = spellID
    row.learned[spellID] = type(learned) == "number" and learned or 0
end

function M.BuildSpells(ranks, mageSpells, talents, liveByName)
    local bucket = {}
    if type(ranks) == "table" then
        for name, chain in pairs(ranks) do
            if type(chain) == "table" then
                for _, rank in ipairs(chain) do
                    if type(rank) == "table" then
                        AddSpell(bucket, name, rank.id, rank.learned or rank.n)
                    end
                end
            end
        end
    end
    if type(mageSpells) == "table" then
        for _, row in ipairs(mageSpells) do
            if type(row) == "table" then
                AddSpell(bucket, row.name, row.id, row.learned)
            end
        end
    end
    if type(talents) == "table" then
        for _, row in ipairs(talents) do
            if type(row) == "table" and type(row.name) == "string" and WANTED[row.name] then
                AddSpell(bucket, row.name, row.spell, row.learned or 20)
            end
        end
    end
    if type(liveByName) == "table" then
        for name, ids in pairs(liveByName) do
            if WANTED[name] and type(ids) == "table" then
                for idx, sid in ipairs(ids) do
                    AddSpell(bucket, name, sid, idx)
                end
            end
        end
    end
    for _, row in pairs(bucket) do
        table.sort(row.ids, function(a, b)
            local la = row.learned[a] or 0
            local lb = row.learned[b] or 0
            if la == lb then return a < b end
            return la < lb
        end)
    end
    return bucket
end

function M.IndexAuras(list)
    if type(list) ~= "table" then return nil end
    local map = {}
    for _, row in ipairs(list) do
        if type(row) == "table" and type(row.name) == "string" then
            if type(row.applications) == "number" then
                map[row.name] = row.applications
            else
                map[row.name] = true
            end
        end
    end
    return map
end

local function Up(map, name)
    if type(map) ~= "table" then return false end
    local value = map[name]
    if value == true then return true end
    if type(value) == "number" and value > 0 then return true end
    return false
end

local function PickReady(state, spells, key, why, meta)
    local spell = spells and spells[key]
    if not spell then return nil end
    local known = state.known or {}
    local cooldown = state.cooldown or {}
    for i = #spell.ids, 1, -1 do
        local spellID = spell.ids[i]
        if known[spellID] == "yes" and cooldown[spellID] == "ready" then
            return {
                spellID = spellID,
                name = spell.name,
                why = why,
                spec = meta and meta.spec or state.spec,
                mode = meta and meta.mode or state.mode or "st",
                unverified = meta and meta.unverified or false,
            }
        end
    end
    return nil
end

local function PickReadyIDs(state, ids, name, why, meta)
    if type(ids) ~= "table" then return nil end
    local known = state.known or {}
    local cooldown = state.cooldown or {}
    for i = #ids, 1, -1 do
        local spellID = ids[i]
        if known[spellID] == "yes" and cooldown[spellID] == "ready" then
            return {
                spellID = spellID,
                name = name,
                why = why,
                spec = meta and meta.spec or state.spec,
                mode = meta and meta.mode or state.mode or "st",
                unverified = meta and meta.unverified or false,
            }
        end
    end
    return nil
end

local function SuggestMageBuffs(state, spells, preferMageArmor, meta)
    if type(state.buffs) ~= "table" then return nil end
    local armorUp = Up(state.buffs, "Frost Armor") or Up(state.buffs, "Ice Armor")
        or Up(state.buffs, "Mage Armor")
    if not armorUp then
        if preferMageArmor then
            local mage = PickReady(state, spells, "mageArmor",
                "Suggestion: keep Mage Armor up for mana regeneration.", meta)
            if mage then return mage end
        end
        local ice = PickReady(state, spells, "iceArmor",
            "Suggestion: keep Ice Armor up while leveling.", meta)
        if ice then return ice end
        local frost = PickReady(state, spells, "frostArmor",
            "Suggestion: keep Frost Armor up while leveling.", meta)
        if frost then return frost end
    end
    if not Up(state.buffs, "Arcane Intellect") and not Up(state.buffs, "Arcane Brilliance") then
        local intellect = PickReady(state, spells, "intellect",
            "Suggestion: keep Arcane Intellect up.", meta)
        if intellect then return intellect end
    end
    return nil
end

local function SuggestMageAoE(state, spells, spec)
    local meta = { spec = spec or "Frost", mode = "aoe", unverified = false }
    if state.mana == "low" then
        return PickReady(state, spells, "shoot",
            "Suggestion: use the wand when mana is low.", meta)
    end
    local buff = SuggestMageBuffs(state, spells, spec == "Arcane", meta)
    if buff then return buff end

    if state.melee == true then
        local nova = PickReady(state, spells, "frostNova",
            "Suggestion: Frost Nova to root the pack before AoE.", meta)
        if nova then return nova end
        if spec == "Frost" then
            local cone = PickReady(state, spells, "cone",
                "Suggestion: Cone of Cold while enemies are stacked in melee.", meta)
            if cone then return cone end
        end
        local ae = PickReady(state, spells, "arcaneExplosion",
            "Suggestion: Arcane Explosion on packs in melee range.", meta)
        if ae then return ae end
    end

    if spec == "Fire" then
        local fs = PickReady(state, spells, "flamestrike",
            "Suggestion: Flamestrike on stacked packs.", meta)
        if fs then return fs end
        local ae = PickReady(state, spells, "arcaneExplosion",
            "Suggestion: Arcane Explosion while moving through melee packs.", meta)
        if ae then return ae end
    elseif spec == "Arcane" then
        local ae = PickReady(state, spells, "arcaneExplosion",
            "Suggestion: Arcane Explosion on packs in melee range.", meta)
        if ae then return ae end
        local bliz = PickReady(state, spells, "blizzard",
            "Suggestion: Blizzard for ranged AoE.", meta)
        if bliz then return bliz end
        local fs = PickReady(state, spells, "flamestrike",
            "Suggestion: Flamestrike on stacked packs.", meta)
        if fs then return fs end
    else
        local bliz = PickReady(state, spells, "blizzard",
            "Suggestion: Blizzard for ranged AoE grinding.", meta)
        if bliz then return bliz end
        local cone = PickReady(state, spells, "cone",
            "Suggestion: Cone of Cold when enemies close in.", meta)
        if cone then return cone end
        local ae = PickReady(state, spells, "arcaneExplosion",
            "Suggestion: Arcane Explosion on packs in melee range.", meta)
        if ae then return ae end
    end
    return PickReady(state, spells, "frostbolt",
        "Suggestion: Frostbolt when AoE spells are not available.", meta)
        or PickReady(state, spells, "fireball",
            "Suggestion: Fireball when AoE spells are not available.", meta)
end

local function SuggestMageFire(state, spells)
    local meta = { spec = "Fire", mode = "st", unverified = true }
    if state.mana == "low" then
        return PickReady(state, spells, "shoot",
            "Suggestion: use the wand when mana is low.", meta)
    end
    local buff = SuggestMageBuffs(state, spells, false, meta)
    if buff then return buff end

    if state.melee == true then
        local nova = PickReady(state, spells, "frostNova",
            "Suggestion: Frost Nova when an enemy is in melee, then step back.", meta)
        if nova then return nova end
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast is the instant while Frost Nova is not ready.", meta)
        if blast then return blast end
    end

    local comb = PickReady(state, spells, "combustion",
        "Suggestion: Combustion on elites or tough pulls.", meta)
    if comb then return comb end

    local blast = PickReady(state, spells, "fireBlast",
        "Suggestion: Fire Blast on cooldown or to finish.", meta)
    if blast then return blast end

    local fball = PickReady(state, spells, "fireball",
        "Suggestion: Fireball is the primary Fire nuke.", meta)
    if fball then return fball end

    local scorch = PickReady(state, spells, "scorch",
        "Suggestion: Scorch as a fast Fire cast.", meta)
    if scorch then return scorch end

    return PickReady(state, spells, "frostbolt",
        "Suggestion: Frostbolt while Fire spells are unavailable.", meta)
end

local function SuggestMageArcane(state, spells)
    local meta = { spec = "Arcane", mode = "st", unverified = true }
    if state.mana == "low" then
        return PickReady(state, spells, "shoot",
            "Suggestion: use the wand when mana is low.", meta)
    end
    local buff = SuggestMageBuffs(state, spells, true, meta)
    if buff then return buff end

    if state.melee == true then
        local nova = PickReady(state, spells, "frostNova",
            "Suggestion: Frost Nova when an enemy is in melee, then step back.", meta)
        if nova then return nova end
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast is the instant while Frost Nova is not ready.", meta)
        if blast then return blast end
    end

    if Up(state.buffs, "Clearcasting") then
        local am = PickReady(state, spells, "arcaneMissiles",
            "Suggestion: Arcane Missiles while Clearcasting is active.", meta)
        if am then return am end
    end

    local ap = PickReady(state, spells, "arcanePower",
        "Suggestion: Arcane Power for burst windows.", meta)
    if ap then return ap end

    local pom = PickReady(state, spells, "presenceOfMind",
        "Suggestion: Presence of Mind for an instant cast.", meta)
    if pom then return pom end

    local ab = PickReady(state, spells, "arcaneBlast",
        "Suggestion: Arcane Blast as your primary Arcane cast.", meta)
    if ab then return ab end

    local am = PickReady(state, spells, "arcaneMissiles",
        "Suggestion: Arcane Missiles as Arcane filler.", meta)
    if am then return am end

    local bolt = PickReady(state, spells, "frostbolt",
        "Suggestion: Frostbolt when Arcane casts are unavailable.", meta)
    if bolt then return bolt end

    return PickReady(state, spells, "fireball",
        "Suggestion: Fireball when Arcane casts are unavailable.", meta)
        or PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast as an instant fallback.", meta)
end

-- Generalized multi-class suggestion engine powered by TA_Rotations.forever
-- and live spellbook / buff checks. Honest about unverified reference guides.
function M.SuggestForClass(state, playbook)
    if type(state) ~= "table" or type(playbook) ~= "table" then return nil end
    local meta = {
        spec = playbook.spec or state.spec,
        mode = playbook.mode or state.mode or "st",
        unverified = playbook.verified ~= true,
    }

    if state.mana == "low" and WAND_CLASSES[state.class] and type(playbook.shootIDs) == "table" then
        local wand = PickReadyIDs(state, playbook.shootIDs, "Shoot",
            "Suggestion: use your wand while mana is low.", meta)
        if wand then return wand end
    end

    if type(state.buffs) == "table" and type(playbook.buffGroups) == "table" then
        for _, grp in ipairs(playbook.buffGroups) do
            local isUp = false
            for _, sp in ipairs(grp.spells or {}) do
                if Up(state.buffs, sp.name) then
                    isUp = true
                    break
                end
            end
            if not isUp then
                for _, sp in ipairs(grp.spells or {}) do
                    local pick = PickReadyIDs(state, sp.ids, sp.name,
                        "Suggestion: keep " .. tostring(sp.name) .. " active.", meta)
                    if pick then return pick end
                end
            end
        end
    end

    for _, entry in ipairs(playbook.entries or {}) do
        local cond = type(entry.cond) == "string" and entry.cond ~= ""
            and (" (" .. entry.cond .. ")") or ""
        local entryMeta = {
            spec = meta.spec,
            mode = meta.mode,
            unverified = (entry.verified ~= true) or meta.unverified,
        }
        local pick = PickReadyIDs(state, entry.ids, entry.name,
            "Suggestion: " .. tostring(entry.name) .. cond .. ".", entryMeta)
        if pick then return pick end
    end
    return nil
end

-- One suggestion, or nil when every applicable rule is unknown or unusable.
-- state.mana is "low", "ok", or "unknown". state.melee is true, false, or nil.
-- state.buffs / state.debuffs nil means that aura read was skipped.
function M.Suggest(state, spells)
    if type(state) ~= "table" then return nil end

    if state.class ~= "MAGE" then
        if type(state.playbook) == "table" then
            return M.SuggestForClass(state, state.playbook)
        end
        return nil
    end

    spells = spells or {}
    local mode = state.mode or "st"
    local spec = state.spec

    if mode == "aoe" then
        return SuggestMageAoE(state, spells, spec)
    end
    if spec == "Fire" then
        return SuggestMageFire(state, spells)
    end
    if spec == "Arcane" then
        return SuggestMageArcane(state, spells)
    end

    -- Default / Frost Mage (verified Forever Frost leveling guide).
    if state.mana == "low" then
        -- Guide: Shoot from a wand when mana is the problem, including to
        -- finish so the five-second regen rule can start.
        return PickReady(state, spells, "shoot",
            "Suggestion: use the wand when mana is low.")
    end

    local buff = SuggestMageBuffs(state, spells, false)
    if buff then return buff end

    local lanceWhy
    if Up(state.buffs, "Fingers of Frost") then
        lanceWhy = "Suggestion: Ice Lance while Fingers of Frost is up."
    elseif type(state.debuffs) == "table" then
        for name in pairs(FROZEN) do
            if Up(state.debuffs, name) then
                lanceWhy = "Suggestion: Ice Lance while the enemy is frozen."
                break
            end
        end
    end
    if lanceWhy then
        local lance = PickReady(state, spells, "iceLance", lanceWhy)
        if lance then return lance end
    end

    if state.melee == true then
        -- Guide: Frost Nova when they get too close, then step back.
        local nova = PickReady(state, spells, "frostNova",
            "Suggestion: Frost Nova when an enemy is in melee, then step back.")
        if nova then return nova end
    end

    if type(state.debuffs) == "table" then
        local stacks = state.debuffs["Winter's Chill"]
        if type(stacks) == "number" and stacks >= WINTERS_CHILL_STACKS then
            local cone = PickReady(state, spells, "cone",
                "Suggestion: Cone of Cold when Winter's Chill is at five stacks.")
            if cone then return cone end
        end
    end

    if state.melee == true then
        -- Guide: Fire Blast finishes a low-health enemy that is not frozen,
        -- and it is the instant while you are still in melee and Nova is down.
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast is the instant while Frost Nova is not ready.")
        if blast then return blast end
    end

    local bolt = PickReady(state, spells, "frostbolt",
        "Suggestion: Frostbolt is the cast to repeat at range.")
    if bolt then return bolt end

    if state.melee ~= true then
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast when Frostbolt is not available.")
        if blast then return blast end
    end
    return nil
end

local function AppendUnique(list, id)
    if type(id) ~= "number" then return end
    for _, existing in ipairs(list) do
        if existing == id then return end
    end
    list[#list + 1] = id
end

--- Scan the player's live spellbook via manifest-verified C_SpellBook APIs.
--- Returns byName[spellName] = { id1, id2, ... } sorted ascending.
function M.ScanLiveSpellbook()
    if M._liveByName then return M._liveByName end
    local byName = {}
    if not (C_SpellBook and type(C_SpellBook.GetNumSpellBookSkillLines) == "function"
        and type(C_SpellBook.GetSpellBookSkillLineInfo) == "function"
        and type(C_SpellBook.GetSpellBookItemInfo) == "function") then
        M._liveByName = byName
        return byName
    end
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
    local okN, numLines = pcall(C_SpellBook.GetNumSpellBookSkillLines)
    if not okN or not M.ValueKnown(numLines) or type(numLines) ~= "number" then
        M._liveByName = byName
        return byName
    end
    for i = 1, numLines do
        local okL, line = pcall(C_SpellBook.GetSpellBookSkillLineInfo, i)
        if okL and type(line) == "table" and M.ValueKnown(line.itemIndexOffset) and M.ValueKnown(line.numSpellBookItems) then
            local offset = tonumber(line.itemIndexOffset) or 0
            local count = tonumber(line.numSpellBookItems) or 0
            for slot = offset + 1, offset + count do
                local okI, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, bank)
                if okI and type(info) == "table" and not info.isPassive then
                    local sid = info.spellID or info.actionID
                    local name = info.name
                    if (type(name) ~= "string" or name == "") and type(sid) == "number"
                        and C_Spell and type(C_Spell.GetSpellInfo) == "function" then
                        local okS, sinfo = pcall(C_Spell.GetSpellInfo, sid)
                        if okS and type(sinfo) == "table" then name = sinfo.name end
                    end
                    if M.ValueKnown(sid) and type(sid) == "number"
                        and M.ValueKnown(name) and type(name) == "string" and name ~= "" then
                        byName[name] = byName[name] or {}
                        AppendUnique(byName[name], sid)
                    end
                end
            end
        end
    end
    for _, ids in pairs(byName) do
        table.sort(ids)
    end
    M._liveByName = byName
    return byName
end

--- Build a Playbook-backed class catalog for any Forever class + spec + level.
function M.BuildClassPlaybook(classToken, specName, level, mode, liveByName, rotationsRoot, dataRoot)
    if type(classToken) ~= "string" or classToken == "" then return nil end
    local root = rotationsRoot or (_G.TA_Rotations and _G.TA_Rotations.forever)
    local cls = type(root) == "table" and root[classToken] or nil
    local live = type(liveByName) == "table" and liveByName or {}
    local data = dataRoot or TA.Data or {}
    local ranks = data.ForeverSpellRanks or {}
    local classSpells = data.ForeverSpells and data.ForeverSpells[classToken] or nil

    local catalogByName = {}
    if type(ranks) == "table" then
        for name, chain in pairs(ranks) do
            if type(chain) == "table" then
                catalogByName[name] = catalogByName[name] or {}
                for _, r in ipairs(chain) do
                    if type(r) == "table" then AppendUnique(catalogByName[name], r.id) end
                end
            end
        end
    end
    if type(classSpells) == "table" then
        for _, row in ipairs(classSpells) do
            if type(row) == "table" and type(row.name) == "string" then
                catalogByName[row.name] = catalogByName[row.name] or {}
                AppendUnique(catalogByName[row.name], row.id)
            end
        end
    end

    local function CollectIDs(name, fallbackIDs, singleID)
        local ids = {}
        if type(fallbackIDs) == "table" then
            for _, id in ipairs(fallbackIDs) do AppendUnique(ids, id) end
        end
        if type(singleID) == "number" then AppendUnique(ids, singleID) end
        if type(catalogByName[name]) == "table" then
            for _, id in ipairs(catalogByName[name]) do AppendUnique(ids, id) end
        end
        if type(live[name]) == "table" then
            for _, id in ipairs(live[name]) do AppendUnique(ids, id) end
        end
        return ids
    end

    local pickedSpec = nil
    local band = nil
    local specVerified = false
    if type(cls) == "table" then
        local specs = {}
        for k, v in pairs(cls) do
            if type(k) == "string" and type(v) == "table"
                and (v["10-19"] or v["20-39"] or v["40-59"] or v["60"]) then
                specs[#specs + 1] = k
            end
        end
        table.sort(specs)
        if type(specName) == "string" then
            for _, s in ipairs(specs) do
                if s == specName then pickedSpec = s; break end
            end
        end
        if not pickedSpec then pickedSpec = specs[1] end
        local specTbl = pickedSpec and cls[pickedSpec] or nil
        if type(specTbl) == "table" then
            specVerified = specTbl.verified == true
            local lv = tonumber(level) or 1
            local bandKey = (lv >= 60 and "60") or (lv >= 40 and "40-59")
                or (lv >= 20 and "20-39") or "10-19"
            band = specTbl[bandKey] or specTbl["10-19"] or specTbl["20-39"] or specTbl["60"]
        end
    end

    local activeMode = (mode == "aoe") and "aoe" or "st"
    local rawList = band and (band[activeMode] or band.st) or {}
    local entries = {}
    for _, row in ipairs(rawList) do
        if type(row) == "table" and type(row.name) == "string" then
            local ids = CollectIDs(row.name, row.rankIDs, row.spellID)
            if #ids > 0 then
                entries[#entries + 1] = {
                    name = row.name,
                    ids = ids,
                    cond = row.cond,
                    verified = row.verified == true,
                }
            end
        end
    end

    local rawGroups = (TA.SpellPlaybook and TA.SpellPlaybook.GetBuffGroups
        and TA.SpellPlaybook.GetBuffGroups(classToken))
        or FALLBACK_BUFF_GROUPS[classToken] or {}
    local buffGroups = {}
    for _, grp in ipairs(rawGroups) do
        local spells = {}
        for _, spName in ipairs(grp.spells or {}) do
            local ids = CollectIDs(spName)
            if #ids > 0 then
                spells[#spells + 1] = { name = spName, ids = ids }
            end
        end
        if #spells > 0 then
            buffGroups[#buffGroups + 1] = { label = grp.label, spells = spells }
        end
    end

    local shootIDs = WAND_CLASSES[classToken] and CollectIDs("Shoot") or nil

    return {
        class = classToken,
        spec = pickedSpec,
        mode = activeMode,
        verified = specVerified,
        entries = entries,
        buffGroups = buffGroups,
        shootIDs = (shootIDs and #shootIDs > 0) and shootIDs or nil,
    }
end

function M.Spells()
    if M._spells then return M._spells end
    local data = TA.Data or {}
    local book = data.ForeverSpells
    local talents = data.ForeverTalents
    M._spells = M.BuildSpells(
        data.ForeverSpellRanks,
        book and book.MAGE,
        talents and talents.MAGE,
        M.ScanLiveSpellbook())
    return M._spells
end

local function CooldownAllowed()
    if not (TA and TA.HasAPI) then return true end
    if TA:HasAPI("C_Spell.GetSpellCooldown") then return true end
    if TA:HasAPI("GetSpellCooldown") then return true end
    return false
end

local function AurasAllowed()
    local modern = false
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        if not (TA and TA.HasAPI and not TA:HasAPI("C_UnitAuras.GetAuraDataByIndex")) then
            modern = true
        end
    end
    local util = AuraUtil and type(AuraUtil.ForEachAura) == "function"
    return modern or util or false
end

local function ManaAllowed()
    if not (TA and TA.HasAPI) then
        return type(UnitPower) == "function" and type(UnitPowerMax) == "function"
    end
    return TA:HasAPI("UnitPower") and TA:HasAPI("UnitPowerMax")
end

local function ResolveActiveSpec()
    local SP = TA.SpellPlaybook
    if SP and type(SP.selectedSpec) == "string" and SP.selectedSpec ~= "" then
        return SP.selectedSpec
    end
    if TA.Utils and type(TA.Utils.GetPlayerSpec) == "function" then
        local ok, _, sName = pcall(TA.Utils.GetPlayerSpec)
        if ok and M.ValueKnown(sName) and type(sName) == "string" and sName ~= "" then
            return sName
        end
    end
    return nil
end

local function ResolveActiveMode()
    local db = TA.db and TA.db.mageSuggest
    if db and (db.mode == "st" or db.mode == "aoe") then
        return db.mode
    end
    local SP = TA.SpellPlaybook
    if SP and (SP.activeMode == "aoe" or SP.activeMode == "st") then
        return SP.activeMode
    end
    return "st"
end

local function ReadSpellIDsState(state, ids, compat, canLearn, canCd)
    for _, spellID in ipairs(ids or {}) do
        if state.known[spellID] == nil then
            local learned = "unknown"
            if canLearn then
                local ok, value = pcall(compat.SpellLearned, spellID)
                if ok and (value == "yes" or value == "no" or value == "unknown") then
                    learned = value
                end
            end
            state.known[spellID] = learned
            if canCd then
                local ok, start, duration = pcall(compat.GetSpellCooldown, spellID)
                if ok then
                    state.cooldown[spellID] = M.CooldownState(start, duration)
                else
                    state.cooldown[spellID] = "unknown"
                end
            else
                state.cooldown[spellID] = "unknown"
            end
        end
    end
end

function M.ReadState()
    local state = {
        known = {},
        cooldown = {},
        mana = "unknown",
        melee = nil,
        buffs = nil,
        debuffs = nil,
        spec = ResolveActiveSpec(),
        mode = ResolveActiveMode(),
    }
    local compat = TA.Compat
    if not compat then return state end
    if type(compat.UnitClass) == "function" then
        local _, token = compat.UnitClass("player")
        if M.ValueKnown(token) and type(token) == "string" and token ~= "" then
            state.class = token
        end
    end
    if not state.class then return state end

    local level = 1
    if type(UnitLevel) == "function" then
        local okL, lv = pcall(UnitLevel, "player")
        if okL and M.ValueKnown(lv) and type(lv) == "number" then level = lv end
    end
    state.level = level

    local canLearn = type(compat.SpellLearned) == "function"
    local canCd = CooldownAllowed() and type(compat.GetSpellCooldown) == "function"

    if state.class == "MAGE" then
        local spells = M.Spells()
        for _, row in pairs(spells) do
            ReadSpellIDsState(state, row.ids, compat, canLearn, canCd)
        end
    else
        local pb = M.BuildClassPlaybook(state.class, state.spec, level, state.mode, M.ScanLiveSpellbook())
        state.playbook = pb
        if pb then
            if pb.spec and not state.spec then state.spec = pb.spec end
            for _, entry in ipairs(pb.entries or {}) do
                ReadSpellIDsState(state, entry.ids, compat, canLearn, canCd)
            end
            for _, grp in ipairs(pb.buffGroups or {}) do
                for _, sp in ipairs(grp.spells or {}) do
                    ReadSpellIDsState(state, sp.ids, compat, canLearn, canCd)
                end
            end
            if pb.shootIDs then
                ReadSpellIDsState(state, pb.shootIDs, compat, canLearn, canCd)
            end
        end
    end

    if ManaAllowed() and type(compat.PlayerMana) == "function" then
        local ok, current, maxValue = pcall(compat.PlayerMana)
        if ok then state.mana = M.ManaState(current, maxValue) end
    end

    if AurasAllowed() and type(compat.ReadAuras) == "function" then
        local okH, helpful = pcall(compat.ReadAuras, "player", "HELPFUL")
        local okD, harmful = pcall(compat.ReadAuras, "target", "HARMFUL")
        if okH then state.buffs = M.IndexAuras(helpful) end
        if okD then state.debuffs = M.IndexAuras(harmful) end
    end

    if type(compat.TargetInMelee) == "function" then
        local ok, dist = pcall(compat.TargetInMelee, "target")
        if ok then state.melee = M.MeleeState(dist) end
    end
    return state
end

function M:BlockCounts()
    return self._blocked or 0, self._forbidden or 0
end

function M:NoteBlock(event, addon)
    if not M.ValueKnown(addon) or addon ~= "ToonAge" then return end
    if event == "ADDON_ACTION_BLOCKED" then
        self._blocked = (self._blocked or 0) + 1
    elseif event == "ADDON_ACTION_FORBIDDEN" then
        self._forbidden = (self._forbidden or 0) + 1
    end
end

local function InCombat()
    local compat = TA.Compat
    if compat and type(compat.InCombat) == "function" then
        local ok, locked = pcall(compat.InCombat)
        if ok and locked == true then return true end
    end
    return false
end

local function Saved()
    if not TA.db then return nil end
    TA.db.mageSuggest = TA.db.mageSuggest or {}
    return TA.db.mageSuggest
end

function M:IsEnabled()
    local db = TA.db and TA.db.mageSuggest
    if db and db.enabled == false then return false end
    return true
end

function M:SetEnabled(flag)
    local db = Saved()
    if db then db.enabled = flag and true or false end
    self:Refresh()
    return self:IsEnabled()
end

function M:ToggleEnabled()
    return self:SetEnabled(not self:IsEnabled())
end

function M:Locked()
    local db = TA.db and TA.db.mageSuggest
    return db and db.locked and true or false
end

function M:ToggleLock()
    local db = Saved()
    if db then db.locked = not db.locked end
    self:ApplyLock()
    return self:Locked()
end

function M:GetMode()
    return ResolveActiveMode()
end

function M:SetMode(mode)
    local norm = (mode == "aoe") and "aoe" or "st"
    local db = Saved()
    if db then db.mode = norm end
    if TA.SpellPlaybook and (TA.SpellPlaybook.activeMode == "st" or TA.SpellPlaybook.activeMode == "aoe") then
        TA.SpellPlaybook.activeMode = norm
    end
    self:Refresh()
    return norm
end

function M:ToggleMode()
    return self:SetMode(self:GetMode() == "aoe" and "st" or "aoe")
end

function M:ResetPosition()
    local db = Saved()
    if db then
        db.point = nil
        db.rel = nil
        db.x = nil
        db.y = nil
    end
    self._placed = nil
    local frame = self._frame
    if frame and not InCombat() then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    elseif frame then
        self._deferred = true
    end
end

local function FontFile()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    return "Fonts\\FRIZQT__.TTF"
end

function M:ApplyTheme(classToken)
    local frame = self._frame
    if not frame then return end
    local accent = { 0.85, 0.65, 0.13 }
    if TA.Theme and type(TA.Theme.GetAccent) == "function" then
        local ok, col = pcall(TA.Theme.GetAccent, TA.Theme, classToken)
        if ok and type(col) == "table" and type(col[1]) == "number" then
            accent = col
        end
    end
    if frame.SetBackdropColor then
        frame:SetBackdropColor(0.05, 0.06, 0.08, 0.86)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.85)
    end
    if frame.specular and frame.specular.SetColorTexture then
        frame.specular:SetColorTexture(1, 1, 1, 0.22)
    end
    if frame.badge and frame.badge.SetTextColor then
        frame.badge:SetTextColor(accent[1], accent[2], accent[3], 0.95)
    end
end

function M:ApplyLock()
    local frame = self._frame
    if not frame then return end
    if frame.SetMovable then frame:SetMovable(not self:Locked()) end
end

function M:ApplyFrame()
    local frame = self._frame
    if not frame then return end
    if InCombat() then
        self._deferred = true
        return
    end
    self._deferred = nil
    if not self._placed and TA.db then
        self._placed = true
        local db = TA.db.mageSuggest
        if db and type(db.point) == "string" and M.ValueKnown(db.x) and M.ValueKnown(db.y)
            and type(db.x) == "number" and type(db.y) == "number" then
            frame:ClearAllPoints()
            frame:SetPoint(db.point, UIParent, db.rel or "CENTER", db.x, db.y)
        end
    end
    self:ApplyLock()
    if self._wantShow then
        if frame.IsShown and not frame:IsShown() then frame:Show() end
    else
        if frame.IsShown and frame:IsShown() then frame:Hide() end
    end
end

local function Paint(frame, suggestion, state)
    frame.suggestion = suggestion
    if suggestion then
        local tex
        local compat = TA.Compat
        if compat and type(compat.GetSpellTexture) == "function" then
            local ok, icon = pcall(compat.GetSpellTexture, suggestion.spellID)
            if ok and M.ValueKnown(icon) and (type(icon) == "number" or type(icon) == "string") then
                tex = icon
            end
        end
        if tex and frame.icon then
            frame.icon:SetTexture(tex)
            frame.icon:Show()
        elseif frame.icon then
            frame.icon:Hide()
        end
        if frame.label then frame.label:SetText(suggestion.name or "") end
        if frame.badge then
            local modeTag = (suggestion.mode == "aoe") and "AoE" or "ST"
            local specTag = suggestion.spec or (state and state.spec) or ""
            frame.badge:SetText(specTag ~= "" and (specTag .. " " .. modeTag) or modeTag)
        end
    else
        if frame.icon then frame.icon:Hide() end
        if frame.label then frame.label:SetText("") end
        if frame.badge then frame.badge:SetText("") end
    end
end

function M:Refresh()
    local state = M.ReadState()
    local forever = TA.flavor == "forever"
    local enabled = self:IsEnabled()
    local show = forever and enabled and type(state.class) == "string" and state.class ~= ""
    local suggestion
    if show then
        suggestion = M.Suggest(state, state.class == "MAGE" and M.Spells() or nil)
        -- For non-Mage classes, hide the capsule cleanly if no spell is ready/known
        -- so the player never sees an empty floating box.
        if state.class ~= "MAGE" and not suggestion then
            show = false
        end
    end
    self._wantShow = show and true or false
    if self._frame then
        self:ApplyTheme(state.class)
        Paint(self._frame, suggestion, state)
    end
    self:ApplyFrame()
end

local function SavePosition(frame)
    if InCombat() then return end
    if not frame.GetPoint then return end
    local point, _, rel, x, y = frame:GetPoint()
    if type(point) ~= "string" then return end
    if not M.ValueKnown(x) or not M.ValueKnown(y) then return end
    if type(x) ~= "number" or type(y) ~= "number" then return end
    local db = Saved()
    if not db then return end
    db.point = point
    db.rel = type(rel) == "string" and rel or "CENTER"
    db.x = x
    db.y = y
end

function M:CreateFrame()
    if self._frame or type(CreateFrame) ~= "function" or not UIParent then return end
    local frame = CreateFrame("Frame", "ToonAgeMageSuggestFrame", UIParent, "BackdropTemplate")
    frame:SetSize(64, 76)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        if frame.SetBackdropColor then frame:SetBackdropColor(0.05, 0.06, 0.08, 0.86) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.85, 0.65, 0.13, 0.85) end
    end

    -- 1px top specular highlight (Liquid Glass suggestion capsule).
    local specular = frame:CreateTexture(nil, "OVERLAY")
    specular:SetHeight(1)
    specular:SetPoint("TOPLEFT", 1, -1)
    specular:SetPoint("TOPRIGHT", -1, -1)
    if specular.SetColorTexture then specular:SetColorTexture(1, 1, 1, 0.22) end
    frame.specular = specular

    local badge = frame:CreateFontString(nil, "OVERLAY")
    if badge.SetFont then badge:SetFont(FontFile(), 8, "") end
    badge:SetPoint("TOP", 0, -3)
    badge:SetSize(60, 10)
    badge:SetTextColor(0.85, 0.65, 0.13, 0.95)
    badge:SetText("")
    frame.badge = badge

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOP", 0, -15)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    frame.icon = icon

    local label = frame:CreateFontString(nil, "OVERLAY")
    if label.SetFont then label:SetFont(FontFile(), 9, "") end
    label:SetPoint("BOTTOM", 0, 4)
    label:SetSize(60, 12)
    label:SetTextColor(0.92, 0.90, 0.87, 1)
    label:SetText("")
    frame.label = label

    frame:SetScript("OnDragStart", function(self)
        if M:Locked() or InCombat() then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    frame:SetScript("OnEnter", function(self)
        if not self.suggestion or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local header = self.suggestion.name or "Suggestion"
        if self.suggestion.spec and self.suggestion.spec ~= "" then
            header = header .. " (" .. self.suggestion.spec
                .. (self.suggestion.mode == "aoe" and " · AoE" or " · ST") .. ")"
        end
        GameTooltip:AddLine(header, 1, 0.85, 0.3, false)
        GameTooltip:AddLine(self.suggestion.why or "Suggestion", 0.92, 0.90, 0.87, true)
        if self.suggestion.unverified then
            GameTooltip:AddLine("Reference priority (unverified on Forever 1.60.1).", 0.85, 0.70, 0.35, true)
        end
        GameTooltip:AddLine("Suggestion only. This frame does not cast. (/ta hud)", 0.62, 0.59, 0.55, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)

    local function watch(event)
        pcall(frame.RegisterEvent, frame, event)
    end
    watch("ADDON_ACTION_BLOCKED")
    watch("ADDON_ACTION_FORBIDDEN")
    watch("PLAYER_ENTERING_WORLD")
    watch("PLAYER_REGEN_ENABLED")
    watch("PLAYER_REGEN_DISABLED")
    watch("PLAYER_TARGET_CHANGED")
    watch("SPELLS_CHANGED")
    watch("SPELL_UPDATE_COOLDOWN")
    watch("UNIT_AURA")
    watch("UNIT_POWER_UPDATE")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
            M:NoteBlock(event, ...)
            return
        end
        if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            M._liveByName = nil
            M._spells = nil
        end
        if event == "PLAYER_REGEN_ENABLED" then M._deferred = true end
        M._dirty = true
    end)

    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, dt)
        if not M.ValueKnown(dt) or type(dt) ~= "number" then return end
        elapsed = elapsed + dt
        if elapsed < UPDATE_INTERVAL and not M._dirty and not M._deferred then return end
        if elapsed >= UPDATE_INTERVAL or M._dirty then
            elapsed = 0
            M._dirty = nil
            local ok, err = pcall(M.Refresh, M)
            if not ok and not M._logged then
                M._logged = true
                local log = TA.ErrorLog
                if log and log.Log then pcall(log.Log, log, "MageSuggest", tostring(err)) end
            end
        elseif M._deferred and not InCombat() then
            M:ApplyFrame()
        end
    end)

    -- CreateFrame shows the new frame. It is not secure and it is not a
    -- protected action to hide it. Later Show, Hide, and SetPoint go through
    -- ApplyFrame, which waits for combat to end.
    self._frame = frame
    self._wantShow = false
    frame:Hide()
end

M.SlashCommands = {
    hud = function(self, arg)
        local cmd = type(arg) == "string" and arg:lower():match("^%s*(%S+)") or ""
        if cmd == "lock" then
            local locked = self:ToggleLock()
            if TA.Print then TA:Print("Combat Suggest HUD " .. (locked and "locked." or "unlocked.")) end
        elseif cmd == "st" or cmd == "aoe" then
            local m = self:SetMode(cmd)
            if TA.Print then TA:Print("Combat Suggest HUD mode: " .. (m == "aoe" and "AoE." or "Single Target.")) end
        elseif cmd == "reset" then
            self:ResetPosition()
            if TA.Print then TA:Print("Combat Suggest HUD position reset.") end
        elseif cmd == "on" then
            self:SetEnabled(true)
            if TA.Print then TA:Print("Combat Suggest HUD enabled.") end
        elseif cmd == "off" then
            self:SetEnabled(false)
            if TA.Print then TA:Print("Combat Suggest HUD hidden.") end
        else
            local on = self:ToggleEnabled()
            if TA.Print then TA:Print("Combat Suggest HUD " .. (on and "enabled." or "hidden.")) end
        end
    end,
}

function M:Init()
    self:CreateFrame()
    self._dirty = true
end

return M
