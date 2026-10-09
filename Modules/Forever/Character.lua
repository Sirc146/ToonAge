-- ToonAge/Modules/Forever/Character.lua  (WoW Forever — Mainline API, Vanilla content)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS, AND WHAT IT REFUSES TO DO ───────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Forever is Vanilla-era content on Midnight's API. There is no researched
-- Data/Forever yet, so no module here may score gear, rank stats, suggest
-- talents or name a rotation: every one of those needs numbers nobody has
-- verified for this game.
--
-- What CAN be shipped honestly today is a readout. Everything below is a value
-- the client itself reports about your character — level, attributes, armour,
-- resistances, professions. No weights, no thresholds, no "you should".
-- Observed facts, not advice, which is why this can exist before the data does.
--
-- Confirmed against the beta client's own character sheet (Docs/FOREVER_BRIEF):
--   * Primary attributes are Strength, Agility, Stamina, Intellect, SPIRIT.
--   * Crit is a flat percentage. No mastery, no versatility, no ratings.
--   * Defense is a capped SKILL ("13 / 15"), and armour and dodge sit with it.
--   * Resistances are Arcane / Fire / Frost / Nature / Shadow. No Holy.
--   * Professions are two primaries plus Cooking, Fishing and FIRST AID.
--
-- Forever is a CUSTOM realm, not real 1.60. Its combat model differs from the
-- Vanilla labels the character sheet still uses: Hit is one combined stat
-- (melee/ranged/spell folded together), Crit is likewise one combined stat,
-- Expertise exists (it did not in Vanilla), and healing power grants a third
-- of its value as bonus spell damage. The Offense section flags this inline so
-- the client's per-school crit lines are not read as how Forever totals them.
--
-- Every read goes through Try(), which returns nil when the API is absent
-- rather than 0. A stat this client cannot answer is shown as "n/a", because
-- zero is a claim and it would be a false one — the same rule the TBC module
-- follows. That matters more here than anywhere else: this client's API set is
-- only partly mapped, so "no answer" is a likely outcome, not an edge case.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils
local L                       -- resolved at render; see M:Render

local M = {}
-- Registered under its OWN name, not "Character". Retail loads this file too
-- (Forever picks the Mainline TOC, so both Character modules ship in it), and
-- TA:RegisterModule is a flat overwrite that runs at FILE LOAD -- before the
-- profile gate has any say. Sharing the name meant whichever file the TOC
-- listed last won, which was this one: Retail's own Character tab was being
-- silently replaced by the Forever readout. The profile picks the tab's module
-- by name, so distinct names settle it with no ordering dependency at all.
TA:RegisterModule("ForeverCharacter", M)

-- ─── READS ───────────────────────────────────────────────────────────────

--- Call an API that may not exist on this client. nil means "no answer".
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

-- MEASURED on this client, 2026-09-23, mid-combat:
--     UnitHealth("player") -> 307, issecretvalue(that) -> TRUE
--     C_Spell.GetSpellCooldown(133).duration -> issecretvalue -> false
-- So health and power really are secret values in combat here, while cooldowns
-- are not. A secret cannot be compared, converted with tonumber, used in
-- arithmetic or used as a table key -- every one of those RAISES. It can be
-- passed to SetText, which is why the number still renders on screen.
--
-- Num is the choke point every read in this file passes through, so the guard
-- lives here: a secret becomes nil, which every caller already handles as
-- "n/a". Without it, opening this tab in combat threw on `hp >= hpMax`.
local isSecret = _G.issecretvalue or function() return false end

local function Num(v)
    if v == nil then return nil end
    if isSecret(v) then return nil end
    local n = tonumber(tostring(v))
    return n
end

-- MEASURED THE HARD WAY, 2026-09-23. tostring() on a secret survives and the
-- number appears on screen -- but the STRING IS STILL SECRET, and a FontString
-- holding one makes the frame's measured height secret too. The scroll child's
-- height then feeds Blizzard's own SecureScrollTemplates, which does arithmetic
-- on it and raises:
--
--   SecureScrollTemplates.lua:140: attempt to perform arithmetic on a secret
--   number value (execution tainted by 'ToonAge')
--
-- The error lands in BLIZZARD code with ToonAge named as the taint source, and
-- it kills the whole tab render -- which is how showing a secret health value
-- blanked every bar on the Character tab.
--
-- So a secret is never displayed, never measured, never concatenated. The row
-- says what is true -- that the client is withholding it -- in a plain string
-- of our own.
local HIDDEN_TEXT = "—"
local HIDDEN_FOOTNOTE = "Health and mana are secret in combat, so those rows show a dash until you leave combat."

--- "n/a" for a missing answer, the formatted number otherwise.
local function Show(value, fmt)
    if value == nil then return "|cFF6E6A62n/a|r" end
    return string.format(fmt or "%d", value)
end

local STAT_ORDER = { "STR", "AGI", "STA", "INT", "SPI" }
local STAT_INDEX = { STR = 1, AGI = 2, STA = 3, INT = 4, SPI = 5 }
local STAT_NAMES = {
    STR = "Strength",  AGI = "Agility", STA = "Stamina",
    INT = "Intellect", SPI = "Spirit",
}

local function ReadStat(key)
    local idx = STAT_INDEX[key]
    if not idx or type(UnitStat) ~= "function" then return nil, nil end
    local ok, base, effective = pcall(UnitStat, "player", idx)
    if not ok then return nil, nil end
    return Num(effective), Num(base)
end

-- Resistance indices: 1 is physical (armour), 2-6 are the five magic schools.
local RESIST_ORDER = {
    { index = 2, name = "Arcane" },
    { index = 3, name = "Fire"   },
    { index = 4, name = "Frost"  },
    { index = 5, name = "Nature" },
    { index = 6, name = "Shadow" },
}

-- ─── SKILL LINES ─────────────────────────────────────────────────────────
--
-- MEASURED on Forever 1.60.1 (interface 16001), level 1 Rogue, 2026-10-09:
--   UnitAttackBothHands / UnitRangedAttack / UnitDefense -> MISSING.
--   UnitDefenseSkill("player") works.
--   C_SkillInfo.GetNumSkillLines / GetSkillLineInfo / GetSkillLineInfoByID
--     answer rank and maxRank. maxRank is 5 per level.
--   GetSkillLineInfoByID returns nil for a skill the character does not have.
--     That nil is "absent", not rank 0.
--   category 6 = Weapon Skills (Defense, skillID 95, lives here too),
--     7 = class lines, 8 = armour, 10 = languages.
--   Class lines Combat (38) and Assassination (253) are already listed at
--   level 1. They are spellbook tabs, not a chosen spec, and not weapon skills.
-- The legacy globals are kept as a fallback for any client that has them.

local CAT_WEAPON = 6
local SKILL_DEFENSE = 95
-- Class skill lines present on a level 1 Rogue. Not weapon skills, and not a spec.
local CLASS_SKILL_LINE = { [38] = true, [253] = true }

--- Forever weapon and Defense caps are 5 skill points per level.
local function LevelSkillCap()
    local level = Num(Try(UnitLevel, "player")) or 1
    if level < 1 then level = 1 end
    return level * 5
end

--- Every skill line as { name, rank, max, mod, id, cat, header }.
local function ReadSkillLines()
    local out = {}
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo then
        local n = Num(Try(C_SkillInfo.GetNumSkillLines)) or 0
        for i = 1, n do
            local info = Try(C_SkillInfo.GetSkillLineInfo, i)
            if type(info) == "table" and info.name then
                local rank, max = Num(info.rank), Num(info.maxRank)
                if rank and (not max or max <= 0) then max = LevelSkillCap() end
                out[#out + 1] = {
                    name = tostring(info.name), rank = rank, max = max,
                    mod = Num(info.modifier) or 0, id = Num(info.skillID),
                    cat = Num(info.skillLineCategoryID), header = info.isHeader and true or false,
                }
            end
        end
        if #out > 0 then return out end
    end
    if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
        local n = Num(Try(GetNumSkillLines)) or 0
        local cat
        for i = 1, n do
            local name, isHeader, _, rank, _, mod, maxRank = Try(GetSkillLineInfo, i)
            if name then
                -- Legacy has no category IDs; the header name stands in.
                if isHeader then cat = (tostring(name):find("Weapon") and CAT_WEAPON) or 0 end
                out[#out + 1] = { name = tostring(name), rank = Num(rank), max = Num(maxRank),
                    mod = Num(mod) or 0, cat = cat, header = isHeader and true or false }
            end
        end
    end
    return out
end
M._ReadSkillLines = ReadSkillLines

-- Weapon item subclass (Enum.ItemWeaponSubclass) -> the weapon SKILL it uses.
-- These pairings are the game's own and have not changed since Vanilla.
local WEAPON_SKILL_BY_SUBCLASS = {
    [0]  = 44,   -- One-Handed Axes
    [1]  = 172,  -- Two-Handed Axes
    [2]  = 45,   -- Bows
    [3]  = 46,   -- Guns
    [4]  = 54,   -- One-Handed Maces
    [5]  = 160,  -- Two-Handed Maces
    [6]  = 229,  -- Polearms
    [7]  = 43,   -- One-Handed Swords
    [8]  = 55,   -- Two-Handed Swords
    [10] = 136,  -- Staves
    [13] = 473,  -- Fist Weapons
    [15] = 173,  -- Daggers
    [16] = 176,  -- Thrown
    [18] = 226,  -- Crossbows
    [19] = 228,  -- Wands
}
local SKILL_UNARMED = 162
local WEAPON_CLASS_ID = 2

--- Skill ID for the weapon in an inventory slot, or Unarmed for an empty main
--- hand. nil when the slot holds no weapon we can map (a shield, a held-in-hand).
local function WeaponSkillFor(slot)
    local link = Try(GetInventoryItemLink, "player", slot)
    if not link then return (slot == 16) and SKILL_UNARMED or nil end
    local getInfo = C_Item and C_Item.GetItemInfoInstant
    if type(getInfo) ~= "function" then return nil end
    local _, _, _, _, _, classID, subClassID = Try(getInfo, link)
    if Num(classID) ~= WEAPON_CLASS_ID then return nil end
    return WEAPON_SKILL_BY_SUBCLASS[Num(subClassID) or -1]
end
M._WeaponSkillFor = WeaponSkillFor

local function FindSkill(lines, id)
    for _, l in ipairs(lines) do if l.id == id then return l end end
end

--- One skill by ID. nil when the character does not have it.
--- GetSkillLineInfoByID returns nil in that case (Forever 1.60.1). A nil
--- result is not reported as rank 0.
local function SkillByID(skillID)
    if not skillID then return nil end
    if CLASS_SKILL_LINE[skillID] then return nil end
    if C_SkillInfo and type(C_SkillInfo.GetSkillLineInfoByID) == "function" then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, skillID)
        if not ok or info == nil or type(info) ~= "table" then return nil end
        local rank, max = Num(info.rank), Num(info.maxRank)
        if rank and (not max or max <= 0) then max = LevelSkillCap() end
        if not max or max <= 0 then return nil end
        return {
            name = tostring(info.name or ""),
            rank = rank or 0,
            max = max,
            mod = Num(info.modifier) or 0,
            id = skillID,
        }
    end
    return FindSkill(ReadSkillLines(), skillID)
end

-- ─── SECTIONS ────────────────────────────────────────────────────────────

local function RenderHeadline(content, y)
    local name  = UnitName("player") or "?"
    local level = UnitLevel("player") or 0
    -- FIRST return, not the second: UnitClass and UnitRace each give the
    -- display name first and the internal token second. Reading the token
    -- printed "Level 7 Scourge MAGE" — Scourge is Undead's token and MAGE is
    -- shouted because tokens are upper case. The display names are also the
    -- localized ones, which the tokens never are.
    local class = UnitClass("player")
    local race  = UnitRace("player")

    y = L:SectionHeader(content, y, name,
        string.format("Level %d %s %s", level, tostring(race or ""), tostring(class or "")))

    -- Raw reads kept alongside the Num() ones: when a value is secret the number
    -- can still be SHOWN, just not measured against anything.
    local rawXP  = UnitXP and Try(UnitXP, "player")
    local rawXPM = UnitXPMax and Try(UnitXPMax, "player")
    local cur, max = Num(rawXP), Num(rawXPM)

    local secretNote = false
    if (not cur or not max) and rawXP ~= nil and isSecret(rawXP) then
        y = L:DataRow(content, y, {
            label = "Experience", value = HIDDEN_TEXT, status = "dim",
        })
        secretNote = true
    end

    if cur and max and max > 0 then
        local rested = Num(GetXPExhaustion and GetXPExhaustion())
        -- A bar, not a row. Experience is one of the very few things on this
        -- client with a real denominator, so a fill genuinely means something
        -- -- unlike a stat bar, which would need weights nobody has verified.
        y = L:CapBar(content, y, {
            label  = "Experience",
            value  = string.format("%d / %d  (%.0f%%)", cur, max, (cur / max) * 100),
            current = cur,
            cap     = max,
            capped  = false,
            note   = rested and rested > 0
                     and string.format("%d rested experience banked", rested) or nil,
        })
    end

    local rawHP, rawHPM = Try(UnitHealth, "player"), Try(UnitHealthMax, "player")
    local hp, hpMax = Num(rawHP), Num(rawHPM)
    if hp and hpMax and hpMax > 0 then
        y = L:CapBar(content, y, {
            label = "Health", value = string.format("%d / %d", hp, hpMax),
            current = hp, cap = hpMax, capped = hp >= hpMax,
        })
    elseif rawHP ~= nil and isSecret(rawHP) then
        y = L:DataRow(content, y, {
            label = "Health", value = HIDDEN_TEXT, status = "dim",
        })
        secretNote = true
    end

    -- Power type 0 is mana. A class without it reports 0 max, and a bar of
    -- zero out of zero says nothing -- so it simply does not draw.
    local rawMP, rawMPM = Try(UnitPower, "player", 0), Try(UnitPowerMax, "player", 0)
    local mp, mpMax = Num(rawMP), Num(rawMPM)
    if mp and mpMax and mpMax > 0 then
        y = L:CapBar(content, y, {
            label = "Mana", value = string.format("%d / %d", mp, mpMax),
            current = mp, cap = mpMax, capped = mp >= mpMax,
        })
    elseif rawMP ~= nil and isSecret(rawMP) then
        y = L:DataRow(content, y, {
            label = "Mana", value = HIDDEN_TEXT, status = "dim",
        })
        secretNote = true
    end
    if secretNote then
        y = L:Paragraph(content, y, HIDDEN_FOOTNOTE, { color = L.C_DIM, size = 9 })
    end
    return y
end

-- The scale the five attribute bars share, kept between renders so it only ever
-- grows within a session: a buff dropping must not resize the whole sheet.
local statScale

local function RenderAttributes(content, y)
    y = L:SectionHeader(content, y, "Attributes")

    -- Read every stat first -- the bars share one denominator, so the largest
    -- value has to be known before the first bar is drawn.
    local read, values = {}, {}
    for _, key in ipairs(STAT_ORDER) do
        local effective, base = ReadStat(key)
        read[key] = { effective = effective, base = base }
        values[#values + 1] = effective
    end

    statScale = L:StatScale(values, statScale)

    for _, key in ipairs(STAT_ORDER) do
        local r = read[key]
        y = L:StatBar(content, y, {
            label = STAT_NAMES[key],
            value = r.effective,
            base  = r.base,
            scale = statScale,
            text  = Show(r.effective),
        })
    end

    y = L:Paragraph(content, y,
        string.format("Bars compare your five attributes against a shared scale of %d. "
            .. "The solid part is what level and race give you; the lighter part is "
            .. "what your gear and buffs add. The number is always the real one.",
            statScale), { color = L.C_DIM })
    return y
end

-- A percentage's maximum is 100, full stop -- so crit, dodge, parry and block
-- get a TRUE denominator rather than a drawing scale. 4.20% drawing as a
-- near-empty bar is correct: it is four percent of what is possible.
local PERCENT_SCALE = 100

-- Shared drawing scales, sticky within a session like the attribute one.
local offenseScale, defenseScale, resistScale

local function RenderOffense(content, y)
    y = L:SectionHeader(content, y, "Offense")

    local base, posBuff, negBuff = Try(UnitAttackPower, "player")
    local ap = Num(base)
    if ap then ap = ap + (Num(posBuff) or 0) + (Num(negBuff) or 0) end

    local rBase, rPos, rNeg = Try(UnitRangedAttackPower, "player")
    local rap = Num(rBase)
    if rap then rap = rap + (Num(rPos) or 0) + (Num(rNeg) or 0) end

    -- Spell power is reported per school; arcane (6) stands in for "magic", the
    -- same way the character sheet does.
    local sp = Num(Try(GetSpellBonusDamage, 6))

    -- One scale for the flat numbers in this section, so attack power and spell
    -- power are comparable. Percentages stay out of it -- they have their own
    -- real maximum, and mixing the two would make 4% look like 40.
    -- Weapon skill is not on this scale: it has a real cap (5 per level) and
    -- UnitAttackBothHands, which used to stand in for it, is missing.
    offenseScale = L:StatScale({ ap, rap, sp }, offenseScale)

    y = L:StatBar(content, y, {
        label = "Attack Power", value = ap, scale = offenseScale, text = Show(ap),
    })

    if rap and rap > 0 then
        y = L:StatBar(content, y, {
            label = "Ranged Attack Power", value = rap, scale = offenseScale, text = Show(rap),
        })
    end

    local crit = Num(Try(GetCritChance))
    y = L:StatBar(content, y, {
        label = "Critical Strike", value = crit, scale = PERCENT_SCALE,
        text = Show(crit, "%.2f%%"),
    })

    if sp and sp > 0 then
        y = L:StatBar(content, y, {
            label = "Spell Power", value = sp, scale = offenseScale, text = Show(sp),
        })
        local spCrit = Num(Try(GetSpellCritChance, 6))
        y = L:StatBar(content, y, {
            label = "Spell Critical Strike", value = spCrit, scale = PERCENT_SCALE,
            text = Show(spCrit, "%.2f%%"),
        })
    end

    -- Weapon skill for what you are actually holding. Forever keeps Vanilla's
    -- capped weapon skills (5 x level), one per weapon type. UnitAttackBothHands
    -- and UnitRangedAttack are missing, so the equipped weapon's type picks its
    -- skill line out of C_SkillInfo (rank and maxRank). GetSkillLineInfoByID
    -- returns nil when the character has not trained that weapon. Below the cap
    -- means more misses and more glancing blows; it rises only by hitting
    -- things with THAT weapon type.
    local shown = {}
    for _, hand in ipairs({ { 16, "Main hand" }, { 17, "Off hand" }, { 18, "Ranged" } }) do
        local id = WeaponSkillFor(hand[1])
        local line = id and SkillByID(id)
        if line and line.rank and line.max and line.max > 0 and not shown[id] then
            shown[id] = true
            local eff = line.rank + (line.mod or 0)
            local short = line.max - line.rank
            y = L:CapBar(content, y, {
                label   = string.format("%s: %s", hand[2], line.name),
                value   = (line.mod or 0) ~= 0
                    and string.format("%d (+%d) / %d", line.rank, line.mod, line.max)
                    or  string.format("%d / %d", line.rank, line.max),
                current = math.min(eff, line.max),
                cap     = line.max,
                capped  = short <= 0,
                urgent  = short > 0 and (line.rank / line.max) < 0.75 or nil,
                note    = short > 0 and string.format(
                    "%d below the cap for your level -- fight with this weapon type to raise it",
                    short) or nil,
            })
        end
    end

    -- Forever is a custom realm, not real 1.60. Its combat stats do not map
    -- one-to-one onto the character sheet's Vanilla-era labels, so spell this
    -- out rather than let the numbers above imply plain Vanilla behaviour.
    y = L:Paragraph(content, y,
        "Forever note: this realm folds melee, ranged and spell Hit into a "
        .. "single Hit stat, and likewise a single Crit stat, so the separate "
        .. "crit lines above are the client's Vanilla view, not how Forever "
        .. "totals them. Forever also uses Expertise (absent in real Vanilla) "
        .. "and grants a third of healing power as bonus spell damage. Weapon "
        .. "skill still matters and is weapon-type specific.",
        { color = L.C_DIM })
    return y
end

local function RenderDefense(content, y)
    y = L:SectionHeader(content, y, "Defense")

    local armorBase, armorEff = Try(UnitArmor, "player")
    local armor = Num(armorEff) or Num(armorBase)

    -- UnitDefense is missing. Defense rank and cap come from C_SkillInfo
    -- (skill 95, maxRank = 5 per level). GetSkillLineInfoByID nil means this
    -- character has no Defense line -- that is not a rank of 0. UnitDefenseSkill
    -- still answers and is only the fallback when C_SkillInfo itself is absent.
    local defLine = SkillByID(SKILL_DEFENSE)
    local defBase, defMod, defCap, defTotal
    if defLine then
        defBase, defMod, defCap = defLine.rank, defLine.mod, defLine.max
        defTotal = (defBase or 0) + (defMod or 0)
    elseif not (C_SkillInfo and type(C_SkillInfo.GetSkillLineInfoByID) == "function") then
        defBase, defMod = Try(UnitDefenseSkill, "player")
        defBase, defMod = Num(defBase), Num(defMod)
        if defBase then defTotal = defBase + (defMod or 0) end
    end

    defenseScale = L:StatScale({ armor, defTotal }, defenseScale)

    -- Armour's REAL cap is 75% physical reduction, roughly 17265 against a raid
    -- boss at 60 -- useless as a denominator at low level, where a few hundred
    -- armour already mitigates a lot against a same-level mob. The conversion is
    -- level-dependent and unverified on this client, so the bar uses the
    -- section's drawing scale and the ceiling is stated rather than pretended.
    y = L:StatBar(content, y, {
        label = "Armor", value = armor, scale = defenseScale, text = Show(armor),
    })

    if defTotal and defCap and defCap > 0 then
        local base = Num(defBase) or defTotal
        local short = defCap - base
        y = L:CapBar(content, y, {
            label   = "Defense Skill",
            value   = (Num(defMod) or 0) ~= 0
                and string.format("%d (+%d) / %d", base, Num(defMod), defCap)
                or  string.format("%d / %d", base, defCap),
            current = math.min(defTotal, defCap),
            cap     = defCap,
            capped  = short <= 0,
            urgent  = short > 0 and (base / defCap) < 0.75 or nil,
            note    = short > 0 and string.format(
                "%d below the cap for your level -- it rises by being hit", short) or nil,
        })
    elseif defTotal then
        y = L:StatBar(content, y, {
            label = "Defense Skill", value = defTotal, scale = defenseScale,
            text  = Show(defTotal),
        })
    end

    local dodge = Num(Try(GetDodgeChance))
    y = L:StatBar(content, y, {
        label = "Dodge", value = dodge, scale = PERCENT_SCALE,
        text  = Show(dodge, "%.2f%%"),
    })

    local parry = Num(Try(GetParryChance))
    if parry and parry > 0 then
        y = L:StatBar(content, y, {
            label = "Parry", value = parry, scale = PERCENT_SCALE, text = Show(parry, "%.2f%%"),
        })
    end
    local block = Num(Try(GetBlockChance))
    if block and block > 0 then
        y = L:StatBar(content, y, {
            label = "Block", value = block, scale = PERCENT_SCALE, text = Show(block, "%.2f%%"),
        })
    end

    y = L:Paragraph(content, y,
        "Armour caps at 75% physical reduction -- around 17265 against a raid "
        .. "boss at 60. The bar above is a comparison, not progress toward that: "
        .. "the level-by-level conversion has not been verified on this client, "
        .. "so it is not used as a denominator.", { color = L.C_DIM })
    return y
end

local function RenderResistances(content, y)
    y = L:SectionHeader(content, y, "Resistances")

    local values, read = {}, {}
    for _, school in ipairs(RESIST_ORDER) do
        local base, total = Try(UnitResistance, "player", school.index)
        local v = Num(total) or Num(base)
        read[school.name] = v
        values[#values + 1] = v
    end

    resistScale = L:StatScale(values, resistScale)

    for _, school in ipairs(RESIST_ORDER) do
        local v = read[school.name]
        y = L:StatBar(content, y, {
            label = school.name, value = v, scale = resistScale, text = Show(v),
        })
    end
    return y
end

local function RenderProfessions(content, y)
    if type(GetProfessions) ~= "function" then return y end

    -- Retail's GetProfessions returns six slots in a fixed order: two
    -- primaries, archaeology, fishing, cooking, first aid. Forever does NOT
    -- return them in that order — a character with Tailoring, Enchanting,
    -- Cooking and First Aid came back with First Aid sitting in the slot
    -- Retail uses for archaeology, so a positional label printed
    -- "Archaeology: First Aid".
    --
    -- So the position is only used to say "this is your first/second primary".
    -- Everything else is labelled with the name the CLIENT gives for that
    -- skill line, which is right whatever order this game returns them in and
    -- in whatever language the player runs.
    local slots = { Try(GetProfessions) }
    if #slots == 0 then return y end

    y = L:SectionHeader(content, y, "Professions")
    local printed = {}
    for i, slot in ipairs(slots) do
        if slot then
            local name, _, rank, maxRank = Try(GetProfessionInfo, slot)
            rank, maxRank = Num(rank), Num(maxRank)
            local label
            if i <= 2 then
                label = (i == 1) and "First Profession" or "Second Profession"
            else
                label = "Secondary"
            end
            printed[tostring(name or "")] = true
            -- A profession HAS a real denominator -- the client reports the cap
            -- for the skill -- so this is a true progress bar, not a scaled
            -- comparison. Coloured per profession where the name is one we know;
            -- an unrecognised or localised name falls back to neutral rather
            -- than to a wrong colour.
            y = L:StatBar(content, y, {
                label = tostring(name or ("Slot " .. i)),
                value = rank,
                scale = maxRank,
                color = L:ProfessionColor(name),
                text  = string.format("%s / %s", Show(rank), Show(maxRank)),
            })
        end
    end
    return y, printed
end

--- Weapon skills, Defense, and anything else the client tracks as a skill line.
---
--- The beta's own character sheet shows "Defense 13 / 15", but UnitDefense()
--- returned nothing on this client, so that row never appeared on our tab. The
--- Vanilla-era skills API is the other way in: GetNumSkillLines/GetSkillLineInfo
--- walk the skill book, which is where weapon skills and Defense actually live
--- on a game with capped skills.
---
--- Professions are skill lines too, so they are filtered out — they have their
--- own section above, with ranks.
local function RenderSkills(content, y, professionNames)
    local rows = {}
    for _, l in ipairs(ReadSkillLines()) do
        -- Weapon skills only: armour and languages are 1/1 or 300/300 and say
        -- nothing, class lines are spellbook tabs (Combat 38, Assassination 253
        -- are already there at level 1 and are not a chosen spec), and Defense
        -- has its own row.
        if not l.header and l.cat == CAT_WEAPON and l.id ~= SKILL_DEFENSE
           and not CLASS_SKILL_LINE[l.id]
           and l.rank and l.max and l.max > 0 and not professionNames[l.name] then
            rows[#rows + 1] = l
        end
    end
    if #rows == 0 then return y end
    table.sort(rows, function(a, b) return a.name < b.name end)

    y = L:SectionHeader(content, y, "Weapon Skills",
        "Every weapon type you can train. Each rises only by fighting with it.")
    for _, row in ipairs(rows) do
        -- A skill sitting below its cap for your level is the one thing on this
        -- tab worth acting on, and it needs no researched data to say: the cap
        -- is whatever the client reports.
        local short = row.max - row.rank
        y = L:CapBar(content, y, {
            label   = row.name,
            value   = string.format("%d / %d", row.rank, row.max),
            current = row.rank,
            cap     = row.max,
            capped  = short == 0,
            urgent  = short > 0 and (row.rank / row.max) < 0.75 or nil,
            note    = short > 0 and string.format("%d below the cap for your level", short) or nil,
        })
    end
    return y
end

local function RenderFooter(content, y)
    y = L:SectionHeader(content, y, "Not here yet")
    y = L:Paragraph(content, y,
        "Gear scoring, rotations, talents and profession advice need numbers "
        .. "researched for this game specifically. Vanilla's are close but not "
        .. "identical, and Midnight's are wrong outright, so ToonAge shows you "
        .. "what your character IS and stays quiet about what to do until those "
        .. "numbers exist.")
    y = L:Paragraph(content, y,
        "Anything reading n/a means this client did not answer that call — worth "
        .. "reporting, since it maps what the API actually exposes here.")
    return y
end

-- ─── RENDER ──────────────────────────────────────────────────────────────

--- The left column: who this character is.
---
--- Deliberately NOT L:CharacterSidebar, even though that lives in the shared
--- Core/Layout.lua this file already draws through. That component calls
--- U.GetPlayerClassLocalized, U.GetPlayerRace and U.GetSpecLabel, all three of
--- which are defined in Core/TBCUtils.lua -- a file only the TBC TOC ships. On
--- this client they are nil, so the "shared" component throws. Until that is
--- untangled, this reads the same facts through Try() like everything else
--- here.
-- Tracks the 3D model so it can be torn down when the tab is left. A
-- PlayerModel is a real frame; recreating one on every tab-open without hiding
-- the old one stacks invisible models and leaks them.
M._sideFrames = M._sideFrames or {}

--- The left column: who this character is, over a live 3D portrait.
---
--- This is the one place the Forever tab reaches for the retail look on
--- purpose. Retail's Character sidebar is a PlayerModel with the identity text
--- laid over a bottom gradient, and that is most of why that tab reads as
--- finished. PlayerModel / SetUnit are unprotected and exist on every client
--- (they are not in the disarmament set), so the portrait itself is safe here.
---
--- Still deliberately NOT L:CharacterSidebar: that shared component calls
--- U.GetPlayerClassLocalized / U.GetPlayerRace / U.GetSpecLabel, all defined in
--- Core/TBCUtils.lua which only the TBC TOC ships. On this client they are nil
--- and the component throws, so the text is read here through Try() as before —
--- only now it is drawn over the model.
local MODEL_H = 210   -- portrait height; caption sits under it
local CAPTION_LINES = 5

--- Built ONCE and reused on every render (2026-10-03). The old version created
--- a PlayerModel, a fade texture, five caption FontStrings and an OnHide hook
--- on every redraw of seven tabs: the model was orphaned by RebuildChild
--- (the self-test's "1.0 frames discarded per re-render"), and the strings and
--- hooks piled up on the pooled scroll child, which the self-test can't see.
--- One holder frame now owns all of it and is re-parented to whichever
--- sidebar child is current. _laKind marks it as reused for the self-test's
--- leak counter; Layout never pools it (it is not in any pane's _laUsed).
local function SidebarHolder()
    if M._sideHolder then return M._sideHolder end
    local h = CreateFrame("Frame")
    h._laKind = "ForeverSidebar"

    -- Guarded: if PlayerModel is unavailable the sidebar is text-only.
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, h)
    if ok and m then
        m:SetPoint("TOPLEFT",  h, "TOPLEFT",  0, 0)
        m:SetPoint("TOPRIGHT", h, "TOPRIGHT", 0, 0)
        m:SetHeight(MODEL_H)
        -- Soft fade at the very bottom of the model so it blends into the
        -- caption area rather than cutting off hard at the feet.
        if m.CreateTexture and CreateColor then
            local fade = m:CreateTexture(nil, "OVERLAY")
            fade:SetPoint("BOTTOMLEFT",  m, "BOTTOMLEFT",  0, 0)
            fade:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 0, 0)
            fade:SetHeight(60)
            pcall(fade.SetGradient, fade, "VERTICAL",
                CreateColor(0.05, 0.05, 0.06, 0),
                CreateColor(0.05, 0.05, 0.06, 0.95))
        end
        h.model = m
    end

    h.lines = {}
    for i = 1, CAPTION_LINES do
        local fs = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        fs:SetJustifyH("CENTER")
        h.lines[i] = fs
    end
    M._sideHolder = h
    return h
end

--- The holder is re-parented, not re-created; the PlayerModel's unit and
--- camera are re-applied each time because a model that was hidden or moved
--- can come back blank.
local function RenderSidebar(side)
    if not side then return end
    local h = SidebarHolder()
    local w = math.max((side:GetWidth() or 202) - 20, 40)

    h:SetParent(side)
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", side, "TOPLEFT", 0, 0)
    h:SetPoint("TOPRIGHT", side, "TOPRIGHT", 0, 0)
    h:Show()

    local model = h.model
    if model then
        model:Show()
        pcall(model.SetUnit, model, "player")
        pcall(model.SetAnimation, model, 0)
        pcall(model.SetCamDistanceScale, model, 1.10)
        pcall(model.SetFacing, model, math.pi / 8)
    end

    -- ── Identity caption, centered, below the model ───────────────────
    -- Name, level/class, race, item level, gold, in reading order.
    -- First return of UnitClass/UnitRace is the localized display name; the
    -- second is the token, which printed "Scourge MAGE" when read by mistake.
    local class = Try(UnitClass, "player")
    local race  = Try(UnitRace, "player")
    local level = Try(UnitLevel, "player")
    local ilvl  = Try(GetAverageItemLevel)
    local gold  = Try(GetMoney)

    local rows = {
        { Try(UnitName, "player") or "?", 15, 1, 0.82, 0 },
        { string.format("Level %s %s", Show(level, "%d"), tostring(class or "")), 11, 0.72, 0.67, 0.52 },
    }
    if race then rows[#rows + 1] = { tostring(race), 10, 0.53, 0.53, 0.50 } end
    if ilvl and ilvl > 0 then
        rows[#rows + 1] = { string.format("Item level %d", math.floor(ilvl)), 10, 0.55, 0.45, 0.75 }
    end
    if gold then
        rows[#rows + 1] = { Try(GetMoneyString, gold) or string.format("%dg", math.floor(gold / 10000)),
            10, 0.53, 0.53, 0.50 }
    end

    local ty = -((model and MODEL_H or 8) + 6)
    for i, fs in ipairs(h.lines) do
        local r = rows[i]
        if r then
            fs:SetFont(STANDARD_TEXT_FONT, r[2], "OUTLINE")
            fs:SetText(r[1])
            fs:SetTextColor(r[3], r[4], r[5], 1)
            fs:ClearAllPoints()
            fs:SetPoint("TOP", h, "TOP", 0, ty)
            fs:SetWidth(w)
            fs:Show()
            ty = ty - (r[2] + 8)
        else
            fs:Hide()
        end
    end

    -- Reserve room for portrait + caption so the sidebar scroll sizes right.
    local height = math.abs(ty) + 12
    h:SetHeight(height)
    if side.SetHeight then side:SetHeight(height) end
end

--- Public wrapper so other Forever tabs (Gear, etc.) can draw the same
--- 3D-portrait identity sidebar without duplicating it. Kept as a thin method
--- over the file-local RenderSidebar so there is one implementation to change.
function M:RenderSidebarPublic(side)
    RenderSidebar(side)
end

function M:Render(content, side)
    -- Layout is the component factory every row here draws through. If the TOC
    -- ever drops it, fail loudly in the panel rather than rendering an empty
    -- tab: a blank window with no explanation cost an evening of chasing the
    -- wrong bug once already.
    L = L or TA.Layout
    if not L then
        local msg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
        msg:SetWidth(420)
        msg:SetText("|cFFFF4444ToonAge:|r Core/Layout.lua did not load, so this tab "
            .. "cannot draw. The TOC for this client is missing it — report this with "
            .. "/ta health.")
        content:SetHeight(120)
        return
    end

    -- The left column. Retail's Character tab has one and it is most of why
    -- that tab reads as finished rather than as a list of numbers.
    RenderSidebar(side)

    local y = -8
    y = RenderHeadline(content, y)
    -- In-game quick actions. Each runs the same /ta command, so the button and
    -- the typed command can never drift apart; a command whose module is not
    -- loaded on this client simply has no button.
    do
        local buttons = {}
        local function Add(cmd, label, module)
            if TA:GetModule(module) then
                buttons[#buttons + 1] = { label = label, onClick = function() TA:SlashCommand(cmd) end }
            end
        end
        Add("since",  "Since last session", "ForeverSessionCheck")
        Add("xp",     "XP rate",            "XPTracker")
        Add("gather", "Gathering",          "GatherTracker")
        if #buttons > 0 then y = L:ButtonRow(content, y, buttons) end
    end
    y = L:Divider(content, y)
    y = RenderAttributes(content, y)
    y = L:Divider(content, y)
    y = RenderOffense(content, y)
    y = L:Divider(content, y)
    y = RenderDefense(content, y)
    y = L:Divider(content, y)
    y = RenderResistances(content, y)
    local professionNames
    y, professionNames = RenderProfessions(content, y)
    y = RenderSkills(content, y, professionNames or {})
    y = L:Divider(content, y)
    y = RenderFooter(content, y)
    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "PLAYER_LEVEL_UP",
    "PLAYER_EQUIPMENT_CHANGED",
    "UNIT_STATS",
    "UNIT_RESISTANCES",
    "SKILL_LINES_CHANGED",
    "PLAYER_XP_UPDATE",
}

return M
