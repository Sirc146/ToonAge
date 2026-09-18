-- ==========================================================================
-- ToonAge: FarmOptimizer_Data.lua
-- Static data for the real-time farming optimizer.
-- Provides item values, scoring constants, and profession identifiers.
-- No executable logic — data only.
-- ==========================================================================

local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.FarmOptimizer = {}

local FO = TA.Data.FarmOptimizer

-- ==========================================================================
-- PROFESSION SKILLLINES
-- SkillLine IDs used by C_TradeSkillUI for gathering professions.
-- ==========================================================================

FO.PROFESSION_SKILLLINES = {
    HERBALISM = 182,
    MINING    = 186,
    SKINNING  = 393,
}

-- ==========================================================================
-- GATHER SUBCLASS
-- Item subclass IDs for tradeskill items (classID = 7) from GetItemInfoInstant.
-- Used to identify the type of gathered material.
-- ==========================================================================

FO.GATHER_SUBCLASS = {
    HERB     = 9,
    ORE      = 7,
    LEATHER  = 6,
}

-- ==========================================================================
-- ITEM VALUES
-- Approximate gold value per item in copper (100g = 1,000,000 copper).
-- Ballpark values for gold/hour estimation, not precise AH prices.
-- ==========================================================================

FO.ITEM_VALUES = {
    -- War Within Herbs (itemID = value in copper)
    [210796] = 5000,   -- Mycobloom
    [210797] = 7500,   -- Luredrop
    [210798] = 6000,   -- Orbinid
    [210799] = 8000,   -- Blessing Blossom
    [210800] = 12000,  -- Arathor's Spear
    [210801] = 15000,  -- Bismuth (rare herb)

    -- War Within Ores
    [210930] = 4000,   -- Bismuth
    [210931] = 5500,   -- Aqirite
    [210932] = 7000,   -- Ironclaw Ore
    [210933] = 9000,   -- Null Stone

    -- Skinning
    [210938] = 3000,   -- Stormcharged Leather
    [210939] = 4500,   -- Crystalskin
    [210940] = 6000,   -- Flawless Proto-Scale

    -- Midnight Herbs (placeholder IDs)
    [220001] = 6000,   -- Midnight Herb A
    [220002] = 8000,   -- Midnight Herb B
    [220003] = 10000,  -- Midnight Herb C

    -- Midnight Ores (placeholder IDs)
    [220010] = 5000,   -- Midnight Ore A
    [220011] = 7000,   -- Midnight Ore B
    [220012] = 9000,   -- Midnight Ore C
}

-- ==========================================================================
-- DEFAULT ITEM VALUE
-- Fallback value (in copper) when an item is not found in ITEM_VALUES.
-- ==========================================================================

FO.DEFAULT_ITEM_VALUE = 5000  -- 50 silver

-- ==========================================================================
-- SCORING CONSTANTS
-- Thresholds for efficiency grading, zone heat, cluster detection,
-- rolling window parameters, and movement calculations.
-- ==========================================================================

FO.SCORING = {
    -- Efficiency grade thresholds (nodes per minute)
    GRADE_A = 3.0,   -- 3+ nodes/min = A
    GRADE_B = 2.0,   -- 2-3 = B
    GRADE_C = 1.5,   -- 1.5-2 = C
    GRADE_D = 1.0,   -- 1-1.5 = D
    GRADE_F = 0.0,   -- below 1 = F

    -- Zone heat thresholds (nodes in rolling window)
    HEAT_HOT  = 8,   -- 8+ nodes in window = Hot
    HEAT_WARM = 4,   -- 4-7 = Warm
    HEAT_COLD = 0,   -- below 4 = Cold

    -- Cluster detection
    CLUSTER_RADIUS     = 0.03,  -- map-unit radius for cluster grouping
    CLUSTER_MIN_NODES  = 3,     -- minimum nodes to form a cluster
    CLUSTER_FADE_TIME  = 300,   -- seconds before a cluster fades (5 min)

    -- Rolling window
    WINDOW_DURATION    = 600,   -- 10 minute rolling window (seconds)
    POSITION_INTERVAL  = 0.5,   -- seconds between position samples
    IDLE_THRESHOLD     = 3.0,   -- seconds without movement = idle

    -- Movement
    YARDS_PER_MAP_UNIT = 1000,  -- approximate yards per 1.0 map coordinate unit
}

-- ==========================================================================
-- GRADE COLORS
-- RGB color values (0-1 range) for each efficiency grade.
-- ==========================================================================

FO.GRADE_COLORS = {
    A = { 0.29, 1.00, 0.48 },  -- green
    B = { 0.40, 0.85, 1.00 },  -- blue
    C = { 1.00, 0.82, 0.00 },  -- gold
    D = { 1.00, 0.55, 0.20 },  -- orange
    F = { 1.00, 0.30, 0.25 },  -- red
}

-- ==========================================================================
-- HEAT COLORS
-- RGB color values (0-1 range) for zone heat indicators.
-- ==========================================================================

FO.HEAT_COLORS = {
    Hot  = { 1.00, 0.30, 0.15 },
    Warm = { 1.00, 0.70, 0.10 },
    Cold = { 0.40, 0.55, 0.80 },
}
