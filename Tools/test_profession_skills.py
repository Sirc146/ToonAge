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
    check("reader does not hardcode an absent profession", "Jewelcrafting" in src, False)
    check("reader does not hardcode a class gate", '"MAGE"' in src, False)
    check("reader does not hardcode Gardening", "Gardening" in src, False)
    check("reader does not hardcode the gardening spell", "1278062" in src, False)
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
    check("classic segment does not invent a cap when the API max is 0",
          lua.eval("result.cards[1].segments[1].max"), 0)
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
            if probe[i]:find("GetProfessionInfoBySkillLineID", 1, true) then
                API_LINE = probe[i]
            else
            local n = 1
            for _ in string.gmatch(probe[i], "\t") do n = n + 1 end
            if n ~= 5 then bad = bad + 1 end
            end
            if probe[i] == "2907\tMidnight Blacksmithing\t25\t100\tMidnight" then midnight = true end
            if probe[i] == "794\tArchaeology\t50\t950\tSecondary Skills" then arch = true end
        end
    """)
    check("retail probe midnight line", lua.eval("midnight"), True)
    check("retail probe archaeology line", lua.eval("arch"), True)
    check("retail probe lines have five fields", lua.eval("bad"), 0)
    check("probe reports the child skill call",
          "GetProfessionInfoBySkillLineID -> present, called" in (lua.eval("API_LINE") or ""), True)

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
    check("mists does not add unlearned secondaries", lua.eval("#result.cards"), 2)


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

    # Gates and absences come from the data file. A rogue never sees
    # Comprehension. A mage below 6 does not either. Poisons is a rogue skill.
    lua.execute(FOREVER_APIS)
    lua.execute(r"""
        function UnitClass() return "Rogue", "ROGUE" end
        function UnitLevel() return 20 end
        local orig = C_SkillInfo.GetSkillLineInfo
        C_SkillInfo.GetSkillLineInfo = function(i)
            if i == 9 then return { name = "Jewelcrafting", rank = 10, maxRank = 300, skillID = 755 } end
            if i == 10 then return { name = "Poisons", rank = 1, maxRank = 300, skillID = 40 } end
            return orig(i)
        end
        C_SkillInfo.GetNumSkillLines = function() return 10 end
        result = ToonAge.ProfessionSkills.Collect()
        local names = {}
        for i = 1, #result.cards do names[i] = result.cards[i].name end
        rogueNames = table.concat(names, ",")
    """)
    check("rogue names", lua.eval("rogueNames"), "Blacksmithing,Poisons")
    check("forever data omits jewelcrafting",
          "Jewelcrafting" in read("Data/Forever/ProfessionSkills.lua")
          and "absent" in read("Data/Forever/ProfessionSkills.lua"), True)

    lua.execute(r"""
        function UnitClass() return "Mage", "MAGE" end
        function UnitLevel() return 5 end
        result = ToonAge.ProfessionSkills.Collect()
        local names = {}
        for i = 1, #result.cards do names[i] = result.cards[i].name end
        lowNames = table.concat(names, ",")
        UnitLevel = function() return 6 end
        result = ToonAge.ProfessionSkills.Collect()
        names = {}
        for i = 1, #result.cards do names[i] = result.cards[i].name end
        mageNames = table.concat(names, ",")
    """)
    check("a level 5 mage does not see comprehension", lua.eval("lowNames"), "Blacksmithing")
    check("a level 6 mage sees comprehension and not poisons",
          lua.eval("mageNames"), "Blacksmithing,Comprehension")

    # Gardening is a hunter skill matched by name. The spell id is not a
    # skill-line id. A mage does not see the row.
    lua.execute(FOREVER_APIS)
    lua.execute(r"""
        local lines = ToonAge.Data.ProfessionSkills.lines
        garden = nil
        for i = 1, #lines do
            if lines[i].name == "Gardening" then garden = lines[i] end
        end
        function UnitClass() return "Hunter", "HUNTER" end
        function UnitLevel() return 1 end
        local orig = C_SkillInfo.GetSkillLineInfo
        C_SkillInfo.GetSkillLineInfo = function(i)
            if i == 9 then return { name = "Gardening", rank = 1, maxRank = 75, skillID = 1278062 } end
            return orig(i)
        end
        C_SkillInfo.GetNumSkillLines = function() return 9 end
        result = ToonAge.ProfessionSkills.Collect()
        local names = {}
        for i = 1, #result.cards do names[i] = result.cards[i].name end
        hunterNames = table.concat(names, ",")
        function UnitClass() return "Mage", "MAGE" end
        function UnitLevel() return 6 end
        result = ToonAge.ProfessionSkills.Collect()
        names = {}
        for i = 1, #result.cards do names[i] = result.cards[i].name end
        mageGarden = table.concat(names, ",")
    """)
    check("gardening row has no skill-line id", lua.eval("garden.id"), None)
    check("gardening stores the confirmed spell", lua.eval("garden.spell"), 1278062)
    check("gardening is hunter gated", lua.eval("garden.class"), "HUNTER")
    check("gardening row records the confirmation", lua.eval("garden.verified"), True)
    check("a hunter sees gardening by name", lua.eval("hunterNames"), "Blacksmithing,Gardening")
    check("a mage does not see gardening", lua.eval("mageGarden"), "Blacksmithing,Comprehension")


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


def test_retail_expansion_tier():
    """A level 80 warlock's parent skill lines are 0/100. Blizzard shows the
    expansion child that actually has points, and still lists unlearned
    secondaries.
    """
    lua = runtime()
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(r"""
        function GetProfessions() return 1, 2, nil, 4, nil, nil end
        function GetProfessionInfo(i)
            if i == 1 then return "Herbalism", 136065, 0, 100, 0, 0, 182 end
            if i == 2 then return "Mining", 134708, 0, 100, 0, 0, 186 end
            if i == 4 then return "Fishing", 136245, 0, 100, 0, 0, 356 end
        end
        local SKILL = {
            [2877] = { professionName = "Khaz Algar Herbalism", skillLevel = 4, maxSkillLevel = 100 },
            [2881] = { professionName = "Khaz Algar Mining", skillLevel = 4, maxSkillLevel = 100 },
            [2826] = { professionName = "Dragon Isles Fishing", skillLevel = 1, maxSkillLevel = 100 },
        }
        BY_LINE = 0
        C_TradeSkillUI = {
            GetProfessionInfoBySkillLineID = function(id)
                BY_LINE = BY_LINE + 1
                return SKILL[id] or { professionName = "Unknown", skillLevel = 0, maxSkillLevel = 0 }
            end,
        }
        local orig = ToonAge.Compat.GetProfessionInfoBySkillLineID
        function ToonAge.Compat.GetProfessionInfoBySkillLineID(id)
            COMPAT_LINES = (COMPAT_LINES or 0) + 1
            return orig(id)
        end
    """)
    load_reader(lua, "Data/Retail/ProfessionSkills.lua")
    lua.execute(r"""
        result = ToonAge.ProfessionSkills.Collect()
        local by = {}
        for _, card in ipairs(result.cards) do
            by[card.name] = card
        end
        HERB, MINE, FISH = by["Herbalism"], by["Mining"], by["Fishing"]
        COOK, ARCH = by["Cooking"], by["Archaeology"]
    """)
    check("retail tier reader is segments", lua.eval("result.reader"), "segments")
    check("child skill lines go through Compat", (lua.eval("COMPAT_LINES") or 0) > 0, True)
    check("herbalism shows the Khaz Algar tier", lua.eval("HERB.shownName"), "Khaz Algar Herbalism")
    check("herbalism rank is 4", lua.eval("HERB.shownRank"), 4)
    check("herbalism max is 100", lua.eval("HERB.shownMax"), 100)
    check("mining shows the Khaz Algar tier", lua.eval("MINE.shownName"), "Khaz Algar Mining")
    check("mining rank is 4", lua.eval("MINE.shownRank"), 4)
    check("fishing shows Dragon Isles, not a later empty tier",
          lua.eval("FISH.shownName"), "Dragon Isles Fishing")
    check("fishing rank is 1", lua.eval("FISH.shownRank"), 1)
    check("fishing stays secondary", lua.eval("FISH.secondary"), True)
    check("cooking is listed when unlearned", lua.eval("COOK.unlearned"), True)
    check("archaeology is listed when unlearned", lua.eval("ARCH.unlearned"), True)
    check("cooking is secondary", lua.eval("COOK.secondary"), True)
    check("archaeology is secondary", lua.eval("ARCH.secondary"), True)

    lua.execute("ToonAge.Utils = {}")
    lua.execute("function ToonAge:RegisterModule(name, mod) self[name] = mod end")
    lua.execute(FRAME)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(read("Modules/Character/ProfessionBoard.lua"))
    lua.execute(r"""
        PARENT = CreateFrame()
        PARENT.GetWidth = function() return 480 end
        TEXTS = {}
        local L = ToonAge.Layout
        local orig = L.ProfessionCard
        function L:ProfessionCard(parent, y, opts)
            TEXTS[#TEXTS + 1] = (opts.name or "") .. "|" .. (opts.subtitle or "")
                .. "|" .. (opts.rankText or "")
            return orig(self, parent, y, opts)
        end
        function L:SectionHeader(_, y) return y end
        function L:Paragraph(_, y) return y end
        function L:CharacterSidebar() end
        function L:Finish() end
        ToonAge.ProfessionBoard:Render(PARENT, PARENT)
        SHOWN = table.concat(TEXTS, "\n")
    """)
    shown = lua.eval("SHOWN") or ""
    check("the tab title stays Herbalism", "Herbalism|Khaz Algar Herbalism|4 / 100" in shown, True)
    check("the tab title stays Fishing", "Fishing|Dragon Isles Fishing|1 / 100" in shown, True)
    check("the tab says Cooking is not learned", "Cooking||Not learned" in shown, True)
    check("the tab says Archaeology is not learned", "Archaeology||Not learned" in shown, True)
    check("the tab does not show the parent 0/100", "Herbalism|0 / 100" in shown, False)


def test_christopher_midnight():
    """Midnight caps come from maxSkillLevel. Fishing is 108/300, not 0/100.
    Archaeology stays the parent line, 803/950.
    """
    lua = runtime()
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(r"""
        function GetProfessions() return 1, 2, 3, 4, nil, nil end
        function GetProfessionInfo(i)
            if i == 1 then return "Alchemy", 136240, 0, 100, 0, 0, 171 end
            if i == 2 then return "Herbalism", 136065, 0, 100, 0, 0, 182 end
            if i == 3 then return "Archaeology", 441139, 803, 950, 0, 0, 794 end
            if i == 4 then return "Fishing", 136245, 0, 100, 0, 0, 356 end
        end
        local SKILL = {
            [2485] = { professionName = "Classic Alchemy", skillLevel = 300,
                       maxSkillLevel = 300, expansionName = "Classic" },
            [2906] = { professionName = "Midnight Alchemy", skillLevel = 90,
                       maxSkillLevel = 100, expansionName = "Classic" },
            [2912] = { professionName = "Midnight Herbalism", skillLevel = 100,
                       maxSkillLevel = 100, expansionName = "The War Within" },
            [2592] = { professionName = "Classic Fishing", skillLevel = 300,
                       maxSkillLevel = 300 },
            [2911] = { professionName = "Midnight Fishing", skillLevel = 108,
                       maxSkillLevel = 300 },
        }
        C_TradeSkillUI = {
            GetProfessionInfoBySkillLineID = function(id)
                return SKILL[id] or { professionName = "Unknown", skillLevel = 0, maxSkillLevel = 0 }
            end,
        }
    """)
    load_reader(lua, "Data/Retail/ProfessionSkills.lua")
    lua.execute(r"""
        result = ToonAge.ProfessionSkills.Collect()
        local by = {}
        for _, card in ipairs(result.cards) do by[card.name] = card end
        ALCH, HERB, FISH, ARCH = by["Alchemy"], by["Herbalism"], by["Fishing"], by["Archaeology"]
        local lines = ToonAge.Data.ProfessionSkills.lines
        local byId = {}
        for _, line in ipairs(lines) do byId[line.id] = line end
        local tw = { 2871, 2872, 2873, 2874, 2875, 2876, 2877, 2878, 2879, 2880, 2881, 2882, 2883 }
        local mid = { 2906, 2907, 2908, 2909, 2910, 2911, 2912, 2913, 2914, 2915, 2916, 2917, 2918 }
        local parents = { 171, 164, 185, 333, 202, 356, 182, 773, 755, 165, 186, 393, 197 }
        BAD_ID = 0
        for i, parent in ipairs(parents) do
            local kids = byId[parent] and byId[parent].children
            if not kids or kids[11] ~= tw[i] or kids[12] ~= mid[i] then BAD_ID = BAD_ID + 1 end
        end
    """)
    check("midnight and war within child ids match", lua.eval("BAD_ID"), 0)
    check("alchemy shows the midnight child", lua.eval("ALCH.shownName"), "Midnight Alchemy")
    check("alchemy is 90", lua.eval("ALCH.shownRank"), 90)
    check("alchemy cap is the API max", lua.eval("ALCH.shownMax"), 100)
    check("herbalism is 100", lua.eval("HERB.shownRank"), 100)
    check("herbalism cap is the API max", lua.eval("HERB.shownMax"), 100)
    check("fishing shows midnight, not an older tier", lua.eval("FISH.shownName"), "Midnight Fishing")
    check("fishing rank is 108", lua.eval("FISH.shownRank"), 108)
    check("fishing cap is 300", lua.eval("FISH.shownMax"), 300)
    check("archaeology rank is 803", lua.eval("ARCH.rank"), 803)
    check("archaeology cap is 950", lua.eval("ARCH.max"), 950)
    check("archaeology has no child segments", lua.eval("ARCH.segments"), None)


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


def test_card_art():
    lua = runtime()
    lua.execute("ToonAge.Utils = {}")
    lua.execute(r"""
        local function Rec()
            local o = { shown = true, lines = {} }
            function o:SetFont() end
            function o:SetTextColor(r, g, b) self.r, self.g, self.b = r, g, b end
            function o:SetText(t) self.text = t end
            function o:SetJustifyH() end
            function o:ClearAllPoints() end
            function o:SetPoint() end
            function o:SetWidth() end
            function o:SetHeight() end
            function o:SetSize() end
            function o:SetWordWrap(v) self.wrap = v end
            function o:SetMaxLines(n) self.maxLines = n end
            function o:Show() self.shown = true end
            function o:Hide() self.shown = false end
            function o:SetParent() end
            function o:EnableMouse() end
            function o:SetScript(name, fn)
                self.scripts = self.scripts or {}
                self.scripts[name] = fn
            end
            function o:GetScript(name)
                return self.scripts and self.scripts[name]
            end
            function o:SetTexture() end
            function o:SetTexCoord() end
            function o:SetColorTexture(r, g, b, a) self._rgb = { r, g, b, a } end
            function o:CreateTexture() return Rec() end
            function o:CreateFontString() return Rec() end
            return o
        end
        CreateFrame = function() return Rec() end
        TIP = { lines = {} }
        function TIP:SetOwner() end
        function TIP:SetText() end
        function TIP:AddDoubleLine(label, value) self.lines[#self.lines + 1] = label .. "=" .. value end
        function TIP:Show() end
        function TIP:Hide() self.lines = {} end
        GameTooltip = TIP
    """)
    lua.execute(read("Core/Layout.lua"))
    lua.execute(r"""
        PARENT = CreateFrame()
        PARENT.GetWidth = function() return 480 end
        local _, blank = ToonAge.Layout:ProfessionCard(PARENT, -8, {
            name = "Cooking", rankText = "Not learned", rank = 0, max = 0,
        })
        BLANK_TRACK, BLANK_FILL = blank.track.shown, blank.fill.shown
        BLANK_RANK, BLANK_R, BLANK_G, BLANK_B = blank.rank.text, blank.rank.r, blank.rank.g, blank.rank.b
        BLANK_WRAP, BLANK_LINES = blank.name.wrap, blank.name.maxLines
        local _, titled = ToonAge.Layout:ProfessionCard(PARENT, -80, {
            name = "Alchemy", subtitle = "Midnight Alchemy",
            colorName = "Alchemy", skillLine = 171,
            rankText = "90 / 100", rank = 90, max = 100,
            segments = {
                { label = "Classic", rank = 0, max = 0 },
                { label = "Midnight", rank = 90, max = 100, current = true },
            },
        })
        TITLED = titled
        if titled:GetScript("OnEnter") then titled:GetScript("OnEnter")(titled) end
        TIP_LINES = table.concat(TIP.lines, "|")
        HUE = titled.fill._rgb or (titled.fills[1] and titled.fills[1]._rgb)
    """)
    check("a zero cap hides the bar", lua.eval("BLANK_TRACK"), False)
    check("a zero cap hides the fill", lua.eval("BLANK_FILL"), False)
    check("not learned is the rank text", lua.eval("BLANK_RANK"), "Not learned")
    check("not learned is muted",
          (round(lua.eval("BLANK_R"), 2), round(lua.eval("BLANK_G"), 2), round(lua.eval("BLANK_B"), 2)),
          (0.62, 0.59, 0.55))
    check("the name does not wrap", lua.eval("BLANK_WRAP"), False)
    check("the name is one line", lua.eval("BLANK_LINES"), 1)
    check("the tier is the subtitle", lua.eval("TITLED.sub.text"), "Midnight Alchemy")
    check("the title stays the base name", lua.eval("TITLED.name.text"), "Alchemy")
    check("colour follows the parent id, not the tier name",
          (round(lua.eval("HUE[1]"), 2), round(lua.eval("HUE[2]"), 2), round(lua.eval("HUE[3]"), 2)),
          (0.62, 0.36, 0.86))
    check("a zero cap segment is left out of the tooltip",
          "Classic" not in (lua.eval("TIP_LINES") or ""), True)
    check("a real tier is in the tooltip", "Midnight (current)=90 / 100" in (lua.eval("TIP_LINES") or ""), True)


def main():
    test_source_has_no_version_branch()
    test_retail_segments()
    test_retail_expansion_tier()
    test_christopher_midnight()
    test_mists_single_bar()
    test_header_filter("Data/TBC/ProfessionSkills.lua", 375, "tbc")
    test_header_filter("Data/Vanilla/ProfessionSkills.lua", 300, "era")
    test_forever_skillinfo()
    test_current_segment_is_gold()
    test_card_art()
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
