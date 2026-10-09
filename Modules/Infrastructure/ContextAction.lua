-- ToonAge/Modules/Infrastructure/ContextAction.lua
-- One secure button other features share.
--
-- It sits just above the action bars and can be dragged. A feature calls
-- Set(source, candidate) with a spell or an item. The highest priority
-- candidate is the one the button shows. Quest items use a higher priority
-- than the gathering Overload reminder.
--
-- The slot is 44px with a gold frame and a steady glow. The icon is the
-- spell or item texture the feature already has. The keybind is drawn on
-- the slot, and the tooltip adds candidate.why (why the button appeared).
-- Nothing here pulses, and combat does not move the slot or restyle it.
--
-- Attributes, Show, Hide, SetPoint, and SetOverrideBindingClick run only
-- out of combat. A change that arrives during combat is stored and applied
-- on PLAYER_REGEN_ENABLED. This file names no C_ API: Forever and the
-- classic clients load it, and each feature supplies the icon and cooldown.

local TA = ToonAge
TA.modules = TA.modules or {}

local CA = {}
TA.ContextAction = CA
TA:RegisterModule("ContextAction", CA)

CA.QUEST_PRIORITY = 20
CA.OVERLOAD_PRIORITY = 10
CA.NEAR_YARDS = 15
CA.BUTTON_SIZE = 44
-- Just above the default action bar.
CA.BAR_GAP = 72
-- Gold frame #E8B35A. Drawn once; combat never retints it.
CA.FRAME_GOLD = { 0.910, 0.702, 0.353 }
CA.GLOW_ALPHA = 0.40
CA.GLOW_OUTSET = 6
-- Keybind on the slot is #F5F7FA. The why-line is text_muted #8C939A.
CA.KEY_COLOR = { 245 / 255, 247 / 255, 250 / 255 }
CA.WHY_COLOR = { 140 / 255, 147 / 255, 154 / 255 }
CA.PLACEHOLDER_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
CA.BUTTON_NAME = "TAContextActionButton"
CA.KEY_MODS = { SHIFT = "S", CTRL = "C", ALT = "A" }

function CA.Secret(v)
    if type(issecretvalue) ~= "function" then return false end
    local ok, res = pcall(issecretvalue, v)
    return ok and res == true
end

function CA.InCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

--- Short label for the 44px slot. SHIFT-F is S-F. The saved binding stays full.
function CA.KeyLabel(key)
    if CA.Secret(key) or type(key) ~= "string" or key == "" then return "" end
    local parts = {}
    for part in string.gmatch(key, "[^%-]+") do
        parts[#parts + 1] = CA.KEY_MODS[part] or part
    end
    return table.concat(parts, "-")
end

--- "Quest item for: <quest>". A secret or empty title adds no line.
function CA.WhyForQuest(title)
    if CA.Secret(title) or type(title) ~= "string" then return nil end
    title = title:gsub("^%s+", ""):gsub("%s+$", "")
    if title == "" then return nil end
    return "Quest item for: " .. title
end

--- "<family> node nearby", for example "Infused node nearby".
function CA.WhyForFamily(family)
    if CA.Secret(family) or type(family) ~= "string" then return nil end
    family = family:gsub("^%s+", ""):gsub("%s+$", "")
    if family == "" then return nil end
    return family .. " node nearby"
end

--- Yards to a guide coordinate. Missing numbers are not "near".
function CA.WithinRange(yards, range)
    if CA.Secret(yards) or CA.Secret(range) then return false end
    yards = tonumber(yards)
    if not yards then return false end
    range = tonumber(range) or CA.NEAR_YARDS
    return yards <= range
end

--- Creature or GameObject id from a unit GUID. Other kinds are ignored.
function CA.UnitID(guid)
    if CA.Secret(guid) or type(guid) ~= "string" then return nil end
    local ok, id = pcall(function()
        local kind, found
        local index = 0
        for part in string.gmatch(guid, "[^%-]+") do
            index = index + 1
            if index == 1 then kind = part
            elseif index == 6 then found = tonumber(part) end
        end
        if kind ~= "Creature" and kind ~= "GameObject" and kind ~= "Vehicle" then
            return nil
        end
        return found
    end)
    if not ok then return nil end
    return id
end

--- Lowercase names pulled out of objective lines ("Wolf 0/8", "Slain: Boar").
function CA.ObjectiveNames(texts)
    local out = {}
    if type(texts) ~= "table" then return out end
    for _, text in ipairs(texts) do
        if type(text) == "string" and text ~= "" then
            local name = text:match("^(.-)%s+%d+%s*/%s*%d+")
                or text:match("^(.-)%s+%(")
                or text
            name = name:gsub("^[Ss]lain:%s*", "")
            name = name:gsub("^[Kk]illed?:%s*", "")
            name = name:gsub("^[Cc]ollected?:%s*", "")
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" then out[#out + 1] = name:lower() end
        end
    end
    return out
end

function CA.TargetMatches(targetName, targetID, names, ids)
    if CA.Secret(targetName) then targetName = nil end
    if CA.Secret(targetID) then targetID = nil end
    if targetID and type(ids) == "table" then
        for _, id in ipairs(ids) do
            if id == targetID then return true end
        end
    end
    if type(targetName) ~= "string" or targetName == "" or type(names) ~= "table" then
        return false
    end
    local ok, lname = pcall(string.lower, targetName)
    if not ok or type(lname) ~= "string" or lname == "" then return false end
    for _, n in ipairs(names) do
        if type(n) == "string" and n ~= "" then
            if n == lname then return true end
            local okFind, matched = pcall(function()
                return lname:find(n, 1, true) or n:find(lname, 1, true)
            end)
            if okFind and matched then return true end
        end
    end
    return false
end

local function PlainName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local inner = name:match("%[(.-)%]")
    if inner and inner ~= "" then return inner end
    if name:find("|H", 1, true) then return nil end
    return name
end

--- The guide's quest item, when the player is hovering the objective, near it, or has it targeted.
--- `special` is whatever GetQuestLogSpecialItemInfo returned. `fallbackID` is the
--- item id stored on the guide step, used only when the API returned nothing.
function CA.QuestCandidate(facts)
    facts = facts or {}
    if not facts.near and not facts.targeting and not facts.hover then return nil end
    local special = facts.special
    local itemID, name, texture
    local fromAPI = type(special) == "table"
        and (special.itemID or (type(special.name) == "string" and special.name ~= ""))
    if fromAPI then
        itemID = special.itemID
        name = special.name
        texture = special.texture
    else
        itemID = tonumber(facts.fallbackID)
        if not itemID then return nil end
        local count = facts.fallbackCount
        if count ~= nil and not (type(count) == "number" and count > 0) then
            return nil
        end
    end
    local action
    if type(name) == "string" and name ~= "" then
        action = name
    elseif itemID then
        action = "item:" .. tostring(itemID)
    else
        return nil
    end
    local label = PlainName(name) or "Quest item"
    return {
        source = "quest item",
        kind = "item",
        action = action,
        itemID = itemID,
        icon = texture,
        label = label,
        why = CA.WhyForQuest(facts.questTitle),
        priority = CA.QUEST_PRIORITY,
    }
end

--- start, duration when both values can be compared. nil when either is secret.
function CA.SafeCooldown(start, duration)
    if CA.Secret(start) or CA.Secret(duration) then return nil end
    start = tonumber(start) or 0
    duration = tonumber(duration) or 0
    return start, duration
end

function CA.Pick(offers)
    local best, bestP
    if type(offers) ~= "table" then return nil end
    for _, candidate in pairs(offers) do
        if type(candidate) == "table" then
            local p = tonumber(candidate.priority) or 0
            if not best or p > bestP then
                best = candidate
                bestP = p
            end
        end
    end
    return best
end

function CA:KeybindLabel()
    local key = TA.db and TA.db.contextActionKey
    if type(key) == "string" and key ~= "" then return key end
    return "none"
end

function CA:StatusLine()
    local source = self._source
    if type(source) ~= "string" or source == "" then source = "none" end
    local line = "Context action: " .. source
    if self._unverified and source ~= "none" then
        line = line .. " (unverified)"
    end
    return line
end

function CA:EnsureButton()
    if self._button then return self._button end
    if type(CreateFrame) ~= "function" or not UIParent then return nil end
    local template = "SecureActionButtonTemplate"
    if BackdropTemplateMixin then
        template = "SecureActionButtonTemplate,BackdropTemplate"
    end
    local btn = CreateFrame("Button", CA.BUTTON_NAME, UIParent, template)
    local size = CA.BUTTON_SIZE
    btn:SetSize(size, size)
    btn:SetFrameStrata("HIGH")
    if btn.SetMovable then btn:SetMovable(true) end
    if btn.EnableMouse then btn:EnableMouse(true) end
    if btn.RegisterForDrag then btn:RegisterForDrag("LeftButton") end
    if btn.RegisterForClicks then btn:RegisterForClicks("LeftButtonUp") end
    if btn.SetClampedToScreen then btn:SetClampedToScreen(true) end
    local gold = CA.FRAME_GOLD
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        btn:SetBackdropColor(0.04, 0.03, 0.00, 0.98)
        btn:SetBackdropBorderColor(gold[1], gold[2], gold[3], 1)
    end
    -- Steady halo behind the icon. White texture, tinted once. No animation.
    local glow = btn:CreateTexture(nil, "BACKGROUND")
    local out = CA.GLOW_OUTSET
    if glow.SetPoint then
        glow:SetPoint("TOPLEFT", btn, "TOPLEFT", -out, out)
        glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", out, -out)
    end
    if glow.SetTexture then glow:SetTexture("Interface\\Buttons\\WHITE8X8") end
    if glow.SetVertexColor then
        glow:SetVertexColor(gold[1], gold[2], gold[3], CA.GLOW_ALPHA)
    end
    if glow.SetBlendMode then glow:SetBlendMode("ADD") end
    btn.glow = glow
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    icon:SetTexture(CA.PLACEHOLDER_ICON)
    btn.icon = icon
    local cd
    pcall(function()
        cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    end)
    if cd then
        if cd.SetAllPoints then cd:SetAllPoints(icon) end
        if cd.SetDrawEdge then cd:SetDrawEdge(true) end
        btn.cooldown = cd
    end
    local keyText = btn:CreateFontString(nil, "OVERLAY")
    if keyText.SetFont then
        local painted = keyText:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
        if not painted and STANDARD_TEXT_FONT then
            keyText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        end
    end
    if keyText.SetPoint then keyText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3) end
    if keyText.SetJustifyH then keyText:SetJustifyH("RIGHT") end
    if keyText.SetTextColor then
        local c = CA.KEY_COLOR
        keyText:SetTextColor(c[1], c[2], c[3], 1)
    end
    if keyText.SetText then keyText:SetText("") end
    btn.keyText = keyText
    btn:SetScript("OnDragStart", function(f)
        if CA.InCombat() then return end
        if f.StartMoving then f:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function(f)
        if f.StopMovingOrSizing then f:StopMovingOrSizing() end
        if not TA.charDB or not f.GetLeft or not f.GetTop then return end
        local x, y = f:GetLeft(), f:GetTop()
        if type(x) ~= "number" or type(y) ~= "number" then return end
        TA.charDB.contextAction = { x = x, y = y }
    end)
    btn:SetScript("OnEnter", function(f)
        local tip = GameTooltip
        if not tip or not tip.SetOwner then return end
        tip:SetOwner(f, "ANCHOR_TOP")
        local plan = CA._plan
        if plan and plan.kind == "item" and plan.itemID and tip.SetItemByID then
            tip:SetItemByID(plan.itemID)
        elseif plan and plan.kind == "spell" and plan.action and tip.SetSpellByID then
            tip:SetSpellByID(plan.action)
        elseif tip.SetText then
            tip:SetText(plan and plan.label or "", 1, 0.82, 0)
        end
        local why = plan and plan.why
        if type(why) == "string" and why ~= "" and not CA.Secret(why) and tip.AddLine then
            local c = CA.WHY_COLOR
            tip:AddLine(why, c[1], c[2], c[3], true)
        end
        if tip.Show then tip:Show() end
    end)
    btn:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)
    self:Place(btn)
    self._button = btn
    if CA.InCombat() then
        self._dirty = true
        if self._queued == nil then self._queued = false end
    elseif btn.Hide then
        btn:Hide()
    end
    return btn
end

function CA:Place(btn)
    if not btn or btn._placed or not btn.SetPoint then return end
    if CA.InCombat() then
        self._placeQueued = true
        return
    end
    self._placeQueued = false
    btn._placed = true
    if btn.ClearAllPoints then btn:ClearAllPoints() end
    local saved = TA.charDB and TA.charDB.contextAction
    if not (saved and type(saved.x) == "number" and type(saved.y) == "number") then
        saved = TA.charDB and TA.charDB.questItem
    end
    if saved and type(saved.x) == "number" and type(saved.y) == "number" and UIParent then
        btn:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    elseif UIParent then
        btn:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, CA.BAR_GAP)
    end
end

function CA.IconFor(plan)
    local icon = plan and plan.icon
    if icon and icon ~= "" then return icon end
    local U = TA.Utils
    if plan and plan.kind == "spell" and U and type(U.GetSpellTexture) == "function" then
        local tex = U.GetSpellTexture(plan.action)
        if tex and tex ~= "" then return tex end
    end
    if plan and plan.kind == "item" and U and type(U.GetItemInfo) == "function" then
        local name, _, _, _, _, _, _, _, _, tex = U.GetItemInfo(plan.itemID or plan.action)
        if tex and tex ~= "" then return tex end
        if not plan.label or plan.label == "Quest item" then
            local plain = PlainName(name)
            if plain then plan.label = plain end
        end
    end
    return CA.PLACEHOLDER_ICON
end

function CA.Swipe(btn, cooldown)
    local frame = btn and btn.cooldown
    if not frame or type(frame.SetCooldown) ~= "function" then return end
    if type(cooldown) ~= "table" then
        frame:SetCooldown(0, 0)
        return
    end
    local start, duration = CA.SafeCooldown(cooldown.start, cooldown.duration)
    if not start then return end
    frame:SetCooldown(start, duration)
end

function CA:Paint(plan)
    if CA.InCombat() then
        self._queued = plan or false
        self._dirty = true
        return
    end
    local btn = self:EnsureButton()
    self._plan = plan
    self._source = plan and plan.source or nil
    self._unverified = plan and plan.unverified and true or false
    if not btn then return end
    local sig = ""
    if plan and (plan.kind == "spell" or plan.kind == "item") and plan.action ~= nil then
        sig = tostring(plan.kind) .. "\t" .. tostring(plan.action)
    else
        plan = nil
        self._plan = nil
        self._source = nil
        self._unverified = false
    end
    if not plan then
        if self._shown and btn.Hide then btn:Hide() end
        self._shown = false
        self._sig = ""
        if self._armed and btn.SetAttribute then
            btn:SetAttribute("type", nil)
            btn:SetAttribute("spell", nil)
            btn:SetAttribute("item", nil)
            self._armed = false
        end
        return
    end
    local icon = CA.IconFor(plan)
    if btn.icon and btn.icon.SetTexture and btn._icon ~= icon then
        btn.icon:SetTexture(icon)
        btn._icon = icon
    end
    CA.Swipe(btn, plan.cooldown)
    if btn.keyText and btn.keyText.SetText then
        local key = TA.db and TA.db.contextActionKey
        btn.keyText:SetText(CA.KeyLabel(key))
    end
    local changed = self._sig ~= sig
    if changed and btn.SetAttribute then
        btn:SetAttribute("type", plan.kind)
        if plan.kind == "spell" then
            btn:SetAttribute("spell", plan.action)
            btn:SetAttribute("item", nil)
        else
            btn:SetAttribute("item", plan.action)
            btn:SetAttribute("spell", nil)
        end
        self._armed = true
        self._sig = sig
    end
    local was = self._shown
    if not was and btn.Show then btn:Show() end
    self._shown = true
end

function CA:Commit(plan)
    if CA.InCombat() then
        self._queued = plan or false
        self._dirty = true
        return
    end
    self._dirty = false
    self._queued = nil
    self:Paint(plan)
end

function CA:Set(source, candidate)
    if type(source) ~= "string" or source == "" then return end
    self._offers = self._offers or {}
    if type(candidate) == "table" then
        if not candidate.source then candidate.source = source end
        self._offers[source] = candidate
    else
        self._offers[source] = nil
    end
    self:Commit(CA.Pick(self._offers))
end

function CA:ApplyBinding()
    if CA.InCombat() then
        self._bindQueued = true
        return
    end
    self._bindQueued = false
    local btn = self:EnsureButton()
    if not btn then return end
    local key = TA.db and TA.db.contextActionKey
    if type(key) ~= "string" or key == "" then key = nil end
    if self._boundKey ~= key then
        if type(ClearOverrideBinding) == "function" then
            ClearOverrideBinding(btn)
        end
        if key and type(SetOverrideBindingClick) == "function" then
            SetOverrideBindingClick(btn, true, key, CA.BUTTON_NAME, "LeftButton")
        end
        self._boundKey = key
    end
    if btn.keyText and btn.keyText.SetText then
        btn.keyText:SetText(CA.KeyLabel(key))
    end
end

function CA:SetKey(key)
    if key == "" then key = nil end
    if type(key) ~= "string" then key = nil end
    TA.db = TA.db or {}
    TA.db.contextActionKey = key
    self:ApplyBinding()
end

--- true when the key was stored or cleared. Modifier keys wait for the real key.
function CA:CaptureKey(key)
    if type(key) ~= "string" or key == "" then return false end
    if key == "ESCAPE" then
        self:SetKey(nil)
        return true
    end
    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
        or key == "LALT" or key == "RALT" then
        return false
    end
    local parts = {}
    if type(IsAltKeyDown) == "function" and IsAltKeyDown() then parts[#parts + 1] = "ALT" end
    if type(IsControlKeyDown) == "function" and IsControlKeyDown() then parts[#parts + 1] = "CTRL" end
    if type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
    parts[#parts + 1] = key
    self:SetKey(table.concat(parts, "-"))
    return true
end

function CA:DrawKeybindRow(parent, y, width, remember)
    if type(CreateFrame) ~= "function" or not parent then return y end
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local row = CreateFrame("Button", nil, parent, template)
    row:SetSize((width or 300) - 28, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    if row.SetBackdrop then
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.06, 0.06, 0.06, 1)
        row:SetBackdropBorderColor(0.30, 0.25, 0.08, 0.4)
    end
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if lbl.SetFont and STANDARD_TEXT_FONT then
        lbl:SetFont(STANDARD_TEXT_FONT, 10, "")
    end
    if lbl.SetPoint then lbl:SetPoint("LEFT", row, "LEFT", 8, 0) end
    if lbl.SetTextColor then lbl:SetTextColor(0.88, 0.83, 0.65, 1) end
    local function Show()
        if lbl.SetText then
            lbl:SetText("Context action keybind: " .. CA:KeybindLabel())
        end
    end
    Show()
    row:SetScript("OnClick", function(self)
        if CA.InCombat() then return end
        if self.EnableKeyboard then self:EnableKeyboard(true) end
        if lbl.SetText then lbl:SetText("Press a key (Esc clears)") end
        self:SetScript("OnKeyDown", function(btn, key)
            if not CA:CaptureKey(key) then return end
            if btn.EnableKeyboard then btn:EnableKeyboard(false) end
            btn:SetScript("OnKeyDown", nil)
            Show()
        end)
    end)
    if remember then
        remember(row)
        remember(lbl)
    end
    return (y or 0) - 26
end

function CA:OnEvent(event)
    if event ~= "PLAYER_REGEN_ENABLED" then return end
    if self._placeQueued and self._button then
        self:Place(self._button)
    end
    if self._dirty then
        local plan = self._queued
        if plan == false then plan = nil end
        self._dirty = false
        self._queued = nil
        self:Paint(plan)
    end
    if self._bindQueued then
        self:ApplyBinding()
    end
end

CA.Events = { "PLAYER_REGEN_ENABLED" }

function CA:Init()
    self._offers = {}
    self._source = nil
    self:EnsureButton()
    self:ApplyBinding()
end
