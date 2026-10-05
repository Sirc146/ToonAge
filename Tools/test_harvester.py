#!/usr/bin/env python3
"""The recorder: it must be silent, bounded, honest and shipped only where it has a pack.

No outside source has numbers for Forever, so the client is the only one and
the player is the instrument. That makes the recorder's failure modes specific:
a store that grows without limit eventually corrupts on write and costs weeks of
play; a half-written record poisons the data it exists to collect; and running
where it has no pack would be pure cost.

Since harvest spec T4 (Docs/SPEC_HARVEST_SENSOR_ARRAY.md) the recorder is the
shared core (Modules/Infrastructure/Harvester.lua, still registered as the
DataHarvester module), the domains under Modules/Harvest/Domains/ and one pack
per client under Modules/Harvest/Packs/. Modules/Forever/DataHarvester.lua is
gone; these pins follow the code to its new files. Behaviour is proven by
Tools/test_harvest_packs.py and Tools/test_harvest_store.py.
"""
import sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


core  = read("Modules/Infrastructure/Harvester.lua")
items = read("Modules/Harvest/Domains/Items.lua")
book  = read("Modules/Harvest/Domains/Spellbook.lua")
trait = read("Modules/Harvest/Domains/TraitTree.lua")
legacy = read("Modules/Harvest/Domains/TalentTrees.lua")
trainer = read("Modules/Harvest/Domains/Trainer.lua")
pack  = read("Modules/Harvest/Packs/Forever.lua")
pf    = read("Core/Profile.lua")
domains = [read("Modules/Harvest/Domains/" + f) for f in sorted(os.listdir(os.path.join(ROOT, "Modules/Harvest/Domains")))
           if f.endswith(".lua")]
everything = "\n".join([core, pack] + domains)

# ── Only where it has a pack ─────────────────────────────────────────────
check("the core registers the module as DataHarvester", 'TA:RegisterModule("DataHarvester", H)' in core)
init = core[core.index("function H:Init()"):]
check("Init stands down without this client's pack",
      "if not pack or pack.client ~= TA.flavor then" in init)
check("and disables itself when it does", "self._disabled = true" in init)
check("the stand-down happens before any event registers",
      init.index("pack.client ~= TA.flavor") < init.index("RegisterEvent"))
check("Forever's pack names its client", 'client  = "forever"' in pack)

# ── Bounded ──────────────────────────────────────────────────────────────
check("MAX_ITEMS exists", "local MAX_ITEMS" in items)
check("MAX_SPELLS exists", "local MAX_SPELLS" in book)
check("MAX_TALENTS exists", "local MAX_TALENTS" in trait and "local MAX_TALENTS" in legacy)
check("the cap is enforced on write", "if cap and Size(tbl) >= cap then return false end" in core)
check("a known key is never rewritten", "if tbl[key] ~= nil then return false end" in core)

# ── Honest records ───────────────────────────────────────────────────────
# An item the client has not cached yet returns no name. Writing that record
# would store a permanent blank for an item we will see again in a minute.
check("uncached items are skipped, not half-written", "if not name then return false end" in items)
check("already-known items exit before the expensive read",
      items.index("if s.items[itemID] ~= nil then return false end") < items.index("local name, _, quality"))
check("stat blocks are captured", "GetItemStats" in items)
check("stat keys are sorted for stable records", "table.sort(keys)" in items)
check("tabs are stripped from values", 'v:gsub("[\\t\\r\\n]", " ")' in core)
check("a catalog scan never removes a stored rank (2026-10-04)",
      "for k, line in pairs(s.catalog or {}) do merged[k] = line end" in core)

# ── Guarded, like everything else on this client ─────────────────────────
check("the guarded caller goes through Caps", "function Hv.Try(path, ...)" in core
      and "Caps.Call(path, ...)" in core)
check("modern container API is probed", "C_Container.GetContainerItemLink" in items)
check("legacy container API is kept", 'Try("GetContainerItemLink"' in items)
check("modern spellbook API is probed", "C_SpellBook.GetSpellBookItemInfo" in book)
check("legacy spellbook API is kept", 'Try("GetSpellBookItemInfo"' in book)
check("vanilla talent API is kept", 'Try("GetTalentInfo", tab, i)' in legacy)

# ── Silent ───────────────────────────────────────────────────────────────
# Bag events fire several times per loot; an unthrottled five-bag scan on each
# is a stutter the player feels.
check("bag scans are debounced", 'Hv:Once("items", SCAN_DELAY' in items)
check("the debounce has a delay", "local SCAN_DELAY" in items)
check("one pending call per key", "if self._pending[key] then return end" in core)
# Background recording never writes to chat. Allowed: LOG.OUTPUT replies to a
# button the player just clicked (clear store, run spell catalog, run all), and
# the one debug-gated "recording" line. Anything at INFO/WARN would be the
# harvester talking on its own -- the chatter this guards against.
import re as _re
_raw_levels = _re.findall(r"TA:Raw\(\s*TA\.LOG\.([A-Z]+)", everything)
check("it does not chatter",
      len([lv for lv in _raw_levels if lv != "OUTPUT"]) <= 1
      and everything.count("TA:Raw(") == len(_raw_levels))

# ── Store survives a schema bump ─────────────────────────────────────────
# Since harvest spec T3 the store is the shared core's (TA.db.harvest, v3),
# moved there from TA.db.foreverHarvest. Tools/test_harvest_store.py runs the
# move on a real-shaped store and proves no record is lost.
store = core[core.index("function Hv:Store()"):core.index("function Hv:Clear()")]
check("an older store is backfilled, not reset",
      "for _, k in ipairs(BASE_SECTIONS) do s[k] = s[k] or {} end" in store)
check("the Forever store is moved (same table), not copied or reset",
      "s = old" in store and "db.foreverHarvest = nil" in store)
check("an existing store is never overwritten",
      store.count("db.harvest = s") == 1 and 'if type(s) ~= "table" then' in store)
check("every domain that writes reads the store through the core",
      all("Hv:Store()" in d for d in domains if "s." in d and "Hv:RegisterDomain" in d
          and ("Put(" in d or "s.chars[" in d or "s.racials[" in d or "s.trainer" in d)))
check("the Copy row is built from the core registry", "Hv:Exports()" in core)
check("trainer ranks and the spell catalog have copy buttons (R8)",
      'label = "Trainer ranks"' in trainer and 'entries.catalog = "Spell catalog"' in core)

# ── Clearing is deliberate ───────────────────────────────────────────────
check("clearing takes two clicks", "_confirmClear" in core)

# ── Wiring ───────────────────────────────────────────────────────────────
# Forever's TOC is the ONLY one that ships the recorder (core, domains, pack).
# It rode along in the retail TOCs while Mainline still claimed 16001 and
# Forever could fall through to it; neither is true now. D6 (2026-10-04)
# reverses this for Retail in T9, when Retail gets its own pack; until then
# shipping it there would just be dead weight on every retail player's disk.
check("forever ships the harvester", "DataHarvester    = true," in pf)
check("forever gets a Harvest tab",
      '{ id = "harvest",    label = "Harvest",    module = "DataHarvester" }' in pf)
cam = read("ToonAge_Camelot.toc")
check("Forever's TOC lists the core and its pack",
      "Modules\\Infrastructure\\Harvester.lua" in cam and "Modules\\Harvest\\Packs\\Forever.lua" in cam)
for toc in ("ToonAge.toc", "ToonAge_Mainline.toc"):
    t = read(toc)
    check(f"{toc} does NOT ship it",
          "Modules\\Infrastructure\\Harvester.lua" not in t and "Modules\\Harvest\\" not in t)
# It draws through the shared Layout, so the TOC that ships it needs that.
check("Forever's TOC lists Core\\Layout.lua", "Core\\Layout.lua" in cam)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
