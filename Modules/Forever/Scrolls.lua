-- ToonAge/Modules/Forever/Scrolls.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS TAB IS ──────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- "Which class is this scroll for?" -- answered for everything in your bags,
-- and on the item tooltip wherever you hover it.
--
-- The answer is READ, never looked up. Every item carries its own class rules
-- in its tooltip, in Blizzard's localized format strings:
--
--     ITEM_CLASSES_ALLOWED  "Classes: %s"       -> exactly those classes
--     ITEM_MIN_SKILL        "Requires %s (%d)"  -> a skill gate; when the
--                                                  skill is Comprehension the
--                                                  item is a Mage decipher
--
-- An item with neither line is usable by any class. So this module carries no
-- item list and no class table of its own: a scroll Blizzard adds tomorrow is
-- classified correctly the first time it lands in a bag. That is the only way
-- to be right on a client no outside database describes yet.
--
-- VERIFIED 2026-09-27 (Wowhead Forever, items 211786 and 275067): scroll
-- tooltips carry "Classes: Mage", undeciphered ones add "Requires
-- Comprehension (N)" -- both lines this file parses.
--
-- WHAT IS UNVERIFIED (Docs/FOREVER_BRIEF.md, "Mage Comprehension scrolls"):
--   * The exact requirement line on an undeciphered scroll. Published guides
--     say the tooltip names Comprehension; whether it uses ITEM_MIN_SKILL or a
--     line of its own is not confirmed. Both are matched below, and anything
--     that mentions Comprehension with a number is treated as the gate.
-- Comprehension itself is skill line 3012, read with
-- C_TradeSkillUI.GetProfessionInfoBySkillLineID. Forever 1.60.1 answers
-- skillLevel 0 and maxSkillLevel 0 for a non-mage, and the skill row is hidden
-- in that case. GetSkillLineInfoByID returns nil when the character does not
-- have the skill; that nil is not a rank of 0.
--
-- WHAT COUNTS AS A SCROLL for the tab: anything Comprehension-gated, anything
-- class-restricted that is not equipment, and anything with "Scroll" in its
-- name. Equipment with a Classes: line (tier-style sets) is left out -- that
-- is the Gear tab's business, and it would bury the scrolls.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}

-- Forward declaration: defined in the CONVERSIONS section below Render.
local ConversionLine
TA:RegisterModule("ForeverScrolls", M)

-- English fallbacks, used only if the client lacks the localized global.
local COMPREHENSION_EN = "comprehension"
local SCROLL_WORD_EN   = "scroll"
local MAX_BAG_FALLBACK = 4

-- ─── SMALL HELPERS ─────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Plain(s)
    if s == nil or U.IsSecret(s) then return nil end
    local text = U.StripMarkup(s)
    if not text or text == "" then return nil end
    return U.Trim(text)
end

--- Turn a Blizzard format string into an anchored Lua pattern.
--- "Requires %s (%d)" -> "^Requires (.+) %((%d+)%)$"
--- Positional forms (%1$s) appear in some locales and are handled too.
local function FormatToPattern(fmt)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    local p = fmt:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    p = p:gsub("%%s", "(.+)")
    p = p:gsub("%%d", "(%%d+)")
    p = p:gsub("%%%d+%%%$s", "(.+)")
    p = p:gsub("%%%d+%%%$d", "(%%d+)")
    return "^" .. p .. "$"
end

local PAT_CLASSES = FormatToPattern(_G.ITEM_CLASSES_ALLOWED or "Classes: %s")
local PAT_SKILL   = FormatToPattern(_G.ITEM_MIN_SKILL or "Requires %s (%d)")

-- ─── CLASS NAMES ───────────────────────────────────────────────────────────
-- Tooltips print LOCALIZED class names. Map them back to the stable English
-- token so colours and "is this me?" work in any locale.

local classTokenByName

local function ClassToken(localizedName)
    if not classTokenByName then
        classTokenByName = {}
        for _, list in ipairs({ _G.LOCALIZED_CLASS_NAMES_MALE, _G.LOCALIZED_CLASS_NAMES_FEMALE }) do
            if type(list) == "table" then
                for token, name in pairs(list) do
                    classTokenByName[string.lower(name)] = token
                end
            end
        end
    end
    return classTokenByName[string.lower(localizedName or "")]
end

local function ClassColourText(name, token)
    local c = token and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[token]
    if c and c.colorStr then
        return "|c" .. c.colorStr .. name .. "|r"
    end
    return name
end

local function PlayerClass()
    local localized, token = UnitClass("player")
    return localized, token
end

-- ─── COMPREHENSION SKILL ───────────────────────────────────────────────────

local function IsComprehension(skillName)
    return skillName and string.lower(skillName):find(COMPREHENSION_EN, 1, true) ~= nil
end

--- The player's Comprehension rank, or nil if the client will not say.
--- @return number|nil rank, number|nil maxRank
local COMPREHENSION_SKILL_LINE = 3012   -- Wowhead Forever, skill=3012

--- Pure read of the two Comprehension answers.
--- profInfo: C_TradeSkillUI.GetProfessionInfoBySkillLineID(3012), or nil.
--- skillInfo: C_SkillInfo.GetSkillLineInfoByID(3012). Pass false when that
--- call returned nil -- the character does not have the skill. nil means the
--- call was not made. A max of 0 is definitive (a non-mage on Forever 1.60.1
--- answers skillLevel 0 and maxSkillLevel 0) and does not fall through.
--- @return number|nil rank, number|nil maxRank
function M.ReadComprehension(profInfo, skillInfo)
    if type(profInfo) == "table" then
        local max = tonumber(profInfo.maxSkillLevel)
        local rank = tonumber(profInfo.skillLevel)
        if max == 0 then return nil, 0 end
        if max and max > 0 then return rank or 0, max end
    end
    if skillInfo == false then return nil, 0 end
    if type(skillInfo) == "table" then
        local max = tonumber(skillInfo.maxRank)
        if not max or max <= 0 then return nil, 0 end
        return tonumber(skillInfo.rank) or 0, max
    end
    return nil, nil
end

local function PlayerComprehension()
    -- Comprehension is NOT in GetProfessions() on Forever (measured 2026-09-27:
    -- five slots, all trade/secondary skills). Ask for skill line 3012.
    -- Forever 1.60.1: a non-mage gets skillLevel 0 and maxSkillLevel 0 from
    -- GetProfessionInfoBySkillLineID. That hides the skill row. Do not fall
    -- through and invent a rank.
    local profInfo
    if C_TradeSkillUI and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) == "function" then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, COMPREHENSION_SKILL_LINE)
        if ok and type(info) == "table" then profInfo = info end
    end
    if type(profInfo) == "table" and tonumber(profInfo.maxSkillLevel) == 0 then
        return M.ReadComprehension(profInfo, nil)
    end
    if type(profInfo) == "table" and tonumber(profInfo.maxSkillLevel) and tonumber(profInfo.maxSkillLevel) > 0 then
        return M.ReadComprehension(profInfo, nil)
    end

    local profs = Try(U.GetProfessions)
    if type(profs) == "table" then
        for _, p in ipairs(profs) do
            if IsComprehension(p.name) then
                local rank, max = U.SafeNum(p.rank, nil), U.SafeNum(p.maxRank, nil)
                if max == 0 then return nil, 0 end
                if rank or max then return rank, max end
            end
        end
    end

    -- GetSkillLineInfoByID returns nil when the character does not have the
    -- skill. The old GetNumSkillLines/GetSkillLineInfo globals below are
    -- missing on Forever.
    if C_SkillInfo and type(C_SkillInfo.GetSkillLineInfoByID) == "function" then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, COMPREHENSION_SKILL_LINE)
        if ok and info == nil then return M.ReadComprehension(nil, false) end
        if ok and type(info) == "table" then return M.ReadComprehension(nil, info) end
    end

    -- Classic skill-line globals. Forever may not have them; every call is
    -- guarded and a missing function simply ends the search.
    -- Written as direct calls so gen_api_manifest.py lists them and ApiGuard
    -- reports at login whether this client has them at all.
    if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then
        return nil, nil
    end
    local okN, count = pcall(function() return GetNumSkillLines() end)
    count = okN and U.SafeNum(count, 0) or 0
    for i = 1, count do
        local ok, name, isHeader, _, rank, _, _, maxRank = pcall(function() return GetSkillLineInfo(i) end)
        if ok and name and not isHeader and IsComprehension(name) then
            return U.SafeNum(rank, nil), U.SafeNum(maxRank, nil)
        end
    end
    return nil, nil
end

-- ─── CLASSIFY ──────────────────────────────────────────────────────────────

--- Read class rules out of tooltip lines.
--- @param lines table array of tooltip left-line strings
--- @return table { classes = { {name, token} } | nil, skill, skillLevel, decipher }
function M.Classify(lines)
    local info = { classes = nil, skill = nil, skillLevel = nil, decipher = false }

    for _, raw in ipairs(lines or {}) do
        local text = Plain(raw)
        if text then
            local list = PAT_CLASSES and text:match(PAT_CLASSES)
            if list and not info.classes then
                info.classes = {}
                for part in list:gmatch("[^,]+") do
                    local name = U.Trim(part)
                    if name ~= "" then
                        info.classes[#info.classes + 1] = { name = name, token = ClassToken(name) }
                    end
                end
            end

            local skill, level = nil, nil
            if PAT_SKILL then skill, level = text:match(PAT_SKILL) end
            if skill and IsComprehension(skill) then
                info.skill, info.skillLevel = skill, tonumber(level)
                info.decipher = true
            elseif not info.decipher and IsComprehension(text) then
                -- Unconfirmed wording: any line naming Comprehension with a number.
                local n = text:match("(%d+)")
                if n then
                    info.skill, info.skillLevel = "Comprehension", tonumber(n)
                    info.decipher = true
                end
            end
        end
    end

    -- A Comprehension gate with no Classes: line still means Mage: only a Mage
    -- has the skill. Say so explicitly rather than "any class".
    if info.decipher and not info.classes then
        local mageName = (_G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE.MAGE) or "Mage"
        info.classes = { { name = mageName, token = "MAGE" } }
    end
    return info
end

--- Is the player's class allowed by this classification?
local function PlayerAllowed(info)
    if not info.classes then return true end
    local localized, token = PlayerClass()
    for _, c in ipairs(info.classes) do
        if (c.token and c.token == token) or (localized and c.name == localized) then
            return true
        end
    end
    return false
end

local function ClassesText(info)
    if not info.classes then return "Any class" end
    local parts = {}
    for _, c in ipairs(info.classes) do
        parts[#parts + 1] = ClassColourText(c.name, c.token)
    end
    return table.concat(parts, ", ")
end

--- One-line verdict for this player, plus a status key for colour.
--- @return string text, string status
local function Verdict(info, myRank)
    if not PlayerAllowed(info) then
        return "Not your class -- trade or mail it", "bad"
    end
    if info.decipher then
        local need = info.skillLevel or 0
        if myRank == nil then
            return string.format("Decipher: needs Comprehension %d -- your skill: n/a", need), "warn"
        elseif myRank >= need then
            return string.format("Readable now (needs Comprehension %d, you have %d)", need, myRank), "good"
        else
            return string.format("Not yet: needs Comprehension %d, you have %d", need, myRank), "warn"
        end
    end
    return "You can use this", "good"
end

-- ─── EFFECT AND BENEFIT ────────────────────────────────────────────────────
--
-- What a scroll DOES is read from its own "Use:" line, the same way its class
-- rules are, so this carries no item list either. The benefit maths is the
-- Classic Era rule set (15 mana per Intellect, 10 health per Stamina, armour
-- reduction A / (A + 400 + 85 x level)). Forever is a custom realm and none of
-- these conversions has been measured on it yet; the tab says so.

local USE_PREFIX = _G.ITEM_SPELL_TRIGGER_ONUSE or "Use:"

--- Raw tooltip text still carries Blizzard's |4singular:plural; escapes
--- ("1 |4hour:hrs;", measured 2026-09-28). Resolve them against the number
--- that precedes them; any left over take the plural.
local function Grammar(text)
    text = text:gsub("(%d+)(%s*)|4([^:;]*):([^;]*);", function(n, gap, one, many)
        return n .. gap .. ((tonumber(n) == 1) and one or many)
    end)
    return (text:gsub("|4([^:;]*):([^;]*);", "%2"))
end

--- The item's "Use:" text without its prefix, or nil.
local function UseText(lines)
    for _, raw in ipairs(lines or {}) do
        local t = Plain(raw)
        if t and t:sub(1, #USE_PREFIX) == USE_PREFIX then
            return U.Trim(Grammar(t:sub(#USE_PREFIX + 1)))
        end
    end
    return nil
end

local STAT_KEY = {
    strength = "STR", agility = "AGI", stamina = "STA",
    intellect = "INT", spirit = "SPI", armor = "ARMOR", armour = "ARMOR",
}

--- { stat, amount, duration, targeted } from a Use: line, or nil when the
--- effect is not a flat stat bonus (Confuse Beast, imbues, familiars' extras).
--- "targeted" = the standard scroll wording ("Increases the target's X"),
--- which in Classic Era shares a buff slot with the matching class buff.
local function ParseEffect(use)
    if not use then return nil end
    local l = string.lower(use)
    local word, amount = l:match("increases?[^%d]-%f[%a](%a+) by (%d+)")
    local stat = word and STAT_KEY[word]
    if not stat then return nil end
    local dn, du = l:match("for (%d+) (%a+)")
    return {
        stat     = stat,
        amount   = tonumber(amount),
        duration = dn and (dn .. " " .. du) or nil,
        targeted = l:find("the target's", 1, true) ~= nil,
    }
end

-- Classic Era conversions, by class token.
local MANA_CLASS = { MAGE = true, PRIEST = true, WARLOCK = true, DRUID = true,
                     SHAMAN = true, PALADIN = true, HUNTER = true }
local STR_TO_AP  = { WARRIOR = 2, PALADIN = 2, SHAMAN = 2, DRUID = 2, ROGUE = 1, HUNTER = 1 }
local SPI_DIV    = { MAGE = 4, PRIEST = 4 }     -- mana per 2 s tick = Spirit / 4; others / 5
local AGI_MAIN   = { ROGUE = true, HUNTER = true, WARRIOR = true, DRUID = true,
                     SHAMAN = true, PALADIN = true }

--- Physical damage reduction for `armor` against an attacker of `level`.
local function ArmorDR(armor, level)
    local k = (level < 60) and (400 + 85 * level) or (467.5 * level - 22167.5)
    return armor / (armor + k)
end

--- What `effect` is worth to the player's class.
--- @return string text, boolean useful, string|nil betterFor
local function Benefit(effect, token)
    local n, st = effect.amount or 0, effect.stat
    if st == "INT" then
        if MANA_CLASS[token] then
            return string.format("+%d maximum mana (15 per Intellect)", n * 15), true
        end
        return "No benefit: your class has no mana", false, "mana users (Mage, Priest, Warlock, Druid, Shaman, Paladin, Hunter)"
    elseif st == "SPI" then
        if MANA_CLASS[token] then
            local div = SPI_DIV[token] or 5
            return string.format("+%.2f mana every 2 s while not casting (Spirit / %d)", n / div, div), true
        end
        return "Minor: faster out-of-combat health regen only", false, "mana users"
    elseif st == "STA" then
        return string.format("+%d maximum health (10 per Stamina)", n * 10), true
    elseif st == "STR" then
        local per = STR_TO_AP[token]
        if per then
            local ap = n * per
            return string.format("+%d attack power (about +%.1f melee DPS)", ap, ap / 14), true
        end
        return "No benefit for your class: Strength only adds melee attack power", false, "Warrior, Paladin, Shaman, Druid"
    elseif st == "AGI" then
        if AGI_MAIN[token] then
            return string.format("+%d armor, plus crit and dodge", n * 2), true
        end
        return string.format("Minor: +%d armor and a little dodge", n * 2), false, "Rogue, Hunter, Warrior"
    elseif st == "ARMOR" then
        local _, eff = Try(UnitArmor, "player")
        local armor = U.SafeNum(eff, 0)
        local level = U.SafeNum(Try(UnitLevel, "player"), 1)
        local before, after = ArmorDR(armor, level), ArmorDR(armor + n, level)
        return string.format("Physical damage taken from a level %d mob: %.1f%% -> %.1f%% reduction (armor %d -> %d)",
            level, before * 100, after * 100, armor, armor + n), true
    end
    return nil, true
end

-- Class buffs that overwrite the standard scroll of the same stat (Classic Era
-- rule). First-rank spell IDs; names are read from the client, so the check
-- works in any locale.
local OVERRIDDEN_BY = { INT = 1459, STA = 1243, SPI = 14752 }

--- Why this scroll would be wasted on you right now, or nil.
local function Overlap(effect)
    if not (effect and effect.targeted) then return nil end
    local id = OVERRIDDEN_BY[effect.stat]
    if not id then return nil end
    local name = TA.Compat and TA.Compat.GetSpellName and Try(TA.Compat.GetSpellName, id)
    if not name or U.IsSecret(name) then return nil end
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        for i = 1, 40 do
            local aura = Try(C_UnitAuras.GetBuffDataByIndex, "player", i)
            if type(aura) ~= "table" then break end
            if aura.name and not U.IsSecret(aura.name) and aura.name == name then
                return string.format("Your %s is active and overrides this scroll", name)
            end
        end
    end
    if TA.Compat and TA.Compat.IsSpellKnown and Try(TA.Compat.IsSpellKnown, id) then
        return string.format("You cast %s yourself, and it overrides this scroll", name)
    end
    return nil
end

-- ─── BAG SCAN ──────────────────────────────────────────────────────────────

local function IsScrollName(name)
    if not name then return false end
    -- English only: there is no localized global for the word "Scroll".
    -- Non-English clients still see every Comprehension-gated or
    -- class-restricted scroll; only unrestricted ones are missed.
    return string.lower(name):find(SCROLL_WORD_EN, 1, true) ~= nil
end

local function IsEquipment(link)
    if not (C_Item and C_Item.GetItemInfoInstant) then return false end
    local ok, _, _, _, equipLoc = pcall(C_Item.GetItemInfoInstant, link)
    if not ok or type(equipLoc) ~= "string" then return false end
    -- Modern clients report consumables as INVTYPE_NON_EQUIP_IGNORE, not "".
    return equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE"
end

local function StackCount(bag, slot)
    local a, b = U.GetContainerItemInfo(bag, slot)
    if type(a) == "table" then return U.SafeNum(a.stackCount, 1) end
    return U.SafeNum(b, 1)
end

-- Classification per item link. An item's tooltip rules do not change, so a
-- bag refresh after the first costs one table lookup per slot, not a tooltip
-- scan. Bounded: wiped past CACHE_MAX links.
local CACHE_MAX = 500
local cache, cacheSize = {}, 0

--- @return table|nil { keep, name, info } or nil if the item is not cached yet
--- Tooltip lines from the client's structured tooltip data. This is what the
--- Mainline API renders tooltips from, so it carries the Classes: and Requires
--- lines exactly as shown -- no hidden frame, nothing drawn, nothing tainted.
local function DataLines(link)
    if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local lines = {}
    for _, ln in ipairs(data.lines) do
        if type(ln) == "table" and ln.leftText and not U.IsSecret(ln.leftText) then
            lines[#lines + 1] = ln.leftText
        end
    end
    return lines
end

function M:Lookup(link, scan)
    local c = cache[link]
    if c then return c end
    local lines = DataLines(link)
    local cached = lines ~= nil and #lines > 1
    if not cached then
        if not (scan and scan.ReadLines) then return nil end
        lines, cached = scan:ReadLines(link)
    end
    if not cached then return nil end

    local info = M.Classify(lines)
    local name = Plain(lines[1]) or link
    local use  = UseText(lines)
    c = {
        name   = name,
        info   = info,
        use    = use,
        effect = ParseEffect(use),
        keep = info.decipher
            or (info.classes ~= nil and not IsEquipment(link))
            or IsScrollName(name),
    }
    if cacheSize >= CACHE_MAX then cache, cacheSize = {}, 0 end
    cache[link] = c
    cacheSize = cacheSize + 1
    return c
end

--- Walk the bags and classify every scroll-like item.
--- @return table entries, number uncached
function M:ScanBags()
    local byLink, order, uncached = {}, {}, 0
    local lastBag = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or MAX_BAG_FALLBACK
    local scan = TA.TooltipScan

    for bag = 0, lastBag do
        local slots = U.SafeNum(U.GetContainerNumSlots(bag), 0)
        for slot = 1, slots do
            local link = U.GetContainerItemLink(bag, slot)
            if link and not U.IsSecret(link) then
                local entry = byLink[link]
                if entry then
                    entry.count = entry.count + StackCount(bag, slot)
                else
                    local c = self:Lookup(link, scan)
                    if not c then
                        uncached = uncached + 1
                        if U.RequestItemInfo then pcall(U.RequestItemInfo, link) end
                    elseif c.keep then
                        entry = { link = link, name = c.name, info = c.info, count = StackCount(bag, slot),
                                  use = c.use, effect = c.effect }
                        byLink[link] = entry
                        order[#order + 1] = entry
                    end
                end
            end
        end
    end

    table.sort(order, function(a, b) return a.name < b.name end)
    return order, uncached
end

-- ─── TOOLTIP LINE ──────────────────────────────────────────────────────────
-- Adds one "ToonAge:" line to item tooltips. Reads the tooltip's own lines, so
-- no second scan and no recursion through the hidden scanner tooltip.

local HOOKED_TOOLTIPS = { GameTooltip = true, ItemRefTooltip = true }

local function TooltipLines(tooltip, data)
    local lines = {}
    if type(data) == "table" and type(data.lines) == "table" then
        for _, ln in ipairs(data.lines) do
            if type(ln) == "table" and ln.leftText then lines[#lines + 1] = ln.leftText end
        end
        if #lines > 0 then return lines end
    end
    local name = tooltip.GetName and tooltip:GetName()
    if not name then return lines end
    for i = 1, (tooltip:NumLines() or 0) do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if t then lines[#lines + 1] = t end
    end
    return lines
end

local function OnItemTooltip(tooltip, data)
    if not M._tooltipOn then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local tname = tooltip and tooltip.GetName and tooltip:GetName()
    if not (tname and HOOKED_TOOLTIPS[tname]) then return end

    local info = M.Classify(TooltipLines(tooltip, data))
    if not (info.decipher or info.classes) then return end

    local verdict, status = Verdict(info, (PlayerComprehension()))
    local c = (L or TA.Layout) and (L or TA.Layout).STATUS[status]
    local r, g, b = 0.9, 0.9, 0.9
    if c then r, g, b = c[1], c[2], c[3] end
    tooltip:AddLine("ToonAge: " .. ClassesText(info) .. " -- " .. verdict, r, g, b, true)
end

local function HookTooltips()
    if M._hooked then return end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            local ok, err = pcall(OnItemTooltip, tooltip, data)
            if not ok and TA.ErrorLog then TA.ErrorLog:Log("ForeverScrolls tooltip", tostring(err), "") end
        end)
        M._hooked = "TooltipDataProcessor"
    elseif GameTooltip and GameTooltip.HookScript then
        for tname in pairs(HOOKED_TOOLTIPS) do
            local tip = _G[tname]
            if tip and tip.HookScript then
                pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self)
                    local ok, err = pcall(OnItemTooltip, self, nil)
                    if not ok and TA.ErrorLog then TA.ErrorLog:Log("ForeverScrolls tooltip", tostring(err), "") end
                end)
            end
        end
        M._hooked = "OnTooltipSetItem"
    end
end

-- ─── RENDER ────────────────────────────────────────────────────────────────

local VERDICT_COLOUR = { good = U.GREEN, warn = U.ORANGE, bad = U.RED }

local function Section(content, y, title, subtitle, entries, myRank)
    if #entries == 0 then return y end
    y = L:SectionHeader(content, y, title, subtitle)
    local _, token = PlayerClass()
    for _, e in ipairs(entries) do
        local verdict, status = Verdict(e.info, myRank)

        -- What it does, and what that is worth to THIS character.
        local benefit, useful, betterFor
        if e.effect and PlayerAllowed(e.info) and not e.info.decipher then
            benefit, useful, betterFor = Benefit(e.effect, token)
            if useful == false then
                verdict = "No real benefit for your class"
                    .. (betterFor and (" -- better for " .. betterFor) or "")
                status = "warn"
            end
        end
        local overlap = PlayerAllowed(e.info) and Overlap(e.effect) or nil
        if overlap then status = "warn" end

        local label = e.link
        if e.count and e.count > 1 then label = label .. "  x" .. e.count end
        y = L:DataRow(content, y, {
            label   = label,
            value   = ClassesText(e.info),
            note    = (VERDICT_COLOUR[status] or "") .. verdict .. "|r",
            tooltip = e.use and { e.use } or nil,
            tooltipTitle = e.name,
        })
        if e.use then
            y = L:Paragraph(content, y, "Does: " .. e.use, { size = 9, gap = 1 })
        end
        if benefit then
            y = L:Paragraph(content, y, "For you: " .. benefit,
                { size = 9, gap = 1, color = useful and L.C_SUCCESS or L.C_WARNING })
        end
        if overlap then
            y = L:Paragraph(content, y, overlap, { size = 9, gap = 1, color = L.C_WARNING })
        end
        y = L:Spacer(y, 4)
    end
    return L:Spacer(y, 6)
end

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

    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then pcall(FC.RenderSidebarPublic, FC, side) end

    local entries, uncached = self:ScanBags()
    local myRank, myMax = PlayerComprehension()

    local decipher, yours, others, anyone = {}, {}, {}, {}
    for _, e in ipairs(entries) do
        if e.info.decipher then
            decipher[#decipher + 1] = e
        elseif not e.info.classes then
            anyone[#anyone + 1] = e
        elseif PlayerAllowed(e.info) then
            yours[#yours + 1] = e
        else
            others[#others + 1] = e
        end
    end

    local y = -8
    local _, token = PlayerClass()
    -- maxSkillLevel 0 (a non-mage, or a character with no Comprehension cap)
    -- hides the skill row. An unanswered client still shows n/a for a Mage.
    if token == "MAGE" and myMax ~= 0 then
        y = L:SectionHeader(content, y, "Comprehension")
        local spellKnown = false
        if not myRank then
            local knownFn = (C_SpellBook and C_SpellBook.IsSpellKnown) or IsSpellKnown
            if type(knownFn) == "function" then
                local ok, known = pcall(knownFn, 1296017) -- Comprehend Scroll
                spellKnown = ok and known and true or false
            end
        end
        local note
        if myRank then
            note = nil
        elseif spellKnown then
            note = "Comprehend Scroll is in your spellbook. The client did not report a skill rank."
        else
            note = "The client did not report a Comprehension skill line. "
                .. "Learn Comprehend Scroll from a Mage trainer (level 6)."
        end
        y = L:DataRow(content, y, {
            label  = "Your skill",
            value  = myRank and (myMax and string.format("%d / %d", myRank, myMax) or tostring(myRank)) or "n/a",
            status = myRank and "neutral" or "dim",
            note   = note,
        })
        y = L:Spacer(y, 6)
    end

    if #entries == 0 then
        y = L:SectionHeader(content, y, "Scrolls")
        y = L:Paragraph(content, y,
            "No scrolls or class-restricted items in your bags.")
    else
        y = Section(content, y, "Mage decipher", "Undeciphered scrolls -- only a Mage with Comprehension can read them.", decipher, myRank)
        y = Section(content, y, "For your class", nil, yours, myRank)
        y = Section(content, y, "For other classes", "Trade or mail these to a character of the listed class.", others, myRank)
        y = Section(content, y, "Any class", nil, anyone, myRank)
    end

    if uncached > 0 then
        y = L:Paragraph(content, y, string.format(
            "%d item%s not cached by the client yet -- they appear here once their data loads.",
            uncached, uncached == 1 and " is" or "s are"), { color = L.C_WARNING })
    end

    y = L:Divider(content, y)
    y = L:Paragraph(content, y,
        "Read from each item's own tooltip (its Classes: and Requires lines), not from a list, "
        .. "so new scrolls classify correctly the first time you loot them. Hover any item for "
        .. "the same answer on its tooltip.", { color = L.C_DIM })
    y = L:Paragraph(content, y,
        "\"For you\" uses Classic Era conversions -- 15 mana per Intellect, 10 health per "
        .. "Stamina, 2 or 1 attack power per Strength by class, Spirit / 4 (Mage, Priest) or / 5 "
        .. "mana per 2 s, armor reduction A / (A + 400 + 85 x level). A standard scroll is "
        .. "overwritten by the matching class buff (Arcane Intellect, Power Word: Fortitude, "
        .. "Divine Spirit).", { color = L.C_DIM })
    -- Checked on this client, not assumed: see SampleConversions.
    y = L:SectionHeader(content, y, "Conversions on Forever")
    for _, c in ipairs({ { "Intellect", "INT", 15, "mana" }, { "Stamina", "STA", 10, "health" } }) do
        local text, match = ConversionLine(c[1], c[2], c[3], c[4])
        y = L:Paragraph(content, y, text,
            { color = (match == true and L.C_SUCCESS) or (match == false and L.C_WARNING) or L.C_DIM })
    end
    L:Finish(content, y)
end

-- ─── CONVERSIONS, MEASURED ON THIS CLIENT (2026-10-03) ────────────────────
-- The "For you" maths assumes Classic Era's 15 mana per Intellect and 10
-- health per Stamina. Those are checkable here, passively: out of combat,
-- UnitPowerMax(player) is a plain number (651 in the 2026-09-26 baseline),
-- and UnitStat gives effective Intellect/Stamina. Every time either stat
-- changes (gear, a scroll, a buff), the pair is recorded; two readings at the
-- same level with different stat values give the measured rate.
--   * Keyed by level: base mana/health rise with level, which would read as
--     a conversion.
--   * Talents that scale max mana/health by a percentage (Arcane Mind,
--     Fortitude-type talents) inflate the slope; the line says so.
--   * Secret or missing values are skipped, never guessed.

local CONV_MAX = 12   -- readings kept per stat per level

local function ConvStore()
    local c = TA.charDB
    if not c then return nil end
    c.convSamples = c.convSamples or { INT = {}, STA = {} }
    return c.convSamples
end

local function Readable(v)
    if v == nil or U.IsSecret(v) then return nil end
    return tonumber(v)
end

function M:SampleConversions()
    if Try(InCombatLockdown) then return end
    local st = ConvStore()
    local level = Readable(Try(UnitLevel, "player"))
    if not (st and level) then return end
    local pairsToTake = {
        { key = "INT", stat = 4, max = function() return Try(UnitPowerMax, "player", 0) end },
        { key = "STA", stat = 3, max = function() return Try(UnitHealthMax, "player") end },
    }
    for _, p in ipairs(pairsToTake) do
        local _, eff = Try(UnitStat, "player", p.stat)
        local stat, max = Readable(eff), Readable(p.max())
        if stat and max and max > 0 then
            local byLevel = st[p.key][level] or {}
            st[p.key][level] = byLevel
            byLevel[stat] = max          -- same stat value overwrites: newest wins
            local n = 0
            for _ in pairs(byLevel) do n = n + 1 end
            if n > CONV_MAX then
                local lo
                for k in pairs(byLevel) do if not lo or k < lo then lo = k end end
                byLevel[lo] = nil
            end
        end
    end
end

--- Measured points of `max` per point of stat at the current level, from the
--- two readings furthest apart. @return rate, readings, lowStat, highStat
local function MeasuredRate(key)
    local st = ConvStore()
    local level = Readable(Try(UnitLevel, "player"))
    local byLevel = st and level and st[key][level]
    if not byLevel then return nil end
    local lo, hi, n = nil, nil, 0
    for stat in pairs(byLevel) do
        n = n + 1
        -- Classic Era's first 20 points convert at 1:1; stay above them so the
        -- slope is the per-point rate, not a blend.
        if stat > 20 then
            if not lo or stat < lo then lo = stat end
            if not hi or stat > hi then hi = stat end
        end
    end
    if not (lo and hi) or lo == hi then return nil, n end
    return (byLevel[hi] - byLevel[lo]) / (hi - lo), n, lo, hi
end
M._MeasuredRate = MeasuredRate

ConversionLine = function(label, key, assumed, unit)
    local rate, n, lo, hi = MeasuredRate(key)
    if rate then
        local match = math.abs(rate - assumed) < 0.6
        return string.format("%s: measured %.1f %s per point (%s %d-%d, %d readings) -- %s",
            label, rate, unit, label, lo, hi, n,
            match and ("matches the assumed " .. assumed)
                  or ("assumed " .. assumed .. "; talents that scale max " .. unit .. " raise this")), match
    end
    return string.format("%s: not measured yet -- changes when your %s changes out of combat "
        .. "(equip or remove an item with it, or use a scroll).", label, label), nil
end

-- ─── LIFECYCLE ─────────────────────────────────────────────────────────────

function M:Init()
    -- Retail loads this file too through the shared Mainline TOC. The tab is
    -- Forever's, and so is the tooltip line.
    if not TA.IsForever then
        self._disabled = true
        return
    end
    -- The item-tooltip line stays OFF until the 2026-09-27 blocked-action
    -- popup is traced (Logs\\taint.log). The tab reads tooltip DATA and draws
    -- only into its own frames, so it cannot be the source.
    self._tooltipOn = false
    C_Timer.After(3, function() pcall(self.SampleConversions, self) end)
end

function M:OnEvent(event, unit)
    if (event == "UNIT_STATS" or event == "UNIT_MAXPOWER" or event == "UNIT_MAXHEALTH")
       and unit == "player" then
        -- Coalesce: equipping fires all three; read once after they settle.
        if self._convPending then return end
        self._convPending = true
        C_Timer.After(0.5, function()
            self._convPending = nil
            pcall(self.SampleConversions, self)
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        pcall(self.SampleConversions, self)
    end
end

M.Events = { "UNIT_STATS", "UNIT_MAXPOWER", "UNIT_MAXHEALTH", "PLAYER_REGEN_ENABLED" }

return M
