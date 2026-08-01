-- ToonAge/Data/StatWeights.lua
-- Stat weights per spec for PvE and PvP (Mists of Pandaria Classic 5.4.x)
-- Higher = more valuable. Primary stat always reference weight of 1.0.
-- Source: SimulationCraft 5.4.8, Icy Veins, EJ theorycrafting
-- MoP stats: STR, AGI, INT, SPI (Spirit), STAM, HIT, EXP (Expertise),
--            CRIT, HASTE, MASTERY, DODGE, PARRY

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.StatWeights = {}
local SW = TA.Data.StatWeights

-- ── Weight table format ────────────────────────────────────────────────
-- SW[specID] = { name, role, primary, pve={...}, pvp={...} }
-- Stat keys: STR, AGI, INT, SPI, STAM, HIT, EXP, CRIT, HASTE, MASTERY, DODGE, PARRY
-- Note: In MoP, HIT and EXP caps are 7.5% (PvE melee/ranged) or 15% (spell).
-- Once capped, their weight drops to 0.

-- ── Warrior ───────────────────────────────────────────────────────────
SW[71] = { -- Arms
    name = "Arms",
    role = "DAMAGER",
    primary = "STR",
    pve = { STR=1.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.10, HASTE=0.90, MASTERY=1.20, DODGE=0.00, PARRY=0.00 },
    pvp = { STR=1.40, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.10, HASTE=0.90, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[72] = { -- Fury
    name = "Fury",
    role = "DAMAGER",
    primary = "STR",
    pve = { STR=1.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.20, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
    pvp = { STR=1.40, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.20, HASTE=1.00, MASTERY=0.80, DODGE=0.00, PARRY=0.00 },
}
SW[73] = { -- Protection Warrior
    name = "Protection",
    role = "TANK",
    primary = "STR",
    pve = { STR=0.80, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.30, HIT=1.20, EXP=1.30, CRIT=0.60, HASTE=0.90, MASTERY=1.10, DODGE=1.00, PARRY=1.00 },
    pvp = { STR=0.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.50, HIT=0.80, EXP=0.80, CRIT=0.50, HASTE=0.70, MASTERY=0.90, DODGE=0.80, PARRY=0.80 },
}

-- ── Paladin ───────────────────────────────────────────────────────────
SW[65] = { -- Holy Paladin
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.20, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=0.90, HASTE=1.30, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.80, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}
SW[66] = { -- Protection Paladin
    name = "Protection",
    role = "TANK",
    primary = "STR",
    pve = { STR=0.80, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.30, HIT=1.20, EXP=1.30, CRIT=0.60, HASTE=1.10, MASTERY=1.20, DODGE=0.90, PARRY=0.90 },
    pvp = { STR=0.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.50, HIT=0.80, EXP=0.80, CRIT=0.50, HASTE=0.80, MASTERY=1.00, DODGE=0.70, PARRY=0.70 },
}
SW[70] = { -- Retribution
    name = "Retribution",
    role = "DAMAGER",
    primary = "STR",
    pve = { STR=1.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=0.90, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { STR=1.40, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}

-- ── Druid ─────────────────────────────────────────────────────────────
SW[102] = { -- Balance
    name = "Balance",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.40, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.30, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[103] = { -- Feral
    name = "Feral",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.10, HASTE=1.00, MASTERY=1.20, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.00, HASTE=0.90, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}
SW[104] = { -- Guardian
    name = "Guardian",
    role = "TANK",
    primary = "AGI",
    pve = { AGI=1.10, STR=0.20, INT=0.00, SPI=0.00, STAM=1.30, HIT=1.20, EXP=1.30, CRIT=0.80, HASTE=0.90, MASTERY=1.10, DODGE=1.20, PARRY=0.00 },
    pvp = { AGI=0.80, STR=0.20, INT=0.00, SPI=0.00, STAM=1.50, HIT=0.80, EXP=0.80, CRIT=0.60, HASTE=0.70, MASTERY=0.90, DODGE=1.00, PARRY=0.00 },
}
SW[105] = { -- Restoration Druid
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.30, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=0.80, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.70, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}


-- ── Hunter ────────────────────────────────────────────────────────────
SW[253] = { -- Beast Mastery
    name = "Beast Mastery",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.10, HASTE=1.20, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.00, HASTE=1.10, MASTERY=0.80, DODGE=0.00, PARRY=0.00 },
}
SW[254] = { -- Marksmanship
    name = "Marksmanship",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.20, HASTE=1.00, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.10, HASTE=0.90, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[255] = { -- Survival
    name = "Survival",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.00, HASTE=1.10, MASTERY=1.20, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.00, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}

-- ── Mage ──────────────────────────────────────────────────────────────
SW[62] = { -- Arcane
    name = "Arcane",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=0.90, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.80, HASTE=1.10, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}
SW[63] = { -- Fire
    name = "Fire",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.30, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=1.20, HASTE=1.00, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}
SW[64] = { -- Frost Mage
    name = "Frost",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.10, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=1.00, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}


-- ── Rogue ─────────────────────────────────────────────────────────────
SW[259] = { -- Assassination
    name = "Assassination",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=0.90, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.80, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[260] = { -- Combat (Outlaw in later expansions)
    name = "Combat",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.00, HASTE=1.30, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.20, MASTERY=0.80, DODGE=0.00, PARRY=0.00 },
}
SW[261] = { -- Subtlety
    name = "Subtlety",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.00, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.00, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}

-- ── Shaman ────────────────────────────────────────────────────────────
SW[262] = { -- Elemental
    name = "Elemental",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.40, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.30, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[263] = { -- Enhancement
    name = "Enhancement",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[264] = { -- Restoration Shaman
    name = "Restoration",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.30, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=1.00, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.80, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}

-- ── Priest ────────────────────────────────────────────────────────────
SW[256] = { -- Discipline
    name = "Discipline",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.20, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=1.10, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.90, HASTE=1.10, MASTERY=0.80, DODGE=0.00, PARRY=0.00 },
}
SW[257] = { -- Holy Priest
    name = "Holy",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.30, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=0.90, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.80, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}
SW[258] = { -- Shadow
    name = "Shadow",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.40, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=0.90, HASTE=1.30, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.30, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.80, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}


-- ── Warlock ───────────────────────────────────────────────────────────
SW[265] = { -- Affliction
    name = "Affliction",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=0.90, HASTE=1.30, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.80, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[266] = { -- Demonology
    name = "Demonology",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.00, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=0.90, HASTE=1.10, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}
SW[267] = { -- Destruction
    name = "Destruction",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=0.00, CRIT=1.20, HASTE=1.00, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=0.00, CRIT=1.10, HASTE=0.90, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}

-- ── Monk ──────────────────────────────────────────────────────────────
SW[268] = { -- Brewmaster
    name = "Brewmaster",
    role = "TANK",
    primary = "AGI",
    pve = { AGI=1.10, STR=0.20, INT=0.00, SPI=0.00, STAM=1.30, HIT=1.20, EXP=1.30, CRIT=1.00, HASTE=1.10, MASTERY=0.90, DODGE=0.80, PARRY=0.80 },
    pvp = { AGI=0.80, STR=0.20, INT=0.00, SPI=0.00, STAM=1.50, HIT=0.80, EXP=0.80, CRIT=0.70, HASTE=0.90, MASTERY=0.70, DODGE=0.60, PARRY=0.60 },
}
SW[270] = { -- Mistweaver
    name = "Mistweaver",
    role = "HEALER",
    primary = "INT",
    pve = { INT=1.70, AGI=0.00, STR=0.00, SPI=1.30, STAM=0.50, HIT=0.00, EXP=0.00, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=1.00, HIT=0.00, EXP=0.00, CRIT=0.80, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}
SW[269] = { -- Windwalker
    name = "Windwalker",
    role = "DAMAGER",
    primary = "AGI",
    pve = { AGI=1.60, STR=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.10, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { AGI=1.40, STR=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.00, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}

-- ── Death Knight ──────────────────────────────────────────────────────
SW[250] = { -- Blood
    name = "Blood",
    role = "TANK",
    primary = "STR",
    pve = { STR=0.80, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.30, HIT=1.20, EXP=1.30, CRIT=0.60, HASTE=0.90, MASTERY=1.20, DODGE=1.00, PARRY=1.10 },
    pvp = { STR=0.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=1.50, HIT=0.80, EXP=0.80, CRIT=0.50, HASTE=0.70, MASTERY=1.00, DODGE=0.80, PARRY=0.90 },
}
SW[251] = { -- Frost DK
    name = "Frost",
    role = "DAMAGER",
    primary = "STR",
    pve = { STR=1.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { STR=1.40, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[252] = { -- Unholy
    name = "Unholy",
    role = "DAMAGER",
    primary = "STR",
    pve = { STR=1.60, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.30, CRIT=0.90, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { STR=1.40, AGI=0.20, INT=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.80, HASTE=1.10, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}


-- ── Lookup helpers ────────────────────────────────────────────────────
function SW:GetWeights(specID, mode)
    local spec = self[specID]
    if not spec then return nil end
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
    if not weights then return 0 end
    local score = 0
    for stat, value in pairs(stats) do
        score = score + (weights[stat] or 0.1) * value
    end
    return math.floor(score)
end

-- ── Hit/Expertise cap helpers (MoP-specific) ──────────────────────────
-- PvE melee/ranged hit cap: 7.5% (2550 rating at 90)
-- PvE spell hit cap: 15% (5100 rating at 90)
-- Expertise soft cap: 7.5% (2550 rating at 90)
-- Expertise hard cap (removes parry): 15% (5100 rating at 90, tanks only)
SW.CAPS = {
    HIT_MELEE   = 2550,
    HIT_SPELL   = 5100,
    EXP_SOFT    = 2550,
    EXP_HARD    = 5100,
}

function SW:IsHitCapped(hitRating, specID)
    local spec = self[specID]
    if not spec then return false end
    local role = spec.role
    local primary = spec.primary
    -- Casters need 15% spell hit
    if primary == "INT" and role == "DAMAGER" then
        return hitRating >= self.CAPS.HIT_SPELL
    end
    -- Melee/ranged need 7.5%
    return hitRating >= self.CAPS.HIT_MELEE
end

function SW:IsExpCapped(expRating, specID)
    local spec = self[specID]
    if not spec then return false end
    if spec.role == "TANK" then
        return expRating >= self.CAPS.EXP_HARD
    end
    return expRating >= self.CAPS.EXP_SOFT
end
