-- ToonAge/Data/StatWeights.lua
-- Stat weights per spec for PvE and PvP (Midnight 12.0.5)
-- Higher = more valuable. Primary stat always reference weight of 1.0.
-- Source: Method, Icy Veins, Archon theorycrafting (12.0.5)

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.StatWeights = {}
local SW = TA.Data.StatWeights

-- ── Weight table format ────────────────────────────────────────────────
-- SW[specID] = { pve = {...}, pvp = {...} }
-- Stat keys: INT, AGI, STR, STAM, HASTE, CRIT, MASTERY, VERS, ARMOR

-- ── Evoker ────────────────────────────────────────────────────────────
SW[1468] = { -- Preservation
    name = "Preservation",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        MASTERY = 1.30,
        VERS = 1.10,
        HASTE = 1.00,
        CRIT = 0.85,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[1467] = { -- Devastation
    name = "Devastation",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[1473] = { -- Augmentation
    name = "Augmentation",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.30,
        MASTERY = 1.30,
        HASTE = 1.10,
        CRIT = 0.90,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.80,
        VERS = 1.60,
        MASTERY = 1.00,
        HASTE = 1.00,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Warrior ───────────────────────────────────────────────────────────
SW[71] = { -- Arms
    name = "Arms",
    role = "DAMAGER",
    primary = "STR",
    pve = {
        STR = 1.60,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        STR = 1.40,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[72] = { -- Fury
    name = "Fury",
    role = "DAMAGER",
    primary = "STR",
    pve = {
        STR = 1.60,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.30,
        CRIT = 1.00,
        MASTERY = 0.90,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        STR = 1.40,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.20,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[73] = { -- Protection Warrior
    name = "Protection",
    role = "TANK",
    primary = "STR",
    pve = {
        STR = 1.10,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.30,
        VERS = 1.20,
        HASTE = 1.00,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 1.10,
    },
    pvp = {
        STR = 0.80,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}

-- ── Paladin ───────────────────────────────────────────────────────────
SW[65] = { -- Holy Paladin
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.20,
        STAM = 0.50,
        HASTE = 1.20,
        MASTERY = 1.10,
        CRIT = 1.00,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.20,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[66] = { -- Protection Paladin
    name = "Protection",
    role = "TANK",
    primary = "STR",
    pve = {
        STR = 1.10,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.30,
        HASTE = 1.10,
        VERS = 1.20,
        MASTERY = 1.00,
        CRIT = 0.80,
        ARMOR = 1.00,
    },
    pvp = {
        STR = 0.80,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}
SW[70] = { -- Retribution
    name = "Retribution",
    role = "DAMAGER",
    primary = "STR",
    pve = {
        STR = 1.60,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        STR = 1.40,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Druid ─────────────────────────────────────────────────────────────
SW[102] = { -- Balance
    name = "Balance",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[103] = { -- Feral
    name = "Feral",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[104] = { -- Guardian
    name = "Guardian",
    role = "TANK",
    primary = "AGI",
    pve = {
        AGI = 1.10,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.30,
        VERS = 1.20,
        MASTERY = 1.10,
        HASTE = 1.00,
        CRIT = 0.80,
        ARMOR = 1.10,
    },
    pvp = {
        AGI = 0.80,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}
SW[105] = { -- Restoration Druid
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.50,
        MASTERY = 1.30,
        HASTE = 1.10,
        VERS = 1.00,
        CRIT = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.10,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Hunter ────────────────────────────────────────────────────────────
SW[253] = { -- Beast Mastery
    name = "Beast Mastery",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[254] = { -- Marksmanship
    name = "Marksmanship",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.10,
        CRIT = 1.20,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[255] = { -- Survival
    name = "Survival",
    role = "DAMAGER",
    primary = "AGI",
    -- Pack Leader / melee: Haste > Mastery > Crit > Vers for sustained PvE.
    -- AGI is always king as primary stat. Mastery powers Wildfire Bomb and
    -- melee DoT components. Haste reduces GCD and focus regen.
    pve = {
        AGI = 1.60,
        STR = 0.10,
        INT = 0.10,
        STAM = 0.25,
        HASTE = 1.25,
        MASTERY = 1.15,
        CRIT = 1.05,
        VERS = 0.85,
        ARMOR = 0.10,
    },
    -- PvP: Versatility is mandatory (damage reduction + throughput), then
    -- Mastery (consistent damage in short windows), Haste, Crit last.
    pvp = {
        AGI = 1.40,
        STR = 0.10,
        INT = 0.10,
        STAM = 0.90,
        VERS = 1.60,
        HASTE = 1.10,
        MASTERY = 1.05,
        CRIT = 0.90,
        ARMOR = 0.10,
    },
}

-- ── Mage ──────────────────────────────────────────────────────────────
SW[62] = { -- Arcane
    name = "Arcane",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[63] = { -- Fire
    name = "Fire",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        CRIT = 1.30,
        HASTE = 1.00,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[64] = { -- Frost Mage
    name = "Frost",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Rogue ─────────────────────────────────────────────────────────────
SW[259] = { -- Assassination
    name = "Assassination",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[260] = { -- Outlaw
    name = "Outlaw",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.30,
        CRIT = 1.00,
        MASTERY = 0.90,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[261] = { -- Subtlety
    name = "Subtlety",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        MASTERY = 1.10,
        CRIT = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.60,
        HASTE = 1.00,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Shaman ────────────────────────────────────────────────────────────
SW[262] = { -- Elemental
    name = "Elemental",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[263] = { -- Enhancement
    name = "Enhancement",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.20,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.20,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[264] = { -- Restoration Shaman
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.50,
        MASTERY = 1.20,
        HASTE = 1.20,
        CRIT = 1.00,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.10,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Priest ────────────────────────────────────────────────────────────
SW[256] = { -- Discipline
    name = "Discipline",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.50,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[257] = { -- Holy Priest
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.50,
        HASTE = 1.20,
        CRIT = 1.00,
        MASTERY = 1.10,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[258] = { -- Shadow
    name = "Shadow",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.00,
        MASTERY = 1.10,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Warlock ───────────────────────────────────────────────────────────
SW[265] = { -- Affliction
    name = "Affliction",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        MASTERY = 1.10,
        CRIT = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[266] = { -- Demonology
    name = "Demonology",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.00,
        MASTERY = 1.10,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[267] = { -- Destruction
    name = "Destruction",
    role = "DAMAGER",
    primary = "INT",
    pve = {
        INT = 1.60,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.30,
        HASTE = 1.10,
        CRIT = 1.20,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.10,
        STR = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Monk ─────────────────────────────────────────────────────────────
SW[268] = { -- Brewmaster
    name = "Brewmaster",
    role = "TANK",
    primary = "AGI",
    pve = {
        AGI = 1.10,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.30,
        VERS = 1.20,
        MASTERY = 1.10,
        HASTE = 1.00,
        CRIT = 0.80,
        ARMOR = 1.00,
    },
    pvp = {
        AGI = 0.80,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}
SW[270] = { -- Mistweaver
    name = "Mistweaver",
    role = "HEALER",
    primary = "INT",
    pve = {
        INT = 1.70,
        AGI = 0.20,
        STR = 0.10,
        STAM = 0.50,
        HASTE = 1.20,
        MASTERY = 1.10,
        CRIT = 1.00,
        VERS = 1.00,
        ARMOR = 0.10,
    },
    pvp = {
        INT = 1.40,
        AGI = 0.20,
        STR = 0.10,
        STAM = 1.00,
        VERS = 1.70,
        HASTE = 1.10,
        MASTERY = 0.90,
        CRIT = 0.80,
        ARMOR = 0.10,
    },
}
SW[269] = { -- Windwalker
    name = "Windwalker",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Demon Hunter ──────────────────────────────────────────────────────
SW[577] = { -- Havoc
    name = "Havoc",
    role = "DAMAGER",
    primary = "AGI",
    pve = {
        AGI = 1.60,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        AGI = 1.40,
        STR = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[581] = { -- Vengeance
    name = "Vengeance",
    role = "TANK",
    primary = "AGI",
    pve = {
        AGI = 1.10,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.30,
        VERS = 1.20,
        MASTERY = 1.10,
        HASTE = 1.00,
        CRIT = 0.80,
        ARMOR = 1.00,
    },
    pvp = {
        AGI = 0.80,
        STR = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}

-- ── Death Knight ──────────────────────────────────────────────────────
SW[250] = { -- Blood
    name = "Blood",
    role = "TANK",
    primary = "STR",
    pve = {
        STR = 1.10,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.30,
        VERS = 1.20,
        MASTERY = 1.10,
        HASTE = 1.00,
        CRIT = 0.80,
        ARMOR = 1.00,
    },
    pvp = {
        STR = 0.80,
        AGI = 0.20,
        INT = 0.10,
        STAM = 1.60,
        VERS = 1.80,
        HASTE = 0.90,
        MASTERY = 0.70,
        CRIT = 0.60,
        ARMOR = 0.80,
    },
}
SW[251] = { -- Frost DK
    name = "Frost",
    role = "DAMAGER",
    primary = "STR",
    pve = {
        STR = 1.60,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.20,
        CRIT = 1.10,
        MASTERY = 1.00,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        STR = 1.40,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}
SW[252] = { -- Unholy
    name = "Unholy",
    role = "DAMAGER",
    primary = "STR",
    pve = {
        STR = 1.60,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.30,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 1.20,
        VERS = 0.90,
        ARMOR = 0.10,
    },
    pvp = {
        STR = 1.40,
        AGI = 0.20,
        INT = 0.10,
        STAM = 0.80,
        VERS = 1.50,
        HASTE = 1.10,
        CRIT = 1.00,
        MASTERY = 0.80,
        ARMOR = 0.10,
    },
}

-- ── Lookup helper ─────────────────────────────────────────────────────
function SW:GetWeights(specID, mode)
    local spec = self[specID]
    if not spec then
        return nil
    end
    return spec[mode or "pve"]
end

function SW:GetRole(specID)
    local spec = self[specID]
    return spec and spec.role or "DAMAGER"
end

function SW:GetPrimary(specID)
    local spec = self[specID]
    return spec and spec.primary or "INT"
end

function SW:ScoreItem(stats, specID, mode)
    local weights = self:GetWeights(specID, mode)
    if not weights then
        return 0
    end
    local score = 0
    for stat, value in pairs(stats) do
        score = score + (weights[stat] or 0.2) * value
    end
    return math.floor(score)
end
