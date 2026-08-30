-- ToonAge/Modules/CutsceneSkip.lua (Classic — MoP 50504)
-- Automatically skips in-engine and movie cutscenes when the player has
-- opted in via the "Skip cutscenes" checkbox in the Tracker options panel.
--
-- MoP Classic has the same cutscene surfaces as retail:
--   1. CinematicFrame — pre-rendered video playback
--   2. MovieFrame     — Blizzard cinematic sequences
--   3. In-engine scenes — scripted cutscenes (CINEMATIC_START / STOP)
--
-- API notes:
--   • CinematicFrame_CancelCinematic() — cancels CinematicFrame video.
--   • MovieFrame:Hide() / StopCinematic() — stops in-engine scene.
--   • GameMovieFinished() — signals the engine the movie is over.
--   All three are confirmed non-protected.
--
-- Nearly verbatim from the retail version — these APIs are stable.

local TA = ToonAge

local CS = {}
TA:RegisterModule("CutsceneSkip", CS)

-- ── Skip logic ────────────────────────────────────────────────────────────────

local function ShouldSkip()
    return TA.charDB
        and TA.charDB.tracker
        and TA.charDB.tracker.cutsceneSkip
end

-- Small delay before skipping so the engine has time to actually start
-- playing and register the scene internally.
local SKIP_DELAY = 0.3   -- seconds

local function SkipInEngineCinematic()
    C_Timer.After(SKIP_DELAY, function()
        if not ShouldSkip() then return end
        -- MovieFrame covers in-engine scripted cutscenes
        if MovieFrame and MovieFrame:IsShown() then
            if MovieFrame.StopMovie then MovieFrame:StopMovie() end
            MovieFrame:Hide()
        end
        -- Legacy in-engine scenes
        if CinematicFrame and CinematicFrame:IsShown() then
            CinematicFrame_CancelCinematic()
        end
        -- Catch-all: StopCinematic() terminates most camera-controlled scenes
        if StopCinematic then StopCinematic() end
    end)
end

local function SkipMovie()
    C_Timer.After(SKIP_DELAY, function()
        if not ShouldSkip() then return end
        if MovieFrame and MovieFrame:IsShown() then
            if GameMovieFinished then GameMovieFinished() end
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
