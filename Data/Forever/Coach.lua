-- ToonAge/Data/Forever/Coach.lua
--
-- Reference play per spec, used by Modules/Forever/CastLog.lua to compare
-- what you cast with what the guide says to cast.
--
-- SOURCE, AND ITS LIMITS. Every entry below is taken from Icy Veins' WoW
-- Forever spec guides, read 2026-09-27 -- all 27 specs. Those guides are
-- written for the beta's level cap of 20. Nothing here is a game NUMBER (no
-- damage values, no weights) -- only which abilities the guide names and in
-- what role, so a wrong entry produces a wrong suggestion, never a wrong stat.
--
-- Abilities are keyed by NAME, not spell ID: Forever keeps a separate spell
-- ID per rank (Fireball 133/143/145, measured 2026-09-26), and a name matches
-- every rank. An ability is only judged when your spellbook has it, so
-- anything above your level is skipped rather than reported as missing.
-- "A|B" means either one satisfies the entry.
--
-- Roles:
--   buff    keep it up on YOURSELF; checked out of combat. Weapon imbues,
--           poisons, totems and buffs cast on others are left out: they do
--           not show as your own aura.
--   opener  the guide's first cast of a fight (casts in the 3 seconds before
--           combat count, so pulls like Charge and Hunter's Mark are seen)
--   core    the guide expects it in most fights
--   limit   { name, max }: no more than `max` casts in a row
-- Situational advice (AoE, elites only, "when you need Health/Mana") is left
-- out on purpose -- the record cannot tell when the situation applied.

local TA = ToonAge
TA.Data = TA.Data or {}

local IV = "https://www.icy-veins.com/wow-forever/"

TA.Data.ForeverCoach = {
    DRUID = {
        Balance = {
            source = IV .. "balance-druid-ranged-dps-pve-guide",
            opener = { "Moonfire" },
            core   = { "Moonfire", "Wrath" },
        },
        Feral = {
            source = IV .. "feral-druid-melee-dps-and-tank-pve-guide",
            buff   = { "Mark of the Wild", "Thorns" },
            core   = { "Claw", "Rip" },
        },
        Restoration = {
            source = IV .. "restoration-druid-healer-pve-guide",
            core   = { "Rejuvenation", "Healing Touch" },
        },
    },
    HUNTER = {
        ["Beast Mastery"] = {
            source = IV .. "beast-mastery-hunter-ranged-dps-pve-guide",
            buff   = { "Aspect of the Hawk" },
            opener = { "Hunter's Mark" },
            core   = { "Serpent Sting", "Aimed Shot" },
        },
        Marksmanship = {
            source = IV .. "marksmanship-hunter-ranged-dps-pve-guide",
            buff   = { "Aspect of the Hawk" },
            opener = { "Hunter's Mark" },
            core   = { "Serpent Sting", "Aimed Shot" },
        },
        Survival = {
            source = IV .. "survival-hunter-melee-dps-pve-guide",
            buff   = { "Aspect of the Hawk" },
            opener = { "Hunter's Mark" },
            core   = { "Serpent Sting", "Aimed Shot" },
        },
    },
    MAGE = {
        Arcane = {
            source = IV .. "arcane-mage-ranged-dps-pve-guide",
            buff   = { "Arcane Intellect", "Frost Armor|Mage Armor" },
            opener = { "Frostbolt" },
            core   = { "Arcane Blast", "Arcane Missiles" },
            limit  = { { "Arcane Blast", 4 } },
        },
        Fire = {
            source = IV .. "fire-mage-ranged-dps-pve-guide",
            buff   = { "Arcane Intellect", "Frost Armor|Mage Armor" },
            -- Low levels: Fireball is the filler. Fire Blast on cooldown.
            -- Frost Nova is an emergency, not part of the rotation.
            -- Heavy Arcane Missiles use is what the comparison flags.
            opener = { "Fireball" },
            core   = { "Fireball", "Fire Blast" },
            flag   = { "Arcane Missiles" },
        },
        Frost = {
            source = IV .. "frost-mage-ranged-dps-pve-guide",
            buff   = { "Arcane Intellect", "Frost Armor" },
            opener = { "Frostbolt" },
            core   = { "Frostbolt", "Ice Lance" },
        },
    },
    PALADIN = {
        Holy = {
            source = IV .. "holy-paladin-healer-pve-guide",
            buff   = { "Seal of Righteousness" },
            core   = { "Flash of Light", "Holy Light" },
        },
        Protection = {
            source = IV .. "protection-paladin-tank-pve-guide",
            buff   = { "Seal of Fury" },
            core   = { "Consecration", "Judgement", "Holy Strike" },
        },
        Retribution = {
            source = IV .. "retribution-paladin-melee-dps-pve-guide",
            buff   = { "Seal of Righteousness|Seal of Command",
                       "Blessing of Might|Blessing of Kings", "Devotion Aura" },
            core   = { "Holy Strike", "Judgement" },
        },
    },
    PRIEST = {
        Discipline = {
            source = IV .. "discipline-priest-healer-pve-guide",
            buff   = { "Power Word: Fortitude", "Inner Fire" },
            core   = { "Power Word: Shield", "Heal", "Renew" },
        },
        Holy = {
            source = IV .. "holy-priest-healer-pve-guide",
            buff   = { "Power Word: Fortitude", "Inner Fire" },
            core   = { "Power Word: Shield", "Heal", "Renew" },
        },
        Shadow = {
            source = IV .. "shadow-priest-ranged-dps-pve-guide",
            buff   = { "Power Word: Fortitude", "Inner Fire" },
            opener = { "Smite" },
            core   = { "Power Word: Shield", "Mind Blast", "Shadow Word: Pain" },
        },
    },
    ROGUE = {
        Assassination = {
            source = IV .. "assassination-rogue-melee-dps-pve-guide",
            opener = { "Ambush" },
            core   = { "Backstab|Sinister Strike", "Slice and Dice", "Eviscerate" },
        },
        Combat = {
            source = IV .. "combat-rogue-melee-dps-pve-guide",
            opener = { "Ambush" },
            core   = { "Backstab|Sinister Strike", "Slice and Dice", "Eviscerate" },
        },
        Subtlety = {
            source = IV .. "subtlety-rogue-melee-dps-pve-guide",
            opener = { "Gouge" },
            core   = { "Backstab|Sinister Strike", "Eviscerate" },
        },
    },
    SHAMAN = {
        Elemental = {
            source = IV .. "elemental-shaman-ranged-dps-pve-guide",
            opener = { "Lightning Bolt" },
            core   = { "Flame Shock", "Lightning Bolt" },
        },
        Enhancement = {
            source = IV .. "enhancement-shaman-melee-dps-pve-guide",
            buff   = { "Lightning Shield" },
            opener = { "Lightning Bolt" },
            core   = { "Earth Shock|Frost Shock" },
        },
        Restoration = {
            source = IV .. "restoration-shaman-healer-pve-guide",
            core   = { "Healing Wave" },
        },
    },
    WARLOCK = {
        Affliction = {
            source = IV .. "affliction-warlock-ranged-dps-pve-guide",
            buff   = { "Demon Armor|Demon Skin" },
            core   = { "Immolate", "Corruption", "Bane of Agony" },
        },
        Demonology = {
            source = IV .. "demonology-warlock-ranged-dps-pve-guide",
            buff   = { "Demon Armor|Demon Skin" },
            core   = { "Immolate", "Corruption", "Bane of Agony" },
        },
        Destruction = {
            source = IV .. "destruction-warlock-ranged-dps-pve-guide",
            buff   = { "Demon Armor|Demon Skin" },
            core   = { "Immolate", "Corruption", "Shadow Bolt" },
        },
    },
    WARRIOR = {
        Arms = {
            source = IV .. "arms-warrior-melee-dps-pve-guide",
            buff   = { "Battle Shout" },
            opener = { "Charge" },
            core   = { "Rend", "Sunder Armor", "Demoralizing Shout",
                       "Victory Rush", "Overpower", "Slam" },
        },
        Fury = {
            source = IV .. "fury-warrior-melee-dps-pve-guide",
            buff   = { "Battle Shout" },
            opener = { "Charge" },
            core   = { "Rend", "Sunder Armor", "Demoralizing Shout",
                       "Victory Rush", "Overpower" },
        },
        Protection = {
            source = IV .. "protection-warrior-tank-pve-guide",
            buff   = { "Battle Shout" },
            opener = { "Charge" },
            core   = { "Demoralizing Shout", "Victory Rush", "Revenge", "Sunder Armor" },
        },
    },
}
