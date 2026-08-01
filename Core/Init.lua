-- CharacterAdvisor/Core/Init.lua
-- Addon object, event registration, SavedVariables, module system

local ADDON_NAME = "CharacterAdvisor"
local ADDON_VERSION = "1.0.0"

-- Create the global addon table
CharacterAdvisor = CharacterAdvisor or {}
local CA = CharacterAdvisor

-- Version
CA.version = ADDON_VERSION

-- Module registry: modules register themselves here
CA.modules = {}

-- Event frame
CA.eventFrame = CreateFrame("Frame", "CharacterAdvisorEventFrame")

-- Default saved variables schema
local DB_DEFAULTS = {
    minimap = { minimized = false, position = 45 },
    lastTab  = "character",
    char     = {},  -- per-character data keyed by "Name-Server"
}

-- ── SavedVariables ────────────────────────────────────────────────────
function CA:InitDB()
    -- CharacterAdvisorDB is set by WoW from SavedVariables on login
    CharacterAdvisorDB = CharacterAdvisorDB or {}
    local db = CharacterAdvisorDB

    -- Apply defaults for any missing keys
    for k, v in pairs(DB_DEFAULTS) do
        if db[k] == nil then
            db[k] = v
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
function CA:RegisterModule(name, module)
    self.modules[name] = module
    if CA.debug then
        print("|cFFFFD100[CA]|r Module registered: " .. name)
    end
end

function CA:GetModule(name)
    return self.modules[name]
end

function CA:InitModules()
    for name, mod in pairs(self.modules) do
        if mod.Init then
            local ok, err = pcall(mod.Init, mod)
            if not ok then
                print("|cFFFF4444[CA] Error initialising module " .. name .. ":|r " .. tostring(err))
            end
        end
    end
end

function CA:UpdateModules(event, ...)
    for name, mod in pairs(self.modules) do
        if mod.OnEvent then
            local ok, err = pcall(mod.OnEvent, mod, event, ...)
            if not ok then
                print("|cFFFF4444[CA] Module " .. name .. " OnEvent error:|r " .. tostring(err))
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
    "SKILL_LINES_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE",
    "GROUP_ROSTER_UPDATE",
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PET_STABLE_UPDATE",
    "CHAT_MSG_SYSTEM",
}

-- Register one-shot boot events
CA.eventFrame:RegisterEvent("ADDON_LOADED")
CA.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Register persistent events
for _, event in ipairs(PERSISTENT_EVENTS) do
    CA.eventFrame:RegisterEvent(event)
end

CA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    local CA  = CharacterAdvisor
    local arg1 = ...

    if event == "ADDON_LOADED" then
        -- Only act on our own addon load; unregister immediately
        if arg1 == "CharacterAdvisor" then
            self:UnregisterEvent("ADDON_LOADED")
            -- Pre-init: nothing to do yet — SavedVariables not available yet
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- SavedVariables are now guaranteed loaded — safe to init DB and UI
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        CA:OnLogin()

    else
        -- All persistent events: update modules then refresh UI if open
        CA:UpdateModules(event, ...)
        if CA.UI and CA.UI:IsVisible() then
            CA.UI:Refresh(event)
        end
    end
end)

-- ── Login sequence ────────────────────────────────────────────────────
function CA:OnLogin()
    self:InitDB()
    self:InitModules()
    self:InitUI()       -- defined in Core/UI.lua
    self:InitMinimap()  -- defined in Core/MinimapButton.lua

    -- Slash commands
    SLASH_CHARACTERADVISOR1 = "/ca"
    SLASH_CHARACTERADVISOR2 = "/characteradvisor"
    SlashCmdList["CHARACTERADVISOR"] = function(msg)
        CA:SlashCommand(msg)
    end

    print("|cFFFFD100Character Advisor|r v" .. self.version .. " loaded. Type |cFFFFD100/ca|r to open.")
end

-- ── Slash command handler ─────────────────────────────────────────────
function CA:SlashCommand(msg)
    msg = msg and msg:lower():trim() or ""

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
    elseif msg == "debug" then
        CA.debug = not CA.debug
        print("|cFFFFD100[CA]|r Debug mode: " .. (CA.debug and "ON" or "OFF"))
    elseif msg == "reset" then
        CharacterAdvisorDB = nil
        print("|cFFFFD100[CA]|r Settings reset. Please reload UI (/reload).")
    else
        print("|cFFFFD100Character Advisor|r commands:")
        print("  |cFFFFD100/ca|r — open/close")
        print("  |cFFFFD100/ca gear|r — gear tab")
        print("  |cFFFFD100/ca talents|r — talents tab")
        print("  |cFFFFD100/ca rotation|r — rotation tab")
        print("  |cFFFFD100/ca prof|r — professions tab")
        print("  |cFFFFD100/ca pets|r — pets tab")
        print("  |cFFFFD100/ca weekly|r — weekly tab")
        print("  |cFFFFD100/ca reset|r — reset saved data")
    end
end

function CA:ToggleUI()
    if self.UI then
        if self.UI:IsVisible() then
            self.UI:Hide()
        else
            self.UI:Show()
        end
    end
end

function CA:OpenTab(tabName)
    if self.UI then
        self.UI:Show()
        self.UI:SetTab(tabName)
    end
end
