-- ToonAge/Core/Init.lua
-- Addon object, event registration, SavedVariables, module system

local ADDON_NAME = "ToonAge"

-- The TOC's "## Version" is the single source of truth: it is what the packager
-- stamps, what WowUp and Wago read, and what the addon list shows. A second
-- copy here drifts the moment a release bumps one and not the other, and the
-- version a tester reads off /ta health is then not the version they installed.
-- Read directly rather than through Core/Compat/API.lua -- that file loads
-- after this one.
local ADDON_VERSION = (function()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    if type(get) ~= "function" then return "unknown" end
    local ok, v = pcall(get, ADDON_NAME, "Version")
    if ok and type(v) == "string" and v ~= "" then return v end
    return "unknown"
end)()

-- ── Dev Build Tester Lock ─────────────────────────────────────────────────────
-- When IS_DEV_BUILD is true, only characters listed in AUTHORIZED_TESTERS can
-- use the addon. Everyone else gets a one-line message and the addon disables.
-- Set IS_DEV_BUILD to false (or remove the -dev suffix from the version) for
-- public releases.
local IS_DEV_BUILD = false  -- Disabled for testing; re-enable with -dev suffix for tester builds
local AUTHORIZED_TESTERS = {
    -- Add "Name-Server" keys for authorized testers
    ["Ellacait-Vargoth"]  = true,
    ["Asirc-Myzrael"]     = true,
    ["Nethendera-Vargoth"] = true,
    -- Add more testers here:
    -- ["Character-Server"] = true,
}

-- Create the global addon table
ToonAge = ToonAge or {}
local TA = ToonAge

-- Version
TA.version = ADDON_VERSION

-- Module registry: modules register themselves here
TA.modules = {}

-- Event frame
TA.eventFrame = CreateFrame("Frame", "ToonAgeEventFrame")

-- ── Registering an event the client may not have ──────────────────────
--
-- RegisterEvent THROWS on an event the running client does not define, and
-- module Init calls it directly. One bad name therefore takes the whole module
-- down: on WoW Forever, DataHarvester died at Init on LEARNED_SPELL_IN_TAB --
-- an event modern clients replaced with LEARNED_SPELL_IN_SKILL_LINE -- and
-- with it went the item, spell and talent recording that client exists to
-- collect. Every other event it asked for was fine.
--
-- This is the same shape as calling an API the client lacks, and it gets the
-- same treatment: attempt it, survive the miss, and write down what was
-- missing so it can be reported rather than rediscovered.
--
-- What the client does NOT define is real information about that client --
-- the same kind the API manifest exists to capture -- so the names are kept
-- and surfaced by /ta health rather than silently swallowed.
TA.unknownEvents = {}

--- Registers an event, or records it as unavailable on this client.
--- Returns true when the client accepted it.
function TA:RegisterEvent(event)
    if type(event) ~= "string" or event == "" then return false end
    local ok = pcall(self.eventFrame.RegisterEvent, self.eventFrame, event)
    if not ok then
        self.unknownEvents[event] = true
        return false
    end
    return true
end

-- ── Chat output ───────────────────────────────────────────────────────────
-- One funnel for everything the addon says. Before this there were 309 direct
-- print() calls across 53 modules and no way to quiet any of them: a fresh
-- login printed a wall of text and the user had no recourse.
--
-- The colours below are not new. They were already in use and already meant
-- these things -- this only makes the convention enforceable.
--
-- OUTPUT is deliberately outside the severity scale. A reply to a command the
-- user just typed is not logging, and must not vanish because the log level is
-- low. /ta errors printing nothing would be a bug, not quiet.
TA.LOG = {
    OUTPUT = 0,   -- direct answer to a user command -- always shown
    ERROR  = 1,
    WARN   = 2,
    INFO   = 3,
    DEBUG  = 4,
}

local LOG_COLOR = {
    [0] = "FFFFD100",   -- gold
    [1] = "FFFF4444",   -- red
    [2] = "FFFF9A1A",   -- orange
    [3] = "FFFFD100",   -- gold
    [4] = "FF00CCFF",   -- cyan
}

-- Default WARN: a working install says nothing at login. InitDB raises it from
-- db.logLevel once SavedVariables exist. Until then -- module load, which is
-- before InitDB runs -- this value applies, so early output is quiet too.
TA.logLevel = TA.LOG.WARN

-- ── Output routing ────────────────────────────────────────────────────────
-- Three destinations, and every line belongs to exactly one of them:
--
--   PANEL  -- game data the player asked to look at (XP, stats, gear). That
--            belongs on a tab in the addon window. A PANEL command opens the
--            tab and prints nothing at all, so there is no text to route.
--   REPORT -- diagnostics, dumps, module lists, anything the user might paste
--            into a bug report. Goes to the selectable copy window, the same
--            one /ta errors copy opens.
--   CHAT   -- one-line acknowledgements. Nothing else is allowed here.
--
-- Two design decisions worth stating, because the obvious implementations of
-- both are wrong:
--
-- 1. The capture is installed at the PRINTER, not at the call site. That is the
--    whole point: ~300 TA:Print calls across the modules need no edit, and a
--    module written next month is routed correctly without knowing any of this
--    exists. A per-call-site sink argument would have to be added 300 times and
--    would be forgotten the 301st.
--
-- 2. There is no table mapping command -> sink. Such a table goes stale the
--    first time a command is added, which is exactly the failure that produced
--    three disagreeing copies of the command list further down this file.
--    Instead every command captures to REPORT and the LINE COUNT decides:
--    ACK_MAX lines or fewer is an acknowledgement and prints to chat, more than
--    that is a report and opens the window. "Debug mode: ON" needs no window;
--    a 40-line module list cannot live in a chat frame you can't select.
TA.SINK = { CHAT = "chat", REPORT = "report", PANEL = "panel" }

-- Output this short is an acknowledgement, not a report. ONE line: a status
-- reply ("Debug mode: ON", "Chat verbosity set to info.") stays in chat; any
-- command that produces two lines or more opens the copy window, so real
-- output is always selectable and never scrolls away in the chat frame
-- (2026-09-30: "anything that has output ... to a window for a copyable
-- version"). This was 3, which let usage hints and short lists print to chat.
local ACK_MAX = 1

-- Active capture, or nil when output goes straight to chat.
TA._sink = nil

-- The one place a line leaves this addon. Every printer below funnels here.
local function Emit(text)
    local sink = TA._sink
    if sink then
        sink.lines[#sink.lines + 1] = tostring(text)
        return
    end
    print(tostring(text))
end
TA.Emit = Emit

-- ── Background errors ─────────────────────────────────────────────────────
-- An error thrown by a module's event handler is not a reply to anything the
-- user typed, so it does not belong in chat as text -- and it cannot open a
-- window either, because a handler that throws on UNIT_AURA throws forty times
-- a fight. The log already has the full entry with its stack. Chat gets one
-- throttled line pointing at it, and nothing else.
local ERROR_NOTICE_INTERVAL = 20   -- seconds between chat notices
local lastErrorNotice, pendingErrors = 0, 0

--- Log a background error and, at most once per interval, say so in one line.
--- @param source string  module name, or a label like "UI refresh"
--- @param msg    string  the error
function TA:NoteError(source, msg)
    if TA.ErrorLog and TA.ErrorLog.Log then
        TA.ErrorLog:Log(source or "Background", msg, debugstack(2, 6, 0))
    end
    pendingErrors = pendingErrors + 1

    local now = (GetTime and GetTime()) or 0
    if now - lastErrorNotice < ERROR_NOTICE_INTERVAL then return end
    lastErrorNotice = now

    local n = pendingErrors
    pendingErrors = 0
    print(("|cFFFF4444[ToonAge]|r %d error%s logged -- %s"):format(
        n, n == 1 and "" or "s",
        (TA.MakeSlashLink and TA:MakeSlashLink("errors copy", "open the log"))
            or "/ta errors copy"))
end

--- Run `fn(...)` with everything it prints captured and routed to `sink`.
--- @param sink string   one of TA.SINK
--- @param title string  window header if the output ends up in the copy window
function TA:WithSink(sink, title, fn, ...)
    if sink == TA.SINK.CHAT then return fn(...) end

    local prev = TA._sink
    TA._sink = { lines = {}, title = title }

    local ok, err = pcall(fn, ...)

    local cap = TA._sink
    -- Restore BEFORE flushing. Flushing prints, printing goes through Emit, and
    -- Emit would capture the flush into the capture it is flushing.
    TA._sink = prev

    if not ok then
        -- A command that threw is precisely what the copy window is for: the
        -- partial output and the error together, selectable, in one place.
        cap.lines[#cap.lines + 1] = "|cFFFF4444error:|r " .. tostring(err)
        if TA.ErrorLog and TA.ErrorLog.Log then
            TA.ErrorLog:Log("Command:" .. tostring(title), err, debugstack(2, 6, 0))
        end
    end

    if #cap.lines == 0 then return ok end

    -- Nested capture: an inner command's lines belong to the outer report.
    if prev then
        for _, line in ipairs(cap.lines) do
            prev.lines[#prev.lines + 1] = line
        end
        return ok
    end

    -- Count display lines, not print calls: one TA:Raw carrying a whole
    -- export joined with "\n" is many lines (/ta coordexport printed its
    -- entire export to chat as a single "line", 2026-09-30).
    local shown = 0
    for _, line in ipairs(cap.lines) do
        local _, nl = tostring(line):gsub("\n", "")
        shown = shown + 1 + nl
    end

    if ok and shown <= ACK_MAX then
        for _, line in ipairs(cap.lines) do print(line) end
        return ok
    end

    if TA.ShowCopyWindow then
        TA:ShowCopyWindow(cap.title or "ToonAge", table.concat(cap.lines, "\n"))
        print(("|cFFFFD100[ToonAge]|r %s -- %d lines, opened in a window you can select and paste.")
              :format(cap.title or "report", #cap.lines))
    else
        -- No window available (UI not initialised yet): chat is the fallback,
        -- because losing the output entirely is worse than putting it here.
        for _, line in ipairs(cap.lines) do print(line) end
    end
    return ok
end

-- module is optional:  TA:Print(TA.LOG.INFO, "Arrow", msg)  ->  [TA Arrow] msg
--                      TA:Print(TA.LOG.INFO, nil, msg)      ->  [TA] msg
--
-- The level filter is skipped while a capture is active. A diagnostic command
-- whose output is DEBUG-level printed NOTHING at the WARN default -- you had to
-- raise verbosity first to see the thing you just asked for. Inside a capture
-- the destination is a window the user opened on purpose, so there is nothing
-- to protect them from.
function TA:Print(level, module, msg)
    level = level or TA.LOG.INFO
    if not TA._sink and level > (TA.logLevel or TA.LOG.WARN) then return end
    Emit(string.format("|c%s[%s]|r %s",
        LOG_COLOR[level] or LOG_COLOR[3],
        module and ("TA " .. module) or "TA",
        tostring(msg)))
end

-- No prefix, still filtered. For the indented continuation lines under a header
-- ("  Arrow ON", "  3 loaded · 1 off"), where a repeated [TA] on every row would
-- be noise. Same level rules; only the tag is dropped.
function TA:Raw(level, msg)
    level = level or TA.LOG.INFO
    if not TA._sink and level > (TA.logLevel or TA.LOG.WARN) then return end
    Emit(msg)
end

function TA:Printf(level, module, fmt, ...)
    level = level or TA.LOG.INFO
    if not TA._sink and level > (TA.logLevel or TA.LOG.WARN) then return end
    -- Format under pcall: a bad format string in a log line must never be the
    -- thing that breaks a module. Fall back to the raw format string.
    local ok, out = pcall(string.format, fmt, ...)
    TA:Print(level, module, ok and out or fmt)
end

-- Default saved variables schema
local DB_DEFAULTS = {
    minimap = { minimized = false, position = 45 },
    char    = {},  -- per-character data keyed by "Name-Server"

    -- Module enable/disable toggles. Optional modules can be turned off by
    -- the user via /ta toggle <name>. Core modules (Character, Gear, Talents,
    -- Rotation, QuestTracker, Arrow, GuideParser) always load.
    modules = {
        NavHud       = true,
        MapPins      = true,
        CombatState  = true,
        DungeonGear  = true,
        TravelRouter = true,
        Onboarding   = true,
        QuestRewardAdvisor = true,
        DungeonGuide       = true,
    },

    -- What happens when a character is seen for the first time. One setting
    -- rather than a web of booleans: the old onboardScope/onboardedAccount pair
    -- could disagree with each other, and nothing defined which won.
    --
    --   "wizard"  — (default) show the guided setup popup, once per character.
    --   "inherit" — no popup. Apply defaultPreset silently and print one line.
    --   "off"     — do nothing at all. No popup, no message.
    --
    -- /ta onboard <wizard|inherit|off> switches. /ta onboard with no argument
    -- always runs the wizard on demand, whatever this is set to.
    newCharBehavior = "wizard",

    -- Which preset "inherit" applies. Set by the wizard whenever a character
    -- completes it, so the choice you made last is the one your alts get.
    defaultPreset   = "auto",

    -- How much ToonAge says in chat. See TA.LOG above. WARN means a healthy
    -- install is silent at login and only speaks up when something is wrong;
    -- replies to commands you typed are LOG.OUTPUT and ignore this entirely.
    -- /ta verbose <error|warn|info|debug> changes it.
    logLevel = 2,   -- TA.LOG.WARN

    -- Usage reporting (Core/Analytics.lua). Records a handful of aggregate
    -- switches into the Wago App's analytics addon IF the player has that app
    -- installed with sharing on; ToonAge itself never sends anything. false
    -- here turns it off regardless. Settings -> Usage reporting.
    analytics = true,

    -- Safe Mode boot flag. Persisted deliberately: the whole point is to
    -- survive a reload when the addon is too broken to reach its own UI.
    -- Cleared only by the user via /ta safemode.
    safeMode = false,

    -- UI layout toggle
    -- true  = Unified HUD (compass + tracker parented inside one draggable frame)
    -- false = Fragmented (each window floats independently, classic feel)
    useUnifiedUI = true,

    -- Position for the unified master frame
    unifiedPosition = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 220 },

    -- Saved independent positions used by the old fragmented layout.
    -- These are written every time the player drags a window in fragmented mode
    -- so switching back preserves wherever they left each window.
    oldUiPositions = {
        arrow  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 150  },
        guide  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 0    },
    },
}

-- ── SavedVariables ────────────────────────────────────────────────────

--- Copies a value out of DB_DEFAULTS. Tables are copied recursively.
--- Assigning a default table straight into the DB shares the reference, which
--- makes DB_DEFAULTS itself user-writable: on a fresh install db.modules *is*
--- DB_DEFAULTS.modules, so `/ta toggle` edits the defaults. That survives until
--- reload, and `/ta reset` in the same session then "restores" the mutated
--- table rather than the shipped one.
--- @param v any
--- @return any
local function CopyDefault(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, sub in pairs(v) do
        out[k] = CopyDefault(sub)
    end
    return out
end

--- Recursively backfills missing keys of `defaults` into `dst`.
---
--- Replaces the three hand-written blocks that used to deep-default
--- oldUiPositions/unifiedPosition/modules one at a time. Those covered three of
--- the four nested tables in DB_DEFAULTS -- `minimap` was missed, and any nested
--- default added later would have been missed too, silently, on every existing
--- install. One recursive walk cannot develop that kind of hole.
---
--- Contract: fill in what is absent, never overwrite what the user set, and
--- never hand out a reference into the defaults table (see CopyDefault).
--- @param dst table       destination -- a live SavedVariables subtree
--- @param defaults table  shipped defaults to backfill from
--- @return table dst
local function ApplyDefaults(dst, defaults)
    for k, v in pairs(defaults) do
        if dst[k] == nil then
            dst[k] = CopyDefault(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            ApplyDefaults(dst[k], v)
        end
        -- Type mismatch (the user has a scalar where defaults grew a table, or
        -- the reverse) is left alone deliberately. Coercing it would discard
        -- user data; whichever reader cares should type-check.
    end
    return dst
end

-- NOTE ON PER-CHARACTER DEFAULTS -- deliberately absent.
--
-- A CHAR_DEFAULTS table applied to TA.charDB was tried and reverted. It looks
-- like the obvious counterpart to DB_DEFAULTS, but this scope works differently:
-- modules lazily create their own subtables at the call site
-- (`charDB.x = charDB.x or {}`) and then treat *absence as meaning something*.
-- charDB.tracker being nil is how the code knows no layout preset has been
-- applied; Tools/test_onboarding.py asserts exactly that in three places.
--
-- Pre-creating those keys as empty tables silently converts "never set" into
-- "set to empty" across ~35 presence checks. The lazy idiom already provides the
-- backfill a defaults table would -- a key added today reads correctly on an alt
-- created three versions ago, because the reader supplies the default itself.
--
-- If you add a per-character key: follow the `or {}` idiom at the point of use.
-- Do not reintroduce a defaults table here without first re-running
-- Tools/test_onboarding.py.

-- ── Schema migrations ─────────────────────────────────────────────────
-- Ordered, versioned upgrades for SavedVariables. ApplyDefaults only ADDS
-- missing keys; anything that renames, moves, reshapes or deletes saved data
-- belongs here instead.
--
-- Rules for adding a migration:
--   1. Append a function at index DB_SCHEMA_VERSION + 1 and bump the constant.
--      Never renumber or edit a migration that has shipped.
--   2. Make it idempotent (safe if it half-ran before an error or a crash).
--   3. Account data -> ACCOUNT_MIGRATIONS(db). Per-character data ->
--      CHAR_MIGRATIONS(charDB, charKey); those run when that character logs in.
--   4. Don't pre-create per-character keys (see the note above InitDB).
--
-- Behaviour:
--   * Fresh install / new character: stamped with the current version, no
--     migrations run (there is nothing old to upgrade).
--   * Existing data without a stamp is version 0.
--   * Each step runs in pcall. On error the version stays at the last good
--     step, the error is logged, and the addon keeps loading; the failed step
--     is retried next login.
--   * Data from a NEWER build (downgrade) is left untouched and not re-stamped.

local ACCOUNT_MIGRATIONS = {
    -- [1] Old two-flag onboarding model -> newCharBehavior.
    -- Only "account scope, already done" maps to a hard off. Account scope that
    -- had not fired yet becomes "wizard" and now runs for each new character
    -- rather than once ever -- the closest honest equivalent, since the new
    -- model has no run-once-then-disable state. The old keys are dropped once
    -- translated; leaving them would recreate the ambiguity this replaces.
    [1] = function(db)
        if db.onboardScope ~= nil or db.onboardedAccount ~= nil then
            if db.newCharBehavior == nil or db.newCharBehavior == DB_DEFAULTS.newCharBehavior then
                if db.onboardScope == "account" and db.onboardedAccount then
                    db.newCharBehavior = "off"
                else
                    db.newCharBehavior = "wizard"
                end
            end
            db.onboardScope     = nil
            db.onboardedAccount = nil
        end
    end,
}

local CHAR_MIGRATIONS = {
    -- [1] = function(charDB, charKey) ... end,
}

local DB_SCHEMA_VERSION   = #ACCOUNT_MIGRATIONS
local CHAR_SCHEMA_VERSION = #CHAR_MIGRATIONS

--- Runs pending migrations on `tbl` in order.
--- @return number versionReached, string|nil errorMessage
local function RunMigrations(tbl, list, target, label, ...)
    local from = tonumber(tbl.schemaVersion) or 0
    if from > target then
        return from, "saved data is from a newer ToonAge build (schema "
            .. from .. " > " .. target .. "); left unchanged"
    end
    for v = from + 1, target do
        local step = list[v]
        if step then
            local ok, err = pcall(step, tbl, ...)
            if not ok then
                local msg = label .. " migration " .. v .. " failed: " .. tostring(err)
                if TA.ErrorLog and TA.ErrorLog.Log then TA.ErrorLog:Log("Migrations", msg, label) end
                return tbl.schemaVersion or from, msg
            end
        end
        tbl.schemaVersion = v
    end
    return tbl.schemaVersion or target, nil
end

TA.SCHEMA_VERSION      = DB_SCHEMA_VERSION
TA.CHAR_SCHEMA_VERSION = CHAR_SCHEMA_VERSION
-- Exposed for tests and /ta debugging.
TA._RunMigrations      = RunMigrations
TA._AccountMigrations  = ACCOUNT_MIGRATIONS
TA._CharMigrations     = CHAR_MIGRATIONS

function TA:InitDB()
    -- ToonAgeDB is set by WoW from SavedVariables on login
    local fresh = (ToonAgeDB == nil) or (next(ToonAgeDB) == nil)
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB

    -- 1) Upgrade old shapes BEFORE defaults are backfilled, so a migration can
    --    still tell "user never set this" from "default just filled it in".
    if fresh then
        db.schemaVersion = DB_SCHEMA_VERSION
    else
        local _, err = RunMigrations(db, ACCOUNT_MIGRATIONS, DB_SCHEMA_VERSION, "account")
        if err then self._migrationError = err end
    end

    -- 2) Backfill every missing key, at every depth, so sub-keys added in new
    --    versions land in existing SavedVariables without wiping user data.
    ApplyDefaults(db, DB_DEFAULTS)

    self.db = db

    -- Raise the log level from the saved value. Until this line runs, output is
    -- filtered at the WARN default set beside TA.LOG, which is why anything
    -- printed during module load stays quiet on a default install.
    TA.logLevel = db.logLevel or TA.LOG.WARN

    if self._migrationError and TA.Print and TA.LOG then
        TA:Print(TA.LOG.WARN, "SavedVariables", self._migrationError)
    end

    -- Per-character key
    local name   = UnitName("player") or "Unknown"
    local server = GetRealmName() or "Unknown"
    self.charKey = name .. "-" .. server
    local charDB = self.db.char[self.charKey]
    if charDB == nil then
        charDB = { schemaVersion = CHAR_SCHEMA_VERSION }
        self.db.char[self.charKey] = charDB
    else
        local _, err = RunMigrations(charDB, CHAR_MIGRATIONS, CHAR_SCHEMA_VERSION, "character", self.charKey)
        if err and TA.Print and TA.LOG then TA:Print(TA.LOG.WARN, "SavedVariables", err) end
    end
    self.charDB = charDB
end

-- ── Module system ─────────────────────────────────────────────────────
function TA:RegisterModule(name, module)
    self.modules[name] = module
    if TA.debug then
        TA:Print(TA.LOG.DEBUG, nil, "Module registered: " .. name)
    end
end

--- The module, IF it is running on this client.
---
--- Returns nil for anything the flavor profile skipped, Safe Mode skipped, the
--- user turned off, or that auto-disabled after errors. All four mean the same
--- thing: Init never ran, so its state is not set up and calling into it is a
--- bug waiting to happen.
---
--- This is the gate for cross-module calls. QuestTracker asking SpecAdaptive
--- for a dungeon tip found this the hard way on WoW Forever: the profile
--- skipped SpecAdaptive, but GetModule handed it over anyway and it threw on
--- the first API a specless client does not have. Every caller already writes
--- `local M = TA:GetModule("X"); if M and M.Fn then`, so returning nil makes
--- all 190-odd call sites correct at once.
---
--- Use GetRegisteredModule when you specifically need a module that is off —
--- the health report and the toggle list do.
function TA:GetModule(name)
    local mod = self.modules[name]
    if not mod then return nil end
    if mod._disabled or mod._profileSkipped then return nil end
    return mod
end

--- The module whether or not it is running. For diagnostics and toggles only.
function TA:GetRegisteredModule(name)
    return self.modules[name]
end

--- Returns a health report of all registered modules.
--- @return table — array of { name, status="loaded"|"disabled"|"errored", error=string|nil }
function TA:GetHealthReport()
    local report = {}
    for name, mod in pairs(self.modules) do
        local entry = { name = name }
        if mod._disabled then
            entry.status = "disabled"
        elseif mod._initError then
            entry.status = "errored"
            entry.error  = mod._initError
        else
            entry.status = "loaded"
        end
        table.insert(report, entry)
    end
    table.sort(report, function(a, b) return a.name < b.name end)
    return report
end

-- ── Safe Mode ─────────────────────────────────────────────────────────
-- Two independent mechanisms with the same goal: keep one broken module from
-- taking the whole addon down with it.
--
-- 1. Automatic, per session. A module whose OnEvent throws repeatedly gets
--    switched off for the rest of the session. This is NOT persisted — a
--    transient failure should not silently disable something forever, so a
--    reload always gives every module another chance.
--
-- 2. Manual, persisted. `/ta safemode` sets a flag that survives reload and
--    boots with only the core set initialised. This is the one to reach for
--    when the addon breaks badly enough that you cannot get to its UI.

-- Errors on one module in one session before it is switched off. High enough
-- that a one-off does not trip it, low enough to stop a module that fails on a
-- high-frequency event from erroring hundreds of times.
local ERROR_DISABLE_THRESHOLD = 10

-- Stop printing after this many. A module failing on BAG_UPDATE can emit
-- hundreds of identical lines and scroll away whatever you were trying to read.
-- Every error still reaches the ErrorLog; only the chat spam is capped.
local ERROR_PRINT_LIMIT = 3

-- Initialised even in safe mode. The seven core modules the addon is unusable
-- without, plus ErrorLog — safe mode exists to diagnose a problem, and
-- disabling the thing that records problems would defeat it entirely.
-- ── Engine modules the flavor gate must never skip ────────────────────
--
-- A few pieces under Core/ register themselves as modules so they get Init and
-- OnEvent like everything else. They are ENGINE, not product: no flavor
-- profile lists them, because a profile answers "what does this flavor ship?"
-- and the answer for the engine is always "all of it".
--
-- Leaving them to the gate broke two things silently, on exactly the clients
-- least able to absorb it:
--
--   ApiGuard  Its Init is what calls Probe(). Skip it and Guard.hasRun stays
--             false, and TA:HasAPI() short-circuits to `return true` for
--             everything. The whole design is TWO gates -- the profile says
--             what a flavor ships, ApiGuard says what the client can actually
--             do -- and the second gate was off on every non-retail flavor.
--             Retail is allowAll so it ran there; Forever, whose API surface is
--             only part mapped and which needs it most, got nothing.
--
--   SkillScan Its OnEvent clears the skill cache on SKILL_LINES_CHANGED and
--             PLAYER_LEVEL_UP. A skipped module receives no events, so on TBC
--             the cache went stale and never refreshed -- under StatCaps and
--             WeaponSkill, the two features that exist to read skill levels.
--
-- State and TBCStats have neither Init nor OnEvent, so they cost nothing
-- either way; they are listed because the rule is "the engine always runs",
-- not "the engine runs where we noticed it mattered".
local ENGINE_MODULES = {
    ApiGuard = true, State = true, SkillScan = true, TBCStats = true,
    ErrorLog = true,   -- a client that errors is when you need this most
}

local SAFE_MODE_KEEP = {
    ErrorLog = true,
    Character = true, Gear = true, Talents = true, Rotation = true,
    QuestTracker = true, Arrow = true, GuideParser = true,
}

function TA:InitModules()
    local safe = self.db and self.db.safeMode

    -- ── Wrong build for this client ───────────────────────────────────────
    -- A client that does not recognise a TOC suffix does not error: it reads
    -- whichever TOC it does recognise, and the addon runs another flavour's
    -- module set with no sign anything is wrong. That is exactly how Forever
    -- came to load the entire retail product.
    --
    -- Core/Environment.lua already detects it (TA:TocFlavorMismatch compares
    -- the client against the loaded TOC's "## X-Flavor"), but until now the
    -- only place that said so was /ta health -- printed long after every wrong
    -- module had initialised. This is where the detection has to bite.
    --
    -- ENGINE_MODULES still start, so /ta health, /ta errors and /ta apiprobe
    -- can explain the situation and be copied into a bug report.
    local wantFlavor, gotFlavor
    if self.TocFlavorMismatch then wantFlavor, gotFlavor = self:TocFlavorMismatch() end
    if wantFlavor then
        self.wrongPackage = { want = wantFlavor, got = gotFlavor }
        TA:Printf(TA.LOG.ERROR, nil,
            "This is a %s client but the %s build loaded. Nothing will run -- "
            .. "install the %s build. |cFFFFD100/ta health|r for detail.",
            tostring(wantFlavor), tostring(gotFlavor), tostring(wantFlavor))
        for name, mod in pairs(self.modules) do
            mod._errorCount   = 0
            mod._autoDisabled = false
            if ENGINE_MODULES[name] then
                mod._disabled = false
                if type(mod.Init) == "function" then
                    local ok, err = pcall(mod.Init, mod)
                    if not ok then
                        TA:NoteError(name, ("Init failed: %s"):format(tostring(err)))
                    end
                end
            else
                mod._disabled       = true
                mod._profileSkipped = true
                mod._profileReason  = "wrong build for this client"
            end
        end
        return
    end

    if safe then
        TA:Print(TA.LOG.WARN, nil, "SAFE MODE — only core modules loaded. "
              .. "|cFF888780/ta safemode to turn off, then /reload.|r")
    end

    for name, mod in pairs(self.modules) do
        -- Reset per-session failure state. Without this a module auto-disabled
        -- last session would look disabled on a fresh login even though its
        -- counter is gone.
        mod._errorCount = 0
        mod._autoDisabled = false

        local userDisabled = self.db and self.db.modules and self.db.modules[name] == false
        local safeSkipped  = safe and not SAFE_MODE_KEEP[name]

        -- Flavor gate: skip modules the active flavor's profile does not ship
        -- (Core/Profile.lua). On Retail this is allow-all, so nothing is
        -- skipped here; on TBC/MoP/scaffold flavors it prevents retail-only
        -- modules from initialising on a client they were never built for.
        -- Guarded so a missing Profile (e.g. minimal test harness) defaults to
        -- "allowed" rather than disabling everything.
        local profileReason
        local profileSkipped = false
        if self.ModuleAllowed and not ENGINE_MODULES[name] then
            local allowed, reason = self:ModuleAllowed(name)
            if not allowed then
                profileSkipped = true
                profileReason = reason
            end
        end

        if userDisabled or safeSkipped or profileSkipped then
            mod._disabled = true
            mod._safeSkipped = safeSkipped or nil
            mod._profileSkipped = profileSkipped or nil
            mod._profileReason = profileReason
        else
            mod._disabled = false
            mod._safeSkipped = nil
            if mod.Init then
                local ok, err = pcall(mod.Init, mod)
                if not ok then
                    mod._initError = tostring(err)
                    TA:NoteError(name, ("init failed: %s"):format(tostring(err)))
                    if TA.ErrorLog then TA.ErrorLog:Log(name .. " Init", tostring(err), "") end
                end
            end
        end
    end

    -- Second pass, after EVERY Init has run: register the events each running
    -- module declares in M.Events. Six Forever modules declared lists that no
    -- code ever read, so UNIT_STATS, UNIT_RESISTANCES, ACTIONBAR_SLOT_CHANGED,
    -- the pet-happiness events and all five PvP events were never registered
    -- and those tabs went stale (confirmed by /ta test, 2026-09-28). Done after
    -- the loop so a module's own unfiltered RegisterEvent always wins over the
    -- player-only registration below.
    for _, mod in pairs(self.modules) do
        if not mod._disabled and not mod._initError then
            self:RegisterModuleEvents(mod)
        end
    end
end

--- Registers the events a module lists in `mod.Events`.
---
--- UNIT_* events are registered for "player" only (RegisterUnitEvent), and only
--- when nothing has already registered them for all units: UNIT_FACTION or
--- UNIT_STATS for every nameplate would rebuild the open tab constantly for
--- data about somebody else. Anything else goes through TA:RegisterEvent, so a
--- name this client does not define is recorded for /ta health, not thrown.
function TA:RegisterModuleEvents(mod)
    if type(mod) ~= "table" or type(mod.Events) ~= "table" then return end
    local f = self.eventFrame
    for _, event in ipairs(mod.Events) do
        if type(event) == "string" and event ~= "" then
            local okQ, already = pcall(f.IsEventRegistered, f, event)
            if not (okQ and already) then
                if event:find("^UNIT_") and f.RegisterUnitEvent then
                    if not pcall(f.RegisterUnitEvent, f, event, "player") then
                        self.unknownEvents[event] = true
                    end
                else
                    self:RegisterEvent(event)
                end
            end
        end
    end
end

-- High-frequency events go only to the modules that mention them; everything
-- else is still broadcast. Generated from module sources so a route can't miss
-- a module that handles the event (a module must name an event to filter on it).
-- BEGIN GENERATED EVENT_ROUTES (Tools/gen_event_routes.py)
local EVENT_ROUTES = {
    BAG_UPDATE = { "Gear", "Heirlooms" },
    UNIT_INVENTORY_CHANGED = { "Character", "ForeverGear", "Gear" },
    GET_ITEM_INFO_RECEIVED = { "ForeverGear", "Gear", "Heirlooms" },
    QUEST_LOG_UPDATE = { "CoordHarvester", "NameplateObjectives", "PullPlanner", "QuestTracker", "TargetMarker" },
    UNIT_AURA = { "CombatState" },
    UNIT_STATS = { "ForeverCharacter", "ForeverScrolls" },
    COMBAT_RATING_UPDATE = {  },
    UNIT_POWER_UPDATE = { "CombatState" },
    UNIT_HEALTH = { "CombatState", "RoleMorph" },
    CHAT_MSG_SYSTEM = { "ForeverWorldRefresh" },
    PLAYER_XP_UPDATE = { "ForeverCharacter", "XPTracker" },
    ACTIONBAR_SLOT_CHANGED = { "CombatRecorder", "ForeverRotation" },
    SPELL_UPDATE_COOLDOWN = {  },
    PLAYER_TARGET_CHANGED = { "CombatState", "ForeverPvP", "Gear" },
    UNIT_ATTACK_POWER = {  },
    BAG_UPDATE_DELAYED = { "AutoEquip", "DataHarvester", "ForeverGear" },
    ZONE_CHANGED = { "CoordResolver", "TravelRouter" },
    UNIT_SPELLCAST_SUCCEEDED = { "CombatRecorder", "CombatState", "ForeverCastLog" },
}
-- END GENERATED EVENT_ROUTES

local function DispatchToModule(name, mod, event, ...)
    -- _profileSkipped is checked as well as _disabled. They are set together in
    -- InitModules, but a module that was never initialised for this flavor must
    -- not receive events under any circumstances: its OnEvent will reach for
    -- data that was deliberately not loaded, and the player gets an error for a
    -- module the health report says is off.
    if mod.OnEvent and not mod._disabled and not mod._profileSkipped then
        do
            local ok, err = pcall(mod.OnEvent, mod, event, ...)
            if not ok then
                mod._errorCount = (mod._errorCount or 0) + 1

                if mod._errorCount <= ERROR_PRINT_LIMIT then
                    TA:NoteError(name, ("OnEvent error: %s"):format(tostring(err)))
                elseif mod._errorCount == ERROR_PRINT_LIMIT + 1 then
                    TA:Printf(TA.LOG.WARN, nil, "%s keeps failing — muting further errors. "
                          .. "|cFF888780/ta errors to read them.|r", name)
                end

                -- Pass the event as the stack field. Which event triggered a
                -- failure is usually the fastest way to find it, and this was
                -- previously logged as an empty string.
                if TA.ErrorLog then TA.ErrorLog:Log(name .. " OnEvent", tostring(err), event or "") end

                if mod._errorCount >= ERROR_DISABLE_THRESHOLD then
                    mod._disabled = true
                    mod._autoDisabled = true
                    local msg = name .. " disabled after " .. mod._errorCount
                                .. " errors this session"
                    TA:Print(TA.LOG.WARN, "Safe Mode", msg
                          .. ". |cFF888780Reload to re-enable. /ta health for status.|r")
                    if TA.ErrorLog then TA.ErrorLog:Log("SafeMode", msg, event or "") end
                end
            end
        end
    end
end

function TA:UpdateModules(event, ...)
    local route = EVENT_ROUTES[event]
    if route then
        for i = 1, #route do
            local mod = self.modules[route[i]]
            if mod then DispatchToModule(route[i], mod, event, ...) end
        end
        return
    end
    for name, mod in pairs(self.modules) do
        DispatchToModule(name, mod, event, ...)
    end
end

-- ── Event registration ────────────────────────────────────────────────
-- ADDON_LOADED is one-shot. PLAYER_ENTERING_WORLD stays registered: the first
-- fire runs login (SavedVariables are guaranteed loaded by then), later fires
-- are zone-ins that refresh instance/arena-dependent state.
local PERSISTENT_EVENTS = {
    "PLAYER_LEVEL_UP",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "TRAIT_CONFIG_UPDATED",        -- fires when active talent loadout switches (Dragonflight+)
    "SKILL_LINES_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE",
    "GROUP_ROSTER_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PET_STABLE_UPDATE",
    "UNIT_PET",
    "CHAT_MSG_SYSTEM",
    "GET_ITEM_INFO_RECEIVED",
    "QUEST_ACCEPTED",              -- needed by DevHelpers recorder & QuestTracker; registered here
                                   -- to guarantee it fires regardless of module init order.
    "ENCOUNTER_START",             -- hide HUD elements during boss fights (DBM/BigWigs bridge)
    "ENCOUNTER_END",               -- restore HUD after boss kill/wipe
    "UNIT_ENTERED_VEHICLE",        -- hide HUD in vehicles
    "UNIT_EXITED_VEHICLE",         -- restore HUD after vehicle exit
    "PET_BATTLE_OPENING_START",    -- hide HUD in pet battles
    "PET_BATTLE_OVER",             -- restore HUD after pet battle
}

-- Register one-shot boot events
TA:RegisterEvent("ADDON_LOADED")
TA:RegisterEvent("PLAYER_ENTERING_WORLD")
TA:RegisterEvent("PLAYER_LOGOUT")   -- reset tripwire: last counts before SavedVariables are written

-- Register persistent events
for _, event in ipairs(PERSISTENT_EVENTS) do
    TA:RegisterEvent(event)
end

TA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local TA  = ToonAge
    local arg1 = ...

    if event == "PLAYER_LOGOUT" then
        -- Only after a login that loaded the DB; a failed login must not
        -- overwrite the last good counts with zeros.
        if TA.db then pcall(TA.GuardSnapshot, TA) end
    end
    if event == "ADDON_LOADED" then
        -- Only act on our own addon load; unregister immediately
        if arg1 == "ToonAge" then
            self:UnregisterEvent("ADDON_LOADED")
            -- Pre-init: nothing to do yet — SavedVariables not available yet
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not TA._loggedIn then
            -- First fire: SavedVariables are guaranteed loaded — init DB and UI.
            TA._loggedIn = true
            TA:OnLogin()
        else
            -- Every later loading screen (instance, arena, raid, portal): let
            -- modules that care re-check where they are, and redraw the open tab.
            -- Not broadcast through OnEvent, because modules such as DungeonGuide
            -- already listen for this event on their own frames.
            local isInitialLogin, isReloadingUi = ...
            if TA.State then TA.State:Invalidate(event) end
            for name, mod in pairs(TA.modules) do
                if mod.OnEnterWorld and not mod._disabled then
                    local ok, err = pcall(mod.OnEnterWorld, mod, isInitialLogin, isReloadingUi)
                    if not ok and TA.ErrorLog then TA.ErrorLog:Log(name .. " OnEnterWorld", tostring(err), event) end
                end
            end
            TA:QueueUIRefresh(event)
        end

    else
        -- Invalidate cached display state BEFORE modules run, so a module
        -- handling this event recomputes from a cleared cache instead of
        -- reading back its own stale value from the previous tick. Ordering
        -- here is the whole point — invalidating afterwards would hand every
        -- handler the very data the event just made wrong.
        if TA.State then TA.State:Invalidate(event) end

        -- Resolve pending item-data requests after invalidation but before
        -- modules run, so a module handling this event sees the item already
        -- populated rather than racing the callback that fills it in.
        if event == "GET_ITEM_INFO_RECEIVED" and TA.Utils and TA.Utils.OnItemInfoReceived then
            local itemID, success = ...
            TA.Utils.OnItemInfoReceived(itemID, success)
        end

        -- All persistent events: dispatch to modules immediately (they do their
        -- own throttling), but coalesce the UI rebuild — see QueueUIRefresh.
        TA:UpdateModules(event, ...)
        TA:QueueUIRefresh(event)
    end
end)

-- ── Coalesced UI refresh ──────────────────────────────────────────────
-- UI:Refresh() tears down and rebuilds the whole active tab. Some of the
-- events above are high-frequency: BAG_UPDATE fires once per bag per change,
-- so looting a single stack can fire it five or more times in one frame.
-- Rebuilding the Gear tab (a full inventory scan) that many times per loot is
-- the addon's worst stutter. Per .rules.md ("Debounce high-frequency events"),
-- collect the events that arrive within a short window and rebuild once.
local UI_REFRESH_DELAY = 0.15

-- Minimum seconds between tab rebuilds when a batch contains ONLY these events.
local UI_REFRESH_THROTTLE = {
    QUEST_LOG_UPDATE = 2.0, BAG_UPDATE = 1.0, BAG_UPDATE_DELAYED = 1.0,
    UNIT_INVENTORY_CHANGED = 1.0, GET_ITEM_INFO_RECEIVED = 1.0,
    UNIT_STATS = 1.0, COMBAT_RATING_UPDATE = 1.0, UNIT_ATTACK_POWER = 1.0,
    CHAT_MSG_SYSTEM = 1.0, PLAYER_XP_UPDATE = 2.0,
}

TA._pendingUIEvents = nil   -- set of event names awaiting a flush
TA._uiRefreshQueued = false

function TA:QueueUIRefresh(event)
    -- Nothing to rebuild if the panel is closed. Drop the event rather than
    -- queueing work that would be thrown away on flush.
    if not (self.UI and self.UI:IsVisible()) then return end

    -- A caller that forgets to pass the event through still wants a refresh;
    -- a nil table index would throw, so fall back to a sentinel key.
    if event == nil then event = "UNSPECIFIED" end

    self._pendingUIEvents = self._pendingUIEvents or {}
    self._pendingUIEvents[event] = true

    if self._uiRefreshQueued then return end
    self._uiRefreshQueued = true

    local function Flush()
        local events = TA._pendingUIEvents
        -- The panel may have been closed during the delay.
        if not (TA.UI and TA.UI:IsVisible()) then
            TA._pendingUIEvents = nil
            TA._uiRefreshQueued = false
            return
        end

        -- A batch made only of noisy events (quest log, bags, stats...) waits
        -- until its throttle window has passed since the last rebuild, so an
        -- open tab isn't torn down several times a second while questing.
        local wait = 0
        for ev in pairs(events or {}) do
            local t = UI_REFRESH_THROTTLE[ev]
            if not t then wait = 0; break end
            if t > wait then wait = t end
        end
        local since = GetTime() - (TA._lastUIRefresh or 0)
        if wait > 0 and since < wait then
            C_Timer.After(wait - since, Flush)
            return
        end

        TA._pendingUIEvents = nil
        TA._uiRefreshQueued = false
        TA._lastUIRefresh = GetTime()

        local ok, err = pcall(TA.UI.Refresh, TA.UI, events)
        if not ok then
            TA:NoteError("UI refresh", tostring(err))
            if TA.ErrorLog then TA.ErrorLog:Log("UI Refresh", tostring(err), "") end
        end
    end

    C_Timer.After(UI_REFRESH_DELAY, Flush)
end

-- ── Login sequence ────────────────────────────────────────────────────
--- One login step, isolated. A throw in any step used to abort the rest of
--- OnLogin -- including the /ta registration at its end -- leaving a half-
--- loaded addon with no slash command to diagnose it (G4, 2026-09-28).
--- Each step now runs in xpcall: the error goes to the normal error handler
--- (ErrorLog / BugSack see it with a stack), the step is recorded in
--- TA._loginFailures, and the next step still runs.
local function LoginStep(name, fn)
    local ok, err = xpcall(fn, function(e)
        return tostring(e) .. "\n" .. (debugstack and debugstack(2) or "")
    end)
    if not ok then
        TA._loginFailures = TA._loginFailures or {}
        TA._loginFailures[#TA._loginFailures + 1] = name
        -- Kept for ErrorLog: it isn't installed yet when InitDB fails, so the
        -- error would otherwise reach only the default handler.
        TA._loginErrors = TA._loginErrors or {}
        TA._loginErrors[#TA._loginErrors + 1] = { step = name, err = tostring(err) }
        local handler = geterrorhandler and geterrorhandler()
        if handler then pcall(handler, "ToonAge login step '" .. name .. "' failed: " .. tostring(err)) end
    end
    return ok
end

TA._LoginStep = LoginStep   -- exposed for the self-test (login suite)
local RECOVERED_DAYS = 7

-- ── Reset tripwire (2026-10-03) ──────────────────────────────────────────
-- ToonAgeDB was reset on 2026-10-03 between 08:46 and 09:57 with nothing
-- recording why, and WoW's own .bak was already post-reset. ToonAgeGuard is a
-- second, tiny SavedVariable (TOC: "## SavedVariables: ToonAgeDB, ToonAgeGuard")
-- holding only last session's counts. A loss of ToonAgeDB does not take it
-- along, so the next login can tell:
--   * "missing"  -- ToonAgeDB arrived nil: WoW did not load ToonAge.lua
--                   (file deleted, unreadable, or the addon was not saved)
--   * "emptied"  -- arrived as an empty table
--   * "shrank"   -- harvest records dropped by more than half
--   * "reset"    -- a reset ran in ToonAge itself (lastReset says which)
-- Each incident is kept in ToonAgeGuard.incidents and announced once.
local function GuardCounts(db)
    local c = { keys = 0, chars = 0, harvest = 0 }
    if type(db) ~= "table" then return c end
    for _ in pairs(db) do c.keys = c.keys + 1 end
    if type(db.char) == "table" then for _ in pairs(db.char) do c.chars = c.chars + 1 end end
    -- The harvest store moved from foreverHarvest to harvest (harvest spec T3).
    -- Count whichever is present, so the move itself is never read as "shrank".
    local h = (type(db.harvest) == "table" and db.harvest)
        or (type(db.foreverHarvest) == "table" and db.foreverHarvest) or nil
    for _, k in ipairs({ "items", "spells", "talents", "chars", "racials" }) do
        if h and type(h[k]) == "table" then for _ in pairs(h[k]) do c.harvest = c.harvest + 1 end end
    end
    return c
end

local function Tripwire()
    ToonAgeGuard = type(ToonAgeGuard) == "table" and ToonAgeGuard or {}
    local g = ToonAgeGuard
    g.incidents = g.incidents or {}
    local last = g.last
    local now = GuardCounts(ToonAgeDB)
    local build = select(2, GetBuildInfo())
    local kind
    if last and (last.keys or 0) > 0 then
        if ToonAgeDB == nil then kind = "missing"
        elseif now.keys == 0 then kind = "emptied"
        elseif (last.harvest or 0) >= 20 and now.harvest < (last.harvest / 2) then kind = "shrank" end
    end
    if kind then
        local inc = {
            at = time and time() or nil, kind = kind, build = build,
            before = { keys = last.keys, chars = last.chars, harvest = last.harvest, at = last.at, build = last.build },
            after = now, lastReset = g.lastReset,
        }
        table.insert(g.incidents, 1, inc)
        while #g.incidents > 10 do table.remove(g.incidents) end
        TA._resetIncident = inc
    end
    g.lastReset = nil   -- consumed: it explains this login or none
end
TA._GuardCounts = GuardCounts

--- Called at logout and by every reset path. `how` names a reset.
function TA:GuardSnapshot(how)
    ToonAgeGuard = type(ToonAgeGuard) == "table" and ToonAgeGuard or {}
    if how then
        ToonAgeGuard.lastReset = { at = time and time() or nil, how = how }
        return
    end
    local c = GuardCounts(ToonAgeDB)
    c.at = time and time() or nil
    c.build = select(2, GetBuildInfo())
    ToonAgeGuard.last = c
end

function TA:OnLogin()
    -- DB first: every later step and every command reads it. If it fails there
    -- is nothing safe to run, but /ta is still registered below so the failure
    -- can be seen (/ta errors works off the global error handler's log).
    -- Before InitDB touches anything: compare what arrived with last session.
    LoginStep("Tripwire", Tripwire)
    local dbOK = LoginStep("InitDB", function() self:InitDB() end)
    if not dbOK then
        -- Unreadable SavedVariables (wrong type after a crash, a hand-edit, a
        -- schema the migrations can't handle). Start from an empty table so
        -- the addon runs, and keep the old data under _recovered -- attached
        -- AFTER the fresh InitDB, so migrations never see it. Nothing is
        -- deleted; the next logout writes it back out with the new table.
        local old = ToonAgeDB
        ToonAgeDB = {}
        dbOK = LoginStep("InitDB (fresh)", function() self:InitDB() end)
        if dbOK then
            TA:GuardSnapshot("unreadable-settings recovery")
            ToonAgeDB._recovered = { at = time and time() or nil, data = old }
            self._dbRecovered = true
        else
            ToonAgeDB = old    -- both failed: leave the original untouched
        end
    end

    -- ── Dev Build Tester Lock ─────────────────────────────────────────────
    -- Before /ta is registered: an unauthorized dev build stays fully inert.
    if IS_DEV_BUILD then
        local name   = UnitName("player") or "Unknown"
        local server = GetRealmName() or "Unknown"
        local charKey = name .. "-" .. server
        if not AUTHORIZED_TESTERS[charKey] then
            print("|cFFFF4444[ToonAge]|r Dev build — not authorized. Contact the developer.")
            return  -- Abort login sequence, addon stays inert
        end
    end

    -- Slash commands FIRST (G4): diagnosability before functionality. A later
    -- step that throws no longer takes /ta errors, /ta health or /ta safemode
    -- down with it.
    SLASH_TOONAGE1 = "/ta"
    SLASH_TOONAGE2 = "/toonage"
    if not dbOK then
        -- Nothing below can run without a DB, and the normal /ta handler and
        -- ErrorLog both need one. This handler needs nothing: it says what
        -- failed and offers the one fix that doesn't need the addon running.
        SlashCmdList["TOONAGE"] = function(msg)
            msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
            if msg == "resetdb confirm" then
                TA:GuardSnapshot("/ta resetdb confirm")
                ToonAgeDB = nil
                print("|cFFFFD100[ToonAge]|r Saved settings cleared. Type /reload.")
                return
            elseif msg == "resetdb" then
                print("|cFFFFD100[ToonAge]|r This clears ALL ToonAge settings. Type /ta resetdb confirm")
                return
            end
            print("|cFFFF4444[ToonAge]|r Not running: saved settings failed to load twice ("
                .. tostring(TA._loginFailures and table.concat(TA._loginFailures, ", ")) .. ").")
            print("|cFFFF4444[ToonAge]|r /ta resetdb confirm clears them (all ToonAge settings), then /reload.")
        end
        SlashCmdList["TOONAGE"]("")
        return
    end
    SlashCmdList["TOONAGE"] = function(msg)
        TA:SlashCommand(msg)
    end
    -- _recovered is a quarantine, not an archive: it is written back to the
    -- SavedVariables file every logout while it exists, so it expires after
    -- RECOVERED_DAYS. /ta recovered shows it and can discard it sooner.
    local rec = ToonAgeDB and ToonAgeDB._recovered
    if type(rec) == "table" and rec.at and time and (time() - rec.at) > RECOVERED_DAYS * 86400 then
        ToonAgeDB._recovered = nil
    end
    if TA._resetIncident then
        local i = TA._resetIncident
        local WHY = {
            missing = "WoW did not load ToonAge's saved file (missing or unreadable)",
            emptied = "the saved data arrived empty",
            shrank  = "harvested records dropped by more than half",
        }
        TA:Raw(TA.LOG.WARN, ("|cFFFF4444[ToonAge]|r Saved data changed since last session: %s "
            .. "(%d -> %d harvest records%s). Details kept in ToonAgeGuard.incidents.")
            :format(WHY[i.kind] or i.kind, i.before.harvest or 0, i.after.harvest or 0,
                i.lastReset and (", after " .. tostring(i.lastReset.how)) or ""))
    end
    if self._dbRecovered then
        TA:Raw(TA.LOG.WARN, "|cFFFF4444[ToonAge]|r Saved settings were unreadable and were reset. "
            .. "The old data is kept in ToonAgeDB._recovered; /ta errors shows the cause.")
    end

    -- Snapshot this character's professions (+ class/level) on every login,
    -- so profession data can be gathered across the whole account just by
    -- logging into each character — read back from SavedVariables afterward.
    LoginStep("ProfessionSnapshot", function()
        self.charDB.professionSnapshot = {
            class       = TA.Utils.GetPlayerClass(),
            level       = TA.Utils.GetPlayerLevel(),
            professions = TA.Utils.GetProfessions(),
        }
    end)

    LoginStep("InitModules", function() self:InitModules() end)
    if TA._loginErrors and TA.ErrorLog and TA.ErrorLog.Log then
        for _, e in ipairs(TA._loginErrors) do
            pcall(TA.ErrorLog.Log, TA.ErrorLog, "Login: " .. e.step, e.err, "")
        end
    end
    LoginStep("InitUI",      function() self:InitUI() end)       -- Core/UI.lua
    LoginStep("InitMinimap", function() self:InitMinimap() end)  -- Core/MinimapButton.lua

    -- Apply the saved layout choice (Unified HUD vs Fragmented Windows).
    -- Called after both InitUI and InitMinimap so all frames exist, and after
    -- InitModules so Arrow.frame and QuestTracker.window are initialised.
    LoginStep("ApplyLayout", function() self:ApplyLayout() end)

    -- Install clickable hyperlink system for interactive /ta commands
    LoginStep("SlashLinks", function() self:InstallSlashLinkHook() end)

    -- Usage reporting, after modules are up so the session snapshot is real.
    -- Three gates inside decide whether anything is recorded at all.
    if TA.Analytics then
        LoginStep("Analytics", function()
            TA.Analytics:Init()
            TA.Analytics:RecordSession()
        end)
    end

    if TA._loginFailures then
        -- WARN, not INFO: a partial load is exactly what the quiet-login promise
        -- must not hide.
        TA:Raw(TA.LOG.WARN, "|cFFFF4444[ToonAge]|r Loaded with errors in: "
            .. table.concat(TA._loginFailures, ", ") .. ". /ta errors shows why.")
        return
    end

    -- INFO, not OUTPUT: nobody typed a command to get this. At the WARN default
    -- it stays quiet, which is the "healthy install is silent at login" promise
    -- made beside DB_DEFAULTS.logLevel. /ta verbose info brings it back.
    TA:Raw(TA.LOG.INFO, "|cFFFFD100ToonAge|r v" .. self.version
        .. " |cFF888780[" .. tostring(self.flavor or "unknown") .. "]|r loaded. Type "
        .. self:MakeSlashLink("help", "/ta help") .. " for clickable commands.")
end

-- ── Built-in command registry ─────────────────────────────────────────
-- Non-tab commands, declared once. `label` is what the help listing prints.
-- Tab commands are NOT here: they are generated from the active profile, so a
-- command for a tab this client does not ship cannot exist.
local SYSTEM_COMMANDS = {
    { name = "options",  label = "Settings"        },
    { name = "toggle",   label = "Module Toggles"  },
    { name = "layout",   label = "Toggle Layout"   },
    { name = "verbose",  label = "Chat Verbosity"  },
    { name = "health",   label = "Module Health"   },
    { name = "safemode", label = "Safe Mode"       },
    { name = "reset",    label = "Reset Data"      },
    { name = "debug",    label = "Debug Mode"      },
    { name = "help",     label = "This List"       },
}

-- /ta help groups. Keyed by command name; anything unlisted is "In game".
local GROUP_ORDER = {
    { id = "ingame",  title = "IN GAME" },
    { id = "options", title = "OPTIONS" },
    { id = "debug",   title = "DEBUG" },
    { id = "dev",     title = "DEV (data collection, API mapping)" },
}
local COMMAND_GROUP = {
    -- options
    options = "options", toggle = "options", layout = "options", verbose = "options",
    profile = "options", safemode = "options", reset = "options",
    -- debug
    health = "debug", errors = "debug", test = "debug", debug = "debug", state = "debug",
    -- dev
    report = "dev", catalog = "dev", probe = "dev", apiprobe = "dev",
    coordstats = "dev", coordexport = "dev", coordclear = "dev",
    -- help is its own line at the bottom of in-game
    help = "ingame",
}
-- Readable labels for commands whose name alone says little.
local COMMAND_LABELS = {
    since = "Since last session", refreshlog = "World refresh log", xp = "XP rate",
    gather = "Gathering", copy = "Copy chat", errors = "Error log", state = "State keys",
    report = "Full report", catalog = "Spell catalog scan", probe = "Client probes",
    apiprobe = "Missing APIs", coordstats = "Coord stats", coordexport = "Coord export",
    coordclear = "Coord clear", profile = "Profile export/import",
}
-- Second names for the same command: still work when typed, not listed twice.
local COMMAND_ALIAS = { copychat = true }

--- Tab ids that are real on THIS client, in profile order, minus `character`
--- (that one is the anchor tab -- /ta with no argument already opens it).
---
--- This exists because the tab commands used to be written out by hand in three
--- places -- the BUILTIN table below, GetAllCommandNames, and
--- PrintInteractiveHelp -- and all three carried the RETAIL list. On Forever,
--- whose tabs are character/gear/talents/spells/pets/pvp/harvest, `/ta rotation`
--- therefore existed, called OpenTab("rotation"), failed IsTabEnabled inside
--- SetTab, and silently landed on Character. Same for /ta prof, /ta weekly and
--- /ta guide. A command that quietly does the wrong thing is worse than one
--- that reports it does not exist.
function TA:TabCommandNames()
    local out = {}
    for _, tab in ipairs((self.ProfileTabs and self:ProfileTabs()) or {}) do
        if tab.id ~= "character"
           and (not self.IsTabAvailable or self:IsTabAvailable(tab.id)) then
            out[#out + 1] = tab.id
        end
    end
    return out
end

--- Every built-in command name that exists on this client.
function TA:BuiltinCommandNames()
    local names = { "open" }
    for _, id in ipairs(self:TabCommandNames()) do names[#names + 1] = id end
    for _, c in ipairs(SYSTEM_COMMANDS) do names[#names + 1] = c.name end
    return names
end

-- ── Slash command handler ─────────────────────────────────────────────
-- Dispatch is the body. TA:SlashCommand below wraps it in an output capture so
-- that everything it prints is routed per TA.SINK, rather than each of the ~300
-- print sites having to know where its output belongs.
local function Dispatch(self, msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""

    -- Split into command + args (e.g. "switchto 12345" → cmd="switchto", args="12345")
    local cmd, args = msg:match("^(%S+)%s*(.*)$")
    if not cmd then cmd = msg; args = "" end

    -- ── Empty input: toggle UI ────────────────────────────────────────
    if cmd == "" or cmd == "open" then
        self:ToggleUI()
        return
    end

    -- ── Built-in commands (exact match) ───────────────────────────────
    local BUILTIN = {
        options  = function() self:ToggleOptionsPanel() end,
        debug    = function()
            TA.debug = not TA.debug
            TA:Print(TA.LOG.OUTPUT, nil, "Debug mode: " .. (TA.debug and "ON" or "OFF"))
        end,
        reset    = function()
            -- Typed confirmation (2026-10-03): the Settings button already asks
            -- through a popup; the slash command wiped on a single typo-able word.
            if args ~= "confirm" then
                TA:Print(TA.LOG.OUTPUT, nil, "This clears ALL ToonAge settings and data for every "
                    .. "character. To do it, type |cFFFFD100/ta reset confirm|r")
                return
            end
            TA:GuardSnapshot("/ta reset confirm")
            -- Rebuild immediately. Clearing the global alone left TA.db and
            -- TA.charDB pointing at the orphaned table, so every write between
            -- the reset and the reload went into a table nothing would save.
            ToonAgeDB = nil
            self:InitDB()
            -- Cached display state was derived from the old DB. Dropping it
            -- forces every value to be recomputed rather than surviving a
            -- reset that was supposed to clear everything.
            if TA.State then TA.State:Wipe() end
            -- Modules that cached a sub-table of the old db still hold the
            -- orphan, which is why the reload is still required.
            TA:Print(TA.LOG.OUTPUT, nil, "Settings reset. Please reload UI (/reload).")
        end,
        recovered = function()
            local rec = ToonAgeDB and ToonAgeDB._recovered
            if type(rec) ~= "table" then
                TA:Print(TA.LOG.OUTPUT, nil, "No recovered settings are being kept.")
                return
            end
            if args == "discard" then
                ToonAgeDB._recovered = nil
                TA:Print(TA.LOG.OUTPUT, nil, "Recovered settings discarded.")
                return
            end
            local n = 0
            if type(rec.data) == "table" then for _ in pairs(rec.data) do n = n + 1 end end
            local days = rec.at and time and math.floor((time() - rec.at) / 86400) or "?"
            TA:Print(TA.LOG.OUTPUT, nil, ("Saved settings were reset %s day(s) ago because they "
                .. "could not be loaded. The old data (%s, %d top-level keys) is kept for %d days "
                .. "in WTF\\...\\SavedVariables\\ToonAge.lua under ToonAgeDB._recovered, "
                .. "for copying values back by hand. There is no automatic restore: loading it is "
                .. "what failed. |cFFFFD100/ta recovered discard|r drops it now.")
                :format(tostring(days), type(rec.data), n, RECOVERED_DAYS))
        end,
        layout   = function()
            self.db.useUnifiedUI = not self.db.useUnifiedUI
            self:ApplyLayout()
            local mode = self.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
            TA:Print(TA.LOG.OUTPUT, nil, "Layout: " .. mode)
        end,
        safemode = function()
            self.db.safeMode = not self.db.safeMode
            if self.db.safeMode then
                TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode |cFFFF9A1AON|r — next load initialises "
                      .. "core modules only. |cFF888780/reload to apply.|r")
            else
                TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode |cFF4AFF7AOFF|r. "
                      .. "|cFF888780/reload to load everything again.|r")
            end
        end,
        health   = function()
            -- NAMING, deliberately: the module list and the output window are
            -- two different things and must not share a name. They did once --
            -- both were called `report` -- and the second declaration shadowed
            -- the first, so the loop below walked the WINDOW instead of the
            -- module list. ipairs() over a window object yields nothing, so
            -- every count came out zero and not one module line printed. The
            -- report claimed "0 loaded · 0 off · 0 errored" on a client where
            -- every module had in fact loaded, which reads exactly like a total
            -- addon failure. A diagnostic that lies is worse than none.
            local entries = self:GetHealthReport()
            local loaded, off, errored = 0, 0, 0

            -- Every line is collected as well as printed, so "/ta health copy"
            -- can hand the whole report over in a selectable window. Chat holds
            -- ~50 visible lines and cannot be selected; this report is longer
            -- than that on any flavor that skips modules.
            local win = TA.BeginReport and TA:BeginReport("ToonAge Module Health")
            local lines = {}
            local function Say(text)
                lines[#lines + 1] = text
                if win then win:Add(text) else TA:Raw(TA.LOG.OUTPUT, text) end
            end

            Say("━━━ ToonAge Module Health ━━━")
            Say(("client: %s · profile: %s · build %s (interface %s)"):format(
                tostring(TA.flavor),
                tostring((TA.GetProfile and TA:GetProfile() or {}).label or "?"),
                tostring(select(1, GetBuildInfo())),
                tostring(select(4, GetBuildInfo()))))
            for _, entry in ipairs(entries) do
                local mod = self:GetRegisteredModule(entry.name)
                if entry.status == "loaded" then
                    loaded = loaded + 1
                elseif entry.status == "errored" then
                    errored = errored + 1
                    Say(("  ✗ %s — init failed: %s"):format(entry.name, tostring(entry.error)))
                else
                    off = off + 1
                    -- Distinguish the three ways a module ends up off. "Disabled"
                    -- alone is not actionable: turned off on purpose, skipped by
                    -- safe mode, and switched off for misbehaving want different
                    -- responses from you.
                    local why = "off by /ta toggle"
                    if mod and mod._autoDisabled then
                        why = ("auto-disabled after %d errors — /ta errors"):format(mod._errorCount or 0)
                    elseif mod and mod._safeSkipped then
                        why = "skipped by Safe Mode"
                    elseif mod and mod._profileSkipped then
                        -- Not part of this flavor's product (Core/Profile.lua).
                        -- Not a fault: e.g. a retail-only module on a TBC client.
                        why = mod._profileReason or "not in this flavor's profile"
                    end
                    Say(("  ○ %s — %s"):format(entry.name, why))
                end
            end

            Say(("  %d loaded · %d off · %d errored"):format(loaded, off, errored))

            -- Events this client does not define. Not a fault: a name that
            -- was valid three expansions ago, or one this flavor never had.
            -- Worth stating, because it is measured knowledge about the
            -- client and the alternative is rediscovering it as a dead
            -- module next time.
            local unknown = {}
            for name in pairs(self.unknownEvents or {}) do unknown[#unknown + 1] = name end
            if #unknown > 0 then
                table.sort(unknown)
                Say(("  %d event(s) this client does not define:"):format(#unknown))
                for _, name in ipairs(unknown) do
                    Say("    |cFF888780" .. name .. "|r")
                end
            end

            -- A TOC the client no longer recognizes does not error -- it is
            -- skipped, and another product's TOC loads in its place. Nothing
            -- else in the addon would ever mention it.
            if self.TocFlavorMismatch then
                local want, got = self:TocFlavorMismatch()
                if want then
                    Say(("  |cFFFF4444Wrong TOC loaded:|r this is a %s client, but the"
                        .. " %s TOC was read."):format(want, got))
                    Say("  |cFF888780The client no longer recognizes this flavor's TOC"
                        .. " suffix, so it fell back. Everything below is the wrong"
                        .. " product's module set.|r")
                end
            end

            -- Forever identified by its TOC, not its project id: the client
            -- reports an id Core/Environment.lua does not know. Everything
            -- still runs, but the id belongs in PROJECT_IDS so detection
            -- stops depending on the fallback.
            if self.flavorSource == "toc-fallback" then
                Say(("  |cFFFFD100Forever detected by TOC fallback:|r client reports"
                    .. " project id %s, interface %s. Add this id to"
                    .. " Core/Environment.lua PROJECT_IDS."):format(
                    tostring(self.projectId), tostring(self.interfaceCode)))
            end

            -- Outstanding item-data requests. Should sit at 0 most of the time;
            -- a number that climbs and never falls means GET_ITEM_INFO_RECEIVED
            -- is not resolving them and the 10s timeout is doing all the work.
            local pending = TA.Utils and TA.Utils.PendingItemCount and TA.Utils.PendingItemCount()
            if pending and pending > 0 then
                Say(("  %d item request(s) awaiting GET_ITEM_INFO_RECEIVED"):format(pending))
            end
            if self.db.safeMode then
                Say("  Safe Mode is ON. /ta safemode to turn it off.")
            end
            if TA.Analytics and TA.Analytics.StatusLine then
                Say("  " .. TA.Analytics:StatusLine())
            end
            Say("━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            -- "copy" opens the same report in a selectable window; without it,
            -- point at that, because this list scrolls out of chat instantly.
            if win then
                -- Always the window for this one: it is one line per module.
                win.threshold = 0
                win:Finish()
            elseif TA.ShowCopyWindow then
                TA:ShowCopyWindow("ToonAge Module Health", table.concat(lines, "\n"))
            end
        end,
        help     = function() self:PrintInteractiveHelp() end,
    }

    -- Tab commands, generated from the active flavor. These are PANEL sink:
    -- they open a tab and print nothing, because the data belongs on the tab.
    for _, id in ipairs(self:TabCommandNames()) do
        BUILTIN[id] = function() self:OpenTab(id) end
    end

    -- Check exact built-in match
    if BUILTIN[cmd] then
        BUILTIN[cmd]()
        return
    end

    -- ── Verbosity subcommand ──────────────────────────────────────────
    -- Everything printed here is LOG.OUTPUT: the user asked, so the answer must
    -- appear regardless of the level being set -- including when setting it to
    -- the quietest one.
    if cmd == "verbose" then
        local LEVELS = { error = TA.LOG.ERROR, warn = TA.LOG.WARN,
                         info  = TA.LOG.INFO,  debug = TA.LOG.DEBUG }
        local NAMES  = { [1] = "error", [2] = "warn", [3] = "info", [4] = "debug" }
        local want = LEVELS[args:lower()]
        if not want then
            TA:Printf(TA.LOG.OUTPUT, nil, "Chat verbosity is |cFF4AFF7A%s|r.",
                NAMES[TA.logLevel] or tostring(TA.logLevel))
            TA:Print(TA.LOG.OUTPUT, nil, "Usage: /ta verbose error|warn|info|debug")
            TA:Print(TA.LOG.OUTPUT, nil,
                "warn is the default: replies to your commands always show, background chatter does not.")
            return
        end
        self.db.logLevel = want
        TA.logLevel      = want
        TA:Printf(TA.LOG.OUTPUT, nil, "Chat verbosity set to |cFF4AFF7A%s|r.", NAMES[want])
        return
    end

    -- ── Toggle subcommand ─────────────────────────────────────────────
    if cmd == "toggle" then
        local modName = args ~= "" and args or nil
        if not modName then
            TA:Print(TA.LOG.OUTPUT, nil, "Toggleable modules:")
            for name, enabled in pairs(self.db.modules or {}) do
                local status = enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
                local link = self:MakeSlashLink("toggle " .. name:lower(), name .. " " .. status)
                TA:Raw(TA.LOG.OUTPUT, "  " .. link)
            end
            return
        end
        local matchedKey = nil
        for name in pairs(self.db.modules or {}) do
            if name:lower() == modName:lower() then matchedKey = name; break end
        end
        if not matchedKey then
            -- Fuzzy match for toggle
            matchedKey = self:FuzzyMatchModule(modName)
        end
        if not matchedKey then
            TA:Print(TA.LOG.OUTPUT, nil, "Unknown module: " .. modName)
            return
        end
        self.db.modules[matchedKey] = not self.db.modules[matchedKey]
        local status = self.db.modules[matchedKey] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        TA:Print(TA.LOG.OUTPUT, nil, "Module " .. matchedKey .. ": " .. status .. "  (reload to apply)")
        return
    end

    -- ── Module slash commands (exact match first) ─────────────────────
    -- Skips modules that are not running on this client, and says so rather
    -- than failing silently: typing a command that belongs to a module the
    -- flavor does not ship should explain itself, not throw from inside it.
    for name, mod in pairs(self.modules) do
        if mod.SlashCommands and mod.SlashCommands[cmd]
           and (mod._disabled or mod._profileSkipped) then
            TA:Print(TA.LOG.OUTPUT, nil, ("/ta %s belongs to %s, which is not running here (%s)."):format(
                cmd, name, mod._profileReason or "switched off"))
            return
        end
        if mod.SlashCommands and not mod._disabled and not mod._profileSkipped then
            local fn = mod.SlashCommands[cmd]
            if fn then fn(mod, args); return end
        end
    end

    -- ── Prefix / fuzzy match ──────────────────────────────────────────
    -- Try prefix matching: "mis" → "missed", "farm" → "farmhud", etc.
    local allCommands = self:GetAllCommandNames()
    local prefixMatches = {}
    local fuzzyMatches = {}

    for _, name in ipairs(allCommands) do
        if name:sub(1, #cmd) == cmd then
            table.insert(prefixMatches, name)
        elseif self:FuzzyScore(cmd, name) >= 0.6 then
            table.insert(fuzzyMatches, name)
        end
    end

    -- Single prefix match: execute it directly
    if #prefixMatches == 1 then
        local matchedCmd = prefixMatches[1]
        -- Check built-in
        if BUILTIN[matchedCmd] then
            BUILTIN[matchedCmd]()
            return
        end
        -- Check module commands
        for _, mod in pairs(self.modules) do
            if mod.SlashCommands and mod.SlashCommands[matchedCmd] then
                mod.SlashCommands[matchedCmd](mod, args)
                return
            end
        end
    end

    -- Multiple prefix matches or fuzzy matches: suggest them as clickable links
    if #prefixMatches > 0 or #fuzzyMatches > 0 then
        local suggestions = #prefixMatches > 0 and prefixMatches or fuzzyMatches
        TA:Print(TA.LOG.OUTPUT, nil, "Unknown command: |cFFFF8800" .. cmd .. "|r")
        TA:Raw(TA.LOG.OUTPUT, "  Did you mean:")
        for _, name in ipairs(suggestions) do
            TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink(name, "/ta " .. name))
        end
        return
    end

    -- ── Nothing matched: show interactive help ────────────────────────
    self:PrintInteractiveHelp()
end

--- Entry point for /ta and for any module calling TA:SlashCommand(...).
---
--- Everything the command prints is captured here and routed: two lines or
--- fewer go to chat as an acknowledgement, anything longer opens the selectable
--- copy window. See TA.SINK at the top of this file for why the routing lives
--- at the printer instead of at each call site.
function TA:SlashCommand(msg)
    local cmd = ((msg or ""):lower():match("^%s*(%S*)")) or ""
    local title = (cmd ~= "" and cmd ~= "open")
        and ("ToonAge -- /ta " .. cmd)
        or  "ToonAge"
    return self:WithSink(TA.SINK.REPORT, title, Dispatch, self, msg)
end

-- ── Clickable slash command hyperlink system ──────────────────────────────────
-- Creates clickable text in chat that executes /ta commands when clicked.
-- Format: |Htacommand:cmd|h[display text]|h

function TA:MakeSlashLink(cmd, displayText)
    displayText = displayText or ("/ta " .. cmd)
    return "|cFF4AE0FF|Htacommand:" .. cmd .. "|h[" .. displayText .. "]|h|r"
end

-- Hook SetItemRef to handle our tacommand: hyperlinks
do
    local hookInstalled = false
    function TA:InstallSlashLinkHook()
        if hookInstalled then return end
        hookInstalled = true
        hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
            -- SetItemRef fires for every hyperlink click of any kind, and can
            -- be called with a nil link in some cases — always guard first.
            if not link then return end
            local prefix, cmd = link:match("^(tacommand):(.+)$")
            if prefix ~= "tacommand" then return end
            -- Execute the command directly
            TA:SlashCommand(cmd)
        end)

        -- Tooltip on hover
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            local frame = _G["ChatFrame" .. i]
            if frame then
                frame:HookScript("OnHyperlinkEnter", function(_, link)
                    if not link then return end
                    local prefix, cmd = link:match("^(tacommand):(.+)$")
                    if prefix ~= "tacommand" then return end
                    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
                    GameTooltip:SetText("ToonAge Command", 1, 0.82, 0)
                    GameTooltip:AddLine("Click to run: /ta " .. cmd, 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                frame:HookScript("OnHyperlinkLeave", function(_, link)
                    if not link then return end
                    if link:match("^tacommand:") then GameTooltip:Hide() end
                end)
            end
        end
    end
end

-- ── Fuzzy matching utilities ──────────────────────────────────────────────────

--- Compute a simple similarity score between two strings (0-1).
--- Uses longest common subsequence ratio.
function TA:FuzzyScore(input, candidate)
    if not input or not candidate then return 0 end
    local lenA, lenB = #input, #candidate
    if lenA == 0 or lenB == 0 then return 0 end

    -- Simple character overlap ratio (faster than full LCS for short strings)
    local matches = 0
    local used = {}
    for i = 1, lenA do
        local c = input:sub(i, i)
        for j = 1, lenB do
            if not used[j] and candidate:sub(j, j) == c then
                matches = matches + 1
                used[j] = true
                break
            end
        end
    end
    return matches / math.max(lenA, lenB)
end

--- Find the closest module name for toggle fuzzy matching.
function TA:FuzzyMatchModule(input)
    local best, bestScore = nil, 0
    for name in pairs(self.db.modules or {}) do
        local score = self:FuzzyScore(input, name:lower())
        if score > bestScore and score >= 0.6 then
            bestScore = score
            best = name
        end
    end
    return best
end

--- Collect all registered command names (built-in + module).
function TA:GetAllCommandNames()
    local names = {}
    -- Built-ins, from the registry rather than a second hand-written list. The
    -- list that used to be here named rotation/prof/weekly/guide on every
    -- flavor, so the prefix matcher would happily complete `/ta rot` into a
    -- command that did not work.
    for _, n in ipairs(self:BuiltinCommandNames()) do names[#names+1] = n end

    -- Module commands
    for _, mod in pairs(self.modules) do
        if mod.SlashCommands then
            for k, v in pairs(mod.SlashCommands) do
                if type(v) == "function" then
                    names[#names+1] = k
                end
            end
        end
    end
    return names
end

-- ── Interactive help with clickable commands ──────────────────────────────────

function TA:PrintInteractiveHelp()
    -- Generated, never written out. The block that used to be here was the
    -- third hand-written copy of the command list, and the most misleading: it
    -- advertised `hud` (NavHud, since removed), `rotation`, `prof`, `weekly`,
    -- `guide`, plus a dozen tracker and HUD commands from modules this flavor
    -- does not load. Every line of it was a command that either did nothing or
    -- silently opened the Character tab.
    --
    -- TABS comes from the active profile. COMMANDS comes from the modules that
    -- actually loaded, so a module that is off, skipped by Safe Mode or absent
    -- from this flavor's profile contributes nothing.
    local R = TA:BeginReport("ToonAge -- Commands", 0)

    R:Add("|cFFFFD100ToonAge|r v" .. tostring(self.version or "?")
        .. "  |cFF888780" .. tostring((self.GetProfile and self:GetProfile() or {}).label or "?") .. "|r")
    -- This list opens in the copy window, which shows plain text: the [links]
    -- are labels there, not buttons. Every command also has a real button.
    R:Add("Type /ta <command>. Buttons: title bar (? Copy), Character, Spells, Harvest, and the gear drawer.")
    R:Add("")
    R:Add("  " .. self:MakeSlashLink("", "Open/Close ToonAge"))
    R:Add("")

    -- ── Tabs ──────────────────────────────────────────────────────────
    local tabIDs = self:TabCommandNames()
    if #tabIDs > 0 then
        R:Add("  |cFF888780TABS:|r")
        local labels = {}
        for _, tab in ipairs((self.ProfileTabs and self:ProfileTabs()) or {}) do
            labels[tab.id] = tab.label or tab.id
        end
        local row = {}
        for _, id in ipairs(tabIDs) do
            row[#row + 1] = self:MakeSlashLink(id, labels[id] or id)
            if #row == 3 then
                R:Add("    " .. table.concat(row, "  "))
                row = {}
            end
        end
        if #row > 0 then R:Add("    " .. table.concat(row, "  ")) end
        R:Add("")
    end

    -- ── Everything else, grouped by who it is for ─────────────────────
    -- In game: things a player uses while playing. Options: settings.
    -- Debug: when something looks wrong. Dev: data collection and API
    -- mapping for building ToonAge itself. A command not named in
    -- COMMAND_GROUP (a module added later, or another flavor's) lands in
    -- In game, so nothing ever drops off the list.
    local all = {}
    for name, mod in pairs(self.modules or {}) do
        if mod.SlashCommands and not mod._disabled and not mod._profileSkipped then
            for cmd, fn in pairs(mod.SlashCommands) do
                if type(fn) == "function" and not COMMAND_ALIAS[cmd] then
                    all[#all + 1] = { name = cmd, label = COMMAND_LABELS[cmd] or cmd }
                end
            end
        end
    end
    for _, c in ipairs(SYSTEM_COMMANDS) do all[#all + 1] = { name = c.name, label = c.label } end
    for _, c in ipairs(self.extraSystemCommands or {}) do all[#all + 1] = { name = c.name, label = c.label } end

    local groups = {}
    for _, c in ipairs(all) do
        local g = COMMAND_GROUP[c.name] or "ingame"
        groups[g] = groups[g] or {}
        table.insert(groups[g], c)
    end
    for _, g in ipairs(GROUP_ORDER) do
        local list = groups[g.id]
        if list and #list > 0 then
            table.sort(list, function(x, y) return x.label < y.label end)
            R:Add("  |cFF888780" .. g.title .. ":|r")
            local row = {}
            for _, c in ipairs(list) do
                row[#row + 1] = self:MakeSlashLink(c.name, c.label)
                if #row == 3 then
                    R:Add("    " .. table.concat(row, "  "))
                    row = {}
                end
            end
            if #row > 0 then R:Add("    " .. table.concat(row, "  ")) end
            R:Add("")
        end
    end

    R:Add("|cFF555555Partial commands work: /ta heal -> health.|r")
    R:Add("|cFF555555Long output opens in a window you can select and copy.|r")
    R:Finish()
end

function TA:ToggleUI()
    if self.UI then
        if self.UI:IsVisible() then
            self.UI:Hide()
        else
            self.UI:Show()
        end
    end
end

function TA:OpenTab(tabName)
    if self.UI then
        self.UI:Show()
        self.UI:SetTab(tabName)
    end
end


-- ── Addon Compartment (modern minimap button API) ─────────────────────
-- These global functions are referenced by the TOC AddonCompartmentFunc
-- fields. They provide a click-through minimap entry in the addon
-- compartment dropdown (the backpack-like icon near the minimap in 10.x+).

function ToonAge_OnAddonCompartmentClick(_, button)
    if button == "LeftButton" then
        ToonAge:ToggleUI()
    elseif button == "RightButton" then
        ToonAge:ToggleOptionsPanel()
    end
end

function ToonAge_OnAddonCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFFD100ToonAge|r v" .. (ToonAge.version or "1.0"))
    GameTooltip:AddLine("Left-click: Open panel", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Options", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function ToonAge_OnAddonCompartmentLeave(_, menuButtonFrame)
    GameTooltip:Hide()
end

-- ── Keybind functions (referenced by Bindings.xml) ────────────────────
-- These must be global for the keybind system to call them.

function ToonAge_ToggleNavHud()
    local NH = ToonAge:GetModule("NavHud")
    if NH then NH:Toggle() end
end

function ToonAge_ToggleArrow()
    local Arrow = ToonAge:GetModule("Arrow")
    if Arrow then Arrow:Toggle() end
end

function ToonAge_ToggleTracker()
    local QT = ToonAge:GetModule("QuestTracker")
    if QT then QT:ToggleWindow() end
end

function ToonAge_TogglePanel()
    ToonAge:ToggleUI()
end

-- Keybind display names (localization)
BINDING_HEADER_TOONAGE = "ToonAge"
BINDING_NAME_TOONAGE_TOGGLE_NAVHUD = "Toggle NavHud"

--- Bind a key to one of ToonAge's actions, saving it to the active binding set.
--- Only ever called from a button the player clicked: silently rebinding
--- someone's keyboard is the kind of thing that gets an addon uninstalled.
--- Returns true, or false plus a reason.
function TA:BindKey(key, action)
    if InCombatLockdown() then return false, "not while in combat" end
    if type(SetBinding) ~= "function" then return false, "binding API unavailable" end

    local existing = GetBindingAction and GetBindingAction(key)
    local ok = SetBinding(key, action)
    if not ok then return false, "the game refused that key" end
    if SaveBindings and GetCurrentBindingSet then
        SaveBindings(GetCurrentBindingSet())
    end
    return true, existing
end
BINDING_NAME_TOONAGE_TOGGLE_ARROW = "Toggle Arrow"
BINDING_NAME_TOONAGE_TOGGLE_TRACKER = "Toggle Tracker"
BINDING_NAME_TOONAGE_TOGGLE_PANEL = "Toggle Main Panel"
