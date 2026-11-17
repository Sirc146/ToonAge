-- Tools/harness/engine.lua
-- Widget, timer, and installer core for the offline client in wowsim.py.
-- Loaded into a fresh Lua 5.1 state before any addon file. It does not
-- install WoW APIs by itself: wowsim.py feeds a snapshot and calls
-- _wowsim_install(), and anything the snapshot does not list stays nil.

_wowsim_calls = {}
_wowsim_printed = {}
_wowsim_queue = {}
_wowsim_timer_errors = {}
_wowsim_fire_errors = {}
_wowsim_frames = {}
_wowsim_seq = 0
_wowsim_now = 0
_wowsim_rich = {}
_wowsim_unverified = {}
_wowsim_event_status = {}
_wowsim_enforce_events = false
_wowsim_rows = {}
_wowsim_player = { name = "Pebble", realm = "Fakeserver", level = 1,
    class = "Mage", class_file = "MAGE", race = "Human", race_file = "Human" }
_wowsim_build = { "0", "0", "date", 0 }
_wowsim_project_id = 1
_wowsim_text_font = "Fonts\\FRIZQT__.TTF"
_wowsim_id = ""
_wowsim_meta = {}

function _wowsim_note(name)
    _wowsim_calls[name] = (_wowsim_calls[name] or 0) + 1
end

function _wowsim_take_unverified()
    local out = {}
    for name in pairs(_wowsim_calls) do
        if _wowsim_unverified[name] then out[#out + 1] = name end
    end
    table.sort(out)
    _wowsim_calls = {}
    return out
end

print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    _wowsim_printed[#_wowsim_printed + 1] = table.concat(parts, " ")
end

-- Unknown widget methods are callable tables, not raw functions. A raw
-- function cannot be indexed, and UI code reads fields such as glyph.label
-- before it calls them (btn.glyph.SetVertexColor). Keys that start with "_"
-- or a lowercase letter are data: a real widget returns nil for an unset
-- one. Returning a function for "_" made Core/Layout.lua treat every mock
-- as a pooled pane.
local function Bound(frame)
    local proxy = {}
    setmetatable(proxy, {
        __call = function() return frame end,
        __index = function(_, key)
            if type(key) ~= "string" then return nil end
            if key:sub(1, 1) == "_" or key:match("^%l") then return nil end
            return Bound(frame)
        end,
    })
    return proxy
end

function MockFrame(name, kind)
    local f = {
        _name = name,
        _shown = false,
        _kind = kind or "Frame",
        _scripts = {},
        _children = {},
        _regions = {},
        _events = {},
        _level = 1,
        _text = "",
    }
    local function numeric(store, fallback)
        return function(s)
            local v = rawget(s, store)
            if v == nil then return fallback end
            return v
        end
    end
    f.Show = function(s) rawset(s, "_shown", true) return s end
    f.Hide = function(s) rawset(s, "_shown", false) return s end
    f.IsShown = function(s) return rawget(s, "_shown") and true or false end
    f.IsVisible = function(s) return rawget(s, "_shown") and true or false end
    f.SetShown = function(s, on)
        if on then return s:Show() end
        return s:Hide()
    end
    f.SetScript = function(s, ev, fn)
        rawget(s, "_scripts")[ev] = fn
        return s
    end
    f.GetScript = function(s, ev) return rawget(s, "_scripts")[ev] end
    f.HookScript = function(s, ev, fn)
        local scripts = rawget(s, "_scripts")
        local prev = scripts[ev]
        if type(prev) == "function" and type(fn) == "function" then
            scripts[ev] = function(...)
                prev(...)
                return fn(...)
            end
        else
            scripts[ev] = fn
        end
        return s
    end
    f.HasScript = function(s, ev) return rawget(s, "_scripts")[ev] ~= nil end
    f.RegisterEvent = function(s, event)
        if _wowsim_enforce_events then
            if _wowsim_event_status[event] ~= "present" then
                error("event not present on this client: " .. tostring(event), 2)
            end
        end
        rawget(s, "_events")[event] = true
        return s
    end
    f.RegisterUnitEvent = function(s, event, ...)
        return s:RegisterEvent(event)
    end
    f.UnregisterEvent = function(s, event)
        rawget(s, "_events")[event] = nil
        return s
    end
    f.UnregisterAllEvents = function(s)
        rawset(s, "_events", {})
        return s
    end
    f.IsEventRegistered = function(s, event)
        if rawget(s, "_events")[event] then return 1 end
        return nil
    end
    f.CreateFontString = function(s, fname)
        local child = MockFrame(fname, "FontString")
        local regions = rawget(s, "_regions")
        regions[#regions + 1] = child
        rawset(child, "_parent", s)
        return child
    end
    f.CreateTexture = function(s, tname)
        local child = MockFrame(tname, "Texture")
        local regions = rawget(s, "_regions")
        regions[#regions + 1] = child
        rawset(child, "_parent", s)
        return child
    end
    f.SetText = function(s, text) rawset(s, "_text", text) return s end
    f.GetText = function(s) return rawget(s, "_text") end
    f.SetWidth = function(s, n) rawset(s, "_w", n) return s end
    f.SetHeight = function(s, n) rawset(s, "_h", n) return s end
    f.SetSize = function(s, w, h) rawset(s, "_w", w) rawset(s, "_h", h or w) return s end
    f.GetWidth = numeric("_w", 400)
    f.GetHeight = numeric("_h", 300)
    f.GetStringWidth = function() return 40 end
    f.GetStringHeight = function() return 12 end
    f.SetFrameLevel = function(s, n) rawset(s, "_level", n or 1) return s end
    f.GetFrameLevel = numeric("_level", 1)
    f.GetEffectiveScale = function() return 1 end
    f.GetScale = function() return 1 end
    f.SetAlpha = function(s, n) rawset(s, "_alpha", n) return s end
    f.GetAlpha = numeric("_alpha", 1)
    f.GetLeft = function() return 0 end
    f.GetBottom = function() return 0 end
    f.GetRight = function(s) return rawget(s, "_w") or 400 end
    f.GetTop = function(s) return rawget(s, "_h") or 300 end
    f.GetCenter = function(s)
        return (rawget(s, "_w") or 400) / 2, (rawget(s, "_h") or 300) / 2
    end
    f.GetRect = function(s)
        return 0, 0, rawget(s, "_w") or 400, rawget(s, "_h") or 300
    end
    f.GetVerticalScroll = function() return 0 end
    f.GetHorizontalScroll = function() return 0 end
    f.SetVerticalScroll = function(s) return s end
    f.SetHorizontalScroll = function(s) return s end
    f.GetNumPoints = function() return 0 end
    f.GetNumRegions = function(s) return #(rawget(s, "_regions") or {}) end
    f.GetNumChildren = function(s) return #(rawget(s, "_children") or {}) end
    f.GetChildren = function(s) return unpack(rawget(s, "_children") or {}) end
    f.GetRegions = function(s) return unpack(rawget(s, "_regions") or {}) end
    f.GetParent = function(s) return rawget(s, "_parent") end
    f.GetName = function(s) return rawget(s, "_name") end
    f.GetObjectType = function(s) return rawget(s, "_kind") or "Frame" end
    f.IsObjectType = function(s, k) return rawget(s, "_kind") == k end
    f.SetParent = function(s, parent)
        if parent == s then return s end
        local old = rawget(s, "_parent")
        if old and old ~= parent then
            local old_kids = rawget(old, "_children")
            if old_kids then
                for i = #old_kids, 1, -1 do
                    if old_kids[i] == s then table.remove(old_kids, i) end
                end
            end
        end
        rawset(s, "_parent", parent)
        if type(parent) == "table" then
            local kids = rawget(parent, "_children")
            if kids then
                local seen = false
                for i = 1, #kids do
                    if kids[i] == s then seen = true break end
                end
                if not seen then kids[#kids + 1] = s end
            end
        end
        return s
    end
    f.Cancel = function(s) rawset(s, "_cancelled", true) return s end
    f.IsCancelled = function(s) return rawget(s, "_cancelled") and true or false end
    setmetatable(f, { __index = function(s, k)
        if type(k) ~= "string" then return nil end
        if k:sub(1, 1) == "_" or k:match("^%l") then return nil end
        return Bound(s)
    end })
    _wowsim_frames[#_wowsim_frames + 1] = f
    if type(name) == "string" and name ~= "" then
        rawset(_G, name, f)
    end
    return f
end

function _wowsim_set_path(path, value)
    local ns, key = path:match("^([%w_]+)%.([%w_]+)$")
    if not ns then
        rawset(_G, path, value)
        return
    end
    if value == nil then
        local t = rawget(_G, ns)
        if type(t) == "table" then t[key] = nil end
        return
    end
    local t = rawget(_G, ns)
    if type(t) ~= "table" then
        t = {}
        rawset(_G, ns, t)
    end
    t[key] = value
end

function _wowsim_generic_return(name)
    -- The TBC boot prelude defined every function it installed. A present
    -- name with no rich body stays nil there so control flow matches that
    -- prelude. Forever and Retail get a type-stable empty so `for i = 1, n`
    -- and `if IsX()` do not throw on a stub.
    if _wowsim_id == "tbc" then return nil end
    if name:find("^Is") or name:find("^Can") or name:find("^Has")
        or name:find("^UnitIs") or name:find("Exists") then
        return false
    end
    if name:find("Num") or name:find("Count") or name:find("Chance")
        or name:find("Money") or name:find("Seconds") or name:find("Time$")
        or name:find("XP") then
        return 0
    end
    return nil
end

_wowsim_engine = {}

_wowsim_engine.CreateColor = function(r, g, b, a)
    return {
        r = r or 0, g = g or 0, b = b or 0, a = a or 1,
        GetRGB = function() return r or 0, g or 0, b or 0 end,
        GetRGBA = function() return r or 0, g or 0, b or 0, a or 1 end,
    }
end

_wowsim_engine.CreateFrame = function(kind, name, parent, template)
    local f = MockFrame(name, kind or "Frame")
    rawset(f, "_template", template)
    if type(parent) == "table" and parent ~= f then
        rawset(f, "_parent", parent)
        local kids = rawget(parent, "_children")
        if kids then kids[#kids + 1] = f end
    end
    return f
end

_wowsim_engine["C_Timer.After"] = function(delay, fn)
    if type(fn) ~= "function" then return end
    _wowsim_seq = _wowsim_seq + 1
    local at = _wowsim_now + (tonumber(delay) or 0)
    _wowsim_queue[#_wowsim_queue + 1] = { at = at, seq = _wowsim_seq, fn = fn }
end

_wowsim_engine["C_Timer.NewTicker"] = function()
    return MockFrame("ticker")
end

_wowsim_engine.GetBuildInfo = function()
    local b = _wowsim_build
    return b[1], b[2], b[3], b[4]
end

_wowsim_engine.GetTime = function()
    return _wowsim_now
end

_wowsim_engine.time = function()
    return 1750000000
end

_wowsim_engine.date = function()
    return "2026-01-01 00:00:00"
end

_wowsim_engine.UnitName = function()
    return _wowsim_player.name
end

_wowsim_engine.GetRealmName = function()
    return _wowsim_player.realm
end

_wowsim_engine.UnitLevel = function()
    return _wowsim_player.level
end

_wowsim_engine.UnitClass = function()
    return _wowsim_player.class, _wowsim_player.class_file
end

_wowsim_engine.UnitRace = function()
    return _wowsim_player.race, _wowsim_player.race_file
end

_wowsim_engine.InCombatLockdown = function()
    return false
end

_wowsim_engine.debugstack = function()
    return ""
end

_wowsim_engine.hooksecurefunc = function() end

_wowsim_engine.geterrorhandler = function()
    return function() end
end

_wowsim_engine.seterrorhandler = function() end

_wowsim_engine.IsAddOnLoaded = function()
    return false
end

_wowsim_engine.GetAddOnInfo = function()
    return nil, "Title"
end

_wowsim_engine.GetAddOnMetadata = function(addon, field)
    if addon ~= "ToonAge" then return nil end
    return _wowsim_meta[field]
end

_wowsim_engine["C_AddOns.GetAddOnMetadata"] = function(addon, field)
    if addon ~= "ToonAge" then return nil end
    return _wowsim_meta[field]
end

_wowsim_engine["C_AddOns.IsAddOnLoaded"] = function()
    return false
end

_wowsim_engine["C_AddOns.GetAddOnInfo"] = function()
    return nil, "Title"
end

_wowsim_engine.issecretvalue = function()
    return false
end

_wowsim_engine.CreateFramePool = function(frameType, parent, template, resetter)
    local pool = { _free = {} }
    function pool:Acquire()
        local f = table.remove(self._free)
        if not f then
            f = _wowsim_engine.CreateFrame(frameType or "Frame", nil, parent, template)
        end
        if f.Show then f:Show() end
        return f
    end
    function pool:Release(f)
        if type(resetter) == "function" then resetter(self, f) end
        if f and f.Hide then f:Hide() end
        self._free[#self._free + 1] = f
    end
    return pool
end

_wowsim_engine.EnumerateFrames = function()
    return nil
end

_wowsim_engine.UpdateAddOnMemoryUsage = function() end

_wowsim_engine.GetAddOnMemoryUsage = function()
    return 0
end

_wowsim_engine.Mixin = function(obj, ...)
    if type(obj) ~= "table" then return obj end
    for i = 1, select("#", ...) do
        local src = select(i, ...)
        if type(src) == "table" then
            for k, v in pairs(src) do obj[k] = v end
        end
    end
    return obj
end

_wowsim_engine.wipe = function(t)
    if type(t) ~= "table" then return t end
    for k in pairs(t) do t[k] = nil end
    return t
end

_wowsim_engine.strsplit = function(delim, text, pieces)
    if text == nil then return end
    delim = tostring(delim)
    text = tostring(text)
    local out = {}
    local start = 1
    local n = 0
    while true do
        local a, b = string.find(text, delim, start, true)
        if not a or (pieces and n >= pieces - 1) then
            out[#out + 1] = string.sub(text, start)
            break
        end
        out[#out + 1] = string.sub(text, start, a - 1)
        n = n + 1
        start = b + 1
    end
    return unpack(out)
end

_wowsim_engine.strjoin = function(delim, ...)
    return table.concat({ ... }, delim or "")
end

_wowsim_engine.strtrim = function(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

_wowsim_engine.strmatch = function(s, pattern, init)
    return string.match(s, pattern, init)
end

_wowsim_engine.tContains = function(t, v)
    if type(t) ~= "table" then return false end
    for _, x in pairs(t) do
        if x == v then return true end
    end
    return false
end

_wowsim_engine.CopyTable = function(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = _wowsim_engine.CopyTable(v)
    end
    return out
end

_wowsim_engine.format = function(fmt, ...)
    return string.format(fmt, ...)
end

_wowsim_engine.tinsert = function(t, a, b)
    if b == nil then table.insert(t, a) else table.insert(t, a, b) end
end

_wowsim_engine.tremove = function(t, i)
    return table.remove(t, i)
end

function _wowsim_build_rich()
    _wowsim_rich = {}
    if _wowsim_id ~= "tbc" then return end
    -- Return values carried over from the TBC boot prelude so InitModules
    -- sees the same classic surface that Tools/test_tbc_boot.py asserted.
    _wowsim_rich.GetNumTalentTabs = function() return 3 end
    _wowsim_rich.GetTalentTabInfo = function(tab)
        local names = { "Arcane", "Fire", "Frost" }
        local points = (tab == 3) and 56 or 0
        return names[tab] or ("Tab" .. tostring(tab)), "icon", points, nil
    end
    _wowsim_rich.GetTalentInfo = function()
        return "Talent", "icon", 5, 5, 0, 5
    end
    _wowsim_rich.GetNumSpellTabs = function() return 1 end
    _wowsim_rich.GetSpellTabInfo = function() return "General", "icon", 0, 10 end
    _wowsim_rich.GetSpellBookItemName = function() return "Frostbolt", "Rank 13" end
    _wowsim_rich.GetSpellBookItemInfo = function() return "SPELL", 116 end
    _wowsim_rich.IsPassiveSpell = function() return false end
    _wowsim_rich.GetActionInfo = function() return "spell", 116 end
    _wowsim_rich.GetSpellInfo = function() return "Frostbolt", nil, 135846, 2500 end
    _wowsim_rich.GetShapeshiftFormInfo = function() return nil end
    _wowsim_rich.GetNumShapeshiftForms = function() return 0 end
    _wowsim_rich.GetInventoryItemLink = function() return nil end
    _wowsim_rich.GetItemInfo = function()
        return "Item", "link", 4, 100, 60, "Weapon", "Staves", 1, "INVTYPE_2HWEAPON"
    end
    _wowsim_rich.GetContainerNumSlots = function() return 16 end
    _wowsim_rich.GetContainerItemLink = function() return nil end
    _wowsim_rich.GetContainerItemID = function() return nil end
    _wowsim_rich.GetContainerItemInfo = function() return nil end
    _wowsim_rich.GetCombatRating = function() return 0 end
    _wowsim_rich.GetCombatRatingBonus = function() return 0 end
    _wowsim_rich.GetExpertise = function() return 0, 0 end
    _wowsim_rich.GetDodgeChance = function() return 5 end
    _wowsim_rich.GetParryChance = function() return 5 end
    _wowsim_rich.GetBlockChance = function() return 5 end
    _wowsim_rich.GetSpellBonusDamage = function() return 0 end
    _wowsim_rich.GetSpellCritChance = function() return 0 end
    _wowsim_rich.GetInventoryItemsForSlot = function() return {} end
end

function _wowsim_install()
    _wowsim_build_rich()
    local child_present = {}
    for i = 1, #_wowsim_rows do
        local row = _wowsim_rows[i]
        if row.status == "present" then
            local ns = row.name:match("^([%w_]+)%.")
            if ns then child_present[ns] = true end
        end
    end
    for i = 1, #_wowsim_rows do
        local row = _wowsim_rows[i]
        if row.status ~= "present" and not row.name:find(".", 1, true) then
            if not child_present[row.name] then
                rawset(_G, row.name, nil)
            end
        end
    end
    for i = 1, #_wowsim_rows do
        local row = _wowsim_rows[i]
        local kind = row.kind or "function"
        if row.status == "present" and not row.name:find(".", 1, true) and kind ~= "function" then
            if kind == "table" then
                if type(rawget(_G, row.name)) ~= "table" then
                    rawset(_G, row.name, {})
                end
            elseif kind == "frame" then
                rawset(_G, row.name, MockFrame(row.name, "Frame"))
            elseif kind == "number" and row.name == "WOW_PROJECT_ID" then
                rawset(_G, row.name, _wowsim_project_id)
            elseif kind == "string" and row.name == "STANDARD_TEXT_FONT" then
                rawset(_G, row.name, _wowsim_text_font)
            end
        end
    end
    for i = 1, #_wowsim_rows do
        local row = _wowsim_rows[i]
        local kind = row.kind or "function"
        if row.status == "present" and kind == "function" then
            local name = row.name
            local eng = _wowsim_engine[name]
            local fn
            if eng then
                fn = function(...)
                    _wowsim_note(name)
                    return eng(...)
                end
            else
                fn = function(...)
                    _wowsim_note(name)
                    local rich = _wowsim_rich[name]
                    if rich then return rich(...) end
                    return _wowsim_generic_return(name)
                end
            end
            _wowsim_set_path(name, fn)
        elseif row.status ~= "present" and row.name:find(".", 1, true) then
            _wowsim_set_path(row.name, nil)
        end
    end
end

function _wowsim_drain(limit)
    limit = limit or 8000
    local steps = 0
    while steps < limit do
        local best, best_i
        for i = 1, #_wowsim_queue do
            local item = _wowsim_queue[i]
            if not best or item.at < best.at or (item.at == best.at and item.seq < best.seq) then
                best = item
                best_i = i
            end
        end
        if not best then return steps, 0 end
        if best.at > _wowsim_now + 60 then
            return steps, #_wowsim_queue
        end
        table.remove(_wowsim_queue, best_i)
        _wowsim_now = best.at
        steps = steps + 1
        local ok, err = pcall(best.fn)
        if not ok then
            _wowsim_timer_errors[#_wowsim_timer_errors + 1] = tostring(err)
        end
    end
    return steps, #_wowsim_queue
end

function _wowsim_fire(event, ...)
    local argc = select("#", ...)
    local args = { ... }
    for i = 1, #_wowsim_frames do
        local f = _wowsim_frames[i]
        local ev = rawget(f, "_events")
        if ev and ev[event] then
            local scripts = rawget(f, "_scripts")
            local fn = scripts and scripts.OnEvent
            if type(fn) == "function" then
                local ok, err = pcall(fn, f, event, unpack(args, 1, argc))
                if not ok then
                    _wowsim_fire_errors[#_wowsim_fire_errors + 1] = tostring(event) .. ": " .. tostring(err)
                end
            end
        end
    end
end
