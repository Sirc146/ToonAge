-- ToonAge/Modules/Mists/PetCare.lua (Mists of Pandaria Classic)
--
-- A Pet Care tab was originally built here as a Feed-O-Matic-style feeding
-- tab, then pulled 2026-08-22: pet happiness and Feed Pet were removed in
-- patch 4.0.1 and don't exist on this client.
--
-- What remains is a Tame Beast sanity check for hunters.
--   The "Taming the Beast" quest chain was removed in patch 4.0.1 (Tame Beast
--   became a level-10 trainer spell), and patch 5.0.4 made all class spells
--   learned automatically on level-up (Warcraft Wiki: Tame Beast, Class
--   trainer). So a level-10+ hunter without spell 1515 is an anomaly (e.g.
--   the spellbook hasn't refreshed), not an unfinished quest.
--   Warlock pet quests were likewise removed in 4.0.3a and are not tracked.

local TA = ToonAge
local U = TA.Utils

local PetCare = {}
TA:RegisterModule("PetCare", PetCare)

PetCare.frames = {}

local TAME_BEAST_SPELL_ID = 1515
local TAME_BEAST_MIN_LEVEL = 10

-- ─── Init & Events ──────────────────────────────────────────────────────

function PetCare:Init() end

function PetCare:OnEvent(event, ...)
    -- Re-render on a relevant event is driven by Core/UI.lua's
    -- TAB_EVENTS-gated Refresh(); nothing to do here beyond the module
    -- contract's expectation that OnEvent exists.
end

-- ─── Render ─────────────────────────────────────────────────────────────

local BD = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function Card(parent, w, h, frames)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetBackdrop(BD)
    f:SetBackdropColor(0.05, 0.05, 0.05, 1)
    f:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
    table.insert(frames, f)
    return f
end

function PetCare:Render(content, sidebar)
    for _, f in ipairs(self.frames) do
        f:Hide()
        f:SetParent(nil)
    end
    self.frames = {}

    local w = content:GetWidth() - 20
    local padL = 10
    local y = -10

    local class = U.GetPlayerClass and U.GetPlayerClass()
    local level = UnitLevel("player") or 0
    local shown = false

    if class == "HUNTER" and level >= TAME_BEAST_MIN_LEVEL then
        local okKnown, known = pcall(IsSpellKnown, TAME_BEAST_SPELL_ID)
        if okKnown and not known then
            local card = Card(content, w, 40, self.frames)
            card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
            card:SetBackdropColor(0.10, 0.08, 0.00, 1)
            card:SetBackdropBorderColor(0.70, 0.50, 0.10, 0.7)

            local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            lbl:SetText("|cFFFFCC00Tame Beast|r is not in your spellbook. It is learned automatically at level 10 — try /reload; if still missing, visit a Hunter trainer.")
            lbl:SetTextColor(0.90, 0.80, 0.50, 1)
            lbl:SetWidth(w - 20)
            lbl:SetJustifyH("CENTER")
            lbl:SetPoint("CENTER", card, "CENTER", 0, 0)

            y = y - 46
            shown = true
        end
    end

    if not shown then
        local card = Card(content, w, 60, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        if class == "HUNTER" then
            lbl:SetText("Tame Beast is known — nothing outstanding. Pets need no feeding on this client.")
        else
            lbl:SetText(
                "No class pet setup needed for "
                    .. (class or "this class")
                    .. ".\nPet feeding/happiness no longer exists on this client (removed in patch 4.0.1)."
            )
        end
        lbl:SetTextColor(0.50, 0.50, 0.50, 1)
        lbl:SetWidth(w - 20)
        lbl:SetJustifyH("CENTER")
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
    end
end
