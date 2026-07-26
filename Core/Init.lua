-- ToonAge/Core/Init.lua
-- Addon object, event registration, SavedVariables, module system

local ADDON_NAME = "ToonAge"
local ADDON_VERSION = "1.0.0"

-- Create the global addon table
ToonAge = ToonAge or {}
local TA = ToonAge

-- Version
TA.version = ADDON_VERSION

-- Module registry: modules register themselves here
TA.modules = {}

-- Event frame
TA.eventFrame = CreateFrame("Frame", "ToonAgeEventFrame")

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

function TA:InitDB()
    -- ToonAgeDB is set by WoW from SavedVariables on login
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB

    -- Apply defaults for any missing top-level keys
    for k, v in pairs(DB_DEFAULTS) do
        if db[k] == nil then
            db[k] = CopyDefault(v)
        end
    end

    -- Deep-default nested tables so sub-keys added in new versions get
    -- backfilled into existing SavedVariables without wiping user data.
    if type(DB_DEFAULTS.oldUiPositions) == "table" then
        db.oldUiPositions = db.oldUiPositions or {}
        for k, v in pairs(DB_DEFAULTS.oldUiPositions) do
            if db.oldUiPositions[k] == nil then
                db.oldUiPositions[k] = CopyDefault(v)
            end
        end
    end
    if type(DB_DEFAULTS.unifiedPosition) == "table" then
        db.unifiedPosition = db.unifiedPosition or {}
        for k, v in pairs(DB_DEFAULTS.unifiedPosition) do
            if db.unifiedPosition[k] == nil then
                db.unifiedPosition[k] = CopyDefault(v)
            end
        end
    end
    if type(DB_DEFAULTS.modules) == "table" then
        db.modules = db.modules or {}
        for k, v in pairs(DB_DEFAULTS.modules) do
            if db.modules[k] == nil then
                db.modules[k] = CopyDefault(v)
            end
        end
    end

    self.db = db

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
        print("|cFFFFD100[TA]|r Module registered: " .. name)
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
        print("|cFFFF9A1A[ToonAge] SAFE MODE|r — only core modules loaded. "
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
                    print("|cFFFF4444[TA] Error initialising module " .. name .. ":|r " .. tostring(err))
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
                    print("|cFFFF4444[TA] Module " .. name .. " OnEvent error:|r " .. tostring(err))
                elseif mod._errorCount == ERROR_PRINT_LIMIT + 1 then
                    print("|cFFFF9A1A[TA]|r " .. name .. " keeps failing — muting further errors. "
                          .. "|cFF888780/ta errors to read them.|r")
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
                    print("|cFFFF9A1A[ToonAge Safe Mode]|r " .. msg
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
            print("|cFFFF4444[TA] UI refresh error:|r " .. tostring(err))
            if TA.ErrorLog then TA.ErrorLog:Log("UI Refresh", tostring(err), "") end
        end
    end)
end

-- ── Login sequence ────────────────────────────────────────────────────
function TA:OnLogin()
    self:InitDB()

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

    print("|cFFFFD100ToonAge|r v" .. self.version .. " loaded. Type "
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
            print("|cFFFFD100[TA]|r Debug mode: " .. (TA.debug and "ON" or "OFF"))
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
            print("|cFFFFD100[TA]|r Settings reset. Please reload UI (/reload).")
        end,
        layout   = function()
            self.db.useUnifiedUI = not self.db.useUnifiedUI
            self:ApplyLayout()
            local mode = self.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
            print("|cFFFFD100[ToonAge]|r Layout: " .. mode)
        end,
        safemode = function()
            self.db.safeMode = not self.db.safeMode
            if self.db.safeMode then
                print("|cFFFF9A1A[ToonAge]|r Safe Mode |cFFFF9A1AON|r — next load initialises "
                      .. "core modules only. |cFF888780/reload to apply.|r")
            else
                print("|cFFFFD100[ToonAge]|r Safe Mode |cFF4AFF7AOFF|r. "
                      .. "|cFF888780/reload to load everything again.|r")
            end
        end,
        health   = function()
            local report = self:GetHealthReport()
            local loaded, off, errored = 0, 0, 0

            print("|cFFFFD100━━━ ToonAge Module Health ━━━|r")
            for _, entry in ipairs(report) do
                local mod = self.modules[entry.name]
                if entry.status == "loaded" then
                    loaded = loaded + 1
                elseif entry.status == "errored" then
                    errored = errored + 1
                    print(("  |cFFFF4444✗ %s|r — init failed: %s"):format(entry.name, tostring(entry.error)))
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
                    print(("  |cFF888780○ %s — %s|r"):format(entry.name, why))
                end
            end

            print(("  |cFF4AFF7A%d loaded|r · |cFF888780%d off|r · |cFFFF4444%d errored|r")
                  :format(loaded, off, errored))

            -- Outstanding item-data requests. Should sit at 0 most of the time;
            -- a number that climbs and never falls means GET_ITEM_INFO_RECEIVED
            -- is not resolving them and the 10s timeout is doing all the work.
            local pending = TA.Utils and TA.Utils.PendingItemCount and TA.Utils.PendingItemCount()
            if pending and pending > 0 then
                print(("  |cFF888780%d item request(s) awaiting GET_ITEM_INFO_RECEIVED|r"):format(pending))
            end
            if self.db.safeMode then
                print("  |cFFFF9A1ASafe Mode is ON.|r |cFF888780/ta safemode to turn it off.|r")
            end
            print("|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
        end,
        help     = function() self:PrintInteractiveHelp() end,
    }

    -- Check exact built-in match
    if BUILTIN[cmd] then
        BUILTIN[cmd]()
        return
    end

    -- ── Toggle subcommand ─────────────────────────────────────────────
    if cmd == "toggle" then
        local modName = args ~= "" and args or nil
        if not modName then
            print("|cFFFFD100[TA]|r Toggleable modules:")
            for name, enabled in pairs(self.db.modules or {}) do
                local status = enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
                local link = self:MakeSlashLink("toggle " .. name:lower(), name .. " " .. status)
                print("  " .. link)
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
            print("|cFFFFD100[TA]|r Unknown module: " .. modName)
            return
        end
        self.db.modules[matchedKey] = not self.db.modules[matchedKey]
        local status = self.db.modules[matchedKey] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        print("|cFFFFD100[TA]|r Module " .. matchedKey .. ": " .. status .. "  (reload to apply)")
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
        print("|cFFFFD100[ToonAge]|r Unknown command: |cFFFF8800" .. cmd .. "|r")
        print("  Did you mean:")
        for _, name in ipairs(suggestions) do
            print("    " .. self:MakeSlashLink(name, "/ta " .. name))
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
    print("|cFFFFD100ToonAge|r — click any command to run it:")
    print("")
    print("  " .. self:MakeSlashLink("", "Open/Close ToonAge"))
    print("")
    print("  |cFF888780TABS:|r")
    print("    " .. self:MakeSlashLink("gear", "Gear")
        .. "  " .. self:MakeSlashLink("talents", "Talents")
        .. "  " .. self:MakeSlashLink("rotation", "Rotation"))
    print("    " .. self:MakeSlashLink("prof", "Professions")
        .. "  " .. self:MakeSlashLink("pets", "Pets")
        .. "  " .. self:MakeSlashLink("weekly", "Weekly"))
    print("    " .. self:MakeSlashLink("guide", "Guide"))
    print("")
    print("  |cFF888780TRACKER:|r")
    print("    " .. self:MakeSlashLink("tracker", "Toggle Tracker")
        .. "  " .. self:MakeSlashLink("autoselect", "Auto-Select Guide"))
    print("    " .. self:MakeSlashLink("diag", "Diagnose Tracker")
        .. "  " .. self:MakeSlashLink("missed", "Missed Content"))
    print("")
    print("  |cFF888780HUD:|r")
    print("    " .. self:MakeSlashLink("arrow", "Toggle Arrow")
        .. "  " .. self:MakeSlashLink("hud", "Toggle NavHud"))
    print("    " .. self:MakeSlashLink("trail", "Toggle AntTrail")
        .. "  " .. self:MakeSlashLink("farmhud", "Farm Optimizer"))
    print("")
    print("  |cFF888780TOOLS:|r")
    print("    " .. self:MakeSlashLink("coord", "Show Coordinates")
        .. "  " .. self:MakeSlashLink("xp", "XP Stats"))
    print("    " .. self:MakeSlashLink("alts", "Alt Roster")
        .. "  " .. self:MakeSlashLink("todo", "Weekly Todo"))
    print("    " .. self:MakeSlashLink("gather", "Gather History")
        .. "  " .. self:MakeSlashLink("errors", "Error Log"))
    print("")
    print("  |cFF888780SYSTEM:|r")
    print("    " .. self:MakeSlashLink("options", "Settings")
        .. "  " .. self:MakeSlashLink("layout", "Toggle Layout"))
    print("    " .. self:MakeSlashLink("toggle", "Module Toggles")
        .. "  " .. self:MakeSlashLink("reset", "Reset Data"))
    print("")
    print("  |cFF555555Tip: You can type partial commands — /ta mis → missed|r")
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
