#!/usr/bin/env python3
"""Two crashes the Forever client surfaced, and the guards that close them.

A) Character OnEvent swallowed its `event` argument and handed nil to
   TA:QueueUIRefresh, which used it as a table key -> "table index is nil",
   repeated until the module hit the 10-error cutoff and disabled itself.
B) GatherTracker called GetLootSlotLink/GetItemInfoInstant unguarded. Those
   are absent on Forever, so every LOOT_OPENED threw.
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


ch   = read("Modules/Forever/Character.lua")
init = read("Core/Init.lua")
gt   = read("Modules/Farming/GatherTracker.lua")

# --- Bug A ---------------------------------------------------------------
check("Character OnEvent forwards its event", "TA:QueueUIRefresh(event)" in ch)
check("no bare QueueUIRefresh() anywhere", "QueueUIRefresh()" not in ch + init + gt)

q = init[init.index("function TA:QueueUIRefresh"):]
q = q[:q.index("\nend")]
check("QueueUIRefresh survives a nil event", 'if event == nil then' in q)
check("the fallback key is set before indexing",
      q.index("event = \"UNSPECIFIED\"") < q.index("_pendingUIEvents[event]"))

# --- Bug B ---------------------------------------------------------------
check("GatherTracker has a guarded caller", "local function Try(fn, ...)" in gt)
check("Try rejects non-functions", 'if type(fn) ~= "function" then return nil end' in gt)
check("Try swallows errors", "pcall(fn, ...)" in gt)

det = gt[gt.index("local function DetectGatherType"):]
det = det[:det.index("\nend")]
for api in ("GetNumLootItems", "GetLootSlotLink", "GetItemInfoInstant"):
    # Item classification moved into a helper above DetectGatherType; the
    # guarded C_Item call there is what Forever needs (the global is nil).
    scope = gt if api == "GetItemInfoInstant" else det
    check(f"{api} goes through Try", f"Try({api}" in scope or f"Try(C_Item.{api}" in scope)
check("no unguarded loot call remains",
      not any(f"= {api}(" in det for api in
              ("GetNumLootItems", "GetLootSlotLink", "GetItemInfoInstant")))

rec = gt[gt.index("function GatherTracker:RecordNode"):]
rec = rec[:rec.index("\n-- ")]
check("C_Map presence is checked", 'type(C_Map) ~= "table"' in rec)
check("map lookups go through Try", "Try(C_Map.GetBestMapForUnit" in rec)
check("GetXY is checked before the call", 'type(pos.GetXY) ~= "function"' in rec)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
