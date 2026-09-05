-- ToonAge/Modules/RoleMorph.lua
-- Role-aware environment morphing: camera distance, threat nameplates,
-- heirloom alerts, pre-pull audit, healer triage.

local TA = ToonAge
local U  = TA.Utils
local SW = TA.Data.StatWeights

local RM = {}
TA:RegisterModule("RoleMorph", RM)

-- ══════════════════════════════════════════════════════════════════════════════
-- §1 — CVar Camera Morphing
-- ══════════════════════════════════════════════════════════════════════════════
-- Ranged specs need wide battlefield view. Melee/tanks need tighter camera.

local CAMERA_RANGED = "2.6"   -- max zoom for ranged
local CAMERA_MELEE  = "1.9"   -- tighter for melee/tank

local function IsRangedSpec(specID)
    -- Ranged DPS + Healers = want far camera
    local data = SW and SW[specID]
    if not data then return false end
    if data.role == "HEALER" then return true end
    if data.primary == "INT" and data.role == "DAMAGER" then return true end
    -- Hunters (except Survival 255)
    if specID == 253 or specID == 254 then return true end
    -- Evoker DPS
    if specID == 1467 or specID == 1473 then return true end
    return false
end

function RM:ApplyCameraProfile()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID = GetSpecializationInfo(specIndex)
    if not specID then return end

    local zoom = IsRangedSpec(specID) and CAMERA_RANGED or CAMERA_MELEE
    pcall(C_CVar.SetCVar, "cameraDistanceMaxZoomFactor", zoom)

    if TA.debug then
        TA:Raw(TA.LOG.INFO, string.format("|cFFFFD100[TA]|r Camera → %s (spec %d)", zoom, specID))
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §2 — Heirloom Cap Alert
-- ══════════════════════════════════════════════════════════════════════════════
-- Heirlooms (quality 7) stop scaling at specific level caps.
-- Alert when player levels past the cap so they know to replace the gear.

local HEIRLOOM_QUALITY = 7
-- Heirloom upgrade tier caps (approximate — covers most cases)
local HEIRLOOM_CAPS = { 35, 40, 45, 50, 60, 70, 80 }

local function GetHeirloomCap(itemLink)
    if not itemLink then return 999 end
    -- Check if item has heirloom quality
    local _, _, quality = GetItemInfo(itemLink)
    if quality ~= HEIRLOOM_QUALITY then return 999 end

    -- Heirloom effective ilvl stops increasing past its cap.
    -- We detect this by checking if the ilvl matches what it would be at cap.
    -- Simpler approach: check the item's max level via tooltip scan or
    -- C_Heirloom API if available.
    if C_Heirloom and C_Heirloom.GetHeirloomMaxUpgradeLevel then
        local itemID = GetItemInfoInstant(itemLink)
        if itemID then
            local maxLevel = C_Heirloom.GetHeirloomMaxUpgradeLevel(itemID)
            if maxLevel then return maxLevel end
        end
    end

    -- Fallback: assume current highest cap
    return 80
end

function RM:CheckHeirlooms()
    local playerLevel = UnitLevel("player") or 1
    local deadSlots = {}

    for slotID = 1, 17 do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local _, _, quality = GetItemInfo(link)
            if quality == HEIRLOOM_QUALITY then
                local cap = GetHeirloomCap(link)
                if playerLevel >= cap then
                    local name = GetItemInfo(link) or "Heirloom"
                    table.insert(deadSlots, { slot = slotID, name = name, cap = cap })
                end
            end
        end
    end

    if #deadSlots > 0 then
        TA:Raw(TA.LOG.WARN, "|cFFFF9A1A[ToonAge]|r ⚠ Heirloom gear has stopped scaling!")
        for _, info in ipairs(deadSlots) do
            TA:Raw(TA.LOG.WARN, string.format("  |cFFFF4444✗|r %s (capped at level %d) — replace ASAP", info.name, info.cap))
        end
        -- Flag these slots for aggressive AutoEquip replacement
        TA.charDB.heirloomDeadSlots = {}
        for _, info in ipairs(deadSlots) do
            TA.charDB.heirloomDeadSlots[info.slot] = true
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §3 — Tank Threat Inversion (Nameplate Coloring)
-- ══════════════════════════════════════════════════════════════════════════════
-- TANK: mobs on you = green (safe), mobs on others = RED (taunt!)
-- DPS:  mobs on you = red (danger), mobs on others = normal

function RM:UpdateThreatPlates()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID = GetSpecializationInfo(specIndex)
    local data = SW and SW[specID]
    local role = data and data.role or "DAMAGER"

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
                local isTanking = UnitDetailedThreatSituation("player", unit)
                local hb = nameplate.UnitFrame.healthBar

                if role == "TANK" then
                    if isTanking then
                        -- Safe: mob is on you
                        hb:SetStatusBarColor(0.2, 0.8, 0.3)  -- green
                    else
                        -- DANGER: mob is on someone else — need to taunt
                        hb:SetStatusBarColor(1.0, 0.2, 0.1)  -- red
                        -- Scale up slightly for visibility
                        if nameplate.SetScale then nameplate:SetScale(1.15) end
                    end
                elseif role == "DAMAGER" then
                    if isTanking then
                        -- Danger: you have aggro as DPS
                        hb:SetStatusBarColor(1.0, 0.3, 0.1)  -- red warning
                    else
                        -- Normal: someone else has aggro (correct)
                        hb:SetStatusBarColor(0.8, 0.8, 0.8)  -- neutral
                        if nameplate.SetScale then nameplate:SetScale(1.0) end
                    end
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §4 — Pre-Pull Buff Audit
-- ══════════════════════════════════════════════════════════════════════════════
-- On READY_CHECK: verify player has correct flask/food/rune for their role.

local FLASK_SPELLIDS = {
    -- Midnight flasks (example IDs — would need real 12.0 IDs)
    INT  = { 431972, 431973 },  -- Intellect flasks
    AGI  = { 431974, 431975 },  -- Agility flasks
    STR  = { 431976, 431977 },  -- Strength flasks
}

local FOOD_BUFF_IDS = {
    -- Well Fed buffs that grant secondaries
    370, 371, 372,  -- placeholder IDs
}

function RM:AuditBuffs()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID = GetSpecializationInfo(specIndex)
    local data = SW and SW[specID]
    if not data then return end

    local primary = data.primary  -- "INT", "AGI", "STR"
    local warnings = {}

    -- Check flask
    local hasCorrectFlask = false
    local hasAnyFlask = false
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        if auraData.spellId then
            -- Check if this is a flask for our primary stat
            local correctIDs = FLASK_SPELLIDS[primary] or {}
            for _, fid in ipairs(correctIDs) do
                if auraData.spellId == fid then hasCorrectFlask = true end
            end
            -- Check if it's ANY flask (wrong stat)
            for _, ids in pairs(FLASK_SPELLIDS) do
                for _, fid in ipairs(ids) do
                    if auraData.spellId == fid then hasAnyFlask = true end
                end
            end
        end
    end

    if not hasAnyFlask then
        table.insert(warnings, "|cFFFF4444✗ No Flask!|r Use a " .. primary .. " flask.")
    elseif not hasCorrectFlask and hasAnyFlask then
        table.insert(warnings, "|cFFFF9A1A⚠ Wrong Flask!|r You need " .. primary .. ", not your current flask.")
    end

    -- Check food (simplified: just check if Well Fed is active)
    local hasFood = false
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        if auraData.spellId and auraData.name and auraData.name:find("Well Fed") then
            hasFood = true
            break
        end
    end
    if not hasFood then
        table.insert(warnings, "|cFFFF9A1A⚠ No Food Buff!|r Eat for secondary stats.")
    end

    -- Output warnings
    if #warnings > 0 then
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge Pre-Pull Audit]|r")
        for _, w in ipairs(warnings) do TA:Raw(TA.LOG.OUTPUT, "  " .. w) end
    else
        if TA.debug then
            TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A[ToonAge]|r Buffs OK for pull.")
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §5 — Healer Triage Engine
-- ══════════════════════════════════════════════════════════════════════════════
-- For healer specs: track party health deficits and rank by urgency.
-- Surfaces the highest-priority heal target name on the prediction bar.

RM.triageTarget = nil   -- { name, unit, urgency, reason }

function RM:UpdateTriage()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID = GetSpecializationInfo(specIndex)
    local data = SW and SW[specID]
    if not data or data.role ~= "HEALER" then
        self.triageTarget = nil
        return
    end

    if not IsInGroup() then self.triageTarget = nil; return end

    local bestTarget = nil
    local bestUrgency = 0

    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1

    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            -- UnitHealth/UnitHealthMax can return a "secret" opaque value under WoW's
            -- execution-taint sandboxing (group roster context can be tainted). The old
            -- type(hpMax) == "number" check does NOT protect the *comparison* right
            -- after it (hpMax > 0) — a secret value can still report type "number" and
            -- then throw on the actual `>` comparison. pcall the whole computation.
            local ok, pct, deficit = pcall(function()
                local hp = UnitHealth(unit)
                local hpMax = UnitHealthMax(unit)
                if type(hp) ~= "number" or type(hpMax) ~= "number" or not (hpMax > 0) then
                    return nil
                end
                local p = hp / hpMax * 100
                return p, 100 - p
            end)

            if ok and pct then
                -- Urgency scoring: higher = more urgent
                local urgency = deficit  -- base: how much HP they're missing

                -- Bonus if they're the tank (tanks dying = wipe)
                local role = UnitGroupRolesAssigned(unit)
                if role == "TANK" then urgency = urgency + 20 end

                -- Bonus if they have a dangerous debuff (DOT ticking)
                -- Simplified: if below 40%, extra urgency
                if pct < 40 then urgency = urgency + 30 end
                if pct < 20 then urgency = urgency + 50 end

                -- Penalty if they have a defensive active (they're managing it)
                -- Would need aura scanning — simplified for now

                if urgency > bestUrgency and deficit > 15 then
                    bestUrgency = urgency
                    bestTarget = {
                        name = UnitName(unit) or unit,
                        unit = unit,
                        urgency = urgency,
                        pct = pct,
                        role = role,
                    }
                end
            end
        end
    end

    self.triageTarget = bestTarget
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EVENT HANDLING
-- ══════════════════════════════════════════════════════════════════════════════

function RM:OnEvent(event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:ApplyCameraProfile()
    elseif event == "PLAYER_LEVEL_UP" then
        -- Delay to let new level register
        C_Timer.After(1, function() RM:CheckHeirlooms() end)
    elseif event == "READY_CHECK" then
        self:AuditBuffs()
    elseif event == "UNIT_HEALTH" then
        -- Update triage on health changes (throttled by CombatState polling)
        local unit = ...
        if unit and unit:match("^party") or unit and unit:match("^raid") then
            self:UpdateTriage()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        self:UpdateTriage()
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════════════════════════════════════════

function RM:Init()
    -- Register events
    TA.eventFrame:RegisterEvent("READY_CHECK")

    -- Apply camera on login (in case they logged in as a different spec)
    C_Timer.After(2, function() RM:ApplyCameraProfile() end)

    -- Check heirlooms on login
    C_Timer.After(3, function() RM:CheckHeirlooms() end)

    -- Start threat plate updates (throttled ticker)
    C_Timer.NewTicker(0.5, function()
        if UnitAffectingCombat("player") then
            pcall(RM.UpdateThreatPlates, RM)
        end
    end)

    -- Triage ticker for healers (0.3s in combat)
    C_Timer.NewTicker(0.3, function()
        if UnitAffectingCombat("player") and IsInGroup() then
            pcall(RM.UpdateTriage, RM)
        end
    end)
end

RM.SlashCommands = {}
