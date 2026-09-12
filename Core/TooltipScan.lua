-- ToonAge/Core/TooltipScan.lua (Anniversary — TBC Classic / 20506)
-- Reads item tooltip lines to find the value GetItemStats cannot see.
--
-- ─── THE BUG THIS EXISTS TO FIX ─────────────────────────────────────────────
--
-- GetItemStats returns STATIC stats only. It returns nothing at all for:
--
--     "Use: Increases attack power by 278 for 20 sec."
--     "Chance on hit: Increases haste rating by 325 for 10 sec."
--     "Equip: Your melee attacks have a chance to ..."
--
-- Which is to say: it returns nothing for the part of a TBC trinket that makes
-- it a TBC trinket. Bloodlust Brooch, Icon of the Silver Crescent, Dragonspine
-- Trophy and Darkmoon Card: Crusade all carry little or no static stat budget —
-- their entire power is in a line GetItemStats never reports.
--
-- Before this file existed, Modules/Gear/Gear.lua scored those at or near zero
-- and would rank a best-in-slot trinket BELOW a green with +8 Stamina, then
-- offer the green as an upgrade. That is not a cosmetic ranking error; it is the
-- addon confidently recommending a downgrade, with no error and no warning.
--
-- The fix is NOT to guess what an on-use is worth. Estimating "278 attack power
-- for 20 seconds on a 2 minute cooldown" requires knowing your rotation, your
-- other cooldowns and the fight length, and a made-up number would be worse than
-- no number because it would look authoritative.
--
-- The fix is to DETECT that unscoreable value is present, mark the item, and
-- refuse to rank it against items that were scored fully. An honest "cannot
-- compare this" beats a confident wrong answer.
--
-- ─── LOCALE ─────────────────────────────────────────────────────────────────
--
-- Matching is done against Blizzard's own localized globals — ITEM_SPELL_TRIGGER_ONUSE
-- and friends — not against hardcoded English. Those globals hold "Use:" on an
-- English client and the correct translation elsewhere, so this works in any
-- locale. English strings appear only as a fallback if a global is missing.

local TA = ToonAge
local U  = TA.Utils

local T = {}
TA.TooltipScan = T

-- ── The scanning tooltip ─────────────────────────────────────────────
-- A hidden tooltip of our own. Using GameTooltip directly would flicker the
-- player's real tooltip and fight with any other addon that hooks it.
local scanner

local function GetScanner()
    if scanner then return scanner end
    local ok, frame = pcall(CreateFrame, "GameTooltip", "ToonAgeScanTooltip", nil, "GameTooltipTemplate")
    if not ok or not frame then return nil end
    frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner = frame
    return scanner
end

-- Localized trigger strings, with English fallbacks.
local function Trigger(globalName, fallback)
    local v = _G[globalName]
    if type(v) == "string" and v ~= "" then return v end
    return fallback
end

local ON_USE   = Trigger("ITEM_SPELL_TRIGGER_ONUSE",  "Use:")
local ON_PROC  = Trigger("ITEM_SPELL_TRIGGER_ONPROC", "Chance on hit:")
local UNIQUE   = Trigger("ITEM_UNIQUE",               "Unique")
local UNIQUE_EQ= Trigger("ITEM_UNIQUE_EQUIPPABLE",    "Unique-Equipped")

--- Read every left-hand tooltip line for an item link.
--- @return table lines, boolean ok
function T:ReadLines(link)
    if not link then return {}, false end
    local tip = GetScanner()
    if not tip then return {}, false end

    local ok = pcall(function()
        tip:ClearLines()
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tip:SetHyperlink(link)
    end)
    if not ok then return {}, false end

    local lines = {}
    local n = tip:NumLines() or 0
    for i = 1, n do
        local fs = _G["ToonAgeScanTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if text and text ~= "" then
            lines[#lines + 1] = text
        end
    end

    -- A tooltip with one line means the item is not in the client's cache yet.
    -- Report that rather than concluding "this item has no effects".
    -- WARN: this heuristic assumes every cached item tooltip has 2+ left lines.
    -- A genuinely minimal item (no bind text, no item level/type line shown,
    -- nothing but the name) would report n == 1 while fully cached, and gets
    -- permanently misread as "not cached yet" here — GetItemFlags then returns
    -- all-false with cached=false, and HasHiddenValue reports "the client has
    -- not cached this item yet" forever for that item, never re-checking since
    -- nothing about a truly 1-line tooltip changes on a later scan.
    return lines, (n > 1)
end

--- Flags describing value the stat scorer cannot see.
--- @return table {hasUse, hasProc, unique, uniqueEquipped, cached, effectLines}
function T:GetItemFlags(link)
    local result = {
        hasUse = false, hasProc = false,
        unique = false, uniqueEquipped = false,
        cached = false, effectLines = {},
    }
    if not link then return result end

    local lines, cached = self:ReadLines(link)
    result.cached = cached
    if not cached then return result end

    for _, text in ipairs(lines) do
        if ON_USE ~= "" and text:find(ON_USE, 1, true) then
            result.hasUse = true
            result.effectLines[#result.effectLines + 1] = text
        elseif ON_PROC ~= "" and text:find(ON_PROC, 1, true) then
            result.hasProc = true
            result.effectLines[#result.effectLines + 1] = text
        end

        if UNIQUE_EQ ~= "" and text:find(UNIQUE_EQ, 1, true) then
            result.uniqueEquipped = true
        elseif UNIQUE ~= "" and text == UNIQUE then
            result.unique = true
        end
    end

    return result
end

--- Does this item carry value the stat scorer provably cannot account for?
---
--- Two independent signals, because either alone misses cases:
---   1. An explicit Use: or Chance on hit: line. Definitive.
---   2. A trinket that scored zero. Trinkets with genuinely no value do not
---      exist at usable quality, so a zero score on a trinket IS the evidence
---      that its worth lives somewhere GetItemStats does not look — including
---      "Equip:" proc lines, which carry no static stats and are easy to miss.
--- @return boolean unscoreable, string|nil reason
function T:HasHiddenValue(link, score, equipLoc)
    local flags = self:GetItemFlags(link)

    if not flags.cached then
        return true, "the client has not cached this item yet"
    end
    if flags.hasUse then
        return true, "it has an on-use effect, which no stat weight can price"
    end
    if flags.hasProc then
        return true, "it has a proc, whose value depends on your rotation and weapon speed"
    end
    if equipLoc == "INVTYPE_TRINKET" and (score or 0) <= 0 then
        return true, "it is a trinket with no static stats — its value is entirely in an effect"
    end

    return false, nil
end
