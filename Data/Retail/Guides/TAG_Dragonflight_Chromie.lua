-- ToonAge guide data: Dragonflight leveling CAMPAIGN route for a Chromie Time ("Timewalking Campaign: Dragonflight") character
-- Generated 2026-10-08 (PT). Format: { type, questID, text, [faction], coord = { map = uiMapID, x = 0-1, y = 0-1 } }
-- Retail 12.1.0 (build 69933). Chromie Time: zones scale to 80; removed from the campaign at 81; must start at 68 or below.
--
-- uiMapIDs (verified in wago.tools UiMap DB2, 12.1.0.69933):
--   84 Stormwind City, 85 Orgrimmar, 1 Durotar (Horde zeppelin tower / Rokhan's Point area), 2022 The Waking Shores,
--   2023 Ohn'ahran Plains, 2024 The Azure Span, 2025 Thaldraszus, 2112 Valdrakken,
--   2085 The Primalist Future, 2089 The Black Empire, 2090 The Gnoll War, 2092 Azmerloth
--   (the last four are Thaldraszus campaign time-rift phase maps, instance map 2512).
--
-- SOURCES / VERIFICATION
--  * Step order and questIDs come from the Azeroth Pilot Reloaded routes in Routes/Dragonflight/{Dragonflight.lua, Dragonflight_Alliance.lua,
--    Dragonflight_horde.lua} (github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded, master @ c56dba7, fetched 2026-10-08).
--    Route chain: 84-DF01A-Stormwind / 85-DF01H-Orgrimmar -> 2022-DF03A/H-WakingShores -> 2022-DF03N-WakingShores
--    -> 2023-DF04-OhnahranPlains -> 2024-DF05-AzureSpan -> 2025-DF06A/H-Thaldraszus.
--  * Every quest name was checked on Wowhead's tooltip API (nether.wowhead.com/tooltip/quest/<id>), 2026-10-08. All 345 quest IDs resolved (0 missing).
--  * Accept coords are quest-giver coords from AllTheThings (.contrib/.db/standard/02 - Outdoor Zones/14 Dragon Isles/*/Quests.lua).
--  * All other coords are APR world positions converted EXACTLY with the UiMapAssignment DB2 bounds (no curve fitting):
--      mapX = (RegionMaxY - worldY) / (RegionMaxY - RegionMinY), mapY = (RegionMaxX - worldX) / (RegionMaxX - RegionMinX).
--    Cross-check: across 379 accept steps, converted APR coords vs. ATT giver coords had a median error of 0.05 map-%
--    and a 90th percentile of 0.10 map-%. Max error was 2.1 map-% (one quest, 66001).
--  * faction = "Alliance"/"Horde" tags faction-specific steps (the intro, the Wingrest Embassy section, and the faction-variant Thaldraszus
--    time-rift quests). Untagged steps are shared.
--  * Steps marked UNVERIFIED in their trailing comment have an inferred coord or an inferred auto-accept. Grep for "UNVERIFIED".
--
-- EXCLUDED / NOTES
--  * APR's account "skip campaign" branch is omitted. These steps are gated on hidden achievement 16326
--    "ACCOUNT: Campaign Complete". When an alt's warband has finished the DF campaign, the alt is offered 72293 "Adventuring in the Dragon Isles",
--    then a zone pick: 72266 The Waking Shores / 72267 Ohn'ahran Plains / 72268 The Azure Span / 72269 Thaldraszus.
--    The full campaign below still works.
--  * APR "Fillers" (optional side quests en route), flight-path, hearthstone and portal steps are not emitted, so this is campaign-only.
--  * Duplicate zone-transition turn-ins were removed: 67700, 65444 (intro end), 65779, 65686 (zone-edge copies) and 66244 (repeated
--    at the start of Thaldraszus). The turn-in kept for each is the one in the destination zone.
--  * 65801 "Making Introductions" has no turn-in step in APR. It is assumed to complete on its last objective (UNVERIFIED).
--  * Dracthyr starting-zone routes (Forbidden Reach) are not included. Dracthyr start at 10 and use a separate route.
--  * Level ranges and XP have changed many times. Content scales 10-80 in Chromie Time. Quest IDs are unchanged since 10.x per APR, ATT and Wowhead.

local TA = ToonAge
TA.GuideData = TA.GuideData or {}

TA.GuideData["dragonflight_chromie_campaign"] = {
    id = "dragonflight_chromie_campaign", title = "Dragonflight: Dragon Isles Campaign (Chromie Time)", expansion = "dragonflight",
    zone = 2022, minLevel = 10, maxLevel = 80,
    nextGuide = nil, -- campaign ends at Valdrakken ("Moving On", 66221)
    steps = {
        -- ===== Intro: Stormwind (Alliance) / Orgrimmar & Durotar (Horde) =====
        { type = "accept", questID = 65436, text = "The Dragon Isles Await", faction = "Alliance",
          coord = { map = 84, x = 0.798, y = 0.272 } },  -- giver coord: ATT
        { type = "turnin", questID = 65436, text = "Turn in: The Dragon Isles Await", faction = "Alliance",
          coord = { map = 84, x = 0.798, y = 0.271 } },  -- APR route coord (converted)
        { type = "accept", questID = 66577, text = "Aspectral Invitation", faction = "Alliance",
          coord = { map = 84, x = 0.798, y = 0.271 } },  -- giver coord: ATT
        { type = "quest", questID = 66577, text = "Aspectral Invitation (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.798, y = 0.271 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66577, text = "Turn in: Aspectral Invitation", faction = "Alliance",
          coord = { map = 84, x = 0.798, y = 0.271 } },  -- APR route coord (converted)
        { type = "accept", questID = 72240, text = "The Obsidian Warders", faction = "Alliance",
          coord = { map = 84, x = 0.799, y = 0.271 } },  -- giver coord: ATT
        { type = "accept", questID = 66589, text = "Expeditionary Coordination", faction = "Alliance",
          coord = { map = 84, x = 0.797, y = 0.273 } },  -- giver coord: ATT
        { type = "quest", questID = 66589, text = "Expeditionary Coordination (objective 2)", faction = "Alliance",
          coord = { map = 84, x = 0.382, y = 0.454 } },  -- APR route coord (converted)
        { type = "quest", questID = 72240, text = "The Obsidian Warders (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.392, y = 0.414 } },  -- APR route coord (converted)
        { type = "quest", questID = 66589, text = "Expeditionary Coordination (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.381, y = 0.351 } },  -- APR route coord (converted)
        { type = "quest", questID = 66589, text = "Expeditionary Coordination (objective 3)", faction = "Alliance",
          coord = { map = 84, x = 0.329, y = 0.346 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66589, text = "Turn in: Expeditionary Coordination", faction = "Alliance",
          coord = { map = 84, x = 0.227, y = 0.557 } },  -- APR route coord (converted)
        { type = "turnin", questID = 72240, text = "Turn in: The Obsidian Warders", faction = "Alliance",
          coord = { map = 84, x = 0.227, y = 0.557 } },  -- APR route coord (converted)
        { type = "accept", questID = 66596, text = "Whispers on the Winds", faction = "Alliance",
          coord = { map = 84, x = 0.230, y = 0.561 } },  -- giver coord: ATT
        { type = "quest", questID = 66596, text = "Whispers on the Winds (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.230, y = 0.561 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66596, text = "Turn in: Whispers on the Winds", faction = "Alliance",
          coord = { map = 84, x = 0.229, y = 0.560 } },  -- APR route coord (converted)
        { type = "accept", questID = 67700, text = "To the Dragon Isles!", faction = "Alliance",
          coord = { map = 84, x = 0.227, y = 0.556 } },  -- giver coord: ATT
        { type = "accept", questID = 65435, text = "The Dragon Isles Await", faction = "Horde",
          coord = { map = 85, x = 0.442, y = 0.382 } },  -- giver coord: ATT
        { type = "turnin", questID = 65435, text = "Turn in: The Dragon Isles Await", faction = "Horde",
          coord = { map = 85, x = 0.441, y = 0.380 } },  -- APR route coord (converted)
        { type = "accept", questID = 65437, text = "Aspectral Invitation", faction = "Horde",
          coord = { map = 85, x = 0.441, y = 0.380 } },  -- giver coord: ATT
        { type = "quest", questID = 65437, text = "Aspectral Invitation (objective 1)", faction = "Horde",
          coord = { map = 85, x = 0.441, y = 0.380 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65437, text = "Turn in: Aspectral Invitation", faction = "Horde",
          coord = { map = 85, x = 0.441, y = 0.380 } },  -- APR route coord (converted)
        { type = "accept", questID = 65443, text = "Expeditionary Coordination", faction = "Horde",
          coord = { map = 85, x = 0.442, y = 0.378 } },  -- giver coord: ATT
        { type = "accept", questID = 72256, text = "The Dark Talons", faction = "Horde",
          coord = { map = 85, x = 0.440, y = 0.383 } },  -- giver coord: ATT
        { type = "quest", questID = 65443, text = "Expeditionary Coordination (objective 2)", faction = "Horde",
          coord = { map = 1, x = 0.540, y = 0.130 } },  -- APR route coord (converted)
        { type = "quest", questID = 72256, text = "The Dark Talons (objective 1)", faction = "Horde",
          coord = { map = 1, x = 0.541, y = 0.099 } },  -- APR route coord (converted)
        { type = "quest", questID = 65443, text = "Expeditionary Coordination (objective 1)", faction = "Horde",
          coord = { map = 1, x = 0.552, y = 0.116 } },  -- APR route coord (converted)
        { type = "quest", questID = 65443, text = "Expeditionary Coordination (objective 3)", faction = "Horde",
          coord = { map = 1, x = 0.560, y = 0.132 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65443, text = "Turn in: Expeditionary Coordination", faction = "Horde",
          coord = { map = 1, x = 0.558, y = 0.127 } },  -- APR route coord (converted)
        { type = "turnin", questID = 72256, text = "Turn in: The Dark Talons", faction = "Horde",
          coord = { map = 1, x = 0.558, y = 0.127 } },  -- APR route coord (converted)
        { type = "accept", questID = 65439, text = "Whispers on the Winds", faction = "Horde",
          coord = { map = 1, x = 0.559, y = 0.126 } },  -- giver coord: ATT
        { type = "quest", questID = 65439, text = "Whispers on the Winds (objective 1)", faction = "Horde",
          coord = { map = 1, x = 0.559, y = 0.126 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65439, text = "Turn in: Whispers on the Winds", faction = "Horde",
          coord = { map = 1, x = 0.558, y = 0.127 } },  -- APR route coord (converted)
        { type = "accept", questID = 65444, text = "To the Dragon Isles!", faction = "Horde",
          coord = { map = 1, x = 0.558, y = 0.127 } },  -- giver coord: ATT
        { type = "quest", questID = 65444, text = "To the Dragon Isles! (objective 1)", faction = "Horde",
          coord = { map = 1, x = 0.558, y = 0.126 } },  -- APR route coord (converted)
        -- ===== The Waking Shores: Wingrest Embassy (faction section) =====
        { type = "quest", questID = 67700, text = "To the Dragon Isles! (objective 1)", faction = "Alliance",
          coord = { map = 84, x = 0.227, y = 0.557 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67700, text = "Turn in: To the Dragon Isles!", faction = "Alliance",
          coord = { map = 2022, x = 0.821, y = 0.319 } },  -- APR route coord (converted)
        { type = "accept", questID = 70122, text = "Explorers in Peril", faction = "Alliance",
          coord = { map = 2022, x = 0.821, y = 0.319 } },  -- giver coord: ATT
        { type = "accept", questID = 70123, text = "Primal Pests", faction = "Alliance",
          coord = { map = 2022, x = 0.822, y = 0.318 } },  -- giver coord: ATT
        { type = "accept", questID = 70124, text = "Practice Materials", faction = "Alliance",
          coord = { map = 2022, x = 0.821, y = 0.319 } },  -- giver coord: ATT
        { type = "quest", questID = 70122, text = "Explorers in Peril (objective 1)", faction = "Alliance",
          coord = { map = 2022, x = 0.836, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest", questID = 70122, text = "Explorers in Peril (objective 2)", faction = "Alliance",
          coord = { map = 2022, x = 0.831, y = 0.361 } },  -- APR route coord (converted)
        { type = "quest", questID = 70122, text = "Explorers in Peril (objective 3)", faction = "Alliance",
          coord = { map = 2022, x = 0.796, y = 0.354 } },  -- APR route coord (converted)
        { type = "quest", questID = 70123, text = "Primal Pests (objective 1)", faction = "Alliance",
          coord = { map = 2022, x = 0.813, y = 0.339 } },  -- APR route coord (converted)
        { type = "quest", questID = 70124, text = "Practice Materials (objective 1)", faction = "Alliance",
          coord = { map = 2022, x = 0.813, y = 0.339 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70122, text = "Turn in: Explorers in Peril", faction = "Alliance",
          coord = { map = 2022, x = 0.766, y = 0.336 } },  -- APR route coord (converted)
        { type = "accept", questID = 70125, text = "Where is Wrathion?", faction = "Alliance",
          coord = { map = 2022, x = 0.766, y = 0.336 } },  -- giver coord: ATT
        { type = "quest", questID = 70125, text = "Where is Wrathion? (objective 1)", faction = "Alliance",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70125, text = "Turn in: Where is Wrathion?", faction = "Alliance",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest", questID = 65444, text = "To the Dragon Isles! (objective 2)", faction = "Horde",
          coord = { map = 2022, x = 0.808, y = 0.278 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65444, text = "Turn in: To the Dragon Isles!", faction = "Horde",
          coord = { map = 2022, x = 0.806, y = 0.276 } },  -- APR route coord (converted)
        { type = "accept", questID = 65452, text = "Explorers in Peril", faction = "Horde",
          coord = { map = 2022, x = 0.806, y = 0.276 } },  -- giver coord: ATT
        { type = "accept", questID = 65453, text = "Primal Pests", faction = "Horde",
          coord = { map = 2022, x = 0.807, y = 0.276 } },  -- giver coord: ATT
        { type = "accept", questID = 65451, text = "Practice Materials", faction = "Horde",
          coord = { map = 2022, x = 0.806, y = 0.277 } },  -- giver coord: ATT
        { type = "quest", questID = 65452, text = "Explorers in Peril (objective 1)", faction = "Horde",
          coord = { map = 2022, x = 0.804, y = 0.264 } },  -- APR route coord (converted)
        { type = "quest", questID = 65452, text = "Explorers in Peril (objective 2)", faction = "Horde",
          coord = { map = 2022, x = 0.787, y = 0.244 } },  -- APR route coord (converted)
        { type = "quest", questID = 65452, text = "Explorers in Peril (objective 3)", faction = "Horde",
          coord = { map = 2022, x = 0.773, y = 0.299 } },  -- APR route coord (converted)
        { type = "quest", questID = 65451, text = "Practice Materials (objective 1)", faction = "Horde",
          coord = { map = 2022, x = 0.785, y = 0.308 } },  -- APR route coord (converted)
        { type = "quest", questID = 65453, text = "Primal Pests (objective 1)", faction = "Horde",
          coord = { map = 2022, x = 0.785, y = 0.308 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65452, text = "Turn in: Explorers in Peril", faction = "Horde",
          coord = { map = 2022, x = 0.766, y = 0.336 } },  -- APR route coord (converted)
        { type = "accept", questID = 69910, text = "Where is Wrathion?", faction = "Horde",
          coord = { map = 2022, x = 0.766, y = 0.336 } },  -- giver coord: ATT
        { type = "quest", questID = 69910, text = "Where is Wrathion? (objective 1)", faction = "Horde",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69910, text = "Turn in: Where is Wrathion?", faction = "Horde",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "accept", questID = 69911, text = "Excuse the Mess",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- giver coord: ATT
        { type = "turnin", questID = 70123, text = "Turn in: Primal Pests", faction = "Alliance",
          coord = { map = 2022, x = 0.767, y = 0.344 } },  -- APR route coord (converted)
        { type = "accept", questID = 67053, text = "Give Peace a Chance", faction = "Alliance",
          coord = { map = 2022, x = 0.767, y = 0.346 } },  -- giver coord: ATT
        { type = "turnin", questID = 70124, text = "Turn in: Practice Materials", faction = "Alliance",
          coord = { map = 2022, x = 0.765, y = 0.344 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67053, text = "Turn in: Give Peace a Chance", faction = "Alliance",
          coord = { map = 2022, x = 0.764, y = 0.331 } },  -- APR route coord (converted)
        { type = "accept", questID = 70135, text = "Encroaching Elementals", faction = "Alliance",
          coord = { map = 2022, x = 0.764, y = 0.331 } },  -- giver coord: ATT
        { type = "accept", questID = 66110, text = "Give Peace a Chance", faction = "Horde",
          coord = { map = 2022, x = 0.764, y = 0.331 } },  -- giver coord: ATT
        { type = "turnin", questID = 65453, text = "Turn in: Primal Pests", faction = "Horde",
          coord = { map = 2022, x = 0.763, y = 0.330 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65451, text = "Turn in: Practice Materials", faction = "Horde",
          coord = { map = 2022, x = 0.759, y = 0.332 } },  -- APR route coord (converted)
        { type = "accept", questID = 66101, text = "From Such Great Heights",
          coord = { map = 2022, x = 0.758, y = 0.330 } },  -- giver coord: ATT
        { type = "quest", questID = 66101, text = "From Such Great Heights (objective 1)",
          coord = { map = 2022, x = 0.759, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest", questID = 66101, text = "From Such Great Heights (objective 2)",
          coord = { map = 2022, x = 0.759, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest", questID = 66101, text = "From Such Great Heights (objective 3)",
          coord = { map = 2022, x = 0.759, y = 0.336 } },  -- APR route coord (converted)
        { type = "quest", questID = 66101, text = "From Such Great Heights (objective 4)",
          coord = { map = 2022, x = 0.759, y = 0.336 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66101, text = "Turn in: From Such Great Heights",
          coord = { map = 2022, x = 0.759, y = 0.335 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66110, text = "Turn in: Give Peace a Chance", faction = "Horde",
          coord = { map = 2022, x = 0.767, y = 0.346 } },  -- APR route coord (converted)
        { type = "accept", questID = 66111, text = "Encroaching Elementals", faction = "Horde",
          coord = { map = 2022, x = 0.767, y = 0.346 } },  -- giver coord: ATT
        { type = "accept", questID = 69965, text = "Quality Assurance",
          coord = { map = 2022, x = 0.764, y = 0.344 } },  -- giver coord: ATT
        { type = "accept", questID = 66112, text = "Always Be Crafting",
          coord = { map = 2022, x = 0.764, y = 0.346 } },  -- giver coord: ATT
        { type = "quest", questID = 69911, text = "Excuse the Mess (objective 1)",
          coord = { map = 2022, x = 0.763, y = 0.356 } },  -- APR route coord (converted)
        { type = "quest", questID = 69911, text = "Excuse the Mess (objective 2)",
          coord = { map = 2022, x = 0.763, y = 0.356 } },  -- APR route coord (converted)
        { type = "quest", questID = 69911, text = "Excuse the Mess (objective 3)",
          coord = { map = 2022, x = 0.756, y = 0.341 } },  -- APR route coord (converted)
        { type = "quest", questID = 69911, text = "Excuse the Mess (objective 4)",
          coord = { map = 2022, x = 0.784, y = 0.318 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69911, text = "Turn in: Excuse the Mess",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "accept", questID = 69912, text = "My First Real Emergency!",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- giver coord: ATT
        { type = "quest", questID = 69912, text = "My First Real Emergency! (objective 1)",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest", questID = 66112, text = "Always Be Crafting (objective 2)",
          coord = { map = 2022, x = 0.750, y = 0.393 } },  -- APR route coord (converted)
        { type = "quest", questID = 66112, text = "Always Be Crafting (objective 1)",
          coord = { map = 2022, x = 0.729, y = 0.330 } },  -- APR route coord (converted)
        { type = "quest", questID = 69965, text = "Quality Assurance (objective 1)",
          coord = { map = 2022, x = 0.748, y = 0.362 } },  -- APR route coord (converted)
        { type = "quest", questID = 70135, text = "Encroaching Elementals (objective 1)", faction = "Alliance",
          coord = { map = 2022, x = 0.748, y = 0.362 } },  -- APR route coord (converted)
        { type = "quest", questID = 66111, text = "Encroaching Elementals (objective 1)", faction = "Horde",
          coord = { map = 2022, x = 0.748, y = 0.362 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66112, text = "Turn in: Always Be Crafting",
          coord = { map = 2022, x = 0.764, y = 0.346 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69965, text = "Turn in: Quality Assurance",
          coord = { map = 2022, x = 0.764, y = 0.345 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70135, text = "Turn in: Encroaching Elementals", faction = "Alliance",
          coord = { map = 2022, x = 0.764, y = 0.331 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66111, text = "Turn in: Encroaching Elementals", faction = "Horde",
          coord = { map = 2022, x = 0.767, y = 0.346 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69912, text = "Turn in: My First Real Emergency!",
          coord = { map = 2022, x = 0.762, y = 0.345 } },  -- APR route coord (converted)
        -- ===== The Waking Shores: main campaign =====
        { type = "accept", questID = 69914, text = "The Djaradin Have Awoken",
          coord = { map = 2022, x = 0.766, y = 0.337 } },  -- giver coord: ATT
        { type = "quest", questID = 69914, text = "The Djaradin Have Awoken (objective 1)",
          coord = { map = 2022, x = 0.762, y = 0.345 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69914, text = "Turn in: The Djaradin Have Awoken",
          coord = { map = 2022, x = 0.763, y = 0.344 } },  -- APR route coord (converted)
        { type = "accept", questID = 65760, text = "Reporting for Duty",
          coord = { map = 2022, x = 0.763, y = 0.344 } },  -- giver coord: ATT
        { type = "quest", questID = 65760, text = "Reporting for Duty (objective 1)",
          coord = { map = 2022, x = 0.763, y = 0.344 } },  -- APR route coord (converted)
        { type = "quest", questID = 65760, text = "Reporting for Duty (objective 2)",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65760, text = "Turn in: Reporting for Duty",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- APR route coord (converted)
        { type = "accept", questID = 65989, text = "Invader Djaradin",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- giver coord: ATT
        { type = "accept", questID = 65990, text = "Deliver Whelps From Evil",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- giver coord: ATT
        { type = "quest", questID = 65990, text = "Deliver Whelps From Evil (objective 1)",
          coord = { map = 2022, x = 0.705, y = 0.447 } },  -- APR route coord (converted)
        { type = "quest", questID = 65989, text = "Invader Djaradin (objective 1)",
          coord = { map = 2022, x = 0.705, y = 0.447 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65989, text = "Turn in: Invader Djaradin",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65990, text = "Turn in: Deliver Whelps From Evil",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- APR route coord (converted)
        { type = "accept", questID = 65991, text = "Time for a Reckoning",
          coord = { map = 2022, x = 0.712, y = 0.408 } },  -- giver coord: ATT
        { type = "quest", questID = 65991, text = "Time for a Reckoning (objective 1)",
          coord = { map = 2022, x = 0.663, y = 0.347 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65991, text = "Turn in: Time for a Reckoning",
          coord = { map = 2022, x = 0.664, y = 0.349 } },  -- APR route coord (converted)
        { type = "accept", questID = 65993, text = "Killjoy",
          coord = { map = 2022, x = 0.664, y = 0.350 } },  -- giver coord: ATT
        { type = "accept", questID = 65992, text = "Blacktalon Intel",
          coord = { map = 2022, x = 0.664, y = 0.350 } },  -- giver coord: ATT
        { type = "quest", questID = 66956, text = "Dragonhunter Igordan (objective 1)",
          coord = { map = 2022, x = 0.642, y = 0.329 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "quest", questID = 65992, text = "Blacktalon Intel (objective 1)",
          coord = { map = 2022, x = 0.630, y = 0.333 } },  -- APR route coord (converted)
        { type = "quest", questID = 65993, text = "Killjoy (objective 1)",
          coord = { map = 2022, x = 0.629, y = 0.294 } },  -- APR route coord (converted)
        { type = "accept", questID = 65995, text = "The Obsidian Citadel",
          coord = { map = 2022, x = 0.631, y = 0.295 } },  -- giver coord: ATT
        { type = "quest", questID = 65992, text = "Blacktalon Intel (objective 2)",
          coord = { map = 2022, x = 0.634, y = 0.289 } },  -- APR route coord (converted)
        { type = "quest", questID = 65992, text = "Blacktalon Intel (objective 3)",
          coord = { map = 2022, x = 0.651, y = 0.293 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65993, text = "Turn in: Killjoy",
          coord = { map = 2022, x = 0.626, y = 0.331 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65992, text = "Turn in: Blacktalon Intel",
          coord = { map = 2022, x = 0.626, y = 0.331 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65995, text = "Turn in: The Obsidian Citadel",
          coord = { map = 2022, x = 0.626, y = 0.331 } },  -- APR route coord (converted)
        { type = "accept", questID = 65996, text = "Veteran Reinforcements",
          coord = { map = 2022, x = 0.627, y = 0.331 } },  -- giver coord: ATT
        { type = "quest", questID = 65994, text = "Djaradin Djustice (objective 1)",
          coord = { map = 2022, x = 0.639, y = 0.336 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "accept", questID = 66998, text = "Fighting Fire with... Water",
          coord = { map = 2022, x = 0.591, y = 0.348 } },  -- giver coord: ATT
        { type = "quest", questID = 66998, text = "Fighting Fire with... Water (objective 1)",
          coord = { map = 2022, x = 0.590, y = 0.326 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66998, text = "Turn in: Fighting Fire with... Water",
          coord = { map = 2022, x = 0.591, y = 0.349 } },  -- APR route coord (converted)
        { type = "quest", questID = 65996, text = "Veteran Reinforcements (objective 1)",
          coord = { map = 2022, x = 0.593, y = 0.344 } },  -- APR route coord (converted)
        { type = "quest", questID = 65996, text = "Veteran Reinforcements (objective 2)",
          coord = { map = 2022, x = 0.550, y = 0.308 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65996, text = "Turn in: Veteran Reinforcements",
          coord = { map = 2022, x = 0.550, y = 0.308 } },  -- APR route coord (converted)
        { type = "accept", questID = 65997, text = "Chasing Sendrax",
          coord = { map = 2022, x = 0.550, y = 0.308 } },  -- giver coord: ATT
        { type = "quest", questID = 65997, text = "Chasing Sendrax (objective 1)",
          coord = { map = 2022, x = 0.552, y = 0.249 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65997, text = "Turn in: Chasing Sendrax",
          coord = { map = 2022, x = 0.552, y = 0.249 } },  -- APR route coord (converted)
        { type = "accept", questID = 65998, text = "Future of the Flights",
          coord = { map = 2022, x = 0.552, y = 0.250 } },  -- giver coord: ATT
        { type = "accept", questID = 65999, text = "Red in Tooth and Claw",
          coord = { map = 2022, x = 0.552, y = 0.250 } },  -- giver coord: ATT
        { type = "accept", questID = 66000, text = "Library of Alexstrasza",
          coord = { map = 2022, x = 0.553, y = 0.247 } },  -- giver coord: ATT
        { type = "quest", questID = 65999, text = "Red in Tooth and Claw (objective 1)",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "quest", questID = 66000, text = "Library of Alexstrasza (objective 1)",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "quest", questID = 65998, text = "Future of the Flights (objective 1,2)",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65998, text = "Turn in: Future of the Flights",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65999, text = "Turn in: Red in Tooth and Claw",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66000, text = "Turn in: Library of Alexstrasza",
          coord = { map = 2022, x = 0.561, y = 0.229 } },  -- APR route coord (converted)
        { type = "accept", questID = 66001, text = "A Last Hope",
          coord = { map = 2022, x = 0.540, y = 0.228 } },  -- giver coord: ATT
        { type = "quest", questID = 66001, text = "A Last Hope (objective 1)",
          coord = { map = 2022, x = 0.563, y = 0.221 } },  -- APR route coord (converted)
        { type = "quest", questID = 66001, text = "A Last Hope (objective 2)",
          coord = { map = 2022, x = 0.569, y = 0.216 } },  -- APR route coord (converted)
        { type = "quest", questID = 66001, text = "A Last Hope (objective 3)",
          coord = { map = 2022, x = 0.550, y = 0.308 } },  -- APR route coord (converted)
        { type = "accept", questID = 70179, text = "A Two for One Deal",
          coord = { map = 2022, x = 0.544, y = 0.308 } },  -- giver coord: ATT
        { type = "quest", questID = 70179, text = "A Two for One Deal (objective 1)",
          coord = { map = 2022, x = 0.516, y = 0.322 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70179, text = "Turn in: A Two for One Deal",
          coord = { map = 2022, x = 0.544, y = 0.308 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66001, text = "Turn in: A Last Hope",
          coord = { map = 2022, x = 0.551, y = 0.310 } },  -- APR route coord (converted)
        { type = "accept", questID = 66114, text = "For the Benefit of the Queen",
          coord = { map = 2022, x = 0.551, y = 0.310 } },  -- giver coord: ATT
        { type = "quest", questID = 66114, text = "For the Benefit of the Queen (objective 1)",
          coord = { map = 2022, x = 0.623, y = 0.729 } },  -- APR route coord (converted)
        { type = "quest", questID = 66114, text = "For the Benefit of the Queen (objective 2)",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66114, text = "Turn in: For the Benefit of the Queen",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- APR route coord (converted)
        { type = "accept", questID = 66115, text = "The Mandate of the Red",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- giver coord: ATT
        { type = "accept", questID = 68795, text = "Skyriding",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- giver coord: ATT
        { type = "quest", questID = 66115, text = "The Mandate of the Red (objective 1)",
          coord = { map = 2022, x = 0.607, y = 0.740 } },  -- APR route coord (converted)
        { type = "quest", questID = 66115, text = "The Mandate of the Red (objective 2)",
          coord = { map = 2022, x = 0.594, y = 0.724 } },  -- APR route coord (converted)
        { type = "quest", questID = 68795, text = "Skyriding (objective 1)",
          coord = { map = 2022, x = 0.584, y = 0.671 } },  -- APR route coord (converted)
        { type = "accept", questID = 70132, text = "Stay a While",
          coord = { map = 2022, x = 0.578, y = 0.668 } },  -- giver coord: ATT
        { type = "quest", questID = 70132, text = "Stay a While (objective 1)",
          coord = { map = 2022, x = 0.578, y = 0.668 } },  -- APR route coord (converted)
        { type = "quest", questID = 70132, text = "Stay a While (objective 1)",
          coord = { map = 2022, x = 0.578, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70132, text = "Turn in: Stay a While",
          coord = { map = 2022, x = 0.578, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 68795, text = "Turn in: Skyriding",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- APR route coord (converted)
        { type = "accept", questID = 65118, text = "How to Glide with Your Dragon",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- giver coord: ATT
        { type = "quest", questID = 65118, text = "How to Glide with Your Dragon (objective 2)",
          coord = { map = 2022, x = 0.577, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 65118, text = "How to Glide with Your Dragon (objective 3)",
          coord = { map = 2022, x = 0.575, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65118, text = "Turn in: How to Glide with Your Dragon",
          coord = { map = 2022, x = 0.575, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 65120, text = "How to Dive with Your Dragon",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- giver coord: ATT
        { type = "quest", questID = 65120, text = "How to Dive with Your Dragon (objective 2)",
          coord = { map = 2022, x = 0.577, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 65120, text = "How to Dive with Your Dragon (objective 3)",
          coord = { map = 2022, x = 0.575, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65120, text = "Turn in: How to Dive with Your Dragon",
          coord = { map = 2022, x = 0.575, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 65133, text = "How to Use Momentum with Your Dragon",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- giver coord: ATT
        { type = "quest", questID = 65133, text = "How to Use Momentum with Your Dragon (objective 2)",
          coord = { map = 2022, x = 0.577, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 65133, text = "How to Use Momentum with Your Dragon (objective 3)",
          coord = { map = 2022, x = 0.575, y = 0.593 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65133, text = "Turn in: How to Use Momentum with Your Dragon",
          coord = { map = 2022, x = 0.575, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 77345, text = "The Need For Higher Velocities",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- giver coord: ATT
        { type = "turnin", questID = 77345, text = "Turn in: The Need For Higher Velocities",
          coord = { map = 2022, x = 0.575, y = 0.591 } },  -- UNVERIFIED: ender Celormu (Wowhead); APR has no coord; landing ledge ~57,59 per Wowhead comment = 65133 turn-in spot
        { type = "accept", questID = 68796, text = "The Skytop Observatory",
          coord = { map = 2022, x = 0.577, y = 0.669 } },  -- giver coord: ATT
        { type = "quest", questID = 68796, text = "The Skytop Observatory (objective 1)",
          coord = { map = 2022, x = 0.577, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 68796, text = "The Skytop Observatory (objective 2)",
          coord = { map = 2022, x = 0.577, y = 0.667 } },  -- APR route coord (converted)
        { type = "turnin", questID = 68796, text = "Turn in: The Skytop Observatory",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- APR route coord (converted)
        { type = "accept", questID = 68797, text = "A New Set of Horns",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- giver coord: ATT
        { type = "quest", questID = 68797, text = "A New Set of Horns (objective 1)",
          coord = { map = 2022, x = 0.741, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest", questID = 68797, text = "A New Set of Horns (objective 2)",
          coord = { map = 2022, x = 0.740, y = 0.581 } },  -- APR route coord (converted)
        { type = "turnin", questID = 68797, text = "Turn in: A New Set of Horns",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- APR route coord (converted)
        { type = "accept", questID = 68798, text = "Skyriding Talents and You",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- giver coord: ATT
        { type = "quest", questID = 68798, text = "Skyriding Talents and You (objective 1)",
          coord = { map = 2022, x = 0.743, y = 0.576 } },  -- APR route coord (converted)
        { type = "quest", questID = 68798, text = "Skyriding Talents and You (objective 2)",
          coord = { map = 2022, x = 0.746, y = 0.570 } },  -- APR route coord (converted)
        { type = "quest", questID = 68798, text = "Skyriding Talents and You (objective 3)",
          coord = { map = 2022, x = 0.746, y = 0.570 } },  -- APR route coord (converted)
        { type = "quest", questID = 68798, text = "Skyriding Talents and You (objective 4)",
          coord = { map = 2022, x = 0.746, y = 0.570 } },  -- APR route coord (converted)
        { type = "quest", questID = 68798, text = "Skyriding Talents and You (objective 5)",
          coord = { map = 2022, x = 0.732, y = 0.521 } },  -- APR route coord (converted)
        { type = "turnin", questID = 68798, text = "Turn in: Skyriding Talents and You",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- APR route coord (converted)
        { type = "accept", questID = 68799, text = "Return to the Ruby Lifeshrine",
          coord = { map = 2022, x = 0.752, y = 0.550 } },  -- giver coord: ATT
        { type = "quest", questID = 68799, text = "Return to the Ruby Lifeshrine (objective 1)",
          coord = { map = 2022, x = 0.750, y = 0.556 } },  -- APR route coord (converted)
        { type = "quest", questID = 68799, text = "Return to the Ruby Lifeshrine (objective 1)",
          coord = { map = 2022, x = 0.752, y = 0.571 } },  -- APR route coord (converted)
        { type = "quest", questID = 66115, text = "The Mandate of the Red (objective 3)",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- APR route coord (converted)
        { type = "quest", questID = 66115, text = "The Mandate of the Red (objective 4)",
          coord = { map = 2022, x = 0.628, y = 0.704 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66115, text = "Turn in: The Mandate of the Red",
          coord = { map = 2022, x = 0.628, y = 0.704 } },  -- APR route coord (converted)
        { type = "accept", questID = 70061, text = "Training Wings",
          coord = { map = 2022, x = 0.622, y = 0.705 } },  -- giver coord: ATT
        { type = "quest", questID = 70061, text = "Training Wings (objective 1)",
          coord = { map = 2022, x = 0.611, y = 0.715 } },  -- APR route coord (converted)
        { type = "quest", questID = 70061, text = "Training Wings (objective 2,3,4)",
          coord = { map = 2022, x = 0.614, y = 0.718 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70061, text = "Turn in: Training Wings",
          coord = { map = 2022, x = 0.623, y = 0.729 } },  -- APR route coord (converted)
        { type = "turnin", questID = 68799, text = "Turn in: Return to the Ruby Lifeshrine",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- APR route coord (converted)
        { type = "accept", questID = 66931, text = "Who Brought the Ruckus?",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- giver coord: ATT
        { type = "quest", questID = 66931, text = "Who Brought the Ruckus? (objective 1)",
          coord = { map = 2022, x = 0.595, y = 0.726 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66931, text = "Turn in: Who Brought the Ruckus?",
          coord = { map = 2022, x = 0.595, y = 0.726 } },  -- APR route coord (converted)
        { type = "accept", questID = 66116, text = "The Primary Threat",
          coord = { map = 2022, x = 0.595, y = 0.726 } },  -- giver coord: ATT
        { type = "quest", questID = 66116, text = "The Primary Threat (objective 2)",
          coord = { map = 2022, x = 0.594, y = 0.759 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66116, text = "Turn in: The Primary Threat",
          coord = { map = 2022, x = 0.594, y = 0.759 } },  -- APR route coord (converted)
        { type = "accept", questID = 66118, text = "Basalt Assault",
          coord = { map = 2022, x = 0.595, y = 0.759 } },  -- giver coord: ATT
        { type = "quest", questID = 66118, text = "Basalt Assault (objective 1)",
          coord = { map = 2022, x = 0.596, y = 0.780 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66118, text = "Turn in: Basalt Assault",
          coord = { map = 2022, x = 0.594, y = 0.759 } },  -- APR route coord (converted)
        { type = "accept", questID = 66122, text = "Proto-Fight",
          coord = { map = 2022, x = 0.595, y = 0.759 } },  -- giver coord: ATT
        { type = "accept", questID = 66121, text = "Egg Evac",
          coord = { map = 2022, x = 0.595, y = 0.761 } },  -- giver coord: ATT
        { type = "quest", questID = 66121, text = "Egg Evac (objective 1)",
          coord = { map = 2022, x = 0.561, y = 0.813 } },  -- APR route coord (converted)
        { type = "quest", questID = 66121, text = "Egg Evac (objective 4)",
          coord = { map = 2022, x = 0.550, y = 0.810 } },  -- APR route coord (converted)
        { type = "quest", questID = 66121, text = "Egg Evac (objective 3)",
          coord = { map = 2022, x = 0.553, y = 0.833 } },  -- APR route coord (converted)
        { type = "quest", questID = 66960, text = "Klozicc the Ascended (objective 1)",
          coord = { map = 2022, x = 0.548, y = 0.822 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "quest", questID = 66121, text = "Egg Evac (objective 2)",
          coord = { map = 2022, x = 0.573, y = 0.833 } },  -- APR route coord (converted)
        { type = "quest", questID = 66122, text = "Proto-Fight (objective 2)",
          coord = { map = 2022, x = 0.557, y = 0.815 } },  -- APR route coord (converted)
        { type = "quest", questID = 66117, text = "Clear the Battlefield (objective 1)",
          coord = { map = 2022, x = 0.557, y = 0.815 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 66122, text = "Turn in: Proto-Fight",
          coord = { map = 2022, x = 0.537, y = 0.801 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66121, text = "Turn in: Egg Evac",
          coord = { map = 2022, x = 0.537, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 66123, text = "Cut Off the Head",
          coord = { map = 2022, x = 0.537, y = 0.802 } },  -- giver coord: ATT
        { type = "quest", questID = 66123, text = "Cut Off the Head (objective 1)",
          coord = { map = 2022, x = 0.536, y = 0.830 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66123, text = "Turn in: Cut Off the Head",
          coord = { map = 2022, x = 0.537, y = 0.801 } },  -- APR route coord (converted)
        { type = "accept", questID = 66124, text = "Exeunt, Triumphant",
          coord = { map = 2022, x = 0.537, y = 0.802 } },  -- giver coord: ATT
        { type = "accept", questID = 66963, text = "Out For Delivery",
          coord = { map = 2022, x = 0.485, y = 0.789 } },  -- giver coord: ATT
        { type = "turnin", questID = 66963, text = "Turn in: Out For Delivery",
          coord = { map = 2022, x = 0.485, y = 0.827 } },  -- APR route coord (converted)
        { type = "accept", questID = 66524, text = "Amateur Protography",
          coord = { map = 2022, x = 0.485, y = 0.827 } },  -- giver coord: ATT
        { type = "quest", questID = 66524, text = "Amateur Protography (objective 1)",
          coord = { map = 2022, x = 0.454, y = 0.821 } },  -- APR route coord (converted)
        { type = "quest", questID = 66524, text = "Amateur Protography (objective 2)",
          coord = { map = 2022, x = 0.439, y = 0.817 } },  -- APR route coord (converted)
        { type = "quest", questID = 66524, text = "Amateur Protography (objective 3)",
          coord = { map = 2022, x = 0.441, y = 0.785 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66524, text = "Turn in: Amateur Protography",
          coord = { map = 2022, x = 0.390, y = 0.832 } },  -- APR route coord (converted)
        { type = "accept", questID = 66525, text = "Competitive Protography",
          coord = { map = 2022, x = 0.390, y = 0.832 } },  -- giver coord: ATT
        { type = "accept", questID = 66526, text = "Preserving the Wilds",
          coord = { map = 2022, x = 0.391, y = 0.833 } },  -- giver coord: ATT
        { type = "quest", questID = 66525, text = "Competitive Protography (objective 1)",
          coord = { map = 2022, x = 0.383, y = 0.808 } },  -- APR route coord (converted)
        { type = "quest", questID = 66525, text = "Competitive Protography (objective 2)",
          coord = { map = 2022, x = 0.385, y = 0.812 } },  -- APR route coord (converted)
        { type = "quest", questID = 66526, text = "Preserving the Wilds (objective 1)",
          coord = { map = 2022, x = 0.385, y = 0.812 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66525, text = "Turn in: Competitive Protography",
          coord = { map = 2022, x = 0.390, y = 0.832 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66526, text = "Turn in: Preserving the Wilds",
          coord = { map = 2022, x = 0.391, y = 0.833 } },  -- APR route coord (converted)
        { type = "accept", questID = 66527, text = "Professional Protography",
          coord = { map = 2022, x = 0.390, y = 0.832 } },  -- giver coord: ATT
        { type = "quest", questID = 66527, text = "Professional Protography (objective 1)",
          coord = { map = 2022, x = 0.389, y = 0.834 } },  -- APR route coord (converted)
        { type = "quest", questID = 66527, text = "Professional Protography (objective 2)",
          coord = { map = 2022, x = 0.388, y = 0.840 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66527, text = "Turn in: Professional Protography",
          coord = { map = 2022, x = 0.390, y = 0.832 } },  -- APR route coord (converted)
        { type = "accept", questID = 66528, text = "King Without a Crown",
          coord = { map = 2022, x = 0.391, y = 0.833 } },  -- giver coord: ATT
        { type = "quest", questID = 66528, text = "King Without a Crown (objective 2)",
          coord = { map = 2022, x = 0.388, y = 0.835 } },  -- APR route coord (converted)
        { type = "quest", questID = 66528, text = "King Without a Crown (objective 1)",
          coord = { map = 2022, x = 0.391, y = 0.839 } },  -- APR route coord (converted)
        { type = "quest", questID = 66528, text = "King Without a Crown (objective 3)",
          coord = { map = 2022, x = 0.394, y = 0.840 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66528, text = "Turn in: King Without a Crown",
          coord = { map = 2022, x = 0.391, y = 0.833 } },  -- APR route coord (converted)
        { type = "accept", questID = 66529, text = "A Thousand Words",
          coord = { map = 2022, x = 0.391, y = 0.833 } },  -- giver coord: ATT
        { type = "quest", questID = 66529, text = "A Thousand Words (objective 1)",
          coord = { map = 2022, x = 0.389, y = 0.836 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66529, text = "Turn in: A Thousand Words",
          coord = { map = 2022, x = 0.387, y = 0.837 } },  -- APR route coord (converted)
        { type = "quest", questID = 66124, text = "Exeunt, Triumphant (objective 1)",
          coord = { map = 2022, x = 0.462, y = 0.784 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66124, text = "Turn in: Exeunt, Triumphant",
          coord = { map = 2022, x = 0.462, y = 0.784 } },  -- APR route coord (converted)
        { type = "accept", questID = 66079, text = "Wrathion Awaits",
          coord = { map = 2022, x = 0.461, y = 0.783 } },  -- giver coord: ATT
        { type = "turnin", questID = 66079, text = "Turn in: Wrathion Awaits",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- APR route coord (converted)
        { type = "accept", questID = 72241, text = "Lessons From Our Past",
          coord = { map = 2022, x = 0.424, y = 0.668 } },  -- giver coord: ATT
        { type = "quest", questID = 72241, text = "Lessons From Our Past (objective 1)",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 72241, text = "Turn in: Lessons From Our Past",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- APR route coord (converted)
        { type = "accept", questID = 66048, text = "Best Plans and Intentions",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- giver coord: ATT
        { type = "accept", questID = 66078, text = "Sharp Practice",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- giver coord: ATT
        { type = "quest", questID = 66048, text = "Best Plans and Intentions (objective 1)",
          coord = { map = 2022, x = 0.424, y = 0.662 } },  -- APR route coord (converted)
        { type = "quest", questID = 66048, text = "Best Plans and Intentions (objective 4)",
          coord = { map = 2022, x = 0.429, y = 0.670 } },  -- APR route coord (converted)
        { type = "quest", questID = 66048, text = "Best Plans and Intentions (objective 2)",
          coord = { map = 2022, x = 0.438, y = 0.673 } },  -- APR route coord (converted)
        { type = "quest", questID = 66048, text = "Best Plans and Intentions (objective 3)",
          coord = { map = 2022, x = 0.423, y = 0.693 } },  -- APR route coord (converted)
        { type = "quest", questID = 66078, text = "Sharp Practice (objective 1)",
          coord = { map = 2022, x = 0.427, y = 0.673 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66078, text = "Turn in: Sharp Practice",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66048, text = "Turn in: Best Plans and Intentions",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- APR route coord (converted)
        { type = "accept", questID = 65956, text = "Talon Strike",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- giver coord: ATT
        { type = "accept", questID = 65957, text = "No Time for Heroes",
          coord = { map = 2022, x = 0.425, y = 0.668 } },  -- giver coord: ATT
        { type = "quest", questID = 65957, text = "No Time for Heroes (objective 1)",
          coord = { map = 2022, x = 0.356, y = 0.686 } },  -- APR route coord (converted)
        { type = "quest", questID = 65957, text = "No Time for Heroes (objective 3)",
          coord = { map = 2022, x = 0.348, y = 0.670 } },  -- APR route coord (converted)
        { type = "quest", questID = 65957, text = "No Time for Heroes (objective 2)",
          coord = { map = 2022, x = 0.356, y = 0.607 } },  -- APR route coord (converted)
        { type = "quest", questID = 65956, text = "Talon Strike (objective 1)",
          coord = { map = 2022, x = 0.354, y = 0.659 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65956, text = "Turn in: Talon Strike",
          coord = { map = 2022, x = 0.340, y = 0.613 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65957, text = "Turn in: No Time for Heroes",
          coord = { map = 2022, x = 0.340, y = 0.613 } },  -- APR route coord (converted)
        { type = "accept", questID = 65939, text = "The Courage of One's Convictions",
          coord = { map = 2022, x = 0.340, y = 0.613 } },  -- giver coord: ATT
        { type = "quest", questID = 65939, text = "The Courage of One's Convictions (objective 1)",
          coord = { map = 2022, x = 0.340, y = 0.613 } },  -- APR route coord (converted)
        { type = "quest", questID = 65939, text = "The Courage of One's Convictions (objective 2)",
          coord = { map = 2022, x = 0.305, y = 0.608 } },  -- APR route coord (converted)
        { type = "accept", questID = 66044, text = "Taking the Walls",
          coord = { map = 2022, x = 0.292, y = 0.588 } },  -- giver coord: ATT
        { type = "quest", questID = 66044, text = "Taking the Walls (objective 1)",
          coord = { map = 2022, x = 0.292, y = 0.588 } },  -- APR route coord (converted)
        { type = "quest", questID = 66044, text = "Taking the Walls (objective 2)",
          coord = { map = 2022, x = 0.268, y = 0.599 } },  -- APR route coord (converted)
        { type = "quest", questID = 66044, text = "Taking the Walls (objective 3)",
          coord = { map = 2022, x = 0.295, y = 0.610 } },  -- APR route coord (converted)
        { type = "quest", questID = 66044, text = "Taking the Walls (objective 4)",
          coord = { map = 2022, x = 0.278, y = 0.567 } },  -- APR route coord (converted)
        { type = "quest", questID = 66044, text = "Taking the Walls (objective 5)",
          coord = { map = 2022, x = 0.269, y = 0.572 } },  -- APR route coord (converted)
        { type = "quest", questID = 65939, text = "The Courage of One's Convictions (objective 3)",
          coord = { map = 2022, x = 0.265, y = 0.580 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65939, text = "Turn in: The Courage of One's Convictions",
          coord = { map = 2022, x = 0.264, y = 0.588 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66044, text = "Turn in: Taking the Walls",
          coord = { map = 2022, x = 0.264, y = 0.588 } },  -- APR route coord (converted)
        { type = "accept", questID = 66049, text = "Obsidian Oathstone",
          coord = { map = 2022, x = 0.264, y = 0.588 } },  -- giver coord: ATT
        { type = "quest", questID = 66049, text = "Obsidian Oathstone (objective 1)",
          coord = { map = 2022, x = 0.273, y = 0.626 } },  -- APR route coord (converted)
        { type = "quest", questID = 66049, text = "Obsidian Oathstone (objective 2)",
          coord = { map = 2022, x = 0.276, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66049, text = "Turn in: Obsidian Oathstone",
          coord = { map = 2022, x = 0.273, y = 0.626 } },  -- APR route coord (converted)
        { type = "accept", questID = 66055, text = "A Shattered Past",
          coord = { map = 2022, x = 0.273, y = 0.628 } },  -- giver coord: ATT
        { type = "quest", questID = 66055, text = "A Shattered Past (objective 1)",
          coord = { map = 2022, x = 0.272, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest", questID = 66055, text = "A Shattered Past (objective 2)",
          coord = { map = 2022, x = 0.246, y = 0.581 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66055, text = "Turn in: A Shattered Past",
          coord = { map = 2022, x = 0.273, y = 0.628 } },  -- APR route coord (converted)
        { type = "accept", questID = 66056, text = "Forging a New Future",
          coord = { map = 2022, x = 0.273, y = 0.628 } },  -- giver coord: ATT
        { type = "quest", questID = 66056, text = "Forging a New Future (objective 1)",
          coord = { map = 2022, x = 0.246, y = 0.609 } },  -- APR route coord (converted)
        { type = "quest", questID = 66056, text = "Forging a New Future (objective 2)",
          coord = { map = 2022, x = 0.250, y = 0.611 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66056, text = "Turn in: Forging a New Future",
          coord = { map = 2022, x = 0.247, y = 0.611 } },  -- APR route coord (converted)
        { type = "accept", questID = 66354, text = "The Spark",
          coord = { map = 2022, x = 0.247, y = 0.611 } },  -- giver coord: ATT
        { type = "quest", questID = 66354, text = "The Spark (objective 1)",
          coord = { map = 2022, x = 0.246, y = 0.610 } },  -- APR route coord (converted)
        { type = "quest", questID = 66354, text = "The Spark (objective 3)",
          coord = { map = 2022, x = 0.246, y = 0.610 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66354, text = "Turn in: The Spark",
          coord = { map = 2022, x = 0.247, y = 0.611 } },  -- APR route coord (converted)
        { type = "accept", questID = 66057, text = "Restoring the Faith",
          coord = { map = 2022, x = 0.247, y = 0.611 } },  -- giver coord: ATT
        { type = "quest", questID = 66057, text = "Restoring the Faith (objective 1)",
          coord = { map = 2022, x = 0.273, y = 0.626 } },  -- APR route coord (converted)
        { type = "quest", questID = 66057, text = "Restoring the Faith (objective 2)",
          coord = { map = 2022, x = 0.271, y = 0.622 } },  -- APR route coord (converted)
        { type = "quest", questID = 66057, text = "Restoring the Faith (objective 3)",
          coord = { map = 2022, x = 0.253, y = 0.566 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66057, text = "Turn in: Restoring the Faith",
          coord = { map = 2022, x = 0.244, y = 0.555 } },  -- APR route coord (converted)
        { type = "accept", questID = 66780, text = "Claimant to the Throne",
          coord = { map = 2022, x = 0.244, y = 0.555 } },  -- giver coord: ATT
        { type = "accept", questID = 66779, text = "Heir Apparent",
          coord = { map = 2022, x = 0.242, y = 0.559 } },  -- giver coord: ATT
        { type = "quest", questID = 66780, text = "Claimant to the Throne (objective 2)",
          coord = { map = 2022, x = 0.250, y = 0.552 } },  -- APR route coord (converted)
        { type = "quest", questID = 66780, text = "Claimant to the Throne (objective 1)",
          coord = { map = 2022, x = 0.264, y = 0.545 } },  -- APR route coord (converted)
        { type = "quest", questID = 66779, text = "Heir Apparent (objective 3)",
          coord = { map = 2022, x = 0.251, y = 0.562 } },  -- APR route coord (converted)
        { type = "quest", questID = 66780, text = "Claimant to the Throne (objective 3)",
          coord = { map = 2022, x = 0.251, y = 0.562 } },  -- APR route coord (converted)
        { type = "quest", questID = 66779, text = "Heir Apparent (objective 2)",
          coord = { map = 2022, x = 0.244, y = 0.578 } },  -- APR route coord (converted)
        { type = "quest", questID = 66779, text = "Heir Apparent (objective 1)",
          coord = { map = 2022, x = 0.243, y = 0.589 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66779, text = "Turn in: Heir Apparent",
          coord = { map = 2022, x = 0.243, y = 0.558 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66780, text = "Turn in: Claimant to the Throne",
          coord = { map = 2022, x = 0.244, y = 0.555 } },  -- APR route coord (converted)
        { type = "accept", questID = 65793, text = "Black Wagon Flight",
          coord = { map = 2022, x = 0.242, y = 0.559 } },  -- giver coord: ATT
        { type = "quest", questID = 65793, text = "Black Wagon Flight (objective 2)",
          coord = { map = 2022, x = 0.438, y = 0.664 } },  -- APR route coord (converted)
        { type = "quest", questID = 65793, text = "Black Wagon Flight (objective 3)",
          coord = { map = 2022, x = 0.519, y = 0.668 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65793, text = "Turn in: Black Wagon Flight",
          coord = { map = 2022, x = 0.580, y = 0.673 } },  -- APR route coord (converted)
        { type = "accept", questID = 66785, text = "The Last Eggtender",
          coord = { map = 2022, x = 0.580, y = 0.673 } },  -- giver coord: ATT
        { type = "turnin", questID = 66785, text = "Turn in: The Last Eggtender",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- APR route coord (converted)
        { type = "accept", questID = 66788, text = "Egg-cited for the Future",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- giver coord: ATT
        { type = "quest", questID = 66788, text = "Egg-cited for the Future (objective 1,2,3)",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66788, text = "Turn in: Egg-cited for the Future",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- APR route coord (converted)
        { type = "accept", questID = 65791, text = "Life-Binder on Duty",
          coord = { map = 2022, x = 0.616, y = 0.687 } },  -- giver coord: ATT
        { type = "turnin", questID = 65791, text = "Turn in: Life-Binder on Duty",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- APR route coord (converted)
        { type = "accept", questID = 65794, text = "A Charge of Care",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- giver coord: ATT
        { type = "quest", questID = 65794, text = "A Charge of Care (objective 1)",
          coord = { map = 2022, x = 0.623, y = 0.730 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65794, text = "Turn in: A Charge of Care",
          coord = { map = 2022, x = 0.616, y = 0.686 } },  -- APR route coord (converted)
        { type = "accept", questID = 65795, text = "Next Steppes",
          coord = { map = 2022, x = 0.616, y = 0.686 } },  -- giver coord: ATT
        { type = "turnin", questID = 65795, text = "Turn in: Next Steppes",
          coord = { map = 2022, x = 0.483, y = 0.887 } },  -- APR route coord (converted)
        { type = "accept", questID = 65779, text = "Into the Plains",
          coord = { map = 2022, x = 0.483, y = 0.887 } },  -- giver coord: ATT
        -- ===== Ohn'ahran Plains =====
        { type = "turnin", questID = 65779, text = "Turn in: Into the Plains",
          coord = { map = 2023, x = 0.777, y = 0.237 } },  -- APR route coord (converted)
        { type = "accept", questID = 65780, text = "Proving Oneself",
          coord = { map = 2023, x = 0.777, y = 0.239 } },  -- giver coord: ATT
        { type = "quest", questID = 65780, text = "Proving Oneself (objective 1)",
          coord = { map = 2023, x = 0.784, y = 0.267 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65780, text = "Turn in: Proving Oneself",
          coord = { map = 2023, x = 0.786, y = 0.254 } },  -- APR route coord (converted)
        { type = "accept", questID = 65783, text = "Welcome at Our Fire",
          coord = { map = 2023, x = 0.786, y = 0.254 } },  -- giver coord: ATT
        { type = "turnin", questID = 65783, text = "Turn in: Welcome at Our Fire",
          coord = { map = 2023, x = 0.853, y = 0.254 } },  -- APR route coord (converted)
        { type = "accept", questID = 70174, text = "The Shikaar",
          coord = { map = 2023, x = 0.853, y = 0.254 } },  -- giver coord: ATT
        { type = "quest", questID = 70174, text = "The Shikaar (objective 1)",
          coord = { map = 2023, x = 0.857, y = 0.253 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70174, text = "Turn in: The Shikaar",
          coord = { map = 2023, x = 0.857, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 65801, text = "Making Introductions",
          coord = { map = 2023, x = 0.857, y = 0.253 } },  -- giver coord: ATT
        { type = "accept", questID = 65802, text = "Supplies for the Journey",
          coord = { map = 2023, x = 0.857, y = 0.253 } },  -- giver coord: ATT
        { type = "quest", questID = 65801, text = "Making Introductions (objective 1)",
          coord = { map = 2023, x = 0.856, y = 0.209 } },  -- APR route coord (converted)
        { type = "accept", questID = 65951, text = "Sole Supplier",
          coord = { map = 2023, x = 0.844, y = 0.250 } },  -- giver coord: ATT
        { type = "accept", questID = 65950, text = "Thieving Gorlocs",
          coord = { map = 2023, x = 0.844, y = 0.250 } },  -- giver coord: ATT
        { type = "quest", questID = 65801, text = "Making Introductions (objective 3)",
          coord = { map = 2023, x = 0.839, y = 0.259 } },  -- APR route coord (converted)
        { type = "quest", questID = 65801, text = "Making Introductions (objective 2)",
          coord = { map = 2023, x = 0.857, y = 0.266 } },  -- APR route coord (converted)
        { type = "quest", questID = 65802, text = "Supplies for the Journey (objective 1,2)",
          coord = { map = 2023, x = 0.848, y = 0.248 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65802, text = "Turn in: Supplies for the Journey",
          coord = { map = 2023, x = 0.847, y = 0.228 } },  -- APR route coord (converted)
        { type = "accept", questID = 65803, text = "Toward the City",
          coord = { map = 2023, x = 0.847, y = 0.229 } },  -- giver coord: ATT
        { type = "quest", questID = 65803, text = "Toward the City (objective 1)",
          coord = { map = 2023, x = 0.832, y = 0.237 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65951, text = "Turn in: Sole Supplier",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- APR route coord (converted)
        { type = "quest", questID = 65950, text = "Thieving Gorlocs (objective 1)",
          coord = { map = 2023, x = 0.816, y = 0.308 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65950, text = "Turn in: Thieving Gorlocs",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- APR route coord (converted)
        { type = "accept", questID = 65953, text = "The Ora-cull",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- giver coord: ATT
        { type = "accept", questID = 65954, text = "Release the Hounds",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- giver coord: ATT
        { type = "accept", questID = 65955, text = "A Centaur's Best Friend",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- giver coord: ATT
        { type = "quest", questID = 65955, text = "A Centaur's Best Friend (objective 1)",
          coord = { map = 2023, x = 0.806, y = 0.307 } },  -- APR route coord (converted)
        { type = "quest", questID = 65954, text = "Release the Hounds (objective 1)",
          coord = { map = 2023, x = 0.816, y = 0.309 } },  -- APR route coord (converted)
        { type = "quest", questID = 65953, text = "The Ora-cull (objective 1)",
          coord = { map = 2023, x = 0.816, y = 0.309 } },  -- APR route coord (converted)
        { type = "quest", questID = 65955, text = "A Centaur's Best Friend (objective 2)",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65953, text = "Turn in: The Ora-cull",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65954, text = "Turn in: Release the Hounds",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65955, text = "Turn in: A Centaur's Best Friend",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "accept", questID = 65952, text = "A Chief of Legends",
          coord = { map = 2023, x = 0.834, y = 0.323 } },  -- giver coord: ATT
        { type = "quest", questID = 65952, text = "A Chief of Legends (objective 1)",
          coord = { map = 2023, x = 0.820, y = 0.313 } },  -- APR route coord (converted)
        { type = "accept", questID = 66005, text = "Medallion of a Fallen Friend",
          coord = { map = 2023, x = 0.820, y = 0.314 } },  -- giver coord: ATT
        { type = "turnin", questID = 65952, text = "Turn in: A Chief of Legends",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66005, text = "Turn in: Medallion of a Fallen Friend",
          coord = { map = 2023, x = 0.834, y = 0.324 } },  -- APR route coord (converted)
        { type = "accept", questID = 65949, text = "The Sole Mender",
          coord = { map = 2023, x = 0.834, y = 0.323 } },  -- giver coord: ATT
        { type = "accept", questID = 66006, text = "Return to Roscha",
          coord = { map = 2023, x = 0.834, y = 0.323 } },  -- giver coord: ATT
        { type = "quest", questID = 66006, text = "Return to Roscha (objective 1)",
          coord = { map = 2023, x = 0.835, y = 0.322 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66006, text = "Turn in: Return to Roscha",
          coord = { map = 2023, x = 0.844, y = 0.250 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65949, text = "Turn in: The Sole Mender",
          coord = { map = 2023, x = 0.844, y = 0.250 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65803, text = "Turn in: Toward the City",
          coord = { map = 2023, x = 0.757, y = 0.317 } },  -- APR route coord (converted)
        { type = "accept", questID = 65804, text = "For Food and Rivalry",
          coord = { map = 2023, x = 0.757, y = 0.317 } },  -- giver coord: ATT
        { type = "accept", questID = 70185, text = "Mysterious Beast",
          coord = { map = 2023, x = 0.767, y = 0.319 } },  -- giver coord: ATT
        { type = "quest", questID = 70185, text = "Mysterious Beast (objective 1)",
          coord = { map = 2023, x = 0.777, y = 0.354 } },  -- APR route coord (converted)
        { type = "quest", questID = 65804, text = "For Food and Rivalry (objective 1)",
          coord = { map = 2023, x = 0.775, y = 0.317 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65804, text = "Turn in: For Food and Rivalry",
          coord = { map = 2023, x = 0.757, y = 0.317 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70185, text = "Turn in: Mysterious Beast",
          coord = { map = 2023, x = 0.757, y = 0.317 } },  -- APR route coord (converted)
        { type = "accept", questID = 65940, text = "By Broken Road",
          coord = { map = 2023, x = 0.757, y = 0.317 } },  -- giver coord: ATT
        { type = "turnin", questID = 65940, text = "Turn in: By Broken Road",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- APR route coord (converted)
        { type = "accept", questID = 65805, text = "Connection to Ohn'ahra",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- giver coord: ATT
        { type = "quest", questID = 65805, text = "Connection to Ohn'ahra (objective 1,2,3)",
          coord = { map = 2023, x = 0.696, y = 0.380 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65805, text = "Turn in: Connection to Ohn'ahra",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- APR route coord (converted)
        { type = "accept", questID = 66848, text = "Omens on the Wind",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- giver coord: ATT
        { type = "quest", questID = 66848, text = "Omens on the Wind (objective 1)",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- APR route coord (converted)
        { type = "quest", questID = 66848, text = "Omens on the Wind (objective 2)",
          coord = { map = 2023, x = 0.699, y = 0.376 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66848, text = "Turn in: Omens on the Wind",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- APR route coord (converted)
        { type = "accept", questID = 65806, text = "Maruukai",
          coord = { map = 2023, x = 0.700, y = 0.380 } },  -- giver coord: ATT
        { type = "turnin", questID = 65806, text = "Turn in: Maruukai",
          coord = { map = 2023, x = 0.615, y = 0.396 } },  -- APR route coord (converted)
        { type = "accept", questID = 66018, text = "Clan Nokhud",
          coord = { map = 2023, x = 0.614, y = 0.395 } },  -- giver coord: ATT
        { type = "accept", questID = 66017, text = "Clan Ohn'ir",
          coord = { map = 2023, x = 0.614, y = 0.395 } },  -- giver coord: ATT
        { type = "accept", questID = 66016, text = "Clan Teerai",
          coord = { map = 2023, x = 0.614, y = 0.395 } },  -- giver coord: ATT
        { type = "turnin", questID = 66017, text = "Turn in: Clan Ohn'ir",
          coord = { map = 2023, x = 0.630, y = 0.337 } },  -- APR route coord (converted)
        { type = "accept", questID = 66020, text = "Omens and Incense",
          coord = { map = 2023, x = 0.630, y = 0.336 } },  -- giver coord: ATT
        { type = "quest", questID = 66020, text = "Omens and Incense (objective 1)",
          coord = { map = 2023, x = 0.630, y = 0.351 } },  -- APR route coord (converted)
        { type = "quest", questID = 66020, text = "Omens and Incense (objective 2)",
          coord = { map = 2023, x = 0.628, y = 0.337 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66020, text = "Turn in: Omens and Incense",
          coord = { map = 2023, x = 0.630, y = 0.337 } },  -- APR route coord (converted)
        { type = "accept", questID = 65890, text = "The Nelthazan Ruins",
          coord = { map = 2023, x = 0.660, y = 0.251 } },  -- giver coord: ATT
        { type = "turnin", questID = 65890, text = "Turn in: The Nelthazan Ruins",
          coord = { map = 2023, x = 0.640, y = 0.183 } },  -- APR route coord (converted)
        { type = "accept", questID = 65891, text = "Tools of the Tirade",
          coord = { map = 2023, x = 0.640, y = 0.183 } },  -- giver coord: ATT
        { type = "accept", questID = 65893, text = "The Relic Inquiry",
          coord = { map = 2023, x = 0.640, y = 0.183 } },  -- giver coord: ATT
        { type = "quest", questID = 65891, text = "Tools of the Tirade (objective 1)",
          coord = { map = 2023, x = 0.636, y = 0.155 } },  -- APR route coord (converted)
        { type = "quest", questID = 65893, text = "The Relic Inquiry (objective 1)",
          coord = { map = 2023, x = 0.636, y = 0.155 } },  -- APR route coord (converted)
        { type = "quest", questID = 65892, text = "The Sundered Asunder (objective 1)",
          coord = { map = 2023, x = 0.636, y = 0.155 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 65891, text = "Turn in: Tools of the Tirade",
          coord = { map = 2023, x = 0.640, y = 0.183 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65893, text = "Turn in: The Relic Inquiry",
          coord = { map = 2023, x = 0.640, y = 0.183 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66016, text = "Turn in: Clan Teerai",
          coord = { map = 2023, x = 0.592, y = 0.376 } },  -- APR route coord (converted)
        { type = "accept", questID = 66019, text = "Honoring Our Ancestors",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- giver coord: ATT
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 1)",
          coord = { map = 2023, x = 0.594, y = 0.378 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 2)",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 3)",
          coord = { map = 2023, x = 0.593, y = 0.373 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 4)",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 5)",
          coord = { map = 2023, x = 0.594, y = 0.374 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 6)",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 7)",
          coord = { map = 2023, x = 0.591, y = 0.379 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 8)",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 9)",
          coord = { map = 2023, x = 0.591, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 10)",
          coord = { map = 2023, x = 0.589, y = 0.373 } },  -- APR route coord (converted)
        { type = "quest", questID = 66019, text = "Honoring Our Ancestors (objective 11)",
          coord = { map = 2023, x = 0.591, y = 0.371 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66019, text = "Turn in: Honoring Our Ancestors",
          coord = { map = 2023, x = 0.592, y = 0.376 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66018, text = "Turn in: Clan Nokhud",
          coord = { map = 2023, x = 0.604, y = 0.407 } },  -- APR route coord (converted)
        { type = "accept", questID = 66021, text = "Unwelcome Outsider",
          coord = { map = 2023, x = 0.603, y = 0.407 } },  -- giver coord: ATT
        { type = "quest", questID = 66021, text = "Unwelcome Outsider (objective 1)",
          coord = { map = 2023, x = 0.595, y = 0.418 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66021, text = "Turn in: Unwelcome Outsider",
          coord = { map = 2023, x = 0.624, y = 0.417 } },  -- APR route coord (converted)
        { type = "accept", questID = 66969, text = "Clans of the Plains",
          coord = { map = 2023, x = 0.624, y = 0.416 } },  -- giver coord: ATT
        { type = "quest", questID = 66969, text = "Clans of the Plains (objective 1)",
          coord = { map = 2023, x = 0.615, y = 0.395 } },  -- APR route coord (converted)
        { type = "quest", questID = 66969, text = "Clans of the Plains (objective 2)",
          coord = { map = 2023, x = 0.615, y = 0.395 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66969, text = "Turn in: Clans of the Plains",
          coord = { map = 2023, x = 0.615, y = 0.395 } },  -- APR route coord (converted)
        { type = "accept", questID = 66948, text = "The Emissary's Arrival",
          coord = { map = 2023, x = 0.610, y = 0.404 } },  -- giver coord: ATT
        { type = "quest", questID = 66948, text = "The Emissary's Arrival (objective 1)",
          coord = { map = 2023, x = 0.610, y = 0.404 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66948, text = "Turn in: The Emissary's Arrival",
          coord = { map = 2023, x = 0.610, y = 0.404 } },  -- APR route coord (converted)
        { type = "accept", questID = 66022, text = "The Khanam Matra",
          coord = { map = 2023, x = 0.610, y = 0.404 } },  -- giver coord: ATT
        { type = "quest", questID = 66022, text = "The Khanam Matra (objective 1)",
          coord = { map = 2023, x = 0.603, y = 0.379 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66022, text = "Turn in: The Khanam Matra",
          coord = { map = 2023, x = 0.603, y = 0.379 } },  -- APR route coord (converted)
        { type = "accept", questID = 66023, text = "Trucebreakers",
          coord = { map = 2023, x = 0.603, y = 0.380 } },  -- giver coord: ATT
        { type = "accept", questID = 66024, text = "Covering Their Tails",
          coord = { map = 2023, x = 0.595, y = 0.387 } },  -- giver coord: ATT
        { type = "quest", questID = 66024, text = "Covering Their Tails (objective 1)",
          coord = { map = 2023, x = 0.583, y = 0.393 } },  -- APR route coord (converted)
        { type = "quest", questID = 66023, text = "Trucebreakers (objective 1)",
          coord = { map = 2023, x = 0.594, y = 0.387 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66023, text = "Turn in: Trucebreakers",
          coord = { map = 2023, x = 0.603, y = 0.381 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66024, text = "Turn in: Covering Their Tails",
          coord = { map = 2023, x = 0.603, y = 0.381 } },  -- APR route coord (converted)
        { type = "accept", questID = 66025, text = "The Nokhud Threat",
          coord = { map = 2023, x = 0.603, y = 0.380 } },  -- giver coord: ATT
        { type = "turnin", questID = 66025, text = "Turn in: The Nokhud Threat",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- APR route coord (converted)
        { type = "accept", questID = 66201, text = "Hooves of War",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- giver coord: ATT
        { type = "turnin", questID = 66201, text = "Turn in: Hooves of War",
          coord = { map = 2023, x = 0.419, y = 0.618 } },  -- APR route coord (converted)
        { type = "accept", questID = 66222, text = "The Calm Before the Storm",
          coord = { map = 2023, x = 0.418, y = 0.617 } },  -- giver coord: ATT
        { type = "accept", questID = 66651, text = "Up to No-khud",
          coord = { map = 2023, x = 0.409, y = 0.616 } },  -- giver coord: ATT
        { type = "turnin", questID = 66651, text = "Turn in: Up to No-khud",
          coord = { map = 2023, x = 0.390, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 66652, text = "Return to Mender",
          coord = { map = 2023, x = 0.391, y = 0.660 } },  -- giver coord: ATT
        { type = "quest", questID = 66652, text = "Return to Mender (objective 1)",
          coord = { map = 2023, x = 0.372, y = 0.656 } },  -- APR route coord (converted)
        { type = "quest", questID = 66652, text = "Return to Mender (objective 2)",
          coord = { map = 2023, x = 0.370, y = 0.655 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66652, text = "Turn in: Return to Mender",
          coord = { map = 2023, x = 0.390, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 66654, text = "Desecrator Annihilator",
          coord = { map = 2023, x = 0.391, y = 0.660 } },  -- giver coord: ATT
        { type = "accept", questID = 66655, text = "Reagents of De-Necromancy",
          coord = { map = 2023, x = 0.391, y = 0.660 } },  -- giver coord: ATT
        { type = "quest", questID = 66654, text = "Desecrator Annihilator (objective 1,2)",
          coord = { map = 2023, x = 0.354, y = 0.671 } },  -- APR route coord (converted)
        { type = "quest", questID = 66655, text = "Reagents of De-Necromancy (objective 1,2)",
          coord = { map = 2023, x = 0.354, y = 0.671 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66654, text = "Turn in: Desecrator Annihilator",
          coord = { map = 2023, x = 0.338, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66655, text = "Turn in: Reagents of De-Necromancy",
          coord = { map = 2023, x = 0.338, y = 0.654 } },  -- APR route coord (converted)
        { type = "accept", questID = 69936, text = "Zambul, Head Vandal",
          coord = { map = 2023, x = 0.338, y = 0.654 } },  -- giver coord: ATT
        { type = "quest", questID = 69936, text = "Zambul, Head Vandal (objective 1)",
          coord = { map = 2023, x = 0.354, y = 0.671 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69936, text = "Turn in: Zambul, Head Vandal",
          coord = { map = 2023, x = 0.338, y = 0.654 } },  -- APR route coord (converted)
        { type = "accept", questID = 66656, text = "Definitely Eternal Slumber",
          coord = { map = 2023, x = 0.338, y = 0.654 } },  -- giver coord: ATT
        { type = "quest", questID = 66656, text = "Definitely Eternal Slumber (objective 1)",
          coord = { map = 2023, x = 0.311, y = 0.690 } },  -- APR route coord (converted)
        { type = "quest", questID = 66656, text = "Definitely Eternal Slumber (objective 2)",
          coord = { map = 2023, x = 0.311, y = 0.711 } },  -- APR route coord (converted)
        { type = "quest", questID = 66656, text = "Definitely Eternal Slumber (objective 4)",
          coord = { map = 2023, x = 0.332, y = 0.718 } },  -- APR route coord (converted)
        { type = "quest", questID = 66656, text = "Definitely Eternal Slumber (objective 3)",
          coord = { map = 2023, x = 0.324, y = 0.708 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66656, text = "Turn in: Definitely Eternal Slumber",
          coord = { map = 2023, x = 0.320, y = 0.700 } },  -- APR route coord (converted)
        { type = "accept", questID = 66657, text = "And Stay Dead!",
          coord = { map = 2023, x = 0.314, y = 0.710 } },  -- giver coord: ATT
        { type = "quest", questID = 66657, text = "And Stay Dead! (objective 1)",
          coord = { map = 2023, x = 0.313, y = 0.711 } },  -- APR route coord (converted)
        { type = "quest", questID = 66657, text = "And Stay Dead! (objective 2)",
          coord = { map = 2023, x = 0.311, y = 0.710 } },  -- APR route coord (converted)
        { type = "quest", questID = 66657, text = "And Stay Dead! (objective 3)",
          coord = { map = 2023, x = 0.315, y = 0.715 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66657, text = "Turn in: And Stay Dead!",
          coord = { map = 2023, x = 0.315, y = 0.715 } },  -- APR route coord (converted)
        { type = "quest", questID = 66222, text = "The Calm Before the Storm (objective 4)",
          coord = { map = 2023, x = 0.376, y = 0.595 } },  -- APR route coord (converted)
        { type = "quest", questID = 66222, text = "The Calm Before the Storm (objective 1)",
          coord = { map = 2023, x = 0.385, y = 0.574 } },  -- APR route coord (converted)
        { type = "accept", questID = 71027, text = "WANTED: Mara'nar the Thunderous",
          coord = { map = 2023, x = 0.396, y = 0.564 } },  -- giver coord: ATT
        { type = "quest", questID = 66222, text = "The Calm Before the Storm (objective 3)",
          coord = { map = 2023, x = 0.395, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest", questID = 66222, text = "The Calm Before the Storm (objective 2)",
          coord = { map = 2023, x = 0.408, y = 0.564 } },  -- APR route coord (converted)
        { type = "accept", questID = 66687, text = "Land of the Apex",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- giver coord: ATT
        { type = "accept", questID = 66688, text = "Signs of the Wind",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- giver coord: ATT
        { type = "quest", questID = 66688, text = "Signs of the Wind (objective 1)",
          coord = { map = 2023, x = 0.460, y = 0.533 } },  -- APR route coord (converted)
        { type = "quest", questID = 66687, text = "Land of the Apex (objective 3)",
          coord = { map = 2023, x = 0.536, y = 0.523 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66688, text = "Turn in: Signs of the Wind",
          coord = { map = 2023, x = 0.493, y = 0.495 } },  -- APR route coord (converted)
        { type = "accept", questID = 70374, text = "Himia, the Blessed",
          coord = { map = 2023, x = 0.493, y = 0.494 } },  -- giver coord: ATT
        { type = "quest", questID = 70374, text = "Himia, the Blessed (objective 1)",
          coord = { map = 2023, x = 0.493, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 66687, text = "Land of the Apex (objective 1)",
          coord = { map = 2023, x = 0.436, y = 0.502 } },  -- APR route coord (converted)
        { type = "quest", questID = 71027, text = "WANTED: Mara'nar the Thunderous (objective 1)",
          coord = { map = 2023, x = 0.422, y = 0.473 } },  -- APR route coord (converted)
        { type = "quest", questID = 66687, text = "Land of the Apex (objective 2)",
          coord = { map = 2023, x = 0.426, y = 0.465 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66687, text = "Turn in: Land of the Apex",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70374, text = "Turn in: Himia, the Blessed",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- APR route coord (converted)
        { type = "accept", questID = 66834, text = "Rellen, the Learned",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- giver coord: ATT
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 1)",
          coord = { map = 2023, x = 0.401, y = 0.578 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 2)",
          coord = { map = 2023, x = 0.402, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 3)",
          coord = { map = 2023, x = 0.402, y = 0.579 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 4)",
          coord = { map = 2023, x = 0.401, y = 0.578 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 5)",
          coord = { map = 2023, x = 0.401, y = 0.578 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 6)",
          coord = { map = 2023, x = 0.401, y = 0.577 } },  -- APR route coord (converted)
        { type = "quest", questID = 66834, text = "Rellen, the Learned (objective 7)",
          coord = { map = 2023, x = 0.401, y = 0.577 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66834, text = "Turn in: Rellen, the Learned",
          coord = { map = 2023, x = 0.416, y = 0.567 } },  -- APR route coord (converted)
        { type = "turnin", questID = 71027, text = "Turn in: WANTED: Mara'nar the Thunderous",
          coord = { map = 2023, x = 0.419, y = 0.618 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66222, text = "Turn in: The Calm Before the Storm",
          coord = { map = 2023, x = 0.419, y = 0.618 } },  -- APR route coord (converted)
        { type = "accept", questID = 70229, text = "Boku the Mystic",
          coord = { map = 2023, x = 0.418, y = 0.617 } },  -- giver coord: ATT
        { type = "turnin", questID = 70229, text = "Turn in: Boku the Mystic",
          coord = { map = 2023, x = 0.368, y = 0.573 } },  -- APR route coord (converted)
        { type = "accept", questID = 66254, text = "Pessimistic Mystic",
          coord = { map = 2023, x = 0.368, y = 0.572 } },  -- giver coord: ATT
        { type = "quest", questID = 66254, text = "Pessimistic Mystic (objective 1)",
          coord = { map = 2023, x = 0.369, y = 0.575 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66254, text = "Turn in: Pessimistic Mystic",
          coord = { map = 2023, x = 0.368, y = 0.573 } },  -- APR route coord (converted)
        { type = "accept", questID = 66224, text = "Mystic Mystery",
          coord = { map = 2023, x = 0.368, y = 0.572 } },  -- giver coord: ATT
        { type = "quest", questID = 66224, text = "Mystic Mystery (objective 1)",
          coord = { map = 2023, x = 0.446, y = 0.618 } },  -- APR route coord (converted)
        { type = "quest", questID = 66224, text = "Mystic Mystery (objective 2)",
          coord = { map = 2023, x = 0.446, y = 0.620 } },  -- APR route coord (converted)
        { type = "quest", questID = 66224, text = "Mystic Mystery (objective 3)",
          coord = { map = 2023, x = 0.465, y = 0.632 } },  -- APR route coord (converted)
        { type = "quest", questID = 66224, text = "Mystic Mystery (objective 4)",
          coord = { map = 2023, x = 0.465, y = 0.632 } },  -- APR route coord (converted)
        { type = "quest", questID = 66224, text = "Mystic Mystery (objective 5)",
          coord = { map = 2023, x = 0.493, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66224, text = "Turn in: Mystic Mystery",
          coord = { map = 2023, x = 0.493, y = 0.632 } },  -- APR route coord (converted)
        { type = "accept", questID = 66225, text = "Toting Totems",
          coord = { map = 2023, x = 0.494, y = 0.631 } },  -- giver coord: ATT
        { type = "accept", questID = 70195, text = "Taken By Storm",
          coord = { map = 2023, x = 0.494, y = 0.631 } },  -- giver coord: ATT
        { type = "quest", questID = 70195, text = "Taken By Storm (objective 1,2)",
          coord = { map = 2023, x = 0.489, y = 0.688 } },  -- APR route coord (converted)
        { type = "quest", questID = 66225, text = "Toting Totems (objective 1)",
          coord = { map = 2023, x = 0.501, y = 0.675 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66225, text = "Turn in: Toting Totems",
          coord = { map = 2023, x = 0.493, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70195, text = "Turn in: Taken By Storm",
          coord = { map = 2023, x = 0.493, y = 0.632 } },  -- APR route coord (converted)
        { type = "accept", questID = 66236, text = "Catching Wind",
          coord = { map = 2023, x = 0.493, y = 0.631 } },  -- giver coord: ATT
        { type = "turnin", questID = 66236, text = "Turn in: Catching Wind",
          coord = { map = 2023, x = 0.581, y = 0.690 } },  -- APR route coord (converted)
        { type = "accept", questID = 66242, text = "Weather Control",
          coord = { map = 2023, x = 0.581, y = 0.690 } },  -- giver coord: ATT
        { type = "accept", questID = 66256, text = "Eagle-itarian",
          coord = { map = 2023, x = 0.581, y = 0.690 } },  -- giver coord: ATT
        { type = "accept", questID = 66257, text = "Fowl Sorcery",
          coord = { map = 2023, x = 0.581, y = 0.690 } },  -- giver coord: ATT
        { type = "quest", questID = 66257, text = "Fowl Sorcery (objective 1) [1/4]",
          coord = { map = 2023, x = 0.582, y = 0.674 } },  -- APR route coord (converted)
        { type = "quest", questID = 69968, text = "Prozela Galeshot (objective 1)",
          coord = { map = 2023, x = 0.598, y = 0.669 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "quest", questID = 66257, text = "Fowl Sorcery (objective 1) [2/4]",
          coord = { map = 2023, x = 0.592, y = 0.655 } },  -- APR route coord (converted)
        { type = "quest", questID = 66257, text = "Fowl Sorcery (objective 1) [3/4]",
          coord = { map = 2023, x = 0.588, y = 0.618 } },  -- APR route coord (converted)
        { type = "quest", questID = 66257, text = "Fowl Sorcery (objective 1) [4/4]",
          coord = { map = 2023, x = 0.618, y = 0.667 } },  -- APR route coord (converted)
        { type = "quest", questID = 66242, text = "Weather Control (objective 1,2)",
          coord = { map = 2023, x = 0.597, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest", questID = 66256, text = "Eagle-itarian (objective 1,2)",
          coord = { map = 2023, x = 0.597, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66242, text = "Turn in: Weather Control",
          coord = { map = 2023, x = 0.607, y = 0.635 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66256, text = "Turn in: Eagle-itarian",
          coord = { map = 2023, x = 0.607, y = 0.635 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66257, text = "Turn in: Fowl Sorcery",
          coord = { map = 2023, x = 0.607, y = 0.635 } },  -- APR route coord (converted)
        { type = "accept", questID = 66258, text = "Oh No, Ohn'ahra!",
          coord = { map = 2023, x = 0.606, y = 0.635 } },  -- giver coord: ATT
        { type = "quest", questID = 66258, text = "Oh No, Ohn'ahra! (objective 1,2)",
          coord = { map = 2023, x = 0.605, y = 0.649 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66258, text = "Turn in: Oh No, Ohn'ahra!",
          coord = { map = 2023, x = 0.614, y = 0.628 } },  -- APR route coord (converted)
        { type = "accept", questID = 66259, text = "A Storm of Ill Tidings",
          coord = { map = 2023, x = 0.614, y = 0.628 } },  -- giver coord: ATT
        { type = "quest", questID = 66259, text = "A Storm of Ill Tidings (objective 1)",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66259, text = "Turn in: A Storm of Ill Tidings",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- APR route coord (converted)
        { type = "accept", questID = 66327, text = "Chasing the Wind",
          coord = { map = 2023, x = 0.600, y = 0.374 } },  -- giver coord: ATT
        { type = "quest", questID = 66327, text = "Chasing the Wind (objective 1)",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- APR route coord (converted)
        { type = "quest", questID = 66327, text = "Chasing the Wind (objective 2)",
          coord = { map = 2023, x = 0.600, y = 0.375 } },  -- APR route coord (converted)
        { type = "quest", questID = 66327, text = "Chasing the Wind (objective 3)",
          coord = { map = 2023, x = 0.730, y = 0.406 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66327, text = "Turn in: Chasing the Wind",
          coord = { map = 2023, x = 0.730, y = 0.406 } },  -- APR route coord (converted)
        { type = "accept", questID = 70244, text = "Nokhud Can Come of This",
          coord = { map = 2023, x = 0.730, y = 0.405 } },  -- giver coord: ATT
        { type = "quest", questID = 70244, text = "Nokhud Can Come of This (objective 1)",
          coord = { map = 2023, x = 0.753, y = 0.409 } },  -- APR route coord (converted)
        { type = "quest", questID = 70244, text = "Nokhud Can Come of This (objective 2)",
          coord = { map = 2023, x = 0.761, y = 0.409 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70244, text = "Turn in: Nokhud Can Come of This",
          coord = { map = 2023, x = 0.767, y = 0.409 } },  -- APR route coord (converted)
        { type = "accept", questID = 66329, text = "Blowing of the Horn",
          coord = { map = 2023, x = 0.767, y = 0.409 } },  -- giver coord: ATT
        { type = "quest", questID = 66329, text = "Blowing of the Horn (objective 1)",
          coord = { map = 2023, x = 0.767, y = 0.409 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66329, text = "Turn in: Blowing of the Horn",
          coord = { map = 2023, x = 0.767, y = 0.409 } },  -- APR route coord (converted)
        { type = "accept", questID = 66328, text = "Green Dragon Down",
          coord = { map = 2023, x = 0.767, y = 0.409 } },  -- giver coord: ATT
        { type = "quest", questID = 66328, text = "Green Dragon Down (objective 1)",
          coord = { map = 2023, x = 0.723, y = 0.503 } },  -- APR route coord (converted)
        { type = "quest", questID = 66328, text = "Green Dragon Down (objective 2)",
          coord = { map = 2023, x = 0.723, y = 0.503 } },  -- APR route coord (converted)
        { type = "accept", questID = 66681, text = "Tempests Abound",
          coord = { map = 2023, x = 0.810, y = 0.589 } },  -- giver coord: ATT
        { type = "accept", questID = 66680, text = "Counting Sheep",
          coord = { map = 2023, x = 0.810, y = 0.589 } },  -- giver coord: ATT
        { type = "quest", questID = 66680, text = "Counting Sheep (objective 1)",
          coord = { map = 2023, x = 0.806, y = 0.588 } },  -- APR route coord (converted)
        { type = "quest", questID = 66680, text = "Counting Sheep (objective 2)",
          coord = { map = 2023, x = 0.810, y = 0.595 } },  -- APR route coord (converted)
        { type = "quest", questID = 66680, text = "Counting Sheep (objective 3)",
          coord = { map = 2023, x = 0.815, y = 0.653 } },  -- APR route coord (converted)
        { type = "quest", questID = 66681, text = "Tempests Abound (objective 1)",
          coord = { map = 2023, x = 0.815, y = 0.653 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66680, text = "Turn in: Counting Sheep",
          coord = { map = 2023, x = 0.810, y = 0.590 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66681, text = "Turn in: Tempests Abound",
          coord = { map = 2023, x = 0.810, y = 0.590 } },  -- APR route coord (converted)
        { type = "accept", questID = 66689, text = "More Than A Rock",
          coord = { map = 2023, x = 0.815, y = 0.653 } },  -- APR DroppableQuest: item drop from Pinehoof Doe (mob 191496); coord = APR farm spot (converted)
        { type = "turnin", questID = 66689, text = "Turn in: More Than A Rock",
          coord = { map = 2023, x = 0.810, y = 0.590 } },  -- APR route coord (converted)
        { type = "accept", questID = 66683, text = "Last Resort Analysis",
          coord = { map = 2023, x = 0.810, y = 0.589 } },  -- giver coord: ATT
        { type = "quest", questID = 66683, text = "Last Resort Analysis (objective 1)",
          coord = { map = 2023, x = 0.810, y = 0.595 } },  -- APR route coord (converted)
        { type = "quest", questID = 66683, text = "Last Resort Analysis (objective 3)",
          coord = { map = 2023, x = 0.806, y = 0.588 } },  -- APR route coord (converted)
        { type = "quest", questID = 66683, text = "Last Resort Analysis (objective 2)",
          coord = { map = 2023, x = 0.804, y = 0.579 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66683, text = "Turn in: Last Resort Analysis",
          coord = { map = 2023, x = 0.810, y = 0.590 } },  -- APR route coord (converted)
        { type = "accept", questID = 65836, text = "Show of Storm",
          coord = { map = 2023, x = 0.810, y = 0.589 } },  -- giver coord: ATT
        { type = "quest", questID = 65836, text = "Show of Storm (objective 1)",
          coord = { map = 2023, x = 0.840, y = 0.608 } },  -- APR route coord (converted)
        { type = "quest", questID = 65836, text = "Show of Storm (objective 2)",
          coord = { map = 2023, x = 0.840, y = 0.608 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65836, text = "Turn in: Show of Storm",
          coord = { map = 2023, x = 0.840, y = 0.608 } },  -- APR route coord (converted)
        { type = "accept", questID = 66684, text = "Storm Chasing",
          coord = { map = 2023, x = 0.840, y = 0.607 } },  -- giver coord: ATT
        { type = "quest", questID = 66684, text = "Storm Chasing (objective 1)",
          coord = { map = 2023, x = 0.850, y = 0.642 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66684, text = "Turn in: Storm Chasing",
          coord = { map = 2023, x = 0.809, y = 0.589 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66328, text = "Turn in: Green Dragon Down",
          coord = { map = 2023, x = 0.723, y = 0.503 } },  -- APR route coord (converted)
        { type = "accept", questID = 66344, text = "With the Wind at Our Backs",
          coord = { map = 2023, x = 0.724, y = 0.507 } },  -- giver coord: ATT
        { type = "quest", questID = 66344, text = "With the Wind at Our Backs (objective 1)",
          coord = { map = 2023, x = 0.723, y = 0.507 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66344, text = "Turn in: With the Wind at Our Backs",
          coord = { map = 2023, x = 0.283, y = 0.577 } },  -- APR route coord (converted)
        { type = "accept", questID = 70220, text = "Shady Sanctuary",
          coord = { map = 2023, x = 0.283, y = 0.577 } },  -- giver coord: ATT
        { type = "quest", questID = 70220, text = "Shady Sanctuary (objective 2)",
          coord = { map = 2023, x = 0.298, y = 0.577 } },  -- APR route coord (converted)
        { type = "quest", questID = 70220, text = "Shady Sanctuary (objective 3)",
          coord = { map = 2023, x = 0.302, y = 0.557 } },  -- APR route coord (converted)
        { type = "quest", questID = 70220, text = "Shady Sanctuary (objective 1)",
          coord = { map = 2023, x = 0.291, y = 0.553 } },  -- APR route coord (converted)
        { type = "quest", questID = 70220, text = "Shady Sanctuary (objective 4)",
          coord = { map = 2023, x = 0.293, y = 0.564 } },  -- APR route coord (converted)
        { type = "quest", questID = 70220, text = "Shady Sanctuary (objective 5)",
          coord = { map = 2023, x = 0.300, y = 0.603 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70220, text = "Turn in: Shady Sanctuary",
          coord = { map = 2023, x = 0.283, y = 0.577 } },  -- APR route coord (converted)
        { type = "accept", questID = 66331, text = "The Primalist Front",
          coord = { map = 2023, x = 0.282, y = 0.576 } },  -- giver coord: ATT
        { type = "quest", questID = 66331, text = "The Primalist Front (objective 3)",
          coord = { map = 2023, x = 0.275, y = 0.461 } },  -- APR route coord (converted)
        { type = "quest", questID = 66331, text = "The Primalist Front (objective 2)",
          coord = { map = 2023, x = 0.257, y = 0.443 } },  -- APR route coord (converted)
        { type = "quest", questID = 66331, text = "The Primalist Front (objective 4)",
          coord = { map = 2023, x = 0.262, y = 0.401 } },  -- APR route coord (converted)
        { type = "quest", questID = 66331, text = "The Primalist Front (objective 5)",
          coord = { map = 2023, x = 0.256, y = 0.405 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66331, text = "Turn in: The Primalist Front",
          coord = { map = 2023, x = 0.257, y = 0.404 } },  -- APR route coord (converted)
        { type = "accept", questID = 66333, text = "Justice for Solethus",
          coord = { map = 2023, x = 0.256, y = 0.405 } },  -- giver coord: ATT
        { type = "quest", questID = 66333, text = "Justice for Solethus (objective 2) [1/3]",
          coord = { map = 2023, x = 0.248, y = 0.399 } },  -- APR route coord (converted)
        { type = "quest", questID = 66333, text = "Justice for Solethus (objective 2) [2/3]",
          coord = { map = 2023, x = 0.244, y = 0.385 } },  -- APR route coord (converted)
        { type = "quest", questID = 66333, text = "Justice for Solethus (objective 2) [3/3]",
          coord = { map = 2023, x = 0.255, y = 0.377 } },  -- APR route coord (converted)
        { type = "quest", questID = 66333, text = "Justice for Solethus (objective 1)",
          coord = { map = 2023, x = 0.247, y = 0.399 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66333, text = "Turn in: Justice for Solethus",
          coord = { map = 2023, x = 0.254, y = 0.378 } },  -- APR route coord (converted)
        { type = "accept", questID = 66784, text = "Starve the Storm",
          coord = { map = 2023, x = 0.252, y = 0.385 } },  -- giver coord: ATT
        { type = "accept", questID = 66335, text = "Deconstruct Additional Pylons",
          coord = { map = 2023, x = 0.252, y = 0.385 } },  -- giver coord: ATT
        { type = "quest", questID = 66335, text = "Deconstruct Additional Pylons (objective 1)",
          coord = { map = 2023, x = 0.240, y = 0.395 } },  -- APR route coord (converted)
        { type = "quest", questID = 66335, text = "Deconstruct Additional Pylons (objective 2)",
          coord = { map = 2023, x = 0.232, y = 0.376 } },  -- APR route coord (converted)
        { type = "quest", questID = 66335, text = "Deconstruct Additional Pylons (objective 3)",
          coord = { map = 2023, x = 0.222, y = 0.375 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66335, text = "Turn in: Deconstruct Additional Pylons",
          coord = { map = 2023, x = 0.222, y = 0.375 } },  -- APR route coord (converted)
        { type = "quest", questID = 66784, text = "Starve the Storm (objective 1)",
          coord = { map = 2023, x = 0.249, y = 0.350 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66784, text = "Turn in: Starve the Storm",
          coord = { map = 2023, x = 0.249, y = 0.350 } },  -- APR route coord (converted)
        { type = "quest", questID = 66421, text = "The Storm Scar (objective 1)",
          coord = { map = 2023, x = 0.254, y = 0.378 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "accept", questID = 66337, text = "Stormbreaker",
          coord = { map = 2023, x = 0.248, y = 0.350 } },  -- giver coord: ATT
        { type = "quest", questID = 66970, text = "Ty'foon the Ascended (objective 1)",
          coord = { map = 2023, x = 0.259, y = 0.342 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "quest", questID = 66337, text = "Stormbreaker (objective 1)",
          coord = { map = 2023, x = 0.224, y = 0.396 } },  -- APR route coord (converted)
        { type = "quest", questID = 66337, text = "Stormbreaker (objective 2)",
          coord = { map = 2023, x = 0.229, y = 0.402 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66337, text = "Turn in: Stormbreaker",
          coord = { map = 2023, x = 0.256, y = 0.484 } },  -- APR route coord (converted)
        { type = "accept", questID = 66336, text = "The Isle of Emerald",
          coord = { map = 2023, x = 0.257, y = 0.484 } },  -- giver coord: ATT
        { type = "turnin", questID = 66336, text = "Turn in: The Isle of Emerald",
          coord = { map = 2023, x = 0.221, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 66783, text = "Renewal of Vows",
          coord = { map = 2023, x = 0.221, y = 0.510 } },  -- giver coord: ATT
        { type = "quest", questID = 66783, text = "Renewal of Vows (objective 1)",
          coord = { map = 2023, x = 0.223, y = 0.509 } },  -- APR route coord (converted)
        { type = "quest", questID = 66783, text = "Renewal of Vows (objective 2)",
          coord = { map = 2023, x = 0.224, y = 0.511 } },  -- APR route coord (converted)
        { type = "quest", questID = 66783, text = "Renewal of Vows (objective 3)",
          coord = { map = 2023, x = 0.223, y = 0.510 } },  -- APR route coord (converted)
        { type = "quest", questID = 66783, text = "Renewal of Vows (objective 4)",
          coord = { map = 2023, x = 0.221, y = 0.510 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66783, text = "Turn in: Renewal of Vows",
          coord = { map = 2023, x = 0.221, y = 0.510 } },  -- APR route coord (converted)
        { type = "accept", questID = 66340, text = "Into the Azure",
          coord = { map = 2023, x = 0.221, y = 0.509 } },  -- giver coord: ATT
        { type = "turnin", questID = 66340, text = "Turn in: Into the Azure",
          coord = { map = 2023, x = 0.717, y = 0.806 } },  -- APR route coord (converted)
        { type = "accept", questID = 65686, text = "To the Azure Span",
          coord = { map = 2023, x = 0.717, y = 0.806 } },  -- giver coord: ATT
        -- ===== The Azure Span =====
        { type = "turnin", questID = 65686, text = "Turn in: To the Azure Span",
          coord = { map = 2024, x = 0.414, y = 0.356 } },  -- APR route coord (converted)
        { type = "accept", questID = 66228, text = "Camp Antonidas",
          coord = { map = 2024, x = 0.414, y = 0.356 } },  -- giver coord: ATT
        { type = "accept", questID = 67174, text = "Arcane Detection",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- giver coord: ATT
        { type = "quest", questID = 67174, text = "Arcane Detection (objective 1)",
          coord = { map = 2024, x = 0.414, y = 0.357 } },  -- APR route coord (converted)
        { type = "quest", questID = 67174, text = "Arcane Detection (objective 2)",
          coord = { map = 2024, x = 0.414, y = 0.358 } },  -- APR route coord (converted)
        { type = "quest", questID = 67174, text = "Arcane Detection (objective 3)",
          coord = { map = 2024, x = 0.412, y = 0.364 } },  -- APR route coord (converted)
        { type = "accept", questID = 67177, text = "WANTED: Gorger",
          coord = { map = 2024, x = 0.414, y = 0.364 } },  -- giver coord: ATT
        { type = "turnin", questID = 67174, text = "Turn in: Arcane Detection",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- APR route coord (converted)
        { type = "accept", questID = 67175, text = "How To Stop An Exploding Toy Boat",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- giver coord: ATT
        { type = "quest", questID = 67175, text = "How To Stop An Exploding Toy Boat (objective 1)",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- APR route coord (converted)
        { type = "quest", questID = 67175, text = "How To Stop An Exploding Toy Boat (objective 2)",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- APR route coord (converted)
        { type = "quest", questID = 67175, text = "How To Stop An Exploding Toy Boat (objective 3)",
          coord = { map = 2024, x = 0.406, y = 0.366 } },  -- APR route coord (converted)
        { type = "quest", questID = 67177, text = "WANTED: Gorger (objective 1)",
          coord = { map = 2024, x = 0.398, y = 0.373 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67177, text = "Turn in: WANTED: Gorger",
          coord = { map = 2024, x = 0.414, y = 0.364 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67175, text = "Turn in: How To Stop An Exploding Toy Boat",
          coord = { map = 2024, x = 0.412, y = 0.359 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66228, text = "Turn in: Camp Antonidas",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- APR route coord (converted)
        { type = "accept", questID = 67033, text = "Assemble the Defenses",
          coord = { map = 2024, x = 0.466, y = 0.397 } },  -- giver coord: ATT
        { type = "accept", questID = 67035, text = "Preservation of Knowledge",
          coord = { map = 2024, x = 0.467, y = 0.397 } },  -- giver coord: ATT
        { type = "quest", questID = 67033, text = "Assemble the Defenses (objective 1)",
          coord = { map = 2024, x = 0.460, y = 0.397 } },  -- APR route coord (converted)
        { type = "quest", questID = 67035, text = "Preservation of Knowledge (objective 1)",
          coord = { map = 2024, x = 0.460, y = 0.397 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67033, text = "Turn in: Assemble the Defenses",
          coord = { map = 2024, x = 0.467, y = 0.398 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67035, text = "Turn in: Preservation of Knowledge",
          coord = { map = 2024, x = 0.467, y = 0.398 } },  -- APR route coord (converted)
        { type = "accept", questID = 67036, text = "Wrath of the Kirin Tor",
          coord = { map = 2024, x = 0.467, y = 0.398 } },  -- giver coord: ATT
        { type = "quest", questID = 67036, text = "Wrath of the Kirin Tor (objective 1)",
          coord = { map = 2024, x = 0.463, y = 0.388 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67036, text = "Turn in: Wrath of the Kirin Tor",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- APR route coord (converted)
        { type = "accept", questID = 65688, text = "Meeting Kalecgos",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- giver coord: ATT
        { type = "accept", questID = 66488, text = "WANTED: Frigellus",
          coord = { map = 2024, x = 0.462, y = 0.396 } },  -- giver coord: ATT
        { type = "quest", questID = 65688, text = "Meeting Kalecgos (objective 1)",
          coord = { map = 2024, x = 0.460, y = 0.388 } },  -- APR route coord (converted)
        { type = "quest", questID = 65688, text = "Meeting Kalecgos (objective 2)",
          coord = { map = 2024, x = 0.460, y = 0.389 } },  -- APR route coord (converted)
        { type = "quest", questID = 66488, text = "WANTED: Frigellus (objective 1)",
          coord = { map = 2024, x = 0.480, y = 0.381 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66488, text = "Turn in: WANTED: Frigellus",
          coord = { map = 2024, x = 0.460, y = 0.383 } },  -- APR route coord (converted)
        { type = "accept", questID = 66489, text = "Setting the Defense",
          coord = { map = 2024, x = 0.460, y = 0.384 } },  -- giver coord: ATT
        { type = "quest", questID = 66489, text = "Setting the Defense (objective 1)",
          coord = { map = 2024, x = 0.462, y = 0.388 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66489, text = "Turn in: Setting the Defense",
          coord = { map = 2024, x = 0.460, y = 0.384 } },  -- APR route coord (converted)
        { type = "accept", questID = 65914, text = "Mammoths Matter",
          coord = { map = 2024, x = 0.448, y = 0.506 } },  -- giver coord: ATT
        { type = "accept", questID = 65925, text = "Culling the Cullers",
          coord = { map = 2024, x = 0.448, y = 0.506 } },  -- giver coord: ATT
        { type = "quest", questID = 65925, text = "Culling the Cullers (objective 1,2)",
          coord = { map = 2024, x = 0.474, y = 0.514 } },  -- APR route coord (converted)
        { type = "quest", questID = 65914, text = "Mammoths Matter (objective 1,2)",
          coord = { map = 2024, x = 0.474, y = 0.514 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65914, text = "Turn in: Mammoths Matter",
          coord = { map = 2024, x = 0.454, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65925, text = "Turn in: Culling the Cullers",
          coord = { map = 2024, x = 0.454, y = 0.542 } },  -- APR route coord (converted)
        { type = "accept", questID = 65926, text = "Tackling the Falls",
          coord = { map = 2024, x = 0.454, y = 0.542 } },  -- giver coord: ATT
        { type = "quest", questID = 65926, text = "Tackling the Falls (objective 1)",
          coord = { map = 2024, x = 0.454, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65926, text = "Turn in: Tackling the Falls",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- APR route coord (converted)
        { type = "accept", questID = 66724, text = "The Gleamfisher",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- giver coord: ATT
        { type = "quest", questID = 66724, text = "The Gleamfisher (objective 1)",
          coord = { map = 2024, x = 0.452, y = 0.542 } },  -- APR route coord (converted)
        { type = "quest", questID = 66724, text = "The Gleamfisher (objective 2)",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66724, text = "Turn in: The Gleamfisher",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- APR route coord (converted)
        { type = "accept", questID = 65929, text = "Ice Breakers",
          coord = { map = 2024, x = 0.454, y = 0.542 } },  -- giver coord: ATT
        { type = "accept", questID = 65928, text = "Wayward Winds",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- giver coord: ATT
        { type = "quest", questID = 65929, text = "Ice Breakers (objective 1)",
          coord = { map = 2024, x = 0.465, y = 0.575 } },  -- APR route coord (converted)
        { type = "quest", questID = 65928, text = "Wayward Winds (objective 1)",
          coord = { map = 2024, x = 0.465, y = 0.575 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65928, text = "Turn in: Wayward Winds",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65929, text = "Turn in: Ice Breakers",
          coord = { map = 2024, x = 0.455, y = 0.542 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65688, text = "Turn in: Meeting Kalecgos",
          coord = { map = 2024, x = 0.409, y = 0.550 } },  -- APR route coord (converted)
        { type = "accept", questID = 65689, text = "The Many Images of Kalecgos",
          coord = { map = 2024, x = 0.409, y = 0.550 } },  -- giver coord: ATT
        { type = "quest", questID = 65689, text = "The Many Images of Kalecgos (objective 1)",
          coord = { map = 2024, x = 0.411, y = 0.553 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65689, text = "Turn in: The Many Images of Kalecgos",
          coord = { map = 2024, x = 0.407, y = 0.590 } },  -- APR route coord (converted)
        { type = "accept", questID = 65702, text = "Driven Mad",
          coord = { map = 2024, x = 0.407, y = 0.590 } },  -- giver coord: ATT
        { type = "accept", questID = 65709, text = "Arcane Pruning",
          coord = { map = 2024, x = 0.406, y = 0.591 } },  -- giver coord: ATT
        { type = "quest", questID = 65709, text = "Arcane Pruning (objective 1)",
          coord = { map = 2024, x = 0.407, y = 0.591 } },  -- APR route coord (converted)
        { type = "quest", questID = 65709, text = "Arcane Pruning (objective 2)",
          coord = { map = 2024, x = 0.396, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest", questID = 65709, text = "Arcane Pruning (objective 3)",
          coord = { map = 2024, x = 0.412, y = 0.623 } },  -- APR route coord (converted)
        { type = "quest", questID = 65702, text = "Driven Mad (objective 1)",
          coord = { map = 2024, x = 0.401, y = 0.609 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65702, text = "Turn in: Driven Mad",
          coord = { map = 2024, x = 0.407, y = 0.591 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65709, text = "Turn in: Arcane Pruning",
          coord = { map = 2024, x = 0.407, y = 0.591 } },  -- APR route coord (converted)
        { type = "accept", questID = 65852, text = "Straight to the Top",
          coord = { map = 2024, x = 0.407, y = 0.590 } },  -- giver coord: ATT
        { type = "quest", questID = 65852, text = "Straight to the Top (objective 1)",
          coord = { map = 2024, x = 0.396, y = 0.603 } },  -- APR route coord (converted)
        { type = "quest", questID = 65852, text = "Straight to the Top (objective 2)",
          coord = { map = 2024, x = 0.396, y = 0.603 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65852, text = "Turn in: Straight to the Top",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 65751, text = "Platform Adjustments",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- giver coord: ATT
        { type = "accept", questID = 65752, text = "Arcane Annoyances",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- giver coord: ATT
        { type = "quest", questID = 65751, text = "Platform Adjustments (objective 1)",
          coord = { map = 2024, x = 0.399, y = 0.617 } },  -- APR route coord (converted)
        { type = "quest", questID = 65752, text = "Arcane Annoyances (objective 1)",
          coord = { map = 2024, x = 0.399, y = 0.617 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65752, text = "Turn in: Arcane Annoyances",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65751, text = "Turn in: Platform Adjustments",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- APR route coord (converted)
        { type = "accept", questID = 65854, text = "Reclaiming the Oathstone",
          coord = { map = 2024, x = 0.400, y = 0.615 } },  -- giver coord: ATT
        { type = "quest", questID = 65854, text = "Reclaiming the Oathstone (objective 1)",
          coord = { map = 2024, x = 0.394, y = 0.632 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65854, text = "Turn in: Reclaiming the Oathstone",
          coord = { map = 2024, x = 0.395, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 65855, text = "Aiding Azure Span",
          coord = { map = 2024, x = 0.395, y = 0.631 } },  -- giver coord: ATT
        { type = "turnin", questID = 65855, text = "Turn in: Aiding Azure Span",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- APR route coord (converted)
        { type = "accept", questID = 66699, text = "Ask the Locals",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- giver coord: ATT
        { type = "accept", questID = 69904, text = "Suspiciously Quiet",
          coord = { map = 2024, x = 0.466, y = 0.402 } },  -- giver coord: ATT
        { type = "quest", questID = 69904, text = "Suspiciously Quiet (objective 1)",
          coord = { map = 2024, x = 0.477, y = 0.402 } },  -- APR route coord (converted)
        { type = "turnin", questID = 69904, text = "Turn in: Suspiciously Quiet",
          coord = { map = 2024, x = 0.477, y = 0.402 } },  -- APR route coord (converted)
        { type = "accept", questID = 66500, text = "Ways of Seeing",
          coord = { map = 2024, x = 0.477, y = 0.402 } },  -- giver coord: ATT
        { type = "quest", questID = 66500, text = "Ways of Seeing (objective 1)",
          coord = { map = 2024, x = 0.478, y = 0.400 } },  -- APR route coord (converted)
        { type = "quest", questID = 66500, text = "Ways of Seeing (objective 2)",
          coord = { map = 2024, x = 0.471, y = 0.404 } },  -- APR route coord (converted)
        { type = "quest", questID = 66500, text = "Ways of Seeing (objective 3)",
          coord = { map = 2024, x = 0.460, y = 0.410 } },  -- APR route coord (converted)
        { type = "quest", questID = 66500, text = "Ways of Seeing (objective 4)",
          coord = { map = 2024, x = 0.460, y = 0.386 } },  -- APR route coord (converted)
        { type = "quest", questID = 66699, text = "Ask the Locals (objective 1)",
          coord = { map = 2024, x = 0.468, y = 0.386 } },  -- APR route coord (converted)
        { type = "quest", questID = 66699, text = "Ask the Locals (objective 2)",
          coord = { map = 2024, x = 0.463, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest", questID = 66699, text = "Ask the Locals (objective 3)",
          coord = { map = 2024, x = 0.457, y = 0.388 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66699, text = "Turn in: Ask the Locals",
          coord = { map = 2024, x = 0.457, y = 0.388 } },  -- APR route coord (converted)
        { type = "accept", questID = 65864, text = "Catch the Caravan",
          coord = { map = 2024, x = 0.457, y = 0.388 } },  -- giver coord: ATT
        { type = "turnin", questID = 66500, text = "Turn in: Ways of Seeing",
          coord = { map = 2024, x = 0.477, y = 0.402 } },  -- APR route coord (converted)
        { type = "quest", questID = 65864, text = "Catch the Caravan (objective 1)",
          coord = { map = 2024, x = 0.352, y = 0.370 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65864, text = "Turn in: Catch the Caravan",
          coord = { map = 2024, x = 0.352, y = 0.370 } },  -- APR route coord (converted)
        { type = "accept", questID = 65868, text = "Those Aren't for Chewing",
          coord = { map = 2024, x = 0.354, y = 0.369 } },  -- giver coord: ATT
        { type = "accept", questID = 65866, text = "Snap the Traps",
          coord = { map = 2024, x = 0.353, y = 0.369 } },  -- giver coord: ATT
        { type = "accept", questID = 65867, text = "Howling in the Big Tree Hills",
          coord = { map = 2024, x = 0.353, y = 0.369 } },  -- giver coord: ATT
        { type = "quest", questID = 65867, text = "Howling in the Big Tree Hills (objective 1)",
          coord = { map = 2024, x = 0.356, y = 0.347 } },  -- APR route coord (converted)
        { type = "quest", questID = 65867, text = "Howling in the Big Tree Hills (objective 2)",
          coord = { map = 2024, x = 0.349, y = 0.326 } },  -- APR route coord (converted)
        { type = "quest", questID = 65867, text = "Howling in the Big Tree Hills (objective 3)",
          coord = { map = 2024, x = 0.339, y = 0.331 } },  -- APR route coord (converted)
        { type = "quest", questID = 65868, text = "Those Aren't for Chewing (objective 1)",
          coord = { map = 2024, x = 0.353, y = 0.335 } },  -- APR route coord (converted)
        { type = "quest", questID = 65866, text = "Snap the Traps (objective 1)",
          coord = { map = 2024, x = 0.353, y = 0.335 } },  -- APR route coord (converted)
        { type = "quest", questID = 67173, text = "Thieving Gnolls (objective 1)",
          coord = { map = 2024, x = 0.368, y = 0.325 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 65866, text = "Turn in: Snap the Traps",
          coord = { map = 2024, x = 0.343, y = 0.313 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65868, text = "Turn in: Those Aren't for Chewing",
          coord = { map = 2024, x = 0.343, y = 0.313 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65867, text = "Turn in: Howling in the Big Tree Hills",
          coord = { map = 2024, x = 0.343, y = 0.313 } },  -- APR route coord (converted)
        { type = "accept", questID = 65871, text = "Gnoll Way Out",
          coord = { map = 2024, x = 0.344, y = 0.311 } },  -- giver coord: ATT
        { type = "accept", questID = 65870, text = "Supplies!",
          coord = { map = 2024, x = 0.343, y = 0.310 } },  -- giver coord: ATT
        { type = "accept", questID = 65872, text = "Ill Gnolls with Ill Intent",
          coord = { map = 2024, x = 0.343, y = 0.310 } },  -- giver coord: ATT
        { type = "accept", questID = 65873, text = "Leader of the Shadepaw Pack",
          coord = { map = 2024, x = 0.343, y = 0.310 } },  -- giver coord: ATT
        { type = "quest", questID = 65870, text = "Supplies! (objective 3)",
          coord = { map = 2024, x = 0.339, y = 0.304 } },  -- APR route coord (converted)
        { type = "quest", questID = 65870, text = "Supplies! (objective 1)",
          coord = { map = 2024, x = 0.335, y = 0.295 } },  -- APR route coord (converted)
        { type = "quest", questID = 65873, text = "Leader of the Shadepaw Pack (objective 1)",
          coord = { map = 2024, x = 0.340, y = 0.268 } },  -- APR route coord (converted)
        { type = "quest", questID = 65870, text = "Supplies! (objective 2)",
          coord = { map = 2024, x = 0.346, y = 0.276 } },  -- APR route coord (converted)
        { type = "quest", questID = 65871, text = "Gnoll Way Out (objective 1,2)",
          coord = { map = 2024, x = 0.341, y = 0.280 } },  -- APR route coord (converted)
        { type = "quest", questID = 65872, text = "Ill Gnolls with Ill Intent (objective 1)",
          coord = { map = 2024, x = 0.341, y = 0.280 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65870, text = "Turn in: Supplies!",
          coord = { map = 2024, x = 0.344, y = 0.310 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65872, text = "Turn in: Ill Gnolls with Ill Intent",
          coord = { map = 2024, x = 0.344, y = 0.310 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65873, text = "Turn in: Leader of the Shadepaw Pack",
          coord = { map = 2024, x = 0.344, y = 0.310 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65871, text = "Turn in: Gnoll Way Out",
          coord = { map = 2024, x = 0.344, y = 0.311 } },  -- APR route coord (converted)
        { type = "accept", questID = 66239, text = "Spreading Decay",
          coord = { map = 2024, x = 0.344, y = 0.310 } },  -- giver coord: ATT
        { type = "turnin", questID = 66239, text = "Turn in: Spreading Decay",
          coord = { map = 2024, x = 0.287, y = 0.348 } },  -- APR route coord (converted)
        { type = "accept", questID = 65869, text = "Another Ambush",
          coord = { map = 2024, x = 0.287, y = 0.348 } },  -- giver coord: ATT
        { type = "accept", questID = 71233, text = "Falling Water",
          coord = { map = 2024, x = 0.285, y = 0.351 } },  -- giver coord: ATT
        { type = "quest", questID = 65869, text = "Another Ambush (objective 1)",
          coord = { map = 2024, x = 0.287, y = 0.347 } },  -- APR route coord (converted)
        { type = "quest", questID = 65869, text = "Another Ambush (objective 2)",
          coord = { map = 2024, x = 0.286, y = 0.327 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65869, text = "Turn in: Another Ambush",
          coord = { map = 2024, x = 0.288, y = 0.347 } },  -- APR route coord (converted)
        { type = "accept", questID = 66026, text = "Urgent Action Required",
          coord = { map = 2024, x = 0.288, y = 0.347 } },  -- giver coord: ATT
        { type = "turnin", questID = 66026, text = "Turn in: Urgent Action Required",
          coord = { map = 2024, x = 0.206, y = 0.357 } },  -- APR route coord (converted)
        { type = "accept", questID = 66843, text = "Out of Lukh",
          coord = { map = 2024, x = 0.193, y = 0.269 } },  -- giver coord: ATT
        { type = "accept", questID = 66844, text = "The Great Shokhari",
          coord = { map = 2024, x = 0.190, y = 0.240 } },  -- giver coord: ATT
        { type = "accept", questID = 66839, text = "It's Brew Time!",
          coord = { map = 2024, x = 0.190, y = 0.233 } },  -- giver coord: ATT
        { type = "turnin", questID = 71233, text = "Turn in: Falling Water",
          coord = { map = 2024, x = 0.187, y = 0.245 } },  -- APR route coord (converted)
        { type = "accept", questID = 66837, text = "Nothing for Breakfast",
          coord = { map = 2024, x = 0.187, y = 0.245 } },  -- giver coord: ATT
        { type = "accept", questID = 66838, text = "It's Cold Up Here",
          coord = { map = 2024, x = 0.187, y = 0.245 } },  -- giver coord: ATT
        { type = "quest", questID = 66844, text = "The Great Shokhari (objective 1)",
          coord = { map = 2024, x = 0.133, y = 0.263 } },  -- APR route coord (converted)
        { type = "quest", questID = 66843, text = "Out of Lukh (objective 1)",
          coord = { map = 2024, x = 0.156, y = 0.275 } },  -- APR route coord (converted)
        { type = "quest", questID = 66837, text = "Nothing for Breakfast (objective 1,2)",
          coord = { map = 2024, x = 0.165, y = 0.273 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66843, text = "Turn in: Out of Lukh",
          coord = { map = 2024, x = 0.193, y = 0.269 } },  -- APR route coord (converted)
        { type = "quest", questID = 66839, text = "It's Brew Time! (objective 1)",
          coord = { map = 2024, x = 0.213, y = 0.263 } },  -- APR route coord (converted)
        { type = "quest", questID = 66838, text = "It's Cold Up Here (objective 1)",
          coord = { map = 2024, x = 0.213, y = 0.263 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66844, text = "Turn in: The Great Shokhari",
          coord = { map = 2024, x = 0.190, y = 0.240 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66839, text = "Turn in: It's Brew Time!",
          coord = { map = 2024, x = 0.190, y = 0.233 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66837, text = "Turn in: Nothing for Breakfast",
          coord = { map = 2024, x = 0.187, y = 0.245 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66838, text = "Turn in: It's Cold Up Here",
          coord = { map = 2024, x = 0.187, y = 0.245 } },  -- APR route coord (converted)
        { type = "accept", questID = 66841, text = "A Shard of the Past",
          coord = { map = 2024, x = 0.192, y = 0.247 } },  -- giver coord: ATT
        { type = "accept", questID = 66840, text = "Water Safety",
          coord = { map = 2024, x = 0.185, y = 0.237 } },  -- giver coord: ATT
        { type = "quest", questID = 66840, text = "Water Safety (objective 1)",
          coord = { map = 2024, x = 0.188, y = 0.236 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66840, text = "Turn in: Water Safety",
          coord = { map = 2024, x = 0.185, y = 0.237 } },  -- APR route coord (converted)
        { type = "quest", questID = 66841, text = "A Shard of the Past (objective 1)",
          coord = { map = 2024, x = 0.176, y = 0.282 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66841, text = "Turn in: A Shard of the Past",
          coord = { map = 2024, x = 0.187, y = 0.237 } },  -- APR route coord (converted)
        { type = "accept", questID = 66845, text = "Legendary Foil",
          coord = { map = 2024, x = 0.187, y = 0.244 } },  -- giver coord: ATT
        { type = "quest", questID = 66845, text = "Legendary Foil (objective 1)",
          coord = { map = 2024, x = 0.173, y = 0.261 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66845, text = "Turn in: Legendary Foil",
          coord = { map = 2024, x = 0.187, y = 0.244 } },  -- APR route coord (converted)
        { type = "accept", questID = 66846, text = "The Heart of the Deck",
          coord = { map = 2024, x = 0.188, y = 0.244 } },  -- giver coord: ATT
        { type = "quest", questID = 66846, text = "The Heart of the Deck (objective 1)",
          coord = { map = 2024, x = 0.187, y = 0.244 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66846, text = "Turn in: The Heart of the Deck",
          coord = { map = 2024, x = 0.187, y = 0.244 } },  -- APR route coord (converted)
        { type = "accept", questID = 65838, text = "Breaching the Brackenhide",
          coord = { map = 2024, x = 0.205, y = 0.357 } },  -- giver coord: ATT
        { type = "quest", questID = 65838, text = "Breaching the Brackenhide (objective 2)",
          coord = { map = 2024, x = 0.189, y = 0.370 } },  -- APR route coord (converted)
        { type = "quest", questID = 65838, text = "Breaching the Brackenhide (objective 1)",
          coord = { map = 2024, x = 0.184, y = 0.347 } },  -- APR route coord (converted)
        { type = "quest", questID = 65838, text = "Breaching the Brackenhide (objective 3)",
          coord = { map = 2024, x = 0.176, y = 0.370 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65838, text = "Turn in: Breaching the Brackenhide",
          coord = { map = 2024, x = 0.168, y = 0.373 } },  -- APR route coord (converted)
        { type = "accept", questID = 65846, text = "Ley Litter",
          coord = { map = 2024, x = 0.167, y = 0.373 } },  -- giver coord: ATT
        { type = "accept", questID = 65844, text = "Cut Out the Rot",
          coord = { map = 2024, x = 0.167, y = 0.373 } },  -- giver coord: ATT
        { type = "accept", questID = 65845, text = "Echoes of the Fallen",
          coord = { map = 2024, x = 0.167, y = 0.372 } },  -- giver coord: ATT
        { type = "quest", questID = 65845, text = "Echoes of the Fallen (objective 1)",
          coord = { map = 2024, x = 0.179, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest", questID = 65844, text = "Cut Out the Rot (objective 1,2)",
          coord = { map = 2024, x = 0.179, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest", questID = 65846, text = "Ley Litter (objective 1)",
          coord = { map = 2024, x = 0.179, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest", questID = 65841, text = "Stop the Spread (objective 1)",
          coord = { map = 2024, x = 0.179, y = 0.381 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 65846, text = "Turn in: Ley Litter",
          coord = { map = 2024, x = 0.168, y = 0.373 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65844, text = "Turn in: Cut Out the Rot",
          coord = { map = 2024, x = 0.168, y = 0.373 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65845, text = "Turn in: Echoes of the Fallen",
          coord = { map = 2024, x = 0.167, y = 0.372 } },  -- APR route coord (converted)
        { type = "accept", questID = 65848, text = "Tome-ward Bound",
          coord = { map = 2024, x = 0.167, y = 0.373 } },  -- giver coord: ATT
        { type = "quest", questID = 65848, text = "Tome-ward Bound (objective 1)",
          coord = { map = 2024, x = 0.167, y = 0.372 } },  -- APR route coord (converted)
        { type = "quest", questID = 65848, text = "Tome-ward Bound (objective 2)",
          coord = { map = 2024, x = 0.167, y = 0.372 } },  -- APR route coord (converted)
        { type = "quest", questID = 65848, text = "Tome-ward Bound (objective 3)",
          coord = { map = 2024, x = 0.156, y = 0.381 } },  -- APR route coord (converted)
        { type = "quest", questID = 65848, text = "Tome-ward Bound (objective 4)",
          coord = { map = 2024, x = 0.156, y = 0.381 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65848, text = "Turn in: Tome-ward Bound",
          coord = { map = 2024, x = 0.153, y = 0.394 } },  -- APR route coord (converted)
        { type = "accept", questID = 65847, text = "Realignment",
          coord = { map = 2024, x = 0.153, y = 0.394 } },  -- giver coord: ATT
        { type = "quest", questID = 65847, text = "Realignment (objective 1)",
          coord = { map = 2024, x = 0.154, y = 0.395 } },  -- APR route coord (converted)
        { type = "quest", questID = 65847, text = "Realignment (objective 2)",
          coord = { map = 2024, x = 0.155, y = 0.393 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65847, text = "Turn in: Realignment",
          coord = { map = 2024, x = 0.161, y = 0.414 } },  -- APR route coord (converted)
        { type = "accept", questID = 65849, text = "To Iskaara",
          coord = { map = 2024, x = 0.161, y = 0.415 } },  -- giver coord: ATT
        { type = "quest", questID = 69872, text = "Vakril, the Strongest Tuskarr (objective 1)",
          coord = { map = 2024, x = 0.173, y = 0.417 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 65849, text = "Turn in: To Iskaara",
          coord = { map = 2024, x = 0.132, y = 0.495 } },  -- APR route coord (converted)
        { type = "accept", questID = 66210, text = "Gather the Family",
          coord = { map = 2024, x = 0.132, y = 0.496 } },  -- giver coord: ATT
        { type = "accept", questID = 72435, text = "Orientation: Iskaara",
          coord = { map = 2024, x = 0.131, y = 0.493 } },  -- APR route coord (converted)
        { type = "accept", questID = 66218, text = "Scampering Scamps",
          coord = { map = 2024, x = 0.135, y = 0.482 } },  -- giver coord: ATT
        { type = "quest", questID = 72435, text = "Orientation: Iskaara (objective 4)",
          coord = { map = 2024, x = 0.129, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest", questID = 72435, text = "Orientation: Iskaara (objective 1)",
          coord = { map = 2024, x = 0.132, y = 0.485 } },  -- APR route coord (converted)
        { type = "quest", questID = 72435, text = "Orientation: Iskaara (objective 3)",
          coord = { map = 2024, x = 0.132, y = 0.488 } },  -- APR route coord (converted)
        { type = "quest", questID = 66210, text = "Gather the Family (objective 1) [1/4]",
          coord = { map = 2024, x = 0.135, y = 0.486 } },  -- APR route coord (converted)
        { type = "quest", questID = 66210, text = "Gather the Family (objective 1) [2/4]",
          coord = { map = 2024, x = 0.139, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 72435, text = "Orientation: Iskaara (objective 2)",
          coord = { map = 2024, x = 0.139, y = 0.501 } },  -- APR route coord (converted)
        { type = "quest", questID = 66210, text = "Gather the Family (objective 1) [3/4]",
          coord = { map = 2024, x = 0.125, y = 0.503 } },  -- APR route coord (converted)
        { type = "accept", questID = 66213, text = "The Weave of a Tale",
          coord = { map = 2024, x = 0.124, y = 0.494 } },  -- giver coord: ATT
        { type = "quest", questID = 66213, text = "The Weave of a Tale (objective 1)",
          coord = { map = 2024, x = 0.124, y = 0.493 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66213, text = "Turn in: The Weave of a Tale",
          coord = { map = 2024, x = 0.124, y = 0.494 } },  -- APR route coord (converted)
        { type = "quest", questID = 66210, text = "Gather the Family (objective 1)",
          coord = { map = 2024, x = 0.125, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 66210, text = "Gather the Family (objective 2)",
          coord = { map = 2024, x = 0.131, y = 0.486 } },  -- APR route coord (converted)
        { type = "turnin", questID = 72435, text = "Turn in: Orientation: Iskaara",
          coord = { map = 2024, x = 0.131, y = 0.493 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66210, text = "Turn in: Gather the Family",
          coord = { map = 2024, x = 0.132, y = 0.495 } },  -- APR route coord (converted)
        { type = "accept", questID = 65850, text = "The Cycle of the Sea",
          coord = { map = 2024, x = 0.133, y = 0.495 } },  -- giver coord: ATT
        { type = "accept", questID = 66558, text = "Rowie",
          coord = { map = 2024, x = 0.138, y = 0.476 } },  -- giver coord: ATT
        { type = "quest", questID = 66218, text = "Scampering Scamps (objective 1)",
          coord = { map = 2024, x = 0.106, y = 0.469 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66218, text = "Turn in: Scampering Scamps",
          coord = { map = 2024, x = 0.106, y = 0.469 } },  -- APR route coord (converted)
        { type = "accept", questID = 66223, text = "Can We Keep It?",
          coord = { map = 2024, x = 0.106, y = 0.469 } },  -- giver coord: ATT
        { type = "quest", questID = 66223, text = "Can We Keep It? (objective 1)",
          coord = { map = 2024, x = 0.139, y = 0.495 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66223, text = "Turn in: Can We Keep It?",
          coord = { map = 2024, x = 0.106, y = 0.469 } },  -- APR route coord (converted)
        { type = "accept", questID = 66781, text = "A Matter of Taste",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- giver coord: ATT
        { type = "quest", questID = 66781, text = "A Matter of Taste (objective 1)",
          coord = { map = 2024, x = 0.072, y = 0.451 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66781, text = "Turn in: A Matter of Taste",
          coord = { map = 2024, x = 0.076, y = 0.444 } },  -- APR route coord (converted)
        { type = "accept", questID = 66164, text = "Fishy Fingers",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- giver coord: ATT
        { type = "accept", questID = 66154, text = "Salivatory Samples",
          coord = { map = 2024, x = 0.077, y = 0.443 } },  -- giver coord: ATT
        { type = "accept", questID = 66147, text = "Crystals in the Water",
          coord = { map = 2024, x = 0.076, y = 0.442 } },  -- giver coord: ATT
        { type = "quest", questID = 66147, text = "Crystals in the Water (objective 1)",
          coord = { map = 2024, x = 0.102, y = 0.429 } },  -- APR route coord (converted)
        { type = "quest", questID = 66164, text = "Fishy Fingers (objective 1)",
          coord = { map = 2024, x = 0.101, y = 0.433 } },  -- APR route coord (converted)
        { type = "quest", questID = 66154, text = "Salivatory Samples (objective 1)",
          coord = { map = 2024, x = 0.103, y = 0.433 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66147, text = "Turn in: Crystals in the Water",
          coord = { map = 2024, x = 0.076, y = 0.442 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66154, text = "Turn in: Salivatory Samples",
          coord = { map = 2024, x = 0.077, y = 0.443 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66164, text = "Turn in: Fishy Fingers",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- APR route coord (converted)
        { type = "accept", questID = 66175, text = "Field Experiment",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- giver coord: ATT
        { type = "quest", questID = 66175, text = "Field Experiment (objective 1)",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66175, text = "Turn in: Field Experiment",
          coord = { map = 2024, x = 0.077, y = 0.443 } },  -- APR route coord (converted)
        { type = "accept", questID = 66177, text = "No Dwarf Left Behind",
          coord = { map = 2024, x = 0.076, y = 0.443 } },  -- giver coord: ATT
        { type = "accept", questID = 66232, text = "Afront 'Till A Salt",
          coord = { map = 2024, x = 0.075, y = 0.443 } },  -- giver coord: ATT
        { type = "quest", questID = 66177, text = "No Dwarf Left Behind (objective 1)",
          coord = { map = 2024, x = 0.094, y = 0.425 } },  -- APR route coord (converted)
        { type = "quest", questID = 66177, text = "No Dwarf Left Behind (objective 2)",
          coord = { map = 2024, x = 0.100, y = 0.413 } },  -- APR route coord (converted)
        { type = "quest", questID = 66177, text = "No Dwarf Left Behind (objective 3)",
          coord = { map = 2024, x = 0.100, y = 0.397 } },  -- APR route coord (converted)
        { type = "quest", questID = 66177, text = "No Dwarf Left Behind (objective 4)",
          coord = { map = 2024, x = 0.106, y = 0.412 } },  -- APR route coord (converted)
        { type = "quest", questID = 66232, text = "Afront 'Till A Salt (objective 1)",
          coord = { map = 2024, x = 0.099, y = 0.416 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66177, text = "Turn in: No Dwarf Left Behind",
          coord = { map = 2024, x = 0.108, y = 0.412 } },  -- APR route coord (converted)
        { type = "accept", questID = 66187, text = "Mad Mordigan & The Crystal King",
          coord = { map = 2024, x = 0.108, y = 0.412 } },  -- giver coord: ATT
        { type = "quest", questID = 66187, text = "Mad Mordigan & The Crystal King (objective 1)",
          coord = { map = 2024, x = 0.112, y = 0.412 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66187, text = "Turn in: Mad Mordigan & The Crystal King",
          coord = { map = 2024, x = 0.108, y = 0.412 } },  -- APR route coord (converted)
        { type = "accept", questID = 66559, text = "Back To Camp",
          coord = { map = 2024, x = 0.108, y = 0.412 } },  -- giver coord: ATT
        { type = "turnin", questID = 66559, text = "Turn in: Back To Camp",
          coord = { map = 2024, x = 0.077, y = 0.443 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66232, text = "Turn in: Afront 'Till A Salt",
          coord = { map = 2024, x = 0.075, y = 0.443 } },  -- APR route coord (converted)
        { type = "quest", questID = 65850, text = "The Cycle of the Sea (objective 1)",
          coord = { map = 2024, x = 0.132, y = 0.495 } },  -- APR route coord (converted)
        { type = "quest", questID = 65850, text = "The Cycle of the Sea (objective 2)",
          coord = { map = 2024, x = 0.132, y = 0.502 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65850, text = "Turn in: The Cycle of the Sea",
          coord = { map = 2024, x = 0.129, y = 0.504 } },  -- APR route coord (converted)
        { type = "accept", questID = 65911, text = "Azure Alignment",
          coord = { map = 2024, x = 0.129, y = 0.504 } },  -- giver coord: ATT
        { type = "quest", questID = 66558, text = "Rowie (objective 1)",
          coord = { map = 2024, x = 0.161, y = 0.504 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66558, text = "Turn in: Rowie",
          coord = { map = 2024, x = 0.161, y = 0.504 } },  -- APR route coord (converted)
        { type = "accept", questID = 70129, text = "Toejam the Terrible",
          coord = { map = 2024, x = 0.161, y = 0.504 } },  -- giver coord: ATT
        { type = "quest", questID = 70129, text = "Toejam the Terrible (objective 1)",
          coord = { map = 2024, x = 0.168, y = 0.493 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70129, text = "Turn in: Toejam the Terrible",
          coord = { map = 2024, x = 0.138, y = 0.490 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65911, text = "Turn in: Azure Alignment",
          coord = { map = 2024, x = 0.395, y = 0.630 } },  -- APR route coord (converted)
        { type = "accept", questID = 66027, text = "Calling the Blue Dragons",
          coord = { map = 2024, x = 0.395, y = 0.630 } },  -- giver coord: ATT
        { type = "quest", questID = 66027, text = "Calling the Blue Dragons (objective 1)",
          coord = { map = 2024, x = 0.395, y = 0.630 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66027, text = "Turn in: Calling the Blue Dragons",
          coord = { map = 2024, x = 0.395, y = 0.630 } },  -- APR route coord (converted)
        { type = "accept", questID = 65886, text = "To Rhonin's Shield",
          coord = { map = 2024, x = 0.395, y = 0.630 } },  -- giver coord: ATT
        { type = "accept", questID = 66391, text = "To the Ruins!",
          coord = { map = 2024, x = 0.634, y = 0.580 } },  -- giver coord: ATT
        { type = "turnin", questID = 66391, text = "Turn in: To the Ruins!",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 66353, text = "R.A.D. Anomalies",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- giver coord: ATT
        { type = "accept", questID = 66352, text = "What the Enemy Knows",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- giver coord: ATT
        { type = "quest", questID = 66353, text = "R.A.D. Anomalies (objective 1)",
          coord = { map = 2024, x = 0.659, y = 0.595 } },  -- APR route coord (converted)
        { type = "quest", questID = 66352, text = "What the Enemy Knows (objective 1)",
          coord = { map = 2024, x = 0.658, y = 0.595 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66353, text = "Turn in: R.A.D. Anomalies",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66352, text = "Turn in: What the Enemy Knows",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- APR route coord (converted)
        { type = "accept", questID = 66422, text = "The Expedition Continues!",
          coord = { map = 2024, x = 0.650, y = 0.586 } },  -- giver coord: ATT
        { type = "turnin", questID = 66422, text = "Turn in: The Expedition Continues!",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- APR route coord (converted)
        { type = "accept", questID = 66423, text = "Worries and Validations",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- giver coord: ATT
        { type = "quest", questID = 66423, text = "Worries and Validations (objective 1)",
          coord = { map = 2024, x = 0.656, y = 0.607 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66423, text = "Turn in: Worries and Validations",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- APR route coord (converted)
        { type = "accept", questID = 66425, text = "Arcane Overload",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- giver coord: ATT
        { type = "quest", questID = 66425, text = "Arcane Overload (objective 1)",
          coord = { map = 2024, x = 0.653, y = 0.613 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66425, text = "Turn in: Arcane Overload",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- APR route coord (converted)
        { type = "accept", questID = 66426, text = "Running Out of Time",
          coord = { map = 2024, x = 0.656, y = 0.608 } },  -- giver coord: ATT
        { type = "turnin", questID = 66426, text = "Turn in: Running Out of Time",
          coord = { map = 2024, x = 0.685, y = 0.605 } },  -- APR route coord (converted)
        { type = "accept", questID = 66427, text = "A Looming Menace",
          coord = { map = 2024, x = 0.685, y = 0.605 } },  -- giver coord: ATT
        { type = "quest", questID = 66427, text = "A Looming Menace (objective 1)",
          coord = { map = 2024, x = 0.681, y = 0.616 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66427, text = "Turn in: A Looming Menace",
          coord = { map = 2024, x = 0.685, y = 0.605 } },  -- APR route coord (converted)
        { type = "accept", questID = 66428, text = "Friendship For Granted",
          coord = { map = 2024, x = 0.685, y = 0.604 } },  -- giver coord: ATT
        { type = "quest", questID = 66428, text = "Friendship For Granted (objective 1)",
          coord = { map = 2024, x = 0.686, y = 0.604 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66428, text = "Turn in: Friendship For Granted",
          coord = { map = 2024, x = 0.685, y = 0.605 } },  -- APR route coord (converted)
        { type = "accept", questID = 66429, text = "I Will Remember",
          coord = { map = 2024, x = 0.695, y = 0.604 } },  -- giver coord: ATT
        { type = "turnin", questID = 66429, text = "Turn in: I Will Remember",
          coord = { map = 2024, x = 0.637, y = 0.589 } },  -- APR route coord (converted)
        { type = "accept", questID = 66709, text = "Field Medic 101",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- giver coord: ATT
        { type = "quest", questID = 66709, text = "Field Medic 101 (objective 1)",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- APR route coord (converted)
        { type = "quest", questID = 66709, text = "Field Medic 101 (objective 2)",
          coord = { map = 2024, x = 0.592, y = 0.398 } },  -- APR route coord (converted)
        { type = "quest", questID = 66709, text = "Field Medic 101 (objective 3)",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- APR route coord (converted)
        { type = "quest", questID = 66709, text = "Field Medic 101 (objective 4)",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66709, text = "Turn in: Field Medic 101",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- APR route coord (converted)
        { type = "accept", questID = 66715, text = "The Extraction",
          coord = { map = 2024, x = 0.593, y = 0.397 } },  -- giver coord: ATT
        { type = "quest", questID = 66715, text = "The Extraction (objective 1)",
          coord = { map = 2024, x = 0.584, y = 0.420 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66715, text = "Turn in: The Extraction",
          coord = { map = 2024, x = 0.584, y = 0.420 } },  -- APR route coord (converted)
        { type = "accept", questID = 66703, text = "Snowball Effect",
          coord = { map = 2024, x = 0.584, y = 0.420 } },  -- giver coord: ATT
        { type = "quest", questID = 66703, text = "Snowball Effect (objective 1)",
          coord = { map = 2024, x = 0.580, y = 0.423 } },  -- APR route coord (converted)
        { type = "quest", questID = 66718, text = "Gnolls Must Die (objective 2)",
          coord = { map = 2024, x = 0.578, y = 0.451 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "quest", questID = 66718, text = "Gnolls Must Die (objective 1)",
          coord = { map = 2024, x = 0.580, y = 0.423 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66703, text = "Turn in: Snowball Effect",
          coord = { map = 2024, x = 0.584, y = 0.420 } },  -- APR route coord (converted)
        { type = "accept", questID = 67050, text = "Frostbite: Causes and Symptoms",
          coord = { map = 2024, x = 0.584, y = 0.420 } },  -- giver coord: ATT
        { type = "quest", questID = 67050, text = "Frostbite: Causes and Symptoms (objective 1)",
          coord = { map = 2024, x = 0.582, y = 0.420 } },  -- APR route coord (converted)
        { type = "quest", questID = 67050, text = "Frostbite: Causes and Symptoms (objective 2)",
          coord = { map = 2024, x = 0.585, y = 0.405 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67050, text = "Turn in: Frostbite: Causes and Symptoms",
          coord = { map = 2024, x = 0.585, y = 0.405 } },  -- APR route coord (converted)
        { type = "accept", questID = 66730, text = "True Survivors",
          coord = { map = 2024, x = 0.585, y = 0.405 } },  -- giver coord: ATT
        { type = "turnin", questID = 66730, text = "Turn in: True Survivors",
          coord = { map = 2024, x = 0.588, y = 0.349 } },  -- APR route coord (converted)
        { type = "quest", questID = 65886, text = "To Rhonin's Shield (objective 1)",
          coord = { map = 2024, x = 0.656, y = 0.258 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65886, text = "Turn in: To Rhonin's Shield",
          coord = { map = 2024, x = 0.658, y = 0.253 } },  -- APR route coord (converted)
        { type = "accept", questID = 65887, text = "To the Mountain",
          coord = { map = 2024, x = 0.658, y = 0.253 } },  -- giver coord: ATT
        { type = "accept", questID = 67299, text = "Drakes be Gone",
          coord = { map = 2024, x = 0.658, y = 0.253 } },  -- giver coord: ATT
        { type = "quest", questID = 67299, text = "Drakes be Gone (objective 1)",
          coord = { map = 2024, x = 0.661, y = 0.256 } },  -- APR route coord (converted)
        { type = "turnin", questID = 67299, text = "Turn in: Drakes be Gone",
          coord = { map = 2024, x = 0.658, y = 0.253 } },  -- APR route coord (converted)
        { type = "quest", questID = 69895, text = "Summoned Destroyer (objective 1)",
          coord = { map = 2024, x = 0.701, y = 0.332 } },  -- APR route coord (converted); no accept step in APR: area/bonus/rare quest, auto-accepted on arrival (UNVERIFIED)
        { type = "turnin", questID = 65887, text = "Turn in: To the Mountain",
          coord = { map = 2024, x = 0.700, y = 0.352 } },  -- APR route coord (converted)
        { type = "accept", questID = 65943, text = "Primal Offensive",
          coord = { map = 2024, x = 0.700, y = 0.352 } },  -- giver coord: ATT
        { type = "accept", questID = 65944, text = "Lava Burst",
          coord = { map = 2024, x = 0.700, y = 0.353 } },  -- giver coord: ATT
        { type = "accept", questID = 66647, text = "Elemental Unfocus",
          coord = { map = 2024, x = 0.700, y = 0.353 } },  -- giver coord: ATT
        { type = "quest", questID = 66647, text = "Elemental Unfocus (objective 1)",
          coord = { map = 2024, x = 0.729, y = 0.386 } },  -- APR route coord (converted)
        { type = "quest", questID = 65944, text = "Lava Burst (objective 1)",
          coord = { map = 2024, x = 0.725, y = 0.372 } },  -- APR route coord (converted)
        { type = "quest", questID = 65943, text = "Primal Offensive (objective 1)",
          coord = { map = 2024, x = 0.725, y = 0.372 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65943, text = "Turn in: Primal Offensive",
          coord = { map = 2024, x = 0.745, y = 0.378 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65944, text = "Turn in: Lava Burst",
          coord = { map = 2024, x = 0.745, y = 0.378 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66647, text = "Turn in: Elemental Unfocus",
          coord = { map = 2024, x = 0.745, y = 0.378 } },  -- APR route coord (converted)
        { type = "accept", questID = 65977, text = "Kirin Tor Recovery",
          coord = { map = 2024, x = 0.745, y = 0.378 } },  -- giver coord: ATT
        { type = "accept", questID = 65958, text = "Primal Power",
          coord = { map = 2024, x = 0.745, y = 0.378 } },  -- giver coord: ATT
        { type = "quest", questID = 65977, text = "Kirin Tor Recovery (objective 1)",
          coord = { map = 2024, x = 0.755, y = 0.380 } },  -- APR route coord (converted)
        { type = "quest", questID = 65958, text = "Primal Power (objective 1)",
          coord = { map = 2024, x = 0.755, y = 0.380 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65958, text = "Turn in: Primal Power",
          coord = { map = 2024, x = 0.769, y = 0.394 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65977, text = "Turn in: Kirin Tor Recovery",
          coord = { map = 2024, x = 0.769, y = 0.394 } },  -- APR route coord (converted)
        { type = "accept", questID = 66007, text = "Free Air",
          coord = { map = 2024, x = 0.769, y = 0.394 } },  -- giver coord: ATT
        { type = "quest", questID = 66007, text = "Free Air (objective 1)",
          coord = { map = 2024, x = 0.776, y = 0.390 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66007, text = "Turn in: Free Air",
          coord = { map = 2024, x = 0.784, y = 0.400 } },  -- APR route coord (converted)
        { type = "accept", questID = 66009, text = "In Defense of Vakthros",
          coord = { map = 2024, x = 0.784, y = 0.400 } },  -- giver coord: ATT
        { type = "quest", questID = 66009, text = "In Defense of Vakthros (objective 1)",
          coord = { map = 2024, x = 0.791, y = 0.365 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66009, text = "Turn in: In Defense of Vakthros",
          coord = { map = 2024, x = 0.780, y = 0.325 } },  -- APR route coord (converted)
        { type = "accept", questID = 70041, text = "The Storm-Eater's Fury",
          coord = { map = 2024, x = 0.780, y = 0.325 } },  -- giver coord: ATT
        { type = "quest", questID = 70041, text = "The Storm-Eater's Fury (objective 1)",
          coord = { map = 2024, x = 0.780, y = 0.324 } },  -- APR route coord (converted)
        { type = "quest", questID = 70041, text = "The Storm-Eater's Fury (objective 2)",
          coord = { map = 2024, x = 0.780, y = 0.324 } },  -- APR route coord (converted)
        { type = "quest", questID = 70041, text = "The Storm-Eater's Fury (objective 3)",
          coord = { map = 2024, x = 0.780, y = 0.324 } },  -- APR route coord (converted)
        { type = "quest", questID = 70041, text = "The Storm-Eater's Fury (objective 4)",
          coord = { map = 2024, x = 0.780, y = 0.324 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70041, text = "Turn in: The Storm-Eater's Fury",
          coord = { map = 2024, x = 0.782, y = 0.333 } },  -- APR route coord (converted)
        { type = "accept", questID = 66015, text = "The Blue Dragon Oathstone",
          coord = { map = 2024, x = 0.782, y = 0.333 } },  -- giver coord: ATT
        { type = "quest", questID = 66015, text = "The Blue Dragon Oathstone (objective 1)",
          coord = { map = 2024, x = 0.395, y = 0.631 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66015, text = "Turn in: The Blue Dragon Oathstone",
          coord = { map = 2024, x = 0.395, y = 0.631 } },  -- APR route coord (converted)
        { type = "accept", questID = 66244, text = "To Valdrakken",
          coord = { map = 2024, x = 0.395, y = 0.631 } },  -- giver coord: ATT
        { type = "quest", questID = 66244, text = "To Valdrakken (objective 1)",
          coord = { map = 2112, x = 0.619, y = 0.321 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66244, text = "Turn in: To Valdrakken",
          coord = { map = 2112, x = 0.580, y = 0.354 } },  -- APR route coord (converted)
        -- ===== Thaldraszus & Valdrakken =====
        { type = "accept", questID = 66159, text = "A Message Most Dire",
          coord = { map = 2112, x = 0.585, y = 0.357 } },  -- giver coord: ATT
        { type = "quest", questID = 66159, text = "A Message Most Dire (objective 1)",
          coord = { map = 2112, x = 0.580, y = 0.354 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66159, text = "Turn in: A Message Most Dire",
          coord = { map = 2112, x = 0.580, y = 0.354 } },  -- APR route coord (converted)
        { type = "accept", questID = 66163, text = "Nowhere to Hide",
          coord = { map = 2112, x = 0.593, y = 0.348 } },  -- giver coord: ATT
        { type = "accept", questID = 66166, text = "Eyes and Ears",
          coord = { map = 2112, x = 0.593, y = 0.348 } },  -- giver coord: ATT
        { type = "quest", questID = 66163, text = "Nowhere to Hide (objective 1)",
          coord = { map = 2112, x = 0.594, y = 0.347 } },  -- APR route coord (converted)
        { type = "quest", questID = 66166, text = "Eyes and Ears (objective 3)",
          coord = { map = 2112, x = 0.470, y = 0.477 } },  -- APR route coord (converted)
        { type = "quest", questID = 66166, text = "Eyes and Ears (objective 2)",
          coord = { map = 2112, x = 0.591, y = 0.547 } },  -- APR route coord (converted)
        { type = "quest", questID = 66166, text = "Eyes and Ears (objective 1)",
          coord = { map = 2112, x = 0.347, y = 0.613 } },  -- APR route coord (converted)
        { type = "quest", questID = 66163, text = "Nowhere to Hide (objective 2)",
          coord = { map = 2112, x = 0.495, y = 0.567 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66163, text = "Turn in: Nowhere to Hide",
          coord = { map = 2112, x = 0.547, y = 0.473 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66166, text = "Turn in: Eyes and Ears",
          coord = { map = 2112, x = 0.547, y = 0.473 } },  -- APR route coord (converted)
        { type = "accept", questID = 66167, text = "Southern Exposure",
          coord = { map = 2112, x = 0.547, y = 0.473 } },  -- giver coord: ATT
        { type = "quest", questID = 66167, text = "Southern Exposure (objective 1)",
          coord = { map = 2025, x = 0.359, y = 0.826 } },  -- APR route coord (converted)
        { type = "quest", questID = 66167, text = "Southern Exposure (objective 2)",
          coord = { map = 2025, x = 0.359, y = 0.826 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66167, text = "Turn in: Southern Exposure",
          coord = { map = 2025, x = 0.359, y = 0.826 } },  -- APR route coord (converted)
        { type = "accept", questID = 66169, text = "Vengeance, Served Hot",
          coord = { map = 2025, x = 0.358, y = 0.826 } },  -- giver coord: ATT
        { type = "accept", questID = 66246, text = "The Fog of Battle",
          coord = { map = 2025, x = 0.358, y = 0.826 } },  -- giver coord: ATT
        { type = "quest", questID = 66246, text = "The Fog of Battle (objective 1)",
          coord = { map = 2025, x = 0.362, y = 0.844 } },  -- APR route coord (converted)
        { type = "quest", questID = 66169, text = "Vengeance, Served Hot (objective 1)",
          coord = { map = 2025, x = 0.362, y = 0.844 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66169, text = "Turn in: Vengeance, Served Hot",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66246, text = "Turn in: The Fog of Battle",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- APR route coord (converted)
        { type = "accept", questID = 66245, text = "Remember the Fallen",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- giver coord: ATT
        { type = "accept", questID = 66247, text = "Slightly Used Weapons",
          coord = { map = 2025, x = 0.379, y = 0.833 } },  -- giver coord: ATT
        { type = "accept", questID = 66248, text = "Tying Things Together",
          coord = { map = 2025, x = 0.386, y = 0.834 } },  -- giver coord: ATT
        { type = "quest", questID = 66247, text = "Slightly Used Weapons (objective 1)",
          coord = { map = 2025, x = 0.389, y = 0.835 } },  -- APR route coord (converted)
        { type = "quest", questID = 66248, text = "Tying Things Together (objective 1)",
          coord = { map = 2025, x = 0.389, y = 0.835 } },  -- APR route coord (converted)
        { type = "quest", questID = 66245, text = "Remember the Fallen (objective 1)",
          coord = { map = 2025, x = 0.389, y = 0.835 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66247, text = "Turn in: Slightly Used Weapons",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66248, text = "Turn in: Tying Things Together",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66245, text = "Turn in: Remember the Fallen",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- APR route coord (converted)
        { type = "accept", questID = 66249, text = "Clear the Sky",
          coord = { map = 2025, x = 0.376, y = 0.831 } },  -- giver coord: ATT
        { type = "quest", questID = 66249, text = "Clear the Sky (objective 1)",
          coord = { map = 2025, x = 0.409, y = 0.839 } },  -- APR route coord (converted)
        { type = "quest", questID = 66249, text = "Clear the Sky (objective 2)",
          coord = { map = 2025, x = 0.409, y = 0.839 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66249, text = "Turn in: Clear the Sky",
          coord = { map = 2025, x = 0.406, y = 0.855 } },  -- APR route coord (converted)
        { type = "accept", questID = 66250, text = "Where's The Chief?",
          coord = { map = 2025, x = 0.406, y = 0.855 } },  -- giver coord: ATT
        { type = "quest", questID = 66250, text = "Where's The Chief? (objective 1)",
          coord = { map = 2025, x = 0.406, y = 0.855 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66250, text = "Turn in: Where's The Chief?",
          coord = { map = 2025, x = 0.402, y = 0.851 } },  -- APR route coord (converted)
        { type = "accept", questID = 66251, text = "Fire Fighter",
          coord = { map = 2025, x = 0.402, y = 0.851 } },  -- giver coord: ATT
        { type = "quest", questID = 66251, text = "Fire Fighter (objective 1)",
          coord = { map = 2025, x = 0.401, y = 0.866 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66251, text = "Turn in: Fire Fighter",
          coord = { map = 2025, x = 0.402, y = 0.851 } },  -- APR route coord (converted)
        { type = "accept", questID = 66252, text = "Reporting In",
          coord = { map = 2025, x = 0.402, y = 0.851 } },  -- giver coord: ATT
        { type = "turnin", questID = 66252, text = "Turn in: Reporting In",
          coord = { map = 2112, x = 0.560, y = 0.401 } },  -- APR route coord (converted)
        { type = "accept", questID = 66320, text = "The Flow of Time",
          coord = { map = 2112, x = 0.609, y = 0.390 } },  -- giver coord: ATT
        { type = "quest", questID = 66320, text = "The Flow of Time (objective 1)",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66320, text = "Turn in: The Flow of Time",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "accept", questID = 66080, text = "Temporal Difficulties",
          coord = { map = 2025, x = 0.575, y = 0.788 } },  -- giver coord: ATT
        { type = "quest", questID = 66080, text = "Temporal Difficulties (objective 1)",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66080, text = "Turn in: Temporal Difficulties",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- APR route coord (converted)
        { type = "accept", questID = 70136, text = "Haven't Got Time For the Pain",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- giver coord: ATT
        { type = "quest", questID = 70136, text = "Haven't Got Time For the Pain (objective 2)",
          coord = { map = 2025, x = 0.532, y = 0.774 } },  -- APR route coord (converted)
        { type = "quest", questID = 70136, text = "Haven't Got Time For the Pain (objective 3)",
          coord = { map = 2025, x = 0.527, y = 0.768 } },  -- APR route coord (converted)
        { type = "quest", questID = 70136, text = "Haven't Got Time For the Pain (objective 1)",
          coord = { map = 2025, x = 0.527, y = 0.768 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70136, text = "Turn in: Haven't Got Time For the Pain",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- APR route coord (converted)
        { type = "accept", questID = 66081, text = "Time is Running Out",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- giver coord: ATT
        { type = "accept", questID = 66082, text = "Time in a Bottle",
          coord = { map = 2025, x = 0.550, y = 0.756 } },  -- giver coord: ATT
        { type = "quest", questID = 66081, text = "Time is Running Out (objective 1)",
          coord = { map = 2025, x = 0.544, y = 0.773 } },  -- APR route coord (converted)
        { type = "quest", questID = 66082, text = "Time in a Bottle (objective 1)",
          coord = { map = 2025, x = 0.544, y = 0.773 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66081, text = "Turn in: Time is Running Out",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66082, text = "Turn in: Time in a Bottle",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "accept", questID = 66083, text = "Feels Like the First Time",
          coord = { map = 2025, x = 0.575, y = 0.787 } },  -- giver coord: ATT
        { type = "quest", questID = 66083, text = "Feels Like the First Time (objective 1)",
          coord = { map = 2025, x = 0.576, y = 0.784 } },  -- APR route coord (converted)
        { type = "quest", questID = 66083, text = "Feels Like the First Time (objective 2)",
          coord = { map = 2025, x = 0.577, y = 0.784 } },  -- APR route coord (converted)
        { type = "quest", questID = 66083, text = "Feels Like the First Time (objective 3)",
          coord = { map = 2025, x = 0.577, y = 0.784 } },  -- APR route coord (converted)
        { type = "quest", questID = 66083, text = "Feels Like the First Time (objective 4)",
          coord = { map = 2025, x = 0.577, y = 0.784 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66083, text = "Turn in: Feels Like the First Time",
          coord = { map = 2025, x = 0.575, y = 0.788 } },  -- APR route coord (converted)
        { type = "accept", questID = 66084, text = "Times Like These",
          coord = { map = 2025, x = 0.575, y = 0.788 } },  -- giver coord: ATT
        { type = "accept", questID = 66085, text = "If We Could Turn Back Time",
          coord = { map = 2025, x = 0.574, y = 0.789 } },  -- giver coord: ATT
        { type = "quest", questID = 66085, text = "If We Could Turn Back Time (objective 1)",
          coord = { map = 2025, x = 0.586, y = 0.782 } },  -- APR route coord (converted)
        { type = "quest", questID = 66085, text = "If We Could Turn Back Time (objective 2)",
          coord = { map = 2025, x = 0.598, y = 0.793 } },  -- APR route coord (converted)
        { type = "quest", questID = 66085, text = "If We Could Turn Back Time (objective 3)",
          coord = { map = 2025, x = 0.600, y = 0.793 } },  -- APR route coord (converted)
        { type = "quest", questID = 66085, text = "If We Could Turn Back Time (objective 4)",
          coord = { map = 2025, x = 0.600, y = 0.772 } },  -- APR route coord (converted)
        { type = "quest", questID = 66085, text = "If We Could Turn Back Time (objective 5)",
          coord = { map = 2025, x = 0.600, y = 0.772 } },  -- APR route coord (converted)
        { type = "quest", questID = 66084, text = "Times Like These (objective 1)",
          coord = { map = 2025, x = 0.594, y = 0.785 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66084, text = "Turn in: Times Like These",
          coord = { map = 2025, x = 0.575, y = 0.788 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66085, text = "Turn in: If We Could Turn Back Time",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "accept", questID = 66087, text = "Closing Time",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- giver coord: ATT
        { type = "quest", questID = 66087, text = "Closing Time (objective 1)",
          coord = { map = 2025, x = 0.571, y = 0.828 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66087, text = "Turn in: Closing Time",
          coord = { map = 2025, x = 0.575, y = 0.789 } },  -- APR route coord (converted)
        { type = "accept", questID = 65935, text = "Catching Up to Chromie",
          coord = { map = 2025, x = 0.575, y = 0.788 } },  -- giver coord: ATT
        { type = "quest", questID = 65935, text = "Catching Up to Chromie (objective 1)",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65935, text = "Turn in: Catching Up to Chromie",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 65947, text = "Time-Locked Timewalkers",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- giver coord: ATT
        { type = "accept", questID = 65948, text = "Cracks in Time",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- giver coord: ATT
        { type = "accept", questID = 66646, text = "Quelling Causalities",
          coord = { map = 2025, x = 0.596, y = 0.827 } },  -- giver coord: ATT
        { type = "quest", questID = 65948, text = "Cracks in Time (objective 1)",
          coord = { map = 2025, x = 0.586, y = 0.831 } },  -- APR route coord (converted)
        { type = "quest", questID = 65948, text = "Cracks in Time (objective 2)",
          coord = { map = 2025, x = 0.607, y = 0.805 } },  -- APR route coord (converted)
        { type = "quest", questID = 65947, text = "Time-Locked Timewalkers (objective 1)",
          coord = { map = 2025, x = 0.595, y = 0.814 } },  -- APR route coord (converted)
        { type = "quest", questID = 65948, text = "Cracks in Time (objective 3)",
          coord = { map = 2025, x = 0.595, y = 0.814 } },  -- APR route coord (converted)
        { type = "quest", questID = 66646, text = "Quelling Causalities (objective 1)",
          coord = { map = 2025, x = 0.595, y = 0.814 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65948, text = "Turn in: Cracks in Time",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65947, text = "Turn in: Time-Locked Timewalkers",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66646, text = "Turn in: Quelling Causalities",
          coord = { map = 2025, x = 0.596, y = 0.827 } },  -- APR route coord (converted)
        { type = "accept", questID = 65938, text = "The Once and Future Team",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- giver coord: ATT
        { type = "quest", questID = 65938, text = "The Once and Future Team (objective 1)",
          coord = { map = 2025, x = 0.606, y = 0.834 } },  -- APR route coord (converted)
        { type = "quest", questID = 65938, text = "The Once and Future Team (objective 2)",
          coord = { map = 2025, x = 0.606, y = 0.838 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65938, text = "Turn in: The Once and Future Team",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "accept", questID = 65962, text = "The Never-Final Countdown",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- giver coord: ATT
        { type = "quest", questID = 65962, text = "The Never-Final Countdown (objective 1)",
          coord = { map = 2025, x = 0.596, y = 0.817 } },  -- APR route coord (converted)
        { type = "turnin", questID = 65962, text = "Turn in: The Never-Final Countdown",
          coord = { map = 2025, x = 0.600, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 70040, text = "Tumbling Through Time",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "quest", questID = 70040, text = "Tumbling Through Time (objective 2)",
          coord = { map = 2025, x = 0.602, y = 0.818 } },  -- APR route coord (converted)
        { type = "quest", questID = 70040, text = "Tumbling Through Time (objective 1)",
          coord = { map = 2025, x = 0.595, y = 0.825 } },  -- APR route coord (converted)
        { type = "quest", questID = 70040, text = "Tumbling Through Time (objective 3)",
          coord = { map = 2025, x = 0.593, y = 0.822 } },  -- APR route coord (converted)
        { type = "quest", questID = 70040, text = "Tumbling Through Time (objective 4)",
          coord = { map = 2025, x = 0.600, y = 0.824 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70040, text = "Turn in: Tumbling Through Time",
          coord = { map = 2025, x = 0.600, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 66028, text = "To the Future!",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 66029, text = "Temporal Tuning",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "quest", questID = 66028, text = "To the Future! (objective 1)",
          coord = { map = 2025, x = 0.598, y = 0.822 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66028, text = "Turn in: To the Future!",
          coord = { map = 2085, x = 0.611, y = 0.508 } },  -- APR route coord (converted)
        { type = "accept", questID = 66030, text = "Resistance Isn't Futile",
          coord = { map = 2085, x = 0.611, y = 0.508 } },  -- giver coord: ATT
        { type = "accept", questID = 66031, text = "Making Time",
          coord = { map = 2085, x = 0.614, y = 0.502 } },  -- giver coord: ATT
        { type = "quest", questID = 66029, text = "Temporal Tuning (objective 1)",
          coord = { map = 2085, x = 0.468, y = 0.413 } },  -- APR route coord (converted)
        { type = "quest", questID = 66031, text = "Making Time (objective 1)",
          coord = { map = 2085, x = 0.464, y = 0.337 } },  -- APR route coord (converted)
        { type = "quest", questID = 66030, text = "Resistance Isn't Futile (objective 1)",
          coord = { map = 2085, x = 0.464, y = 0.337 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66030, text = "Turn in: Resistance Isn't Futile",
          coord = { map = 2085, x = 0.611, y = 0.508 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66031, text = "Turn in: Making Time",
          coord = { map = 2085, x = 0.615, y = 0.502 } },  -- APR route coord (converted)
        { type = "accept", questID = 66032, text = "Return to the Present",
          coord = { map = 2085, x = 0.611, y = 0.508 } },  -- giver coord: ATT
        { type = "turnin", questID = 66032, text = "Turn in: Return to the Present",
          coord = { map = 2025, x = 0.601, y = 0.825 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66029, text = "Turn in: Temporal Tuning",
          coord = { map = 2025, x = 0.601, y = 0.825 } },  -- APR route coord (converted)
        { type = "accept", questID = 72519, text = "Temporal Two-ning",
          coord = { map = 2025, x = 0.600, y = 0.824 } },  -- giver coord: ATT
        { type = "accept", questID = 66033, text = "To the... Past?",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "quest", questID = 66033, text = "To the... Past? (objective 1)",
          coord = { map = 2025, x = 0.600, y = 0.821 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66033, text = "Turn in: To the... Past?",
          coord = { map = 2092, x = 0.598, y = 0.661 } },  -- APR route coord (converted)
        { type = "accept", questID = 66035, text = "Murloc Motes",
          coord = { map = 2092, x = 0.598, y = 0.661 } },  -- giver coord: ATT
        { type = "accept", questID = 66036, text = "Mugurlglrlgl!", faction = "Alliance",
          coord = { map = 2092, x = 0.599, y = 0.659 } },  -- giver coord: ATT
        { type = "accept", questID = 66704, text = "Mugurlglrlgl!", faction = "Horde",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- giver coord: ATT
        { type = "quest", questID = 72519, text = "Temporal Two-ning (objective 1)",
          coord = { map = 2092, x = 0.616, y = 0.619 } },  -- APR route coord (converted)
        { type = "quest", questID = 66035, text = "Murloc Motes (objective 1)",
          coord = { map = 2092, x = 0.607, y = 0.654 } },  -- APR route coord (converted)
        { type = "quest", questID = 66036, text = "Mugurlglrlgl! (objective 1)", faction = "Alliance",
          coord = { map = 2092, x = 0.607, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66036, text = "Turn in: Mugurlglrlgl!", faction = "Alliance",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- APR route coord (converted)
        { type = "quest", questID = 66704, text = "Mugurlglrlgl! (objective 1,2)", faction = "Horde",
          coord = { map = 2092, x = 0.607, y = 0.654 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66704, text = "Turn in: Mugurlglrlgl!", faction = "Horde",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66035, text = "Turn in: Murloc Motes",
          coord = { map = 2092, x = 0.598, y = 0.661 } },  -- APR route coord (converted)
        { type = "accept", questID = 70373, text = "Deathwingurlugull!", faction = "Alliance",
          coord = { map = 2092, x = 0.599, y = 0.660 } },  -- giver coord: ATT
        { type = "quest", questID = 70373, text = "Deathwingurlugull! (objective 1)", faction = "Alliance",
          coord = { map = 2092, x = 0.598, y = 0.657 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70373, text = "Turn in: Deathwingurlugull!", faction = "Alliance",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 70371, text = "Deathwingurlugull!", faction = "Horde",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- giver coord: ATT
        { type = "quest", questID = 70371, text = "Deathwingurlugull! (objective 1)", faction = "Horde",
          coord = { map = 2092, x = 0.598, y = 0.657 } },  -- APR route coord (converted)
        { type = "quest", questID = 70371, text = "Deathwingurlugull! (objective 2)", faction = "Horde",
          coord = { map = 2092, x = 0.600, y = 0.596 } },  -- APR route coord (converted)
        { type = "turnin", questID = 70371, text = "Turn in: Deathwingurlugull!", faction = "Horde",
          coord = { map = 2092, x = 0.600, y = 0.660 } },  -- APR route coord (converted)
        { type = "accept", questID = 66037, text = "Back to Reality",
          coord = { map = 2092, x = 0.598, y = 0.661 } },  -- giver coord: ATT
        { type = "quest", questID = 66037, text = "Back to Reality (objective 1)",
          coord = { map = 2092, x = 0.597, y = 0.661 } },  -- APR route coord (converted)
        { type = "turnin", questID = 72519, text = "Turn in: Temporal Two-ning",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66037, text = "Turn in: Back to Reality",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 66660, text = "On Your Mark... Get Set...",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "quest", questID = 66660, text = "On Your Mark... Get Set... (objective 1)",
          coord = { map = 2025, x = 0.599, y = 0.822 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66660, text = "Turn in: On Your Mark... Get Set...",
          coord = { map = 2090, x = 0.434, y = 0.692 } },  -- APR route coord (converted)
        { type = "accept", questID = 66038, text = "Race Through Time!",
          coord = { map = 2090, x = 0.434, y = 0.692 } },  -- giver coord: ATT
        { type = "turnin", questID = 66038, text = "Turn in: Race Through Time!",
          coord = { map = 2089, x = 0.524, y = 0.737 } },  -- APR route coord (converted)
        { type = "accept", questID = 66039, text = "Chromie Time",
          coord = { map = 2089, x = 0.524, y = 0.738 } },  -- giver coord: ATT
        { type = "quest", questID = 66039, text = "Chromie Time (objective 1)",
          coord = { map = 2089, x = 0.533, y = 0.439 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66039, text = "Turn in: Chromie Time",
          coord = { map = 2089, x = 0.535, y = 0.437 } },  -- APR route coord (converted)
        { type = "accept", questID = 66040, text = "Back to the Future",
          coord = { map = 2089, x = 0.534, y = 0.441 } },  -- giver coord: ATT
        { type = "quest", questID = 66040, text = "Back to the Future (objective 1)",
          coord = { map = 2089, x = 0.535, y = 0.437 } },  -- APR route coord (converted)
        { type = "quest", questID = 66040, text = "Back to the Future (objective 2)",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66040, text = "Turn in: Back to the Future",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- APR route coord (converted)
        { type = "accept", questID = 66221, text = "Moving On",
          coord = { map = 2025, x = 0.601, y = 0.824 } },  -- giver coord: ATT
        { type = "quest", questID = 66221, text = "Moving On (objective 1)",
          coord = { map = 2112, x = 0.579, y = 0.353 } },  -- APR route coord (converted)
        { type = "turnin", questID = 66221, text = "Turn in: Moving On",
          coord = { map = 2112, x = 0.579, y = 0.353 } },  -- APR route coord (converted)
    },
}
