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
        TA:Raw(TA.LOG.INFO, string.format(("|cFFFFD100[TA]|r Camera " .. ToonAge.Utils.Glyph("arrow") .. " %s (spec %d)"), zoom, specID))
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- §2 — Heirloom Cap Alert
-- ══════════════════════════════════════════════════════════════════════════════
-- Heirlooms (quality 7) stop scaling at specific level caps.
-- Alert when player levels past the cap so they know to replace the gear.

local HEIRLOOM_QUALITY = 7

local function IsSecret(v)
    if U and type(U.IsSecret) == "function" then return U.IsSecret(v) end
    if type(issecretvalue) ~= "function" then return false end
    local ok, secret = pcall(issecretvalue, v)
    return ok and secret == true
end

local function ItemID(itemLink)
    local fn = TA.Compat and TA.Compat.GetItemInfoInstant
    if type(fn) == "function" then
        local ok, id = pcall(fn, itemLink)
        if ok and type(id) == "number" and not IsSecret(id) then return id end
    end
    if type(itemLink) == "string" then
        local digits = itemLink:match("item:(%d+)")
        if digits then return tonumber(digits) end
    end
    return nil
end

--- UNVERIFIED on 12.x. GetHeirloomMaxUpgradeLevel is an upgrade-tier count,
--- not a player level, and GetHeirloomInfo's returns are not confirmed.
--- This does not call C_Heirloom. nil means unknown, so the dead-heirloom
--- warning stays off. /ta heirlooms probe prints the raw returns.
function RM.GetHeirloomCap()
    return nil
end

local function ShowValue(v)
    if IsSecret(v) then return "secret" end
    if v == nil then return "nil" end
    local ok, text = pcall(tostring, v)
    if not ok then return "unprintable" end
    return text
end

local function Capture(fn, itemID)
    local box = { n = 0 }
    local ok, err = pcall(function()
        local function take(...)
            box.n = select("#", ...)
            for i = 1, box.n do box[i] = select(i, ...) end
        end
        take(fn(itemID))
    end)
    if not ok then return { false, err } end
    local out = { true, n = box.n + 1 }
    for i = 1, box.n do out[i + 1] = box[i] end
    return out
end

local function ShowReturns(label, res)
    if not res[1] then
        return label .. " -> error: " .. ShowValue(res[2])
    end
    local first = res[2]
    if type(first) == "table" and not IsSecret(first) then
        local keys = {}
        for k in pairs(first) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. ShowValue(first[k]) end
        if #parts == 0 then return label .. " -> {}" end
        return label .. " -> { " .. table.concat(parts, ", ") .. " }"
    end
    local parts = {}
    local n = res.n or 2
    for i = 2, n do parts[#parts + 1] = ShowValue(res[i]) end
    return label .. " -> " .. table.concat(parts, ", ")
end

--- One equipped heirloom, raw and secret-safe. /ta heirlooms probe.
--- UNVERIFIED on 12.x until Christopher's run is read.
function RM.HeirloomProbe()
    local lines = {}
    local function add(text) lines[#lines + 1] = text end
    local heirloom = C_Heirloom
    local maxUp = type(heirloom) == "table" and heirloom.GetHeirloomMaxUpgradeLevel
    local info = type(heirloom) == "table" and heirloom.GetHeirloomInfo
    add("C_Heirloom.GetHeirloomMaxUpgradeLevel " .. (type(maxUp) == "function" and "present" or "absent"))
    add("C_Heirloom.GetHeirloomInfo " .. (type(info) == "function" and "present" or "absent"))
    local itemID, slotID
    local linkFn = GetInventoryItemLink
    if type(linkFn) == "function" then
        for slot = 1, 17 do
            local ok, link = pcall(linkFn, "player", slot)
            if ok and type(link) == "string" then
                local read = TA.Compat and TA.Compat.GetItemInfo
                local qok, _, _, quality = false, nil, nil, nil
                if type(read) == "function" then qok, _, _, quality = pcall(read, link) end
                if qok and not IsSecret(quality) and quality == HEIRLOOM_QUALITY then
                    local id = ItemID(link)
                    if id then itemID, slotID = id, slot break end
                end
            end
        end
    end
    if not itemID then
        add("no equipped heirloom")
        add("UNVERIFIED on 12.x. The heirloom cap warning stays off.")
        return lines
    end
    add("equipped heirloom item " .. tostring(itemID) .. " slot " .. tostring(slotID))
    if type(maxUp) == "function" then
        add(ShowReturns("GetHeirloomMaxUpgradeLevel(" .. tostring(itemID) .. ")", Capture(maxUp, itemID)))
    end
    if type(info) == "function" then
        add(ShowReturns("GetHeirloomInfo(" .. tostring(itemID) .. ")", Capture(info, itemID)))
    end
    add("UNVERIFIED on 12.x. The heirloom cap warning stays off.")
    return lines
end

function RM:CheckHeirlooms()
    local playerLevel = UnitLevel("player") or 1
    local deadSlots = {}

    for slotID = 1, 17 do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local _, _, quality = TA.Compat.GetItemInfo(link)
            if not IsSecret(quality) and quality == HEIRLOOM_QUALITY then
                local cap = RM.GetHeirloomCap(link)
                -- nil is unknown. A number is only a cap once 12.x is verified.
                if type(cap) == "number" and not IsSecret(cap) and not IsSecret(playerLevel)
                    and playerLevel >= cap then
                    local name = TA.Compat.GetItemInfo(link) or "Heirloom"
                    table.insert(deadSlots, { slot = slotID, name = name, cap = cap })
                end
            end
        end
    end

    if #deadSlots > 0 then
        TA:Raw(TA.LOG.WARN, ("|cFFFF9A1A[ToonAge]|r " .. ToonAge.Utils.Glyph("warn") .. " Heirloom gear has stopped scaling!"))
        for _, info in ipairs(deadSlots) do
            TA:Raw(TA.LOG.WARN, string.format(("  " .. ToonAge.Utils.Glyph("cross", "FF4444") .. " %s (capped at level %d) — replace ASAP"), info.name, info.cap))
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

-- Flask and food detection is by aura NAME. The spellID tables that used to be
-- here were placeholders ("example IDs", "placeholder IDs"), so the pre-pull
-- audit reported "No Flask!" for everyone. Names can't tell which stat a flask
-- gives, so the wrong-stat warning was dropped rather than guessed.
local function IsFlaskAura(name)
    return name and (name:find("Flask") or name:find("Phial")) and true or false
end

function RM:AuditBuffs()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID = GetSpecializationInfo(specIndex)
    local data = SW and SW[specID]
    if not data then return end

    local primary = data.primary  -- "INT", "AGI", "STR"
    local warnings = {}

    -- Check flask
    local hasAnyFlask = false
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        local okName, isFlask = pcall(IsFlaskAura, auraData.name)
        if okName and isFlask then hasAnyFlask = true; break end
    end

    if not hasAnyFlask then
        table.insert(warnings, ("|cFFFF4444" .. ToonAge.Utils.Glyph("cross", "FF4444") .. " No Flask!|r Use a ") .. primary .. " flask.")
    end

    -- Check food (simplified: just check if Well Fed is active)
    local hasFood = false
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        local okFed, fed = pcall(function() return auraData.name and auraData.name:find("Well Fed") end)
        if okFed and fed then
            hasFood = true
            break
        end
    end
    if not hasFood then
        table.insert(warnings, ("|cFFFF9A1A" .. ToonAge.Utils.Glyph("warn", "FF9A1A") .. " No Food Buff!|r Eat for secondary stats."))
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
    -- CombatState now keeps group health (polled in combat) and computes the
    -- triage target the next-3 bar shows; mirror it here for other callers.
    local CS = TA:GetModule("CombatState")
    if CS and CS.state and CS.state.group then
        if CS._UpdateGroup then pcall(CS._UpdateGroup) end
        self.triageTarget = CS.state.group.triage
        return
    end
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
    TA:RegisterEvent("READY_CHECK")

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
