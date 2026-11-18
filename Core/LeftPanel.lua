-- ToonAge/Core/LeftPanel.lua
-- A slot under the character block. A tab opts in by registering callbacks.
-- Tabs that do not register are not touched: nothing here draws on its own,
-- and Mount is a no-op for an unknown tab.
--
-- The slot has its own scroll, separate from the sidebar scroll that holds
-- the character block. On tab switch the host calls Release, which runs the
-- tab's release callback and then Core/Layout.lua ReleasePane so pooled rows
-- go back to the pool. The scroll frame itself is created once per window.
--
-- Cata and Wrath do not load Layout. Release still runs the tab callback
-- there; the pool hand-back is skipped when Layout is absent.
--
--   TA:RegisterLeftPanel(tabKey, spec) -> boolean
--     spec.build(content, host)    required. Draw into the slot scroll child.
--     spec.refresh(content, host)  optional. Update without leaving the tab.
--     spec.release(content, host)  optional. Called before pooled frames return.
--     spec.place                   optional. "below" (default) or "swap".
--       "below" keeps the character block and anchors the slot under it.
--       "swap" hides that scroll and the slot fills the sidebar.
--   TA:ClearLeftPanel(tabKey) -> boolean
--   TA:LeftPanelSpec(tabKey) -> spec or nil
--   TA:ReleaseLeftPanel(ui) -> boolean
--   TA:MountLeftPanel(ui, tabKey) -> boolean
--   TA:RefreshLeftPanel(ui) -> boolean
--
-- host = { scroll, content, sidebar, side, place, width, tabKey }
-- ui supplies sidebar, sideScroll, sideChild, and sideWidth. The window
-- sets _leftPanelTab while a slot is mounted; the empty-sidebar check reads it.

local TA = ToonAge

local REG = {}

local function ValidSpec(spec)
    if type(spec) ~= "table" then return false end
    if type(spec.build) ~= "function" then return false end
    if spec.refresh ~= nil and type(spec.refresh) ~= "function" then return false end
    if spec.release ~= nil and type(spec.release) ~= "function" then return false end
    if spec.place ~= nil and spec.place ~= "below" and spec.place ~= "swap" then
        return false
    end
    return true
end

function TA:RegisterLeftPanel(tabKey, spec)
    if type(tabKey) ~= "string" or tabKey == "" then return false end
    if not ValidSpec(spec) then return false end
    REG[tabKey] = spec
    return true
end

function TA:ClearLeftPanel(tabKey)
    if type(tabKey) ~= "string" or REG[tabKey] == nil then return false end
    REG[tabKey] = nil
    return true
end

function TA:LeftPanelSpec(tabKey)
    if type(tabKey) ~= "string" then return nil end
    return REG[tabKey]
end

local function CallHeight(frame)
    if not (frame and frame.GetHeight) then return 0 end
    local ok, h = pcall(frame.GetHeight, frame)
    if ok and type(h) == "number" then return h end
    return 0
end

local function ScrollRange(scroll)
    if scroll.GetVerticalScrollRange then
        local ok, reported = pcall(scroll.GetVerticalScrollRange, scroll)
        if ok and type(reported) == "number" and reported > 0 then
            return reported
        end
    end
    local child = scroll.GetScrollChild and scroll:GetScrollChild() or nil
    local contentH = CallHeight(child)
    local viewH = CallHeight(scroll)
    if contentH > viewH then return contentH - viewH end
    return 0
end

local function OnWheel(self, delta)
    if type(delta) ~= "number" or not self.SetVerticalScroll then return end
    local cur = 0
    if self.GetVerticalScroll then
        local ok, n = pcall(self.GetVerticalScroll, self)
        if ok and type(n) == "number" then cur = n end
    end
    local range = ScrollRange(self)
    local nxt = cur - delta * 24
    if nxt < 0 then nxt = 0 end
    if nxt > range then nxt = range end
    self:SetVerticalScroll(nxt)
end

local function Ensure(ui)
    if ui._leftSlot and ui._leftSlot.scroll then return ui._leftSlot end
    if type(CreateFrame) ~= "function" or not ui.sidebar then return nil end
    local scroll = CreateFrame("ScrollFrame", nil, ui.sidebar, "UIPanelScrollFrameTemplate")
    scroll._laKind = "LeftPanelSlot"
    local content = CreateFrame("Frame", nil, scroll)
    content._laPane = true
    content._laKind = "LeftPanelSlot"
    if scroll.SetScrollChild then scroll:SetScrollChild(content) end
    if scroll.EnableMouseWheel then scroll:EnableMouseWheel(true) end
    if scroll.SetScript then scroll:SetScript("OnMouseWheel", OnWheel) end
    if ui.sidebar.GetFrameLevel and scroll.SetFrameLevel then
        local ok, level = pcall(ui.sidebar.GetFrameLevel, ui.sidebar)
        if ok and type(level) == "number" then scroll:SetFrameLevel(level + 5) end
    end
    if scroll.Hide then scroll:Hide() end
    ui._leftSlot = { scroll = scroll, content = content }
    return ui._leftSlot
end

local function Place(ui, slot, place)
    local scroll = slot.scroll
    if scroll.ClearAllPoints then scroll:ClearAllPoints() end
    local charH = 0
    if place == "below" then
        charH = CallHeight(ui.sideChild)
        if charH < 1 then charH = 0 end
    end
    local top = 4
    if place == "below" and charH > 0 then top = 4 + charH + 4 end
    if scroll.SetPoint and ui.sidebar then
        scroll:SetPoint("TOPLEFT", ui.sidebar, "TOPLEFT", 4, -top)
        scroll:SetPoint("BOTTOMRIGHT", ui.sidebar, "BOTTOMRIGHT", -22, 4)
    end
    if place == "swap" then
        if ui.sideScroll and ui.sideScroll.Hide then ui.sideScroll:Hide() end
    elseif ui.sideScroll and ui.sideScroll.Show then
        ui.sideScroll:Show()
    end
end

local function HandBack(slot)
    local L = TA.Layout
    if L and type(L.ReleasePane) == "function" and slot and slot.content then
        pcall(L.ReleasePane, L, slot.content)
    end
end

function TA:ReleaseLeftPanel(ui)
    if type(ui) ~= "table" or ui._leftPanelTab == nil then return false end
    local spec = REG[ui._leftPanelTab]
    local slot = ui._leftSlot
    if spec and type(spec.release) == "function" and slot then
        pcall(spec.release, slot.content, slot.host)
    end
    HandBack(slot)
    if slot and slot.place == "swap" and ui.sideScroll and ui.sideScroll.Show then
        ui.sideScroll:Show()
    end
    if slot and slot.scroll then
        if slot.scroll.SetVerticalScroll then slot.scroll:SetVerticalScroll(0) end
        if slot.scroll.Hide then slot.scroll:Hide() end
    end
    if slot then
        slot.place = nil
        slot.host = nil
    end
    ui._leftPanelTab = nil
    return true
end

function TA:MountLeftPanel(ui, tabKey)
    if type(ui) ~= "table" or type(tabKey) ~= "string" then return false end
    local spec = REG[tabKey]
    if not spec then return false end
    if ui._leftPanelTab ~= nil then self:ReleaseLeftPanel(ui) end
    local slot = Ensure(ui)
    if not slot then return false end
    local place = (spec.place == "swap") and "swap" or "below"
    Place(ui, slot, place)
    local width = ui.sideWidth
    if type(width) ~= "number" or width <= 0 then width = 184 end
    width = math.floor(width)
    if slot.content.SetWidth then slot.content:SetWidth(width) end
    if slot.content.SetHeight then
        local h = CallHeight(slot.content)
        if h < 1 then slot.content:SetHeight(1) end
    end
    local host = {
        scroll = slot.scroll,
        content = slot.content,
        sidebar = ui.sidebar,
        side = ui.sideChild,
        place = place,
        width = width,
        tabKey = tabKey,
    }
    slot.host = host
    slot.place = place
    ui._leftPanelTab = tabKey
    if slot.scroll.Show then slot.scroll:Show() end
    HandBack(slot)
    local ok, err = pcall(spec.build, slot.content, host)
    if not ok then
        if TA.ErrorLog and TA.ErrorLog.Log then
            TA.ErrorLog:Log("LeftPanel", tostring(err), tabKey)
        end
        return false
    end
    return true
end

function TA:RefreshLeftPanel(ui)
    if type(ui) ~= "table" or ui._leftPanelTab == nil then return false end
    local spec = REG[ui._leftPanelTab]
    local slot = ui._leftSlot
    if not (spec and type(spec.refresh) == "function" and slot) then return false end
    local ok = pcall(spec.refresh, slot.content, slot.host)
    return ok and true or false
end
