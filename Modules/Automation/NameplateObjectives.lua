-- ToonAge/Modules/NameplateObjectives.lua
-- Shows quest objective icons on enemy nameplates (like AutoPilotReloaded).
-- When the player has a "Kill X" or "Loot Y from Z" objective, marks relevant
-- mobs with an icon + progress counter directly on their nameplate.
--
-- This is the #1 feature that makes Zygor/APR feel faster than manual play.

local TA = ToonAge
local U  = TA.Utils

local NP = {}
TA:RegisterModule("NameplateObjectives", NP)

NP.activeObjectives = {}  -- [npcName:lower()] = { questID, text, have, need, type }
NP.npcIDObjectives  = {}  -- [npcID] = { questID, text, have, need, type }
NP.platFrames       = {}  -- [nameplate] = our overlay frame
NP._dirty           = true

-- ── Objective scanner ─────────────────────────────────────────────────────────
-- Scans the quest log for active kill/collect objectives and maps them
-- to NPC IDs via the quest objective's target creature data.

local function ExtractNpcID(guid)
    if not guid then return nil end
    local npcID = guid:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)")
    return npcID and tonumber(npcID)
end

local function ScanObjectives()
    wipe(NP.activeObjectives)
    wipe(NP.npcIDObjectives)

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID then
            local questID = info.questID
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            if objectives then
                for objIdx, obj in ipairs(objectives) do
                    if not obj.finished and obj.numRequired and obj.numRequired > 0 then
                        local objType = obj.type  -- "monster", "item", "object", etc.
                        if objType == "monster" or objType == "item" then
                            local objData = {
                                questID = questID,
                                text    = obj.text,
                                have    = obj.numFulfilled or 0,
                                need    = obj.numRequired,
                                type    = objType,
                            }

                            -- Parse NPC name from objective text
                            local targetName = obj.text and obj.text:match("^(.-)%s+[%d]+/[%d]+")
                                            or obj.text and obj.text:match("^(.-)%s+%(")
                                            or obj.text
                            if targetName then
                                -- Remove common prefixes like "Slain: " or "Killed: "
                                targetName = targetName:gsub("^[Ss]lain:%s*", "")
                                targetName = targetName:gsub("^[Kk]illed?:%s*", "")
                                targetName = targetName:gsub("^[Cc]ollected?:%s*", "")
                                NP.activeObjectives[targetName:lower()] = objData
                            end

                            -- Also try to get NPC IDs from quest objective creature data
                            -- C_QuestLog stores creature IDs for monster-type objectives
                            if obj.type == "monster" and C_QuestLog.GetQuestObjectiveCreatures then
                                local creatures = C_QuestLog.GetQuestObjectiveCreatures(questID, objIdx)
                                if creatures then
                                    for _, creatureID in ipairs(creatures) do
                                        NP.npcIDObjectives[creatureID] = objData
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ── Nameplate overlay ─────────────────────────────────────────────────────────

local MARKER_SIZE = 28   -- large raid-marker-style icon above nameplate
local COUNTER_SIZE = 14  -- progress counter font

-- Raid marker textures (Lucky Charms style) from the built-in atlas
local KILL_MARKER = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"  -- X (cross)
local LOOT_MARKER = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"  -- Star

local function CreateOverlay(nameplate)
    local f = CreateFrame("Frame", nil, nameplate)
    f:SetSize(MARKER_SIZE + 4, MARKER_SIZE + 18)
    f:SetPoint("BOTTOM", nameplate, "TOP", 0, 2)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(nameplate:GetFrameLevel() + 10)

    -- Large raid marker icon (skull/star) — centered, floats above the plate
    local marker = f:CreateTexture(nil, "ARTWORK")
    marker:SetSize(MARKER_SIZE, MARKER_SIZE)
    marker:SetPoint("TOP", f, "TOP", 0, 0)
    f.marker = marker

    -- Progress counter below the marker: "3/5"
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, COUNTER_SIZE, "OUTLINE")
    text:SetPoint("TOP", marker, "BOTTOM", 0, -1)
    text:SetTextColor(1, 1, 1, 1)
    f.text = text

    -- Subtle glow/pulse animation on the marker
    local glow = f:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(MARKER_SIZE + 12, MARKER_SIZE + 12)
    glow:SetPoint("CENTER", marker, "CENTER", 0, 0)
    glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    glow:SetVertexColor(1, 0.82, 0, 0.15)
    glow:SetBlendMode("ADD")
    f.glow = glow

    f:Hide()
    return f
end

local function UpdatePlate(nameplate, unitToken)
    if not unitToken or not UnitExists(unitToken) then return end
    if UnitIsDead(unitToken) then
        if NP.platFrames[nameplate] then NP.platFrames[nameplate]:Hide() end
        return
    end
    if not UnitCanAttack("player", unitToken) then
        if NP.platFrames[nameplate] then NP.platFrames[nameplate]:Hide() end
        return
    end

    -- METHOD 1: Match by NPC ID from GUID (most reliable, works even with PTR name mismatches)
    local guid = UnitGUID(unitToken)
    local npcID = ExtractNpcID(guid)
    local objData = npcID and NP.npcIDObjectives[npcID]

    -- METHOD 2: Fall back to name matching
    if not objData then
        local name = UnitName(unitToken)
        if name then
            objData = NP.activeObjectives[name:lower()]
            -- Partial match (some objectives truncate or prefix names)
            if not objData then
                for objName, data in pairs(NP.activeObjectives) do
                    if name:lower():find(objName, 1, true) or objName:find(name:lower(), 1, true) then
                        objData = data
                        break
                    end
                end
            end
        end
    end

    if objData then
        local overlay = NP.platFrames[nameplate]
        if not overlay then
            overlay = CreateOverlay(nameplate)
            NP.platFrames[nameplate] = overlay
        end

        -- Skull for kills, Star for loot/items
        if objData.type == "item" then
            overlay.marker:SetTexture(LOOT_MARKER)
            overlay.glow:SetVertexColor(1, 0.85, 0, 0.15)
        else
            overlay.marker:SetTexture(KILL_MARKER)
            overlay.glow:SetVertexColor(0.9, 0.2, 0.1, 0.15)
        end

        -- Progress text with color: white when incomplete, green when almost done
        local pct = objData.have / objData.need
        if pct >= 0.8 then
            overlay.text:SetTextColor(0.30, 0.92, 0.40, 1)  -- green = almost done
        elseif pct >= 0.5 then
            overlay.text:SetTextColor(1, 0.82, 0, 1)         -- gold = halfway
        else
            overlay.text:SetTextColor(1, 1, 1, 1)             -- white = still need more
        end
        overlay.text:SetText(string.format("%d/%d", objData.have, objData.need))

        overlay:Show()
    else
        if NP.platFrames[nameplate] then
            NP.platFrames[nameplate]:Hide()
        end
    end
end

-- ── Events ────────────────────────────────────────────────────────────────────

function NP:OnEvent(event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unitToken = ...
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if nameplate then
            UpdatePlate(nameplate, unitToken)
        end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unitToken = ...
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if nameplate and NP.platFrames[nameplate] then
            NP.platFrames[nameplate]:Hide()
        end

    elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_ACCEPTED"
        or event == "QUEST_TURNED_IN" or event == "UNIT_QUEST_LOG_CHANGED" then
        -- Re-scan objectives and refresh all visible plates
        ScanObjectives()
        self:RefreshAllPlates()
    end
end

function NP:RefreshAllPlates()
    -- Update all currently visible nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate then
                UpdatePlate(nameplate, unit)
            end
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function NP:Init()
    -- Register nameplate events on the main event frame
    TA.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    TA.eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

    -- Initial objective scan (delayed to let quest log load)
    C_Timer.After(2, function()
        ScanObjectives()
        NP:RefreshAllPlates()
    end)
end

NP.SlashCommands = {}
