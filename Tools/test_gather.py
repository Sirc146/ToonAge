#!/usr/bin/env python3
"""Skinning feeds the same farm pipeline as herbs and ore.

FarmOptimizer has always branched on a "skin" gather type, but GatherTracker
only ever classified herbs and ore, so that branch could never run. These
assertions keep the two halves connected.
"""
import sys, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


gt = open(os.path.join(ROOT, "Modules/Farming/GatherTracker.lua"), encoding="utf-8").read()
fo = open(os.path.join(ROOT, "Modules/Farming/FarmOptimizer.lua"), encoding="utf-8").read()

# Leather is tradeskill subclass 6; herbs 9, ore 7. Getting this wrong would
# classify cloth (5) or cooking mats (8) as skins.
check("leather subclass is 6", "GATHER_SUBCLASS_LEATHER = 6" in gt)
check("herb subclass still 9", "GATHER_SUBCLASS_HERB    = 9" in gt)
check("ore subclass still 7", "GATHER_SUBCLASS_ORE     = 7" in gt)

detect = gt[gt.index("local function DetectGatherType"):gt.index("-- ── Recording nodes")]
check("classifier returns skin", 'return "skin"' in detect)
check("classifier keeps herb and ore",
      'return "herb"' in detect and 'return "ore"' in detect)
check("classifier only looks at tradeskill items", "classID == 7" in detect)

check("skinned nodes get their own colour", "COLOR_SKIN" in gt)
check("renderer branches on skin", 'node.type == "skin"' in gt)
check("summary counts skins", "skinCount" in gt)

# The consumer side: FarmOptimizer's skin branch is what this feeds.
check("FarmOptimizer handles the skin type", 'gatherType == "skin"' in fo)
check("FarmOptimizer knows the skinning profession", "SKINNING" in fo)

# Corpses are events, not spawn points: they must not be merged at the node
# radius, or a busy camp collapses into one dot.
rec = gt[gt.index("function GatherTracker:RecordNode"):]
rec = rec[:rec.index("\n-- ")]
check("skins dedupe at a tighter radius", 'gatherType == "skin") and (DEDUP_DISTANCE' in rec)
check("dedupe only merges the same type", "node.type == gatherType" in rec)
check("recording is observable under /ta debug", "TA.debug" in rec)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
