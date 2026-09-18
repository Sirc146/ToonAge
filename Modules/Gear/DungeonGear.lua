-- ToonAge/Modules/DungeonGear.lua
-- Dungeon Gear Suggestions: cross-references character's weakest equipment
-- slots (via Gear.lua scores) with dungeon loot data to show "your biggest
-- upgrade drops from X boss in Y dungeon."
--
-- Displays in the Gear tab as an additional section below the upgrade list.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local DG = {}
TA:RegisterModule("DungeonGear", DG)

-- ── Static loot data (Midnight Season 1 M+ pool) ─────────────────────────────
-- Format: { dungeonName, bossName, slot, itemID, ilvlBase, primaryStat }
-- This is a curated subset — the most impactful pieces per armor type.
-- Expandable via Data/ files in future.

DG.LOOT_TABLE = {
    -- Windrunner Spire
    { dungeon = "Windrunner Spire",  boss = "Sylvanas Remnant",      slot = "INVTYPE_CHEST",     itemID = 232001, ilvl = 639, stat = "AGI" },
    { dungeon = "Windrunner Spire",  boss = "Sylvanas Remnant",      slot = "INVTYPE_CHEST",     itemID = 232002, ilvl = 639, stat = "INT" },
    { dungeon = "Windrunner Spire",  boss = "Sylvanas Remnant",      slot = "INVTYPE_CHEST",     itemID = 232003, ilvl = 639, stat = "STR" },
    { dungeon = "Windrunner Spire",  boss = "Darkfallen Commander",  slot = "INVTYPE_TRINKET",   itemID = 232010, ilvl = 639, stat = "AGI" },
    { dungeon = "Windrunner Spire",  boss = "Darkfallen Commander",  slot = "INVTYPE_TRINKET",   itemID = 232011, ilvl = 639, stat = "INT" },

    -- Skyreach
    { dungeon = "Skyreach",          boss = "High Sage Viryx",       slot = "INVTYPE_HEAD",      itemID = 232020, ilvl = 639, stat = "AGI" },
    { dungeon = "Skyreach",          boss = "High Sage Viryx",       slot = "INVTYPE_HEAD",      itemID = 232021, ilvl = 639, stat = "INT" },
    { dungeon = "Skyreach",          boss = "Rukhran",               slot = "INVTYPE_WEAPON",    itemID = 232025, ilvl = 639, stat = "STR" },

    -- Magisters' Terrace
    { dungeon = "Magisters' Terrace", boss = "Kael'thas Sunstrider", slot = "INVTYPE_WEAPON",    itemID = 232030, ilvl = 639, stat = "INT" },
    { dungeon = "Magisters' Terrace", boss = "Kael'thas Sunstrider", slot = "INVTYPE_TRINKET",   itemID = 232031, ilvl = 639, stat = "STR" },
    { dungeon = "Magisters' Terrace", boss = "Priestess Delrissa",   slot = "INVTYPE_SHOULDER",  itemID = 232035, ilvl = 639, stat = "AGI" },

    -- Maisara Caverns
    { dungeon = "Maisara Caverns",   boss = "Elder Deeproot",        slot = "INVTYPE_LEGS",      itemID = 232040, ilvl = 639, stat = "STR" },
    { dungeon = "Maisara Caverns",   boss = "Elder Deeproot",        slot = "INVTYPE_LEGS",      itemID = 232041, ilvl = 639, stat = "AGI" },
    { dungeon = "Maisara Caverns",   boss = "Fungal Behemoth",       slot = "INVTYPE_FINGER",    itemID = 232045, ilvl = 639, stat = "INT" },

    -- Nexus-Point Xenas
    { dungeon = "Nexus-Point Xenas", boss = "Void Warden",           slot = "INVTYPE_CLOAK",     itemID = 232050, ilvl = 639, stat = "AGI" },
    { dungeon = "Nexus-Point Xenas", boss = "Void Warden",           slot = "INVTYPE_CLOAK",     itemID = 232051, ilvl = 639, stat = "INT" },
    { dungeon = "Nexus-Point Xenas", boss = "Xenas",                 slot = "INVTYPE_HAND",      itemID = 232055, ilvl = 639, stat = "STR" },

    -- Pit of Saron
    { dungeon = "Pit of Saron",      boss = "Scourgelord Tyrannus",  slot = "INVTYPE_FEET",      itemID = 232060, ilvl = 639, stat = "STR" },
    { dungeon = "Pit of Saron",      boss = "Scourgelord Tyrannus",  slot = "INVTYPE_FEET",      itemID = 232061, ilvl = 639, stat = "AGI" },
    { dungeon = "Pit of Saron",      boss = "Ick & Krick",           slot = "INVTYPE_WRIST",     itemID = 232065, ilvl = 639, stat = "INT" },

    -- Seat of the Triumvirate
    { dungeon = "Seat of the Triumvirate", boss = "L'ura",           slot = "INVTYPE_WAIST",     itemID = 232070, ilvl = 639, stat = "INT" },
    { dungeon = "Seat of the Triumvirate", boss = "Viceroy Nezhar",  slot = "INVTYPE_WAIST",     itemID = 232071, ilvl = 639, stat = "AGI" },

    -- Algeth'ar Academy
    { dungeon = "Algeth'ar Academy", boss = "Echo of Doragosa",      slot = "INVTYPE_2HWEAPON",  itemID = 232080, ilvl = 639, stat = "INT" },
    { dungeon = "Algeth'ar Academy", boss = "Crawth",                slot = "INVTYPE_FINGER",    itemID = 232085, ilvl = 639, stat = "AGI" },
}

-- Map INVTYPE to equipment slot IDs for comparison with Gear.lua
local SLOT_MAP = {
    INVTYPE_HEAD       = 1,  INVTYPE_NECK     = 2,  INVTYPE_SHOULDER = 3,
    INVTYPE_CLOAK      = 15, INVTYPE_CHEST    = 5,  INVTYPE_WRIST    = 9,
    INVTYPE_HAND       = 10, INVTYPE_WAIST    = 6,  INVTYPE_LEGS     = 7,
    INVTYPE_FEET       = 8,  INVTYPE_FINGER   = 11, INVTYPE_TRINKET  = 13,
    INVTYPE_WEAPON     = 16, INVTYPE_2HWEAPON = 16, INVTYPE_SHIELD   = 17,
    INVTYPE_RANGED     = 18, INVTYPE_HOLDABLE = 17,
}

-- ── Public API ────────────────────────────────────────────────────────────────

--- Get the primary stat for the current player spec.
function DG:GetPlayerPrimaryStat()
    local specIndex = GetSpecialization()
    if not specIndex then return "STR" end
    local _, _, _, _, role = GetSpecializationInfo(specIndex)
    -- Determine primary from spec
    local primaryStat = select(6, GetSpecializationInfo(specIndex))
    -- Fallback: check stat from spec role
    if primaryStat == LE_UNIT_STAT_INTELLECT or primaryStat == 4 then return "INT" end
    if primaryStat == LE_UNIT_STAT_AGILITY   or primaryStat == 2 then return "AGI" end
    return "STR"
end

--- Find the best dungeon upgrades for the player's weakest slots.
--- @param weakSlots table — array of { slotID, score } (lowest score = weakest)
--- @param maxResults number — how many suggestions to return
--- @return table — array of { dungeon, boss, slot, itemID, slotID }
function DG:GetSuggestions(weakSlots, maxResults)
    maxResults = maxResults or 3
    local primaryStat = self:GetPlayerPrimaryStat()
    local results = {}

    for _, weak in ipairs(weakSlots) do
        if #results >= maxResults then break end

        for _, loot in ipairs(self.LOOT_TABLE) do
            local lootSlot = SLOT_MAP[loot.slot]
            if lootSlot == weak.slotID and loot.stat == primaryStat then
                table.insert(results, {
                    dungeon = loot.dungeon,
                    boss    = loot.boss,
                    slot    = loot.slot,
                    itemID  = loot.itemID,
                    ilvl    = loot.ilvl,
                    slotID  = weak.slotID,
                })
                break  -- one suggestion per slot
            end
        end
    end

    return results
end

--- Get formatted suggestion lines for display.
--- Called from Gear.lua render when showing the upgrade section.
--- @return table — array of formatted strings, or empty if no suggestions
function DG:GetFormattedSuggestions()
    local Gear = TA:GetModule("Gear")
    if not Gear then return {} end

    -- Get slot scores from Gear module (if exposed)
    -- Fallback: scan equipped items for lowest ilvl slots
    local weakSlots = {}

    for slotID = 1, 18 do
        if slotID ~= 4 then  -- skip shirt
            local link = GetInventoryItemLink("player", slotID)
            if link then
                local ilvl = GetDetailedItemLevelInfo(link) or 0
                table.insert(weakSlots, { slotID = slotID, score = ilvl })
            else
                -- Empty slot is the weakest
                table.insert(weakSlots, { slotID = slotID, score = 0 })
            end
        end
    end

    -- Sort by score ascending (weakest first)
    table.sort(weakSlots, function(a, b) return a.score < b.score end)

    -- Get top 3 weakest slots
    local top3 = {}
    for i = 1, math.min(3, #weakSlots) do
        top3[i] = weakSlots[i]
    end

    local suggestions = self:GetSuggestions(top3)
    local lines = {}

    for _, s in ipairs(suggestions) do
        local slotName = s.slot:gsub("INVTYPE_", ""):gsub("2H", "Two-Hand "):lower()
        slotName = slotName:sub(1,1):upper() .. slotName:sub(2)
        table.insert(lines, string.format(
            "|cFF55CCFF%s|r — |cFFFFFFFF%s|r drops from |cFFFFD100%s|r (%s)",
            slotName, s.dungeon, s.boss, s.ilvl .. " ilvl"
        ))
    end

    return lines
end

--- Rank dungeons by total upgrade potential for this character.
--- Returns an ordered array of { dungeon, upgradeCount, totalScoreGain, items={} }
--- @param maxDungeons number — how many to return (default 3)
--- @return table
function DG:RankDungeons(maxDungeons)
    maxDungeons = maxDungeons or 3
    local primaryStat = self:GetPlayerPrimaryStat()
    local Gear = TA:GetModule("Gear")

    -- Build current score per slot
    local slotScores = {}
    for slotID = 1, 18 do
        if slotID ~= 4 then
            local link = GetInventoryItemLink("player", slotID)
            if link and Gear and Gear.CalculateItemScore then
                local specID = U.GetPlayerSpec and U.GetPlayerSpec()
                local mode = (TA.charDB and TA.charDB.pvxMode) or "pve"
                slotScores[slotID] = Gear.CalculateItemScore(link, specID, mode) or 0
            else
                slotScores[slotID] = link and (GetDetailedItemLevelInfo(link) or 0) * 3 or 0
            end
        end
    end

    -- Score each dungeon by how many slots it can upgrade
    local dungeonScores = {}
    for _, loot in ipairs(self.LOOT_TABLE) do
        if loot.stat == primaryStat then
            local lootSlot = SLOT_MAP[loot.slot]
            if lootSlot then
                local currentScore = slotScores[lootSlot] or 0
                local lootScore = (loot.ilvl or 0) * 3  -- approximate; real scoring needs the item link
                local gain = lootScore - currentScore
                if gain > 0 then
                    local key = loot.dungeon
                    if not dungeonScores[key] then
                        dungeonScores[key] = { dungeon = key, upgradeCount = 0, totalScoreGain = 0, items = {} }
                    end
                    dungeonScores[key].upgradeCount = dungeonScores[key].upgradeCount + 1
                    dungeonScores[key].totalScoreGain = dungeonScores[key].totalScoreGain + gain
                    table.insert(dungeonScores[key].items, {
                        boss = loot.boss,
                        slot = loot.slot,
                        ilvl = loot.ilvl,
                        gain = math.floor(gain),
                    })
                end
            end
        end
    end

    -- Sort by total score gain descending
    local ranked = {}
    for _, d in pairs(dungeonScores) do
        table.insert(ranked, d)
    end
    table.sort(ranked, function(a, b) return a.totalScoreGain > b.totalScoreGain end)

    -- Trim to max
    local results = {}
    for i = 1, math.min(maxDungeons, #ranked) do
        results[i] = ranked[i]
    end
    return results
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function DG:Init()
    -- No init needed — data is static, queries are on-demand
end

DG.SlashCommands = {
    dungear = function(self)
        local lines = self:GetFormattedSuggestions()
        if #lines == 0 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r No dungeon gear suggestions available.")
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Dungeon gear upgrades for your weakest slots:")
            for _, line in ipairs(lines) do
                TA:Raw(TA.LOG.OUTPUT, "  " .. line)
            end
        end
    end,

    dungeonrank = function(self)
        local ranked = self:RankDungeons(5)
        if #ranked == 0 then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r No dungeon upgrades found for your spec.")
        else
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r Best dungeons for upgrades (by total gain):")
            for i, d in ipairs(ranked) do
                TA:Raw(TA.LOG.OUTPUT, string.format("  |cFF4AFF7A%d.|r |cFFFFFFFF%s|r — %d upgrades, +%d score",
                    i, d.dungeon, d.upgradeCount, math.floor(d.totalScoreGain)))
                for _, item in ipairs(d.items) do
                    local slotName = item.slot:gsub("INVTYPE_", ""):gsub("2H", "2H-"):lower()
                    TA:Raw(TA.LOG.OUTPUT, string.format("     |cFF888780%s from %s (%d ilvl, +%d)|r",
                        slotName, item.boss, item.ilvl, item.gain))
                end
            end
        end
    end,
}
