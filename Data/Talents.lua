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
local T  = TA.Data.Talents
local DB = {}

-- ── WARRIOR ──────────────────────────────────────────────────────────────
DB[71] = { -- Arms
    builds = {
        mplus = { name="Colossus Cleave",      desc="Sweeping Strikes with Colossus Smash windows for burst pack damage.",            string="", nodes={} },
        raid  = { name="Warbreaker ST",         desc="Mortal Strike and Overpower rhythm for sustained single-target.",                string="", nodes={} },
        solo  = { name="Impending Victory",     desc="Ignore Pain and Impending Victory self-healing for comfortable soloing.",        string="", nodes={} },
    }
}
DB[72] = { -- Fury
    builds = {
        mplus = { name="Meat Cleaver Pack",     desc="Whirlwind-empowered Rampage into Bloodthirst for consistent AoE.",              string="", nodes={} },
        raid  = { name="Recklessness Burst",    desc="Bloodbath and Avatar alignment for maximum single-target burst windows.",        string="", nodes={} },
        solo  = { name="Enrage Sustain",        desc="Enrage self-healing via Bloodthirst spam for durable open-world play.",         string="", nodes={} },
    }
}
DB[73] = { -- Protection
    builds = {
        mplus = { name="Ravager Threat",        desc="Ravager and Thunder Clap for rapid AoE threat on large packs.",                 string="", nodes={} },
        raid  = { name="Shield Block Wall",     desc="Shield Block uptime and Shield Slam for physical damage smoothing.",            string="", nodes={} },
        solo  = { name="Victory Rush Tank",     desc="Intercept mobility with Victory Rush healing for world content.",               string="", nodes={} },
    }
}

-- ── PALADIN ───────────────────────────────────────────────────────────────
DB[65] = { -- Holy
    builds = {
        mplus = { name="Glimmer Beacon",        desc="Glimmer of Light spreading with Beacon of Virtue for group coverage.",          string="", nodes={} },
        raid  = { name="Aura Mastery Burst",    desc="Wings and Aura Mastery timing for critical raid healing windows.",              string="", nodes={} },
        solo  = { name="Crusader Strike Healer",desc="Melee hybrid with high self-sustain and Holy Shock resets.",                   string="", nodes={} },
    }
}
DB[66] = { -- Protection
    builds = {
        mplus = { name="Avenger's Shield Prio", desc="Avenger's Shield bouncing for interrupt-heavy mythic+ packs.",                  string="", nodes={} },
        raid  = { name="Consecration ST",       desc="Consecration and Shield of the Righteous timing for boss tanking.",             string="", nodes={} },
        solo  = { name="Word of Glory Solo",    desc="Selfless Healer and Word of Glory for comfortable solo progression.",           string="", nodes={} },
    }
}
DB[70] = { -- Retribution
    builds = {
        mplus = { name="Templar's Verdict AoE", desc="Divine Storm and Hammer of Wrath for sustained AoE pressure.",                  string="", nodes={} },
        raid  = { name="Final Reckoning Burst", desc="Final Reckoning and Execution Sentence for burst single-target.",               string="", nodes={} },
        solo  = { name="Crusade Open World",    desc="Crusade and Inquisition for rapid open-world clears.",                          string="", nodes={} },
    }
}

-- ── DEATH KNIGHT ─────────────────────────────────────────────────────────
DB[250] = { -- Blood
    builds = {
        mplus = { name="Death and Decay Tank",  desc="Bone Shield maintenance and Heart Strike for heavy AoE threat.",                string="", nodes={} },
        raid  = { name="Death Strike Efficiency",desc="Maximizing Death Strike healing with Ossuary uptime on bosses.",               string="", nodes={} },
        solo  = { name="Crimson Scourge Solo",  desc="Near-immortal self-sustain with Consumption and Death Pact.",                   string="", nodes={} },
    }
}
DB[251] = { -- Frost
    builds = {
        mplus = { name="Remorseless Pack",      desc="Remorseless Winter and Howling Blast for consistent pack damage.",              string="", nodes={} },
        raid  = { name="Obliteration Window",   desc="Killing Machine alignment with Obliteration for burst phases.",                 string="", nodes={} },
        solo  = { name="Glacial Advance",       desc="Glacial Advance and Breath of Sindragosa for solo efficiency.",                 string="", nodes={} },
    }
}
DB[252] = { -- Unholy
    builds = {
        mplus = { name="Festering Cleave",      desc="Festering Wound stacking and Scourge Strike for cleave pressure.",              string="", nodes={} },
        raid  = { name="Dark Transformation",   desc="Army of the Dead and Apocalypse timing for boss burst windows.",                string="", nodes={} },
        solo  = { name="Army of the Damned",    desc="Pet army with Raise Abomination for durable open-world farming.",               string="", nodes={} },
    }
}

-- ── DEMON HUNTER ─────────────────────────────────────────────────────────
DB[577] = { -- Havoc
    builds = {
        mplus = { name="Fel Rush Cleave",       desc="Eye Beam and Chaos Nova for burst AoE with Momentum uptime.",                  string="", nodes={} },
        raid  = { name="Essence Break ST",      desc="Essence Break and Metamorphosis alignment for single-target burst.",            string="", nodes={} },
        solo  = { name="Unbound Chaos",         desc="Fel Rush resets and Unbound Chaos empowerment for fast mob clearing.",          string="", nodes={} },
    }
}
DB[581] = { -- Vengeance
    builds = {
        mplus = { name="Fiery Brand Rotate",    desc="Fiery Brand rotation and Sigil of Chains for pack control.",                   string="", nodes={} },
        raid  = { name="Fel Devastation ST",    desc="Fel Devastation self-healing and Spirit Bomb for boss mitigation.",             string="", nodes={} },
        solo  = { name="Painbringer Self-Heal", desc="Soul Fragment generation and Painbringer for near-unkillable soloing.",         string="", nodes={} },
    }
}

-- ── DRUID ─────────────────────────────────────────────────────────────────
DB[102] = { -- Balance
    builds = {
        mplus = { name="Starfall Spread",       desc="Stellar Flare and Starfall for consistent sustained pack damage.",              string="", nodes={} },
        raid  = { name="Celestial Alignment ST",desc="Celestial Alignment windows with Convoke the Spirits burst.",                  string="", nodes={} },
        solo  = { name="Moonkin Form Soloing",  desc="Wild Charge mobility and Sunfire spread for efficient open-world farming.",     string="", nodes={} },
    }
}
DB[103] = { -- Feral
    builds = {
        mplus = { name="Primal Wrath Bleed",    desc="Primal Wrath and Rampant Ferocity for bleed-stack cleave.",                    string="", nodes={} },
        raid  = { name="Tiger's Fury Rip",      desc="Tiger's Fury and Berserk for maximum Rip single-target uptime.",               string="", nodes={} },
        solo  = { name="Predator Reset",        desc="Predator talent for Shred reset chains on world mobs.",                         string="", nodes={} },
    }
}
DB[104] = { -- Guardian
    builds = {
        mplus = { name="Ironfur Stacks",        desc="Ironfur maintenance and Galactic Guardian Moonfire for AoE threat.",            string="", nodes={} },
        raid  = { name="Frenzied Regen Timing", desc="Survival Instincts and Frenzied Regeneration for raid boss tanking.",           string="", nodes={} },
        solo  = { name="Thrash Tank Solo",      desc="Thrash and Mauling strikes for comfortable open-world content.",                string="", nodes={} },
    }
}
DB[105] = { -- Restoration
    builds = {
        mplus = { name="Efflorescence M+",      desc="Efflorescence and Wild Growth for efficient sustained group healing.",           string="", nodes={} },
        raid  = { name="Flourish Extension",    desc="Flourish and Convoke for extended Tranquility throughput on raid damage.",       string="", nodes={} },
        solo  = { name="Balance Affinity Heal", desc="Moonfire range and Regrowth self-sustain for comfortable questing.",            string="", nodes={} },
    }
}

-- ── HUNTER ───────────────────────────────────────────────────────────────
DB[253] = { -- Beast Mastery
    builds = {
        mplus = { name="Beast Cleave Pack",     desc="Multi-Shot Beast Cleave and Barrage for strong pack clearing.",                 string="", nodes={} },
        raid  = { name="Bestial Wrath Burst",   desc="Bestial Wrath and Dire Beast for sustained single-target boss pressure.",       string="", nodes={} },
        solo  = { name="Aspect of the Wild",    desc="High pet damage with Aspect of the Wild for open-world content.",              string="", nodes={} },
    }
}
DB[254] = { -- Marksmanship
    builds = {
        mplus = { name="Trick Shots AoE",       desc="Trick Shots with Volley for strong sustained pack damage.",                     string="", nodes={} },
        raid  = { name="Aimed Shot ST",         desc="Aimed Shot empowerment with Lone Wolf for pure single-target.",                 string="", nodes={} },
        solo  = { name="Careful Aim Execute",   desc="Careful Aim and Double Tap for fast mob and elite kills.",                      string="", nodes={} },
    }
}
DB[255] = { -- Survival
    builds = {
        mplus = { name="Wildfire Bomb Pack",    desc="Wildfire Bomb spreads and Mongoose Bite stacks for cleave.",                    string="", nodes={} },
        raid  = { name="Coordinated Assault",   desc="Coordinated Assault and Flanking Strike for burst single-target windows.",      string="", nodes={} },
        solo  = {
            name  = "Terms of Engagement",
            desc  = "High mobility with Terms of Engagement sustain for soloing.",
            string = "",
            nodes  = {},
            -- levelPath: one recommended talent name per level (10 → max).
            -- Fill this in as you verify talent names in-game.
            -- Levels with no entry fall back to "follow the build above."
            levelPath = {
                [10] = "Wildfire Bomb",        -- defines the spec; take first
                [11] = "Terms of Engagement",  -- Harpoon generates Focus; core sustain
                [12] = "Guerrilla Tactics",    -- doubles Wildfire Bomb effectiveness
                [13] = "Tip of the Spear",     -- empowers next attack after Mongoose Bite
                [14] = "Mongoose Bite",        -- primary combo builder, replaces Raptor Strike
                [15] = "Flanking Strike",      -- coordinated pet strike; damage + pet synergy
                [16] = "Serpent Sting",        -- DoT for consistent damage on elites
                [17] = "Alpha Predator",       -- extra Mongoose Bite charge for sustain
                [18] = "Birds of Prey",        -- extends Coordinated Assault on Raptor Strike
                [19] = "Coordinated Assault",  -- major DPS cooldown; unlock before instancing
                [20] = "Fury of the Eagle",    -- powerful channel capstone; plan around it
            },
        },
    }
}

-- ── MAGE ─────────────────────────────────────────────────────────────────
DB[62] = { -- Arcane
    builds = {
        mplus = { name="Arcane Surge Push",     desc="Arcane Surge and Touch of the Magi burst for heavy pull damage.",              string="", nodes={} },
        raid  = { name="Radiant Spark Funnel",  desc="Radiant Spark and Arcane Missiles funnel into execute windows.",               string="", nodes={} },
        solo  = { name="Clearcasting Flow",     desc="Clearcasting abuse and Presence of Mind for smooth open-world kills.",          string="", nodes={} },
    }
}
DB[63] = { -- Fire
    builds = {
        mplus = { name="Flamestrike Ignite",    desc="Flamestrike spread Ignite on packs with Phoenix Flames resets.",               string="", nodes={} },
        raid  = { name="Combustion Window",     desc="Combustion and Scorch into Pyroblast for peak boss burst.",                     string="", nodes={} },
        solo  = { name="Hot Streak Spam",       desc="Hot Streak and Pyromaniac for instant Pyroblast proc chains.",                  string="", nodes={} },
    }
}
DB[64] = { -- Frost
    builds = {
        mplus = { name="Frozen Orb Shatter",    desc="Frozen Orb with Splitting Ice for broad shatter combos on packs.",             string="", nodes={} },
        raid  = { name="Icy Veins ST",          desc="Icy Veins and Glacial Spike for heavy single-target.",                         string="", nodes={} },
        solo  = { name="Ice Lance Chain",       desc="Fingers of Frost chains and Comet Storm for fast mob kills.",                   string="", nodes={} },
    }
}

-- ── MONK ──────────────────────────────────────────────────────────────────
DB[268] = { -- Brewmaster
    builds = {
        mplus = { name="Master of Harmony M+",  desc="High Stagger mitigation with exceptional AoE threat generation.",              string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA", nodes={} },
        raid  = { name="Master of Harmony ST",  desc="Smooth physical damage intake and Purifying Brew efficiency.",                 string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJAAAAAQSSSCJJgEJSSgkkkBAA", nodes={} },
        solo  = { name="Ox Stance Solo",        desc="Self-healing and rapid clear speed for open world content.",                    string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgkEJJJJJSiEJJJkBAAQSSSCJJgEJSSgkkEAAA", nodes={} },
    }
}
DB[269] = { -- Windwalker
    builds = {
        mplus = { name="Shado-Pan Cleave",      desc="Spinning Crane Kick maximization and clone synchronization.",                  string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA", nodes={} },
        raid  = { name="Shado-Pan ST",          desc="Fists of Fury channeling and single-target burst prioritization.",             string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAA", nodes={} },
        solo  = { name="Swift Clearing",        desc="High mobility and rapid chi generation for fast open-world kills.",             string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAA", nodes={} },
    }
}
DB[270] = { -- Mistweaver
    builds = {
        mplus = { name="Conduit of the Celestials",desc="Fistweaving melee-heals prioritizing Ancient Teachings.",                   string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC", nodes={} },
        raid  = { name="Conduit Raid",          desc="Ranged Soothing Mist channeling and Essence Font blanketing.",                 string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAgkEJJJJJSiEJJAAAAAQSSSC", nodes={} },
        solo  = { name="Fistweaver Solo",       desc="High DPS output while maintaining self-sustainability in open world.",          string="BwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAgkEJJJJJSiEJJJkBAAQSSSC", nodes={} },
    }
}

-- ── PRIEST ───────────────────────────────────────────────────────────────
DB[256] = { -- Discipline
    builds = {
        mplus = { name="Atonement Spam",        desc="Power Word: Radiance and Penance for efficient atonement group healing.",       string="", nodes={} },
        raid  = { name="Evangelism Extension",  desc="Evangelism and Rapture for absorb blanket timing on heavy damage phases.",      string="", nodes={} },
        solo  = { name="Smite Discipline",      desc="Mindbender damage and Atonement self-heal for solo content.",                   string="", nodes={} },
    }
}
DB[257] = { -- Holy
    builds = {
        mplus = { name="Circle of Healing",     desc="Circle of Healing and Binding Heal for rapid sustained group heals.",           string="", nodes={} },
        raid  = { name="Apotheosis Burst",      desc="Holy Word: Sanctify and Apotheosis for heavy raid damage windows.",             string="", nodes={} },
        solo  = { name="Holy Fire DPS",         desc="Holy Fire DoT and Chastise stuns for practical solo content.",                  string="", nodes={} },
    }
}
DB[258] = { -- Shadow
    builds = {
        mplus = { name="Devouring Plague AoE",  desc="Void Torrent spread and Mind Sear for efficient pack clearing.",               string="", nodes={} },
        raid  = { name="Dark Ascension Burst",  desc="Voidform and Dark Ascension for heavy burst on boss damage phases.",            string="", nodes={} },
        solo  = { name="Misery DoT Train",      desc="Vampiric Embrace sustain and Misery DoT spread for open-world farming.",        string="", nodes={} },
    }
}

-- ── ROGUE ─────────────────────────────────────────────────────────────────
DB[259] = { -- Assassination
    builds = {
        mplus = { name="Garrote Spread DoTs",   desc="Garrote cleave with Crimson Tempest for DoT spread across packs.",             string="", nodes={} },
        raid  = { name="Kingsbane Execute",     desc="Kingsbane and Elaborate Planning for sustained single-target.",                 string="", nodes={} },
        solo  = { name="Blindside Chain",       desc="Blindside procs and Fan of Knives for efficient mob farming.",                  string="", nodes={} },
    }
}
DB[260] = { -- Outlaw
    builds = {
        mplus = { name="Blade Flurry Cleave",   desc="Blade Flurry and Roll the Bones-buffed Pistol Shot for pack cleave.",          string="", nodes={} },
        raid  = { name="Dispatch ST",           desc="Ghostly Strike and Dispatch with Adrenaline Rush burst windows.",              string="", nodes={} },
        solo  = { name="Restless Blades",       desc="High CDR from Restless Blades for frequent cooldown use while questing.",       string="", nodes={} },
    }
}
DB[261] = { -- Subtlety
    builds = {
        mplus = { name="Shadow Dance AoE",      desc="Shadow Dance and Black Powder for burst AoE on pack pulls.",                   string="", nodes={} },
        raid  = { name="Find Weakness ST",      desc="Find Weakness uptime via Shadow Dance for sustained raid damage.",              string="", nodes={} },
        solo  = { name="Premeditation Opener",  desc="Shadowstep Backstab chain for quick world mob kills.",                          string="", nodes={} },
    }
}

-- ── SHAMAN ───────────────────────────────────────────────────────────────
DB[262] = { -- Elemental
    builds = {
        mplus = { name="Stormkeeper Surge",     desc="Stormkeeper and Earthquake for front-loaded pack burst.",                      string="", nodes={} },
        raid  = { name="Primordial Wave Burst", desc="Primordial Wave Lava Burst empowerment for single-target boss phases.",         string="", nodes={} },
        solo  = { name="Echoes of the Elements",desc="Echoes of Great Sundering for massive burst damage on elite mobs.",             string="", nodes={} },
    }
}
DB[263] = { -- Enhancement
    builds = {
        mplus = { name="Doom Winds Maelstrom",  desc="Doom Winds and Fire Nova for rapid AoE Maelstrom generation.",                 string="", nodes={} },
        raid  = { name="Ascendance Burst",      desc="Ascendance and Primordial Wave for physical burst single-target.",              string="", nodes={} },
        solo  = { name="Feral Spirit Pack",     desc="Feral Spirit wolves and sustained Maelstrom generation for solo play.",         string="", nodes={} },
    }
}
DB[264] = { -- Restoration
    builds = {
        mplus = { name="Chain Heal Priority",   desc="Chain Heal and Cloudburst Totem for efficient sustained group healing.",        string="", nodes={} },
        raid  = { name="Ancestral Awakening",   desc="Spirit Link and High Tide for raid-wide emergency coverage.",                  string="", nodes={} },
        solo  = { name="Earth Shield Sustain",  desc="Earth Shield self-healing and Astral Shift for survivability while questing.", string="", nodes={} },
    }
}

-- ── WARLOCK ───────────────────────────────────────────────────────────────
DB[265] = { -- Affliction
    builds = {
        mplus = { name="Hellcaller M+",         desc="Seed of Corruption spread and rapid Agony stacking.",                          string="BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA", nodes={} },
        raid  = { name="Hellcaller Raid",       desc="Malefic Rapture dump windows and sustained single-target DoTs.",               string="BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA", nodes={} },
        solo  = { name="Voidwalker Solo",       desc="High leech and pet survivability for open-world farming.",                     string="BqQAAAAAAAAAAAAAAAAAAAAAAAIJRIJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA", nodes={} },
    }
}
DB[266] = { -- Demonology
    builds = {
        mplus = { name="Diabolist Cleave",      desc="Implosion loops and massive demon swarm generation.",                          string="BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAA", nodes={} },
        raid  = { name="Diabolist ST",          desc="Tyrant maximization and sustained Felguard cleave.",                           string="BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAA", nodes={} },
        solo  = { name="Felguard Solo",         desc="Beefed up Felguard with quick Dreadstalker resets.",                           string="BqQAAAAAAAAAAAAAAAAAAAAAAAQSSSCJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAA", nodes={} },
    }
}
DB[267] = { -- Destruction
    builds = {
        mplus = { name="Hellcaller AoE",        desc="Rain of Fire spam and Havoc cleave efficiency.",                               string="BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIRSSiIBAAAAAQSSSC", nodes={} },
        raid  = { name="Hellcaller ST",         desc="Chaos Bolt optimization and Infernal burst windows.",                          string="BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkkBAAIJRIJikIcgIRSSiIBAAAAAQSSSC", nodes={} },
        solo  = { name="Voidwalker Burst",      desc="Quick burst setups to instantly delete quest mobs.",                           string="BqQAAAAAAAAAAAAAAAAAAAAAAAJJgEJSSgkkEAAAIJRIJikIcgIJJJiIBAAAAAQSSSC", nodes={} },
    }
}

-- ── EVOKER ────────────────────────────────────────────────────────────────
DB[1467] = { -- Devastation
    builds = {
        mplus = { name="Scalecommander AoE",    desc="Massive Fire Breath spread and Shattering Star windows.",                      string="BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJAAAAA", nodes={} },
        raid  = { name="Scalecommander ST",     desc="Disintegrate channeling and Dragonrage optimization.",                         string="BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIRSSiIBAAAAAgkkEJJJJJSiEJJJkBAA", nodes={} },
        solo  = { name="Leveling & Delves",     desc="High survivability with instant cast priority.",                               string="BqbBAAAAAAAAAAAAAAAAAAAAAABSEiEJJhIcgIJJJiIBAAAAAgkkEJJJJJSiEJJAAAAA", nodes={} },
    }
}
DB[1468] = { -- Preservation
    builds = {
        mplus = { name="Chronowarden AoE",      desc="Echo-centric build maximizing Temporal Anomaly and Dream Breath.",             string="BwbBAAAAAAAAAAAAAAAAAAAAAABiEiIJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkEAAA", nodes={} },
        raid  = { name="Chronowarden ST",       desc="Focuses on Reversion uptime and Stasis burst healing.",                        string="BwbBAAAAAAAAAAAAAAAAAAAAAABiESLJJJikIcgIRSSiIBAAAAAQSSSCJJgEJSSgkkkBAA", nodes={} },
        solo  = { name="Open World Solo",       desc="Living Flame damage optimization with self-sustain.",                          string="BwbBAAAAAAAAAAAAAAAAAAAAAABiEgIJJJJikIcgIJJJiIBAAAAAQSSSCJJgEJSSgkkEAAA", nodes={} },
    }
}
DB[1473] = { -- Augmentation
    builds = {
        mplus = { name="Prescience Buff Rota",  desc="Prescience rotation and Ebon Might uptime for sustained party augmentation.", string="", nodes={} },
        raid  = { name="Breath of Eons Burst",  desc="Breath of Eons and Temporal Wound alignment for coordinated raid burst.",      string="", nodes={} },
        solo  = { name="Eruption Solo",         desc="Eruption and Upheaval for practical solo damage and self-sustain.",             string="", nodes={} },
    }
}

-- ── Accessors ─────────────────────────────────────────────────────────────
function T:GetBySpecID(specID)
    return DB[specID]
end
