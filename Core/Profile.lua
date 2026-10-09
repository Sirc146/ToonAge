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
            -- No heirlooms on TBC. The module skips the scan and draws the
            -- empty-state card on the Gear tab.
            Heirlooms         = true,
            PvPAdvisor        = true,
            -- Shipped by ToonAge_TBC.toc all along but never listed here, so
            -- they loaded and never initialized. AutoEquip scores with the
            -- cap-aware Gear score (TBC audit fix 6).
            AutoEquip         = true,
            AutoQuest         = true,
            VendorAssist      = true,
            -- Shared drawer, self-gating per section (G9, 2026-10-04). Shipped
            -- by ToonAge_TBC.toc; without it the gear button opened nothing.
            Settings          = true,
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
            -- Hidden for classes with no pet (N5): Hunter/Warlock, or a pet out.
            { id = "pets",        label = "Pets",        module = "PetCare",
              condition = "hasPetClass" },
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
            -- Collection API is checked at runtime. MoP predates the heirloom
            -- journal, so a missing C_Heirloom falls back to a bag scan.
            Heirlooms    = true,
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
            DeathRecovery = true,
            Settings     = true,
            ChatCopy     = true,
            -- Shipped by ToonAge_Mists.toc but previously denied here.
            AutoEquip    = true,
            AutoMount    = true,
            CutsceneSkip = true,
            VendorAssist = true,
        },
        -- Leveling companion: no Delves/Weekly/Talents/Rotation/Professions.
        tabs      = {
            { id = "character",  label = "Character",  module = "Character"    },
            { id = "guide",      label = "Guide",      module = "QuestTracker" },
            { id = "gear",       label = "Gear",       module = "Gear"         },
            -- Hidden for classes with no pet (N5): Hunter/Warlock, Frost Mage,
            -- Unholy DK, or any pet out. See TabConditions in Core/UI.lua.
            { id = "pets",       label = "Pets",       module = "PetCare",
              condition = "hasPetClass" },
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
    -- G12 (2026-10-04). ToonAge_Wrath.toc shipped with no profile, so a Wrath
    -- client resolved to UNKNOWN_PROFILE and /ta health and the no-content panel
    -- called it "Unknown client" -- a launch-checklist NO-GO. Same inert
    -- scaffold as cata/vanilla. No Wrath Classic client exists to test on as of
    -- this date; whether to keep the TOC at all is the open checklist decision.
    wrath = {
        label     = "Wrath of the Lich King Classic (scaffold)",
        allowAll  = false,
        modules   = {},
        data      = "Wrath",
        statRules = "wrath-trees",
        scaffold  = true,
    },
    -- WoW Forever. Detected since the 2026-09 beta (project id 18, or a
    -- Mainline project id with a 1.60.x interface). The client loads
    -- ToonAge_Camelot.toc, which does not include retail modules. This
    -- allow-list is the second gate if a wrong TOC is ever what loaded.
    --
    -- The split is by DEPENDENCY, not by caution. Modules listed here read the
    -- world through APIs this client has and carry no expansion numbers of
    -- their own: waypoints, coordinates, XP, gathering, rest, guide parsing and
    -- tracking. Everything left out — gear scoring, rotations, talents,
    -- professions, pets, Delves, Weekly, world quests, travel routing — is
    -- driven by Data/Retail values that are wrong for Vanilla-era content, and
    -- stays out until Data/Forever exists.
    --
    -- partial (not scaffold): the addon does real work here, but only part of
    -- the product. ApiGuard stays quiet about the missing manifest, and the UI
    -- explains itself when no guide has been imported yet.
    forever = {
        label     = "WoW Forever (beta)",
        allowAll  = false,
        modules   = {
            -- A readout, not advice: Modules/Forever/Character.lua reports what
            -- the client says about this character and ranks nothing. It
            -- registers as ForeverCharacter so it cannot collide with the
            -- retail Character module, which ships in the same TOC.
            ForeverCharacter = true,
            -- Infrastructure — no game-rule content at all
            ErrorLog         = true,
            Settings         = true,
            ChatCopy         = true,
            CoordHarvester   = true,
            -- No guide stack here. Forever ships no guides, none of the
            -- existing ones describe this game's quests, and the tracker is
            -- what dragged SpecAdaptive and the rest of the retail chain in
            -- behind it. A guide tab with nothing to guide you through is
            -- worse than no tab.
            -- No HUD either, as of 2026-09-22. It was the last piece of the
            -- guide-era overlay stack left here: it drew waypoints that no
            -- longer exist, and gather dots for a recorder whose loot-API path
            -- is unverified on this client. The arrow, the tracker drawer, the
            -- map pins, the ant trail and the coordinate resolver went for the
            -- same reason — they point at guide steps, and there are none.
            -- Still shipped on retail and Mists; this is a Forever-only cut.
            -- Leveling quality of life
            XPTracker        = true,
            RestOptimizer    = true,
            GatherTracker    = true,
            DeathRecovery    = true,
            -- The recorder. No outside source has numbers for this client, so
            -- the client itself is the only one, and playing is how it gets
            -- read. Everything Data/Forever eventually contains starts here.
            DataHarvester    = true,
            -- Gear: a Vanilla-correct readout of what is equipped (per-slot
            -- item + item level) and the combined stats those items carry.
            -- Reports facts only; no scoring until Data/Forever weights exist.
            ForeverGear      = true,
            -- Talents: a readout of the three Vanilla trees and the points in
            -- each. Guards the classic talent globals heavily and says so
            -- plainly when the client will not answer them.
            ForeverTalents   = true,
            -- Spellbook: what the character actually knows, grouped by skill
            -- line. Not a rotation — Vanilla exposes none — a readout of known
            -- spells and their ranks, guarded against both spellbook APIs.
            ForeverRotation  = true,
            -- Pets: only shown for classes that actually command a pet
            -- (Hunter/Warlock), gated by the tab's condition below.
            ForeverPets      = true,
            -- PvP: what actually draws on build 70124 (measured 2026-09-28/30):
            --   * racial matchups -- yours, your target's, the enemy faction's
            --     (Data/Forever/Racials.lua, harvested from all 9 races)
            --   * session + lifetime honorable kills / honor
            --     (GetPVPSessionStats / GetPVPLifetimeStats are present)
            -- NOT drawn: rank name/number/progress and this/last-week stats.
            -- The game's own PvP pane shows the 14-rank ladder, but
            -- UnitPVPRank, GetPVPRankInfo, GetPVPRankProgress and
            -- GetPVPThisWeekStats/LastWeekStats are absent to addons, so the
            -- "Standing" section is omitted. Class matchups wait on spell data.
            ForeverPvP       = true,
            -- Scrolls: which class each scroll in your bags is for, read from
            -- the item's own Classes:/Requires tooltip lines (no item list), plus
            -- a matching line on every item tooltip. Mage Comprehension gates
            -- are shown against the player's skill when the client reports it.
            ForeverScrolls   = true,
            -- Cast order per fight. Replaces the banned Combat tab on Forever:
            -- own frame, player spell-cast event only, no combat log.
            ForeverCastLog   = true,
            -- "Since last session" at login: compares the snapshot saved at
            -- logout with the live character (ranks to train, low ranks on
            -- bars, unspent talents, skills behind the cap, new gear). No tab.
            ForeverSessionCheck = true,
            -- Beta "world will refresh in N minutes" notice: countdown bar,
            -- 60s/10s warnings, and a log (/ta refreshlog). No tab.
            ForeverWorldRefresh = true,
        },
        tabs      = {
            { id = "character",  label = "Character",  module = "ForeverCharacter" },
            { id = "gear",       label = "Gear",       module = "ForeverGear"      },
            { id = "talents",    label = "Talents",    module = "ForeverTalents"   },
            { id = "spells",     label = "Spells",     module = "ForeverRotation"  },
            { id = "pets",       label = "Pets",       module = "ForeverPets", condition = "hasPetClass" },
            { id = "pvp",        label = "PvP",        module = "ForeverPvP"    },
            { id = "scrolls",    label = "Scrolls",    module = "ForeverScrolls",
              events = { "BAG_UPDATE" } },   -- bag contents ARE this tab
            { id = "casts",      label = "Casts",      module = "ForeverCastLog" },
            { id = "harvest",    label = "Harvest",    module = "DataHarvester" },
        },
        data      = "Forever",
        statRules = "vanilla-trees",
        partial   = true,
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
