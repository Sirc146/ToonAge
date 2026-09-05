-- ToonAge/Data/TalentsPvP.lua
-- PvP-specific talent data: recommended nodes, explanations, alternatives.
--
-- Schema:
--   TA.Data.TalentsPvP[specID] = {
--       importString = "...",           -- full PvP loadout string (Blizzard format)
--       heroSpec     = "Pack Leader"|"Dark Ranger"|etc, -- recommended hero talent tree
--       pvpTalents   = { spellID, spellID, spellID },  -- informational only; the live
--                                        -- "PvP Talents" panel reads slot data straight
--                                        -- from C_SpecializationInfo, not from here.
--       panels = {
--           class = { nodes },   -- class tree picks
--           spec  = { nodes },   -- spec tree picks
--           hero  = { nodes },   -- hero talent picks
--       },
--       nodes = {
--           [spellID] = {
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
-- NOTE: `nodes` is keyed by the talent's spellID, matched against each live tree
-- node's entries (TalentsPvP.lua:RenderTreePanel) — NOT by the node's own nodeID.
-- Real nodeIDs can only be captured from a live client (C_Traits) so a data file
-- can't ship them pre-populated; spellIDs are stable and can be sourced from
-- Wowhead/icy-veins ahead of time, so keying on those is what actually works.

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.TalentsPvP = {}

local PVP = TA.Data.TalentsPvP

-- ═══════════════════════════════════════════════════════════════════════════════
-- WARRIOR
-- ═══════════════════════════════════════════════════════════════════════════════

-- NOTE (Arms hero talent): live PvP guides don't show a strong lean either way
-- between Colossus/Slayer for Arms right now (icy-veins treats both as viable
-- per-matchup) — kept as Colossus rather than guessing a "correction" the data
-- doesn't support. Fury and Protection below DID have a clear, verified lean.
PVP[71] = { -- Arms
    importString = "",
    heroSpec = "Colossus",
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [1219165] = { -- Sharpen Blade
            pick = "Sharpen Blade",
            why = "Near-mandatory burst+healing-reduction combo that secures kills through healer mitigation.",
            alt = "Storm of Destruction",
            altWhy = "Safe generalist pick giving Bladestorm/Ravager/Demolish a 60% snare + 50% healing reduction.",
            pveNote = "PvP-only talent row, not used in PvE.",
        },
        [236308] = { -- Storm of Destruction
            pick = "Storm of Destruction",
            why = "Gives Arms team-wide slow/peel utility off existing CDs, works in nearly any comp.",
            alt = "Disarm",
            altWhy = "Shuts down weapon-dependent physical classes entirely.",
            pveNote = "PvP-only talent, N/A in PvE.",
        },
    },
    levelPath = {
        [10] = { name = "Mortal Strike", why = "Core ability — healing reduction is king in PvP." },
        [11] = { name = "Impending Victory", why = "Self-healing to survive between healer CDs." },
    },
}

PVP[72] = { -- Fury
    importString = "",
    heroSpec = "Mountain Thane", -- corrected from Slayer: murlok.io top-50 3v3 shows 39/50 on Mountain Thane
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [352998] = { -- Slaughterhouse
            pick = "Slaughterhouse",
            why = "Fury's only source of a Mortal Wounds-style healing-reduction debuff, essentially mandatory in arena.",
            alt = "Enduring Rage",
            altWhy = "Extends Enrage uptime for sustained damage windows when healing-reduction is less critical.",
            pveNote = "PvP-only talent, not used in PvE.",
        },
        [198877] = { -- Enduring Rage
            pick = "Enduring Rage",
            why = "Used by most top Fury players to keep Enrage active through CC-heavy PvP exchanges.",
            alt = "Disarm",
            altWhy = "Neutralizes weapon-reliant melee threats.",
            pveNote = "PvP-only talent, N/A in PvE.",
        },
    },
    levelPath = {
        [10] = { name = "Bloodthirst", why = "Self-healing baseline — keeps you alive in skirmishes." },
    },
}

PVP[73] = { -- Protection
    importString = "",
    heroSpec = "Mountain Thane", -- corrected from Colossus: top-rated Prot 2v2 players run Mountain Thane exclusively
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [199023] = { -- Morale Killer
            pick = "Morale Killer",
            why = "Near-universal pick — turns a self-only cooldown into team-wide damage reduction plus faster rage generation.",
            alt = "Thunderstruck",
            altWhy = "Adds a DR-free root proc off Avatar/Shockwave/Stormbolt for peeling when the team lacks other roots.",
            pveNote = "PvP-only talent, not used in PvE.",
        },
        [199045] = { -- Thunderstruck
            pick = "Thunderstruck",
            why = "Provides reliable, DR-independent CC to peel for teammates when the comp has no other root.",
            alt = "Berserker Roar",
            altWhy = "Better vs. CC-heavy comps (RMP/Jungle Cleave) needing a break-free/anti-CC tool instead of a root.",
            pveNote = "PvP-only talent, N/A in PvE.",
        },
    },
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PALADIN
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[65] = { -- Holy
    importString = "",
    heroSpec = "Lightsmith", -- corrected from Herald of the Sun: murlok.io top-50 3v3 shows 35 Lightsmith vs 15 Herald
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [199324] = { -- Divine Vision
            pick = "Divine Vision",
            why = "Near-permanent Aura Mastery uptime for dispel-protection windows in arena.",
            alt = "Cleanse the Weak",
            altWhy = "Better vs dispel-chain-heavy comps needing double cleanses.",
            pveNote = "PvP-only talent, no PvE equivalent.",
        },
        [199330] = { -- Cleanse the Weak
            pick = "Cleanse the Weak",
            why = "Doubles dispel value, critical vs CC-chain comps.",
            alt = "Divine Vision",
            altWhy = "Better vs comps relying on sustained magic dispels.",
            pveNote = "PvP-only talent.",
        },
        [410126] = { -- Searing Glare
            pick = "Searing Glare",
            why = "Peel tool vs melee trains, breaks kill pressure.",
            alt = "Blinding Light (baseline)",
            altWhy = "Kept baseline for M+/PvE AoE stun.",
            pveNote = "PvE keeps baseline Blinding Light; Searing Glare only exists as the PvP swap.",
        },
    },
    levelPath = {},
}

PVP[66] = { -- Protection
    importString = "",
    heroSpec = "Lightsmith", -- confirmed vs Templar, but Prot arena sample sizes are small — moderate confidence
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [204018] = { -- Blessing of Spellwarding
            pick = "Blessing of Spellwarding",
            why = "Hard-counters single-target magic burst/CC in arena.",
            alt = "Blessing of Sanctuary",
            altWhy = "Better vs physical stun-cleave comps.",
            pveNote = "Rarely used in PvE tanking.",
        },
        [20066] = { -- Repentance
            pick = "Repentance",
            why = "Gives Prot a real lockdown/peel tool it otherwise lacks.",
            alt = "Hammer of Justice (baseline)",
            altWhy = "Guaranteed short stun, no cast time.",
            pveNote = "PvE Prot usually skips this for a utility/defensive pick.",
        },
        [210256] = { -- Blessing of Sanctuary
            pick = "Blessing of Sanctuary",
            why = "Breaks CC chains, key survivability in RBG/arena.",
            alt = "Hallowed Ground",
            altWhy = "Counters slow/root-kiting comps.",
            pveNote = "PvP-only talent.",
        },
    },
    levelPath = {},
}

PVP[70] = { -- Retribution
    importString = "",
    heroSpec = "Herald of the Sun", -- corrected from Templar (Templar is the PvE pick); icy-veins recommends Herald for PvP
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [210256] = { -- Blessing of Sanctuary
            pick = "Blessing of Sanctuary",
            why = "Mandatory per top guides — breaks stun/fear lockouts.",
            alt = "Blessing of Spellwarding",
            altWhy = "Preferred vs caster-heavy comps.",
            pveNote = "PvP-only, no PvE use.",
        },
        [410126] = { -- Searing Glare
            pick = "Searing Glare",
            why = "Situational CC swap vs melee cleave to reset burst.",
            alt = "Blinding Light (baseline)",
            altWhy = "Default AoE stun for PvE/Blitz.",
            pveNote = "PvE keeps baseline Blinding Light.",
        },
        [216868] = { -- Hallowed Ground
            pick = "Hallowed Ground",
            why = "Removes snares/roots so Ret maintains melee uptime vs kiting.",
            alt = "Luminescence",
            altWhy = "Boosts Lightbearer healing for 3v3 sustain comps.",
            pveNote = "PvP-only talent.",
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
    heroSpec = "Pack Leader", -- confirmed: icy-veins "Pack Leader is the better Hero Talent tree currently"
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [202746] = { -- Survival Tactics
            pick = "Survival Tactics",
            why = "Turns Feign Death into an on-demand near-immunity, the core Hunter defensive in arena.",
            alt = "Guardian's Hide",
            altWhy = "Passive 3% damage reduction via pet when you can't spare Feign Death's positioning cost.",
            pveNote = "PvE drops this row entirely for damage talents.",
        },
        [213691] = { -- Scatter Shot
            pick = "Scatter Shot",
            why = "Reliable incapacitate to peel melee or land a trap setup.",
            alt = "Chimaeral Sting",
            altWhy = "Silence+slow shuts down a healer's cast instead of disabling one target.",
            pveNote = "This PvP row has no PvE equivalent.",
        },
        [321530] = { -- Bloodshed
            pick = "Bloodshed",
            why = "Amplifies the Bestial Wrath burst window that arena kills are built around.",
            alt = "Stomp",
            altWhy = "Better vs multiple targets/pets (cleave) instead of single-target burst.",
            pveNote = "None — same pick in PvE.",
        },
    },
    levelPath = {
        [10] = { name = "Kill Command", why = "Core damage and pet synergy." },
        [11] = { name = "Intimidation", why = "Early CC access for world PvP survivability." },
    },
}

PVP[254] = { -- Marksmanship
    importString = "",
    heroSpec = "Sentinel", -- corrected from Dark Ranger: murlok.io live leaderboard shows 45 Sentinel vs 9 Dark Ranger in 2v2
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [202746] = { -- Survival Tactics
            pick = "Survival Tactics",
            why = "Same universal Feign Death defensive, ~86-100% pick rate across sources.",
            alt = "Camouflage",
            altWhy = "Stealth reset/disengage when defense isn't the immediate need.",
            pveNote = "PvE skips this row.",
        },
        [356719] = { -- Chimaeral Sting
            pick = "Chimaeral Sting",
            why = "Shuts down healer or DPS casters, ~79-98% pick rate.",
            alt = "Scatter Shot",
            altWhy = "Hard incap for melee peel instead of caster shutdown.",
            pveNote = "None — PvP-only row.",
        },
        [203340] = { -- Diamond Ice
            pick = "Diamond Ice",
            why = "Guarantees the trap CC lands against dispel-heavy comps.",
            alt = "Ranger's Finesse",
            altWhy = "When not being trained, trade CC-proofing for Volley/cooldown burst.",
            pveNote = "PvE doesn't run Freezing Trap.",
        },
    },
    levelPath = {
        [10] = { name = "Aimed Shot", why = "Core cast — your main damage in all PvP." },
    },
}

PVP[255] = { -- Survival
    importString = "",
    heroSpec = "Pack Leader", -- confirmed: icy-veins notes higher current throughput than Sentinel, which remains a viable alt
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [202746] = { -- Survival Tactics
            pick = "Survival Tactics",
            why = "Same defensive FD talent, ~91% pick rate.",
            alt = "Mending Bandage",
            altWhy = "Self-cleanse vs Feral/Rogue bleeds instead of a damage-negation window.",
            pveNote = "PvE skips this row.",
        },
        [213691] = { -- Scatter Shot
            pick = "Scatter Shot",
            why = "Core incapacitate/peel tool.",
            alt = "Diamond Ice",
            altWhy = "Undispellable trap vs dispel comps instead of a second incap.",
            pveNote = "None.",
        },
        [356719] = { -- Chimaeral Sting
            pick = "Chimaeral Sting",
            why = "Silences/kites casters.",
            alt = "Sticky Tar Bomb", -- spellID 407031
            altWhy = "Disarms a melee train instead of silencing a caster.",
            pveNote = "None.",
        },
    },
    levelPath = {
        [10] = { name = "Raptor Strike", why = "Bread and butter — transitions to Mongoose Bite later." },
        [11] = { name = "Harpoon", why = "Gap closer is mandatory in PvP. Close distance instantly." },
        [12] = { name = "Muzzle", why = "Interrupt — you MUST have this for arena/BG." },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEATH KNIGHT
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[250] = { -- Blood
    importString = "",
    heroSpec = "San'layn", -- confirmed: murlok PvP data shows 6 San'layn vs 2 Deathbringer among top Solo Shuffle players
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [47476] = { -- Strangulate
            pick = "Strangulate",
            why = "Instant, no-cast-time silence that shuts down healer/caster casts on a short CD.",
            alt = "Asphyxiate",
            altWhy = "5-second stun better vs melee-heavy comps to set up kill windows.",
            pveNote = "PvE M+ usually prefers Asphyxiate for its stun utility on packs.",
        },
        [55233] = { -- Vampiric Blood
            pick = "Vampiric Blood",
            why = "Core defensive cooldown that massively amplifies Death Strike self-healing to survive burst windows.",
            alt = "Will of the Necropolis",
            altWhy = "Passive 20% damage reduction below 30% HP — a safety net vs one more big hit.",
            pveNote = "None — both are also top PvE picks.",
        },
        [205727] = { -- Anti-Magic Barrier
            pick = "Anti-Magic Barrier",
            why = "Stronger, more frequent Anti-Magic Shell counters caster burst and magic CC comps.",
            alt = "Will of the Necropolis",
            altWhy = "Swap in vs physical/melee cleave comps instead of magic-heavy comps.",
            pveNote = "PvE priority is fight-dependent, same logic.",
        },
    },
    levelPath = {},
}

PVP[251] = { -- Frost
    importString = "",
    heroSpec = "Rider of the Apocalypse", -- confirmed: icy-veins names this the primary recommendation for arena/RBG
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [47476] = { -- Strangulate
            pick = "Strangulate",
            why = "Same silence utility, essential lockout tool in any DK PvP spec.",
            alt = "Asphyxiate",
            altWhy = "Stun for peel/kill setup vs melee.",
            pveNote = "PvE skips both for pure damage talents.",
        },
        [356470] = { -- Bitter Chill
            pick = "Bitter Chill",
            why = "Sustained anti-burst/anti-kite haste reduction, refreshable, disrupts enemy melee/caster tempo.",
            alt = "Bloodforged Armor",
            altWhy = "Better vs sustained melee pressure than a haste debuff.",
            pveNote = "PvP-only utility pick; PvE takes damage talents instead.",
        },
    },
    levelPath = {},
}

PVP[252] = { -- Unholy
    importString = "",
    heroSpec = "San'layn", -- confirmed: murlok PvP data shows universal San'layn adoption, Rider showed 0% usage
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [47476] = { -- Strangulate
            pick = "Strangulate",
            why = "Reliable silence in a spec already rich in CC.",
            alt = "Asphyxiate",
            altWhy = "Stun option when silence is on CD or vs melee.",
            pveNote = "PvE prioritizes neither.",
        },
        [205727] = { -- Anti-Magic Barrier
            pick = "Anti-Magic Barrier",
            why = "Top-used Unholy PvP defensive per usage data — stronger, more frequent AMS vs caster burst.",
            alt = "The Blood is Life", -- spellID 434260
            altWhy = "Passive sustain tied to damage output, better vs sustained pressure than burst magic.",
            pveNote = "PvE also values The Blood is Life for sustain, lower priority than DPS nodes.",
        },
    },
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DRUID
-- ═══════════════════════════════════════════════════════════════════════════════

PVP[102] = { -- Balance
    importString = "",
    heroSpec = "Keeper of the Grove", -- confirmed: u.gg S-tier/3.2% pick vs Elune's Chosen B-tier/0.3%
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [209749] = { -- Faerie Swarm
            pick = "Faerie Swarm",
            why = "Primary snare/peel to stop melee closing on a caster.",
            alt = "High Winds",
            altWhy = "Extends Cyclone/Typhoon/Roots range 5yds instead of snaring directly.",
            pveNote = "None — PvP-only.",
        },
        [233750] = { -- Moon and Stars
            pick = "Moon and Stars",
            why = "Protects burst-cast windows from melee kicks/silences.",
            alt = "Owlkin Adept",
            altWhy = "Speeds up landing Cyclone/Roots instead of protecting the cast.",
            pveNote = "None — PvP-only.",
        },
        [354541] = { -- Owlkin Adept
            pick = "Owlkin Adept",
            why = "Faster CC casts help land Cyclone before an interrupt.",
            alt = "Faerie Swarm",
            altWhy = "Guarantees a snare rather than speeding up a CC cast.",
            pveNote = "None — PvP-only.",
        },
    },
    levelPath = {},
}
PVP[103] = { -- Feral
    importString = "",
    heroSpec = "Wildstalker", -- corrected from Druid of the Claw: u.gg shows Wildstalker S-tier (86 players) vs 9
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [203242] = { -- Wicked Claws
            pick = "Wicked Claws",
            why = "Feral's only built-in healing-debuff without a dedicated Mortal Wounds source.",
            alt = "Ferocious Wound",
            altWhy = "Trades the healing-reduction for bleed damage when a teammate already brings Mortal Wounds.",
            pveNote = "Dropped entirely in PvE for pure damage talents.",
        },
        [377801] = { -- Tireless Pursuit
            pick = "Tireless Pursuit",
            why = "Prevents the speed-loss punish when shapeshifting to peel, kite, or use utility.",
            alt = "High Winds",
            altWhy = "Extends CC range instead of preserving mobility.",
            pveNote = "None — PvP-only.",
        },
        [200931] = { -- High Winds
            pick = "High Winds",
            why = "Extra range lets Feral land its CC/roots before closing to melee.",
            alt = "Tireless Pursuit",
            altWhy = "Preserves speed after shifting instead of extending CC range.",
            pveNote = "None — PvP-only.",
        },
    },
    levelPath = {},
}
PVP[104] = { -- Guardian
    importString = "",
    heroSpec = "Elune's Chosen", -- confirmed: murlok RBG data shows 12 players on Elune's Chosen vs 2 on Druid of the Claw
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [236180] = { -- Den Mother
            pick = "Den Mother",
            why = "Raid-wide HP buff plus reduced stun uptime is a core RBG survivability tool.",
            alt = "Demoralizing Roar",
            altWhy = "Trades the HP/stun-resist buff for flat AoE damage reduction.",
            pveNote = "None — PvP-only.",
        },
        [201664] = { -- Demoralizing Roar
            pick = "Demoralizing Roar",
            why = "Strong group defensive cooldown for RBG teamfight windows.",
            alt = "Overrun",
            altWhy = "Opts for a stun/knockback gap-closer over raw damage mitigation.",
            pveNote = "None — PvP-only.",
        },
        [202246] = { -- Overrun
            pick = "Overrun",
            why = "Gives Guardian a hard stun + AoE knockback engage/peel in Bear Form.",
            alt = "Den Mother",
            altWhy = "Prioritizes sustain/stun-resist over an offensive gap-closer.",
            pveNote = "None — PvP-only.",
        },
    },
    levelPath = {},
}
PVP[105] = { -- Restoration
    importString = "",
    heroSpec = "Keeper of the Grove", -- confirmed: u.gg A-tier/10.2% pick vs Wildstalker A-tier/2.1%
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [1246126] = { -- Call of Ohn'ahra
            pick = "Call of Ohn'ahra",
            why = "Instant, hard-hitting CC on demand from a pure healer is a huge swing tool.",
            alt = "Early Spring",
            altWhy = "Reduces Swiftmend/Wild Growth cooldowns for throughput instead of enabling instant Cyclone.",
            pveNote = "None — PvP-only.",
        },
        [1217474] = { -- Forest Guardian
            pick = "Forest Guardian",
            why = "Lets Resto keep healing output up while still applying pressure/CC in arena.",
            alt = "Call of Ohn'ahra",
            altWhy = "Focuses on one big CC instead of passive heal-while-casting.",
            pveNote = "None — PvP-only.",
        },
        [428937] = { -- Early Spring
            pick = "Early Spring",
            why = "More frequent burst-heal windows to answer arena burst.",
            alt = "Forest Guardian",
            altWhy = "Integrates CC into healing instead of pure cooldown reduction.",
            pveNote = "Balance spec gets a different effect from the same talent (Force of Nature CDR).",
        },
    },
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- REMAINING SPECS (stubs — fill with real data as available)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Demon Hunter
PVP[577] = { -- Havoc
    importString = "",
    heroSpec = "Aldrachi Reaver", -- confirmed
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [354489] = { -- Glimpse
            pick = "Glimpse",
            why = "Gives a CC-immune escape off your existing gap-closer, acting as a second trinket vs melee trains.",
            alt = "Reverse Magic",
            altWhy = "Better vs teams stacking magic CC (hex/poly/fear) — strips and reflects magic effects on your whole team.",
            pveNote = "PvP-only, no PvE equivalent.",
        },
        [355995] = { -- Blood Moon
            pick = "Blood Moon",
            why = "Turns your dispel into an AoE dispel plus free fragment generation, near-universal pick in top brackets.",
            alt = "Detainment",
            altWhy = "Swap in when you need extra hard lockdown on a healer instead of the dispel utility.",
            pveNote = "PvP-only talent.",
        },
        [205596] = { -- Detainment
            pick = "Detainment",
            why = "Turns Imprison into a longer healing-immune lockdown for killing priority targets.",
            alt = "Reverse Magic",
            altWhy = "Swap when the enemy leans on magic CC/dispels rather than needing extra hard-CC duration.",
            pveNote = "PvP-only.",
        },
    },
    levelPath = {},
}
PVP[581] = { -- Vengeance
    importString = "",
    heroSpec = "Annihilator", -- moderate confidence: currently favored over Aldrachi Reaver but close/tuning-sensitive
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [205630] = { -- Illidan's Grasp
            pick = "Illidan's Grasp",
            why = "Your only reliable stun-plus-displacement, key for peeling or landing kill windows in RBGs.",
            alt = "Detainment",
            altWhy = "Pick this instead when you need a longer soft-CC lock on a healer rather than a stun/toss.",
            pveNote = "PvP-only, unused in PvE tanking.",
        },
        [205627] = { -- Jagged Spikes
            pick = "Jagged Spikes",
            why = "Punishes melee trains for attacking you — a strong flag-carrier/peel defensive in RBGs.",
            alt = "Reverse Magic",
            altWhy = "Swap vs caster-heavy comps where stripping magic debuffs matters more than punishing melee.",
            pveNote = "PvP-only.",
        },
        [205626] = { -- Everlasting Hunt
            pick = "Everlasting Hunt",
            why = "Cheap always-on mobility to stick to kill targets or chase flag carriers without spending a cooldown.",
            alt = "none widely reported",
            altWhy = "n/a",
            pveNote = "PvP-only.",
        },
    },
    levelPath = {},
}

-- Evoker
PVP[1467] = { -- Devastation
    importString = "",
    heroSpec = "Scalecommander", -- confirmed: unanimous in top-ranked 3v3/Blitz/RBG samples
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [378437] = { -- Unburdened Flight
            pick = "Unburdened Flight",
            why = "Near-mandatory anti-kite tool since Hover is your only mobility.",
            alt = "Nullifying Shroud",
            altWhy = "Trades snare immunity for a one-time full-CC block vs heavy-CC comps.",
            pveNote = "PvP-only.",
        },
        [378444] = { -- Obsidian Mettle
            pick = "Obsidian Mettle",
            why = "Turns your defensive CD into interrupt/silence immunity during dive windows.",
            alt = "Time Stop", -- spellID 383340
            altWhy = "Freezes a teammate (usually healer) instead of yourself.",
            pveNote = "PvP-only.",
        },
        [358385] = { -- Landslide
            pick = "Landslide",
            why = "Devastation's only hard-CC root, key for peels/kill setup.",
            alt = "Renewing Blaze", -- spellID 374348
            altWhy = "Self-healing instead of CC.",
            pveNote = "Landslide has zero PvE value, dropped for a damage talent in raid/M+.",
        },
    },
    levelPath = {},
}
PVP[1468] = { -- Preservation
    importString = "",
    heroSpec = "Chronowarden", -- confirmed: 50/50 top-player adoption vs 0 for Flameshaper
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [378464] = { -- Nullifying Shroud
            pick = "Nullifying Shroud",
            why = "Universal pick, your only CC-breaker.",
            alt = "Scouring Flame", -- spellID 378438
            altWhy = "Anti-buff dispel instead of CC protection.",
            pveNote = "PvP-only.",
        },
        [370984] = { -- Emerald Communion
            pick = "Emerald Communion",
            why = "Only self-heal usable through hard CC.",
            alt = "Dream Simulacrum", -- spellID 1241669
            altWhy = "Safer positioning healing, no CC-immunity.",
            pveNote = "None — strong in both.",
        },
        [360806] = { -- Sleep Walk
            pick = "Sleep Walk",
            why = "Preservation's only real offensive CC to shut down a target.",
            alt = "Rescue", -- spellID 370665
            altWhy = "Repositioning/save tool instead of CC.",
            pveNote = "Sleep Walk rarely taken in PvE.",
        },
    },
    levelPath = {},
}
PVP[1473] = { -- Augmentation
    importString = "",
    heroSpec = "Scalecommander", -- corrected from Chronowarden: murlok.io leads Scalecommander in 3v3 (4-2), Blitz (5-3), and RBG (exclusive)
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [378437] = { -- Unburdened Flight
            pick = "Unburdened Flight",
            why = "100% pick rate, keeps Hover snare-immune while supporting.",
            alt = "Nullifying Shroud", -- spellID 378464
            altWhy = "Full CC block instead of snare immunity.",
            pveNote = "PvP-only.",
        },
        [378444] = { -- Obsidian Mettle
            pick = "Obsidian Mettle",
            why = "Keeps you buffing/channeling through interrupts/silences.",
            alt = "Scouring Flame", -- spellID 378438
            altWhy = "Dispel option instead.",
            pveNote = "PvP-only.",
        },
        [360827] = { -- Blistering Scales
            pick = "Blistering Scales",
            why = "Main way Augmentation protects a teammate from melee pressure.",
            alt = "Sleep Walk", -- spellID 360806
            altWhy = "Offensive CC on enemy healer instead.",
            pveNote = "None — also a core PvE cooldown.",
        },
    },
    levelPath = {},
}

-- Mage
PVP[62] = { -- Arcane
    importString = "",
    heroSpec = "Sunfury", -- corrected from Spellslinger: murlok.io Midnight S2 3v3 shows 30 Sunfury vs 8 Spellslinger
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [1220739] = { -- Overpowered Barrier
            pick = "Overpowered Barrier",
            why = "Turns Prismatic Barrier into a burst-absorption window that survives arena burst combos.",
            alt = "Ice Wall",
            altWhy = "Hard line-of-sight wall to peel melee or block a cast.",
            pveNote = "PvP talent row doesn't exist in PvE content.",
        },
        [235711] = { -- Chrono Shift
            pick = "Chrono Shift",
            why = "Gives Arcane its only reliable slow, letting Arcane Barrage double as a kite/peel tool.",
            alt = "Improved Mass Invisibility",
            altWhy = "Emergency vanish to save yourself or a teammate.",
            pveNote = "None — PvP-only.",
        },
        [415945] = { -- Improved Mass Invisibility
            pick = "Improved Mass Invisibility",
            why = "2nd-most-picked Arcane PvP talent, a repeatable team-saving defensive cooldown.",
            alt = "Master Shepherd",
            altWhy = "Punishes Polymorph chains with +25% speed/+12% Vers.",
            pveNote = "None.",
        },
    },
    levelPath = {},
}
PVP[63] = { -- Fire
    importString = "",
    heroSpec = "Sunfury", -- corrected from Frostfire: murlok.io shows 45 Sunfury vs 5 Frostfire among top Fire arena players
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [1220739] = { -- Overpowered Barrier
            pick = "Overpowered Barrier",
            why = "Fire's only baseline shield — its 60%-absorb window is a key defensive against dive comps.",
            alt = "Master Shepherd",
            altWhy = "Extra speed/Vers while Polymorph is active, aiding Fire's dive-and-reset playstyle.",
            pveNote = "PvP-only row.",
        },
        [415945] = { -- Improved Mass Invisibility
            pick = "Improved Mass Invisibility",
            why = "Most-picked Fire PvP talent — primary defensive/save for a squishy burst caster.",
            alt = "Ice Wall",
            altWhy = "Situational LoS peel against melee trains.",
            pveNote = "None.",
        },
        [410248] = { -- Master Shepherd
            pick = "Master Shepherd",
            why = "Closes the old poly-dispel-heal exploit and adds mobility for Fire's burst windows.",
            alt = "Ice Wall",
            altWhy = "Extra peel/LoS on top of a barrier reset.",
            pveNote = "None.",
        },
    },
    levelPath = {},
}
PVP[64] = { -- Frost
    importString = "",
    heroSpec = "Spellslinger", -- corrected from Frostfire: murlok.io shows 41 Spellslinger vs 4 Frostfire among top Frost arena players
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [415945] = { -- Improved Mass Invisibility
            pick = "Improved Mass Invisibility",
            why = "#1 Frost PvP pick — main defensive/save vs enemy burst windows.",
            alt = "Overpowered Barrier",
            altWhy = "Ice Barrier absorb as a secondary defensive layer.",
            pveNote = "None.",
        },
        [1220739] = { -- Overpowered Barrier
            pick = "Overpowered Barrier",
            why = "Near-mandatory — Ice Barrier's boosted absorb is Frost's key defensive cooldown.",
            alt = "Snowdrift",
            altWhy = "AoE slow that stuns after 2s exposure, extra CC vs melee.",
            pveNote = "None.",
        },
        [410248] = { -- Master Shepherd
            pick = "Master Shepherd",
            why = "Adds mobility/Vers during chain-Polymorph setups.",
            alt = "Snowdrift", -- spellID 389794
            altWhy = "Converts a kiting slow into a hard stun.",
            pveNote = "None. Note: Ring of Frost has fallen out of the PvP meta entirely (0% pick rate in current data) — don't treat it as a defining Frost CC talent.",
        },
    },
    levelPath = {},
}

-- Monk
PVP[268] = { -- Brewmaster
    importString = "",
    heroSpec = "Shado-Pan", -- medium confidence: Brewmaster PvP is rarely played, small sample; Master of Harmony is the pure-defense alt
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [115203] = { -- Fortifying Brew
            pick = "Fortifying Brew",
            why = "Core damage-reduction CD needed to survive burst windows in arena/BG.",
            alt = "Celestial Brew",
            altWhy = "Absorb shield better vs magic-heavy comps.",
            pveNote = "None.",
        },
        [116705] = { -- Spear Hand Strike
            pick = "Spear Hand Strike",
            why = "Mandatory interrupt to stop enemy healer casts.",
            alt = "none (baseline class talent)",
            altWhy = "n/a",
            pveNote = "None.",
        },
        [116844] = { -- Ring of Peace
            pick = "Ring of Peace",
            why = "Knocks/ejects melee off your healer for map control.",
            alt = "Diffuse Magic", -- spellID 122783
            altWhy = "Better vs heavy magic-damage comps.",
            pveNote = "Rarely taken in PvE.",
        },
    },
    levelPath = {},
}
PVP[269] = { -- Windwalker
    importString = "",
    heroSpec = "Shado-Pan", -- confirmed: murlok 3v3 shows 47/50 top players
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [287681] = { -- Turbo Fists
            pick = "Turbo Fists",
            why = "Near-mandatory vs melee — slows stick and gives a parry window during burst.",
            alt = "Rising Dragon Sweep",
            altWhy = "Adds a knockup to compensate for low CC.",
            pveNote = "PvE takes other capstones instead — Turbo Fists is PvP-only value.",
        },
        [233759] = { -- Grapple Weapon
            pick = "Grapple Weapon",
            why = "Shuts down melee burst windows (esp. vs Warriors/DKs).",
            alt = "Ring of Peace", -- spellID 116844
            altWhy = "Broader peel vs multiple melee.",
            pveNote = "Not used in PvE.",
        },
        [116705] = { -- Spear Hand Strike
            pick = "Spear Hand Strike",
            why = "Mandatory interrupt on enemy casters.",
            alt = "none",
            altWhy = "n/a",
            pveNote = "None.",
        },
    },
    levelPath = {},
}
PVP[270] = { -- Mistweaver
    importString = "",
    heroSpec = "Master of Harmony", -- confirmed: murlok 3v3 43/50, u.gg A-tier/4.5% pop vs Conduit C-tier/0.3%
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [353319] = { -- Peaceweaver
            pick = "Peaceweaver",
            why = "Brief magic-damage immunity after a big heal, key to surviving burst combos.",
            alt = "Zen Focus Tea",
            altWhy = "Better vs interrupt-heavy teams.",
            pveNote = "PvE often takes raid-CDR talents instead.",
        },
        [122783] = { -- Diffuse Magic
            pick = "Diffuse Magic",
            why = "Premier defensive vs magic burst comps.",
            alt = "Eminence",
            altWhy = "Extra CC-break/mobility vs mobile melee.",
            pveNote = "Less relevant in PvE.",
        },
        [410777] = { -- Zen Spheres
            pick = "Zen Spheres",
            why = "Adds passive healing and damage pressure while kiting.",
            alt = "none direct",
            altWhy = "n/a",
            pveNote = "None.",
        },
    },
    levelPath = {},
}

-- Priest
PVP[256] = { -- Discipline
    importString = "",
    heroSpec = "Oracle", -- corrected from Voidweaver: dominant in 3v3, ~43 vs 7 players in top data
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [8122] = { -- Psychic Scream
            pick = "Psychic Scream",
            why = "Primary reliable AoE CC to peel or set up kills in arena.",
            alt = "Silence",
            altWhy = "Better vs melee/caster interrupt-lockdown comps.",
            pveNote = "None — mandatory in PvP.",
        },
        [33206] = { -- Pain Suppression
            pick = "Pain Suppression",
            why = "Core external defensive to save a teammate from burst, usable through stuns.",
            alt = "Power Word: Barrier",
            altWhy = "Better AoE damage mitigation in RBG/large-scale fights.",
            pveNote = "None — near-mandatory in PvP.",
        },
        [32375] = { -- Mass Dispel
            pick = "Mass Dispel",
            why = "Only reliable way to strip immunities/HoTs and shut down enemy defensive cooldowns.",
            alt = "Purification",
            altWhy = "Extra Purify charge, better vs dispellable CC-heavy comps.",
            pveNote = "PvE favors Purification/other dispel-adjacent nodes over Mass Dispel utility.",
        },
    },
    levelPath = {},
}
PVP[257] = { -- Holy
    importString = "",
    heroSpec = "Archon", -- corrected from Oracle: murlok top-50 2v2 data confirms Archon dominant
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [8122] = { -- Psychic Scream
            pick = "Psychic Scream",
            why = "Best crowd control tool a healer has to survive dive attempts.",
            alt = "none commonly swapped",
            altWhy = "n/a",
            pveNote = "Purely a PvP pick.",
        },
        [47788] = { -- Guardian Spirit
            pick = "Guardian Spirit",
            why = "Primary external cooldown to save a teammate from burst kill windows.",
            alt = "Divine Hymn",
            altWhy = "Raid-wide healing burst better for RBG/mass-target scenarios.",
            pveNote = "None — standard in both.",
        },
        [32375] = { -- Mass Dispel
            pick = "Mass Dispel",
            why = "Strips undispellable defensives/CC-immunities and offensive buffs from enemy team.",
            alt = "Purification",
            altWhy = "Extra dispel charge, stronger vs comps with spammable dispellable CC.",
            pveNote = "PvE leans Purification for raid utility instead.",
        },
    },
    levelPath = {},
}
PVP[258] = { -- Shadow
    importString = "",
    heroSpec = "Voidweaver", -- confirmed: murlok 3v3 shows 12/13 top players on Voidweaver vs 1/13 Archon
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [8122] = { -- Psychic Scream
            pick = "Psychic Scream",
            why = "Top-usage CC in current 3v3 data (13/13), core peel/setup tool.",
            alt = "none, universal pick",
            altWhy = "n/a",
            pveNote = "PvP-only pick.",
        },
        [605] = { -- Mind Control
            pick = "Mind Control",
            why = "Usable offensively to force a target off a ledge/into a hazard or as a disruptive CC breaking casts.",
            alt = "Psyfiend",
            altWhy = "Passive pet CC/pressure that doesn't require channel commitment.",
            pveNote = "Essentially PvP-only, not used in PvE rotations.",
        },
        [586] = { -- Fade
            pick = "Fade",
            why = "Primary self-peel to drop melee target-lock and avoid incoming CC chains.",
            alt = "Dispersion",
            altWhy = "Stronger raw damage-reduction cooldown for sustained pressure.",
            pveNote = "PvE picks favor Dispersion/mana tools over Fade's anti-melee utility.",
        },
    },
    levelPath = {},
}

-- Rogue
PVP[259] = { -- Assassination
    importString = "",
    heroSpec = "Fatebound", -- corrected from Deathstalker: current meta ~96% usage
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [76577] = { -- Smoke Bomb
            pick = "Smoke Bomb",
            why = "Zone-control that blocks peels/saves and secures kills on CC'd targets.",
            alt = "Thick as Thieves", -- spellID 221622
            altWhy = "15% team damage amp off Tricks, used in heavy-burst comps.",
            pveNote = "PvP-talent-row only, not usable in PvE content.",
        },
        [31224] = { -- Cloak of Shadows
            pick = "Cloak of Shadows",
            why = "Clutch full magic immunity vs caster burst/CC chains in arena.",
            alt = "Cheap Shot", -- spellID 1833
            altWhy = "Stealth opener stun to force a CC chain instead of relying on the defensive cooldown.",
            pveNote = "None — Cloak seen in PvE too.",
        },
    },
    levelPath = {},
}
PVP[260] = { -- Outlaw
    importString = "",
    heroSpec = "Trickster", -- confirmed: Fatebound shows ~0% usage
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [1219122] = { -- Preemptive Maneuver
            pick = "Preemptive Maneuver",
            why = "Core anti-burst survivability, adds damage reduction to Feint while stunned.",
            alt = "Dismantle", -- spellID 207777
            altWhy = "Hard silence/disarm vs Warrior/Rogue/MM Hunter comps.",
            pveNote = "PvP-talent-row only.",
        },
        [441415] = { -- Don't Be Suspicious
            pick = "Don't Be Suspicious",
            why = "Trickster hero-node that shortens Blind cooldown for repeat shutdowns.",
            alt = "Kidney Shot", -- spellID 408
            altWhy = "Combo-point stun finisher as the non-hero-talent CC fallback.",
            pveNote = "None — same pick used in PvE Trickster builds.",
        },
    },
    levelPath = {},
}
PVP[261] = { -- Subtlety
    importString = "",
    -- Live top-50 usage data (murlok.io) shows 66% Deathstalker vs 34% Trickster,
    -- which conflicts with icy-veins' prose guide (claims Trickster) — weighted
    -- the usage data higher since it reflects actual top-50 play, not guide text.
    heroSpec = "Deathstalker",
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [2094] = { -- Blind
            pick = "Blind",
            why = "Primary non-DR'd-with-stun CC to peel or set up kills.",
            alt = "Sap", -- spellID 6770
            altWhy = "Out-of-combat incapacitate for pre-fight pick/node control in RBG.",
            pveNote = "Sap has PvE use for skipping trash; Blind is PvP-only value.",
        },
        [31224] = { -- Cloak of Shadows
            pick = "Cloak of Shadows",
            why = "Full magic immunity vs caster CC/burst, ~50/50 usage.",
            alt = "Evasion", -- spellID 5277
            altWhy = "+100% dodge for 10s, counters physical cleave instead of magic.",
            pveNote = "None.",
        },
    },
    levelPath = {},
}

-- Shaman
PVP[262] = { -- Elemental
    importString = "",
    heroSpec = "Farseer", -- corrected from Stormbringer: murlok top-50 3v3 shows 50/50 on Farseer, 0/50 Stormbringer
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [204336] = { -- Grounding Totem
            pick = "Grounding Totem",
            why = "Absorbs one enemy spell/CC cast, the primary anti-burst/anti-CC tool for casters.",
            alt = "Static Field Totem",
            altWhy = "Repositions enemies off teammates instead of eating a cast.",
            pveNote = "PvP talent only, not used in PvE.",
        },
        [51514] = { -- Hex
            pick = "Hex",
            why = "Core hard CC to lock a kill target or peel a partner.",
            alt = "Capacitor Totem",
            altWhy = "AoE stun for team CC chains instead of single-target lockdown.",
            pveNote = "Deprioritized in M+/raid where CC matters less.",
        },
        [108271] = { -- Astral Shift
            pick = "Astral Shift",
            why = "On-demand 40% DR to survive burst windows on a squishy caster.",
            alt = "Nature's Guardian",
            altWhy = "Passive automatic mitigation instead of an active cooldown.",
            pveNote = "None — used in both.",
        },
    },
    levelPath = {},
}
PVP[263] = { -- Enhancement
    importString = "",
    heroSpec = "Stormbringer", -- confirmed: 43/50 vs Totemic 7/50 in top 3v3
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [57994] = { -- Wind Shear
            pick = "Wind Shear",
            why = "Only interrupt in kit — mandatory to shut down healer casts while sticking to target.",
            alt = "none (baseline ability, not a talent choice)",
            altWhy = "n/a",
            pveNote = "None.",
        },
        [51514] = { -- Hex
            pick = "Hex",
            why = "Lets melee lock down a target without losing uptime.",
            alt = "Capacitor Totem",
            altWhy = "Team-wide stun for setups instead of single-target lockdown.",
            pveNote = "None.",
        },
        [108271] = { -- Astral Shift
            pick = "Astral Shift",
            why = "Melee eats constant focus fire; 40% DR cooldown is key survival.",
            alt = "Nature's Guardian",
            altWhy = "Passive DR instead of active cooldown.",
            pveNote = "None.",
        },
    },
    levelPath = {},
}
PVP[264] = { -- Restoration
    importString = "",
    -- Totemic leads Blitz/RBG (39/50) and is icy-veins' default; Farseer edges
    -- ahead in pure 3v3 (30/50) — Totemic kept as the safer meta default.
    heroSpec = "Totemic",
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [8143] = { -- Tremor Totem
            pick = "Tremor Totem",
            why = "AoE fear/charm cleanse for the whole team, critical vs Warlock/Priest/DH fear comps.",
            alt = "Grounding Totem",
            altWhy = "Absorbs one big single-target CC/burst cast instead of cleansing the team.",
            pveNote = "Rarely taken in PvE.",
        },
        [204336] = { -- Grounding Totem
            pick = "Grounding Totem",
            why = "Eats a devastating spell/CC aimed at the healer or a low-HP ally.",
            alt = "Poison Cleansing Totem",
            altWhy = "Cleanses poison/disease/curse over time instead of one instant redirect.",
            pveNote = "PvP talent only.",
        },
        [108271] = { -- Astral Shift
            pick = "Astral Shift",
            why = "Healers are focus-fired hardest; buys survival time to keep healing under pressure.",
            alt = "Nature's Guardian",
            altWhy = "Passive mitigation instead of an active cooldown.",
            pveNote = "None.",
        },
    },
    levelPath = {},
}

-- Warlock
PVP[265] = { -- Affliction
    importString = "",
    heroSpec = "Soul Harvester", -- confirmed: icy-veins 12.1 PvP guide's meta pick
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [426352] = { -- Jinx
            pick = "Jinx",
            why = "Cuts the globals needed to keep both DoTs up — called mandatory by icy-veins for Affliction PvP.",
            alt = "Rot and Decay",
            altWhy = "Extends DoT duration off Drain Life/Soul casts when you need to sit and channel instead.",
            pveNote = "None — PvP-only talent.",
        },
        [212295] = { -- Nether Ward
            pick = "Nether Ward",
            why = "No-sells the magic interrupts/burst of double-caster teams, freeing you to keep DoTing.",
            alt = "Impish Instincts",
            altWhy = "Better vs melee-heavy comps — cuts Demonic Circle cooldown on physical hits for kiting.",
            pveNote = "None — PvP-only talent.",
        },
    },
    levelPath = {},
}
PVP[266] = { -- Demonology
    importString = "",
    -- corrected from Diabolist: murlok's Season 2 solo-shuffle data shows top
    -- players run Soul Harvester 38-to-12 over Diabolist, and Diabolist's
    -- Chaos Salvo/Felseeker damage was cut 20% in 12.1.
    heroSpec = "Soul Harvester",
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [409835] = { -- Impish Instincts
            pick = "Impish Instincts",
            why = "The single most-taken Demo PvP talent — lets you kite melee to protect your pet/cast time.",
            alt = "Nether Ward",
            altWhy = "Swap in vs caster-heavy teams to reflect magic kicks/burst instead.",
            pveNote = "None — PvP-only talent.",
        },
        [212459] = { -- Call Fel Lord
            pick = "Call Fel Lord",
            why = "A zone-stun icy-veins calls crucial against melees who try to ignore it, protecting Tyrant burst windows.",
            alt = "Soul Rip",
            altWhy = "Pick instead for anti-healing/pressure into stacked-damage comps rather than pure melee control.",
            pveNote = "None — PvP-only talent.",
        },
    },
    levelPath = {},
}
PVP[267] = { -- Destruction
    importString = "",
    heroSpec = "Hellcaller", -- corrected from Diabolist: icy-veins 12.1 guide + murlok RBG top-3 all confirm Hellcaller
    pvpTalents = {},
    panels = { class = {}, spec = {}, hero = {} },
    nodes = {
        [212295] = { -- Nether Ward
            pick = "Nether Ward",
            why = "Crucial against all casters — prevents magic interrupts during your Chaos Bolt cast window.",
            alt = "Impish Instincts",
            altWhy = "Better vs melee teams that camp you — cheaper Demonic Circle for repositioning.",
            pveNote = "None — PvP-only talent.",
        },
        [410598] = { -- Soul Rip (NOT 220893, which is an unrelated Rogue ability of the same name)
            pick = "Soul Rip",
            why = "Multi-target damage/healing reduction that turns Malevolence burst windows into kills.",
            alt = "Shadow Rift",
            altWhy = "Swap for a repositioning tool that punishes pillar-humping instead of pure pressure.",
            pveNote = "None — PvP-only talent.",
        },
    },
    levelPath = {},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- API: Lookup helpers
-- ═══════════════════════════════════════════════════════════════════════════════

function TA.Data.TalentsPvP:GetForSpec(specID)
    return PVP[specID]
end

function TA.Data.TalentsPvP:GetNodeInfo(specID, spellID)
    local spec = PVP[specID]
    if not spec or not spec.nodes then
        return nil
    end
    return spec.nodes[spellID]
end

function TA.Data.TalentsPvP:GetLevelPath(specID)
    local spec = PVP[specID]
    if not spec then
        return nil
    end
    return spec.levelPath
end

function TA.Data.TalentsPvP:GetImportString(specID)
    local spec = PVP[specID]
    if not spec then
        return nil
    end
    return (spec.importString ~= "") and spec.importString or nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PVP CLASS MATCHUPS — "Matchups" reference tab
-- ═══════════════════════════════════════════════════════════════════════════════
-- Per-spec (39 entries) list of which of the 13 enemy CLASSES tend to be
-- favorable or unfavorable matchups in Solo Shuffle / arena / War Mode PvP,
-- with a concrete counter-play tip for each unfavorable class. Compiled from
-- icy-veins PvP guides (where a spec has one), ArenaCoach Solo Shuffle/arena
-- win-rate and first-death data for Midnight Season 2, Method.gg, u.gg,
-- murlok.io, skill-capped, wowcarry, and Wowhead, current as of Patch 12.1
-- "Midnight" Season 2 ("Curse of Ula'tek").
--
-- Notes on scope:
--   • Granularity is per-ENEMY-CLASS (13), not per-enemy-spec (39), per user
--     preference — a spec-specific nuance (e.g. "especially rough vs Fire,
--     less so vs Frost") is folded into the counter tip text rather than
--     split into separate entries.
--   • Same-class "mirror" matchups are omitted (not useful as a generic
--     "vs <YOUR OWN CLASS>" reference line).
--   • A few specs with no dedicated PvP guide in practice (Blood DK,
--     Protection Paladin, Brewmaster Monk, Vengeance DH) and a few where
--     supplementary research was cut short by rate limits (Evoker, Mage)
--     are mechanically reasoned from spec kit/cooldowns rather than pulled
--     from an explicit cited matchup table — still verified sane, just
--     flagged here for transparency.
--
-- Schema: MATCHUPS[specID] = {
--     favorable   = { "CLASSTOKEN", ... },
--     unfavorable = { { class = "CLASSTOKEN", tip = "counter-play text" }, ... },
-- }

local MATCHUPS = {

    -- ── Warrior ──────────────────────────────────────────────────────────
    [71] = { -- Arms
        favorable = { "SHAMAN", "MONK", "DEATHKNIGHT", "DEMONHUNTER" },
        unfavorable = {
            { class = "MAGE",   tip = "Save your stun/leap for right after their Blink; delay Colossus Smash burst until Ice Block is on cooldown." },
            { class = "PRIEST", tip = "Bait Pain Suppression with a smaller cooldown before committing full burst; keep Mortal Strike's healing debuff up continuously." },
            { class = "HUNTER", tip = "Hold your gap-closer for the moment they Disengage/Feign; interrupt Aimed Shot with Pummel." },
        },
    },
    [72] = { -- Fury
        favorable = { "SHAMAN", "HUNTER", "PALADIN", "DRUID" },
        unfavorable = {
            { class = "MAGE",    tip = "Hold Enraged Regeneration specifically for the Combustion cast; Heroic Leap the instant they Blink." },
            { class = "WARLOCK", tip = "Pool a stun for when Demonic Circle: Teleport is on cooldown; Spell Reflect Fear casts." },
            { class = "ROGUE",   tip = "Save your CC-trinket/breaker for Kidney Shot, not the opener; pre-pop Enraged Regeneration before a Vanish re-engage." },
        },
    },
    [73] = { -- Protection
        favorable = { "ROGUE", "DEATHKNIGHT", "DEMONHUNTER" },
        unfavorable = {
            { class = "WARLOCK", tip = "Save Spell Reflection specifically for the Chaos Bolt cast; break line of sight to force a recast." },
            { class = "MAGE",    tip = "Use your gap-closer instantly on a slow/root landing; hold Rallying Cry for the Combustion window." },
            { class = "HUNTER",  tip = "Intervene onto their healer to force trades instead of chasing the Hunter." },
            { class = "PRIEST",  tip = "Trinket or Berserker Rage the fear immediately to preserve your uptime." },
        },
    },

    -- ── Paladin ──────────────────────────────────────────────────────────
    [65] = { -- Holy
        favorable = { "DEATHKNIGHT", "ROGUE" },
        unfavorable = {
            { class = "WARLOCK",     tip = "Pre-Bubble/Blessing of Protection before a Fear chain lands; hold Aura Mastery for the Malefic Rapture spike." },
            { class = "DEMONHUNTER", tip = "Use pillars to LOS Eye Beam; save Blessing of Sacrifice for the DH's kill target." },
            { class = "SHAMAN",      tip = "Bait Purge onto a low-value buff first; use Divine Shield to fully no-sell the real burst window." },
        },
    },
    [66] = { -- Protection
        favorable = { "ROGUE", "WARRIOR", "HUNTER", "DEATHKNIGHT" },
        unfavorable = {
            { class = "MAGE",    tip = "Pop Blessing of Freedom + Divine Steed instantly on a slow; only commit when Ice Block/Alter Time is on cooldown." },
            { class = "WARLOCK", tip = "Interrupt Drain Life/Malefic Rapture the moment the channel starts; Divine Shield to survive a Fear-into-burst chain." },
            { class = "SHAMAN",  tip = "Bait Purge onto a throwaway buff, then refresh real defensives before their burst." },
        },
    },
    [70] = { -- Retribution
        favorable = { "MONK", "ROGUE" },
        unfavorable = {
            { class = "DEMONHUNTER", tip = "Hold Blessing of Protection/Divine Shield specifically for Eye Beam or Metamorphosis; kite with Divine Steed rather than trading." },
            { class = "SHAMAN",      tip = "Pre-Bubble the Doom Winds window; pool burst for CC windows on their healer and force LoS on Earth Shield/Riptide." },
        },
    },

    -- ── Hunter ───────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery
        favorable = { "DEATHKNIGHT", "MAGE", "SHAMAN", "WARLOCK" },
        unfavorable = {
            { class = "MONK",        tip = "Bait their Roll before committing Freezing Trap; pre-drop Tar Trap the instant they close." },
            { class = "PRIEST",      tip = "Hold Aspect of the Turtle specifically for Void Torrent/Mind Spike burst." },
            { class = "ROGUE",       tip = "Bank a Disengage charge before the opener, trinket the first stun, then Feign Death immediately." },
            { class = "DEMONHUNTER", tip = "Pre-place Tar Trap before the second gap closer; save Aspect of the Turtle for the Metamorphosis burst." },
        },
    },
    [254] = { -- Marksmanship
        favorable = { "MAGE", "WARLOCK", "SHAMAN", "PRIEST" },
        unfavorable = {
            { class = "ROGUE",       tip = "Never pre-cast Aimed Shot with the Rogue out of vision; trinket the opener then Disengage immediately." },
            { class = "DEMONHUNTER", tip = "Pre-place Tar Trap/Concussive Shot ahead of the second gap closer; save Aspect of the Turtle for Eye Beam/Meta." },
            { class = "WARRIOR",     tip = "Bank Disengage and drop a trap before the leap lands." },
            { class = "MONK",        tip = "Bait the gap closer before committing Freezing Trap, then Scatter Shot on landing to regain cast time." },
        },
    },
    [255] = { -- Survival
        favorable = { "MAGE", "WARLOCK", "PRIEST", "DRUID" },
        unfavorable = {
            { class = "WARRIOR",     tip = "Hit-and-run: Harpoon in, burst, Disengage out; save Aspect of the Turtle for Recklessness/Avatar." },
            { class = "DEMONHUNTER", tip = "Bank Tracker's Net for the Metamorphosis window rather than using it early." },
            { class = "ROGUE",       tip = "Pop Aspect of the Turtle immediately on a stealth stunlock; keep Feign Death in reserve." },
            { class = "MONK",        tip = "Save Tar Bomb to root them mid-Roll; pressure only during Monk's defensive cooldown windows." },
        },
    },

    -- ── Death Knight ─────────────────────────────────────────────────────
    [250] = { -- Blood
        favorable = { "WARLOCK", "HUNTER", "DRUID", "MONK" },
        unfavorable = {
            { class = "MAGE",        tip = "Pop Anti-Magic Shell/Zone proactively into their cooldown-window burst; Death Grip the instant they try to create distance." },
            { class = "PRIEST",      tip = "Trinket the first fear, hold Lichborne for the second, interrupt Mind Blast/Void Torrent." },
            { class = "DEMONHUNTER", tip = "Use Death's Advance/Wraith Walk to close gaps; pre-emptively Grip before they disengage." },
            { class = "ROGUE",       tip = "Keep Icebound Fortitude for the opener stun-lock; use Anti-Magic Shell/trinket to survive follow-up burst." },
        },
    },
    [251] = { -- Frost
        favorable = { "WARLOCK", "HUNTER" },
        unfavorable = {
            { class = "WARRIOR", tip = "Play passively through the opener; hold Icebound Fortitude for Arms' burst window instead of trinketing early." },
            { class = "MONK",    tip = "Proactively use Anti-Magic Shell/Death Grip to punish their gap-closer; save defensives for the double-stun chain." },
            { class = "PALADIN", tip = "Focus interrupts on Holy Shock/Word of Glory; use Chains of Ice to stop them peeling for their healer." },
        },
    },
    [252] = { -- Unholy
        favorable = { "EVOKER", "SHAMAN", "WARLOCK" },
        unfavorable = {
            { class = "MONK",    tip = "Play the opener defensively; save defensives for the Mistweaver's burst window instead of committing pets early." },
            { class = "PALADIN", tip = "Pool disease uptime and burst together rather than spread out, forcing a cooldown trade." },
            { class = "HUNTER",  tip = "Use Death Grip/Chains of Ice aggressively on cooldown; open with Asphyxiate rather than saving it." },
        },
    },

    -- ── Druid ────────────────────────────────────────────────────────────
    [102] = { -- Balance
        favorable = { "DEMONHUNTER", "MAGE", "PRIEST" },
        unfavorable = {
            { class = "SHAMAN", tip = "Pool Cyclone/interrupts for their big heals; only burst during Bloodlust/cooldown windows." },
            { class = "PRIEST", tip = "Bait Guardian Spirit before committing your burst." },
            { class = "MONK",   tip = "Hold Barkskin/Bear Form for their opener burst, not for chip damage." },
        },
    },
    [103] = { -- Feral
        favorable = { "HUNTER", "MONK", "PALADIN" },
        unfavorable = {
            { class = "DEATHKNIGHT", tip = "Bank Bear Form/Barkskin for their opening burst window instead of mid-fight." },
            { class = "WARRIOR",     tip = "Don't try to out-heal Mortal Strike stacks; use roots/Cyclone to disengage and reset." },
            { class = "EVOKER",      tip = "Bank Berserk/Convoke until after their major defensives are spent." },
        },
    },
    [104] = { -- Guardian
        favorable = { "WARRIOR", "ROGUE", "HUNTER", "PALADIN" },
        unfavorable = {
            { class = "MAGE",    tip = "Open with Ursol's Vortex/Typhoon proactively to stop kiting before engaging." },
            { class = "WARLOCK", tip = "Trinket or Berserk-cleanse the first Fear immediately rather than saving it." },
            { class = "PRIEST",  tip = "Use Skull Bash on Void Torrent/Mind Blast rather than holding it for mobility." },
            { class = "DRUID",   tip = "Bait their Cyclone with a feint before committing to your redirect window, or trinket it immediately." },
        },
    },
    [105] = { -- Restoration
        favorable = { "MAGE", "PRIEST", "SHAMAN" },
        unfavorable = {
            { class = "ROGUE",      tip = "Pop Barkskin at the very start of the round; pre-HoT the whole team before their stealth opener and trinket the first full CC chain." },
            { class = "DEATHKNIGHT", tip = "Use Stampeding Roar/Wild Charge proactively to break snares before they stack." },
        },
    },

    -- ── Demon Hunter ─────────────────────────────────────────────────────
    [577] = { -- Havoc
        favorable = { "HUNTER", "PALADIN", "SHAMAN", "WARLOCK" },
        unfavorable = {
            { class = "DEATHKNIGHT", tip = "Bank Metamorphosis/Eye Beam for a window right after their Death Strike/AMS is spent." },
            { class = "MONK",        tip = "Use Imprison or Sigil of Misery pre-emptively before the Monk's burst." },
            { class = "DRUID",       tip = "Force a trinket/CC on a stun before committing Metamorphosis; Chaos Brand the Druid early." },
            { class = "WARRIOR",     tip = "Use Darkness/Vengeful Retreat kiting via Glimpse's CC-immunity to reset before reengaging." },
        },
    },
    [581] = { -- Vengeance
        favorable = { "WARRIOR", "ROGUE", "HUNTER", "DEATHKNIGHT" },
        unfavorable = {
            { class = "WARLOCK", tip = "Pre-pop Fiery Brand and Fel Devastation before DoTs stack; use Consume Magic to strip damage-amplifying buffs." },
            { class = "PRIEST",  tip = "Trinket the first Fear to protect Fel Devastation's timing; open with Sigil of Misery to stagger their CC." },
            { class = "MAGE",    tip = "Hold Infernal Strike as a post-root gap closer; use Consume Magic on key defensive procs." },
            { class = "EVOKER",  tip = "Use Sigil of Silence to shut down empowered casts; force them into melee range." },
        },
    },

    -- ── Evoker ───────────────────────────────────────────────────────────
    [1467] = { -- Devastation
        favorable = { "HUNTER", "WARLOCK", "MAGE", "SHAMAN" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pop Obsidian Scales the instant stealth breaks, not after the stun lands; hug pillars/LOS to deny a clean opener." },
            { class = "WARRIOR",     tip = "Pre-cast Renewing Blaze before the leap lands; kite diagonally with Hover, not in a straight line." },
            { class = "DEMONHUNTER", tip = "Hold Zephyr specifically for the post-Nova burst window; force them to path around terrain." },
            { class = "PALADIN",     tip = "Bait Repentance onto a pet/totem; save Renewing Blaze for the Wake of Ashes burst." },
        },
    },
    [1468] = { -- Preservation
        favorable = { "HUNTER", "WARLOCK", "MAGE", "SHAMAN" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pre-position near your own peel; save Rescue to instantly escape the opening Cheap Shot." },
            { class = "DEMONHUNTER", tip = "Weave instant heals — Verdant Embrace, Emerald Blossom — instead of channeling Dream Breath while they're in range." },
            { class = "WARRIOR",     tip = "Use Hover's slow immunity to hold max range; pre-cast Renewing Blaze before the leap connects." },
            { class = "PALADIN",     tip = "Bank a CC-breaker or Time Stop; absorb Wake of Ashes with Obsidian Scales pre-cast." },
        },
    },
    [1473] = { -- Augmentation
        favorable = { "WARLOCK", "HUNTER", "SHAMAN", "MAGE" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pre-cast Blistering Scales before committing to an Ebon Might window; hold Breath of Eons for their opener." },
            { class = "DEMONHUNTER", tip = "Cast Ebon Might/Prescience behind LoS to bait the jump before committing." },
            { class = "WARRIOR",     tip = "Kite diagonally with Hover; save Blistering Scales for the leap's follow-up burst." },
            { class = "PALADIN",     tip = "Bait Repentance onto a pet/totem rather than yourself." },
        },
    },

    -- ── Mage ─────────────────────────────────────────────────────────────
    [62] = { -- Arcane
        favorable = { "WARLOCK", "PRIEST", "HUNTER", "SHAMAN" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pre-pop Prismatic Barrier on suspected openers; save trinket/Ice Block for the second CC chain." },
            { class = "WARRIOR",     tip = "Bait Spell Reflect with a throwaway cast before Arcane Surge; use Alter Time as an emergency reset." },
            { class = "DEMONHUNTER", tip = "Save Ice Block for the Metamorphosis burst window; kite to LOS pillars to force Fel Rush's cooldown." },
            { class = "MONK",        tip = "Hold Blink specifically for the Fists of Fury channel — don't waste it early." },
        },
    },
    [63] = { -- Fire
        favorable = { "WARLOCK", "PRIEST", "HUNTER", "DEATHKNIGHT" },
        unfavorable = {
            { class = "ROGUE",       tip = "Bank Ice Block for the Vanish re-opener rather than the first burst; proactively Blazing Barrier when you sense a stealth approach." },
            { class = "DEMONHUNTER", tip = "Bank Ice Block for the Metamorphosis window; kite around obstacles to reset Fel Rush charges." },
            { class = "WARRIOR",     tip = "Bait Spell Reflect with Fireball/Scorch first; use Alter Time to undo a bad trade." },
            { class = "DRUID",       tip = "Delay Combustion until Berserk/major cooldowns are spent." },
        },
    },
    [64] = { -- Frost
        favorable = { "WARLOCK", "SHAMAN", "HUNTER", "EVOKER" },
        unfavorable = {
            { class = "ROGUE",       tip = "React with Ice Block on the burst window after Cheap Shot/Vanish rather than pre-emptively." },
            { class = "MONK",        tip = "Kite through chokepoints to force Roll's cooldown; hold Ice Block for Fists of Fury/Touch of Death." },
            { class = "DEMONHUNTER", tip = "Pre-spread CC with Ring of Frost before they fully close; save Ice Block for Metamorphosis." },
            { class = "DEATHKNIGHT", tip = "Save Blink specifically to escape Death Grip range; bait AMS with weak Frostbolts before committing burst." },
        },
    },

    -- ── Monk ─────────────────────────────────────────────────────────────
    [268] = { -- Brewmaster
        favorable = { "WARRIOR", "ROGUE", "HUNTER", "DEMONHUNTER" },
        unfavorable = {
            { class = "MAGE",        tip = "Save Tiger's Lust for the root-into-Blink reset, not earlier slows." },
            { class = "WARLOCK",     tip = "Hold Zen Meditation for magic burst windows only; Paralysis them before DoTs stack." },
            { class = "PRIEST",      tip = "Hold Tiger's Lust specifically for Psychic Scream, then pressure through Fade." },
            { class = "DEATHKNIGHT", tip = "Bait Death Grip's cooldown before committing; use Ring of Peace to break melee uptime." },
        },
    },
    [269] = { -- Windwalker
        favorable = { "WARLOCK", "PRIEST", "SHAMAN" },
        unfavorable = {
            { class = "MAGE",        tip = "Save Tiger's Lust for the Frost Nova-into-Blink sequence specifically." },
            { class = "ROGUE",       tip = "Trinket the opening Cheap Shot to deny the Shadow Dance burst rather than saving it." },
            { class = "DEATHKNIGHT", tip = "Bait Death Grip before committing Storm, Earth, and Fire/Serenity." },
        },
    },
    [270] = { -- Mistweaver
        favorable = { "WARLOCK", "HUNTER", "DEATHKNIGHT", "DRUID" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pre-place Transcendence and use Transcendence: Transfer the instant a stun lands rather than trinketing every stun." },
            { class = "WARRIOR",     tip = "Place Transcendence at max range so you can Transfer the instant they close." },
            { class = "DEMONHUNTER", tip = "Front-load Renewing Mist/Enveloping Mist HoTs before they close." },
            { class = "MAGE",        tip = "Save Tiger's Lust for the first hard CC; lean on Renewing Mist's HoT ticking through silences." },
        },
    },

    -- ── Priest ───────────────────────────────────────────────────────────
    [256] = { -- Discipline
        favorable = { "WARRIOR", "MONK", "PALADIN", "ROGUE" },
        unfavorable = {
            { class = "MAGE",   tip = "Use Fade+Phase Shift to close safely; hold Pain Suppression for the Icy Veins burst window; Psychic Scream to break their kiting cadence." },
            { class = "HUNTER", tip = "Trinket the first trap, Psychic Scream the hunter+pet to reset, save Pain Suppression for the Aimed Shot burst." },
        },
    },
    [257] = { -- Holy
        favorable = { "MONK", "DEMONHUNTER", "WARLOCK" },
        unfavorable = {
            { class = "DEATHKNIGHT", tip = "Pre-cast Guardian Spirit before Strangulate lands; kite the pet with Fade." },
            { class = "HUNTER",      tip = "Use Fade to shed slows; hold Guardian Spirit for the Trueshot burst window or the Intimidation stun-into-burst." },
            { class = "ROGUE",       tip = "Pre-shield/HoT before engaging; trinket the first stun to buy a GCD to react." },
        },
    },
    [258] = { -- Shadow
        favorable = { "HUNTER", "PALADIN", "WARLOCK" },
        unfavorable = {
            { class = "DEMONHUNTER", tip = "Hold Dispersion specifically for the Meta window instead of using it early." },
            { class = "SHAMAN",      tip = "Use Fade, Psychic Scream, and Silence to break their melee uptime; save Dispersion for burst windows." },
            { class = "WARRIOR",     tip = "Pre-position near pillars/LOS; Fade+Psychic Scream to create distance; save Dispersion for execute range." },
        },
    },

    -- ── Rogue ────────────────────────────────────────────────────────────
    [259] = { -- Assassination
        favorable = { "HUNTER", "SHAMAN", "DEMONHUNTER", "WARLOCK" },
        unfavorable = {
            { class = "MONK",   tip = "Bank Cloak of Shadows/Crimson Vial specifically for Fists of Fury/Touch of Death windows; open with Kidney Shot from Vanish rather than trading first." },
            { class = "MAGE",   tip = "Interrupt the Combustion/Pyroblast cast with Kick/Gouge; hold Cloak until after Ice Block is spent." },
            { class = "PRIEST", tip = "Pool combo points behind Garrote/Kidney Shot chains; don't overextend defensives before their fear chain resolves." },
        },
    },
    [260] = { -- Outlaw
        favorable = { "MAGE", "WARLOCK", "SHAMAN", "PRIEST" },
        unfavorable = {
            { class = "PALADIN", tip = "Save Cheap Shot/Kidney Shot for after they burn Freedom/Shield baits; interrupt Wake of Ashes/Final Verdict." },
            { class = "WARRIOR", tip = "Use Dismantle to strip their weapon during Die by the Sword; kite with Grappling Hook instead of standing in melee trades." },
            { class = "HUNTER",  tip = "Pop Sprint/Grappling Hook to close before Trap lands; pool points behind Cloak of Shadows through Kill Shot/Trueshot." },
        },
    },
    [261] = { -- Subtlety
        favorable = { "WARLOCK", "DRUID", "SHAMAN" },
        unfavorable = {
            { class = "HUNTER",  tip = "Use Shadowstep/Shadow Dance to close before Concussive Shot/traps land; don't blow Symbols of Death until in range." },
            { class = "MAGE",    tip = "Bait Ice Block with a fake burst window before committing full Shadow Dance; interrupt Combustion on cooldown." },
            { class = "PALADIN", tip = "Hold Kidney Shot until Freedom is on cooldown; pressure the healer instead of forcing a CC-locked kill." },
        },
    },

    -- ── Shaman ───────────────────────────────────────────────────────────
    [262] = { -- Elemental
        favorable = { "PALADIN", "MONK", "MAGE", "WARLOCK" },
        unfavorable = {
            { class = "ROGUE",       tip = "Pre-position near your totems; use Spirit Walk/Astral Shift proactively at the opener, not reactively." },
            { class = "DEMONHUNTER", tip = "Keep Earthgrab Totem or Thunderstorm ready to peel them off you; Ghost Wolf away between casts." },
            { class = "WARRIOR",     tip = "Pop Astral Shift before their Recklessness/Avatar window, not after damage starts." },
        },
    },
    [263] = { -- Enhancement
        favorable = { "MAGE", "WARLOCK", "PALADIN", "HUNTER" },
        unfavorable = {
            { class = "WARRIOR",     tip = "Hold Astral Shift/Earth Elemental for their cooldown pop rather than early trades." },
            { class = "DEMONHUNTER", tip = "Pop Capacitor Totem or Earthgrab the instant they close; save Astral Shift for their Metamorphosis burst." },
            { class = "ROGUE",       tip = "Trinket the first big CC and pre-set Capacitor Totem to punish their opener." },
        },
    },
    [264] = { -- Restoration
        favorable = { "MAGE", "WARLOCK", "PRIEST" },
        unfavorable = {
            { class = "DEATHKNIGHT", tip = "Focus offense — Purge their self-healing modifiers and coordinate kill windows with your DPS instead of turtling." },
            { class = "HUNTER",      tip = "Break line of sight behind pillars for their Aimed Shot casts; use Earthgrab Totem to slow their kite." },
            { class = "ROGUE",       tip = "Save a personal defensive for the opener and call for a peel before the second CC chain lands." },
            { class = "DEMONHUNTER", tip = "Pre-shield with Earth Shield/Riptide ahead of their cooldown; use Capacitor Totem to disrupt the Meta engage." },
        },
    },

    -- ── Warlock ──────────────────────────────────────────────────────────
    [265] = { -- Affliction
        favorable = { "HUNTER", "PALADIN", "MONK" },
        unfavorable = {
            { class = "DEATHKNIGHT", tip = "Teleport via Demonic Circle the instant Grip lands; save Unending Resolve for the disease burst, not the opener." },
            { class = "SHAMAN",      tip = "Hold Fear/Howl of Terror specifically for Spirits/Ascendance windows; stand off-angle from likely totem drops." },
            { class = "WARRIOR",     tip = "Lead with Curse of Exhaustion/Tongues since Fear alone won't hold them; teleport out before they pop Rage." },
        },
    },
    [266] = { -- Demonology
        favorable = { "PALADIN", "EVOKER", "ROGUE" },
        unfavorable = {
            { class = "MONK",   tip = "CC the Monk with Axe Toss/Shadowfury right before committing Demonic Tyrant, never on cooldown." },
            { class = "SHAMAN", tip = "Axe Toss + Demonic Circle: Teleport to reset distance the moment Spirits/Ascendance pop." },
            { class = "HUNTER", tip = "Teleport in to force close range where Felguard pressure and CC actually function." },
        },
    },
    [267] = { -- Destruction
        favorable = { "MONK", "PALADIN", "PRIEST" },
        unfavorable = {
            { class = "ROGUE",  tip = "Trinket/Unending Resolve the opener immediately, then Shadowfury once Cloak is on cooldown." },
            { class = "SHAMAN", tip = "Pre-spread Curse of Tongues onto their healer; stand off-angle from totem placement." },
            { class = "WARRIOR", tip = "Weave instant Conflagrate/Incinerate procs over hardcasts; keep Demonic Circle: Teleport up to dodge leap range." },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- API: Matchup lookup helpers
-- ═══════════════════════════════════════════════════════════════════════════════

TA.Data.PvPMatchups = TA.Data.PvPMatchups or {}

function TA.Data.PvPMatchups:GetForSpec(specID)
    return MATCHUPS[specID]
end
