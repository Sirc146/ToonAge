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
--   WOW_PROJECT_CATACLYSM_CLASSIC       = 14  Cataclysm Classic (no ToonAge flavor; dropped 2026-10-08)
--   WOW_PROJECT_MISTS_CLASSIC           = 19  Mists of Pandaria Classic
--
-- "WoW Forever" had no project ID of its own until build 70205, which reports
-- 18 (see FOREVER below). Before that, its beta client (folder
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
    MISTS       = 19,
    -- Forever's own id. MEASURED 2026-10-03 on build 70205 (1.60.1, interface
    -- 16001): WOW_PROJECT_ID = 18. Builds up to 70124 reported 1 (Mainline);
    -- the interface-code rule below still catches those.
    FOREVER     = 18,
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
TA.IsForever    = (projectId == PROJECT_IDS.FOREVER)
                  or (projectId == PROJECT_IDS.MAINLINE and interfaceCode ~= nil
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
TA.IsMists      = (projectId == PROJECT_IDS.MISTS)

-- "Old-style talent tree" family — everything whose game design uses the
-- tree/points/GetTalentTabInfo shape, as opposed to Retail's loadout system.
-- Profiles for these flavors share a data schema shape even though their
-- actual numbers differ per expansion. Forever is deliberately NOT in this
-- family: its content is Vanilla-era but its API surface is Mainline's, so
-- code written against GetTalentTabInfo and friends would break on it.
--
-- Mists is NOT in this family either (G13, 2026-10-04). Patch 5.0 replaced
-- the three point-spend trees with six tiers of three choices (one pick per
-- tier, every 15 levels), so neither the tree shape nor the tab/points data
-- schema applies to it. Mists is still classic-ERA content; it is just not
-- tree-shaped. The self-test's env suite cross-checks this flag against the
-- client's talent-tab API on every run.
TA.IsClassicFamily = TA.IsClassicEra or TA.IsTBC or TA.IsWrath

-- ── Forever launch-day fallback ───────────────────────────────────────
--
-- Forever detection above assumes the beta's shape: Mainline project id with a
-- 1.60.x interface. If Blizzard gives the live client a WOW_PROJECT_* constant
-- of its own, nothing above matches and the flavor resolves to "unknown" --
-- the profile gate then initializes nothing, and the addon opens empty with no
-- error on launch day.
--
-- The TOC that loaded settles it. "## X-Flavor: Forever" ships only in the
-- Forever build, and that build is only ever installed into the Forever
-- client (Tools/build_flavors.ps1), so reading it is proof of which client
-- this is. It fires ONLY when every id-based check has already failed: a
-- client this file recognizes is never overridden by metadata.
--
-- Read directly, not through Core/Compat/API.lua, which loads after this
-- file. Metadata for the loading addon is available at file-load time.
local ADDON_NAME = ... or "ToonAge"
TA.flavorSource = "project-id"
if not (TA.IsForever or TA.IsRetail or TA.IsClassicEra or TA.IsTBC
        or TA.IsWrath or TA.IsMists) then
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local tocFlavor
    if getMeta then
        local ok, value = pcall(getMeta, ADDON_NAME, "X-Flavor")
        if ok then tocFlavor = value end
    end
    if tocFlavor == "Forever" then
        TA.IsForever    = true
        TA.flavorSource = "toc-fallback"
    end
end

-- Single canonical flavor string. Core/Profile.lua keys off this to pick the
-- module allow-list and Data namespace. Kept in sync with the booleans above.
TA.flavor = (TA.IsForever     and "forever")
         or (TA.IsRetail      and "retail")
         or (TA.IsTBC         and "tbc")
         or (TA.IsClassicEra  and "vanilla")
         or (TA.IsWrath       and "wrath")
         or (TA.IsMists       and "mists")
         or "unknown"

-- ── Which TOC actually loaded ─────────────────────────────────────────
--
-- WoW picks a TOC by matching a filename suffix it already knows, and if it
-- finds none it silently falls back. Silently is the problem: a flavour whose
-- suffix the client stops recognizing loads the WRONG product with no error,
-- which is exactly how Forever ended up parsing the entire retail addon.
--
-- Every TOC declares "## X-Flavor". Comparing what this client IS against
-- what the loaded TOC SAYS turns that silent fallback into something
-- /ta health can state out loud. This matters most for Forever, whose suffix
-- is a pre-release codename Blizzard may well retire at launch -- the day it
-- changes, this check is what reports it instead of a week of odd bugs.
--
-- Deferred, not computed here: the metadata API lives in Core/Compat/API.lua,
-- which loads after this file.

--- What "## X-Flavor" the TOC for this client is expected to declare.
local EXPECTED_TOC_FLAVOR = {
    retail = "Mainline", forever = "Forever", tbc = "TBC",
    mists  = "Mists",    vanilla = "Vanilla",
    wrath  = "Wrath",
}

--- nil when the right TOC loaded (or we cannot tell); otherwise
--- expected, actual -- meaning the client fell back to another product's TOC.
function TA:TocFlavorMismatch()
    local want = EXPECTED_TOC_FLAVOR[self.flavor]
    if not want then return nil end
    local C = self.Compat
    local read = C and C.GetAddOnMetadata and C.GetAddOnMetadata("ToonAge", "X-Flavor")
    if not read or read == "" then return nil end   -- cannot tell; say nothing
    if read == want then return nil end
    -- ToonAge.toc declares "fallback" on purpose: it is the file for a client
    -- no suffix matched. In the repository (and therefore in the GitHub/Wago
    -- release zip, which packs the repo root) that file carries the RETAIL
    -- file list, so it is only correct on Retail. On any other client it is
    -- the wrong product: report it, so the wrong-build guard stops the modules
    -- and says why, instead of silently running retail files (2026-10-04).
    -- Per-client builds from build_flavors.ps1 never hit this: their
    -- ToonAge.toc is a copy of that client's own TOC, X-Flavor included.
    if read == "fallback" then
        if want == "Mainline" then return nil end
        return want, "fallback (retail list)"
    end
    return want, read
end

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
