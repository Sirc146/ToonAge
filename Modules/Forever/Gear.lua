-- ToonAge/Modules/Forever/Gear.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS (AND ISN'T) ──────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- A readout of what you are wearing, nothing more. It lists every equipped
-- slot with the item's name (in its quality colour) and item level, then a
-- combined tally of the stats those items carry, read straight from the client.
--
-- It does NOT score gear, rank upgrades, or say "equip this". Vanilla stat
-- weights for this game have not been verified, and a scorer built on guessed
-- weights hands out confidently wrong advice — the same reason the Character
-- tab stays a readout. When real Data/Forever weights exist, an advisory layer
-- can sit on top of this; until then it reports facts.
--
-- APIs: C_Item.GetItemInfo / C_Item.GetItemStats (confirmed present in
-- Data/Forever/ApiManifest.lua) with the old globals as a fallback, and
-- GetInventoryItemLink for the equipped slots. Every call goes through Try(),
-- so a slot the client cannot answer is skipped rather than shown as a zero.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
TA:RegisterModule("ForeverGear", M)

-- ─── READS ─────────────────────────────────────────────────────────────────

--- Call an API that may not exist on this client. nil means "no answer".
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Num(v)
    if v == nil then return nil end
    return tonumber(tostring(v))
end

-- Equipped inventory slots that hold gear, in the order the character sheet
-- reads top-to-bottom. Slot 4 (shirt) and 19 (tabard) are cosmetic and left
-- out; ranged/relic (18) is kept because hunters and casters use it.
local SLOTS = {
    { id = 1,  name = "Head"      },
    { id = 2,  name = "Neck"      },
    { id = 3,  name = "Shoulder"  },
    { id = 15, name = "Back"      },
    { id = 5,  name = "Chest"     },
    { id = 9,  name = "Wrist"     },
    { id = 10, name = "Hands"     },
    { id = 6,  name = "Waist"     },
    { id = 7,  name = "Legs"      },
    { id = 8,  name = "Feet"      },
    { id = 11, name = "Ring 1"    },
    { id = 12, name = "Ring 2"    },
    { id = 13, name = "Trinket 1" },
    { id = 14, name = "Trinket 2" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand"  },
    { id = 18, name = "Ranged"    },
}

-- Item quality colours (Vanilla 0-5: poor/common/uncommon/rare/epic/legendary).
local QUALITY_HEX = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00",
    [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}

--- name, itemLevel, quality, link for an item link/id, via C_Item then globals.
local function ItemInfo(link)
    if not link then return nil end
    -- C_Item.GetItemInfo is the modern form Forever exposes; the global is the
    -- fallback for any client that still answers it.
    local name, _, quality, ilvl
    if C_Item and C_Item.GetItemInfo then
        local r = { Try(C_Item.GetItemInfo, link) }
        name, quality, ilvl = r[1], r[3], r[4]
    end
    if not name then
        local r = { Try(GetItemInfo, link) }
        name, quality, ilvl = r[1], r[3], r[4]
    end
    return name, Num(ilvl), Num(quality)
end

--- Item stat table for a link, via C_Item.GetItemStats then the global.
local function ItemStats(link)
    if not link then return nil end
    if C_Item and C_Item.GetItemStats then
        local t = Try(C_Item.GetItemStats, link)
        if type(t) == "table" then return t end
    end
    local t = Try(GetItemStats, link)
    if type(t) == "table" then return t end
    return nil
end

-- Human labels for the stat keys C_Item.GetItemStats returns. Only the ones
-- that exist in Vanilla are listed; anything the client returns that isn't here
-- is shown under its raw key rather than hidden, so nothing is silently lost.
local STAT_LABELS = {
    ITEM_MOD_STRENGTH_SHORT          = "Strength",
    ITEM_MOD_AGILITY_SHORT           = "Agility",
    ITEM_MOD_STAMINA_SHORT           = "Stamina",
    ITEM_MOD_INTELLECT_SHORT         = "Intellect",
    ITEM_MOD_SPIRIT_SHORT            = "Spirit",
    ITEM_MOD_ATTACK_POWER_SHORT      = "Attack Power",
    ITEM_MOD_CRIT_RATING_SHORT       = "Critical Strike",
    ITEM_MOD_HIT_RATING_SHORT        = "Hit",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense",
    ITEM_MOD_DODGE_RATING_SHORT      = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT      = "Parry",
    ITEM_MOD_BLOCK_RATING_SHORT      = "Block",
    ITEM_MOD_BLOCK_VALUE_SHORT       = "Block Value",
    ITEM_MOD_SPELL_POWER_SHORT       = "Spell Power",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT= "Healing Power",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mana per 5s",
    ITEM_MOD_POWER_REGEN0_SHORT      = "Mana per 5s",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "Weapon DPS",
    ITEM_MOD_MANA_SHORT              = "Mana",
    ITEM_MOD_HEALTH_SHORT            = "Health",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Damage",
    RESISTANCE1_NAME                 = "Holy Resistance",
    RESISTANCE2_NAME                 = "Fire Resistance",
    RESISTANCE3_NAME                 = "Nature Resistance",
    RESISTANCE4_NAME                 = "Frost Resistance",
    RESISTANCE5_NAME                 = "Shadow Resistance",
    RESISTANCE6_NAME                 = "Arcane Resistance",
    ITEM_MOD_HEALTH_REGENERATION_SHORT = "Health per 5s",
    RESISTANCE0_NAME                 = "Armor",
    ITEM_MOD_FIRE_RESISTANCE_SHORT   = "Fire Resistance",
    ITEM_MOD_FROST_RESISTANCE_SHORT  = "Frost Resistance",
    ITEM_MOD_NATURE_RESISTANCE_SHORT = "Nature Resistance",
    ITEM_MOD_SHADOW_RESISTANCE_SHORT = "Shadow Resistance",
    ITEM_MOD_ARCANE_RESISTANCE_SHORT = "Arcane Resistance",
}

-- Weapon DPS: labelled like any other stat, but deliberately kept OUT of the
-- combined totals -- see ScanEquipped.
local DPS_KEY = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"

-- Order the aggregated stats read sensibly: primaries, then offense, then
-- defense/resist. Keys not listed here fall to the end, alphabetically.
local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT",
    "RESISTANCE0_NAME", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_VALUE_SHORT",
    "ITEM_MOD_FIRE_RESISTANCE_SHORT", "ITEM_MOD_FROST_RESISTANCE_SHORT",
    "ITEM_MOD_NATURE_RESISTANCE_SHORT", "ITEM_MOD_SHADOW_RESISTANCE_SHORT",
    "ITEM_MOD_ARCANE_RESISTANCE_SHORT",
}

-- ─── SECTIONS ────────────────────────────────────────────────────────────

--- Scan equipped slots once, returning per-slot rows and the summed stat table.
--- Equip / Use / proc text for one item, or nil.
---
--- GetItemStats returns numeric stats only. "Equip: Increases damage and
--- healing done by magical spells and effects by up to 1." lives in the
--- tooltip and nowhere else, so it is read from a hidden tooltip through
--- Core/TooltipScan.lua -- the same scanner the TBC build uses, matched against
--- Blizzard's own localised trigger strings rather than English text.
---
--- DISPLAY ONLY. These lines are never added to the totals: modern clients
--- fold some of them into ITEM_MOD_SPELL_POWER already, so counting the text
--- as well would count the same point twice.
-- Scanned once per item link, then remembered.
--
-- A scan calls SetHyperlink, and an item the client has not cached yet answers
-- with a stub AND fires GET_ITEM_INFO_RECEIVED when the real data lands. That
-- event queues a UI refresh, the refresh re-renders this tab, the render scans
-- again -- a slow loop that also kept yanking the view back to the top. Caching
-- by link breaks it: each item is scanned once per session.
--
-- Only a CACHED result is stored. An uncached item is left out so it is picked
-- up on the next render, once its data has actually arrived.
local effectCache = {}

local function EffectLines(link)
    if not link then return nil end
    local hit = effectCache[link]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end

    local TS = TA.TooltipScan
    if not (TS and TS.GetItemFlags) then return nil end
    local ok, flags = pcall(TS.GetItemFlags, TS, link)
    if not ok or type(flags) ~= "table" then return nil end
    if not flags.cached then return nil end        -- try again once it loads

    if type(flags.effectLines) ~= "table" or #flags.effectLines == 0 then
        effectCache[link] = false
        return nil
    end
    effectCache[link] = flags.effectLines
    return flags.effectLines
end

--- One pass over the equipped slots.
--- @return table rows, table totals, table contributions, number equipped, number empty, number avgIlvl
local function ScanEquipped()
    local rows, totals, contrib = {}, {}, {}
    local equippedCount, emptyCount = 0, 0
    local ilvlSum, ilvlCount = 0, 0

    for _, slot in ipairs(SLOTS) do
        local link = Try(GetInventoryItemLink, "player", slot.id)
        if link then
            equippedCount = equippedCount + 1
            local name, ilvl, quality = ItemInfo(link)
            local row = {
                slot = slot.name, link = link, name = name, ilvl = ilvl,
                quality = quality, stats = {},
            }
            rows[#rows + 1] = row

            if ilvl and ilvl > 0 then
                ilvlSum   = ilvlSum + ilvl
                ilvlCount = ilvlCount + 1
            end

            local stats = ItemStats(link)
            if stats then
                for k, v in pairs(stats) do
                    local n = Num(v)
                    if n then
                        if k == DPS_KEY then
                            row.dps = n
                        else
                            totals[k] = (totals[k] or 0) + n
                            -- Which slot gave you this stat, kept for the
                            -- segmented bars. The total is the sum of exactly
                            -- these numbers, so the breakdown can never
                            -- disagree with the figure beside it.
                            contrib[k] = contrib[k] or {}
                            contrib[k][#contrib[k] + 1] = { label = slot.name, value = n }
                            row.stats[#row.stats + 1] = { key = k, value = n }
                        end
                    end
                end
            end

            row.effects = EffectLines(link)

            -- Read order from pairs() is arbitrary; sort so the same item always
            -- lists its stats the same way.
            table.sort(row.stats, function(a, b)
                return (STAT_LABELS[a.key] or a.key) < (STAT_LABELS[b.key] or b.key)
            end)
        else
            emptyCount = emptyCount + 1
            rows[#rows + 1] = { slot = slot.name, empty = true }
        end
    end

    for _, list in pairs(contrib) do
        table.sort(list, function(a, b) return a.value > b.value end)
    end

    local avg = (ilvlCount > 0) and (ilvlSum / ilvlCount) or nil
    return rows, totals, contrib, equippedCount, emptyCount, avg
end

local function RenderHeadline(content, y, rows, equippedCount, emptyCount, avgIlvl)
    y = L:SectionHeader(content, y, "Equipped Gear")

    -- Averaged over FILLED slots, not all of them.
    --
    -- GetAverageItemLevel counts an empty slot as zero, so a level 14 wearing
    -- nine items of level 10-15 was shown "6". That number is not wrong about
    -- its own arithmetic and is useless as a description of your gear. The
    -- client's figure is kept beside it, because that is what every other addon
    -- and Blizzard's own sheet will say.
    if avgIlvl then
        local blizz = Num(Try(GetAverageItemLevel))
        y = L:DataRow(content, y, {
            label = "Average item level",
            value = string.format("%.1f", avgIlvl),
            bold  = true,
            note  = blizz and string.format(
                "across %d equipped item%s; the client reports %d, counting empty slots as zero",
                equippedCount, equippedCount == 1 and "" or "s", math.floor(blizz)) or nil,
        })
    end

    y = L:DataRow(content, y, {
        label = "Slots filled",
        value = string.format("%d / %d", equippedCount, equippedCount + emptyCount),
    })

    -- Empty slots as ONE line instead of eight rows saying "empty". Eight
    -- repetitions of the same word was the loudest thing on this tab and the
    -- least informative; the list is the same information in a tenth the space.
    if emptyCount > 0 then
        local names = {}
        for _, r in ipairs(rows) do
            if r.empty then names[#names + 1] = r.slot end
        end
        y = L:DataRow(content, y, {
            label = "Empty",
            value = tostring(emptyCount),
            note  = table.concat(names, " · "),
            status = "dim",
        })
    end
    return y
end

--- "+3 Stamina  +1 Spirit" for one item.
local function StatSummary(row)
    if not row.stats or #row.stats == 0 then return nil end
    local parts = {}
    for _, s in ipairs(row.stats) do
        parts[#parts + 1] = string.format("%+d %s", s.value, STAT_LABELS[s.key] or s.key)
    end
    return table.concat(parts, "  ")
end

local function RenderSlots(content, y, rows)
    y = L:SectionHeader(content, y, "By Slot",
        "What each piece is carrying. Empty slots are listed above.")

    for _, r in ipairs(rows) do
        -- Empty slots are summarised in the headline; repeating them here is
        -- the noise this layout exists to remove.
        if not r.empty then
            local hex = QUALITY_HEX[r.quality or 1] or "ffffff"
            local shown = r.name and ("|cFF" .. hex .. r.name .. "|r") or "|cFF6E6A62loading…|r"

            local note = r.ilvl and ("Item level " .. r.ilvl) or nil
            if r.dps then
                local dps = string.format("%.1f DPS", r.dps)
                note = note and (note .. "  ·  " .. dps) or dps
            end

            y = L:DataRow(content, y, { label = r.slot, value = shown, note = note })

            local summary = StatSummary(r)
            if summary then
                y = L:Paragraph(content, y, summary, { color = L.C_SECONDARY, size = 9, gap = 0 })
            end

            -- Equip / Use / proc text, verbatim from the tooltip. Shown in the
            -- game's own green for effect lines so it reads the way it does on
            -- the item itself, and never folded into the totals below.
            if r.effects then
                for _, line in ipairs(r.effects) do
                    y = L:Paragraph(content, y, line, { color = L.C_SUCCESS, size = 9, gap = 0 })
                end
            end

            y = y - 4
        end
    end
    return y
end

local function RenderTotals(content, y, totals, contrib)
    y = L:SectionHeader(content, y, "Combined Stats",
        "Summed from equipped items as the client reports them. Hover a bar to "
        .. "see which slots it came from.")

    -- Ordered known stats first, then anything the client returned that has no
    -- label here -- surfaced under its raw key so an unknown stat is visible
    -- rather than silently dropped. An unknown key is Forever vocabulary nobody
    -- has written down yet, which is worth seeing.
    local ordered, shown = {}, {}
    for _, key in ipairs(STAT_ORDER) do
        local v = totals[key]
        if v and v ~= 0 then
            ordered[#ordered + 1] = { key = key, v = v }
            shown[key] = true
        end
    end
    local extras = {}
    for key, v in pairs(totals) do
        if not shown[key] and v and v ~= 0 then extras[#extras + 1] = { key = key, v = v } end
    end
    table.sort(extras, function(a, b) return a.key < b.key end)
    for _, e in ipairs(extras) do ordered[#ordered + 1] = e end

    if #ordered == 0 then
        y = L:Paragraph(content, y,
            "No item stats to total -- either nothing is equipped, or this client "
            .. "did not answer the item-stat calls.")
        return y
    end

    -- One scale for every bar in the section, so armour's 103 and stamina's 3
    -- are drawn to the same ruler and the comparison between them is real.
    local values = {}
    for _, e in ipairs(ordered) do values[#values + 1] = e.v end
    local scale = L.StatScale and L:StatScale(values) or nil

    for _, e in ipairs(ordered) do
        local segs = contrib[e.key]
        if scale and L.StackBar and segs and #segs > 0 then
            y = L:StackBar(content, y, {
                label = STAT_LABELS[e.key] or e.key,
                segments = segs, scale = scale,
                text = string.format("%d", e.v),
                status = STAT_LABELS[e.key] and nil or "dim",
            })
        else
            y = L:DataRow(content, y, {
                label = STAT_LABELS[e.key] or e.key,
                value = string.format("%d", e.v),
                status = STAT_LABELS[e.key] and "neutral" or "dim",
            })
        end
    end

    if totals["RESISTANCE0_NAME"] then
        y = L:Paragraph(content, y,
            "Armor above is the total from your gear. The Character tab shows a "
            .. "higher figure because it adds base armour from agility and level.",
            { color = L.C_DIM })
    end

    y = L:Paragraph(content, y,
        "Forever note: this realm treats Hit as one combined stat and Crit as "
        .. "one combined stat, so if items report melee/ranged/spell variants "
        .. "separately they all feed the same pool. Expertise counts here too, "
        .. "and healing power adds a third of its value as spell damage.",
        { color = L.C_DIM })

    y = L:Paragraph(content, y,
        "Equip and Use lines on the rows above are shown but NOT added here: "
        .. "the client already folds some of them into the stats it reports, and "
        .. "counting the text as well would count the same point twice.",
        { color = L.C_DIM })
    return y
end

local function RenderFooter(content, y)
    y = L:SectionHeader(content, y, "Scoring")
    y = L:Paragraph(content, y,
        "This tab reports what you are wearing and stays quiet about what to "
        .. "change. Upgrade scoring and best-in-slot are deliberately left to "
        .. "ForeverGear, the dedicated gear addon, which ships Forever "
        .. "Level-20 stat-priority profiles. ToonAge is the readout, not a "
        .. "second scoring engine.")
    return y
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. Report this with /ta health.")
        content:SetHeight(120)
        return
    end

    -- Reuse the Character tab's identity sidebar if it is available, so Gear
    -- has the same left column and does not draw a blank one. Guarded: if that
    -- module or its helper is absent, the sidebar is simply left empty.
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local rows, totals, contrib, equippedCount, emptyCount, avgIlvl = ScanEquipped()

    local y = -8
    y = RenderHeadline(content, y, rows, equippedCount, emptyCount, avgIlvl)
    y = L:Divider(content, y)
    y = RenderSlots(content, y, rows)
    y = L:Divider(content, y)
    y = RenderTotals(content, y, totals, contrib)
    y = L:Divider(content, y)
    y = RenderFooter(content, y)
    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    -- PLAYER_AVG_ITEM_LEVEL_UPDATE is gone on purpose: this tab computes its
    -- own average from the equipped slots, so the client's figure changing is
    -- not news, and the event fires often enough to be felt as the view
    -- jumping while you read.
    "PLAYER_EQUIPMENT_CHANGED",
    "UNIT_INVENTORY_CHANGED",
}

return M
