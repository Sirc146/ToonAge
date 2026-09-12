-- ToonAge/Core/Environment.lua (Anniversary — TBC Classic / Interface 20506)
-- Runtime engine detection, replacing the hardcoded flavor booleans that used
-- to live in Core/Init.lua.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════
--
-- Added 2026-09-10 as the first step toward the multi-TOC pattern requested
-- by the user (one repo, one release, a separate .toc per game flavor —
-- AddonName_TBC.toc, AddonName_Cata.toc, AddonName_Mainline.toc, etc., each
-- parsed and loaded ONLY by the matching client). Before this file, Init.lua
-- hardcoded `TA.isClassic = true`, `TA.isTBC = true`, `TA.flavor =
-- "anniversary"` as literal booleans/strings — correct today because this
-- build only ever runs on one flavor, but it meant the addon could never
-- tell what client it was actually running on. This file replaces that with
-- real detection so the same Core/Utils.lua, Core/TBCStats.lua etc. could
-- one day be shared across a Vanilla/TBC/Wrath/Cata/Mists/Retail split
-- without every file needing its own guess.
--
-- IMPORTANT — what this file does NOT do: it does not make ToonAge run on
-- Retail or Cataclysm/Mists Classic today. TOC\## Interface is still 20506
-- and ToonAge.toc still only lists TBC-era files. Detection alone is inert
-- until (a) sibling .toc files exist for the other flavors and (b) this
-- addon's actual game-design DATA exists for them — see the header note
-- below on why that second part is the real work, not a shim.
--
-- ══════════════════════════════════════════════════════════════════════════
-- ── THE MULTI-TOC PATTERN WORKS FOR APIS. IT DOES NOT WORK FOR GAME RULES. ──
-- ══════════════════════════════════════════════════════════════════════════
--
-- The multi-TOC + Compat-shim pattern (as used by UI addons like ElvUI/
-- WeakAuras) papers over API *surface* differences: Retail's C_Container vs.
-- Classic's global GetContainerNumSlots, C_Spell vs. GetSpellInfo, and so on.
-- A shim function like the example in the architecture request works because
-- both APIs describe the SAME underlying game concept (a bag slot count) —
-- only the calling convention changed.
--
-- ToonAge's actual value is not a UI layer sitting on top of API differences.
-- It IS game-design data: TBC's specific 3-tree/61-point talent system with
-- its specific hit/expertise caps (Core/TBCStats.lua, Data/TBCWeights.lua,
-- Data/TBCTalentBuilds.lua, Data/TBCRotations.lua, Data/TBCPvP.lua,
-- Data/TBCProfessions.lua, Data/TBCArmor.lua, Data/TBCRaces.lua,
-- Data/TBCTalentHit.lua). Those rules are not a Retail/Classic API
-- difference to shim around — Retail has no GetTalentTabInfo, no hit rating,
-- and an entirely different (post-Dragonflight) talent-loadout system, and
-- Cataclysm/Mists Classic use the OLD-style tree UI but with different
-- trees, different point totals, and different caps than TBC. There is no
-- function that can return "the right answer" for all of them — each
-- flavor's Data/*.lua would have to be independently researched and written,
-- the same way Data/TBCTalentBuilds.lua was for this one.
--
-- Net: this file is real, useful, and safe to add today. Building actual
-- Wrath/Cata/Mists/Retail *content* on top of it is a separate, much larger
-- research project per flavor — not turned on by adding this file.
--
-- ══════════════════════════════════════════════════════════════════════════

local TA = ToonAge or {}
ToonAge = TA

-- ─── PROJECT ID CONSTANTS ─────────────────────────────────────────────────
-- Blizzard's WOW_PROJECT_* globals, current as of the 2026 client line.
-- Verified 2026-09-10 against Warcraft Wiki's WOW_PROJECT_ID reference page
-- (not assumed from memory, since a wrong value here would silently
-- misdetect the flavor on any future client this addon is loaded on).
--
--   WOW_PROJECT_MAINLINE                = 1   Retail (The War Within / Midnight)
--   WOW_PROJECT_CLASSIC                 = 2   Classic Era ("Vanilla" / Hardcore / Fresh)
--   WOW_PROJECT_WOWLABS                 = 3   Plunderstorm and similar WoW Labs modes
--   WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5   TBC Classic & TBC Anniversary  <-- this build
--   WOW_PROJECT_WRATH_CLASSIC           = 11  Wrath Classic
--   WOW_PROJECT_CATACLYSM_CLASSIC       = 14  Cataclysm Classic
--   WOW_PROJECT_MISTS_CLASSIC           = 19  Mists of Pandaria Classic
--
-- Historical gotcha (does not apply to this Anniversary client, noted for
-- when/if a Vanilla-flavor TOC is ever added): the ORIGINAL 2021 Burning
-- Crusade Classic client shipped before WOW_PROJECT_BURNING_CRUSADE_CLASSIC
-- existed and reported WOW_PROJECT_ID == WOW_PROJECT_CLASSIC (2) like
-- vanilla Classic, requiring an Interface-number fallback check to tell them
-- apart. The current Anniversary client reports the real, distinct value
-- (5), so this build trusts WOW_PROJECT_ID directly rather than carrying
-- that workaround — but the fallback is included below, inert, in case this
-- addon is ever loaded on an old client build that predates the fix.

local PROJECT_IDS = {
    MAINLINE = 1,
    CLASSIC_ERA = 2,      -- "Vanilla" / Hardcore / Fresh
    WOWLABS = 3,
    TBC = 5,
    WRATH = 11,
    CATA = 14,
    MISTS = 19,
}
TA.ProjectIDs = PROJECT_IDS

-- ─── DETECTION ────────────────────────────────────────────────────────────

local projectId = WOW_PROJECT_ID
local interfaceCode = select(4, GetBuildInfo())

TA.IsRetail     = (projectId == PROJECT_IDS.MAINLINE)
TA.IsClassicEra = (projectId == PROJECT_IDS.CLASSIC_ERA and interfaceCode and interfaceCode < 20000)
TA.IsTBC        = (projectId == PROJECT_IDS.TBC)
    -- Fallback for the old-client gotcha described above: some TBC build
    -- reports Classic Era's project ID but a TBC-range interface number.
    or (projectId == PROJECT_IDS.CLASSIC_ERA and interfaceCode and interfaceCode >= 20000 and interfaceCode < 30000)
TA.IsWrath      = (projectId == PROJECT_IDS.WRATH)
TA.IsCata       = (projectId == PROJECT_IDS.CATA)
TA.IsMists      = (projectId == PROJECT_IDS.MISTS)

-- Convenience group: "old-style talent tree" flavors, i.e. everything this
-- addon's Data/TBC*.lua schema shape (tree/points/GetTalentTabInfo) could
-- ever plausibly extend to, as opposed to Retail's unrelated system.
TA.IsClassicFamily = TA.IsClassicEra or TA.IsTBC or TA.IsWrath or TA.IsCata or TA.IsMists

-- ─── BACKWARD-COMPATIBLE ALIASES ──────────────────────────────────────────
-- Core/Init.lua used to hardcode these four as literals. Kept as the same
-- field names so nothing else in the codebase needs to change, now sourced
-- from real detection instead of an assumption.
TA.isClassic = TA.IsClassicFamily
TA.isTBC     = TA.IsTBC
TA.flavor    = TA.IsTBC and "anniversary"
    or TA.IsClassicEra and "classic-era"
    or TA.IsWrath and "wrath"
    or TA.IsCata and "cata"
    or TA.IsMists and "mists"
    or TA.IsRetail and "retail"
    or "unknown"
TA.interfaceCode = interfaceCode

-- ─── GUARD RAIL ───────────────────────────────────────────────────────────
-- This build's Data/*.lua is TBC-only. If this file is ever loaded on a
-- flavor it wasn't written for (e.g. copied into a _classic_ or _retail_
-- AddOns folder by hand, bypassing the TOC system entirely), say so loudly
-- once instead of silently producing wrong talent/hit-cap advice.
if not TA.IsTBC then
    local flavorName = TA.flavor
    TA.eventFrame = TA.eventFrame or CreateFrame("Frame")
    TA.eventFrame:RegisterEvent("PLAYER_LOGIN")
    TA.eventFrame:HookScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            print("|cFFFF4444[ToonAge]|r This build's talent/stat-cap data is TBC Classic only, "
                .. "but you're running on '" .. tostring(flavorName) .. "'. Advice on every tab will "
                .. "be wrong for this expansion until a matching Data set exists for it.")
        end
    end)
end
