#!/usr/bin/env python3
"""
ToonAge -- Forever gear tooltip: no BIS echo, caps only on Hit items
=====================================================================
ToonAge's own suggestion lines stay. Another addon's BIS number is not
echoed, even when _G.BIS.UpgradeInfo is present. Cap text ("names these
caps as text only") is shown only when the hovered item's stats include a
key Modules/Forever/StatPriority.lua maps to Hit.

Usage:  python3 Tools/test_gear_tooltip_bis_caps.py [-v]
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

# Named in the request. A cap is allowed for one of these only when
# StatPriority's ITEM_KEY actually maps that key to Hit.
HIT_KEY_CANDIDATES = (
    "ITEM_MOD_HIT_RATING_SHORT",
    "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    "ITEM_MOD_HIT_SHORT",
)


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


def mapped_hit_keys(text):
    """Item-stat keys whose StatPriority ITEM_KEY value is Hit."""
    start = text.find("local ITEM_KEY = {")
    if start < 0:
        return []
    end = text.find("\n}", start)
    block = text[start:end]
    keys = []
    for line in block.splitlines():
        code = re.sub(r"--.*$", "", line)
        match = re.match(r'\s*([A-Za-z0-9_]+)\s*=\s*"Hit"\s*,?\s*$', code)
        if match:
            keys.append(match.group(1))
    return keys


def parse_dump(text):
    rows = []
    if not text:
        return rows
    for line in str(text).split("\n"):
        if not line:
            continue
        name, verdict, rounded, body, cap, red, green, blue = line.split("\t")
        rows.append({
            "name": name,
            "verdict": verdict,
            "rounded": int(rounded),
            "text": body,
            "cap": cap,
            "r": float(red),
            "g": float(green),
            "b": float(blue),
        })
    return rows


def main():
    advice = read(ADVICE)
    advice_code = strip_comments(advice)
    mapped = mapped_hit_keys(read(PRIORITY))
    check("StatPriority maps at least one item key to Hit", len(mapped) > 0, True)
    check("the Hit mapping is a subset of the known Hit item keys",
          all(key in HIT_KEY_CANDIDATES for key in mapped), True)

    check("advice never builds a BIS (other addon) line",
          "BIS (other addon)" in advice, False)
    check("advice does not read UpgradeInfo", "UpgradeInfo" in advice_code, False)
    check("BisLine is gone", "BisLine" in advice_code, False)
    check("BisText is gone", "BisText" in advice_code, False)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
ToonAge = { Data = {}, db = {}, IsForever = true }
function ToonAge:HasAPI() return true end
items = {
    ["item:worn"] = {
        equip = "INVTYPE_CLOAK",
        stats = { ITEM_MOD_INTELLECT_SHORT = 1 },
    },
    ["item:cloak"] = {
        equip = "INVTYPE_CLOAK",
        stats = {
            ITEM_MOD_INTELLECT_SHORT = 10,
            ITEM_MOD_SPIRIT_SHORT = 10,
        },
    },
}
equipped = "item:worn"
specName = "Frost"
bisCalls = 0
ToonAge.Compat = {
    GetItemStats = function(link)
        local row = items[link]
        return row and row.stats or nil
    end,
    GetItemInfo = function(link)
        local row = items[link]
        if not row then return nil end
        return "Item", link, 2, 10, 1, "Armor", "Cloth", 1, row.equip
    end,
    GetInventoryItemLink = function(unit, slot)
        if slot == 15 then return equipped end
        return nil
    end,
    IsEquippableItem = function() return true end,
    IsAddOnLoaded = function() return false end,
    UnitClass = function() return "Mage", "MAGE" end,
}
ToonAge.Utils = { GetPlayerSpec = function() return 1, specName end }
""")
    lua.execute(read(DATA))
    lua.execute(read(PRIORITY))
    lua.execute(read(ADVICE))
    lua.execute(r"""
function LineContract(srcName, rowLabel, rounded, emptySlot, orderLabel)
    local where = emptySlot and "empty slot" or "equipped"
    local who = tostring(srcName or "Guide") .. " order"
    if type(rowLabel) == "string" and rowLabel ~= "" then
        who = who .. ", " .. rowLabel
    end
    who = who .. ", " .. orderLabel
    if rounded > 0 then
        return string.format("ToonAge: suggestion, upgrade vs %s (%s) +%d%%", where, who, rounded)
    elseif rounded < 0 then
        return string.format("ToonAge: suggestion, downgrade vs %s (%s) %d%%", where, who, rounded)
    end
    return string.format("ToonAge: suggestion, same as %s (%s)", where, who)
end

function CapContract(srcName, phrases)
    if type(phrases) ~= "table" or #phrases == 0 then return "" end
    local text = "ToonAge: suggestion, " .. tostring(srcName or "Guide")
        .. " names these caps as text only (not in the score): "
        .. table.concat(phrases, "; ")
    if #text > 220 then text = text:sub(1, 217) .. "..." end
    return text
end

function Contract(link)
    local SP = ToonAge.StatPriority
    local entry = SP:Get("MAGE", specName)
    local parts = {}
    for _, row in ipairs(SP:Rows(entry)) do
        for _, src in ipairs(row.sources or {}) do
            if type(src) == "table" and SP:SourceVisible(src.name) then
                local weights = SP:WeightsForSource(src)
                local itemScore = SP:ScoreStats(items[link].stats, weights)
                local eq, emptySlot = 0, true
                if type(equipped) == "string" and items[equipped] then
                    eq = SP:ScoreStats(items[equipped].stats, weights)
                    emptySlot = false
                end
                local pct
                if eq > 0 then
                    pct = (itemScore - eq) / eq * 100
                elseif itemScore > 0 then
                    pct = 100
                else
                    pct = 0
                end
                local rounded = math.floor(pct + 0.5)
                local verdict = "same"
                if rounded > 0 then verdict = "upgrade"
                elseif rounded < 0 then verdict = "downgrade" end
                parts[#parts + 1] = table.concat({
                    tostring(src.name), verdict, tostring(rounded),
                    LineContract(src.name, row.label, rounded, emptySlot, SP:OrderLabel()),
                    CapContract(src.name, SP:CapPhrases(src)),
                }, "\t")
            end
        end
    end
    return table.concat(parts, "\n")
end

function Dump(link)
    local parts = {}
    for _, row in ipairs(ToonAge.GearAdvice:Suggestions(link)) do
        parts[#parts + 1] = table.concat({
            tostring(row.name), tostring(row.verdict), tostring(row.rounded),
            tostring(row.text), tostring(row.cap or ""),
            string.format("%.2f", row.r), string.format("%.2f", row.g), string.format("%.2f", row.b),
        }, "\t")
    end
    return table.concat(parts, "\n")
end

function CollectLines(link)
    local lines = {}
    local tip = {
        GetName = function() return "GameTooltip" end,
        AddLine = function(self, text)
            lines[#lines + 1] = tostring(text)
        end,
        ClearLines = function() error("ClearLines") end,
        SetText = function() error("SetText") end,
    }
    local host = { "Woolen Cloak", "Binds when equipped" }
    tip.lines = { host[1], host[2] }
    local real = tip.AddLine
    tip.AddLine = function(self, text, r, g, b)
        self.lines[#self.lines + 1] = text
        real(self, text, r, g, b)
    end
    local ok, err = pcall(function()
        ToonAge.GearAdvice:AppendSuggestions(tip, link)
    end)
    if not ok then return "ERROR\t" .. tostring(err) end
    if tip.lines[1] ~= host[1] or tip.lines[2] ~= host[2] then
        return "HOST"
    end
    local added = {}
    for i = 3, #tip.lines do added[#added + 1] = tip.lines[i] end
    return table.concat(added, "\n")
end
""")

    def add_item(name, extra):
        stats = [
            "ITEM_MOD_INTELLECT_SHORT = 10",
            "ITEM_MOD_SPIRIT_SHORT = 10",
        ]
        for key, amount in extra.items():
            stats.append(f"{key} = {amount}")
        lua.execute(
            'items["%s"] = { equip = "INVTYPE_CLOAK", stats = { %s } }'
            % (name, ", ".join(stats))
        )

    for key in mapped:
        add_item("item:hit:" + key, {key: 20})
    for key in HIT_KEY_CANDIDATES:
        if key not in mapped:
            add_item("item:other:" + key, {key: 40})

    colors = {"upgrade": (0.30, 0.92, 0.40), "downgrade": (1.00, 0.35, 0.30), "same": (0.62, 0.59, 0.55)}

    def assert_suggestions(link, expect_cap, label):
        actual = parse_dump(str(lua.eval(f'Dump("{link}")')))
        contract = []
        raw = str(lua.eval(f'Contract("{link}")'))
        if raw:
            for line in raw.split("\n"):
                name, verdict, rounded, body, cap = line.split("\t")
                contract.append({
                    "name": name, "verdict": verdict, "rounded": int(rounded),
                    "text": body, "cap": cap,
                })
        check(f"{label}: one suggestion per visible source", len(actual), len(contract))
        if len(actual) != len(contract):
            return actual
        for got, want in zip(actual, contract):
            check(f"{label}: {got['name']} suggestion has no percent", "%" not in got["text"], True)
            check(f"{label}: {got['name']} percent unchanged", got["rounded"], want["rounded"])
            check(f"{label}: {got['name']} verdict unchanged", got["verdict"], want["verdict"])
            red, green, blue = colors[want["verdict"]]
            check(f"{label}: {got['name']} color unchanged",
                  (got["r"], got["g"], got["b"]), (red, green, blue))
            check(f"{label}: {got['name']} suggestion is not a cap line",
                  "names these caps as text only" not in got["text"], True)
            if expect_cap:
                check(f"{label}: {got['name']} cap line present", got["cap"], want["cap"])
                check(f"{label}: {got['name']} cap is text only",
                      got["cap"].startswith("ToonAge: suggestion, ")
                      and "names these caps as text only (not in the score): " in got["cap"]
                      and "%" in got["cap"], True)
            else:
                check(f"{label}: {got['name']} cap line absent", got["cap"], "")
        return actual

    cloak = assert_suggestions("item:cloak", False, "cloak without Hit")
    hit_rows = []
    for key in mapped:
        hit_rows.append(assert_suggestions("item:hit:" + key, True, f"item with {key}"))
    for key in HIT_KEY_CANDIDATES:
        if key not in mapped:
            assert_suggestions("item:other:" + key, True, f"item with {key} and no global")

    if cloak and hit_rows and hit_rows[0]:
        cloak_pct = {row["name"]: row["rounded"] for row in cloak}
        hit_pct = {row["name"]: row["rounded"] for row in hit_rows[0]}
        check("Hit still changes the suggestion percent", cloak_pct != hit_pct, True)
        if len(HIT_KEY_CANDIDATES) > len(mapped):
            other_key = next(key for key in HIT_KEY_CANDIDATES if key not in mapped)
            other = parse_dump(str(lua.eval(f'Dump("item:other:{other_key}")')))
            other_rounded = {row["name"]: row["rounded"] for row in other}
            cloak_rounded = {row["name"]: row["rounded"] for row in cloak}
            check("an unmapped Hit-like key does not change the score",
                  other_rounded, cloak_rounded)

    links = ["item:cloak"] + [f"item:hit:{key}" for key in mapped]
    for key in HIT_KEY_CANDIDATES:
        if key not in mapped:
            links.append("item:other:" + key)

    shapes = (
        'return "plus 4"',
        "return 17",
        'return { text = "ring" }',
        'return { label = "neck" }',
        'return { "cloak" }',
        'error("boom")',
    )
    for link in links:
        lua.execute("""
_G.BIS = nil
BIS = nil
bisCalls = 0
ToonAge.Compat.IsAddOnLoaded = function() return false end
""")
        quiet = str(lua.eval(f'CollectLines("{link}")'))
        check(f"{link}: append keeps the host tooltip", quiet.startswith("ERROR") or quiet == "HOST", False)
        for shape in shapes:
            lua.execute(f"""
bisCalls = 0
_G.BIS = {{
    UpgradeInfo = function()
        bisCalls = bisCalls + 1
        {shape}
    end,
}}
BIS = _G.BIS
ToonAge.Compat.IsAddOnLoaded = function(name) return name == "BIS" end
""")
            echoed = str(lua.eval(f'CollectLines("{link}")'))
            produced = [ln for ln in echoed.split("\n") if ln.startswith("BIS (other addon)")]
            check(f"{link}: no BIS line when UpgradeInfo does [{shape}]", produced, [])
            check(f"{link}: UpgradeInfo was not called for [{shape}]",
                  int(lua.eval("bisCalls")), 0)
            check(f"{link}: suggestion lines unchanged with a fake BIS addon [{shape}]",
                  echoed, quiet)

    lua.execute("_G.BIS = nil; BIS = nil")
    lua.execute("ToonAge.Compat.IsAddOnLoaded = function() return false end")

    settings = read("Modules/Infrastructure/Settings.lua")
    check("settings offers Defer gear scoring to Polestar/Pawn",
          "Defer gear scoring to Polestar/Pawn" in settings and "foreverGearDefer" in settings, True)
    check("advice does not call Pawn, Polestar, or BIS globals",
          any(token in advice_code for token in (
              "_G.Pawn", "_G.Polestar", "_G.ForeverLevelingBiS", "_G.BIS", "UpgradeInfo",
          )), False)

    lua.execute(r"""
playerLevel = 60
ToonAge.Compat.UnitLevel = function() return playerLevel end
scorerProbes = 0
local function trap()
    return setmetatable({}, { __index = function() scorerProbes = scorerProbes + 1 end })
end
_G.Polestar = trap()
_G.ForeverLevelingBiS = trap()
_G.Pawn = trap()
function DisplayDump(link)
    local parts = {}
    for _, line in ipairs(ToonAge.GearAdvice:DisplayLines(link)) do
        parts[#parts + 1] = table.concat({
            line.text,
            string.format("%.2f", line.r),
            string.format("%.2f", line.g),
            string.format("%.2f", line.b),
        }, "\t")
    end
    return table.concat(parts, "\n")
end
""")

    def display(link):
        raw = str(lua.eval(f'DisplayDump("{link}")'))
        rows = []
        if raw:
            for line in raw.split("\n"):
                body, red, green, blue = line.split("\t")
                rows.append({"text": body, "r": float(red), "g": float(green), "b": float(blue)})
        return rows

    def line_texts(rows):
        return [row["text"] for row in rows]

    def no_percent(rows):
        return all("%" not in row["text"] for row in rows)

    lua.execute(r"""
ToonAge.db.foreverGearDefer = nil
ToonAge.db.foreverGearTooltip = nil
scorerProbes = 0
ToonAge.Compat.IsAddOnLoaded = function(name) return name == "Polestar" end
""")
    polestar = display("item:cloak")
    check("Polestar loaded: in-charge line and no percent",
          line_texts(polestar), ["ToonAge: Polestar is scoring gear"])
    check("Polestar loaded: the line is dim",
          (polestar[0]["r"], polestar[0]["g"], polestar[0]["b"]), (0.62, 0.59, 0.55))
    check("Polestar loaded: addon globals were not read", int(lua.eval("scorerProbes")), 0)

    lua.execute('ToonAge.Compat.IsAddOnLoaded = function(name) return name == "Pawn" end')
    pawn = display("item:cloak")
    check("Pawn loaded: Pawn is in charge and no percent",
          line_texts(pawn), ["ToonAge: Pawn is scoring gear"])
    check("Pawn loaded: addon globals were not read", int(lua.eval("scorerProbes")), 0)

    lua.execute('''ToonAge.Compat.IsAddOnLoaded = function(name)
        return name == "Polestar" or name == "Pawn" end''')
    check("Polestar and Pawn loaded: Polestar wins",
          line_texts(display("item:cloak")),
          ["ToonAge: Polestar is scoring gear"])

    lua.execute('ToonAge.Compat.IsAddOnLoaded = function(name) return name == "ForeverLevelingBiS" end')
    check("Forever Leveling BiS alone names itself",
          line_texts(display("item:cloak")),
          ["ToonAge: Forever Leveling BiS is scoring gear"])

    lua.execute('''ToonAge.Compat.IsAddOnLoaded = function(name)
        return name == "ForeverLevelingBiS" or name == "Pawn" end''')
    check("Forever Leveling BiS outranks Pawn",
          line_texts(display("item:cloak")),
          ["ToonAge: Forever Leveling BiS is scoring gear"])

    lua.execute('''ToonAge.Compat.IsAddOnLoaded = function(name)
        return name == "Polestar" or name == "ForeverLevelingBiS" end''')
    check("Polestar and Forever Leveling BiS use the combined name",
          line_texts(display("item:cloak")),
          ["ToonAge: Polestar (Forever Leveling BiS) is scoring gear"])

    lua.execute(r"""
ToonAge.db.foreverGearDefer = false
ToonAge.Compat.IsAddOnLoaded = function(name) return name == "Polestar" or name == "Pawn" end
playerLevel = 60
""")
    own = display("item:cloak")
    own_text = line_texts(own)
    check("toggle off: trade line instead of a scorer",
          own_text[0], "ToonAge: +9 Intellect, +10 Spirit")
    check("toggle off: trade color is neutral",
          (own[0]["r"], own[0]["g"], own[0]["b"]), (0.93, 0.93, 0.93))
    check("toggle off: trade is not green or red",
          own[0]["r"] == own[0]["g"] == own[0]["b"] and own[0]["g"] != 0.92 and own[0]["r"] != 1.00, True)
    check("toggle off: Icy Veins order, no percent, not unverified at 60",
          "Icy Veins order" in own_text[-1] and "level 60 guide order" in own_text[-1]
          and "UNVERIFIED for leveling" not in own_text[-1] and "%" not in own_text[-1], True)
    check("toggle off: no percent anywhere", no_percent(own), True)
    check("toggle off: no scorer line",
          any("is scoring gear" in text for text in own_text), False)

    lua.execute(r"""
ToonAge.db.foreverGearDefer = nil
ToonAge.Compat.IsAddOnLoaded = function() return false end
playerLevel = 60
_G.ITEM_MOD_HIT_SPELL_RATING_SHORT = nil
_G.ITEM_MOD_HIT_SHORT = nil
""")
    solo = display("item:cloak")
    check("no scorer: trade line plus the Icy Veins order",
          line_texts(solo)[0] == "ToonAge: +9 Intellect, +10 Spirit"
          and "Icy Veins order, level 60 guide order:" in line_texts(solo)[-1], True)
    check("no scorer: no percent", no_percent(solo), True)
    check("no scorer: trade stays neutral",
          (solo[0]["r"], solo[0]["g"], solo[0]["b"]), (0.93, 0.93, 0.93))

    spell_lines = line_texts(display("item:other:ITEM_MOD_HIT_SPELL_RATING_SHORT"))
    check("spell-hit item shows a cap line when the global is undefined",
          any("names these caps as text only" in text for text in spell_lines), True)
    check("spell-hit trade keeps the fallback label without the global",
          "Spell Hit" in spell_lines[0], True)
    check("non-Hit item has no cap line",
          any("names these caps as text only" in text for text in line_texts(display("item:cloak"))),
          False)

    lua.execute("playerLevel = 12")
    low = line_texts(display("item:hit:ITEM_MOD_HIT_RATING_SHORT"))
    check("below 60 hides level-60 cap lines",
          any("names these caps as text only" in text for text in low), False)
    check("below 60 marks the Icy Veins order UNVERIFIED for leveling",
          any("UNVERIFIED for leveling" in text and "level 60 guide order" in text for text in low), True)
    check("below 60 prints no percent and no upgrade percent line",
          all("%" not in text and "upgrade vs" not in text for text in low), True)
    lua.execute("playerLevel = 60")
    high = line_texts(display("item:hit:ITEM_MOD_HIT_RATING_SHORT"))
    check("level 60 hit item shows the cap line",
          any("names these caps as text only" in text for text in high), True)

    lua.execute(r"""
playerLevel = 60
ToonAge.db.foreverGearDefer = nil
ToonAge.db.foreverGearArrows = nil
ToonAge.Compat.IsAddOnLoaded = function() return false end
arrowVisible = false
InCombatLockdown = function() return false end
NUM_CONTAINER_FRAMES = 1
ContainerFrame1 = {
    GetName = function() return "ContainerFrame1" end,
    GetID = function() return 0 end,
}
ContainerFrame1Item1 = {
    CreateTexture = function(self)
        return {
            SetSize = function() end,
            SetPoint = function() end,
            SetTexture = function() end,
            SetVertexColor = function() end,
            Hide = function() arrowVisible = false end,
            Show = function() arrowVisible = true end,
        }
    end,
    IsProtected = function() return false end,
}
ToonAge.Compat.GetContainerNumSlots = function() return 1 end
ToonAge.Compat.GetContainerItemLink = function() return "item:cloak" end
ToonAge.GearAdvice:RefreshBags()
""")
    check("nothing loaded at 60: the bag arrow still shows an upgrade",
          bool(lua.eval("arrowVisible")) and bool(lua.eval('ToonAge.GearAdvice:IsUpgrade("item:cloak")')), True)
    lua.execute("playerLevel = 12; ToonAge.GearAdvice:RefreshBags()")
    check("level below 60: no bag arrow",
          bool(lua.eval("arrowVisible")) or bool(lua.eval('ToonAge.GearAdvice:IsUpgrade("item:cloak")')), False)
    lua.execute("""
playerLevel = 60
ToonAge.Compat.IsAddOnLoaded = function(name) return name == "Polestar" end
ToonAge.GearAdvice:RefreshBags()
""")
    check("scorer loaded: no bag arrow",
          bool(lua.eval("arrowVisible")) or bool(lua.eval('ToonAge.GearAdvice:IsUpgrade("item:cloak")')), False)
    lua.execute("""
ToonAge.Compat.IsAddOnLoaded = function() return false end
playerLevel = 60
ToonAge.GearAdvice:RefreshBags()
""")
    check("scorer cleared at 60: the bag arrow returns", bool(lua.eval("arrowVisible")), True)

    lua.execute(r"""
savedLink = ToonAge.Compat.GetInventoryItemLink
items["item:ring"] = { equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 10 } }
items["item:strong"] = { equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 40 } }
items["item:weak"] = { equip = "INVTYPE_FINGER", stats = { ITEM_MOD_INTELLECT_SHORT = 1 } }
items["item:trinket"] = { equip = "INVTYPE_TRINKET", stats = { ITEM_MOD_SPIRIT_SHORT = 8 } }
items["item:trinketHi"] = { equip = "INVTYPE_TRINKET", stats = { ITEM_MOD_SPIRIT_SHORT = 20 } }
items["item:trinketLo"] = { equip = "INVTYPE_TRINKET", stats = { ITEM_MOD_SPIRIT_SHORT = 2 } }
items["item:weapon"] = { equip = "INVTYPE_WEAPON", stats = { ITEM_MOD_INTELLECT_SHORT = 10 } }
items["item:weaponHi"] = { equip = "INVTYPE_WEAPON", stats = { ITEM_MOD_INTELLECT_SHORT = 30 } }
items["item:weaponLo"] = { equip = "INVTYPE_WEAPON", stats = { ITEM_MOD_INTELLECT_SHORT = 2 } }
ToonAge.Compat.IsAddOnLoaded = function() return false end
playerLevel = 60
ToonAge.Compat.GetInventoryItemLink = function(unit, slot)
    if slot == 11 then return "item:strong" end
    if slot == 12 then return "item:weak" end
    return nil
end
""")
    check("ring compares with the weaker equipped ring, not the first slot",
          line_texts(display("item:ring"))[0], "ToonAge: +9 Intellect")
    lua.execute("""
ToonAge.Compat.GetInventoryItemLink = function(unit, slot)
    if slot == 11 then return "item:weak" end
    if slot == 12 then return "item:strong" end
    return nil
end
""")
    check("ring still uses the weaker ring when it is in the first slot",
          line_texts(display("item:ring"))[0], "ToonAge: +9 Intellect")
    lua.execute("""
ToonAge.Compat.GetInventoryItemLink = function(unit, slot)
    if slot == 11 then return nil end
    if slot == 12 then return "item:weak" end
    return nil
end
""")
    check("an empty ring slot does not replace the filled weaker ring",
          line_texts(display("item:ring"))[0], "ToonAge: +9 Intellect")
    lua.execute("""
ToonAge.Compat.GetInventoryItemLink = function(unit, slot)
    if slot == 13 then return "item:trinketHi" end
    if slot == 14 then return "item:trinketLo" end
    return nil
end
""")
    check("trinket compares with the weaker equipped trinket",
          line_texts(display("item:trinket"))[0], "ToonAge: +6 Spirit")
    lua.execute("""
ToonAge.Compat.GetInventoryItemLink = function(unit, slot)
    if slot == 16 then return "item:weaponHi" end
    if slot == 17 then return "item:weaponLo" end
    return nil
end
""")
    check("weapon compares with the weaker equipped weapon",
          line_texts(display("item:weapon"))[0], "ToonAge: +8 Intellect")
    lua.execute("ToonAge.Compat.GetInventoryItemLink = savedLink")

    passed = sum(_results)
    print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
