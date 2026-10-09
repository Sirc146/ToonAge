-- ToonAge/Modules/Infrastructure/RotationBoard.lua
-- Rotation tab for versions that do not already have one.
-- Mists and Classic Era. The list comes from that version's own data file.
-- An empty band, including Mists Death Knight below 55, is the
-- "No verified rotation yet" card.

local TA = ToonAge
local B = {}
TA:RegisterModule("RotationBoard", B)

function B:Render(content, side)
    local L = TA.Layout
    local U = TA.Utils
    local RL = TA.RotationLists
    if L and L.CharacterSidebar then L:CharacterSidebar(side) end
    local y = -8
    if not L or not RL then
        if content and content.CreateFontString then
            local f = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            f:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -10)
            f:SetText(RL and RL.EMPTY or "No verified rotation yet")
        end
        if content and content.SetHeight then content:SetHeight(80) end
        return
    end
    local class = U and U.GetPlayerClass and U.GetPlayerClass() or nil
    local spec
    if U and U.GetPlayerSpec then
        local _, name = U.GetPlayerSpec()
        spec = name
    end
    local level = U and U.GetPlayerLevel and U.GetPlayerLevel() or nil
    local st = RL.Resolve(nil, class, spec, level, "st")
    local aoe = RL.Resolve(nil, class, spec, level, "aoe")
    if (not st or st.empty) and (not aoe or aoe.empty) then
        y = RL.DrawList(content, y, L, { empty = true }, "ROTATION")
    else
        if st and not st.empty then
            y = RL.DrawList(content, y, L, st, "SINGLE TARGET")
        end
        if aoe and not aoe.empty then
            y = RL.DrawList(content, y, L, aoe, "AOE")
        end
    end
    if L.Finish then L:Finish(content, y) end
end
