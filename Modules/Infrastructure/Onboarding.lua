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

    -- Already seen this character.
    if TA.charDB.onboarded then return end

    local behavior = (TA.db and TA.db.newCharBehavior) or "wizard"

    -- "off": nothing at all. Deliberately does not claim the login below, so
    -- AltQuickStart keeps its ordinary behaviour -- which for a character with
    -- no lastLoginTime means it stays shut anyway.
    if behavior == "off" then
        TA.charDB.onboarded = true
        return
    end

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

    -- "inherit": no popup and no windows. Settings are applied silently and
    -- the player gets a single chat line telling them what happened.
    if behavior == "inherit" then
        self:RunSilentInherit()
        return
    end

    -- Delay the welcome message slightly so it appears after all module
    -- init messages and the login splash has settled.
    C_Timer.After(3, function()
        self:RunFirstLogin()
    end)
end

--- The opt-out path: apply the remembered preset, say so once, open no panels.
---
--- "Silent" means no wizard popup, no main window and no Quick Start panel. It
--- does NOT mean an empty screen: the preset asks for the arrow and prediction
--- bar, both of which are HUD elements rather than windows, so they appear.
--- Writing visible=true and then leaving the frames hidden would be the one
--- genuinely inconsistent outcome.
function Onboarding:RunSilentInherit()
    local preset = (TA.db and TA.db.defaultPreset) or "auto"

    -- Synchronous, so any module whose Init runs after this one reads the
    -- finished settings rather than a half-written table.
    self:ApplyPresetConfig(preset)

    C_Timer.After(3, function()
        -- Reconcile the modules that sample these flags once at Init and never
        -- again. Module Init order comes from pairs() and is not deterministic
        -- (see the note in Init above), so whether Arrow:Init and QT:Init ran
        -- before or after the writes above is a coin flip -- and the losing
        -- side leaves the arrow hidden and the Blizzard tracker still showing.
        -- The wizard path never hit this because its display half force-showed
        -- everything. Doing it here, on a timer, is the equivalent that does
        -- not open any windows. All three calls are idempotent.
        local Arrow = TA:GetModule("Arrow")
        if Arrow and Arrow.frame and TA.charDB.arrow and TA.charDB.arrow.visible then
            Arrow.frame:Show()
        end

        local QT = TA:GetModule("QuestTracker")
        if QT and QT.UpdateBlizzardTrackerVisibility then
            QT:UpdateBlizzardTrackerVisibility()
        end

        local Rot = TA:GetModule("Rotation")
        if Rot and Rot.predictBar and TA.charDB.predictBar
           and TA.charDB.predictBar.visible then
            Rot.predictBar:Show()
        end

        -- Printed here rather than from Init so the one clean line lands after
        -- the module init messages instead of buried in them -- the same reason
        -- the wizard path delays its welcome by 3 seconds.
        local label = (preset == "auto") and "Full Auto" or "Manual"
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r New character detected. Inheriting |cFFFFD100"
              .. label .. "|r setup.  |cFF888780/ta onboard for the full setup"
              .. " wizard, /ta options to change.|r")

        -- Release the claim only now: held past AltQuickStart's 2s auto-show so
        -- "silent" stays silent, cleared afterwards because a flag that is
        -- never reset is a trap for the next reader.
        TA._onboardingActive = false
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
---
--- Safe to call from a manual /ta onboard as well as from first login: it no
--- longer writes any "do not run again" flag. It used to set onboardedAccount
--- unconditionally, so anyone on account scope who typed /ta onboard just to
--- look at the panel silently burned the account-wide flag for every alt.
function Onboarding:CompleteFlow()
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

local BEHAVIOR_DESC = {
    wizard  = "show the setup wizard on each new character",
    inherit = "apply the saved preset silently, one chat line, no windows",
    off     = "do nothing on new characters",
}

Onboarding.SlashCommands = {
    onboard = function(self, args)
        args = args or ""
        local sub  = (args:match("^(%S*)") or ""):lower()
        local rest = (args:match("^%S*%s+(%S+)") or ""):lower()

        if BEHAVIOR_DESC[sub] then
            if TA.db then TA.db.newCharBehavior = sub end
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r New characters: |cFFFFD100" .. sub .. "|r — "
                  .. BEHAVIOR_DESC[sub] .. ".")
            return
        end

        -- Back-compat for muscle memory from the old two-flag model.
        if sub == "account" or sub == "character" then
            local mapped = (sub == "account") and "off" or "wizard"
            if TA.db then TA.db.newCharBehavior = mapped end
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r |cFF888780Scopes were replaced by modes.|r "
                  .. "New characters: |cFFFFD100" .. mapped .. "|r — "
                  .. BEHAVIOR_DESC[mapped] .. ".")
            return
        end

        if sub == "preset" then
            if rest ~= "auto" and rest ~= "manual" then
                local cur = (TA.db and TA.db.defaultPreset) or "auto"
                TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Inherited preset: |cFFFFD100" .. cur
                      .. "|r.  |cFF888780/ta onboard preset auto|manual to change.|r")
                return
            end
            if TA.db then TA.db.defaultPreset = rest end
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r New characters will inherit the |cFFFFD100"
                  .. rest .. "|r preset.")
            return
        end

        if sub == "reset" then
            if TA.charDB then TA.charDB.onboarded = nil end
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r This character will be treated as new next login. "
                  .. "|cFF888780/ta onboard runs the wizard now.|r")
            return
        end

        if sub ~= "" then
            TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Unknown: /ta onboard " .. sub
                  .. "  |cFF888780(try: wizard, inherit, off, preset, reset)|r")
            return
        end

        -- No argument: the manual override. Runs the wizard on this character
        -- whatever newCharBehavior says, and touches no saved flags.
        local mode = (TA.db and TA.db.newCharBehavior) or "wizard"
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Setup wizard — new characters are set to |cFFFFD100"
              .. mode .. "|r.  |cFF888780/ta onboard wizard|inherit|off to change.|r")
        self:ShowPopup()
    end,
}

-- ── First login sequence ──────────────────────────────────────────────────────

function Onboarding:RunFirstLogin()
    -- Print concise welcome
    TA:Raw(TA.LOG.INFO, "|cFFFFD100ToonAge|r loaded! Opening setup...")

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

--- Writes a preset's settings into charDB and nothing else -- no windows, no
--- chat output. Split out from ApplyPreset so the silent inherit path can
--- reuse it: the display half below calls TA:ToggleUI(), which is a *toggle*,
--- so on a silent login it would either open the main window (contradicting
--- "open nothing") or close one that something else had already opened.
--- @param preset string "auto" | "manual"
function Onboarding:ApplyPresetConfig(preset)
    if not TA.charDB then return end
    local auto = (preset == "auto")

    local t = TA.charDB.tracker or {}
    t.autoQuest           = auto
    t.cutsceneSkip        = auto
    t.autoEquip           = auto
    t.replaceBlizzTracker = auto
    TA.charDB.tracker = t

    -- On in both presets: the prediction bar is passive information, not
    -- automation, so Manual mode still gets it.
    TA.charDB.predictBar = TA.charDB.predictBar or {}
    TA.charDB.predictBar.visible = true

    TA.charDB.arrow = TA.charDB.arrow or {}
    TA.charDB.arrow.visible = true
end

--- The wizard's version: applies the preset, reports it, and opens the UI.
function Onboarding:ApplyPreset(preset)
    self:ApplyPresetConfig(preset)

    -- Remember the choice so alts created later can inherit it under
    -- newCharBehavior = "inherit".
    if TA.db then TA.db.defaultPreset = (preset == "auto") and "auto" or "manual" end

    if preset == "auto" then
        TA:Raw(TA.LOG.OUTPUT, "|cFF4AFF7A[ToonAge]|r Full Auto enabled! Quests auto-accept, cutscenes skip, combat bar active.")
        TA:Raw(TA.LOG.OUTPUT, "|cFF888780Hold Shift at any NPC to pause automation.|r")
    else
        TA:Raw(TA.LOG.OUTPUT, "|cFFFFD100[ToonAge]|r Manual mode. Arrow + tracker + prediction active. No auto-quest.")
    end

    -- Show main panel instead of standalone tracker
    TA:ToggleUI()
    local Arrow = TA:GetModule("Arrow")
    if Arrow and Arrow.frame then
        Arrow.frame:Show()
    end
    -- Show prediction bar
    local Rot = TA:GetModule("Rotation")
    if Rot and Rot.predictBar and TA.charDB.predictBar.visible then
        Rot.predictBar:Show()
    end
end
