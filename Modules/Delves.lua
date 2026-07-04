-- ToonAge/Modules/Delves.lua
-- Brann companion advisor + Delve tier progression tracker

local TA = ToonAge
local U  = TA.Utils
local Z  = TA.Data.Zones

local Delves = {}
TA:RegisterModule("Delves", Delves)

Delves.frames     = {}
Delves.sideFrames = {}  -- persistent sidebar frames cleaned up by UI.lua on tab switch

-- ── Delve tier table (Midnight Season 1, PTR 12.0.5) ─────────────────
-- iLvl ranges sourced from Z.TRACKS. Update breakpoints each season reset.
local TIERS = {
    { tier=1,  label="Tier 1",       iLvlMin=0,   track="Adventurer", bountiful=false },
    { tier=2,  label="Tier 2",       iLvlMin=220, track="Adventurer", bountiful=false },
    { tier=3,  label="Tier 3",       iLvlMin=224, track="Adventurer", bountiful=false },
    { tier=4,  label="Tier 4",       iLvlMin=228, track="Adventurer", bountiful=false },
    { tier=5,  label="Tier 5",       iLvlMin=233, track="Veteran",    bountiful=true  },
    { tier=6,  label="Tier 6",       iLvlMin=237, track="Veteran",    bountiful=true  },
    { tier=7,  label="Tier 7",       iLvlMin=242, track="Veteran",    bountiful=true  },
    { tier=8,  label="Tier 8",       iLvlMin=246, track="Champion",   bountiful=true  },
    { tier=9,  label="Tier 9",       iLvlMin=253, track="Champion",   bountiful=true  },
    { tier=10, label="Tier 10",      iLvlMin=259, track="Hero",       bountiful=true  },
    { tier=11, label="Tier 11 (Max)",iLvlMin=272, track="Myth",       bountiful=true  },
}

local function EstimateTier(iLvl)
    for i = #TIERS, 1, -1 do
        if iLvl >= TIERS[i].iLvlMin then return TIERS[i] end
    end
    return TIERS[1]
end

-- ── Group role scan ────────────────────────────────────────────────────
local function ScanGroupRoles()
    local hasHealer, hasTank = false, false
    if IsInGroup() then
        local n = GetNumGroupMembers()
        for i = 1, n do
            local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
            if UnitExists(unit) then
                local r = UnitGroupRolesAssigned(unit)
                if r == "HEALER" then hasHealer = true end
                if r == "TANK"   then hasTank   = true end
            end
        end
        local pr = UnitGroupRolesAssigned("player")
        if pr == "HEALER" then hasHealer = true end
        if pr == "TANK"   then hasTank   = true end
    end
    return hasHealer, hasTank
end

-- ── Brann suggestion engine ────────────────────────────────────────────
-- Returns: mode ("HEALER"|"DPS"|"TANK"), reason, switchTip
local function SuggestBrann(role, iLvl, tier, groupSize)
    local hasGroupHealer, hasGroupTank = ScanGroupRoles()

    -- Group logic: if party already has a healer, free Brann for DPS
    if groupSize > 1 then
        if hasGroupHealer then
            return "DPS",
                "Your party has a healer — Brann deals maximum damage.",
                "Switch to HEALER if your healer struggles on a difficult boss."
        elseif hasGroupTank then
            return "HEALER",
                "No dedicated healer in group — Brann keeps the party topped.",
                "Switch to DPS if all members are heavily over-geared."
        else
            return "HEALER",
                "No healer or tank assigned — Brann stabilizes the group.",
                "Once you out-gear the tier, consider switching Brann to DPS."
        end
    end

    -- Solo logic
    if role == "TANK" then
        return "DPS",
            "Tanks are nearly self-sufficient — Brann adds maximum DPS.",
            "Only switch to HEALER if a boss is consistently killing you."
    elseif role == "HEALER" then
        return "DPS",
            "Healers self-sustain — Brann deals damage to speed clears.",
            "Switch to HEALER if you run Mana-intensive builds in deep tiers."
    end

    -- Solo DPS: scale recommendation by tier difficulty
    if tier.tier <= 4 then
        return "HEALER",
            "Tiers 1-4 punish undergeared DPS — Brann healing prevents wipes.",
            "Switch to DPS at Tier 5+ once your iLvl exceeds 233."
    elseif tier.tier <= 8 then
        return "HEALER",
            "Tier " .. tier.tier .. ": Brann healing keeps sustained fights comfortable.",
            "Switch to DPS at Tier 9+ (iLvl 253+) when content becomes trivial."
    elseif tier.tier <= 10 then
        return "DPS",
            "Tier " .. tier.tier .. ": your iLvl outpaces the content — Brann maximizes speed.",
            "Switch back to HEALER if attempting the tier for the first time."
    else
        return "DPS",
            "Tier 11 (max): full DPS — Brann damage pushes the fastest clears.",
            "Only revert to HEALER if attempting Tier 11 severely undergeared."
    end
end

-- ── Color helpers ─────────────────────────────────────────────────────
local MODE_COLORS = {
    HEALER = { r=0.29, g=1.00, b=0.48, label="HEALER",  spec="Medic Protocol"    },
    DPS    = { r=1.00, g=0.70, b=0.20, label="DPS",     spec="Combat Medic"      },
    TANK   = { r=0.29, g=0.65, b=1.00, label="TANK",    spec="Shield Protocol"   },
}
local TRACK_COLORS = {
    Adventurer = { 0.70, 0.70, 0.70 },
    Veteran    = { 0.29, 0.82, 1.00 },
    Champion   = { 0.29, 1.00, 0.48 },
    Hero       = { 0.80, 0.45, 1.00 },
    Myth       = { 1.00, 0.55, 0.00 },
}

local BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- ── Events ────────────────────────────────────────────────────────────
function Delves:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA"
    or event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "GROUP_ROSTER_UPDATE" then
        if TA.UI and TA.UI.activeTab == "delves" then
            self:Render(TA.UI.contentChild, TA.UI.sideChild)
        end
    end
end

-- ── Main render ───────────────────────────────────────────────────────
function Delves:Render(content, sidebar)
    for _, f in ipairs(self.frames) do f:Hide(); f:SetParent(nil) end
    self.frames = {}

    local role      = U.GetPlayerRole()
    local iLvl      = U.GetAverageIlvl()
    local groupSize = U.GetGroupSize()
    local tier      = EstimateTier(iLvl)
    local mode, reason, switchTip = SuggestBrann(role, iLvl, tier, groupSize)
    local mc        = MODE_COLORS[mode] or MODE_COLORS.HEALER
    local tc        = TRACK_COLORS[tier.track] or { 0.60, 0.60, 0.60 }

    local y    = -10
    local padL = 10
    local w    = content:GetWidth() - 20

    local function Track(f) table.insert(self.frames, f); return f end

    local function Section(h, br, bg, bb, er, eg, eb)
        local f = Track(CreateFrame("Frame", nil, content, "BackdropTemplate"))
        f:SetSize(w, h)
        f:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)
        f:SetBackdrop(BD)
        f:SetBackdropColor(br or 0.04, bg or 0.04, bb or 0.04, 1)
        f:SetBackdropBorderColor(er or 0.20, eg or 0.20, eb or 0.20, 0.6)
        return f
    end

    -- ── Header ────────────────────────────────────────────────────────
    local hdr = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    hdr:SetText("DELVE ADVISOR")
    hdr:SetTextColor(1.00, 0.82, 0.00, 1)
    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", padL, y)

    local tierBadge = Track(content:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    tierBadge:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    tierBadge:SetText(tier.label .. "  ·  " .. tier.track)
    tierBadge:SetTextColor(tc[1], tc[2], tc[3], 1)
    tierBadge:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)

    y = y - 22

    local sep = Track(content:CreateTexture(nil, "ARTWORK"))
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  content, "TOPLEFT",  padL, y)
    sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padL, y)
    sep:SetColorTexture(0.55, 0.40, 0.08, 0.25)
    y = y - 10

    -- ── Brann recommendation card ─────────────────────────────────────
    local bCard = Section(96, mc.r * 0.06, mc.g * 0.06, mc.b * 0.06, mc.r * 0.50, mc.g * 0.50, mc.b * 0.50)

    -- Mode badge (large)
    local modeLbl = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLbl:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    modeLbl:SetText(mc.label)
    modeLbl:SetTextColor(mc.r, mc.g, mc.b, 1)
    modeLbl:SetPoint("TOPLEFT", bCard, "TOPLEFT", 12, -10)

    local specLbl = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    specLbl:SetText("BRANN SPEC  ·  " .. mc.spec)
    specLbl:SetTextColor(mc.r * 0.70, mc.g * 0.70, mc.b * 0.70, 1)
    specLbl:SetPoint("TOPLEFT", bCard, "TOPLEFT", 12, -32)

    -- Group mode indicator
    local grpTxt = groupSize > 1 and ("GROUP  (" .. groupSize .. ")") or "SOLO"
    local grpLbl = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    grpLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    grpLbl:SetText(grpTxt)
    grpLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    grpLbl:SetPoint("TOPRIGHT", bCard, "TOPRIGHT", -12, -10)

    -- Divider within card
    local cdiv = bCard:CreateTexture(nil, "ARTWORK")
    cdiv:SetHeight(1)
    cdiv:SetPoint("TOPLEFT",  bCard, "TOPLEFT",  12, -44)
    cdiv:SetPoint("TOPRIGHT", bCard, "TOPRIGHT", -12, -44)
    cdiv:SetColorTexture(mc.r, mc.g, mc.b, 0.12)

    -- Reason text
    local reasonLbl = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reasonLbl:SetFont(STANDARD_TEXT_FONT, 10)
    reasonLbl:SetText(reason)
    reasonLbl:SetTextColor(0.82, 0.78, 0.62, 1)
    reasonLbl:SetWidth(w - 24)
    reasonLbl:SetJustifyH("LEFT")
    reasonLbl:SetPoint("TOPLEFT", bCard, "TOPLEFT", 12, -52)

    -- Switch tip
    local tipLbl = bCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tipLbl:SetFont(STANDARD_TEXT_FONT, 9)
    tipLbl:SetText("|cFF666666Switch tip: " .. (switchTip or "") .. "|r")
    tipLbl:SetWidth(w - 24)
    tipLbl:SetJustifyH("LEFT")
    tipLbl:SetPoint("BOTTOMLEFT", bCard, "BOTTOMLEFT", 12, 8)

    y = y - 104

    -- ── Progression card ──────────────────────────────────────────────
    local trackInfo = Z.TRACKS[tier.track:lower()]
    local pCard = Section(76, 0.04, 0.04, 0.04, tc[1] * 0.40, tc[2] * 0.40, tc[3] * 0.40)

    local pHdr = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pHdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    pHdr:SetText("PROGRESSION  ·  " .. iLvl .. " iLvl equipped")
    pHdr:SetTextColor(tc[1], tc[2], tc[3], 0.85)
    pHdr:SetPoint("TOPLEFT", pCard, "TOPLEFT", 12, -8)

    -- Track progress bar
    if trackInfo then
        local trackRange = trackInfo.ilvlMax - trackInfo.ilvlMin
        local progress   = math.min(1, math.max(0, (iLvl - trackInfo.ilvlMin) / trackRange))
        local barW       = w - 90
        local filledW    = math.max(2, math.floor(barW * progress))

        local barBG = pCard:CreateTexture(nil, "ARTWORK")
        barBG:SetSize(barW, 6)
        barBG:SetPoint("LEFT", pCard, "LEFT", 12, 0)
        barBG:SetColorTexture(0.12, 0.12, 0.12, 1)

        local barFG = pCard:CreateTexture(nil, "ARTWORK")
        barFG:SetSize(filledW, 6)
        barFG:SetPoint("LEFT", pCard, "LEFT", 12, 0)
        barFG:SetColorTexture(tc[1], tc[2], tc[3], 1)

        local pctLbl = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctLbl:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        pctLbl:SetText(math.floor(progress * 100) .. "%  " .. tier.track)
        pctLbl:SetTextColor(tc[1], tc[2], tc[3], 1)
        pctLbl:SetPoint("LEFT", pCard, "LEFT", 12 + barW + 6, 0)
    end

    -- Current tier info
    local curLbl = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    curLbl:SetFont(STANDARD_TEXT_FONT, 10)
    curLbl:SetText("Current:  " .. tier.label .. (tier.bountiful and "  ★ Bountiful" or ""))
    curLbl:SetTextColor(tc[1], tc[2], tc[3], 1)
    curLbl:SetPoint("TOPLEFT", pCard, "TOPLEFT", 12, -22)

    -- Next tier / milestone
    local nextTier = tier.tier < #TIERS and TIERS[tier.tier + 1] or nil
    local nextLbl  = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nextLbl:SetFont(STANDARD_TEXT_FONT, 9)
    if nextTier then
        nextLbl:SetText("Next:  " .. nextTier.label .. " — reach " .. nextTier.iLvlMin .. " iLvl")
    else
        nextLbl:SetText("|cFF4AFF7AMax tier reached!|r  Push Tier 11 for Myth track upgrades.")
    end
    nextLbl:SetTextColor(0.55, 0.55, 0.55, 1)
    nextLbl:SetPoint("TOPLEFT", pCard, "TOPLEFT", 12, -38)

    -- Source note
    if trackInfo then
        local srcLbl = pCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        srcLbl:SetFont(STANDARD_TEXT_FONT, 9)
        srcLbl:SetText("Gear from:  " .. (trackInfo.source or ""))
        srcLbl:SetTextColor(0.44, 0.44, 0.44, 1)
        srcLbl:SetWidth(w - 24)
        srcLbl:SetJustifyH("LEFT")
        srcLbl:SetPoint("BOTTOMLEFT", pCard, "BOTTOMLEFT", 12, 8)
    end

    y = y - 84

    -- ── Bountiful Delve reminder (Tier 5+) ───────────────────────────
    if tier.tier >= 5 then
        local bount = Section(46, 0.04, 0.05, 0.02, 0.29, 0.70, 0.20)

        local bHdr = bount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bHdr:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        bHdr:SetText("\226\152\133  BOUNTIFUL DELVES ACTIVE")
        bHdr:SetTextColor(0.29, 1.00, 0.38, 1)
        bHdr:SetPoint("TOPLEFT", bount, "TOPLEFT", 12, -8)

        local bTip = bount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bTip:SetFont(STANDARD_TEXT_FONT, 9)
        bTip:SetText("Complete 4 Bountiful Delves this week for Great Vault credit.  Brann also earns bonus XP in Bountiful runs.")
        bTip:SetTextColor(0.60, 0.80, 0.44, 1)
        bTip:SetWidth(w - 24)
        bTip:SetJustifyH("LEFT")
        bTip:SetPoint("TOPLEFT", bount, "TOPLEFT", 12, -22)

        y = y - 54
    end

    -- ── Brann mode quick-switch tips ──────────────────────────────────
    local tCard = Section(84, 0.04, 0.04, 0.04, 0.24, 0.20, 0.06)

    local tHdr = tCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tHdr:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    tHdr:SetText("BRANN MODE REFERENCE")
    tHdr:SetTextColor(0.70, 0.60, 0.30, 1)
    tHdr:SetPoint("TOPLEFT", tCard, "TOPLEFT", 12, -8)

    local tips = {
        { mode="HEALER", color={0.29,1.00,0.48}, tip="Sustains you via healing potions and salves. Best for new tiers and solo DPS." },
        { mode="DPS",    color={1.00,0.70,0.20}, tip="Deals bonus damage alongside you. Best when content is trivial or you have a healer." },
        { mode="TANK",   color={0.29,0.65,1.00}, tip="Intercepts and holds enemies. Rarely optimal but useful for swarm mechanics." },
    }
    for i, tip in ipairs(tips) do
        local cy = -20 - (i - 1) * 20
        local mLabel = tCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mLabel:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        mLabel:SetText(tip.mode .. (tip.mode == mode and " \226\134\144" or ""))
        mLabel:SetTextColor(tip.color[1], tip.color[2], tip.color[3], tip.mode == mode and 1 or 0.50)
        mLabel:SetPoint("TOPLEFT", tCard, "TOPLEFT", 12, cy)

        local mTip = tCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mTip:SetFont(STANDARD_TEXT_FONT, 9)
        mTip:SetText(tip.tip)
        mTip:SetTextColor(0.50, 0.50, 0.50, 1)
        mTip:SetWidth(w - 90)
        mTip:SetJustifyH("LEFT")
        mTip:SetPoint("TOPLEFT", tCard, "TOPLEFT", 80, cy)
    end

    y = y - 92

    content:SetHeight(math.abs(y) + 20)

    -- ── Sidebar ───────────────────────────────────────────────────────
    self:RenderSidebar(sidebar, mode, mc, tier, tc, iLvl)
end

-- ── Sidebar ───────────────────────────────────────────────────────────
function Delves:RenderSidebar(sidebar, mode, mc, tier, tc, iLvl)
    for _, f in ipairs(self.sideFrames) do f:Hide(); f:SetParent(nil) end
    self.sideFrames = {}

    if not sidebar then return end
    local sW = sidebar:GetWidth()

    local function TrackSide(f) table.insert(self.sideFrames, f); return f end

    -- Brann mode badge (large)
    local badge = TrackSide(CreateFrame("Frame", nil, sidebar, "BackdropTemplate"))
    badge:SetSize(sW - 12, 70)
    badge:SetPoint("TOP", sidebar, "TOP", 0, -8)
    badge:SetBackdrop(BD)
    badge:SetBackdropColor(mc.r * 0.10, mc.g * 0.10, mc.b * 0.10, 1)
    badge:SetBackdropBorderColor(mc.r, mc.g, mc.b, 0.80)

    local modeLabel = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    modeLabel:SetText("Brann")
    modeLabel:SetTextColor(0.70, 0.65, 0.50, 1)
    modeLabel:SetPoint("TOPLEFT", badge, "TOPLEFT", 10, -8)

    local modeValue = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeValue:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    modeValue:SetText(mc.label)
    modeValue:SetTextColor(mc.r, mc.g, mc.b, 1)
    modeValue:SetPoint("TOPLEFT", badge, "TOPLEFT", 10, -28)

    local specLabel = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specLabel:SetFont(STANDARD_TEXT_FONT, 8)
    specLabel:SetText(mc.spec)
    specLabel:SetTextColor(mc.r * 0.65, mc.g * 0.65, mc.b * 0.65, 1)
    specLabel:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", 10, 7)

    -- iLvl + current tier strip
    local tierStrip = TrackSide(CreateFrame("Frame", nil, sidebar, "BackdropTemplate"))
    tierStrip:SetSize(sW - 12, 34)
    tierStrip:SetPoint("TOP", badge, "BOTTOM", 0, -4)
    tierStrip:SetBackdrop(BD)
    tierStrip:SetBackdropColor(tc[1] * 0.08, tc[2] * 0.08, tc[3] * 0.08, 1)
    tierStrip:SetBackdropBorderColor(tc[1] * 0.40, tc[2] * 0.40, tc[3] * 0.40, 0.8)

    local tierName = tierStrip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tierName:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    tierName:SetText(tier.label)
    tierName:SetTextColor(tc[1], tc[2], tc[3], 1)
    tierName:SetPoint("TOPLEFT", tierStrip, "TOPLEFT", 8, -6)

    local ilvlLabel = tierStrip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    ilvlLabel:SetText(iLvl .. " iLvl")
    ilvlLabel:SetTextColor(0.65, 0.62, 0.46, 1)
    ilvlLabel:SetPoint("TOPRIGHT", tierStrip, "TOPRIGHT", -8, -6)

    local bountifulLbl = tierStrip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bountifulLbl:SetFont(STANDARD_TEXT_FONT, 8)
    bountifulLbl:SetText(tier.bountiful and "\226\152\133 Bountiful unlocked" or "Bountiful: Tier 5+")
    bountifulLbl:SetTextColor(tier.bountiful and 0.29 or 0.40, tier.bountiful and 1.00 or 0.40, tier.bountiful and 0.38 or 0.40, 1)
    bountifulLbl:SetPoint("BOTTOMLEFT", tierStrip, "BOTTOMLEFT", 8, 6)

    -- Compact tier ladder
    local anchor = tierStrip
    local hdr = TrackSide(sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    hdr:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    hdr:SetText("TIER PROGRESS")
    hdr:SetTextColor(0.44, 0.38, 0.14, 1)
    hdr:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 2, -8)
    anchor = hdr

    for _, t in ipairs(TIERS) do
        local done    = (iLvl >= t.iLvlMin)
        local current = (t.tier == tier.tier)
        local tcc     = TRACK_COLORS[t.track] or {0.50, 0.50, 0.50}

        local row = TrackSide(sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
        row:SetFont(STANDARD_TEXT_FONT, 9, current and "OUTLINE" or "")
        local prefix = current and "\226\134\146 " or (done and "\226\156\147 " or "\226\150\161 ")
        row:SetText(prefix .. t.label .. (t.bountiful and "  \226\152\133" or ""))
        row:SetTextColor(
            current and 1 or (done and tcc[1] or 0.30),
            current and 1 or (done and tcc[2] or 0.30),
            current and 1 or (done and tcc[3] or 0.30), 1)
        row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", current and 0 or 2, current and -4 or -2)
        anchor = row
    end
end
