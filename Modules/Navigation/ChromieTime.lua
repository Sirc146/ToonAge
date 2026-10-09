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
        guideKey = M.GUIDE_KEYS[id], intro = false, eligible = eligible,
    }
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
    local label = timeline.name or ("Chromie Time " .. tostring(timeline.id))
    local n = (key and M.CountGuides(guides, key, false)) or 0
    if not key or n == 0 then
        return {
            mode = "missing",
            key = nil,
            header = label,
            name = label,
            cardTitle = "No guide for " .. label .. " yet",
            cardBody = "These are the zones we do have.",
        }
    end
    return { mode = "timeline", key = key, header = label, name = label }
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

function M.HeaderLine(timeline)
    if not timeline or timeline.skipped then return nil end
    if timeline.active then
        return timeline.name or ("Chromie Time " .. tostring(timeline.id))
    end
    return "No timeline"
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

return M
