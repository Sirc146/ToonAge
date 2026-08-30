-- ToonAge/Data/Talents.lua
-- Build data for all 39 specs (Midnight 12.0.x PTR)
--
-- Schema per entry:
--   builds.{mplus|raid|solo} = { name, desc, string, nodes, levelPath }
--   string    = "" → no import string yet (copy button hidden)
--   nodes     = {} → no C_Traits IDs yet (match score hidden)
--   levelPath = table or nil → step-by-step talent at each level (10 to max)
--              { [10]="Talent A", [11]="Talent B", ... }
--              Missing levels show "follow the build above" in the leveling card.
--
-- To enable match scoring: populate nodes with C_Traits node IDs.
-- To enable leveling advisor: populate levelPath with talent name per level.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Talents = {}
local T = TA.Data.Talents
local DB = {}

-- ── WARRIOR ──────────────────────────────────────────────────────────────
DB[71] = { -- Arms
    builds = {
        mplus = {
            name = "Colossus Cleave",
            desc = "Sweeping Strikes with Colossus Smash windows for burst pack damage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Warbreaker ST",
            desc = "Mortal Strike and Overpower rhythm for sustained single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Impending Victory",
            desc = "Ignore Pain and Impending Victory self-healing for comfortable soloing.",
            string = "",
            nodes = {},
        },
    },
}
DB[72] = { -- Fury
    builds = {
        mplus = {
            name = "Meat Cleaver Pack",
            desc = "Whirlwind-empowered Rampage into Bloodthirst for consistent AoE.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Recklessness Burst",
            desc = "Bloodbath and Avatar alignment for maximum single-target burst windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Enrage Sustain",
            desc = "Enrage self-healing via Bloodthirst spam for durable open-world play.",
            string = "",
            nodes = {},
        },
    },
}
DB[73] = { -- Protection
    builds = {
        mplus = {
            name = "Ravager Threat",
            desc = "Ravager and Thunder Clap for rapid AoE threat on large packs.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Shield Block Wall",
            desc = "Shield Block uptime and Shield Slam for physical damage smoothing.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Victory Rush Tank",
            desc = "Intercept mobility with Victory Rush healing for world content.",
            string = "",
            nodes = {},
        },
    },
}

-- ── PALADIN ───────────────────────────────────────────────────────────────
DB[65] = { -- Holy
    builds = {
        mplus = {
            name = "Glimmer Beacon",
            desc = "Glimmer of Light spreading with Beacon of Virtue for group coverage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Aura Mastery Burst",
            desc = "Wings and Aura Mastery timing for critical raid healing windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Crusader Strike Healer",
            desc = "Melee hybrid with high self-sustain and Holy Shock resets.",
            string = "",
            nodes = {},
        },
    },
}
DB[66] = { -- Protection
    builds = {
        mplus = {
            name = "Avenger's Shield Prio",
            desc = "Avenger's Shield bouncing for interrupt-heavy mythic+ packs.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Consecration ST",
            desc = "Consecration and Shield of the Righteous timing for boss tanking.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Word of Glory Solo",
            desc = "Selfless Healer and Word of Glory for comfortable solo progression.",
            string = "",
            nodes = {},
        },
    },
}
DB[70] = { -- Retribution
    builds = {
        mplus = {
            name = "Templar's Verdict AoE",
            desc = "Divine Storm and Hammer of Wrath for sustained AoE pressure.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Final Reckoning Burst",
            desc = "Final Reckoning and Execution Sentence for burst single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Crusade Open World",
            desc = "Crusade and Inquisition for rapid open-world clears.",
            string = "",
            nodes = {},
        },
    },
}

-- ── DEATH KNIGHT ─────────────────────────────────────────────────────────
DB[250] = { -- Blood
    builds = {
        mplus = {
            name = "Death and Decay Tank",
            desc = "Bone Shield maintenance and Heart Strike for heavy AoE threat.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Death Strike Efficiency",
            desc = "Maximizing Death Strike healing with Ossuary uptime on bosses.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Crimson Scourge Solo",
            desc = "Near-immortal self-sustain with Consumption and Death Pact.",
            string = "",
            nodes = {},
        },
    },
}
DB[251] = { -- Frost
    builds = {
        mplus = {
            name = "Remorseless Pack",
            desc = "Remorseless Winter and Howling Blast for consistent pack damage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Obliteration Window",
            desc = "Killing Machine alignment with Obliteration for burst phases.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Glacial Advance",
            desc = "Glacial Advance and Breath of Sindragosa for solo efficiency.",
            string = "",
            nodes = {},
        },
    },
}
DB[252] = { -- Unholy
    builds = {
        mplus = {
            name = "Festering Cleave",
            desc = "Festering Wound stacking and Scourge Strike for cleave pressure.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Dark Transformation",
            desc = "Army of the Dead and Apocalypse timing for boss burst windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Army of the Damned",
            desc = "Pet army with Raise Abomination for durable open-world farming.",
            string = "",
            nodes = {},
        },
    },
}

-- ── DEMON HUNTER ─────────────────────────────────────────────────────────
DB[577] = { -- Havoc
    builds = {
        mplus = {
            name = "Fel Rush Cleave",
            desc = "Eye Beam and Chaos Nova for burst AoE with Momentum uptime.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Essence Break ST",
            desc = "Essence Break and Metamorphosis alignment for single-target burst.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Unbound Chaos",
            desc = "Fel Rush resets and Unbound Chaos empowerment for fast mob clearing.",
            string = "",
            nodes = {},
        },
    },
}
DB[581] = { -- Vengeance
    builds = {
        mplus = {
            name = "Fiery Brand Rotate",
            desc = "Fiery Brand rotation and Sigil of Chains for pack control.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Fel Devastation ST",
            desc = "Fel Devastation self-healing and Spirit Bomb for boss mitigation.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Painbringer Self-Heal",
            desc = "Soul Fragment generation and Painbringer for near-unkillable soloing.",
            string = "",
            nodes = {},
        },
    },
}

-- ── DRUID ─────────────────────────────────────────────────────────────────
DB[102] = { -- Balance
    builds = {
        mplus = {
            name = "Starfall Spread",
            desc = "Stellar Flare and Starfall for consistent sustained pack damage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Celestial Alignment ST",
            desc = "Celestial Alignment windows with Convoke the Spirits burst.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Moonkin Form Soloing",
            desc = "Wild Charge mobility and Sunfire spread for efficient open-world farming.",
            string = "",
            nodes = {},
        },
    },
}
DB[103] = { -- Feral
    builds = {
        mplus = {
            name = "Primal Wrath Bleed",
            desc = "Primal Wrath and Rampant Ferocity for bleed-stack cleave.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Tiger's Fury Rip",
            desc = "Tiger's Fury and Berserk for maximum Rip single-target uptime.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Predator Reset",
            desc = "Predator talent for Shred reset chains on world mobs.",
            string = "",
            nodes = {},
        },
    },
}
DB[104] = { -- Guardian
    builds = {
        mplus = {
            name = "Ironfur Stacks",
            desc = "Ironfur maintenance and Galactic Guardian Moonfire for AoE threat.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Frenzied Regen Timing",
            desc = "Survival Instincts and Frenzied Regeneration for raid boss tanking.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Thrash Tank Solo",
            desc = "Thrash and Mauling strikes for comfortable open-world content.",
            string = "",
            nodes = {},
        },
    },
}
DB[105] = { -- Restoration
    builds = {
        mplus = {
            name = "Efflorescence M+",
            desc = "Efflorescence and Wild Growth for efficient sustained group healing.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Flourish Extension",
            desc = "Flourish and Convoke for extended Tranquility throughput on raid damage.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Balance Affinity Heal",
            desc = "Moonfire range and Regrowth self-sustain for comfortable questing.",
            string = "",
            nodes = {},
        },
    },
}

-- ── HUNTER ───────────────────────────────────────────────────────────────
DB[253] = { -- Beast Mastery
    builds = {
        mplus = {
            name = "Beast Cleave Pack",
            desc = "Multi-Shot Beast Cleave and Barrage for strong pack clearing.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Bestial Wrath Burst",
            desc = "Bestial Wrath and Dire Beast for sustained single-target boss pressure.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Aspect of the Wild",
            desc = "High pet damage with Aspect of the Wild for open-world content.",
            string = "",
            nodes = {},
        },
    },
}
DB[254] = { -- Marksmanship
    builds = {
        mplus = {
            name = "Trick Shots AoE",
            desc = "Trick Shots with Volley for strong sustained pack damage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Aimed Shot ST",
            desc = "Aimed Shot empowerment with Lone Wolf for pure single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Careful Aim Execute",
            desc = "Careful Aim and Double Tap for fast mob and elite kills.",
            string = "",
            nodes = {},
        },
    },
}
DB[255] = { -- Survival
    builds = {
        mplus = {
            name = "Wildfire Bomb Pack",
            desc = "Wildfire Bomb spreads and Mongoose Bite stacks for cleave.",
            string = "", -- Use /ta talentscan or 'Save Current' button to fill
            nodes = {},
        },
        raid = {
            name = "Coordinated Assault",
            desc = "Coordinated Assault and Flanking Strike for burst single-target windows.",
            string = "",
            nodes = {},
        },
        pvp = {
            name = "Pack Leader PvP",
            desc = "Versatility-focused survivability with burst Coordinated Assault windows.",
            -- From user's Raidbots export (PVP loadout)
            string = "C8PAD57yiELKEty14ekTDtZEqMgxMG2gNYGGMYxMzMjxDsMPAAAAAAgZYMzyyMeAzMGWmhZAAAAGAgllZmZxMzMmhZGwMbwCmxYmZzAA",
            nodes = {},
        },
        solo = {
            name = "Terms of Engagement",
            desc = "High mobility with Terms of Engagement sustain for soloing.",
            -- Active loadout from Raidbots export (main spec)
            string = "C8PAD57yiELKEty14ekTDtZEqMgxMG2ILwMM0gFzMzMmxyAAAAAAwMGzMLLzYMjHYwQzAAAAMA4BYbZmZWMzMzMzMDgZ2AGGjZsZAA",
            nodes = {},
            -- Level-by-level talent recommendation (level 10 → 90)
            -- This is a COMPLETE progression path covering every talent point
            -- from first unlock to endgame cap. Each level that grants a point
            -- has an entry; levels without a new point are omitted.
            levelPath = {
                -- EARLY (10-20): Core kit + mobility + sustain
                [10] = "Kill Command", -- core rotational ability
                [11] = "Wildfire Bomb", -- primary AoE tool, spec identity
                [12] = "Terms of Engagement", -- Harpoon generates Focus; core sustain
                [13] = "Guerrilla Tactics", -- doubles Wildfire Bomb effectiveness
                [14] = "Tip of the Spear", -- empowers next attack after Kill Command
                [15] = "Mongoose Bite", -- replaces Raptor Strike; primary combo
                [16] = "Flanking Strike", -- pet coordinated strike; Focus gen
                [17] = "Serpent Sting", -- DoT; consistent damage on elites
                [18] = "Alpha Predator", -- extra Kill Command charge
                [19] = "Coordinated Assault", -- major DPS cooldown; defines burst windows
                [20] = "Fury of the Eagle", -- channel capstone for AoE finisher

                -- MID (21-40): Class tree + survivability + utility
                [21] = "Lone Survivor", -- Survival of the Fittest CDR when solo
                [22] = "Natural Mending", -- Exhilaration CDR from Focus spending
                [23] = "Improved Traps", -- shorter trap CDs for kiting/CC
                [24] = "Born to be Wild", -- Turtle/Cheetah CDR
                [25] = "Binding Shot", -- AoE root for pack control in M+
                [26] = "Steel Trap", -- bleed + root for elite kiting
                [27] = "Improved Kill Command", -- Kill Command deals more damage
                [28] = "Bloodseeker", -- Attack speed from bleeds on target
                [29] = "Hydra's Bite", -- Serpent Sting spreads to 2 extra targets
                [30] = "Lunge", -- Kill Command range increase for QoL
                [31] = "Spearhead", -- Bleed + crit buff cooldown (if available)
                [32] = "Ruthless Marauder", -- Fury of the Eagle improvements
                [33] = "Ranger", -- passive damage increase in melee
                [34] = "Tactical Advantage", -- Harpoon buffs next melee ability
                [35] = "Frenzy Strikes", -- Mongoose Bite resets during frenzy
                [36] = "Intense Focus", -- Kill Command Focus refund
                [37] = "Killer Companion", -- pet damage passive
                [38] = "Aspect of the Eagle", -- ranged fallback for mechanics
                [39] = "Terms of Engagement R2", -- rank 2 if available
                [40] = "Carve / Butchery", -- AoE melee for pack situations

                -- LATE (41-60): Hero talents + throughput passives
                [41] = "Pack Leader", -- Hero talent choice (recommended)
                [42] = "Vicious Hunt", -- Pack Leader: Kill Command empowers next
                [43] = "Pack Coordination", -- Pack Leader: pet synergy buff
                [44] = "Howl of the Pack", -- Pack Leader: group buff
                [45] = "Den Recovery", -- Pack Leader: self-heal proc
                [46] = "Frenzied Tear", -- Pack Leader: bleed enhancement
                [47] = "Scattered Prey", -- Pack Leader: multi-target spread
                [48] = "Cornered Prey", -- Pack Leader: execute phase buff
                [49] = "Cull the Herd", -- Pack Leader: finisher bonus vs low HP
                [50] = "Beast of Opportunity", -- Pack Leader: capstone proc

                -- ENDGAME (51-71+): Final tree points + optimization
                [51] = "Wildfire Infusion", -- Bomb variants for adaptability
                [52] = "Birds of Prey", -- extends Coordinated Assault duration
                [53] = "Explosives Expert", -- Wildfire Bomb CDR from melee
                [54] = "Deadly Duo", -- Flanking + Kill Command synergy
                [55] = "Exposed Flank", -- Flanking Strike debuff
                [56] = "Relentless Primal Ferocity", -- sustained damage passive
                [57] = "Merciless Blows", -- crit bonus after Raptor/Mongoose
                [58] = "Quick Shot", -- ranged proc between melee swings
                [59] = "Sentinel Owl", -- Hunter class capstone if available
                [60] = "Sentinel's Wisdom", -- utility capstone
            },
        },
    },
}

-- ── MAGE ─────────────────────────────────────────────────────────────────
DB[62] = { -- Arcane
    builds = {
        mplus = {
            name = "Arcane Surge Push",
            desc = "Arcane Surge and Touch of the Magi burst for heavy pull damage.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Radiant Spark Funnel",
            desc = "Radiant Spark and Arcane Missiles funnel into execute windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Clearcasting Flow",
            desc = "Clearcasting abuse and Presence of Mind for smooth open-world kills.",
            string = "",
            nodes = {},
        },
    },
}
DB[63] = { -- Fire
    builds = {
        mplus = {
            name = "Flamestrike Ignite",
            desc = "Flamestrike spread Ignite on packs with Phoenix Flames resets.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Combustion Window",
            desc = "Combustion and Scorch into Pyroblast for peak boss burst.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Hot Streak Spam",
            desc = "Hot Streak and Pyromaniac for instant Pyroblast proc chains.",
            string = "",
            nodes = {},
        },
    },
}
DB[64] = { -- Frost
    builds = {
        mplus = {
            name = "Frozen Orb Shatter",
            desc = "Frozen Orb with Splitting Ice for broad shatter combos on packs.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Icy Veins ST",
            desc = "Icy Veins and Glacial Spike for heavy single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Ice Lance Chain",
            desc = "Fingers of Frost chains and Comet Storm for fast mob kills.",
            string = "",
            nodes = {},
        },
    },
}

-- ── MONK ──────────────────────────────────────────────────────────────────
DB[268] = { -- Brewmaster
    builds = {
        mplus = {
            name = "Master of Harmony M+",
            desc = "High Stagger mitigation with exceptional AoE threat generation.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
        raid = {
            name = "Master of Harmony ST",
            desc = "Smooth physical damage intake and Purifying Brew efficiency.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJAAAAAQSSSCJJgEJSSgkkkBAA",
            nodes = {},
        },
        solo = {
            name = "Ox Stance Solo",
            desc = "Self-healing and rapid clear speed for open world content.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
    },
}
DB[269] = { -- Windwalker
    builds = {
        mplus = {
            name = "Shado-Pan Cleave",
            desc = "Spinning Crane Kick maximization and clone synchronization.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA",
            nodes = {},
        },
        raid = {
            name = "Shado-Pan ST",
            desc = "Fists of Fury channeling and single-target burst prioritization.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAA",
            nodes = {},
        },
        solo = {
            name = "Swift Clearing",
            desc = "High mobility and rapid chi generation for fast open-world kills.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA",
            nodes = {},
        },
    },
}
DB[270] = { -- Mistweaver
    builds = {
        mplus = {
            name = "Conduit of the Celestials",
            desc = "Fistweaving melee-heals prioritizing Ancient Teachings.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC",
            nodes = {},
        },
        raid = {
            name = "Conduit Raid",
            desc = "Ranged Soothing Mist channeling and Essence Font blanketing.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAAQSSSC",
            nodes = {},
        },
        solo = {
            name = "Fistweaver Solo",
            desc = "High DPS output while maintaining self-sustainability in open world.",
            string = "BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC",
            nodes = {},
        },
    },
}

-- ── PRIEST ───────────────────────────────────────────────────────────────
DB[256] = { -- Discipline
    builds = {
        mplus = {
            name = "Atonement Spam",
            desc = "Power Word: Radiance and Penance for efficient atonement group healing.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Evangelism Extension",
            desc = "Evangelism and Rapture for absorb blanket timing on heavy damage phases.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Smite Discipline",
            desc = "Mindbender damage and Atonement self-heal for solo content.",
            string = "",
            nodes = {},
        },
    },
}
DB[257] = { -- Holy
    builds = {
        mplus = {
            name = "Circle of Healing",
            desc = "Circle of Healing and Binding Heal for rapid sustained group heals.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Apotheosis Burst",
            desc = "Holy Word: Sanctify and Apotheosis for heavy raid damage windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Holy Fire DPS",
            desc = "Holy Fire DoT and Chastise stuns for practical solo content.",
            string = "",
            nodes = {},
        },
    },
}
DB[258] = { -- Shadow
    builds = {
        mplus = {
            name = "Devouring Plague AoE",
            desc = "Void Torrent spread and Mind Sear for efficient pack clearing.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Dark Ascension Burst",
            desc = "Voidform and Dark Ascension for heavy burst on boss damage phases.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Misery DoT Train",
            desc = "Vampiric Embrace sustain and Misery DoT spread for open-world farming.",
            string = "",
            nodes = {},
        },
    },
}

-- ── ROGUE ─────────────────────────────────────────────────────────────────
DB[259] = { -- Assassination
    builds = {
        mplus = {
            name = "Garrote Spread DoTs",
            desc = "Garrote cleave with Crimson Tempest for DoT spread across packs.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Kingsbane Execute",
            desc = "Kingsbane and Elaborate Planning for sustained single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Blindside Chain",
            desc = "Blindside procs and Fan of Knives for efficient mob farming.",
            string = "",
            nodes = {},
        },
    },
}
DB[260] = { -- Outlaw
    builds = {
        mplus = {
            name = "Blade Flurry Cleave",
            desc = "Blade Flurry and Roll the Bones-buffed Pistol Shot for pack cleave.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Dispatch ST",
            desc = "Ghostly Strike and Dispatch with Adrenaline Rush burst windows.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Restless Blades",
            desc = "High CDR from Restless Blades for frequent cooldown use while questing.",
            string = "",
            nodes = {},
        },
    },
}
DB[261] = { -- Subtlety
    builds = {
        mplus = {
            name = "Shadow Dance AoE",
            desc = "Shadow Dance and Black Powder for burst AoE on pack pulls.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Find Weakness ST",
            desc = "Find Weakness uptime via Shadow Dance for sustained raid damage.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Premeditation Opener",
            desc = "Shadowstep Backstab chain for quick world mob kills.",
            string = "",
            nodes = {},
        },
    },
}

-- ── SHAMAN ───────────────────────────────────────────────────────────────
DB[262] = { -- Elemental
    builds = {
        mplus = {
            name = "Stormkeeper Surge",
            desc = "Stormkeeper and Earthquake for front-loaded pack burst.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Primordial Wave Burst",
            desc = "Primordial Wave Lava Burst empowerment for single-target boss phases.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Echoes of the Elements",
            desc = "Echoes of Great Sundering for massive burst damage on elite mobs.",
            string = "",
            nodes = {},
        },
    },
}
DB[263] = { -- Enhancement
    builds = {
        mplus = {
            name = "Doom Winds Maelstrom",
            desc = "Doom Winds and Fire Nova for rapid AoE Maelstrom generation.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Ascendance Burst",
            desc = "Ascendance and Primordial Wave for physical burst single-target.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Feral Spirit Pack",
            desc = "Feral Spirit wolves and sustained Maelstrom generation for solo play.",
            string = "",
            nodes = {},
        },
    },
}
DB[264] = { -- Restoration
    builds = {
        mplus = {
            name = "Chain Heal Priority",
            desc = "Chain Heal and Cloudburst Totem for efficient sustained group healing.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Ancestral Awakening",
            desc = "Spirit Link and High Tide for raid-wide emergency coverage.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Earth Shield Sustain",
            desc = "Earth Shield self-healing and Astral Shift for survivability while questing.",
            string = "",
            nodes = {},
        },
    },
}

-- ── WARLOCK ───────────────────────────────────────────────────────────────
DB[265] = { -- Affliction
    builds = {
        mplus = {
            name = "Hellcaller M+",
            desc = "Seed of Corruption spread and rapid Agony stacking.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
        raid = {
            name = "Hellcaller Raid",
            desc = "Malefic Rapture dump windows and sustained single-target DoTs.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA",
            nodes = {},
        },
        solo = {
            name = "Voidwalker Solo",
            desc = "High leech and pet survivability for open-world farming.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
    },
}
DB[266] = { -- Demonology
    builds = {
        mplus = {
            name = "Diabolist Cleave",
            desc = "Implosion loops and massive demon swarm generation.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAA",
            nodes = {},
        },
        raid = {
            name = "Diabolist ST",
            desc = "Tyrant maximization and sustained Felguard cleave.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAA",
            nodes = {},
        },
        solo = {
            name = "Felguard Solo",
            desc = "Beefed up Felguard with quick Dreadstalker resets.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAA",
            nodes = {},
        },
    },
}
DB[267] = { -- Destruction
    builds = {
        mplus = {
            name = "Hellcaller AoE",
            desc = "Rain of Fire spam and Havoc cleave efficiency.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAAQSSSC",
            nodes = {},
        },
        raid = {
            name = "Hellcaller ST",
            desc = "Chaos Bolt optimization and Infernal burst windows.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAAQSSSC",
            nodes = {},
        },
        solo = {
            name = "Voidwalker Burst",
            desc = "Quick burst setups to instantly delete quest mobs.",
            string = "BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAAQSSSC",
            nodes = {},
        },
    },
}

-- ── EVOKER ────────────────────────────────────────────────────────────────
DB[1467] = { -- Devastation
    builds = {
        mplus = {
            name = "Scalecommander AoE",
            desc = "Massive Fire Breath spread and Shattering Star windows.",
            string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJAAAAA",
            nodes = {},
        },
        raid = {
            name = "Scalecommander ST",
            desc = "Disintegrate channeling and Dragonrage optimization.",
            string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJJkBAA",
            nodes = {},
        },
        solo = {
            name = "Leveling & Delves",
            desc = "High survivability with instant cast priority.",
            string = "BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIJJJiIBAAAAAgkkEJJJJJSiEJJAAAAA",
            nodes = {},
        },
    },
}
DB[1468] = { -- Preservation
    builds = {
        mplus = {
            name = "Chronowarden AoE",
            desc = "Echo-centric build maximizing Temporal Anomaly and Dream Breath.",
            string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiEiIJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
        raid = {
            name = "Chronowarden ST",
            desc = "Focuses on Reversion uptime and Stasis burst healing.",
            string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiESLJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA",
            nodes = {},
        },
        solo = {
            name = "Open World Solo",
            desc = "Living Flame damage optimization with self-sustain.",
            string = "BwbBAAAAAAAAAAAAAAAAAAAAAABiEgIJJJJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA",
            nodes = {},
        },
    },
}
DB[1473] = { -- Augmentation
    builds = {
        mplus = {
            name = "Prescience Buff Rota",
            desc = "Prescience rotation and Ebon Might uptime for sustained party augmentation.",
            string = "",
            nodes = {},
        },
        raid = {
            name = "Breath of Eons Burst",
            desc = "Breath of Eons and Temporal Wound alignment for coordinated raid burst.",
            string = "",
            nodes = {},
        },
        solo = {
            name = "Eruption Solo",
            desc = "Eruption and Upheaval for practical solo damage and self-sustain.",
            string = "",
            nodes = {},
        },
    },
}

-- ── Accessors ─────────────────────────────────────────────────────────────
function T:GetBySpecID(specID)
    return DB[specID]
end

-- ── Spec Name → SpecID map (for BetterTalents sync) ──────────────────────
-- BetterTalents keys builds by display name (e.g. "Affliction"), while ToonAge
-- keys by specID (e.g. 265). This table bridges the two.
-- Keys here match BetterTalents/Data/BuildData.lua exactly.
local SPEC_NAME_TO_ID = {
    -- Warrior
    ["Arms"] = 71,
    ["Fury"] = 72,
    ["Protection (Warrior)"] = 73,
    -- Paladin
    ["Holy (Paladin)"] = 65,
    ["Protection (Paladin)"] = 66,
    ["Retribution"] = 70,
    -- Death Knight
    ["Blood"] = 250,
    ["Frost (DK)"] = 251,
    ["Unholy"] = 252,
    -- Demon Hunter
    ["Havoc"] = 577,
    ["Vengeance"] = 581,
    -- Druid
    ["Balance"] = 102,
    ["Feral"] = 103,
    ["Guardian"] = 104,
    ["Restoration (Druid)"] = 105,
    -- Hunter
    ["Beast Mastery"] = 253,
    ["Marksmanship"] = 254,
    ["Survival"] = 255,
    -- Mage
    ["Arcane"] = 62,
    ["Fire"] = 63,
    ["Frost (Mage)"] = 64,
    -- Monk
    ["Brewmaster"] = 268,
    ["Windwalker"] = 269,
    ["Mistweaver"] = 270,
    -- Priest
    ["Discipline"] = 256,
    ["Holy (Priest)"] = 257,
    ["Shadow"] = 258,
    -- Rogue
    ["Assassination"] = 259,
    ["Outlaw"] = 260,
    ["Subtlety"] = 261,
    -- Shaman
    ["Elemental"] = 262,
    ["Enhancement"] = 263,
    ["Restoration (Shaman)"] = 264,
    -- Warlock
    ["Affliction"] = 265,
    ["Demonology"] = 266,
    ["Destruction"] = 267,
    -- Evoker
    ["Devastation"] = 1467,
    ["Devourer"] = nil, -- New spec? Skip until specID confirmed
    ["Preservation"] = 1468,
    ["Augmentation"] = 1473,
}

--- Mirror talent import strings from BetterTalents into ToonAge's per-spec build entries.
--- Called once on login (or on demand via /ta talentsync) after both addons are loaded.
--- Only fills in empty strings — never overwrites user-pasted data.
--- @return number — count of strings filled
function T:SyncFromBetterTalents()
    local BT = _G["BetterTalents"]
    if not BT or not BT.BuildData then
        if TA.debug then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Talents]|r BetterTalents.BuildData not found — skipped sync.")
        end
        return 0
    end

    local filled = 0
    for specName, btData in pairs(BT.BuildData) do
        -- Resolve specID from name
        local specID = SPEC_NAME_TO_ID[specName]
        if not specID then
            -- Try direct match by iterating all known specIDs and comparing
            -- against GetSpecializationInfoByID display names. This handles
            -- cases where BetterTalents uses simple names like "Frost" for
            -- unambiguous specs or future new specs.
            -- (Fallback: skip unknown names silently)
            if TA.debug then
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Talents]|r Unknown spec name: " .. specName .. " — skipped.")
            end
        end

        if specID and DB[specID] then
            local builds = DB[specID].builds

            -- M+ build: prefer mplus_overall, fallback to mplus_12
            local mplusStr = btData.mplus_overall or btData.mplus_12
            if
                mplusStr
                and mplusStr ~= ""
                and builds.mplus
                and (builds.mplus.string == "" or builds.mplus.string == nil)
            then
                builds.mplus.string = mplusStr
                filled = filled + 1
            end

            -- Raid Mythic → raid build
            local raidStr = btData.raid_mythic
            if
                raidStr
                and raidStr ~= ""
                and builds.raid
                and (builds.raid.string == "" or builds.raid.string == nil)
            then
                builds.raid.string = raidStr
                filled = filled + 1
            end

            -- Raid Heroic → store as a secondary reference (if the spec has no raid string,
            -- use heroic as fallback)
            local heroicStr = btData.raid_heroic
            if heroicStr and heroicStr ~= "" then
                -- If raid is still empty after mythic check, use heroic
                if builds.raid and (builds.raid.string == "" or builds.raid.string == nil) then
                    builds.raid.string = heroicStr
                    filled = filled + 1
                end
                -- Also store heroic as its own reference for users who want it
                if not builds.raid_heroic then
                    builds.raid_heroic = {
                        name = (builds.raid and builds.raid.name or "Raid") .. " (Heroic)",
                        desc = "Heroic raid build imported from BetterTalents log data.",
                        string = heroicStr,
                        nodes = {},
                    }
                elseif builds.raid_heroic.string == "" or builds.raid_heroic.string == nil then
                    builds.raid_heroic.string = heroicStr
                    filled = filled + 1
                end
            end
        end
    end

    if filled > 0 then
        -- INFO: an auto-import count nobody asked for. Same class as the
        -- "module loaded" notices 9959873 quieted; goes silent at the WARN default.
        TA:Raw(
            TA.LOG.INFO,
            string.format(
                "|cFFFFD100[ToonAge]|r Talent sync: imported |cFF4AFF7A%d|r build strings from BetterTalents.",
                filled
            )
        )
    elseif TA.debug then
        TA:Raw(
            TA.LOG.OUTPUT,
            "|cFFFFD100[TA Talents]|r Sync complete — no new strings needed (all slots already filled)."
        )
    end

    return filled
end

-- ── Content type labels (displayed in the tab selector) ───────────────────
T.BuildTypes = {
    { key = "mplus", label = "Mythic+" },
    { key = "raid", label = "Raid" },
    { key = "delves", label = "Delves" },
    { key = "pvp", label = "PvP" },
    { key = "solo", label = "Leveling" },
}

-- ── Auto-populate missing build types ─────────────────────────────────────
-- Many specs above only have mplus/raid/solo.  Fill in pvp and delves with
-- sensible defaults (desc + empty import string) so the UI never shows
-- "No build for this content type" when those tabs are selected.
for specID, specData in pairs(DB) do
    if not specData.builds.pvp then
        specData.builds.pvp = {
            name = "PvP Recommended",
            desc = "Versatility-focused survivability with burst windows. Fill import string with your current PvP loadout.",
            string = "",
            nodes = {},
        }
    end
    if not specData.builds.delves then
        -- Delves sit between solo and M+ difficulty.  Default to solo build
        -- with a relabeled desc until spec-specific Delve builds are researched.
        local soloRef = specData.builds.solo
        specData.builds.delves = {
            name = (soloRef and soloRef.name or "Delves Recommended") .. " (Delve)",
            desc = "Self-sustain and consistent throughput for Tier 8+ Delves. Modify from your solo build.",
            string = soloRef and soloRef.string or "",
            nodes = soloRef and soloRef.nodes or {},
        }
    end
end
