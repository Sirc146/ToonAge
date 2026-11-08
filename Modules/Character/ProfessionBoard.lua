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
    if L.CharacterSidebar then L:CharacterSidebar(side) end
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
        at = DrawLearned(content, at, cards)
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

function DrawLearned(content, y, cards)
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
    local function plan()
        local rows = {
            { key = "n", label = "Batch size: number of crafts" },
            { key = "cut", label = "Auction cut as a fraction of the sale price, for example 0.05" },
            { key = "vendor", label = "Vendor buy for the whole batch, in gold. Enter 0 when there is no vendor material." },
            { key = "lostCraft", label = "Known lost deposit on the crafted listings, in gold. Leave blank if unknown." },
            { key = "lostRaw", label = "Known lost deposit on the raw listings this craft avoids, in gold. Leave blank if unknown." },
            { key = "refund", label = "Refundable deposit tied up, in gold. It is not subtracted. Leave blank if none." },
            { key = "seconds", label = "Active crafting seconds for the batch. Leave blank to withhold the hour rate." },
        }
        for i = 1, PB.form.reagents do
            local p = "Reagent " .. i .. " "
            rows[#rows + 1] = { key = "reag" .. i .. "need", label = p .. "need per craft, in items. The batch size multiplies this." }
            rows[#rows + 1] = { key = "reag" .. i .. "owned", label = p .. "owned, in items. This is not multiplied again." }
            rows[#rows + 1] = { key = "reag" .. i .. "price", label = p .. "listing price, in gold each. Not a completed sale." }
            rows[#rows + 1] = { key = "reag" .. i .. "buyQty", label = p .. "quantity bought, in items. The full quantity is the cash paid." }
            rows[#rows + 1] = { key = "reag" .. i .. "buyPrice", label = p .. "price paid, in gold each." }
        end
        for i = 1, PB.form.outputs do
            local p = "Output " .. i .. " "
            rows[#rows + 1] = { key = "out" .. i .. "count", label = p .. "count per craft, in items. The batch size multiplies this." }
            rows[#rows + 1] = { key = "out" .. i .. "price", label = p .. "listing price, in gold each. Not realized profit." }
        end
        return rows
    end
    y = L:SectionHeader(content, y, "Learned recipes")
    y = L:Paragraph(content, y, PB.lastNote or
        "Learned recipes are not enabled from the open profession window. Ownership of that window is not a verified field. The calculator below uses only the numbers you type.")
    local shown = PB.CurrentView and PB.CurrentView(PB.LiveIdentity and PB.LiveIdentity() or nil) or {}
    if #shown == 0 then
        y = L:Paragraph(content, y, "No saved learned recipes are shown for this character.")
    end
    for _, rec in ipairs(shown) do
        y = L:Paragraph(content, y, tostring(rec.professionID) .. " " .. tostring(rec.profession) .. ": " .. rec.name
            .. " (previously saved, not a complete current read)")
    end
    y = L:ButtonRow(content, y, {
        { label = "Refresh learned recipes", onClick = function() PB:Refresh(cards); rerender() end },
        { label = "Add reagent", onClick = changeRows(function() PB.form.reagents = PB.form.reagents + 1 end) },
        { label = "Remove reagent", onClick = changeRows(function()
            if PB.form.reagents > 1 then PB.form.reagents = PB.form.reagents - 1 end
        end) },
        { label = "Add output", onClick = changeRows(function() PB.form.outputs = PB.form.outputs + 1 end) },
        { label = "Remove output", onClick = changeRows(function()
            if PB.form.outputs > 1 then PB.form.outputs = PB.form.outputs - 1 end
        end) },
        { label = "Calculate batch", onClick = function()
            PB.lastResult = PB.CompareBatch(PB.InputFromForm())
            rerender()
        end },
    })
    y = L:Paragraph(content, y,
        "Gold means the number you type. The result is a conditional listing estimate, not realized profit and not gold earned. The hour, when shown, uses active crafting seconds only.")
    local function PlaceBox(field, at)
        local box = PB.boxes[field.key]
        if not (box and box.SetText) then
            box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
            box.fieldKey = field.key
            PB.boxes[field.key] = box
        end
        local detached = box.GetParent and box:GetParent() ~= content
        if box.SetParent then box:SetParent(content) end
        if box.ClearAllPoints then box:ClearAllPoints() end
        if box.SetFontObject then box:SetFontObject(ChatFontNormal or "ChatFontNormal") end
        if box.SetFont then
            local fontFile = STANDARD_TEXT_FONT
            if type(fontFile) ~= "string" or fontFile == "" then fontFile = "Fonts\\FRIZQT__.TTF" end
            box:SetFont(fontFile, 11, "")
        end
        if box.SetTextInsets then box:SetTextInsets(5, 5, 2, 2) end
        if box.SetMultiLine then box:SetMultiLine(false) end
        if box.SetAutoFocus then box:SetAutoFocus(false) end
        if box.SetScript then
            box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
            -- userInput is true only for typing. SetText during a redraw
            -- passes false and must not invalidate or draw again.
            box:SetScript("OnTextChanged", function(self, userInput)
                if userInput ~= true then return end
                local result = PB.lastResult
                if type(result) ~= "table" or result.reason == "outdated" then return end
                -- The estimate is no longer current, but the fields stay as
                -- they are. Rebuilding the pane would SetText every box and
                -- move the caret. A second keystroke finds this reason and
                -- does not draw again.
                PB.lastResult = { ok = false, reason = "outdated" }
                local line = PB.resultLine
                if line and line.SetText then
                    line:SetText("Batch comparison withheld: outdated. The numbers above were kept.")
                end
            end)
        end
        local boxW, boxH = 160, 22
        if L.Width then
            local usable = L:Width(content)
            if type(usable) == "number" and usable > 0 and usable < boxW then boxW = usable end
        end
        if box.SetSize then box:SetSize(boxW, boxH) end
        if box.SetPoint then box:SetPoint("TOPLEFT", content, "TOPLEFT", L.PAD or 14, at) end
        if content.GetFrameLevel and box.SetFrameLevel then
            box:SetFrameLevel((content:GetFrameLevel() or 0) + 2)
        end
        if content.GetFrameStrata and box.SetFrameStrata then
            local strata = content:GetFrameStrata()
            if type(strata) == "string" then box:SetFrameStrata(strata) end
        end
        if box.SetText then box:SetText(PB.form.text[field.key] or "") end
        box.hidden = false
        if detached and box.ClearFocus then box:ClearFocus() end
        if box.Show then box:Show() end
        return box, at - boxH - 6
    end
    local order = {}
    for _, field in ipairs(plan()) do
        y = L:Paragraph(content, y, field.label)
        local box
        box, y = PlaceBox(field, y)
        order[#order + 1] = box
    end
    for i = 1, #order do
        local nxt = order[i + 1]
        if order[i].SetScript then
            order[i]:SetScript("OnTabPressed", function()
                if nxt and nxt.SetFocus then nxt:SetFocus() end
            end)
        end
    end
    for key, box in pairs(PB.boxes) do
        local keep = false
        for _, field in ipairs(plan()) do if field.key == key then keep = true end end
        if not keep then
            box.hidden = true
            if box.Hide then box:Hide() end
        end
    end
    local result = PB.lastResult
    if type(result) == "table" then
        local text
        if result.ok then
            text = string.format("Conditional listing estimate %.4f gold. This is not realized profit.", result.net)
            if result.incomplete then text = text .. " Incomplete: an unknown listing loss was omitted." end
            if result.rate then
                text = text .. string.format(" Active crafting hour %.4f gold, from measured seconds only.", result.rate)
            else
                text = text .. " No hour rate: active crafting seconds were not entered."
            end
            if result.tiedUp and result.tiedUp > 0 then
                text = text .. string.format(" Tied-up deposit %.4f gold is not subtracted.", result.tiedUp)
            end
        else
            text = "Batch comparison withheld: " .. tostring(result.reason) .. ". The numbers above were kept."
        end
        y = L:Paragraph(content, y, text)
        PB.resultLine = nil
        if content.GetRegions then
            for _, region in ipairs({ content:GetRegions() }) do
                if region.GetText and region:GetText() == text then
                    PB.resultLine = region
                end
            end
        end
    else
        PB.resultLine = nil
    end
    return y
end

function B:OnEvent(event)
    if event ~= "SKILL_LINES_CHANGED" then return end
    if not (TA.UI and TA.UI.activeTab == "professions" and TA.UI.contentChild) then return end
    self:Render(TA.UI.contentChild, TA.UI.sideChild)
end
