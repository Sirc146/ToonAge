-- ToonAge/Modules/Character/PetCare.lua (Anniversary — TBC Classic / Interface 20506)
--
-- Happiness/loyalty readout and a one-click Feed Pet button, in the spirit of
-- the classic Hunter addon Feed-O-Matic. This client still runs the pre-
-- Cataclysm pet model (GetPetHappiness/GetPetLoyalty, Feed Pet spell + a
-- food item), which is why this tab exists at all — retail's Pets.lua has no
-- equivalent because that mechanic was removed from later expansions.
--
-- NOTE: GetPetHappiness/GetPetLoyalty are confirmed present on this client
-- family (TBC Classic Anniversary / Classic Era / MoP Classic all still ship
-- the API), but every call is still pcall-guarded below — if a future patch
-- pulls the API, this tab degrades to "unavailable" instead of erroring.

local TA = ToonAge
local U = TA.Utils

local PetCare = {}
TA:RegisterModule("PetCare", PetCare)

PetCare.frames = {}

-- ─── Bag Scanning ───────────────────────────────────────────────────────

local _GetContainerItemInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo

local function SlotCount(bag, slot)
    if not _GetContainerItemInfo then
        return 0
    end
    if C_Container then
        local info = _GetContainerItemInfo(bag, slot)
        return (info and info.stackCount) or 0
    end
    local ok, _, itemCount = pcall(_GetContainerItemInfo, bag, slot)
    return (ok and itemCount) or 0
end

--- Scan all bags for the best food match for the given diet set, preferring
--- (in order): conjured > Well Fed quality > basic, and within a tier the
--- smallest stack first — same priority Feed-O-Matic uses, so a big stack of
--- a common food isn't chewed through before a nearly-empty one is used up.
--- @param dietSet table  set of diet strings the active pet accepts
--- @return table|nil  { bag, slot, name, icon, tier, count }
local function FindBestFood(dietSet)
    local F = TA.Data.PetFoods
    local best

    for bag = 0, 4 do
        local numSlots = U.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = U.GetContainerItemLink(bag, slot)
            if link then
                local name, _, _, _, _, _, _, _, _, icon = U.GetItemInfo(link)
                local entry = name and F:Get(name)
                if entry and dietSet[entry.diet] then
                    local count = SlotCount(bag, slot)
                    if
                        not best
                        or entry.tier < best.tier
                        or (entry.tier == best.tier and count < best.count)
                    then
                        best = { bag = bag, slot = slot, name = name, icon = icon, tier = entry.tier, count = count }
                    end
                end
            end
        end
    end

    return best
end

-- ─── Init & Events ──────────────────────────────────────────────────────

function PetCare:Init() end

function PetCare:OnEvent(event, ...)
    if event == "UNIT_PET" and (select(1, ...)) ~= "player" then
        return
    end
    -- Actual re-render on a relevant event is driven by Core/UI.lua's
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

local function HappinessColor(happiness)
    if happiness == 1 then
        return 0.90, 0.30, 0.30, "Unhappy"
    elseif happiness == 2 then
        return 0.95, 0.80, 0.20, "Content"
    elseif happiness == 3 then
        return 0.35, 0.90, 0.40, "Happy"
    end
    return 0.5, 0.5, 0.5, "Unknown"
end

-- ── Class Quests: Mandatory Pet-Acquisition Chains ────────────────────
-- Every checked-for ability is granted by completing a mandatory,
-- kill-a-demon/tame-a-beast class quest chain, not by leveling alone.
-- Checking IsSpellKnown(spellID) instead of a quest-ID sidesteps needing a
-- per-race/per-faction quest ID table (several of these quests have a
-- different ID for nearly every starting race) and works identically
-- whether the quest happens to be flagged complete or the spell was
-- granted some other way (race change, trainer refund, etc.).
--
-- NOTE: Warlock's Imp (spell 688) is deliberately excluded — it's the
-- starting demon, known from level 1 with no quest in this era, so
-- checking it would only ever produce false-reassurance, never a useful
-- warning.
--
-- WARN: this whole list applies to TBC (this install) but NOT to the
-- Classic/Cata build — Blizzard's patch 4.0.3a auto-granted all three
-- Warlock pet spells and removed their quest chains outright, while
-- Hunter's Taming the Beast survived. If this file is ever used as a
-- template for another install, that split must be preserved, not copied
-- wholesale.
local CLASS_PET_QUESTS = {
    HUNTER = {
        { spellID = 1515, minLevel = 10, label = "Taming the Beast", pet = "Tame Beast" },
    },
    WARLOCK = {
        { spellID = 697, minLevel = 10, label = "Summon Voidwalker quest", pet = "Voidwalker" },
        { spellID = 712, minLevel = 20, label = "Summon Succubus quest", pet = "Succubus" },
        { spellID = 691, minLevel = 30, label = "Summon Felhunter quest", pet = "Felhunter" },
    },
}

local function RenderClassQuestReminder(content, frames, w, padL, y)
    local class = TA.Utils.GetPlayerClass and TA.Utils.GetPlayerClass()
    local quests = class and CLASS_PET_QUESTS[class]
    if not quests then
        return y
    end

    local level = UnitLevel("player") or 0

    for _, q in ipairs(quests) do
        if level >= q.minLevel then
            local okKnown, known = pcall(IsSpellKnown, q.spellID)
            if okKnown and not known then
                local card = Card(content, w, 40, frames)
                card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                card:SetBackdropColor(0.10, 0.08, 0.00, 1)
                card:SetBackdropBorderColor(0.70, 0.50, 0.10, 0.7)

                local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
                lbl:SetText(("|cFFFFCC00%s|r not completed — see your class trainer to learn %s."):format(
                    q.label,
                    q.pet
                ))
                lbl:SetTextColor(0.90, 0.80, 0.50, 1)
                lbl:SetWidth(w - 20)
                lbl:SetJustifyH("CENTER")
                lbl:SetPoint("CENTER", card, "CENTER", 0, 0)

                y = y - 46
            end
        end
    end

    return y
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

    y = RenderClassQuestReminder(content, self.frames, w, padL, y)

    if not UnitExists("pet") then
        local card = Card(content, w, 60, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText("No pet summoned.\nCall your pet to see its happiness and feed it.")
        lbl:SetTextColor(0.50, 0.50, 0.50, 1)
        lbl:SetWidth(w - 20)
        lbl:SetJustifyH("CENTER")
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
        return
    end

    local petName = UnitName("pet") or "Unknown"
    local family = UnitCreatureFamily("pet") or "Unknown"

    local ok, happiness, dmgPct, loyaltyRate = pcall(GetPetHappiness)
    if not ok then
        happiness = nil
    end
    local okL, loyaltyText = pcall(GetPetLoyalty)
    if not okL then
        loyaltyText = nil
    end

    -- ── Name card ─────────────────────────────────────────────────
    local nameCard = Card(content, w, 40, self.frames)
    nameCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

    local nLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nLbl:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    nLbl:SetText(petName)
    nLbl:SetTextColor(1, 1, 1, 1)
    nLbl:SetPoint("TOPLEFT", nameCard, "TOPLEFT", 10, -7)

    local fLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fLbl:SetFont(STANDARD_TEXT_FONT, 9)
    fLbl:SetText(family)
    fLbl:SetTextColor(0.78, 0.73, 0.48, 1)
    fLbl:SetPoint("TOPLEFT", nameCard, "TOPLEFT", 10, -23)

    y = y - 46

    -- ── Happiness card ────────────────────────────────────────────
    local hCard = Card(content, w, 54, self.frames)
    hCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

    if happiness then
        local hr, hg, hb, hLabel = HappinessColor(happiness)
        hCard:SetBackdropBorderColor(hr * 0.6, hg * 0.6, hb * 0.6, 0.9)

        local hHdr = hCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hHdr:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        hHdr:SetText(hLabel)
        hHdr:SetTextColor(hr, hg, hb, 1)
        hHdr:SetPoint("TOPLEFT", hCard, "TOPLEFT", 10, -7)

        local dmgLbl = hCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dmgLbl:SetFont(STANDARD_TEXT_FONT, 9)
        dmgLbl:SetText((dmgPct or 100) .. "% pet damage")
        dmgLbl:SetTextColor(0.65, 0.62, 0.55, 1)
        dmgLbl:SetPoint("TOPLEFT", hCard, "TOPLEFT", 10, -25)

        if loyaltyText then
            local lLbl = hCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lLbl:SetFont(STANDARD_TEXT_FONT, 9)
            lLbl:SetText(loyaltyText)
            lLbl:SetTextColor(0.65, 0.62, 0.55, 1)
            lLbl:SetPoint("TOPLEFT", hCard, "TOPLEFT", 10, -38)
        end
    else
        local uLbl = hCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        uLbl:SetFont(STANDARD_TEXT_FONT, 10)
        uLbl:SetText("Happiness data unavailable on this client.")
        uLbl:SetTextColor(0.45, 0.45, 0.45, 1)
        uLbl:SetPoint("CENTER", hCard, "CENTER", 0, 0)
    end

    y = y - 60

    -- ── Feed button (Hunter only — Feed Pet targets a Hunter pet) ───
    local class = U.GetPlayerClass and U.GetPlayerClass()
    if class == "HUNTER" then
        local okDiet, d1, d2, d3, d4, d5 = pcall(GetPetFoodTypes)
        local dietSet, dietList = {}, {}
        if okDiet then
            for _, diet in ipairs({ d1, d2, d3, d4, d5 }) do
                if diet and diet ~= "" then
                    dietSet[diet] = true
                    table.insert(dietList, diet)
                end
            end
        end

        local food = next(dietSet) and FindBestFood(dietSet) or nil

        local fCard = Card(content, w, 64, self.frames)
        fCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

        local dLbl = fCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dLbl:SetFont(STANDARD_TEXT_FONT, 9)
        dLbl:SetText("Eats: " .. (#dietList > 0 and table.concat(dietList, ", ") or "unknown"))
        dLbl:SetTextColor(0.60, 0.56, 0.44, 1)
        dLbl:SetPoint("TOPLEFT", fCard, "TOPLEFT", 10, -7)

        local inCombat = InCombatLockdown()
        local btn = CreateFrame("Button", nil, fCard, "SecureActionButtonTemplate,BackdropTemplate")
        btn:SetSize(w - 20, 28)
        btn:SetPoint("BOTTOMLEFT", fCard, "BOTTOMLEFT", 10, 8)
        btn:SetBackdrop(BD)
        btn:RegisterForClicks("AnyUp", "AnyDown")

        if food and not inCombat then
            btn:SetAttribute("type1", "spell")
            btn:SetAttribute("spell1", "Feed Pet")
            btn:SetAttribute("target-bag", food.bag)
            btn:SetAttribute("target-slot", food.slot)
            btn:SetBackdropColor(0.06, 0.18, 0.06, 1)
            btn:SetBackdropBorderColor(0.20, 0.55, 0.20, 0.85)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
            icon:SetTexture(food.icon)

            local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            label:SetText(("Feed  %s  (x%d)"):format(food.name, food.count))
            label:SetTextColor(0.55, 1.00, 0.55, 1)
            label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        else
            btn:SetBackdropColor(0.08, 0.08, 0.08, 1)
            btn:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)

            local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetFont(STANDARD_TEXT_FONT, 10)
            label:SetText(inCombat and "Unavailable in combat" or "No compatible food in bags")
            label:SetTextColor(0.45, 0.45, 0.45, 1)
            label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end
    else
        local nCard = Card(content, w, 34, self.frames)
        nCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local nLbl2 = nCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nLbl2:SetFont(STANDARD_TEXT_FONT, 9)
        nLbl2:SetText("Feeding via this addon is available for Hunter pets.")
        nLbl2:SetTextColor(0.45, 0.45, 0.45, 1)
        nLbl2:SetPoint("CENTER", nCard, "CENTER", 0, 0)
    end
end
