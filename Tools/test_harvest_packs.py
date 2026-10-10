#!/usr/bin/env python3
"""Harvest domains and client packs (Docs/SPEC_HARVEST_SENSOR_ARRAY.md, T4).

Packaging (read from the files):
  * ToonAge_Camelot.toc lists the core, Forever's domains and exactly one pack
    (Forever's); no other TOC lists a domain, a pack or the core yet
  * Modules/Forever/DataHarvester.lua is gone and no TOC names it
  * Forever-only probes and rows (R6: Comprehension, scrolls, C_SkillInfo,
    World refresh) live only in Packs/Forever.lua
  * a high-frequency event a domain handles is named in the core file, so
    Tools/gen_event_routes.py keeps routing it to the DataHarvester module

Behaviour (the real core, domains and pack under Lua 5.1, on the mocked
Forever client in Tools/fixtures/harvest_world_forever.lua):
  * Init registers every domain event once; the scans write records; the Copy
    row, probe sections and Full report come out in the pack's order
  * a rescan writes the same record counts (T4's in-game check)
  * one failing domain does not stop the others, and its error still surfaces
  * no pack for this client -> recording stands down, shared probes still run
  * a G3 stand-in provider swaps into Caps and the pack runs unchanged; a
    provider that vetoes a need skips that domain and the report says why
  * hostile client (almost every API absent): nothing throws
  * CATALOG (regression for 2026-10-04 17:23, 85 -> 77): a scan keeps every
    stored rank the session reads blank, adds new ranks, rewrites changed ones,
    never keeps a blank, and hands readers a new table
  * REPAIR: the 8 lost ranks come back once, only if missing, only on 70205
  * TRAINER (option a): a profession visit files under trainerProf, a class
    visit under the class; the incident's 39 misfiled rows move, none dropped

Usage:  python Tools/test_harvest_packs.py [-v]
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


def toc_files(toc):
    out = []
    for ln in read(toc).splitlines():
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        s = s.split("[")[0].strip()
        if s.lower().endswith(".lua"):
            out.append(s.replace("\\", "/"))
    return out


CORE = "Modules/Infrastructure/Harvester.lua"
FOREVER_DOMAINS = ["Character", "Items", "Racials", "Spellbook", "TraitTree", "Trainer"]
DOMAIN_FILES = [f"Modules/Harvest/Domains/{d}.lua" for d in FOREVER_DOMAINS]
PACK = "Modules/Harvest/Packs/Forever.lua"

# ── Packaging ────────────────────────────────────────────────────────────
cam = toc_files("ToonAge_Camelot.toc")
check("Forever TOC lists the core", CORE in cam)
for f in DOMAIN_FILES:
    check(f"Forever TOC lists {f}", f in cam)
check("Forever TOC lists exactly one pack, its own",
      [f for f in cam if f.startswith("Modules/Harvest/Packs/")], [PACK])
check("domains and pack load after the core",
      all(cam.index(f) > cam.index(CORE) for f in DOMAIN_FILES + [PACK]))
check("Forever TOC does not list the legacy talent domain (no GetNumTalentTabs there)",
      "Modules/Harvest/Domains/TalentTrees.lua" in cam, False)
check("the old recorder file is gone", os.path.exists(os.path.join(ROOT, "Modules/Forever/DataHarvester.lua")), False)
for toc in sorted(f for f in os.listdir(ROOT) if f.startswith("ToonAge") and f.endswith(".toc")):
    files = toc_files(toc)
    check(f"{toc} names no Modules/Forever/DataHarvester.lua", "Modules/Forever/DataHarvester.lua" in files, False)
    if toc != "ToonAge_Camelot.toc":
        check(f"{toc} ships the shared probe core", CORE in files)
        check(f"{toc} ships Caps for those probes", "Core/Caps.lua" in files)
        check(f"{toc} ships no harvest domain or pack",
              [f for f in files if f.startswith("Modules/Harvest/")], [])

# R6: Forever-only probes and rows stay in Forever's pack.
shared = [CORE] + DOMAIN_FILES + ["Modules/Harvest/Domains/TalentTrees.lua"]
for marker in ("C_SkillInfo", "Comprehend", "refreshlog", "Scroll tooltips"):
    check(f"'{marker}' appears in no shared harvest file", [f for f in shared if marker in read(f)], [])
    check(f"'{marker}' is in Forever's pack", marker in read(PACK))

# Routed events: gen_event_routes.py routes a high-frequency event to a module
# only when the module's own file names it.
gen = read("Tools/gen_event_routes.py")
HIGH_FREQ = re.findall(r'"([A-Z_]+)"', gen[gen.index("HIGH_FREQ = ["):gen.index("]", gen.index("HIGH_FREQ = ["))])
core_src = read(CORE)
for f in DOMAIN_FILES + ["Modules/Harvest/Domains/TalentTrees.lua"]:
    for ev in HIGH_FREQ:
        if f'"{ev}"' in read(f):
            check(f"{ev} (used by {os.path.basename(f)}) is named in the core, so it stays routed",
                  f'"{ev}"' in core_src)
check("the core registers the DataHarvester module (profile, tab, toggles key on it)",
      'TA:RegisterModule("DataHarvester", H)' in core_src)

# ── Behaviour ────────────────────────────────────────────────────────────
WORLD = read("Tools/fixtures/harvest_world_forever.lua")
LOAD = ["Core/Caps.lua", "Core/Compat/API.lua", "Modules/Infrastructure/HarvestFormat.lua", CORE] + DOMAIN_FILES + [PACK]

SER = r"""
function SER(v, drop)
    if type(v) ~= "table" then return (type(v) == "string") and string.format("%q", v) or tostring(v) end
    local keys = {}
    for k in pairs(v) do if not (drop and drop[k]) then keys[#keys + 1] = k end end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local out = {}
    for _, k in ipairs(keys) do out[#out + 1] = "[" .. tostring(k) .. "]=" .. SER(v[k]) end
    return "{" .. table.concat(out, ",") .. "}"
end
function COUNTS(s)
    local o = {}
    for k, v in pairs(s) do
        if type(v) == "table" and k ~= "client" and k ~= "times" and k ~= "captures" then
            local n = 0
            local function w(t) for _, x in pairs(t) do if type(x) == "table" then w(x) else n = n + 1 end end end
            w(v); o[k] = n
        end
    end
    return o
end
"""

STORE = r"""{ harvest = {
    version = 3, catalogBuild = "70205", trainerFormat = 2,
    client = { flavor = "forever", build = "70205", interface = 16001, channel = "unknown" },
    times = {}, items = {}, spells = {}, talents = {}, chars = {}, racials = {}, talentGeo = {}, counts = {},
    trainer = {},
    catalog = { ["133"] = "Fireball\tRank 1\t1", ["143"] = "Fireball\tRank 2\t6", ["78"] = "Heroic Strike\tRank 1\t1" },
} }"""


def world(store=STORE, extra="", files=LOAD):
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(WORLD)
    L.execute(extra)
    for f in files:
        L.execute(read(f))
    L.execute(SER)
    if store is not None:
        L.execute("ToonAge.db = " + store)
    return L


def lst(L, name):
    t = L.eval(name)
    return [t[i] for i in range(1, len(t) + 1)]


L = world()
L.execute("ToonAge.modules.DataHarvester:Init()")
H = L.eval("ToonAge.modules.DataHarvester")
check("module runs on Forever", H._disabled, None)
events = lst(L, "EVENTS_LOG")
check("every event registered once", len(events), len(set(events)))
check("the recorder's events, as before T4", sorted(events), sorted([
    "LOOT_OPENED", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
    "LEARNED_SPELL_IN_SKILL_LINE", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED",
    "PLAYER_LEVEL_UP", "TRAINER_SHOW", "TRAINER_UPDATE",
    "PLAYER_REGEN_ENABLED", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE"]))
labels = [e.label for e in lst(L, "ToonAge.Harvester:Exports()")]
check("Copy row in the pack's order", labels,
      ["Items", "Spells", "Talents", "Characters", "Racials", "Trainer ranks", "Profession trainers", "Spell catalog"])
check("slash aliases kept (R7)", sorted(H.SlashCommands.keys()), ["catalog", "probe", "report"])

L.execute("ToonAge.modules.DataHarvester:OnEnterWorld(); FLUSH()")
L.execute("ToonAge.modules.DataHarvester:OnEvent('LOOT_OPENED')")
for _ in range(3):
    L.execute("ToonAge.modules.DataHarvester:OnEvent('BAG_UPDATE_DELAYED')")
check("bag events inside the debounce window queue one scan", len(lst(L, "TIMERS")), 1)
L.execute("FLUSH()")
L.execute("ToonAge.modules.DataHarvester:OnEvent('TRAINER_SHOW'); ToonAge.modules.DataHarvester:OnEvent('TRAINER_UPDATE'); FLUSH()")
c = L.eval("COUNTS(ToonAge.db.harvest)")
check("items recorded (equipped, bags, loot; the uncached one skipped)", c["items"], 8)
check("spells recorded (every spellbook entry)", c["spells"], 10)
check("racials recorded from the spellbook", c["racials"], 2)
check("trait-tree nodes recorded", c["talents"], 2)
check("character recorded", c["chars"], 1)
check("class trainer visit filed under the class", c["trainer"], 4)
check("nothing filed under professions from a class visit", c["trainerProf"], None)
check("racial tooltip stored verbatim",
      L.eval("ToonAge.db.harvest.racials['Scourge:Horde:7744']").split("\t")[4],
      "Instant | 2 min cooldown | Will of the Forsaken effect.")

before = L.eval("SER(COUNTS(ToonAge.db.harvest))")
L.execute("WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:RunAll(); FLUSH()")
L.execute("ToonAge.modules.DataHarvester:RunAll(); FLUSH()")
check("a rescan writes the same record counts (T4's check)", L.eval("SER(COUNTS(ToonAge.db.harvest))"), before)
report = lst(L, "WINDOWS_LOG")[0].text
check("report opens with Forever's title and the stamp", report.splitlines()[:2],
      ["ToonAge Forever -- full report",
       "-- client forever · 1.60.1 · build 70205 · interface 16001 · project 18 · channel unknown"])
rescan = report[report.index("== Rescan =="):report.index("catalog")].splitlines()[1:]
check("rescan rows: every running domain's scans, in pack order",
      [r.split()[0] + (" " + r.split()[1] if r.startswith("trait") else "") for r in rescan],
      ["character", "equipped", "bags", "spellbook", "trait tree"])
check("every rescan row ok", all(r.rstrip().endswith("ok") for r in rescan))
check("report dumps the same five sections as before",
      re.findall(r"== Harvest: (\w+) ==", report), ["items", "spells", "talents", "chars", "racials"])
probes = re.findall(r"^== (.+) ==$", report[report.index("== Probes =="):report.index("== Harvest:")], re.M)
check("probe sections in Forever's order", probes,
      ["Probes", "Client", "Professions and skills", "Professions", "Character sheet",
       "Skill lines: C_SkillInfo", "Talent tree geometry", "Spell ranks", "Combat", "Map",
       "Reputation", "Scroll tooltips in your bags"])
check("a missing API probes as 'missing', not an error",
      "UnitDefense(player)  ->  missing" in report)
check("Forever's map probe names the waypoint APIs",
      all(s in report for s in (
          "UnitPosition(player)  ->  ",
          "C_Map.GetWorldPosFromMapPos",
          "C_Map.GetBestMapForUnit(player)",
          "C_Map.GetPlayerMapPosition",
          "GetPlayerMapPosition(player)  ->  ",
          "Texture:SetRotation",
          "IsInInstance()",
      )))
check("scroll probe reads the bag scroll's tooltip", "  2: \"Use: armor up.\"" in report)

# Tab: the renamed scan button cannot be mistaken for the Copy row's button.
L.execute("LAYOUT_LOG = {}; ToonAge.modules.DataHarvester:Render({}, nil)")
lay = lst(L, "LAYOUT_LOG")
check("scan section is 'Catalog scan' with a 'Run catalog scan' button",
      ("SectionHeader|Catalog scan|nil" in lay, "ButtonRow|Run catalog scan|nil" in lay), (True, True))
check("no button named just 'Spell catalog' outside the Copy row",
      [x for x in lay if x.startswith("ButtonRow|") and "Spell catalog" in x and "|Copy:" not in x], [])
check("World refresh row comes from the pack", "ButtonRow|World refresh log|nil" in lay)
check("summary shows profession trainers", any(x.startswith("DataRow|Profession trainers|") for x in lay))

# Another class's saved rows must not read as this character's export.
L.execute(r"""
ToonAge.db.harvest.trainer = { HUNTER = { ["1978"] = "Serpent Sting\tRank 1\t4\tavailable\t1" } }
function UnitClass() return "Rogue", "ROGUE" end
LAYOUT_LOG = {}
WINDOWS_LOG = {}
ToonAge.modules.DataHarvester:Render({}, nil)
ToonAge.modules.DataHarvester:Export("trainer", 1)
function UnitClass() return "Mage", "MAGE", 8 end
""")
lay_rogue = lst(L, "LAYOUT_LOG")
exported = lst(L, "WINDOWS_LOG")[0].text.splitlines()
check("trainer summary counts this class only",
      "DataRow|Trainer ranks (open a class trainer)|not visited yet" in lay_rogue)
check("copy row offers every character's captures beside the current character",
      any(x.startswith("ButtonRow|") and "All characters" in x and x.endswith("|Copy:") for x in lay_rogue))
check("spell catalog still has an all-classes button",
      any(x.startswith("ButtonRow|") and "All catalog classes" in x and x.endswith("|Copy:") for x in lay_rogue))
check("muted label names the saved class that is not this character",
      "Paragraph|Trainer ranks: Showing saved Hunter data|dim" in lay_rogue)
check("the trainer button exports this character's empty capture, not the hunter rows",
      exported[-1], "No trainer data yet for Eramali (Rogue). Open a trainer to record it.")
check("that export starts with this character's source line",
      exported[0], "-- source Eramali · Rogue · level 18 · build 70205 · captured unknown")
check("the hunter rows are not in this character's export",
      "Serpent Sting" not in lst(L, "WINDOWS_LOG")[0].text)

# Export of a section not written yet still opens a stamped window.
L.execute("WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:Export('trainerProf', 1)")
w = lst(L, "WINDOWS_LOG")
check("an empty section's button opens a 0-record window",
      (len(w), w[0].text.splitlines()[0] if w else None), (1, "-- ToonAge harvest · trainerProf · page 1/1 · records 0-0 of 0"))

# ── One failing domain ───────────────────────────────────────────────────
L.execute("""ToonAge.Harvester:Domain('spellbook').ScanSpellbook = function() error('spellbook broke') end
             LEVEL = 19""")
ok_err = L.eval("""(function()
    local ok, err = pcall(ToonAge.modules.DataHarvester.OnEvent, ToonAge.modules.DataHarvester, 'PLAYER_LEVEL_UP')
    return tostring(ok) .. '|' .. tostring(err) end)()""")
check("a failing domain's error still surfaces", ok_err.startswith("false|spellbook: "), True)
check("the domains after it still ran (character re-recorded at 19)",
      L.eval("ToonAge.db.harvest.chars['Player-4618-008D2110']").split("\t")[4], "19")

# ── No pack for this client ──────────────────────────────────────────────
L2 = world(extra="ToonAge.flavor = 'tbc'")
L2.execute("ToonAge.modules.DataHarvester:Init()")
check("no pack for this client: recording stands down, probes stay",
      (L2.eval("ToonAge.modules.DataHarvester._probesOnly"),
       L2.eval("ToonAge.modules.DataHarvester._disabled"),
       len(lst(L2, "EVENTS_LOG"))), (True, None, 0))
L2.execute("PROBE = table.concat(ToonAge.modules.DataHarvester:BuildProbeLines(), '\\n')")
probe_tbc = L2.eval("PROBE")
check("TBC probe report names UnitPosition", "UnitPosition(player)  ->  " in probe_tbc)
check("TBC probe report names GetWorldPosFromMapPos", "C_Map.GetWorldPosFromMapPos" in probe_tbc)
check("TBC probe report names GetBestMapForUnit", "C_Map.GetBestMapForUnit(player)" in probe_tbc)
check("TBC probe report names GetPlayerMapPosition", "C_Map.GetPlayerMapPosition" in probe_tbc)
check("TBC probe report names the legacy global on its own line",
      "GetPlayerMapPosition(player)  ->  " in probe_tbc)
check("TBC probe report names SetRotation", "Texture:SetRotation" in probe_tbc)
check("TBC probe report notes an instance", "IsInInstance()" in probe_tbc)

Lguard = world(extra=r"""
function UnitPosition() return 9, 8, 7, 0 end
function ToonAge:HasAPI(path) return path ~= "UnitPosition" end
""")
Lguard.execute("GUARDED = table.concat(ToonAge.modules.DataHarvester:BuildProbeLines(), '\\n')")
guarded = Lguard.eval("GUARDED")
check("ApiGuard missing refuses UnitPosition even when the global exists",
      "UnitPosition(player)  ->  missing" in guarded)
check("ApiGuard does not sample a refused API", "9, 8, 7, 0" not in guarded)

Linside = world(extra=r"""
function IsInInstance() return true, "party" end
function UnitPosition() return nil end
function CreateFrame()
    return { CreateTexture = function() return { SetRotation = function() end } end }
end
C_Map.GetPlayerMapPosition = function() return { x = 0.5, y = 0.5 } end
C_Map.GetWorldPosFromMapPos = function() return 1, { x = 10, y = 20 } end
""")
Linside.execute("INSIDE = table.concat(ToonAge.modules.DataHarvester:BuildProbeLines(), '\\n')")
inside = Linside.eval("INSIDE")
check("an instance is noted beside UnitPosition",
      "inside an instance; UnitPosition returns nil here" in inside)
check("UnitPosition still reports its sample inside an instance",
      "UnitPosition(player)  ->  nil" in inside)
check("GetWorldPosFromMapPos reports a sample", "x=10" in inside)
check("SetRotation reports present plus a sample",
      "Texture:SetRotation(0)  ->  present, sample ok" in inside)

Lpos = world(extra=r"""
C_Map.GetPlayerMapPosition = nil
function GetPlayerMapPosition(unit) return 0.2, 0.3 end
""")
Lpos.execute("POS = table.concat(ToonAge.modules.DataHarvester:BuildProbeLines(), '\\n')")
pos = Lpos.eval("POS")
check("a missing namespaced position is not filled in from the global",
      "C_Map.GetPlayerMapPosition  ->  missing" in pos)
check("the legacy global has its own sample",
      "GetPlayerMapPosition(player)  ->  0.2, 0.3" in pos)
Lpos.execute("FB_X, FB_Y = ToonAge.Compat.WaypointFn('C_Map.GetPlayerMapPosition')('player')")
check("WaypointFn falls back to the legacy global",
      (Lpos.eval("FB_X"), Lpos.eval("FB_Y")), (0.2, 0.3))
Lpos.execute("C_Map.GetPlayerMapPosition = function() return { x = 1 } end")
check("WaypointFn prefers C_Map.GetPlayerMapPosition when both exist",
      Lpos.eval("type(ToonAge.Compat.WaypointFn('C_Map.GetPlayerMapPosition')(10, 'player'))"), "table")

Lrot = world(extra=r"""
ROT_FRAMES, ROT_TEXTURES = 0, 0
function CreateFrame()
    ROT_FRAMES = ROT_FRAMES + 1
    return { CreateTexture = function()
        ROT_TEXTURES = ROT_TEXTURES + 1
        return { SetRotation = function() end }
    end }
end
""")
Lrot.execute("ToonAge.Compat:ProbeTextureSetRotation(); ToonAge.Compat:ProbeTextureSetRotation()")
check("the rotation probe creates one frame", Lrot.eval("ROT_FRAMES"), 1)
check("the rotation probe creates one texture", Lrot.eval("ROT_TEXTURES"), 1)
check("that frame is kept on the harvester module",
      Lrot.eval("type(ToonAge.modules.DataHarvester._probeRotationFrame)"), "table")
check("that texture is kept on the harvester module",
      Lrot.eval("type(ToonAge.modules.DataHarvester._probeRotationTex)"), "table")

Loutside = world(extra=r"""
function IsInInstance() return false, "none" end
function UnitPosition() return 1, 2, 3, 0 end
""")
Loutside.execute("OUTSIDE = table.concat(ToonAge.modules.DataHarvester:BuildProbeLines(), '\\n')")
outside = Loutside.eval("OUTSIDE")
check("outside an instance the nil warning is absent",
      "inside an instance" not in outside and "IsInInstance()  ->  false" in outside)
check("UnitPosition reports the open-world sample",
      "UnitPosition(player)  ->  1, 2, 3, 0" in outside)

# ── G3 stand-in provider ─────────────────────────────────────────────────
L3 = world()
L3.execute(r"""
G3_ASKED = 0
local real = {}
ToonAge.Caps.SetProvider("g3-stub", function(path)
    G3_ASKED = G3_ASKED + 1
    if path == "C_Traits" then return "missing" end      -- veto one need
    local node = _G
    for seg in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return "missing" end
        node = node[seg]
        if node == nil then return "missing" end
    end
    return "present"
end)
ToonAge.modules.DataHarvester:Init()
ToonAge.modules.DataHarvester:OnEnterWorld(); FLUSH()
WINDOWS_LOG = {}; ToonAge.modules.DataHarvester:RunAll(); FLUSH()
""")
c3 = L3.eval("COUNTS(ToonAge.db.harvest)")
check("under a swapped provider the pack runs unchanged (items, spells recorded)",
      (c3["items"] > 0, c3["spells"] > 0), (True, True))
check("the provider was consulted", L3.eval("G3_ASKED") > 10)
check("a vetoed need skips its domain; the report says which path",
      "traitTree   skipped: missing C_Traits" in lst(L3, "WINDOWS_LOG")[0].text)
check("the skipped domain recorded nothing", c3["talents"], 0)

# ── Hostile client: almost nothing exists ────────────────────────────────
L4 = world(extra="")
L4.execute(r"""
for _, n in ipairs({ "C_Item", "C_Container", "C_SpellBook", "C_Spell", "C_TooltipInfo", "C_Traits",
                     "C_ClassTalents", "GetInventoryItemLink", "GetNumLootItems", "GetNumTrainerServices",
                     "GetProfessions", "C_SkillInfo", "C_Map", "C_AssistedCombat", "UnitGUID", "Enum" }) do _G[n] = nil end
""")
hostile = L4.eval(r"""(function()
    local H = ToonAge.modules.DataHarvester
    local ok, err = pcall(function()
        H:Init(); H:OnEnterWorld(); FLUSH()
        for _, e in ipairs({ "LOOT_OPENED", "BAG_UPDATE_DELAYED", "SPELLS_CHANGED", "TRAIT_CONFIG_UPDATED",
                             "TRAINER_SHOW", "PLAYER_LEVEL_UP" }) do H:OnEvent(e) end
        FLUSH(); H:RunAll(); H:RunProbes(); H:ScanCatalog(); FLUSH()
        for _, e in ipairs(ToonAge.Harvester:Exports()) do H:Export(e.section, 1) end
        H:Render({}, nil)
    end)
    return tostring(ok) .. "|" .. tostring(err) end)()""")
check("hostile client: nothing throws", hostile, "true|nil")
check("hostile client: the catalog says what is missing, in reply to the click",
      any("C_Spell.GetSpellName" in x for x in lst(L4, "CHAT_LOG")))

# ── Catalog: additive (regression for 2026-10-04 17:23) ──────────────────
L5 = world(extra=r"""
SPELL[78]   = { "Heroic Strike", "", 1 }     -- stored ranked; this session reads it blank
SPELL[143]  = { "Fireball", "Rank 2", 7 }    -- stored at level 6; the client now says 7
SPELL[8400] = { "Fireball", "Rank 5", 24 }   -- a rank the store does not have
SPELL[9053] = { "Fireball", "", 20 }         -- an NPC copy: blank, never kept
function GetBuildInfo() return "1.60.2", "70300", "Oct  9 2026", 16001, "", " " end  -- a later build
""", store=STORE.replace('catalogBuild = "70205"', 'catalogBuild = "70100"').replace('build = "70205"', 'build = "70100"'))
L5.execute("ToonAge.modules.DataHarvester:Init(); ToonAge.Harvester:Pack().catalogRanges = { { 1, 10000 } }")
L5.execute("OLD_CATALOG = ToonAge.db.harvest.catalog; ToonAge.modules.DataHarvester:ScanCatalog(); FLUSH()")
cat = L5.eval("ToonAge.db.harvest.catalog")
check("a stored rank this session reads blank is kept", cat["78"], "Heroic Strike\tRank 1\t1")
check("a new rank is added", cat["8400"], "Fireball\tRank 5\t24")
check("a changed rank is rewritten", cat["143"], "Fireball\tRank 2\t7")
check("a blank from this pass is never kept", cat["9053"], None)
check("readers get a new table (the Spells tab's cache rebuilds)",
      L5.eval("ToonAge.db.harvest.catalog ~= OLD_CATALOG"), True)
check("the scan reports what it did, none removed",
      lst(L5, "CHAT_LOG")[-1].endswith("Catalog holds 8 (+5 new, 1 changed, none removed)."))
check("off build 70205 the repair does not run", L5.eval("ToonAge.db.harvest.catalog['100']"), None)
L5.execute("FIRST = ToonAge.db.harvest.times.catalog.last; NOW = NOW + 60; ToonAge.modules.DataHarvester:ScanCatalog(); FLUSH()")
check("a scan that changes nothing does not move the harvest date",
      L5.eval("ToonAge.db.harvest.times.catalog.last == FIRST"), True)

# ── Catalog: load blank spell data, then read it ─────────────────────────
# Rank text is empty until SPELL_DATA_LOAD_RESULT. Requests go out 200 per
# frame. The level is GetSpellLevelLearned or, when that is 0, the trainer row.
Lload = world(extra=r"""
for i = 20000, 21199 do SPELL[i] = { "Bolt" .. i, "", i } end
LOAD_N = 0
BATCHES = {}
LOADS = 0
local realAfter = C_Timer.After
C_Spell.RequestLoadSpellData = function(id)
    LOAD_N = LOAD_N + 1
    LOADS = LOADS + 1
    SPELL[id][2] = "Rank 1"
    ToonAge.modules.DataHarvester:OnEvent("SPELL_DATA_LOAD_RESULT", id, true)
end
C_Timer.After = function(sec, fn)
    if LOAD_N > 0 then BATCHES[#BATCHES + 1] = LOAD_N; LOAD_N = 0 end
    return realAfter(sec, fn)
end
""")
Lload.execute(r"""
ToonAge.modules.DataHarvester:Init()
ToonAge.Harvester:Pack().catalogRanges = { { 20000, 21199 } }
CHAT_LOG = {}
ToonAge.modules.DataHarvester:ScanCatalog()
FLUSH()
if LOAD_N > 0 then BATCHES[#BATCHES + 1] = LOAD_N end
""")
check("blank ids are requested 200 per frame",
      lst(Lload, "BATCHES"), [200, 200, 200, 200, 200, 200])
check("a loaded spell is not asked again", Lload.eval("LOADS"), 1200)
check("the load event fills the rank text",
      Lload.eval("ToonAge.db.harvest.catalog['20000']"), "Bolt20000\tRank 1\t20000")
check("the level is the trained level, not the rank number",
      Lload.eval("ToonAge.db.harvest.catalog['21199']"), "Bolt21199\tRank 1\t21199")
check("progress names how many of the blanks have loaded",
      any("Catalog: 1,200 / 1,200 loaded" in x for x in lst(Lload, "CHAT_LOG")))
check("the pass line counts the ranks the events filled",
      Lload.eval("ToonAge.db.harvest.catalogPasses[1]"), "load: +1200 ranks, 0 still blank")

Llate = world(extra=r"""
SPELL[30001] = { "Timeout Bolt", "", 4 }
SPELL[30002] = { "Late Bolt", "", 8 }
SPELL[30010] = { "Frostbolt", "", 0 }
SPELL[30013] = { "Ghost", "", 6 }
SEEN = {}
C_Spell.RequestLoadSpellData = function(id)
    SEEN[id] = (SEEN[id] or 0) + 1
    if id == 30002 and SEEN[id] == 2 then
        SPELL[id][2] = "Rank 2"
        ToonAge.modules.DataHarvester:OnEvent("SPELL_DATA_LOAD_RESULT", id, true)
    elseif id == 30010 and SEEN[id] == 1 then
        SPELL[id][2] = "Rank 3"
        ToonAge.modules.DataHarvester:OnEvent("SPELL_DATA_LOAD_RESULT", id, true)
    elseif id == 30013 and SEEN[id] == 1 then
        ToonAge.modules.DataHarvester:OnEvent("SPELL_DATA_LOAD_RESULT", id, true)
    end
end
""", store=STORE.replace(
    "trainer = {}",
    'trainer = { MAGE = { ["30010"] = "Frostbolt\\t\\t20\\tunavailable\\t1" } }'))
Llate.execute(r"""
ToonAge.modules.DataHarvester:Init()
ToonAge.Harvester:Pack().catalogRanges = { { 30001, 30013 } }
CHAT_LOG = {}
ToonAge.modules.DataHarvester:ScanCatalog()
FLUSH()
""")
check("a spell that never answers is asked a second time", Llate.eval("SEEN[30001]"), 2)
check("the second request is the only retry", Llate.eval("SEEN[30002]"), 2)
check("a timed-out id is not invented", Llate.eval("ToonAge.db.harvest.catalog['30001']"), None)
check("the retry's load event fills the rank",
      Llate.eval("ToonAge.db.harvest.catalog['30002']"), "Late Bolt\tRank 2\t8")
check("trainer data supplies the level when the spell API does not",
      Llate.eval("ToonAge.db.harvest.catalog['30010']"), "Frostbolt\tRank 3\t20")
check("a loaded spell with no rank text is still not kept",
      Llate.eval("ToonAge.db.harvest.catalog['30013']"), None)
check("progress counts loads, not the ones still waiting",
      any("Catalog: 3 / 4 loaded" in x for x in lst(Llate, "CHAT_LOG")))
passes = lst(Llate, "ToonAge.db.harvest.catalogPasses")
check("the first round and the retry are both recorded",
      passes, ["load: +1 ranks, 2 still blank", "retry: +1 ranks, 1 still blank"])

# ── Repair: the 8 ranks lost 2026-10-04 ──────────────────────────────────
L6 = world()
L6.execute("ToonAge.modules.DataHarvester:Init()")
cat6 = L6.eval("ToonAge.db.harvest.catalog")
LOST = {"78": "Heroic Strike\tRank 1\t1", "100": "Charge\tRank 1\t4", "772": "Rend\tRank 1\t4",
        "1244": "Power Word: Fortitude\tRank 2\t12", "6343": "Thunder Clap\tRank 1\t6",
        "6673": "Battle Shout\tRank 1\t1", "8091": "Armor\tRank 1\t10", "8112": "Spirit\tRank 1\t10"}
check("repair: every lost rank present, verbatim", {k: cat6[k] for k in LOST}, LOST)
check("repair: 7 were missing (78 was still there)", L6.eval("ToonAge.db.harvest.catalogRepair"),
      "2026-10-04 lost ranks: +7")
check("repair: existing ranks untouched", cat6["143"], "Fireball\tRank 2\t6")
L6.execute("ToonAge.db.harvest.catalog['100'] = nil; ToonAge.modules.DataHarvester:Init()")
check("repair runs once", L6.eval("ToonAge.db.harvest.catalog['100']"), None)

# ── Trainer: option (a) ──────────────────────────────────────────────────
L7 = world(extra=r"""
TRAINER = { { "Apprentice Mining", "available", 0, 2575 }, { "Smelt Copper", "available", 0, 2657 },
            { "Smelt Tin", "unavailable", 0, 3304 } }
""")
L7.execute("ToonAge.modules.DataHarvester:Init(); ToonAge.modules.DataHarvester:OnEvent('TRAINER_SHOW'); FLUSH()")
check("a profession visit files under trainerProf, named by its rank row",
      sorted(L7.eval("ToonAge.db.harvest.trainerProf.Mining").keys()), ["2575", "2657", "3304"])
check("and nothing under the class", L7.eval("ToonAge.db.harvest.trainer.MAGE"), None)
check("the status line says so",
      "| profession trainer Mining: services=3 recorded=3" in L7.eval("ToonAge.db.harvest.trainerApi"))

# The incident's shape: a Blacksmithing visit (one rank row at level 1) and a
# Mining visit (all 0) filed under MAGE before T4.
rows = {}
for i in range(23):
    rows[str(5000 + i)] = f"Copper Thing {i}\t\t0\tunavailable\t1791057806"
rows["2018"] = "Apprentice Blacksmith\t\t1\tavailable\t1791057806"
del rows["5022"]
for i in range(15):
    rows[str(6000 + i)] = f"Some Bar {i}\t\t0\tunavailable\t1791057815"
rows["2575"] = "Apprentice Mining\t\t0\tavailable\t1791057815"
rows["133"] = "Fireball\t\t1\tused\t1791000000"
rows["3140"] = "Fireball\t\t18\tavailable\t1791000000"
mage = ", ".join(f'["{k}"] = "{v}"'.replace("\t", "\\t") for k, v in rows.items())
L8 = world(store=STORE.replace("trainer = {},", "trainer = { MAGE = { " + mage + " } },"))
L8.execute("ToonAge.modules.DataHarvester:Init()")
s8 = "ToonAge.db.harvest"
check("migration: the Blacksmithing visit moves whole",
      len(list(L8.eval(f"{s8}.trainerProf.Blacksmith").keys())), 23)
check("migration: the Mining visit moves whole", len(list(L8.eval(f"{s8}.trainerProf.Mining").keys())), 16)
check("migration: the class visit stays", sorted(L8.eval(f"{s8}.trainer.MAGE").keys()), ["133", "3140"])
check("migration: no row lost", L8.eval(f"{s8}.trainerProfFiled") + 2, len(rows))
L8.execute(f"{s8}.trainer.MAGE['9'] = 'X\\t\\t0\\tused\\t1'; ToonAge.modules.DataHarvester:Init()")
check("migration runs once", L8.eval(f"{s8}.trainer.MAGE['9']") is not None)

# ── Legacy talent trees (no TOC lists it until the Era/TBC packs) ────────
L9 = world(extra=r"""
function GetNumTalentTabs() return 1 end
function GetTalentTabInfo(t) return "Fire" end
function GetNumTalents(t) return 2 end
function GetTalentInfo(t, i) return ({ "Improved Fireball", "Impact" })[i], 0, i, 2, 0, 5 end
""", files=["Core/Caps.lua", "Modules/Infrastructure/HarvestFormat.lua", CORE,
            "Modules/Harvest/Domains/TalentTrees.lua"])
L9.execute("""ToonAge.Harvester:RegisterPack{ client = "forever", domains = { "talentTrees" },
                                               exportOrder = { "talents" } }
              ToonAge.modules.DataHarvester:Init(); ToonAge.modules.DataHarvester:OnEnterWorld(); FLUSH()""")
check("legacy talent domain records the tree shape",
      L9.eval("ToonAge.db.harvest.talents['MAGE:1:2']"), "Fire\tImpact\t2\t2\t5")
check("legacy talent domain handles CHARACTER_POINTS_CHANGED",
      "CHARACTER_POINTS_CHANGED" in lst(L9, "EVENTS_LOG"))

passed, total = sum(_res), len(_res)
print(f"[{'PASS' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
