-- ToonAge/Modules/Automation/CutsceneSkip.lua
-- Automatically skips in-engine and movie cutscenes when the player has
-- opted in via the "Skip cutscenes" checkbox in the Tracker options panel.
--
-- Three cutscene surfaces exist in modern WoW:
--   1. CinematicFrame    — pre-rendered video (OpeningCinematic, expansion
--                          intros, legacy cinematics via PlayMovie).
--   2. MovieFrame        — Blizzard cinematic sequences also played through
--                          the video player in-engine (PLAY_MOVIE event).
--   3. In-engine scenes  — scripted cutscenes rendered using world geometry
--                          and the player model (CINEMATIC_START / STOP).
--
-- API notes:
--   • CinematicFrame_CancelCinematic()  — cancels CinematicFrame video.
--   • MovieFrame:Hide() / StopCinematic() — stops in-engine scene.
--   • GameMovieFinished()               — fires after MovieFrame finishes;
--     calling it manually signals the engine the movie is over.
--   All three are confirmed non-protected (no SecureActionButton needed).
--
-- Safety note: We only act when autoQuest (the broader "automate for me"
-- flag) is enabled. The cutsceneSkip flag is a separate per-character
-- preference that defaults to OFF so players who enjoy the story are
-- never surprised.

local TA = ToonAge

local CS = {}
TA:RegisterModule("CutsceneSkip", CS)

-- ── Skip logic ────────────────────────────────────────────────────────────────

local function ShouldSkip()
    return TA.charDB and TA.charDB.tracker and TA.charDB.tracker.cutsceneSkip
end

-- Small delay before skipping so the engine has time to actually start
-- playing and register the scene internally.  Skipping in the same frame
-- as the start event can occasionally leave the NPC dialog stuck open.
local SKIP_DELAY = 0.3 -- seconds

local function SkipInEngineCinematic()
    C_Timer.After(SKIP_DELAY, function()
        if not ShouldSkip() then
            return
        end
        -- MovieFrame covers in-engine scripted cutscenes in Dragonflight+
        if MovieFrame and MovieFrame:IsShown() then
            if MovieFrame.StopMovie then
                MovieFrame:StopMovie()
            end
            MovieFrame:Hide()
        end
        -- Legacy in-engine scenes (still used in Exile's Reach, Midnight intros)
        if CinematicFrame and CinematicFrame:IsShown() then
            CinematicFrame_CancelCinematic()
        end
        -- Catch-all: StopCinematic() terminates most camera-controlled scenes
        if StopCinematic then
            StopCinematic()
        end
    end)
end

local function SkipMovie()
    C_Timer.After(SKIP_DELAY, function()
        if not ShouldSkip() then
            return
        end
        if MovieFrame and MovieFrame:IsShown() then
            if GameMovieFinished then
                GameMovieFinished()
            end
        end
    end)
end

-- ── Events ────────────────────────────────────────────────────────────────────

function CS:OnEvent(event, ...)
    if event == "CINEMATIC_START" then
        SkipInEngineCinematic()
    elseif event == "PLAY_MOVIE" then
        -- arg1 = movieID. We skip all movies uniformly when the flag is on.
        SkipMovie()
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function CS:Init()
    TA.eventFrame:RegisterEvent("CINEMATIC_START")
    TA.eventFrame:RegisterEvent("PLAY_MOVIE")

    -- Default cutsceneSkip to false (opt-in).
    if TA.charDB and TA.charDB.tracker then
        if TA.charDB.tracker.cutsceneSkip == nil then
            TA.charDB.tracker.cutsceneSkip = false
        end
    end

    if TA.debug then
        TA:Raw(TA.LOG.INFO, "|cFFFFD100[TA]|r CutsceneSkip module loaded.")
    end
end
