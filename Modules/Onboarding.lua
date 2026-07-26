-- ToonAge/Modules/Onboarding.lua
-- First-login experience: detects new characters, runs initial setup,
-- shows welcome message with feature overview and key commands.
--
-- Triggers on first PLAYER_ENTERING_WORLD when charDB.onboarded is nil.
-- ═══════════════════════════════════════════════════════════════════════════════

local TA = ToonAge

local Onboarding = {}
TA:RegisterModule("Onboarding", Onboarding)

-- ── Welcome message content ───────────────────────────────────────────────────

local WELCOME_LINES = {
    "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r",
    "|cFFFFD100ToonAge|r — Your all-in-one character advisor",
    "",
    "|cFF4AFF7A✓|r  Guide Tracker  — auto-syncs to your quest log",
    "|cFF4AFF7A✓|r  Navigation Arrow  — points to your next objective",
    "|cFF4AFF7A✓|r  NavHud  — transparent FarmHud-style overlay (|cFFFFD100/ta hud|r)",
    "|cFF4AFF7A✓|r  Gear Advisor  — stat-weight upgrade detection",
    "|cFF4AFF7A✓|r  Talent Builds  — recommended specs with import strings",
    "|cFF4AFF7A✓|r  Rotation Helper  — combat priority with live highlighting",
    "|cFF4AFF7A✓|r  Weekly & Delves  — endgame tracking that stays relevant",
    "",
    "|cFFFFD100Key commands:|r",
    "  |cFFFFD100/ta|r — open the main panel",
    "  |cFFFFD100/ta hud|r — toggle the navigation HUD",
    "  |cFFFFD100/ta tracker|r — toggle the floating quest tracker",
    "  |cFFFFD100/ta arrow|r — toggle the navigation arrow",
    "  |cFFFFD100/ta options|r — open settings (auto-quest, layout, etc.)",
    "",
    "|cFF888780Right-click quests to start following them.|r",
    "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r",
}

-- ── Init ──────────────────────────────────────────────────────────────────────

function Onboarding:Init()
    if not TA.charDB then return end

    local db    = TA.db
    local scope = (db and db.onboardScope) or "character"

    -- "account" scope: once ever, however many characters you roll.
    if scope == "account" and db and db.onboardedAccount then return end

    -- "character" scope (default): once per character.
    if TA.charDB.onboarded then return end

    -- Mark as onboarded immediately to prevent re-triggering
    TA.charDB.onboarded = true

    -- Claim the login for the guided flow. AltQuickStart schedules its own
    -- auto-show at 2s and this runs at 3s, so the "what to do next" panel used
    -- to arrive a full second BEFORE the welcome screen meant to introduce it —
    -- two popups, in the wrong order, which is what made first login feel like
    -- a wall. The flow now opens that panel itself as its final step.
    --
    -- Set here and read inside AltQuickStart's timer callback rather than at
    -- its Init, because module init order comes from pairs() and is not
    -- deterministic. By the time either callback fires, both Inits have run.
    TA._onboardingActive = true

    -- Delay the welcome message slightly so it appears after all module
    -- init messages and the login splash has settled.
    C_Timer.After(3, function()
        self:RunFirstLogin()
    end)
end

--- Called when the welcome popup is dismissed by any route. Advances the flow.
---
--- Step 2 (gear-aware build choice) will slot in between these two points.
--- Its governing rule, decided up front: recommend for the gear that exists.
--- Scan equipped and bags; if no better weapon combination is actually present,
--- recommend the best build for what is currently wearable and say so. Never
--- send the player hunting for an item to enable a build. Heirlooms are the
--- exception — they are replaceable by design, so a maxed one is an expected
--- swap point rather than a gear gap (Gear.lua's GetItemIlvls already returns
--- a heirloomCap for this).
function Onboarding:CompleteFlow()
    if TA.db then TA.db.onboardedAccount = true end
    TA._onboardingActive = false

    -- Step 3: the main screen. Short delay so it does not appear in the same
    -- frame the welcome popup vanishes in, which reads as a flicker.
    C_Timer.After(0.4, function()
        local AQS = TA:GetModule("AltQuickStart")
        local optedOut = TA.charDB and TA.charDB.altQuickStart
                     and TA.charDB.altQuickStart.disabled
        if AQS and AQS.Show and not optedOut then
            AQS:Show()
        end
    end)
end

-- ── Slash commands ────────────────────────────────────────────────────────────

Onboarding.SlashCommands = {
    onboard = function(self, args)
        local sub = ((args or ""):match("^(%S*)") or ""):lower()

        if sub == "account" or sub == "character" then
            if TA.db then TA.db.onboardScope = sub end
            local desc = sub == "account" and "once per account"
                                           or "once per character"
            print("|cFFFFD100[ToonAge]|r First-run setup: |cFFFFD100" .. desc .. "|r.")
            return
        end

        if sub == "reset" then
            if TA.charDB then TA.charDB.onboarded = nil end
            if TA.db then TA.db.onboardedAccount = false end
            print("|cFFFFD100[ToonAge]|r First-run setup will run again next login. "
                  .. "|cFF888780/ta onboard runs it now.|r")
            return
        end

        if sub ~= "" then
            print("|cFFFFD100[ToonAge]|r Unknown: /ta onboard " .. sub
                  .. "  |cFF888780(try: account, character, reset)|r")
            return
        end

        -- No argument: run the flow now, without touching the saved flags.
        local scope = (TA.db and TA.db.onboardScope) or "character"
        print("|cFFFFD100[ToonAge]|r Setup — currently |cFFFFD100" .. scope .. "|r scope. "
              .. "|cFF888780/ta onboard account|character to change.|r")
        self:ShowPopup()
    end,
}

-- ── First login sequence ──────────────────────────────────────────────────────

function Onboarding:RunFirstLogin()
    -- Print concise welcome
    print("|cFFFFD100ToonAge|r loaded! Opening setup...")

    -- Create the onboarding popup
    self:ShowPopup()
end

function Onboarding:ShowPopup()
    if self.popup then self.popup:Show(); return end

    local f = CreateFrame("Frame", "TAOnboardingPopup", UIParent, "BackdropTemplate")
    f:SetSize(420, 320)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.97)
    f:SetBackdropBorderColor(0.55, 0.40, 0.08, 1)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetText("|cFFFFD100ToonAge|r  —  First Time Setup")
    title:SetPoint("TOP", f, "TOP", 0, -16)

    -- Description
    local desc = f:CreateFontString(nil, "OVERLAY")
    desc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    desc:SetWidth(380)
    desc:SetJustifyH("CENTER")
    desc:SetText(
        "Welcome! ToonAge replaces Zygor, Pawn, Hekili, and TomTom\n" ..
        "in a single lightweight addon.\n\n" ..
        "|cFFFFD100Choose your experience:|r"
    )
    desc:SetTextColor(0.85, 0.83, 0.78, 1)
    desc:SetPoint("TOP", title, "BOTTOM", 0, -14)

    -- Feature list
    local features = f:CreateFontString(nil, "OVERLAY")
    features:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    features:SetWidth(360)
    features:SetJustifyH("LEFT")
    features:SetText(
        "|cFF4AFF7A●|r Auto-accept & turn-in quests\n" ..
        "|cFF4AFF7A●|r Skip cutscenes automatically\n" ..
        "|cFF4AFF7A●|r Next 3 abilities combat bar\n" ..
        "|cFF4AFF7A●|r Nameplate kill/loot markers\n" ..
        "|cFF4AFF7A●|r Tooltip upgrade percentages\n" ..
        "|cFF4AFF7A●|r Smart arrow to Flight Masters"
    )
    features:SetTextColor(0.80, 0.78, 0.72, 1)
    features:SetPoint("TOP", desc, "BOTTOM", 0, -10)

    -- ── Full Auto button ──────────────────────────────────────────────
    local btnAuto = CreateFrame("Button", nil, f, "BackdropTemplate")
    btnAuto:SetSize(180, 36)
    btnAuto:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 60)
    btnAuto:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    btnAuto:SetBackdropColor(0.05, 0.15, 0.05, 1)
    btnAuto:SetBackdropBorderColor(0.20, 0.92, 0.40, 0.9)
    local autoLbl = btnAuto:CreateFontString(nil, "OVERLAY")
    autoLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    autoLbl:SetText("|cFF4AFF7A⚡|r Full Auto")
    autoLbl:SetAllPoints(btnAuto)
    autoLbl:SetJustifyH("CENTER")
    local autoSub = f:CreateFontString(nil, "OVERLAY")
    autoSub:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    autoSub:SetText("Enable everything — fastest leveling")
    autoSub:SetTextColor(0.55, 0.52, 0.45, 1)
    autoSub:SetPoint("TOP", btnAuto, "BOTTOM", 0, -3)

    btnAuto:SetScript("OnClick", function()
        self:ApplyPreset("auto")
        f:Hide()
        self:CompleteFlow()
    end)

    -- ── Manual button ─────────────────────────────────────────────────
    local btnManual = CreateFrame("Button", nil, f, "BackdropTemplate")
    btnManual:SetSize(180, 36)
    btnManual:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 60)
    btnManual:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    btnManual:SetBackdropColor(0.08, 0.06, 0.02, 1)
    btnManual:SetBackdropBorderColor(0.55, 0.40, 0.08, 0.7)
    local manLbl = btnManual:CreateFontString(nil, "OVERLAY")
    manLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    manLbl:SetText("|cFFFFD100◆|r Manual")
    manLbl:SetAllPoints(btnManual)
    manLbl:SetJustifyH("CENTER")
    local manSub = f:CreateFontString(nil, "OVERLAY")
    manSub:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    manSub:SetText("Just show info — I'll click things myself")
    manSub:SetTextColor(0.55, 0.52, 0.45, 1)
    manSub:SetPoint("TOP", btnManual, "BOTTOM", 0, -3)

    btnManual:SetScript("OnClick", function()
        self:ApplyPreset("manual")
        f:Hide()
        self:CompleteFlow()
    end)

    -- ── Close / Decide Later ──────────────────────────────────────────
    local btnLater = CreateFrame("Button", nil, f)
    btnLater:SetSize(100, 20)
    btnLater:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    local laterLbl = btnLater:CreateFontString(nil, "OVERLAY")
    laterLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    laterLbl:SetText("|cFF888780Decide Later (/ta options)|r")
    laterLbl:SetAllPoints(btnLater)
    laterLbl:SetJustifyH("CENTER")
    btnLater:SetScript("OnClick", function() f:Hide(); Onboarding:CompleteFlow() end)

    self.popup = f
end

-- ── Presets ───────────────────────────────────────────────────────────────────

function Onboarding:ApplyPreset(preset)
    local t = TA.charDB.tracker or {}

    if preset == "auto" then
        -- Enable all automation
        t.autoQuest      = true
        t.cutsceneSkip   = true
        t.autoEquip      = true
        t.replaceBlizzTracker = true
        TA.charDB.predictBar = TA.charDB.predictBar or {}
        TA.charDB.predictBar.visible = true
        print("|cFF4AFF7A[ToonAge]|r Full Auto enabled! Quests auto-accept, cutscenes skip, combat bar active.")
        print("|cFF888780Hold Shift at any NPC to pause automation.|r")
    else
        -- Manual mode — show info only, no automation
        t.autoQuest      = false
        t.cutsceneSkip   = false
        t.autoEquip      = false
        t.replaceBlizzTracker = false
        TA.charDB.predictBar = TA.charDB.predictBar or {}
        TA.charDB.predictBar.visible = true  -- still show prediction bar (it's passive info)
        print("|cFFFFD100[ToonAge]|r Manual mode. Arrow + tracker + prediction active. No auto-quest.")
    end

    TA.charDB.tracker = t

    -- Show main panel instead of standalone tracker
    TA:ToggleUI()
    local Arrow = TA:GetModule("Arrow")
    if Arrow and Arrow.frame then
        Arrow.frame:Show()
        TA.charDB.arrow = TA.charDB.arrow or {}
        TA.charDB.arrow.visible = true
    end
    -- Show prediction bar
    local Rot = TA:GetModule("Rotation")
    if Rot and Rot.predictBar and TA.charDB.predictBar.visible then
        Rot.predictBar:Show()
    end
end

Onboarding.SlashCommands = {}
