-- ToonAge/Modules/Navigation/ChromieTime.lua
-- Retail leveling-guide timeline. This file is not on any Classic TOC.
--
-- API names checked against current FrameXML and Warcraft Wiki (2026-10-09),
-- not taken from the request alone:
--   UnitChromieTimeID(unit) -> number
--     Blizzard_APIDocumentationGenerated/UnitDocumentation.lua.
--     The number is UIChromieTimeExpansionInfo.ID. Added 9.0.1.
--   C_ChromieTime.GetChromieTimeExpansionOptions() -> ChromieTimeExpansionInfo[]
--     ChromieTimeFrameMixin:SetupExpansionButtons in Blizzard_ChromieTimeUI.lua
--     calls it and reads option.id, name, alreadyOn, completed, recommended.
--     Wiki game type: mainline. Fields recommended and sortPriority are 10.1.5.
--   CHROMIE_TIME_OPEN and CHROMIE_TIME_CLOSE have no payload (added 9.0.1).
--   PLAYER_LEVEL_UP is the existing level-up event.
-- The singular expansion-option lookup (one campaign id) is a different
-- function and is not used. This file never changes the player's timeline.
-- A missing function means no timeline. Eligibility is the options list the
-- API returns (recommended / alreadyOn / completed). No level brackets.
--
-- Campaign id -> guide.expansion, from UIChromieTimeExpansionInfo on
-- build 12.1.5.70077 (wago.tools DB2). These are campaign ids, not
-- LE_EXPANSION_* values and not character levels:
--   5  The Cataclysm            -> cata
--   6  Portal to Outland        -> tbc
--   7  Fall of the Lich King    -> wrath
--   8  Wilds of Pandaria        -> mop
--   9  Draenor                  -> wod
--   10 The Legion Invasion      -> legion
--   14 Shadowlands              -> shadowlands
--   15 Battle for Azeroth       -> bfa
--   16 Dragonflight             -> dragonflight
-- War Within and Midnight are not rows in that table. No active id
-- (nil, a non-number, or 0) is the current expansion's intro.

local TA = ToonAge
local M = {}
TA.Chromie = M

M.CURRENT_INTRO_KEY = "midnight"
M.CURRENT_INTRO_LABEL = "Midnight intro"

M.GUIDE_KEYS = {
    [5]  = "cata",
    [6]  = "tbc",
    [7]  = "wrath",
    [8]  = "mop",
    [9]  = "wod",
    [10] = "legion",
    [14] = "shadowlands",
    [15] = "bfa",
    [16] = "dragonflight",
}

-- Short names for the empty-state card ("Legion timeline guide is coming.").
-- The header pill uses the in-game campaign name from
-- GetChromieTimeExpansionOptions (timeline.name), not this short label.
M.SHORT = {
    [5]  = "Cataclysm",
    [6]  = "Outland",
    [7]  = "Wrath",
    [8]  = "Pandaria",
    [9]  = "Draenor",
    [10] = "Legion",
    [14] = "Shadowlands",
    [15] = "BfA",
    [16] = "Dragonflight",
}

-- Chromie Time guide files, in the order they are being written.
-- Dragonflight is Chronicler's campaign file. Legion, BfA, and Shadowlands
-- are still coming. A regular expansion guide is not one of these.
M.DF_GUIDE_ID = "dragonflight_chromie_campaign"
M.SKIP_ACHIEVEMENT = 16326
M.GUIDE_PRIORITY = {
    { key = "dragonflight", id = "dragonflight_chromie_campaign", short = "Dragonflight" },
    { key = "legion",       id = "legion_chromie",       short = "Legion" },
    { key = "bfa",          id = "bfa_chromie",          short = "BfA" },
    { key = "shadowlands",  id = "shadowlands_chromie",  short = "Shadowlands" },
}

local function EachOption(options, fn)
    if type(options) ~= "table" then return end
    if #options > 0 then
        for _, opt in ipairs(options) do fn(opt) end
        return
    end
    for _, opt in pairs(options) do fn(opt) end
end

--- flavor is the client. chromieID is UnitChromieTimeID("player") or nil
--- when that function is missing. options is the expansion list or nil.
function M.Read(flavor, chromieID, options)
    if flavor ~= "retail" then
        return {
            skipped = true, active = false, id = nil, name = nil,
            guideKey = nil, intro = false, eligible = {},
        }
    end
    local eligible = {}
    EachOption(options, function(opt)
        if type(opt) == "table" and type(opt.id) == "number" then
            eligible[#eligible + 1] = {
                id = opt.id,
                name = opt.name,
                guideKey = M.GUIDE_KEYS[opt.id],
                recommended = opt.recommended == true,
                alreadyOn = opt.alreadyOn == true,
                completed = opt.completed == true,
            }
        end
    end)
    local id = chromieID
    if type(id) ~= "number" or id == 0 then
        return {
            skipped = false, active = false, id = nil, name = nil,
            guideKey = M.CURRENT_INTRO_KEY, intro = true, eligible = eligible,
        }
    end
    local name
    for _, opt in ipairs(eligible) do
        if opt.id == id then name = opt.name break end
    end
    return {
        skipped = false, active = true, id = id, name = name,
        short = M.SHORT[id],
        guideKey = M.GUIDE_KEYS[id], intro = false, eligible = eligible,
    }
end

function M.GuideIdFor(key)
    for _, row in ipairs(M.GUIDE_PRIORITY) do
        if row.key == key then return row.id end
    end
    if type(key) == "string" and key ~= "" then return key .. "_chromie" end
    return nil
end

--- A timeline guide is the Chromie Time file for that expansion
--- (dragonflight_chromie_campaign, and the same shape after it), or a guide
--- that says so with chromie = true. The ordinary zone guides do not count.
function M.IsTimelineGuide(guide, key)
    if type(guide) ~= "table" or type(key) ~= "string" then return false end
    if guide.id == M.GuideIdFor(key) then return true end
    if guide.chromie == true and guide.expansion == key then return true end
    return false
end

function M.CountTimelineGuides(guides, key)
    local n = 0
    for _, g in pairs(guides or {}) do
        if M.IsTimelineGuide(g, key) then n = n + 1 end
    end
    return n
end

function M.ComingCopy(short)
    if type(short) ~= "string" or short == "" then
        return "This timeline guide is coming. Your game is fine."
    end
    return short .. " timeline guide is coming. Your game is fine."
end

--- Plain pill text. Uses the campaign's in-game name from the options list.
--- Nil when the player is not on a timeline.
function M.PillText(timeline)
    if not timeline or timeline.skipped or not timeline.active then return nil end
    local name = timeline.name
    if type(name) ~= "string" or name == "" then name = timeline.short end
    if type(name) ~= "string" or name == "" then return nil end
    return "Chromie Time · " .. name
end

function M.IsIntroGuide(guide)
    if type(guide) ~= "table" then return false end
    if guide.expansion ~= M.CURRENT_INTRO_KEY then return false end
    local id = string.lower(tostring(guide.id or ""))
    local title = string.lower(tostring(guide.title or ""))
    if string.find(id, "intro", 1, true) then return true end
    if string.find(title, "intro", 1, true) then return true end
    return false
end

function M.CountGuides(guides, key, introOnly)
    local n = 0
    for _, g in pairs(guides or {}) do
        if type(g) == "table" then
            if introOnly then
                if M.IsIntroGuide(g) then n = n + 1 end
            elseif g.expansion == key then
                n = n + 1
            end
        end
    end
    return n
end

--- Which guide set the picker should open, given a Read() result and the
--- guides that are actually loaded. mode "missing" means do not pretend
--- some other expansion's zones are this timeline.
function M.Resolve(timeline, guides)
    if not timeline or timeline.skipped then
        return { mode = "skip" }
    end
    if timeline.intro or not timeline.active then
        if M.CountGuides(guides, nil, true) == 0 then
            return {
                mode = "missing",
                key = nil,
                header = M.CURRENT_INTRO_LABEL,
                cardTitle = "No intro guide yet",
                cardBody = "These are the zones we do have.",
            }
        end
        return {
            mode = "intro",
            key = M.CURRENT_INTRO_KEY,
            header = M.CURRENT_INTRO_LABEL,
        }
    end
    local key = timeline.guideKey
    local short = timeline.short
    if type(short) ~= "string" or short == "" then short = timeline.name end
    local n = (key and M.CountTimelineGuides(guides, key)) or 0
    if not key or n == 0 then
        return {
            mode = "missing",
            key = nil,
            header = short,
            name = timeline.name,
            short = short,
            cardTitle = short or "Timeline",
            cardBody = M.ComingCopy(short),
        }
    end
    return {
        mode = "timeline", key = key, header = short or key,
        name = timeline.name, short = short,
    }
end

function M.ZonesWeHave(guides, expansions)
    local out = {}
    for _, exp in ipairs(expansions or {}) do
        local n = M.CountGuides(guides, exp.key, false)
        if n > 0 then
            out[#out + 1] = { key = exp.key, label = exp.label, count = n }
        end
    end
    return out
end

function M.Status(timeline, apiPresent)
    if not timeline or timeline.skipped then
        return "Chromie Time skipped (not Retail)"
    end
    if not apiPresent then
        return "Chromie Time: API absent, no timeline"
    end
    if not timeline.active then
        return "Chromie Time: no timeline"
    end
    if timeline.name and timeline.name ~= "" then
        return string.format("Chromie Time: %s (id %s)", timeline.name, tostring(timeline.id))
    end
    return string.format("Chromie Time: id %s", tostring(timeline.id))
end

--- idFn is UnitChromieTimeID. optionsFn is GetChromieTimeExpansionOptions.
--- Either one missing means no timeline.
function M.FromApi(flavor, idFn, optionsFn)
    if flavor ~= "retail" then
        return M.Read(flavor, nil, nil), false
    end
    if type(idFn) ~= "function" or type(optionsFn) ~= "function" then
        return M.Read("retail", nil, nil), false
    end
    local ok, id = pcall(idFn, "player")
    if not ok then id = nil end
    local ok2, options = pcall(optionsFn)
    if not ok2 or type(options) ~= "table" then options = nil end
    return M.Read("retail", id, options), true
end

function M.Detect()
    if TA.flavor ~= "retail" then
        return M.Read(TA.flavor, nil, nil), false
    end
    if type(UnitChromieTimeID) ~= "function"
        or type(C_ChromieTime) ~= "table"
        or type(C_ChromieTime.GetChromieTimeExpansionOptions) ~= "function" then
        return M.Read("retail", nil, nil), false
    end
    return M.FromApi("retail", UnitChromieTimeID, C_ChromieTime.GetChromieTimeExpansionOptions)
end

-- Steps whose trailing comment in the campaign file says UNVERIFIED.
-- Comments are gone once the file loads, so the match is quest, type, map,
-- and coordinate. 77345 and 66718 each appear twice; only the noted step matches.
M.UNVERIFIED = {
    { 66956, "quest",  2022, 0.642, 0.329 },
    { 65994, "quest",  2022, 0.639, 0.336 },
    { 77345, "turnin", 2022, 0.575, 0.591 },
    { 66960, "quest",  2022, 0.548, 0.822 },
    { 66117, "quest",  2022, 0.557, 0.815 },
    { 65892, "quest",  2023, 0.636, 0.155 },
    { 69968, "quest",  2023, 0.598, 0.669 },
    { 66421, "quest",  2023, 0.254, 0.378 },
    { 66970, "quest",  2023, 0.259, 0.342 },
    { 67173, "quest",  2024, 0.368, 0.325 },
    { 65841, "quest",  2024, 0.179, 0.381 },
    { 69872, "quest",  2024, 0.173, 0.417 },
    { 66718, "quest",  2024, 0.578, 0.451 },
    { 69895, "quest",  2024, 0.701, 0.332 },
}

local function UnverifiedKey(questID, stepType, map, x, y)
    return string.format("%d|%s|%d|%.3f|%.3f", questID or 0, stepType or "", map or 0, x or 0, y or 0)
end

function M.MarkUnverified(guide)
    if type(guide) ~= "table" or type(guide.steps) ~= "table" then return 0 end
    local want = {}
    for _, row in ipairs(M.UNVERIFIED) do
        want[UnverifiedKey(row[1], row[2], row[3], row[4], row[5])] = true
    end
    local n = 0
    for _, step in ipairs(guide.steps) do
        local c = step.coord
        if c and step.questID and step.type then
            local key = UnverifiedKey(step.questID, step.type, c.map, c.x, c.y)
            if want[key] then
                step.estimated = true
                want[key] = nil
                n = n + 1
            end
        end
    end
    return n
end

-- The campaign file leaves APR's skip branch out. These steps exist only
-- at runtime. 72293, then one of 72266-72269. They are not written into
-- the 1,139-step table.
M.SKIP_ZONES = {
    { questID = 72266, text = "The Waking Shores", map = 2022 },
    { questID = 72267, text = "Ohn'ahran Plains",  map = 2023 },
    { questID = 72268, text = "The Azure Span",    map = 2024 },
    { questID = 72269, text = "Thaldraszus",       anchor = 66159 },
}

function M.SkipSteps()
    if M._skipSteps then return M._skipSteps end
    M._skipSteps = {
        { type = "accept", questID = 72293, text = "Adventuring in the Dragon Isles" },
        { type = "turnin", questID = 72293, text = "Turn in: Adventuring in the Dragon Isles" },
        {
            type = "text",
            _zonePick = true,
            text = "Pick a zone: The Waking Shores (72266), Ohn'ahran Plains (72267), The Azure Span (72268), or Thaldraszus (72269).",
        },
    }
    return M._skipSteps
end

--- First campaign step for a skip-zone choice. Faction-tagged steps that
--- are not this character's are skipped when a later step on that map fits.
function M.ZoneStartIndex(steps, zone, faction)
    if type(steps) ~= "table" or type(zone) ~= "table" then return nil end
    local fallback
    for i, step in ipairs(steps) do
        local hit = false
        if zone.anchor and step.questID == zone.anchor then
            hit = true
        elseif zone.map and step.coord and step.coord.map == zone.map then
            hit = true
        end
        if hit then
            if not fallback then fallback = i end
            local fac = step.faction
            if not fac or fac == "Neutral" or not faction or fac == faction then
                return i
            end
        end
    end
    return fallback
end

function M.ZoneByQuest(questID)
    for _, zone in ipairs(M.SKIP_ZONES) do
        if zone.questID == questID then return zone end
    end
    return nil
end

--- completed is GetAchievementInfo's 4th return, or a table from
--- C_AchievementInfo.GetAchievementInfo. Account-wide achievements report
--- completed when the account has earned them.
function M.AchievementCompleted(completed)
    if type(completed) == "table" then return completed.completed == true end
    return completed == true
end

function M.ShouldShowSkipCard(guideID, earned, dismissed, skipping, listingDF)
    if earned ~= true or dismissed or skipping then return false end
    if guideID == M.DF_GUIDE_ID then return true end
    if listingDF then return true end
    return false
end

--- Hidden account achievement 16326 "ACCOUNT: Campaign Complete".
--- GetAchievementInfo's 4th return is `completed` (Warcraft Wiki). The
--- C_AchievementInfo lookup returns an AchievementInfo table with the same
--- field. A missing API means the card stays hidden.
function M.ReadAchievementComplete()
    local id = M.SKIP_ACHIEVEMENT
    if type(C_AchievementInfo) == "table" and type(C_AchievementInfo.GetAchievementInfo) == "function" then
        local ok, info = pcall(C_AchievementInfo.GetAchievementInfo, id)
        if ok and type(info) == "table" and info.completed ~= nil then
            return info.completed == true
        end
    end
    if type(GetAchievementInfo) == "function" then
        local ok, first, _, _, completed = pcall(GetAchievementInfo, id)
        if ok then
            if type(first) == "table" then return first.completed == true end
            return completed == true
        end
    end
    return false
end

do
    local guides = TA.Guides or TA.GuideData
    local g = guides and guides[M.DF_GUIDE_ID]
    if g then M.MarkUnverified(g) end
end

return M
