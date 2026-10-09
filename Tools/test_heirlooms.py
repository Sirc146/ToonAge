#!/usr/bin/env python3
"""Heirloom scan decisions, without a WoW client.

The suggestion rule is item level only: a piece is listed when it beats the
equipped item, or the slot is empty. Retail copy must not claim a bonus-XP
gain. Mists copy must. Era and TBC skip. Forever stays off unless the flag
is flipped.
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
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
    return (ROOT / rel).read_text(encoding="utf-8")


src = read("Modules/Gear/Heirlooms.lua")

lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(r"""
ToonAge = {}
function ToonAge:RegisterModule(name, mod)
    HEIR = mod
end
""")
lua.execute(src)

chunk = r"""
local M = HEIR
local fail = {}
local function eq(name, got, want)
    if got ~= want then
        fail[#fail + 1] = name .. " got " .. tostring(got) .. " want " .. tostring(want)
    end
end

eq("era skips", M.ScanMode("vanilla", true, false), "skip")
eq("tbc skips", M.ScanMode("tbc", true, false), "skip")
eq("forever off", M.ScanMode("forever", true, false), "off")
eq("forever flag uses collection", M.ScanMode("forever", true, true), "collection")
eq("forever flag bags", M.ScanMode("forever", false, true), "bags")
eq("retail collection", M.ScanMode("retail", true, false), "collection")
eq("retail missing api", M.ScanMode("retail", false, false), "missing-api")
eq("mists bags", M.ScanMode("mists", false, false), "bags")
eq("mists collection", M.ScanMode("mists", true, false), "collection")
eq("flag default", M.FOREVER_ENABLED, false)
eq("create absent", M.CreateHeirloomMode(), "absent")

local retail = M.Advice("retail")
local mists = M.Advice("mists")
eq("retail denies bonus xp", retail:find("do not grant bonus experience") ~= nil, true)
eq("retail names the patch", retail:find("9.0.1") ~= nil, true)
eq("mists keeps bonus xp", mists:find("still grant bonus experience") ~= nil, true)
eq("era card", M.EmptyCopy("skip", "vanilla", 0, 0), "No heirlooms here")
local _, tbcSentence = M.EmptyCopy("skip", "tbc", 0, 0)
eq("tbc card", tbcSentence:find("Burning Crusade") ~= nil, true)

local function item(id, ilvl, slots, where)
    return { itemID = id, ilvl = ilvl, slots = slots, where = where or "bag", name = "Loom " .. id }
end

local one = M.Suggest({ item(1, 20, { 1 }) }, {})
eq("empty slot suggests", #one, 1)
eq("empty slot id", one[1].slot, 1)

local weaker = M.Suggest({ item(1, 10, { 1 }) }, { [1] = { ilvl = 25, itemID = 9 } })
eq("weaker heirloom hidden", #weaker, 0)

local better = M.Suggest({ item(1, 30, { 1 }) }, { [1] = { ilvl = 12, itemID = 9 } })
eq("stronger heirloom shown", #better, 1)
eq("records equipped ilvl", better[1].eqIlvl, 12)

local worn = M.Suggest({ item(7, 40, { 5 }) }, { [5] = { ilvl = 10, itemID = 7 } })
eq("already equipped hidden", #worn, 0)

local unknown = M.Suggest({ item(1, 40, { 1 }) }, { [1] = { itemID = 9 } })
eq("unknown equipped ilvl hidden", #unknown, 0)

local rings = M.Suggest({
    item(1, 15, { 11, 12 }),
    item(2, 28, { 11, 12 }),
}, {
    [11] = { ilvl = 20, itemID = 3 },
    [12] = { ilvl = 5, itemID = 4 },
})
eq("two rings, one winner", #rings, 1)
eq("winner fills the weaker ring", rings[1].slot, 12)
eq("winner is the stronger loom", rings[1].item.itemID, 2)

local both = M.Suggest({
    item(1, 30, { 11, 12 }),
    item(2, 28, { 11, 12 }),
}, {})
eq("two empty rings take two looms", #both, 2)

local deduped = M.Dedupe({
    { itemID = 5, where = "collection", name = "C" },
    { itemID = 5, where = "bank", name = "B" },
    { itemID = 5, where = "bag", name = "A" },
})
eq("dedupe keeps one", #deduped, 1)
eq("bag beats bank and collection", deduped[1].where, "bag")

eq("cloth on cloth", M.CanWear(4, 1, 1), true)
eq("plate on cloth", M.CanWear(4, 4, 1), false)
eq("cloth on plate", M.CanWear(4, 1, 4), true)
eq("shield kept", M.CanWear(4, 6, 1), true)
eq("weapon kept", M.CanWear(2, 7, 1), true)

if #fail > 0 then
    return table.concat(fail, "\n")
end
return ""
"""
errors = lua.execute(chunk)
check("suggestion and copy rules", errors, "")

check("literal GetHeirloomItemIDs", "C_Heirloom.GetHeirloomItemIDs" in src, True)
check("literal PlayerHasHeirloom", "C_Heirloom.PlayerHasHeirloom" in src, True)
check("literal GetHeirloomInfo", "C_Heirloom.GetHeirloomInfo" in src, True)
check("literal GetHeirloomMaxUpgradeLevel", "C_Heirloom.GetHeirloomMaxUpgradeLevel" in src, True)
check("does not call CreateHeirloom", "pcall(C_Heirloom.CreateHeirloom" not in src, True)
check("journal label", "Open Heirloom Journal" in src, True)
check("name colour", "00CCFF" in src, True)
check("pip texture", "util_pip_8.tga" in src, True)
check("lock texture", "util_lock_16.tga" in src, True)
check("secure item attribute", '"type", "item"' in src, True)
check("regen requeue", "PLAYER_REGEN_ENABLED" in src, True)

for toc, want in (
    ("ToonAge_Mainline.toc", True),
    ("ToonAge.toc", True),
    ("ToonAge_Mists.toc", True),
    ("ToonAge_TBC.toc", True),
    ("ToonAge_Vanilla.toc", False),
    ("ToonAge_Camelot.toc", False),
):
    listed = "Modules\\Gear\\Heirlooms.lua" in read(toc)
    check(f"{toc} lists Heirlooms", listed, want)

ui = read("Core/UI.lua")
check("era empty card", "Classic Era has no heirloom items" in ui, True)
harness = read("Modules/Infrastructure/TestHarness.lua")
check("self-test probes the collection API", "C_Heirloom collection API" in harness, True)
check("self-test records CreateHeirloom", "CreateHeirloom" in harness, True)
profile = read("Core/Profile.lua")
check("tbc profile allows the module", "Heirlooms" in profile, True)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
