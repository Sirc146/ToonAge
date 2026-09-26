#!/usr/bin/env python3
"""The Forever recorder: it must be silent, bounded, honest and Forever-only.

No outside source has numbers for this client, so the client is the only one
and the player is the instrument. That makes this module's failure modes
specific: a store that grows without limit eventually corrupts on write and
costs weeks of play; a half-written record poisons the data it exists to
collect; and running on Retail would be pure cost, since Retail already has
researched data.
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


h  = read("Modules/Forever/DataHarvester.lua")
pf = read("Core/Profile.lua")

# ── Forever only ─────────────────────────────────────────────────────────
check("it registers as DataHarvester", 'TA:RegisterModule("DataHarvester", H)' in h)
init = h[h.index("function H:Init()"):]
check("Init stands down off Forever", "if not TA.IsForever then" in init)
check("and disables itself when it does", "self._disabled = true" in init)
check("the stand-down happens before any event registers",
      init.index("TA.IsForever") < init.index("RegisterEvent"))

# ── Bounded ──────────────────────────────────────────────────────────────
for cap in ("MAX_ITEMS", "MAX_SPELLS", "MAX_TALENTS"):
    check(f"{cap} exists", f"local {cap}" in h)
check("the cap is enforced on write", "if cap and Count(tbl) >= cap then return false end" in h)
check("a known key is never rewritten", "if tbl[key] ~= nil then return false end" in h)

# ── Honest records ───────────────────────────────────────────────────────
# An item the client has not cached yet returns no name. Writing that record
# would store a permanent blank for an item we will see again in a minute.
check("uncached items are skipped, not half-written",
      "if not name then return false end" in h)
check("already-known items exit before the expensive read",
      h.index("if s.items[itemID] ~= nil then return false end") < h.index("local name, _, quality"))
check("stat blocks are captured", "GetItemStats" in h)
check("stat keys are sorted for stable records", "table.sort(keys)" in h)
check("tabs are stripped from values", 'v:gsub("[\\t\\r\\n]", " ")' in h)

# ── Guarded, like everything else on this client ─────────────────────────
check("it has a guarded caller", "local function Try(fn, ...)" in h)
check("Try rejects non-functions", 'if type(fn) ~= "function" then return nil end' in h)
check("modern container API is probed", "C_Container.GetContainerItemLink" in h)
check("legacy container API is kept", "Try(GetContainerItemLink" in h)
check("modern spellbook API is probed", "C_SpellBook.GetSpellBookItemInfo" in h)
check("legacy spellbook API is kept", "Try(GetSpellBookItemInfo" in h)
check("vanilla talent API is used", "Try(GetTalentInfo, tab, i)" in h)

# ── Silent ───────────────────────────────────────────────────────────────
# Bag events fire several times per loot; an unthrottled five-bag scan on each
# is a stutter the player feels.
check("bag scans are debounced", "_scanQueued" in h)
check("the debounce has a delay", "local SCAN_DELAY" in h)
# The only chat writes allowed are the debug line and the clear confirmation.
check("it does not chatter", h.count("TA:Raw(") <= 2)

# ── Store survives a schema bump ─────────────────────────────────────────
store = h[h.index("local function Store()"):h.index("local function Count(")]
check("an older store is backfilled, not reset", "s.items   = s.items   or {}" in store)
check("it does not overwrite an existing store",
      "TA.db.foreverHarvest = s" in store and store.count("TA.db.foreverHarvest = s") == 1)

# ── Clearing is deliberate ───────────────────────────────────────────────
check("clearing takes two clicks", "_confirmClear" in h)

# ── Wiring ───────────────────────────────────────────────────────────────
# Forever's TOC is the ONLY one that ships the harvester. It rode along in
# the retail TOCs while Mainline still claimed 16001 and Forever could fall
# through to it; neither is true now, so shipping it there would just be dead
# weight on every retail player's disk.
check("forever ships the harvester", "DataHarvester    = true," in pf)
check("forever gets a Harvest tab",
      '{ id = "harvest",    label = "Harvest",    module = "DataHarvester" }' in pf)
check("Forever's TOC lists it",
      "Modules\\Forever\\DataHarvester.lua" in read("ToonAge_Camelot.toc"))
for toc in ("ToonAge.toc", "ToonAge_Mainline.toc"):
    check(f"{toc} does NOT ship it",
          "Modules\\Forever\\DataHarvester.lua" not in read(toc))
# It draws through the shared Layout, so the TOC that ships it needs that.
check("Forever's TOC lists Core\\Layout.lua",
      "Core\\Layout.lua" in read("ToonAge_Camelot.toc"))

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
