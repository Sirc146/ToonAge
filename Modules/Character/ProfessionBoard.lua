-- ToonAge/Modules/Character/ProfessionBoard.lua
-- The professions tab: one card per profession. The bar on the card is the
-- only thing that changes between versions, and ProfessionSkills decides
-- which bar from the calls that exist.

local TA = ToonAge

local B = {}
TA:RegisterModule("ProfessionBoard", B)

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
    if not result.reader then
        y = L:Paragraph(content, y, "This client has no profession skill API this tab can read.")
        L:Finish(content, y)
        return
    end
    if #cards == 0 then
        y = L:Paragraph(content, y, "No professions learned.")
        L:Finish(content, y)
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
    L:Finish(content, y)
end

function B:OnEvent(event)
    if event ~= "SKILL_LINES_CHANGED" then return end
    if not (TA.UI and TA.UI.activeTab == "professions" and TA.UI.contentChild) then return end
    self:Render(TA.UI.contentChild, TA.UI.sideChild)
end
