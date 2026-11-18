#!/usr/bin/env python3
"""Faction tracker reads, bar colors, and quests-left estimate.

Retail uses the Renown, standing, paragon, and friendship calls. Mists, TBC
and Era use GetFactionInfoByID only. Forever guards every call and marks the
read unverified. The bar label sits inside the track:
"<Standing> · cur / max". Fill colour is an existing palette token toned
toward the bar track. Hated and Hostile use the dim and secondary tokens,
not the warning or error red. Paragon and a maxed Exalted row never divide
by zero.
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
        RENOWN_TOKEN = FT.ColorToken(READ)
        RENOWN_BAR = READ.barText
        CALLS_MAJOR = calls["C_MajorFactions.GetMajorFactionData"]
        CALLS_PARAGON = calls["C_Reputation.IsFactionParagon"]
        CALLS_FRIEND = calls["C_GossipInfo.GetFriendshipReputation"]
    """)
    check("renown progress uses level and the data-file amount", lua.eval("READ.current"), 2600)
    check("renown cap is max level times the data-file amount", lua.eval("READ.cap"), 50000)
    check("partial renown is not max", lua.eval("READ.atMax"), False)
    check("partial renown fill uses the stat token, not an error red",
          lua.eval("RENOWN_TOKEN"), "stat")
    check("partial renown bar names the track",
          lua.eval("RENOWN_BAR"), "Renown · 2600 / 50000")
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
        PARA_BAR = read.barText
        PARA_FLAG = read.paragon
        PARA_MAX = read.atMax
        PARA_COLOR = FT.ColorToken(read)
        PARA_LINE = FT.LeftLine(read, FT.QuestsLeft(faction, read, function() return false end))
    """)
    check("paragon progress drops the reward prefix", lua.eval("PARA_TEXT"), "717/7500")
    check("paragon bar keeps the remainder and does not divide by zero",
          lua.eval("PARA_BAR"), "Paragon · 717 / 7500")
    check("paragon is not treated as the max fill", lua.eval("PARA_FLAG"), True)
    check("paragon clears the max flag used for green", lua.eval("PARA_MAX"), False)
    check("paragon fill is the accent token, not the error red",
          lua.eval("PARA_COLOR"), "accent")
    check("paragon does not estimate quests left", lua.eval("PARA_LINE"), "Paragon.")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.modules.QuestTracker = { guideID = "midnight_rep_2770" }
        FT._fn = function(path)
            if path == "C_Reputation.GetFactionDataByID" then
                return function()
                    return {
                        reaction = 6, currentStanding = 12000,
                        currentReactionThreshold = 9000, nextReactionThreshold = 21000,
                    }
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
        STAND_BAR = read.barText
        STAND_MAX = read.atMax
        STAND_TOKEN = FT.ColorToken(read)
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
    check("the bar names the standing and the band, not the route gold",
          lua.eval("STAND_BAR"), "Honored · 3000 / 12000")
    check("an active route keeps the standing token", lua.eval("STAND_TOKEN"), "good")
    check("an active route does not paint the header gold", lua.eval("GOLD_R") == 1.0, False)

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
        CLASSIC_BAR = read.barText
        CLASSIC_MAX = read.atMax
        CLASSIC_COLOR = FT.FillColor(read, true)
        CLASSIC_PARA = seen["C_Reputation.IsFactionParagon"]
        CLASSIC_MAJOR = seen["C_MajorFactions.GetMajorFactionData"]
        CLASSIC_UNVER = read.unverified
    """)
    check("classic text is bar numbers", lua.eval("CLASSIC_TEXT"), "42500/43000")
    check("classic exalted bar is the band inside that standing",
          lua.eval("CLASSIC_BAR"), "Exalted · 500 / 1000")
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
        FRIEND_BAR = read.barText
        FRIEND_COLOR = FT.FillColor(read, false)
    """)
    check("top friendship rank is max", lua.eval("FRIEND_MAX"), True)
    check("friendship text is numbers", lua.eval("FRIEND_TEXT"), "42000/42000")
    check("friendship bar uses the rank name and does not divide by zero",
          lua.eval("FRIEND_BAR"), "Best Friend · 42000 / 42000")
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
            LAYOUT[#LAYOUT+1] = "BAR|" .. tostring(opts.text) .. "|" .. tostring(opts.color)
                .. "|" .. tostring(opts.status) .. "|in=" .. tostring(opts.inside)
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
    check("classic bar puts the standing and the band inside the track",
          "BAR|Honored · 3000 / 12000|good|neutral|in=true" in lines)
    check("classic standing name is the bar text",
          any("Honored" in row for row in lines), True)
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
            local tip = ""
            if type(opts.tooltip) == "table" then
                tip = "|" .. table.concat(opts.tooltip, "~")
            end
            LAYOUT[#LAYOUT+1] = "BAR|" .. tostring(opts.label) .. "|" .. tostring(opts.text)
                .. "|in=" .. tostring(opts.inside) .. tip
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
          any(row.startswith("BAR|Darkspear Trolls|Neutral · 2000 / 3000") for row in lines), True)
    check("forever bar label sits inside the track",
          any("|in=true" in row and row.startswith("BAR|Darkspear") for row in lines), True)
    check("forever tooltip keeps the standing, the band, and the total",
          any("Standing: Neutral" in row and "Progress: 2000 / 3000" in row
              and "Total: 2000" in row for row in lines), True)
    check("forever does not claim there are no reputation routes",
          "No reputation routes on this client." not in "\n".join(lines), True)
    check("a faction header is not a standing row",
          any(row.startswith("BAR|") and row.split("|")[1].startswith("Horde") for row in lines if row.startswith("BAR|")),
          False)
    check("undercity standing uses the band inside that standing",
          any("Friendly · 1000 / 6000" in row and "Total: 4000" in row for row in lines), True)

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
            if type(LAYOUT[i]) == "string" and LAYOUT[i]:find("Orgrimmar", 1, true) then
                sawOrgrimmar = true
            end
        end
    """)
    lines = [lua.eval(f"LAYOUT[{i}]") for i in range(1, int(lua.eval("#LAYOUT")) + 1)]
    check("a collapsed header is not opened for the read", lua.eval("expandCalls"), 0)
    check("the faction hidden by that header is not listed",
          any("Orgrimmar" in row for row in lines), False)
    check("the collapsed header is still collapsed", lua.eval("citiesCollapsed"), True)
    check("no collapse call is needed when nothing was opened", lua.eval("collapseLog[1]"), None)
    check("a faction beside that header is still listed",
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)

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
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)
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
          any(row.startswith("BAR|Darkspear Trolls|Neutral · 2000 / 3000") for row in lines), True)
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
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)
    check("a faction under a collapsed header is not invented",
          any("Orgrimmar" in row for row in lines), False)
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
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)
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
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)
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
          any(row.startswith("BAR|Darkspear Trolls|2000 / 3000") for row in lines), True)
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

    test_rep_edges()
    test_rep_bar_layout()

    failed = sum(1 for ok in _results if not ok)
    print(f"  {len(_results) - failed}/{len(_results)} checks passed")
    return failed == 0


def test_rep_edges():
    """Exalted, paragon, and an empty band never divide by zero."""
    lua = world()
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "GetFactionInfoByID" then
                return function() return "Exalted", "desc", 8, 42000, 42000, 42000 end
            end
            return nil
        end
        local read = FT.Read({ factionID = 72 }, "vanilla")
        EX_BAR = read.barText
        EX_SHORT = read.barShort
        EX_V, EX_S = FT.BarFill(read)
        EX_TIP = table.concat(FT.BarTooltip(read), " | ")
        EX_TOKEN = FT.ColorToken(read)
    """)
    check("a maxed exalted row is the standing alone", lua.eval("EX_BAR"), "Exalted")
    check("a maxed exalted row does not invent a ratio", "/" in str(lua.eval("EX_BAR")), False)
    check("a maxed exalted fill is a full bar", (lua.eval("EX_V"), lua.eval("EX_S")), (1, 1))
    check("a maxed exalted tooltip names the standing",
          "Standing: Exalted" in str(lua.eval("EX_TIP")), True)
    check("a maxed exalted fill stays on the good token", lua.eval("EX_TOKEN"), "good")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "GetFactionInfoByID" then
                return function() return "Hated", "desc", 1, -42000, -6000, -42000 end
            end
            return nil
        end
        local read = FT.Read({ factionID = 72 }, "vanilla")
        EMPTY_BAR = read.barText
        EMPTY_V, EMPTY_S = FT.BarFill(read)
        EMPTY_TOKEN = FT.ColorToken(read)
        EMPTY_TIP = table.concat(FT.BarTooltip(read), " | ")
    """)
    check("an empty hated band keeps a zero and its max",
          lua.eval("EMPTY_BAR"), "Hated · 0 / 36000")
    check("an empty hated fill is zero over that band",
          (lua.eval("EMPTY_V"), lua.eval("EMPTY_S")), (0, 36000))
    check("hated uses the dim token", lua.eval("EMPTY_TOKEN"), "dim")
    check("an empty bar tooltip still has the exact band and the total",
          str(lua.eval("EMPTY_TIP")),
          "Standing: Hated | Progress: 0 / 36000 | Total: -42000")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "GetFactionInfoByID" then
                return function() return "Hostile", "desc", 2, -6000, -3000, -4500 end
            end
            return nil
        end
        HOSTILE_TOKEN = ToonAge.FactionTracker.ColorToken(ToonAge.FactionTracker.Read({ factionID = 72 }, "vanilla"))
    """)
    check("hostile uses the secondary token", lua.eval("HOSTILE_TOKEN"), "secondary")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        FT._fn = function(path)
            if path == "C_Reputation.GetFactionDataByID" then
                return function()
                    return { reaction = 8, currentStanding = 42000,
                             currentReactionThreshold = 42000, nextReactionThreshold = 42000 }
                end
            end
            if path == "C_Reputation.IsFactionParagon" then
                return function() return true end
            end
            if path == "C_Reputation.GetFactionParagonInfo" then
                return function() return 10, 0 end
            end
            return nil
        end
        local read = FT.Read({ factionID = 72, system = "standard" }, "retail")
        ZERO_BAR = read.barText
        ZERO_V, ZERO_S = FT.BarFill(read)
        ZERO_TOKEN = FT.ColorToken(read)
    """)
    check("a paragon row with no threshold is the name alone", lua.eval("ZERO_BAR"), "Paragon")
    check("a paragon row with no threshold does not divide",
          "/" in str(lua.eval("ZERO_BAR")), False)
    check("a paragon row with no threshold has no fill scale",
          (lua.eval("ZERO_V"), lua.eval("ZERO_S")), (None, None))
    check("paragon stays on the accent token", lua.eval("ZERO_TOKEN"), "accent")

    lua.execute(read("Core/Compat/API.lua"))
    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        ToonAge.flavor = "forever"
        FACTION_STANDING_LABEL5 = "Amical"
        C_Reputation = {
            GetNumFactions = function() return 1 end,
            GetFactionDataByIndex = function()
                return {
                    name = "Darnassus", factionID = 69, isHeader = false, reaction = 5,
                    currentReactionThreshold = 3000, nextReactionThreshold = 9000,
                    currentStanding = 5897,
                }
            end,
            IsFactionParagon = function() return false end,
        }
        LAYOUT = {}
        function ToonAge.Layout:StatBar(_, _, opts)
            LAYOUT[#LAYOUT+1] = table.concat({
                tostring(opts.text), tostring(opts.shortText), tostring(opts.inside),
                table.concat(opts.tooltip or {}, "~"),
            }, "|")
            return -60
        end
        function ToonAge.Layout:SectionHeader(_, _, title) return -20 end
        function ToonAge.Layout:Paragraph() return -30 end
        function ToonAge.Layout:Finish() end
        FT:Render({})
        OBS = LAYOUT[1]
    """)
    obs = str(lua.eval("OBS"))
    check("the client standing global wins over the English fallback",
          obs.startswith("Amical · 2897 / 6000|"), True)
    check("a narrow-bar short label is the standing alone",
          "|Amical|" in obs, True)
    check("the tooltip keeps the band and the absolute total",
          "Progress: 2897 / 6000" in obs and "Total: 5897" in obs, True)


def test_rep_bar_layout():
    """The in-bar label is one line, drops the ratio when narrow, and stays white."""
    lua = world()
    lua.execute(r"""
        GameTooltip = setmetatable({}, { __index = function() return function() end end })
        ToonAge._ApplyBackdrop = function() end
        local function Widget()
            local f = { _anchors = {}, _shown = true, _fontSize = 10, _text = "", _wordWrap = true, _width = 0 }
            function f:SetParent(p) self._parent = p end
            function f:GetParent() return self._parent end
            function f:SetSize(w, h) self._width = w; self._height = h end
            function f:SetWidth(w) self._width = w end
            function f:SetHeight(h) self._height = h end
            function f:GetWidth() return self._width or 0 end
            function f:GetHeight() return self._height or 0 end
            function f:SetPoint(point, rel, relPoint, x, y)
                self._anchors[#self._anchors + 1] = { point = point, x = x or 0, y = y or 0 }
            end
            function f:ClearAllPoints() self._anchors = {} end
            function f:SetFont(_, size, flags)
                if size then self._fontSize = size end
                self._flags = flags or ""
            end
            function f:SetText(t) self._text = t or "" end
            function f:GetText() return self._text end
            function f:SetTextColor(r, g, b, a)
                self._tr, self._tg, self._tb, self._ta = r, g, b, a
            end
            function f:SetJustifyH(j) self._justify = j end
            function f:SetJustifyV(j) self._justifyV = j end
            function f:SetWordWrap(v) self._wordWrap = v and true or false end
            function f:SetShadowOffset(x, y) self._sx, self._sy = x, y end
            function f:SetShadowColor(r, g, b, a)
                self._sr, self._sg, self._sb, self._sa = r, g, b, a
            end
            function f:GetStringWidth()
                return math.max(#(self._text or ""), 1) * ((self._fontSize or 10) * 0.55)
            end
            function f:Show() self._shown = true end
            function f:Hide() self._shown = false end
            function f:SetScript() end
            function f:EnableMouse() end
            function f:SetDrawLayer() end
            function f:SetColorTexture(r, g, b, a)
                self._r, self._g, self._b, self._a = r, g, b, a
            end
            function f:CreateFontString()
                local fs = Widget()
                fs._parent = self
                return fs
            end
            function f:CreateTexture()
                local tex = Widget()
                tex._parent = self
                return tex
            end
            return f
        end
        function CreateFrame()
            return Widget()
        end
    """)
    lua.execute(read("Core/Theme.lua"))
    lua.execute(read("Core/Layout.lua"))
    lua.execute(r"""
        local L = ToonAge.Layout
        local theme = ToonAge.Theme.active
        content = CreateFrame()
        content:SetWidth(700)
        local _, wide = L:StatBar(content, -8, {
            label = "Darnassus",
            value = 2897, scale = 6000,
            color = { theme.text_success[1], theme.text_success[2], theme.text_success[3], theme.slot_current_a },
            text = "Friendly · 2897 / 6000",
            shortText = "Friendly",
            inside = true,
            status = "neutral",
        })
        WIDE_TEXT = wide.text._text
        WIDE_WRAP = wide.text._wordWrap
        WIDE_FLAGS = wide.text._flags
        WIDE_WHITE = (wide.text._tr == theme.white[1] and wide.text._tg == theme.white[2]
            and wide.text._tb == theme.white[3])
        WIDE_SHADOW = (wide.text._sx == 1 and wide.text._sy == -1
            and wide.text._sr == theme.glass_shadow[1]
            and wide.text._sa == theme.glass_shadow[4])
        WIDE_JUST = wide.text._justify
        WIDE_BAR = wide.track._width
        WIDE_NOCLIP = wide.text._width >= wide.text:GetStringWidth()

        narrowParent = CreateFrame()
        narrowParent:SetWidth(90)
        local _, narrow = L:StatBar(narrowParent, -8, {
            label = "Darnassus",
            value = 2897, scale = 6000,
            text = "Friendly · 2897 / 6000",
            shortText = "Friendly",
            inside = true,
        })
        NARROW_TEXT = narrow.text._text
        NARROW_WRAP = narrow.text._wordWrap
        NARROW_NOCLIP = narrow.text._width >= narrow.text:GetStringWidth()
        NARROW_HAS_RATIO = NARROW_TEXT:find("/", 1, true) ~= nil

        local _, plain = L:StatBar(content, -40, {
            label = "Stamina", value = 12, scale = 50, text = "12",
        })
        local anchor = plain.text._anchors[#plain.text._anchors]
        PLAIN_POINT = anchor.point
        PLAIN_X = anchor.x
        PLAIN_BAR = plain.track._width
        PLAIN_ALPHA = plain.fill._a
        PLAIN_WRAP = plain.text._wordWrap

        local _, empty = L:StatBar(content, -70, {
            label = "Hated", value = 0, scale = 36000,
            text = "Hated · 0 / 36000", shortText = "Hated", inside = true,
            color = { 0.2, 0.2, 0.2, theme.slot_current_a },
        })
        EMPTY_FILL = empty.fill._shown

        local _, sliver = L:StatBar(content, -100, {
            label = "Hated", value = 1, scale = 36000,
            text = "Hated · 1 / 36000", shortText = "Hated", inside = true,
            color = { 0.2, 0.2, 0.2, theme.slot_current_a },
        })
        SLIVER_SHOWN = sliver.fill._shown
        SLIVER_W = sliver.fill._width

        local _, full = L:StatBar(content, -130, {
            label = "Exalted", value = 1, scale = 1,
            text = "Exalted", shortText = "Exalted", inside = true,
            color = { theme.text_success[1], theme.text_success[2], theme.text_success[3], theme.slot_current_a },
        })
        FULL_W = full.fill._width
        FULL_INNER = full.track._width - 2
        FULL_A = full.fill._a

        CHOOSE_FULL = L:ChooseBarText("Friendly · 2897 / 3000", "Friendly", 400, function() return 80 end)
        CHOOSE_SHORT = L:ChooseBarText("Friendly · 2897 / 3000", "Friendly", 40, function() return 120 end)
    """)
    check("a wide bar keeps the standing and the ratio on one line",
          lua.eval("WIDE_TEXT"), "Friendly · 2897 / 6000")
    check("the in-bar label does not wrap", lua.eval("WIDE_WRAP"), False)
    check("the in-bar label is not an outline stroke", lua.eval("WIDE_FLAGS"), "")
    check("the in-bar label is the white token", lua.eval("WIDE_WHITE"), True)
    check("the in-bar label has a 1px dark shadow", lua.eval("WIDE_SHADOW"), True)
    check("the in-bar label is centered", lua.eval("WIDE_JUST"), "CENTER")
    check("the in-bar label is not clipped", lua.eval("WIDE_NOCLIP"), True)
    check("a narrow bar drops the ratio and keeps the standing",
          lua.eval("NARROW_TEXT"), "Friendly")
    check("a narrow bar still does not wrap", lua.eval("NARROW_WRAP"), False)
    check("a narrow standing name is not clipped", lua.eval("NARROW_NOCLIP"), True)
    check("a narrow bar does not keep a slash", lua.eval("NARROW_HAS_RATIO"), False)
    check("a plain stat bar still uses the right-hand column",
          lua.eval("PLAIN_POINT"), "TOPLEFT")
    check("a plain stat bar is narrower than the reputation bar",
          float(lua.eval("PLAIN_BAR")) < float(lua.eval("WIDE_BAR")), True)
    check("a plain stat bar keeps the existing fill alpha",
          float(lua.eval("PLAIN_ALPHA")), 0.90)
    check("a plain stat bar can still wrap its own number", lua.eval("PLAIN_WRAP"), True)
    check("a zero band draws no fill", lua.eval("EMPTY_FILL"), False)
    check("a nearly empty band keeps a one-pixel sliver",
          (lua.eval("SLIVER_SHOWN"), lua.eval("SLIVER_W")), (True, 1))
    check("a maxed bar fills the track",
          (lua.eval("FULL_W"), lua.eval("FULL_INNER")),
          (lua.eval("FULL_INNER"), lua.eval("FULL_INNER")))
    check("an inside fill uses the toned alpha",
          abs(float(lua.eval("FULL_A")) - 0.55) < 0.001, True)
    check("choose keeps the full label when it fits",
          lua.eval("CHOOSE_FULL"), "Friendly · 2897 / 3000")
    check("choose drops the ratio when the full label does not fit",
          lua.eval("CHOOSE_SHORT"), "Friendly")

    lua.execute(r"""
        local FT = ToonAge.FactionTracker
        local theme = ToonAge.Theme.active
        local hated = FT.FillColor({ reaction = 1, system = "standing" }, false)
        local hostile = FT.FillColor({ reaction = 2, system = "standing" }, false)
        local danger = ToonAge.Layout.C_DANGER
        local warn = ToonAge.Layout.C_WARNING
        local dim = ToonAge.Layout.C_DIM
        local track = theme.bar_track_bg
        HATED_R, HATED_A = hated[1], hated[4]
        HOSTILE_R = hostile[1]
        DIM_R, DANGER_R, WARN_R, TRACK_R = dim[1], danger[1], warn[1], track[1]
        HATED_MOVED = math.abs(hated[1] - dim[1]) > 0.01 and hated[1] < dim[1]
        ALPHA_OK = hated[4] == theme.slot_current_a and hostile[4] == theme.slot_current_a
    """)
    check("hated fill is not the error red",
          float(lua.eval("HATED_R")) < float(lua.eval("DANGER_R")) - 0.4, True)
    check("hostile fill is not the warning red",
          float(lua.eval("HOSTILE_R")) < float(lua.eval("WARN_R")) - 0.4, True)
    check("hated fill is the dim token moved toward the track",
          lua.eval("HATED_MOVED"), True)
    check("toned fills use the slot alpha token", lua.eval("ALPHA_OK"), True)


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
