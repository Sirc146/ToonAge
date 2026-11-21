-- ToonAge/Modules/Forever/LootWatch.lua  (WoW Forever)
--
-- Private Dungeon "Loot Watch" toast notification.
-- Styled as a compact dark-gold pill with a circular item icon and run-wide
-- Need counter badge (zero Blizzard UI taint, never posts to party chat).
--
-- Alerts you LIVE as party members click Need — even BEFORE you press Need/Greed:
--   1. Off-class / off-armor / off-stat Need (e.g. Warrior/Rogue needing Cloth +Int,
--      or Cloth caster needing Mail/Plate/+Strength)
--   2. BoE green Need (quality == 2, bindType == 2)
--   3. Repeat Need (3+ Needs by the same player in the current dungeon run)
--   4. Contested Need (another player rolls Need on an item you rolled Need on, or
--      you roll Need on an item someone already rolled Need on)
--
-- Tracks per-player Need rolls for the CURRENT run only (auto-resets on leaving
-- the party or instance). Hover pauses fade and shows that player's Need history
-- for this run. Click dismisses immediately. Shift-drag repositions.
-- Use /ta lootwatch to preview the toast anytime in-game.

local TA = ToonAge
local U  = TA.Utils

local LW = {}
TA:RegisterModule("ForeverLootWatch", LW)

LW.activeRolls = {}   -- rollID / itemLink -> itemInfo
LW.myNeeds     = {}   -- itemLink -> true
LW.itemNeeders = {}   -- itemLink -> { { name=, class=, reason= }, ... }
LW.runNeeds    = {}   -- playerName -> { { link=, name=, reason=, ts= }, ... }
LW._queue      = {}   -- queued alerts if multiple fire back-to-back

local DISPLAY_SEC = 6.0
local FADE_SEC    = 0.45

local ARMOR_SUBCLASS = {
    [1] = "Cloth",
    [2] = "Leather",
    [3] = "Mail",
    [4] = "Plate",
    [6] = "Shield",
}

-- Classes that legitimately wear each armor type for main-spec dungeon upgrades.
local MAX_ARMOR_CLASS = {
    MAGE    = 1, PRIEST  = 1, WARLOCK = 1,
    ROGUE   = 2, DRUID   = 2,
    HUNTER  = 3, SHAMAN  = 3,
    WARRIOR = 4, PALADIN = 4,
}

local PURE_MELEE_NON_MANA = { WARRIOR = true, ROGUE = true }
local PURE_CASTER_CLOTH   = { MAGE = true, PRIEST = true, WARLOCK = true }

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return select(2, unpack(res))
end

local function Secret(v)
    if v == nil then return false end
    if U and U.IsSecret and U.IsSecret(v) then return true end
    if issecretvalue and issecretvalue(v) then return true end
    return false
end

local function PlainStr(v)
    if v == nil or Secret(v) or type(v) ~= "string" then return nil end
    return v ~= "" and v or nil
end

local function PlainNum(v)
    if v == nil or Secret(v) then return nil end
    return tonumber(v)
end

local function IsEnabled()
    if TA.db and TA.db.lootWatch == false then return false end
    return true
end

-- Convert a Blizzard global format string like "%s has selected Need for: %s"
-- into a Lua pattern "^(.-) has selected Need for: (.+)$".
local function FmtToPattern(fmt, fallback)
    if type(fmt) ~= "string" or fmt == "" then return fallback end
    local p = fmt:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    p = p:gsub("%%%d+%%%$s", "(.+)")
    p = p:gsub("%%s", "(.+)")
    -- First capture non-greedy so player names never swallow item links
    p = p:gsub("^%(%.%+%)", "(.-)", 1)
    return "^" .. p .. "$"
end

local PAT_NEED_OTHER = FmtToPattern(_G.LOOT_ROLL_NEED, "^(.-) has selected Need for: (.+)$")
local PAT_NEED_SELF  = FmtToPattern(_G.LOOT_ROLL_NEED_SELF, "^You have selected Need for: (.+)$")

--- Parse a CHAT_MSG_LOOT line for a Need selection.
--- Returns who ("SELF" or playerName), itemLink (or nil when not a Need line).
function LW.ParseNeedMessage(msg)
    local s = PlainStr(msg)
    if not s then return nil, nil end
    local selfItem = s:match(PAT_NEED_SELF)
    if selfItem then
        local link = selfItem:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)") or selfItem:match("(%[.-%])") or selfItem
        return "SELF", link
    end
    local who, otherItem = s:match(PAT_NEED_OTHER)
    if who and otherItem then
        local link = otherItem:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)") or otherItem:match("(%[.-%])") or otherItem
        local cleanWho = who:gsub("%-.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if cleanWho ~= "" then
            return cleanWho, link
        end
    end
    return nil, nil
end

--- Look up a party/raid member's class token (e.g. "WARRIOR", "HUNTER").
function LW.ClassForPlayer(name)
    if type(name) ~= "string" or name == "" then return nil end
    local target = name:gsub("%-.*$", "")
    local myName = PlainStr(Try(UnitName, "player"))
    if myName and myName == target then
        local _, tok = Try(UnitClass, "player")
        return PlainStr(tok)
    end
    for i = 1, 4 do
        local u = "party" .. i
        local pn = PlainStr(Try(UnitName, u))
        if pn and pn:gsub("%-.*$", "") == target then
            local _, tok = Try(UnitClass, u)
            return PlainStr(tok)
        end
    end
    for i = 1, 40 do
        local u = "raid" .. i
        local pn = PlainStr(Try(UnitName, u))
        if pn and pn:gsub("%-.*$", "") == target then
            local _, tok = Try(UnitClass, u)
            return PlainStr(tok)
        end
    end
    return nil
end

--- Inspect an item link into structured metadata for rule evaluation.
function LW.InspectItem(link)
    local s = PlainStr(link)
    if not s then return nil end
    local name = s:match("%[(.-)%]") or s
    local icon, classID, subClassID, equipLoc, quality, bindType
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, eq, ic, cID, scID = Try(C_Item.GetItemInfoInstant, s)
        equipLoc = PlainStr(eq)
        icon = ic
        classID = PlainNum(cID)
        subClassID = PlainNum(scID)
    end
    if C_Item and C_Item.GetItemInfo then
        local nm, _, q, _, _, _, _, _, eq2, ic2, _, c2, sc2, bt = Try(C_Item.GetItemInfo, s)
        if PlainStr(nm) then name = PlainStr(nm) end
        quality = PlainNum(q)
        equipLoc = equipLoc or PlainStr(eq2)
        icon = icon or ic2
        classID = classID or PlainNum(c2)
        subClassID = subClassID or PlainNum(sc2)
        bindType = PlainNum(bt) -- 2 = Bind on Equip
    end
    local stats = {}
    if C_Item and C_Item.GetItemStats then
        local tbl = Try(C_Item.GetItemStats, s)
        if type(tbl) == "table" then
            stats.str = PlainNum(tbl.ITEM_MOD_STRENGTH_SHORT) or 0
            stats.agi = PlainNum(tbl.ITEM_MOD_AGILITY_SHORT) or 0
            stats.int = PlainNum(tbl.ITEM_MOD_INTELLECT_SHORT) or 0
            stats.spi = PlainNum(tbl.ITEM_MOD_SPIRIT_SHORT) or 0
            stats.sp  = (PlainNum(tbl.ITEM_MOD_SPELL_POWER_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_FROST_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_FIRE_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_NATURE_DAMAGE_DONE_SHORT) or 0)
                      + (PlainNum(tbl.ITEM_MOD_HOLY_DAMAGE_DONE_SHORT) or 0)
            stats.ap  = PlainNum(tbl.ITEM_MOD_ATTACK_POWER_SHORT) or 0
        end
    end
    return {
        link = s,
        name = name,
        icon = icon,
        quality = quality,
        classID = classID,
        subClassID = subClassID,
        equipLoc = equipLoc,
        bindType = bindType,
        stats = stats,
    }
end

--- Pure rule engine: evaluate whether a party member's Need roll should alert.
--- Returns nil (no alert) or { severity = "goblin"|"contested", title, detail, reason, count }.
function LW.EvaluateNeed(rollerName, rollerClass, item, myRolledNeed, runCount)
    if type(rollerName) ~= "string" or rollerName == "" or type(item) ~= "table" then
        return nil
    end
    local count = tonumber(runCount) or 1
    local stats = item.stats or {}
    local isArmor = (item.classID == 4) and (item.equipLoc ~= "INVTYPE_CLOAK")
    local armorSub = isArmor and (item.subClassID or 0) or 0
    local armorName = ARMOR_SUBCLASS[armorSub]
    local maxArmor = rollerClass and MAX_ARMOR_CLASS[rollerClass] or nil

    local reasons = {}
    local isGoblin = false

    -- 1. Armor class impossible to wear (e.g. Cloth caster needing Leather/Mail/Plate)
    if isArmor and maxArmor and armorSub >= 1 and armorSub <= 4 and armorSub > maxArmor then
        isGoblin = true
        reasons[#reasons + 1] = "cannot wear " .. tostring(armorName or "armor")
    end

    -- 2. Non-mana melee (Warrior / Rogue) needing Cloth or pure caster stats
    if rollerClass and PURE_MELEE_NON_MANA[rollerClass] then
        if isArmor and armorSub == 1 then
            isGoblin = true
            reasons[#reasons + 1] = "melee on Cloth"
        elseif ((stats.int or 0) > 0 or (stats.sp or 0) > 0) and (stats.str or 0) == 0 and (stats.agi or 0) == 0 and (stats.ap or 0) == 0 then
            isGoblin = true
            reasons[#reasons + 1] = "pure caster stats"
        end
    end

    -- 3. Cloth caster needing pure physical Str/Agi/AP gear
    if rollerClass and PURE_CASTER_CLOTH[rollerClass] then
        if ((stats.str or 0) > 0 or (stats.agi or 0) > 0 or (stats.ap or 0) > 0) and (stats.int or 0) == 0 and (stats.sp or 0) == 0 and (stats.spi or 0) == 0 then
            isGoblin = true
            reasons[#reasons + 1] = "caster on melee stats"
        end
    end

    -- 4. Hunter needing Cloth +Spell Power
    if rollerClass == "HUNTER" and isArmor and armorSub == 1 and (stats.sp or 0) > 0 then
        isGoblin = true
        reasons[#reasons + 1] = "Hunter on Cloth Spell Power"
    end

    -- 5. BoE Green Need
    if item.quality == 2 and item.bindType == 2 then
        isGoblin = true
        reasons[#reasons + 1] = "BoE green Need"
    end

    -- 6. Repeat Needer in a single dungeon run (3+ Needs)
    if count >= 3 then
        isGoblin = true
        reasons[#reasons + 1] = string.format("%d Needs this run", count)
    end

    local classTag = rollerClass and (" (" .. rollerClass:sub(1, 1) .. rollerClass:sub(2):lower() .. ")") or ""
    if isGoblin then
        local why = table.concat(reasons, " · ")
        return {
            severity = "goblin",
            title = "Loot Watch · " .. rollerName .. classTag,
            detail = string.format("Need: %s (%s)", tostring(item.name or "Item"), why),
            reason = why,
            count = count,
            roller = rollerName,
            icon = item.icon,
        }
    end

    if myRolledNeed then
        return {
            severity = "contested",
            title = "Contested Need · " .. rollerName .. classTag,
            detail = string.format("Also rolled Need on %s", tostring(item.name or "Item")),
            reason = "contested your Need",
            count = count,
            roller = rollerName,
            icon = item.icon,
        }
    end

    return nil
end

--- Clear per-run loot tracking (called on leaving group or exiting dungeon).
function LW.ResetRun()
    LW.activeRolls = {}
    LW.myNeeds = {}
    LW.itemNeeders = {}
    LW.runNeeds = {}
    LW._queue = {}
end

-- ─── POOLED MODERN AZEROTH TOAST FRAME (0 CHURN, ZERO TAINT) ──────────────

local function ToastFrame()
    local f = _G.TALootWatchToast
    if f then return f end
    if type(CreateFrame) ~= "function" or not UIParent then return nil end

    f = CreateFrame("Button", "TALootWatchToast", UIParent)
    f._laKind = "ForeverLootWatch"
    f:SetSize(332, 52)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)

    local pos = TA.db and TA.db.lootWatchPos
    if type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" then
        f:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x, pos.y)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 215)
    end

    -- Dark Modern Azeroth pill body (starts at x=24 so the circular icon overlaps cleanly)
    local pill = CreateFrame("Frame", nil, f)
    pill._laKind = "ForeverLootWatch"
    pill:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -4)
    pill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 4)
    f.pill = pill

    local bg = pill:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.055, 0.075, 0.102, 0.95)
    f.bg = bg

    -- 1px accent border edges
    local function Edge()
        local t = pill:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.910, 0.702, 0.353, 0.90)
        return t
    end
    f.bTop = Edge(); f.bTop:SetHeight(1); f.bTop:SetPoint("TOPLEFT"); f.bTop:SetPoint("TOPRIGHT")
    f.bBot = Edge(); f.bBot:SetHeight(1); f.bBot:SetPoint("BOTTOMLEFT"); f.bBot:SetPoint("BOTTOMRIGHT")
    f.bLft = Edge(); f.bLft:SetWidth(1);  f.bLft:SetPoint("TOPLEFT"); f.bLft:SetPoint("BOTTOMLEFT")
    f.bRgt = Edge(); f.bRgt:SetWidth(1);  f.bRgt:SetPoint("TOPRIGHT"); f.bRgt:SetPoint("BOTTOMRIGHT")

    -- Left circular icon + golden ring halo (matches screenshot toast look)
    local iconBg = f:CreateTexture(nil, "ARTWORK", nil, 0)
    iconBg:SetSize(44, 44)
    iconBg:SetPoint("LEFT", f, "LEFT", 2, 0)
    iconBg:SetColorTexture(0.04, 0.05, 0.07, 1)
    f.iconBg = iconBg

    local icon = f:CreateTexture(nil, "ARTWORK", nil, 1)
    icon:SetSize(38, 38)
    icon:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    f.icon = icon

    local ring = f:CreateTexture(nil, "OVERLAY", nil, 2)
    ring:SetSize(48, 48)
    ring:SetPoint("CENTER", iconBg, "CENTER", 0, 0)
    if U and U.TEX_RING then
        ring:SetTexture(U.TEX_RING)
    else
        ring:SetTexture("Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga")
    end
    f.ring = ring

    -- Bottom-right circular Need counter badge (e.g. (3))
    local badgeBg = f:CreateTexture(nil, "OVERLAY", nil, 3)
    badgeBg:SetSize(18, 18)
    badgeBg:SetPoint("BOTTOMRIGHT", iconBg, "BOTTOMRIGHT", 3, -2)
    badgeBg:SetColorTexture(0.08, 0.10, 0.14, 0.98)
    f.badgeBg = badgeBg

    local badgeRing = f:CreateTexture(nil, "OVERLAY", nil, 4)
    badgeRing:SetSize(20, 20)
    badgeRing:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
    if U and U.TEX_RING then
        badgeRing:SetTexture(U.TEX_RING)
    else
        badgeRing:SetTexture("Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga")
    end
    f.badgeRing = badgeRing

    local badgeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badgeText:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
    f.badgeText = badgeText

    -- Title & detail text inside the pill
    local title = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", pill, "TOPLEFT", 30, -8)
    title:SetPoint("TOPRIGHT", pill, "TOPRIGHT", -10, -8)
    if title.SetJustifyH then title:SetJustifyH("LEFT") end
    if title.SetWordWrap then title:SetWordWrap(false) end
    f.title = title

    local detail = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT", pill, "TOPLEFT", 30, -25)
    detail:SetPoint("TOPRIGHT", pill, "TOPRIGHT", -10, -25)
    if detail.SetJustifyH then detail:SetJustifyH("LEFT") end
    if detail.SetWordWrap then detail:SetWordWrap(false) end
    f.detail = detail

    f:SetScript("OnDragStart", function(self)
        if self.StartMoving then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
        if TA.db and self.GetPoint then
            local p, _, rp, x, y = self:GetPoint()
            TA.db.lootWatchPos = { point = p, relPoint = rp, x = x, y = y }
        end
    end)
    f:SetScript("OnClick", function(self)
        self._elapsed = DISPLAY_SEC + FADE_SEC + 1
        self:Hide()
        self:SetScript("OnUpdate", nil)
        LW._PumpQueue()
    end)
    f:SetScript("OnEnter", function(self)
        self._paused = true
        if GameTooltip and self._alert then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self._alert.title or "Loot Watch", 1, 0.82, 0)
            local hist = self._alert.roller and LW.runNeeds[self._alert.roller]
            if type(hist) == "table" and #hist > 0 then
                GameTooltip:AddLine("Need rolls this run:", 0.72, 0.80, 0.88)
                for i, h in ipairs(hist) do
                    local tag = h.reason and (" (" .. h.reason .. ")") or ""
                    GameTooltip:AddLine(string.format("%d. %s%s", i, tostring(h.name or h.link), tag), 0.95, 0.95, 0.95)
                end
            else
                GameTooltip:AddLine(self._alert.detail or "", 0.95, 0.95, 0.95, true)
            end
            GameTooltip:AddLine("Click to dismiss · Drag to move", 0.55, 0.62, 0.70)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function(self)
        self._paused = false
        if GameTooltip then GameTooltip:Hide() end
    end)

    f:Hide()
    return f
end

function LW._PumpQueue()
    if #LW._queue == 0 then return end
    local nextAlert = table.remove(LW._queue, 1)
    LW.ShowToast(nextAlert)
end

--- Display one alert on the pooled toast frame.
function LW.ShowToast(alert)
    if type(alert) ~= "table" then return false end
    local f = ToastFrame()
    if not f then return false end
    if f.IsShown and f:IsShown() then
        LW._queue[#LW._queue + 1] = alert
        return true
    end

    local isGoblin = (alert.severity == "goblin")
    local border = isGoblin and { 0.92, 0.32, 0.28 } or { 0.910, 0.702, 0.353 }
    local titleC = isGoblin and { 1.00, 0.52, 0.42 } or { 0.96, 0.82, 0.36 }

    for _, edge in ipairs({ f.bTop, f.bBot, f.bLft, f.bRgt }) do
        if edge and edge.SetColorTexture then edge:SetColorTexture(border[1], border[2], border[3], 0.92) end
    end
    if f.ring and f.ring.SetVertexColor then f.ring:SetVertexColor(border[1], border[2], border[3], 1) end
    if f.badgeRing and f.badgeRing.SetVertexColor then f.badgeRing:SetVertexColor(border[1], border[2], border[3], 1) end
    if f.icon and f.icon.SetTexture then
        f.icon:SetTexture(alert.icon or "Interface\\Icons\\INV_Misc_Coin_02")
    end
    if f.badgeText then
        f.badgeText:SetText(tostring(alert.count or 1))
        f.badgeText:SetTextColor(1, 0.96, 0.88, 1)
    end
    if f.title then
        f.title:SetText(alert.title or "Loot Watch")
        f.title:SetTextColor(titleC[1], titleC[2], titleC[3], 1)
    end
    if f.detail then
        f.detail:SetText(alert.detail or "")
        f.detail:SetTextColor(0.94, 0.96, 0.98, 1)
    end

    f._alert = alert
    f._elapsed = 0
    f._paused = false
    if f.SetAlpha then f:SetAlpha(1) end
    f:Show()

    -- Subtle Blizzard UI notification sound (no custom sound files needed)
    if type(PlaySound) == "function" and SOUNDKIT then
        pcall(PlaySound, isGoblin and (SOUNDKIT.RAID_WARNING or SOUNDKIT.IG_QUEST_LIST_OPEN) or (SOUNDKIT.TELL_MESSAGE or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON))
    end

    f:SetScript("OnUpdate", function(self, dt)
        if self._paused then return end
        self._elapsed = (self._elapsed or 0) + (tonumber(dt) or 0)
        if self._elapsed >= DISPLAY_SEC + FADE_SEC then
            self:Hide()
            self:SetScript("OnUpdate", nil)
            LW._PumpQueue()
        elseif self._elapsed > DISPLAY_SEC then
            local rem = 1 - ((self._elapsed - DISPLAY_SEC) / FADE_SEC)
            if self.SetAlpha then self:SetAlpha(math.max(0, rem)) end
        end
    end)
    return true
end

-- ─── EVENT HANDLER ─────────────────────────────────────────────────────────

function LW:HandleLootMessage(msg, classOverride, itemOverride)
    if not IsEnabled() then return nil end
    local who, link = LW.ParseNeedMessage(msg)
    if not who or not link then return nil end

    local item = itemOverride or LW.activeRolls[link] or LW.InspectItem(link)
    if not item then return nil end
    LW.activeRolls[link] = item

    if who == "SELF" then
        LW.myNeeds[link] = true
        -- Check if someone ALREADY rolled Need on this item before we did
        local prior = LW.itemNeeders[link]
        if type(prior) == "table" and #prior > 0 then
            local last = prior[#prior]
            local cnt = LW.runNeeds[last.name] and #LW.runNeeds[last.name] or 1
            local alert = LW.EvaluateNeed(last.name, last.class, item, true, cnt)
            if alert then LW.ShowToast(alert) end
            return alert
        end
        return nil
    end

    local cls = classOverride or LW.ClassForPlayer(who)
    LW.runNeeds[who] = LW.runNeeds[who] or {}
    local hist = LW.runNeeds[who]
    local newCount = #hist + 1

    local alert = LW.EvaluateNeed(who, cls, item, LW.myNeeds[link] == true, newCount)
    hist[newCount] = {
        link = link,
        name = item.name,
        reason = alert and alert.reason or nil,
        ts = time and time() or 0,
    }
    LW.itemNeeders[link] = LW.itemNeeders[link] or {}
    LW.itemNeeders[link][#LW.itemNeeders[link] + 1] = { name = who, class = cls }

    if alert then
        LW.ShowToast(alert)
    end
    return alert
end

function LW:OnEvent(event, arg1)
    if event == "START_LOOT_ROLL" then
        local link = (type(GetLootRollItemLink) == "function") and Try(GetLootRollItemLink, arg1) or nil
        if PlainStr(link) then
            local info = LW.InspectItem(link)
            if info then LW.activeRolls[info.link] = info end
        end
    elseif event == "CHAT_MSG_LOOT" then
        self:HandleLootMessage(arg1)
    elseif event == "GROUP_LEFT" then
        LW.ResetRun()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local inGrp = (type(IsInGroup) == "function") and Try(IsInGroup) or false
        if not inGrp then LW.ResetRun() end
    end
end

LW.Events = {
    "START_LOOT_ROLL",
    "CHAT_MSG_LOOT",
    "GROUP_LEFT",
    "PLAYER_ENTERING_WORLD",
}

LW.SlashCommands = {
    lootwatch = function()
        LW.ShowToast({
            severity = "goblin",
            title = "Loot Watch · SampleHunter (Hunter)",
            detail = "Need: Robe of the Magi (Hunter on Cloth Spell Power · 3 Needs this run)",
            reason = "Hunter on Cloth Spell Power",
            count = 3,
            roller = "SampleHunter",
            icon = "Interface\\Icons\\INV_Chest_Cloth_25",
        })
    end,
}

return LW
