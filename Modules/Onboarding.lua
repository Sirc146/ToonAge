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
    "|cFF888780Type /ta help for full command list.|r",
    "|cFFFFD100━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r",
}

-- ── Init ──────────────────────────────────────────────────────────────────────

function Onboarding:Init()
    if not TA.charDB then return end

    -- Already onboarded this character
    if TA.charDB.onboarded then return end

    -- Mark as onboarded immediately to prevent re-triggering
    TA.charDB.onboarded = true

    -- Delay the welcome message slightly so it appears after all module
    -- init messages and the login splash has settled.
    C_Timer.After(3, function()
        self:RunFirstLogin()
    end)
end

-- ── First login sequence ──────────────────────────────────────────────────────

function Onboarding:RunFirstLogin()
    -- 1. Print welcome message
    for _, line in ipairs(WELCOME_LINES) do
        print(line)
    end

    -- 2. Auto-select a guide if none is active
    local QT = TA:GetModule("QuestTracker")
    if QT and not QT.guideID then
        QT:AutoSelectGuide()
        if QT.guideID then
            local guide = TA.Guides and TA.Guides[QT.guideID]
            if guide then
                print(string.format("|cFFFFD100[ToonAge]|r Auto-selected guide: |cFFFFFFFF%s|r", guide.title))
            end
        end
    end

    -- 3. Show the tracker window if a guide was found
    if QT and QT.guideID and QT.window then
        QT.window:Show()
        if TA.charDB.tracker then
            TA.charDB.tracker.visible = true
        end
    end

    -- 4. Show the arrow if a guide is active
    local Arrow = TA:GetModule("Arrow")
    if Arrow and QT and QT.guideID then
        if Arrow.frame then
            Arrow.frame:Show()
            if TA.charDB then
                TA.charDB.arrow = TA.charDB.arrow or {}
                TA.charDB.arrow.visible = true
            end
        end
    end

    -- 5. Suggest NavHud for experienced players (level > 10)
    local level = UnitLevel("player") or 1
    if level > 10 then
        print("|cFFFFD100[ToonAge]|r Tip: Try |cFFFFD100/ta hud|r for a transparent navigation overlay while questing.")
    end
end

Onboarding.SlashCommands = {}
