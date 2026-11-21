-- ToonAge/Data/Forever/Enchants.lua
--
-- Sourced WoW Forever (1.60.1) Enchanting guide reference.
-- Pure data: zero executable logic, zero client API calls.
--
-- Key Forever differences from Vanilla Classic:
--   * No gem sockets exist in Forever.
--   * Flat Health / Mana enchants are converted to Stamina / Intellect.
--   * Necklace, Off-Hand, and Class Relics (Librams, Totems, Idols) gain
--     enchanting support.
--   * Enchanters receive personal Ring enchants (Attack Power, Spell Power,
--     or Stamina) that scale with Enchanting skill.
--
-- Sources:
--   https://www.icy-veins.com/wow-forever/enchanting-profession-guide
--   https://www.wowhead.com/forever/guide/professions/enchanting-overview

local TA = ToonAge
TA.Data = TA.Data or {}

local IV_ENCH = "https://www.icy-veins.com/wow-forever/enchanting-profession-guide"
local WH_ENCH = "https://www.wowhead.com/forever/guide/professions/enchanting-overview"

TA.Data.ForeverEnchants = {
    meta = {
        version = "1.60.1",
        noGems = true,
        summary = "Forever has no gem sockets. Necklace, Off-Hand, and Class Relics gain enchants, and Enchanters can enchant their own rings (scaling with skill).",
        sources = { IV_ENCH, WH_ENCH },
    },

    perks = {
        enchanterRings = {
            slotID = 11,
            label = "Enchanter Ring Enchants",
            note = "Personal ring enchants (Attack Power, Spell Power, or Stamina) scale with Enchanting skill.",
            foreverNew = true,
            source = IV_ENCH,
        },
        classRelics = {
            slotID = 18,
            label = "Crafted Class Relics",
            note = "Enchanters craft class Relics (Librams, Totems, Idols) in Forever.",
            foreverNew = true,
            source = WH_ENCH,
        },
    },

    -- Maps classToken -> specName (or _default) -> role key below.
    classRoleMap = {
        MAGE = {
            _default = "caster",
        },
        WARLOCK = {
            _default = "caster",
        },
        PRIEST = {
            Shadow = "caster",
            Discipline = "healer",
            Holy = "healer",
            _default = "healer",
        },
        WARRIOR = {
            Protection = "tank",
            Arms = "melee_str",
            Fury = "melee_str",
            _default = "melee_str",
        },
        PALADIN = {
            Protection = "tank",
            Holy = "healer",
            Retribution = "melee_str",
            _default = "healer",
        },
        ROGUE = {
            _default = "melee_agi",
        },
        HUNTER = {
            _default = "melee_agi",
        },
        SHAMAN = {
            Elemental = "caster",
            Enhancement = "melee_str",
            Restoration = "healer",
            _default = "caster",
        },
        DRUID = {
            Balance = "caster",
            Feral = "melee_agi",
            ["Feral (Bear)"] = "tank",
            ["Feral (Cat)"] = "melee_agi",
            Restoration = "healer",
            _default = "caster",
        },
    },

    roles = {
        caster = {
            label = "Caster DPS",
            summary = "Prioritize Spell Power, Intellect, and Haste. Off-Hand Wisdom and Necklace Spell Power are new in Forever.",
            source = IV_ENCH,
            slots = {
                { slotID = 16, slot = "Weapon",   enchant = "2H Spellblasting (+65 SP) or 1H Mighty Intellect (+22 Int)", levelNote = "Lv 60" },
                { slotID = 2,  slot = "Neck",     enchant = "Spell Power (+6 SP)", foreverNew = true, levelNote = "Lv 60" },
                { slotID = 15, slot = "Back",     enchant = "Greater Resistance (+5 All Res)", levelNote = "Lv 60" },
                { slotID = 5,  slot = "Chest",    enchant = "Greater Stats (+4 All Stats)", levelNote = "Lv 60" },
                { slotID = 9,  slot = "Wrist",    enchant = "Greater Spellpower (+16 SP)", levelNote = "Lv 60" },
                { slotID = 10, slot = "Hands",    enchant = "School Power (+20) or Minor Haste (+1% Haste)", levelNote = "Lv 60" },
                { slotID = 8,  slot = "Feet",     enchant = "Greater Stamina (+7 Sta)", levelNote = "Lv 60" },
                { slotID = 17, slot = "Off-Hand", enchant = "Wisdom (+6 Int, +5 Spi)", foreverNew = true, requireHoldable = true, levelNote = "Lv 60" },
            },
        },
        healer = {
            label = "Healer",
            summary = "Healing Power also grants 1/3 Spell Damage in Forever. Off-Hand Wisdom and Necklace Healing Power are new.",
            source = IV_ENCH,
            slots = {
                { slotID = 16, slot = "Weapon",   enchant = "2H Mighty Healing Power (+100 Heal / +34 Dmg) or 1H Mighty Spirit (+22 Spi)", levelNote = "Lv 60" },
                { slotID = 2,  slot = "Neck",     enchant = "Healing Power (+11 Heal / +4 Dmg)", foreverNew = true, levelNote = "Lv 60" },
                { slotID = 15, slot = "Back",     enchant = "Greater Resistance (+5 All Res)", levelNote = "Lv 60" },
                { slotID = 5,  slot = "Chest",    enchant = "Greater Stats (+4 All Stats)", levelNote = "Lv 60" },
                { slotID = 9,  slot = "Wrist",    enchant = "Healing Power (+24 Heal / +8 Dmg)", levelNote = "Lv 60" },
                { slotID = 10, slot = "Hands",    enchant = "Minor Haste (+1% Haste)", levelNote = "Lv 60" },
                { slotID = 8,  slot = "Feet",     enchant = "Spirit (+5 Spi)", levelNote = "Lv 60" },
                { slotID = 17, slot = "Off-Hand", enchant = "Wisdom (+6 Int, +5 Spi)", foreverNew = true, requireHoldable = true, levelNote = "Lv 60" },
            },
        },
        melee_str = {
            label = "Strength Melee",
            summary = "Crusader and Strength enchants lead melee throughput; Necklace Strength is new in Forever.",
            source = IV_ENCH,
            slots = {
                { slotID = 16, slot = "Weapon", enchant = "Crusader (1H/2H) or 2H Agility (+25 Agi)", levelNote = "Lv 60" },
                { slotID = 2,  slot = "Neck",   enchant = "Strength (+5 Str)", foreverNew = true, levelNote = "Lv 60" },
                { slotID = 15, slot = "Back",   enchant = "Greater Resistance (+5 All Res) or Agility (+5 Agi)", levelNote = "Lv 60" },
                { slotID = 5,  slot = "Chest",  enchant = "Greater Stats (+4 All Stats)", levelNote = "Lv 60" },
                { slotID = 9,  slot = "Wrist",  enchant = "Superior Strength (+9 Str)", levelNote = "Lv 60" },
                { slotID = 10, slot = "Hands",  enchant = "Superior Strength (+15 Str)", levelNote = "Lv 60" },
                { slotID = 8,  slot = "Feet",   enchant = "Greater Agility (+7 Agi)", levelNote = "Lv 60" },
            },
        },
        melee_agi = {
            label = "Agility DPS",
            summary = "Agility enchants scale crit and Attack Power; Necklace Agility is new in Forever.",
            source = IV_ENCH,
            slots = {
                { slotID = 16, slot = "Weapon", enchant = "Agility (+15 1H / +25 2H) or Crusader", levelNote = "Lv 60" },
                { slotID = 2,  slot = "Neck",   enchant = "Agility (+5 Agi)", foreverNew = true, levelNote = "Lv 60" },
                { slotID = 15, slot = "Back",   enchant = "Agility (+5 Agi)", levelNote = "Lv 60" },
                { slotID = 5,  slot = "Chest",  enchant = "Greater Stats (+4 All Stats)", levelNote = "Lv 60" },
                { slotID = 9,  slot = "Wrist",  enchant = "Superior Strength (+9 Str) or Superior Stamina (+9 Sta)", levelNote = "Lv 60" },
                { slotID = 10, slot = "Hands",  enchant = "Greater Agility (+10 Agi)", levelNote = "Lv 60" },
                { slotID = 8,  slot = "Feet",   enchant = "Greater Agility (+7 Agi)", levelNote = "Lv 60" },
            },
        },
        tank = {
            label = "Tank",
            summary = "Stamina, Defense, and threat enchants; Necklace Deflection is new in Forever.",
            source = WH_ENCH,
            slots = {
                { slotID = 16, slot = "Weapon", enchant = "Crusader (Threat/Sustain)", levelNote = "Lv 60" },
                { slotID = 2,  slot = "Neck",   enchant = "Deflection (+5 Def)", foreverNew = true, levelNote = "Lv 60" },
                { slotID = 15, slot = "Back",   enchant = "Greater Resistance (+5 All Res)", levelNote = "Lv 60" },
                { slotID = 5,  slot = "Chest",  enchant = "Greater Stats (+4 All Stats) or Major Stamina", levelNote = "Lv 60" },
                { slotID = 9,  slot = "Wrist",  enchant = "Superior Stamina (+9 Sta)", levelNote = "Lv 60" },
                { slotID = 10, slot = "Hands",  enchant = "Greater Agility (+10 Agi) or Threat", levelNote = "Lv 60" },
                { slotID = 8,  slot = "Feet",   enchant = "Greater Stamina (+7 Sta)", levelNote = "Lv 60" },
                { slotID = 17, slot = "Shield", enchant = "Greater Stamina (+7 Sta)", requireShield = true, levelNote = "Lv 60" },
            },
        },
    },
}
