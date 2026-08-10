-- ToonAge/Core/Init.lua
-- Addon object, event registration, SavedVariables, module system

local ADDON_NAME = "ToonAge"
local ADDON_VERSION = "2.0.0-dev.1"

-- ── Dev Build Tester Lock ─────────────────────────────────────────────────────
-- When IS_DEV_BUILD is true, only characters listed in AUTHORIZED_TESTERS can
-- use the addon. Everyone else gets a one-line message and the addon disables.
-- Set IS_DEV_BUILD to false (or remove the -dev suffix from the version) for
-- public releases.
local IS_DEV_BUILD = ADDON_VERSION:find("-dev") ~= nil
local AUTHORIZED_TESTERS = {
    -- Add "Name-Server" keys for authorized testers
    ["Ellacait-Vargoth"]  = true,
    ["Asirc-Myzrael"]     = true,
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

-- module is optional:  TA:Print(TA.LOG.INFO, "Arrow", msg)  ->  [TA Arrow] msg
--                      TA:Print(TA.LOG.INFO, nil, msg)      ->  [TA] msg
function TA:Print(level, module, msg)
    level = level or TA.LOG.INFO
    if level > (TA.logLevel or TA.LOG.WARN) then return end
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
    if level > (TA.logLevel or TA.LOG.WARN) then return end
    print(tostring(msg))
end

function TA:Printf(level, module, fmt, ...)
    level = level or TA.LOG.INFO
    if level > (TA.logLevel or TA.LOG.WARN) then return end
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

function TA:InitDB()
    -- ToonAgeDB is set by WoW from SavedVariables on login
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB

    -- Backfill every missing key, at every depth, so sub-keys added in new
    -- versions land in existing SavedVariables without wiping user data.
    ApplyDefaults(db, DB_DEFAULTS)

    -- Migrate the old two-flag onboarding model onto newCharBehavior.
    -- Runs here, with the other defaults, so it completes before any module
    -- Init reads the value. The old keys are dropped once translated; leaving
    -- them would recreate exactly the ambiguity this replaces.
    --
    -- Only "account scope, already done" maps to a hard off. Account scope that
    -- had not fired yet becomes "wizard" and will now run for each new
    -- character rather than once ever -- the closest honest equivalent, since
    -- the new model has no run-once-then-disable state.
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

    -- Raise the log level from the saved value. Until this line runs, output is
    -- filtered at the WARN default set beside TA.LOG, which is why anything
    -- printed during module load stays quiet on a default install.
    TA.logLevel = db.logLevel or TA.LOG.WARN

    -- Per-character key
    local name   = UnitName("player") or "Unknown"
    local server = GetRealmName() or "Unknown"
    self.charKey = name .. "-" .. server
    self.db.char[self.charKey] = self.db.char[self.charKey] or {}
    self.charDB  = self.db.char[self.charKey]
end

-- ── Module system ─────────────────────────────────────────────────────
function TA:RegisterModule(name, module)
    self.modules[name] = module
    if TA.debug then
        TA:Print(TA.LOG.DEBUG, nil, "Module registered: " .. name)
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

    for name, mod in pairs(self.modules) do
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
end

function TA:UpdateModules(event, ...)
    for name, mod in pairs(self.modules) do
        if mod.OnEvent and not mod._disabled then
            local ok, err = pcall(mod.OnEvent, mod, event, ...)
            if not ok then
                mod._errorCount = (mod._errorCount or 0) + 1

                if mod._errorCount <= ERROR_PRINT_LIMIT then
                    TA:Printf(TA.LOG.ERROR, nil, "Module %s OnEvent error: %s", name, tostring(err))
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

-- ── Event registration ────────────────────────────────────────────────
-- ADDON_LOADED and PLAYER_ENTERING_WORLD are one-shot events per the
-- guide's pattern — unregister them immediately after first fire.
-- SavedVariables are guaranteed available by PLAYER_ENTERING_WORLD.
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
TA.eventFrame:RegisterEvent("ADDON_LOADED")
TA.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Register persistent events
for _, event in ipairs(PERSISTENT_EVENTS) do
    TA.eventFrame:RegisterEvent(event)
end

TA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local TA  = ToonAge
    local arg1 = ...

    if event == "ADDON_LOADED" then
        -- Only act on our own addon load; unregister immediately
        if arg1 == "ToonAge" then
            self:UnregisterEvent("ADDON_LOADED")
            -- Pre-init: nothing to do yet — SavedVariables not available yet
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- SavedVariables are now guaranteed loaded — safe to init DB and UI
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        TA:OnLogin()

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

TA._pendingUIEvents = nil   -- set of event names awaiting a flush
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

-- ── Login sequence ────────────────────────────────────────────────────
function TA:OnLogin()
    self:InitDB()

    -- ── Dev Build Tester Lock ─────────────────────────────────────────────
    if IS_DEV_BUILD then
        local name   = UnitName("player") or "Unknown"
        local server = GetRealmName() or "Unknown"
        local charKey = name .. "-" .. server
        if not AUTHORIZED_TESTERS[charKey] then
            print("|cFFFF4444[ToonAge]|r Dev build — not authorized. Contact the developer.")
            return  -- Abort login sequence, addon stays inert
        end
    end

    -- Snapshot this character's professions (+ class/level) on every login,
    -- so profession data can be gathered across the whole account just by
    -- logging into each character — read back from SavedVariables afterward.
    self.charDB.professionSnapshot = {
        class       = TA.Utils.GetPlayerClass(),
        level       = TA.Utils.GetPlayerLevel(),
        professions = TA.Utils.GetProfessions(),
    }

    self:InitModules()
    self:InitUI()       -- defined in Core/UI.lua
    self:InitMinimap()  -- defined in Core/MinimapButton.lua

    -- Apply the saved layout choice (Unified HUD vs Fragmented Windows).
    -- Called after both InitUI and InitMinimap so all frames exist, and after
    -- InitModules so Arrow.frame and QuestTracker.window are initialised.
    self:ApplyLayout()

    -- Slash commands
    SLASH_TOONAGE1 = "/ta"
    SLASH_TOONAGE2 = "/toonage"
    SlashCmdList["TOONAGE"] = function(msg)
        TA:SlashCommand(msg)
    end

    -- Install clickable hyperlink system for interactive /ta commands
    self:InstallSlashLinkHook()

    -- INFO, not OUTPUT: nobody typed a command to get this. At the WARN default
    -- it stays quiet, which is the "healthy install is silent at login" promise
    -- made beside DB_DEFAULTS.logLevel. /ta verbose info brings it back.
    TA:Raw(TA.LOG.INFO, "|cFFFFD100ToonAge|r v" .. self.version .. " loaded. Type "
        .. self:MakeSlashLink("help", "/ta help") .. " for clickable commands.")
end

-- ── Slash command handler ─────────────────────────────────────────────
function TA:SlashCommand(msg)
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
        gear     = function() self:OpenTab("gear") end,
        talents  = function() self:OpenTab("talents") end,
        rotation = function() self:OpenTab("rotation") end,
        prof     = function() self:OpenTab("professions") end,
        pets     = function() self:OpenTab("pets") end,
        weekly   = function() self:OpenTab("weekly") end,
        guide    = function() self:OpenTab("guide") end,
        options  = function() self:ToggleOptionsPanel() end,
        debug    = function()
            TA.debug = not TA.debug
            TA:Print(TA.LOG.OUTPUT, nil, "Debug mode: " .. (TA.debug and "ON" or "OFF"))
        end,
        reset    = function()
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
            local report = self:GetHealthReport()
            local loaded, off, errored = 0, 0, 0

            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Module Health ━━━|r")
            for _, entry in ipairs(report) do
                local mod = self.modules[entry.name]
                if entry.status == "loaded" then
                    loaded = loaded + 1
                elseif entry.status == "errored" then
                    errored = errored + 1
                    TA:Raw(TA.LOG.OUTPUT, ("  |cFFFF4444✗ %s|r — init failed: %s"):format(entry.name, tostring(entry.error)))
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
                    end
                    TA:Raw(TA.LOG.OUTPUT, ("  |cFF888780○ %s — %s|r"):format(entry.name, why))
                end
            end

            TA:Raw(TA.LOG.OUTPUT, ("  |cFF4AFF7A%d loaded|r · |cFF888780%d off|r · |cFFFF4444%d errored|r")
                  :format(loaded, off, errored))

            -- Outstanding item-data requests. Should sit at 0 most of the time;
            -- a number that climbs and never falls means GET_ITEM_INFO_RECEIVED
            -- is not resolving them and the 10s timeout is doing all the work.
            local pending = TA.Utils and TA.Utils.PendingItemCount and TA.Utils.PendingItemCount()
            if pending and pending > 0 then
                TA:Raw(TA.LOG.OUTPUT, ("  |cFF888780%d item request(s) awaiting GET_ITEM_INFO_RECEIVED|r"):format(pending))
            end
            if self.db.safeMode then
                TA:Raw(TA.LOG.OUTPUT, "  |cFFFF9A1ASafe Mode is ON.|r |cFF888780/ta safemode to turn it off.|r")
            end
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
        end,
        help     = function() self:PrintInteractiveHelp() end,
    }

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
    for _, mod in pairs(self.modules) do
        if mod.SlashCommands then
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
    -- Built-in commands
    local builtins = {"gear","talents","rotation","prof","pets","weekly","guide",
                      "options","debug","reset","layout","help","toggle","open",
                      "safemode","health"}
    for _, n in ipairs(builtins) do names[#names+1] = n end

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
        .. "  " .. self:MakeSlashLink("reset", "Reset Data"))
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
BINDING_NAME_TOONAGE_TOGGLE_ARROW = "Toggle Arrow"
BINDING_NAME_TOONAGE_TOGGLE_TRACKER = "Toggle Tracker"
BINDING_NAME_TOONAGE_TOGGLE_PANEL = "Toggle Main Panel"
