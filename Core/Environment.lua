-- ToonAge/Core/Environment.lua  (SHARED ENGINE — flavor-neutral)
-- Runtime game-flavor detection for the single-engine, multi-flavor build.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- ToonAgeOne is ONE codebase that ships to every WoW flavor (Retail/Mainline,
-- TBC Anniversary, MoP Classic, and future Cataclysm/Vanilla/"WoW Forever")
-- from one repository and one release tag. The engine (this Core/, the module
-- registry, the event funnel, the UI shell) is shared. Only flavor-specific
-- DATA and a handful of flavor-only modules branch.
--
-- For that to work the addon must know, at login, which client it is actually
-- running on — so Core/Profile.lua can decide which modules initialize and
-- which Data namespace to read. This file is that detection layer. It sets a
-- small set of boolean flags plus TA.flavor, and nothing else. It has no UI,
-- registers no module, and makes no game-rule decisions of its own.
--
-- Load order: this file loads immediately after Core/Init.lua (which creates
-- the ToonAge global) and BEFORE Core/Utils.lua and every module, so that
-- everything downstream can read TA.flavor / TA.IsRetail / TA.IsClassicFamily
-- instead of guessing.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── DETECTION IS SHIMMABLE. GAME-RULE DATA IS NOT. ────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- This file only answers "what client is this?". It deliberately does NOT try
-- to make one set of talent/stat-cap logic serve every flavor. Retail's
-- loadout talent system, TBC's 61-point trees with hit/expertise caps, and
-- MoP's trees are genuinely different game designs — each needs its own
-- researched Data/<Flavor>/*.lua. Detection tells the engine which of those to
-- load; it does not substitute for them. Shipping guessed content for a flavor
-- that has none is exactly the failure this project avoids.
--
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge or {}
ToonAge = TA

-- ─── PROJECT ID CONSTANTS ─────────────────────────────────────────────────
-- Blizzard's WOW_PROJECT_* globals. Verified against Warcraft Wiki's
-- WOW_PROJECT_ID reference (a wrong value here silently misdetects the flavor).
--
--   WOW_PROJECT_MAINLINE                = 1   Retail (live / PTR / Beta / XPTR)
--   WOW_PROJECT_CLASSIC                 = 2   Classic Era ("Vanilla" / Hardcore / Fresh)
--   WOW_PROJECT_WOWLABS                 = 3   Plunderstorm and similar WoW Labs modes
--   WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5   TBC Classic & TBC Anniversary
--   WOW_PROJECT_WRATH_CLASSIC           = 11  Wrath Classic
--   WOW_PROJECT_CATACLYSM_CLASSIC       = 14  Cataclysm Classic
--   WOW_PROJECT_MISTS_CLASSIC           = 19  Mists of Pandaria Classic
--
-- "WoW Forever" has NO project ID of its own. Its beta client (folder
-- _classic_beta_, WowB.exe) reports WOW_PROJECT_MAINLINE (1) with a 1.60.x
-- interface code (16001) — Blizzard built it on Mainline's UI architecture
-- with Midnight's API set, but with Vanilla-era content and version numbers.
-- So the project id alone cannot separate it from Retail; the interface code
-- does: every Mainline retail/PTR/beta build is >= 100000 (11xxxx / 12xxxx),
-- Forever is five digits. Captured from the 2026-09 beta client; revisit if
-- Blizzard ships a dedicated WOW_PROJECT_* constant.
local PROJECT_IDS = {
    MAINLINE    = 1,
    CLASSIC_ERA = 2,      -- Vanilla / Hardcore / Fresh
    WOWLABS     = 3,
    TBC         = 5,
    WRATH       = 11,
    CATA        = 14,
    MISTS       = 19,
}
TA.ProjectIDs = PROJECT_IDS

-- ─── DETECTION ────────────────────────────────────────────────────────────
-- WOW_PROJECT_ID is absent on very old clients; guard the read so this file is
-- safe to load anywhere. GetBuildInfo's 4th return is the numeric interface
-- code (e.g. 120007, 50504, 20506), used both for reporting and for the
-- historical TBC-vs-Vanilla disambiguation below.
-- Lowest interface code any Mainline retail-line client reports (Legion's
-- 70000 era onward is >= 100000 today; anything below this on Mainline is
-- Forever's 1.60.x line).
local MAINLINE_MIN_INTERFACE = 100000

local projectId     = _G.WOW_PROJECT_ID
local interfaceCode  = select(4, GetBuildInfo())
-- Interface code arrives as a string on some clients; normalize to a number so
-- the range comparisons below are reliable.
interfaceCode = tonumber(interfaceCode)

-- Forever first: it claims the Mainline project id, so IsRetail must exclude
-- it or retail spec/talent/gear data would be applied to Vanilla-era content.
TA.IsForever    = (projectId == PROJECT_IDS.MAINLINE and interfaceCode ~= nil
                   and interfaceCode < MAINLINE_MIN_INTERFACE)
TA.IsRetail     = (projectId == PROJECT_IDS.MAINLINE) and not TA.IsForever
TA.IsClassicEra = (projectId == PROJECT_IDS.CLASSIC_ERA and interfaceCode and interfaceCode < 20000)
TA.IsTBC        = (projectId == PROJECT_IDS.TBC)
    -- Historical gotcha: the original 2021 TBC Classic client shipped before
    -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC existed and reported the Classic Era
    -- project ID (2) with a TBC-range interface number. Current Anniversary
    -- clients report the real value (5), so this fallback is inert there but
    -- kept for safety on old builds.
    or (projectId == PROJECT_IDS.CLASSIC_ERA and interfaceCode and interfaceCode >= 20000 and interfaceCode < 30000)
TA.IsWrath      = (projectId == PROJECT_IDS.WRATH)
TA.IsCata       = (projectId == PROJECT_IDS.CATA)
TA.IsMists      = (projectId == PROJECT_IDS.MISTS)

-- "Old-style talent tree" family — everything whose game design uses the
-- tree/points/GetTalentTabInfo shape, as opposed to Retail's loadout system.
-- Profiles for these flavors share a data schema shape even though their
-- actual numbers differ per expansion. Forever is deliberately NOT in this
-- family: its content is Vanilla-era but its API surface is Mainline's, so
-- code written against GetTalentTabInfo and friends would break on it.
TA.IsClassicFamily = TA.IsClassicEra or TA.IsTBC or TA.IsWrath or TA.IsCata or TA.IsMists

-- Single canonical flavor string. Core/Profile.lua keys off this to pick the
-- module allow-list and Data namespace. Kept in sync with the booleans above.
TA.flavor = (TA.IsForever     and "forever")
         or (TA.IsRetail      and "retail")
         or (TA.IsTBC         and "tbc")
         or (TA.IsClassicEra  and "vanilla")
         or (TA.IsWrath       and "wrath")
         or (TA.IsCata        and "cata")
         or (TA.IsMists       and "mists")
         or "unknown"

TA.interfaceCode = interfaceCode
TA.projectId     = projectId

-- ─── BACKWARD-COMPATIBLE ALIASES ──────────────────────────────────────────
-- The Anniversary/TBC source used these lowercase field names. Kept as aliases
-- so TBC code folded in during Task 7 needs no edits, now sourced from real
-- detection instead of hardcoded literals.
TA.isClassic = TA.IsClassicFamily
TA.isTBC     = TA.IsTBC

--- Convenience predicate for modules/profiles: "is the running client one of
--- these flavors?"  Usage: TA:IsFlavor("retail", "mists")
--- @vararg string
--- @return boolean
function TA:IsFlavor(...)
    for i = 1, select("#", ...) do
        if self.flavor == select(i, ...) then return true end
    end
    return false
end

return TA
