-------------------------------------------------------------------------------
-- ToonAge Dungeon Data
-- Static dungeon information for role-specific strategies and boss encounters.
--
-- SCHEMA:
--   Each entry is keyed by instanceID (the ID from the instance lock / LFG system).
--
--   [instanceID] = {
--       name       = "Dungeon Name",          -- localized display name
--       expansion  = "warwithin",             -- expansion short key
--       patch      = "11.0",                  -- patch the dungeon was added/current
--       minLevel   = 80,                      -- minimum level to queue
--       bosses     = {                        -- ordered list of bosses
--           [1] = {
--               name        = "Boss Name",
--               encounterID = 12345,          -- from ENCOUNTER_START combat log event
--               strategies  = {
--                   TANK    = "Brief tank advice.",
--                   HEALER  = "Brief healer advice.",
--                   DAMAGER = "Brief DPS advice.",
--               },
--               loot = {},                    -- future: notable drops
--           },
--       },
--   }
--
-- HOW TO ADD A NEW DUNGEON:
--   1. Find the instanceID (Dungeon Journal API: EJ_GetInstanceInfo or /dump).
--   2. Find each boss encounterID from ENCOUNTER_START in combat logs.
--   3. Copy the template above and fill in practical, concise strategies per role.
--   4. Keep strategies to 1-2 sentences — actionable tips, not full guides.
-------------------------------------------------------------------------------

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.Dungeons = {}

local D = TA.Data.Dungeons

-------------------------------------------------------------------------------
-- Priory of the Sacred Flame (War Within Season 1)
-------------------------------------------------------------------------------
D[2649] = {
    name = "Priory of the Sacred Flame",
    expansion = "warwithin",
    patch = "11.0",
    minLevel = 80,
    bosses = {
        [1] = {
            name = "Captain Dailcry",
            encounterID = 2847,
            strategies = {
                TANK = "Face boss away from group. Pick up Arathi Knight adds quickly and interrupt their heals.",
                HEALER = "Heavy group damage during Battle Cry — save a cooldown. Dispel Savage Mauling bleeds when possible.",
                DAMAGER = "Prioritize Arathi Knight adds. Interrupt Holy Smite casts and dodge frontal cleaves.",
            },
            loot = {},
        },
        [2] = {
            name = "Baron Braunpyke",
            encounterID = 2848,
            strategies = {
                TANK = "Kite boss out of Burning Light pools. Use active mitigation for Hammer of Purity hits.",
                HEALER = "Heal through Castigator's Shield absorb quickly to free the target. Spread for Burning Light.",
                DAMAGER = "Break Castigator's Shield absorb on allies immediately. Move out of Burning Light zones.",
            },
            loot = {},
        },
        [3] = {
            name = "Prioress Murrpray",
            encounterID = 2849,
            strategies = {
                TANK = "Interrupt Inner Fire when possible. Position boss so group can dodge Holy Smite frontal.",
                HEALER = "Heavy ticking damage during Barrier of Light phase — use throughput cooldowns. Dispel Sinful Brand.",
                DAMAGER = "Burn the Barrier of Light shield fast to end the phase. Dodge Sacred Pyre swirlies on the ground.",
            },
            loot = {},
        },
    },
}

-------------------------------------------------------------------------------
-- The Stonevault (War Within Season 1)
-------------------------------------------------------------------------------
D[2652] = {
    name = "The Stonevault",
    expansion = "warwithin",
    patch = "11.0",
    minLevel = 80,
    bosses = {
        [1] = {
            name = "E.D.N.A.",
            encounterID = 2854,
            strategies = {
                TANK = "Face boss away from group. Move out of Seismic Smash zones and pick up Volatile Sparks.",
                HEALER = "Group damage ramps during Refracting Beam — heal through or use a cooldown. Keep spread for Chain Lightning.",
                DAMAGER = "Kill Volatile Sparks before they reach the boss. Dodge Refracting Beam and spread for Chain Lightning.",
            },
            loot = {},
        },
        [2] = {
            name = "Skarmorak",
            encounterID = 2880,
            strategies = {
                TANK = "Pick up Crystalline Shards immediately. Use cooldowns during Void Discharge — heavy tank damage.",
                HEALER = "Spot-heal whoever is targeted by Crystalline Eruption. Save cooldowns for Void Discharge overlap.",
                DAMAGER = "Cleave Crystalline Shards down — they buff the boss if alive too long. Soak Void pools to remove them.",
            },
            loot = {},
        },
        [3] = {
            name = "Master Machinists",
            encounterID = 2888,
            strategies = {
                TANK = "Swap between Brokk and Dorlita based on stacks. Move boss out of hazardous ground effects.",
                HEALER = "Spread for Molten Metal splashes. Both bosses alive means more sustained damage — manage mana carefully.",
                DAMAGER = "Even cleave both bosses — they enrage if one dies too far ahead. Interrupt Repair Drone casts.",
            },
            loot = {},
        },
        [4] = {
            name = "Void Speaker Eirich",
            encounterID = 2883,
            strategies = {
                TANK = "Face boss away and sidestep Entropic Reckoning frontal. Grab Void Bound Despoiler adds quickly.",
                HEALER = "Heavy damage during Unbridled Void phase — rotate healing cooldowns. Dispel Void Corruption stacks.",
                DAMAGER = "Burn Void Bound Despoiler adds immediately. Dodge Entropy pools and maximize uptime between mechanics.",
            },
            loot = {},
        },
    },
}

-------------------------------------------------------------------------------
-- Cinderbrew Meadery (War Within Season 1)
-------------------------------------------------------------------------------
D[2661] = {
    name = "Cinderbrew Meadery",
    expansion = "warwithin",
    patch = "11.0",
    minLevel = 80,
    bosses = {
        [1] = {
            name = "Brew Master Aldryr",
            encounterID = 2900,
            strategies = {
                TANK = "Face boss away from group. Move out of Brew Splash pools and use mitigation for Keg Smash.",
                HEALER = "Dispel Drunken Haze debuff quickly — it disorients. Steady healing during Happy Hour phase.",
                DAMAGER = "Dodge Brew Splash swirlies. Use the Throw Brew extra action button at correct stacks to avoid explosion.",
            },
            loot = {},
        },
        [2] = {
            name = "I'pa",
            encounterID = 2901,
            strategies = {
                TANK = "Keep boss positioned away from Fermenting Brew puddles. Active mitigation for Spouting Stout combo.",
                HEALER = "Group takes pulsing damage during Carbonation — spread and heal through. Watch for Rejuvenating Brew on boss.",
                DAMAGER = "Interrupt Rejuvenating Brew to prevent boss healing. Kill Brew Drop adds quickly before they reach puddles.",
            },
            loot = {},
        },
        [3] = {
            name = "Benk Buzzbee",
            encounterID = 2902,
            strategies = {
                TANK = "Grab Honey Bee adds and cleave them down. Position boss near barrels for Bee Swarm soak mechanic.",
                HEALER = "Heavy single-target damage on Sting targets — heal them up fast. Use cooldown if multiple Bee Swarms overlap.",
                DAMAGER = "AoE Honey Bee swarms immediately. Stand behind barrels to break line of sight on Flaming Barrage.",
            },
            loot = {},
        },
        [4] = {
            name = "Goldie Baronbottom",
            encounterID = 2903,
            strategies = {
                TANK = "Move boss out of Cinderbrew Toss fire zones. Use mitigation for Burning Fervor empowered melees.",
                HEALER = "Raid-wide damage during Cinderfall — save a healing cooldown. Spot-heal Spread the Wealth targets.",
                DAMAGER = "Spread for Spread the Wealth to minimize overlap damage. Burst boss during Liquid Courage vulnerability window.",
            },
            loot = {},
        },
    },
}
