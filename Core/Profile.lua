-- ToonAge/Core/Profile.lua  (SHARED ENGINE — per-flavor profile)
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- ToonAgeOne is one codebase for every WoW flavor. Core/Environment.lua answers
-- "what client is this?". Core/Compat/API.lua absorbs API-SURFACE differences.
-- This file answers the next question: "given the client, WHAT does this flavor
-- actually run?" — which modules initialize, which Data namespace they read,
-- and which stat-rule set applies.
--
-- A profile is intentionally declarative and small. It does NOT contain game
-- logic or data; it points at them. The heavy, flavor-specific game-design DATA
-- lives in Data/<Flavor>/** (see Docs/DATA_SOURCES.md), never here.
--
-- The engine consults the active profile in TWO ways:
--   1. Core/Init.lua:InitModules() calls TA:ModuleAllowed(name) and skips any
--      module the active flavor's profile does not list.
--   2. Modules/data loaders read TA:DataNamespace() to find their flavor's
--      Data folder (wired in Task 5).
--
-- Gating is the AND of two independent checks (belt and suspenders):
--   * profile allow-list  — "is this module part of this flavor's product?"
--   * ApiGuard (TA:HasAPI) — "does the running client even expose what it needs?"
-- A module must pass both. The profile is the product decision; ApiGuard is the
-- runtime-capability reality. Neither subsumes the other: retail lists a module
-- the client is missing after a patch -> ApiGuard still blocks it; a client has
-- an API but the flavor deliberately omits the module -> the profile blocks it.
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge or {}
ToonAge = TA

-- ─── PROFILE DEFINITIONS ───────────────────────────────────────────────────
-- Keyed by TA.flavor (set in Core/Environment.lua).
--
--   allowAll   — if true, every registered module is allowed (subject still to
--                ApiGuard + user toggles + safe mode). Retail/Mainline uses this
--                because it IS the full product; enumerating ~51 modules here
--                would be a second list to keep in sync with the TOC, and drift
--                between them is exactly the silent-breakage this project fights.
--   modules    — when allowAll is false, the explicit set of module names this
--                flavor ships. A module not listed is skipped even if loaded.
--   data       — the Data/<sub> namespace this flavor reads (Task 5 loaders).
--   statRules  — selector string for the stat-scoring rule set (e.g. retail DR
--                engine vs TBC hard caps). Consumed by gear/stat modules.
--   tabs       — ordered main-window tab list { id, label, module } for this
--                flavor. nil = Core/UI.lua's retail default set. Tab ids that
--                mean the same thing across flavors (talents, professions,
--                pets) are shared so /ta slash commands and saved lastTab /
--                disabledTabs keep working. UI.lua additionally hides any tab
--                whose module is not registered or not allowed, so a tab can
--                never render blank.
--   requires   — optional list of API paths (as in Data/ApiManifest) that the
--                flavor as a whole assumes; logged if absent. Per-module API
--                needs are still enforced individually via ApiGuard.
--
-- Only flavors with REAL shipped content are fully defined here. Cata/Vanilla/
-- Forever are declared as inert scaffolds (empty module set) until their
-- content exists — see Tasks 8/9. An unknown flavor falls back to a safe,
-- do-little profile rather than guessing.
local PROFILES = {
    retail = {
        label     = "Mainline (Retail)",
        allowAll  = true,
        data      = "Retail",
        statRules = "retail-dr",   -- DR-aware StatEngine (Core/StatEngine.lua)
    },

    -- TBC Anniversary. Modules live under Modules/TBC/ (listed only by
    -- ToonAge_TBC.toc). ErrorLog is the SHARED infrastructure module (no
    -- game-rule content), not a TBC-specific one.
    tbc = {
        label     = "TBC Anniversary",
        allowAll  = false,
        modules   = {
            ErrorLog          = true,   -- shared Modules/Infrastructure/ErrorLog.lua
            Character         = true,
            StatCaps          = true,
            WeaponSkill       = true,
            RaceAdvisor       = true,
            ProfessionAdvisor = true,
            TalentBuilds      = true,
            Rotation          = true,
            Spells            = true,
            PetCare           = true,
            Gear              = true,
            AutoEquip         = true,
            PvPAdvisor        = true,
        },
        -- Advisory-only product: no Guide (player uses Zygor), no Delves or
        -- Weekly (retail-only systems). Talents/Professions/Pets reuse the
        -- retail tab ids but point at the TBC modules.
        tabs      = {
            { id = "character",   label = "Character",   module = "Character"         },
            { id = "caps",        label = "Stat Caps",   module = "StatCaps"          },
            { id = "gear",        label = "Gear",        module = "Gear"              },
            { id = "talents",     label = "Talents",     module = "TalentBuilds"      },
            { id = "rotation",    label = "Rotation",    module = "Rotation"          },
            { id = "spells",      label = "Spells",      module = "Spells"            },
            { id = "weapons",     label = "Weapons",     module = "WeaponSkill"       },
            { id = "racials",     label = "Racials",     module = "RaceAdvisor"       },
            { id = "professions", label = "Professions", module = "ProfessionAdvisor" },
            { id = "pets",        label = "Pets",        module = "PetCare"           },
            { id = "pvp",         label = "PvP",         module = "PvPAdvisor"        },
        },
        data      = "TBC",
        statRules = "tbc-caps",    -- hard hit/expertise/defense caps
    },

    -- Mists of Pandaria Classic. Modules live under Modules/Mists/ (listed only
    -- by ToonAge_Mists.toc). Uses SHARED Utils + SHARED ErrorLog — MoP modules
    -- need no flavor-specific utils extension (unlike TBC). A trimmed leveling
    -- companion: navigation/guide + character + gear, no retail endgame set.
    mists = {
        label     = "Mists of Pandaria Classic",
        allowAll  = false,
        modules   = {
            ErrorLog     = true,   -- shared Modules/Infrastructure/ErrorLog.lua
            DevHelpers   = true,
            Character    = true,
            PetCare      = true,
            Gear         = true,
            AutoEquip    = true,
            GuideParser  = true,
            GuideImporter = true,
            GuideBrowser = true,
            GuideContextMenu = true,
            QuestTracker = true,
            Arrow        = true,
            CoordResolver = true,
            AntTrail     = true,
            NavHud       = true,
            MapPins      = true,
            XPTracker    = true,
            RestOptimizer = true,
            GatherTracker = true,
            CutsceneSkip = true,
            AutoMount    = true,
            DeathRecovery = true,
            Settings     = true,
            ChatCopy     = true,
        },
        -- Leveling companion: no Delves/Weekly/Talents/Rotation/Professions.
        tabs      = {
            { id = "character", label = "Character", module = "Character"    },
            { id = "guide",     label = "Guide",     module = "QuestTracker" },
            { id = "gear",      label = "Gear",      module = "Gear"         },
            { id = "pets",      label = "Pet Care",  module = "PetCare"      },
        },
        data      = "Mists",
        statRules = "mists-trees",
    },

    -- ── Tested inert scaffolds (Tasks 8/9) ────────────────────────────────
    -- Declared so the flavor is a first-class citizen the engine recognizes,
    -- but with no modules and no shipped Data. Loading on one of these clients
    -- initializes nothing harmful and prints no wrong advice.
    cata = {
        label     = "Cataclysm Classic (scaffold)",
        allowAll  = false,
        modules   = {},
        data      = "Cata",
        statRules = "cata-trees",
        scaffold  = true,
    },
    vanilla = {
        label     = "Classic Era / Vanilla (scaffold)",
        allowAll  = false,
        modules   = {},
        data      = "Vanilla",
        statRules = "vanilla-trees",
        scaffold  = true,
    },
    -- WoW Forever. REACHABLE as of the 2026-09 beta (Mainline project id with
    -- a 1.60.x interface code — see Core/Environment.lua). Content is
    -- Vanilla-era, so none of the Retail data applies; the API surface is
    -- Mainline's, so none of the TBC/MoP tree code applies either. Until
    -- Data/Forever exists this profile ships only shared infrastructure, which
    -- carries no game-rule content: the addon loads, captures errors and can
    -- report its own state without giving a single line of wrong advice.
    forever = {
        label     = "WoW Forever (beta)",
        allowAll  = false,
        modules   = {
            ErrorLog = true,   -- shared Modules/Infrastructure/ErrorLog.lua
        },
        data      = "Forever",
        statRules = "vanilla-trees",
        scaffold  = true,
    },
}

-- Fallback for an unrecognized/unlisted client (TA.flavor == "unknown"). Runs
-- nothing flavor-specific; the core framework still loads so /ta health etc.
-- work and can report the situation.
local UNKNOWN_PROFILE = {
    label     = "Unknown client",
    allowAll  = false,
    modules   = {},
    data      = nil,
    statRules = "none",
    unknown   = true,
}

TA.Profiles = PROFILES

-- ─── ACTIVE PROFILE SELECTION ──────────────────────────────────────────────
-- Resolved from TA.flavor. Environment.lua runs before this file (TOC order),
-- so TA.flavor is already set. Kept as a function AND a cached field so tests
-- can re-resolve after stubbing a different flavor.
function TA:ResolveProfile()
    local p = PROFILES[self.flavor or "unknown"] or UNKNOWN_PROFILE
    self.profile = p
    return p
end

--- The active profile, resolving on first use if needed.
function TA:GetProfile()
    return self.profile or self:ResolveProfile()
end

-- ─── GATING ────────────────────────────────────────────────────────────────

--- Is this module part of the active flavor's product?
--- (Profile decision only — ApiGuard is checked separately in ModuleAllowed.)
--- @param name string module name as registered
--- @return boolean
function TA:ModuleInProfile(name)
    local p = self:GetProfile()
    if p.allowAll then return true end
    if not p.modules then return false end
    return p.modules[name] == true
end

--- The full gate used by InitModules: a module runs only if the active flavor
--- ships it AND the running client exposes the APIs it declared.
--- ApiGuard's TA:HasAPI returns true when the probe hasn't run yet, so this is
--- never MORE restrictive than reality at early call time.
--- @param name string
--- @return boolean allowed
--- @return string|nil reason  when not allowed, why (for /ta health)
function TA:ModuleAllowed(name)
    if not self:ModuleInProfile(name) then
        return false, "not in " .. (self:GetProfile().label or "profile")
    end
    return true, nil
end

--- Ordered tab list for the active flavor, or nil to use the UI default.
--- @return table|nil
function TA:ProfileTabs()
    return self:GetProfile().tabs
end

--- Data/<sub> namespace for the active flavor (used by loaders in Task 5).
--- @return string|nil
function TA:DataNamespace()
    return self:GetProfile().data
end

--- Stat-rule selector for the active flavor (used by gear/stat modules).
--- @return string
function TA:StatRules()
    return self:GetProfile().statRules or "none"
end

-- Resolve once at load so self.profile is populated for anything that reads it
-- before OnLogin. Safe: depends only on TA.flavor, already set by Environment.
TA:ResolveProfile()

return TA
