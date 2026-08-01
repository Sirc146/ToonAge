-- CharacterAdvisor/Data/Professions.lua
-- Seamlessly aligned data definitions matching the in-game specialization window layouts node-for-node

local CA = CharacterAdvisor
CA.Data = CA.Data or {}
CA.Data.Professions = CA.Data.Professions or {}
local P = CA.Data.Professions

local DATA_MATRIX = {
    -- ── ALCHEMY (SkillLine 171) ──────────────────────────────────────
    [171] = {
        benefit = "Craft life-saving Potions, Phials, and Alchemical Catalyst utility items.",
        gearSlots = {
            tool = { recommended = "Stirring Rod of Dawn", bonuses = "+10 Crafting Skill, +6 Resourcefulness", source = "Invention Work Order" },
            accessory1 = { recommended = "Alchemist's Protective Smock", bonuses = "+8 Ingenuity", source = "Tailoring / AH" },
            accessory2 = { recommended = "Midnight Mixing Flasks", bonuses = "+12 Multicraft", source = "Jewelcrafting" }
        },
        talentTree = {
            permanenceWarning = "Profession specialization choices are PERMANENT. Potion Prowess maximizes instant burst throughput.",
            rows = {
                { -- Tab 1: Potion Prowess Base
                    { name = "Potion Prowess", desc = "Leverage the diametric powers of Light and Void to brew even more effective potions.", recommended = true }
                },
                { -- Secondary Branch Sub-Nodes
                    { name = "Vial Velocity", desc = "Increases your crafting speed by +15% per milestone tier for all potion classifications.", recommended = true },
                    { name = "Batch Production", desc = "Unlocks a permanent +5% Multicraft bonus, yielding extra pots on successful designs.", recommended = false }
                },
                { -- Final Sub-Tier Capstones
                    { name = "Light-Bound Concoctions", desc = "Healing and defensive restoration potions have an increased base value.", recommended = true },
                    { name = "Void-Tinged Elixirs", desc = "Combat throughput potions grant an extended dynamic stat bonus window.", recommended = true }
                }
            }
        }
    },

    -- ── HERBALISM (SkillLine 182) ────────────────────────────────────
    [182] = {
        benefit = "Gather Duskbloom and Voidpetal — core materials for healing flasks that increase HPS by ~8%.",
        gearSlots = {
            tool = { recommended = "Midnight Herbalist's Sickle", bonuses = "+15 Herbalism Skill, +10 Deftness", source = "Crafted (Blacksmithing 50) or AH" },
            accessory1 = { recommended = "Herbalist's Gathering Basket", bonuses = "+8 Finesse", source = "Crafted (Leatherworking 25) or AH" },
            accessory2 = { recommended = "Verdant Gathering Charm", bonuses = "+8 Finesse", source = "Crafted (Jewelcrafting 25) or AH" }
        },
        talentTree = {
            permanenceWarning = "Profession talent choices are PERMANENT — unlike combat talents, KP cannot be refunded. Botany (mounted gathering at 40 KP) is the highest-value milestone. Prioritize it before branching.",
            rows = {
                { -- Wheel Root Base
                    { name = "Botany (General Mastery)", desc = "+Skill all herbs · 40 KP = Mounted Gathering", recommended = true },
                    { name = "Bountiful Harvest", desc = "Finesse: +herbs per node", recommended = true },
                    { name = "Deftness Track", desc = "Deftness: faster animation", recommended = false }
                },
                { -- Mid-tier branches
                    { name = "Verdant Bounty", desc = "+1 herb on Finesse proc", recommended = true },
                    { name = "Swift Gathering", desc = "Deftness +15 — near-instant picks", recommended = false },
                    { name = "Perception Nodes", desc = "Perception: rare herb discovery", recommended = false }
                },
                { -- Row 3 Nodes
                    { name = "Plentiful Yield", desc = "+2 herbs on proc (Finesse)", recommended = true },
                    { name = "Fleet of Foot", desc = "+8% move speed between nodes", recommended = false },
                    { name = "Rare Seeker", desc = "Perception doubles rare chance", recommended = true }
                },
                { -- Capstone Endpoints
                    { name = "Master Botanist", desc = "Capstone: all yields +25%", recommended = true },
                    { name = "Nightbloom Whisperer", desc = "Prismatic proc (Perception)", recommended = true }
                }
            }
        }
    },

    -- ── MINING (SkillLine 186) ───────────────────────────────────────
    [186] = {
        benefit = "Extract Corestone and Ironfound ore nodes to fuel high-tier Blacksmithing layouts.",
        gearSlots = {
            tool = { recommended = "Pneumatic Corestone Pick", bonuses = "+12 Mining Skill, +8 Deftness", source = "Engineering" },
            accessory1 = { recommended = "Reinforced Mining Gloves", bonuses = "+6 Finesse", source = "Leatherworking" },
            accessory2 = { recommended = "Prospector's Protective Lens", bonuses = "+10 Perception", source = "Engineering" }
        },
        talentTree = {
            permanenceWarning = "Mining KP choices lock permanently upon saving. Prioritize Mining Mastery to maximize overall circuit layout speed.",
            rows = {
                { -- Core Specialization Head Node
                    { name = "Mining Mastery", desc = "Improves general extraction skills across all base and modified nodes.", recommended = true }
                },
                { -- Secondary Node Paths
                    { name = "Industrial Efficiency", desc = "Increases your mining animation speed (Deftness) significantly per milestone tier.", recommended = false },
                    { name = "Surveyor's Sight", desc = "Boosts your global Perception rating to help track down pristine gems inside ore layers.", recommended = true }
                },
                { -- Capstone Masteries
                    { name = "Mineral Abundance", desc = "Final Node Perk: Standard mining swings have an added +15% chance to extract rare sub-materials.", recommended = true }
                }
            }
        }
    }
}

function P:GetBySkillLine(skillLineID)
    return DATA_MATRIX[skillLineID]
end

P.SECONDARY = {
    [185] = { firstPath = "Focus on primary attribute feasts (Agility/Intellect) to optimize team raid requirements." },
    [356] = { firstPath = "Fish in active open world pools to bypass resource expenditures." },
    [794] = { firstPath = "Track historical fragments to discover rare legacy collectibles." }
}