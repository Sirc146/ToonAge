-- ToonAge/Modules/Pets.lua

local TA = ToonAge
local U  = TA.Utils

local Pets = {}
TA:RegisterModule("Pets", Pets)

Pets.frames      = {}
Pets.sideFrames  = {}
Pets.view        = "active"
Pets.filterRole  = "ALL"
Pets.lastContent = nil
Pets.lastSidebar = nil

-- ── Init ──────────────────────────────────────────────────────────────
function Pets:Init()
    if TA.charDB then
        TA.charDB.knownPets = TA.charDB.knownPets or {}
    end
end

-- ── Events ────────────────────────────────────────────────────────────
function Pets:OnEvent(event, ...)
    if event == "UNIT_PET" and (select(1, ...)) ~= "player" then return end
    self.lastContent = nil
    if TA.UI and TA.UI.activeTab == "pets" and TA.UI.contentChild then
        self:Render(TA.UI.contentChild, TA.UI.sideChild)
    end
end

-- ── Stable helpers ────────────────────────────────────────────────────
function Pets:TrackPet(name, family)
    if not TA.charDB then return end
    TA.charDB.knownPets = TA.charDB.knownPets or {}
    for _, p in ipairs(TA.charDB.knownPets) do
        if p.name == name then return end
    end
    table.insert(TA.charDB.knownPets, { name = name, family = family })
end

function Pets:ForgetPet(name)
    if not TA.charDB then return end
    local t = TA.charDB.knownPets
    for i = #t, 1, -1 do
        if t[i].name == name then table.remove(t, i) end
    end
end

-- ── Color helpers ─────────────────────────────────────────────────────
local function RoleColor(role)
    if role == "FEROCITY" then return 1.00, 0.42, 0.29 end
    if role == "TENACITY" then return 0.29, 0.65, 1.00 end
    if role == "CUNNING"  then return 1.00, 0.82, 0.29 end
    return 0.78, 0.73, 0.48
end

local function RoleLabel(role)
    if role == "FEROCITY" then return "Ferocity  (DPS)"     end
    if role == "TENACITY" then return "Tenacity  (Tank)"    end
    if role == "CUNNING"  then return "Cunning  (Utility)"  end
    return role or "Unknown"
end

local function RarityColor(rarity)
    if rarity == "Rare"       then return 0.10, 0.44, 0.87 end
    if rarity == "Rare Elite" then return 0.60, 0.10, 0.80 end
    return 0.45, 0.45, 0.45
end

local function CompRoleColor(role)
    if role == "DPS"     then return 1.00, 0.42, 0.29 end
    if role == "TANK"    then return 0.29, 0.65, 1.00 end
    if role == "HEALING" then return 0.29, 1.00, 0.50 end
    if role == "CONTROL" then return 1.00, 0.82, 0.29 end
    if role == "UTILITY" then return 0.80, 0.50, 1.00 end
    if role == "SUPPORT" then return 0.50, 0.90, 1.00 end
    return 0.70, 0.70, 0.70
end

-- ── Frame factory ─────────────────────────────────────────────────────
local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function Card(parent, w, h, frames)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetBackdrop(BD)
    f:SetBackdropColor(0.05, 0.05, 0.05, 1)
    f:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
    if frames then table.insert(frames, f) end
    return f
end

local function Lbl(parent, text, size, r, g, b, x, y, maxW)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(STANDARD_TEXT_FONT, size or 10)
    fs:SetText(text or "")
    fs:SetTextColor(r or 1, g or 1, b or 1, 1)
    if x and y then fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y) end
    if maxW then
        fs:SetWidth(maxW)
        fs:SetJustifyH("LEFT")
    end
    return fs
end

-- ── Sidebar ───────────────────────────────────────────────────────────
function Pets:RenderSidebar(sideChild)
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    local P       = TA.Data.Pets
    local sidebar = TA.UI.sidebar
    local sW      = sidebar:GetWidth()
    local hasPet  = UnitExists("pet")

    if hasPet then
        -- 3D model
        local model = CreateFrame("PlayerModel", nil, sidebar)
        model:SetSize(sW - 20, 200)
        model:SetPoint("TOP", sidebar, "TOP", 0, -10)
        model:SetUnit("pet")
        model:RefreshUnit()
        table.insert(self.sideFrames, model)

        local grad = model:CreateTexture(nil, "OVERLAY")
        grad:SetAllPoints(model)
        grad:SetTexture("Interface\\Buttons\\WHITE8X8")
        grad:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.7))

        local petName    = UnitName("pet") or "Unknown"
        local family     = UnitCreatureFamily("pet") or "Unknown"
        local familyInfo = P:GetFamilyInfo(family)

        local nameLbl = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLbl:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
        nameLbl:SetText(petName)
        nameLbl:SetTextColor(1, 1, 1, 1)
        nameLbl:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 8, 26)

        local famLbl = model:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        famLbl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        famLbl:SetText(family)
        famLbl:SetTextColor(0.78, 0.73, 0.48, 1)
        famLbl:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 8, 10)

        sideChild:HookScript("OnHide", function() model:Hide() end)

        local anchor = model

        if familyInfo then
            local rr, rg, rb = RoleColor(familyInfo.role)

            -- Role badge
            local badge = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
            badge:SetSize(sW - 20, 22)
            badge:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
            badge:SetBackdrop(BD)
            badge:SetBackdropColor(rr * 0.12, rg * 0.12, rb * 0.12, 1)
            badge:SetBackdropBorderColor(rr, rg, rb, 0.7)
            table.insert(self.sideFrames, badge)
            anchor = badge

            local rl = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rl:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            rl:SetText(RoleLabel(familyInfo.role))
            rl:SetTextColor(rr, rg, rb, 1)
            rl:SetPoint("CENTER", badge, "CENTER", 0, 0)

            -- Ability tags
            local tags = {}
            if familyInfo.lust   then table.insert(tags, "|cFFFF8800Bloodlust|r") end
            if familyInfo.mw     then table.insert(tags, "|cFFFF4040Mortal Wounds|r") end
            if familyInfo.shield then table.insert(tags, "|cFF29A5FFShell Shield|r") end
            if familyInfo.exotic then table.insert(tags, "|cFFFF44FFExotic (BM)|r") end

            if #tags > 0 then
                local tagBox = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
                tagBox:SetSize(sW - 20, 20)
                tagBox:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
                tagBox:SetBackdrop(BD)
                tagBox:SetBackdropColor(0.04, 0.04, 0.04, 1)
                tagBox:SetBackdropBorderColor(0.16, 0.16, 0.16, 1)
                table.insert(self.sideFrames, tagBox)
                anchor = tagBox

                local tl = tagBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tl:SetFont(STANDARD_TEXT_FONT, 9)
                tl:SetText(table.concat(tags, "  "))
                tl:SetPoint("CENTER", tagBox, "CENTER", 0, 0)
            end

            -- Best for
            if familyInfo.bestFor then
                local bestBox = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
                bestBox:SetSize(sW - 20, 60)
                bestBox:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
                bestBox:SetBackdrop(BD)
                bestBox:SetBackdropColor(0.04, 0.04, 0.04, 1)
                bestBox:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
                table.insert(self.sideFrames, bestBox)

                local hdr = bestBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                hdr:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
                hdr:SetText("BEST FOR")
                hdr:SetTextColor(0.44, 0.44, 0.44, 1)
                hdr:SetPoint("TOPLEFT", bestBox, "TOPLEFT", 6, -5)

                local bTxt = bestBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                bTxt:SetFont(STANDARD_TEXT_FONT, 9)
                bTxt:SetText(familyInfo.bestFor)
                bTxt:SetTextColor(0.88, 0.83, 0.65, 1)
                bTxt:SetWidth(sW - 32)
                bTxt:SetJustifyH("LEFT")
                bTxt:SetPoint("TOPLEFT", bestBox, "TOPLEFT", 6, -17)
            end
        end
    else
        local class = U.GetPlayerClass()
        local msg   = class == "HUNTER"
            and "No pet summoned.\nCall a pet to view its stats."
            or  "No active companion."

        local ph = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
        ph:SetSize(sW - 20, 80)
        ph:SetPoint("TOP", sidebar, "TOP", 0, -10)
        ph:SetBackdrop(BD)
        ph:SetBackdropColor(0.06, 0.06, 0.06, 1)
        ph:SetBackdropBorderColor(0.16, 0.16, 0.16, 1)
        table.insert(self.sideFrames, ph)

        local icon = ph:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        icon:SetFont(STANDARD_TEXT_FONT, 26, "OUTLINE")
        icon:SetText("?")
        icon:SetTextColor(0.26, 0.26, 0.26, 1)
        icon:SetPoint("TOP", ph, "TOP", 0, -10)

        local hint = ph:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetFont(STANDARD_TEXT_FONT, 9)
        hint:SetText(msg)
        hint:SetTextColor(0.45, 0.45, 0.45, 1)
        hint:SetJustifyH("CENTER")
        hint:SetWidth(sW - 30)
        hint:SetPoint("BOTTOM", ph, "BOTTOM", 0, 8)
    end
end

-- ── Main render ───────────────────────────────────────────────────────
function Pets:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    -- Preserve sidebar ref so inner button callbacks can re-render
    if sidebar then self.lastSidebar = sidebar end
    local sideRef = sidebar or self.lastSidebar

    if self.lastContent ~= content then
        if sideRef then self:RenderSidebar(sideRef) end
        self.lastContent = content
    end

    local P      = TA.Data.Pets
    local class  = U.GetPlayerClass()
    local specID = U.GetPlayerSpec()
    local isBM   = (specID == 253)
    local w      = content:GetWidth() - 20
    local padL   = 10

    local isHunter    = (class == "HUNTER")
    local hasPetClass = (P.ClassPetDB[class] ~= nil)

    local tabs
    if isHunter then
        tabs = {
            { id = "active",  label = "Active Pet"  },
            { id = "zone",    label = "Zone Pets"   },
            { id = "stable",  label = "My Stable"   },
            { id = "finder",  label = "Pet Finder"  },
        }
    elseif hasPetClass then
        tabs = {
            { id = "active",     label = "Active"           },
            { id = "companions", label = "Companion Guide"  },
        }
    else
        tabs = {
            { id = "active", label = "Companion" },
        }
    end

    -- Validate current view exists in tab list
    local valid = false
    for _, t in ipairs(tabs) do if t.id == self.view then valid = true; break end end
    if not valid then self.view = tabs[1].id end

    -- Tab row
    local tabRow = CreateFrame("Frame", nil, content)
    tabRow:SetSize(w, 26)
    tabRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, -10)
    table.insert(self.frames, tabRow)

    local btnW = math.floor((w - (#tabs - 1) * 4) / #tabs)
    local tx   = 0
    for _, tab in ipairs(tabs) do
        local active = (tab.id == self.view)
        local btn = CreateFrame("Button", nil, tabRow, "BackdropTemplate")
        btn:SetSize(btnW, 24)
        btn:SetPoint("LEFT", tabRow, "LEFT", tx, 0)
        btn:SetBackdrop(BD)
        if active then
            btn:SetBackdropColor(0.10, 0.38, 0.68, 0.30)
            btn:SetBackdropBorderColor(0.30, 0.65, 1.00, 0.80)
        else
            btn:SetBackdropColor(0.08, 0.08, 0.08, 1)
            btn:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        end
        table.insert(self.frames, btn)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10, active and "OUTLINE" or "")
        lbl:SetText(tab.label)
        lbl:SetTextColor(active and 0.55 or 0.44, active and 0.88 or 0.44, active and 1.00 or 0.44, 1)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)

        local tid = tab.id
        btn:SetScript("OnClick", function()
            self.view = tid
            self:Render(content, nil)
        end)

        tx = tx + btnW + 4
    end

    local yBase = -44

    if     self.view == "active"     then self:RenderActiveView(content, P, class, isHunter, isBM, w, padL, yBase)
    elseif self.view == "zone"       then self:RenderZoneView(content, P, isBM, w, padL, yBase)
    elseif self.view == "stable"     then self:RenderStableView(content, P, w, padL, yBase)
    elseif self.view == "finder"     then self:RenderFinderView(content, P, isBM, w, padL, yBase)
    elseif self.view == "companions" then self:RenderCompanionView(content, P, class, w, padL, yBase)
    end
end

-- ── View: Active Pet ──────────────────────────────────────────────────
function Pets:RenderActiveView(content, P, class, isHunter, isBM, w, padL, y)
    local hasPet = UnitExists("pet")

    if not hasPet then
        local card = Card(content, w, 54, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        card:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        local msg = isHunter
            and "No pet summoned. Visit Zone Pets or Pet Finder to find a companion."
            or  "No active companion. Check the Companion Guide tab for available summons."
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText(msg)
        lbl:SetTextColor(0.50, 0.50, 0.50, 1)
        lbl:SetWidth(w - 20)
        lbl:SetJustifyH("CENTER")
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
        return
    end

    local petName    = UnitName("pet") or "Unknown"
    local family     = UnitCreatureFamily("pet") or "Unknown"
    local familyInfo = P:GetFamilyInfo(family)
    local rr, rg, rb = familyInfo and RoleColor(familyInfo.role) or 0.35, 0.35, 0.35

    -- Name card
    local nameH = familyInfo and 72 or 44
    local nameCard = Card(content, w, nameH, self.frames)
    nameCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    nameCard:SetBackdropBorderColor(rr * 0.55, rg * 0.55, rb * 0.55, 0.8)

    local nLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nLbl:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    nLbl:SetText(petName)
    nLbl:SetTextColor(1, 1, 1, 1)
    nLbl:SetPoint("TOPLEFT", nameCard, "TOPLEFT", 10, -7)

    local fLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fLbl:SetFont(STANDARD_TEXT_FONT, 10)
    fLbl:SetText("Family: " .. family)
    fLbl:SetTextColor(0.78, 0.73, 0.48, 1)
    fLbl:SetPoint("TOPLEFT", nameCard, "TOPLEFT", 10, -25)

    if familyInfo then
        local roleLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        roleLbl:SetFont(STANDARD_TEXT_FONT, 10)
        roleLbl:SetText(RoleLabel(familyInfo.role))
        roleLbl:SetTextColor(rr, rg, rb, 1)
        roleLbl:SetPoint("TOPLEFT", nameCard, "TOPLEFT", 10, -40)

        local tags = {}
        if familyInfo.lust   then table.insert(tags, "|cFFFF8800Bloodlust|r") end
        if familyInfo.mw     then table.insert(tags, "|cFFFF4040Mortal Wounds|r") end
        if familyInfo.shield then table.insert(tags, "|cFF29A5FFShell Shield|r") end
        if familyInfo.exotic then table.insert(tags, "|cFFFF44FFExotic|r") end
        if #tags > 0 then
            local tLbl = nameCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tLbl:SetFont(STANDARD_TEXT_FONT, 9)
            tLbl:SetText(table.concat(tags, "  "))
            tLbl:SetPoint("TOPRIGHT", nameCard, "TOPRIGHT", -10, -40)
        end
    end
    y = y - nameH - 6

    -- Best for
    if familyInfo and familyInfo.bestFor then
        local bCard = Card(content, w, 50, self.frames)
        bCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        bCard:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)

        local hdr = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        hdr:SetText("BEST FOR")
        hdr:SetTextColor(0.42, 0.42, 0.42, 1)
        hdr:SetPoint("TOPLEFT", bCard, "TOPLEFT", 10, -6)

        local bTxt = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bTxt:SetFont(STANDARD_TEXT_FONT, 10)
        bTxt:SetText(familyInfo.bestFor)
        bTxt:SetTextColor(0.88, 0.83, 0.65, 1)
        bTxt:SetWidth(w - 20)
        bTxt:SetJustifyH("LEFT")
        bTxt:SetPoint("TOPLEFT", bCard, "TOPLEFT", 10, -20)
        y = y - 56
    end

    -- Prerequisites
    if familyInfo and familyInfo.prereq and familyInfo.prereq ~= "BM" then
        local pCard = Card(content, w, 36, self.frames)
        pCard:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        pCard:SetBackdropColor(0.06, 0.04, 0.00, 1)
        pCard:SetBackdropBorderColor(0.70, 0.50, 0.10, 0.5)

        local pTxt = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pTxt:SetFont(STANDARD_TEXT_FONT, 9)
        pTxt:SetText("|cFFFFCC00***|r " .. (P:GetPrereqText(familyInfo.prereq) or "Special requirement"))
        pTxt:SetTextColor(0.90, 0.80, 0.50, 1)
        pTxt:SetWidth(w - 20)
        pTxt:SetJustifyH("LEFT")
        pTxt:SetPoint("CENTER", pCard, "CENTER", 4, 0)
    end
end

-- ── View: Zone Pets ───────────────────────────────────────────────────
function Pets:RenderZoneView(content, P, isBM, w, padL, y)
    local zoneID   = U.GetCurrentMapID and U.GetCurrentMapID() or 0
    local mapInfo  = C_Map.GetMapInfo(zoneID)
    local zoneName = mapInfo and mapInfo.name or ("Zone " .. zoneID)

    -- Header
    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    hdr:SetText(zoneName .. "  ·  Tameable Pets")
    hdr:SetTextColor(0.88, 0.83, 0.65, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, hdr)

    local zidLbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zidLbl:SetFont(STANDARD_TEXT_FONT, 8)
    zidLbl:SetText("Zone ID " .. zoneID .. "  ·  /script print(C_Map.GetBestMapForUnit(\"player\")) to verify")
    zidLbl:SetTextColor(0.30, 0.30, 0.30, 1)
    zidLbl:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y - 14)
    table.insert(self.frames, zidLbl)

    y = y - 32

    local zonePets = P:GetZonePets(zoneID)

    if #zonePets == 0 then
        local card = Card(content, w, 54, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText("No tameable pet data for this zone yet.\nID: " .. zoneID)
        lbl:SetTextColor(0.45, 0.45, 0.45, 1)
        lbl:SetJustifyH("CENTER")
        lbl:SetWidth(w - 20)
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
        return
    end

    local shown = 0
    for _, pet in ipairs(zonePets) do
        local familyInfo = P:GetFamilyInfo(pet.family)
        if familyInfo then
            -- Spec filter: exotic families require BM
            if not familyInfo.exotic or isBM then
                local hasPrereqs = pet.prereqs and #pet.prereqs > 0
                local hasNote    = pet.note and pet.note ~= ""
                local cardH      = 56
                if hasPrereqs then cardH = cardH + (#pet.prereqs * 17) end
                if hasNote    then cardH = cardH + 14 end

                local rr, rg, rb = RoleColor(familyInfo.role)
                local card = Card(content, w, cardH, self.frames)
                card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
                card:SetBackdropBorderColor(rr * 0.40, rg * 0.40, rb * 0.40, 0.8)

                -- Rarity badge (top-right)
                local br, bg, bb = RarityColor(pet.rarity)
                local rarLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                rarLbl:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
                rarLbl:SetText(pet.rarity)
                rarLbl:SetTextColor(br, bg, bb, 1)
                rarLbl:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -8)

                -- Name
                local nameLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameLbl:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
                nameLbl:SetText(pet.name)
                nameLbl:SetTextColor(1, 1, 1, 1)
                nameLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)

                -- Family · Role
                local subLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                subLbl:SetFont(STANDARD_TEXT_FONT, 9)
                subLbl:SetText(pet.family .. "  ·  " .. RoleLabel(familyInfo.role))
                subLbl:SetTextColor(rr, rg, rb, 0.85)
                subLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -22)

                -- Best for (first sentence only)
                if familyInfo.bestFor then
                    local bText = familyInfo.bestFor
                    local stop  = bText:find("%.")
                    local bLbl  = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    bLbl:SetFont(STANDARD_TEXT_FONT, 9)
                    bLbl:SetText(stop and bText:sub(1, stop) or bText)
                    bLbl:SetTextColor(0.62, 0.58, 0.44, 1)
                    bLbl:SetWidth(w - 80)
                    bLbl:SetJustifyH("LEFT")
                    bLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -36)
                end

                -- "+ Stable" button
                local sBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
                sBtn:SetSize(52, 18)
                sBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 6)
                sBtn:SetBackdrop(BD)
                sBtn:SetBackdropColor(0.06, 0.18, 0.06, 1)
                sBtn:SetBackdropBorderColor(0.20, 0.55, 0.20, 0.8)
                local sbL = sBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                sbL:SetFont(STANDARD_TEXT_FONT, 9)
                sbL:SetText("+ Stable")
                sbL:SetTextColor(0.38, 0.90, 0.38, 1)
                sbL:SetPoint("CENTER", sBtn, "CENTER", 0, 0)

                local pN = pet.name
                local pF = pet.family
                sBtn:SetScript("OnClick", function()
                    self:TrackPet(pN, pF)
                    print("|cFFFFD100[TA]|r Added |cFF00FF00" .. pN .. "|r to stable list.")
                end)

                -- Prerequisites with ***
                local cy = -50
                if hasPrereqs then
                    for _, pKey in ipairs(pet.prereqs) do
                        local pStr = P:GetPrereqText(pKey)
                        local pLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        pLbl:SetFont(STANDARD_TEXT_FONT, 9)
                        pLbl:SetText("|cFFFFCC00***|r " .. pStr)
                        pLbl:SetTextColor(0.88, 0.78, 0.40, 1)
                        pLbl:SetWidth(w - 70)
                        pLbl:SetJustifyH("LEFT")
                        pLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, cy)
                        cy = cy - 17
                    end
                end

                -- Note
                if hasNote then
                    local nLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nLbl:SetFont(STANDARD_TEXT_FONT, 9)
                    nLbl:SetText("|cFF777777" .. pet.note .. "|r")
                    nLbl:SetWidth(w - 20)
                    nLbl:SetJustifyH("LEFT")
                    nLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, cy)
                end

                y = y - cardH - 6
                shown = shown + 1
            end
        end
    end

    if shown == 0 then
        local card = Card(content, w, 44, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText("No tameable pets available for your spec in this zone.")
        lbl:SetTextColor(0.44, 0.44, 0.44, 1)
        lbl:SetJustifyH("CENTER")
        lbl:SetWidth(w - 20)
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
    end
end

-- ── View: My Stable ───────────────────────────────────────────────────
function Pets:RenderStableView(content, P, w, padL, y)
    local known = (TA.charDB and TA.charDB.knownPets) or {}

    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    hdr:SetText("Tracked Pets  (" .. #known .. ")")
    hdr:SetTextColor(0.88, 0.83, 0.65, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, hdr)

    local sub = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sub:SetFont(STANDARD_TEXT_FONT, 9)
    sub:SetText("Add pets via Zone Pets → + Stable. Saved per character.")
    sub:SetTextColor(0.38, 0.38, 0.38, 1)
    sub:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y - 14)
    table.insert(self.frames, sub)

    y = y - 34

    if #known == 0 then
        local card = Card(content, w, 50, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText("No pets tracked yet. Use Zone Pets \226\134\146 + Stable.")
        lbl:SetTextColor(0.44, 0.44, 0.44, 1)
        lbl:SetJustifyH("CENTER")
        lbl:SetWidth(w - 20)
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
        return
    end

    local contentRef = content
    for _, pet in ipairs(known) do
        local fi = P:GetFamilyInfo(pet.family)
        local rr, rg, rb = fi and RoleColor(fi.role) or 0.38, 0.38, 0.38

        local row = Card(content, w, 38, self.frames)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        row:SetBackdropBorderColor(rr * 0.40, rg * 0.40, rb * 0.40, 0.8)

        local nLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        nLbl:SetText(pet.name)
        nLbl:SetTextColor(1, 1, 1, 1)
        nLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)

        local iLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        iLbl:SetFont(STANDARD_TEXT_FONT, 9)
        iLbl:SetText(pet.family .. (fi and ("  ·  " .. RoleLabel(fi.role)) or ""))
        iLbl:SetTextColor(rr, rg, rb, 0.85)
        iLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -21)

        -- Remove button
        local rmBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        rmBtn:SetSize(50, 18)
        rmBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        rmBtn:SetBackdrop(BD)
        rmBtn:SetBackdropColor(0.18, 0.04, 0.04, 1)
        rmBtn:SetBackdropBorderColor(0.55, 0.14, 0.14, 0.8)
        local rmL = rmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rmL:SetFont(STANDARD_TEXT_FONT, 9)
        rmL:SetText("Remove")
        rmL:SetTextColor(0.90, 0.38, 0.38, 1)
        rmL:SetPoint("CENTER", rmBtn, "CENTER", 0, 0)

        local pName = pet.name
        rmBtn:SetScript("OnClick", function()
            self:ForgetPet(pName)
            self:Render(contentRef, nil)
        end)

        y = y - 44
    end
end

-- ── View: Pet Finder ──────────────────────────────────────────────────
function Pets:RenderFinderView(content, P, isBM, w, padL, y)
    -- Role filter strip
    local filters = {
        { id = "ALL",      label = "All Families" },
        { id = "FEROCITY", label = "Ferocity" },
        { id = "TENACITY", label = "Tenacity" },
        { id = "CUNNING",  label = "Cunning"  },
    }

    local fRow = CreateFrame("Frame", nil, content)
    fRow:SetSize(w, 24)
    fRow:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, fRow)

    local fBtnW = math.floor((w - 12) / 4)
    local fx = 0
    for _, f in ipairs(filters) do
        local isActive = (self.filterRole == f.id)
        local fr, fg, fb = RoleColor(f.id)
        if f.id == "ALL" then fr, fg, fb = 0.70, 0.70, 0.70 end

        local btn = CreateFrame("Button", nil, fRow, "BackdropTemplate")
        btn:SetSize(fBtnW, 22)
        btn:SetPoint("LEFT", fRow, "LEFT", fx, 0)
        btn:SetBackdrop(BD)
        if isActive then
            btn:SetBackdropColor(fr * 0.16, fg * 0.16, fb * 0.16, 1)
            btn:SetBackdropBorderColor(fr, fg, fb, 0.80)
        else
            btn:SetBackdropColor(0.07, 0.07, 0.07, 1)
            btn:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        end
        table.insert(self.frames, btn)

        local fl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fl:SetFont(STANDARD_TEXT_FONT, 9, isActive and "OUTLINE" or "")
        fl:SetText(f.label)
        fl:SetTextColor(isActive and fr or 0.44, isActive and fg or 0.44, isActive and fb or 0.44, 1)
        fl:SetPoint("CENTER", btn, "CENTER", 0, 0)

        local fid = f.id
        local contentRef = content
        btn:SetScript("OnClick", function()
            self.filterRole = fid
            self:Render(contentRef, nil)
        end)

        fx = fx + fBtnW + 4
    end

    y = y - 30

    -- Sorted family list
    local sorted = {}
    for name, info in pairs(P.FamilyDB) do
        if self.filterRole == "ALL" or info.role == self.filterRole then
            table.insert(sorted, { name = name, info = info })
        end
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sorted) do
        local name    = entry.name
        local info    = entry.info
        local locked  = info.exotic and not isBM
        local hasPrereq = info.prereq and info.prereq ~= "BM"
        local cardH   = 50
        if hasPrereq then cardH = cardH + 16 end

        local rr, rg, rb = RoleColor(info.role)

        local card = Card(content, w, cardH, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        if locked then
            card:SetBackdropColor(0.04, 0.04, 0.04, 1)
            card:SetBackdropBorderColor(0.18, 0.18, 0.18, 0.4)
        else
            card:SetBackdropColor(0.05, 0.05, 0.05, 1)
            card:SetBackdropBorderColor(rr * 0.35, rg * 0.35, rb * 0.35, 0.8)
        end

        -- Name (+ Exotic tag)
        local nLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        nLbl:SetText(name .. (info.exotic and "  |cFFFF44FFExotic|r" or ""))
        nLbl:SetTextColor(locked and 0.40 or 1, locked and 0.40 or 1, locked and 0.40 or 1, 1)
        nLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)

        -- Role (top-right)
        local rLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rLbl:SetFont(STANDARD_TEXT_FONT, 9)
        rLbl:SetText(RoleLabel(info.role))
        rLbl:SetTextColor(locked and 0.28 or rr, locked and 0.28 or rg, locked and 0.28 or rb, 1)
        rLbl:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -7)

        -- Ability tags + first sentence of bestFor
        local tags = {}
        if info.lust   then table.insert(tags, "|cFFFF8800Lust|r") end
        if info.mw     then table.insert(tags, "|cFFFF4040MW|r")   end
        if info.shield then table.insert(tags, "|cFF29A5FFShield|r") end
        local tagStr = #tags > 0 and (table.concat(tags, " ") .. "  ") or ""

        local bText  = info.bestFor or ""
        local stop   = bText:find("%.")
        local bShort = stop and bText:sub(1, stop) or bText

        local bLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bLbl:SetFont(STANDARD_TEXT_FONT, 9)
        bLbl:SetText(tagStr .. bShort)
        bLbl:SetTextColor(locked and 0.30 or 0.65, locked and 0.30 or 0.60, locked and 0.30 or 0.44, 1)
        bLbl:SetWidth(w - 20)
        bLbl:SetJustifyH("LEFT")
        bLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -22)

        if locked then
            local lockLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lockLbl:SetFont(STANDARD_TEXT_FONT, 8)
            lockLbl:SetText("Beast Mastery specialization required")
            lockLbl:SetTextColor(0.55, 0.35, 0.75, 0.85)
            lockLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -36)
        elseif hasPrereq then
            local pLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            pLbl:SetFont(STANDARD_TEXT_FONT, 9)
            pLbl:SetText("|cFFFFCC00***|r " .. (P:GetPrereqText(info.prereq) or ""))
            pLbl:SetTextColor(0.88, 0.78, 0.40, 1)
            pLbl:SetWidth(w - 20)
            pLbl:SetJustifyH("LEFT")
            pLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -36)
        end

        y = y - cardH - 4
    end
end

-- ── View: Companion Guide (non-Hunter pet classes) ────────────────────
function Pets:RenderCompanionView(content, P, class, w, padL, y)
    local companions = P:GetClassPets(class)
    local specIdx    = GetSpecialization()
    local specName   = specIdx and select(2, GetSpecializationInfo(specIdx)) or ""

    local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    hdr:SetText("Companion Guide  —  " .. (specName ~= "" and specName or class))
    hdr:SetTextColor(0.88, 0.83, 0.65, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
    table.insert(self.frames, hdr)

    y = y - 24

    if #companions == 0 then
        local card = Card(content, w, 44, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetFont(STANDARD_TEXT_FONT, 10)
        lbl:SetText("No companion data for this class.")
        lbl:SetTextColor(0.44, 0.44, 0.44, 1)
        lbl:SetJustifyH("CENTER")
        lbl:SetWidth(w - 20)
        lbl:SetPoint("CENTER", card, "CENTER", 0, 0)
        return
    end

    for _, comp in ipairs(companions) do
        local isSpecific = comp.spec and comp.spec ~= "All"
        local specMatch  = not isSpecific or (comp.spec == specName)
        local dimmed     = not specMatch

        local rr, rg, rb = CompRoleColor(comp.role)
        local cardH = 56

        local card = Card(content, w, cardH, self.frames)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        if dimmed then
            card:SetBackdropColor(0.04, 0.04, 0.04, 1)
            card:SetBackdropBorderColor(0.16, 0.16, 0.16, 0.4)
        else
            card:SetBackdropColor(0.05, 0.05, 0.05, 1)
            card:SetBackdropBorderColor(rr * 0.35, rg * 0.35, rb * 0.35, 0.8)
        end

        -- Name
        local nLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nLbl:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        nLbl:SetText(comp.name)
        nLbl:SetTextColor(dimmed and 0.38 or 1, dimmed and 0.38 or 1, dimmed and 0.38 or 1, 1)
        nLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)

        -- Summon type + duration (top-right)
        local typeStr = comp.summonType .. (comp.duration and (" (" .. comp.duration .. "s)") or "")
        local typeLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        typeLbl:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        typeLbl:SetText(typeStr)
        typeLbl:SetTextColor(
            comp.summonType == "Permanent" and 0.29 or 1.00,
            comp.summonType == "Permanent" and 1.00 or 0.82,
            comp.summonType == "Permanent" and 0.40 or 0.29, 1)
        typeLbl:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -7)

        -- Role + spec restriction
        local roleLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        roleLbl:SetFont(STANDARD_TEXT_FONT, 9)
        roleLbl:SetText(comp.role .. (isSpecific and ("  ·  " .. comp.spec) or ""))
        roleLbl:SetTextColor(dimmed and 0.28 or rr, dimmed and 0.28 or rg, dimmed and 0.28 or rb, 1)
        roleLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -21)

        -- Description
        local dLbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dLbl:SetFont(STANDARD_TEXT_FONT, 9)
        dLbl:SetText(comp.desc or "")
        dLbl:SetTextColor(dimmed and 0.30 or 0.68, dimmed and 0.30 or 0.62, dimmed and 0.30 or 0.44, 1)
        dLbl:SetWidth(w - 20)
        dLbl:SetJustifyH("LEFT")
        dLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -36)

        y = y - cardH - 5
    end
end
