-- ToonAge/Modules/Character/ProfessionOverload.lua
-- Retail gathering Overload reminder.
--
-- The only nodes this can see are the soft target and the mouseover. The
-- client does not expose gathering nodes at a distance, so this file never
-- goes looking for them. Node types and Overload spell ids live in
-- Data/Retail/professions_retail.lua (TA.Data.Overloads). That list is not
-- verified for Midnight.
--
-- The button sits beside the ability tray. It is a secure spell button,
-- hidden in combat, hidden after the Overload is cast, and hidden when the
-- soft target (and the mouseover) stop matching. The icon is a placeholder
-- until Gilder supplies one.

local TA = ToonAge
TA.modules = TA.modules or {}

local OL = {}
TA.ProfessionOverload = OL
TA:RegisterModule("ProfessionOverload", OL)

-- Same gold as the finisher-ready border on the ability tray.
OL.FINISHER_GLOW = { 0.910, 0.702, 0.353 }
OL.REST_GLOW = { 0.55, 0.40, 0.08 }
OL.GLOW_SECONDS = 0.6
-- Gilder's icon replaces this path. Do not tint it.
OL.PLACEHOLDER_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
OL.BUTTON_SIZE = 28

function OL.Secret(v)
    if type(issecretvalue) ~= "function" then return false end
    local ok, res = pcall(issecretvalue, v)
    return ok and res == true
end

function OL.Data()
    return TA.Data and TA.Data.Overloads
end

function OL:Enabled()
    return not (TA.db and TA.db.overloadReminder == false)
end

function OL.InCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

--- Object id from a GameObject GUID. Creature and other kinds are ignored.
--- "GameObject-0-server-instance-zone-objectID-spawn"
function OL.ObjectID(guid)
    if OL.Secret(guid) or type(guid) ~= "string" then return nil end
    local kind, id
    local index = 0
    for part in string.gmatch(guid, "[^%-]+") do
        index = index + 1
        if index == 1 then kind = part
        elseif index == 6 then id = tonumber(part) end
    end
    if kind ~= "GameObject" then return nil end
    return id
end

function OL.Match(data, name, guid)
    if type(data) ~= "table" then return nil end
    local objectID = OL.ObjectID(guid)
    local lname = (not OL.Secret(name) and type(name) == "string") and name:lower() or nil
    for _, node in ipairs(data.nodes or {}) do
        if type(node) == "table" then
            local idHit = node.objectID ~= nil and objectID ~= nil and node.objectID == objectID
            local nameHit = lname and type(node.name) == "string" and node.name:lower() == lname
            if idHit or nameHit then return node end
        end
    end
    return nil
end

function OL.SpellFor(data, node)
    if type(node) ~= "table" then return nil end
    if node.spellID ~= nil then return node.spellID end
    for _, row in ipairs(data and data.spells or {}) do
        if type(row) == "table" and row.profession == node.profession and row.spellID ~= nil then
            return row.spellID
        end
    end
    return nil
end

function OL.NodeLabel(node, sight)
    if type(sight) == "table" and not OL.Secret(sight.name) and type(sight.name) == "string" and sight.name ~= "" then
        return sight.name
    end
    if type(node) == "table" and type(node.name) == "string" and node.name ~= "" then
        return node.name
    end
    local id = type(sight) == "table" and OL.ObjectID(sight.guid) or nil
    if id then return "object " .. tostring(id) end
    return "none"
end

--- "ready", "cooldown", "secret", or "unknown".
--- Secret cooldown fields are refused before any comparison.
function OL.CooldownState(info, now)
    if OL.Secret(info) or type(info) ~= "table" then return "unknown" end
    local start = info.startTime
    if start == nil then start = info.start end
    local duration = info.duration
    local enabled = info.isEnabled
    if OL.Secret(start) or OL.Secret(duration) or OL.Secret(enabled) or OL.Secret(now) then
        return "secret"
    end
    start = tonumber(start) or 0
    duration = tonumber(duration) or 0
    now = tonumber(now) or 0
    if enabled == false then return "cooldown" end
    if duration <= 0 then return "ready" end
    if start > 0 and (start + duration) > now then return "cooldown" end
    return "ready"
end

function OL.ReadCooldown(spellID)
    if not spellID or OL.Secret(spellID) then return "unknown" end
    local fn = C_Spell and C_Spell.GetSpellCooldown
    if type(fn) ~= "function" then return "unknown" end
    local ok, info = pcall(fn, spellID)
    if not ok then return "unknown" end
    local now = type(GetTime) == "function" and GetTime() or 0
    return OL.CooldownState(info, now)
end

function OL.SpellKnown(spellID)
    if not spellID or OL.Secret(spellID) then return false end
    local function Yes(fn, ...)
        if type(fn) ~= "function" then return false end
        local ok, known = pcall(fn, ...)
        return ok and known and true or false
    end
    if C_SpellBook and Yes(C_SpellBook.IsSpellKnown, spellID) then return true end
    if Yes(IsPlayerSpell, spellID) then return true end
    if Yes(IsSpellKnown, spellID) then return true end
    return false
end

function OL.ReadToken(token)
    if type(UnitGUID) ~= "function" then return nil end
    local guid = UnitGUID(token)
    if OL.Secret(guid) or type(guid) ~= "string" or guid == "" then return nil end
    local name
    if type(UnitName) == "function" then
        name = UnitName(token)
        if OL.Secret(name) then name = nil end
    end
    return { name = name, guid = guid, token = token }
end

function OL.BestMatch(data, soft, mouse)
    if type(soft) == "table" then
        local node = OL.Match(data, soft.name, soft.guid)
        if node then return node, soft, "soft" end
    end
    if type(mouse) == "table" then
        local node = OL.Match(data, mouse.name, mouse.guid)
        if node then return node, mouse, "mouse" end
    end
    return nil
end

--- Show only when the reminder is on, out of combat, a node matches, the
--- character knows that Overload, and its cooldown is ready. `held` covers
--- the moment after a cast before the cooldown flips.
function OL.Decide(ctx)
    ctx = ctx or {}
    if ctx.held then return false end
    if ctx.enabled == false then return false end
    if ctx.combat then return false end
    if not ctx.node then return false end
    if not ctx.known then return false end
    if ctx.cooldown ~= "ready" then return false end
    return true
end

function OL.Consider(data, soft, mouse, knownFn, cdFn, opts)
    opts = opts or {}
    local node, sight, via = OL.BestMatch(data, soft, mouse)
    local spellID = OL.SpellFor(data, node)
    local cd = (spellID and cdFn and cdFn(spellID)) or "unknown"
    local known = spellID and knownFn and knownFn(spellID) or false
    local same = opts.pending and type(sight) == "table" and sight.guid == opts.pendingGuid
    local held = same and cd == "ready"
    if opts.pending and not same then held = false end
    if opts.pending and cd ~= "ready" then held = false end
    return {
        show = OL.Decide({
            enabled = opts.enabled ~= false,
            combat = opts.combat and true or false,
            node = node,
            known = known and true or false,
            cooldown = cd,
            held = held and true or false,
        }),
        node = node,
        sight = sight,
        via = via,
        spellID = spellID,
        cooldown = cd,
        known = known and true or false,
        label = node and OL.NodeLabel(node, sight) or nil,
        held = held and true or false,
        clearPending = (opts.pending and (not same or cd ~= "ready")) and true or false,
    }
end

--- Gold while the short flash is running, then the tray's quiet border.
function OL.GlowColor(elapsed)
    elapsed = tonumber(elapsed) or 0
    if elapsed < OL.GLOW_SECONDS then
        local g = OL.FINISHER_GLOW
        return g[1], g[2], g[3], true
    end
    local g = OL.REST_GLOW
    return g[1], g[2], g[3], false
end

function OL:StatusLine()
    local data = OL.Data()
    local node = self._lastNode or "none"
    local cd = self._lastCooldown or "unknown"
    local head = self:Enabled() and "Overload" or "Overload off"
    local line = string.format("%s: last node %s, cooldown %s", head, node, cd)
    if data and data.unverified then line = line .. " (unverified)" end
    return line
end

function OL:EnsureButton()
    if self._button then return self._button end
    if type(CreateFrame) ~= "function" or not UIParent then return nil end
    local template = "SecureActionButtonTemplate"
    if BackdropTemplateMixin then template = "SecureActionButtonTemplate,BackdropTemplate" end
    local btn = CreateFrame("Button", "TAOverloadButton", UIParent, template)
    local size = OL.BUTTON_SIZE
    btn:SetSize(size, size)
    btn:SetFrameStrata("HIGH")
    btn:RegisterForClicks("LeftButtonUp")
    btn:Hide()
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.04, 0.03, 0.00, 0.98)
        btn:SetBackdropBorderColor(OL.REST_GLOW[1], OL.REST_GLOW[2], OL.REST_GLOW[3], 0.70)
    end
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexture(OL.PLACEHOLDER_ICON)
    btn.icon = icon
    btn:SetScript("OnEnter", function(self)
        if not GameTooltip or not GameTooltip.SetOwner then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Overload", 1, 0.82, 0)
        local node = OL._lastNode
        if node and node ~= "none" then
            GameTooltip:AddLine(node, 0.9, 0.9, 0.9, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)
    btn:SetScript("OnUpdate", function(_, elapsed)
        if not OL._glowing then return end
        OL._glowElapsed = (OL._glowElapsed or 0) + (elapsed or 0)
        local r, g, b, live = OL.GlowColor(OL._glowElapsed)
        if btn.SetBackdropBorderColor then
            btn:SetBackdropBorderColor(r, g, b, live and 1 or 0.70)
        end
        if not live then OL._glowing = false end
    end)
    self._button = btn
    return btn
end

function OL:AnchorButton()
    local btn = self._button
    if not btn or not btn.ClearAllPoints then return end
    btn:ClearAllPoints()
    local tray = _G.TARotationPredictBar
    if tray then
        btn:SetPoint("LEFT", tray, "RIGHT", 6, 0)
    elseif UIParent then
        btn:SetPoint("BOTTOM", UIParent, "BOTTOM", 140, 188)
    end
end

function OL:Apply(plan)
    local btn = self:EnsureButton()
    if not btn then return end
    if not plan or not plan.show or OL.InCombat() then
        if btn.Hide then btn:Hide() end
        self._glowing = false
        self._shown = false
        return
    end
    local spellID = plan.spellID
    if spellID and btn._spell ~= spellID and not OL.InCombat() and btn.SetAttribute then
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", spellID)
        btn._spell = spellID
    end
    self:AnchorButton()
    local was = self._shown
    if btn.Show then btn:Show() end
    self._shown = true
    self._currentSpell = spellID
    if not was then
        self._glowElapsed = 0
        self._glowing = true
        if btn.SetBackdropBorderColor then
            local r, g, b = OL.GlowColor(0)
            btn:SetBackdropBorderColor(r, g, b, 1)
        end
    end
end

function OL:Refresh()
    local data = OL.Data()
    local result = OL.Consider(
        data,
        OL.ReadToken("softinteract"),
        OL.ReadToken("mouseover"),
        OL.SpellKnown,
        OL.ReadCooldown,
        {
            enabled = self:Enabled(),
            combat = OL.InCombat(),
            pending = self._pending,
            pendingGuid = self._pendingGuid,
        }
    )
    if result.clearPending then
        self._pending = false
        self._pendingGuid = nil
    end
    self._lastSight = result.sight
    if result.node then
        self._lastNode = result.label
        self._lastSpell = result.spellID
        self._lastCooldown = result.cooldown
    elseif self._lastSpell then
        self._lastCooldown = OL.ReadCooldown(self._lastSpell)
    end
    self:Apply(result)
end

function OL:NoteCast(unit, spellID)
    if unit ~= "player" or not self._currentSpell then return false end
    if OL.Secret(spellID) or spellID ~= self._currentSpell then return false end
    local sight = self._lastSight
    self._pending = true
    self._pendingGuid = sight and sight.guid or nil
    self:Apply({ show = false })
    return true
end

OL.Events = {
    "PLAYER_SOFT_INTERACT_CHANGED",
    "UPDATE_MOUSEOVER_UNIT",
    "SPELL_UPDATE_COOLDOWN",
    "UNIT_SPELLCAST_SUCCEEDED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

function OL:OnEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        self:Apply({ show = false })
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        self:NoteCast(unit, spellID)
        return
    end
    if OL.InCombat() and event ~= "PLAYER_REGEN_ENABLED" then return end
    self:Refresh()
end

function OL:Init()
    self._lastNode = "none"
    self._lastCooldown = "unknown"
    self._secureButtons = nil
    self:EnsureButton()
end
