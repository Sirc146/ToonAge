-- ToonAge/Data/TBCRaces.lua (Anniversary — TBC Classic / Interface 20506)
-- Racial traits, split by how much this addon is willing to stake on them.
--
-- ─── TWO KINDS OF DATA, DELIBERATELY SEPARATED ───────────────────────────────
--
-- `mechanical` — feeds the cap maths in Core/TBCStats.lua. A wrong value here
--   makes the addon tell you the wrong hit cap, so it holds only the two things
--   that actually move a number and that are unambiguous in TBC:
--     * racial weapon-skill bonuses (+5 skill shifts the melee hit cap)
--     * Draenei Heroic Presence (+1% hit, party-wide in TBC)
--
-- `described` — reference text for the Racials tab. Nothing computes from it.
--   Wrong text here misinforms a reader; it cannot corrupt a calculation.
--
-- ─── CORRECTIONS TO Docs/CLASSIC_ANNIVERSARY_BRIEF.md ────────────────────────
--
-- The brief lists "Gnome +5 Dagger/1H Sword" among the racial weapon skills.
-- Gnomes have no weapon-skill racial in TBC — Shortblade Specialization is a
-- Cataclysm (4.0) addition, and it grants expertise, not weapon skill. It is
-- omitted from `mechanical` rather than carried forward, because including it
-- would raise a Gnome's computed hit cap accuracy off a bonus they do not have.
--
-- Race tokens are what UnitRace() returns, NOT display names: Undead is
-- "Scourge". Matching on the localized display name would break on any non-
-- English client.
--
-- CONFIDENCE: the weapon-skill bonuses and Heroic Presence are TBC-stable and
-- well established. Individual numbers in `described` (stun resist %, resistance
-- amounts) shifted between expansions and are shown as reference, not asserted
-- as exact — the tab labels them as such.

local TA = ToonAge
TA.Data = TA.Data or {}

-- ─── WEAPON SKILL LINES ──────────────────────────────────────────────────────
-- English skill-line names as they appear in the skill window. Used only to
-- match a racial bonus to a scanned skill line; a miss shows no bonus rather
-- than a wrong one.

TA.Data.WeaponSkillNames = {
    "Axes", "Two-Handed Axes",
    "Swords", "Two-Handed Swords",
    "Maces", "Two-Handed Maces",
    "Daggers", "Fist Weapons", "Unarmed",
    "Polearms", "Staves",
    "Bows", "Crossbows", "Guns", "Thrown", "Wands",
}

-- Maps GetItemInfo's itemSubType (return 7) to the skill line that governs it.
TA.Data.SubTypeToSkill = {
    ["One-Handed Axes"]   = "Axes",
    ["Two-Handed Axes"]   = "Two-Handed Axes",
    ["One-Handed Swords"] = "Swords",
    ["Two-Handed Swords"] = "Two-Handed Swords",
    ["One-Handed Maces"]  = "Maces",
    ["Two-Handed Maces"]  = "Two-Handed Maces",
    ["Daggers"]           = "Daggers",
    ["Fist Weapons"]      = "Fist Weapons",
    ["Polearms"]          = "Polearms",
    ["Staves"]            = "Staves",
    ["Bows"]              = "Bows",
    ["Crossbows"]         = "Crossbows",
    ["Guns"]              = "Guns",
    ["Thrown"]            = "Thrown",
    ["Wands"]             = "Wands",
}

-- ─── MECHANICAL (drives calculations) ────────────────────────────────────────

TA.Data.RaceMechanics = {
    Human = {
        weaponSkill = {
            ["Swords"]            = 5,
            ["Two-Handed Swords"] = 5,
            ["Maces"]             = 5,
            ["Two-Handed Maces"]  = 5,
        },
        source = "Sword Specialization, Mace Specialization",
    },
    Orc = {
        weaponSkill = {
            ["Axes"]            = 5,
            ["Two-Handed Axes"] = 5,
        },
        source = "Axe Specialization",
    },
    Dwarf = {
        weaponSkill = { ["Guns"] = 5 },
        source = "Gun Specialization",
    },
    Troll = {
        weaponSkill = { ["Bows"] = 5, ["Thrown"] = 5 },
        source = "Bow Specialization, Throwing Specialization",
    },
    Draenei = {
        -- Heroic Presence in TBC is a party-wide +1% hit aura, and it applies to
        -- the Draenei too. GetCombatRatingBonus does NOT include it, so the cap
        -- maths has to add it explicitly or a Draenei over-gears hit by 1%.
        spellHitPercent = 1,
        meleeHitPercent = 1,
        source = "Heroic Presence",
    },
    NightElf = {
        dodgePercent = 1,
        source = "Quickness",
    },
    -- Scourge (Undead), Tauren, Gnome, BloodElf have no racial that changes a
    -- cap or a rating in TBC. Absent on purpose — see the header note on Gnomes.
}

-- ─── DESCRIBED (reference text only) ─────────────────────────────────────────

TA.Data.RaceTraits = {
    Human = {
        name = "Human",
        traits = {
            { n = "Sword Specialization", d = "+5 skill with one- and two-handed swords", combat = true },
            { n = "Mace Specialization",  d = "+5 skill with one- and two-handed maces",  combat = true },
            { n = "The Human Spirit",     d = "+10% Spirit — more out-of-combat and Five Second Rule regen" },
            { n = "Perception",           d = "Active: large stealth-detection boost for 20s" },
            { n = "Diplomacy",            d = "+10% reputation gain" },
        },
        advice = "Two weapon-skill lines is the widest melee coverage of any race. "
              .. "Using a sword or mace effectively lowers your hit cap by 1%, which "
              .. "is 15.77 rating at 70 you can spend elsewhere.",
    },
    Orc = {
        name = "Orc",
        traits = {
            { n = "Axe Specialization", d = "+5 skill with one- and two-handed axes", combat = true },
            { n = "Blood Fury",         d = "Active: large attack power (or spell damage) burst", combat = true },
            { n = "Hardiness",          d = "Reduced chance to be affected by stun effects" },
            { n = "Command",            d = "+5% damage from your pets (Hunter, Warlock)", combat = true },
        },
        advice = "Axes lower your effective hit cap by 1% when your axe skill is capped. "
              .. "Blood Fury is a free damage cooldown — bind it.",
    },
    Dwarf = {
        name = "Dwarf",
        traits = {
            { n = "Gun Specialization", d = "+5 skill with guns", combat = true },
            { n = "Stoneform",          d = "Active: removes bleed, poison and disease; +armour", combat = true },
            { n = "Frost Resistance",   d = "Bonus frost resistance" },
            { n = "Find Treasure",      d = "Shows nearby chests on the minimap" },
        },
        advice = "Gun Specialization only matters if you actually use a gun — for a "
              .. "Hunter that is a real ranged-hit saving, for anyone else it is cosmetic.",
    },
    NightElf = {
        name = "Night Elf",
        traits = {
            { n = "Quickness",         d = "+1% chance to dodge", combat = true },
            { n = "Shadowmeld",        d = "Active: stealth while stationary" },
            { n = "Nature Resistance", d = "Bonus nature resistance" },
            { n = "Wisp Spirit",       d = "+50% movement speed while dead" },
        },
        advice = "The 1% dodge is a genuine tank contribution and is already counted in "
              .. "your character sheet's dodge number.",
    },
    Gnome = {
        name = "Gnome",
        traits = {
            { n = "Expansive Mind",         d = "+5% Intellect — more mana and spell crit" },
            { n = "Arcane Resistance",      d = "Bonus arcane resistance" },
            { n = "Escape Artist",          d = "Active: escapes roots and snares" },
            { n = "Engineering Specialist", d = "+15 Engineering skill" },
        },
        advice = "No weapon-skill racial in TBC — the dagger and one-handed sword bonus "
              .. "some guides mention is a Cataclysm addition and does not exist here. "
              .. "Expansive Mind is the caster draw.",
    },
    Draenei = {
        name = "Draenei",
        traits = {
            { n = "Heroic Presence", d = "+1% chance to hit for you and your whole party", combat = true },
            { n = "Gift of the Naaru", d = "Active: heal over time, scales with your power", combat = true },
            { n = "Shadow Resistance", d = "Bonus shadow resistance" },
            { n = "Gemcutting", d = "+10 Jewelcrafting skill" },
        },
        advice = "That +1% hit is already subtracted from every hit target this addon "
              .. "shows you. It is worth ~16 hit rating at 70, and every party member "
              .. "gets it too — which is why raids want one of you.",
    },
    Scourge = {
        name = "Undead",
        traits = {
            { n = "Will of the Forsaken", d = "Active: breaks and prevents fear, sleep and charm", combat = true },
            { n = "Cannibalize",          d = "Active: heals from a nearby corpse" },
            { n = "Shadow Resistance",    d = "Bonus shadow resistance" },
            { n = "Underwater Breathing", d = "Greatly extended breath" },
        },
        advice = "No stat racial — Will of the Forsaken is the whole package, and in "
              .. "TBC content that breaks fear it is worth more than a stat would be.",
    },
    Tauren = {
        name = "Tauren",
        traits = {
            { n = "Endurance",         d = "+5% base health", combat = true },
            { n = "War Stomp",         d = "Active: stuns nearby enemies", combat = true },
            { n = "Cultivation",       d = "+15 Herbalism skill" },
            { n = "Nature Resistance", d = "Bonus nature resistance" },
        },
        advice = "The health bonus is multiplicative with Stamina, so it is worth more "
              .. "the better geared you are — a real tank racial.",
    },
    Troll = {
        name = "Troll",
        traits = {
            { n = "Bow Specialization",      d = "+5 skill with bows", combat = true },
            { n = "Throwing Specialization", d = "+5 skill with thrown weapons", combat = true },
            { n = "Berserking",              d = "Active: haste burst, stronger at low health", combat = true },
            { n = "Beast Slaying",           d = "+5% damage to Beasts", combat = true },
            { n = "Regeneration",            d = "Improved health regeneration, partly active in combat" },
        },
        advice = "Berserking is a haste cooldown available to every spec — it is the "
              .. "reason Trolls are picked, far more than the bow skill.",
    },
    BloodElf = {
        name = "Blood Elf",
        traits = {
            { n = "Arcane Torrent",  d = "Active: silences nearby enemies and restores resource", combat = true },
            { n = "Magic Resistance",d = "Bonus resistance to all magic schools" },
            { n = "Arcane Affinity", d = "+10 Enchanting skill" },
        },
        advice = "Arcane Torrent is an extra interrupt on a short cooldown for classes "
              .. "that otherwise have none — that is its value, not the resource return.",
    },
}

--- Total racial weapon-skill bonus for a named skill line.
function TA.Data.GetRacialWeaponSkill(raceToken, skillName)
    local m = TA.Data.RaceMechanics[raceToken]
    if not m or not m.weaponSkill then return 0 end
    return m.weaponSkill[skillName] or 0
end
