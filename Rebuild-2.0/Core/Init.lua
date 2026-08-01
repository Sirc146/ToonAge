-- ToonAge 2.0 / Core/Init.lua
-- Addon object, event dispatch, SavedVariables, module system.
--
-- STATUS: 2.0 DRAFT. Not referenced by ToonAge.toc and not loaded by the game.
-- Executed by Tools/test_dispatch.py in embedded Lua 5.1. See
-- Rebuild-2.0/JOURNAL.md Entry 003 for the analysis this implements.
--
-- Scope of this rewrite, deliberately narrow (DIRECTIVE §3.1, eliminate scope
-- creep): the event dispatcher, plus defects F-1..F-7 from JOURNAL Entry 002.
-- Everything else in the 1.x file was judged an asset and is carried forward
-- with its comments intact -- CopyDefault/ApplyDefaults, the Safe Mode design,
-- and the log funnel. "Strip to the studs" was the wrong instruction for this
-- file; the studs were sound.

local ADDON_NAME = "ToonAge"
local ADDON_VERSION = "2.0.0-dev"

-- Create the global addon table
ToonAge = ToonAge or {}
local TA = ToonAge

TA.version = ADDON_VERSION

-- Module registry: modules register themselves here.
--   modules      name -> module table (unchanged from 1.x; GetModule reads it)
--   moduleOrder  array of names in registration order == TOC load order
--
-- moduleOrder is the fix for the nondeterminism half of the dispatch defect.
-- 1.x walked `pairs(self.modules)` for both init and dispatch, so module
-- initialisation order varied between logins and any implicit inter-module
-- dependency worked intermittently. An array alongside the map costs one
-- table and makes both orders reproducible.
TA.modules     = {}
TA.moduleOrder = {}

-- name -> { index, declared, events = {[event]=true} | nil }
-- `declared` distinguishes a module that opted out of every event (events = {})
-- from one that never declared at all (broadcast). Those must not look alike --
-- otherwise "is this module migrated yet?" is unanswerable.
local modMeta = {}

TA.eventFrame = CreateFrame("Frame", "ToonAgeEventFrame")

-- ══════════════════════════════════════════════════════════════════════
-- Chat output
-- ══════════════════════════════════════════════════════════════════════
-- One funnel for everything the addon says. Before this there were 309 direct
-- print() calls across 53 modules and no way to quiet any of them: a fresh
-- login printed a wall of text and the user had no recourse.
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

-- Applies until the DB exists. A working install says nothing at login, and
-- module load happens before the DB is read, so early output is quiet too.
local BOOT_LOG_LEVEL = TA.LOG.WARN

--- F-5: the single source of truth for verbosity.
---
--- 1.x kept `TA.logLevel` and `db.logLevel` in sync by hand, which is a
--- two-writer invariant maintained by discipline alone -- `/ta verbose` had to
--- remember to set both, and any other writer would desync them silently.
--- There is now one stored value (db.logLevel) and one reader. Before the DB
--- exists there is nothing to disagree with, so the boot constant applies.
---
--- Verified safe to remove the TA.logLevel field: a repo-wide grep for
--- `.logLevel` on 2026-07-31 found readers only inside Core/Init.lua itself.
--- No module reads it.
--- @return number
function TA:GetLogLevel()
    local db = rawget(self, "db")
    if db and db.logLevel then return db.logLevel end
    return BOOT_LOG_LEVEL
end

--- @param level number  a TA.LOG value
function TA:SetLogLevel(level)
    local db = rawget(self, "db")
    if db then db.logLevel = level end
end

-- module is optional:  TA:Print(TA.LOG.INFO, "Arrow", msg)  ->  [TA Arrow] msg
--                      TA:Print(TA.LOG.INFO, nil, msg)      ->  [TA] msg
function TA:Print(level, module, msg)
    level = level or TA.LOG.INFO
    if level > TA:GetLogLevel() then return end
    print(string.format("|c%s[%s]|r %s",
        LOG_COLOR[level] or LOG_COLOR[3],
        module and ("TA " .. module) or "TA",
        tostring(msg)))
end

-- No prefix, still filtered. For the indented continuation lines under a header
-- ("  Arrow ON", "  3 loaded · 1 off"), where a repeated [TA] on every row would
-- be noise. Same level rules; only the tag is dropped.
function TA:Raw(level, msg)
    level = level or TA.LOG.INFO
    if level > TA:GetLogLevel() then return end
    print(tostring(msg))
end

function TA:Printf(level, module, fmt, ...)
    level = level or TA.LOG.INFO
    if level > TA:GetLogLevel() then return end
    -- Format under pcall: a bad format string in a log line must never be the
    -- thing that breaks a module. Fall back to the raw format string.
    --
    -- 2.0 note -- this is now a Core *contract*, not a local nicety. Per
    -- STAGE0_POSTMORTEM §3, secrecy is contagious through string.format: a
    -- string built from a secret value is itself secret, and every string
    -- method on it raises. A presentation helper must be non-throwing by
    -- contract, because a cosmetic function must never be the reason a caller
    -- dies.
    local ok, out = pcall(string.format, fmt, ...)
    TA:Print(level, module, ok and out or fmt)
end

-- ══════════════════════════════════════════════════════════════════════
-- Default saved variables schema
-- ══════════════════════════════════════════════════════════════════════
-- Carried forward from 1.x unchanged. D-1 (adopt AceDB-3.0, or keep this
-- hand-rolled DB?) is still unanswered and gates any change here, so this
-- rewrite deliberately touches none of it.
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
        CutsceneSkip = true,
        AutoEquip          = true,
        AutoMount          = true,
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
    newCharBehavior = "wizard",

    -- Which preset "inherit" applies. Set by the wizard whenever a character
    -- completes it, so the choice you made last is the one your alts get.
    defaultPreset   = "auto",

    -- How much ToonAge says in chat. See TA.LOG above. WARN means a healthy
    -- install is silent at login and only speaks up when something is wrong;
    -- replies to commands you typed are LOG.OUTPUT and ignore this entirely.
    logLevel = 2,   -- TA.LOG.WARN

    -- Safe Mode boot flag. Persisted deliberately: the whole point is to
    -- survive a reload when the addon is too broken to reach its own UI.
    safeMode = false,

    -- UI layout toggle
    -- true  = Unified HUD, false = Fragmented windows
    useUnifiedUI = true,

    unifiedPosition = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 220 },

    oldUiPositions = {
        arrow  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 150  },
        guide  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 0    },
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- SavedVariables
-- ══════════════════════════════════════════════════════════════════════

--- Copies a value out of DB_DEFAULTS. Tables are copied recursively.
--- Assigning a default table straight into the DB shares the reference, which
--- makes DB_DEFAULTS itself user-writable: on a fresh install db.modules *is*
--- DB_DEFAULTS.modules, so `/ta toggle` edits the defaults. That survives until
--- reload, and `/ta reset` in the same session then "restores" the mutated
--- table rather than the shipped one.
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
--- Contract: fill in what is absent, never overwrite what the user set, and
--- never hand out a reference into the defaults table (see CopyDefault).
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
-- "set to empty" across ~35 presence checks.
--
-- If you add a per-character key: follow the `or {}` idiom at the point of use.

--- F-1, part 1 of 2 -- account-scope DB only. Runs at ADDON_LOADED.
---
--- 1.x deferred all DB work to PLAYER_ENTERING_WORLD, with the comment
--- "SavedVariables not available yet" at ADDON_LOADED. That comment was
--- factually wrong: SavedVariables *are* guaranteed loaded when ADDON_LOADED
--- fires for your own addon.
---
--- But the naive fix -- move InitDB wholesale to ADDON_LOADED -- is a trap, and
--- this split is why. InitDB also built charKey from UnitName("player") and
--- GetRealmName(), and player unit data is not reliably populated that early on
--- a cold login. With 1.x's `or "Unknown"` fallbacks that would not have
--- errored; it would have written a char["Unknown-Unknown"] bucket and lost the
--- character's settings silently. It would also very likely have looked correct
--- on /reload, which is how it would have been tested.
---
--- So: account data here, character data at PLAYER_LOGIN. The split is
--- structural, which means it stays correct regardless of the exact tick at
--- which UnitName starts answering.
function TA:InitAccountDB()
    -- ToonAgeDB is set by WoW from SavedVariables before ADDON_LOADED fires.
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB

    -- Backfill every missing key, at every depth, so sub-keys added in new
    -- versions land in existing SavedVariables without wiping user data.
    ApplyDefaults(db, DB_DEFAULTS)

    -- Migrate the old two-flag onboarding model onto newCharBehavior. Runs with
    -- the other defaults so it completes before any module Init reads the value.
    -- The old keys are dropped once translated; leaving them would recreate
    -- exactly the ambiguity this replaces.
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

    self.db = db
    -- No logLevel copy here. GetLogLevel reads db.logLevel directly (F-5), so
    -- raising verbosity from the saved value needs no assignment at all.
end

--- F-1, part 2 of 2 -- character-scope DB. Runs at PLAYER_LOGIN, by which
--- point unit data is available.
function TA:InitCharDB()
    local name   = UnitName("player")
    local server = GetRealmName()

    -- Loud, not silent. 1.x's `or "Unknown"` turned a missing identity into a
    -- valid-looking char["Unknown-Unknown"] bucket that the user would never
    -- see and could not diagnose -- their settings would simply be somebody
    -- else's. If this ever fires, it must be visible.
    if not name or name == "" or not server or server == "" then
        TA:Printf(TA.LOG.ERROR, nil,
            "Character identity unavailable at PLAYER_LOGIN (name=%s realm=%s). "
            .. "Per-character settings will not persist correctly this session.",
            tostring(name), tostring(server))
        name   = (name   ~= nil and name   ~= "") and name   or "Unknown"
        server = (server ~= nil and server ~= "") and server or "Unknown"
    end

    self.charKey = name .. "-" .. server
    self.db.char[self.charKey] = self.db.char[self.charKey] or {}
    self.charDB = self.db.char[self.charKey]
end

--- 1.x name, kept for the same fail-open reason as UpdateModules: the
--- ADDON_LOADED/PLAYER_LOGIN split is a Core concern, and a caller that
--- predates it should not have to know about it.
---
--- Verified 2026-07-31 by repo-wide grep: no *module* calls this. The only 1.x
--- callers were Core/Init.lua itself and Tools/test_onboarding.py, which drives
--- it directly. Kept anyway -- a compatibility method nobody calls costs one
--- line, and one that somebody calls fails at login.
function TA:InitDB()
    self:InitAccountDB()
    self:InitCharDB()
end

--- F-7: accessors. Modules must reach the DB through these and must never
--- cache a subtable of it.
---
--- 1.x acknowledged the bug honestly in-code: `/ta reset` replaced ToonAgeDB,
--- but every module holding `local myCfg = TA.db.something` kept pointing at
--- the orphaned table, so writes after a reset went somewhere nothing would
--- save. That is why reset still demands a reload. Going through an accessor
--- means the swap is invisible to callers and the reload requirement can
--- eventually be dropped.
function TA:GetDB()     return rawget(self, "db") end
function TA:GetCharDB() return rawget(self, "charDB") end

-- ══════════════════════════════════════════════════════════════════════
-- Module system
-- ══════════════════════════════════════════════════════════════════════

-- Events Core registers for its own lifecycle. Broadcast (undeclared) modules
-- never receive these, even though Core has the frame registered for them.
--
-- Without this rule, adding PLAYER_REGEN_ENABLED for the combat-deferral queue
-- would silently start delivering it to all 35 OnEvent handlers, none of which
-- have ever seen it. A dispatcher change must not hand modules new events as a
-- side effect. A module that genuinely wants one of these can still declare it
-- explicitly.
local CORE_ONLY_EVENTS = {
    ADDON_LOADED          = true,
    PLAYER_LOGIN          = true,
    PLAYER_ENTERING_WORLD = true,
    PLAYER_REGEN_ENABLED  = true,
}

-- event -> array of module names, in registration order. Built lazily, dropped
-- whenever the registry changes.
local dispatchCache = {}

local function InvalidateDispatch()
    dispatchCache = {}
end

-- Events the frame is already registered for, so re-registration is a no-op.
local registeredEvents = {}

--- RegisterEvent errors outright on an event name the client does not know.
--- With modules now free to declare arbitrary events, one module naming an
--- event removed in a 12.x patch would otherwise take Core down at load time --
--- the addon would not start at all. Contain it to that one module.
--- @return boolean registered
local function SafeRegisterEvent(event)
    if registeredEvents[event] then return true end
    local ok, err = pcall(TA.eventFrame.RegisterEvent, TA.eventFrame, event)
    if ok then
        registeredEvents[event] = true
        return true
    end
    TA:Printf(TA.LOG.ERROR, nil, "Unknown event '%s' rejected by the client: %s",
        tostring(event), tostring(err))
    return false
end

--- Registers a module.
---
--- @param name    string
--- @param module  table
--- @param events  string[]|nil  events this module wants. See below.
---
--- THE COMPATIBILITY RULE, and the single most important line in this file:
---
---   events == nil  ->  legacy broadcast. Receives every non-core event,
---                      exactly as 1.x did.
---   events == {}   ->  declared, subscribes to nothing.
---   events == {..} ->  declared, receives only those.
---
--- The dispatcher is fail-OPEN by default. A module that stops receiving events
--- raises no error and prints nothing -- it just quietly stops working. That is
--- the same silent-failure shape as the 12.1.0 C_Navigation.GetDestination
--- removal (guarded call, no error, always nil), and it is the reason all 55
--- existing 2-arg registrations must keep working untouched.
---
--- Migration is therefore per-module and opt-in, and the performance win
--- accrues incrementally rather than arriving as one big-bang breakage.
--- `/ta dispatch` reports who is still on the legacy path.
function TA:RegisterModule(name, module, events)
    if self.modules[name] then
        TA:Printf(TA.LOG.WARN, nil, "Module '%s' registered twice; keeping the first.", tostring(name))
        return
    end

    self.modules[name] = module
    self.moduleOrder[#self.moduleOrder + 1] = name

    local meta = { index = #self.moduleOrder, declared = false, events = nil }

    if events ~= nil then
        meta.declared = true
        meta.events   = {}
        for _, event in ipairs(events) do
            -- Register before recording, so a rejected event name does not
            -- leave a subscription that can never fire.
            if SafeRegisterEvent(event) then
                meta.events[event] = true
            end
        end
    end

    modMeta[name] = meta
    InvalidateDispatch()

    if TA.debug then
        TA:Printf(TA.LOG.DEBUG, nil, "Module registered: %s (%s)", name,
            meta.declared and "declared" or "legacy broadcast")
    end
end

function TA:GetModule(name)
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

--- Diagnostic: which modules are migrated and which are still broadcast.
--- Without this, "is module X migrated?" cannot be answered from in-game, and
--- an empty declaration is indistinguishable from no declaration.
--- @return table declared, table broadcast, table eventCounts
function TA:GetDispatchReport()
    local declared, broadcast, counts = {}, {}, {}
    for i = 1, #self.moduleOrder do
        local name = self.moduleOrder[i]
        local meta = modMeta[name]
        local mod  = self.modules[name]
        if mod and mod.OnEvent then
            if meta.declared then
                local list = {}
                for event in pairs(meta.events) do
                    list[#list + 1] = event
                    counts[event] = (counts[event] or 0) + 1
                end
                table.sort(list)
                declared[#declared + 1] = { name = name, events = list }
            else
                broadcast[#broadcast + 1] = name
            end
        end
    end
    return declared, broadcast, counts
end

-- ══════════════════════════════════════════════════════════════════════
-- Safe Mode
-- ══════════════════════════════════════════════════════════════════════
-- Two independent mechanisms with the same goal: keep one broken module from
-- taking the whole addon down with it.
--
-- 1. Automatic, per session. A module whose OnEvent throws repeatedly gets
--    switched off for the rest of the session. This is NOT persisted — a
--    transient failure should not silently disable something forever, so a
--    reload always gives every module another chance.
--
-- 2. Manual, persisted. `/ta safemode` sets a flag that survives reload and
--    boots with only the core set initialised.

local ERROR_DISABLE_THRESHOLD = 10
local ERROR_PRINT_LIMIT = 3

local SAFE_MODE_KEEP = {
    ErrorLog = true,
    Character = true, Gear = true, Talents = true, Rotation = true,
    QuestTracker = true, Arrow = true, GuideParser = true,
}

function TA:InitModules()
    local safe = self.db and self.db.safeMode

    if safe then
        TA:Print(TA.LOG.WARN, nil, "SAFE MODE — only core modules loaded. "
              .. "|cFF888780/ta safemode to turn off, then /reload.|r")
    end

    -- Ordered walk, not pairs(). Module init order is now TOC load order on
    -- every login instead of whatever hash order the run happened to produce.
    for i = 1, #self.moduleOrder do
        local name = self.moduleOrder[i]
        local mod  = self.modules[name]

        -- Reset per-session failure state. Without this a module auto-disabled
        -- last session would look disabled on a fresh login even though its
        -- counter is gone.
        mod._errorCount = 0
        mod._autoDisabled = false

        local userDisabled = self.db and self.db.modules and self.db.modules[name] == false
        local safeSkipped  = safe and not SAFE_MODE_KEEP[name]

        if userDisabled or safeSkipped then
            mod._disabled = true
            mod._safeSkipped = safeSkipped or nil
        else
            mod._disabled = false
            mod._safeSkipped = nil
            if mod.Init then
                local ok, err = pcall(mod.Init, mod)
                if not ok then
                    mod._initError = tostring(err)
                    TA:Printf(TA.LOG.ERROR, nil, "Error initialising module %s: %s", name, tostring(err))
                    if TA.ErrorLog then TA.ErrorLog:Log(name .. " Init", tostring(err), "") end
                end
            end
        end
    end

    -- A module may attach OnEvent during its own Init, so any list built before
    -- now could be missing it. Cheap insurance -- the cache refills on the next
    -- event either way.
    InvalidateDispatch()
end

-- ══════════════════════════════════════════════════════════════════════
-- Event dispatch
-- ══════════════════════════════════════════════════════════════════════
-- THE defect this rewrite exists for.
--
-- 1.x dispatched by broadcast: every persistent event walked all 55 registered
-- modules and pcall'd OnEvent on each of the 35 that define one, whether or not
-- that module cared. BAG_UPDATE fires roughly 5x per loot (once per bag), so a
-- single loot cost ~175 pcall invocations, each allocating, to service the
-- handful of modules that actually want BAG_UPDATE. That is the GC-spike source
-- DIRECTIVE §3.2 names.
--
-- 2.0 builds event -> subscriber lists and touches only subscribers, in
-- deterministic registration order. Modules keep the exact OnEvent signature
-- they have today, so this does not cascade into the 35 handlers.

--- Builds the ordered dispatch list for one event.
--- Walking moduleOrder means the result is already in registration order --
--- no sort, and no dependence on hash iteration.
local function BuildDispatchList(event)
    local coreOnly = CORE_ONLY_EVENTS[event]
    local list = {}
    for i = 1, #TA.moduleOrder do
        local name = TA.moduleOrder[i]
        local mod  = TA.modules[name]
        local meta = modMeta[name]
        if mod and mod.OnEvent and meta then
            local wants
            if meta.declared then
                wants = meta.events[event] and true or false
            else
                -- Undeclared == legacy broadcast, but never for core lifecycle
                -- events it has never received before.
                wants = not coreOnly
            end
            if wants then list[#list + 1] = name end
        end
    end
    dispatchCache[event] = list
    return list
end

--- Records one module's OnEvent failure. Split out of the dispatch loop so the
--- hot path stays small and allocation-free.
local function HandleModuleError(name, mod, err, event)
    mod._errorCount = (mod._errorCount or 0) + 1

    if mod._errorCount <= ERROR_PRINT_LIMIT then
        TA:Printf(TA.LOG.ERROR, nil, "Module %s OnEvent error: %s", name, tostring(err))
    elseif mod._errorCount == ERROR_PRINT_LIMIT + 1 then
        TA:Printf(TA.LOG.WARN, nil, "%s keeps failing — muting further errors. "
              .. "|cFF888780/ta errors to read them.|r", name)
    end

    -- Pass the event as the stack field. Which event triggered a failure is
    -- usually the fastest way to find it.
    if TA.ErrorLog then TA.ErrorLog:Log(name .. " OnEvent", tostring(err), event or "") end

    if mod._errorCount >= ERROR_DISABLE_THRESHOLD then
        mod._disabled = true
        mod._autoDisabled = true
        local msg = name .. " disabled after " .. mod._errorCount .. " errors this session"
        TA:Print(TA.LOG.WARN, "Safe Mode", msg
              .. ". |cFF888780Reload to re-enable. /ta health for status.|r")
        if TA.ErrorLog then TA.ErrorLog:Log("SafeMode", msg, event or "") end
    end
end

--- Dispatches one event to its subscribers.
---
--- Two properties this loop must preserve, both easy to break:
---
--- 1. Varargs pass through untouched. Handlers read positionally
---    (GET_ITEM_INFO_RECEIVED takes itemID, success), so `...` must never be
---    packed into a table on the way.
--- 2. The `_disabled` check stays *inside* the loop rather than being resolved
---    when the list is built. Auto-disable fires mid-dispatch -- the tenth
---    error flips _disabled while this very loop is running. Reading the flag
---    per iteration means a module disabling itself cannot affect the siblings
---    queued behind it, and the list is never mutated during iteration.
function TA:Dispatch(event, ...)
    local list = dispatchCache[event] or BuildDispatchList(event)
    for i = 1, #list do
        local name = list[i]
        local mod  = self.modules[name]
        if mod and mod.OnEvent and not mod._disabled then
            local ok, err = pcall(mod.OnEvent, mod, event, ...)
            if not ok then
                HandleModuleError(name, mod, err, event)
            end
        end
    end
end

--- 1.x name, kept so the 35 existing handlers and any caller that reaches for
--- it keep working. Dispatch is the name that describes what it does.
function TA:UpdateModules(event, ...)
    return self:Dispatch(event, ...)
end

-- ══════════════════════════════════════════════════════════════════════
-- Combat guard (F-4)
-- ══════════════════════════════════════════════════════════════════════
-- 1.x's Init.lua contained zero InCombatLockdown() checks -- verified, the
-- count was 0. `/ta layout` calls ApplyLayout(), which re-parents and moves
-- frames, and it is reachable from a SetItemRef hyperlink click, i.e. from a
-- tainted execution path. DIRECTIVE §3.3 requires the guard.
--
-- Deferring rather than refusing: the user asked for something, and "not now"
-- with no follow-through is a worse answer than doing it a moment later.

local pendingCombatActions = {}

--- Runs fn now, or queues it until combat ends.
--- @return boolean ranNow
function TA:RunWhenSafe(label, fn)
    if not InCombatLockdown or not InCombatLockdown() then
        fn()
        return true
    end

    pendingCombatActions[#pendingCombatActions + 1] = { label = label, fn = fn }
    SafeRegisterEvent("PLAYER_REGEN_ENABLED")
    TA:Printf(TA.LOG.OUTPUT, nil,
        "In combat — |cFFFF9A1A%s|r will run when you leave combat.", label)
    return false
end

function TA:FlushCombatActions()
    if #pendingCombatActions == 0 then return end

    -- Swap the queue out first. An action that queues another action must land
    -- in a fresh table rather than extending the one being iterated.
    local queued = pendingCombatActions
    pendingCombatActions = {}

    for i = 1, #queued do
        local action = queued[i]
        local ok, err = pcall(action.fn)
        if not ok then
            TA:Printf(TA.LOG.ERROR, nil, "Deferred action '%s' failed: %s",
                action.label, tostring(err))
            if TA.ErrorLog then TA.ErrorLog:Log("CombatDefer", tostring(err), action.label) end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- Event registration
-- ══════════════════════════════════════════════════════════════════════
-- These stay registered while any module is still on the legacy broadcast
-- path -- an undeclared module expects all of them. As modules migrate, this
-- list stops being the bottleneck it is in 1.x: a module can declare an event
-- that is not here and simply get it, instead of needing this array edited.
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
    "QUEST_ACCEPTED",              -- needed by DevHelpers recorder & QuestTracker
}

SafeRegisterEvent("ADDON_LOADED")
SafeRegisterEvent("PLAYER_LOGIN")
SafeRegisterEvent("PLAYER_ENTERING_WORLD")

for _, event in ipairs(PERSISTENT_EVENTS) do
    SafeRegisterEvent(event)
end

TA._bootPhase = "none"

TA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...

    if event == "ADDON_LOADED" then
        -- Only act on our own addon load; unregister immediately.
        if arg1 == ADDON_NAME then
            self:UnregisterEvent("ADDON_LOADED")
            registeredEvents["ADDON_LOADED"] = nil
            -- SavedVariables ARE available here for our own addon. Account
            -- data only -- see InitAccountDB for why character data is not.
            TA:InitAccountDB()
            TA._bootPhase = "db"
            -- Delivered only to modules that explicitly declared it.
            TA:Dispatch(event, ...)
        end

    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        registeredEvents["PLAYER_LOGIN"] = nil
        -- Character identity only. Unit data is available here; world data is
        -- not, which is why module Init does NOT run yet.
        TA:InitCharDB()
        TA._bootPhase = "login"
        TA:Dispatch(event, ...)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Fires again on every zone and instance change, so this must be
        -- idempotent rather than one-shot.
        if TA._bootPhase ~= "world" then
            TA._bootPhase = "world"
            TA:OnLogin()
        end
        TA:Dispatch(event, ...)

    elseif event == "PLAYER_REGEN_ENABLED" then
        TA:FlushCombatActions()
        TA:Dispatch(event, ...)

    else
        -- Invalidate cached display state BEFORE modules run, so a module
        -- handling this event recomputes from a cleared cache instead of
        -- reading back its own stale value from the previous tick. Ordering
        -- here is the whole point.
        if TA.State then TA.State:Invalidate(event) end

        -- Resolve pending item-data requests after invalidation but before
        -- modules run, so a module handling this event sees the item already
        -- populated rather than racing the callback that fills it in.
        if event == "GET_ITEM_INFO_RECEIVED" and TA.Utils and TA.Utils.OnItemInfoReceived then
            local itemID, success = ...
            TA.Utils.OnItemInfoReceived(itemID, success)
        end

        TA:Dispatch(event, ...)
        TA:QueueUIRefresh(event)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- Coalesced UI refresh
-- ══════════════════════════════════════════════════════════════════════
-- UI:Refresh() tears down and rebuilds the whole active tab. Some events are
-- high-frequency: BAG_UPDATE fires once per bag per change, so looting a single
-- stack can fire it five or more times in one frame. Per .rules.md ("Debounce
-- high-frequency events"), collect events arriving within a short window and
-- rebuild once.
local UI_REFRESH_DELAY = 0.15

TA._pendingUIEvents = nil
TA._uiRefreshQueued = false

function TA:QueueUIRefresh(event)
    -- Nothing to rebuild if the panel is closed. Drop the event rather than
    -- queueing work that would be thrown away on flush.
    if not (self.UI and self.UI:IsVisible()) then return end

    self._pendingUIEvents = self._pendingUIEvents or {}
    self._pendingUIEvents[event] = true

    if self._uiRefreshQueued then return end
    self._uiRefreshQueued = true

    C_Timer.After(UI_REFRESH_DELAY, function()
        local events = TA._pendingUIEvents
        TA._pendingUIEvents = nil
        TA._uiRefreshQueued = false

        -- The panel may have been closed during the delay.
        if not (TA.UI and TA.UI:IsVisible()) then return end

        local ok, err = pcall(TA.UI.Refresh, TA.UI, events)
        if not ok then
            TA:Printf(TA.LOG.ERROR, nil, "UI refresh error: %s", tostring(err))
            if TA.ErrorLog then TA.ErrorLog:Log("UI Refresh", tostring(err), "") end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- Login sequence
-- ══════════════════════════════════════════════════════════════════════

--- First PLAYER_ENTERING_WORLD -- the same point 1.x ran this, deliberately.
---
--- An earlier draft of 2.0 moved all of this to PLAYER_LOGIN. That was scope
--- creep with a silent failure mode, and it is corrected here. F-1 asked only
--- that the *database* move earlier; Entry 002's own wording was "move InitDB
--- to ADDON_LOADED; keep UI init on PLAYER_ENTERING_WORLD."
---
--- Moving module Init earlier changes the world-data assumptions of all 55
--- modules at once. An audit of every module Init body found two that touch
--- world-dependent APIs, and one is a real regression:
--- `TravelRouter:Init` reads `C_Map.GetBestMapForUnit("player")` to record
--- `hearthZoneID`, guarded by `if mapID then`. At PLAYER_LOGIN that guard would
--- simply fail every login -- no error, and the field would never be recorded.
--- Exactly the silent shape this rewrite exists to remove.
---
--- So: DB timing is fixed (the actual defect), module and UI timing is
--- preserved bit-for-bit from 1.x (not the defect).
function TA:OnLogin()
    -- Snapshot this character's professions (+ class/level), so profession data
    -- can be gathered across the whole account just by logging into each
    -- character -- read back from SavedVariables afterward. Verified
    -- 2026-07-31 by grep: nothing in the addon reads this field. If a reader is
    -- ever added, it must not read it during module Init.
    local charDB = self:GetCharDB()
    if charDB then
        charDB.professionSnapshot = {
            class       = TA.Utils.GetPlayerClass(),
            level       = TA.Utils.GetPlayerLevel(),
            professions = TA.Utils.GetProfessions(),
        }
    end

    self:InitModules()
    self:InitUI()       -- defined in Core/UI.lua
    self:InitMinimap()  -- defined in Core/MinimapButton.lua

    -- After InitUI and InitMinimap so all frames exist, and after InitModules
    -- so Arrow.frame and QuestTracker.window are initialised.
    self:ApplyLayout()

    SLASH_TOONAGE1 = "/ta"
    SLASH_TOONAGE2 = "/toonage"
    SlashCmdList["TOONAGE"] = function(msg)
        TA:SlashCommand(msg)
    end

    self:InstallSlashLinkHook()

    -- INFO, not OUTPUT: nobody typed a command to get this. At the WARN default
    -- it stays quiet, which is the "healthy install is silent at login"
    -- promise. /ta verbose info brings it back.
    TA:Raw(TA.LOG.INFO, "|cFFFFD100ToonAge|r v" .. self.version .. " loaded. Type "
        .. self:MakeSlashLink("help", "/ta help") .. " for clickable commands.")
end

--- Retained as an alias: OnLogin is the 1.x name and runs at the 1.x point,
--- but "OnLogin" firing on PLAYER_ENTERING_WORLD is confusing enough to be
--- worth a second, accurate name.
function TA:OnFirstWorldEnter()
    return self:OnLogin()
end

-- ══════════════════════════════════════════════════════════════════════
-- Slash commands
-- ══════════════════════════════════════════════════════════════════════
-- F-3: this table is file-scope and built exactly once.
--
-- 1.x declared it *inside* SlashCommand, so the table and all ~16 closures were
-- reallocated on every single /ta invocation -- a file-scope constant given
-- function-local lifetime.
--
-- F-2: it is also now the only list of built-in command names. 1.x kept a
-- second, hardcoded array in GetAllCommandNames, and the two had already
-- drifted: `verbose` was implemented but missing from the array, so `/ta verb`
-- never prefix-matched. Two lists that must agree will not stay agreeing.
-- Commands that take arguments (toggle, verbose) are entries here like any
-- other, which is what makes one list sufficient.
--
--   combat = true  ->  runs through RunWhenSafe: deferred if in combat.
local BUILTIN

--- @param args string
local function Cmd_Verbose(args)
    -- Everything printed here is LOG.OUTPUT: the user asked, so the answer must
    -- appear regardless of the level being set -- including when setting it to
    -- the quietest one.
    local LEVELS = { error = TA.LOG.ERROR, warn = TA.LOG.WARN,
                     info  = TA.LOG.INFO,  debug = TA.LOG.DEBUG }
    local NAMES  = { [1] = "error", [2] = "warn", [3] = "info", [4] = "debug" }
    local want = LEVELS[args:lower()]
    if not want then
        local current = TA:GetLogLevel()
        TA:Printf(TA.LOG.OUTPUT, nil, "Chat verbosity is |cFF4AFF7A%s|r.",
            NAMES[current] or tostring(current))
        TA:Print(TA.LOG.OUTPUT, nil, "Usage: /ta verbose error|warn|info|debug")
        TA:Print(TA.LOG.OUTPUT, nil,
            "warn is the default: replies to your commands always show, background chatter does not.")
        return
    end
    TA:SetLogLevel(want)
    TA:Printf(TA.LOG.OUTPUT, nil, "Chat verbosity set to |cFF4AFF7A%s|r.", NAMES[want])
end

local function Cmd_Toggle(args)
    local db = TA:GetDB()
    local modName = args ~= "" and args or nil

    if not modName then
        TA:Print(TA.LOG.OUTPUT, nil, "Toggleable modules:")
        for name, enabled in pairs(db.modules or {}) do
            local status = enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
            local link = TA:MakeSlashLink("toggle " .. name:lower(), name .. " " .. status)
            TA:Raw(TA.LOG.OUTPUT, "  " .. link)
        end
        return
    end

    local matchedKey = nil
    for name in pairs(db.modules or {}) do
        if name:lower() == modName:lower() then matchedKey = name; break end
    end
    if not matchedKey then
        matchedKey = TA:FuzzyMatchModule(modName)
    end
    if not matchedKey then
        TA:Print(TA.LOG.OUTPUT, nil, "Unknown module: " .. modName)
        return
    end

    db.modules[matchedKey] = not db.modules[matchedKey]
    local status = db.modules[matchedKey] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
    TA:Print(TA.LOG.OUTPUT, nil, "Module " .. matchedKey .. ": " .. status .. "  (reload to apply)")
end

local function Cmd_Health()
    local report = TA:GetHealthReport()
    local loaded, off, errored = 0, 0, 0

    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Module Health ━━━|r")
    for _, entry in ipairs(report) do
        local mod = TA.modules[entry.name]
        if entry.status == "loaded" then
            loaded = loaded + 1
        elseif entry.status == "errored" then
            errored = errored + 1
            TA:Raw(TA.LOG.OUTPUT, ("  |cFFFF4444✗ %s|r — init failed: %s"):format(entry.name, tostring(entry.error)))
        else
            off = off + 1
            -- Distinguish the three ways a module ends up off. "Disabled"
            -- alone is not actionable: turned off on purpose, skipped by safe
            -- mode, and switched off for misbehaving want different responses.
            local why = "off by /ta toggle"
            if mod and mod._autoDisabled then
                why = ("auto-disabled after %d errors — /ta errors"):format(mod._errorCount or 0)
            elseif mod and mod._safeSkipped then
                why = "skipped by Safe Mode"
            end
            TA:Raw(TA.LOG.OUTPUT, ("  |cFF888780○ %s — %s|r"):format(entry.name, why))
        end
    end

    TA:Raw(TA.LOG.OUTPUT, ("  |cFF4AFF7A%d loaded|r · |cFF888780%d off|r · |cFFFF4444%d errored|r")
          :format(loaded, off, errored))

    local pending = TA.Utils and TA.Utils.PendingItemCount and TA.Utils.PendingItemCount()
    if pending and pending > 0 then
        TA:Raw(TA.LOG.OUTPUT, ("  |cFF888780%d item request(s) awaiting GET_ITEM_INFO_RECEIVED|r"):format(pending))
    end
    local db = TA:GetDB()
    if db and db.safeMode then
        TA:Raw(TA.LOG.OUTPUT, "  |cFFFF9A1ASafe Mode is ON.|r |cFF888780/ta safemode to turn it off.|r")
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
end

--- The migration ledger. Answers "did module X actually move off the broadcast
--- path?" -- which is otherwise unanswerable from in-game, and is the only way
--- to tell an explicit empty declaration from no declaration at all.
local function Cmd_Dispatch()
    local declared, broadcast, counts = TA:GetDispatchReport()

    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Event Dispatch ━━━|r")
    TA:Raw(TA.LOG.OUTPUT, ("  |cFF4AFF7A%d declared|r · |cFFFF9A1A%d legacy broadcast|r")
          :format(#declared, #broadcast))

    for _, entry in ipairs(declared) do
        local list = #entry.events > 0 and table.concat(entry.events, ", ") or "|cFF888780(none)|r"
        TA:Raw(TA.LOG.OUTPUT, ("  |cFF4AFF7A✓ %s|r — %s"):format(entry.name, list))
    end

    if #broadcast > 0 then
        TA:Raw(TA.LOG.OUTPUT, "  |cFF888780Still receiving every event:|r")
        for _, name in ipairs(broadcast) do
            TA:Raw(TA.LOG.OUTPUT, ("    |cFFFF9A1A○ %s|r"):format(name))
        end
    end

    local hot = {}
    for event, n in pairs(counts) do hot[#hot + 1] = { event = event, n = n } end
    table.sort(hot, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        return a.event < b.event
    end)
    if #hot > 0 then
        TA:Raw(TA.LOG.OUTPUT, "  |cFF888780Subscribers per declared event:|r")
        for i = 1, math.min(#hot, 8) do
            TA:Raw(TA.LOG.OUTPUT, ("    %s |cFF888780x%d|r"):format(hot[i].event, hot[i].n))
        end
    end
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
end

BUILTIN = {
    open     = { fn = function() TA:ToggleUI() end },
    gear     = { fn = function() TA:OpenTab("gear") end },
    talents  = { fn = function() TA:OpenTab("talents") end },
    rotation = { fn = function() TA:OpenTab("rotation") end },
    prof     = { fn = function() TA:OpenTab("professions") end },
    pets     = { fn = function() TA:OpenTab("pets") end },
    weekly   = { fn = function() TA:OpenTab("weekly") end },
    guide    = { fn = function() TA:OpenTab("guide") end },
    options  = { fn = function() TA:ToggleOptionsPanel() end },
    help     = { fn = function() TA:PrintInteractiveHelp() end },
    health   = { fn = Cmd_Health },
    dispatch = { fn = Cmd_Dispatch },
    verbose  = { fn = Cmd_Verbose },
    toggle   = { fn = Cmd_Toggle },

    debug    = { fn = function()
        TA.debug = not TA.debug
        TA:Print(TA.LOG.OUTPUT, nil, "Debug mode: " .. (TA.debug and "ON" or "OFF"))
    end },

    reset    = { fn = function()
        -- Rebuild immediately. Clearing the global alone left TA.db and
        -- TA.charDB pointing at the orphaned table, so every write between the
        -- reset and the reload went into a table nothing would save.
        ToonAgeDB = nil
        TA:InitAccountDB()
        TA:InitCharDB()
        if TA.State then TA.State:Wipe() end
        -- Modules that cached a sub-table of the old db still hold the orphan,
        -- which is why the reload is still required. F-7's accessors exist to
        -- retire this line once modules stop caching subtables.
        TA:Print(TA.LOG.OUTPUT, nil, "Settings reset. Please reload UI (/reload).")
    end },

    -- Combat-guarded: ApplyLayout re-parents and moves frames, and is reachable
    -- from a SetItemRef hyperlink click -- a tainted path.
    layout   = { combat = true, fn = function()
        local db = TA:GetDB()
        db.useUnifiedUI = not db.useUnifiedUI
        TA:ApplyLayout()
        local mode = db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
        TA:Print(TA.LOG.OUTPUT, nil, "Layout: " .. mode)
    end },

    safemode = { fn = function()
        local db = TA:GetDB()
        db.safeMode = not db.safeMode
        if db.safeMode then
            TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode |cFFFF9A1AON|r — next load initialises "
                  .. "core modules only. |cFF888780/reload to apply.|r")
        else
            TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode |cFF4AFF7AOFF|r. "
                  .. "|cFF888780/reload to load everything again.|r")
        end
    end },
}

--- Runs a built-in, honouring its combat guard.
local function RunBuiltin(name, args)
    local entry = BUILTIN[name]
    if not entry then return false end
    if entry.combat then
        TA:RunWhenSafe("/ta " .. name, function() entry.fn(args or "") end)
    else
        entry.fn(args or "")
    end
    return true
end

function TA:SlashCommand(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""

    -- Split into command + args (e.g. "switchto 12345" → cmd="switchto", args="12345")
    local cmd, args = msg:match("^(%S+)%s*(.*)$")
    if not cmd then cmd = msg; args = "" end

    -- Empty input: toggle UI
    if cmd == "" then
        self:ToggleUI()
        return
    end

    -- Built-in commands (exact match)
    if RunBuiltin(cmd, args) then return end

    -- Module slash commands (exact match)
    for _, name in ipairs(self.moduleOrder) do
        local mod = self.modules[name]
        if mod and mod.SlashCommands then
            local fn = mod.SlashCommands[cmd]
            if fn then fn(mod, args); return end
        end
    end

    -- Prefix / fuzzy match: "mis" → "missed", "farm" → "farmhud"
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
        if RunBuiltin(matchedCmd, args) then return end
        for _, name in ipairs(self.moduleOrder) do
            local mod = self.modules[name]
            if mod and mod.SlashCommands and mod.SlashCommands[matchedCmd] then
                mod.SlashCommands[matchedCmd](mod, args)
                return
            end
        end
    end

    -- Multiple prefix or fuzzy matches: suggest them as clickable links
    if #prefixMatches > 0 or #fuzzyMatches > 0 then
        local suggestions = #prefixMatches > 0 and prefixMatches or fuzzyMatches
        TA:Print(TA.LOG.OUTPUT, nil, "Unknown command: |cFFFF8800" .. cmd .. "|r")
        TA:Raw(TA.LOG.OUTPUT, "  Did you mean:")
        for _, name in ipairs(suggestions) do
            TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink(name, "/ta " .. name))
        end
        return
    end

    self:PrintInteractiveHelp()
end

--- Collect all registered command names (built-in + module).
--- Built-ins are derived from BUILTIN itself (F-2) -- there is no second list
--- to drift out of sync with it.
function TA:GetAllCommandNames()
    local names = {}
    for name in pairs(BUILTIN) do names[#names + 1] = name end
    -- Sorted so suggestion output is stable between runs; pairs() order is not.
    table.sort(names)

    for _, modName in ipairs(self.moduleOrder) do
        local mod = self.modules[modName]
        if mod and mod.SlashCommands then
            for k, v in pairs(mod.SlashCommands) do
                if type(v) == "function" then
                    names[#names + 1] = k
                end
            end
        end
    end
    return names
end

-- ══════════════════════════════════════════════════════════════════════
-- Clickable slash command hyperlinks
-- ══════════════════════════════════════════════════════════════════════
-- Format: |Htacommand:cmd|h[display text]|h

function TA:MakeSlashLink(cmd, displayText)
    displayText = displayText or ("/ta " .. cmd)
    return "|cFF4AE0FF|Htacommand:" .. cmd .. "|h[" .. displayText .. "]|h|r"
end

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
            TA:SlashCommand(cmd)
        end)

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

-- ══════════════════════════════════════════════════════════════════════
-- Fuzzy matching
-- ══════════════════════════════════════════════════════════════════════

-- F-6: bound the work. FuzzyScore is O(n*m) and allocates a `used` table per
-- candidate, and SlashCommand calls it once per registered command name on
-- every unmatched input. Neither the loop nor the allocation is reached now
-- unless the score could actually clear the 0.6 threshold.
local FUZZY_MAX_LEN = 32
local FUZZY_THRESHOLD = 0.6

--- Similarity score between two strings (0-1), by character overlap ratio.
function TA:FuzzyScore(input, candidate)
    if not input or not candidate then return 0 end
    local lenA, lenB = #input, #candidate
    if lenA == 0 or lenB == 0 then return 0 end
    if lenA > FUZZY_MAX_LEN or lenB > FUZZY_MAX_LEN then return 0 end

    -- The score is matches / max(lenA, lenB), and matches can never exceed
    -- min(lenA, lenB). So if min/max is already below the threshold, no amount
    -- of matching gets there -- skip the nested loop and the table entirely.
    local shorter = lenA < lenB and lenA or lenB
    local longer  = lenA < lenB and lenB or lenA
    if shorter / longer < FUZZY_THRESHOLD then return 0 end

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
    return matches / longer
end

--- Find the closest module name for toggle fuzzy matching.
function TA:FuzzyMatchModule(input)
    local db = self:GetDB()
    local best, bestScore = nil, 0
    for name in pairs((db and db.modules) or {}) do
        local score = self:FuzzyScore(input, name:lower())
        if score > bestScore and score >= FUZZY_THRESHOLD then
            bestScore = score
            best = name
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════════════════
-- Interactive help
-- ══════════════════════════════════════════════════════════════════════

function TA:PrintInteractiveHelp()
    TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100ToonAge|r — click any command to run it:")
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  " .. self:MakeSlashLink("", "Open/Close ToonAge"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780TABS:|r")
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("gear", "Gear")
        .. "  " .. self:MakeSlashLink("talents", "Talents")
        .. "  " .. self:MakeSlashLink("rotation", "Rotation"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("prof", "Professions")
        .. "  " .. self:MakeSlashLink("pets", "Pets")
        .. "  " .. self:MakeSlashLink("weekly", "Weekly"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("guide", "Guide"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780TRACKER:|r")
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("tracker", "Toggle Tracker")
        .. "  " .. self:MakeSlashLink("autoselect", "Auto-Select Guide"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("diag", "Diagnose Tracker")
        .. "  " .. self:MakeSlashLink("missed", "Missed Content"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780HUD:|r")
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("arrow", "Toggle Arrow")
        .. "  " .. self:MakeSlashLink("hud", "Toggle NavHud"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("trail", "Toggle AntTrail")
        .. "  " .. self:MakeSlashLink("farmhud", "Farm Optimizer"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780TOOLS:|r")
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("coord", "Show Coordinates")
        .. "  " .. self:MakeSlashLink("xp", "XP Stats"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("alts", "Alt Roster")
        .. "  " .. self:MakeSlashLink("todo", "Weekly Todo"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("gather", "Gather History")
        .. "  " .. self:MakeSlashLink("errors", "Error Log"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF888780SYSTEM:|r")
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("options", "Settings")
        .. "  " .. self:MakeSlashLink("layout", "Toggle Layout"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("toggle", "Module Toggles")
        .. "  " .. self:MakeSlashLink("dispatch", "Event Dispatch"))
    TA:Raw(TA.LOG.OUTPUT, "    " .. self:MakeSlashLink("reset", "Reset Data"))
    TA:Raw(TA.LOG.OUTPUT, "")
    TA:Raw(TA.LOG.OUTPUT, "  |cFF555555Tip: You can type partial commands — /ta mis → missed|r")
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

-- ══════════════════════════════════════════════════════════════════════
-- Addon Compartment (modern minimap button API)
-- ══════════════════════════════════════════════════════════════════════
-- These global functions are referenced by the TOC AddonCompartmentFunc fields.

function ToonAge_OnAddonCompartmentClick(_, button)
    if button == "LeftButton" then
        ToonAge:ToggleUI()
    elseif button == "RightButton" then
        ToonAge:ToggleOptionsPanel()
    end
end

function ToonAge_OnAddonCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFFD100ToonAge|r v" .. (ToonAge.version or "2.0"))
    GameTooltip:AddLine("Left-click: Open panel", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Options", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function ToonAge_OnAddonCompartmentLeave(_, menuButtonFrame)
    GameTooltip:Hide()
end

-- ══════════════════════════════════════════════════════════════════════
-- Keybind functions (referenced by Bindings.xml)
-- ══════════════════════════════════════════════════════════════════════
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

BINDING_HEADER_TOONAGE = "ToonAge"
BINDING_NAME_TOONAGE_TOGGLE_NAVHUD = "Toggle NavHud"
BINDING_NAME_TOONAGE_TOGGLE_ARROW = "Toggle Arrow"
BINDING_NAME_TOONAGE_TOGGLE_TRACKER = "Toggle Tracker"
BINDING_NAME_TOONAGE_TOGGLE_PANEL = "Toggle Main Panel"
