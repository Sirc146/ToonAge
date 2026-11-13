#!/usr/bin/env python3
"""
ToonAge -- Gear Stage 2 (Forever weights, tooltip lines, arrows)
=================================================================
Weights come only from the stored guide orders. Rank 1 weighs 1. With N
ranks, rank r weighs (N - r + 1) / N. A repeated stat does not take a second
rank. Names in one step share a rank. Several lists on one source keep the
highest weight, not an average. Two sources are never averaged.

The tooltip only appends lines. Arrows are non-secure and guarded. BIS is
read only after a loaded check. The new file is Forever's TOC only.

Usage:  python3 Tools/test_gear_stage2.py [-v]
"""
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python3 -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

ADVICE = "Modules/Forever/GearAdvice.lua"
PRIORITY = "Modules/Forever/StatPriority.lua"
DATA = "Data/Forever/StatPriority.lua"
FORBIDDEN = ("ForeverLevelingBiS", "MaxDps")


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


def strip_comments(text):
    return "\n".join(re.sub(r"--.*$", "", line) for line in text.splitlines())


def listed(name):
    rows = []
    for line in read(name).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        rows.append(s.split("[")[0].strip().replace("\\", "/"))
    return rows


def weights_from_steps(encoded):
    """Independent rank rule. encoded is 'A+B>C' with one step per rank."""
    seen = set()
    ranks = []
    if encoded:
        for step in encoded.split(">"):
            fresh = []
            for name in step.split("+"):
                if name and name not in seen:
                    seen.add(name)
                    fresh.append(name)
            if fresh:
                ranks.append(fresh)
    n = len(ranks)
    out = {}
    for i, group in enumerate(ranks, 1):
        weight = (n - i + 1) / n
        for name in group:
            out[name] = weight
    return out


def weights_for_source(encoded_lists):
    best = {}
    for encoded in encoded_lists:
        for stat, weight in weights_from_steps(encoded).items():
            if stat not in best or weight > best[stat]:
                best[stat] = weight
    return best


def parse_weights(text):
    out = {}
    if not text:
        return out
    for part in str(text).split(","):
        if not part:
            continue
        key, value = part.split("=")
        out[key] = float(value)
    return out


def maps_close(got, want):
    if set(got) != set(want):
        return False
    return all(abs(got[k] - want[k]) < 1e-6 for k in got)


def main():
    for rel in (DATA, PRIORITY, ADVICE):
        check(f"{rel} exists", (ROOT / rel).is_file(), True)

    camelot = listed("ToonAge_Camelot.toc")
    check("Camelot lists GearAdvice", "Modules/Forever/GearAdvice.lua" in camelot, True)
    for toc in sorted(p.name for p in ROOT.glob("*.toc")):
        if toc == "ToonAge_Camelot.toc":
            continue
        check(f"{toc} does not list GearAdvice", "GearAdvice.lua" in read(toc), False)

    priority = read(PRIORITY)
    advice = read(ADVICE)
    advice_code = strip_comments(advice)
    check("rank rule is written next to the weights", "(N - r + 1) / N" in priority, True)
    check("weights are labeled level 60 guide order", "level 60 guide order" in priority, True)
    check("leveling brackets are called UNVERIFIED", "UNVERIFIED" in priority and "leveling" in priority, True)
    check("advice does not invent a leveling weight table",
          "levelingWeights" in advice or "bracketWeights" in advice, False)

    for rel in (ADVICE, PRIORITY):
        body = read(rel)
        for word in ("TODO", "FIXME", "placeholder"):
            check(f"{rel} has no {word}", word.lower() in body.lower(), False)

    check("tooltip code has no ClearLines", "ClearLines" in advice_code, False)
    check("tooltip code has no SetText", re.search(r"\bSetText\b", advice_code) is not None, False)
    check("tooltip code appends with AddLine", "AddLine" in advice_code, True)
    check("arrows do not set secure attributes", "SetAttribute" in advice_code, False)
    check("arrows use a texture", "CreateTexture" in advice_code, True)
    check("arrows guard combat", "InCombatLockdown" in advice_code, True)
    check("arrows guard protected frames", "IsProtected" in advice_code, True)
    check("frame hooks are skipped when the global is missing",
          "type(_G[name]) ~= \"function\"" in advice_code, True)
    check("advice does not average scores", "average" in advice_code.lower(), False)

    loaded_at = advice.find('self:AddonLoaded("BIS")')
    info_at = advice.find("bis.UpgradeInfo")
    check("BIS UpgradeInfo is behind the loaded check",
          loaded_at >= 0 and info_at > loaded_at, True)
    writes = []
    for line in advice_code.splitlines():
        if re.search(r"\bBIS\s*=", line) or re.search(r"\bBIS\s*\[", line):
            writes.append(line.strip())
        if re.search(r"UpgradeInfo\s*=", line):
            writes.append(line.strip())
    check("advice does not write BIS", writes, [])

    licence_hits = []
    for rel in listed("ToonAge_Camelot.toc"):
        if not rel.endswith(".lua"):
            continue
        path = ROOT / rel
        if not path.is_file():
            continue
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if any(name in line for name in FORBIDDEN):
                ok = line.strip().startswith("--") and "All Rights Reserved" in line
                if not ok:
                    licence_hits.append(f"{rel}:{lineno}")
    check("Forever files name those addons only in a licence comment", licence_hits, [])

    if not (ROOT / ADVICE).is_file():
        passed = sum(_results)
        print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
        return 0 if passed == len(_results) else 1

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
ToonAge = { Data = {}, db = {}, IsForever = true }
function ToonAge:HasAPI() return true end
items = {
    ["item:new"] = {
        equip = "INVTYPE_CHEST",
        stats = {
            ITEM_MOD_INTELLECT_SHORT = 10,
            ITEM_MOD_SPIRIT_SHORT = 10,
            ITEM_MOD_MASTERY_SHORT = 50,
        },
    },
    ["item:old"] = {
        equip = "INVTYPE_CHEST",
        stats = { ITEM_MOD_INTELLECT_SHORT = 1 },
    },
    ["item:big"] = {
        equip = "INVTYPE_CHEST",
        stats = { ITEM_MOD_INTELLECT_SHORT = 100 },
    },
    ["item:haste"] = {
        equip = "INVTYPE_CHEST",
        stats = { ITEM_MOD_HASTE_RATING_SHORT = 10 },
    },
}
equipped = "item:old"
specName = "Frost"
bisCalls = 0
statCalls = 0
ToonAge.Compat = {
    GetItemStats = function(link)
        statCalls = statCalls + 1
        local row = items[link]
        return row and row.stats or nil
    end,
    GetItemInfo = function(link)
        local row = items[link]
        if not row then return nil end
        return "Item", link, 2, 10, 1, "Armor", "Cloth", 1, row.equip
    end,
    GetInventoryItemLink = function(unit, slot)
        if slot == 5 then return equipped end
        return nil
    end,
    IsEquippableItem = function() return true end,
    IsAddOnLoaded = function() return false end,
    UnitClass = function() return "Mage", "MAGE" end,
    GetContainerNumSlots = function() return 1 end,
    GetContainerItemLink = function() return "item:new" end,
    GetNumLootItems = function() return nil end,
    GetLootSlotLink = function() return nil end,
    GetNumQuestChoices = function() return nil end,
    GetNumQuestRewards = function() return nil end,
    GetQuestItemLink = function() return nil end,
}
ToonAge.Utils = { GetPlayerSpec = function() return 1, specName end }
""")
    lua.execute(read(DATA))
    lua.execute(read(PRIORITY))
    lua.execute(read(ADVICE))
    lua.execute(r"""
function ExportSteps(list)
    local parts = {}
    for _, step in ipairs(list.stats or {}) do
        if type(step) == "table" then
            local names = {}
            for _, name in ipairs(step) do names[#names + 1] = tostring(name) end
            parts[#parts + 1] = table.concat(names, "+")
        else
            parts[#parts + 1] = tostring(step)
        end
    end
    return table.concat(parts, ">")
end
function ExportSource(source)
    local parts = {}
    for _, list in ipairs(source.lists or {}) do
        parts[#parts + 1] = ExportSteps(list)
    end
    return table.concat(parts, "|")
end
function WeightString(source)
    local w = ToonAge.StatPriority:WeightsForSource(source)
    local keys = {}
    for k in pairs(w) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        parts[#parts + 1] = k .. "=" .. string.format("%.6f", w[k])
    end
    return table.concat(parts, ",")
end
function RoundFor(spec, sourceName, itemKey, equippedKey)
    local entry = ToonAge.StatPriority:Get("MAGE", spec)
    local src
    for _, row in ipairs(ToonAge.StatPriority:Rows(entry)) do
        for _, s in ipairs(row.sources or {}) do
            if s.name == sourceName then src = s end
        end
    end
    local w = ToonAge.StatPriority:WeightsForSource(src)
    local item = ToonAge.StatPriority:ScoreStats(items[itemKey].stats, w)
    local eq = 0
    if equippedKey then eq = ToonAge.StatPriority:ScoreStats(items[equippedKey].stats, w) end
    local pct
    if eq > 0 then pct = (item - eq) / eq * 100
    elseif item > 0 then pct = 100
    else pct = 0 end
    return math.floor(pct + 0.5)
end
function SuggestionDump(link)
    local rows = ToonAge.GearAdvice:Suggestions(link)
    local parts = {}
    for _, row in ipairs(rows) do
        parts[#parts + 1] = table.concat({
            tostring(row.name), tostring(row.verdict), tostring(row.rounded),
            tostring(row.text), tostring(row.cap or ""),
            string.format("%.2f", row.r), string.format("%.2f", row.g), string.format("%.2f", row.b),
        }, "\t")
    end
    return table.concat(parts, "\n")
end
""")

    mismatches = []

    def accept(label, encoded, got):
        lists = str(encoded).split("|") if encoded else []
        want = weights_for_source(lists)
        parsed = parse_weights(got)
        if not maps_close(parsed, want):
            mismatches.append(f"{label}: got {got} want {want}")

    lua.globals().py_accept = accept
    lua.execute(r"""
local made = {
    lists = {
        { stats = { "Hit", "Hit", { "Crit", "Agility" }, "Stamina" } },
        { stats = { "Stamina", "Hit" } },
    },
}
py_accept("constructed", ExportSource(made), WeightString(made))
for className, classTbl in pairs(ToonAge.Data.ForeverStatPriority) do
    for spec, entry in pairs(classTbl) do
        for _, row in ipairs(ToonAge.StatPriority:Rows(entry)) do
            for i, src in ipairs(row.sources or {}) do
                local label = className .. "/" .. spec .. "/" .. tostring(row.label or "")
                    .. "/" .. tostring(src.name) .. "#" .. i
                py_accept(label, ExportSource(src), WeightString(src))
            end
        end
    end
end
""")
    check("every stored order matches the rank rule, with no averaging inside a source",
          mismatches, [])

    sp = lua.eval("ToonAge.StatPriority")
    hit = float(lua.eval('ToonAge.StatPriority:WeightsForSource(ToonAge.StatPriority:Get("MAGE","Frost").sources[1]).Hit'))
    check("Frost Icy Veins Hit stays weight 1 (17% is not applied as a cap)", hit, 1.0)
    lua.execute("""
        local w = ToonAge.StatPriority:WeightsForSource(ToonAge.StatPriority:Get("MAGE","Frost").sources[1])
        local withMastery = ToonAge.StatPriority:ScoreStats(items["item:new"].stats, w)
        local plain = {
            ITEM_MOD_INTELLECT_SHORT = 10,
            ITEM_MOD_SPIRIT_SHORT = 10,
        }
        masterySame = withMastery == ToonAge.StatPriority:ScoreStats(plain, w)
    """)
    check("an unknown stat adds 0", bool(lua.eval("masterySame")), True)
    check("order label", str(sp.OrderLabel(sp)), "level 60 guide order")

    def dump_rows(link):
        text = str(lua.eval(f'SuggestionDump("{link}")'))
        rows = []
        if text:
            for line in text.split("\n"):
                name, verdict, rounded, body, cap, r, g, b = line.split("\t")
                rows.append({
                    "name": name, "verdict": verdict, "rounded": int(rounded),
                    "text": body, "cap": cap, "r": float(r), "g": float(g), "b": float(b),
                })
        return rows

    both = dump_rows("item:new")
    names = [row["name"] for row in both]
    check("both view returns one line per source", names, ["Icy Veins", "Wowhead"])
    expected = {
        "Icy Veins": int(lua.eval('RoundFor("Frost", "Icy Veins", "item:new", "item:old")')),
        "Wowhead": int(lua.eval('RoundFor("Frost", "Wowhead", "item:new", "item:old")')),
    }
    got_rounds = {row["name"]: row["rounded"] for row in both}
    check("both view uses each source's own percent", got_rounds, expected)
    check("the two source percents differ", expected["Icy Veins"] != expected["Wowhead"], True)
    mean = (expected["Icy Veins"] + expected["Wowhead"]) / 2
    check("neither shown percent is the average of the two",
          expected["Icy Veins"] != mean and expected["Wowhead"] != mean, True)
    for row in both:
        check(f"{row['name']} line is a suggestion from the level 60 order",
              "suggestion" in row["text"] and "level 60 guide order" in row["text"]
              and "upgrade" in row["text"], True)
        check(f"{row['name']} upgrade is green", row["g"] > 0.8 and row["r"] < 0.5, True)
        check(f"{row['name']} cap stays text", "text only" in row["cap"] and "%" in row["cap"], True)

    lua.execute('ToonAge.StatPriority:SetView("iv")')
    iv_only = [row["name"] for row in dump_rows("item:new")]
    check("iv view shows only Icy Veins", iv_only, ["Icy Veins"])
    lua.execute('ToonAge.StatPriority:SetView("wh")')
    wh_only = [row["name"] for row in dump_rows("item:new")]
    check("wh view shows only Wowhead", wh_only, ["Wowhead"])
    lua.execute('ToonAge.StatPriority:SetView("both")')

    lua.execute('equipped = "item:big"')
    down = dump_rows("item:new")
    check("a lower score is a downgrade on both sources",
          [row["verdict"] for row in down], ["downgrade", "downgrade"])
    check("downgrade is red", down[0]["r"] > 0.8 and down[0]["g"] < 0.5, True)
    check("downgrade text says downgrade", "downgrade" in down[0]["text"], True)
    lua.execute('equipped = nil')
    empty = dump_rows("item:new")
    check("an empty slot is named", "empty slot" in empty[0]["text"], True)
    lua.execute('equipped = "item:old"')

    lua.execute('specName = "Arcane"')
    disagree = {row["name"]: row["verdict"] for row in dump_rows("item:haste")}
    check("Haste is an upgrade only on the guide that ranks it",
          disagree, {"Icy Veins": "downgrade", "Wowhead": "upgrade"})
    check("both view hides the arrow unless both sources agree",
          bool(lua.eval('ToonAge.GearAdvice:IsUpgrade("item:haste")')), False)
    lua.execute('specName = "Frost"')
    check("both sources agreeing marks an upgrade",
          bool(lua.eval('ToonAge.GearAdvice:IsUpgrade("item:new")')), True)

    host = ["Frostweave Tunic", "Binds when equipped"]
    lua.execute(r"""
appendResult = "ok"
tipLines = { "Frostweave Tunic", "Binds when equipped" }
tipColors = {}
local tip = {
    GetName = function() return "GameTooltip" end,
    lines = tipLines,
    AddLine = function(self, text, r, g, b)
        self.lines[#self.lines + 1] = text
        tipColors[#tipColors + 1] = { r, g, b }
    end,
    ClearLines = function() error("ClearLines") end,
    SetText = function() error("SetText") end,
}
local ok, err = pcall(function()
    ToonAge.GearAdvice:AppendSuggestions(tip, "item:new")
end)
appendResult = ok and "ok" or tostring(err)
""")
    check("append does not clear or rewrite the host tooltip", str(lua.eval("appendResult")), "ok")
    after = [str(line) for line in lua.eval("tipLines").values()]
    check("host lines stay in place", after[:2], host)
    check("appended lines follow the host lines", len(after) > 2, True)
    check("appended text is only added after the host", after[0], host[0])

    lua.execute('ToonAge.db.foreverGearTooltip = false')
    lua.execute(r"""
hiddenAdds = 0
local tip = {
    GetName = function() return "GameTooltip" end,
    AddLine = function() hiddenAdds = hiddenAdds + 1 end,
    ClearLines = function() error("ClearLines") end,
    SetText = function() error("SetText") end,
}
ToonAge.GearAdvice:AppendSuggestions(tip, "item:new")
""")
    check("tooltip toggle off adds no line", int(lua.eval("hiddenAdds")), 0)
    lua.execute('ToonAge.db.foreverGearTooltip = nil')

    lua.execute(r"""
bisCalls = 0
BIS = { UpgradeInfo = function() bisCalls = bisCalls + 1; return "hidden" end }
""")
    check("BIS is not read while the addon is unloaded",
          lua.eval('ToonAge.GearAdvice:BisLine("item:new")'), None)
    check("unloaded BIS function was not called", int(lua.eval("bisCalls")), 0)
    lua.execute(r"""
ToonAge.Compat.IsAddOnLoaded = function(name) return name == "BIS" end
BIS = { UpgradeInfo = function(link) return "plus 4" end }
""")
    check("loaded BIS string is labeled",
          str(lua.eval('ToonAge.GearAdvice:BisLine("item:new")')),
          "BIS (other addon): plus 4")
    lua.execute('BIS = { UpgradeInfo = function() return { text = "ring" } end }')
    check("loaded BIS table text is labeled",
          str(lua.eval('ToonAge.GearAdvice:BisLine("item:new")')),
          "BIS (other addon): ring")
    lua.execute("BIS = { UpgradeInfo = nil }")
    check("loaded BIS without UpgradeInfo adds nothing",
          lua.eval('ToonAge.GearAdvice:BisLine("item:new")'), None)
    lua.execute('BIS = "not a table"')
    check("a BIS global that is not a table adds nothing",
          lua.eval('ToonAge.GearAdvice:BisLine("item:new")'), None)
    lua.execute("ToonAge.Compat.IsAddOnLoaded = function() return false end")

    lua.execute(r"""
statCalls = 0
local saved = ToonAge.HasAPI
function ToonAge:HasAPI(path)
    if path == "C_Item.GetItemStats" or path == "GetItemStats" then return false end
    return true
end
blocked = ToonAge.GearAdvice:ReadItemStats("item:new")
blockedCalls = statCalls
ToonAge.HasAPI = saved
""")
    check("missing stat APIs are not called", lua.eval("blocked"), None)
    check("GetItemStats was not entered", int(lua.eval("blockedCalls")), 0)

    lua.execute(r"""
arrowShown = false
arrowCreated = 0
InCombatLockdown = function() return false end
NUM_CONTAINER_FRAMES = 1
ContainerFrame1 = {
    GetName = function() return "ContainerFrame1" end,
    GetID = function() return 0 end,
}
ContainerFrame1Item1 = {
    CreateTexture = function(self)
        arrowCreated = arrowCreated + 1
        return {
            SetSize = function() end,
            SetPoint = function() end,
            SetTexture = function() end,
            SetVertexColor = function() end,
            Hide = function(self) self.visible = false end,
            Show = function(self) self.visible = true; arrowShown = true end,
        }
    end,
    IsProtected = function() return true end,
}
LootFrame = nil
ToonAge.GearAdvice:RefreshBags()
ToonAge.GearAdvice:RefreshLoot()
ToonAge.GearAdvice:RefreshQuest()
""")
    check("bag arrow shows when both sources agree", bool(lua.eval("arrowShown")), True)
    check("arrow texture was created once", int(lua.eval("arrowCreated")), 1)
    check("loot refresh skips a missing loot frame", True, True)

    lua.execute(r"""
combatCreated = 0
InCombatLockdown = function() return true end
ContainerFrame1Item1 = {
    CreateTexture = function() combatCreated = combatCreated + 1; error("created in combat") end,
    IsProtected = function() return true end,
}
local ok = pcall(function() ToonAge.GearAdvice:RefreshBags() end)
combatOk = ok
frameBlocked = ToonAge.GearAdvice:FrameOk(ContainerFrame1Item1) == false
InCombatLockdown = function() return false end
frameOpen = ToonAge.GearAdvice:FrameOk(ContainerFrame1Item1) == true
""")
    check("combat refresh does not touch a protected button",
          bool(lua.eval("combatOk")) and int(lua.eval("combatCreated")) == 0, True)
    check("protected frame is refused in combat", bool(lua.eval("frameBlocked")), True)
    check("the same frame is usable out of combat", bool(lua.eval("frameOpen")), True)

    lua.execute(r"""
offCreated = 0
ContainerFrame1Item1 = {
    CreateTexture = function() offCreated = offCreated + 1 end,
    IsProtected = function() return false end,
}
ToonAge.db.foreverGearArrows = false
ToonAge.GearAdvice:RefreshBags()
""")
    check("arrow toggle off creates no overlay", int(lua.eval("offCreated")), 0)

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
