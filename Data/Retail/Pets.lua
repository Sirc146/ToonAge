-- ToonAge/Data/Pets.lua
-- Pet family database, zone tameable pets, and class summon data

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Pets = {}
local P = TA.Data.Pets

-- ── Prerequisites ─────────────────────────────────────────────────────
P.Prereqs = {
    BM = "Beast Mastery specialization only",
    UndeadTaming = "Requires Tome of Undead Taming (purchased from exotic pet trainer)",
    MechTaming = "Requires Tome of the Hybrid Beast (purchased or crafted by Engineer)",
    Feathermane = 'Requires completion of "You\'ll Never Tame Them All" achievement chain',
    CloudSerpent = "Requires Order of the Cloud Serpent Exalted reputation",
    Tentacle = "Requires purchase from specific vendor in Shadowlands",
}

-- ── Hunter pet family database ─────────────────────────────────────────
-- role:   FEROCITY / TENACITY / CUNNING
-- exotic: true = Beast Mastery only
-- prereq: key into P.Prereqs (additional requirement on top of spec)
-- lust:   has Primal Rage (Bloodlust effect) — FEROCITY passive
-- mw:     has Mortal Wounds ability
-- shield: has Shell Shield / Defensive Carapace cooldown
-- bestFor: scenario guidance string shown in UI

local F, T, C = "FEROCITY", "TENACITY", "CUNNING"

P.FamilyDB = {
    -- ── FEROCITY (DPS + Bloodlust) ─────────────────────────────────────
    ["Bat"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Consistent melee-range DPS.",
    },
    ["Cat"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Among the highest raw pet DPS.",
    },
    ["Core Hound"] = {
        role = F,
        exotic = true,
        lust = true,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Raids. Bloodlust + Ancient Hysteria (second lust). BM exotic.",
    },
    ["Crocolisk"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & Leveling. Bloodlust with solid survivability.",
    },
    ["Devilsaur"] = {
        role = F,
        exotic = true,
        lust = true,
        mw = true,
        shield = false,
        prereq = "BM",
        bestFor = "PvP & Raids. Bloodlust + Mortal Wounds. Best BM damage exotic.",
    },
    ["Dragonhawk"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Ranged Flame Breath synergy.",
    },
    ["Hyena"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = true,
        shield = false,
        bestFor = "PvP & Raids. Bloodlust + Mortal Wounds. Strong all-rounder.",
    },
    ["Raptor"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = true,
        shield = false,
        bestFor = "PvP & Raids. Bloodlust + Mortal Wounds. Classic top pick.",
    },
    ["Rodent"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust.",
    },
    ["Serpent"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids. Bloodlust. Can attack at range.",
    },
    ["Spirit Beast"] = {
        role = F,
        exotic = true,
        lust = true,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "M+ & Raids. Bloodlust + Spirit Mend (off-GCD party heal). BM only.",
    },
    ["Tallstrider"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Fast respawn locations.",
    },
    ["Warp Stalker"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Warp (teleport) passive.",
    },
    ["Water Strider"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust. Surface Walk utility.",
    },
    ["Wind Serpent"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids. Bloodlust. Lightning Breath ranged attack.",
    },
    ["Wolf"] = {
        role = F,
        exotic = false,
        lust = true,
        mw = false,
        shield = false,
        bestFor = "Raids & M+. Bloodlust + Furious Howl damage buff. Default top pick.",
    },
    -- ── TENACITY (Tank + Survivability) ───────────────────────────────
    ["Bear"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "Soloing & Leveling. High HP pool. Comfortable sustained fights.",
    },
    ["Beetle"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = true,
        bestFor = "Soloing & PvP. Defensive Carapace shield cooldown.",
    },
    ["Crab"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = true,
        bestFor = "Soloing & PvP. Shell Shield + high armor. Aquatic zones.",
    },
    ["Direhorn"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Disrupting Roar interrupts spellcasting. Strong utility.",
    },
    ["Gorilla"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "Soloing. Thunderstomp AoE threat for multi-mob control.",
    },
    ["Hydra"] = {
        role = T,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Soloing. Three-head frontal cleave. BM exotic.",
    },
    ["Mammoth"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "Soloing & Leveling. Large HP pool. Trample knockback.",
    },
    ["Mechanical"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        prereq = "MechTaming",
        bestFor = "PvP. Immune to Polymorph, Sap, and Hex. Counters caster CC.",
    },
    ["Oxen"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "Raids & Soloing. Pummel (spell interrupt). Solid Tenacity all-rounder.",
    },
    ["Quilen"] = {
        role = T,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Raids. Eternal Guardian battle resurrection. Potentially game-changing. BM only.",
    },
    ["Rhino"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Stampede knockback to interrupt casters.",
    },
    ["Scalehide"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = true,
        bestFor = "Soloing & PvP. Jagged Flesh bleed + Defensive Carapace cooldown.",
    },
    ["Scorpid"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = true,
        shield = false,
        bestFor = "PvP. Mortal Wounds on a tankier pet. Unusual PvP choice.",
    },
    ["Shale Spider"] = {
        role = T,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Raids (niche). Spell Haste debuff stacks with other sources. BM exotic.",
    },
    ["Stone Hound"] = {
        role = T,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Soloing. Extremely high toughness. BM exotic.",
    },
    ["Turtle"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = false,
        shield = true,
        bestFor = "Soloing & PvP. Shell Shield is the strongest pet defensive cooldown.",
    },
    ["Undead"] = {
        role = T,
        exotic = false,
        lust = false,
        mw = true,
        shield = false,
        prereq = "UndeadTaming",
        bestFor = "PvP. Mortal Wounds + immune to Polymorph. #1 Hunter PvP pet.",
    },
    ["Worm"] = {
        role = T,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "Raids (niche). Acid Spit armor reduction. BM exotic.",
    },
    -- ── CUNNING (Utility + Mobility) ──────────────────────────────────
    ["Bird of Prey"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Disarm (weapon strip). Master's Call. Strong vs melee.",
    },
    ["Camel"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP & Leveling. Speed boost. Master's Call.",
    },
    ["Chimaera"] = {
        role = C,
        exotic = true,
        lust = false,
        mw = false,
        shield = false,
        prereq = "BM",
        bestFor = "PvP. Froststorm Breath AoE slow. Ranged pet. BM exotic.",
    },
    ["Courser"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. High base movement. Master's Call.",
    },
    ["Crane"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Lullaby (sleep CC). Master's Call. Unique CC tool.",
    },
    ["Feathermane"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        prereq = "Feathermane",
        bestFor = "PvP. Agile + Master's Call. Requires achievement chain unlock.",
    },
    ["Fox"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP & Leveling. Speed + Master's Call. Reliable starter Cunning.",
    },
    ["Goat"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Trample knockback. Master's Call.",
    },
    ["Monkey"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Rake bleed stun. Master's Call.",
    },
    ["Moth"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Serenity Dust sleep. Master's Call. Caster counter.",
    },
    ["Nether Ray"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Nether Shock spellcaster interrupt. Master's Call.",
    },
    ["Pterrordax"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Screech armor debuff. Master's Call.",
    },
    ["Sporebat"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Spore Cloud cast speed debuff. Master's Call.",
    },
    ["Wasp"] = {
        role = C,
        exotic = false,
        lust = false,
        mw = false,
        shield = false,
        bestFor = "PvP. Sting armor debuff. Fast attack. Master's Call.",
    },
}

-- ── Zone tameable pets ─────────────────────────────────────────────────
-- Key: C_Map.GetBestMapForUnit("player") uiMapID
-- Verify map IDs in-game with: /script print(C_Map.GetBestMapForUnit("player"))
-- { name, family, rarity, prereqs, note }
-- rarity: "Common" | "Rare" | "Rare Elite"

P.ZoneDB = {
    -- Dragon Isles ──────────────────────────────────────────────────────
    [2022] = { -- Waking Shores
        { name = "Hornswog", family = "Crocolisk", rarity = "Common", prereqs = {} },
        { name = "Waking Shore Wolf", family = "Wolf", rarity = "Common", prereqs = {} },
        { name = "Obsidian Whelp", family = "Dragonhawk", rarity = "Common", prereqs = {} },
        { name = "Skyscale Watcher", family = "Bird of Prey", rarity = "Rare", prereqs = {} },
    },
    [2023] = { -- Ohn'ahran Plains
        { name = "Plains Wolf", family = "Wolf", rarity = "Common", prereqs = {} },
        { name = "Steppe Hyena", family = "Hyena", rarity = "Common", prereqs = {} },
        { name = "Ohn'ahran Raptor", family = "Raptor", rarity = "Common", prereqs = {} },
        { name = "Tallstrider", family = "Tallstrider", rarity = "Common", prereqs = {} },
        {
            name = "Lizi",
            family = "Tallstrider",
            rarity = "Rare Elite",
            prereqs = {},
            note = "Requires a special lure.",
        },
    },
    [2024] = { -- Azure Span
        { name = "Azure Span Bear", family = "Bear", rarity = "Common", prereqs = {} },
        { name = "Arctic Fox", family = "Fox", rarity = "Common", prereqs = {} },
        { name = "Span Crane", family = "Crane", rarity = "Common", prereqs = {} },
        { name = "Mammoth Matriarch", family = "Mammoth", rarity = "Common", prereqs = {} },
        { name = "Frostbiter", family = "Wolf", rarity = "Rare", prereqs = {} },
    },
    [2025] = { -- Thaldraszus
        { name = "Warp Stalker", family = "Warp Stalker", rarity = "Common", prereqs = {} },
        { name = "Thaldraszus Wolf", family = "Wolf", rarity = "Common", prereqs = {} },
        { name = "Serpent", family = "Serpent", rarity = "Common", prereqs = {} },
    },
    -- Shadowlands ───────────────────────────────────────────────────────
    [2100] = { -- Maldraxxus
        {
            name = "Plagueborn Alkosh",
            family = "Undead",
            rarity = "Rare",
            prereqs = { "UndeadTaming" },
            note = "Rare undead wolf with striking plague aesthetic.",
        },
        {
            name = "Rotbone Crawler",
            family = "Beetle",
            rarity = "Common",
            prereqs = {},
            note = "Undead-looking beetle; does NOT require Undead Taming.",
        },
        { name = "Fetid Gnasher", family = "Undead", rarity = "Common", prereqs = { "UndeadTaming" } },
        { name = "Maldraxxus Hydra", family = "Hydra", rarity = "Common", prereqs = { "BM" } },
    },
    [2112] = { -- Ardenweald
        {
            name = "Shahe",
            family = "Spirit Beast",
            rarity = "Rare",
            prereqs = { "BM" },
            note = "Glowing dream crane spirit beast. Long spawn timer.",
        },
        {
            name = "Dreamrunner",
            family = "Courser",
            rarity = "Rare",
            prereqs = {},
            note = "Spectral horse. Stunning appearance.",
        },
        { name = "Ardenweald Moth", family = "Moth", rarity = "Common", prereqs = {} },
        { name = "Grove Crane", family = "Crane", rarity = "Common", prereqs = {} },
    },
    [2118] = { -- Bastion
        {
            name = "Steward Larion",
            family = "Cat",
            rarity = "Common",
            prereqs = {},
            note = "The famous kyrian cat-lions. Iconic Shadowlands pet.",
        },
        {
            name = "Phalynx",
            family = "Mechanical",
            rarity = "Common",
            prereqs = { "MechTaming" },
            note = "Bastion construct. Requires Mechanical Taming.",
        },
    },
    -- Existing void/undead zones (from existing addon data) ─────────────
    [2434] = {
        { name = "Void-Touched Raptor", family = "Undead", rarity = "Common", prereqs = { "UndeadTaming" } },
        { name = "Void Crawler", family = "Beetle", rarity = "Common", prereqs = {} },
        { name = "Void Worg", family = "Wolf", rarity = "Rare", prereqs = {} },
    },
    [2436] = {
        { name = "Undead Stalker", family = "Undead", rarity = "Rare", prereqs = { "UndeadTaming" } },
        { name = "Plague Raptor", family = "Undead", rarity = "Common", prereqs = { "UndeadTaming" } },
    },
    -- Classic zones ─────────────────────────────────────────────────────
    [37] = { -- Elwynn Forest
        { name = "Forest Wolf", family = "Wolf", rarity = "Common", prereqs = {} },
        { name = "Forest Cat", family = "Cat", rarity = "Common", prereqs = {} },
        { name = "Webwood Spider", family = "Beetle", rarity = "Common", prereqs = {} },
    },
    [20] = { -- Tirisfal Glades
        { name = "Tirisfal Bat", family = "Bat", rarity = "Common", prereqs = {} },
        { name = "Undead Bear", family = "Undead", rarity = "Common", prereqs = { "UndeadTaming" } },
    },
    [23] = { -- Eastern Plaguelands
        { name = "Plague Bat", family = "Bat", rarity = "Common", prereqs = {} },
        { name = "Carrion Bird", family = "Bird of Prey", rarity = "Common", prereqs = {} },
        { name = "Undead Wolf", family = "Undead", rarity = "Common", prereqs = { "UndeadTaming" } },
        { name = "Diseased Bear", family = "Bear", rarity = "Common", prereqs = {} },
    },
    [118] = { -- Icecrown (Northrend)
        {
            name = "Chillmaw",
            family = "Bat",
            rarity = "Rare Elite",
            prereqs = {},
            note = "Giant bat. Patrol path kill required first.",
        },
        { name = "Icecrown Wolf", family = "Wolf", rarity = "Common", prereqs = {} },
    },
    [249] = { -- Uldum
        { name = "Uldum Cat", family = "Cat", rarity = "Common", prereqs = {} },
        { name = "Uldum Scorpid", family = "Scorpid", rarity = "Common", prereqs = {} },
        { name = "Desert Fox", family = "Fox", rarity = "Common", prereqs = {} },
    },
}

-- ── Class pet / summon data (non-Hunter) ──────────────────────────────
P.ClassPetDB = {
    WARLOCK = {
        {
            name = "Imp",
            role = "DPS",
            summonType = "Permanent",
            spec = "All",
            desc = "Ranged fire DPS. Fel Firebolt spam. Singe Magic dispel.",
        },
        {
            name = "Voidwalker",
            role = "TANK",
            summonType = "Permanent",
            spec = "All",
            desc = "Melee tank pet. Torment taunt. Consume Shadows self-heal. Open world tanking.",
        },
        {
            name = "Felhunter",
            role = "UTILITY",
            summonType = "Permanent",
            spec = "All",
            desc = "Spell interrupt (Spell Lock). Devour Magic dispel. Essential for PvP.",
        },
        {
            name = "Succubus",
            role = "CONTROL",
            summonType = "Permanent",
            spec = "All",
            desc = "Seduction CC. Whiplash knockback. Shadow Embrace DoT. PvP control.",
        },
        {
            name = "Felguard",
            role = "DPS",
            summonType = "Permanent",
            spec = "Demonology",
            desc = "Melee DPS guardian. Felstorm AoE. Axe Toss stun. Demo only.",
        },
        {
            name = "Infernal",
            role = "DPS",
            summonType = "Temporary",
            duration = 30,
            desc = "Burst AoE DPS guardian. Immolation aura + melee. Stuns on impact.",
        },
        {
            name = "Doomguard",
            role = "DPS",
            summonType = "Temporary",
            duration = 25,
            desc = "Ranged DPS cooldown. Doom Bolt. Used on Demonic Power talent.",
        },
        {
            name = "Demonic Tyrant",
            role = "SUPPORT",
            summonType = "Temporary",
            duration = 15,
            spec = "Demonology",
            desc = "Empowers all active demons, extending their duration.",
        },
        {
            name = "Wild Imps",
            role = "DPS",
            summonType = "Temporary",
            spec = "Demonology",
            desc = "Spawned by Hand of Gul'dan. Stack with Inner Demons talent.",
        },
    },
    DEATHKNIGHT = {
        {
            name = "Ghoul",
            role = "DPS",
            summonType = "Permanent",
            spec = "Unholy",
            desc = "Melee DPS companion. Gnaw stun. Monstrous Blow. Empowered by Dark Transformation.",
        },
        {
            name = "Army of the Dead",
            role = "DPS",
            summonType = "Temporary",
            duration = 40,
            spec = "Unholy",
            desc = "8 ghouls for burst DPS. Major cooldown. Apocalypse timing.",
        },
        {
            name = "Gargoyle",
            role = "DPS",
            summonType = "Temporary",
            duration = 30,
            spec = "Unholy",
            desc = "Ranged DPS gargoyle. Empowered by Runic Power spent before summon.",
        },
        {
            name = "Abomination",
            role = "CONTROL",
            summonType = "Temporary",
            spec = "Unholy",
            desc = "PvP talent: melee tank pet with hook and hook-pull CC.",
        },
        {
            name = "Magus of the Dead",
            role = "DPS",
            summonType = "Temporary",
            spec = "Unholy",
            desc = "Summoned by Apocalypse. Amplifies shadow damage.",
        },
    },
    MAGE = {
        {
            name = "Water Elemental",
            role = "DPS",
            summonType = "Permanent",
            spec = "Frost",
            desc = "Ranged DPS pet. Waterbolt. Freeze (AoE root). Passive Geyser burst.",
        },
    },
    SHAMAN = {
        {
            name = "Fire Elemental",
            role = "DPS",
            summonType = "Temporary",
            duration = 30,
            spec = "Elemental",
            desc = "Burst DPS guardian. Empowers fire spells. Major cooldown.",
        },
        {
            name = "Storm Elemental",
            role = "DPS",
            summonType = "Temporary",
            duration = 30,
            spec = "Elemental",
            desc = "Sustained DPS + Call Lightning Maelstrom gen. Alt to Fire Elem.",
        },
        {
            name = "Earth Elemental",
            role = "TANK",
            summonType = "Temporary",
            duration = 60,
            spec = "All",
            desc = "Tank guardian. Taunt, AoE stomp. Rarely used in current meta.",
        },
        {
            name = "Feral Spirits",
            role = "DPS",
            summonType = "Temporary",
            duration = 15,
            spec = "Enhancement",
            desc = "Wolf DPS pair. Spirit Walk healing. Empowered by Witch Doctor's Wolf Pack.",
        },
    },
    DRUID = {
        {
            name = "Force of Nature Treants",
            role = "DPS",
            summonType = "Temporary",
            duration = 10,
            spec = "Balance",
            desc = "3 treant DPS burst. Stomp stun on Resto spec.",
        },
        {
            name = "Grove Guardians",
            role = "HEALING",
            summonType = "Temporary",
            duration = 15,
            spec = "Restoration",
            desc = "3 healing treants. Nourish HoT. Major burst healing tool.",
        },
    },
    PRIEST = {
        {
            name = "Shadowfiend",
            role = "DPS",
            summonType = "Temporary",
            duration = 12,
            spec = "Shadow",
            desc = "Shadow DPS pet. Restores mana on hit. 3-min CD.",
        },
        {
            name = "Mindbender",
            role = "DPS",
            summonType = "Temporary",
            duration = 12,
            spec = "Shadow",
            desc = "Shorter CD than Shadowfiend. Better mana return. Talent swap.",
        },
    },
    MONK = {
        {
            name = "Jade Serpent Statue",
            role = "HEALING",
            summonType = "Permanent",
            spec = "Mistweaver",
            desc = "Healing statue. Soothing Mist beam follows your casts. Place strategically.",
        },
        {
            name = "Yu'lon / Chi-Ji",
            role = "HEALING",
            summonType = "Temporary",
            duration = 25,
            spec = "Mistweaver",
            desc = "Celestial healing guardian depending on Invoke talent choice.",
        },
        {
            name = "Niuzao",
            role = "TANK",
            summonType = "Temporary",
            duration = 25,
            spec = "Brewmaster",
            desc = "Celestial tank guardian. Oxen charge + Stomp. Purifies Stagger.",
        },
        {
            name = "Storm, Earth & Fire",
            role = "DPS",
            summonType = "Temporary",
            duration = 15,
            spec = "Windwalker",
            desc = "Two clone DPS spirits. Copy your abilities. SEF major cooldown.",
        },
    },
}

-- ── Accessors ──────────────────────────────────────────────────────────
function P:GetFamilyInfo(familyName)
    return familyName and self.FamilyDB[familyName]
end

function P:GetZonePets(zoneID)
    return zoneID and self.ZoneDB[zoneID] or {}
end

function P:GetClassPets(class)
    return class and self.ClassPetDB[class] or {}
end

function P:GetPrereqText(prereqKey)
    return prereqKey and self.Prereqs[prereqKey] or ("Requires: " .. tostring(prereqKey))
end

-- Returns display label and color for a pet role
function P:GetRoleDisplay(role)
    if role == "FEROCITY" then
        return "Ferocity (DPS)", 1.00, 0.42, 0.29
    end
    if role == "TENACITY" then
        return "Tenacity (Tank)", 0.29, 0.65, 1.00
    end
    if role == "CUNNING" then
        return "Cunning (Utility)", 1.00, 0.82, 0.29
    end
    return role, 0.78, 0.73, 0.48
end
