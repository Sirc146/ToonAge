-- ToonAge/Data/Forever/StatPriority.lua
--
-- Level-60 stat orders for WoW Forever. Chronicler compared Icy Veins and
-- Wowhead Forever on 12 Nov 2026 against build 70888. Every row is CONFLICT.
-- Both orders are stored. They are not averaged and neither one is confirmed.
-- Icy Veins endgame Stats pages are stamped Nov 4, 2026.
-- Feral is two rows, Cat and Bear. There is no Guardian, Death Knight, Monk,
-- Demon Hunter or Evoker row.
-- A Wowhead caveat is copied only on the pages that call the order speculative
-- because the beta was level-locked at 30.

local TA = ToonAge
TA.Data = TA.Data or {}

local IV = "https://www.icy-veins.com/wow-forever/"
local WH = "https://www.wowhead.com/forever/guide/classes/"
local IVD = "Nov 4, 2026"

local function order(line, stats, label)
    return { line = line, stats = stats, label = label }
end

local function iv(slug, lists)
    return { name = "Icy Veins", url = IV .. slug, updated = IVD, lists = lists }
end

local function wh(path, updated, lists, caveat)
    return { name = "Wowhead", url = WH .. path, updated = updated, lists = lists, caveat = caveat }
end

local function row(sources, label)
    return { status = "CONFLICT", sources = sources, label = label }
end

local CAVEAT_ARMS =
    "Given that the beta was level-locked at Level 30, it's unclear not only what stats are important for Arms Warrior, but also the availability of stats at Level 60. The priority below is purely speculative for endgame and is based on what we know from beta testing, but has not been tested in-game at Level 60."
local CAVEAT_FURY =
    "Given that the beta was level-locked at Level 30, it's unclear not only what stats are important for Fury Warrior, but also the availability of stats at Level 60. The priority below is purely speculative for endgame and is based on what we know from beta testing, but has not been tested in-game at Level 60."
local CAVEAT_ARCANE =
    "Given that the beta was level-locked at Level 30, it's unclear not only what stats are important for Arcane Mage, but also the availability of stats at Level 60. The priority below is purely speculative for endgame and is based on what we know from beta testing, but has not been tested in-game at Level 60."
local CAVEAT_COMBAT =
    "Given that the beta was level-locked at Level 30, it's unclear not only what stats are important for Combat Rogue, but also the availability of stats at Level 60. The priority below is purely speculative for endgame and is based on what we know from beta testing, but has not been tested in-game at Level 60."

local ROGUE_WH_LINE =
    "Hit Chance until 8% (Ability cap) > Expertise to 6.5% > Weapon skill to 308 > Hit to 17% (Poison cap) > Agility > Critical Strike Chance > Haste Rating > Strength > Attack Power > Stamina"
local ROGUE_WH_STATS = {
    "Hit", "Expertise", "WeaponSkill", "Hit", "Agility", "Crit", "Haste", "Strength", "AttackPower", "Stamina",
}
local HUNTER_WH_LINE =
    "% Hit Chance until 9% > % Critical Strike Chance > Agility > Intellect > (Ranged) Attack Power > Spirit > Stamina"
local HUNTER_WH_STATS = { "Hit", "Crit", "Agility", "Intellect", "AttackPower", "Spirit", "Stamina" }
local HUNTER_IV_LINE =
    "Weapon Damage > Hit Chance (8%) > Critical Strike Chance > Agility > Attack Power"
local HUNTER_IV_STATS = { "WeaponDamage", "Hit", "Crit", "Agility", "AttackPower" }
local MAGE_IV_LINE =
    "Hit Chance (to 17%) > Spell Power > Critical Strike > Intellect > Spirit > Mp5"
local MAGE_IV_STATS = { "Hit", "SpellPower", "Crit", "Intellect", "Spirit", "MP5" }

TA.Data.ForeverStatPriorityUnknown = {}

TA.Data.ForeverStatPriority = {
    WARRIOR = {
        Arms = row({
            iv("arms-warrior-melee-dps-pve-stat-priority", {
                order("Weapon DPS > Hit Chance > Expertise > Critical Strike > Strength",
                    { "WeaponDPS", "Hit", "Expertise", "Crit", "Strength" }),
            }),
            wh("warrior/arms/stat-priority-pve-dps", "2026/11/04", {
                order("Hit Chance until 8% > Expertise until 6.5% > Critical Strike Chance > Strength > Agility > Haste > Hit Chance after 8%",
                    { "Hit", "Expertise", "Crit", "Strength", "Agility", "Haste", "Hit" }),
            }, CAVEAT_ARMS),
        }),
        Fury = row({
            iv("fury-warrior-melee-dps-pve-stat-priority", {
                order("Weapon DPS > Hit Chance > Expertise > Critical Strike > Strength",
                    { "WeaponDPS", "Hit", "Expertise", "Crit", "Strength" }),
            }),
            wh("warrior/fury/stat-priority-pve-dps", "2026/10/29", {
                order("Weapon Skill until 305 > Hit Chance until 9% > Critical Strike Chance > Strength > Agility > Stamina",
                    { "WeaponSkill", "Hit", "Crit", "Strength", "Agility", "Stamina" }),
            }, CAVEAT_FURY),
        }),
        Protection = row({
            iv("protection-warrior-tank-pve-stat-priority", {
                order("Expertise > Hit Chance > Agility > Strength > Stamina",
                    { "Expertise", "Hit", "Agility", "Strength", "Stamina" }, "Offensive"),
                order("Stamina > Armor > Agility > Avoidance > Defense",
                    { "Stamina", "Armor", "Agility", { "Dodge", "Parry" }, "Defense" }, "Defensive"),
            }),
            wh("warrior/protection/stat-priority-pve-tank", "2026/11/03", {
                order("Stamina > Defense until 440 > Armor > Agility > Defense after 440 > Parry > Dodge > Expertise (6.5%) - Soft Cap > Block Chance > Attack Power/Strength > Hit (8%) - Melee Cap > Crit > Expertise (14%) - Hard Cap > Haste",
                    { "Stamina", "Defense", "Armor", "Agility", "Defense", "Parry", "Dodge", "Expertise", "Block", { "AttackPower", "Strength" }, "Hit", "Crit", "Expertise", "Haste" },
                    "Defensive"),
                order("Stamina > Expertise (6.5%) - Soft Cap > Hit (8%) - Melee Cap > Defense until 440 > Expertise (14%) - Hard Cap > Armor > Attack Power/Strength > Agility > Defense after 440 > Parry > Dodge > Crit > Block Chance > Haste",
                    { "Stamina", "Expertise", "Hit", "Defense", "Expertise", "Armor", { "AttackPower", "Strength" }, "Agility", "Defense", "Parry", "Dodge", "Crit", "Block", "Haste" },
                    "Balanced"),
                order("Expertise (6.5%) - Soft Cap > Hit (8%) - Melee Cap > Expertise (14%) - Hard Cap > Crit > Attack Power/Strength > Stamina (Still need to survive) > Haste > Agility > Defense before 440 > Armor > Defense after 440 > Parry > Dodge > Block Chance",
                    { "Expertise", "Hit", "Expertise", "Crit", { "AttackPower", "Strength" }, "Stamina", "Haste", "Agility", "Defense", "Armor", "Defense", "Parry", "Dodge", "Block" },
                    "Offensive"),
            }),
        }),
    },
    PALADIN = {
        Holy = row({
            iv("holy-paladin-healer-pve-stat-priority", {
                order("Healing Power > Intellect > Spirit > Mp5 > Critical Strike",
                    { "HealingPower", "Intellect", "Spirit", "MP5", "Crit" }),
            }),
            wh("paladin/holy/stat-priority-pve-healer", "2026/10/29", {
                order("Healing Power > Intellect > Critical Strike > Spirit",
                    { "HealingPower", "Intellect", "Crit", "Spirit" }),
            }),
        }),
        Protection = row({
            iv("protection-paladin-tank-pve-stat-priority", {
                order("Stamina > Defense (to 440) > Spell Power > Intellect > Strength",
                    { "Stamina", "Defense", "SpellPower", "Intellect", "Strength" }),
            }),
            wh("paladin/protection/stat-priority-pve-tank", "2026/10/28", {
                order("Stamina > Defense until 440 > Armor > Agility > Block Chance > Defense after 440 > Spell Power (Still need some threat) > Parry > Dodge > Strength > Hit (8%) - Melee Cap > Expertise (6.5%) - Soft Cap > Crit > Hit (17%) - Spell Cap > Expertise (14%) - Hard Cap > Haste > Intellect",
                    { "Stamina", "Defense", "Armor", "Agility", "Block", "Defense", "SpellPower", "Parry", "Dodge", "Strength", "Hit", "Expertise", "Crit", "Hit", "Expertise", "Haste", "Intellect" },
                    "Defensive"),
                order("Stamina > Spell Power > Hit (8%) - Melee Cap > Defense until 440 > Armor > Expertise (6.5%) - Soft Cap > Agility > Block Chance > Defense after 440 > Parry > Dodge > Crit > Hit (17%) - Spell Cap > Expertise (14%) - Hard Cap > Haste > Strength > Intellect",
                    { "Stamina", "SpellPower", "Hit", "Defense", "Armor", "Expertise", "Agility", "Block", "Defense", "Parry", "Dodge", "Crit", "Hit", "Expertise", "Haste", "Strength", "Intellect" },
                    "Balanced"),
                order("Spell Power > Hit (8%) - Melee Cap > Expertise (6.5%) - Soft Cap > Crit > Stamina (Still need to survive) > Hit (17%) - Spell Cap > Expertise (14%) - Hard Cap > Haste > Strength > Agility > Defense before 440 > Armor > Block Chance > Defense after 440 > Parry > Dodge > Intellect",
                    { "SpellPower", "Hit", "Expertise", "Crit", "Stamina", "Hit", "Expertise", "Haste", "Strength", "Agility", "Defense", "Armor", "Block", "Defense", "Parry", "Dodge", "Intellect" },
                    "Offensive"),
            }),
        }),
        Retribution = row({
            iv("retribution-paladin-melee-dps-pve-stat-priority", {
                order("Weapon Damage > Hit Chance (8%) > Expertise (6.5%) > Strength > Spell Power",
                    { "WeaponDamage", "Hit", "Expertise", "Strength", "SpellPower" }, "Unsealed Wrath"),
                order("Weapon DPS > Hit Chance (8%) > Spell Power > Critical Strike > Expertise (6.5%)",
                    { "WeaponDPS", "Hit", "SpellPower", "Crit", "Expertise" }, "Holy Shock"),
            }),
            wh("paladin/retribution/stat-priority-pve-dps", "2026/10/31", {
                order("Weapon Skill > Weapon DPS & Speed > Hit Chance (9%) > Expertise (6.5%) > Spell Damage > Intellect > Strength & Attack Power > Agility & Critical Strike Chance > Stamina",
                    { "WeaponSkill", "WeaponDPS", "Hit", "Expertise", "SpellPower", "Intellect", { "Strength", "AttackPower" }, { "Agility", "Crit" }, "Stamina" }),
            }),
        }),
    },
    HUNTER = {
        ["Beast Mastery"] = row({
            iv("beast-mastery-hunter-ranged-dps-pve-stat-priority", {
                order(HUNTER_IV_LINE, HUNTER_IV_STATS),
            }),
            wh("hunter/beast-mastery/stat-priority-pve-dps", "2026/11/04", {
                order(HUNTER_WH_LINE, HUNTER_WH_STATS),
            }),
        }),
        Marksmanship = row({
            iv("marksmanship-hunter-ranged-dps-pve-stat-priority", {
                order(HUNTER_IV_LINE, HUNTER_IV_STATS),
            }),
            wh("hunter/marksmanship/stat-priority-pve-dps", "2026/11/04", {
                order(HUNTER_WH_LINE, HUNTER_WH_STATS),
            }),
        }),
        Survival = row({
            iv("survival-hunter-melee-dps-pve-stat-priority", {
                order("Weapon Damage > Hit Chance (8%) > Critical Strike Chance > Agility > Attack Power",
                    HUNTER_IV_STATS),
            }),
            wh("hunter/survival/stat-priority-pve-dps", "2026/11/04", {
                order("% Hit Chance > % Critical Strike Chance > Agility > Strength > Attack Power > Intellect > Spirit > Stamina",
                    { "Hit", "Crit", "Agility", "Strength", "AttackPower", "Intellect", "Spirit", "Stamina" }),
            }),
        }),
    },
    ROGUE = {
        Assassination = row({
            iv("assassination-rogue-melee-dps-pve-stat-priority", {
                order("Expertise (to 6.5%) > Hit Chance (to 8%) > Agility > Weapon Damage > Critical Strike",
                    { "Expertise", "Hit", "Agility", "WeaponDamage", "Crit" }),
            }),
            wh("rogue/assassination/stat-priority-pve-dps", "2026/11/09", {
                order(ROGUE_WH_LINE, ROGUE_WH_STATS),
            }),
        }),
        Combat = row({
            iv("combat-rogue-melee-dps-pve-stat-priority", {
                order("Expertise (to 6.5%) > Hit Chance (to 8%) > Agility > Weapon Damage > Critical Strike",
                    { "Expertise", "Hit", "Agility", "WeaponDamage", "Crit" }),
            }),
            wh("rogue/combat/stat-priority-pve-dps", "2026/10/30", {
                order(ROGUE_WH_LINE, ROGUE_WH_STATS),
            }, CAVEAT_COMBAT),
        }),
        Subtlety = row({
            iv("subtlety-rogue-melee-dps-pve-stat-priority", {
                order("Weapon Damage > Expertise (to 6.5%) > Hit Chance (to 8%) > Weapon Skill > Agility",
                    { "WeaponDamage", "Expertise", "Hit", "WeaponSkill", "Agility" }),
            }),
            wh("rogue/subtlety/stat-priority-pve-dps", "2026/10/30", {
                order(ROGUE_WH_LINE, ROGUE_WH_STATS),
            }),
        }),
    },
    PRIEST = {
        Discipline = row({
            iv("discipline-priest-healer-pve-stat-priority", {
                order("Healing Power > Mp5 > Spirit > Intellect > Critical Strike",
                    { "HealingPower", "MP5", "Spirit", "Intellect", "Crit" }),
            }),
            wh("priest/discipline/stat-priority-pve-healer", "2026/10/30", {
                order("Healing Power > Intellect > Spirit > Critical Strike Chance > Spell Damage > Stamina",
                    { "HealingPower", "Intellect", "Spirit", "Crit", "SpellPower", "Stamina" }),
            }),
        }),
        Holy = row({
            iv("holy-priest-healer-pve-stat-priority", {
                order("Healing Power > Mp5 > Spirit > Intellect > Critical Strike",
                    { "HealingPower", "MP5", "Spirit", "Intellect", "Crit" }),
            }),
            wh("priest/holy/stat-priority-pve-healer", "2026/10/31", {
                order("Healing Power > Intellect > Mana per 5 seconds > Spirit > Spell Critical Strike Chance > Stamina",
                    { "HealingPower", "Intellect", "MP5", "Spirit", "Crit", "Stamina" }),
            }),
        }),
        Shadow = row({
            iv("shadow-priest-ranged-dps-pve-stat-priority", {
                order("Hit Chance (to 17%) > Spell Power > Critical Strike > Spell Pierce > Spirit",
                    { "Hit", "SpellPower", "Crit", "SpellPierce", "Spirit" }),
            }),
            wh("priest/shadow/stat-priority-pve-dps", "2026/10/30", {
                order("Hit Chance until 17% > Spell Critical Strike Chance > Spell Damage (Shadow Damage) > Intellect > Spirit > Stamina",
                    { "Hit", "Crit", { "SpellPower", "ShadowDamage" }, "Intellect", "Spirit", "Stamina" }),
            }),
        }),
    },
    SHAMAN = {
        Elemental = row({
            iv("elemental-shaman-ranged-dps-pve-stat-priority", {
                order("Spell Power > Hit Chance (to 17%) > Critical Strike > Intellect > Mp5",
                    { "SpellPower", "Hit", "Crit", "Intellect", "MP5" }),
            }),
            wh("shaman/elemental/stat-priority-pve-dps", "2026/11/04", {
                order("Spell Piercing > Haste / Cast Speed > Hit Chance until 17% > Spell Damage > Critical Strike Chance > Nature Damage / Fire Damage > Intellect > Spirit > Strength (Only while leveling) > Stamina",
                    { "SpellPierce", "Haste", "Hit", "SpellPower", "Crit", { "NatureDamage", "FireDamage" }, "Intellect", "Spirit", "Strength", "Stamina" }),
            }),
        }),
        Enhancement = row({
            iv("enhancement-shaman-melee-dps-pve-stat-priority", {
                order("Weapon DPS > Hit Chance > Expertise > Intellect > Strength > Spell Power",
                    { "WeaponDPS", "Hit", "Expertise", "Intellect", "Strength", "SpellPower" }),
            }),
            wh("shaman/enhancement/stat-priority-pve-dps", "2026/11/03", {
                order("Hit Chance to minimum 8% > Expertise to 6.5% > Intellect > Spell Damage > Strength > Spell Piercing > Haste > Critical Strike Chance > Agility > Spirit > Stamina",
                    { "Hit", "Expertise", "Intellect", "SpellPower", "Strength", "SpellPierce", "Haste", "Crit", "Agility", "Spirit", "Stamina" }),
            }),
        }),
        Restoration = row({
            iv("restoration-shaman-healer-pve-stat-priority", {
                order("Healing Power > Critical Strike > Intellect > Spirit > Mp5",
                    { "HealingPower", "Crit", "Intellect", "Spirit", "MP5" }),
            }),
            wh("shaman/restoration/stat-priority-pve-healer", "2026/11/01", {
                order("Spell Healing > Critical Strike Chance > Haste / Cast Speed > Intellect > Spirit > Mp5 > Spell Damage (Only while leveling)",
                    { "HealingPower", "Crit", "Haste", "Intellect", "Spirit", "MP5", "SpellPower" }),
            }),
        }),
    },
    MAGE = {
        Arcane = row({
            iv("arcane-mage-ranged-dps-pve-stat-priority", {
                order(MAGE_IV_LINE, MAGE_IV_STATS),
            }),
            wh("mage/arcane/stat-priority-pve-dps", "2026/10/28", {
                order("Hit Chance until 17% > Spell Damage (+ Arcane Damage) > Critical Strike Chance > Spell Piercing > Haste > Intellect > Spirit > Stamina",
                    { "Hit", { "SpellPower", "ArcaneDamage" }, "Crit", "SpellPierce", "Haste", "Intellect", "Spirit", "Stamina" }),
            }, CAVEAT_ARCANE),
        }),
        Fire = row({
            iv("fire-mage-ranged-dps-pve-stat-priority", {
                order(MAGE_IV_LINE, MAGE_IV_STATS),
            }),
            wh("mage/fire/stat-priority-pve-dps", "2026/11/03", {
                order("Hit Chance until 17% > Spell Damage (+ Fire Damage) > Critical Strike Chance > Spell Piercing > Haste > Intellect > Spirit > Stamina",
                    { "Hit", { "SpellPower", "FireDamage" }, "Crit", "SpellPierce", "Haste", "Intellect", "Spirit", "Stamina" }),
            }),
        }),
        Frost = row({
            iv("frost-mage-ranged-dps-pve-stat-priority", {
                order("Hit Chance (to 17%) > Spell Power > Critical Strike > Intellect > Mp5 > Spirit",
                    { "Hit", "SpellPower", "Crit", "Intellect", "MP5", "Spirit" }),
            }),
            wh("mage/frost/stat-priority-pve-dps", "2026/10/29", {
                order("Hit Chance until 11-12% (you'll get 5-6 from talents) > Critical Strike Chance > Spell Damage (+Frost and Arcane Damage) > Intellect > Spirit > Stamina",
                    { "Hit", "Crit", { "SpellPower", "FrostDamage", "ArcaneDamage" }, "Intellect", "Spirit", "Stamina" }),
            }),
        }),
    },
    WARLOCK = {
        Affliction = row({
            iv("affliction-warlock-ranged-dps-pve-stat-priority", {
                order("Hit Chance > Spell Power > Critical Strike > Haste > Intellect",
                    { "Hit", "SpellPower", "Crit", "Haste", "Intellect" }),
            }),
            wh("warlock/affliction/stat-priority-pve-dps", "2026/11/11", {
                order("Spell Power / + Shadow Damage > Crit Chance > Hit Chance (up to 12% from gear with 5/5 Suppression) > Haste > Spell Pierce > Intellect > Spirit",
                    { { "SpellPower", "ShadowDamage" }, "Crit", "Hit", "Haste", "SpellPierce", "Intellect", "Spirit" }),
            }),
        }),
        Demonology = row({
            iv("demonology-warlock-ranged-dps-pve-stat-priority", {
                order("Hit Chance > Spell Power > Critical Strike > Haste > Intellect",
                    { "Hit", "SpellPower", "Crit", "Haste", "Intellect" }),
            }),
            wh("warlock/demonology/stat-priority-pve-dps", "2026/11/03", {
                order("Spell Power / + Fire Damage or + Shadow Damage (matching your build) > Hit Chance (17% from gear, minus 1% per point in Suppression) > Crit Chance > Haste > Spell Pierce > Intellect > Spirit",
                    { { "SpellPower", "FireDamage", "ShadowDamage" }, "Hit", "Crit", "Haste", "SpellPierce", "Intellect", "Spirit" }),
            }),
        }),
        Destruction = row({
            iv("destruction-warlock-ranged-dps-pve-stat-priority", {
                order("Hit Chance > Spell Power > Haste > Critical Strike > Intellect",
                    { "Hit", "SpellPower", "Haste", "Crit", "Intellect" }),
            }),
            wh("warlock/destruction/stat-priority-pve-dps", "2026/11/03", {
                order("Spell Power / + Fire Damage > Crit Chance > Hit Chance (up to 12% from gear with 5/5 Suppression) > Haste > Spell Pierce > Intellect > Spirit",
                    { { "SpellPower", "FireDamage" }, "Crit", "Hit", "Haste", "SpellPierce", "Intellect", "Spirit" }),
            }),
        }),
    },
    DRUID = {
        Balance = row({
            iv("balance-druid-ranged-dps-pve-stat-priority", {
                order("Hit Chance (to 17%) > Critical Strike > Spell Power > Intellect",
                    { "Hit", "Crit", "SpellPower", "Intellect" }),
            }),
            wh("druid/balance/stat-priority-pve-dps", "2026/10/30", {
                order("Hit Chance until 17% > Spell Damage > Spell Penetration > Critical Strike Chance > Haste > Intellect > Spirit > Stamina",
                    { "Hit", "SpellPower", "SpellPierce", "Crit", "Haste", "Intellect", "Spirit", "Stamina" }),
            }),
        }),
        Feral = {
            status = "CONFLICT",
            rows = {
                row({
                    iv("feral-druid-melee-dps-and-tank-pve-stat-priority", {
                        order("Weapon DPS > Expertise (6.5% or 14%) > Hit Chance (8%) > Agility > Strength",
                            { "WeaponDPS", "Expertise", "Hit", "Agility", "Strength" }, "DPS and threat"),
                    }),
                    wh("druid/feral/stat-priority-pve-dps", "2026/10/29", {
                        order("1% Critical Strike Chance > 1% Hit Chance (8% cap) > 1% Reduced Dodge/Parry Chance (6.5% cap) > 1% Haste > Weapon DPS > Agility = Strength > Attack Power > Intellect > Spirit > Stamina",
                            { "Crit", "Hit", "Expertise", "Haste", "WeaponDPS", { "Agility", "Strength" }, "AttackPower", "Intellect", "Spirit", "Stamina" }),
                    }),
                }, "Cat"),
                row({
                    iv("feral-druid-melee-dps-and-tank-pve-stat-priority", {
                        order("Armor > Defense (to 440) > Stamina > Agility > Dodge",
                            { "Armor", "Defense", "Stamina", "Agility", "Dodge" }, "Mitigation"),
                    }),
                    wh("druid/feral/stat-priority-pve-tank", "2026/11/03", {
                        order("Stamina > Defense until 440 > Armor > Agility > Avoidance > Defense after 440",
                            { "Stamina", "Defense", "Armor", "Agility", { "Dodge", "Parry" }, "Defense" }, "Defensive"),
                        order("Hit > Reduced Chance to Be Dodged/Parried > Haste > Crit > Weapon DPS > Strength > Agility > Strength",
                            { "Hit", "Expertise", "Haste", "Crit", "WeaponDPS", "Strength", "Agility", "Strength" }, "Offensive"),
                    }),
                }, "Bear"),
            },
        },
        Restoration = row({
            iv("restoration-druid-healer-pve-stat-priority", {
                order("Healing Power > Intellect > Spirit > Mp5 > Critical Strike",
                    { "HealingPower", "Intellect", "Spirit", "MP5", "Crit" }),
            }),
            wh("druid/restoration/stat-priority-pve-healer", "2026/11/01", {
                order("Spell Healing > Critical Strike Chance > Spell Haste > Spirit > Intellect > MP5 > Stamina",
                    { "HealingPower", "Crit", "Haste", "Spirit", "Intellect", "MP5", "Stamina" }),
            }),
        }),
    },
}
