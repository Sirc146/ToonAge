-- ToonAge/Modules/Character/PetCare.lua (Classic)
--
-- A Pet Care tab was originally built here as a Feed-O-Matic-style feeding
-- tab, then pulled 2026-08-22 once in-game testing confirmed this client has
-- no hunter pet happiness system and no Feed Pet spell — Cataclysm's 4.0.1
-- patch removed pet feeding permanently, and this client is past that point.
--
-- This is a narrower rebuild: mandatory class pet-acquisition quest
-- reminders only, for characters (including alts of other classes) who
-- haven't finished theirs yet.
--
-- Two class-pet quest families exist in this game's history:
--   Hunter — "Taming the Beast" (level 10, learns Tame Beast, spell 1515).
--            Confirmed still a real quest chain in Cataclysm content.
--   Warlock — Summon Voidwalker/Succubus/Felhunter quest chains.
--            NOT tracked here: Blizzard's patch 4.0.3a — the same wave
--            that removed hunter pet feeding — auto-granted all three
--            Warlock pet spells and deleted their quest chains outright.
--            Checking for them on this client would never find anything
--            to warn about, so the check is omitted rather than shipped
--            as dead code. If this client turns out not to be past 4.0.3a
--            after all, that's the same discrepancy already flagged for
--            the feeding removal — add the Warlock table back at that
--            point (see Modules/Character/PetCare.lua in the Anniversary
--            install for the exact spell IDs/levels: 697/10, 712/20,
--            691/30).

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
            lbl:SetText("|cFFFFCC00Taming the Beast|r not completed — see your class trainer to learn Tame Beast.")
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
            lbl:SetText("Taming the Beast already completed — nothing outstanding.")
        else
            lbl:SetText(
                "No outstanding class pet quest for "
                    .. (class or "this class")
                    .. ".\nPet feeding/happiness no longer exists on this client (removed pre-Cataclysm)."
            )
        end
        lbl:SetTextColor(0.50, 0.50, 0.50, 1)
        lbl:SetWidth(w - 20)
        lbl:SetJustifyH("CENTER")
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
    end
end
