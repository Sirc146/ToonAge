-- ToonAge/Modules/Character/ProfessionOverload.lua
-- Retail gathering Overload reminder.
--
-- The only nodes this can see are the soft target and the mouseover. The
-- client does not expose gathering nodes at a distance, so this file never
-- goes looking for them. Which names can be overloaded, which cannot, and
-- the spell ids live in Data/Retail/professions_retail.lua
-- (TA.Data.Overloads). That list is not verified for Midnight. Charges are
-- read with C_Spell.GetSpellCharges. A match is written into the diagnostics
-- line.
--
-- The reminder does not own a button. It offers a spell candidate to the
-- shared context-action button (TA.ContextAction). That button queues
-- attribute and visibility changes until combat ends. The offer goes away
-- after the Overload is cast, and when the soft target and the mouseover
-- both stop matching. The icon is the spell texture, or a placeholder until
-- Gilder supplies one.

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

--- The name starts with one of the data-file words, as its own word.
--- "Wild Iron" matches "Wild". "Wilderness" does not.
function OL.Leading(name, list)
    if OL.Secret(name) or type(name) ~= "string" or type(list) ~= "table" then return nil end
    local lower = name:lower()
    for _, prefix in ipairs(list) do
        if type(prefix) == "string" and prefix ~= "" then
            local word = prefix:lower()
            if lower:sub(1, #word) == word then
                local nxt = lower:sub(#word + 1, #word + 1)
                if nxt == "" or not nxt:match("%a") then return prefix end
            end
        end
    end
    return nil
end

local spotIndex

function OL.RebuildSpots()
    spotIndex = {}
    local groups = TA.GatheringData and TA.GatheringData.midnight
        and TA.GatheringData.midnight.overloadSpots
    if type(groups) ~= "table" then return spotIndex end
    for _, group in ipairs(groups) do
        if type(group) == "table" and type(group.overloadSpellID) == "number" then
            for _, spot in ipairs(group.spots or {}) do
                if type(spot) == "table" then
                    for _, id in ipairs(spot.objectIDs or {}) do
                        if type(id) == "number" and spotIndex[id] == nil then
                            spotIndex[id] = {
                                objectID = id,
                                spellID = group.overloadSpellID,
                                name = group.variant,
                                profession = group.profession,
                            }
                        end
                    end
                end
            end
        end
    end
    return spotIndex
end

function OL.SpotFor(objectID)
    if type(objectID) ~= "number" then return nil end
    local groups = TA.GatheringData and TA.GatheringData.midnight
        and TA.GatheringData.midnight.overloadSpots
    if spotIndex == nil or (not next(spotIndex) and type(groups) == "table" and groups[1]) then
        OL.RebuildSpots()
    end
    return spotIndex and spotIndex[objectID] or nil
end

--- node, prefix, denied. A denied name is never a node, even if an object
--- id is listed. A prefix hit is used when the exact list does not name it.
--- Gathering overload spots supply a spell id without writing the retail
--- node list.
function OL.Match(data, name, guid)
    if type(data) ~= "table" then return nil end
    local denied = OL.Leading(name, data.denyPrefixes)
    if denied then return nil, nil, denied end
    local objectID = OL.ObjectID(guid)
    local lname = (not OL.Secret(name) and type(name) == "string") and name:lower() or nil
    for _, node in ipairs(data.nodes or {}) do
        if type(node) == "table" then
            local idHit = node.objectID ~= nil and objectID ~= nil and node.objectID == objectID
            local nameHit = lname and type(node.name) == "string" and node.name:lower() == lname
            if idHit or nameHit then return node, nil, nil end
        end
    end
    local spot = OL.SpotFor(objectID)
    if spot then return spot, nil, nil end
    local allowed = OL.Leading(name, data.allowPrefixes)
    if allowed and not OL.Secret(name) and type(name) == "string" then
        return { name = name, prefix = allowed }, allowed, nil
    end
    return nil
end

--- Spell id from the node, else from the profession row. A prefix match has
--- no profession, so the spell is used only when the character knows exactly
--- one Overload. Two known Overloads is ambiguous and returns nil.
function OL.SpellFor(data, node, knownFn)
    if type(node) ~= "table" then return nil end
    if node.spellID ~= nil then return node.spellID end
    local hits = {}
    for _, row in ipairs(data and data.spells or {}) do
        if type(row) == "table" and row.spellID ~= nil then
            local profOk = node.profession == nil or row.profession == node.profession
            if profOk then
                local known = true
                if node.profession == nil and knownFn then
                    known = knownFn(row.spellID) and true or false
                end
                if known then hits[#hits + 1] = row.spellID end
            end
        end
    end
    if node.profession ~= nil then return hits[1] end
    if #hits == 1 then return hits[1] end
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

--- Numeric cooldown for the swipe. nil when a field is secret.
function OL.CooldownNumbers(info)
    if OL.Secret(info) or type(info) ~= "table" then return nil end
    local start = info.startTime
    if start == nil then start = info.start end
    local duration = info.duration
    if OL.Secret(start) or OL.Secret(duration) then return nil end
    return tonumber(start) or 0, tonumber(duration) or 0
end

function OL.ReadCooldownRaw(spellID)
    if not spellID or OL.Secret(spellID) then return "unknown", nil end
    local fn = C_Spell and C_Spell.GetSpellCooldown
    if type(fn) ~= "function" then return "unknown", nil end
    local ok, info = pcall(fn, spellID)
    if not ok then return "unknown", nil end
    local now = type(GetTime) == "function" and GetTime() or 0
    return OL.CooldownState(info, now), info
end

function OL.ReadCooldown(spellID)
    local state = OL.ReadCooldownRaw(spellID)
    return state
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
    local function One(sight, via)
        if type(sight) ~= "table" then return nil end
        local node, prefix, denied = OL.Match(data, sight.name, sight.guid)
        if denied then return nil, sight, via, denied end
        if node then return node, sight, via, nil, prefix or node.prefix end
        return nil
    end
    local node, sight, via, denied, prefix = One(soft, "soft")
    if denied or node then return node, sight, via, denied, prefix end
    return One(mouse, "mouse")
end

function OL.NormalizeCharges(ok, first, maxCharges, start, duration)
    if not ok or first == nil or OL.Secret(first) then return nil end
    if type(first) == "table" then return first end
    if type(first) == "number" then
        return {
            currentCharges = first,
            maxCharges = maxCharges,
            cooldownStartTime = start,
            cooldownDuration = duration,
        }
    end
    return nil
end

--- "ready" when a charge is available, "cooldown" when the count is zero,
--- "secret" when a field must not be compared, "unknown" when the call is
--- missing. currentCharges is read before any numeric comparison.
function OL.ChargeState(info)
    if info == nil or OL.Secret(info) or type(info) ~= "table" then return "unknown" end
    local cur = info.currentCharges
    if cur == nil then cur = info.charges end
    local maxc = info.maxCharges
    if OL.Secret(cur) or OL.Secret(maxc) then return "secret" end
    cur = tonumber(cur)
    if not cur then return "unknown" end
    if cur > 0 then return "ready" end
    return "cooldown"
end

function OL.ChargeText(info, data)
    if info == nil or OL.Secret(info) or type(info) ~= "table" then return nil end
    local cur = info.currentCharges
    if cur == nil then cur = info.charges end
    local maxc = info.maxCharges
    if OL.Secret(cur) or OL.Secret(maxc) then return "secret" end
    cur, maxc = tonumber(cur), tonumber(maxc)
    if not cur or not maxc then return nil end
    local text = tostring(cur) .. "/" .. tostring(maxc)
    local points = data and data.charges and data.charges.secondAtPoints
    if maxc < 2 and type(points) == "number" then
        text = text .. " (second at " .. tostring(points) .. " points)"
    end
    return text
end

function OL.ReadCharges(spellID)
    if not spellID or OL.Secret(spellID) then return "unknown", nil end
    local fn = C_Spell and C_Spell.GetSpellCharges
    if type(fn) ~= "function" then return "unknown", nil end
    local packed = { pcall(fn, spellID) }
    local info = OL.NormalizeCharges(unpack(packed))
    return OL.ChargeState(info), info
end

--- One diagnostics sentence for a consider result. Nil when nothing was seen.
function OL.Note(result)
    if type(result) ~= "table" then return nil end
    if result.excluded then
        local family = result.family and (result.family .. " ") or ""
        return string.format("excluded %s%s (%s)", family, result.label or "node", result.excluded)
    end
    if result.node then
        local how = result.prefix and ("prefix " .. result.prefix) or "listed"
        local charges = result.charges and (", charges " .. result.charges) or ""
        local family = result.family and (result.family .. " ") or ""
        return string.format("matched %s%s via %s spell %s%s",
            family, result.label or "node", how, tostring(result.spellID or "?"), charges)
    end
    return nil
end

--- Show only when the reminder is on, a node matches, the character knows
--- that Overload, and its cooldown is ready. Combat does not drop the offer:
--- the shared button keeps its secure state until PLAYER_REGEN_ENABLED.
--- `held` covers the moment after a cast before the cooldown flips.
function OL.Decide(ctx)
    ctx = ctx or {}
    if ctx.held then return false end
    if ctx.enabled == false then return false end
    if not ctx.node then return false end
    if not ctx.known then return false end
    if ctx.cooldown ~= "ready" then return false end
    return true
end

function OL.Consider(data, soft, mouse, knownFn, cdFn, opts)
    opts = opts or {}
    local node, sight, via, denied, prefix = OL.BestMatch(data, soft, mouse)
    local spellID = OL.SpellFor(data, node, knownFn)
    local cd = (spellID and cdFn and cdFn(spellID)) or "unknown"
    local known = spellID and knownFn and knownFn(spellID) or false
    local same = opts.pending and type(sight) == "table" and sight.guid == opts.pendingGuid
    local held = same and cd == "ready"
    if opts.pending and not same then held = false end
    if opts.pending and cd ~= "ready" then held = false end
    local label = node and OL.NodeLabel(node, sight) or nil
    if not label and type(sight) == "table" and not OL.Secret(sight.name) then
        label = sight.name
    end
    return {
        show = (not denied) and OL.Decide({
            enabled = opts.enabled ~= false,
            combat = opts.combat and true or false,
            node = node,
            known = known and true or false,
            cooldown = cd,
            held = held and true or false,
        }) or false,
        node = node,
        sight = sight,
        via = via,
        spellID = spellID,
        cooldown = cd,
        known = known and true or false,
        label = label,
        prefix = prefix,
        excluded = denied,
        family = data and data.family or nil,
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

function OL:Remember(text)
    if type(text) ~= "string" or text == "" then return end
    self._matches = self._matches or {}
    if self._matches[#self._matches] == text then return end
    self._matches[#self._matches + 1] = text
    if #self._matches > 12 then table.remove(self._matches, 1) end
    self._lastNote = text
end

function OL:StatusLine()
    local data = OL.Data()
    local node = self._lastNode or "none"
    local cd = self._lastCooldown or "unknown"
    local head = self:Enabled() and "Overload" or "Overload off"
    local line = string.format("%s: last node %s, cooldown %s", head, node, cd)
    if self._lastNote then line = line .. "; " .. self._lastNote end
    if data and data.unverified then line = line .. " (unverified)" end
    return line
end

function OL:Publish(result)
    local CA = TA.ContextAction
    if not CA or type(CA.Set) ~= "function" then return end
    if not result or not result.show or not result.spellID then
        self._currentSpell = nil
        CA:Set("overload", nil)
        return
    end
    local icon = OL.PLACEHOLDER_ICON
    local U = TA.Utils
    if U and type(U.GetSpellTexture) == "function" then
        local tex = U.GetSpellTexture(result.spellID)
        if tex and tex ~= "" then icon = tex end
    end
    local cooldown
    local _, info = OL.ReadCooldownRaw(result.spellID)
    if info then
        local start, duration = OL.CooldownNumbers(info)
        if start ~= nil then cooldown = { start = start, duration = duration } end
    end
    self._currentSpell = result.spellID
    local family = result.family
    if type(family) ~= "string" or family == "" then
        local data = OL.Data()
        family = data and data.family
    end
    local why
    if CA.WhyForFamily then
        why = CA.WhyForFamily(family)
    elseif type(family) == "string" and family ~= "" then
        why = family .. " node nearby"
    end
    CA:Set("overload", {
        source = "overload",
        kind = "spell",
        action = result.spellID,
        icon = icon,
        label = result.label or "Overload",
        priority = CA.OVERLOAD_PRIORITY or 10,
        cooldown = cooldown,
        why = why,
    })
end

function OL:Refresh()
    local data = OL.Data()
    local chargeInfo
    local function Availability(spellID)
        local state, info = OL.ReadCharges(spellID)
        if info then chargeInfo = info end
        if state == "unknown" then return OL.ReadCooldown(spellID) end
        return state
    end
    local result = OL.Consider(
        data,
        OL.ReadToken("softinteract"),
        OL.ReadToken("mouseover"),
        OL.SpellKnown,
        Availability,
        {
            enabled = self:Enabled(),
            combat = OL.InCombat(),
            pending = self._pending,
            pendingGuid = self._pendingGuid,
        }
    )
    if result then result.charges = OL.ChargeText(chargeInfo, data) end
    local note = OL.Note(result)
    if note then self:Remember(note) end
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
    self:Publish(result)
end

function OL:NoteCast(unit, spellID)
    if unit ~= "player" or not self._currentSpell then return false end
    if OL.Secret(spellID) or spellID ~= self._currentSpell then return false end
    local sight = self._lastSight
    self._pending = true
    self._pendingGuid = sight and sight.guid or nil
    self:Publish({ show = false })
    return true
end

OL.Events = {
    "PLAYER_SOFT_INTERACT_CHANGED",
    "UPDATE_MOUSEOVER_UNIT",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_CHARGES",
    "UNIT_SPELLCAST_SUCCEEDED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

function OL:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        self:NoteCast(unit, spellID)
        return
    end
    self:Refresh()
end

function OL:Init()
    self._lastNode = "none"
    self._lastCooldown = "unknown"
end
