-- ToonAge/Data/TBCWeights.lua (Anniversary — TBC Classic / Interface 20506)
-- Item stat parsing and stat weights for gear scoring.
--
-- ─── HONESTY ABOUT WHAT IS EXACT AND WHAT IS NOT ─────────────────────────────
--
-- The cap logic in Core/TBCStats.lua is exact — miss chance, dodge chance and
-- crit-taken are closed-form functions of level and weapon skill, and the addon
-- computes them rather than looking them up.
--
-- The weights BELOW are not exact and cannot be. A real stat weight in TBC is
-- spec-, gear- and encounter-dependent (an Arms warrior at 30% crit values crit
-- differently than at 15%, and neither matches a Rogue). These are the standard
-- community-consensus approximations, normalised so the role's primary stat is
-- 1.00, and the Gear tab labels them as approximate.
--
-- The design consequence matters: gear ranking leans on the part that IS exact.
-- An item carrying hit you still need beats an item with more raw throughput,
-- because "9% or you miss" is arithmetic, while "crit is worth 1.4 agility" is
-- an estimate. That is the brief's "Hit > everything until capped", implemented
-- as marginal value rather than as a blanket rule — see Modules/Gear/Gear.lua.
--
-- UNVERIFIED on 20506: the exact GetItemStats key strings. Aliases are listed
-- for every stat and unrecognised keys are collected into TA.Data.UnknownStatKeys
-- and surfaced by /ta statkeys, so a mismatch shows up as a report instead of a
-- silently-ignored stat.

local TA = ToonAge
TA.Data = TA.Data or {}

-- ─── ITEM STAT KEY MAP ───────────────────────────────────────────────────────
-- GetItemStats returns a table keyed by Blizzard's ITEM_MOD_* global names.
-- Several stats have more than one key across the 2.x line (spell power was
-- split into damage and healing before 2.4 unified it), so every alias maps to
-- one canonical name.

local KEY_MAP = {
    -- Primary attributes
    ITEM_MOD_STRENGTH_SHORT              = "STR",
    ITEM_MOD_AGILITY_SHORT               = "AGI",
    ITEM_MOD_STAMINA_SHORT               = "STA",
    ITEM_MOD_INTELLECT_SHORT             = "INT",
    ITEM_MOD_SPIRIT_SHORT                = "SPI",

    -- Melee / ranged
    ITEM_MOD_ATTACK_POWER_SHORT          = "AP",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT   = "RAP",
    ITEM_MOD_HIT_RATING_SHORT            = "HIT",
    ITEM_MOD_CRIT_RATING_SHORT           = "CRIT",
    ITEM_MOD_HASTE_RATING_SHORT          = "HASTE",
    ITEM_MOD_EXPERTISE_RATING_SHORT      = "EXP",
    ITEM_MOD_HIT_MELEE_RATING_SHORT      = "HIT",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT     = "CRIT",
    ITEM_MOD_HASTE_MELEE_RATING_SHORT    = "HASTE",
    ITEM_MOD_HIT_RANGED_RATING_SHORT     = "HIT",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT    = "CRIT",

    -- Spell
    ITEM_MOD_SPELL_POWER_SHORT           = "SP",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT     = "SP",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT    = "HEAL",
    ITEM_MOD_HIT_SPELL_RATING_SHORT      = "SPELLHIT",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT     = "SPELLCRIT",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT    = "SPELLHASTE",
    ITEM_MOD_SPELL_PENETRATION_SHORT     = "SPELLPEN",
    ITEM_MOD_POWER_REGEN0_SHORT          = "MP5",
    ITEM_MOD_MANA_REGENERATION_SHORT     = "MP5",

    -- Defensive
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT  = "DEFENSE",
    ITEM_MOD_DODGE_RATING_SHORT          = "DODGE",
    ITEM_MOD_PARRY_RATING_SHORT          = "PARRY",
    ITEM_MOD_BLOCK_RATING_SHORT          = "BLOCKRATING",
    ITEM_MOD_BLOCK_VALUE_SHORT           = "BLOCKVALUE",
    ITEM_MOD_RESILIENCE_RATING_SHORT     = "RESIL",
    RESISTANCE0_NAME                     = "ARMOR",

    -- Empty sockets. GetItemStats reports these as counts alongside real stats,
    -- and before they were mapped they fell into UnknownStatKeys and vanished
    -- from scoring entirely. They are NOT stats — they are a deficit, worth
    -- roughly a rare gem each until filled — so Gear.lua pulls them out of the
    -- stat table and reports them separately rather than weighting them.
    EMPTY_SOCKET_RED     = "SOCKET_RED",
    EMPTY_SOCKET_YELLOW  = "SOCKET_YELLOW",
    EMPTY_SOCKET_BLUE    = "SOCKET_BLUE",
    EMPTY_SOCKET_META    = "SOCKET_META",
    EMPTY_SOCKET_PRISMATIC = "SOCKET_PRISMATIC",
}

-- Canonical socket keys, so scoring can skip them in one test.
TA = TA or ToonAge
local SOCKET_KEYS = {
    SOCKET_RED = "Red", SOCKET_YELLOW = "Yellow", SOCKET_BLUE = "Blue",
    SOCKET_META = "Meta", SOCKET_PRISMATIC = "Prismatic",
}

TA.Data.StatKeyMap    = KEY_MAP
TA.Data.UnknownStatKeys = {}

TA.Data.StatLabels = {
    STR="Strength", AGI="Agility", STA="Stamina", INT="Intellect", SPI="Spirit",
    AP="Attack Power", RAP="Ranged Attack Power", HIT="Hit Rating",
    CRIT="Crit Rating", HASTE="Haste Rating", EXP="Expertise Rating",
    SP="Spell Power", HEAL="Healing Power", SPELLHIT="Spell Hit Rating",
    SPELLCRIT="Spell Crit Rating", SPELLHASTE="Spell Haste Rating",
    SPELLPEN="Spell Penetration", MP5="Mana per 5s",
    DEFENSE="Defense Rating", DODGE="Dodge Rating", PARRY="Parry Rating",
    BLOCKRATING="Block Rating", BLOCKVALUE="Block Value",
    RESIL="Resilience", ARMOR="Armor",
}

TA.Data.SocketKeys = SOCKET_KEYS

--- Rough stat value of one filled socket, for reporting what an empty one costs.
--- A TBC rare gem is about 8 of a secondary stat or 10 stamina. Deliberately a
--- single approximate number, labelled as such wherever it is shown — pricing
--- it per colour and per role would be false precision on top of a guess.
TA.Data.SOCKET_APPROX_VALUE = 8

--- Split socket counts out of a normalised stat table.
--- @return table sockets {colour = count}, number total
function TA.Data.ExtractSockets(stats)
    local sockets, total = {}, 0
    for key, label in pairs(SOCKET_KEYS) do
        local n = stats[key]
        if n and n > 0 then
            sockets[label] = n
            total = total + n
            stats[key] = nil   -- removed so scoring never weights a hole as a stat
        end
    end
    return sockets, total
end

--- Normalise a GetItemStats table into canonical keys.
--- Unrecognised keys are recorded, not dropped silently — an unmapped stat is
--- indistinguishable from a stat worth zero once it has been thrown away.
--- @return table stats, number unknownCount
function TA.Data.NormaliseStats(raw)
    local out, unknown = {}, 0
    if type(raw) ~= "table" then return out, 0 end

    for key, value in pairs(raw) do
        local canon = KEY_MAP[key]
        if canon then
            out[canon] = (out[canon] or 0) + (tonumber(value) or 0)
        else
            unknown = unknown + 1
            TA.Data.UnknownStatKeys[key] = (TA.Data.UnknownStatKeys[key] or 0) + 1
        end
    end
    return out, unknown
end

-- ─── STAT WEIGHTS BY ROLE ────────────────────────────────────────────────────
-- Approximate. Normalised so the role's primary stat is 1.00.
-- Rating stats are per point of RATING, not per percent.

TA.Data.RoleWeights = {
    MELEE = {
        primary = "STR",
        STR = 1.00, AGI = 0.65, AP = 0.50, STA = 0.10,
        HIT = 1.20, EXP = 1.15, CRIT = 0.80, HASTE = 0.75,
        ARMOR = 0.01, RESIL = 0.20,
        note = "Strength-based melee. Hit and expertise lead until both are capped.",
    },
    RANGED = {
        primary = "AGI",
        AGI = 1.00, RAP = 0.50, AP = 0.50, STA = 0.10, INT = 0.15,
        HIT = 1.30, CRIT = 0.85, HASTE = 0.70,
        RESIL = 0.20,
        note = "Hunters. Hit is the single most valuable stat until 9% — a missed "
            .. "shot costs the whole cast, not part of it.",
    },
    CASTER = {
        primary = "SP",
        SP = 1.00, INT = 0.35, SPI = 0.15, STA = 0.05,
        SPELLHIT = 1.30, SPELLCRIT = 0.55, SPELLHASTE = 0.60,
        MP5 = 0.40, SPELLPEN = 0.05, RESIL = 0.20,
        note = "Spell power leads once hit is capped. Spirit is near worthless for "
            .. "most TBC caster specs — Mp5 is the real regen stat.",
    },
    HEALER = {
        primary = "HEAL",
        HEAL = 1.00, SP = 1.00, INT = 0.45, SPI = 0.35, MP5 = 0.90,
        SPELLCRIT = 0.40, SPELLHASTE = 0.45, STA = 0.05,
        note = "Mp5 is close to healing power in value — TBC healing is a mana game. "
            .. "Spell hit does nothing for heals; it is scored at zero.",
    },
    TANK = {
        primary = "STA",
        STA = 1.00, DEFENSE = 1.40, DODGE = 0.85, PARRY = 0.80,
        BLOCKRATING = 0.35, BLOCKVALUE = 0.20, ARMOR = 0.05,
        STR = 0.25, AGI = 0.45, HIT = 0.45, EXP = 0.50, AP = 0.15,
        CRIT = 0.20, RESIL = 0.30,
        note = "Defense is weighted above everything until uncrittable, then falls "
            .. "off a cliff — being 1 point short is a wipe risk, being 20 over is waste.",
    },
}

-- ─── PVP WEIGHTS ─────────────────────────────────────────────────────────────
-- PvP is not PvE with resilience bolted on. Three things genuinely invert:
--
--   1. Resilience goes from worthless to top-three. It is the only stat that
--      reduces damage from a source you cannot avoid.
--   2. Stamina goes from a rounding error to a primary concern. Arena games are
--      decided by whether you survive an opener, and every point of health is a
--      fraction of a global cooldown you get to keep acting for.
--   3. The hit caps collapse. A player is a same-level target: 5% melee and 3%
--      spell instead of 9% and 16%. That is handled by the cap engine, not here
--      — PvP mode forces the "same" context — but it is why hit's weight drops.
--      It reaches its (much lower) cap almost immediately.
--
-- Same honesty as the PvE table: these are approximations for ranking, not
-- predictions. The cap arithmetic underneath them is exact.

TA.Data.PvPRoleWeights = {
    MELEE = {
        primary = "STR",
        STR = 1.00, AGI = 0.65, AP = 0.50, STA = 0.85,
        HIT = 0.90, EXP = 0.35, CRIT = 0.70, HASTE = 0.65,
        RESIL = 1.20, ARMOR = 0.02,
        note = "Resilience and Stamina lead. Expertise falls hard — players dodge "
            .. "far less than bosses, and you are rarely behind one.",
    },
    RANGED = {
        primary = "AGI",
        AGI = 1.00, RAP = 0.50, AP = 0.50, STA = 0.85, INT = 0.10,
        HIT = 0.90, CRIT = 0.75, HASTE = 0.55,
        RESIL = 1.20,
        note = "You are the kill target in most comps. Living to fire twice beats "
            .. "firing harder once.",
    },
    CASTER = {
        primary = "SP",
        SP = 1.00, INT = 0.25, SPI = 0.05, STA = 0.90,
        SPELLHIT = 0.80, SPELLCRIT = 0.55, SPELLHASTE = 0.55,
        MP5 = 0.10, SPELLPEN = 0.35, RESIL = 1.30,
        note = "The largest PvE-to-PvP shift in the game: spell hit caps at 3% "
            .. "instead of 16%, and Mp5 stops mattering because games end before "
            .. "mana does. Spell penetration earns real value against resistances.",
    },
    HEALER = {
        primary = "HEAL",
        HEAL = 1.00, SP = 1.00, INT = 0.25, SPI = 0.10, MP5 = 0.20,
        SPELLCRIT = 0.35, SPELLHASTE = 0.55, STA = 1.00,
        RESIL = 1.40,
        note = "You are the primary target in essentially every arena game. "
            .. "Resilience and Stamina outrank throughput, and Mp5 collapses — "
            .. "the opposite of the PvE healer table.",
    },
    TANK = {
        primary = "STA",
        STA = 1.00, RESIL = 1.20, STR = 0.35, AGI = 0.45,
        DEFENSE = 0.10, DODGE = 0.45, PARRY = 0.40, ARMOR = 0.03,
        HIT = 0.60, EXP = 0.25, AP = 0.20, CRIT = 0.30,
        note = "Defense is near worthless here: player crits are reduced by "
            .. "resilience, not by defense skill, and there is no uncrittable "
            .. "threshold against players.",
    },
}

--- Weights for the player's inferred role.
--- @param role string
--- @param pvp boolean|nil  defaults to the addon's current mode
function TA.Data.GetWeights(role, pvp)
    if pvp == nil then
        pvp = ToonAge.db and ToonAge.db.pvpMode or false
    end
    local set = pvp and TA.Data.PvPRoleWeights or TA.Data.RoleWeights
    return set[role] or set.MELEE or TA.Data.RoleWeights.MELEE
end

--- Which cap a given rating stat feeds. Used by Gear scoring to look up how much
--- of an item's rating is still useful rather than assuming all of it is.
TA.Data.StatToCap = {
    HIT      = "meleeHit",
    SPELLHIT = "spellHit",
    EXP      = "expertise",
    DEFENSE  = "defense",
}
