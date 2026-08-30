-- ToonAge/Core/Init.lua (Anniversary — TBC Classic / Interface 20506)
-- Addon object, event registration, SavedVariables, module system.
--
-- Scope of this build (Docs/CLASSIC_ANNIVERSARY_BRIEF.md): a character
-- optimisation advisor. No quest guides, no navigation, no arrow — the player
-- uses Dugi for questing. Every Navigation module from the retail/classic builds
-- is deliberately absent, not missing.

local ADDON_NAME    = "ToonAge"
local ADDON_VERSION = "2.0.0-anniversary"

ToonAge = ToonAge or {}
local TA = ToonAge

TA.version       = ADDON_VERSION
TA.isClassic     = true
TA.isTBC         = true
TA.flavor        = "anniversary"
TA.interfaceCode = 20506

TA.modules = {}
TA.eventFrame = CreateFrame("Frame", "ToonAgeEventFrame")

-- ─── Chat output ─────────────────────────────────────────────────────────────
TA.LOG = { OUTPUT = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4 }

local LOG_COLOR = {
    [0] = "FFFFD100", [1] = "FFFF4444", [2] = "FFFF9A1A",
    [3] = "FFFFD100", [4] = "FF00CCFF",
}

TA.logLevel = TA.LOG.WARN

function TA:Print(level, module, msg)
    level = level or TA.LOG.INFO
    if level > (TA.logLevel or TA.LOG.WARN) then return end
    print(string.format("|c%s[%s]|r %s",
        LOG_COLOR[level] or LOG_COLOR[3],
        module and ("TA " .. module) or "TA",
        tostring(msg)))
end

function TA:Raw(level, msg)
    level = level or TA.LOG.INFO
    if level > (TA.logLevel or TA.LOG.WARN) then return end
    print(tostring(msg))
end

function TA:Printf(level, module, fmt, ...)
    level = level or TA.LOG.INFO
    if level > (TA.logLevel or TA.LOG.WARN) then return end
    local ok, out = pcall(string.format, fmt, ...)
    TA:Print(level, module, ok and out or fmt)
end

-- ─── Default saved variables ─────────────────────────────────────────────────
local DB_DEFAULTS = {
    minimap = { minimized = false, position = 45 },
    char    = {},

    modules = {
        StatCaps          = true,
        WeaponSkill       = true,
        RaceAdvisor       = true,
        ProfessionAdvisor = true,
        Gear              = true,
        Character         = true,
        PetCare           = true,
    },

    -- Which target the caps are computed against. "auto" tracks player level:
    -- same-level while levelling, +3 boss at 70. See Core/TBCStats.lua.
    capContext = "auto",

    -- PvP mode flips the WHOLE addon, not just one tab: it pins the cap target
    -- to same-level (an enemy player is your level), swaps the gear weights to
    -- the PvP set, drops the defense uncrittable target, and surfaces
    -- resilience. Kept as one flag so those five things cannot disagree.
    pvpMode = false,

    -- Weapon skill scanning expands and restores skill-window headers. A player
    -- who does not want their skill window touched can turn that off and fall
    -- back to equipped-weapon-only reporting.
    allowSkillExpand = true,

    logLevel = 2,
    safeMode = false,
}

local function CopyDefault(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, sub in pairs(v) do out[k] = CopyDefault(sub) end
    return out
end

local function ApplyDefaults(dst, defaults)
    for k, v in pairs(defaults) do
        if dst[k] == nil then
            dst[k] = CopyDefault(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            ApplyDefaults(dst[k], v)
        end
    end
    return dst
end

function TA:InitDB()
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB
    ApplyDefaults(db, DB_DEFAULTS)

    self.db = db
    TA.logLevel = db.logLevel or TA.LOG.WARN

    local name   = UnitName("player") or "Unknown"
    local server = GetRealmName() or "Unknown"
    self.charKey = name .. "-" .. server
    self.db.char[self.charKey] = self.db.char[self.charKey] or {}
    self.charDB  = self.db.char[self.charKey]
end

-- ─── Module system ───────────────────────────────────────────────────────────
function TA:RegisterModule(name, module)
    self.modules[name] = module
    return module
end

function TA:GetModule(name)
    return self.modules[name]
end

function TA:CountModules()
    local n = 0
    for _ in pairs(self.modules) do n = n + 1 end
    return n
end

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

-- ─── Safe Mode ───────────────────────────────────────────────────────────────
local ERROR_DISABLE_THRESHOLD = 10
local ERROR_PRINT_LIMIT = 3

local SAFE_MODE_KEEP = {
    ErrorLog = true, ApiGuard = true, State = true,
    TBCStats = true, SkillScan = true, Character = true,
}

-- WARN: this walks self.modules with pairs(), so Init order across modules is
-- whatever Lua's hash traversal happens to produce — not registration order,
-- and not guaranteed stable across reloads if the module set changes. Fine
-- today because no module's Init reads state another module's Init produces;
-- if that stops being true, this needs an explicit priority list instead of
-- pairs().
function TA:InitModules()
    local safe = self.db and self.db.safeMode

    if safe then
        TA:Print(TA.LOG.WARN, nil, "SAFE MODE — only core modules loaded. "
            .. "|cFF888780/ta safemode to turn off, then /reload.|r")
    end

    for name, mod in pairs(self.modules) do
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

                if TA.ErrorLog then TA.ErrorLog:Log(name .. " OnEvent", tostring(err), event or "") end

                if mod._errorCount >= ERROR_DISABLE_THRESHOLD then
                    mod._disabled = true
                    mod._autoDisabled = true
                    TA:Print(TA.LOG.WARN, "Safe Mode", name .. " disabled after "
                        .. mod._errorCount .. " errors this session. "
                        .. "|cFF888780Reload to re-enable. /ta health for status.|r")
                end
            end
        end
    end
end

-- ─── EVENT REGISTRATION ──────────────────────────────────────────────────────
-- RegisterEvent throws on an event this client does not have, which would take
-- the whole addon down at load. Every registration is therefore individually
-- guarded and the failures are collected — a missing event is a degraded
-- feature, not a dead addon, and it is reported rather than swallowed.
--
-- TBC-specific choices:
--   CHARACTER_POINTS_CHANGED  — TBC's talent-spend event (retail's
--                               PLAYER_TALENT_UPDATE / ACTIVE_TALENT_GROUP_CHANGED
--                               belong to later expansions; there is no dual spec)
--   COMBAT_RATING_UPDATE      — hit/expertise/defense rating changed
--   SKILL_LINES_CHANGED       — weapon skill ticked up
--   PLAYER_TARGET_CHANGED     — caps are target-relative, so the target matters
--
-- WARN: UNIT_STATS / UNIT_ATTACK_POWER / UNIT_RANGED_ATTACK_POWER /
-- UNIT_RESISTANCES are registered here with plain RegisterEvent, not
-- RegisterUnitEvent, so they fire for the unit whose stats changed — which is
-- not always "player" (target, party members, pets all trigger these too).
-- Nothing in the dispatch chain below filters arg1 by unit; TA:UpdateModules
-- forwards every fire to every module's OnEvent regardless of which unit it
-- was about. That is currently harmless (downstream code re-reads via
-- UnitStat("player", ...) rather than trusting the event payload) but it does
-- mean the addon re-invalidates state and queues a UI refresh on stat changes
-- that have nothing to do with the player — worth narrowing to unit=="player"
-- if this ever shows up as unnecessary refresh churn.
--
-- NOTE: these persistent events are registered here at file load, i.e. before
-- TA:OnLogin() (and therefore TA:InitDB()) has run. ADDON_LOADED is guaranteed
-- to fire first, but BAG_UPDATE / GET_ITEM_INFO_RECEIVED / SKILL_LINES_CHANGED
-- and friends can plausibly fire during the loading screen, ahead of
-- PLAYER_ENTERING_WORLD. TA:UpdateModules would dispatch those to module
-- OnEvent handlers while self.db is still nil. Each call is pcall-guarded so
-- it cannot crash the addon, but a module that assumes TA.db is already set
-- would count as an error on every such early fire — enough of them before
-- login completes would trip ERROR_DISABLE_THRESHOLD and auto-disable the
-- module before the player ever sees the UI.

local PERSISTENT_EVENTS = {
    "PLAYER_LEVEL_UP",
    "CHARACTER_POINTS_CHANGED",
    "SKILL_LINES_CHANGED",
    "COMBAT_RATING_UPDATE",
    "UNIT_INVENTORY_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_TARGET_CHANGED",
    "UNIT_STATS",
    "UNIT_ATTACK_POWER",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_RESISTANCES",
    "BAG_UPDATE",
    "GET_ITEM_INFO_RECEIVED",
    "UNIT_PET",
    "SPELLS_CHANGED",
}

TA.unavailableEvents = {}

local function SafeRegister(frame, event)
    local ok = pcall(frame.RegisterEvent, frame, event)
    if not ok then
        table.insert(TA.unavailableEvents, event)
    end
    return ok
end

SafeRegister(TA.eventFrame, "ADDON_LOADED")
SafeRegister(TA.eventFrame, "PLAYER_ENTERING_WORLD")

for _, event in ipairs(PERSISTENT_EVENTS) do
    SafeRegister(TA.eventFrame, event)
end

TA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local TA = ToonAge
    local arg1 = ...

    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        TA:OnLogin()

    else
        if TA.State then TA.State:Invalidate(event) end

        if event == "GET_ITEM_INFO_RECEIVED" and TA.Utils and TA.Utils.OnItemInfoReceived then
            local itemID, success = ...
            TA.Utils.OnItemInfoReceived(itemID, success)
        end

        TA:UpdateModules(event, ...)
        TA:QueueUIRefresh(event)
    end
end)

-- ─── Coalesced UI refresh ────────────────────────────────────────────────────
local UI_REFRESH_DELAY = 0.15

TA._pendingUIEvents = nil
TA._uiRefreshQueued = false

function TA:QueueUIRefresh(event)
    if not (self.UI and self.UI:IsVisible()) then return end

    self._pendingUIEvents = self._pendingUIEvents or {}
    self._pendingUIEvents[event] = true

    if self._uiRefreshQueued then return end
    self._uiRefreshQueued = true

    C_Timer.After(UI_REFRESH_DELAY, function()
        local events = TA._pendingUIEvents
        TA._pendingUIEvents = nil
        TA._uiRefreshQueued = false

        if not (TA.UI and TA.UI:IsVisible()) then return end

        local ok, err = pcall(TA.UI.Refresh, TA.UI, events)
        if not ok then
            TA:Printf(TA.LOG.ERROR, nil, "UI refresh error: %s", tostring(err))
            if TA.ErrorLog then TA.ErrorLog:Log("UI Refresh", tostring(err), "") end
        end
    end)
end

-- ─── OnLogin ─────────────────────────────────────────────────────────────────
function TA:OnLogin()
    self:InitDB()

    -- No profession snapshot here: GetProfessions() arrived in 3.0 and does not
    -- exist on this client. Professions come from Core/SkillScan.lua, which
    -- reads the skill list instead. Calling GetProfessions here is exactly the
    -- kind of copied-forward assumption that produces a nil-index crash at login.

    self:InitModules()

    -- Slash commands are registered BEFORE the UI, and the UI is built inside a
    -- pcall. Order matters more than it looks: if InitUI throws — which is
    -- exactly what happened on the _classic_ build's first-ever login, at
    -- UI.lua:49 — then registering commands afterwards means /ta apiprobe,
    -- /ta dumpme and /ta errors all fail to exist too. The addon would be dead
    -- AND undiagnosable. This way a UI failure still leaves every diagnostic
    -- reachable and says so in chat.
    SLASH_TOONAGE1 = "/ta"
    SLASH_TOONAGE2 = "/toonage"
    SlashCmdList["TOONAGE"] = function(msg) TA:SlashCommand(msg) end

    local uiOK, uiErr = pcall(self.InitUI, self)
    if not uiOK then
        TA:Printf(TA.LOG.ERROR, nil, "The panel failed to build: %s", tostring(uiErr))
        TA:Raw(TA.LOG.ERROR, "|cFFFFD100Slash commands still work.|r Try |cFFFFD100/ta apiprobe|r "
            .. "and |cFFFFD100/ta caps|r — they do not need the window.")
        if TA.ErrorLog then TA.ErrorLog:Log("InitUI", tostring(uiErr), "") end
    end

    local mmOK, mmErr = pcall(self.InitMinimap, self)
    if not mmOK and TA.ErrorLog then
        TA.ErrorLog:Log("InitMinimap", tostring(mmErr), "")
    end

    TA:Printf(TA.LOG.INFO, nil, "v%s loaded (%d modules, interface %d).",
        TA.version, TA:CountModules(), TA.interfaceCode)

    if #TA.unavailableEvents > 0 then
        TA:Printf(TA.LOG.WARN, nil, "%d event(s) not available on this client: %s",
            #TA.unavailableEvents, table.concat(TA.unavailableEvents, ", "))
    end
end

-- ─── Slash command dispatch ──────────────────────────────────────────────────
function TA:SlashCommand(msg)
    local cmd, args = (msg or ""):match("^(%S*)%s*(.*)")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        self:ToggleUI()
        return
    end

    -- ── Help & settings ──
    if cmd == "help" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Anniversary ━━━|r")
        TA:Raw(TA.LOG.OUTPUT, "  /ta            — toggle the panel")
        TA:Raw(TA.LOG.OUTPUT, "  /ta caps       — stat caps: what you still need")
        TA:Raw(TA.LOG.OUTPUT, "  /ta gear       — gear tab")
        TA:Raw(TA.LOG.OUTPUT, "  /ta weapons    — weapon skill tab")
        TA:Raw(TA.LOG.OUTPUT, "  /ta racials    — racial bonuses")
        TA:Raw(TA.LOG.OUTPUT, "  /ta profs      — profession combat perks")
        TA:Raw(TA.LOG.OUTPUT, "  /ta talents    — your talent trees, live from the client")
        TA:Raw(TA.LOG.OUTPUT, "  /ta pvp        — toggle PvP mode (flips caps, weights and resilience)")
        TA:Raw(TA.LOG.OUTPUT, "  /ta hitbonus   — override hit from talents the API cannot report")
        TA:Raw(TA.LOG.OUTPUT, "  /ta statkeys   — item stat keys this build could not map")
        TA:Raw(TA.LOG.OUTPUT, "  /ta context <same|plus1|plus2|plus3|auto> — target the caps assume")
        TA:Raw(TA.LOG.OUTPUT, "  /ta dumpme     — print the /dump lines that verify this build")
        TA:Raw(TA.LOG.OUTPUT, "  /ta apiprobe   — which APIs resolved on this client")
        TA:Raw(TA.LOG.OUTPUT, "  /ta health     — module health")
        TA:Raw(TA.LOG.OUTPUT, "  /ta errors     — recent errors")
        TA:Raw(TA.LOG.OUTPUT, "  /ta safemode   — toggle safe mode")
        TA:Raw(TA.LOG.OUTPUT, "  /ta reset      — wipe settings (then /reload)")
        return
    end

    if cmd == "reset" then
        ToonAgeDB = nil
        TA:Print(TA.LOG.OUTPUT, nil, "Settings wiped. |cFFFFD100/reload|r to apply.")
        return
    end

    if cmd == "safemode" then
        self.db.safeMode = not self.db.safeMode
        TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode: "
            .. (self.db.safeMode and "|cFFFF4444ON|r" or "|cFF4AFF7AOFF|r")
            .. "  |cFF888780/reload to apply.|r")
        return
    end

    -- ── Cap targeting ──
    if cmd == "pvp" then
        self.db.pvpMode = not self.db.pvpMode
        if self.db.pvpMode then
            TA:Print(TA.LOG.OUTPUT, nil, "|cFFFF6E6EPvP mode ON.|r Caps pinned to same-level "
                .. "(5% melee hit, 3% spell hit), gear weights swapped to the PvP set, "
                .. "resilience shown, defense uncrittable target dropped.")
        else
            TA:Print(TA.LOG.OUTPUT, nil, "|cFF4AFF7APvE mode.|r Caps follow |cFFFFD100/ta context|r again.")
        end
        if self.UI and self.UI:IsVisible() then self.UI:Refresh() end
        return
    end

    if cmd == "context" then
        local valid = { auto=true, same=true, plus1=true, plus2=true, plus3=true }
        local want = (args or ""):lower()
        if valid[want] then
            self.db.capContext = want
            TA:Printf(TA.LOG.OUTPUT, nil, "Caps now assume target: |cFFFFD100%s|r", want)
            if self.UI and self.UI:IsVisible() then self.UI:Refresh() end
        else
            TA:Printf(TA.LOG.OUTPUT, nil,
                "Usage: /ta context <auto|same|plus1|plus2|plus3>  (currently %s)",
                tostring(self.db.capContext))
        end
        return
    end

    -- ── Diagnostics ──
    if cmd == "dumpme" then
        local S = TA.TBCStats
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Paste these in chat, then send me the output ━━━|r")
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780Everything this build assumes about the 20506 API is in these lines.|r")
        for _, line in ipairs(S and S:DumpLines() or {}) do
            TA:Raw(TA.LOG.OUTPUT, "  " .. line)
        end
        return
    end

    if cmd == "health" then
        local report = self:GetHealthReport()
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Module Health ━━━|r")
        for _, entry in ipairs(report) do
            local icon = entry.status == "loaded"   and "|cFF4AFF7A●|r"
                      or entry.status == "disabled" and "|cFF888780○|r"
                      or "|cFFFF4444✖|r"
            local line = string.format("  %s %s", icon, entry.name)
            if entry.error then line = line .. " |cFFFF4444" .. entry.error .. "|r" end
            TA:Raw(TA.LOG.OUTPUT, line)
        end
        return
    end

    -- ── Module control ──
    if cmd == "toggle" then
        if args == "" then
            TA:Print(TA.LOG.OUTPUT, nil, "Usage: /ta toggle <ModuleName>")
            return
        end
        if not self.modules[args] then
            TA:Printf(TA.LOG.OUTPUT, nil, "Module '%s' not found.", args)
            return
        end
        local current = self.db.modules[args]
        if current == nil then current = true end
        self.db.modules[args] = not current
        TA:Printf(TA.LOG.OUTPUT, nil, "%s: %s |cFF888780(/reload to apply)|r",
            args, self.db.modules[args] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r")
        return
    end

    -- Tab shortcuts
    local tabShortcuts = {
        character = "character", caps = "caps", gear = "gear",
        weapons = "weapons", racials = "racials", profs = "profs",
    }
    if tabShortcuts[cmd] then
        self:ShowUI()
        if self.UI and self.UI.SetTab then self.UI:SetTab(tabShortcuts[cmd]) end
        return
    end

    -- Module slash commands
    for _, mod in pairs(self.modules) do
        if mod.SlashCommands and mod.SlashCommands[cmd] then
            mod.SlashCommands[cmd](mod, args)
            return
        end
    end

    TA:Printf(TA.LOG.OUTPUT, nil, "Unknown command '%s'. Try /ta help.", cmd)
end

-- ─── UI toggle helpers ───────────────────────────────────────────────────────
function TA:ToggleUI()
    if not self.UI then return end
    if self.UI:IsVisible() then
        self.UI:Hide()
    else
        self.UI:Show()
        if self.UI.Refresh then self.UI:Refresh() end
    end
end

function TA:ShowUI()
    if not self.UI then return end
    self.UI:Show()
    if self.UI.Refresh then self.UI:Refresh() end
end

-- ─── Keybinding ──────────────────────────────────────────────────────────────
-- Bindings.xml names a header and a binding; without these two globals the
-- keybind UI shows the raw tokens ("TOONAGE_TOGGLE") instead of readable text.
-- Bindings.xml threw "Unrecognized XML: Binding" on login 2026-08-16 and was
-- disabled in the TOC. Root cause confirmed 2026-08-22: a `category`
-- attribute on <Binding> that isn't part of the documented schema (only
-- name, header, default, runOnUp are valid) — removed, and the file is
-- re-enabled in ToonAge.toc.
BINDING_HEADER_TOONAGE      = "ToonAge"
BINDING_NAME_TOONAGE_TOGGLE = "Toggle ToonAge panel"

function ToonAge_TogglePanel()
    ToonAge:ToggleUI()
end
