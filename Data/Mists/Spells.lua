-- ToonAge/Data/Spells.lua
-- Travel and utility spell IDs for Mists of Pandaria Classic (5.4.x)
-- Verify in-game via GetSpellInfo(spellID)

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Spells = {}
local S = TA.Data.Spells

-- ── Mounts ────────────────────────────────────────────────────────────
S.MOUNTS = {
    APPRENTICE_RIDING   = 33388,   -- 60% ground (level 20)
    JOURNEYMAN_RIDING   = 33391,   -- 100% ground (level 40)
    EXPERT_RIDING       = 34090,   -- 150% flying (level 60)
    ARTISAN_RIDING      = 34091,   -- 280% flying (level 70)
    MASTER_RIDING       = 90265,   -- 310% flying (level 80)
    COLD_WEATHER_FLYING = 54197,   -- Northrend flying
    FLIGHT_MASTERS_LICENSE = 90267, -- Azeroth flying (Cata zones)
    WISDOM_OF_THE_FOUR_WINDS = 115913, -- Pandaria flying
}

-- ── Hearthstone ───────────────────────────────────────────────────────
S.HEARTH = {
    HEARTHSTONE         = 8690,
    ASTRAL_RECALL       = 556,     -- Shaman 15min hearth
}

-- ── Druid Travel ──────────────────────────────────────────────────────
S.DRUID = {
    TRAVEL_FORM         = 783,
    AQUATIC_FORM        = 1066,
    FLIGHT_FORM         = 33943,
    SWIFT_FLIGHT_FORM   = 40120,
    DASH                = 1850,
    STAMPEDING_ROAR     = 106898,
}

-- ── Mage Teleports ───────────────────────────────────────────────────
S.MAGE_TELEPORT = {
    -- Alliance
    TELE_STORMWIND      = 3561,
    TELE_IRONFORGE      = 3562,
    TELE_DARNASSUS      = 3565,
    TELE_EXODAR         = 32271,
    TELE_THERAMORE      = 49359,
    TELE_DALARAN        = 53140,
    TELE_TOL_BARAD_A    = 88342,
    TELE_VALE_A         = 132621,
    -- Horde
    TELE_ORGRIMMAR      = 3567,
    TELE_UNDERCITY      = 3563,
    TELE_THUNDER_BLUFF  = 3566,
    TELE_SILVERMOON     = 32272,
    TELE_STONARD        = 49358,
    TELE_DALARAN_H      = 53140,
    TELE_TOL_BARAD_H    = 88344,
    TELE_VALE_H         = 132627,
    -- Neutral
    TELE_SHATTRATH_A    = 33690,
    TELE_SHATTRATH_H    = 35715,
    TELE_ANCIENT_DALARAN = 120145,
}

-- ── Mage Portals ─────────────────────────────────────────────────────
S.MAGE_PORTAL = {
    -- Alliance
    PORT_STORMWIND      = 10059,
    PORT_IRONFORGE      = 11416,
    PORT_DARNASSUS      = 11419,
    PORT_EXODAR         = 32266,
    PORT_THERAMORE      = 49360,
    PORT_DALARAN        = 53142,
    PORT_TOL_BARAD_A    = 88345,
    PORT_VALE_A         = 132620,
    -- Horde
    PORT_ORGRIMMAR      = 11417,
    PORT_UNDERCITY      = 11418,
    PORT_THUNDER_BLUFF  = 11420,
    PORT_SILVERMOON     = 32267,
    PORT_STONARD        = 49361,
    PORT_DALARAN_H      = 53142,
    PORT_TOL_BARAD_H    = 88346,
    PORT_VALE_H         = 132626,
    -- Neutral
    PORT_SHATTRATH_A    = 33691,
    PORT_SHATTRATH_H    = 35717,
    PORT_ANCIENT_DALARAN = 120146,
}

-- ── Death Knight ──────────────────────────────────────────────────────
S.DEATHKNIGHT = {
    DEATHS_ADVANCE      = 96268,
    ON_A_PALE_HORSE     = 51986,   -- passive mount speed
    DEATH_GATE          = 50977,   -- Acherus portal
}

-- ── Monk ──────────────────────────────────────────────────────────────
S.MONK = {
    ROLL                = 109132,
    ZEN_PILGRIMAGE      = 126892,  -- teleport to Peak of Serenity
    ZEN_PILGRIMAGE_RET  = 126895,  -- return from Peak
    FLYING_SERPENT_KICK = 101545,
}

-- ── Shaman ────────────────────────────────────────────────────────────
S.SHAMAN = {
    GHOST_WOLF          = 2645,
    ASTRAL_RECALL       = 556,
    FAR_SIGHT           = 6196,
}

-- ── Warlock ───────────────────────────────────────────────────────────
S.WARLOCK = {
    DEMONIC_CIRCLE_SUMMON = 48018,
    DEMONIC_CIRCLE_TELE   = 48020,
    SOULSTONE           = 20707,
    RITUAL_OF_SUMMONING = 698,
}

-- ── Hunter ────────────────────────────────────────────────────────────
S.HUNTER = {
    ASPECT_OF_THE_CHEETAH = 5118,
    ASPECT_OF_THE_PACK    = 13159,
    DISENGAGE             = 781,
}

-- ── Rogue ─────────────────────────────────────────────────────────────
S.ROGUE = {
    SPRINT              = 2983,
    SHADOWSTEP          = 36554,
    BURST_OF_SPEED      = 108212,
}

-- ── Warrior ───────────────────────────────────────────────────────────
S.WARRIOR = {
    CHARGE              = 100,
    HEROIC_LEAP         = 6544,
    INTERVENE           = 3411,
}

-- ── Paladin ───────────────────────────────────────────────────────────
S.PALADIN = {
    DIVINE_STEED        = 0,       -- Does NOT exist in MoP; placeholder
    SPEED_OF_LIGHT      = 85499,   -- talent: 70% speed 8sec
    PURSUIT_OF_JUSTICE  = 26023,   -- passive speed talent
}

-- ── Priest ────────────────────────────────────────────────────────────
S.PRIEST = {
    LEVITATE            = 1706,
    ANGELIC_FEATHER     = 121536,
    BODY_AND_SOUL       = 64129,   -- PW:S speed buff talent
}

-- ── Universal Utility ─────────────────────────────────────────────────
S.UTILITY = {
    BLOODLUST           = 2825,
    HEROISM             = 32182,
    TIME_WARP           = 80353,
    ANCIENT_HYSTERIA    = 90355,   -- Hunter pet
    GUILD_PERK_MOUNT    = 78633,   -- Mount Up guild perk (+10% mount speed)
}

-- ── Lookup helpers ────────────────────────────────────────────────────
function S:GetTexture(spellID)
    if not spellID or spellID == 0 then return nil end
    local name, _, icon = GetSpellInfo(spellID)
    return icon
end

function S:GetName(spellID)
    if not spellID or spellID == 0 then return "Unknown" end
    local name = GetSpellInfo(spellID)
    return name or "Unknown"
end

function S:IsKnown(spellID)
    if not spellID or spellID == 0 then return false end
    return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
end
