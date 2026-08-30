-- ToonAge/Modules/Farming/ProfQuesting.lua
-- Profession-Integrated Questing: while running the guide route, surfaces
-- gathering nodes on-path and flags quest rewards that are profession reagents.
-- Zero-detour opportunism.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local PQ = {}
TA:RegisterModule("ProfQuesting", PQ)

-- ── State ─────────────────────────────────────────────────────────────────────
PQ.playerProfessions = {} -- { [profName] = skillLevel }
PQ.trackingEnabled = {} -- { [profType] = true } (herbs, mining, etc.)

-- ── Profession detection ──────────────────────────────────────────────────────

function PQ:RefreshProfessions()
    wipe(self.playerProfessions)
    wipe(self.trackingEnabled)

    local prof1, prof2 = GetProfessions()
    local profs = { prof1, prof2 }

    for _, idx in ipairs(profs) do
        if idx then
            local name, _, skillLevel = GetProfessionInfo(idx)
            if name then
                self.playerProfessions[name] = skillLevel
                -- Detect gathering professions for node tracking
                if name == "Herbalism" or name:find("Herb") then
                    self.trackingEnabled["herbs"] = true
                elseif name == "Mining" or name:find("Mining") then
                    self.trackingEnabled["mining"] = true
                elseif name == "Skinning" or name:find("Skinning") then
                    self.trackingEnabled["skinning"] = true
                end
            end
        end
    end
end

-- ── Quest reward analysis ─────────────────────────────────────────────────────

--- Check if a quest reward item is a crafting reagent for the player's professions.
--- Called during QUEST_COMPLETE when multiple rewards are available.
--- @return number|nil preferredIndex — 1-based reward index, or nil if no match
function PQ:AnalyzeQuestRewards()
    local numChoices = GetNumQuestChoices()
    if numChoices <= 1 then
        return nil
    end

    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            local _, _, _, _, _, itemType, itemSubType = C_Item.GetItemInfo(link)
            -- Check if it's a tradeskill material
            if itemType == "Tradeskill" or itemType == "Trade Goods" then
                -- It's a reagent — check if it matches our professions
                -- (Any reagent is valuable if we have a crafting profession)
                local hasCraftProf = false
                for name in pairs(self.playerProfessions) do
                    if name ~= "Herbalism" and name ~= "Mining" and name ~= "Skinning" then
                        hasCraftProf = true
                        break
                    end
                end
                if hasCraftProf then
                    return i
                end
            end
        end
    end

    return nil
end

--- Surface a notification about nearby gathering opportunities.
--- Checks if the player has tracking enabled and provides contextual tips.
--- @return string|nil tip
function PQ:GetGatheringTip()
    if not next(self.trackingEnabled) then
        return nil
    end

    -- Check if minimap tracking is enabled for our professions
    local tips = {}
    if self.trackingEnabled["herbs"] then
        -- The NavHud minimap already shows herb nodes via tracking blips
        -- Just remind the player to enable tracking if they haven't
        local numTracking = C_Minimap.GetNumTrackingTypes and C_Minimap.GetNumTrackingTypes() or 0
        for i = 1, numTracking do
            local info = C_Minimap.GetTrackingInfo(i)
            if info and info.name and (info.name:find("Herb") or info.name:find("Flower")) and not info.active then
                return "|cFF4AFF7A🌿 Enable herb tracking on minimap — nodes show on NavHud!|r"
            end
        end
    end
    if self.trackingEnabled["mining"] then
        local numTracking = C_Minimap.GetNumTrackingTypes and C_Minimap.GetNumTrackingTypes() or 0
        for i = 1, numTracking do
            local info = C_Minimap.GetTrackingInfo(i)
            if info and info.name and info.name:find("Mining") and not info.active then
                return "|cFFFFD100⛏ Enable mining tracking — ore nodes show on NavHud!|r"
            end
        end
    end

    return nil
end

-- ── Event handling ────────────────────────────────────────────────────────────

function PQ:OnEvent(event, ...)
    if event == "SKILL_LINES_CHANGED" then
        self:RefreshProfessions()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function PQ:Init()
    self:RefreshProfessions()

    -- Show gathering tip on first login if tracking isn't enabled
    C_Timer.After(8, function()
        local tip = PQ:GetGatheringTip()
        if tip then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r " .. tip)
        end
    end)
end

PQ.SlashCommands = {}
