-- ToonAge/Modules/AutoMount.lua
-- Automatically mounts the player after combat ends (PLAYER_REGEN_ENABLED).
--
-- Design decisions:
--   • Opt-in: enabled by default but togglable via /ta automount.
--   • Configurable delay (default 1.5s) to avoid conflicts with post-combat
--     NPC interactions, quest popups, and loot windows.
--   • Cancels pending mount attempt if player re-enters combat before the
--     timer fires (PLAYER_REGEN_DISABLED).
--   • Prefers dragonriding-capable mounts in zones that support dynamic flight;
--     falls back to random favorite mount via C_MountJournal.SummonByID(0).
--   • Extensive pre-mount checks: dead/ghost, vehicle, indoors, swimming,
--     already mounted, casting/channeling, battleground/arena.
--   • Uses pcall around mount journal API calls for resilience against
--     tainted execution contexts or API changes between patches.

local TA = ToonAge
local U  = TA.Utils

local AutoMount = {}
TA:RegisterModule("AutoMount", AutoMount)

-- ── Constants ─────────────────────────────────────────────────────────────────

local DEFAULT_DELAY = 1.5  -- seconds after combat ends before mounting

-- ── Internal state ────────────────────────────────────────────────────────────

local pendingTimer = nil   -- reference to the C_Timer callback handle (cancelable)

-- ── Database helpers ──────────────────────────────────────────────────────────

--- Ensures the autoMount settings table exists in TA.db and returns it.
local function GetSettings()
    if not TA.db then return nil end
    if not TA.db.autoMount then
        TA.db.autoMount = { enabled = true, delay = DEFAULT_DELAY }
    end
    return TA.db.autoMount
end

local function IsEnabled()
    local settings = GetSettings()
    return settings and settings.enabled
end

local function GetDelay()
    local settings = GetSettings()
    return (settings and settings.delay) or DEFAULT_DELAY
end

-- ── Pre-mount condition checks ────────────────────────────────────────────────

--- Returns true if the player is in a PvP instance (battleground or arena)
--- where auto-mounting would be inappropriate.
local function InPvPInstance()
    local _, iType = IsInInstance()
    return iType == "pvp" or iType == "arena"
end

--- Returns true if the player is currently casting or channeling a spell.
local function IsCastingOrChanneling()
    local casting = UnitCastingInfo("player")
    local channeling = UnitChannelInfo("player")
    return (casting ~= nil) or (channeling ~= nil)
end

--- Master check: returns true only if all conditions are satisfied for mounting.
local function CanMount()
    -- Player must be alive
    if UnitIsDeadOrGhost("player") then return false end

    -- Not in a vehicle (quest vehicles, multi-passenger mounts, etc.)
    if UnitInVehicle("player") then return false end

    -- Not indoors (mounting indoors is blocked by the client anyway)
    if IsIndoors() then return false end

    -- Not swimming/submerged
    if IsSubmerged() then return false end

    -- Not already mounted
    if IsMounted() then return false end

    -- Double-check: not in combat (timer might fire right at the edge)
    if InCombatLockdown() then return false end

    -- Not casting or channeling (don't interrupt player actions)
    if IsCastingOrChanneling() then return false end

    -- Not in a battleground/arena
    if InPvPInstance() then return false end

    return true
end

-- ── Mount selection logic ─────────────────────────────────────────────────────

--- Attempts to find and summon a dragonriding-capable mount.
--- Returns true if a dragonriding mount was summoned, false otherwise.
local function TrySummonDragonridingMount()
    -- C_MountJournal.GetCollectedDragonridingMounts returns an array of
    -- mount IDs that support dynamic flight. Available since Dragonflight.
    if not C_MountJournal or not C_MountJournal.GetCollectedDragonridingMounts then
        return false
    end

    local ok, mounts = pcall(C_MountJournal.GetCollectedDragonridingMounts)
    if not ok or not mounts or #mounts == 0 then
        return false
    end

    -- Pick a random dragonriding mount from the collected list
    local mountID = mounts[math.random(#mounts)]
    local summonOk, summonErr = pcall(C_MountJournal.SummonByID, mountID)
    if not summonOk then
        if TA.debug then
            print("|cFFFF4444[TA AutoMount]|r Dragonriding summon failed: " .. tostring(summonErr))
        end
        return false
    end

    return true
end

--- Checks whether the current zone supports dynamic flight (dragonriding).
local function IsDragonridingZone()
    -- C_MountJournal.IsDragonridingUnlocked or checking if dynamic flight
    -- is available in the current area. The most reliable approach is checking
    -- whether the player CAN use dynamic flight mounts here.
    if C_MountJournal and C_MountJournal.GetCollectedDragonridingMounts then
        local ok, mounts = pcall(C_MountJournal.GetCollectedDragonridingMounts)
        if ok and mounts and #mounts > 0 then
            -- Check if dynamic flight is actually usable in this zone.
            -- If the mount is usable, the zone supports it.
            local mountID = mounts[1]
            if C_MountJournal.GetMountUsabilityByID then
                local usableOk, isUsable = pcall(C_MountJournal.GetMountUsabilityByID, mountID, false)
                if usableOk and isUsable then
                    return true
                end
            end
            -- Fallback: check if the first dragonriding mount is flagged usable
            -- via the standard mount info API
            if C_MountJournal.GetMountInfoByID then
                local infoOk, name, spellID, icon, isActive, isUsable = pcall(
                    C_MountJournal.GetMountInfoByID, mountID
                )
                if infoOk and isUsable then
                    return true
                end
            end
        end
    end
    return false
end

--- Main mount action: selects the appropriate mount and summons it.
local function DoMount()
    -- Final safety check right before summoning
    if not CanMount() then return end

    -- Prefer dragonriding mounts in eligible zones
    if IsDragonridingZone() then
        if TrySummonDragonridingMount() then
            return
        end
    end

    -- Fallback: summon a random favorite mount (ID 0 = random favorite)
    local ok, err = pcall(C_MountJournal.SummonByID, 0)
    if not ok then
        if TA.debug then
            print("|cFFFF4444[TA AutoMount]|r SummonByID(0) failed: " .. tostring(err))
        end
    end
end

-- ── Timer management ──────────────────────────────────────────────────────────

--- Cancels any pending mount timer.
local function CancelPendingMount()
    if pendingTimer then
        -- C_Timer callbacks can be cancelled by setting a flag;
        -- the callback checks this flag before executing.
        pendingTimer.cancelled = true
        pendingTimer = nil
    end
end

--- Schedules a mount attempt after the configured delay.
local function ScheduleMount()
    CancelPendingMount()

    local delay = GetDelay()

    -- Create a trackable timer handle
    local handle = { cancelled = false }
    pendingTimer = handle

    C_Timer.After(delay, function()
        -- If this timer was cancelled (e.g., player re-entered combat), bail
        if handle.cancelled then return end
        pendingTimer = nil

        -- Verify the feature is still enabled (could have been toggled mid-timer)
        if not IsEnabled() then return end

        DoMount()
    end)
end

-- ── Event handling ────────────────────────────────────────────────────────────

function AutoMount:OnEvent(event, ...)
    if not IsEnabled() then return end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended: schedule mount after delay
        ScheduleMount()

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Combat started: cancel any pending mount attempt
        CancelPendingMount()
    end
end

-- ── Slash command integration ─────────────────────────────────────────────────

AutoMount.SlashCommands = {
    ["automount"] = function(self)
        local settings = GetSettings()
        if not settings then
            print("|cFFFF4444[TA AutoMount]|r Settings unavailable (DB not loaded).")
            return
        end
        settings.enabled = not settings.enabled
        local status = settings.enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        print("|cFFFFD100[TA AutoMount]|r Auto-mount after combat: " .. status)
    end,
}

-- ── Init ──────────────────────────────────────────────────────────────────────

function AutoMount:Init()
    -- Register events needed by this module
    TA.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    TA.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

    -- Ensure settings exist in the database
    GetSettings()

    if TA.debug then
        local settings = GetSettings()
        print("|cFFFFD100[TA]|r AutoMount module loaded. Enabled: "
            .. tostring(settings and settings.enabled)
            .. ", Delay: " .. tostring(settings and settings.delay) .. "s")
    end
end
