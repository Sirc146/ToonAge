-- ToonAge/Modules/Forever/MageSuggest.lua
--
-- A suggested next spell for a Forever Mage, drawn as an icon in its own
-- frame. The frame does not cast, does not sit on an action button, and does
-- not glow one.
--
-- Priority is the Frost leveling guide, the same source MageGuidance.lua
-- cites for Frost Armor, Arcane Intellect, the wand, Fire Blast, and
-- Frost Nova:
--   https://www.icy-veins.com/wow-forever/frost-mage-leveling
-- Read 2026-11-13 (page updated 2026-11-10). Spell ids are not written here.
-- BuildSpells copies them from Data/Forever/SpellRanks.lua, Spells.lua, and
-- the Ice Lance row of Data/Forever/Talents.lua (measured spell 1312002).
-- Learned ranks use MageGuidance's check: IsPlayerSpell and IsSpellKnown,
-- by spell id, through Compat.SpellLearned. Unknown is not "unlearned".
--
-- A secret or nil cooldown, mana value, or aura list makes that rule
-- unknown. The other rules still run. issecretvalue and canaccessvalue are
-- both consulted when the client has them, before any arithmetic.

local TA = ToonAge

local M = {}
TA:RegisterModule("ForeverMageSuggest", M)

local UPDATE_INTERVAL = 0.15
-- The guide says to use the wand when mana is the problem. It does not
-- give a fraction. MageGuidance.lua records that an older example percent
-- is not a cutoff. This is only where the suggestion switches to Shoot.
local WAND_MANA_FRACTION = 0.20
-- A shorter return is the global cooldown, so the icon does not go blank
-- between casts. A longer return is the spell's own cooldown.
local GCD_SECONDS = 1.5
-- The guide: Cone of Cold when Winter's Chill reaches 5 stacks.
local WINTERS_CHILL_STACKS = 5

local WANTED = {
    ["Frostbolt"] = "frostbolt",
    ["Fire Blast"] = "fireBlast",
    ["Frost Nova"] = "frostNova",
    ["Cone of Cold"] = "cone",
    ["Shoot"] = "shoot",
    ["Frost Armor"] = "frostArmor",
    ["Ice Armor"] = "iceArmor",
    ["Arcane Intellect"] = "intellect",
    ["Ice Lance"] = "iceLance",
}

local FROZEN = { ["Frostbite"] = true, ["Frost Nova"] = true, ["Freeze"] = true }

M._blocked = 0
M._forbidden = 0

function M.ValueKnown(value)
    if value == nil then return false end
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret == true then return false end
    end
    if type(canaccessvalue) == "function" then
        local ok, access = pcall(canaccessvalue, value)
        if not ok or access ~= true then return false end
    end
    return true
end

function M.ManaState(current, maxValue)
    if not M.ValueKnown(current) or not M.ValueKnown(maxValue) then return "unknown" end
    if type(current) ~= "number" or type(maxValue) ~= "number" then return "unknown" end
    if current ~= current or maxValue ~= maxValue then return "unknown" end
    if maxValue <= 0 then return "unknown" end
    if current / maxValue <= WAND_MANA_FRACTION then return "low" end
    return "ok"
end

function M.CooldownState(start, duration)
    if not M.ValueKnown(start) or not M.ValueKnown(duration) then return "unknown" end
    if type(start) ~= "number" or type(duration) ~= "number" then return "unknown" end
    if start ~= start or duration ~= duration then return "unknown" end
    if duration <= 0 then return "ready" end
    if duration <= GCD_SECONDS then return "ready" end
    return "down"
end

function M.MeleeState(dist)
    if not M.ValueKnown(dist) then return nil end
    if dist == true or dist == 1 then return true end
    if dist == false or dist == 0 then return false end
    return nil
end

local function AddSpell(bucket, name, spellID, learned)
    local key = WANTED[name]
    if not key or type(spellID) ~= "number" then return end
    local row = bucket[key]
    if not row then
        row = { name = name, ids = {}, learned = {} }
        bucket[key] = row
    end
    for _, have in ipairs(row.ids) do
        if have == spellID then return end
    end
    row.ids[#row.ids + 1] = spellID
    row.learned[spellID] = type(learned) == "number" and learned or 0
end

function M.BuildSpells(ranks, mageSpells, talents)
    local bucket = {}
    if type(ranks) == "table" then
        for name, chain in pairs(ranks) do
            if type(chain) == "table" then
                for _, rank in ipairs(chain) do
                    if type(rank) == "table" then
                        AddSpell(bucket, name, rank.id, rank.learned or rank.n)
                    end
                end
            end
        end
    end
    if type(mageSpells) == "table" then
        for _, row in ipairs(mageSpells) do
            if type(row) == "table" then
                AddSpell(bucket, row.name, row.id, row.learned)
            end
        end
    end
    if type(talents) == "table" then
        for _, row in ipairs(talents) do
            if type(row) == "table" and row.name == "Ice Lance" then
                AddSpell(bucket, row.name, row.spell, 20)
            end
        end
    end
    for _, row in pairs(bucket) do
        table.sort(row.ids, function(a, b)
            local la = row.learned[a] or 0
            local lb = row.learned[b] or 0
            if la == lb then return a < b end
            return la < lb
        end)
    end
    return bucket
end

function M.IndexAuras(list)
    if type(list) ~= "table" then return nil end
    local map = {}
    for _, row in ipairs(list) do
        if type(row) == "table" and type(row.name) == "string" then
            if type(row.applications) == "number" then
                map[row.name] = row.applications
            else
                map[row.name] = true
            end
        end
    end
    return map
end

local function Up(map, name)
    if type(map) ~= "table" then return false end
    local value = map[name]
    if value == true then return true end
    if type(value) == "number" and value > 0 then return true end
    return false
end

local function PickReady(state, spells, key, why)
    local spell = spells and spells[key]
    if not spell then return nil end
    local known = state.known or {}
    local cooldown = state.cooldown or {}
    for i = #spell.ids, 1, -1 do
        local spellID = spell.ids[i]
        if known[spellID] == "yes" and cooldown[spellID] == "ready" then
            return { spellID = spellID, name = spell.name, why = why }
        end
    end
    return nil
end

-- One suggestion, or nil when every applicable rule is unknown or unusable.
-- state.mana is "low", "ok", or "unknown". state.melee is true, false, or nil.
-- state.buffs / state.debuffs nil means that aura read was skipped.
function M.Suggest(state, spells)
    if type(state) ~= "table" or state.class ~= "MAGE" then return nil end
    spells = spells or {}

    if state.mana == "low" then
        -- Guide: Shoot from a wand when mana is the problem, including to
        -- finish so the five-second regen rule can start.
        return PickReady(state, spells, "shoot",
            "Suggestion: use the wand when mana is low.")
    end

    if type(state.buffs) == "table" then
        -- Guide: keep Frost Armor (or Ice Armor once you have it) and
        -- Arcane Intellect up. Mage Armor already up is left as it is.
        local armorUp = Up(state.buffs, "Frost Armor") or Up(state.buffs, "Ice Armor")
            or Up(state.buffs, "Mage Armor")
        if not armorUp then
            local ice = PickReady(state, spells, "iceArmor",
                "Suggestion: keep Ice Armor up while leveling.")
            if ice then return ice end
            local frost = PickReady(state, spells, "frostArmor",
                "Suggestion: keep Frost Armor up while leveling.")
            if frost then return frost end
        end
        if not Up(state.buffs, "Arcane Intellect") then
            local intellect = PickReady(state, spells, "intellect",
                "Suggestion: keep Arcane Intellect up.")
            if intellect then return intellect end
        end
    end

    local lanceWhy
    if Up(state.buffs, "Fingers of Frost") then
        lanceWhy = "Suggestion: Ice Lance while Fingers of Frost is up."
    elseif type(state.debuffs) == "table" then
        for name in pairs(FROZEN) do
            if Up(state.debuffs, name) then
                lanceWhy = "Suggestion: Ice Lance while the enemy is frozen."
                break
            end
        end
    end
    if lanceWhy then
        local lance = PickReady(state, spells, "iceLance", lanceWhy)
        if lance then return lance end
    end

    if state.melee == true then
        -- Guide: Frost Nova when they get too close, then step back.
        local nova = PickReady(state, spells, "frostNova",
            "Suggestion: Frost Nova when an enemy is in melee, then step back.")
        if nova then return nova end
    end

    if type(state.debuffs) == "table" then
        local stacks = state.debuffs["Winter's Chill"]
        if type(stacks) == "number" and stacks >= WINTERS_CHILL_STACKS then
            local cone = PickReady(state, spells, "cone",
                "Suggestion: Cone of Cold when Winter's Chill is at five stacks.")
            if cone then return cone end
        end
    end

    if state.melee == true then
        -- Guide: Fire Blast finishes a low-health enemy that is not frozen,
        -- and it is the instant while you are still in melee and Nova is down.
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast is the instant while Frost Nova is not ready.")
        if blast then return blast end
    end

    local bolt = PickReady(state, spells, "frostbolt",
        "Suggestion: Frostbolt is the cast to repeat at range.")
    if bolt then return bolt end

    if state.melee ~= true then
        local blast = PickReady(state, spells, "fireBlast",
            "Suggestion: Fire Blast when Frostbolt is not available.")
        if blast then return blast end
    end
    return nil
end

function M.Spells()
    if M._spells then return M._spells end
    local data = TA.Data or {}
    local book = data.ForeverSpells
    local talents = data.ForeverTalents
    M._spells = M.BuildSpells(
        data.ForeverSpellRanks,
        book and book.MAGE,
        talents and talents.MAGE)
    return M._spells
end

local function CooldownAllowed()
    if not (TA and TA.HasAPI) then return true end
    if TA:HasAPI("C_Spell.GetSpellCooldown") then return true end
    if TA:HasAPI("GetSpellCooldown") then return true end
    return false
end

local function AurasAllowed()
    local modern = false
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        if not (TA and TA.HasAPI and not TA:HasAPI("C_UnitAuras.GetAuraDataByIndex")) then
            modern = true
        end
    end
    local util = AuraUtil and type(AuraUtil.ForEachAura) == "function"
    return modern or util or false
end

local function ManaAllowed()
    if not (TA and TA.HasAPI) then
        return type(UnitPower) == "function" and type(UnitPowerMax) == "function"
    end
    return TA:HasAPI("UnitPower") and TA:HasAPI("UnitPowerMax")
end

function M.ReadState()
    local state = {
        known = {},
        cooldown = {},
        mana = "unknown",
        melee = nil,
        buffs = nil,
        debuffs = nil,
    }
    local compat = TA.Compat
    if not compat then return state end
    if type(compat.UnitClass) == "function" then
        local _, token = compat.UnitClass("player")
        if M.ValueKnown(token) and type(token) == "string" and token ~= "" then
            state.class = token
        end
    end
    if state.class ~= "MAGE" then return state end

    local spells = M.Spells()
    local canLearn = type(compat.SpellLearned) == "function"
    local canCd = CooldownAllowed() and type(compat.GetSpellCooldown) == "function"
    for _, row in pairs(spells) do
        for _, spellID in ipairs(row.ids) do
            local learned = "unknown"
            if canLearn then
                local ok, value = pcall(compat.SpellLearned, spellID)
                if ok and (value == "yes" or value == "no" or value == "unknown") then
                    learned = value
                end
            end
            state.known[spellID] = learned
            if canCd then
                local ok, start, duration = pcall(compat.GetSpellCooldown, spellID)
                if ok then
                    state.cooldown[spellID] = M.CooldownState(start, duration)
                else
                    state.cooldown[spellID] = "unknown"
                end
            else
                state.cooldown[spellID] = "unknown"
            end
        end
    end

    if ManaAllowed() and type(compat.PlayerMana) == "function" then
        local ok, current, maxValue = pcall(compat.PlayerMana)
        if ok then state.mana = M.ManaState(current, maxValue) end
    end

    if AurasAllowed() and type(compat.ReadAuras) == "function" then
        local okH, helpful = pcall(compat.ReadAuras, "player", "HELPFUL")
        local okD, harmful = pcall(compat.ReadAuras, "target", "HARMFUL")
        if okH then state.buffs = M.IndexAuras(helpful) end
        if okD then state.debuffs = M.IndexAuras(harmful) end
    end

    if type(compat.TargetInMelee) == "function" then
        local ok, dist = pcall(compat.TargetInMelee, "target")
        if ok then state.melee = M.MeleeState(dist) end
    end
    return state
end

function M:BlockCounts()
    return self._blocked or 0, self._forbidden or 0
end

function M:NoteBlock(event, addon)
    if not M.ValueKnown(addon) or addon ~= "ToonAge" then return end
    if event == "ADDON_ACTION_BLOCKED" then
        self._blocked = (self._blocked or 0) + 1
    elseif event == "ADDON_ACTION_FORBIDDEN" then
        self._forbidden = (self._forbidden or 0) + 1
    end
end

local function InCombat()
    local compat = TA.Compat
    if compat and type(compat.InCombat) == "function" then
        local ok, locked = pcall(compat.InCombat)
        if ok and locked == true then return true end
    end
    return false
end

local function Saved()
    if not TA.db then return nil end
    TA.db.mageSuggest = TA.db.mageSuggest or {}
    return TA.db.mageSuggest
end

function M:Locked()
    local db = TA.db and TA.db.mageSuggest
    return db and db.locked and true or false
end

local function FontFile()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    return "Fonts\\FRIZQT__.TTF"
end

function M:ApplyLock()
    local frame = self._frame
    if not frame then return end
    if frame.SetMovable then frame:SetMovable(not self:Locked()) end
end

function M:ApplyFrame()
    local frame = self._frame
    if not frame then return end
    if InCombat() then
        self._deferred = true
        return
    end
    self._deferred = nil
    if not self._placed and TA.db then
        self._placed = true
        local db = TA.db.mageSuggest
        if db and type(db.point) == "string" and M.ValueKnown(db.x) and M.ValueKnown(db.y)
            and type(db.x) == "number" and type(db.y) == "number" then
            frame:ClearAllPoints()
            frame:SetPoint(db.point, UIParent, db.rel or "CENTER", db.x, db.y)
        end
    end
    self:ApplyLock()
    if self._wantShow then
        if frame.IsShown and not frame:IsShown() then frame:Show() end
    else
        if frame.IsShown and frame:IsShown() then frame:Hide() end
    end
end

local function Paint(frame, suggestion)
    frame.suggestion = suggestion
    if suggestion then
        local tex
        local compat = TA.Compat
        if compat and type(compat.GetSpellTexture) == "function" then
            local ok, icon = pcall(compat.GetSpellTexture, suggestion.spellID)
            if ok and M.ValueKnown(icon) and (type(icon) == "number" or type(icon) == "string") then
                tex = icon
            end
        end
        if tex and frame.icon then
            frame.icon:SetTexture(tex)
            frame.icon:Show()
        elseif frame.icon then
            frame.icon:Hide()
        end
        if frame.label then frame.label:SetText(suggestion.name or "") end
    else
        if frame.icon then frame.icon:Hide() end
        if frame.label then frame.label:SetText("") end
    end
end

function M:Refresh()
    local state = M.ReadState()
    local forever = TA.flavor == "forever"
    local show = forever and state.class == "MAGE"
    local suggestion
    if show then suggestion = M.Suggest(state, M.Spells()) end
    self._wantShow = show and true or false
    if self._frame then Paint(self._frame, suggestion) end
    self:ApplyFrame()
end

local function SavePosition(frame)
    if InCombat() then return end
    if not frame.GetPoint then return end
    local point, _, rel, x, y = frame:GetPoint()
    if type(point) ~= "string" then return end
    if not M.ValueKnown(x) or not M.ValueKnown(y) then return end
    if type(x) ~= "number" or type(y) ~= "number" then return end
    local db = Saved()
    if not db then return end
    db.point = point
    db.rel = type(rel) == "string" and rel or "CENTER"
    db.x = x
    db.y = y
end

function M:CreateFrame()
    if self._frame or type(CreateFrame) ~= "function" or not UIParent then return end
    local frame = CreateFrame("Frame", "ToonAgeMageSuggestFrame", UIParent, "BackdropTemplate")
    frame:SetSize(48, 64)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        if frame.SetBackdropColor then frame:SetBackdropColor(0.05, 0.05, 0.06, 0.85) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.85, 0.65, 0.13, 0.9) end
    end

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOP", 0, -4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    frame.icon = icon

    local label = frame:CreateFontString(nil, "OVERLAY")
    if label.SetFont then label:SetFont(FontFile(), 9, "") end
    label:SetPoint("BOTTOM", 0, 3)
    label:SetSize(46, 12)
    label:SetTextColor(0.92, 0.90, 0.87, 1)
    label:SetText("")
    frame.label = label

    frame:SetScript("OnDragStart", function(self)
        if M:Locked() or InCombat() then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    frame:SetScript("OnEnter", function(self)
        if not self.suggestion or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.suggestion.why or "Suggestion", 0.92, 0.90, 0.87, true)
        GameTooltip:AddLine("Suggestion only. This frame does not cast.", 0.62, 0.59, 0.55, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)

    local function watch(event)
        pcall(frame.RegisterEvent, frame, event)
    end
    watch("ADDON_ACTION_BLOCKED")
    watch("ADDON_ACTION_FORBIDDEN")
    watch("PLAYER_ENTERING_WORLD")
    watch("PLAYER_REGEN_ENABLED")
    watch("PLAYER_REGEN_DISABLED")
    watch("PLAYER_TARGET_CHANGED")
    watch("SPELLS_CHANGED")
    watch("SPELL_UPDATE_COOLDOWN")
    watch("UNIT_AURA")
    watch("UNIT_POWER_UPDATE")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
            M:NoteBlock(event, ...)
            return
        end
        if event == "PLAYER_REGEN_ENABLED" then M._deferred = true end
        M._dirty = true
    end)

    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, dt)
        if not M.ValueKnown(dt) or type(dt) ~= "number" then return end
        elapsed = elapsed + dt
        if elapsed < UPDATE_INTERVAL and not M._dirty and not M._deferred then return end
        if elapsed >= UPDATE_INTERVAL or M._dirty then
            elapsed = 0
            M._dirty = nil
            local ok, err = pcall(M.Refresh, M)
            if not ok and not M._logged then
                M._logged = true
                local log = TA.ErrorLog
                if log and log.Log then pcall(log.Log, log, "MageSuggest", tostring(err)) end
            end
        elseif M._deferred and not InCombat() then
            M:ApplyFrame()
        end
    end)

    -- CreateFrame shows the new frame. It is not secure and it is not a
    -- protected action to hide it. Later Show, Hide, and SetPoint go through
    -- ApplyFrame, which waits for combat to end.
    self._frame = frame
    self._wantShow = false
    frame:Hide()
end

function M:Init()
    self:CreateFrame()
    self._dirty = true
end

return M
