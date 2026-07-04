-- ToonAge/Modules/GuideParser.lua
-- Validates TA.GuideData at file-load time (TOC phase) and builds the
-- TA.Guides registry. Print output is deferred to Init() so messages
-- appear in chat after PLAYER_ENTERING_WORLD.
--
-- Guide schema:
--   { id, title, zone?, minLevel?, maxLevel?, steps = { step, ... } }
-- Step schema:
--   { type, text, questID?, coord={map,x,y}?, spec?, class?,
--     minLevel?, precondition={questID?,questComplete?}? }

local TA = ToonAge
TA.Guides = TA.Guides or {}

local GP = {}
TA:RegisterModule("GuideParser", GP)

-- ── Schema constants ──────────────────────────────────────────────────
local VALID_TYPES = {
    quest  = true, travel = true, npc    = true,
    item   = true, action = true, text   = true,
}

-- ── Deferred log (flushed in Init) ───────────────────────────────────
local _errors   = {}   -- { { id, stepN, msg } }
local _summary  = {}   -- { { id, title, count, errCount, valid } }

local function LogError(id, stepN, msg)
    table.insert(_errors, { id = id, stepN = stepN, msg = msg })
end

-- ── Validators ────────────────────────────────────────────────────────
local function ValidateCoord(id, stepN, coord)
    if type(coord) ~= "table" then
        LogError(id, stepN, "coord must be a table"); return false
    end
    if type(coord.map) ~= "number" then
        LogError(id, stepN, "coord.map must be a number"); return false
    end
    if type(coord.x) ~= "number" or coord.x < 0 or coord.x > 1 then
        LogError(id, stepN, "coord.x must be a number in [0,1]"); return false
    end
    if type(coord.y) ~= "number" or coord.y < 0 or coord.y > 1 then
        LogError(id, stepN, "coord.y must be a number in [0,1]"); return false
    end
    return true
end

local function ValidateStep(id, n, step)
    if type(step) ~= "table" then
        LogError(id, n, "step must be a table"); return false
    end
    local ok = true
    if type(step.type) ~= "string" or not VALID_TYPES[step.type] then
        LogError(id, n, "invalid or missing 'type' — must be one of: quest/travel/npc/item/action/text")
        ok = false
    end
    if type(step.text) ~= "string" or step.text == "" then
        LogError(id, n, "missing or empty 'text'")
        ok = false
    end
    if step.coord ~= nil and not ValidateCoord(id, n, step.coord) then
        ok = false
    end
    if step.precondition ~= nil and type(step.precondition) ~= "table" then
        LogError(id, n, "'precondition' must be a table")
        ok = false
    end
    return ok
end

local function ValidateGuide(id, guide)
    local errsBefore = #_errors
    if type(guide.title) ~= "string" or guide.title == "" then
        LogError(id, nil, "missing or empty 'title'")
    end
    if type(guide.steps) ~= "table" or #guide.steps == 0 then
        LogError(id, nil, "missing or empty 'steps' array")
        local errs = #_errors - errsBefore
        return false, 0, errs
    end
    for n, step in ipairs(guide.steps) do
        ValidateStep(id, n, step)
    end
    local errs = #_errors - errsBefore
    return errs == 0, #guide.steps, errs
end

-- ── File-scope load ───────────────────────────────────────────────────
-- Guide data files (Data/Guides/*.lua) are listed before this module in
-- the TOC and have already populated TA.GuideData. We validate and build
-- TA.Guides here, at file-load time, so any module's Init() can read it
-- regardless of init order.
do
    for id, guide in pairs(TA.GuideData or {}) do
        guide.id = guide.id or id
        local valid, count, errs = ValidateGuide(id, guide)
        table.insert(_summary, {
            id       = id,
            title    = (type(guide.title) == "string" and guide.title) or id,
            count    = count,
            errCount = errs,
            valid    = valid,
        })
        if valid then
            TA.Guides[id] = guide
        end
    end
end

-- ── Init — flush deferred output ──────────────────────────────────────
function GP:Init()
    for _, e in ipairs(_errors) do
        local where = e.stepN
            and ("Guide '" .. e.id .. "' step " .. e.stepN)
            or  ("Guide '" .. e.id .. "'")
        print("|cFFFFD100[TA]|r " .. where .. ": |cFFFF4444" .. e.msg .. "|r")
    end

    local loadedCount = 0
    for _, s in ipairs(_summary) do
        if s.valid then
            loadedCount = loadedCount + 1
            if TA.debug then
                print(string.format("|cFFFFD100[TA]|r Guide '|cFFFFFFFF%s|r' |cFF1EFF00OK|r (%d steps)", s.title, s.count))
            end
        else
            print(string.format("|cFFFFD100[TA]|r Guide '|cFFFFFFFF%s|r' |cFFFF4444INVALID|r (%d error(s))", s.title, s.errCount))
        end
    end

    if #_summary == 0 then
        if TA.debug then
            print("|cFFFFD100[TA]|r No guide files found — add *.lua to Data/Guides/ and list in the .toc")
        end
    elseif loadedCount > 0 then
        print(string.format("|cFFFFD100[TA]|r %d guide(s) loaded. Type |cFFFFD100/ta tracker|r to open the tracker.", loadedCount))
    end
end

-- ── Public API ────────────────────────────────────────────────────────
function GP:GetGuide(id)
    return TA.Guides[id]
end

function GP:GetAllGuides()
    return TA.Guides
end

function GP:DumpGuides()
    local n = 0
    for id, g in pairs(TA.Guides) do
        n = n + 1
        print(string.format("|cFFFFD100[TA]|r  [%s] \"%s\"  lvl %d-%d  (%d steps)",
            id, g.title, g.minLevel or 1, g.maxLevel or 999, #g.steps))
    end
    if n == 0 then
        print("|cFFFFD100[TA]|r No validated guides are loaded.")
    end
end

GP.SlashCommands = {
    guides = function(self) self:DumpGuides() end,
}
