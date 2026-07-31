-- ToonAge/Modules/DungeonTalents.lua
-- Per-Dungeon Talent Switching — detects dungeon entry and recommends
-- the optimal talent build from BetterTalents.BuildData or TA.Data.Talents.
-- Shows a banner/popup prompting the player to switch loadouts.

local TA = ToonAge
local U  = TA.Utils

local DungeonTalents = {}
TA:RegisterModule("DungeonTalents", DungeonTalents)

-- ── State ─────────────────────────────────────────────────────────────────────
DungeonTalents.bannerFrame   = nil
DungeonTalents.bannerTimer   = nil
DungeonTalents.lastInstance  = nil

-- ── OnEvent ───────────────────────────────────────────────────────────────────
function DungeonTalents:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        self:CheckDungeonTalents()
    end
end

-- ── Core check ────────────────────────────────────────────────────────────────
function DungeonTalents:CheckDungeonTalents()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return end
    if instanceType ~= "party" and instanceType ~= "raid" then return end

    local instanceName = GetInstanceInfo()
    if not instanceName or instanceName == "" then return end

    -- Avoid re-prompting for the same instance
    if self.lastInstance == instanceName then return end
    self.lastInstance = instanceName

    -- Check dismissed state
    if TA.charDB and TA.charDB.dungeonTalents
       and TA.charDB.dungeonTalents.dismissed
       and TA.charDB.dungeonTalents.dismissed[instanceName] then
        return
    end

    -- Get current spec
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID, specName = GetSpecializationInfo(specIndex)
    if not specName then return end

    -- ── Look up recommended build ────────────────────────────────────────
    local recommendedString = nil
    local buildLabel = nil

    -- Source 1: BetterTalents addon (if loaded)
    local BT = _G["BetterTalents"]
    local BTData = BT and BT.BuildData
    if not BTData then
        -- Try the addon namespace approach
        local _, btAddon = pcall(function()
            return U.GetAddOnTitle("BetterTalents")
        end)
        if type(btAddon) == "table" and btAddon.BuildData then
            BTData = btAddon.BuildData
        end
    end

    if BTData and BTData[specName] then
        local specBuilds = BTData[specName]
        -- Check dungeon-specific build
        if specBuilds.mplus_dungeons and specBuilds.mplus_dungeons[instanceName] then
            recommendedString = specBuilds.mplus_dungeons[instanceName]
            buildLabel = instanceName .. " (M+)"
        elseif instanceType == "raid" and specBuilds.raid_mythic then
            recommendedString = specBuilds.raid_mythic
            buildLabel = "Raid Mythic"
        elseif specBuilds.mplus_overall then
            -- Fallback to general M+ build
            recommendedString = specBuilds.mplus_overall
            buildLabel = "M+ Overall"
        end
    end

    -- Source 2: ToonAge's own talent data
    if not recommendedString then
        local TAData = TA.Data and TA.Data.Talents
        if TAData and TAData.GetBySpecID then
            local ok, specData = pcall(TAData.GetBySpecID, TAData, specID)
            if ok and specData and specData.builds and specData.builds.mplus then
                recommendedString = specData.builds.mplus.string
                buildLabel = specData.builds.mplus.name or "M+ Build"
            end
        end
    end

    if not recommendedString or recommendedString == "" then return end

    -- ── Compare with current loadout ─────────────────────────────────────
    local currentString = nil
    if C_Traits and C_Traits.GenerateImportString then
        local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                         and C_ClassTalents.GetActiveConfigID()
        if configID then
            local ok, str = pcall(C_Traits.GenerateImportString, configID)
            if ok and str then currentString = str end
        end
    end

    -- If we can't get current string, always offer the recommended one
    if currentString and currentString == recommendedString then
        return  -- Already on the correct build
    end

    -- ── Show prompt ──────────────────────────────────────────────────────
    self:ShowSwitchPrompt(instanceName, buildLabel, recommendedString)
end

-- ── Banner / Prompt ───────────────────────────────────────────────────────────
function DungeonTalents:ShowSwitchPrompt(instanceName, buildLabel, importString)
    -- Use StaticPopup for a clean, Blizzard-native feel
    StaticPopupDialogs["TOONAGE_TALENT_SWITCH"] = {
        text = string.format(
            "|cFFFFD100ToonAge|r\n\nYou entered |cFFFFD100%s|r.\n\nRecommended build: |cFF4AFF7A%s|r\n\nCopy talent string to clipboard?",
            instanceName, buildLabel or "Dungeon Build"
        ),
        button1 = "Copy & Apply",
        button2 = "Dismiss",
        OnAccept = function()
            -- Copy to clipboard for paste into talent UI
            if CopyToClipboard then
                CopyToClipboard(importString)
                TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A[ToonAge]|r Talent string copied! Open Talents (N) → Import → Paste.")
            end

            -- Also try direct API application (may fail if protected/not supported)
            if C_ClassTalents and C_ClassTalents.ImportLoadout then
                local ok, err = pcall(function()
                    C_ClassTalents.ImportLoadout(importString)
                end)
                if ok then
                    TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A[ToonAge]|r Loadout imported. Click 'Apply' in your talent frame.")
                end
            end
        end,
        OnCancel = function()
            -- Save dismissed state for this instance
            DungeonTalents:DismissForInstance(instanceName)
        end,
        timeout = 30,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("TOONAGE_TALENT_SWITCH")
end

function DungeonTalents:DismissForInstance(instanceName)
    if not TA.charDB then return end
    TA.charDB.dungeonTalents = TA.charDB.dungeonTalents or {}
    TA.charDB.dungeonTalents.dismissed = TA.charDB.dungeonTalents.dismissed or {}
    TA.charDB.dungeonTalents.dismissed[instanceName] = true
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function DungeonTalents:Init()
    -- ZONE_CHANGED_NEW_AREA is already in PERSISTENT_EVENTS in Init.lua
    -- Just ensure our charDB table exists
    if TA.charDB then
        TA.charDB.dungeonTalents = TA.charDB.dungeonTalents or { dismissed = {} }
    end
end

-- ── Slash command: reset dismissed state ──────────────────────────────────────
DungeonTalents.SlashCommands = {
    ["talents-reset"] = function(self)
        if TA.charDB then
            TA.charDB.dungeonTalents = { dismissed = {} }
        end
        self.lastInstance = nil
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Dungeon talent dismiss list cleared.")
    end,
}
