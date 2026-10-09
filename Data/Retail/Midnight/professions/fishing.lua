-- ToonAge: Midnight (12.1.0.69933) Fishing skill-up guide (1-100), generated 2026-10-09 PT by Grok Bot.
-- SOURCES: Blizzard DB2 via wago.tools 12.1.0.69933: SkillLineAbility (SkillupSkillLineID 2911; MinSkillLineRank, TrivialSkillLineRankLow =
--   end of orange, TrivialSkillLineRankHigh = gray, NumSkillUps, AcquireMethod), SpellName, SpellReagents, ModifiedCraftingSpellSlot ->
--   ModifiedCraftingReagentSlot (ReagentType 1 = required) -> MCRSlotXMCRCategory -> CraftingReagentQuality (itemIDs by quality rank,
--   lowest rank first), SpellEffect 288 -> CraftingData/CraftingDataItemQuality (crafted items), TradeSkillCategory, ItemSparse (names).
-- Recipe sources, trainer/vendor NPCs and coords: AllTheThings (github ATTWoWAddon/AllTheThings master, .contrib/.db) - coords are ATT map %.
-- Route: greedy over trainer/auto-learned recipes, cheapest basic reagents per skill-up while orange; yellow segments use an estimated
--   x1.6 crafts and are marked UNVERIFIED. Midnight also grants skill from first crafts / knowledge; real counts may be lower.
-- Material counts use quality-rank-1 itemIDs; qualityItemIDs lists all ranks. Optional/finishing slots are omitted from materials.

local TA = ToonAge or {}
ToonAge = TA
TA.ProfessionGuides = TA.ProfessionGuides or {}
TA.ProfessionGuides.midnight = TA.ProfessionGuides.midnight or {}
TA.ProfessionGuides.midnight["Fishing"] = {
    profession = "Fishing",
    skillLine = 2911,
    expansion = "Midnight",
    cap = 100,
    trainer = {
        npcID = 253468,
        name = "Drathen",
        role = "Fishing Trainer",
        coord = { mapID = 2393, x = 44.8, y = 60.4 },
    },
    suppliers = nil,
    route = nil,
    routeNote = "Gathering: skill comes from gathering nodes; each node type below grants skill while below its grayAt. See midnight/gathering.lua for node coordinates and loops.",
    recipes = {
        {
            spellID = 1226157,
            name = "Lucky Loa Lure",
            category = "Crafting",
            minSkill = 1,
            orangeUntil = 1,
            grayAt = 1,
            skillUps = 1,
            createsItemIDs = { 241145 },
            reagents = {
                { itemID = 238365, qualityItemIDs = nil, name = "Sin'dorei Swarmer", count = 5 },
            },
            optionalSlots = nil,
            firstCraftKnowledge = nil,
            source = { kind = "unknown", note = "source not found in ATT UNVERIFIED" },
        },
    },
}
