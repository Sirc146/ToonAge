-- ToonAge/Modules/AutoMount.lua (Classic — MoP 50504)
-- Automatically mounts the player after combat ends (PLAYER_REGEN_ENABLED).
--
-- Classic adaptations:
--   • No dragonriding / dynamic flight
--   • No C_MountJournal.SummonByID(0) (random favorite shorthand)
--   • Uses C_MountJournal.GetMountIDs() + GetMountInfoByID() to find a usable
--     mount, then C_MountJournal.SummonByID(mountID).
--   • Falls back to GetCompanionInfo/CallCompanion("MOUNT", ...) if
--     C_MountJournal doesn't exist (very early Classic clients).
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge
local U  = TA.Utils

local AutoMount = {}
TA:RegisterModule("AutoMount", AutoMount)

-- ── Constants ─────────────────────────────────────────────────────────────────

local DEFAULT_DELAY = 1.5  -- seconds after combat ends before mounting

-- ── Internal state ────────────────────────────────────────────────────────────

local pendingTimer = nil

-- ── Database helpers ──────────────────────────────────────────────────────────

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

local function InPvPInstance()
    local _, iType = IsInInstance()
    return iType == "pvp" or iType == "arena"
end

local function IsCastingOrChanneling()
    local casting = UnitCastingInfo("player")
    local channeling = UnitChannelInfo("player")
    return (casting ~= nil) or (channeling ~= nil)
end

--- Master check: returns true only if all conditions are satisfied for mounting.
local function CanMount()
    if UnitIsDeadOrGhost("player") then return false end
    if UnitInVehicle and UnitInVehicle("player") then return false end
    if IsIndoors() then return false end
    if IsSubmerged and IsSubmerged() then return false end
    if IsMounted() then return false end
    if InCombatLockdown() then return false end
    if IsCastingOrChanneling() then return false end
    if InPvPInstance() then return false end
    return true
end

-- ── Mount selection logic ─────────────────────────────────────────────────────

--- Try to find and summon a usable mount via C_MountJournal.
--- Returns true if a mount was successfully summoned.
local function TrySummonViaMountJournal()
    if not C_MountJournal then return false end
    if not C_MountJournal.GetMountIDs then return false end

    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs or #mountIDs == 0 then return false end

    -- Collect usable mounts
    local usable = {}
    for _, mountID in ipairs(mountIDs) do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
              isFactionSpecific, faction, shouldHideOnChar, isCollected
            = C_MountJournal.GetMountInfoByID(mountID)

        if isCollected and isUsable then
            -- Prefer favorites if any exist
            if isFavorite then
                table.insert(usable, 1, mountID)  -- push favorites to front
            else
                table.insert(usable, mountID)
            end
        end
    end

    if #usable == 0 then return false end

    -- Pick a random mount (preferring favorites at the front of the list)
    -- If we have favorites, pick from them; otherwise from all usable
    local favoriteCount = 0
    for _, mountID in ipairs(usable) do
        local _, _, _, _, _, _, isFavorite = C_MountJournal.GetMountInfoByID(mountID)
        if isFavorite then favoriteCount = favoriteCount + 1
        else break end  -- favorites are at front, stop counting
    end

    local pickFrom = favoriteCount > 0 and favoriteCount or #usable
    local chosen = usable[math.random(1, pickFrom)]

    local ok, err = pcall(C_MountJournal.SummonByID, chosen)
    if not ok then
        if TA.debug then
            TA:Raw(TA.LOG.ERROR, "|cFFFF4444[TA AutoMount]|r SummonByID failed: " .. tostring(err))
        end
        return false
    end
    return true
end

--- Fallback: Use the legacy Companion API (pre-MoP / very early Classic).
--- This API uses GetCompanionInfo("MOUNT", index) and CallCompanion("MOUNT", index).
local function TrySummonViaCompanionAPI()
    if not GetNumCompanions then return false end

    local numMounts = GetNumCompanions("MOUNT") or 0
    if numMounts == 0 then return false end

    -- Collect usable mounts
    local usable = {}
    for i = 1, numMounts do
        local _, name, spellID, icon, active = GetCompanionInfo("MOUNT", i)
        if spellID and IsUsableSpell(spellID) then
            table.insert(usable, i)
        end
    end

    if #usable == 0 then
        -- Just pick a random one if we can't determine usability
        usable = {}
        for i = 1, numMounts do
            table.insert(usable, i)
        end
    end

    if #usable == 0 then return false end

    local chosen = usable[math.random(1, #usable)]
    CallCompanion("MOUNT", chosen)
    return true
end

--- Main mount action: selects the appropriate mount and summons it.
local function DoMount()
    if not CanMount() then return end

    -- Try C_MountJournal first (available in MoP+)
    if TrySummonViaMountJournal() then return end

    -- Fallback to legacy Companion API
    if TrySummonViaCompanionAPI() then return end

    if TA.debug then
        TA:Raw(TA.LOG.WARN, "|cFFFFD100[TA AutoMount]|r No usable mount found.")
    end
end

-- ── Timer management ──────────────────────────────────────────────────────────

local function CancelPendingMount()
    if pendingTimer then
        pendingTimer.cancelled = true
        pendingTimer = nil
    end
end

local function ScheduleMount()
    CancelPendingMount()

    local delay = GetDelay()
    local handle = { cancelled = false }
    pendingTimer = handle

    C_Timer.After(delay, function()
        if handle.cancelled then return end
        pendingTimer = nil
        if not IsEnabled() then return end
        DoMount()
    end)
end

-- ── Event handling ────────────────────────────────────────────────────────────

function AutoMount:OnEvent(event, ...)
    if not IsEnabled() then return end

    if event == "PLAYER_REGEN_ENABLED" then
        ScheduleMount()
    elseif event == "PLAYER_REGEN_DISABLED" then
        CancelPendingMount()
    end
end

-- ── Slash command ─────────────────────────────────────────────────────────────

AutoMount.SlashCommands = {
    ["automount"] = function(self)
        local settings = GetSettings()
        if not settings then
            TA:Raw(TA.LOG.ERROR, "|cFFFF4444[TA AutoMount]|r Settings unavailable (DB not loaded).")
            return
        end
        settings.enabled = not settings.enabled
        local status = settings.enabled and "|cFF4AFF7AON|r" or "|cFFFF4444OFF|r"
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[TA AutoMount]|r Auto-mount after combat: " .. status)
    end,
}

-- ── Init ──────────────────────────────────────────────────────────────────────

function AutoMount:Init()
    TA.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    TA.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

    GetSettings()

    if TA.debug then
        local settings = GetSettings()
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r AutoMount module loaded. Enabled: "
            .. tostring(settings and settings.enabled)
            .. ", Delay: " .. tostring(settings and settings.delay) .. "s")
    end
end
