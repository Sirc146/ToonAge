-- ToonAge/Modules/Character/ProfessionBoard.lua
-- The professions tab: one card per profession. The bar on the card is the
-- only thing that changes between versions, and ProfessionSkills decides
-- which bar from the calls that exist.

local TA = ToonAge

local B = {}
TA:RegisterModule("ProfessionBoard", B)

local DrawLearned
local RankOf

local GATHERING_SET = {
    Skinning = true,
    Herbalism = true,
    Mining = true,
}

local SECONDARY_BOOK_SET = {
    Cooking = true,
    ["First Aid"] = true,
    Fishing = true,
}

-- Classic / Forever / TBC profession tier thresholds:
-- triggers right when the next tier first opens so you never cap out.
function B.TrainerReminder(card, rank, max, playerLevel)
    if type(card) ~= "table" then return nil end
    rank = tonumber(rank) or 0
    max  = tonumber(max) or 0
    if max <= 0 or rank <= 0 then return nil end
    -- Retail segmented professions (Dragonflight/TWW/Midnight) don't use 75/150/225 caps.
    if type(card.segments) == "table" and #card.segments > 1 then return nil end

    local name = tostring(card.name or "")
    local isGather = GATHERING_SET[name] == true
    local isBookSec = SECONDARY_BOOK_SET[name] == true or card.secondary == true
    local lv = tonumber(playerLevel)
    local nextTier, nextCap, openAt, reqLv, how

    if max == 75 then
        nextTier, nextCap, openAt = "Journeyman", 150, 50
        reqLv = (isGather or isBookSec) and 1 or 10
        how = "Visit your " .. name .. " trainer"
    elseif max == 150 then
        nextTier, nextCap, openAt = "Expert", 225, 125
        reqLv = isGather and 10 or 20
        how = isBookSec
            and ("Buy the Expert " .. name .. " book from a vendor")
            or ("Visit an Expert " .. name .. " trainer")
    elseif max == 225 then
        nextTier, nextCap, openAt = "Artisan", 300, 200
        reqLv = isGather and 25 or 35
        how = isBookSec
            and ("Complete the Artisan " .. name .. " quest (Lv 35)")
            or ("Visit an Artisan " .. name .. " trainer")
    elseif max == 300 and (TA.IsTBC or TA.flavor == "tbc") then
        nextTier, nextCap, openAt = "Master", 375, 275
        reqLv = isGather and 50 or 50
        how = "Visit an Outland Master " .. name .. " trainer"
    else
        return nil
    end

    if rank < openAt then return nil end

    local capped = (rank >= max)
    local levelBlocked = (lv ~= nil and reqLv and lv < reqLv)
    if capped then
        if levelBlocked then
            return {
                capped = true,
                readyNow = false,
                status = "warn",
                badge = "Capped (" .. tostring(rank) .. "/" .. tostring(max) .. ")",
                note = nextTier .. " (" .. tostring(nextCap) .. " cap) requires Lv " .. tostring(reqLv) .. ".",
            }
        end
        return {
            capped = true,
            readyNow = true,
            status = "bad",
            badge = "CAPPED -- Train " .. nextTier .. "!",
            note = how .. " to unlock " .. tostring(nextCap) .. " cap so skillups aren't wasted.",
        }
    end

    if levelBlocked then
        return {
            capped = false,
            readyNow = false,
            status = "neutral",
            badge = nextTier .. " at Lv " .. tostring(reqLv),
            note = "Skill " .. tostring(rank) .. "/" .. tostring(max) .. " reached " .. tostring(openAt)
                .. "; " .. nextTier .. " (" .. tostring(nextCap) .. " cap) unlocks at Lv " .. tostring(reqLv) .. ".",
        }
    end

    return {
        capped = false,
        readyNow = true,
        status = "warn",
        badge = "Train " .. nextTier .. " (" .. tostring(nextCap) .. " cap)",
        note = how .. " now (opens at " .. tostring(openAt) .. ") so you don't cap out at " .. tostring(max) .. ".",
    }
end

--- Collect all active profession tier reminders (used by Now tab for cross-tab briefing).
function B.GetTrainerReminders(playerLevel)
    local PS = TA.ProfessionSkills
    local result = (PS and PS.Collect and PS.Collect()) or { cards = {} }
    local lv = playerLevel
    if lv == nil and type(UnitLevel) == "function" then
        local ok, raw = pcall(UnitLevel, "player")
        if ok and type(raw) == "number" then lv = raw end
    end
    local out = {}
    for _, card in ipairs(result.cards or {}) do
        local rank, max = RankOf(card)
        local rem = B.TrainerReminder(card, rank, max, lv)
        if rem and rem.readyNow then
            rem.name = card.name
            rem.rank = rank
            rem.max = max
            out[#out + 1] = rem
        end
    end
    return out
end

RankOf = function(card)
    local rank, max = card.rank, card.max
    if type(card.segments) == "table" then
        for _, seg in ipairs(card.segments) do
            if seg.current then
                if (seg.rank and seg.rank > 0) or not (rank and rank > 0) then
                    return seg.rank, seg.max
                end
                return rank, (max and max > 0) and max or seg.max
            end
        end
    end
    return rank, max
end

local PROF_BAR_COLORS = {
    Skinning       = { 0.80, 0.34, 0.34 },
    Tailoring      = { 0.38, 0.56, 0.92 },
    Herbalism      = { 0.28, 0.78, 0.44 },
    Mining         = { 0.78, 0.54, 0.26 },
    Alchemy        = { 0.56, 0.44, 0.88 },
    Blacksmithing  = { 0.72, 0.56, 0.40 },
    Enchanting     = { 0.68, 0.42, 0.88 },
    Engineering    = { 0.85, 0.62, 0.24 },
    Leatherworking = { 0.74, 0.48, 0.30 },
    Jewelcrafting  = { 0.36, 0.78, 0.86 },
    Inscription    = { 0.60, 0.54, 0.86 },
    Comprehension  = { 0.34, 0.56, 0.76 },
    Cooking        = { 0.86, 0.68, 0.26 },
    ["First Aid"]  = { 0.76, 0.82, 0.86 },
    Fishing        = { 0.28, 0.66, 0.88 },
}

--- Tier badge shown next to each profession bar (matches Reputation standing column).
function B.TierLabel(card, rank, max)
    local nm = card and card.name or ""
    if nm == "Comprehension" or (card and card.skillID == 3012) then
        return "Scaled"
    end
    local r = tonumber(rank) or 0
    local m = tonumber(max) or 0
    if m > 0 and r >= m then
        return (m < 300) and "CAPPED" or "Max"
    end
    if m <= 75 then return "Apprentice" end
    if m <= 150 then return "Journeyman" end
    if m <= 225 then return "Expert" end
    if m <= 300 then return "Artisan" end
    if m <= 375 then return "Master" end
    return "Skilled"
end

--- Compact gather breakdown omitting zero counts so it never truncates.
function B.FormatGatherBreakdown(sum)
    if type(sum) ~= "table" then return "" end
    local parts = {}
    if (sum.herbs or 0) > 0 then
        parts[#parts + 1] = string.format("%d %s", sum.herbs, sum.herbs == 1 and "herb" or "herbs")
    end
    if (sum.ore or 0) > 0 then
        parts[#parts + 1] = string.format("%d ore", sum.ore)
    end
    if (sum.skin or 0) > 0 then
        parts[#parts + 1] = string.format("%d skinned", sum.skin)
    end
    if #parts == 0 then
        return string.format("%d nodes", sum.total or 0)
    end
    return table.concat(parts, " · ")
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
    local FC = TA.GetModule and TA:GetModule("ForeverCharacter")
    if FC and FC.RenderSidebarPublic then
        pcall(FC.RenderSidebarPublic, FC, side)
    elseif L.CharacterSidebar then
        L:CharacterSidebar(side)
    end
    -- Retail gear lives in its own file. Older clients never load it, and a
    -- client without profession slot calls draws no row.
    local gear = TA.ProfessionGear
    if gear and gear.Begin then gear:Begin() end

    local PS = TA.ProfessionSkills
    local result = (PS and PS.Collect and PS.Collect()) or { cards = {} }
    local cards = result.cards or {}

    local y = -8
    local summaryRight = (#cards > 0) and string.format("%d learned", #cards) or nil
    y = L:SectionHeader(content, y, "Professions", summaryRight)

    if result.unverified and #cards == 0 then
        y = L:Paragraph(content, y,
            "Skill lines and caps for this client are unverified until an in-game probe confirms them.")
    end

    local function DrawGathering(at)
        local GT = TA.GetModule and TA:GetModule("GatherTracker")
        if not (GT and type(GT.GetSummary) == "function") then return at end
        local okG, sum = pcall(GT.GetSummary, GT)
        if not (okG and type(sum) == "table") then return at end
        at = L:Divider(content, at)
        at = L:SectionHeader(content, at, "Gathering log",
            sum.total > 0 and string.format("%d nodes across %d %s", sum.total, sum.zones, sum.zones == 1 and "zone" or "zones")
                or "Records herb, ore, and skinning spots automatically on loot")
        if sum.total == 0 then
            at = L:Paragraph(content, at, "No gather nodes logged yet on this character.", { color = L.C_DIM })
        else
            at = L:DataRow(content, at, {
                label = "Logged nodes",
                value = B.FormatGatherBreakdown(sum),
                note = (sum.hereNodes and sum.hereNodes > 0)
                    and string.format("%d %s recorded in your current zone.", sum.hereNodes, sum.hereNodes == 1 and "node" or "nodes")
                    or nil,
            })
        end
        return at
    end
    local function finish(at)
        at = DrawGathering(at)
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

    local playerLvl = nil
    if type(UnitLevel) == "function" then
        local okL, rawLv = pcall(UnitLevel, "player")
        if okL and type(rawLv) == "number" then playerLvl = rawLv end
    end

    -- Group into Primary Professions and Secondary Skills (matching Reputation layout).
    local primaryCards, secondaryCards = {}, {}
    for _, card in ipairs(cards) do
        if card.secondary then
            secondaryCards[#secondaryCards + 1] = card
        else
            primaryCards[#primaryCards + 1] = card
        end
    end

    local useStatBar = type(L.StatBar) == "function"
    local function DrawGroup(groupTitle, groupCards, addSpacer)
        if #groupCards == 0 then return end
        if addSpacer and L.Spacer then y = L:Spacer(y, 6) end
        if useStatBar then
            y = L:SectionHeader(content, y, groupTitle)
        end
        for _, card in ipairs(groupCards) do
            local rank, max = RankOf(card)
            local rNum = tonumber(rank) or 0
            local mNum = tonumber(max) or 0
            local rem = B.TrainerReminder(card, rNum, mNum, playerLvl)
            if useStatBar then
                local pct = (mNum > 0) and math.floor(math.min(math.max(rNum / mNum, 0), 1) * 100 + 0.5) or 0
                local tier = B.TierLabel(card, rNum, mNum)
                local col = (rem and rem.capped) and { 0.90, 0.34, 0.30 }
                    or ((mNum > 0 and rNum >= mNum) and { 0.27, 0.78, 0.42 }
                    or PROF_BAR_COLORS[card.name] or { 0.35, 0.65, 0.90 })
                local tipLines = {
                    string.format("%s: %d / %d (%d%%)", tostring(card.name or "Profession"), rNum, mNum, pct),
                    "Tier: " .. tier,
                }
                if rem and rem.note then
                    tipLines[#tipLines + 1] = rem.note
                end
                if type(card.segments) == "table" and #card.segments > 1 then
                    for _, seg in ipairs(card.segments) do
                        if seg.label then
                            tipLines[#tipLines + 1] = string.format("%s: %d / %d",
                                tostring(seg.label), tonumber(seg.rank) or 0, tonumber(seg.max) or 0)
                        end
                    end
                end
                y = L:StatBar(content, y, {
                    label = card.name or "Profession",
                    labelWidth = 126,
                    value = rNum,
                    scale = (mNum > 0) and mNum or 1,
                    barHeight = 16,
                    rowGap = 4,
                    color = col,
                    badge = tier,
                    barText = string.format("%d%%", pct),
                    displayText = string.format("%d / %d", rNum, mNum),
                    valueWidth = 88,
                    status = (rem and rem.capped) and "bad" or "neutral",
                    tooltip = tipLines,
                })
            else
                local text = string.format("%d / %d", rNum, mNum)
                if card.secondary then text = text .. "  Secondary" end
                y = L:ProfessionCard(content, y, {
                    name     = card.name,
                    icon     = card.icon,
                    rankText = text,
                    rank     = rNum,
                    max      = mNum,
                    segments = card.segments,
                })
            end
            if rem then
                y = L:DataRow(content, y, {
                    label  = card.name .. " — Next tier open",
                    value  = rem.badge,
                    note   = rem.note,
                    status = rem.status,
                })
            end
            if gear and gear.Draw then
                y = gear:Draw(content, y, card)
            end
        end
    end

    DrawGroup("Primary Professions", primaryCards, false)
    DrawGroup("Secondary Skills", secondaryCards, #primaryCards > 0)
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
    local function sections()
        local out = {
            {
                title = "Batch & Fees",
                fields = {
                    { key = "n",         short = "Batch size (crafts)",          full = "Batch size: number of crafts" },
                    { key = "cut",       short = "Auction cut (e.g. 0.05)",      full = "Auction cut as a fraction of the sale price, for example 0.05" },
                    { key = "vendor",    short = "Vendor buy (gold, whole batch)", full = "Vendor buy for the whole batch, in gold. Enter 0 when there is no vendor material." },
                    { key = "seconds",   short = "Active crafting seconds",      full = "Active crafting seconds for the batch. Leave blank to withhold the hour rate." },
                    { key = "lostCraft", short = "Lost deposit: crafted (gold)", full = "Known lost deposit on the crafted listings, in gold. Leave blank if unknown." },
                    { key = "lostRaw",   short = "Lost deposit: raw avoided (g)", full = "Known lost deposit on the raw listings this craft avoids, in gold. Leave blank if unknown." },
                    { key = "refund",    short = "Refundable deposit tied up (g)", full = "Refundable deposit tied up, in gold. It is not subtracted. Leave blank if none." },
                },
            },
        }
        for i = 1, PB.form.reagents do
            local p = "Reagent " .. i .. " "
            out[#out + 1] = {
                title = "Reagent " .. i,
                fields = {
                    { key = "reag" .. i .. "need",     short = "Need per craft",      full = p .. "need per craft, in items. The batch size multiplies this." },
                    { key = "reag" .. i .. "owned",    short = "Owned (items)",       full = p .. "owned, in items. This is not multiplied again." },
                    { key = "reag" .. i .. "price",    short = "Listing price (g ea)", full = p .. "listing price, in gold each. Not a completed sale." },
                    { key = "reag" .. i .. "buyQty",   short = "Quantity bought",     full = p .. "quantity bought, in items. The full quantity is the cash paid." },
                    { key = "reag" .. i .. "buyPrice", short = "Price paid (g ea)",   full = p .. "price paid, in gold each." },
                },
            }
        end
        for i = 1, PB.form.outputs do
            local p = "Output " .. i .. " "
            out[#out + 1] = {
                title = "Output " .. i,
                fields = {
                    { key = "out" .. i .. "count", short = "Count per craft",     full = p .. "count per craft, in items. The batch size multiplies this." },
                    { key = "out" .. i .. "price", short = "Listing price (g ea)", full = p .. "listing price, in gold each. Not realized profit." },
                },
            }
        end
        return out
    end

    y = L:SectionHeader(content, y, "Learned recipes", "Manual batch estimator")
    y = L:Paragraph(content, y, PB.lastNote or
        "Learned recipes are not enabled from the open profession window. Ownership of that window is not a verified field. The calculator below uses only the numbers you type.",
        { color = L.C_DIM })
    local shown = PB.CurrentView and PB.CurrentView(PB.LiveIdentity and PB.LiveIdentity() or nil) or {}
    if #shown == 0 then
        y = L:Paragraph(content, y, "No saved learned recipes are shown for this character.", { color = L.C_DIM })
    end
    for _, rec in ipairs(shown) do
        y = L:Paragraph(content, y, tostring(rec.professionID) .. " " .. tostring(rec.profession) .. ": " .. rec.name
            .. " (previously saved, not a complete current read)")
    end
    y = L:ButtonRow(content, y, {
        { label = "Calculate batch", gold = true, onClick = function()
            PB.lastResult = PB.CompareBatch(PB.InputFromForm())
            rerender()
        end },
        { label = "Add reagent", onClick = changeRows(function() PB.form.reagents = PB.form.reagents + 1 end) },
        { label = "Remove reagent", onClick = changeRows(function()
            if PB.form.reagents > 1 then PB.form.reagents = PB.form.reagents - 1 end
        end) },
        { label = "Add output", onClick = changeRows(function() PB.form.outputs = PB.form.outputs + 1 end) },
        { label = "Remove output", onClick = changeRows(function()
            if PB.form.outputs > 1 then PB.form.outputs = PB.form.outputs - 1 end
        end) },
        { label = "Refresh learned recipes", onClick = function() PB:Refresh(cards); rerender() end },
    })
    y = L:Paragraph(content, y,
        "Gold means the number you type. Result is a conditional listing estimate, not realized profit. Hover any input for details.",
        { color = L.C_DIM })

    local usable = (L.Width and L:Width(content)) or 600
    if type(usable) ~= "number" or usable <= 0 then usable = 600 end
    local twoCol = usable >= 460
    local pad = L.PAD or 14
    local colGap = 16
    local colW = twoCol and math.floor((usable - colGap) / 2) or usable

    local function PlaceBox(field, x, at, maxW)
        local box = PB.boxes[field.key]
        if not (box and box.SetText) then
            box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
            box.fieldKey = field.key
            PB.boxes[field.key] = box
        end
        -- Kept in PB.boxes and re-parented after RebuildChild. The self-test
        -- (TestHarness.lua CountDescendants) still counts them as orphaned
        -- unless they carry _laKind. Layout does not pool them: an edit box
        -- must not be handed out later as a button.
        box._laKind = "ProfessionField"
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
            box:SetScript("OnEnter", function(self)
                if GameTooltip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(field.short or field.key, 1, 0.82, 0)
                    GameTooltip:AddLine(field.full or "", 0.85, 0.87, 0.90, true)
                    GameTooltip:Show()
                end
            end)
            box:SetScript("OnLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
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
        local boxW, boxH = 148, 22
        if type(maxW) == "number" and maxW > 0 and maxW < boxW then boxW = maxW end
        if box.SetSize then box:SetSize(boxW, boxH) end
        if box.SetPoint then box:SetPoint("TOPLEFT", content, "TOPLEFT", x, at) end
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
        return box, at - boxH - 8
    end

    local order = {}
    local activeKeys = {}
    for _, sec in ipairs(sections()) do
        y = L:SectionHeader(content, y, sec.title)
        local fields = sec.fields
        if twoCol then
            local i = 1
            while i <= #fields do
                local leftF = fields[i]
                local rightF = fields[i + 1]
                local xL = pad
                local xR = pad + colW + colGap
                local yL = L:Paragraph(content, y, leftF.short, { x = xL, width = colW, color = L.C_SECONDARY, gap = 3 })
                local yR = yL
                if rightF then
                    yR = L:Paragraph(content, y, rightF.short, { x = xR, width = colW, color = L.C_SECONDARY, gap = 3 })
                end
                local boxTop = math.min(yL, yR)
                local bL, nextL = PlaceBox(leftF, xL, boxTop, colW)
                order[#order + 1] = bL
                activeKeys[leftF.key] = true
                local nextR = nextL
                if rightF then
                    local bR
                    bR, nextR = PlaceBox(rightF, xR, boxTop, colW)
                    order[#order + 1] = bR
                    activeKeys[rightF.key] = true
                end
                y = math.min(nextL, nextR)
                i = i + 2
            end
        else
            for _, field in ipairs(fields) do
                y = L:Paragraph(content, y, field.full, { color = L.C_SECONDARY, gap = 3 })
                local box
                box, y = PlaceBox(field, pad, y, usable)
                order[#order + 1] = box
                activeKeys[field.key] = true
            end
        end
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
        if not activeKeys[key] then
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
