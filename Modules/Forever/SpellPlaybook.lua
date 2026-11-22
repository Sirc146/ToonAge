-- ToonAge/Modules/Forever/SpellPlaybook.lua  (WoW Forever)
--
-- Live, all-9-class, Lv 1-60 Spell Playbook for the Forever Spells tab.
-- Replaces the Lv 10-19 Mage experimental disclaimer wall with a clean,
-- scannable Modern Azeroth workflow built strictly from live client reads:
--   * Mode pills: Single Target / Opener / AoE / Emergency / Efficiency (DPS & DPM)
--   * Spec selector (auto-picks from TA_Rotations.forever[class])
--   * Live Buff & Wand readiness strip (C_UnitAuras + C_SpellBook + Ranged slot)
--   * Confirmed-only priority rows enriched with Trainer due, Bar rank, Casts share,
--     and equipped school-damage gear notes.
--   * Live Tooltip DPS & Damage-per-Mana (DPM) table (100% live tooltip math).
--
-- Never casts, never glows action buttons, never invents numbers.

local TA = ToonAge
local SP = {}
TA.SpellPlaybook = SP

SP.activeMode = "st"
SP.selectedSpec = nil
SP.showResearchDraft = false

local MODES = {
    { key = "st",         label = "Single Target" },
    { key = "opener",     label = "Opener" },
    { key = "aoe",        label = "AoE" },
    { key = "emergency",  label = "Emergency" },
    { key = "efficiency", label = "DPS & DPM" },
}

-- Core self-buffs per class (checked ONLY when the player actually knows the spell).
local CLASS_BUFF_GROUPS = {
    MAGE = {
        { label = "Armor",     spells = { "Ice Armor", "Mage Armor", "Frost Armor" } },
        { label = "Intellect", spells = { "Arcane Brilliance", "Arcane Intellect" } },
    },
    PRIEST = {
        { label = "Fortitude", spells = { "Prayer of Fortitude", "Power Word: Fortitude" } },
        { label = "Inner Fire", spells = { "Inner Fire" } },
    },
    DRUID = {
        { label = "Mark",   spells = { "Gift of the Wild", "Mark of the Wild" } },
        { label = "Thorns", spells = { "Thorns" } },
    },
    WARLOCK = {
        { label = "Armor", spells = { "Demon Armor", "Demon Skin" } },
    },
    WARRIOR = {
        { label = "Shout", spells = { "Battle Shout" } },
    },
    PALADIN = {
        { label = "Aura",     spells = { "Devotion Aura", "Retribution Aura", "Sanctity Aura", "Concentration Aura" } },
        { label = "Blessing", spells = { "Blessing of Kings", "Blessing of Might", "Blessing of Wisdom" } },
    },
    SHAMAN = {
        { label = "Shield", spells = { "Lightning Shield" } },
    },
    HUNTER = {
        { label = "Aspect", spells = { "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Cheetah" } },
    },
}

--- Shared class self-buff groups (used by both SpellPlaybook and ForeverMageSuggest).
function SP.GetBuffGroups(classToken)
    return CLASS_BUFF_GROUPS[classToken] or {}
end

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Secret(v)
    if v == nil then return false end
    if TA.Utils and TA.Utils.IsSecret and TA.Utils.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function PlainStr(v)
    if v == nil or Secret(v) or type(v) ~= "string" then return nil end
    if TA.Utils and TA.Utils.StripMarkup then
        v = TA.Utils.StripMarkup(v)
    else
        v = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    return v ~= "" and v or nil
end

local function PlainNum(v)
    if v == nil or Secret(v) then return nil end
    return tonumber(tostring(v))
end

--- Level band key matching Data/Forever/RotationLists.lua.
function SP.BandForLevel(level)
    local lv = tonumber(level) or 1
    if lv >= 60 then return "60" end
    if lv >= 40 then return "40-59" end
    if lv >= 20 then return "20-39" end
    return "10-19"
end

--- Available spec names for a class from TA_Rotations.forever.
function SP.SpecsForClass(classToken)
    local root = _G.TA_Rotations and _G.TA_Rotations.forever
    local cls = type(root) == "table" and classToken and root[classToken] or nil
    if type(cls) ~= "table" then return {} end
    local names = {}
    for k, v in pairs(cls) do
        if type(k) == "string" and type(v) == "table"
            and (v["10-19"] or v["20-39"] or v["40-59"] or v["60"]) then
            names[#names + 1] = k
        end
    end
    table.sort(names)
    return names
end

--- Resolve active spec table + band entry for (classToken, specName, level).
function SP.ResolveBand(classToken, specName, level)
    local specs = SP.SpecsForClass(classToken)
    if #specs == 0 then return nil, nil, nil, specs end
    local picked = nil
    if type(specName) == "string" then
        for _, s in ipairs(specs) do
            if s == specName then picked = s; break end
        end
    end
    if not picked then picked = specs[1] end
    local root = _G.TA_Rotations and _G.TA_Rotations.forever
    local specTbl = root and root[classToken] and root[classToken][picked]
    if type(specTbl) ~= "table" then return nil, picked, nil, specs end
    local bandKey = SP.BandForLevel(level)
    local band = specTbl[bandKey] or specTbl["10-19"] or specTbl["20-39"] or specTbl["60"]
    return band, picked, bandKey, specs
end

--- Build a lookup map of confirmed known spells from ReadSpellbook() lines:
--- knownByName[name] = { name, spellID, rank, learned, count }
function SP.IndexSpellbook(lines)
    local byName = {}
    for _, g in ipairs(lines or {}) do
        for _, sp in ipairs(g.spells or {}) do
            if type(sp) == "table" and type(sp.name) == "string" and sp.name ~= "" then
                local cur = byName[sp.name]
                if not cur or (tonumber(sp.learned) or 0) >= (tonumber(cur.learned) or 0) then
                    byName[sp.name] = {
                        name = sp.name,
                        spellID = sp.spellID,
                        rank = sp.rank,
                        learned = sp.learned,
                    }
                end
            end
        end
    end
    return byName
end

--- Read active player buff names via C_UnitAuras.GetBuffDataByIndex.
function SP.ReadActiveBuffs()
    local active = {}
    if not (C_UnitAuras and C_UnitAuras.GetBuffDataByIndex) then return active end
    for i = 1, 40 do
        local aura = Try(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not aura then break end
        local nm = type(aura) == "table" and PlainStr(aura.name) or nil
        if nm then active[nm] = true end
    end
    return active
end

--- Check whether a wand is equipped in the ranged slot (slot 18, class 2, sub 19).
function SP.HasWandEquipped()
    if type(GetInventoryItemLink) ~= "function" then return nil end
    local link = Try(GetInventoryItemLink, "player", 18)
    if type(link) ~= "string" or Secret(link) then return false end
    if C_Item and type(C_Item.GetItemInfoInstant) == "function" then
        local _, _, _, _, _, classID, subID = Try(C_Item.GetItemInfoInstant, link)
        return PlainNum(classID) == 2 and PlainNum(subID) == 19
    end
    return nil
end

--- Live Prep & Buff readiness items for the current character.
function SP.BuildPrepChecks(classToken, knownByName, activeBuffs, hasWand)
    local out = {}
    local buffs = activeBuffs or SP.ReadActiveBuffs()
    local groups = CLASS_BUFF_GROUPS[classToken] or {}
    for _, grp in ipairs(groups) do
        local bestKnown = nil
        local isUp = false
        for _, spName in ipairs(grp.spells) do
            if buffs[spName] then isUp = true end
            if not bestKnown and knownByName[spName] then bestKnown = spName end
        end
        if bestKnown then
            out[#out + 1] = {
                label = bestKnown,
                ok = isUp,
                value = isUp and "Active" or "Missing",
            }
        end
    end
    if knownByName["Shoot"] then
        local wand = hasWand
        if wand == nil then wand = SP.HasWandEquipped() end
        if wand ~= nil then
            out[#out + 1] = {
                label = "Wand (Shoot)",
                ok = wand == true,
                value = wand and "Equipped" or "No wand in ranged slot",
            }
        end
    end
    return out
end

--- Live single-spell Tooltip Efficiency table (DPS & DPM) from the player's
--- actually known spells. 100% live tooltip math; skips non-damaging spells.
function SP.BuildEfficiencyTable(knownByName, descFn, infoFn, costFn)
    local TI = TA.TalentIntel
    local getDesc = descFn or function(sid)
        if TI and TI.ReadSpellDesc then return TI.ReadSpellDesc(sid) end
        return ""
    end
    local getInfo = infoFn or function(sid)
        if C_Spell and C_Spell.GetSpellInfo then return Try(C_Spell.GetSpellInfo, sid) end
        return nil
    end
    local getCost = costFn or function(sid)
        if C_Spell and C_Spell.GetSpellPowerCost then
            local costs = Try(C_Spell.GetSpellPowerCost, sid)
            if type(costs) == "table" and type(costs[1]) == "table" then
                return PlainNum(costs[1].cost)
            end
        end
        return nil
    end

    local rows = {}
    for name, sp in pairs(knownByName or {}) do
        if type(sp.spellID) == "number" then
            local desc = getDesc(sp.spellID) or ""
            local avgDmg = nil
            local lo, hi = desc:match("(%d+)%s+to%s+(%d+)%s+[%a%s]-damage")
            if lo and hi then
                avgDmg = (tonumber(lo) + tonumber(hi)) / 2
            else
                local flat = desc:match("for%s+(%d+)%s+[%a%s]-damage")
                if flat then avgDmg = tonumber(flat) end
            end
            if avgDmg and avgDmg > 0 then
                local info = getInfo(sp.spellID)
                local castMs = type(info) == "table" and PlainNum(info.castTime) or 0
                local castSec = (castMs and castMs > 0) and (castMs / 1000) or 1.5
                local effSec = math.max(1.5, castSec)
                local dps = avgDmg / effSec
                local mana = getCost(sp.spellID)
                local dpm = (mana and mana > 0) and (avgDmg / mana) or nil
                rows[#rows + 1] = {
                    name = name,
                    rank = sp.rank,
                    spellID = sp.spellID,
                    avgDmg = avgDmg,
                    castSec = castSec,
                    dps = dps,
                    mana = mana,
                    dpm = dpm,
                }
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.dps ~= b.dps then return a.dps > b.dps end
        return a.name < b.name
    end)
    return rows
end

--- Filter a priority list (st / aoe / emergency) down to spells confirmed in
--- the player's live spellbook, enriched with live trainer/bar/cast tags.
function SP.BuildPriorityRows(list, knownByName, dueByName, castStats)
    local out = {}
    for _, entry in ipairs(list or {}) do
        local nm = type(entry) == "table" and entry.name or nil
        local sp = nm and knownByName[nm] or nil
        if sp then
            local tags = {}
            if sp.rank and sp.rank ~= "" then tags[#tags + 1] = sp.rank end
            if dueByName and dueByName[nm] then
                tags[#tags + 1] = "Train " .. tostring(dueByName[nm].label)
            end
            if castStats and castStats.byName then
                local cs = castStats.byName[string.lower(nm)]
                if cs and cs.pct and cs.pct > 0 then
                    tags[#tags + 1] = string.format("%d%% of casts", cs.pct)
                end
            end
            out[#out + 1] = {
                name = nm,
                spellID = sp.spellID,
                value = (#tags > 0) and table.concat(tags, " · ") or "Known",
                cond = entry.cond or "",
                hasUpgrade = (dueByName and dueByName[nm] ~= nil) or false,
            }
        end
    end
    return out
end

--- Locate the nearest class trainer for (classToken, side, currentZone).
--- Priority: exact zone match -> same-continent capital -> same-continent town -> primary faction capital.
function SP.FindNearestTrainer(classToken, side, currentZone)
    local root = TA.Data and TA.Data.ForeverTrainers
    if type(root) ~= "table" or type(root.classes) ~= "table" then return nil end
    local byClass = classToken and root.classes[classToken] or nil
    local list = (type(byClass) == "table" and side) and byClass[side] or nil
    if type(list) ~= "table" or #list == 0 then return nil end

    local zc = root.zoneContinent or {}
    local curCont = currentZone and zc[currentZone] or nil
    local sameZone, sameContCap, sameContTown, firstCap = nil, nil, nil, nil
    for _, tr in ipairs(list) do
        if type(tr) == "table" then
            if not firstCap and tr.hubType == "capital" then firstCap = tr end
            if currentZone and tr.zone == currentZone and not sameZone then
                sameZone = tr
            end
            if curCont and tr.continent == curCont then
                if tr.hubType == "capital" and not sameContCap then
                    sameContCap = tr
                elseif tr.hubType ~= "capital" and not sameContTown then
                    sameContTown = tr
                end
            end
        end
    end
    local picked = sameZone or sameContCap or sameContTown or firstCap or list[1]
    local note = root.notes and root.notes[classToken] and root.notes[classToken][side] or nil
    return {
        trainer = picked,
        all = list,
        note = note,
        sameZone = (sameZone ~= nil),
        sameContinent = (curCont ~= nil and picked and picked.continent == curCont),
    }
end

--- Filter Mage Teleports & Portals by level, faction, and live spellbook.
function SP.GetMagePortals(level, side, knownByName)
    local root = TA.Data and TA.Data.ForeverTrainers
    local out = { due = {}, known = {}, upcoming = {} }
    if type(root) ~= "table" or type(root.magePortals) ~= "table" then return out end
    local lv = tonumber(level) or 1
    local known = type(knownByName) == "table" and knownByName or {}
    for _, p in ipairs(root.magePortals) do
        if type(p) == "table" and (p.side == "Both" or not side or p.side == side) then
            if known[p.name] then
                out.known[#out.known + 1] = p
            elseif lv >= (tonumber(p.level) or 99) then
                out.due[#out.due + 1] = p
            else
                out.upcoming[#out.upcoming + 1] = p
            end
        end
    end
    local byLvl = function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return tostring(a.name) < tostring(b.name)
    end
    table.sort(out.due, byLvl)
    table.sort(out.known, byLvl)
    table.sort(out.upcoming, byLvl)
    return out
end

--- Render the live Spell Playbook at the top of the Spells tab.
function SP.Render(content, y, L, lines, dueList, opts)
    opts = opts or {}
    local classToken = opts.classToken
    if not classToken and type(UnitClass) == "function" then
        local _, tok = Try(UnitClass, "player")
        classToken = PlainStr(tok)
    end
    local level = opts.level or PlainNum(Try(UnitLevel, "player")) or 1
    local knownByName = SP.IndexSpellbook(lines)

    local dueByName = {}
    for _, d in ipairs(dueList or {}) do
        if d.name then dueByName[d.name] = d end
    end

    local defaultSpec = SP.selectedSpec
    if not defaultSpec and TA.Utils and TA.Utils.GetPlayerSpec then
        local _, sName = TA.Utils.GetPlayerSpec()
        if type(sName) == "string" and sName ~= "" then defaultSpec = sName end
    end
    local band, specName, bandKey, specs = SP.ResolveBand(classToken, defaultSpec, level)
    if specName then SP.selectedSpec = specName end

    local subTitle = specName
        and string.format("%s · Levels %s · Confirmed spellbook reads", specName, tostring(bandKey or "1-60"))
        or "Confirmed spellbook & live tooltip reads"
    y = L:SectionHeader(content, y, "Spell Playbook", subTitle)

    -- Mode switcher pills right at the top (zero scrolling required)
    local hudMod = TA.GetModule and TA:GetModule("ForeverMageSuggest") or nil
    local modeBtns = {}
    for _, m in ipairs(MODES) do
        local key = m.key
        modeBtns[#modeBtns + 1] = {
            label = m.label,
            active = (SP.activeMode or "st") == key,
            onClick = function()
                SP.activeMode = key
                if hudMod and (key == "st" or key == "aoe") and hudMod.SetMode then
                    hudMod:SetMode(key)
                elseif hudMod and hudMod.Refresh then
                    hudMod:Refresh()
                end
                if TA.QueueUIRefresh then TA:QueueUIRefresh("PLAYBOOK_MODE") end
            end,
        }
    end
    if #specs > 1 then
        modeBtns[#modeBtns + 1] = {
            label = "Spec: " .. tostring(specName),
            onClick = function()
                local idx = 1
                for i, s in ipairs(specs) do
                    if s == specName then idx = i; break end
                end
                SP.selectedSpec = specs[(idx % #specs) + 1]
                if hudMod and hudMod.Refresh then hudMod:Refresh() end
                if TA.QueueUIRefresh then TA:QueueUIRefresh("PLAYBOOK_SPEC") end
            end,
        }
    end
    if hudMod and hudMod.ToggleEnabled then
        local hudOn = hudMod.IsEnabled and hudMod:IsEnabled() or false
        modeBtns[#modeBtns + 1] = {
            label = hudOn and "HUD: On" or "HUD: Off",
            active = hudOn,
            onClick = function()
                hudMod:ToggleEnabled()
                if TA.QueueUIRefresh then TA:QueueUIRefresh("PLAYBOOK_HUD") end
            end,
        }
        if hudOn and hudMod.ToggleLock then
            local hudLocked = hudMod.Locked and hudMod:Locked() or false
            modeBtns[#modeBtns + 1] = {
                label = hudLocked and "HUD: Locked" or "HUD: Unlocked",
                active = hudLocked,
                onClick = function()
                    hudMod:ToggleLock()
                    if TA.QueueUIRefresh then TA:QueueUIRefresh("PLAYBOOK_HUD_LOCK") end
                end,
            }
        end
    end
    if opts.canShowDraft then
        modeBtns[#modeBtns + 1] = {
            label = SP.showResearchDraft and "Hide draft" or "Research draft",
            active = SP.showResearchDraft,
            onClick = function()
                SP.showResearchDraft = not SP.showResearchDraft
                if TA.QueueUIRefresh then TA:QueueUIRefresh("PLAYBOOK_DRAFT") end
            end,
        }
    end
    y = L:ButtonRow(content, y, modeBtns)

    -- Live Buff & Wand readiness strip
    local prep = SP.BuildPrepChecks(classToken, knownByName)
    for _, item in ipairs(prep) do
        y = L:DataRow(content, y, {
            label = item.label,
            value = item.value,
            status = item.ok and "good" or "warn",
        })
    end

    local TI = TA.TalentIntel
    local castStats = (TI and TI.ReadCastStats) and TI.ReadCastStats() or nil
    local mode = SP.activeMode or "st"

    if mode == "efficiency" then
        local eff = SP.BuildEfficiencyTable(knownByName)
        if #eff == 0 then
            y = L:Paragraph(content, y,
                "No direct-damage spells with loaded tooltips found yet. Hover spells in your spellbook if tooltips are still loading.",
                { color = L.C_DIM })
        else
            local limit = math.min(#eff, 8)
            for i = 1, limit do
                local r = eff[i]
                local dpmPart = r.dpm and string.format(" · %.2f DPM (%d mana)", r.dpm, r.mana) or ""
                local castPart = (r.castSec <= 0 or r.castSec <= 1.5)
                    and "Instant/1.5s" or string.format("%.1fs cast", r.castSec)
                y = L:DataRow(content, y, {
                    label = r.rank and (r.name .. " (" .. r.rank .. ")") or r.name,
                    value = string.format("%.1f DPS", r.dps),
                    note = string.format("Avg %.0f dmg · %s%s", r.avgDmg, castPart, dpmPart),
                })
            end
        end
    elseif mode == "opener" then
        local openerText = band and band.opener or nil
        if openerText and openerText ~= "" then
            y = L:Paragraph(content, y, "Opener: " .. openerText)
        else
            y = L:Paragraph(content, y, "No scripted opener for this spec/band; use your Single Target priority.", { color = L.C_DIM })
        end
        local rows = SP.BuildPriorityRows(band and band.st, knownByName, dueByName, castStats)
        for i = 1, math.min(#rows, 3) do
            local r = rows[i]
            y = L:DataRow(content, y, {
                label = tostring(i) .. ". " .. r.name,
                value = r.value,
                note = r.cond ~= "" and r.cond or nil,
                status = r.hasUpgrade and "warn" or "neutral",
            })
        end
    else
        local list = band and band[mode] or nil
        local rows = SP.BuildPriorityRows(list, knownByName, dueByName, castStats)
        if #rows == 0 then
            y = L:Paragraph(content, y,
                "No confirmed spells in your spellbook for this mode yet.", { color = L.C_DIM })
        else
            for i, r in ipairs(rows) do
                y = L:DataRow(content, y, {
                    label = tostring(i) .. ". " .. r.name,
                    value = r.value,
                    note = r.cond ~= "" and r.cond or nil,
                    status = r.hasUpgrade and "warn" or "neutral",
                })
            end
        end
    end

    y = L:Paragraph(content, y,
        "Filtered to spells confirmed in your live spellbook. Sourced priorities & live tooltip math only; never casts for you.",
        { color = L.C_DIM, size = 9 })

    -- Nearest Class Trainer (location & faction aware, all 9 classes)
    local side = opts.side
    if not side then
        if TA.Compat and type(TA.Compat.PlayerFaction) == "function" then
            side = PlainStr(Try(TA.Compat.PlayerFaction))
        elseif type(UnitFactionGroup) == "function" then
            side = PlainStr(Try(UnitFactionGroup, "player"))
        end
    end
    local curZone = opts.zone
    if not curZone then
        if type(GetRealZoneText) == "function" then curZone = PlainStr(Try(GetRealZoneText)) end
        if (not curZone or curZone == "") and type(GetZoneText) == "function" then
            curZone = PlainStr(Try(GetZoneText))
        end
    end
    local pins = TA.GetModule and TA:GetModule("ForeverPins") or nil

    local trInfo = SP.FindNearestTrainer(classToken, side, curZone)
    if trInfo and trInfo.trainer then
        local tr = trInfo.trainer
        if L.Divider then y = L:Divider(content, y) end
        local sub = curZone
            and ("Nearest " .. tostring(side or "") .. " trainer from " .. curZone)
            or ("Sourced " .. tostring(side or "") .. " class trainers")
        y = L:SectionHeader(content, y, "Class Trainer Locator", sub)
        local coordStr = (tr.x and tr.y) and string.format(" (%.1f, %.1f)", tr.x, tr.y) or ""
        local whereVal = tr.zone .. coordStr
        local whereNote = (tr.npc and (tr.npc .. " · ") or "") .. tostring(tr.district or "")
        if trInfo.note then whereNote = whereNote .. " · " .. trInfo.note end
        y = L:DataRow(content, y, {
            label = trInfo.sameZone and "Trainer in your zone" or "Nearest Class Trainer",
            value = whereVal,
            note = whereNote,
            status = (#(dueList or {}) > 0) and "warn" or "good",
        })
        if #trInfo.all > 1 then
            local others = {}
            for _, o in ipairs(trInfo.all) do
                if o ~= tr then
                    others[#others + 1] = o.zone .. (o.district and (" (" .. o.district .. ")") or "")
                end
            end
            if #others > 0 then
                y = L:Paragraph(content, y, "Other faction trainers: " .. table.concat(others, " · "),
                    { color = L.C_DIM, size = 9 })
            end
        end
        if pins and type(pins.ToggleTargetPin) == "function" and L.ButtonRow then
            local pinned = pins.IsPinned and pins:IsPinned("class_trainer") or false
            y = L:ButtonRow(content, y, {
                {
                    label = pinned and ("Clear Trainer Pin") or ("Pin " .. tr.zone .. " Trainer"),
                    active = pinned,
                    onClick = function()
                        pins:ToggleTargetPin(tr, "class_trainer")
                        if TA.QueueUIRefresh then TA:QueueUIRefresh("PIN_TOGGLE") end
                    end,
                },
            })
        end
    end

    -- Mage Teleports & Portals tracker + Portal Trainer reminders
    if classToken == "MAGE" then
        local portals = SP.GetMagePortals(level, side, knownByName)
        if (#portals.due + #portals.known + #portals.upcoming) > 0 then
            if L.Divider then y = L:Divider(content, y) end
            local pSub = (#portals.due > 0)
                and (tostring(#portals.due) .. " teleport/portal(s) ready to train now")
                or "City-specific Portal Trainers (Teleports Lv 20/30/50 · Portals Lv 40/50)"
            y = L:SectionHeader(content, y, "Mage Teleports & Portals", pSub)
            for _, p in ipairs(portals.due) do
                local tag = (p.verified == false) and " [UNVERIFIED]" or ""
                y = L:DataRow(content, y, {
                    label = p.name .. tag,
                    value = "Train now (Lv " .. tostring(p.level) .. ")",
                    note = string.format("%s · %s, %s (%.1f, %.1f) · Uses %s",
                        p.npc, p.zone, p.district, p.x or 0, p.y or 0, p.reagent),
                    status = (p.verified == false) and "neutral" or "warn",
                })
            end
            for _, p in ipairs(portals.known) do
                y = L:DataRow(content, y, {
                    label = p.name,
                    value = "Known",
                    note = p.zone .. " · Uses " .. p.reagent,
                    status = "good",
                })
            end
            for _, p in ipairs(portals.upcoming) do
                local tag = (p.verified == false) and " [UNVERIFIED]" or ""
                y = L:DataRow(content, y, {
                    label = p.name .. tag,
                    value = "Unlocks Lv " .. tostring(p.level),
                    note = string.format("%s · %s, %s (%.1f, %.1f)",
                        p.npc, p.zone, p.district, p.x or 0, p.y or 0),
                    status = "dim",
                })
            end
            local pinTarget = portals.due[1] or portals.upcoming[1]
            if pinTarget and pins and type(pins.ToggleTargetPin) == "function" and L.ButtonRow then
                local pinned = pins.IsPinned and pins:IsPinned("portal_trainer") or false
                y = L:ButtonRow(content, y, {
                    {
                        label = pinned and "Clear Portal Trainer Pin"
                            or ("Pin " .. pinTarget.npc .. " (" .. pinTarget.zone .. ")"),
                        active = pinned,
                        onClick = function()
                            pins:ToggleTargetPin({
                                name = pinTarget.npc .. " (" .. pinTarget.name .. ")",
                                zone = pinTarget.zone,
                                x = pinTarget.x,
                                y = pinTarget.y,
                            }, "portal_trainer")
                            if TA.QueueUIRefresh then TA:QueueUIRefresh("PIN_TOGGLE") end
                        end,
                    },
                })
            end
        end
    end
    return y
end

return SP
