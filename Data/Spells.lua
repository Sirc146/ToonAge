-- ToonAge/Data/Spells.lua
-- Spell IDs for Midnight 12.0.5 (verify in-game via GetSpellInfo)

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Spells = {}
local S = TA.Data.Spells

-- ── Evoker — Preservation ─────────────────────────────────────────────
S.PRES = {
    -- Baseline spells
    LIVING_FLAME       = 361469,
    AZURE_STRIKE       = 362969,
    HOVER              = 358267,
    TAIL_SWIPE         = 368970,
    RESCUE             = 370665,
    OPPRESSING_ROAR    = 372048,
    EXPUNGE            = 365585,
    VERDANT_EMBRACE    = 360995,
    OBSIDIAN_SCALES    = 363916,
    QUELL              = 351338,
    SLEEP_WALK         = 360806,
    ZEPHYR             = 374227,
    TIME_DILATION      = 357170,
    TIP_THE_SCALES     = 370452,
    FURY_OF_THE_ASPECTS = 390386,
    CAUTERIZING_FLAME  = nil,      -- placeholder: ID unverified for Midnight
    -- Preservation spec spells
    EMERALD_BLOSSOM    = 355913,
    REVERSION          = 366155,
    ECHO               = 364343,
    DREAM_BREATH       = 382614,  -- unlocks 85
    TEMPORAL_ANOMALY   = 374251,
    SPIRITBLOOM        = 367226,
    STASIS             = 370537,  -- unlocks 90
    EMERALD_COMMUNION  = 370960,
    RENEWING_BLAZE     = 374348,
    -- Hero: Chronowarden
    TEMPORAL_BURST     = 395152,
    TIP_THE_SCALES_CW  = 370452,
    CHRONAL_DYNAMO     = 395152,  -- placeholder
    -- Apex
    MERITHRA_BLESSING  = 403631,  -- placeholder Midnight
}

-- ── Evoker — Devastation ──────────────────────────────────────────────
S.DEV = {
    LIVING_FLAME       = 361469,
    AZURE_STRIKE       = 362969,
    DISINTEGRATE       = 356995,
    FIRE_BREATH        = 357208,
    ETERNITY_SURGE     = 368847,
    SHATTERING_STAR    = 370462,
    DRAGONRAGE         = 375087,
    DEEP_BREATH        = 357210,
}

-- ── Evoker — Augmentation ─────────────────────────────────────────────
S.AUG = {
    LIVING_FLAME       = 361469,
    ERUPTION           = 395152,  -- placeholder
    EBON_MIGHT         = 395152,  -- placeholder
    PRESCIENCE         = 395152,  -- placeholder
    BREATH_OF_EONS     = 403631,  -- placeholder
    UPHEAVAL           = 403631,  -- placeholder
}

-- ── Universal utility spells ──────────────────────────────────────────
S.UTILITY = {
    BLOODLUST          = 2825,
    HEROISM            = 32182,
    TIME_WARP          = 80353,
    ANCIENT_HYSTERIA   = 90355,
}

-- ── Lookup: get spell texture by specID and spell key ─────────────────
function S:GetTexture(spellID)
    if not spellID then return nil end
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.iconID
end

function S:GetName(spellID)
    if not spellID then return "Unknown" end
    return C_Spell.GetSpellName(spellID) or "Unknown"
end

function S:IsKnown(spellID)
    if not spellID then return false end
    return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
end

function S:GetUnlockLevel(spellID)
    -- Returns the level a spell becomes available
    -- In Midnight these are datamined; check in-game to verify
    local levelMap = {
        [382614] = 85,  -- Dream Breath
        [370537] = 90,  -- Stasis
        [370960] = 72,  -- Emerald Communion
        [375087] = 74,  -- Dragonrage
    }
    return levelMap[spellID]
end
