#!/usr/bin/env python3
"""
ToonAge -- Gear "Enchants & crafting" duplicate rows
=====================================================
A Mage on Forever saw Chest Barbaric Linen Vest twice and Hands Heavy Linen
Gloves twice: one row with no profession and one labeled Tailoring.

The list is every recorded recipe product, concatenated. An empty profession
name is its own saved bucket beside Tailoring, and nothing keys the rows by
item. The merged row keeps the profession and the higher material count.

Usage:  python3 Tools/test_gear_enchants.py [-v]
"""
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { Data = {}, charDB = {}, modules = {} }
        local TA = ToonAge
        function TA:RegisterModule(name, mod) self.modules[name] = mod end
    """)
    lua.execute(read("Modules/Forever/Gear.lua"))
    return lua


def rows_by_name(lua, expr):
    lua.execute(rf"""
        local t = {{}}
        for _, row in ipairs({expr}) do
            t[row.v.name] = {{ prof = row.prof or "", avail = row.avail or 0, slot = row.v.slot }}
        end
        BY_NAME = t
        NROWS = #{expr}
    """)
    return lua.eval("BY_NAME"), lua.eval("NROWS")


def test_merge():
    lua = runtime()
    # Classic item ids. Forever's harvest records Heavy Linen Gloves as 4307.
    # Barbaric Linen Vest is classic item 2578; the link is what the client
    # recorded, and the merge keys off that id.
    lua.execute(r"""
        local M = ToonAge.modules.ForeverGear
        local function evaluate(link)
            local id = tonumber(link:match("item:(%-?%d+)"))
            if id == 2578 then
                return { slot = "Chest", name = "Barbaric Linen Vest", verdict = "better", quality = 2 }
            end
            if id == 4307 then
                return { slot = "Hands", name = "Heavy Linen Gloves", verdict = "better", quality = 2 }
            end
            if id == 4308 then
                return { slot = "Wrist", name = "Green Linen Bracers", verdict = "trade", quality = 2 }
            end
            return nil
        end
        local recipes = {
            [""] = { list = {
                { name = "Barbaric Linen Vest", link = "item:2578:0:0:0", avail = 0 },
                { name = "Heavy Linen Gloves", link = "item:4307:0:0:0", avail = 1 },
                { name = "Green Linen Bracers", link = "item:4308", avail = 3 },
            } },
            Tailoring = { list = {
                { name = "Barbaric Linen Vest", link = "|cff1eff00|Hitem:2578:0:0:0|h[Barbaric Linen Vest]|h|r", avail = 2 },
                { name = "Heavy Linen Gloves", link = "item:4307", avail = 0 },
                { name = "Barbaric Linen Vest", link = "item:2578", avail = 2 },
            } },
        }
        MERGED = M.CraftRows(recipes, evaluate)
    """)
    by_name, nrows = rows_by_name(lua, "MERGED")
    check("the two linen pieces and the bracers are one row each", nrows, 3)
    check("Barbaric Linen Vest keeps Tailoring", by_name["Barbaric Linen Vest"]["prof"], "Tailoring")
    check("Barbaric Linen Vest stays on Chest", by_name["Barbaric Linen Vest"]["slot"], "Chest")
    check("Barbaric Linen Vest keeps the higher material count", by_name["Barbaric Linen Vest"]["avail"], 2)
    check("Heavy Linen Gloves keeps Tailoring", by_name["Heavy Linen Gloves"]["prof"], "Tailoring")
    check("Heavy Linen Gloves stays on Hands", by_name["Heavy Linen Gloves"]["slot"], "Hands")
    check("Heavy Linen Gloves keeps the blank row's material count", by_name["Heavy Linen Gloves"]["avail"], 1)
    check("a recipe that only the blank bucket had is kept", by_name["Green Linen Bracers"]["slot"], "Wrist")
    check("that unique row is not given a profession it did not have", by_name["Green Linen Bracers"]["prof"], "")

    # Same item, no item id on the link: name + slot is the key.
    lua.execute(r"""
        local M = ToonAge.modules.ForeverGear
        local function evaluate()
            return { slot = "Chest", name = "Barbaric Linen Vest", verdict = "better" }
        end
        local recipes = {
            [""] = { list = { { name = "Barbaric Linen Vest", link = "nolink", avail = 0 } } },
            Tailoring = { list = { { name = "Barbaric Linen Vest", link = "nolink", avail = 4 } } },
        }
        NAMED = M.CraftRows(recipes, evaluate)
    """)
    by_name, nrows = rows_by_name(lua, "NAMED")
    check("name and slot collapse the same item when the link has no id", nrows, 1)
    check("that row still carries Tailoring", by_name["Barbaric Linen Vest"]["prof"], "Tailoring")
    check("that row keeps the higher material count", by_name["Barbaric Linen Vest"]["avail"], 4)


def test_record_name():
    lua = runtime()
    lua.execute(r"""
        C_TradeSkillUI = {
            GetAllRecipeIDs = function() return { 2397 } end,
            GetRecipeInfo = function()
                return { name = "Barbaric Linen Vest", learned = true, numAvailable = 1 }
            end,
            GetRecipeItemLink = function() return "item:2578" end,
            GetBaseProfessionInfo = function() return { professionName = "" } end,
        }
        GetTradeSkillLine = function() return "Tailoring" end
        ToonAge.charDB = {}
        ToonAge.modules.ForeverGear:RecordRecipes()
        local n, key = 0, nil
        for k in pairs(ToonAge.charDB.recipes or {}) do n = n + 1; key = k end
        RECORDED_N, RECORDED_KEY = n, key
    """)
    check("an empty professionName falls through to the skill line", lua.eval("RECORDED_N"), 1)
    check("that recording is keyed Tailoring", lua.eval("RECORDED_KEY"), "Tailoring")

    lua.execute(r"""
        GetTradeSkillLine = function() return "" end
        ToonAge.charDB = {}
        ToonAge.modules.ForeverGear:RecordRecipes()
        BLANK_KEY = ToonAge.charDB.recipes and ToonAge.charDB.recipes[""] ~= nil
        OTHER = 0
        for k in pairs(ToonAge.charDB.recipes or {}) do if k ~= "" then OTHER = OTHER + 1 end end
    """)
    check("a read with no profession name is still kept", lua.eval("BLANK_KEY"), True)
    check("that read does not invent a profession key", lua.eval("OTHER"), 0)


def test_wired():
    src = read("Modules/Forever/Gear.lua")
    start = src.index("RenderEnchants = function")
    body = src[start:src.index("\nend", start)]
    check("Enchants & crafting builds the list through CraftRows", "M.CraftRows(" in body, True)
    items = read("Data/Forever/Items.lua")
    check("Heavy Linen Gloves is a single shipped item row", items.count('[4307]'), 1)
    check("Barbaric Linen Vest is not a duplicate shipped row", "Barbaric Linen Vest" in items, False)


def main():
    test_merge()
    test_record_name()
    test_wired()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
