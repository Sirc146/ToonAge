-- ToonAge/Data/ItemLevels.lua
-- Item level brackets and expected gear per content tier
-- Mists of Pandaria Classic (5.4.x, Interface 50504)
-- Source: WoWhead MoP gear progression, official Blizzard dungeon/raid ilvl gates

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.ItemLevels = {}
local IL = TA.Data.ItemLevels

-- ── Content type enum ──────────────────────────────────────────────────
IL.TYPE = {
    WORLD   = "world",
    DUNGEON = "dungeon",
    HEROIC  = "heroic_dungeon",
    SCENARIO = "scenario",
    HSCENARIO = "heroic_scenario",
    RAID    = "raid",
    PVP     = "pvp",
}

-- ── Leveling ilvl brackets (1-90) ─────────────────────────────────────
-- Expected average ilvl at each level range while questing
IL.LEVELING = {
    { minLevel=1,  maxLevel=15,  expectedIlvl=8,   note="Starting gear" },
    { minLevel=16, maxLevel=25,  expectedIlvl=20,  note="First dungeon drops" },
    { minLevel=26, maxLevel=35,  expectedIlvl=32,  note="Mid-classic zones" },
    { minLevel=36, maxLevel=45,  expectedIlvl=44,  note="Late classic / early TBC" },
    { minLevel=46, maxLevel=55,  expectedIlvl=57,  note="Late classic dungeons" },
    { minLevel=56, maxLevel=60,  expectedIlvl=68,  note="Vanilla endgame / Outland entry" },
    { minLevel=61, maxLevel=68,  expectedIlvl=95,  note="Outland questing" },
    { minLevel=69, maxLevel=70,  expectedIlvl=115, note="Outland endgame" },
    { minLevel=71, maxLevel=78,  expectedIlvl=138, note="Northrend questing" },
    { minLevel=79, maxLevel=80,  expectedIlvl=175, note="Northrend endgame" },
    { minLevel=81, maxLevel=84,  expectedIlvl=289, note="Cataclysm questing" },
    { minLevel=85, maxLevel=85,  expectedIlvl=333, note="Cataclysm endgame entry" },
    { minLevel=86, maxLevel=89,  expectedIlvl=400, note="Pandaria questing" },
    { minLevel=90, maxLevel=90,  expectedIlvl=450, note="Fresh level 90" },
}

-- ── Max-level gear tiers (Level 90, Patch 5.4) ────────────────────────
IL.TIERS = {
    -- Dungeons & Scenarios
    normal_dungeon   = { name="Normal Dungeon",      ilvlMin=410, ilvlMax=440,
        source="Level 90 Normal Dungeons",
        note="Entry point for fresh 90s" },
    heroic_dungeon   = { name="Heroic Dungeon",      ilvlMin=440, ilvlMax=463,
        source="Heroic Dungeons (requires ilvl 435)",
        note="Daily valor + gear upgrades" },
    scenario         = { name="Scenario",            ilvlMin=430, ilvlMax=450,
        source="Normal Scenarios",
        note="Quick 3-player content, no tank/healer required" },
    heroic_scenario  = { name="Heroic Scenario",     ilvlMin=463, ilvlMax=476,
        source="Heroic Scenarios (requires ilvl 480)",
        note="Bonus loot bag once per day" },
    -- Raids: Tier 14
    msv_lfr          = { name="MSV LFR",             ilvlMin=476, ilvlMax=483,
        source="Mogu'shan Vaults LFR",
        note="Looking For Raid — no premade needed" },
    hof_lfr          = { name="HoF LFR",             ilvlMin=476, ilvlMax=483,
        source="Heart of Fear LFR",
        note="Tier 14 LFR" },
    toes_lfr         = { name="ToES LFR",            ilvlMin=476, ilvlMax=483,
        source="Terrace of Endless Spring LFR",
        note="Tier 14 LFR" },
    t14_normal       = { name="T14 Normal",          ilvlMin=489, ilvlMax=496,
        source="MSV / HoF / ToES Normal",
        note="Tier 14 Normal mode" },
    t14_heroic       = { name="T14 Heroic",          ilvlMin=502, ilvlMax=509,
        source="MSV / HoF / ToES Heroic",
        note="Tier 14 Heroic mode" },
    -- Raids: Tier 15
    tot_lfr          = { name="ToT LFR",             ilvlMin=502, ilvlMax=510,
        source="Throne of Thunder LFR",
        note="Tier 15 LFR" },
    tot_normal       = { name="ToT Normal",          ilvlMin=522, ilvlMax=528,
        source="Throne of Thunder Normal",
        note="Tier 15 Normal mode" },
    tot_heroic       = { name="ToT Heroic",          ilvlMin=535, ilvlMax=541,
        source="Throne of Thunder Heroic",
        note="Tier 15 Heroic mode — Thunderforged possible" },
    -- Raids: Tier 16
    soo_lfr          = { name="SoO LFR",             ilvlMin=528, ilvlMax=536,
        source="Siege of Orgrimmar LFR",
        note="Tier 16 LFR" },
    soo_flex         = { name="SoO Flex",            ilvlMin=540, ilvlMax=548,
        source="Siege of Orgrimmar Flex (10-25 players)",
        note="Flexible raid size — good mid-tier option" },
    soo_normal       = { name="SoO Normal",          ilvlMin=553, ilvlMax=559,
        source="Siege of Orgrimmar Normal",
        note="Tier 16 Normal — Warforged possible" },
    soo_heroic       = { name="SoO Heroic",          ilvlMin=566, ilvlMax=574,
        source="Siege of Orgrimmar Heroic",
        note="Tier 16 Heroic — Warforged + socket possible" },
    -- Catch-up
    timeless_isle    = { name="Timeless Isle",        ilvlMin=496, ilvlMax=535,
        source="Timeless Isle tokens + Burden of Eternity",
        note="Solo catch-up — 496 base, 535 with Burden" },
    valor_upgrades   = { name="Valor Upgraded",       ilvlMin=0,   ilvlMax=8,
        source="Valor Point upgrades (+4 per upgrade, 2x max)",
        note="Adds +8 ilvl to any upgradeable item" },
    -- PvP
    pvp_honor        = { name="Honor Gear",           ilvlMin=476, ilvlMax=496,
        source="Honor Points vendor (Tyrannical/Grievous)",
        note="Entry PvP gear — decent for starting heroics" },
    pvp_conquest     = { name="Conquest Gear",        ilvlMin=522, ilvlMax=550,
        source="Conquest Points (Grievous/Prideful)",
        note="Rated PvP rewards — ilvl 550 in S15" },
    -- World Bosses
    world_boss       = { name="World Boss",           ilvlMin=496, ilvlMax=553,
        source="Sha of Anger, Galleon, Nalak, Oondasta, Ordos",
        note="Weekly kill — bonus roll recommended" },
}

-- ── Readiness thresholds ───────────────────────────────────────────────
-- What avg ilvl you need to queue/participate in each content type
IL.READINESS = {
    normal_dungeon   = { min=358, rec=410, label="Normal Dungeon (90)" },
    heroic_dungeon   = { min=435, rec=450, label="Heroic Dungeon" },
    scenario         = { min=425, rec=430, label="Scenario" },
    heroic_scenario  = { min=480, rec=490, label="Heroic Scenario" },
    msv_lfr          = { min=460, rec=470, label="MSV LFR" },
    hof_lfr          = { min=470, rec=476, label="HoF/ToES LFR" },
    tot_lfr          = { min=480, rec=496, label="ToT LFR" },
    soo_lfr          = { min=496, rec=510, label="SoO LFR" },
    soo_flex         = { min=510, rec=520, label="SoO Flex" },
    soo_normal       = { min=530, rec=540, label="SoO Normal" },
    soo_heroic       = { min=550, rec=560, label="SoO Heroic" },
    timeless_isle    = { min=430, rec=460, label="Timeless Isle" },
}

-- ── Get tier for a given ilvl ──────────────────────────────────────────
function IL:GetTier(ilvl)
    if ilvl >= 566 then return self.TIERS.soo_heroic
    elseif ilvl >= 553 then return self.TIERS.soo_normal
    elseif ilvl >= 540 then return self.TIERS.soo_flex
    elseif ilvl >= 528 then return self.TIERS.soo_lfr
    elseif ilvl >= 522 then return self.TIERS.tot_normal
    elseif ilvl >= 502 then return self.TIERS.tot_lfr
    elseif ilvl >= 489 then return self.TIERS.t14_normal
    elseif ilvl >= 476 then return self.TIERS.msv_lfr
    elseif ilvl >= 463 then return self.TIERS.heroic_dungeon
    elseif ilvl >= 440 then return self.TIERS.normal_dungeon
    else return nil end
end

-- ── Get expected ilvl for player level ─────────────────────────────────
function IL:GetExpectedForLevel(level)
    for _, bracket in ipairs(self.LEVELING) do
        if level >= bracket.minLevel and level <= bracket.maxLevel then
            return bracket.expectedIlvl, bracket.note
        end
    end
    return 450, "Level 90"
end

-- ── Readiness assessment ───────────────────────────────────────────────
function IL:GetReadiness(avgIlvl)
    local tiers = {
        { key="soo_heroic",    label="SoO Heroic",     recMin=560 },
        { key="soo_normal",    label="SoO Normal",     recMin=540 },
        { key="soo_flex",      label="SoO Flex",       recMin=520 },
        { key="soo_lfr",       label="SoO LFR",        recMin=510 },
        { key="tot_lfr",       label="ToT LFR",        recMin=496 },
        { key="hof_lfr",       label="HoF/ToES LFR",   recMin=476 },
        { key="msv_lfr",       label="MSV LFR",        recMin=470 },
        { key="heroic_scenario",label="Heroic Scenario",recMin=490 },
        { key="heroic_dungeon",label="Heroic Dungeon",  recMin=450 },
        { key="scenario",      label="Scenario",        recMin=430 },
        { key="normal_dungeon",label="Normal Dungeon",   recMin=410 },
    }

    local highestReady = nil
    local nextTarget   = nil

    for _, tier in ipairs(tiers) do
        local threshold = self.READINESS[tier.key]
        if threshold then
            if avgIlvl >= threshold.rec and not highestReady then
                highestReady = tier
            elseif avgIlvl < threshold.rec and not nextTarget and avgIlvl >= (threshold.min or 0) then
                nextTarget = tier
            end
        end
    end

    return highestReady, nextTarget
end

-- ── Gap analysis ──────────────────────────────────────────────────────
function IL:GetGapAnalysis(avgIlvl)
    local milestones = {
        { ilvl=435, label="Heroic Dungeon queue",    color={0.29,1,0.48}   },
        { ilvl=460, label="MSV LFR queue",           color={0.29,1,0.48}   },
        { ilvl=480, label="ToT LFR queue",           color={1,0.82,0}      },
        { ilvl=496, label="SoO LFR / Timeless gear", color={1,0.82,0}      },
        { ilvl=520, label="SoO Flex ready",          color={1,0.60,0.10}   },
        { ilvl=540, label="SoO Normal ready",        color={1,0.60,0.10}   },
        { ilvl=560, label="SoO Heroic ready",        color={1,0.27,0.27}   },
        { ilvl=574, label="BiS (Heroic Warforged)",  color={0.80,0.27,1.0} },
    }

    local result = {}
    for _, m in ipairs(milestones) do
        local gap = m.ilvl - avgIlvl
        if gap > 0 then
            table.insert(result, {
                label = m.label,
                ilvl  = m.ilvl,
                gap   = gap,
                color = m.color,
            })
        end
    end
    return result
end

-- ── Upgrade sources ───────────────────────────────────────────────────
IL.UPGRADE_SOURCES = {
    solo = {
        { name="Timeless Isle tokens",  ilvl="496",     note="BoA armor tokens — instant catch-up" },
        { name="Burden of Eternity",    ilvl="535",     note="Rare drop on Timeless Isle — upgrades one token to 535" },
        { name="World bosses",          ilvl="496-553", note="Sha, Galleon, Nalak, Oondasta, Ordos (weekly)" },
        { name="Valor upgrades",        ilvl="+8",      note="Spend Valor to upgrade any item twice (+4 each)" },
    },
    group = {
        { name="Heroic Dungeons",       ilvl="463",     note="Daily valor bonus — fast queue" },
        { name="Scenarios",             ilvl="430-476", note="Fast 3-player, heroic gives better loot" },
        { name="LFR (all tiers)",       ilvl="476-536", note="Queue solo — bonus roll tokens recommended" },
        { name="Flex Raid (SoO)",       ilvl="540-548", note="10-25 players, flexible sizing" },
        { name="Normal Raid (SoO)",     ilvl="553-559", note="Fixed 10 or 25 — guild groups" },
        { name="Heroic Raid (SoO)",     ilvl="566-574", note="Cutting edge — Warforged drops possible" },
    },
    pvp = {
        { name="Honor gear",            ilvl="476-496", note="BGs and random PvP — usable for PvE entry" },
        { name="Conquest gear",         ilvl="522-550", note="Rated PvP — strong for world content too" },
    },
}
