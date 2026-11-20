-- ToonAge/Modules/Character/ProfessionBoard.lua
-- The professions tab: one card per profession. The bar on the card is the
-- only thing that changes between versions, and ProfessionSkills decides
-- which bar from the calls that exist.

local TA = ToonAge

local B = {}
TA:RegisterModule("ProfessionBoard", B)

local DrawLearned

local function RankOf(card)
    local rank, max = card.rank, card.max
    if type(card.segments) == "table" then
        for _, seg in ipairs(card.segments) do
            if seg.current then return seg.rank, seg.max end
        end
    end
    return rank, max
end

function B:Render(content, side)
    local L = TA.Layout
    if not L then return end
    local function Retire(pane)
        if not pane or not pane._laPane then return end
        if L.ReleasePane then L:ReleasePane(pane) end
        if pane.GetRegions then
            for _, region in ipairs({ pane:GetRegions() }) do
                if region.Hide then region:Hide() end
                if region.SetText then region:SetText("") end
            end
        end
        local PB = TA.ProfessionBatch
        if pane.GetChildren then
            for _, child in ipairs({ pane:GetChildren() }) do
                local keep = false
                if PB and PB.boxes then
                    for _, box in pairs(PB.boxes) do
                        if box == child then keep = true end
                    end
                end
                if not keep then
                    if child.Hide then child:Hide() end
                    if child.SetParent then child:SetParent(nil) end
                end
            end
        end
    end
    Retire(content)
    Retire(side)
    local sideY
    if L.CharacterSidebar then sideY = L:CharacterSidebar(side) end
    -- Retail gear lives in its own file. Older clients never load it, and a
    -- client without profession slot calls draws no row.
    local gear = TA.ProfessionGear
    if gear and gear.Begin then gear:Begin() end

    local y = -8
    y = L:SectionHeader(content, y, "Professions")

    local PS = TA.ProfessionSkills
    local result = (PS and PS.Collect and PS.Collect()) or { cards = {} }
    if result.unverified then
        y = L:Paragraph(content, y,
            "Skill lines and caps for this client are unverified until an in-game probe confirms them.")
    end

    local cards = result.cards or {}
    local function finish(at)
        at = DrawLearned(content, side, sideY, at, cards)
        L:Finish(content, at)
    end
    if not result.reader then
        y = L:Paragraph(content, y, "This client has no profession skill API this tab can read.")
        finish(y)
        return
    end
    if #cards == 0 then
        y = L:Paragraph(content, y, "No professions learned.")
        finish(y)
        return
    end

    for _, card in ipairs(cards) do
        local rank, max = RankOf(card)
        local text = string.format("%d / %d", rank or 0, max or 0)
        if card.secondary then text = text .. "  Secondary" end
        y = L:ProfessionCard(content, y, {
            name     = card.name,
            icon     = card.icon,
            rankText = text,
            rank     = rank,
            max      = max,
            segments = card.segments,
        })
        if gear and gear.Draw then
            y = gear:Draw(content, y, card)
        end
    end
    finish(y)
end

local function InCombat()
    local C = TA.Compat
    if C and type(C.InCombat) == "function" then
        local ok, locked = pcall(C.InCombat, C)
        if ok then return locked and true or false end
    end
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked and true or false
end

local function FontFile()
    local fontFile = STANDARD_TEXT_FONT
    if type(fontFile) ~= "string" or fontFile == "" then
        fontFile = "Fonts\\FRIZQT__.TTF"
    end
    return fontFile
end

-- Absent means open. Reagents and Output start open; Deposits and Time use
-- the same open default so every field is reachable until the player closes
-- one. A saved boolean wins. The account table is optional: a missing
-- ToonAgeDB, or a missing professionCalcGroups key, stays on the default.
local function GroupOpen(key)
    local db = TA.db
    if type(db) == "table" then
        local saved = db.professionCalcGroups
        if type(saved) == "table" and type(saved[key]) == "boolean" then
            return saved[key]
        end
        return true
    end
    local mem = TA.ProfessionBatch and TA.ProfessionBatch.groupOpen
    if type(mem) == "table" and type(mem[key]) == "boolean" then
        return mem[key]
    end
    return true
end

local function SetGroup(key, open)
    local PB = TA.ProfessionBatch
    if PB then
        PB.groupOpen = PB.groupOpen or {}
        PB.groupOpen[key] = open and true or false
    end
    if type(TA.db) ~= "table" then return end
    if type(TA.db.professionCalcGroups) ~= "table" then
        TA.db.professionCalcGroups = {}
    end
    TA.db.professionCalcGroups[key] = open and true or false
end

local function Measurer(PB)
    if PB.measurer and PB.measurer.SetText then return PB.measurer end
    if type(CreateFrame) ~= "function" then return nil end
    local holder = PB.measureFrame
    if not holder then
        holder = CreateFrame("Frame")
        holder._laKind = "ProfessionField"
        if holder.Hide then holder:Hide() end
        PB.measureFrame = holder
    end
    if not holder.CreateFontString then return nil end
    local fs = holder:CreateFontString(nil, "OVERLAY")
    if not fs then return nil end
    fs._laKind = "ProfessionField"
    PB.measurer = fs
    return fs
end

local function TextWidth(PB, text, size)
    local fs = Measurer(PB)
    if fs and fs.SetFont then fs:SetFont(FontFile(), size, "") end
    if fs and fs.SetText then fs:SetText(text) end
    if fs and fs.GetStringWidth then
        local ok, w = pcall(fs.GetStringWidth, fs)
        if ok and type(w) == "number" and w > 0 then return w end
    end
    return #tostring(text) * size * 0.55
end

-- One label width for the whole form. The slack is there so a 1px outline
-- does not clip the last glyph when the UI scale is 0.64: scale shrinks the
-- frame and the font together, and the extra UI units cover the outline.
local function Column(PB, parent, labels)
    local paneW = 184
    if parent and parent.GetWidth then
        local ok, w = pcall(parent.GetWidth, parent)
        if ok and type(w) == "number" and w > 40 then paneW = w end
    end
    local inset, gap, minBox, slack = 6, 4, 40, 8
    local usable = paneW - inset * 2
    if usable < minBox + gap + 48 then usable = minBox + gap + 48 end
    local room = usable - gap - minBox
    local chosen
    local try = 10
    while try >= 8 do
        local widest = 0
        for _, text in ipairs(labels) do
            local w = TextWidth(PB, text, try)
            if w > widest then widest = w end
        end
        local want = math.floor(widest + slack)
        if want <= room then
            chosen = { size = try, labelW = want }
            break
        end
        chosen = { size = try, labelW = math.max(40, math.floor(room)) }
        try = try - 1
    end
    if not chosen then chosen = { size = 8, labelW = 40 } end
    local boxW = math.floor(usable - gap - chosen.labelW)
    if boxW > 160 then boxW = 160 end
    if boxW < minBox then boxW = minBox end
    local boxX = inset + chosen.labelW + gap
    if boxX + boxW > paneW - inset then
        boxW = math.max(minBox, math.floor(paneW - inset - boxX))
    end
    return {
        size = chosen.size, labelW = chosen.labelW, boxW = boxW,
        boxX = boxX, inset = inset, rowW = math.max(40, paneW - inset * 2),
    }
end

local function FieldText(PB, key)
    local box = PB.boxes and PB.boxes[key]
    if box and box.GetText and not box.hidden then
        local ok, text = pcall(box.GetText, box)
        if ok and type(text) == "string" then return text end
    end
    local saved = PB.form and PB.form.text and PB.form.text[key]
    if type(saved) == "string" then return saved end
    return ""
end

local function MissingNames(PB)
    local names = {}
    local function blank(key)
        return FieldText(PB, key) == ""
    end
    if blank("n") then names[#names + 1] = "Batch size" end
    if blank("cut") then names[#names + 1] = "Auction cut" end
    if blank("vendor") then names[#names + 1] = "Vendor buy" end
    local reagents = (PB.form and PB.form.reagents) or 1
    local outputs = (PB.form and PB.form.outputs) or 1
    for i = 1, reagents do
        local p = "Reagent " .. i .. " "
        if blank("reag" .. i .. "need") then names[#names + 1] = p .. "need" end
        if blank("reag" .. i .. "owned") then names[#names + 1] = p .. "owned" end
        if blank("reag" .. i .. "price") then names[#names + 1] = p .. "price" end
        local n = tonumber(FieldText(PB, "n"))
        local need = tonumber(FieldText(PB, "reag" .. i .. "need"))
        local owned = tonumber(FieldText(PB, "reag" .. i .. "owned"))
        local short = n and need and owned and n == math.floor(n) and need == math.floor(need)
            and owned == math.floor(owned) and owned < need * n
        if short and blank("reag" .. i .. "buyQty") then names[#names + 1] = p .. "bought" end
        if short and blank("reag" .. i .. "buyPrice") then names[#names + 1] = p .. "paid" end
    end
    for i = 1, outputs do
        local p = "Output " .. i .. " "
        if blank("out" .. i .. "count") then names[#names + 1] = p .. "count" end
        if blank("out" .. i .. "price") then names[#names + 1] = p .. "listing" end
    end
    return names
end

local function SuccessText(result)
    local text = string.format("Conditional listing estimate %.4f gold. This is not realized profit.", result.net)
    if result.incomplete then text = text .. " Incomplete: an unknown listing loss was omitted." end
    if result.rate then
        text = text .. string.format(" Active crafting hour %.4f gold, from measured seconds only.", result.rate)
    else
        text = text .. " No hour rate: active crafting seconds were not entered."
    end
    if result.tiedUp and result.tiedUp > 0 then
        text = text .. string.format(" Tied-up deposit %.4f gold is not subtracted.", result.tiedUp)
    end
    return text
end

local function StatusText(PB)
    local names = MissingNames(PB)
    local result = PB.lastResult
    if type(result) == "table" and result.ok then
        return SuccessText(result), "dim"
    end
    local parts = {}
    if #names > 0 then
        parts[#parts + 1] = "Need: " .. table.concat(names, ", ")
    end
    if type(result) == "table" then
        parts[#parts + 1] = "Batch comparison withheld: " .. tostring(result.reason)
            .. ". The numbers above were kept."
    end
    if #parts == 0 then parts[1] = "Need: Batch size" end
    local color = "dim"
    if type(result) == "table" and not result.ok and #names == 0 then
        local reason = tostring(result.reason)
        if reason == "overflow" or reason == "shortfall" or reason == "deposit"
            or string.find(reason, "is not a number", 1, true) then
            color = "bad"
        end
    end
    return table.concat(parts, " "), color
end

local function AnchorBox(PB, parent, field, rowY, boxX, boxW)
    local L = TA.Layout
    local box = PB.boxes[field.key]
    if not (box and box.SetText) then
        box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        box.fieldKey = field.key
        PB.boxes[field.key] = box
    end
    -- Kept in PB.boxes and re-parented after RebuildChild. The self-test
    -- (TestHarness.lua CountDescendants) still counts them as orphaned
    -- unless they carry _laKind. Layout does not pool them: an edit box
    -- must not be handed out later as a button.
    box._laKind = "ProfessionField"
    box.fieldKey = field.key
    local detached = box.GetParent and box:GetParent() ~= parent
    if box.SetParent then box:SetParent(parent) end
    if box.ClearAllPoints then box:ClearAllPoints() end
    if box.SetFontObject then box:SetFontObject(ChatFontNormal or "ChatFontNormal") end
    if box.SetFont then box:SetFont(FontFile(), 11, "") end
    if box.SetTextInsets then box:SetTextInsets(5, 5, 2, 2) end
    if box.SetMultiLine then box:SetMultiLine(false) end
    if box.SetAutoFocus then box:SetAutoFocus(false) end
    if box.SetScript then
        box:SetScript("OnEscapePressed", function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
        box:SetScript("OnEnterPressed", function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
        -- userInput is true only for typing. SetText during a redraw
        -- passes false and must not invalidate or draw again.
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput ~= true then return end
            local ok, text = pcall(self.GetText, self)
            if ok and type(text) == "string" and self.fieldKey then
                PB.form.text[self.fieldKey] = text
            end
            local okResult, result = pcall(PB.CompareBatch, PB.InputFromForm())
            if okResult then PB.lastResult = result end
            local line = PB.resultLine
            if line and line.SetText then
                local text = StatusText(PB)
                line:SetText(text)
            end
        end)
    end
    local boxH = 18
    if type(boxW) ~= "number" or boxW <= 0 then boxW = 160 end
    if L and L.Width and parent and parent.GetWidth then
        local ok, paneW = pcall(parent.GetWidth, parent)
        if ok and type(paneW) == "number" and paneW > 0 and boxX + boxW > paneW then
            boxW = math.max(40, math.floor(paneW - boxX))
        end
    end
    if box.SetSize then box:SetSize(boxW, boxH) end
    local y = rowY
    if type(y) ~= "number" then y = -8 end
    if box.SetPoint then box:SetPoint("TOPLEFT", parent, "TOPLEFT", boxX or 8, y - 1) end
    if parent and parent.GetFrameLevel and box.SetFrameLevel then
        local ok, level = pcall(parent.GetFrameLevel, parent)
        if ok and type(level) == "number" then box:SetFrameLevel(level + 2) end
    end
    if parent and parent.GetFrameStrata and box.SetFrameStrata then
        local ok, strata = pcall(parent.GetFrameStrata, parent)
        if ok and type(strata) == "string" then box:SetFrameStrata(strata) end
    end
    if box.SetText then box:SetText(PB.form.text[field.key] or "") end
    box.hidden = false
    if detached and box.ClearFocus then box:ClearFocus() end
    if box.Show then box:Show() end
    return box
end

local function DrawCalcForm(parent, y)
    local L = TA.Layout
    local PB = TA.ProfessionBatch
    if not (L and PB and parent) then return end
    PB.form = PB.form or { outputs = 1, reagents = 1, text = {} }
    PB.form.text = PB.form.text or {}
    PB.boxes = PB.boxes or {}
    if type(y) ~= "number" then y = -8 end
    local always = {
        { key = "n", label = "Batch size", tip = "Batch size: number of crafts" },
        { key = "cut", label = "Auction cut", tip = "Auction cut as a fraction of the sale price, for example 0.05" },
        { key = "vendor", label = "Vendor buy (g)", tip = "Vendor buy for the whole batch, in gold. Enter 0 when there is no vendor material." },
    }
    local groups = {
        { key = "deposits", title = "Deposits", fields = {
            { key = "lostCraft", label = "Lost deposits (g)", tip = "Known lost deposit on the crafted listings, in gold. Leave blank if unknown." },
            { key = "lostRaw", label = "Raw deposits (g)", tip = "Known lost deposit on the raw listings this craft avoids, in gold. Leave blank if unknown." },
            { key = "refund", label = "Refund tied (g)", tip = "Refundable deposit tied up, in gold. It is not subtracted. Leave blank if none." },
        } },
        { key = "reagents", title = "Reagents" },
        { key = "output", title = "Output" },
        { key = "time", title = "Time", fields = {
            { key = "seconds", label = "Active time (s)", tip = "Active crafting seconds for the batch. Leave blank to withhold the hour rate." },
        } },
    }
    local function reagentFields()
        local rows = {}
        for i = 1, PB.form.reagents do
            local p = "Reagent " .. i .. " "
            rows[#rows + 1] = { key = "reag" .. i .. "need", label = "Reagent " .. i .. " need",
                tip = p .. "need per craft, in items. The batch size multiplies this." }
            rows[#rows + 1] = { key = "reag" .. i .. "owned", label = "Reagent " .. i .. " owned",
                tip = p .. "owned, in items. This is not multiplied again." }
            rows[#rows + 1] = { key = "reag" .. i .. "price", label = "Reagent " .. i .. " price (g)",
                tip = p .. "listing price, in gold each. Not a completed sale." }
            rows[#rows + 1] = { key = "reag" .. i .. "buyQty", label = "Reagent " .. i .. " bought",
                tip = p .. "quantity bought, in items. The full quantity is the cash paid." }
            rows[#rows + 1] = { key = "reag" .. i .. "buyPrice", label = "Reagent " .. i .. " paid (g)",
                tip = p .. "price paid, in gold each." }
        end
        return rows
    end
    local function outputFields()
        local rows = {}
        for i = 1, PB.form.outputs do
            local p = "Output " .. i .. " "
            rows[#rows + 1] = { key = "out" .. i .. "count", label = "Output " .. i .. " count",
                tip = p .. "count per craft, in items. The batch size multiplies this." }
            rows[#rows + 1] = { key = "out" .. i .. "price", label = "Output " .. i .. " listing (g)",
                tip = p .. "listing price, in gold each. Not realized profit." }
        end
        return rows
    end
    local visible = {}
    for _, field in ipairs(always) do visible[#visible + 1] = field end
    for _, group in ipairs(groups) do
        local fields = group.fields
        if group.key == "reagents" then fields = reagentFields() end
        if group.key == "output" then fields = outputFields() end
        group._fields = fields
        if GroupOpen(group.key) then
            for _, field in ipairs(fields) do visible[#visible + 1] = field end
        end
    end
    local labels = {}
    for _, field in ipairs(visible) do labels[#labels + 1] = field.label end
    for _, group in ipairs(groups) do
        for _, field in ipairs(group._fields) do labels[#labels + 1] = field.label end
    end
    local col = Column(PB, parent, labels)
    local order = {}
    local function place(field)
        local rowY = y
        if type(L.LabelInput) == "function" then
            local row
            y, row = L:LabelInput(parent, rowY, {
                label = field.label,
                tooltip = field.tip,
                labelWidth = col.labelW,
                width = col.rowW,
                x = col.inset,
                size = col.size,
                height = 20,
            })
            if row then row.fieldKey = field.key end
        elseif L.Paragraph then
            y = L:Paragraph(parent, rowY, field.label)
        end
        order[#order + 1] = AnchorBox(PB, parent, field, rowY, col.boxX, col.boxW)
    end
    for _, field in ipairs(always) do place(field) end
    for _, group in ipairs(groups) do
        local open = GroupOpen(group.key)
        if L.ButtonRow then
            local mark = open and "- " or "+ "
            y = L:ButtonRow(parent, y, {
                {
                    label = mark .. group.title,
                    onClick = function()
                        SetGroup(group.key, not GroupOpen(group.key))
                        if PB._rerender then PB._rerender() end
                    end,
                },
            })
        end
        if open then
            if group.key == "reagents" and L.ButtonRow and PB._addReagent then
                y = L:ButtonRow(parent, y, {
                    { label = "Add reagent", onClick = PB._addReagent },
                    { label = "Remove reagent", onClick = PB._removeReagent },
                })
            end
            if group.key == "output" and L.ButtonRow and PB._addOutput then
                y = L:ButtonRow(parent, y, {
                    { label = "Add output", onClick = PB._addOutput },
                    { label = "Remove output", onClick = PB._removeOutput },
                })
            end
            for _, field in ipairs(group._fields) do place(field) end
        end
    end
    if L.ButtonRow and PB._calc then
        y = L:ButtonRow(parent, y, {
            { label = "Calculate batch", onClick = PB._calc },
        })
    end
    for i = 1, #order do
        local nxt = order[i + 1]
        local box = order[i]
        if box.SetScript then
            box:SetScript("OnTabPressed", function()
                if InCombat() then return end
                if nxt and nxt.SetFocus then nxt:SetFocus() end
            end)
        end
    end
    local keep = {}
    for _, field in ipairs(always) do keep[field.key] = true end
    for _, group in ipairs(groups) do
        if GroupOpen(group.key) then
            for _, field in ipairs(group._fields) do keep[field.key] = true end
        end
    end
    for key, box in pairs(PB.boxes) do
        if not keep[key] then
            box.hidden = true
            if box.Hide then box:Hide() end
        end
    end
    PB.formParent = parent
    if L.Finish then L:Finish(parent, y) end
end

function DrawLearned(content, side, sideY, y, cards)
    local L = TA.Layout
    if not L then return y end
    if not (TA.IsForever or TA.flavor == "forever") then return y end
    local PB = TA.ProfessionBatch
    if not (PB and type(PB.Refresh) == "function" and type(PB.CompareBatch) == "function" and type(PB.InputFromForm) == "function") then
        return y
    end
    PB.form = PB.form or { outputs = 1, reagents = 1, text = {} }
    PB.form.text = PB.form.text or {}
    PB.boxes = PB.boxes or {}
    for _, box in pairs(PB.boxes) do
        if box and box.GetText then
            local ok, text = pcall(box.GetText, box)
            local secret = false
            if ok and type(issecretvalue) == "function" then
                local okSecret, isSecret = pcall(issecretvalue, text)
                secret = (not okSecret) or isSecret == true
            end
            if ok and not secret and type(text) == "string" then PB.form.text[box.fieldKey] = text end
        end
    end
    local function rerender()
        if B.Render and TA.UI and TA.UI.contentChild then
            B:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end
    local function markStale()
        if PB.lastResult ~= nil then
            PB.lastResult = { ok = false, reason = "outdated" }
        end
    end
    local function changeRows(apply)
        return function()
            local beforeR, beforeO = PB.form.reagents, PB.form.outputs
            apply()
            if PB.form.reagents ~= beforeR or PB.form.outputs ~= beforeO then
                markStale()
            end
            rerender()
        end
    end
    PB._rerender = rerender
    PB._addReagent = changeRows(function() PB.form.reagents = PB.form.reagents + 1 end)
    PB._removeReagent = changeRows(function()
        if PB.form.reagents > 1 then PB.form.reagents = PB.form.reagents - 1 end
    end)
    PB._addOutput = changeRows(function() PB.form.outputs = PB.form.outputs + 1 end)
    PB._removeOutput = changeRows(function()
        if PB.form.outputs > 1 then PB.form.outputs = PB.form.outputs - 1 end
    end)
    PB._calc = function()
        PB.lastResult = PB.CompareBatch(PB.InputFromForm())
        rerender()
    end
    y = L:SectionHeader(content, y, "Learned recipes")
    y = L:Paragraph(content, y, PB.lastNote or
        "Learned recipes are not enabled from the open profession window. Ownership of that window is not a verified field. The calculator on the left uses only the numbers you type.")
    local shown = PB.CurrentView and PB.CurrentView(PB.LiveIdentity and PB.LiveIdentity() or nil) or {}
    if #shown == 0 then
        y = L:Paragraph(content, y, "No saved learned recipes are shown for this character.")
    end
    for _, rec in ipairs(shown) do
        y = L:Paragraph(content, y, tostring(rec.professionID) .. " " .. tostring(rec.profession) .. ": " .. rec.name
            .. " (previously saved, not a complete current read)")
    end
    if L.ButtonRow then
        y = L:ButtonRow(content, y, {
            { label = "Refresh learned recipes", onClick = function() PB:Refresh(cards); rerender() end },
        })
    end
    y = L:Paragraph(content, y,
        "Gold means the number you type. The result is a conditional listing estimate, not realized profit and not gold earned. The hour, when shown, uses active crafting seconds only.")
    local status, color = StatusText(PB)
    y = L:Paragraph(content, y, status, { color = color })
    PB.resultLine = nil
    if content.GetRegions then
        for _, region in ipairs({ content:GetRegions() }) do
            if region.GetText and region:GetText() == status then
                PB.resultLine = region
            end
        end
    end
    if type(TA.RegisterLeftPanel) == "function" then
        TA:RegisterLeftPanel("professions", {
            place = "below",
            build = function(slotContent) DrawCalcForm(slotContent, -8) end,
            refresh = function(slotContent) DrawCalcForm(slotContent, -8) end,
            release = function()
                for _, box in pairs(PB.boxes or {}) do
                    if box.ClearFocus then box:ClearFocus() end
                    if box.Hide then box:Hide() end
                    box.hidden = true
                end
            end,
        })
    end
    local ui = TA.UI
    if ui and ui._leftPanelDefer then return y end
    local slot = ui and ui._leftSlot
    local slotShown = slot and slot.scroll and slot.scroll.IsShown and slot.scroll:IsShown()
    if slotShown and ui._leftPanelTab == "professions" and slot.content then
        if L.ReleasePane then L:ReleasePane(slot.content) end
        DrawCalcForm(slot.content, -8)
        return y
    end
    -- sideY is the next free row under the character block. The last sidebar
    -- line can wrap a few pixels past that row, so the form starts lower and
    -- does not cover the name or the role.
    local formY = -16
    if type(sideY) == "number" then formY = sideY - 12 end
    DrawCalcForm(side, formY)
    return y
end

function B:OnEvent(event)
    if event ~= "SKILL_LINES_CHANGED" then return end
    if not (TA.UI and TA.UI.activeTab == "professions" and TA.UI.contentChild) then return end
    self:Render(TA.UI.contentChild, TA.UI.sideChild)
end
