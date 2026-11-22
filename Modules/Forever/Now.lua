-- ToonAge/Modules/Forever/Now.lua  (WoW Forever)
--
-- Prioritized fact->action briefing tab. Placed first, left of Character.
-- Pulls strictly from live verified Forever modules (ForeverRotation,
-- ForeverTalents, ForeverCharacter, ForeverSessionCheck, DataHarvester).
-- Never invents stat weights, never claims DPS optimality, never spends points.
-- Every card ends in a concrete next step.

local TA = ToonAge
local L

local M = {}
TA:RegisterModule("ForeverNow", M)

local SKILL_BEHIND = 10

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

local function PlainNum(v)
    if v == nil or Secret(v) then return nil end
    return tonumber(tostring(v))
end

local function OpenTab(tabID)
    if TA.Layout and TA.Layout.OpenTab then
        TA.Layout:OpenTab(tabID)
    elseif TA.UI and TA.UI.SetTab then
        TA.UI:SetTab(tabID)
    end
end

--- Collect prioritized fact->action items from live Forever modules.
--- Pure read-only: never mutates game state or SavedVariables.
function M:BuildItems()
    local items = {}
    local level = PlainNum(Try(UnitLevel, "player"))

    -- 1. Spell training status (ForeverRotation)
    local R = TA.GetModule and TA:GetModule("ForeverRotation")
    if R and R.TrainableNow and level then
        local ok, due, ranked, covered = pcall(R.TrainableNow, R, level)
        if ok then
            if due == nil then
                items[#items + 1] = {
                    priority = 2,
                    category = "Spells",
                    status = "info",
                    title = "Spell catalog not scanned yet",
                    value = "Scan needed",
                    detail = "ToonAge reads your live spellbook and trainer ranks from Harvest rather than guessing.",
                    actionLabel = "Open Harvest",
                    actionTab = "harvest",
                }
            elseif type(due) == "table" and #due > 0 then
                local names = {}
                for i = 1, math.min(#due, 3) do
                    names[i] = tostring(due[i].name or "Spell")
                end
                local tail = (#due > 3) and (" +" .. tostring(#due - 3) .. " more") or ""
                local trainerHint = ""
                local SP = TA.SpellPlaybook
                if SP and type(SP.FindNearestTrainer) == "function" then
                    local _, clsTok = Try(UnitClass, "player")
                    local side = (TA.Compat and TA.Compat.PlayerFaction and Try(TA.Compat.PlayerFaction))
                        or (type(UnitFactionGroup) == "function" and Try(UnitFactionGroup, "player")) or nil
                    local zone = (type(GetRealZoneText) == "function" and Try(GetRealZoneText)) or nil
                    local info = SP.FindNearestTrainer(clsTok, side, zone)
                    if info and info.trainer then
                        local tr = info.trainer
                        trainerHint = string.format(" Nearest trainer: %s (%s, %.0f, %.0f).",
                            tr.zone, tr.district or "", tr.x or 0, tr.y or 0)
                    end
                end
                items[#items + 1] = {
                    priority = 1,
                    category = "Spells",
                    status = "warning",
                    title = string.format("%d spell %s ready at your class trainer",
                        #due, #due == 1 and "rank" or "ranks"),
                    value = tostring(#due) .. " due",
                    detail = "Trainable now: " .. table.concat(names, ", ") .. tail .. "." .. trainerHint,
                    actionLabel = "Open Spells",
                    actionTab = "spells",
                }
            else
                local covNote = "No verified trainable spell ranks found for your current level."
                if ranked and covered and ranked > covered then
                    covNote = string.format("Rank data covers %d of %d ranked spells; check your trainer for the rest.",
                        covered, ranked)
                end
                items[#items + 1] = {
                    priority = 3,
                    category = "Spells",
                    status = "ok",
                    title = "Spell ranks checked",
                    value = "Up to date",
                    detail = covNote,
                    actionLabel = "Open Spells",
                    actionTab = "spells",
                }
            end
        end
    end

    -- 1c. Mage Teleports & Portals training reminder (SpellPlaybook + live spellbook)
    local SP = TA.SpellPlaybook
    if SP and type(SP.GetMagePortals) == "function" and level then
        local _, clsTok = Try(UnitClass, "player")
        if clsTok == "MAGE" then
            local side = (TA.Compat and TA.Compat.PlayerFaction and Try(TA.Compat.PlayerFaction))
                or (type(UnitFactionGroup) == "function" and Try(UnitFactionGroup, "player")) or nil
            local knownByName = {}
            local M = TA.GetModule and TA:GetModule("ForeverMageSuggest") or nil
            if M and type(M.ScanLiveSpellbook) == "function" then
                local okS, byName = pcall(M.ScanLiveSpellbook)
                if okS and type(byName) == "table" then knownByName = byName end
            end
            local portals = SP.GetMagePortals(level, side, knownByName)
            local verifiedDue = {}
            for _, p in ipairs(portals.due or {}) do
                if p.verified ~= false then verifiedDue[#verifiedDue + 1] = p end
            end
            if #verifiedDue > 0 then
                local parts = {}
                for i = 1, math.min(#verifiedDue, 3) do
                    local p = verifiedDue[i]
                    parts[#parts + 1] = p.name .. " (" .. p.npc .. ", " .. p.zone .. ")"
                end
                items[#items + 1] = {
                    priority = 2,
                    category = "Portals",
                    status = "warning",
                    title = string.format("%d Mage teleport/portal %s ready to train",
                        #verifiedDue, #verifiedDue == 1 and "spell" or "spells"),
                    value = tostring(#verifiedDue) .. " due",
                    detail = table.concat(parts, " · ") .. ".",
                    actionLabel = "Open Spells",
                    actionTab = "spells",
                }
            end
        end
    end

    -- 1b. Profession tier trainer reminders (ProfessionBoard) -- never cap out silently!
    local PB = TA.GetModule and TA:GetModule("ProfessionBoard")
    if PB and type(PB.GetTrainerReminders) == "function" then
        local okP, rems = pcall(PB.GetTrainerReminders, level)
        if okP and type(rems) == "table" and #rems > 0 then
            local anyCapped = false
            local names = {}
            for _, r in ipairs(rems) do
                if r.capped then anyCapped = true end
                names[#names + 1] = tostring(r.name or "Profession") .. " (" .. tostring(r.rank) .. "/" .. tostring(r.max) .. ")"
            end
            items[#items + 1] = {
                priority = anyCapped and 1 or 2,
                category = "Professions",
                status = anyCapped and "alert" or "warning",
                title = anyCapped
                    and "Profession capped -- visit trainer now!"
                    or "Profession tier trainer open",
                value = tostring(#rems) .. " ready",
                detail = table.concat(names, " · ") .. ". Train the next cap so skillups aren't wasted.",
                actionLabel = "Open Professions",
                actionTab = "professions",
            }
        end
    end

    -- 2. Talent plan status (ForeverTalents Phase 1b GetNextPlannedPoint)
    local T = TA.GetModule and TA:GetModule("ForeverTalents")
    if T and T.GetNextPlannedPoint then
        local ok, plan = pcall(T.GetNextPlannedPoint)
        if ok and type(plan) == "table" then
            local unspent = tonumber(plan.unspent) or 0
            local prio = (unspent > 0) and 1 or (plan.hasPlan and 2 or 3)
            local status = (unspent > 0) and "warning" or (plan.hasPlan and "info" or "ok")
            local val = (unspent > 0) and (tostring(unspent) .. " to spend")
                or (plan.hasPlan and (plan.alreadyMaxed and "Target maxed" or "Planned") or "No target")
            items[#items + 1] = {
                priority = prio,
                category = "Talents",
                status = status,
                title = plan.hasPlan and ("Talent Plan: " .. tostring(plan.targetName or "Active")) or "Talent Plan",
                value = val,
                detail = tostring(plan.summary or "Open Talents to inspect the tree or set a plan target."),
                actionLabel = "Open Talents",
                actionTab = "talents",
            }
        end
    end

    -- 2b. Active PvP readiness alert (ForeverPvP: flagged / contested / FFA / in BG)
    local PVP = TA.GetModule and TA:GetModule("ForeverPvP")
    if PVP and type(PVP.GetAlert) == "function" then
        local okP, alert = pcall(PVP.GetAlert)
        if okP and type(alert) == "table" then
            items[#items + 1] = alert
        end
    end

    -- 2c. In-Dungeon Quest Item Map Pins checklist (ForeverDungeonPins)
    local DP = TA.GetModule and TA:GetModule("ForeverDungeonPins")
    if DP and type(DP.GetCurrentDungeonChecklist) == "function" then
        local okD, dInfo = pcall(DP.GetCurrentDungeonChecklist)
        if okD and type(dInfo) == "table" then
            local hasActive = (dInfo.activeCount or 0) > 0
            local detail
            if hasActive then
                detail = "Active: " .. table.concat(dInfo.activeNames, " · ") .. ". Press M to view marked quest item & boss pins on the dungeon map."
            else
                detail = tostring(dInfo.pinCount) .. " quest item/boss pins marked on your dungeon map (press M). Type /ta dpins to filter Active Only or Off."
            end
            items[#items + 1] = {
                priority = hasActive and 1 or 2,
                category = "Dungeon",
                status = hasActive and "warning" or "info",
                title = "In " .. tostring(dInfo.dungeon) .. " -- Quest Map Pins",
                value = hasActive and (tostring(dInfo.activeCount) .. " active") or (tostring(dInfo.pinCount) .. " pins"),
                detail = detail,
            }
        end
    end

    -- 3. Weapon & Defense skill readiness (ForeverCharacter)
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC._ReadSkillLines and FC._WeaponSkillFor then
        local ok, lines = pcall(FC._ReadSkillLines)
        if ok and type(lines) == "table" then
            local byID = {}
            for _, ln in ipairs(lines) do
                if ln.id then byID[ln.id] = ln end
            end
            local behind, seen = {}, {}
            local function checkSkill(id, label)
                local ln = id and byID[id]
                if ln and ln.rank and ln.max and not seen[id] and (ln.max - ln.rank) >= SKILL_BEHIND then
                    seen[id] = true
                    behind[#behind + 1] = string.format("%s %d/%d", tostring(ln.name or label), ln.rank, ln.max)
                end
            end
            for _, slot in ipairs({ { 16, "Main hand" }, { 17, "Off hand" }, { 18, "Ranged" } }) do
                local okSlot, sid = pcall(FC._WeaponSkillFor, slot[1])
                if okSlot and sid then checkSkill(sid, slot[2]) end
            end
            checkSkill(95, "Defense")
            if #behind > 0 then
                items[#items + 1] = {
                    priority = 2,
                    category = "Character",
                    status = "warning",
                    title = "Weapon or Defense skills behind cap",
                    value = tostring(#behind) .. " behind",
                    detail = table.concat(behind, ", ") .. ".",
                    actionLabel = "Open Character",
                    actionTab = "character",
                }
            else
                items[#items + 1] = {
                    priority = 3,
                    category = "Character",
                    status = "ok",
                    title = "Equipped weapon & Defense skills",
                    value = "Near cap",
                    detail = "No equipped weapon skill or Defense line is 10+ points under cap.",
                    actionLabel = "Open Character",
                    actionTab = "character",
                }
            end
        end
    end

    -- 4. Harvest sensor status (DataHarvester / TA.db.harvest)
    local caps = TA.db and TA.db.harvest and TA.db.harvest.captures
    local key
    if TA.Harvester and TA.Harvester.CharacterKey then
        local okK, k = pcall(TA.Harvester.CharacterKey, TA.Harvester)
        if okK then key = k end
    end
    local entry = (type(caps) == "table" and key) and caps[key] or nil
    local domains = { "spellbook", "talents", "trainer", "skills", "professions" }
    local recorded = 0
    local missing = {}
    for _, d in ipairs(domains) do
        if type(entry) == "table" and entry[d] ~= nil then
            recorded = recorded + 1
        else
            missing[#missing + 1] = d
        end
    end
    items[#items + 1] = {
        priority = (recorded == 0) and 2 or 3,
        category = "Harvest",
        status = (recorded == #domains) and "ok" or "info",
        title = "Harvest sensor coverage",
        value = string.format("%d/%d domains", recorded, #domains),
        detail = (#missing == 0)
            and "Spellbook, talents, trainer, skills, and professions are captured for this character."
            or ("Missing captures: " .. table.concat(missing, ", ") .. "."),
        actionLabel = "Open Harvest",
        actionTab = "harvest",
    }

    table.sort(items, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return tostring(a.category) < tostring(b.category)
    end)

    return items
end

local function StatusColor(status)
    if status == "warning" then return L.C_WARNING end
    if status == "ok" then return L.C_OK end
    return L.C_PRIMARY
end

function M:Render(content, side)
    L = L or TA.Layout
    if not L then
        content:SetHeight(80)
        return
    end

    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    end

    local y = -8
    y = L:SectionHeader(content, y, "Now", "Fact-based briefing from live client reads")

    -- Inline "Since last login" delta strip (replaces the old modal popup)
    local SC = TA.GetModule and TA:GetModule("ForeverSessionCheck")
    if SC and type(SC.Summary) == "function" then
        local okS, sum = pcall(SC.Summary, SC)
        if okS and type(sum) == "table" then
            local bits = {}
            if (sum.levelsGained or 0) > 0 and sum.prevLevel and sum.curLevel then
                bits[#bits + 1] = string.format("Level %d -> %d (+%d)", sum.prevLevel, sum.curLevel, sum.levelsGained)
            end
            local eqN = type(sum.equipChanges) == "table" and #sum.equipChanges or 0
            if eqN > 0 then
                bits[#bits + 1] = string.format("%d gear %s", eqN, eqN == 1 and "swap" or "swaps")
            end
            local valText = (#bits > 0) and table.concat(bits, " · ") or "Same level & gear"
            local noteText = (eqN > 0) and ("Equipped: " .. table.concat(sum.equipChanges, ", ")) or nil
            y = L:DataRow(content, y, {
                label = "Since " .. tostring(sum.whenText or "last login"),
                value = valText,
                note = noteText,
                status = (sum.levelsGained or 0) > 0 and "good" or "neutral",
            })
        end
    end

    local items = self:BuildItems()
    local actionCount = 0
    for _, item in ipairs(items) do
        if item.priority <= 2 then actionCount = actionCount + 1 end
    end
    y = L:Paragraph(content, y,
        (actionCount > 0)
            and string.format("%d %s ready for attention. Guidance stays factual — no invented weights or auto-spend.",
                actionCount, actionCount == 1 and "item" or "items")
            or "Nothing urgent due right now. Every section below links directly to its tab.",
        { color = L.C_DIM })

    for _, item in ipairs(items) do
        y = L:Divider(content, y)
        y = L:DataRow(content, y, {
            label = item.title,
            value = item.value,
            status = StatusColor(item.status),
            bold = (item.priority == 1),
            note = item.detail,
        })
        if item.actionLabel and item.actionTab then
            local targetTab = item.actionTab
            y = L:ButtonRow(content, y, {
                {
                    label = item.actionLabel,
                    gold = (item.priority == 1),
                    onClick = function() OpenTab(targetTab) end,
                },
            })
        end
    end

    y = L:Divider(content, y)
    y = L:ButtonRow(content, y, {
        { label = "Since Last Session", onClick = function()
            local SC = TA.GetModule and TA:GetModule("ForeverSessionCheck")
            if SC and SC.Show then SC:Show() end
        end },
        { label = "Open Settings", onClick = function()
            if TA.ToggleOptionsPanel then TA:ToggleOptionsPanel() end
        end },
    }, { label = "Next steps:" })

    L:Finish(content, y)
end

function M:OnEvent(event)
    if TA.QueueUIRefresh then TA:QueueUIRefresh(event) end
end

M.Events = {
    "PLAYER_LEVEL_UP",
    "PLAYER_TALENT_UPDATE",
    "TRAIT_CONFIG_UPDATED",
    "CHARACTER_POINTS_CHANGED",
    "SPELLS_CHANGED",
    "SKILL_LINES_CHANGED",
}

return M
