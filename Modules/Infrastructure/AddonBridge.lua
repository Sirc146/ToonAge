-- ToonAge/Modules/Infrastructure/AddonBridge.lua
-- Phase 1: detect other addons and coexist with them.
--
-- Standalone (none of the known hosts loaded) keeps today's behaviour.
-- This file does not restyle ToonAge and does not hook action bars.
-- Every client lookup goes through TA.Compat or LibStub, inside pcall,
-- so a missing addon or a missing library is a false result rather than an error.
--
-- Names marked UNVERIFIED are guesses. They are not confirmed by this repo.
-- Confirmed names:
--   ElvUI folder — Docs/EVOLUTION_TRACKER.md cites ElvUI_TBC.toc.
--   Zygor folders and the ZygorGuidesViewer global — Core/Utils.lua.
--   TomTom folder — Modules/Navigation/Arrow.lua and Modules/Mists/Arrow.lua.
--   MelloUI.Restock — a module inside MelloUI (Forever, MelloUI 2.1.51),
--   not a separate MelloUI_Restock addon. MelloUI:GetModule("Restock") is
--   the same module. The legacy addon name remains a fallback.

local TA = ToonAge or {}
ToonAge = TA

local B = {}
TA.AddonBridge = B
if type(TA.RegisterModule) == "function" then
    TA:RegisterModule("AddonBridge", B)
end

B.GuideToggles = {
    { key = "deferToZygor", label = "Let Zygor handle questing, arrow and auto-equip when it's loaded" },
    { key = "deferToMittenQuest", label = "Let MittenQuest handle questing, arrow and auto-equip when it's loaded" },
    { key = "deferToMelloQuestList", label = "Let MelloUI Quest List handle questing, arrow and auto-equip when it's loaded" },
}

-- folders / globals / libs / saved are the names that are actually probed.
-- unverified* lists are the subset that this repo has not confirmed.
B.CATALOG = {
    { id = "blizzard", label = "Blizzard", kind = "ui" },
    {
        id = "elvui", label = "ElvUI", kind = "ui",
        folders = { "ElvUI" },
        globals = { "ElvUI" },
        unverifiedGlobals = { "ElvUI" },
    },
    {
        id = "melloui", label = "MelloUI", kind = "ui",
        folders = { "MelloUI" },
        globals = { "MelloUI" },
        unverifiedFolders = { "MelloUI" },
        unverifiedGlobals = { "MelloUI" },
    },
    {
        id = "bartender4", label = "Bartender4", kind = "bar",
        folders = { "Bartender4" },
        globals = { "Bartender4" },
        unverifiedFolders = { "Bartender4" },
        unverifiedGlobals = { "Bartender4" },
    },
    {
        id = "dominos", label = "Dominos", kind = "bar",
        folders = { "Dominos" },
        globals = { "Dominos" },
        unverifiedFolders = { "Dominos" },
        unverifiedGlobals = { "Dominos" },
    },
    {
        id = "mellorest", label = "MelloUI Restock", kind = "restock",
        folders = { "MelloUI_Restock", "MelloRestock" },
        globals = { "MelloUI_Restock", "MelloRestock" },
        saved = { "MelloUI_RestockDB", "MelloRestockDB", "MelloUIRestockDB" },
        unverifiedFolders = { "MelloUI_Restock", "MelloRestock" },
        unverifiedGlobals = { "MelloUI_Restock", "MelloRestock" },
        unverifiedSaved = { "MelloUI_RestockDB", "MelloRestockDB", "MelloUIRestockDB" },
    },
    {
        id = "zygor", label = "Zygor", kind = "guide",
        folders = {
            "ZygorGuidesViewer", "ZygorGuidesViewerClassic",
            "ZygorGuidesViewerClassicTBC", "ZygorGuidesViewerTBC",
            "ZygorGuidesViewerClassicTBCAnniv",
        },
        globals = { "ZygorGuidesViewer" },
    },
    {
        id = "mittenquest", label = "MittenQuest", kind = "guide",
        folders = { "MittenQuest" },
        globals = { "MittenQuest" },
        unverifiedFolders = { "MittenQuest" },
        unverifiedGlobals = { "MittenQuest" },
    },
    {
        id = "melloquest", label = "MelloUI Quest List", kind = "guide",
        folders = { "MelloUI_QuestList", "MelloQuestList" },
        globals = { "MelloUI_QuestList", "MelloQuestList" },
        unverifiedFolders = { "MelloUI_QuestList", "MelloQuestList" },
        unverifiedGlobals = { "MelloUI_QuestList", "MelloQuestList" },
    },
    {
        id = "libdbicon", label = "LibDBIcon", kind = "library",
        libs = { "LibDBIcon-1.0" },
        unverifiedLibs = { "LibDBIcon-1.0" },
    },
    {
        id = "tomtom", label = "TomTom", kind = "waypoint",
        folders = { "TomTom" },
        globals = { "TomTom" },
        unverifiedGlobals = { "TomTom" },
    },
}

function B:Reskins()
    return false
end

function B:GlowHooks()
    return false
end

local function NoteFor(entry)
    local parts = {}
    local function add(prefix, list)
        if type(list) == "table" and #list > 0 then
            parts[#parts + 1] = prefix .. table.concat(list, ", ")
        end
    end
    add("UNVERIFIED folder ", entry.unverifiedFolders)
    add("UNVERIFIED global ", entry.unverifiedGlobals)
    add("UNVERIFIED lib ", entry.unverifiedLibs)
    add("UNVERIFIED saved ", entry.unverifiedSaved)
    return table.concat(parts, "; ")
end

local function BlizzardHost()
    local ok, present = pcall(function()
        if UIParent ~= nil then return true end
        if GameTooltip ~= nil then return true end
        return false
    end)
    return ok and present == true
end

function B:EntryById(id)
    for _, entry in ipairs(self.CATALOG) do
        if entry.id == id then return entry end
    end
end

--- Restock shipped inside MelloUI. Nil unless that addon is loaded and the
--- module table is actually there. Lookup goes through Compat, then a
--- guarded field or GetModule. A throw or a non-table is "not present".
function B:MelloRestockEmbedded()
    local C = TA.Compat
    if not (C and type(C.IsAddOnLoaded) == "function") then return nil end
    local okLoaded, loaded = pcall(C.IsAddOnLoaded, "MelloUI")
    if not (okLoaded and loaded) then return nil end
    local okUI, mello = pcall(function() return rawget(_G, "MelloUI") end)
    if not okUI or type(mello) ~= "table" then return nil end
    local field = rawget(mello, "Restock")
    if type(field) == "table" then return field end
    local getModule = rawget(mello, "GetModule")
    if type(getModule) ~= "function" then return nil end
    local okMod, mod = pcall(getModule, mello, "Restock")
    if okMod and type(mod) == "table" then return mod end
    return nil
end

function B:EntryLoaded(entry)
    if entry.id == "blizzard" then return BlizzardHost() end
    -- Embedded module first. The folder and global checks below stay for
    -- an older MelloUI_Restock addon.
    if entry.id == "mellorest" and self:MelloRestockEmbedded() then return true end
    if entry.id == "zygor" then
        local U = TA.Utils
        if U and type(U.ZygorLoaded) == "function" then
            local ok, loaded = pcall(U.ZygorLoaded)
            if ok and loaded then return true end
        end
    end
    local C = TA.Compat
    for _, name in ipairs(entry.folders or {}) do
        if C and type(C.IsAddOnLoaded) == "function" then
            local ok, loaded = pcall(C.IsAddOnLoaded, name)
            if ok and loaded then return true end
        end
    end
    for _, name in ipairs(entry.globals or {}) do
        local ok, value = pcall(function() return rawget(_G, name) end)
        if ok and value ~= nil then return true end
    end
    for _, name in ipairs(entry.libs or {}) do
        local ok, lib = pcall(function()
            if type(LibStub) ~= "table" then return nil end
            return LibStub(name, true)
        end)
        if ok and lib ~= nil then return true end
    end
    return false
end

local function SafeTitle(entry)
    if entry.id == "blizzard" then return nil end
    local C = TA.Compat
    if not C or type(C.GetAddOnInfo) ~= "function" then return nil end
    for _, name in ipairs(entry.folders or {}) do
        local ok, _, title = pcall(C.GetAddOnInfo, name)
        if ok and type(title) == "string" and title ~= "" then return title end
    end
    return nil
end

function B:Detect()
    local rows = {}
    for _, entry in ipairs(self.CATALOG) do
        local ok, loaded = pcall(self.EntryLoaded, self, entry)
        local titleOk, title = pcall(SafeTitle, entry)
        rows[#rows + 1] = {
            id = entry.id,
            label = entry.label,
            kind = entry.kind,
            loaded = ok and loaded and true or false,
            note = NoteFor(entry),
            title = titleOk and title or nil,
        }
    end
    return rows
end

function B:IsLoaded(id)
    for _, row in ipairs(self:Detect()) do
        if row.id == id then return row.loaded and true or false end
    end
    return false
end

function B:IsStandalone()
    for _, row in ipairs(self:Detect()) do
        if row.loaded and row.id ~= "blizzard" then return false end
    end
    return true
end

function B:HostOwnsTooltip()
    return self:IsLoaded("elvui") or self:IsLoaded("melloui")
end

function B:ReportLines()
    local lines = {}
    for _, row in ipairs(self:Detect()) do
        local state = row.loaded and "loaded" or "not loaded"
        local title = (type(row.title) == "string" and row.title ~= "" and row.title ~= row.label)
            and (" (" .. row.title .. ")") or ""
        local note = (row.note and row.note ~= "") and (" " .. row.note) or ""
        lines[#lines + 1] = row.label .. ": " .. state .. title .. note
    end
    return lines
end

--- Append ToonAge lines after whatever the host already drew.
--- Refuses a missing tooltip. Does not wipe or replace existing lines.
function B:AppendTooltip(tip, lines)
    if type(tip) ~= "table" or type(lines) ~= "table" then return false end
    if type(tip.AddLine) ~= "function" then return false end
    for i = 1, #lines do
        local line = lines[i]
        if type(line) == "string" then
            tip:AddLine(line)
        elseif type(line) == "table" then
            if line.right ~= nil and type(tip.AddDoubleLine) == "function" then
                tip:AddDoubleLine(line.left or "", line.right,
                    line.r, line.g, line.b, line.r2, line.g2, line.b2)
            else
                tip:AddLine(line.text or line.left or "", line.r, line.g, line.b, line.wrap)
            end
        end
    end
    return true
end

function B:DrawReport(content, y, width, frames)
    if not content or type(content.CreateFontString) ~= "function" then
        return y or 0
    end
    frames = frames or {}
    y = y or 0
    width = width or 200
    local function keep(obj)
        if obj then frames[#frames + 1] = obj end
    end
    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if hdr then
        if hdr.SetFont and STANDARD_TEXT_FONT then
            pcall(hdr.SetFont, hdr, STANDARD_TEXT_FONT, 10, "OUTLINE")
        end
        if hdr.SetText then hdr:SetText("OTHER ADDONS") end
        if hdr.SetTextColor then hdr:SetTextColor(0.55, 0.40, 0.08, 1) end
        if hdr.SetPoint then hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y) end
        keep(hdr)
    end
    if content.CreateTexture then
        local line = content:CreateTexture(nil, "ARTWORK")
        if line then
            if line.SetHeight then line:SetHeight(1) end
            if line.SetPoint then
                line:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y - 14)
                line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -14, y - 14)
            end
            if line.SetColorTexture then line:SetColorTexture(0.40, 0.32, 0.08, 0.5) end
            keep(line)
        end
    end
    y = y - 22
    local ok, lines = pcall(self.ReportLines, self)
    if not ok or type(lines) ~= "table" then return y end
    for i = 1, #lines do
        local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if lbl then
            if lbl.SetFont and STANDARD_TEXT_FONT then
                pcall(lbl.SetFont, lbl, STANDARD_TEXT_FONT, 10, "")
            end
            if lbl.SetText then lbl:SetText(lines[i]) end
            if lbl.SetPoint then lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 14, y) end
            if lbl.SetWidth then lbl:SetWidth(width - 28) end
            if lbl.SetJustifyH then lbl:SetJustifyH("LEFT") end
            if lbl.SetWordWrap then lbl:SetWordWrap(true) end
            keep(lbl)
        end
        y = y - 16
    end
    return y - 8
end

-- ── Guide step-back ────────────────────────────────────────────────────

function B:GuideDeferEnabled(key)
    local t = TA.charDB and TA.charDB.tracker
    return not (t and t[key] == false)
end

function B:ToggleGuideDefer(key)
    if not (TA.charDB and TA.charDB.tracker) then return false end
    local on = not (TA.charDB.tracker[key] == false)
    TA.charDB.tracker[key] = not on
    return true
end

--- MittenQuest and MelloUI Quest List. Zygor stays on U.DeferToZygor.
function B:DeferOtherGuides()
    if self:IsLoaded("mittenquest") and self:GuideDeferEnabled("deferToMittenQuest") then
        return true
    end
    if self:IsLoaded("melloquest") and self:GuideDeferEnabled("deferToMelloQuestList") then
        return true
    end
    return false
end

-- ── Restock: read a host list, never write it ─────────────────────────

local function CopyPlain(value, depth)
    local kind = type(value)
    if kind ~= "table" then
        if kind == "function" or kind == "userdata" or kind == "thread" then return nil end
        return value
    end
    if depth >= 4 then return nil end
    local out = {}
    for k, v in pairs(value) do
        if type(k) == "string" or type(k) == "number" then
            local child = CopyPlain(v, depth + 1)
            if child ~= nil or v == false then out[k] = child end
        end
    end
    return out
end

--- In-memory MelloUIDB.Restock only. Never loads an addon and never runs a file.
function B:LiveMelloSettings()
    local ok, db = pcall(function() return rawget(_G, "MelloUIDB") end)
    if not ok or type(db) ~= "table" then return nil end
    local okS, settings = pcall(function() return rawget(db, "Restock") end)
    if not okS or type(settings) ~= "table" then return nil end
    return settings
end

local function ParseIdQtyBlob(text)
    local rows = {}
    if type(text) ~= "string" then return rows end
    for token in string.gmatch(text, "%S+") do
        local idText, qtyText = string.match(token, "^(%d+):(%d+)$")
        local id = tonumber(idText)
        local qty = tonumber(qtyText)
        if id and qty and id > 0 and id == math.floor(id)
            and qty >= 0 and qty == math.floor(qty) then
            rows[#rows + 1] = { id = id, qty = qty }
        end
    end
    return rows
end

--- Rows for this character from list_<GUID> strings. Nil when this table is
--- not that shape, so a legacy host db keeps its own items array.
--- {} when the shape is present but this character's list is not.
function B:MelloCharacterRows(settings)
    if type(settings) ~= "table" then return nil end
    local saw = false
    local okScan = pcall(function()
        for k, v in pairs(settings) do
            if type(k) == "string" and string.sub(k, 1, 5) == "list_" and type(v) == "string" then
                saw = true
            end
        end
    end)
    if not okScan or not saw then return nil end
    local guid
    local C = TA.Compat
    if C and type(C.PlayerGUID) == "function" then
        local ok, g = pcall(C.PlayerGUID)
        if ok and type(g) == "string" and g ~= "" then guid = g end
    end
    if not guid then return {} end
    local okV, blob = pcall(function() return rawget(settings, "list_" .. guid) end)
    if not okV or type(blob) ~= "string" then return {} end
    return ParseIdQtyBlob(blob)
end

function B:HostRestockTable()
    if not self:IsLoaded("mellorest") then return nil end
    if self:MelloRestockEmbedded() then
        local live = self:LiveMelloSettings()
        if type(live) == "table" then return live end
    end
    local entry = self:EntryById("mellorest")
    if not entry then return nil end
    for _, name in ipairs(entry.saved or {}) do
        local ok, db = pcall(function() return rawget(_G, name) end)
        if ok and type(db) == "table" then return db end
    end
    for _, name in ipairs(entry.globals or {}) do
        local ok, obj = pcall(function() return rawget(_G, name) end)
        if ok and type(obj) == "table" then
            local dbOk, db = pcall(function() return rawget(obj, "db") end)
            if dbOk and type(db) == "table" then return db end
        end
    end
    return nil
end

function B:ReadRestock()
    local host = self:HostRestockTable()
    if type(host) == "table" then
        if self:MelloRestockEmbedded() and host == self:LiveMelloSettings() then
            local rows = self:MelloCharacterRows(host)
            if rows then return { items = rows }, "melloui" end
        end
        return CopyPlain(host, 0), "melloui"
    end
    local own = TA.db and TA.db.addonBridge and TA.db.addonBridge.restock
    if type(own) == "table" then
        return CopyPlain(own, 0), "standalone"
    end
    return {}, "standalone"
end

function B:WriteStandalone(entries)
    if type(entries) ~= "table" or not TA.db then return false end
    local host = self:HostRestockTable()
    if host and entries == host then return false end
    TA.db.addonBridge = TA.db.addonBridge or {}
    TA.db.addonBridge.restock = CopyPlain(entries, 0) or {}
    return true
end

-- ── Minimap: LibDBIcon when it is present, otherwise the caller falls back ─

function B:LibDBIconLib()
    local ok, lib = pcall(function()
        if type(LibStub) ~= "table" then return nil end
        return LibStub("LibDBIcon-1.0", true)
    end)
    if not ok or type(lib) ~= "table" or type(lib.Register) ~= "function" then
        return nil
    end
    return lib
end

function B:OnMinimapClick(button)
    if button == "LeftButton" then
        if type(TA.ToggleUI) == "function" then TA:ToggleUI() end
    elseif button == "RightButton" then
        if TA.db then TA.db.useUnifiedUI = not TA.db.useUnifiedUI end
        if type(TA.ApplyLayout) == "function" then TA:ApplyLayout() end
        if type(TA.Raw) == "function" and TA.LOG then
            local mode = (TA.db and TA.db.useUnifiedUI) and "|cFF4AFF7AUnified HUD|r" or "|cFFFF9A1AFragmented Windows|r"
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Layout: " .. mode)
        end
    elseif button == "MiddleButton" then
        local saved = TA.db and TA.db.addonBridge and TA.db.addonBridge.minimap
        if type(saved) == "table" then
            saved.hide = not saved.hide
            local lib = self:LibDBIconLib()
            if lib and type(lib.Refresh) == "function" then
                pcall(lib.Refresh, lib, "ToonAge")
            end
        end
    end
end

function B:TryLibDBIcon()
    local lib = self:LibDBIconLib()
    if not lib or not TA.db then return false end
    TA.db.addonBridge = TA.db.addonBridge or {}
    local saved = TA.db.addonBridge.minimap
    if type(saved) ~= "table" then
        local pos = 45
        if TA.db.minimap and type(TA.db.minimap.position) == "number" then
            pos = TA.db.minimap.position
        end
        saved = { hide = false, minimapPos = pos }
        TA.db.addonBridge.minimap = saved
    end
    local bridge = self
    local ok = pcall(function()
        lib:Register("ToonAge", {
            icon = "Interface\\Icons\\Achievement_Character_Human_Female",
            OnClick = function(_, button)
                bridge:OnMinimapClick(button)
            end,
            OnTooltipShow = function(tip)
                bridge:AppendTooltip(tip, { "ToonAge" })
            end,
        }, saved)
    end)
    if not ok then return false end
    TA.minimapBtn = { libdbicon = true }
    return true
end

function B:Init()
    pcall(function() self:Detect() end)
end

return B
