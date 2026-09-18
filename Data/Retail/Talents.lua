-- ToonAge/Data/Talents.lua
-- Build data for all 40 specs (Midnight 12.1, Season 2)
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
local T = TA.Data.Talents
local DB = {}
-- Rebuilt 2026-09-16 from Icy Veins' Patch 12.1 class guides (hero tree recommendation per
-- content type). The previous entries carried invented build names (several naming abilities
-- removed years ago, e.g. Balance Affinity, Careful Aim, Radiant Spark) and 24 of 26 import
-- strings failed to decode to their own spec (wrong spec ID / serialization version), so every
-- string is empty until a real loadout is captured with /ta talentscan or 'Save Current'.
-- Hero talents unlock at level 71; below that the Leveling view follows the in-game tree.

-- ── WARRIOR ───────────────────────────────────────────────────────────────
DB[71] = { -- Arms
    builds = {
        mplus = { name = "Slayer", desc = "Icy Veins 12.1 best choice for AoE as well.", string = "", nodes = {} },
        raid  = { name = "Slayer", desc = "Icy Veins 12.1 best choice for single-target.", string = "", nodes = {} },
        solo  = { name = "Slayer", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[72] = { -- Fury
    builds = {
        mplus = { name = "Slayer", desc = "Icy Veins 12.1 pick for M+.", string = "", nodes = {} },
        raid  = { name = "Slayer", desc = "Icy Veins 12.1 pick for raid.", string = "", nodes = {} },
        solo  = { name = "Slayer", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[73] = { -- Protection
    builds = {
        mplus = { name = "Colossus", desc = "Icy Veins 12.1: Colossus for AoE-heavy keys; Mountain Thane stays best on single-target.", string = "", nodes = {} },
        raid  = { name = "Mountain Thane", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Colossus", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Mountain Thane for single-target bosses.", string = "", nodes = {} },
    },
}
-- ── PALADIN ───────────────────────────────────────────────────────────────
DB[65] = { -- Holy
    builds = {
        mplus = { name = "Herald of the Sun", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Herald of the Sun", desc = "Icy Veins 12.1 best choice for raid.", string = "", nodes = {} },
        solo  = { name = "Herald of the Sun", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[66] = { -- Protection
    builds = {
        mplus = { name = "Templar", desc = "Icy Veins 12.1 best choice for AoE.", string = "", nodes = {} },
        raid  = { name = "Templar", desc = "Icy Veins 12.1 best choice for single-target and large bosses.", string = "", nodes = {} },
        solo  = { name = "Templar", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[70] = { -- Retribution
    builds = {
        mplus = { name = "Herald of the Sun", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Herald of the Sun", desc = "Icy Veins 12.1 best choice for raid.", string = "", nodes = {} },
        solo  = { name = "Herald of the Sun", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── DEATH KNIGHT ──────────────────────────────────────────────────────────
DB[250] = { -- Blood
    builds = {
        mplus = { name = "San'layn", desc = "Icy Veins 12.1 M+ pick.", string = "", nodes = {} },
        raid  = { name = "Deathbringer", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "San'layn", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Deathbringer for single-target bosses.", string = "", nodes = {} },
    },
}
DB[251] = { -- Frost
    builds = {
        mplus = { name = "Deathbringer", desc = "Icy Veins 12.1: Deathbringer or Rider of the Apocalypse both viable in M+.", string = "", nodes = {} },
        raid  = { name = "Deathbringer", desc = "Icy Veins 12.1 raid pick (with Breath of Sindragosa).", string = "", nodes = {} },
        solo  = { name = "Deathbringer", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[252] = { -- Unholy
    builds = {
        mplus = { name = "Rider of the Apocalypse", desc = "Same tree in M+; swap Death Coil for Epidemic at 4+ targets.", string = "", nodes = {} },
        raid  = { name = "Rider of the Apocalypse", desc = "Icy Veins 12.1 rotation is written for Rider of the Apocalypse.", string = "", nodes = {} },
        solo  = { name = "Rider of the Apocalypse", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── DEMON HUNTER ──────────────────────────────────────────────────────────
DB[577] = { -- Havoc
    builds = {
        mplus = { name = "Fel-Scarred", desc = "Icy Veins 12.1: Fel-Scarred default; Aldrachi Reaver gains value as a funnel in high keys.", string = "", nodes = {} },
        raid  = { name = "Fel-Scarred", desc = "Icy Veins 12.1: best flexibility and burst for raid.", string = "", nodes = {} },
        solo  = { name = "Fel-Scarred", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[581] = { -- Vengeance
    builds = {
        mplus = { name = "Annihilator", desc = "Icy Veins 12.1 best choice for AoE.", string = "", nodes = {} },
        raid  = { name = "Annihilator", desc = "Icy Veins 12.1 best choice for single-target.", string = "", nodes = {} },
        solo  = { name = "Annihilator", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[1480] = { -- Devourer
    builds = {
        mplus = { name = "Void-Scarred", desc = "Icy Veins 12.1: faster ramp and easier access to cooldown windows.", string = "", nodes = {} },
        raid  = { name = "Void-Scarred", desc = "Icy Veins 12.1: strongest single-target plus free burst cleave over Annihilator.", string = "", nodes = {} },
        solo  = { name = "Void-Scarred", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── DRUID ─────────────────────────────────────────────────────────────────
DB[102] = { -- Balance
    builds = {
        mplus = { name = "Keeper of the Grove", desc = "Icy Veins 12.1 M+ pick (Force of Nature multi-target damage).", string = "", nodes = {} },
        raid  = { name = "Elune's Chosen", desc = "Icy Veins 12.1 raid pick (single-target).", string = "", nodes = {} },
        solo  = { name = "Keeper of the Grove", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Elune's Chosen for single-target bosses.", string = "", nodes = {} },
    },
}
DB[103] = { -- Feral
    builds = {
        mplus = { name = "Druid of the Claw", desc = "Icy Veins 12.1: Druid of the Claw uses Blood Spattered slightly better, with better defense.", string = "", nodes = {} },
        raid  = { name = "Wildstalker", desc = "Icy Veins 12.1: Wildstalker and Druid of the Claw are very close on single-target.", string = "", nodes = {} },
        solo  = { name = "Druid of the Claw", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Wildstalker for single-target bosses.", string = "", nodes = {} },
    },
}
DB[104] = { -- Guardian
    builds = {
        mplus = { name = "Elune's Chosen", desc = "Icy Veins 12.1 M+ pick.", string = "", nodes = {} },
        raid  = { name = "Druid of the Claw", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Elune's Chosen", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Druid of the Claw for single-target bosses.", string = "", nodes = {} },
    },
}
DB[105] = { -- Restoration
    builds = {
        mplus = { name = "Wildstalker", desc = "Icy Veins 12.1 M+ pick (rotation barely changes between the two).", string = "", nodes = {} },
        raid  = { name = "Keeper of the Grove", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Wildstalker", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Keeper of the Grove for single-target bosses.", string = "", nodes = {} },
    },
}
-- ── HUNTER ────────────────────────────────────────────────────────────────
DB[253] = { -- Beast Mastery
    builds = {
        mplus = { name = "Pack Leader", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Pack Leader", desc = "Icy Veins 12.1 default; Dark Ranger is the single-target alternative.", string = "", nodes = {} },
        solo  = { name = "Pack Leader", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[254] = { -- Marksmanship
    builds = {
        mplus = { name = "Sentinel", desc = "Icy Veins 12.1 pick for AoE.", string = "", nodes = {} },
        raid  = { name = "Sentinel", desc = "Icy Veins 12.1 pick; Dark Ranger is the single-target alternative.", string = "", nodes = {} },
        solo  = { name = "Sentinel", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[255] = { -- Survival
    builds = {
        mplus = { name = "Sentinel", desc = "Icy Veins 12.1 pick for M+; Pack Leader is the alternative.", string = "", nodes = {} },
        raid  = { name = "Sentinel", desc = "Icy Veins 12.1 pick for raid.", string = "", nodes = {} },
        solo  = { name = "Sentinel", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── MAGE ──────────────────────────────────────────────────────────────────
DB[62] = { -- Arcane
    builds = {
        mplus = { name = "Sunfury", desc = "Icy Veins 12.1: also best in AoE.", string = "", nodes = {} },
        raid  = { name = "Sunfury", desc = "Icy Veins 12.1: significantly ahead on single-target and cleave.", string = "", nodes = {} },
        solo  = { name = "Sunfury", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[63] = { -- Fire
    builds = {
        mplus = { name = "Frostfire", desc = "Icy Veins 12.1: Frostfire equally viable.", string = "", nodes = {} },
        raid  = { name = "Sunfury", desc = "Icy Veins 12.1: no talent differences between hero presets; Sunfury listed first.", string = "", nodes = {} },
        solo  = { name = "Frostfire", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Sunfury for single-target bosses.", string = "", nodes = {} },
    },
}
DB[64] = { -- Frost
    builds = {
        mplus = { name = "Frostfire", desc = "Icy Veins 12.1 pick for M+; Spellslinger is the alternative.", string = "", nodes = {} },
        raid  = { name = "Frostfire", desc = "Icy Veins 12.1 pick for raid.", string = "", nodes = {} },
        solo  = { name = "Frostfire", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── MONK ──────────────────────────────────────────────────────────────────
DB[268] = { -- Brewmaster
    builds = {
        mplus = { name = "Shado-Pan", desc = "Icy Veins 12.1 standard M+ pick.", string = "", nodes = {} },
        raid  = { name = "Master of Harmony", desc = "Icy Veins 12.1 raid (defensive) pick.", string = "", nodes = {} },
        solo  = { name = "Shado-Pan", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Master of Harmony for single-target bosses.", string = "", nodes = {} },
    },
}
DB[269] = { -- Windwalker
    builds = {
        mplus = { name = "Shado-Pan", desc = "Icy Veins 12.1 best choice for multi-target.", string = "", nodes = {} },
        raid  = { name = "Shado-Pan", desc = "Icy Veins 12.1 best choice for single-target.", string = "", nodes = {} },
        solo  = { name = "Shado-Pan", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[270] = { -- Mistweaver
    builds = {
        mplus = { name = "Conduit of the Celestials", desc = "Icy Veins 12.1 M+ pick.", string = "", nodes = {} },
        raid  = { name = "Conduit of the Celestials", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Conduit of the Celestials", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── PRIEST ────────────────────────────────────────────────────────────────
DB[256] = { -- Discipline
    builds = {
        mplus = { name = "Oracle", desc = "Icy Veins 12.1 recommended for M+.", string = "", nodes = {} },
        raid  = { name = "Voidweaver", desc = "Icy Veins 12.1 best choice for raid.", string = "", nodes = {} },
        solo  = { name = "Oracle", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Voidweaver for single-target bosses.", string = "", nodes = {} },
    },
}
DB[257] = { -- Holy
    builds = {
        mplus = { name = "Oracle", desc = "Icy Veins 12.1 M+ pick.", string = "", nodes = {} },
        raid  = { name = "Archon", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Oracle", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Archon for single-target bosses.", string = "", nodes = {} },
    },
}
DB[258] = { -- Shadow
    builds = {
        mplus = { name = "Voidweaver", desc = "Icy Veins 12.1: sustained AoE for dungeon pulls.", string = "", nodes = {} },
        raid  = { name = "Archon", desc = "Icy Veins 12.1: Halo-empowered Voidform burst suits raid bosses.", string = "", nodes = {} },
        solo  = { name = "Voidweaver", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Archon for single-target bosses.", string = "", nodes = {} },
    },
}
-- ── ROGUE ─────────────────────────────────────────────────────────────────
DB[259] = { -- Assassination
    builds = {
        mplus = { name = "Fatebound", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Fatebound", desc = "Icy Veins 12.1 best choice for raid.", string = "", nodes = {} },
        solo  = { name = "Fatebound", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[260] = { -- Outlaw
    builds = {
        mplus = { name = "Trickster", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Fatebound", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Trickster", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Fatebound for single-target bosses.", string = "", nodes = {} },
    },
}
DB[261] = { -- Subtlety
    builds = {
        mplus = { name = "Deathstalker", desc = "Icy Veins 12.1: Trickster is also viable.", string = "", nodes = {} },
        raid  = { name = "Deathstalker", desc = "Icy Veins 12.1 best choice.", string = "", nodes = {} },
        solo  = { name = "Deathstalker", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── SHAMAN ────────────────────────────────────────────────────────────────
DB[262] = { -- Elemental
    builds = {
        mplus = { name = "Farseer", desc = "Icy Veins 12.1 M+ pick; Stormbringer not recommended this tier.", string = "", nodes = {} },
        raid  = { name = "Farseer", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Farseer", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[263] = { -- Enhancement
    builds = {
        mplus = { name = "Stormbringer", desc = "Icy Veins 12.1: Totemic is weaker in current tuning.", string = "", nodes = {} },
        raid  = { name = "Stormbringer", desc = "Icy Veins 12.1 pick for all content this season.", string = "", nodes = {} },
        solo  = { name = "Stormbringer", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[264] = { -- Restoration
    builds = {
        mplus = { name = "Totemic", desc = "Icy Veins 12.1 best choice for M+.", string = "", nodes = {} },
        raid  = { name = "Farseer", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Totemic", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Farseer for single-target bosses.", string = "", nodes = {} },
    },
}
-- ── WARLOCK ───────────────────────────────────────────────────────────────
DB[265] = { -- Affliction
    builds = {
        mplus = { name = "Soul Harvester", desc = "Icy Veins 12.1 best choice for AoE.", string = "", nodes = {} },
        raid  = { name = "Soul Harvester", desc = "Icy Veins 12.1 best choice for single-target.", string = "", nodes = {} },
        solo  = { name = "Soul Harvester", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[266] = { -- Demonology
    builds = {
        mplus = { name = "Soul Harvester", desc = "Icy Veins 12.1 AoE pick.", string = "", nodes = {} },
        raid  = { name = "Diabolist", desc = "Icy Veins 12.1 single-target pick.", string = "", nodes = {} },
        solo  = { name = "Soul Harvester", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Diabolist for single-target bosses.", string = "", nodes = {} },
    },
}
DB[267] = { -- Destruction
    builds = {
        mplus = { name = "Diabolist", desc = "Icy Veins 12.1 recommended for M+; Hellcaller is the alternative.", string = "", nodes = {} },
        raid  = { name = "Diabolist", desc = "Icy Veins 12.1 recommended for raid.", string = "", nodes = {} },
        solo  = { name = "Diabolist", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
-- ── EVOKER ────────────────────────────────────────────────────────────────
DB[1467] = { -- Devastation
    builds = {
        mplus = { name = "Scalecommander", desc = "Icy Veins 12.1 M+ pick.", string = "", nodes = {} },
        raid  = { name = "Scalecommander", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Scalecommander", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[1468] = { -- Preservation
    builds = {
        mplus = { name = "Flameshaper", desc = "Icy Veins 12.1 M+ pick; Chronowarden also viable.", string = "", nodes = {} },
        raid  = { name = "Flameshaper", desc = "Icy Veins 12.1 raid pick.", string = "", nodes = {} },
        solo  = { name = "Flameshaper", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over.", string = "", nodes = {} },
    },
}
DB[1473] = { -- Augmentation
    builds = {
        mplus = { name = "Chronowarden", desc = "Icy Veins 12.1 pick for high keys.", string = "", nodes = {} },
        raid  = { name = "Scalecommander", desc = "Icy Veins 12.1 raid pick; Chronowarden is the alternative.", string = "", nodes = {} },
        solo  = { name = "Chronowarden", desc = "Open world and Delves: the M+ tree's AoE and sustain carry over. Use Scalecommander for single-target bosses.", string = "", nodes = {} },
    },
}

-- ── Accessors ─────────────────────────────────────────────────────────────
function T:GetBySpecID(specID)
    local spec = DB[specID]
    -- The PvP build is auto-filled at load (below) before Data/TalentsPvP.lua
    -- exists, so name it from that file's researched hero tree on first read.
    if spec and spec.builds.pvp and not spec.builds.pvp._named then
        local pvp = TA.Data.TalentsPvP and TA.Data.TalentsPvP[specID]
        if pvp and pvp.heroSpec and pvp.heroSpec ~= "" then
            spec.builds.pvp.name = pvp.heroSpec .. " (PvP)"
            spec.builds.pvp._named = true
        end
    end
    return spec
end

-- ── Spec Name → SpecID map (for BetterTalents sync) ──────────────────────
-- BetterTalents keys builds by display name (e.g. "Affliction"), while ToonAge
-- keys by specID (e.g. 265). This table bridges the two.
-- Keys here match BetterTalents/Data/BuildData.lua exactly.
local SPEC_NAME_TO_ID = {
    -- Warrior
    ["Arms"] = 71,
    ["Fury"] = 72,
    ["Protection (Warrior)"] = 73,
    -- Paladin
    ["Holy (Paladin)"] = 65,
    ["Protection (Paladin)"] = 66,
    ["Retribution"] = 70,
    -- Death Knight
    ["Blood"] = 250,
    ["Frost (DK)"] = 251,
    ["Unholy"] = 252,
    -- Demon Hunter
    ["Havoc"] = 577,
    ["Vengeance"] = 581,
    ["Devourer"] = 1480,
    -- Druid
    ["Balance"] = 102,
    ["Feral"] = 103,
    ["Guardian"] = 104,
    ["Restoration (Druid)"] = 105,
    -- Hunter
    ["Beast Mastery"] = 253,
    ["Marksmanship"] = 254,
    ["Survival"] = 255,
    -- Mage
    ["Arcane"] = 62,
    ["Fire"] = 63,
    ["Frost (Mage)"] = 64,
    -- Monk
    ["Brewmaster"] = 268,
    ["Windwalker"] = 269,
    ["Mistweaver"] = 270,
    -- Priest
    ["Discipline"] = 256,
    ["Holy (Priest)"] = 257,
    ["Shadow"] = 258,
    -- Rogue
    ["Assassination"] = 259,
    ["Outlaw"] = 260,
    ["Subtlety"] = 261,
    -- Shaman
    ["Elemental"] = 262,
    ["Enhancement"] = 263,
    ["Restoration (Shaman)"] = 264,
    -- Warlock
    ["Affliction"] = 265,
    ["Demonology"] = 266,
    ["Destruction"] = 267,
    -- Evoker
    ["Devastation"] = 1467,
    ["Devourer"] = nil, -- New spec? Skip until specID confirmed
    ["Preservation"] = 1468,
    ["Augmentation"] = 1473,
}

--- Mirror talent import strings from BetterTalents into ToonAge's per-spec build entries.
--- Called once on login (or on demand via /ta talentsync) after both addons are loaded.
--- Only fills in empty strings — never overwrites user-pasted data.
--- @return number — count of strings filled
function T:SyncFromBetterTalents()
    local BT = _G["BetterTalents"]
    if not BT or not BT.BuildData then
        if TA.debug then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Talents]|r BetterTalents.BuildData not found — skipped sync.")
        end
        return 0
    end

    local filled = 0
    for specName, btData in pairs(BT.BuildData) do
        -- Resolve specID from name
        local specID = SPEC_NAME_TO_ID[specName]
        if not specID then
            -- Try direct match by iterating all known specIDs and comparing
            -- against GetSpecializationInfoByID display names. This handles
            -- cases where BetterTalents uses simple names like "Frost" for
            -- unambiguous specs or future new specs.
            -- (Fallback: skip unknown names silently)
            if TA.debug then
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA Talents]|r Unknown spec name: " .. specName .. " — skipped.")
            end
        end

        if specID and DB[specID] then
            local builds = DB[specID].builds

            -- M+ build: prefer mplus_overall, fallback to mplus_12
            local mplusStr = btData.mplus_overall or btData.mplus_12
            if
                mplusStr
                and mplusStr ~= ""
                and builds.mplus
                and (builds.mplus.string == "" or builds.mplus.string == nil)
            then
                builds.mplus.string = mplusStr
                filled = filled + 1
            end

            -- Raid Mythic → raid build
            local raidStr = btData.raid_mythic
            if
                raidStr
                and raidStr ~= ""
                and builds.raid
                and (builds.raid.string == "" or builds.raid.string == nil)
            then
                builds.raid.string = raidStr
                filled = filled + 1
            end

            -- Raid Heroic → store as a secondary reference (if the spec has no raid string,
            -- use heroic as fallback)
            local heroicStr = btData.raid_heroic
            if heroicStr and heroicStr ~= "" then
                -- If raid is still empty after mythic check, use heroic
                if builds.raid and (builds.raid.string == "" or builds.raid.string == nil) then
                    builds.raid.string = heroicStr
                    filled = filled + 1
                end
                -- Also store heroic as its own reference for users who want it
                if not builds.raid_heroic then
                    builds.raid_heroic = {
                        name = (builds.raid and builds.raid.name or "Raid") .. " (Heroic)",
                        desc = "Heroic raid build imported from BetterTalents log data.",
                        string = heroicStr,
                        nodes = {},
                    }
                elseif builds.raid_heroic.string == "" or builds.raid_heroic.string == nil then
                    builds.raid_heroic.string = heroicStr
                    filled = filled + 1
                end
            end
        end
    end

    if filled > 0 then
        -- INFO: an auto-import count nobody asked for. Same class as the
        -- "module loaded" notices 9959873 quieted; goes silent at the WARN default.
        TA:Raw(
            TA.LOG.INFO,
            string.format(
                "|cFFFFD100[ToonAge]|r Talent sync: imported |cFF4AFF7A%d|r build strings from BetterTalents.",
                filled
            )
        )
    elseif TA.debug then
        TA:Raw(
            TA.LOG.OUTPUT,
            "|cFFFFD100[TA Talents]|r Sync complete — no new strings needed (all slots already filled)."
        )
    end

    return filled
end

-- ── Content type labels (displayed in the tab selector) ───────────────────
T.BuildTypes = {
    { key = "mplus", label = "Mythic+" },
    { key = "raid", label = "Raid" },
    { key = "delves", label = "Delves" },
    { key = "pvp", label = "PvP" },
    { key = "solo", label = "Leveling" },
}

-- ── Auto-populate missing build types ─────────────────────────────────────
-- Many specs above only have mplus/raid/solo.  Fill in pvp and delves with
-- sensible defaults (desc + empty import string) so the UI never shows
-- "No build for this content type" when those tabs are selected.
for specID, specData in pairs(DB) do
    if not specData.builds.pvp then
        specData.builds.pvp = {
            name = "PvP Recommended",
            desc = "Versatility-focused survivability with burst windows. Fill import string with your current PvP loadout.",
            string = "",
            nodes = {},
        }
    end
    if not specData.builds.delves then
        -- Delves sit between solo and M+ difficulty.  Default to solo build
        -- with a relabeled desc until spec-specific Delve builds are researched.
        local soloRef = specData.builds.solo
        specData.builds.delves = {
            name = (soloRef and soloRef.name or "Delves Recommended") .. " (Delve)",
            desc = "Self-sustain and consistent throughput for Tier 8+ Delves. Modify from your solo build.",
            string = soloRef and soloRef.string or "",
            nodes = soloRef and soloRef.nodes or {},
        }
    end
end
