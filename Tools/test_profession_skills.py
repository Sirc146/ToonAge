#!/usr/bin/env python3
"""
ToonAge -- shared profession cards
==================================
The reader picks a skill-bar shape from the data file's prefer list and from
which calls exist. It must not branch on game version.

  * Retail: one segment per expansion; the current expansion's segment is gold.
  * Mists: one bar, even when the retail child-skill call also exists.
  * TBC and Era: GetSkillLineInfo, profession and secondary-skill headers only.
  * Forever: C_SkillInfo, even when GetProfessions exists. Comprehension 3012
    is a secondary. The data file stays unverified.
  * The harvest probe line carries id, name, rank, max rank and header.

Usage:  python3 Tools/test_profession_skills.py [-v]
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
    lua.execute("ToonAge = {}")
    return lua


def load_reader(lua, data_rel):
    lua.execute(read(data_rel))
    lua.execute(read("Modules/Character/ProfessionSkills.lua"))
    return lua.globals().ToonAge.ProfessionSkills


def fields(line):
    return line.split("\t")


RETAIL_APIS = r"""
function GetProfessions() return 1, nil, 3, nil, nil, nil end
function GetProfessionInfo(i)
    if i == 3 then return "Archaeology", 441139, 50, 950, 0, 0, 794 end
    return "Blacksmithing", 136241, 25, 100, 0, 0, 164
end
C_TradeSkillUI = {
    GetProfessionInfoBySkillLineID = function(id)
        if id == 2907 then
            return { professionID = id, professionName = "Midnight Blacksmithing",
                     skillLevel = 25, maxSkillLevel = 100 }
        end
        return { professionID = id, professionName = "Unknown", skillLevel = 0, maxSkillLevel = 0 }
    end,
}
"""

SKILL_APIS = r"""
local LINES = {
    { "Professions", true, true, 0, 0, 0, 0 },
    { "Blacksmithing", false, false, 10, 0, 0, 75 },
    { "Weapon Skills", true, true, 0, 0, 0, 0 },
    { "Swords", false, false, 80, 0, 0, 85 },
    { "General", true, true, 0, 0, 0, 0 },
    { "Riding", false, false, 150, 0, 0, 150 },
    { "Secondary Skills", true, true, 0, 0, 0, 0 },
    { "Cooking", false, false, 1, 0, 0, 0 },
}
function GetNumSkillLines() return #LINES end
function GetSkillLineInfo(i)
    local r = LINES[i]
    return r[1], r[2], r[3], r[4], r[5], r[6], r[7]
end
-- Present on purpose. The data file does not prefer these, so they must not win.
function GetProfessions() return 1 end
function GetProfessionInfo() return "ShouldNotAppear", 0, 1, 1, 0, 0, 1 end
C_TradeSkillUI = { GetProfessionInfoBySkillLineID = function() return { skillLevel = 9, maxSkillLevel = 9 } end }
"""

FOREVER_APIS = r"""
function GetProfessions() return 1 end
function GetProfessionInfo() return "ShouldNotAppear", 0, 40, 300, 0, 0, 164 end
C_TradeSkillUI = { GetProfessionInfoBySkillLineID = function(id)
    return { professionID = id, professionName = "ShouldNotAppear", skillLevel = 40, maxSkillLevel = 300 }
end }
C_SkillInfo = {
    GetNumSkillLines = function() return 8 end,
    GetSkillLineInfo = function(i)
        local rows = {
            { name = "Weapon Skills", isHeader = true },
            { name = "Swords", rank = 20, maxRank = 100, skillID = 43, skillLineCategoryID = 6 },
            { name = "Class", isHeader = true },
            { name = "Combat", rank = 1, maxRank = 1, skillID = 38, skillLineCategoryID = 7 },
            { name = "Professions", isHeader = true },
            { name = "Blacksmithing", rank = 12, maxRank = 75, skillID = 164 },
            { name = "Secondary Skills", isHeader = true },
            { name = "Comprehension", rank = 5, maxRank = 300, skillID = 3012 },
        }
        return rows[i]
    end,
}
"""


def test_source_has_no_version_branch():
    src = read("Modules/Character/ProfessionSkills.lua")
    check("reader does not mention TA.flavor", "TA.flavor" in src, False)
    check("reader does not compare flavor", "flavor ==" in src, False)
    for name in ("segments", "professions", "skilllines", "skillinfo"):
        check(f"reader knows the {name} feature", name in src, True)


def test_retail_segments():
    lua = runtime()
    lua.execute(RETAIL_APIS)
    load_reader(lua, "Data/Retail/ProfessionSkills.lua")
    lua.execute("result = ToonAge.ProfessionSkills.Collect()")
    check("retail reader is segments", lua.eval("result.reader"), "segments")
    check("retail data is verified", lua.eval("result.unverified"), False)
    check("retail current expansion is Midnight",
          lua.eval("ToonAge.Data.ProfessionSkills.expansions[12].label"), "Midnight")
    check("retail Midnight segment is the current one",
          lua.eval("ToonAge.Data.ProfessionSkills.expansions[12].current"), True)
    check("enchanting has no skill line 2490",
          lua.eval("ToonAge.Data.ProfessionSkills.lines[3].children[5]"), 2489)
    check("blacksmithing has one segment per expansion",
          lua.eval("#result.cards[1].segments"), 12)
    check("classic segment is the published id",
          lua.eval("result.cards[1].segments[1].id"), 2477)
    check("classic segment uses the data-file cap when the API max is 0",
          lua.eval("result.cards[1].segments[1].max"), 300)
    check("classic segment is not current",
          lua.eval("result.cards[1].segments[1].current"), False)
    check("midnight segment is the published id",
          lua.eval("result.cards[1].segments[12].id"), 2907)
    check("midnight segment is current",
          lua.eval("result.cards[1].segments[12].current"), True)
    check("midnight segment keeps the API max",
          lua.eval("result.cards[1].segments[12].max"), 100)
    check("archaeology is a single bar", lua.eval("result.cards[2].segments"), None)
    check("archaeology is secondary", lua.eval("result.cards[2].secondary"), True)
    check("archaeology keeps the API max", lua.eval("result.cards[2].max"), 950)

    lua.execute("probe = ToonAge.ProfessionSkills.ProbeLines()")
    check("retail probe names the reader", lua.eval("probe[1]"), "reader segments")
    lua.execute(r"""
        midnight, arch, bad = false, false, 0
        for i = 2, #probe do
            local n = 1
            for _ in string.gmatch(probe[i], "\t") do n = n + 1 end
            if n ~= 5 then bad = bad + 1 end
            if probe[i] == "2907\tMidnight Blacksmithing\t25\t100\tMidnight" then midnight = true end
            if probe[i] == "794\tArchaeology\t50\t950\tSecondary Skills" then arch = true end
        end
    """)
    check("retail probe midnight line", lua.eval("midnight"), True)
    check("retail probe archaeology line", lua.eval("arch"), True)
    check("retail probe lines have five fields", lua.eval("bad"), 0)

    # The child-skill call going missing falls through to the single bar.
    lua.execute("C_TradeSkillUI = nil; result = ToonAge.ProfessionSkills.Collect()")
    check("retail falls back to one bar when the child call is missing",
          lua.eval("result.reader"), "professions")
    check("fallback card has no segments", lua.eval("result.cards[1].segments"), None)


def test_mists_single_bar():
    lua = runtime()
    lua.execute(RETAIL_APIS)
    load_reader(lua, "Data/Mists/ProfessionSkills.lua")
    check("mists cap is 600", lua.eval("ToonAge.Data.ProfessionSkills.cap"), 600)
    check("mists prefers the single-bar reader",
          lua.eval("ToonAge.Data.ProfessionSkills.prefer[1]"), "professions")
    lua.execute("result = ToonAge.ProfessionSkills.Collect()")
    check("mists stays a single bar when the segment call exists",
          lua.eval("result.reader"), "professions")
    check("mists card has no segments", lua.eval("result.cards[1].segments"), None)
    check("mists uses the API max, not the 600 fallback", lua.eval("result.cards[1].max"), 100)
    check("mists archaeology is secondary", lua.eval("result.cards[2].secondary"), True)


def test_header_filter(data_rel, cap, label):
    lua = runtime()
    lua.execute(SKILL_APIS)
    load_reader(lua, data_rel)
    lua.execute("result = ToonAge.ProfessionSkills.Collect()")
    check(f"{label} reader is skill lines", lua.eval("result.reader"), "skilllines")
    check(f"{label} drops weapon skills and riding", lua.eval("#result.cards"), 2)
    check(f"{label} blacksmithing id comes from the data file",
          lua.eval("result.cards[1].id"), 164)
    check(f"{label} blacksmithing header", lua.eval("result.cards[1].header"), "Professions")
    check(f"{label} cooking is secondary", lua.eval("result.cards[2].secondary"), True)
    check(f"{label} cooking id", lua.eval("result.cards[2].id"), 185)
    check(f"{label} cooking header", lua.eval("result.cards[2].header"), "Secondary Skills")
    check(f"{label} missing max uses the data-file cap", lua.eval("result.cards[2].max"), cap)
    names = lua.eval('table.concat({result.cards[1].name, result.cards[2].name}, ",")')
    check(f"{label} names", names, "Blacksmithing,Cooking")
    lua.execute("probe = ToonAge.ProfessionSkills.ProbeLines()")
    line = lua.eval("probe[2]")
    check(f"{label} probe line", line, f"164\tBlacksmithing\t10\t75\tProfessions")
    check(f"{label} probe field count", len(fields(line)), 5)


def test_forever_skillinfo():
    lua = runtime()
    lua.execute(FOREVER_APIS)
    load_reader(lua, "Data/Forever/ProfessionSkills.lua")
    check("forever data is unverified", lua.eval("ToonAge.Data.ProfessionSkills.unverified"), True)
    check("forever prefers C_SkillInfo",
          lua.eval("ToonAge.Data.ProfessionSkills.prefer[1]"), "skillinfo")
    lua.execute("result = ToonAge.ProfessionSkills.Collect()")
    check("forever uses skillinfo even when GetProfessions exists",
          lua.eval("result.reader"), "skillinfo")
    check("forever result stays unverified", lua.eval("result.unverified"), True)
    check("forever keeps professions and comprehension only", lua.eval("#result.cards"), 2)
    check("forever blacksmithing", lua.eval("result.cards[1].name"), "Blacksmithing")
    check("forever blacksmithing id", lua.eval("result.cards[1].id"), 164)
    check("comprehension id", lua.eval("result.cards[2].id"), 3012)
    check("comprehension is a secondary", lua.eval("result.cards[2].secondary"), True)
    check("comprehension header", lua.eval("result.cards[2].header"), "Secondary Skills")
    check("forever did not take the GetProfessions row",
          lua.eval('result.cards[1].name == "ShouldNotAppear"'), False)
    lua.execute("probe = ToonAge.ProfessionSkills.ProbeLines()")
    check("forever probe says unverified", lua.eval("probe[1]"), "reader skillinfo (unverified)")
    check("forever probe comprehension",
          lua.eval("probe[3]"), "3012\tComprehension\t5\t300\tSecondary Skills")
    check("forever probe field count", len(fields(lua.eval("probe[3]"))), 5)

    # max 0 and rank 0 is not a learned profession.
    lua.execute(r"""
        local orig = C_SkillInfo.GetSkillLineInfo
        C_SkillInfo.GetSkillLineInfo = function(i)
            local info = orig(i)
            if info and info.skillID == 3012 then info.rank = 0; info.maxRank = 0 end
            return info
        end
        result = ToonAge.ProfessionSkills.Collect()
    """)
    check("unlearned comprehension is omitted", lua.eval("#result.cards"), 1)
    check("blacksmithing remains", lua.eval("result.cards[1].name"), "Blacksmithing")


FRAME = r"""
local function Mock(name)
    local f = { _name = name }
    setmetatable(f, { __index = function(s, k)
        if type(k) == "string" and k:sub(1, 1) == "_" then return nil end
        local fn
        if k == "CreateTexture" or k == "CreateFontString" then
            fn = function() return Mock(name .. "_child") end
        else
            fn = function() return s end
        end
        rawset(s, k, fn)
        return fn
    end })
    return f
end
CreateFrame = function() return Mock("frame") end
GameTooltip = Mock("tip")
"""


def test_current_segment_is_gold():
    lua = runtime()
    lua.execute("ToonAge.Utils = {}")
    lua.execute(FRAME)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(r"""
        PARENT = CreateFrame()
        PARENT.GetWidth = function() return 480 end
        local _, card = ToonAge.Layout:ProfessionCard(PARENT, -8, {
            name = "Blacksmithing",
            rank = 40, max = 100,
            segments = {
                { label = "Classic", rank = 300, max = 300, current = false },
                { label = "Midnight", rank = 40, max = 100, current = true },
            },
        })
        GOLD_CARD = card
    """)
    check("current segment fill is gold",
          (lua.eval("GOLD_CARD.fills[2]._rgb[1]"),
           lua.eval("GOLD_CARD.fills[2]._rgb[2]"),
           lua.eval("GOLD_CARD.fills[2]._rgb[3]")),
          (1.0, 0.82, 0.0))
    check("current segment is flagged", lua.eval("GOLD_CARD.fills[2]._current"), True)
    check("other segment is not gold",
          (lua.eval("GOLD_CARD.fills[1]._rgb[1]"),
           lua.eval("GOLD_CARD.fills[1]._rgb[2]"),
           lua.eval("GOLD_CARD.fills[1]._rgb[3]")),
          (0.58, 0.60, 0.65))
    check("other segment is not current", lua.eval("GOLD_CARD.fills[1]._current"), False)
    # One segment, or none, is a single bar in the profession colour.
    lua.execute(r"""
        local _, card = ToonAge.Layout:ProfessionCard(PARENT, -80, {
            name = "Cooking", rank = 20, max = 600,
        })
        SINGLE = card
    """)
    check("single bar uses the profession colour",
          (round(lua.eval("SINGLE.fill._rgb[1]"), 2),
           round(lua.eval("SINGLE.fill._rgb[2]"), 2),
           round(lua.eval("SINGLE.fill._rgb[3]"), 2)),
          (0.95, 0.75, 0.30))
    check("single bar is not a current-expansion segment",
          lua.eval("SINGLE.fill._current"), False)


def main():
    test_source_has_no_version_branch()
    test_retail_segments()
    test_mists_single_bar()
    test_header_filter("Data/TBC/ProfessionSkills.lua", 375, "tbc")
    test_header_filter("Data/Vanilla/ProfessionSkills.lua", 300, "era")
    test_forever_skillinfo()
    test_current_segment_is_gold()
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
