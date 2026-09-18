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
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=1.40, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
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
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=0.90, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.80, HASTE=1.10, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}
SW[63] = { -- Fire
    name = "Fire",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.30, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.20, HASTE=1.00, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
}
SW[64] = { -- Frost Mage
    name = "Frost",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.10, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.00, HASTE=1.10, MASTERY=0.90, DODGE=0.00, PARRY=0.00 },
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
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=1.40, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.00, HASTE=1.20, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
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
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=1.40, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=0.90, HASTE=1.30, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=1.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.80, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}


-- ── Warlock ───────────────────────────────────────────────────────────
SW[265] = { -- Affliction
    name = "Affliction",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=0.90, HASTE=1.30, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.80, HASTE=1.20, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
}
SW[266] = { -- Demonology
    name = "Demonology",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.00, HASTE=1.20, MASTERY=1.30, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=0.90, HASTE=1.10, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
}
SW[267] = { -- Destruction
    name = "Destruction",
    role = "DAMAGER",
    primary = "INT",
    pve = { INT=1.60, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.30, HIT=1.40, EXP=1.40, CRIT=1.20, HASTE=1.00, MASTERY=1.10, DODGE=0.00, PARRY=0.00 },
    pvp = { INT=1.40, AGI=0.00, STR=0.00, SPI=0.00, STAM=0.80, HIT=1.00, EXP=1.00, CRIT=1.10, HASTE=0.90, MASTERY=1.00, DODGE=0.00, PARRY=0.00 },
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
    local pvpStats = self.PVP_STATS[mode or "pve"] or self.PVP_STATS.pve
    for stat, value in pairs(stats) do
        local w = weights[stat] or pvpStats[stat] or 0.1
        score = score + w * value
    end
    return math.floor(score)
end

-- ── Hit/Expertise cap helpers (MoP-specific) ──────────────────────────
-- Caps are expressed in PERCENT so they hold at every level (rating per 1%
-- changes with level; 340 rating = 1% only at 90).
--   vs raid boss (+3):  melee/ranged hit 7.5%, spell hit 15%,
--                       expertise 7.5% (dodge), tanks 15% (dodge + parry)
--   vs same level:      3% / 6% / 3% / 6%  (base miss 3%, spell miss 6%,
--                       +1.5% / +3% per level of difference) - used below 90
-- Casters: Expertise counts toward the 15% spell hit cap in MoP, and
-- Balance (Balance of Power), Elemental (Elemental Precision) and Shadow
-- (Spiritual Precision) convert Spirit to hit rating 1:1 (Icy Veins MoP
-- Classic stat guides). The conversion is applied to the client's combat
-- rating, so GetCombatRatingBonus already includes it.
SW.CAPS = {
    BOSS  = { HIT_MELEE = 7.5, HIT_SPELL = 15, EXP = 7.5, EXP_TANK = 15 },
    LEVEL = { HIT_MELEE = 3,   HIT_SPELL = 6,  EXP = 3,   EXP_TANK = 6  },
    -- Legacy rating values at level 90 (340 rating per 1%)
    HIT_MELEE_RATING_90 = 2550, HIT_SPELL_RATING_90 = 5100,
}

SW.SPIRIT_TO_HIT = { [102] = true, [262] = true, [258] = true }

function SW:IsSpellHitSpec(specID)
    local spec = self[specID]
    return spec and spec.primary == "INT" and spec.role == "DAMAGER" or false
end

function SW:GetCapTable(level)
    return ((level or 90) >= 90) and self.CAPS.BOSS or self.CAPS.LEVEL
end

-- hitPct / expPct are total percentages (rating bonus + non-rating modifiers).
-- Healers have no hit requirement and are never reported as capped.
function SW:IsHitCapped(hitPct, specID, expPct, level)
    local spec = self[specID]
    if not spec or spec.role == "HEALER" then return false end
    local caps = self:GetCapTable(level)
    if self:IsSpellHitSpec(specID) then
        return ((hitPct or 0) + (expPct or 0)) >= caps.HIT_SPELL
    end
    return (hitPct or 0) >= caps.HIT_MELEE
end

function SW:IsExpCapped(expPct, specID, hitPct, level)
    local spec = self[specID]
    if not spec or spec.role == "HEALER" then return false end
    if self:IsSpellHitSpec(specID) then
        -- Expertise is spell hit for casters: shares the combined cap.
        return self:IsHitCapped(hitPct, specID, expPct, level)
    end
    local caps = self:GetCapTable(level)
    return (expPct or 0) >= ((spec.role == "TANK") and caps.EXP_TANK or caps.EXP)
end

-- PvP-only item stats. Weighted in PvP mode, ignored in PvE.
SW.PVP_STATS = {
    pve = { RESIL = 0.00, PVPPOWER = 0.00 },
    pvp = { RESIL = 1.20, PVPPOWER = 1.10 },
}
