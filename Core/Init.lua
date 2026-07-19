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
        AutoEquip    = true,
    },

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
function TA:InitDB()
    -- ToonAgeDB is set by WoW from SavedVariables on login
    ToonAgeDB = ToonAgeDB or {}
    local db = ToonAgeDB

    -- Apply defaults for any missing top-level keys
    for k, v in pairs(DB_DEFAULTS) do
        if db[k] == nil then
            db[k] = v
        end
    end

    -- Deep-default nested tables so sub-keys added in new versions get
    -- backfilled into existing SavedVariables without wiping user data.
    if type(DB_DEFAULTS.oldUiPositions) == "table" then
        db.oldUiPositions = db.oldUiPositions or {}
        for k, v in pairs(DB_DEFAULTS.oldUiPositions) do
            if db.oldUiPositions[k] == nil then
                db.oldUiPositions[k] = v
            end
        end
    end
    if type(DB_DEFAULTS.unifiedPosition) == "table" then
        db.unifiedPosition = db.unifiedPosition or {}
        for k, v in pairs(DB_DEFAULTS.unifiedPosition) do
            if db.unifiedPosition[k] == nil then
                db.unifiedPosition[k] = v
            end
        end
    end
    if type(DB_DEFAULTS.modules) == "table" then
        db.modules = db.modules or {}
        for k, v in pairs(DB_DEFAULTS.modules) do
            if db.modules[k] == nil then
                db.modules[k] = v
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

function TA:InitModules()
    for name, mod in pairs(self.modules) do
        -- Check if this optional module is disabled by the user
        if self.db and self.db.modules and self.db.modules[name] == false then
            mod._disabled = true
        else
            mod._disabled = false
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
                print("|cFFFF4444[TA] Module " .. name .. " OnEvent error:|r " .. tostring(err))
                    if TA.ErrorLog then TA.ErrorLog:Log(name .. " OnEvent", tostring(err), "") end
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
        -- All persistent events: update modules then refresh UI if open
        TA:UpdateModules(event, ...)
        if TA.UI and TA.UI:IsVisible() then
            TA.UI:Refresh(event)
        end
    end
end)

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

    print("|cFFFFD100ToonAge|r v" .. self.version .. " loaded. Type |cFFFFD100/ta|r to open.")
end

-- ── Slash command handler ─────────────────────────────────────────────
function TA:SlashCommand(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""

    if msg == "" or msg == "open" then
        self:ToggleUI()
    elseif msg == "gear" then
        self:OpenTab("gear")
    elseif msg == "talents" then
        self:OpenTab("talents")
    elseif msg == "rotation" then
        self:OpenTab("rotation")
    elseif msg == "prof" then
        self:OpenTab("professions")
    elseif msg == "pets" then
        self:OpenTab("pets")
    elseif msg == "weekly" then
        self:OpenTab("weekly")
    elseif msg == "options" then
        self:ToggleOptionsPanel()
    elseif msg == "layout" then
        -- Toggle between Unified HUD and Fragmented Windows from the command line
        self.db.useUnifiedUI = not self.db.useUnifiedUI
        self:ApplyLayout()
        local mode = self.db.useUnifiedUI and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
        print("|cFFFFD100[ToonAge]|r Layout: " .. mode)
    elseif msg:match("^toggle") then
        local modName = msg:match("^toggle%s+(%S+)")
        if not modName then
            print("|cFFFFD100[TA]|r Toggleable modules:")
            for name, enabled in pairs(self.db.modules or {}) do
                local status = enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
                print("  " .. name .. " — " .. status)
            end
            print("Usage: |cFFFFD100/ta toggle NavHud|r")
            return
        end
        -- Find the module (case-insensitive match)
        local matchedKey = nil
        for name in pairs(self.db.modules or {}) do
            if name:lower() == modName:lower() then matchedKey = name; break end
        end
        if not matchedKey then
            print("|cFFFFD100[TA]|r Unknown module: " .. modName)
            return
        end
        self.db.modules[matchedKey] = not self.db.modules[matchedKey]
        local status = self.db.modules[matchedKey] and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        print("|cFFFFD100[TA]|r Module " .. matchedKey .. ": " .. status .. "  (reload to apply)")
    elseif msg == "debug" then
        TA.debug = not TA.debug
        print("|cFFFFD100[TA]|r Debug mode: " .. (TA.debug and "ON" or "OFF"))
    elseif msg == "reset" then
        ToonAgeDB = nil
        print("|cFFFFD100[TA]|r Settings reset. Please reload UI (/reload).")
    else
        -- Dispatch to module-registered slash commands (e.g. /ta tracker, /ta guides)
        for _, mod in pairs(self.modules) do
            if mod.SlashCommands then
                local fn = mod.SlashCommands[msg]
                if fn then fn(mod); return end
            end
        end
        print("|cFFFFD100ToonAge|r commands:")
        print("  |cFFFFD100/ta|r — open/close")
        print("  |cFFFFD100/ta gear|r — gear tab")
        print("  |cFFFFD100/ta talents|r — talents tab")
        print("  |cFFFFD100/ta rotation|r — rotation tab")
        print("  |cFFFFD100/ta prof|r — professions tab")
        print("  |cFFFFD100/ta pets|r — pets tab")
        print("  |cFFFFD100/ta weekly|r — weekly tab")
        print("  |cFFFFD100/ta guides|r — list loaded guides")
        print("  |cFFFFD100/ta tracker|r — toggle guide tracker window")
        print("  |cFFFFD100/ta autoselect|r — re-run guide auto-selection")
        print("  |cFFFFD100/ta diag|r — diagnose why tracker shows no guide")
        print("  |cFFFFD100/ta arrow|r — toggle navigation arrow HUD")
        print("  |cFFFFD100/ta layout|r — toggle Unified HUD ↔ Fragmented Windows")
        print("  |cFFFFD100/ta options|r — open settings panel")
        print("  |cFFFFD100/ta reset|r — reset saved data")
    end
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
