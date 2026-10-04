-- TASecretProbe — answers the five questions that decide ToonAge Forever's design.
--
--   /tasp          baseline sample now (do this OUT of combat, with a buff up)
--   /tasp show     reprint the last saved in-combat sample
--   /tasp apis     what replaced the globals ApiGuard says are missing
--   /tasp talents  talent/spec API answer only
--
-- Quiet by design: nothing prints to chat on its own. Results open in
-- ToonAge's copy window; chat is only the fallback when ToonAge is not loaded.
--
-- Then hit a dummy. 3s and 10s after combat starts it samples again automatically,
-- and every player cast in that fight is checked. Results land in
-- WTF\Account\<ACCOUNT>\SavedVariables\TASecretProbe.lua after /reload or logout.
--
-- Rule this file holds: a value is tested with issecretvalue BEFORE any compare,
-- arithmetic, concat or table-key use, so the probe can never throw on a secret.

local isSecret = _G.issecretvalue or function() return false end
local isSecretTable = _G.issecrettable or function() return false end

TASecretProbeDB = TASecretProbeDB or {}

local PREFIX = "|cFF66CCFF[TASP]|r "
local MAX_SPELLS = 8
local MAX_AURAS = 5
local MAX_CASTS = 15

local barSpells = {}   -- spell IDs on action bars, captured out of combat
local knownAuras = {}  -- player aura spell IDs, captured out of combat
local casts = {}
local castSeen = 0
local current          -- sample being built

-- ── helpers ────────────────────────────────────────────────────────────────

local function Try(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function S(v)
    if isSecret(v) then return "SECRET" end
    if v == nil then return "nil" end
    local t = type(v)
    if t == "table" then return isSecretTable(v) and "SECRET-TABLE" or "table" end
    if t == "number" then return (string.format("%.3f", v):gsub("%.?0+$", "")) end
    return tostring(v)
end

local function Add(key, value)
    current[#current + 1] = key .. " = " .. value
end

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok and n and not isSecret(n) then return n end
    end
    return "?"
end

local function EventValid(e)
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, v = pcall(C_EventUtils.IsEventValid, e)
        if ok then return S(v) end
    end
    return "no C_EventUtils"
end

-- ── out-of-combat capture ──────────────────────────────────────────────────

local function CaptureBars()
    wipe(barSpells)
    local seen = {}
    for slot = 1, 180 do
        local ok, kind, id = Try(GetActionInfo, slot)
        if ok and kind == "spell" and not isSecret(id) and type(id) == "number"
           and not seen[id] then
            seen[id] = true
            barSpells[#barSpells + 1] = id
            if #barSpells >= MAX_SPELLS then break end
        end
    end
end

local function CaptureAuras()
    wipe(knownAuras)
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        local id = aura.spellId
        if id and not isSecret(id) then
            knownAuras[#knownAuras + 1] = id
            if #knownAuras >= MAX_AURAS then break end
        end
    end
end

-- ── the sample ─────────────────────────────────────────────────────────────

local function SampleTalents()
    local ok, v = Try(GetSpecialization)
    Add("GetSpecialization()", ok and S(v) or "absent/error")
    ok, v = Try(GetNumTalentTabs)
    Add("GetNumTalentTabs()", ok and S(v) or "absent/error")

    local cfg
    if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        ok, cfg = pcall(C_ClassTalents.GetActiveConfigID)
        Add("C_ClassTalents.GetActiveConfigID()", ok and S(cfg) or "error")
    else
        Add("C_ClassTalents.GetActiveConfigID", "absent")
    end
    if cfg and not isSecret(cfg) and C_Traits and C_Traits.GetConfigInfo then
        local ok2, info = pcall(C_Traits.GetConfigInfo, cfg)
        if ok2 and type(info) == "table" then
            Add("  configInfo.type", S(info.type))
            Add("  configInfo.treeIDs", info.treeIDs and tostring(#info.treeIDs) or "nil")
        end
    end
    local camelot = Enum and Enum.TraitConfigType and Enum.TraitConfigType.CamelotCombat
    Add("Enum.TraitConfigType.CamelotCombat", S(camelot))
end

local function Sample(label)
    current = {}
    Add("label", label)
    Add("time", date("%Y-%m-%d %H:%M:%S"))
    Add("build", S((select(4, GetBuildInfo()))))
    Add("InCombatLockdown()", S(InCombatLockdown()))

    -- 1. Does the client declare secret restrictions at all?
    if C_Secrets then
        local ok, v = Try(C_Secrets.HasSecretRestrictions)
        Add("C_Secrets.HasSecretRestrictions()", ok and S(v) or "absent/error")
        ok, v = Try(C_Secrets.ShouldAurasBeSecret)
        Add("C_Secrets.ShouldAurasBeSecret()", ok and S(v) or "absent/error")
    else
        Add("C_Secrets", "absent")
    end
    Add("issecretvalue", _G.issecretvalue and "present" or "absent")

    -- 2. Resources / health
    local ok, v = Try(UnitPower, "player");        Add("UnitPower(player)", ok and S(v) or "error")
    ok, v = Try(UnitPowerMax, "player");           Add("UnitPowerMax(player)", ok and S(v) or "error")
    ok, v = Try(UnitHealth, "player");             Add("UnitHealth(player)", ok and S(v) or "error")
    ok, v = Try(UnitHealth, "target");             Add("UnitHealth(target)", ok and S(v) or "error")
    ok, v = Try(UnitHealthMax, "target");          Add("UnitHealthMax(target)", ok and S(v) or "error")
    ok, v = Try(UnitXP, "player");                 Add("UnitXP(player)", ok and S(v) or "error")

    -- 3. Cooldowns + usability for spells on your bars
    for _, id in ipairs(barSpells) do
        local name = SpellName(id)
        local cdOk, cd = Try(C_Spell and C_Spell.GetSpellCooldown, id)
        local dur, start = "error", "error"
        if cdOk then
            if cd == nil then dur, start = "nil", "nil"
            elseif isSecret(cd) or isSecretTable(cd) then dur, start = "SECRET-TABLE", "-"
            else dur, start = S(cd.duration), S(cd.startTime) end
        end
        local uOk, usable, noMana = Try(C_Spell and C_Spell.IsSpellUsable, id)
        Add(string.format("spell %d %s", id, name), string.format(
            "cd.duration=%s cd.start=%s usable=%s noMana=%s",
            dur, start, uOk and S(usable) or "error", uOk and S(noMana) or "error"))
    end

    -- 4. Aura lookup by known spell ID (the path that should survive secrecy)
    for _, id in ipairs(knownAuras) do
        local aOk, aura = Try(C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID, id)
        local r
        if not aOk then r = "error"
        elseif aura == nil then r = "nil (absent OR hidden)"
        elseif isSecret(aura) or isSecretTable(aura) then r = "SECRET-TABLE"
        else r = "found; expirationTime=" .. S(aura.expirationTime)
                 .. " applications=" .. S(aura.applications) end
        Add(string.format("aura %d %s", id, SpellName(id)), r)
    end
    local eOk, eAura = Try(C_UnitAuras and C_UnitAuras.GetAuraDataByIndex, "player", 1, "HELPFUL")
    Add("GetAuraDataByIndex(player,1)", eOk and (eAura and "returned" or "nil") or "ERROR (enumeration blocked)")

    -- 5. Blizzard's own rotation helper
    if C_AssistedCombat then
        Add("C_AssistedCombat", "present")
        if C_AssistedCombat.GetNextCastSpell then
            local nOk, nxt = pcall(C_AssistedCombat.GetNextCastSpell, false)
            Add("  GetNextCastSpell()", nOk and (S(nxt) .. " " .. ((nxt and not isSecret(nxt)) and SpellName(nxt) or "")) or "error")
        end
        if C_AssistedCombat.GetRotationSpells then
            local rOk, list = pcall(C_AssistedCombat.GetRotationSpells)
            Add("  GetRotationSpells()", rOk and (type(list) == "table" and (#list .. " spells") or S(list)) or "error")
        end
    else
        Add("C_AssistedCombat", "absent")
    end

    -- 6. Events the rotation/usage features would lean on
    for _, e in ipairs({ "COMBAT_LOG_EVENT_UNFILTERED", "UNIT_SPELLCAST_SUCCEEDED",
                         "ACTION_USABLE_CHANGED", "SPELL_UPDATE_COOLDOWN",
                         "UNIT_HEALTH_FREQUENT", "UNIT_POWER_FREQUENT" }) do
        Add("event " .. e, EventValid(e))
    end

    SampleTalents()
    return current
end

local function Save(label, lines)
    TASecretProbeDB.samples = TASecretProbeDB.samples or {}
    TASecretProbeDB.samples[label] = lines
end

local function Print(lines)
    for _, l in ipairs(lines or {}) do DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. l) end
end

--- Put a multi-line result where it can be selected and copied: ToonAge's copy
--- window (Select All button, Ctrl+A / Ctrl+C) when ToonAge is loaded, chat
--- only as the fallback. One line stays in chat to say where the output went.
local function Show(title, lines)
    lines = lines or {}
    if ToonAge and ToonAge.ShowCopyWindow then
        -- The window says everything; no chat line alongside it.
        ToonAge:ShowCopyWindow(title, table.concat(lines, "\n"))
    else
        Print(lines)
    end
end

-- ── what replaced the missing globals ──────────────────────────────────────
-- ToonAge's ApiGuard reports 44 of 61 globals resolved on this client. It says
-- what is GONE; it cannot say what took over, because it only probes the names
-- the source already mentions. This does the other half: it enumerates the C_*
-- namespaces and then, for each missing global, looks for a function of the
-- same (or an obviously-derived) name anywhere in them.
--
-- The 17 it is answering for, and why each matters:
--   PvP     UnitPVPRank GetPVPRankInfo GetPVPRankProgress
--           GetPVPThisWeekStats GetPVPLastWeekStats   -- ALL five gone, so
--           Modules/Forever/PvP.lua has no live path at all
--   Pets    GetPetHappiness GetPetFoodTypes
--   Items   GetItemInfo GetItemStats                  -- gear stat totals
--   Spells  GetSpellCooldown GetSpellInfo
--   Talents GetNumTalentTabs GetNumTalents GetTalentInfo GetTalentTabInfo
--           -- already migrated to C_Traits; listed here to confirm dead
--   Retail  GetSpecialization GetSpecializationInfo   -- expected absent

local NAMESPACES = {
    "C_PvP", "C_Item", "C_Spell", "C_Traits", "C_ClassTalents", "C_UnitAuras",
    "C_Secrets", "C_PetJournal", "C_StableInfo", "C_TooltipInfo",
    "C_AssistedCombat", "C_CurrencyInfo", "C_Container", "C_PaperDollInfo",
    "C_PlayerInfo", "C_SpecializationInfo", "C_Honor",
}

local MISSING = {
    "UnitPVPRank", "GetPVPRankInfo", "GetPVPRankProgress",
    "GetPVPThisWeekStats", "GetPVPLastWeekStats",
    "GetPetHappiness", "GetPetFoodTypes",
    "GetItemInfo", "GetItemStats",
    "GetSpellCooldown", "GetSpellInfo",
    "GetNumTalentTabs", "GetNumTalents", "GetTalentInfo", "GetTalentTabInfo",
    "GetSpecialization", "GetSpecializationInfo",
}

--- Candidate names for a missing global inside a namespace: the name itself,
--- and the name with a leading Unit/Get shuffled, since Blizzard renamed a few
--- when it moved them (UnitPVPRank -> C_PvP.GetUnitPVPRank, that shape).
local function Candidates(name)
    local out = { name }
    local bare = name:gsub("^Get", ""):gsub("^Unit", "")
    out[#out + 1] = "Get" .. bare
    out[#out + 1] = "GetUnit" .. bare
    out[#out + 1] = bare
    return out
end

local function EnumerateAPIs()
    local lines = {
        "=== TASecretProbe — namespace survey ===",
        "time  = " .. date("%Y-%m-%d %H:%M:%S"),
        "build = " .. S((select(4, GetBuildInfo()))),
        "",
        "-- Replacements for the globals ApiGuard reports missing ------------",
    }

    for _, name in ipairs(MISSING) do
        local globalHas = type(_G[name]) == "function"
        local found = {}
        for _, ns in ipairs(NAMESPACES) do
            local t = _G[ns]
            if type(t) == "table" then
                for _, cand in ipairs(Candidates(name)) do
                    local ok, v = pcall(function() return t[cand] end)
                    if ok and type(v) == "function" then
                        found[#found + 1] = ns .. "." .. cand
                        break
                    end
                end
            end
        end
        lines[#lines + 1] = string.format("%-24s global=%-7s %s",
            name,
            globalHas and "present" or "GONE",
            #found > 0 and ("-> " .. table.concat(found, ", ")) or "-> NO REPLACEMENT FOUND")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- Full namespace contents -----------------------------------------"
    for _, ns in ipairs(NAMESPACES) do
        local t = _G[ns]
        if type(t) ~= "table" then
            lines[#lines + 1] = ns .. " : ABSENT"
        else
            local keys = {}
            for k, v in pairs(t) do
                if type(v) == "function" then keys[#keys + 1] = k end
            end
            table.sort(keys)
            lines[#lines + 1] = string.format("%s : %d function(s)", ns, #keys)
            for _, k in ipairs(keys) do
                lines[#lines + 1] = "    " .. k
            end
        end
    end

    return lines
end

-- ── events ─────────────────────────────────────────────────────────────────

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Silent at login: the probe records on its own, and a chat line every
        -- login is noise. /tasp is how you ask it for anything.
        CaptureBars(); CaptureAuras()

    elseif event == "PLAYER_REGEN_DISABLED" then
        wipe(casts); castSeen = 0
        C_Timer.After(3,  function() Save("combat_3s",  Sample("in combat +3s"))  end)
        C_Timer.After(10, function() Save("combat_10s", Sample("in combat +10s")) end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Silent after combat too: every fight used to add a chat line. The
        -- count is kept and shown at the top of /tasp show instead.
        TASecretProbeDB.casts = casts
        TASecretProbeDB.lastCombatCasts = castSeen
        CaptureBars(); CaptureAuras()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, castGUID, spellID = ...
        castSeen = castSeen + 1
        if #casts < MAX_CASTS then
            local line = "spellID=" .. S(spellID) .. " castGUID=" .. (isSecret(castGUID) and "SECRET" or "plain")
                .. " inCombat=" .. S(InCombatLockdown())
            if spellID and not isSecret(spellID) then line = line .. " " .. SpellName(spellID) end
            casts[#casts + 1] = line
        end
    end
end)

-- ── slash ──────────────────────────────────────────────────────────────────

SLASH_TASECRETPROBE1 = "/tasp"
SlashCmdList.TASECRETPROBE = function(msg)
    msg = (msg or ""):lower()
    if msg == "show" then
        local s = TASecretProbeDB.samples
        local out = {}
        if TASecretProbeDB.lastCombatCasts then
            out[#out + 1] = "last fight: " .. TASecretProbeDB.lastCombatCasts
                .. " casts seen (/reload writes the SavedVariables file)"
        end
        for _, l in ipairs(s and (s.combat_10s or s.combat_3s) or { "no combat sample yet" }) do
            out[#out + 1] = l
        end
        for _, c in ipairs(TASecretProbeDB.casts or {}) do out[#out + 1] = "cast " .. c end
        Show("TASP combat sample", out)
    elseif msg == "apis" then
        local lines = EnumerateAPIs()
        TASecretProbeDB.apiSurvey = lines
        -- ToonAge now owns a selectable copy window (Core/UI.lua). This survey
        -- is 200+ lines: chat cannot hold it and cannot be selected, and the
        -- whole point is pasting it somewhere. Reuse ToonAge's window when it
        -- is loaded rather than building a third one here.
        local body = table.concat(lines, "\n")
        if ToonAge and ToonAge.ShowCopyWindow then
            ToonAge:ShowCopyWindow("Forever API survey (also saved to TASecretProbeDB.apiSurvey on /reload)", body)
        else
            DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. #lines
                .. " lines collected. ToonAge is not loaded, so there is no copy "
                .. "window -- /reload and read TASecretProbeDB.apiSurvey.")
        end

    elseif msg == "talents" then
        current = {}; SampleTalents(); Show("TASP talents", current)
    else
        if InCombatLockdown() then
            DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. "baseline must be out of combat.")
            return
        end
        CaptureBars(); CaptureAuras()
        local lines = Sample("out of combat")
        Save("baseline", lines)
        Show("TASP baseline (out of combat)", lines)
    end
end
