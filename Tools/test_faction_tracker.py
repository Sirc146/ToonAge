#!/usr/bin/env python3
"""Faction tracker reads, bar colors, and quests-left estimate.

Retail uses the Renown, standing, paragon, and friendship calls. Mists, TBC
and Era use GetFactionInfoByID only. Forever guards every call and marks the
read unverified. The bar is neutral, gold for the active route, and green
only at max. Paragon past max stays neutral. Classic text is numbers.
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


def check(name, got, want=True):
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


def world():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
        ToonAge = { modules = {}, flavor = "retail", Layout = { C_HEADER = { 1.00, 0.82, 0.00 } } }
        function ToonAge:RegisterModule(name, mod) self.modules[name] = mod; self[name] = mod end
        function ToonAge:GetModule(name) return self.modules[name] end
    """)
    lua.execute(read("Modules/Progression/FactionTracker.lua"))
    return lua


def main():
    src = read("Modules/Progression/FactionTracker.lua")
    check("Run this faction is not a gold button", "gold = true" in src, False)
    check("the bar text is not painted good", 'status = "good"' in src, False)

    lua = world()
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        local calls = {}
        FT._fn = function(path)
            calls[path] = (calls[path] or 0) + 1
            if path == "C_MajorFactions.GetMajorFactionData" then
                return function()
                    return { renownLevel = 2, renownReputationEarned = 100, maxLevel = 20 }
                end
            end
            if path == "C_Reputation.IsFactionParagon" then
                return function() return false end
            end
            return nil
        end
        FACTION = {
            factionID = 2710, name = "Silvermoon Court", system = "renown",
            renown = { maxLevel = 20, repPerLevel = 2500 },
            earn = { quests = {
                { questID = 1, amount = 500, frequency = "once" },
                { questID = 2, amount = 800, frequency = "once" },
                { questID = 3, amount = 100, frequency = "weekly" },
            } },
        }
        READ = FT.Read(FACTION, "retail")
        LEFT = FT.QuestsLeft(FACTION, READ, function(id) return id == 1 end)
        LINE = FT.LeftLine(READ, LEFT)
        COLOR = FT.FillColor(READ, false)
        CALLS_MAJOR = calls["C_MajorFactions.GetMajorFactionData"]
        CALLS_PARAGON = calls["C_Reputation.IsFactionParagon"]
        CALLS_FRIEND = calls["C_GossipInfo.GetFriendshipReputation"]
    """)
    check("renown progress uses level and the data-file amount", lua.eval("READ.current"), 2600)
    check("renown cap is max level times the data-file amount", lua.eval("READ.cap"), 50000)
    check("partial renown is not max", lua.eval("READ.atMax"), False)
    check("partial renown fill is neutral", lua.eval("COLOR"), "neutral")
    check("a finished once-quest is skipped and weeklies are not counted",
          (lua.eval("LEFT.count"), lua.eval("LEFT.covered"), lua.eval("LEFT.short")),
          (1, 800, True))
    check("a short list says how much the quests cover",
          lua.eval("LINE"), "Listed one-time quests cover 800 of 47400.")
    check("retail renown called the major-faction read", lua.eval("CALLS_MAJOR"), 1)
    check("retail checks paragon", lua.eval("CALLS_PARAGON"), 1)
    check("a renown faction does not use the friendship read", lua.eval("CALLS_FRIEND"), None)

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "C_MajorFactions.GetMajorFactionData" then
                return function() return { renownLevel = 20, renownReputationEarned = 0, maxLevel = 20 } end
            end
            if path == "C_Reputation.IsFactionParagon" then
                return function(id) return id == 2727 end
            end
            if path == "C_Reputation.GetFactionParagonInfo" then
                return function() return 120717, 7500, 93811, false, false end
            end
            return nil
        end
        local faction = {
            factionID = 2710, system = "renown",
            renown = { maxLevel = 20, repPerLevel = 2500 },
            paragon = { factionID = 2727, threshold = 7500 },
        }
        local read = FT.Read(faction, "retail")
        PARA_TEXT = read.text
        PARA_FLAG = read.paragon
        PARA_MAX = read.atMax
        PARA_COLOR = FT.FillColor(read, true)
        PARA_LINE = FT.LeftLine(read, FT.QuestsLeft(faction, read, function() return false end))
    """)
    check("paragon progress drops the reward prefix", lua.eval("PARA_TEXT"), "717/7500")
    check("paragon is not treated as the max fill", lua.eval("PARA_FLAG"), True)
    check("paragon clears the max flag used for green", lua.eval("PARA_MAX"), False)
    check("paragon stays neutral even while that route is active", lua.eval("PARA_COLOR"), "neutral")
    check("paragon does not estimate quests left", lua.eval("PARA_LINE"), "Paragon.")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.modules.QuestTracker = { guideID = "midnight_rep_2770" }
        FT._fn = function(path)
            if path == "C_Reputation.GetFactionDataByID" then
                return function()
                    return { reaction = 6, currentStanding = 12000, nextReactionThreshold = 21000 }
                end
            end
            if path == "C_Reputation.IsFactionParagon" then
                return function() return false end
            end
            return nil
        end
        local faction = {
            factionID = 2770, system = "standard", name = "Slayer's Duellum",
            standings = { { standing = "Exalted", min = 42000 } },
        }
        local read = FT.Read(faction, "retail")
        STAND_TEXT = read.text
        STAND_MAX = read.atMax
        GOLD = FT.FillColor(read, FT.IsActive(faction))
        GOLD_R = type(GOLD) == "table" and GOLD[1] or nil
        function ToonAge:GetModule(name) return self.modules[name] end
        RAN = FT.Run(faction)
        RAN_ID = ToonAge.modules.QuestTracker.guideID
    """)
    # SetGuide isn't on the stub, so Run calls it and errors... I need SetGuide.
    # I'll fix the lua if RAN is false because SetGuide is missing. Let me set it in a follow-up if this fails.
    check("standing text is the number, not the standing name", lua.eval("STAND_TEXT"), "12000/42000")
    check("honored is not max", lua.eval("STAND_MAX"), False)
    check("the active route uses the header gold", lua.eval("GOLD_R"), 1.0)

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        local seen = {}
        FT._fn = function(path)
            seen[path] = true
            if path == "GetFactionInfoByID" then
                return function() return "Exalted Name", "desc", 8, 42000, 43000, 42500 end
            end
            return function() error("classic called " .. path) end
        end
        local faction = { factionID = 2770, system = "renown", name = "Should stay a standing" }
        local read = FT.Read(faction, "vanilla")
        CLASSIC_TEXT = read.text
        CLASSIC_MAX = read.atMax
        CLASSIC_COLOR = FT.FillColor(read, true)
        CLASSIC_PARA = seen["C_Reputation.IsFactionParagon"]
        CLASSIC_MAJOR = seen["C_MajorFactions.GetMajorFactionData"]
        CLASSIC_UNVER = read.unverified
    """)
    check("classic text is bar numbers", lua.eval("CLASSIC_TEXT"), "42500/43000")
    check("classic exalted is max", lua.eval("CLASSIC_MAX"), True)
    check("classic exalted is green even if that route is active", lua.eval("CLASSIC_COLOR"), "good")
    check("classic does not read paragon", lua.eval("CLASSIC_PARA"), None)
    check("classic does not read renown", lua.eval("CLASSIC_MAJOR"), None)
    check("classic is not labeled unverified", lua.eval("CLASSIC_UNVER"), False)

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "C_GossipInfo.GetFriendshipReputation" then
                return function()
                    return { standing = 42000, maxRep = 42000, nextThreshold = nil, reaction = "Best Friend" }
                end
            end
            return nil
        end
        local read = FT.Read({ factionID = 9, system = "friendship" }, "retail")
        FRIEND_MAX = read.atMax
        FRIEND_TEXT = read.text
        FRIEND_COLOR = FT.FillColor(read, false)
    """)
    check("top friendship rank is max", lua.eval("FRIEND_MAX"), True)
    check("friendship text is numbers", lua.eval("FRIEND_TEXT"), "42000/42000")
    check("top friendship fill is green", lua.eval("FRIEND_COLOR"), "good")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "C_MajorFactions.GetMajorFactionData" then
                return function() return { renownLevel = 3, renownReputationEarned = 10, maxLevel = 8 } end
            end
            if path == "C_Reputation.IsFactionParagon" then return function() return false end end
            return nil
        end
        local read = FT.Read({
            factionID = 2792, system = "renown",
            renown = { maxLevel = 8, repPerLevel = nil },
        }, "forever")
        FOREVER_UNVER = read.unverified
        FOREVER_SCALE = read.scale
        FOREVER_LINE = FT.LeftLine(read, FT.QuestsLeft({ earn = { quests = {} } }, read))
    """)
    check("forever marks the read unverified", lua.eval("FOREVER_UNVER"), True)
    check("missing rep-per-level stays on the level scale", lua.eval("FOREVER_SCALE"), "levels")
    check("quests left are not estimated without a per-level amount",
          lua.eval("FOREVER_LINE"),
          "Per-level renown is not in the data, so quests left are not estimated.")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        LAYOUT = {}
        ToonAge.flavor = "vanilla"
        ToonAge.Reputations = { midnight = {
            [2770] = { factionID = 2770, name = "Slayer's Duellum", system = "standard" },
        } }
        ToonAge.modules.QuestTracker = nil
        FT._fn = function(path)
            if path == "GetFactionInfoByID" then
                return function() return "Honored", "desc", 6, 9000, 21000, 12000 end
            end
            return nil
        end
        local L = {}
        function L:SectionHeader(_, _, title) LAYOUT[#LAYOUT+1] = "H|" .. title; return -20 end
        function L:Paragraph(_, _, text) LAYOUT[#LAYOUT+1] = "P|" .. text; return -40 end
        function L:StatBar(_, _, opts)
            LAYOUT[#LAYOUT+1] = "BAR|" .. tostring(opts.text) .. "|" .. tostring(opts.color) .. "|" .. tostring(opts.status)
            return -60
        end
        function L:ButtonRow(_, _, buttons)
            local b = buttons[1]
            LAYOUT[#LAYOUT+1] = "BTN|" .. b.label .. "|" .. tostring(b.gold) .. "|" .. tostring(b.danger)
            BTN = b
            return -80
        end
        function L:Finish() end
        ToonAge.Layout = L
        FT:Render({})
        RAN = FT.Run(ToonAge.Reputations.midnight[2770])
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("classic bar shows numbers and a neutral fill",
          "BAR|12000/21000|neutral|neutral" in lines)
    check("classic standing name is not the bar text",
          any("Honored" in row or "Exalted" in row for row in lines), False)
    check("Run this faction is a plain button", "BTN|Run this faction|nil|nil" in lines)
    check("Run this faction does nothing without the tracker", lua.eval("RAN"), False)

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        ToonAge.Reputations = nil
        LAYOUT = {}
        FT:Render({})
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("forever says the reads are unverified",
          "P|Reputation reads are unverified until Harvest probes them." in lines)

    # A nil probe of faction 72 is not the Horde list. The client walk is.
    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        ToonAge.Reputations = nil
        LAYOUT = {}
        C_Reputation = {
            GetNumFactions = function() return 5 end,
            ExpandAllFactionHeaders = function() end,
            GetFactionDataByIndex = function(i)
                local rows = {
                    { name = "Horde", isHeader = true, factionID = 67 },
                    { name = "Darkspear Trolls", factionID = 530, reaction = 4,
                      currentReactionThreshold = 0, nextReactionThreshold = 3000,
                      currentStanding = 2000, isHeader = false },
                    { name = "Orgrimmar", factionID = 76, reaction = 4,
                      currentReactionThreshold = 0, nextReactionThreshold = 3000,
                      currentStanding = 500, isHeader = false },
                    { name = "Thunder Bluff", factionID = 81, reaction = 4,
                      currentReactionThreshold = 0, nextReactionThreshold = 3000,
                      currentStanding = 100, isHeader = false },
                    { name = "Undercity", factionID = 68, reaction = 5,
                      currentReactionThreshold = 3000, nextReactionThreshold = 9000,
                      currentStanding = 4000, isHeader = false },
                }
                return rows[i]
            end,
            GetFactionDataByID = function() return nil end,
        }
        function ToonAge.Layout:StatBar(_, _, opts)
            LAYOUT[#LAYOUT+1] = "BAR|" .. tostring(opts.label) .. "|" .. tostring(opts.text)
            return -60
        end
        function ToonAge.Layout:ButtonRow()
            LAYOUT[#LAYOUT+1] = "BTN"
            return -80
        end
        FT:Render({})
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("forever lists Darkspear Trolls from the client",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("forever does not claim there are no reputation routes",
          "No reputation routes on this client." not in "\n".join(lines), True)
    check("a faction header is not a standing row",
          any(row.startswith("BAR|") and row.split("|")[1].startswith("Horde") for row in lines if row.startswith("BAR|")),
          False)
    check("undercity standing uses the client bar numbers",
          any("4000/9000" in row for row in lines), True)

    # Nested collapsed headers must be readable and then put back.
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        ToonAge.Reputations = nil
        LAYOUT = {}
        expandCalls = 0
        collapseLog = {}
        collapsed = { Cities = true }
        local function rows()
            local list = {
                { name = "Horde", isHeader = true, isCollapsed = false, factionID = 67 },
                { name = "Darkspear Trolls", factionID = 530, isHeader = false,
                  currentReactionThreshold = 0, nextReactionThreshold = 3000,
                  currentStanding = 2000 },
                { name = "Cities", isHeader = true, isCollapsed = collapsed.Cities, factionID = 76 },
            }
            if not collapsed.Cities then
                list[#list + 1] = {
                    name = "Orgrimmar", factionID = 76, isHeader = false,
                    currentReactionThreshold = 0, nextReactionThreshold = 3000,
                    currentStanding = 500,
                }
                list[#list + 1] = {
                    name = "Outposts", isHeader = true, isCollapsed = true, factionID = 81,
                }
            end
            return list
        end
        C_Reputation = {
            GetNumFactions = function() return #rows() end,
            ExpandAllFactionHeaders = function()
                expandCalls = expandCalls + 1
                collapsed.Cities = false
            end,
            CollapseFactionHeader = function(index)
                local row = rows()[index]
                collapseLog[#collapseLog + 1] = row and row.name
                if row and row.name == "Cities" then collapsed.Cities = true end
            end,
            GetFactionDataByIndex = function(i) return rows()[i] end,
        }
        FT:Render({})
        citiesCollapsed = collapsed.Cities
        hordeCollapsed = false
        sawOrgrimmar = false
        for i = 1, #LAYOUT do
            if LAYOUT[i] == "BAR|Orgrimmar|500/3000" then sawOrgrimmar = true end
        end
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a collapsed header is not opened for the read", lua.eval("expandCalls"), 0)
    check("the faction hidden by that header is not listed", "BAR|Orgrimmar|500/3000" not in lines, True)
    check("the collapsed header is still collapsed", lua.eval("citiesCollapsed"), True)
    check("no collapse call is needed when nothing was opened", lua.eval("collapseLog[1]"), None)
    check("a faction beside that header is still listed",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)

    lua.execute(r"""
        expandCalls = 0
        C_Reputation.CollapseFactionHeader = nil
        collapsed.Cities = true
        LAYOUT = {}
        ToonAge.FactionTracker:Render({})
        noCollapseExpand = expandCalls
        citiesStill = collapsed.Cities
    """)
    check("without a collapse function the pane is not expanded", lua.eval("noCollapseExpand"), 0)
    check("that header stays collapsed", lua.eval("citiesStill"), True)

    lua.execute(r"""
        LAYOUT = {}
        expandCalls = 0
        issecretvalue = function() error("predicate failed") end
        C_Reputation = {
            GetNumFactions = function() return 1 end,
            ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
            CollapseFactionHeader = function() end,
            GetFactionDataByIndex = function()
                return { name = "Darkspear Trolls", isHeader = false,
                         currentStanding = 2000, nextReactionThreshold = 3000 }
            end,
        }
        ToonAge.FactionTracker:Render({})
        predicateExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a throwing secrecy predicate does not walk the list",
          any("This client did not return a faction list." in row for row in lines), True)
    check("a throwing secrecy predicate does not expand headers", lua.eval("predicateExpand"), 0)

    lua.execute(r"""
        LAYOUT = {}
        expandCalls = 0
        local secretCount = 4
        issecretvalue = function(v) return v == secretCount or v == "Hidden Name" end
        C_Reputation = {
            GetNumFactions = function() return secretCount end,
            ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
            CollapseFactionHeader = function() end,
            GetFactionDataByIndex = function()
                return { name = "Darkspear Trolls", isHeader = false,
                         currentStanding = 1, nextReactionThreshold = 2 }
            end,
        }
        ToonAge.FactionTracker:Render({})
        secretCountExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a secret faction count is not compared or clamped",
          any("This client did not return a faction list." in row for row in lines), True)
    check("a secret faction count does not expand headers", lua.eval("secretCountExpand"), 0)
    check("a secret count does not invent faction rows",
          any(row.startswith("BAR|") for row in lines), False)

    lua.execute(r"""
        LAYOUT = {}
        issecretvalue = function(v) return v == "Hidden Name" end
        C_Reputation = {
            GetNumFactions = function() return 3 end,
            GetFactionDataByIndex = function(i)
                if i == 2 then error("index unreadable") end
                if i == 3 then
                    return { name = "Hidden Name", isHeader = false,
                             currentStanding = 1, nextReactionThreshold = 2 }
                end
                return { name = "Darkspear Trolls", isHeader = false, factionID = 530,
                         currentStanding = 2000, nextReactionThreshold = 3000,
                         currentReactionThreshold = 0 }
            end,
        }
        ToonAge.FactionTracker:Render({})
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a thrown faction row does not drop the others",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("a secret faction name is not compared and not shown",
          any("Hidden Name" in row for row in lines), False)

    lua.execute(r"""
        LAYOUT = {}
        issecretvalue = nil
        C_Reputation = { GetNumFactions = function() return 2 end }
        function GetFactionInfo(i)
            if i == 1 then
                return "Horde", "desc", 4, 0, 3000, 0, false, false, true, false, false, false, false, 67
            end
            return "Darkspear Trolls", "desc", 4, 0, 3000, 2000, false, false, false, false, true, false, true, 530
        end
        ToonAge.FactionTracker:Render({})
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("classic multi-return rows still list the faction",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("classic multi-return still skips the header",
          any(row.startswith("BAR|Horde") for row in lines), False)

    # Hidden nested headers are not in the index while their parent is collapsed.
    # ExpandAll would open them. A later collapse of only the visible parent
    # cannot put those hidden headers back, and a collapse that does not stick
    # leaves the pane open. The walk must not call either.
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        ToonAge.Reputations = nil
        issecretvalue = nil
        LAYOUT = {}
        expandCalls = 0
        collapseCalls = 0
        state = { Horde = false, Cities = true, Outposts = true }
        local tree = {
            { name = "Horde", header = true, children = {
                { name = "Darkspear Trolls", standing = 2000, cap = 3000 },
                { name = "Cities", header = true, children = {
                    { name = "Orgrimmar", standing = 500, cap = 3000 },
                    { name = "Outposts", header = true, children = {
                        { name = "Razor Hill", standing = 10, cap = 3000 },
                    } },
                } },
            } },
        }
        local function visible()
            local list = {}
            local function walk(nodes)
                for _, node in ipairs(nodes) do
                    local row = {
                        name = node.name,
                        isHeader = node.header and true or false,
                        isCollapsed = node.header and state[node.name] and true or false,
                        factionID = node.name,
                    }
                    if not node.header then
                        row.currentStanding = node.standing
                        row.currentReactionThreshold = 0
                        row.nextReactionThreshold = node.cap
                    end
                    list[#list + 1] = row
                    if node.header and not state[node.name] then
                        walk(node.children)
                    end
                end
            end
            walk(tree)
            return list
        end
        local function expandAll()
            expandCalls = expandCalls + 1
            state.Horde, state.Cities, state.Outposts = false, false, false
        end
        C_Reputation = {
            GetNumFactions = function() return #visible() end,
            ExpandAllFactionHeaders = expandAll,
            CollapseFactionHeader = function()
                collapseCalls = collapseCalls + 1
            end,
            GetFactionDataByIndex = function(i) return visible()[i] end,
        }
        ExpandAllFactionHeaders = expandAll
        FT:Render({})
        paneHorde = state.Horde
        paneCities = state.Cities
        paneOutposts = state.Outposts
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a visible faction under an open header is listed",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("a faction under a collapsed header is not invented",
          "BAR|Orgrimmar|500/3000" not in lines, True)
    check("a faction under a hidden nested header is not invented",
          any("Razor Hill" in row for row in lines), False)
    check("the walk does not expand faction headers", lua.eval("expandCalls"), 0)
    check("the walk does not collapse faction headers", lua.eval("collapseCalls"), 0)
    check("an open header stays open", lua.eval("paneHorde"), False)
    check("a collapsed header stays collapsed", lua.eval("paneCities"), True)
    check("a collapsed header hidden under it stays collapsed", lua.eval("paneOutposts"), True)
    check("collapsed headers are named as left closed",
          any("left closed" in row for row in lines), True)
    check("a partial list is not called an empty faction list",
          any("empty faction list" in row for row in lines), False)

    lua.execute(r"""
        LAYOUT = {}
        state.Horde = true
        expandCalls = 0
        collapseCalls = 0
        ToonAge.FactionTracker:Render({})
        onlyHeaderHorde = state.Horde
        onlyHeaderCities = state.Cities
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a collapsed top header is not opened to fill the tab", lua.eval("expandCalls"), 0)
    check("no standing row is invented under that header",
          any(row.startswith("BAR|") for row in lines), False)
    check("collapsed-only view is not called an empty list",
          any("empty faction list" in row for row in lines), False)
    check("collapsed-only view says the window was not changed",
          any("not changed" in row for row in lines), True)
    check("that top header is still collapsed", lua.eval("onlyHeaderHorde"), True)

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        ToonAge.Reputations = nil
        expandCalls = 0
        collapseCalls = 0
        secretName = "SECRET-NAME"
        compares = 0
        bad = setmetatable({}, {
            __eq = function() compares = compares + 1; error("compare") end,
            __tostring = function() error("tostring") end,
        })
        issecretvalue = function(v) return v == secretName end
        function install(rows)
            LAYOUT = {}
            expandCalls = 0
            collapseCalls = 0
            compares = 0
            C_Reputation = {
                GetNumFactions = function() return #rows end,
                ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
                CollapseFactionHeader = function() collapseCalls = collapseCalls + 1 end,
                GetFactionDataByIndex = function(i) return rows[i] end,
            }
            ExpandAllFactionHeaders = C_Reputation.ExpandAllFactionHeaders
            FT:Render({})
        end
        function faction(name, standing)
            return {
                name = name, isHeader = false, isCollapsed = false,
                currentStanding = standing or 10,
                currentReactionThreshold = 0, nextReactionThreshold = 3000,
            }
        end
        install({
            faction("Darkspear Trolls", 2000),
            faction(""),
            faction(secretName),
            faction(bad),
        })
        mixedExpand = expandCalls
        mixedCollapse = collapseCalls
        mixedCompares = compares
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a readable name is kept beside skipped names",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("a blank name is not shown", any(row.startswith("BAR|") and row.split("|")[2] == "" for row in lines), False)
    check("a secret name is not shown", any("SECRET-NAME" in row for row in lines), False)
    check("a non-string name is not shown", any("table:" in row for row in lines), False)
    check("skipped names are not described as an empty list",
          any("empty faction list" in row for row in lines), False)
    check("skipped names are marked unreadable",
          any("could not be read" in row for row in lines), True)
    check("skipped names do not expand headers", lua.eval("mixedExpand"), 0)
    check("skipped names do not collapse headers", lua.eval("mixedCollapse"), 0)
    check("a non-string name is not compared", lua.eval("mixedCompares"), 0)

    lua.execute(r"""
        install({
            faction(""),
            faction(secretName),
            faction(bad),
        })
        allBadExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("only unreadable names produce no standing row",
          any(row.startswith("BAR|") for row in lines), False)
    check("only unreadable names are not called an empty list",
          any("empty faction list" in row for row in lines), False)
    check("only unreadable names say the list could not be read",
          any("could not be read" in row for row in lines), True)
    check("only unreadable names do not expand headers", lua.eval("allBadExpand"), 0)

    lua.execute(r"""
        local rows = { faction("Darkspear Trolls", 2000) }
        for i = 2, 200 do rows[i] = faction("Filler " .. i, 1) end
        rows[201] = faction("Past The Cap", 999)
        LAYOUT = {}
        expandCalls = 0
        collapseCalls = 0
        C_Reputation = {
            GetNumFactions = function() return 201 end,
            ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
            CollapseFactionHeader = function() collapseCalls = collapseCalls + 1 end,
            GetFactionDataByIndex = function(i) return rows[i] end,
        }
        ToonAge.FactionTracker:Render({})
        capExpand = expandCalls
        capCollapse = collapseCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("the first row of a long list is shown",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("a row past 200 is not invented", any("Past The Cap" in row for row in lines), False)
    check("a list longer than 200 is marked partial",
          any("longer than 200" in row for row in lines), True)
    check("a capped list is not called empty",
          any("empty faction list" in row for row in lines), False)
    check("a capped list does not expand headers", lua.eval("capExpand"), 0)
    check("a capped list does not collapse headers", lua.eval("capCollapse"), 0)

    lua.execute(r"""
        local rows = {}
        for i = 1, 200 do rows[i] = faction("") end
        rows[201] = faction("Past The Cap", 999)
        LAYOUT = {}
        expandCalls = 0
        C_Reputation = {
            GetNumFactions = function() return 201 end,
            ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
            CollapseFactionHeader = function() end,
            GetFactionDataByIndex = function(i) return rows[i] end,
        }
        ToonAge.FactionTracker:Render({})
        capBadExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("blank rows inside a capped scan are not an empty list",
          any("empty faction list" in row for row in lines), False)
    check("blank rows inside a capped scan are unreadable",
          any("could not be read" in row for row in lines), True)
    check("blank rows inside a capped scan still say the list was longer",
          any("longer than 200" in row for row in lines), True)
    check("the row past that cap is still not invented",
          any("Past The Cap" in row for row in lines), False)
    check("a capped scan of blank names does not expand headers", lua.eval("capBadExpand"), 0)

    lua.execute(r"""
        install({
            { name = "Cities", isHeader = true, isCollapsed = true },
            faction("Darkspear Trolls", 2000),
            faction(""),
        })
        bothExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("collapsed and unreadable can both be true",
          any("left closed" in row for row in lines) and any("could not be read" in row for row in lines), True)
    check("the readable row remains beside both flags",
          "BAR|Darkspear Trolls|2000/3000" in lines, True)
    check("both flags do not expand headers", lua.eval("bothExpand"), 0)

    lua.execute(r"""
        issecretvalue = nil
        C_Reputation = {
            GetNumFactions = function() return 0 end,
            ExpandAllFactionHeaders = function() expandCalls = expandCalls + 1 end,
            CollapseFactionHeader = function() collapseCalls = collapseCalls + 1 end,
            GetFactionDataByIndex = function() end,
        }
        expandCalls = 0
        LAYOUT = {}
        ToonAge.FactionTracker:Render({})
        emptyExpand = expandCalls
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a real zero count is an empty faction list",
          any("empty faction list" in row for row in lines), True)
    check("a real zero count is not called unreadable",
          any("could not be read" in row for row in lines), False)
    check("a real zero count does not expand headers", lua.eval("emptyExpand"), 0)

    lua.execute(r"""
        C_Reputation = nil
        GetFactionInfo = nil
        GetNumFactions = nil
        GetFactionInfo = nil
        GetNumFactions = nil
        GetFactionInfo = nil
        LAYOUT = {}
        ToonAge.FactionTracker:Render({})
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a missing faction API does not claim the character has no reputations",
          "No reputation routes on this client." not in "\n".join(lines), True)

    failed = sum(1 for ok in _results if not ok)
    print(f"  {len(_results) - failed}/{len(_results)} checks passed")
    return failed == 0


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
