-- ToonAge/Modules/Forever/Restock.lua
--
-- Bag counts for the Forever reagent list in Data/Forever/Reagents.lua.
-- Targets live in ToonAgeDB.addonBridge.restock, the same store AddonBridge
-- already uses for its standalone list. When MelloUI Restock is loaded its
-- list is read and shown beside ours, labeled "from MelloUI Restock".
-- Nothing here writes that addon's saved variables.

local TA = ToonAge
local M = {}
TA:RegisterModule("ForeverRestock", M)

local MELLO_LABEL = "from MelloUI Restock"
local TARGET_MAX = 999

local function Whole(n)
    n = tonumber(n)
    if not n then return nil end
    n = math.floor(n)
    if n < 0 then return 0 end
    if n > TARGET_MAX then return TARGET_MAX end
    return n
end

local function AsID(v)
    local n = tonumber(v)
    if n and n > 0 and n == math.floor(n) then return n end
    return nil
end

function M:Catalog()
    local data = TA.Data and TA.Data.ForeverReagents
    if type(data) ~= "table" then return {} end
    return data
end

function M:ByID(itemID)
    for _, item in ipairs(self:Catalog()) do
        if type(item) == "table" and item.itemID == itemID then return item end
    end
    return nil
end

--- Saved target only. Nil when the player has not stored one.
function M:SavedTarget(itemID)
    local cur = TA.db and TA.db.addonBridge and TA.db.addonBridge.restock
    if type(cur) ~= "table" then return nil end
    for _, row in ipairs(cur) do
        if type(row) == "table" and AsID(row.id) == itemID then
            return Whole(row.qty or row.count or row.target)
        end
    end
    return nil
end

--- Saved target, else the catalog default.
function M:TargetFor(itemID)
    local saved = self:SavedTarget(itemID)
    if saved ~= nil then return saved end
    local item = self:ByID(itemID)
    if item and type(item.defaultTarget) == "number" then
        return Whole(item.defaultTarget)
    end
    return nil
end

--- Write one target into the AddonBridge standalone list. Other rows stay.
--- WriteStandalone refuses the host table, and this builds a new one.
function M:SetTarget(itemID, qty)
    itemID = AsID(itemID)
    qty = Whole(qty)
    if not itemID or qty == nil or not TA.db or not (TA.AddonBridge and TA.AddonBridge.WriteStandalone) then
        return false
    end
    local rows = {}
    local cur = TA.db.addonBridge and TA.db.addonBridge.restock
    if type(cur) == "table" then
        for _, row in ipairs(cur) do
            local id = type(row) == "table" and AsID(row.id) or nil
            if id and id ~= itemID then
                rows[#rows + 1] = {
                    id = id,
                    qty = Whole(row.qty or row.count or row.target) or 0,
                    name = type(row.name) == "string" and row.name or nil,
                }
            end
        end
    end
    local item = self:ByID(itemID)
    rows[#rows + 1] = {
        id = itemID,
        qty = qty,
        name = item and item.name or nil,
    }
    return TA.AddonBridge:WriteStandalone(rows) and true or false
end

function M:Nudge(itemID, delta)
    local current = self:SavedTarget(itemID)
    if current == nil then current = self:TargetFor(itemID) end
    if current == nil then
        for _, row in ipairs(self:HostRows()) do
            if row.id == AsID(itemID) and tonumber(row.qty) then
                current = tonumber(row.qty)
                break
            end
        end
    end
    self:SetTarget(itemID, (current or 0) + (tonumber(delta) or 0))
    if C_Timer and type(C_Timer.After) == "function" then
        local restock = self
        local ok = pcall(C_Timer.After, 0, function() restock:RefreshViews() end)
        if ok then return end
    end
    self:RefreshViews()
end

function M:EnsureTargets()
    if not TA.db or not (TA.AddonBridge and TA.AddonBridge.WriteStandalone) then return end
    for _, item in ipairs(self:Catalog()) do
        if type(item) == "table" and AsID(item.itemID) then
            local cur = TA.db.addonBridge and TA.db.addonBridge.restock
            local found = false
            if type(cur) == "table" then
                for _, row in ipairs(cur) do
                    if type(row) == "table" and AsID(row.id) == item.itemID then
                        found = true
                        break
                    end
                end
            end
            if not found then
                self:SetTarget(item.itemID, item.defaultTarget or 0)
            end
        end
    end
end

local function RowFrom(entry)
    if type(entry) ~= "table" then return nil end
    local id = AsID(entry.id or entry.itemID or entry.itemId or entry.item)
    if not id then return nil end
    local name = entry.name or entry.itemName
    if type(name) ~= "string" then name = nil end
    return {
        id = id,
        qty = tonumber(entry.qty or entry.count or entry.target or entry.quantity or entry.amount),
        name = name,
    }
end

--- Read a host restock table. Several shapes are accepted because the host
--- saved-variable layout is unverified. This only reads the copy AddonBridge
--- already made.
local function ParseList(tbl)
    local out = {}
    if type(tbl) ~= "table" then return out end
    local nested = tbl.items or tbl.Items or tbl.list or tbl.reagents or tbl.entries
    if type(nested) == "table" then tbl = nested end
    local saw = false
    for _, entry in ipairs(tbl) do
        saw = true
        local row = RowFrom(entry)
        if row then out[#out + 1] = row end
    end
    if saw then return out end
    for k, v in pairs(tbl) do
        local id = AsID(k)
        if id and type(v) == "number" then
            out[#out + 1] = { id = id, qty = v }
        elseif id and type(v) == "table" then
            local row = RowFrom(v)
            if row then
                row.id = id
                out[#out + 1] = row
            end
        end
    end
    return out
end

function M:HostRows()
    local bridge = TA.AddonBridge
    if not (bridge and bridge.IsLoaded and bridge.ReadRestock) then return {} end
    if not bridge:IsLoaded("mellorest") then return {} end
    local copy, source = bridge:ReadRestock()
    if source ~= "melloui" or type(copy) ~= "table" then return {} end
    return ParseList(copy)
end

local function StudySpell(item)
    if type(item) ~= "table" or type(item.uses) ~= "table" then return nil end
    for _, use in ipairs(item.uses) do
        if type(use) == "table" and use.name == "Study" and type(use.spellID) == "number" then
            return use.spellID
        end
    end
    return nil
end

local function UseLines(item)
    local lines = {}
    if type(item) ~= "table" or type(item.uses) ~= "table" then return lines end
    for _, use in ipairs(item.uses) do
        if type(use) == "table" and type(use.name) == "string" then
            if type(use.spellID) == "number" then
                lines[#lines + 1] = string.format("%s (%d)", use.name, use.spellID)
            else
                lines[#lines + 1] = use.name
            end
        end
    end
    return lines
end

local function ApplyCount(row, compat)
    local have, bank
    if row.itemID and compat and type(compat.ItemCounts) == "function" then
        local ok, bags, extra = pcall(compat.ItemCounts, row.itemID)
        if ok and type(bags) == "number" then
            have = bags
            if type(extra) == "number" then bank = extra end
        end
    end
    row.have = have
    row.bank = bank
    if have == nil then
        row.haveText = "count unavailable"
    else
        row.haveText = string.format("%d / %s", have, row.target ~= nil and tostring(row.target) or "?")
        if row.target ~= nil and have < row.target then
            row.need = row.target - have
            row.warning = "need " .. row.need
        end
    end
    return row
end

--- Catalog rows, then any other targets we stored, then host rows we do not
--- already list. have is bags only. bank is separate. A nil have is
--- "count unavailable".
function M:Rows()
    self:EnsureTargets()
    local host = self:HostRows()
    local hostByID = {}
    for _, row in ipairs(host) do hostByID[row.id] = row end

    local out = {}
    local seen = {}
    local compat = TA.Compat

    local function markHost(row, id)
        if hostByID[id] then
            row.label = MELLO_LABEL
            row.source = "melloui"
        end
    end

    for _, item in ipairs(self:Catalog()) do
        if type(item) == "table" then
            local unknown = item.status == "UNKNOWN" or not AsID(item.itemID)
            local row = {
                itemID = AsID(item.itemID),
                name = item.name or "Reagent",
                unknown = unknown and true or false,
                note = item.note,
                uses = UseLines(item),
                source = "standalone",
            }
            if unknown then
                row.haveText = "UNKNOWN"
            else
                seen[row.itemID] = true
                row.target = self:TargetFor(row.itemID)
                ApplyCount(row, compat)
                markHost(row, row.itemID)
                local study = StudySpell(item)
                if study and row.need and row.need > 0 and compat and type(compat.PlayerKnowsSpell) == "function" then
                    local ok, known = pcall(compat.PlayerKnowsSpell, study)
                    if ok and known == true then
                        row.studyWarning = true
                        row.studyText = "Light Feather is below target and Study is known"
                    end
                end
            end
            out[#out + 1] = row
        end
    end

    local cur = TA.db and TA.db.addonBridge and TA.db.addonBridge.restock
    if type(cur) == "table" then
        for _, saved in ipairs(cur) do
            local id = type(saved) == "table" and AsID(saved.id) or nil
            if id and not seen[id] then
                seen[id] = true
                local fromHost = hostByID[id]
                local row = {
                    itemID = id,
                    name = (type(saved.name) == "string" and saved.name)
                        or (fromHost and fromHost.name)
                        or ("item " .. id),
                    target = self:SavedTarget(id),
                    source = "standalone",
                    unknown = false,
                }
                ApplyCount(row, compat)
                markHost(row, id)
                out[#out + 1] = row
            end
        end
    end

    for _, hostRow in ipairs(host) do
        if not seen[hostRow.id] then
            seen[hostRow.id] = true
            local target = self:SavedTarget(hostRow.id)
            if target == nil then target = tonumber(hostRow.qty) end
            local row = {
                itemID = hostRow.id,
                name = hostRow.name or ("item " .. hostRow.id),
                target = target,
                label = MELLO_LABEL,
                source = "melloui",
                unknown = false,
            }
            ApplyCount(row, compat)
            out[#out + 1] = row
        end
    end

    return out
end

function M:RefreshViews()
    local drawer = TA._settingsDrawer
    if type(drawer) == "table" and type(drawer.IsShown) == "function" then
        local ok, shown = pcall(drawer.IsShown, drawer)
        if ok and shown and drawer.content then
            local Settings = TA.GetModule and TA:GetModule("Settings")
            if Settings and type(Settings.Render) == "function" then
                pcall(Settings.Render, Settings, drawer.content, drawer.sidebar)
            end
        end
    end
    if TA.Layout and type(TA.Layout.RefreshUI) == "function" then
        pcall(TA.Layout.RefreshUI, TA.Layout)
    end
end

local function NoteFor(row)
    local parts = {}
    if row.warning then parts[#parts + 1] = row.warning end
    if row.bank ~= nil then parts[#parts + 1] = "bank " .. row.bank end
    if row.label then parts[#parts + 1] = row.label end
    if row.studyText then parts[#parts + 1] = row.studyText end
    if row.unknown and row.note then parts[#parts + 1] = row.note end
    if #parts == 0 then return nil end
    return table.concat(parts, "  ")
end

function M:Draw(content, y)
    if self._disabled then return y end
    local L = TA.Layout
    if not L then return y end
    local rows = self:Rows()
    y = L:SectionHeader(content, y, "Reagent restock",
        "Bags only. The bank is labeled on its own. Change a target in Settings.")
    if #rows == 0 then
        y = L:Paragraph(content, y, "No reagent list on this client.")
        return y
    end
    local buttons = {}
    for _, row in ipairs(rows) do
        local value, status
        if row.unknown then
            value = "UNKNOWN"
            status = "dim"
        elseif row.have == nil then
            value = "count unavailable"
            status = "dim"
        elseif row.need and row.need > 0 then
            value = row.haveText
            status = "warn"
        else
            value = row.haveText
            status = "good"
        end
        y = L:DataRow(content, y, {
            label = row.name,
            value = value,
            status = status,
            note = NoteFor(row),
            tooltipTitle = row.name,
            tooltip = (type(row.uses) == "table" and #row.uses > 0) and row.uses or nil,
        })
        if row.itemID and not row.unknown then
            local id = row.itemID
            local name = row.name
            buttons[#buttons + 1] = {
                label = name .. " -1",
                onClick = function() M:Nudge(id, -1) end,
            }
            buttons[#buttons + 1] = {
                label = name .. " +1",
                onClick = function() M:Nudge(id, 1) end,
            }
        end
    end
    if #buttons > 0 then
        y = L:ButtonRow(content, y, buttons)
    end
    return L:Spacer(y, 6)
end

function M:DrawSettings(parent, y, width, track)
    if self._disabled or not parent or type(track) ~= "function" then return y end
    local rows = self:Rows()
    for _, row in ipairs(rows) do
        local text
        if row.unknown then
            text = "|cFF9E968C" .. (row.name or "Reagent") .. "  UNKNOWN|r"
        elseif row.have == nil then
            text = string.format("%s  |cFF9E968Ccount unavailable|r  target %s",
                row.name, row.target ~= nil and tostring(row.target) or "?")
        else
            local count = string.format("%d / %s", row.have, row.target ~= nil and tostring(row.target) or "?")
            if row.need and row.need > 0 then
                text = row.name .. "  " .. count .. "  |cFFFFA633need " .. row.need .. "|r"
            else
                text = row.name .. "  |cFF4AFF7A" .. count .. "|r"
            end
        end
        if row.bank ~= nil then text = text .. "  bank " .. row.bank end
        if row.label then text = text .. "  " .. row.label end
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont(STANDARD_TEXT_FONT, 10, "")
        fs:SetText(text)
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
        fs:SetWidth((width or 200) - 28)
        fs:SetJustifyH("LEFT")
        track(fs)
        y = y - 16
        if row.studyText then
            local warn = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            warn:SetFont(STANDARD_TEXT_FONT, 10, "")
            warn:SetText("|cFFFFA633" .. row.studyText .. "|r")
            warn:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
            warn:SetWidth((width or 200) - 28)
            warn:SetJustifyH("LEFT")
            track(warn)
            y = y - 16
        end
        if row.itemID and not row.unknown then
            local id = row.itemID
            local function MakeButton(label, delta, xOff)
                local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
                btn:SetSize(36, 20)
                btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 14 + xOff, y)
                btn:SetText(label)
                btn:SetScript("OnClick", function() M:Nudge(id, delta) end)
                track(btn)
            end
            MakeButton("-1", -1, 0)
            MakeButton("+1", 1, 42)
            y = y - 24
        end
    end
    return y
end

function M:Init()
    if not TA.IsForever then
        self._disabled = true
        return
    end
    self:EnsureTargets()
end

return M
