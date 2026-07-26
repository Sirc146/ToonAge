-- ToonAge/Data/TalentsPvP.lua
-- PvP-specific talent data: recommended nodes, explanations, alternatives.
--
-- Schema:
--   TA.Data.TalentsPvP[specID] = {
--       importString = "...",           -- full PvP loadout string (Blizzard format)
--       heroSpec     = "Pack Leader"|"Dark Ranger"|etc, -- recommended hero talent tree
--       pvpTalents   = { spellID, spellID, spellID },  -- 3 PvP talent picks
--       panels = {
--           class = { nodes },   -- class tree picks
--           spec  = { nodes },   -- spec tree picks
--           hero  = { nodes },   -- hero talent picks
--       },
--       nodes = {
--           [nodeID] = {
--               pick    = "Talent Name",
--               why     = "Short explanation of why this is picked for PvP",
--               alt     = "Alternative Name",
--               altWhy  = "When/why you'd pick the alternative instead",
--               pveNote = nil | "In PvE, take X instead because Y",
--               level   = nil | number,  -- level this unlocks at (for leveling path)
--           },
--       },
--       levelPath = {
--           [10] = { name="Talent A", why="First point — survivability" },
--           [11] = { name="Talent B", why="Burst damage for duels" },
--           ...
--       },
--   }
--
-- NOTE: Node IDs are placeholders (0) until populated from live C_Traits data.
-- The 'pick' field name is used for display when nodeIDs aren't yet mapped.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.TalentsPvP = {}

local PVP = TA.Data.TalentsPvP

-- ═══════════════════════════════════════════════════════════════════════════════
-- WARRIOR
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[71] = { -- Arms
    importString = "",
    heroSpec     = "Colossus",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [0] = {
            pick    = "Storm of Swords",
            why     = "Whirlwind becomes instant — essential for pressure in BGs and arenas.",
            alt     = "Fervor of Battle",
            altWhy  = "Better sustained cleave in large-scale BG fights (40v40).",
            pveNote = "In PvE M+, Fervor of Battle is preferred for pack cleave.",
        },
    },
    levelPath = {
        [10] = { name = "Mortal Strike", why = "Core ability — healing reduction is king in PvP." },
        [11] = { name = "Impending Victory", why = "Self-healing to survive between healer CDs." },
    },
}

PVP[72] = { -- Fury
    importString = "",
    heroSpec     = "Slayer",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {
        [10] = { name = "Bloodthirst", why = "Self-healing baseline — keeps you alive in skirmishes." },
    },
}

PVP[73] = { -- Protection
    importString = "",
    heroSpec     = "Colossus",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PALADIN
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[65] = { -- Holy
    importString = "",
    heroSpec     = "Herald of the Sun",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

PVP[66] = { -- Protection
    importString = "",
    heroSpec     = "Templar",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

PVP[70] = { -- Retribution
    importString = "",
    heroSpec     = "Templar",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [0] = {
            pick    = "Execution Sentence",
            why     = "Burst finisher — pairs with wings for kill windows in arena.",
            alt     = "Final Reckoning",
            altWhy  = "Better in RBGs where you can reliably land the AoE.",
            pveNote = "In PvE, Final Reckoning is standard for raid burst.",
        },
    },
    levelPath = {
        [10] = { name = "Blade of Justice", why = "Holy Power generation for Templar's Verdict pressure." },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HUNTER
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[253] = { -- Beast Mastery
    importString = "",
    heroSpec     = "Pack Leader",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [0] = {
            pick    = "Intimidation",
            why     = "1-minute stun on a pet ability — crucial CC in arena.",
            alt     = "Wailing Arrow",
            altWhy  = "AoE silence for BG teamfight disruption.",
            pveNote = "In PvE, neither is mandatory — Wailing Arrow for M+ utility.",
        },
    },
    levelPath = {
        [10] = { name = "Kill Command", why = "Core damage and pet synergy." },
        [11] = { name = "Intimidation", why = "Early CC access for world PvP survivability." },
    },
}

PVP[254] = { -- Marksmanship
    importString = "",
    heroSpec     = "Dark Ranger",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [0] = {
            pick    = "Trueshot",
            why     = "Burst window — Rapid Fire + Aimed Shot pressure during Trueshot is your kill setup.",
            alt     = "Wailing Arrow",
            altWhy  = "When facing caster-heavy teams, the AoE silence wins fights.",
            pveNote = "In PvE, Trueshot timing is the same but Wailing Arrow is never taken.",
        },
    },
    levelPath = {
        [10] = { name = "Aimed Shot", why = "Core cast — your main damage in all PvP." },
    },
}

PVP[255] = { -- Survival
    importString = "",
    heroSpec     = "Pack Leader",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [0] = {
            pick    = "Mongoose Bite",
            why     = "Stacking melee pressure — each consecutive hit deals more. Insane in duels.",
            alt     = "Flanking Strike",
            altWhy  = "More consistent damage + focus gen when you can't maintain Mongoose stacks.",
            pveNote = "In PvE, Flanking Strike is preferred for smoother rotation.",
        },
    },
    levelPath = {
        [10] = { name = "Raptor Strike", why = "Bread and butter — transitions to Mongoose Bite later." },
        [11] = { name = "Harpoon",       why = "Gap closer is mandatory in PvP. Close distance instantly." },
        [12] = { name = "Muzzle",        why = "Interrupt — you MUST have this for arena/BG." },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEATH KNIGHT
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[250] = { -- Blood
    importString = "",
    heroSpec     = "San'layn",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

PVP[251] = { -- Frost
    importString = "",
    heroSpec     = "Rider of the Apocalypse",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

PVP[252] = { -- Unholy
    importString = "",
    heroSpec     = "San'layn",
    pvpTalents   = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {},
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DRUID
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[102] = { importString="", heroSpec="Keeper of the Grove", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[103] = { importString="", heroSpec="Druid of the Claw",   pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[104] = { importString="", heroSpec="Elune's Chosen",      pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[105] = { importString="", heroSpec="Keeper of the Grove", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- ═══════════════════════════════════════════════════════════════════════════════
-- REMAINING SPECS (stubs — fill with real data as available)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Demon Hunter
PVP[577] = { importString="", heroSpec="Aldrachi Reaver", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[581] = { importString="", heroSpec="Aldrachi Reaver", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Evoker
PVP[1467] = { importString="", heroSpec="Scalecommander", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[1468] = { importString="", heroSpec="Chronowarden",   pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[1473] = { importString="", heroSpec="Chronowarden",   pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Mage
PVP[62]  = { importString="", heroSpec="Spellslinger", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[63]  = { importString="", heroSpec="Frostfire",    pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[64]  = { importString="", heroSpec="Frostfire",    pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Monk
PVP[268] = { importString="", heroSpec="Shado-Pan",       pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[269] = { importString="", heroSpec="Shado-Pan",       pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[270] = { importString="", heroSpec="Master of Harmony", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Priest
PVP[256] = { importString="", heroSpec="Voidweaver",  pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[257] = { importString="", heroSpec="Oracle",      pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[258] = { importString="", heroSpec="Voidweaver",  pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Rogue
PVP[259] = { importString="", heroSpec="Deathstalker", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[260] = { importString="", heroSpec="Trickster",    pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[261] = { importString="", heroSpec="Deathstalker", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Shaman
PVP[262] = { importString="", heroSpec="Stormbringer", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[263] = { importString="", heroSpec="Stormbringer", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[264] = { importString="", heroSpec="Totemic",      pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- Warlock
PVP[265] = { importString="", heroSpec="Soul Harvester", pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[266] = { importString="", heroSpec="Diabolist",      pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }
PVP[267] = { importString="", heroSpec="Diabolist",      pvpTalents={}, panels={class={},spec={},hero={}}, nodes={}, levelPath={} }

-- ═══════════════════════════════════════════════════════════════════════════════
-- API: Lookup helpers
-- ═══════════════════════════════════════════════════════════════════════════════

function TA.Data.TalentsPvP:GetForSpec(specID)
    return PVP[specID]
end

function TA.Data.TalentsPvP:GetNodeInfo(specID, nodeID)
    local spec = PVP[specID]
    if not spec or not spec.nodes then return nil end
    return spec.nodes[nodeID]
end

function TA.Data.TalentsPvP:GetLevelPath(specID)
    local spec = PVP[specID]
    if not spec then return nil end
    return spec.levelPath
end

function TA.Data.TalentsPvP:GetImportString(specID)
    local spec = PVP[specID]
    if not spec then return nil end
    return (spec.importString ~= "") and spec.importString or nil
end
