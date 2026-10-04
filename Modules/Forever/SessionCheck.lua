-- ToonAge/Modules/Forever/SessionCheck.lua  (WoW Forever)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHAT THIS IS ──────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- "Since last session", at login. WoW writes SavedVariables at logout and
-- hands them back at the next login before anything runs, so the snapshot
-- this module saved when you logged out is sitting in TA.db when you log in.
-- Comparing it with the live character says what changed and what is due:
--
--   * levels gained since the snapshot
--   * spell ranks your trainer has for you now (Spells tab's catalog check)
--   * action-bar slots still holding a lower rank than you know
--   * unspent talent points
--   * the equipped weapon's skill, and Defense, well below the cap
--   * gear equipped since last time
--
-- A character ToonAge has never seen gets the same list as a "first look" --
-- that is the catch-up check for someone who installs ToonAge at level 40.
--
-- OUTPUT: one chat line with a clickable [Show] that opens the copyable
-- window, never a chat dump. Silent when nothing is due. A /reload or a relog
-- within 15 minutes does not re-announce. /ta since shows it any time.
--
-- Everything read here is already read (and measured on Forever) elsewhere:
-- the rank/bar checks are ForeverRotation's, the skill lines ForeverCharacter's
-- (C_SkillInfo, UnitDefenseSkill), talents C_Traits as the Talents tab reads
-- them. Nothing new is asked of the client.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local M = {}
TA:RegisterModule("ForeverSessionCheck", M)

local CHECK_DELAY = 6        -- seconds after login: spell data and bags settle
local SKILL_BEHIND = 10      -- a skill this many points under its cap is listed
local EQUIP_SLOTS = 19

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local isSecret = _G.issecretvalue or function() return false end
local function Plain(v) if v == nil or isSecret(v) then return nil end return v end

local function Store()
    if not TA.db then return nil end
    TA.db.sessionSnap = TA.db.sessionSnap or {}
    return TA.db.sessionSnap
end

local function CharKey()
    local guid = Plain(Try(UnitGUID, "player"))
    if guid then return guid end
    local name, realm = Plain(Try(UnitName, "player")), Plain(Try(GetRealmName))
    return name and ((name) .. "-" .. tostring(realm or "?")) or nil
end

-- ─── READS ─────────────────────────────────────────────────────────────────

local function Equipped()
    local out = {}
    for slot = 1, EQUIP_SLOTS do
        local id = Plain(Try(GetInventoryItemID, "player", slot))
        if id then out[slot] = id end
    end
    return out
end

local function ItemName(id)
    local name
    if C_Item and C_Item.GetItemNameByID then name = Try(C_Item.GetItemNameByID, id) end
    if not name and C_Item and C_Item.GetItemInfo then name = Try(C_Item.GetItemInfo, id) end
    return Plain(name) or ("item " .. tostring(id))
end

local function Unspent()
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits
            and C_Traits.GetConfigInfo and C_Traits.GetTreeCurrencyInfo) then return nil end
    local configID = Try(C_ClassTalents.GetActiveConfigID)
    local cfg = configID and Try(C_Traits.GetConfigInfo, configID)
    if type(cfg) ~= "table" or type(cfg.treeIDs) ~= "table" then return nil end
    local total, any = 0, false
    for _, treeID in ipairs(cfg.treeIDs) do
        local list = Try(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
        if type(list) == "table" then
            for _, c in ipairs(list) do
                local q = type(c) == "table" and tonumber(Plain(c.quantity))
                if q then total = total + q; any = true end
            end
        end
    end
    return any and total or nil
end

--- Weapon skill of what you hold (main hand, off hand, ranged) and Defense,
--- when well under the cap. Uses ForeverCharacter's readers.
local function SkillsBehind()
    local FC = TA:GetModule("ForeverCharacter")
    if not (FC and FC._ReadSkillLines and FC._WeaponSkillFor) then return nil end
    local lines = FC._ReadSkillLines()
    local byID = {}
    for _, l in ipairs(lines) do if l.id then byID[l.id] = l end end
    local out, seen = {}, {}
    local function Check(id, label)
        local l = id and byID[id]
        if l and l.rank and l.max and not seen[id] and (l.max - l.rank) >= SKILL_BEHIND then
            seen[id] = true
            out[#out + 1] = { label = label, name = l.name, rank = l.rank, max = l.max }
        end
    end
    for _, hand in ipairs({ { 16, "Main hand" }, { 17, "Off hand" }, { 18, "Ranged" } }) do
        Check(FC._WeaponSkillFor(hand[1]), hand[2])
    end
    Check(95, "Defense")
    return out
end

-- ─── SNAPSHOT ─────────────────────────────────────────────────────────────

local function TakeSnapshot()
    local s, key = Store(), CharKey()
    if not (s and key) then return end
    local R = TA:GetModule("ForeverRotation")
    local level = tonumber(Plain(Try(UnitLevel, "player")))
    local due = {}
    for _, d in ipairs((R and R.TrainableNow and level and R:TrainableNow(level)) or {}) do
        due[d.name] = d.label
    end
    s[key] = {
        at = time and time() or nil,
        level = level,
        equipped = Equipped(),
        due = due,
        name = Plain(Try(UnitName, "player")),
    }
end

-- ─── REPORT ───────────────────────────────────────────────────────────────

--- Build the report lines. @return lines, actionable count
function M:Build()
    local s, key = Store(), CharKey()
    local prev = s and key and s[key]
    local level = tonumber(Plain(Try(UnitLevel, "player")))
    local name = Plain(Try(UnitName, "player")) or "this character"
    local lines, n = {}, 0
    local function Add(t) lines[#lines + 1] = t end

    if prev then
        local when = prev.at and date and date("%Y-%m-%d %H:%M", prev.at) or "last session"
        Add(("%s, level %s -- since %s"):format(name, tostring(level or "?"), when))
        if level and prev.level and level > prev.level then
            Add(("Level %d -> %d."):format(prev.level, level))
        end
    else
        Add(("First look at %s, level %s. ToonAge has no earlier snapshot, so this is "
            .. "everything due right now."):format(name, tostring(level or "?")))
    end
    Add("")

    local R = TA:GetModule("ForeverRotation")
    local due, ranked, covered
    if R and R.TrainableNow and level then due, ranked, covered = R:TrainableNow(level) end
    if due ~= nil and ranked and covered and ranked > covered then
        -- Never "nothing due" for spells ToonAge can't check (non-Mage classes
        -- until rank data exists for them).
        Add(("Training: rank data covers %d of your %d ranked spells -- check your "
            .. "trainer for the rest."):format(covered, ranked))
    end
    if due == nil then
        Add("Training: no spell catalog yet (Harvest tab -> Scan spell catalog).")
    elseif #due > 0 then
        Add(("Train now (%d):"):format(#due))
        for _, d in ipairs(due) do
            local new = not (prev and prev.due and prev.due[d.name])
            Add(("  %s %s  (trainable since level %d)%s"):format(d.name, d.label, d.learned,
                (prev and new) and "  -- new" or ""))
            n = n + 1
        end
        Add("  After training, drag the new ranks onto your bars.")
        Add("")
    end

    local bars = R and R.BarsBelow and R:BarsBelow()
    if bars and #bars > 0 then
        Add(("Lower ranks on your bars (%d):"):format(#bars))
        for _, o in ipairs(bars) do
            Add(("  %s: %s on %s -- %s is known"):format(o.name, o.haveLabel, o.where, o.bestLabel))
            n = n + 1
        end
        Add("")
    end

    local unspent = Unspent()
    if unspent and unspent > 0 then
        Add(("Unspent talent points: %d (Talents tab)."):format(unspent))
        Add("")
        n = n + 1
    end

    local behind = SkillsBehind()
    if behind and #behind > 0 then
        Add("Skills well below the cap for your level:")
        for _, b in ipairs(behind) do
            if b.label == "Defense" then
                Add(("  Defense %d / %d -- rises by being hit"):format(b.rank, b.max))
            else
                Add(("  %s: %s %d / %d -- fight with this weapon type to raise it")
                    :format(b.label, b.name, b.rank, b.max))
            end
            n = n + 1
        end
        Add("")
    end

    -- Bag upgrades, with the Gear tab's verdict (weapon DPS, armor, stats;
    -- your best armour type; Dual Wield) -- one judgement everywhere.
    local FG = TA:GetModule("ForeverGear")
    local ups = FG and FG.BagUpgrades and FG.BagUpgrades()
    if ups and #ups > 0 then
        -- "Upgrade" means better on every number the client reports. A trade-off
        -- is counted under its own name, never under "upgrades".
        local better, trades = {}, 0
        for _, u in ipairs(ups) do
            if u.verdict == "better" then better[#better + 1] = u
            elseif u.verdict == "trade" then trades = trades + 1 end
        end
        if #better + trades > 0 then
            Add(("Bag check (Gear tab): %d clear upgrade%s, %d trade-off%s.")
                :format(#better, #better == 1 and "" or "s", trades, trades == 1 and "" or "s"))
            for _, u in ipairs(better) do
                Add(("  %s: %s -- %s"):format(u.slot, tostring(u.name), u.diff or ""))
                n = n + 1
            end
            Add("")
        end
    end

    if prev and prev.equipped then
        local now, changed = Equipped(), {}
        for slot, id in pairs(now) do
            if prev.equipped[slot] ~= id then changed[#changed + 1] = ItemName(id) end
        end
        if #changed > 0 then
            table.sort(changed)
            Add("Equipped since last session: " .. table.concat(changed, ", ") .. ".")
            Add("")
        end
    end

    if n == 0 then Add("Nothing due. Everything checked is current.") end
    return lines, n
end

function M:Show()
    local lines = self:Build()
    if TA.ShowCopyWindow then
        TA:ShowCopyWindow("ToonAge -- since last session", table.concat(lines, "\n"))
    end
end

function M:AutoCheck()
    if TA.db and TA.db.sessionCheck == false then TakeSnapshot() return end
    local ok, lines, n = pcall(self.Build, self)
    if ok and n and n > 0 then
        local link = TA.MakeSlashLink and TA:MakeSlashLink("since", "Show") or "/ta since"
        TA:Raw(TA.LOG.OUTPUT, ("|cFFFFD100[ToonAge]|r %d thing%s due since last session. %s")
            :format(n, n == 1 and "" or "s", link))
    end
    -- The new baseline is taken now as well as at logout, so a crash or a
    -- killed client still leaves a snapshot to compare with next time.
    pcall(TakeSnapshot)
end

M.SlashCommands = {
    since = function(self) self:Show() end,
}

function M:OnEvent(event)
    if event == "PLAYER_LOGOUT" then pcall(TakeSnapshot) end
end

-- PLAYER_LOGOUT fires on /reload as well as on a real logout, and is the last
-- moment before SavedVariables are written.
M.Events = { "PLAYER_LOGOUT" }

--- Init runs inside TA:OnLogin, on the first PLAYER_ENTERING_WORLD of every
--- UI load -- which includes /reload. A reload re-saves the snapshot seconds
--- earlier, so a snapshot younger than RELOAD_WINDOW means "this is a reload
--- or a quick relog": the check still refreshes the baseline but does not
--- announce the same list again.
local RELOAD_WINDOW = 15 * 60

function M:Init()
    if not TA.IsForever then self._disabled = true return end
    local s, key = Store(), CharKey()
    local prev = s and key and s[key]
    local recent = prev and prev.at and time and (time() - prev.at) < RELOAD_WINDOW
    C_Timer.After(CHECK_DELAY, function()
        if recent then pcall(TakeSnapshot) else self:AutoCheck() end
    end)
end

return M
