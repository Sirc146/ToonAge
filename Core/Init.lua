-- ToonAge/Core/Init.lua (Classic)
-- Addon object, event registration, SavedVariables, module system
-- Adapted for Cataclysm Classic (interface 40402)

local ADDON_NAME = "ToonAge"
local ADDON_VERSION = "1.0.0-classic"

-- Create the global addon table
ToonAge = ToonAge or {}
local TA = ToonAge

TA.version = ADDON_VERSION
TA.isClassic = true

-- Module registry
TA.modules = {}

-- Event frame
TA.eventFrame = CreateFrame("Frame", "ToonAgeEventFrame")

-- ── Chat output ───────────────────────────────────────────────────────────
TA.LOG = {
    OUTPUT = 0,
    ERROR  = 1,
    WARN   = 2,
    INFO   = 3,
    DEBUG  = 4,
}

local LOG_COLOR = {
    [0] = "FFFFD100",
    [1] = "FFFF4444",
    [2] = "FFFF9A1A",
    [3] = "FFFFD100",
    [4] = "FF00CCFF",
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

-- ── Default saved variables ───────────────────────────────────────────
local DB_DEFAULTS = {
    minimap = { minimized = false, position = 45 },
    char    = {},

    modules = {
        NavHud       = true,
        MapPins      = true,
        CutsceneSkip = true,
        AutoEquip    = true,
        AutoMount    = true,
        GatherTracker = true,
    },

    newCharBehavior = "wizard",
    defaultPreset   = "auto",
    logLevel = 2,
    safeMode = false,

    useUnifiedUI = true,
    unifiedPosition = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 220 },
    oldUiPositions = {
        arrow  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 150  },
        guide  = { point = "CENTER", relativePoint = "CENTER", x = 0,    y = 0    },
    },
}

-- ── SavedVariables ────────────────────────────────────────────────────
local function CopyDefault(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, sub in pairs(v) do
        out[k] = CopyDefault(sub)
    end
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

    -- Migrate old onboarding flags
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
    TA.logLevel = db.logLevel or TA.LOG.WARN

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
local ERROR_DISABLE_THRESHOLD = 10
local ERROR_PRINT_LIMIT = 3

local SAFE_MODE_KEEP = {
    ErrorLog = true,
    Character = true, Gear = true,
    QuestTracker = true, Arrow = true, GuideParser = true,
}

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
-- Classic Cata events — no TRAIT_CONFIG_UPDATED, no PET_STABLE_UPDATE
local PERSISTENT_EVENTS = {
    "PLAYER_LEVEL_UP",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "SKILL_LINES_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE",
    "GROUP_ROSTER_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "CHAT_MSG_SYSTEM",
    "GET_ITEM_INFO_RECEIVED",
    "QUEST_ACCEPTED",
}

TA.eventFrame:RegisterEvent("ADDON_LOADED")
TA.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

for _, event in ipairs(PERSISTENT_EVENTS) do
    TA.eventFrame:RegisterEvent(event)
end

TA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local TA  = ToonAge
    local arg1 = ...

    if event == "ADDON_LOADED" then
        if arg1 == "ToonAge" then
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

-- ── Coalesced UI refresh ──────────────────────────────────────────────
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

-- ── OnLogin ───────────────────────────────────────────────────────────
function TA:OnLogin()
    self:InitDB()

    -- Profession snapshot (works in Cata Classic)
    local p1, p2 = GetProfessions()
    if p1 then self.charDB.prof1 = select(1, GetProfessionInfo(p1)) end
    if p2 then self.charDB.prof2 = select(1, GetProfessionInfo(p2)) end

    self:InitModules()
    self:InitUI()
    self:InitMinimap()
    self:ApplyLayout()

    -- Slash commands
    SLASH_TOONAGE1 = "/ta"
    SLASH_TOONAGE2 = "/toonage"
    SlashCmdList["TOONAGE"] = function(msg)
        TA:SlashCommand(msg)
    end

    TA:Print(TA.LOG.INFO, nil, string.format("v%s loaded (%d modules).",
        TA.version, TA:CountModules()))
end

function TA:CountModules()
    local n = 0
    for _ in pairs(self.modules) do n = n + 1 end
    return n
end

-- ── Slash command dispatch ────────────────────────────────────────────
function TA:SlashCommand(msg)
    local cmd, args = (msg or ""):match("^(%S*)%s*(.*)")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        self:ToggleUI()
        return
    end

    -- Built-in commands
    if cmd == "help" then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ ToonAge Classic Commands ━━━|r")
        TA:Raw(TA.LOG.OUTPUT, "  /ta              — toggle main panel")
        TA:Raw(TA.LOG.OUTPUT, "  /ta gear         — jump to Gear tab")
        TA:Raw(TA.LOG.OUTPUT, "  /ta guide        — jump to Guide tab")
        TA:Raw(TA.LOG.OUTPUT, "  /ta errors       — show recent errors")
        TA:Raw(TA.LOG.OUTPUT, "  /ta health       — module health report")
        TA:Raw(TA.LOG.OUTPUT, "  /ta toggle <mod> — enable/disable a module")
        TA:Raw(TA.LOG.OUTPUT, "  /ta layout       — toggle Unified/Fragmented")
        TA:Raw(TA.LOG.OUTPUT, "  /ta safemode     — toggle safe mode")
        TA:Raw(TA.LOG.OUTPUT, "  /ta verbose <lvl>— set log level (error/warn/info/debug)")
        TA:Raw(TA.LOG.OUTPUT, "  /ta reset        — reset settings (then /reload)")
        TA:Raw(TA.LOG.OUTPUT, "  /ta apiprobe     — check API availability")
        return
    end

    if cmd == "reset" then
        ToonAgeDB = nil
        TA:Print(TA.LOG.OUTPUT, nil, "Settings wiped. |cFFFFD100/reload|r to apply.")
        return
    end

    if cmd == "safemode" then
        self.db.safeMode = not self.db.safeMode
        local state = self.db.safeMode and "|cFFFF4444ON|r" or "|cFF4AFF7AOFF|r"
        TA:Print(TA.LOG.OUTPUT, nil, "Safe Mode: " .. state .. "  |cFF888780/reload to apply.|r")
        return
    end

    if cmd == "layout" then
        self.db.useUnifiedUI = not self.db.useUnifiedUI
        self:ApplyLayout()
        local mode = self.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
        TA:Print(TA.LOG.OUTPUT, nil, "Layout: " .. mode)
        return
    end

    if cmd == "verbose" then
        local levels = { error = 1, warn = 2, info = 3, debug = 4 }
        local lvl = levels[args:lower()]
        if lvl then
            self.db.logLevel = lvl
            TA.logLevel = lvl
            TA:Printf(TA.LOG.OUTPUT, nil, "Log level set to %s (%d).", args, lvl)
        else
            TA:Print(TA.LOG.OUTPUT, nil, "Usage: /ta verbose <error|warn|info|debug>")
        end
        return
    end

    if cmd == "health" then
        local report = self:GetHealthReport()
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100━━━ Module Health ━━━|r")
        for _, entry in ipairs(report) do
            local icon
            if entry.status == "loaded" then icon = "|cFF4AFF7A●|r"
            elseif entry.status == "disabled" then icon = "|cFF888780○|r"
            else icon = "|cFFFF4444✖|r" end
            local line = string.format("  %s %s", icon, entry.name)
            if entry.error then line = line .. " |cFFFF4444" .. entry.error .. "|r" end
            TA:Raw(TA.LOG.OUTPUT, line)
        end
        return
    end

    if cmd == "toggle" then
        local modName = args
        if modName == "" then
            TA:Print(TA.LOG.OUTPUT, nil, "Usage: /ta toggle <ModuleName>")
            return
        end
        if not self.modules[modName] then
            TA:Printf(TA.LOG.OUTPUT, nil, "Module '%s' not found.", modName)
            return
        end
        local current = self.db.modules[modName]
        if current == nil then current = true end
        self.db.modules[modName] = not current
        local state = self.db.modules[modName] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        TA:Printf(TA.LOG.OUTPUT, nil, "%s: %s |cFF888780(/reload to apply)|r", modName, state)
        return
    end

    -- Tab shortcuts
    local tabShortcuts = { character = "character", gear = "gear", guide = "guide" }
    if tabShortcuts[cmd] then
        self:ShowUI()
        if self.UI and self.UI.SetTab then self.UI:SetTab(tabShortcuts[cmd]) end
        return
    end

    -- Module slash commands
    for name, mod in pairs(self.modules) do
        if mod.SlashCommands and mod.SlashCommands[cmd] then
            mod.SlashCommands[cmd](mod, args)
            return
        end
    end

    TA:Printf(TA.LOG.OUTPUT, nil, "Unknown command '%s'. Try /ta help.", cmd)
end

-- ── UI toggle helpers ─────────────────────────────────────────────────
function TA:ToggleUI()
    if self.UI then
        if self.UI:IsVisible() then
            self.UI:Hide()
        else
            self.UI:Show()
            if self.UI.Refresh then self.UI:Refresh() end
        end
    end
end

function TA:ShowUI()
    if self.UI then
        self.UI:Show()
        if self.UI.Refresh then self.UI:Refresh() end
    end
end

-- ── ApplyLayout (Unified vs Fragmented) ──────────────────────────────
function TA:ApplyLayout()
    -- Stub for Classic — can be expanded if Arrow/QuestTracker window placement
    -- needs to vary between unified and fragmented layouts
    if not self.db then return end
    -- For now, just ensure the Arrow and QuestTracker know about layout mode
    local arrow = self:GetModule("Arrow")
    local qt    = self:GetModule("QuestTracker")
    if arrow and arrow.frame and self.db.useUnifiedUI then
        -- Unified: position relative to bottom-center
    end
end

-- ── Global binding functions ──────────────────────────────────────────
function ToonAge_TogglePanel()
    ToonAge:ToggleUI()
end

function ToonAge_ToggleNavHud()
    local mod = ToonAge:GetModule("NavHud")
    if mod and mod.Toggle then mod:Toggle() end
end

function ToonAge_ToggleArrow()
    local mod = ToonAge:GetModule("Arrow")
    if mod and mod.Toggle then mod:Toggle() end
end

function ToonAge_ToggleTracker()
    local mod = ToonAge:GetModule("QuestTracker")
    if mod and mod.Toggle then mod:Toggle() end
end
