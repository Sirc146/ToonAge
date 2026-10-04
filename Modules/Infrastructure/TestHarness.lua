-- ToonAge/Modules/Infrastructure/TestHarness.lua
-- In-game self-test for ToonAge. Flavor-neutral: ship it in EVERY TOC.
--
-- Targets (one file, runtime-gated):
--   Retail / Midnight 12.x ....... ToonAge_Mainline.toc  (interface 120100/120105/120001)
--   WoW Forever beta ............. ToonAge_Camelot.toc   (interface 16001, WOW_PROJECT_MAINLINE)
--   TBC Anniversary .............. ToonAge_TBC.toc       (interface 20506)
--   Mists of Pandaria Classic .... ToonAge_Mists.toc     (interface 50504)
--   Classic Era / Wrath / Cata ... scaffold TOCs         (11509 / 30405 / 40402)
--
-- Usage
--   /ta test              run every suite
--   /ta test <suite>      env | gate | api | tabs | settings | events | perf | state
--   /ta test <suite> chat also echo FAIL/WARN lines to chat (capped)
--   /ta test list         list suites
--   "Self-test" button    title bar of the main window (dev builds, or /ta debug)
--                         Shift-click = tabs + settings only
--
-- Output
--   * Full report -> the selectable copy window (TA:ShowCopyWindow), colours stripped.
--   * One summary line -> chat.
--   * Plain-text copy -> ToonAgeDB.selfTest (readable in WTF\...\SavedVariables\ToonAge.lua
--     after /reload or logout), so a run can be sent back without copy/paste.
--
-- Design notes
--   * NOT registered through TA:RegisterModule. A registered module is subject to the
--     flavor allow-list in Core/Profile.lua, so on every non-retail client it would be
--     profile-skipped and "/ta test" would answer "not running here". It hooks
--     TA.SlashCommand and TA.InitUI instead, both of which are resolved by method lookup
--     at call time (SlashCmdList calls TA:SlashCommand(msg); OnLogin calls self:InitUI()),
--     so wrapping them here -- at file load, before PLAYER_ENTERING_WORLD -- is enough.
--   * Every test restores what it touches: active tab, lastTab, window visibility,
--     settings-drawer visibility, per-module _errorCount, unknownEvents probe entries.
--   * Mock events use a SAFE list only. Anything that makes a module ACT (loot, bags
--     settling, merchant, quest, gossip, level-up) is excluded, so a test run can never
--     auto-equip, sell, accept or turn in anything.
--   * UI/event/perf suites refuse to run in combat (InCombatLockdown).
--   * Lua 5.1, no goto, no string methods newer than 5.1.

local TA = ToonAge
if not TA then return end

local H = {}
TA.TestHarness = H

-- ── Locals ────────────────────────────────────────────────────────────────
local _G, pairs, ipairs, type, tostring, tonumber, pcall, select, unpack =
      _G, pairs, ipairs, type, tostring, tonumber, pcall, select, unpack
local format, concat, sort, floor = string.format, table.concat, table.sort, math.floor

local ADDON           = "ToonAge"
local MAX_SAVED_LINES = 600
local CHAT_ECHO_MAX   = 15
local PERF_RENDERS    = 3      -- re-renders per tab when measuring leaks (one tab per frame)
local SLOW_RENDER_MS  = 50     -- one noticeable hitch
local FRAME_BUDGET_MS = 16.7   -- one frame at 60 fps

local PASS, FAIL, WARN, SKIP, INFO = "PASS", "FAIL", "WARN", "SKIP", "INFO"
local COLOR = {
    PASS = "FF4AFF7A", FAIL = "FFFF4444", WARN = "FFFF9A1A",
    SKIP = "FF888780", INFO = "FF66BBFF",
}

-- Mirror of Init.lua's local ENGINE_MODULES (never profile-gated).
local ENGINE = { ApiGuard = true, State = true, SkillScan = true, TBCStats = true, ErrorLog = true }

-- Mirror of UI.lua's local DEFAULT_TABS (retail has no profile tab list).
local RETAIL_TABS = {
    { id = "character",   label = "Character",   module = "Character"    },
    { id = "guide",       label = "Guide",       module = "QuestTracker" },
    { id = "gear",        label = "Gear",        module = "Gear"         },
    { id = "talents",     label = "Talents",     module = "Talents"      },
    { id = "rotation",    label = "Rotation",    module = "Rotation"     },
    { id = "delves",      label = "Delves",      module = "Delves"       },
    { id = "weekly",      label = "Weekly",      module = "Weekly"       },
    { id = "professions", label = "Professions", module = "Professions"  },
    { id = "pets",        label = "Pets",        module = "Pets"         },
}

-- Data tables only Data/Retail/*.lua defines (shared names such as Rotations,
-- StatWeights, Spells, Professions are deliberately absent -- TBC/Mists define them too).
local RETAIL_ONLY_DATA = {
    "RotationConditions", "TalentsPvP", "PvPMatchups", "Dungeons",
    "EnchantProfessionMap", "FarmOptimizer", "Talents", "Pets", "Zones",
}

-- Which event SHOULD rebuild each tab. Checked by calling UI:Refresh({[ev]=true})
-- with SetTab stubbed, so nothing is actually rebuilt.
local REFRESH_EXPECT = {
    character   = { "PLAYER_LEVEL_UP", "PLAYER_EQUIPMENT_CHANGED" },
    gear        = { "PLAYER_EQUIPMENT_CHANGED" },
    talents     = { "PLAYER_TALENT_UPDATE" },
    rotation    = { "PLAYER_TALENT_UPDATE" },
    pets        = { "UNIT_PET" },
    guide       = { "QUEST_LOG_UPDATE" },
    delves      = { "PLAYER_EQUIPMENT_CHANGED" },
    weekly      = { "QUEST_TURNED_IN" },
    professions = { "SKILL_LINES_CHANGED" },
    caps        = { "COMBAT_RATING_UPDATE" },
    weapons     = { "SKILL_LINES_CHANGED" },
    racials     = { "PLAYER_LEVEL_UP" },
    scrolls     = { "BAG_UPDATE" },          -- bag contents ARE the tab
    casts       = { "CASTLOG_FIGHT" },       -- pseudo-event CastLog queues after a fight
}
local REFRESH_EXPECT_FLAVOR = {
    forever = { talents = { "TRAIT_CONFIG_UPDATED" }, spells = { "SPELLS_CHANGED" },
                pvp = { "PLAYER_PVP_RANK_CHANGED" } },
    tbc     = { talents = { "CHARACTER_POINTS_CHANGED" }, spells = { "LEARNED_SPELL_IN_TAB" },
                pvp = { "COMBAT_RATING_UPDATE" } },
}

-- Mock events that only make modules READ state. Never add LOOT_*, BAG_UPDATE_DELAYED
-- (AutoEquip / harvester act on it), MERCHANT_*, QUEST_*, GOSSIP_*, PLAYER_LEVEL_UP
-- (XPTracker resets its level timer), CHAT_MSG_*.
local SAFE_EVENTS = {
    { "PLAYER_EQUIPMENT_CHANGED", 16, false },
    { "UNIT_INVENTORY_CHANGED", "player" },
    { "SKILL_LINES_CHANGED" },
    { "PLAYER_TALENT_UPDATE" },
    { "UNIT_PET", "player" },
    { "PLAYER_XP_UPDATE", "player" },
    { "UNIT_STATS", "player" },
    { "SPELLS_CHANGED" },
    { "ZONE_CHANGED_NEW_AREA" },
    { "GET_ITEM_INFO_RECEIVED", 6948, true },   -- 6948 = Hearthstone
}

-- API surface. `need` = space-separated flavors whose shipped code needs it to work
-- (missing there = FAIL). nil = informational probe only.
local API_CHECKS = {
    { "C_Timer.After",                          "all" },
    { "C_Timer.NewTicker",                      "all" },
    { "CreateFrame",                            "all" },
    { "BackdropTemplateMixin",                  "all",          "every panel uses BackdropTemplate" },
    { "UISpecialFrames",                        "all" },
    { "GetProfessions",                         "all",          "Init.lua OnLogin calls it unguarded, before InitModules/InitUI/slash" },
    { "GetProfessionInfo",                      "all" },
    { "PickupContainerItem",                    "tbc mists",    "TBC/Mists AutoEquip call the GLOBAL unguarded" },
    { "EquipCursorItem",                        "tbc mists" },
    { "GetNumTalentTabs",                       "tbc",          "TBC talent trees (TBCUtils)" },
    { "GetTalentTabInfo",                       "tbc" },
    { "GetSpecialization",                      "mists",        "Mists Character/GuideParser" },
    { "GetSpecializationInfo",                  "mists" },
    { "C_ClassTalents.GetActiveConfigID",       "forever",      "Forever Talents tab (C_Traits path)" },
    { "C_Traits.GetConfigInfo",                 "forever" },
    { "C_TooltipInfo.GetHyperlink",             "forever",      "Forever Scrolls tab" },
    { "C_SpellBook.GetNumSpellBookSkillLines",  "forever",      "Forever Spells tab" },
    { "C_Item.GetItemStats",                    "forever",      "Forever Gear totals" },
    { "GetActionInfo",                          "forever",      "Forever Spells tab: lower-rank-on-bar notes" },
    { "C_Spell.GetSpellSubtext",                "forever",      "Forever Spells tab: rank text for bar spells" },
    -- informational
    { "issecretvalue" },
    { "CreateFramePool",                        nil,            "needed for the row-pooling fix" },
    { "EnumerateFrames" },
    { "UpdateAddOnMemoryUsage" },
    { "GetAddOnMemoryUsage" },
    { "C_AddOns.GetAddOnMetadata" },
    { "Settings.RegisterCanvasLayoutCategory" },
    { "Menu.ModifyMenu" },
    { "UIDropDownMenu_AddButton" },
    { "C_AssistedCombat.GetNextCastSpell" },
    { "C_UnitAuras.GetBuffDataByIndex" },
    { "UnitAura" },
    { "GetItemInfoInstant" },
    { "C_Item.GetItemInfoInstant" },
    { "GetSpellInfo" },
    { "C_Spell.GetSpellInfo" },
    { "GetPVPRankInfo" },
    { "UnitPVPRank" },
    { "GetPVPLifetimeStats" },
    { "GetPVPSessionStats" },
    { "C_Container.PickupContainerItem" },
    { "LE_EXPANSION_LEVEL_CURRENT" },
}

-- Settings.lua's module-toggle list (Modules/Infrastructure/Settings.lua ~line 602).
local SETTINGS_TOGGLE_MODULES = {
    "NavHud", "MapPins", "CombatState", "DungeonGear", "TravelRouter",
    "Onboarding", "GearSets", "NameplateObjectives", "TooltipScorer",
}

-- Globals the static scan found this addon writing by accident.
local KNOWN_LEAKS = { "RetryScoring" }

-- ── Run state / output ───────────────────────────────────────────────────
local run   -- { lines = {}, counts = {}, echo = bool, echoed = n }

local function Plain(text)
    return (tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function Line(text)
    run.lines[#run.lines + 1] = text
end

local function Result(status, suite, msg)
    run.counts[status] = (run.counts[status] or 0) + 1
    local text = format("|c%s%-4s|r  %-8s %s", COLOR[status] or COLOR.INFO, status, suite, tostring(msg))
    Line(text)
    if run.echo and (status == FAIL or status == WARN) and run.echoed < CHAT_ECHO_MAX then
        run.echoed = run.echoed + 1
        print("|cFFFFD100[TA test]|r " .. text)
    end
end

-- ── Helpers ──────────────────────────────────────────────────────────────
local function Try(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

--- "C_Traits.GetConfigInfo" / "GetBuildInfo" -> value, absentNamespace
local function Resolve(path)
    local ns, key = path:match("^([%w_]+)%.([%w_]+)$")
    if ns then
        local t = _G[ns]
        if type(t) ~= "table" then return nil, ns end
        return t[key], nil
    end
    return _G[path], nil
end

local function SortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
end

local function Contains(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true end end
    return false
end

local function NeedsFlavor(need, flavor)
    if not need then return false end
    if need == "all" then return true end
    for word in need:gmatch("%S+") do
        if word == flavor then return true end
    end
    return false
end

--- Frames under `f` (children, grandchildren, ...), not counting `f`.
---
--- This replaced a whole-client EnumerateFrames walk, which on Retail 12.1.0
--- (2026-09-28, many addons, 3440x1440) could not finish inside WoW's script
--- time limit on its own -- EnumerateFrames(f) appears to rescan for f on each
--- call. A rebuild discards exactly the descendants of the old content/side
--- panes (RebuildChild pools the pane itself and orphans everything under it),
--- so counting those before each rebuild measures the leak directly and costs
--- a few hundred calls at most.
local function CountDescendants(f)
    if not (f and f.GetChildren) then return 0 end
    local n = 0
    for _, c in ipairs({ f:GetChildren() }) do
        -- Frames Core/Layout.lua pools (_laKind) go back to its pool on the next
        -- rebuild instead of being orphaned, so they are not a leak.
        if not c._laKind then
            n = n + 1 + CountDescendants(c)
        end
    end
    return n
end

--- FontStrings + Textures on f and its non-pooled descendants. A redraw that
--- reuses its regions keeps this flat; one that creates new ones on a pooled
--- pane grows it every render -- the leak the frame counter cannot see
--- (2026-10-03: the Forever portrait sidebar added 5 strings per redraw).
local function CountRegions(f)
    if not (f and f.GetNumRegions) then return 0 end
    local n = f:GetNumRegions() or 0
    for _, c in ipairs({ f:GetChildren() }) do
        if not c._laKind then n = n + CountRegions(c) end
    end
    return n
end

local function AddonMemoryKB()
    if type(UpdateAddOnMemoryUsage) ~= "function" or type(GetAddOnMemoryUsage) ~= "function" then
        return nil
    end
    collectgarbage("collect")
    UpdateAddOnMemoryUsage()
    return GetAddOnMemoryUsage(ADDON)
end

local function Now()
    return (type(debugprofilestop) == "function") and debugprofilestop() or (GetTime() * 1000)
end

--- Hand control back to the client until the next frame. Suites run inside a
--- coroutine that the runner resumes once per frame, so no single execution
--- gets near WoW's per-script time limit ("script ran too long" -- measured on
--- Retail 12.1.0 2026-09-28, where one synchronous run of every suite hit it
--- inside the frame count). Never called from inside a pcall: Lua 5.1 cannot
--- yield across one.
local function Yield()
    if coroutine.running() then coroutine.yield() end
end

local function ProfileTabs()
    return (TA.ProfileTabs and TA:ProfileTabs()) or RETAIL_TABS
end

local function ExpectedRefresh(tabID)
    local fl = REFRESH_EXPECT_FLAVOR[TA.flavor or ""]
    if fl and fl[tabID] then return fl[tabID] end
    return REFRESH_EXPECT[tabID]
end

--- File path from an ApiManifest entry -> registered module name (best effort).
local function ModuleForFile(file)
    if file:find("^Core/") or file:find("^Libs/") then return nil, true end
    local dir, base = file:match("^Modules/([%w_]+)/([%w_]+)%.lua$")
    if not base then return nil end
    if TA.modules[base] then return base end
    if TA.modules[dir .. base] then return dir .. base end   -- Forever/Gear -> ForeverGear
    if base == "Rotation" and TA.modules.ForeverRotation and dir == "Forever" then return "ForeverRotation" end
    return nil
end

--- Why is a tab not available on this client?
local function WhyTabHidden(def)
    local reg = TA:GetRegisteredModule(def.module)
    if not reg then return "module " .. def.module .. " not in this TOC" end
    if reg._profileSkipped then return "profile skipped " .. def.module end
    if reg._disabled then return def.module .. " disabled (" .. (reg._autoDisabled and "auto, errors" or "toggle/safe mode") .. ")" end
    if def.id == "guide" and TA.HasGuideContent and not TA.HasGuideContent() then return "no guide content loaded" end
    if def.condition then return "condition '" .. def.condition .. "' false for this character" end
    if def.id == "pets" and TA.flavor == "retail" then
        return "no pet out, and this class/spec keeps no permanent pet (Retail pets rule)"
    end
    return "unknown"
end

local function FindRenderError(parent)
    if not parent then return nil end
    for _, r in ipairs({ parent:GetRegions() }) do
        if r.GetText then
            local ok, t = pcall(r.GetText, r)
            if ok and type(t) == "string" and t:find("Error rendering", 1, true) then
                return Plain(t):gsub("\n", " ")
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════════
-- SUITES — each receives S(status, message)
-- ══════════════════════════════════════════════════════════════════════════

-- ── env: flavor detection ────────────────────────────────────────────────
local function SuiteEnv(S)
    local version, build, _, iface = GetBuildInfo()
    iface = tonumber(iface)
    local pid = _G.WOW_PROJECT_ID
    S(INFO, format("client %s (%s) interface %s  WOW_PROJECT_ID=%s  LE_EXPANSION_LEVEL_CURRENT=%s",
        tostring(version), tostring(build), tostring(iface), tostring(pid),
        tostring(_G.LE_EXPANSION_LEVEL_CURRENT)))

    if pid == nil then S(FAIL, "WOW_PROJECT_ID is nil -- Environment.lua can only use the TOC fallback")
    else S(PASS, "WOW_PROJECT_ID present") end

    local FLAGS = {
        { "IsRetail", "retail" }, { "IsForever", "forever" }, { "IsTBC", "tbc" },
        { "IsClassicEra", "vanilla" }, { "IsWrath", "wrath" }, { "IsCata", "cata" },
        { "IsMists", "mists" },
    }
    local on = {}
    for _, f in ipairs(FLAGS) do if TA[f[1]] then on[#on + 1] = f end end
    if #on == 1 then
        S(PASS, "exactly one flavor flag set: " .. on[1][1])
        if TA.flavor == on[1][2] then S(PASS, "TA.flavor = '" .. tostring(TA.flavor) .. "' matches its flag")
        else S(FAIL, format("TA.flavor '%s' disagrees with %s", tostring(TA.flavor), on[1][1])) end
    else
        local names = {}
        for _, f in ipairs(on) do names[#names + 1] = f[1] end
        S(FAIL, format("%d flavor flags set (%s) -- expected exactly 1", #on, concat(names, ", ")))
    end

    -- Forever vs Retail share project id 1; interface decides.
    if pid == 1 and iface then
        local want = (iface < 100000) and "forever" or "retail"
        if TA.flavor == want then S(PASS, format("Mainline project split by interface: %d -> %s", iface, want))
        else S(FAIL, format("Mainline project, interface %d should be %s, got %s", iface, want, tostring(TA.flavor))) end
    end

    if TA.flavorSource == "toc-fallback" then
        S(WARN, format("flavor came from the TOC fallback -- add project id %s to Environment.lua PROJECT_IDS", tostring(pid)))
    else
        S(PASS, "flavor detected from project id"
            .. (TA.flavorSource and "" or " (build predates the flavorSource field)"))
    end

    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
    local ok, tocFlavor = Try(getMeta, ADDON, "X-Flavor")
    S(INFO, "loaded TOC declares X-Flavor = " .. tostring(ok and tocFlavor or "?"))
    if TA.TocFlavorMismatch then
        local want, got = TA:TocFlavorMismatch()
        if want then S(FAIL, format("wrong TOC loaded: client is %s, TOC is %s", tostring(want), tostring(got)))
        else S(PASS, "TOC matches client (no silent suffix fallback)") end
    end
    if TA.wrongPackage then S(FAIL, "InitModules halted: wrong build for this client") end

    -- OnLogin has no pcall around it: one throw there leaves no modules, no UI, no /ta.
    if not TA.UI then
        S(FAIL, "TA.UI is nil -- OnLogin aborted (or the dev-build tester lock stopped it)")
    elseif not (SlashCmdList and SlashCmdList.TOONAGE) then
        S(FAIL, "/ta is not registered -- OnLogin aborted before the slash block")
    else
        S(PASS, "OnLogin completed (UI built, /ta registered)")
    end

    local p = TA.GetProfile and TA:GetProfile() or {}
    if p.unknown then
        S(TA.flavor == "wrath" and FAIL or WARN,
          format("no profile for flavor '%s' -- resolves to 'Unknown client'", tostring(TA.flavor)))
    else
        S(PASS, format("profile '%s' (%s)", tostring(p.label),
            p.allowAll and "allowAll" or (p.scaffold and "scaffold") or (p.partial and "partial") or "allow-list"))
    end

    -- Mists is flagged as an old-style talent-TREE client; MoP replaced trees with tier rows.
    if TA.IsClassicFamily and TA.Compat and TA.Compat.HasTalentTabs then
        if TA.Compat.HasTalentTabs() then S(PASS, "IsClassicFamily and the talent-tab API agree")
        else S(WARN, "IsClassicFamily=true but GetNumTalentTabs/GetTalentTabInfo absent -- family flag is wrong for this client") end
    end
end

-- ── gate: dual-gate architecture ─────────────────────────────────────────
-- ── login: G4 isolation, checked on the live client (2026-10-03) ─────────
-- Reads state OnLogin left behind; does not re-run login or throw on purpose
-- (that would write a real entry into the error log).
local function LoginChecks(S)
    if not (SlashCmdList and SlashCmdList.TOONAGE) then
        S(FAIL, "login: /ta handler missing")
    else
        S(PASS, "login: /ta registered")
    end
    if type(TA._LoginStep) ~= "function" then
        S(WARN, "login: TA._LoginStep absent -- this Init.lua predates the isolated login")
    elseif TA._loginFailures then
        S(FAIL, "login: steps failed this session: " .. table.concat(TA._loginFailures, ", "))
    else
        S(PASS, "login: every step completed (isolated login)")
    end
    if TA._dbRecovered then
        S(WARN, "login: saved settings were reset this session; old data in ToonAgeDB._recovered")
    end
end

local function SuiteGate(S)
    LoginChecks(S)
    local p = TA:GetProfile()
    local okCount, names = 0, SortedKeys(TA.modules)
    for _, name in ipairs(names) do
        local mod = TA.modules[name]
        local inProfile = TA:ModuleInProfile(name)
        if not inProfile and not ENGINE[name] then
            if mod._profileSkipped and TA:GetModule(name) == nil then okCount = okCount + 1
            else S(FAIL, name .. " is outside the profile but was initialised / is reachable via GetModule") end
        elseif mod._initError then
            S(FAIL, name .. " Init failed: " .. tostring(mod._initError))
        elseif mod._autoDisabled then
            S(FAIL, format("%s auto-disabled after %d OnEvent errors this session", name, mod._errorCount or 0))
        elseif mod._disabled then
            S(INFO, name .. " off (" .. (mod._safeSkipped and "safe mode" or "user toggle") .. ")")
        else
            okCount = okCount + 1
        end
    end
    S(PASS, format("%d/%d registered modules gated as expected", okCount, #names))

    if not p.allowAll then
        for _, name in ipairs(SortedKeys(p.modules)) do
            if not TA.modules[name] then
                S(WARN, name .. " is in the profile allow-list but no loaded file registers it (TOC gap)")
            end
        end
    end

    -- Retail data must not be resident on other clients.
    if TA.flavor ~= "retail" then
        local leaked = {}
        for _, key in ipairs(RETAIL_ONLY_DATA) do
            if TA.Data and TA.Data[key] ~= nil then leaked[#leaked + 1] = key end
        end
        if #leaked > 0 then S(FAIL, "retail-only data loaded on " .. TA.flavor .. ": " .. concat(leaked, ", "))
        else S(PASS, "no retail-only Data tables resident") end
        local guides = 0
        for _ in pairs(TA.Guides or {}) do guides = guides + 1 end
        S(guides > 0 and TA.flavor ~= "mists" and WARN or PASS, format("%d guide(s) resident", guides))
    end

    -- Second gate: ApiGuard.
    local G = TA:GetRegisteredModule("ApiGuard")
    if not G then S(FAIL, "ApiGuard not loaded") return end
    if not G.hasRun then
        S((p.scaffold or p.partial or p.unknown) and INFO or FAIL,
          "ApiGuard has not probed (no manifest for this flavor?)")
        return
    end
    local missing = G:CountMissing()
    S(missing == 0 and PASS or WARN, format("ApiGuard: %d/%d manifest APIs resolved", G.present, G.checked))

    -- A missing API called from a RUNNING module means the gate did not stop it.
    local shown = 0
    for _, path in ipairs(SortedKeys(G.missing)) do
        local users = {}
        for _, file in ipairs(G.missing[path] or {}) do
            local modName, isCore = ModuleForFile(file)
            if isCore then users[#users + 1] = file
            elseif modName and TA:GetModule(modName) then users[#users + 1] = modName end
        end
        if #users > 0 and shown < 20 then
            shown = shown + 1
            S(WARN, format("%s missing; referenced by running code: %s -- confirm every call site is guarded", path, concat(users, ", ")))
        end
    end
    if missing > 0 and shown == 0 then S(PASS, "every missing API belongs to a module that is not running") end
    if shown >= 20 then S(INFO, "list capped at 20 -- /ta apiprobe has the rest") end
end

-- ── api: surface probes ──────────────────────────────────────────────────
local function SuiteApi(S)
    local flavor = TA.flavor or "unknown"
    local present, absent = {}, {}
    for _, c in ipairs(API_CHECKS) do
        local path, need, note = c[1], c[2], c[3]
        local v = Resolve(path)
        local has = v ~= nil
        if NeedsFlavor(need, flavor) then
            if has then S(PASS, path .. " present" .. (note and (" -- " .. note) or ""))
            else S(FAIL, path .. " MISSING" .. (note and (" -- " .. note) or "")) end
        elseif has then
            present[#present + 1] = (type(v) == "number") and (path .. "=" .. v) or path
        else
            absent[#absent + 1] = path
        end
    end
    if #present > 0 then S(INFO, "present: " .. concat(present, ", ")) end
    if #absent  > 0 then S(INFO, "absent:  " .. concat(absent, ", ")) end

    -- AutoEquip needs some way to pick an item up.
    if TA:GetModule("AutoEquip") then
        local pick = (C_Container and C_Container.PickupContainerItem) or _G.PickupContainerItem
        S(pick and PASS or FAIL, "AutoEquip running; container pickup API " .. (pick and "available" or "MISSING"))
    end

    -- Event-registration guard (TA:RegisterEvent arrived after the 2026-09-21
    -- builds; older installs skip this check instead of crashing the suite).
    local probe = "TOONAGE_SELFTEST_NOT_AN_EVENT"
    local accepted = type(TA.RegisterEvent) == "function" and TA:RegisterEvent(probe)
    if type(TA.RegisterEvent) ~= "function" then
        S(SKIP, "TA:RegisterEvent not in this build (pre-2026-09-22 Init.lua)")
    elseif accepted then
        S(FAIL, "TA:RegisterEvent accepted a bogus event name")
        pcall(TA.eventFrame.UnregisterEvent, TA.eventFrame, probe)
    elseif TA.unknownEvents and TA.unknownEvents[probe] then
        S(PASS, "TA:RegisterEvent absorbs unknown events and records them")
    else
        S(WARN, "TA:RegisterEvent rejected the bogus event but did not record it")
    end
    if TA.unknownEvents then TA.unknownEvents[probe] = nil end

    local unknown = SortedKeys(TA.unknownEvents)
    if #unknown > 0 then S(INFO, "events this client does not define: " .. concat(unknown, ", ")) end

    for _, g in ipairs(KNOWN_LEAKS) do
        if _G[g] ~= nil then S(WARN, "global '" .. g .. "' is set -- ToonAge leaks it (make it local)") end
    end
end

-- ── tabs: UI tab states, render, refresh wiring ──────────────────────────
local function SuiteTabs(S)
    if InCombatLockdown() then S(SKIP, "in combat -- UI tests skipped") return end
    local UI = TA.UI
    if not UI then S(FAIL, "TA.UI missing -- InitUI did not run (check /ta errors)") return end

    local wasShown  = UI:IsShown()
    local prevTab   = UI.activeTab
    local prevLast  = TA.charDB and TA.charDB.lastTab
    if not wasShown then UI:Show() end

    local defs = ProfileTabs()
    local seen, enabledCount = {}, 0
    for _, def in ipairs(defs) do
        Yield()
        if seen[def.id] then S(FAIL, "duplicate tab id '" .. def.id .. "' in profile") end
        seen[def.id] = true

        local label = format("[%s]", def.id)
        if not TA:IsTabAvailable(def.id) then
            S(SKIP, label .. " hidden: " .. WhyTabHidden(def))
        elseif not TA:IsTabEnabled(def.id) then
            S(INFO, label .. " hidden by the player (disabledTabs)")
        else
            enabledCount = enabledCount + 1
            if not UI.tabButtons[def.id] then S(FAIL, label .. " enabled but has no tab button") end

            -- Render.
            local t0 = Now()
            local ok, err = pcall(UI.SetTab, UI, def.id)
            local ms = Now() - t0
            if not ok then
                S(FAIL, label .. " SetTab threw: " .. tostring(err))
            elseif UI.activeTab ~= def.id then
                S(FAIL, format("%s SetTab landed on '%s'", label, tostring(UI.activeTab)))
            else
                local renderErr = FindRenderError(UI.contentChild)
                local h = UI.contentChild and UI.contentChild:GetHeight() or 0
                if renderErr then
                    S(FAIL, label .. " " .. renderErr)
                elseif h <= 20 then
                    S(WARN, format("%s rendered nothing (content height %.0f) -- needs an empty state", label, h))
                else
                    S(PASS, format("%s renders (%.0f px, %.1f ms)", label, h, ms))
                end
            end

            -- Refresh wiring: does the event that changes this tab rebuild it?
            local expect = ExpectedRefresh(def.id)
            if expect and ok then
                local origSetTab, calls = UI.SetTab, 0
                UI.SetTab = function() calls = calls + 1 end
                for _, ev in ipairs(expect) do
                    calls = 0
                    local rok = pcall(UI.Refresh, UI, { [ev] = true })
                    if not rok then S(FAIL, label .. " Refresh threw on " .. ev)
                    elseif calls == 0 then S(FAIL, format("%s does NOT rebuild on %s (event is claimed by another tab and swallowed)", label, ev))
                    else S(PASS, format("%s rebuilds on %s", label, ev)) end
                end
                UI.SetTab = origSetTab
            end

            -- Declared-but-never-registered events (Forever modules' M.Events).
            local mod = TA:GetModule(def.module)
            if mod and type(mod.Events) == "table" then
                local dead = {}
                for _, ev in ipairs(mod.Events) do
                    local rok, isReg = pcall(TA.eventFrame.IsEventRegistered, TA.eventFrame, ev)
                    local unknown = TA.unknownEvents and TA.unknownEvents[ev]
                    if rok and not isReg and not unknown then dead[#dead + 1] = ev end
                end
                if #dead > 0 then
                    S(FAIL, format("%s %s.Events declares %s but nothing registers them", label, def.module, concat(dead, ", ")))
                else
                    S(PASS, format("%s every %s.Events entry is registered", label, def.module))
                end
            end
        end
    end
    if enabledCount == 0 then S(WARN, "no enabled tabs -- window shows the no-content notice") end

    -- Tab bar overflow.
    local barRight = UI.tabBar and UI.tabBar:GetRight()
    if barRight then
        local over = {}
        for id, btn in pairs(UI.tabButtons) do
            local r = btn:GetRight()
            if r and r > barRight + 0.5 then over[#over + 1] = id end
        end
        if #over > 0 then S(FAIL, "tab buttons overflow the tab bar: " .. concat(over, ", "))
        else S(PASS, "all tab buttons fit the tab bar") end
    else
        S(SKIP, "tab bar geometry not resolved")
    end

    -- Esc closes the main window?
    if Contains(UISpecialFrames, "ToonAgeFrame") then S(PASS, "Esc closes the main window")
    else S(WARN, "ToonAgeFrame is not in UISpecialFrames -- Esc does not close it") end

    -- On-screen / scale.
    local l, b, w, h = UI:GetRect()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if l and (l < 0 or b < 0 or l + w > sw + 1 or b + h > sh + 1) then
        S(WARN, format("main window extends off-screen (rect %.0f,%.0f %.0fx%.0f on %.0fx%.0f)", l, b, w, h, sw, sh))
    else
        S(PASS, format("main window on-screen (%.0fx%.0f on %.0fx%.0f, scale %.2f)", w or 0, h or 0, sw, sh, UI:GetEffectiveScale()))
    end

    -- Restore.
    pcall(UI.SetTab, UI, (prevTab and TA:IsTabEnabled(prevTab)) and prevTab or "character")
    if TA.charDB then TA.charDB.lastTab = prevLast end
    if not wasShown then UI:Hide() end
end

-- ── settings: configuration drawer ───────────────────────────────────────
local function SuiteSettings(S)
    if InCombatLockdown() then S(SKIP, "in combat -- UI tests skipped") return end
    local Set = TA:GetModule("Settings")
    if not Set then
        S(FAIL, "no Settings module on this client -- the title-bar gear opens an empty drawer")
    end

    local UI = TA.UI
    local wasMainShown = UI and UI:IsShown()
    if UI and not wasMainShown then UI:Show() end

    local d = TA._settingsDrawer
    local wasOpen = d and d:IsShown()
    if not wasOpen and TA.ToggleSettingsDrawer then
        local ok, err = pcall(TA.ToggleSettingsDrawer, TA)
        if not ok then S(FAIL, "ToggleSettingsDrawer threw: " .. tostring(err)) end
    end
    d = TA._settingsDrawer

    if d and d:IsShown() then
        local h = d.content and d.content:GetHeight() or 0
        if Set and h < 260 then
            S(WARN, format("settings drawer has %.0f px of content -- little beyond Module Health/About on this client", h))
        elseif Set then
            S(PASS, format("settings drawer renders %.0f px of content", h))
        end
        if d.sidebar and not d.sidebar:IsShown() and Set and Set.RenderSidebar then
            S(FAIL, "Quick Actions (Reset All Settings, layout, tracker) render into the drawer's hidden 1x1 sidebar -- unreachable")
        end
        if UI and UI:IsShown() then
            local dTop, mBottom = d:GetTop(), UI:GetBottom()
            if dTop and mBottom and dTop > mBottom + 1 then
                S(WARN, format("settings drawer overlaps the main window by %.0f px (clamped to screen)", dTop - mBottom))
            else
                S(PASS, "settings drawer sits below the main window")
            end
        end
    else
        S(FAIL, "settings drawer did not open")
    end

    -- Toggle rows vanish for disabled modules (Has() uses GetModule, which hides disabled ones).
    local hidden = {}
    for _, name in ipairs(SETTINGS_TOGGLE_MODULES) do
        if TA:GetRegisteredModule(name) and TA.db and TA.db.modules and TA.db.modules[name] == false then
            hidden[#hidden + 1] = name
        end
    end
    if #hidden > 0 then
        S(FAIL, "disabled here, and their toggle rows are now hidden -- only /ta toggle can re-enable: " .. concat(hidden, ", "))
    else
        S(PASS, "no module is stranded off (no toggle row hidden by its own OFF state)")
    end

    local hiddenTabs = {}
    for id, v in pairs((TA.db and TA.db.disabledTabs) or {}) do if v then hiddenTabs[#hiddenTabs + 1] = id end end
    if #hiddenTabs > 0 then
        S(WARN, "tabs hidden via disabledTabs with no reachable UI to restore them: " .. concat(hiddenTabs, ", "))
    end

    local bp = TA._blizzOptionsPanel
    if bp then
        local kids = select("#", bp:GetChildren()) + select("#", bp:GetRegions())
        if kids == 0 then S(WARN, "Esc > Options > AddOns > ToonAge is registered but blank")
        else S(PASS, "Blizzard options page has content") end
    else
        S(INFO, "no Blizzard options page registered")
    end

    -- Restore.
    if not wasOpen and TA._settingsDrawer and TA._settingsDrawer:IsShown() then TA._settingsDrawer:Hide() end
    if UI and not wasMainShown then UI:Hide() end
end

-- ── events: mock dispatch through the real funnel ────────────────────────
local function SuiteEvents(S)
    if InCombatLockdown() then S(SKIP, "in combat -- mock events skipped") return end
    local EL = TA.ErrorLog

    for _, spec in ipairs(SAFE_EVENTS) do
        local ev = spec[1]
        local args = { select(2, unpack(spec)) }
        local nargs = #spec - 1

        local before = {}
        for name, mod in pairs(TA.modules) do
            before[name] = { mod._errorCount or 0, mod._disabled, mod._autoDisabled }
        end
        local logBefore = EL and EL.GetCount and EL:GetCount() or 0

        if TA.State and TA.State.Invalidate then pcall(TA.State.Invalidate, TA.State, ev) end
        local ok, err = pcall(TA.UpdateModules, TA, ev, unpack(args, 1, nargs))

        local failed = {}
        for name, mod in pairs(TA.modules) do
            local b = before[name]
            if b and (mod._errorCount or 0) > b[1] then
                failed[#failed + 1] = name
                -- Mock errors must not count toward the 10-error auto-disable.
                mod._errorCount, mod._disabled, mod._autoDisabled = b[1], b[2], b[3]
            end
        end
        sort(failed)

        if not ok then
            S(FAIL, ev .. " dispatch threw: " .. tostring(err))
        elseif #failed > 0 then
            local detail = ""
            if EL and EL.GetLog then
                local log = EL:GetLog() or {}
                local last = log[#log]
                if last then detail = " -- " .. Plain(tostring(last.msg or last.message or "")) end
            end
            S(FAIL, format("%s -> OnEvent error in %s%s", ev, concat(failed, ", "), detail))
        else
            S(PASS, ev .. " dispatched cleanly")
        end
    end

    -- Coalescer: two queued refreshes -> one pending flush.
    local UI = TA.UI
    local wasShown = UI and UI:IsShown()
    if UI and not wasShown then UI:Show() end
    if UI and UI:IsVisible() and TA.QueueUIRefresh then
        TA:QueueUIRefresh("TOONAGE_SELFTEST")
        TA:QueueUIRefresh("TOONAGE_SELFTEST")
        if TA._uiRefreshQueued and TA._pendingUIEvents and TA._pendingUIEvents.TOONAGE_SELFTEST then
            S(PASS, "UI refresh coalescer queued once (flushes in ~0.15 s)")
        else
            S(WARN, "UI refresh coalescer did not queue")
        end
    else
        S(SKIP, "coalescer check needs the main window")
    end
    if UI and not wasShown then UI:Hide() end   -- the queued flush drops itself when hidden
end

-- ── perf: render cost and frame leaks per tab ────────────────────────────
local function SuitePerf(S)
    if InCombatLockdown() then S(SKIP, "in combat -- perf skipped") return end
    local UI = TA.UI
    if not UI then S(FAIL, "TA.UI missing") return end
    local wasShown, prevTab = UI:IsShown(), UI.activeTab
    local prevLast = TA.charDB and TA.charDB.lastTab
    if not wasShown then UI:Show() end
    local memStart = AddonMemoryKB()   -- full GC: its own frame, before and after

    for _, def in ipairs(ProfileTabs()) do
        Yield()
        if TA:IsTabEnabled(def.id) then
            pcall(UI.SetTab, UI, def.id)                 -- warm (first render allocates caches)
            local discarded, worst, total = 0, 0, 0
            -- Region growth, per pane frame: panes are pooled, so the same
            -- frame comes back; its region count must not climb between visits.
            local firstSeen, lastSeen = {}, {}
            local function NoteRegions()
                for _, f in ipairs({ UI.contentChild, UI.sideChild }) do
                    if f then
                        local n = CountRegions(f)
                        if firstSeen[f] == nil then firstSeen[f] = n end
                        lastSeen[f] = n
                    end
                end
            end
            NoteRegions()
            for _ = 1, PERF_RENDERS do
                -- Everything under the current panes is thrown away by the rebuild.
                discarded = discarded + CountDescendants(UI.contentChild) + CountDescendants(UI.sideChild)
                local t0 = Now()
                pcall(UI.SetTab, UI, def.id)
                local ms = Now() - t0
                total = total + ms
                if ms > worst then worst = ms end
                NoteRegions()
            end
            local grown = 0
            for f, n in pairs(lastSeen) do grown = grown + math.max(0, n - firstSeen[f]) end
            if grown > 0 then
                S(WARN, format("[%s] %d text/texture regions added across %d re-renders "
                    .. "(created per redraw on a pooled pane -- reuse them)", def.id, grown, PERF_RENDERS))
            end
            local leaked = discarded / PERF_RENDERS
            local avg = total / PERF_RENDERS
            local status = PASS
            if leaked > 0 or worst > SLOW_RENDER_MS then status = WARN end
            S(status, format("[%s] avg %.1f ms, worst %.1f ms%s, %.1f frames discarded per re-render%s",
                def.id, avg, worst, (worst > FRAME_BUDGET_MS) and " (>1 frame)" or "",
                leaked, (leaked > 0) and " (orphaned, never freed: pool rows instead)" or ""))
        end
    end

    if TA.Layout and TA.Layout.PoolStats then
        local parts = {}
        for kind, n in pairs(TA.Layout:PoolStats()) do parts[#parts + 1] = kind .. "=" .. n end
        sort(parts)
        S(INFO, "Layout pools (free, reusable): " .. (#parts > 0 and concat(parts, ", ") or "none yet"))
    end

    Yield()
    local memEnd = AddonMemoryKB()
    if memStart and memEnd then
        S(INFO, format("ToonAge memory %.0f KB -> %.0f KB across the perf run (%+.0f KB)", memStart, memEnd, memEnd - memStart))
    end

    pcall(UI.SetTab, UI, (prevTab and TA:IsTabEnabled(prevTab)) and prevTab or "character")
    if TA.charDB then TA.charDB.lastTab = prevLast end
    if not wasShown then UI:Hide() end
end

-- ── state: SavedVariables sanity ─────────────────────────────────────────
local function SuiteState(S)
    if type(ToonAgeDB) ~= "table" then S(FAIL, "ToonAgeDB missing") return end
    if TA.db == ToonAgeDB then S(PASS, "TA.db is the live ToonAgeDB table")
    else S(FAIL, "TA.db is NOT ToonAgeDB -- writes go to an orphan table (reset without reload?)") end

    if TA.charDB then S(PASS, "charDB present for " .. tostring(TA.charKey))
    else S(FAIL, "TA.charDB missing") end

    S(type(TA.db.schemaVersion) == "number" and PASS or WARN,
      "account schemaVersion = " .. tostring(TA.db.schemaVersion))

    local lvl = TA.db.logLevel
    S((type(lvl) == "number" and lvl >= 1 and lvl <= 4) and PASS or WARN, "logLevel = " .. tostring(lvl))

    if TA.db.safeMode then S(WARN, "Safe Mode is ON -- most modules skipped") end

    local valid = {}
    for _, def in ipairs(ProfileTabs()) do valid[def.id] = true end
    local stale = {}
    for id in pairs(TA.db.disabledTabs or {}) do if not valid[id] then stale[#stale + 1] = id end end
    if #stale > 0 then S(INFO, "disabledTabs entries for tabs this client doesn't ship: " .. concat(stale, ", ")) end

    local last = TA.charDB and TA.charDB.lastTab
    if last and not valid[last] then S(WARN, "lastTab '" .. tostring(last) .. "' is not a tab on this client")
    else S(PASS, "lastTab = " .. tostring(last)) end

    local EL = TA.ErrorLog
    if EL and EL.GetCount then
        local n = EL:GetCount()
        S(n == 0 and PASS or WARN, format("%d entr%s in the error log (/ta errors copy)", n, n == 1 and "y" or "ies"))

        -- Grouped by source, newest message per group, so a full log (200 is the
        -- cap) reads as a handful of causes instead of a wall of repeats.
        if n > 0 and EL.GetLog then
            local groups, order = {}, {}
            for _, e in ipairs(EL:GetLog() or {}) do
                local src = tostring(e.source or "?")
                local g = groups[src]
                if not g then
                    g = { source = src, count = 0 }
                    groups[src] = g
                    order[#order + 1] = g
                end
                g.count = g.count + 1
                g.last  = e
            end
            sort(order, function(a, b) return a.count > b.count end)
            for i = 1, math.min(#order, 10) do
                local g = order[i]
                local msg = Plain(tostring(g.last.msg or "")):gsub("\n", " ")
                if #msg > 160 then msg = msg:sub(1, 157) .. "..." end
                S(INFO, format("errors: %dx %s -- last %s: %s", g.count, g.source,
                    tostring(g.last.time or "?"), msg))
            end
            if #order > 10 then S(INFO, format("errors: %d more sources", #order - 10)) end
        end
    end
end

-- ── Registry ─────────────────────────────────────────────────────────────
local SUITES = {
    { id = "env",      title = "Flavor detection",          fn = SuiteEnv      },
    { id = "gate",     title = "Dual gate (TOC + profile + ApiGuard)", fn = SuiteGate },
    { id = "api",      title = "API surface",               fn = SuiteApi      },
    { id = "state",    title = "SavedVariables",            fn = SuiteState    },
    { id = "events",   title = "Mock events",               fn = SuiteEvents   },
    { id = "tabs",     title = "Tabs: state, render, refresh", fn = SuiteTabs  },
    { id = "settings", title = "Settings drawer",           fn = SuiteSettings },
    { id = "perf",     title = "Render cost and frame leaks", fn = SuitePerf   },
}

-- ══════════════════════════════════════════════════════════════════════════
-- RUNNER
-- ══════════════════════════════════════════════════════════════════════════
function H:Run(arg)
    if run then print("|cFFFFD100[ToonAge]|r self-test already running") return end

    local words = {}
    for w in tostring(arg or ""):lower():gmatch("%S+") do words[#words + 1] = w end
    local echo = Contains(words, "chat")
    local want = {}
    for _, w in ipairs(words) do if w ~= "chat" and w ~= "all" then want[#want + 1] = w end end

    if want[1] == "list" or want[1] == "help" then
        print("|cFFFFD100[ToonAge]|r /ta test [suite ...] [chat]  --  suites:")
        for _, s in ipairs(SUITES) do print(format("   |cFFFFD100%-9s|r %s", s.id, s.title)) end
        return
    end

    local selected = {}
    if #want == 0 then
        selected = SUITES
    else
        for _, w in ipairs(want) do
            local found
            for _, s in ipairs(SUITES) do if s.id == w then found = s end end
            if found then selected[#selected + 1] = found
            else print("|cFFFF4444[ToonAge]|r unknown suite '" .. w .. "' -- /ta test list") return end
        end
    end

    run = { lines = {}, counts = {}, echo = echo, echoed = 0 }
    local version, build = GetBuildInfo()
    local stamp = date and date("%Y-%m-%d %H:%M:%S") or tostring(GetTime())
    Line(format("ToonAge self-test  v%s  flavor=%s  client %s (%s)  %s",
        tostring(TA.version), tostring(TA.flavor), tostring(version), tostring(build), stamp))

    print("|cFFFFD100[ToonAge]|r Self-test running -- the report opens when it finishes (a few seconds).")

    -- One suite per coroutine, resumed once per frame. coroutine.resume is the
    -- error boundary (a crash returns false, err), which is what lets suites
    -- yield -- a pcall around them would make yielding impossible in Lua 5.1.
    local idx, co, current = 0, nil, nil
    local function Step()
        if not co then
            idx = idx + 1
            current = selected[idx]
            if not current then return H:_Finish(stamp, build) end
            Line("")
            Line("|cFFFFD100== " .. current.title .. " ==|r")
            local suite = current
            co = coroutine.create(function()
                suite.fn(function(status, msg) Result(status, suite.id, msg) end)
            end)
        end
        local ok, err = coroutine.resume(co)
        if not ok then
            Result(FAIL, current.id, "suite crashed: " .. tostring(err))
            co = nil
        elseif coroutine.status(co) == "dead" then
            co = nil
        end
        C_Timer.After(0, Step)
    end
    C_Timer.After(0, Step)
end

function H:_Finish(stamp, build)
    local c = run.counts
    local summary = format("%d pass · %d fail · %d warn · %d skip · %d info",
        c.PASS or 0, c.FAIL or 0, c.WARN or 0, c.SKIP or 0, c.INFO or 0)
    Line("")
    Line("RESULT: " .. summary)

    -- Persist a plain copy for offline reading.
    if TA.db then
        local plain = {}
        for i = 1, math.min(#run.lines, MAX_SAVED_LINES) do plain[i] = Plain(run.lines[i]) end
        TA.db.selfTest = {
            at = stamp, flavor = TA.flavor, build = build, version = TA.version,
            counts = { pass = c.PASS or 0, fail = c.FAIL or 0, warn = c.WARN or 0, skip = c.SKIP or 0 },
            lines = plain,
        }
    end

    local lines = run.lines
    run = nil

    if TA.ShowCopyWindow then
        TA:ShowCopyWindow("ToonAge Self-Test", concat(lines, "\n"))
    else
        for _, l in ipairs(lines) do print(l) end
    end
    local colour = ((c.FAIL or 0) > 0 and "FFFF4444") or ((c.WARN or 0) > 0 and "FFFF9A1A") or "FF4AFF7A"
    print(format("|cFFFFD100[ToonAge]|r Self-test: |c%s%s|r -- full report in the copy window; also saved to ToonAgeDB.selfTest.",
        colour, summary))
end

-- ══════════════════════════════════════════════════════════════════════════
-- HOOKS (installed at file load, before PLAYER_ENTERING_WORLD)
-- ══════════════════════════════════════════════════════════════════════════

-- /ta test ... and /toonage test ... (both route through TA:SlashCommand).
local origSlash = TA.SlashCommand
if type(origSlash) == "function" then
    TA.SlashCommand = function(self, msg)
        local cmd, rest = tostring(msg or ""):match("^%s*(%S+)%s*(.-)%s*$")
        if cmd and cmd:lower() == "test" then
            return H:Run(rest)
        end
        return origSlash(self, msg)
    end
end

-- Let prefix/fuzzy matching and /ta help know the command exists.
local origNames = TA.GetAllCommandNames
if type(origNames) == "function" then
    TA.GetAllCommandNames = function(self, ...)
        local names = origNames(self, ...)
        if type(names) == "table" and not Contains(names, "test") then names[#names + 1] = "test" end
        return names
    end
end

-- And a clickable entry in the SYSTEM block of /ta help.
TA.extraSystemCommands = TA.extraSystemCommands or {}
table.insert(TA.extraSystemCommands, { name = "test", label = "Self-test" })

-- Title-bar button (dev builds, or when /ta debug is on at login).
local function AddTitleButton()
    local UI = TA.UI
    if not UI or H.button then return end
    local isDev = type(TA.version) == "string" and TA.version:find("%-dev") ~= nil
    if not (isDev or TA.debug) then return end

    local b = CreateFrame("Button", "ToonAgeSelfTestButton", UI, "BackdropTemplate")
    b:SetSize(64, 18)
    -- Right of the "ToonAge" title text (icon 10..28, label from x=34, ~60 px wide).
    b:SetPoint("TOPLEFT", UI, "TOPLEFT", 104, -8)
    b:SetFrameLevel(UI:GetFrameLevel() + 10)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    b:SetBackdropColor(0.10, 0.10, 0.12, 1)
    b:SetBackdropBorderColor(0.40, 0.75, 1.00, 0.6)

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    fs:SetText("Self-test")
    fs:SetTextColor(0.62, 0.59, 0.55, 1)
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")

    b:SetScript("OnEnter", function(self)
        fs:SetTextColor(0.92, 0.90, 0.87, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("ToonAge self-test", 1, 0.82, 0)
        GameTooltip:AddLine("Click: every suite", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-click: tabs + settings only", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Same as /ta test", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        fs:SetTextColor(0.62, 0.59, 0.55, 1)
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function()
        if IsShiftKeyDown() then H:Run("tabs settings") else H:Run() end
    end)
    H.button = b
end

-- Fallback command that does not depend on OnLogin finishing: /ta is registered at
-- the END of OnLogin, so any throw before it (InitUI, InitMinimap, ApplyLayout, the
-- profession snapshot) leaves no way in. /tatest is registered at file load.
-- Guarded: SlashCmdList always exists in the game, but the offline boot suites
-- (Tools/test_tbc_boot.py) load every TOC file without it.
if type(SlashCmdList) == "table" then
    SLASH_TOONAGETEST1 = "/tatest"
    SlashCmdList.TOONAGETEST = function(msg) H:Run(msg) end
end

local origInitUI = TA.InitUI
if type(origInitUI) == "function" then
    TA.InitUI = function(self, ...)
        origInitUI(self, ...)          -- errors propagate exactly as before
        pcall(AddTitleButton)
    end
end

return H
