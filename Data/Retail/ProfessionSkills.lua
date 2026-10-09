-- ToonAge/Data/Retail/ProfessionSkills.lua
-- Skill-line caps and child skill lines for the shared profession cards.
--
-- The reader in Modules/Character/ProfessionSkills.lua does not know which
-- game this is. It walks `prefer` and uses the first reader whose calls exist.
-- Retail wants one segment per expansion, so `segments` is first.
--
-- Child ids are the published TradeSkillLineID variants, left to right:
-- Classic, Outland, Northrend, Cataclysm, Pandaria, Draenor, Legion,
-- Battle for Azeroth, Shadowlands, Dragonflight, The War Within, Midnight.
-- Dragon Isles Blacksmithing is 2822 and Khaz Algar Blacksmithing is 2872.
-- Enchanting has no 2490. Archaeology and First Aid have no expansion column.
-- The current expansion is the row with current = true (Midnight).

local TA = ToonAge
TA.Data = TA.Data or {}

local EXPANSIONS = {
    { label = "Classic",            cap = 300 },
    { label = "Outland",            cap = 75  },
    { label = "Northrend",          cap = 75  },
    { label = "Cataclysm",          cap = 75  },
    { label = "Pandaria",           cap = 75  },
    { label = "Draenor",            cap = 100 },
    { label = "Legion",             cap = 100 },
    { label = "Battle for Azeroth", cap = 150 },
    { label = "Shadowlands",        cap = 100 },
    { label = "Dragonflight",       cap = 100 },
    { label = "The War Within",     cap = 100 },
    { label = "Midnight",           cap = 100, current = true },
}

local function Line(id, name, children, secondary)
    return { id = id, name = name, children = children, secondary = secondary and true or false }
end

TA.Data.ProfessionSkills = {
    unverified = false,
    prefer     = { "segments", "professions" },
    cap        = 100,
    headers    = { "Professions", "Secondary Skills" },
    expansions = EXPANSIONS,
    lines = {
        Line(171, "Alchemy",        { 2485, 2484, 2483, 2482, 2481, 2480, 2479, 2478, 2750, 2823, 2871, 2906 }),
        Line(164, "Blacksmithing",  { 2477, 2476, 2475, 2474, 2473, 2472, 2454, 2437, 2751, 2822, 2872, 2907 }),
        Line(333, "Enchanting",     { 2494, 2493, 2492, 2491, 2489, 2488, 2487, 2486, 2753, 2825, 2874, 2909 }),
        Line(202, "Engineering",    { 2506, 2505, 2504, 2503, 2502, 2501, 2500, 2499, 2755, 2827, 2875, 2910 }),
        Line(182, "Herbalism",      { 2556, 2555, 2554, 2553, 2552, 2551, 2550, 2549, 2760, 2832, 2877, 2912 }),
        Line(773, "Inscription",    { 2514, 2513, 2512, 2511, 2510, 2509, 2508, 2507, 2756, 2828, 2878, 2913 }),
        Line(755, "Jewelcrafting",  { 2524, 2523, 2522, 2521, 2520, 2519, 2518, 2517, 2757, 2829, 2879, 2914 }),
        Line(165, "Leatherworking", { 2532, 2531, 2530, 2529, 2528, 2527, 2526, 2525, 2758, 2830, 2880, 2915 }),
        Line(186, "Mining",         { 2572, 2571, 2570, 2569, 2568, 2567, 2566, 2565, 2761, 2833, 2881, 2916 }),
        Line(393, "Skinning",       { 2564, 2563, 2562, 2561, 2560, 2559, 2558, 2557, 2762, 2834, 2882, 2917 }),
        Line(197, "Tailoring",      { 2540, 2539, 2538, 2537, 2536, 2535, 2534, 2533, 2759, 2831, 2883, 2918 }),
        Line(185, "Cooking",        { 2548, 2547, 2546, 2545, 2544, 2543, 2542, 2541, 2752, 2824, 2873, 2908 }, true),
        Line(356, "Fishing",        { 2592, 2591, 2590, 2589, 2588, 2587, 2586, 2585, 2754, 2826, 2876, 2911 }, true),
        Line(794, "Archaeology",    nil, true),
        Line(129, "First Aid",      nil, true),
    },
}
