-- ToonAge/Modules/GuideParser.lua
-- Validates TA.GuideData at file-load time (TOC phase) and builds the
-- TA.Guides registry. Print output is deferred to Init() so messages
-- appear in chat after PLAYER_ENTERING_WORLD.
--
-- ═══════════════════════════════════════════════════════════════════════
-- GUIDE SCHEMA (v2 — 2026-07-19)
-- ═══════════════════════════════════════════════════════════════════════
--
-- Guide table:
--   {
--     id        = string,            -- unique identifier (required)
--     title     = string,            -- display name (required)
--     zone      = number?,           -- primary uiMapID for this guide
--     minLevel  = number?,           -- minimum player level to show
--     maxLevel  = number?,           -- maximum player level to show
--     faction   = "Alliance"|"Horde"|nil,  -- faction restriction
--     nextGuide = string?,           -- id of the guide to chain into after last step
--     sideGuide = string?,           -- optional route offered alongside nextGuide
--     order     = number?,           -- sort among guides that share a level
--     optional  = boolean?,          -- side route, not the campaign chain
--     steps     = { step, ... },     -- ordered step array (required, non-empty)
--   }
--
-- Step table:
--   {
--     type           = string,       -- step type (see VALID_TYPES below)
--     text           = string,       -- display text (required)
--     questID        = number?,      -- associated quest ID
--     coord          = {map=N, x=N, y=N}?,  -- normalized [0,1] map coords
--     objectiveIndex = number?,      -- specific quest objective (1-based)
--     range          = number?,      -- proximity in yards for auto-advance
--     spec           = string?,      -- spec restriction (e.g. "Protection")
--     class          = string?,      -- class restriction (e.g. "WARRIOR")
--     race           = string?,      -- race restriction (e.g. "BloodElf")
--     faction        = "Alliance"|"Horde"|nil,  -- step-level faction gate
--     minLevel       = number?,      -- minimum level for this step
--     questItem      = number?,      -- older item id for the context button
--     useItem        = number?,      -- Chronicler item id; may be unverified.
--                                    -- The quest log's own item wins over it.
--     reward         = number?,      -- preferred reward itemID for auto-quest
--     noArrow        = boolean?,     -- suppress arrow for this step
--     estimated      = boolean?,     -- hollow approximate marker
--     optional       = boolean?,     -- skippable achievement/side step
--     rep            = { { factionID = number, amount = number }, ... }?,
--     precondition   = {             -- gating conditions
--       questID       = number?,     -- quest must be in log
--       questComplete = number?,     -- quest must be flagged complete
--     }?,
--   }
--
-- ═══════════════════════════════════════════════════════════════════════
-- STEP TYPES
-- ═══════════════════════════════════════════════════════════════════════
--
-- pickup    — Accept a quest. Complete when questID enters the quest log.
-- turnin    — Turn in a quest. Complete when IsQuestFlaggedCompleted(questID).
-- objective — Complete a specific objective. Uses objectiveIndex to check
--             C_QuestLog.GetQuestObjectives()[objectiveIndex].finished.
-- waypoint  — Travel to a location. No quest logic — completes by proximity
--             (range field, default 15 yards). Auto-skipped if player is flying.
-- quest     — Legacy combined type (kept for backward compat). Complete when
--             IsQuestFlaggedCompleted(questID).
-- accept    — Synonym for pickup (v1 compat). Complete when quest enters log.
-- travel    — Travel step with optional coord. Similar to waypoint but won't
--             auto-skip when flying (used for mandatory path steps).
-- npc       — Interact with an NPC. No auto-completion — manual advance.
-- item      — Use/collect an item. useItem (or questItem) drives the context button.
-- action    — Perform a specific action (bind hearth, set spec, etc.).
-- text      — Informational only. Always considered complete (auto-skip).
-- flyto     — Take a flight path. Complete when player lands in target zone.
-- sethearth — Set hearthstone. Complete when hearthstone location changes.
-- gather    — Farm-loop hotspot. Completes by proximity, like a waypoint.
-- note      — Informational. Always complete, like text.
-- treasure, rare, glyph, worldboss, hiddenquest, firstgather, achievement,
-- vendor, firstcraft — catalog steps. A questID completes when flagged.
-- ═══════════════════════════════════════════════════════════════════════

local TA = ToonAge
TA.Guides = TA.Guides or {}

local GP = {}
TA:RegisterModule("GuideParser", GP)

-- ── Schema constants ──────────────────────────────────────────────────
local VALID_TYPES = {
    -- Navigation / quest progression (core types)
    pickup    = true,   -- accept quest (complete when in log)
    turnin    = true,   -- turn in quest (complete when flagged complete)
    objective = true,   -- complete specific objective index
    waypoint  = true,   -- proximity-based travel point (auto-skip if flying)

    -- Legacy / general types
    quest     = true,   -- combined accept+complete (v1 compat)
    accept    = true,   -- synonym for pickup (v1 compat)
    travel    = true,   -- travel step (mandatory, no auto-skip)
    npc       = true,   -- NPC interaction
    item      = true,   -- item use/collect
    action    = true,   -- general action (hearth, spec, etc.)
    text      = true,   -- informational (always complete)

    -- Specialized types
    flyto     = true,   -- take flight path
    sethearth = true,   -- set hearthstone location

    -- Midnight catalog types (Chronicler, 2026-10-09).
    gather      = true,
    note        = true,
    treasure    = true,
    rare        = true,
    glyph       = true,
    worldboss   = true,
    hiddenquest = true,
    firstgather = true,
    firstcraft  = true,
    achievement = true,
    vendor      = true,
}

-- Expose for other modules (NavHud, QuestTracker use this to classify steps)
GP.VALID_TYPES = VALID_TYPES

-- Types that represent "go to this location" (used by NavHud for pin display)
GP.NAV_TYPES = {
    pickup = true, turnin = true, objective = true, waypoint = true,
    quest = true, accept = true, travel = true, npc = true, item = true,
    action = true, flyto = true, sethearth = true,
}

-- Types that auto-complete by proximity alone (no quest state check)
GP.PROXIMITY_TYPES = {
    waypoint = true,
}

-- Types where IsQuestFlaggedCompleted() is the completion check
GP.TURNIN_TYPES = {
    turnin = true, quest = true,
}

-- Types where "quest is in log" means complete
GP.PICKUP_TYPES = {
    pickup = true, accept = true,
}

-- ── Deferred log (flushed in Init) ───────────────────────────────────
local _errors   = {}   -- { { id, stepN, msg } }
local _summary  = {}   -- { { id, title, count, errCount, valid } }
local _estimated = {}  -- { { id, title, count } } coords still needing a spot-check

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
        LogError(id, n, "invalid or missing 'type' — must be one of: " ..
            "pickup/turnin/objective/waypoint/quest/accept/travel/npc/item/action/text/flyto/sethearth")
        ok = false
    end
    if type(step.text) ~= "string" or step.text == "" then
        -- Allow steps with a questID to skip text validation —
        -- U.ResolveStepText() resolves titles at runtime from the API.
        if not step.questID then
            LogError(id, n, "missing or empty 'text'")
            ok = false
        else
            -- Ensure text field exists for downstream code that reads it
            step.text = ""
        end
    end
    if step.coord ~= nil and not ValidateCoord(id, n, step.coord) then
        ok = false
    end
    if step.precondition ~= nil and type(step.precondition) ~= "table" then
        LogError(id, n, "'precondition' must be a table")
        ok = false
    end
    -- Validate objectiveIndex when type is "objective"
    if step.type == "objective" then
        if type(step.objectiveIndex) ~= "number" or step.objectiveIndex < 1 then
            LogError(id, n, "type 'objective' requires a positive 'objectiveIndex'")
            ok = false
        end
        if type(step.questID) ~= "number" then
            LogError(id, n, "type 'objective' requires a 'questID'")
            ok = false
        end
    end
    -- Validate that pickup/turnin/quest have questID
    if (step.type == "pickup" or step.type == "turnin" or step.type == "quest" or step.type == "accept") then
        if step.questID ~= nil and type(step.questID) ~= "number" then
            LogError(id, n, "'" .. step.type .. "' step has non-numeric questID")
            ok = false
        end
    end
    -- Validate range if provided
    if step.range ~= nil and (type(step.range) ~= "number" or step.range <= 0) then
        LogError(id, n, "'range' must be a positive number (yards)")
        ok = false
    end
    if step.useItem ~= nil then
        local itemID = step.useItem
        if type(itemID) == "table" then itemID = itemID.id or itemID.itemID end
        if type(itemID) ~= "number" or itemID <= 0 then
            LogError(id, n, "'useItem' must be an item id")
            ok = false
        end
    end
    if step.rep ~= nil then
        if type(step.rep) ~= "table" then
            LogError(id, n, "'rep' must be a table")
            ok = false
        else
            for _, grant in ipairs(step.rep) do
                if type(grant) ~= "table"
                    or type(grant.factionID) ~= "number"
                    or type(grant.amount) ~= "number" then
                    LogError(id, n, "'rep' entries need a factionID and an amount")
                    ok = false
                    break
                end
            end
        end
    end
    return ok
end

local function ValidateGuide(id, guide)
    local errsBefore = #_errors
    if type(guide.title) ~= "string" or guide.title == "" then
        LogError(id, nil, "missing or empty 'title'")
    end
    if type(guide.steps) ~= "table" then
        LogError(id, nil, "missing 'steps' array")
        local errs = #_errors - errsBefore
        return false, 0, errs
    end
    -- Empty steps are valid — they represent stub guides that trigger
    -- Quest Log Follow mode in the tracker. The Guide Tab still shows them
    -- with a "coming soon" state and the tracker uses Blizzard's native
    -- quest tracking system for arrow guidance.
    if #guide.steps == 0 then
        local errs = #_errors - errsBefore
        return true, 0, errs  -- valid stub, 0 steps, no errors
    end
    -- Validate nextGuide reference (can't fully validate target exists yet)
    if guide.nextGuide ~= nil and type(guide.nextGuide) ~= "string" then
        LogError(id, nil, "'nextGuide' must be a string guide id")
    end
    if guide.sideGuide ~= nil and type(guide.sideGuide) ~= "string" then
        LogError(id, nil, "'sideGuide' must be a string guide id")
    end
    if guide.order ~= nil and type(guide.order) ~= "number" then
        LogError(id, nil, "'order' must be a number")
    end
    -- Validate faction
    if guide.faction ~= nil and guide.faction ~= "Alliance" and guide.faction ~= "Horde"
       and guide.faction ~= "Neutral" then
        LogError(id, nil, "'faction' must be 'Alliance', 'Horde' or 'Neutral'")
    end
    local estimatedSteps = 0
    for n, step in ipairs(guide.steps) do
        ValidateStep(id, n, step)
        if guide.coordsEstimated and step.coord then
            estimatedSteps = estimatedSteps + 1
            step.estimated = true
        end
    end
    if estimatedSteps > 0 then
        _estimated[#_estimated + 1] = {
            id = id,
            title = (type(guide.title) == "string" and guide.title) or id,
            count = estimatedSteps,
        }
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

-- ── Post-load cross-validation ────────────────────────────────────────
-- Verify nextGuide references point to valid guide IDs.
-- Run after all guides are registered but before Init() prints output.
do
    for id, guide in pairs(TA.Guides) do
        if guide.nextGuide and not TA.Guides[guide.nextGuide] then
            -- Warn but don't invalidate — the target guide may load later
            -- or may be conditional (level/faction gated)
            table.insert(_errors, {
                id = id, stepN = nil,
                msg = "nextGuide '" .. guide.nextGuide .. "' not found (may load later)"
            })
        end
        if guide.sideGuide and not TA.Guides[guide.sideGuide] then
            table.insert(_errors, {
                id = id, stepN = nil,
                msg = "sideGuide '" .. guide.sideGuide .. "' not found (may load later)"
            })
        end
    end
end

-- ── Init — flush deferred output ──────────────────────────────────────
function GP:Init()
    for _, e in ipairs(_errors) do
        local where = e.stepN
            and ("Guide '" .. e.id .. "' step " .. e.stepN)
            or  ("Guide '" .. e.id .. "'")
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r " .. where .. ": |cFFFF4444" .. e.msg .. "|r")
    end

    local loadedCount = 0
    for _, s in ipairs(_summary) do
        if s.valid then
            loadedCount = loadedCount + 1
            if TA.debug then
                TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r Guide '|cFFFFFFFF%s|r' |cFF1EFF00OK|r (%d steps)", s.title, s.count))
            end
        else
            TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r Guide '|cFFFFFFFF%s|r' |cFFFF4444INVALID|r (%d error(s))", s.title, s.errCount))
        end
    end

    if #_summary == 0 then
        if TA.debug then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r No guide files found — add *.lua to Data/Guides/ and list in the .toc")
        end
    elseif loadedCount > 0 then
        TA:Raw(TA.LOG.INFO, string.format("|cFFFFD100[TA]|r %d guide(s) loaded. Type |cFFFFD100/ta tracker|r to open the tracker.", loadedCount))
    end
    for _, e in ipairs(_estimated) do
        TA:Raw(TA.LOG.INFO, string.format(
            "|cFFFFD100[TA]|r Guide '%s': %d step(s) use estimated coordinates (spot-check in game).",
            e.title, e.count))
    end
end

-- A guide that is entirely 0,0 is an unfilled stub. A guide that already
-- has a real coordinate, or an explicit nil coordinate, must not also
-- contain a 0,0 step. Retail also requires the Midnight faction routes.
function GP:AuditLoaded()
    local report = {
        loaded = 0,
        data = 0,
        bad = 0,
        stubs = 0,
        failed = {},
        problems = {},
        midnight = {},
        useItems = 0,
        noArrow = 0,
        nilCoord = 0,
        saw14 = false,
        saw2372 = false,
        holokey = false,
    }

    for id in pairs(TA.GuideData or {}) do
        report.data = report.data + 1
        if not (TA.Guides and TA.Guides[id]) then
            report.failed[#report.failed + 1] = id
            report.problems[#report.problems + 1] = "did not load: " .. id
        end
    end

    for id, guide in pairs(TA.Guides or {}) do
        report.loaded = report.loaded + 1
        local real, zeros, nils = 0, 0, 0
        for _, step in ipairs(guide.steps or {}) do
            if type(step) == "table" then
                local coord = step.coord
                if coord == nil then
                    nils = nils + 1
                    report.nilCoord = report.nilCoord + 1
                    if step.noArrow then report.noArrow = report.noArrow + 1 end
                elseif type(coord) == "table" then
                    local x = tonumber(coord.x) or 0
                    local y = tonumber(coord.y) or 0
                    if x == 0 and y == 0 then zeros = zeros + 1
                    else real = real + 1 end
                    if coord.map == 14 then report.saw14 = true end
                    if coord.map == 2372 then report.saw2372 = true end
                end
                if step.useItem ~= nil then
                    local itemID = step.useItem
                    if type(itemID) == "table" then itemID = itemID.id or itemID.itemID end
                    if type(itemID) == "number" and itemID > 0 then
                        report.useItems = report.useItems + 1
                    else
                        report.midnight[#report.midnight + 1] = id .. " useItem is not an item id"
                    end
                end
                if id == "midnight_voidstorm_campaign" and step.questID == 86528 and step.type == "accept" then
                    report.holokey = step.estimated == true
                end
                if step.questID == 86528 and step.type ~= "accept" and step.estimated then
                    report.midnight[#report.midnight + 1] = "86528 turn-in is marked approximate"
                end
            end
        end
        if zeros > 0 and (real > 0 or nils > 0) then
            report.bad = report.bad + 1
            report.problems[#report.problems + 1] = id .. " has a 0,0 coordinate"
            report.midnight[#report.midnight + 1] = id .. " has a 0,0 coordinate"
        elseif zeros > 0 then
            report.stubs = report.stubs + 1
        end
    end

    if TA.flavor == "retail" then
        local reps = TA.Reputations and TA.Reputations.midnight
        if type(reps) ~= "table" then
            report.midnight[#report.midnight + 1] = "reputations are not loaded"
        else
            local n = 0
            for fid, faction in pairs(reps) do
                n = n + 1
                local idNum = (type(faction) == "table" and faction.factionID) or fid
                local gid = "midnight_rep_" .. tostring(idNum)
                if not (TA.Guides and TA.Guides[gid]) then
                    report.midnight[#report.midnight + 1] = "missing " .. gid
                end
            end
            if n ~= 12 then
                report.midnight[#report.midnight + 1] = "faction count " .. tostring(n)
            end
        end
        if not report.holokey then
            report.midnight[#report.midnight + 1] = "86528 A Cracked Holokey is not approximate"
        end
        if not report.saw14 or not report.saw2372 then
            report.midnight[#report.midnight + 1] = "Arathi map 14 or 2372 is missing"
        end
    end
    return report
end

-- ── Public API ────────────────────────────────────────────────────────
function GP:GetGuide(id)
    return TA.Guides[id]
end

function GP:GetAllGuides()
    return TA.Guides
end

--- Guides whose coordinates were converted and still need an in-game spot-check.
--- Each entry is { id, title, count } where count is steps that carry a coord.
function GP:EstimatedCoords()
    return _estimated
end

--- Returns the next guide in a chain, or nil.
function GP:GetNextGuide(currentGuideID)
    local guide = TA.Guides[currentGuideID]
    if guide and guide.nextGuide then
        return TA.Guides[guide.nextGuide]
    end
    return nil
end

--- Check if a step should be shown to the current player.
--- Evaluates faction, class, race, spec, and minLevel filters.
function GP:IsStepApplicable(step)
    if not step then return false end

    -- Faction filter
    if step.faction then
        local playerFaction = UnitFactionGroup("player")
        if step.faction ~= playerFaction then return false end
    end

    -- Class filter
    if step.class then
        local _, playerClass = UnitClass("player")
        if step.class ~= playerClass then return false end
    end

    -- Race filter
    if step.race then
        local _, playerRace = UnitRace("player")
        if step.race ~= playerRace then return false end
    end

    -- Spec filter
    if step.spec then
        -- Through Utils, not the raw API: GetSpecialization does not exist on
        -- every client this runs on (WoW Forever has no spec system), and
        -- calling a nil global throws rather than returning nil.
        local _, specName = TA.Utils.GetPlayerSpec()
        if specName and step.spec ~= specName then return false end
    end

    -- Level filter
    if step.minLevel then
        local playerLevel = UnitLevel("player")
        if playerLevel < step.minLevel then return false end
    end

    return true
end

--- Check if a guide is applicable to the current player (faction, level).
function GP:IsGuideApplicable(guide)
    if not guide then return false end
    if guide.faction and guide.faction ~= "Neutral" then
        local playerFaction = UnitFactionGroup("player")
        if guide.faction ~= playerFaction then return false end
    end
    local playerLevel = UnitLevel("player")
    if guide.maxLevel and playerLevel > guide.maxLevel + 5 then
        return false  -- generous buffer, don't hide guides 1-2 levels early
    end
    return true
end

function GP:DumpGuides()
    local n = 0
    for id, g in pairs(TA.Guides) do
        n = n + 1
        local chain = g.nextGuide and (" → " .. g.nextGuide) or ""
        TA:Raw(TA.LOG.OUTPUT, string.format("|cFFFFD100[TA]|r  [%s] \"%s\"  lvl %d-%d  (%d steps)%s",
            id, g.title, g.minLevel or 1, g.maxLevel or 999, #g.steps, chain))
    end
    if n == 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA]|r No validated guides are loaded.")
    end
end

GP.SlashCommands = {
    guides = function(self) self:DumpGuides() end,
}
