#!/usr/bin/env python3
"""Forever session journal: guarded events, chunked storage, a hard cap.

The journal is local SavedVariables only (ToonAgeDB.journey). It is not
analytics and it must never compile anything it stored. Usage:

    python Tools/test_journey.py [-v]
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


def strip_comments(src):
    return "\n".join(re.sub(r"--.*$", "", line) for line in src.split("\n"))


def seq(t):
    """Lua sequence (1..n) as a Python list. Stops at the first hole."""
    if t is None:
        return []
    out = []
    i = 1
    while True:
        v = t[i]
        if v is None:
            break
        out.append(v)
        i += 1
    return out


# ── Source gates (no runtime required) ───────────────────────────────────

journey_path = os.path.join(ROOT, "Modules/Forever/Journey.lua")
check("Journey.lua exists", os.path.exists(journey_path))
journey = read("Modules/Forever/Journey.lua") if os.path.exists(journey_path) else ""
code = strip_comments(journey)

check("no loadstring", "loadstring" not in code and "loadstring" not in journey)
check("no load(", not re.search(r"(?<![\w.])load\s*\(", code))
check("no RunScript", "RunScript" not in code)
check("journal does not talk to analytics",
      "Analytics" not in journey and "Wago" not in journey)
analytics = read("Core/Analytics.lua")
check("analytics does not read the journal", "journey" not in analytics.lower())

for raw in ("GetMoney", "UnitXP", "GetZoneText", "GetRealZoneText", "UnitOnTaxi",
            "GetItemInfo", "C_Map", "C_QuestLog", "C_Item", "GetLootSlotLink",
            "GetNumLootItems", "SendAddonMessage"):
    check(f"Journey.lua does not call {raw}", raw not in code)

check("events go through TA:RegisterEvent",
      "TA:RegisterEvent" in code and code.count(":RegisterEvent") == code.count("TA:RegisterEvent"))
check("no direct frame RegisterEvent", "eventFrame" not in code)

api = read("Core/Compat/API.lua")
for fn, probe in (
    ("function C.PlayerXP()", "UnitXP"),
    ("function C.PlayerMoney()", "GetMoney"),
    ("function C.PlayerMap()", "C_Map.GetBestMapForUnit"),
    ("function C.QuestTitle(", "C_QuestLog.GetTitleForQuestID"),
    ("function C.ItemQuality(", "GetItemInfo"),
    ("function C.OnTaxi()", "UnitOnTaxi"),
    ("function C.ZoneText()", "GetZoneText"),
    ("function C.RealZoneText()", "GetRealZoneText"),
):
    check(f"Compat defines {fn}", fn in api)
    start = api.find(fn)
    nxt = api.find("\nfunction C.", start + len(fn))
    body = api[start:nxt if nxt != -1 else start + 800]
    check(f"{fn} asks HasAPI about {probe}", f'HasAPI("{probe}")' in body)

settings = read("Modules/Infrastructure/Settings.lua")
has_at = settings.find('Has("ForeverJourney")')
check("Settings section is ForeverJourney-only", has_at > 0)
block = settings[has_at:has_at + 1800] if has_at > 0 else ""
check("Settings offers Clear journal", "Clear journal" in block and "RequestClear" in block)
check("Settings offers Copy recent sessions",
      "Copy recent sessions" in block and "ShowSummary" in block)

cam = read("ToonAge_Camelot.toc")
check("Camelot TOC lists Journey.lua", "Modules\\Forever\\Journey.lua" in cam)
for name in os.listdir(ROOT):
    if not (name.startswith("ToonAge") and name.endswith(".toc")):
        continue
    if name == "ToonAge_Camelot.toc":
        continue
    body = read(name)
    check(f"{name} does not list Journey.lua", "Journey.lua" not in body)

prof = read("Core/Profile.lua")
check("profile names ForeverJourney once", prof.count("ForeverJourney"), 1)
forever_at = prof.find("forever = {")
check("ForeverJourney is in the forever profile",
      forever_at > 0 and prof.find("ForeverJourney", forever_at) > forever_at)

harvester = read("Modules/Infrastructure/Harvester.lua")
check("harvester probes still stand down without a pack",
      "self._probesOnly = true" in harvester)
check("harvester probe command still runs probes", "self:RunProbes()" in harvester)

# ── Compat guards actually skip a missing or throwing API ────────────────

GUARD_ENV = r"""
ToonAge = {}
function ToonAge:HasAPI(path) return ALLOW[path] ~= false end
ALLOW = {}
GetMoney = function() return 99 end
UnitXP = function() return 50 end
GetZoneText = function() return "Elwynn Forest" end
GetRealZoneText = function() return "Elwynn Forest" end
UnitOnTaxi = function() return 1 end
GetItemInfo = function() return "Linen Cloth", "link", 1 end
C_QuestLog = { GetTitleForQuestID = function(id) return "Kobold Camp" end }
C_Map = {
  GetBestMapForUnit = function() return 1429 end,
  GetMapInfo = function() return { name = "Elwynn Forest" } end,
}
function date(fmt, t) return "TIME" end
function time() return 1700000000 end
"""


def load_api(extra=""):
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(GUARD_ENV)
    if extra:
        L.execute(extra)
    L.execute(read("Core/Compat/API.lua"))
    return L, L.globals().ToonAge.Compat


def call(fn, *args):
    """Call a Compat reader. A missing function is a failed check, not a crash."""
    if not callable(fn):
        return None
    return fn(*args)


L, C = load_api()
check("PlayerMoney reads GetMoney", call(C.PlayerMoney), 99)
check("PlayerXP reads UnitXP", call(C.PlayerXP), 50)
check("QuestTitle reads the quest log", call(C.QuestTitle, 12), "Kobold Camp")
check("ItemQuality reads GetItemInfo", call(C.ItemQuality, 2589), 1)
check("OnTaxi is true when the unit is on a taxi", call(C.OnTaxi), True)
mapped = call(C.PlayerMap)
map_id, map_name = mapped if isinstance(mapped, tuple) else (mapped, None)
check("PlayerMap returns uiMapID", map_id, 1429)
check("PlayerMap returns the map name", map_name, "Elwynn Forest")

L, C = load_api('ALLOW["GetMoney"] = false; ALLOW["UnitXP"] = false; ALLOW["C_Map.GetBestMapForUnit"] = false')
check("HasAPI false skips GetMoney", call(C.PlayerMoney), None)
check("HasAPI false skips UnitXP", call(C.PlayerXP), None)
# Zone text is still allowed, so the map wrapper falls back instead of erroring.
fallback = call(C.PlayerMap)
fallback_id, fallback_name = fallback if isinstance(fallback, tuple) else (fallback, None)
check("missing map API does not invent an id", fallback_id, None)
check("missing map API can still use zone text", fallback_name, "Elwynn Forest")

L, C = load_api("GetMoney = function() error('boom') end")
try:
    thrown = call(C.PlayerMoney)
    check("throwing GetMoney returns nil", thrown, None)
except Exception as exc:  # noqa: BLE001 - a shim that lets the error out is a failure
    check("throwing GetMoney returns nil", str(exc), None)

# ── Journal runtime ──────────────────────────────────────────────────────

WORLD = r"""
ToonAge = {
  flavor = "forever",
  db = {},
  version = "2.0.0-dev.1",
  unknownEvents = {},
  modules = {},
  _events = {},
  _reject = {},
  _throw = {},
  _noapi = {},
}
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetRegisteredModule(name) return self.modules[name] end
function ToonAge:RegisterEvent(event)
  self._tried = self._tried or {}
  self._tried[#self._tried + 1] = event
  if self._throw[event] then error("missing event " .. event) end
  if self._reject[event] then
    self.unknownEvents[event] = true
    return false
  end
  self._events[#self._events + 1] = event
  return true
end
function ToonAge:HasAPI(path) return self._noapi[path] ~= true end
function ToonAge:ShowCopyWindow(title, text) self._copy = { title = title, text = text } end

NOW = 1700000000
XP = 0
MONEY = 1000
ZONE_ID = 1429
ZONE_NAME = "Elwynn Forest"
KILLER = "Kobold Vermin"
OnTaxiFlag = true

ToonAge.Compat = {}
local C = ToonAge.Compat
function C.ServerTime() return NOW end
function C.FormatTime(t) return tostring(t) end
function C.PlayerXP()
  if ToonAge:HasAPI("UnitXP") then return XP end
  return nil
end
function C.PlayerMoney()
  if ToonAge:HasAPI("GetMoney") then return MONEY end
  return nil
end
function C.PlayerMap()
  if not ToonAge:HasAPI("C_Map.GetBestMapForUnit") then return nil, nil end
  return ZONE_ID, ZONE_NAME
end
function C.QuestTitle(id)
  if not ToonAge:HasAPI("C_QuestLog.GetTitleForQuestID") then return nil end
  return "Kobold Camp"
end
function C.ItemQuality(id)
  if not ToonAge:HasAPI("GetItemInfo") then return nil end
  return 1
end
function C.OnTaxi()
  if not ToonAge:HasAPI("UnitOnTaxi") then return nil end
  return OnTaxiFlag
end
function C.UnitName(unit)
  if unit == "target" then return KILLER end
  return "Eramali"
end
function C.ZoneText() return ZONE_NAME end
function C.RealZoneText() return ZONE_NAME end

loadstring_calls = 0
function loadstring() loadstring_calls = loadstring_calls + 1 error("loadstring") end
function load() loadstring_calls = loadstring_calls + 1 error("load") end
"""


def boot(extra=""):
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(WORLD)
    if extra:
        L.execute(extra)
    L.execute(journey)
    return L, L.globals().ToonAge


if journey:
    # Missing taxi events must be skipped, not thrown.
    L, TA = boot('ToonAge._throw["TAXIMAP_OPENED"] = true; ToonAge._throw["TAXIMAP_CLOSED"] = true')
    J = TA.Journey
    init_ok = True
    try:
        J.Init(J)
    except Exception as exc:  # noqa: BLE001 - the product must not raise
        init_ok = False
        check("Init survives a missing taxi event", str(exc), "")
    check("Init survives a missing taxi event", init_ok)
    check("flights are UNVERIFIED when TAXIMAP_OPENED is missing", J.FlightState(J), "UNVERIFIED")
    tried = [str(e) for e in seq(TA._tried)]
    for ev in ("PLAYER_XP_UPDATE", "CHAT_MSG_COMBAT_XP_GAIN", "QUEST_TURNED_IN",
               "QUEST_ACCEPTED", "PLAYER_DEAD", "PLAYER_MONEY",
               "ZONE_CHANGED_NEW_AREA", "CHAT_MSG_LOOT", "TAXIMAP_OPENED"):
        check(f"tried to register {ev}", ev in tried)
    check("a rejected taxi event is not in the live set",
          "TAXIMAP_OPENED" not in [str(e) for e in seq(TA._events)])

    # XP by source, death, loot, money, zone, quests.
    J.OnEvent(J, "CHAT_MSG_COMBAT_XP_GAIN", "You gain 45 experience.")
    L.execute("XP = 45")
    J.OnEvent(J, "PLAYER_XP_UPDATE", "player")
    J.OnEvent(J, "QUEST_ACCEPTED", 15, 783)
    J.OnEvent(J, "QUEST_TURNED_IN", 783, 200, 0)
    L.execute("XP = 245")
    J.OnEvent(J, "CHAT_MSG_COMBAT_XP_GAIN", "You gain 200 experience.")
    J.OnEvent(J, "PLAYER_XP_UPDATE", "player")
    L.execute("XP = 300")
    J.OnEvent(J, "CHAT_MSG_SYSTEM", "Discovered Northshire: 55 experience gained")
    J.OnEvent(J, "PLAYER_XP_UPDATE", "player")
    L.execute("XP = 310")
    J.OnEvent(J, "PLAYER_XP_UPDATE", "player")
    J.OnEvent(J, "PLAYER_DEAD")
    J.OnEvent(J, "CHAT_MSG_LOOT",
              "You receive loot: |cff9d9d9d|Hitem:2589::::::::1:::::|h[Linen Cloth]|h|rx2.")
    L.execute("MONEY = 1600")
    J.OnEvent(J, "PLAYER_MONEY")
    L.execute("MONEY = 1500")
    J.OnEvent(J, "PLAYER_MONEY")
    L.execute('ZONE_ID = 1431; ZONE_NAME = "Redridge Mountains"')
    J.OnEvent(J, "ZONE_CHANGED_NEW_AREA")

    st = TA.db.journey
    sm = seq(st.ses)[0]
    xp = seq(sm.x)
    check("xp kill", xp[0], 45)
    check("xp quest", xp[1], 200)
    check("xp explore", xp[2], 55)
    check("xp other", xp[3], 10)
    check("one death recorded", sm.d, 1)
    check("loot count", sm.l, 2)
    check("money in", sm.mi, 600)
    check("money out", sm.mo, 100)
    check("quest accepted", sm.qa, 1)
    check("quest turned in", sm.qt, 1)
    check("zone entries include start and the new zone", sm.z >= 2, True)

    # Missing money API is a skip, not an error.
    L.execute('ToonAge._noapi["GetMoney"] = true; MONEY = 99999')
    money_ok = True
    try:
        J.OnEvent(J, "PLAYER_MONEY")
    except Exception as exc:  # noqa: BLE001
        money_ok = False
        check("missing GetMoney does not error", str(exc), "")
    check("missing GetMoney does not error", money_ok)
    check("missing GetMoney records nothing further", sm.mi, 600)

    J.ShowSummary(J)
    text = str(TA._copy.text)
    check("summary opens in the copy window", "session journal" in text.lower())
    check("summary says it stays on this computer", "not uploaded" in text.lower())
    check("summary names the kill total", "kill 45" in text)
    check("summary marks flights UNVERIFIED", "UNVERIFIED" in text)
    check("nothing compiled saved data", L.globals().loadstring_calls, 0)

    # Chunk boundaries.
    L2, TA2 = boot(
        'ToonAge._throw["TAXIMAP_OPENED"] = true; ToonAge._throw["TAXIMAP_CLOSED"] = true\n'
        'ZONE_ID = nil; ZONE_NAME = nil'
    )
    J2 = TA2.Journey
    J2.Init(J2)
    J2.SetChunkCap(J2, 3)
    for i in range(1, 8):
        J2.RecordLoot(J2, 1000 + i, 1, 1)
    chunks = seq(TA2.db.journey.chunks)
    check("7 loot entries become 3 chunks", len(chunks), 3)
    check("chunk 1 is full", len(seq(chunks[0].e)), 3)
    check("chunk 2 is full", len(seq(chunks[1].e)), 3)
    check("chunk 3 holds the remainder", len(seq(chunks[2].e)), 1)
    check("default budget is 64 KB", J2.Budget(J2) == 65536 or TA2.db.journey.b == 65536)

    # Cap: oldest chunks and then oldest sessions go first. Summaries outlive raw.
    L3, TA3 = boot(
        'ToonAge._throw["TAXIMAP_OPENED"] = true; ToonAge._throw["TAXIMAP_CLOSED"] = true\n'
        'ZONE_ID = nil; ZONE_NAME = nil'
    )
    J3 = TA3.Journey
    J3.Init(J3)
    J3.SetBudget(J3, 10000000)
    J3.SetChunkCap(J3, 10)
    L3.execute(r"""
      local n = 0
      function ADD(k)
        for i = 1, k do
          n = n + 1
          ToonAge.Journey:RecordLoot(n, 1, 1)
        end
      end
      for s = 1, 4 do
        if s > 1 then
          ToonAge.Journey:OnEvent("PLAYER_LOGOUT")
          ToonAge.Journey:OpenSession()
        end
        ADD(40)
      end
      LAST_ID = n
    """)
    full = J3.Used(J3)
    budget = max(256, int(full) // 4)
    J3.SetBudget(J3, budget)
    used = J3.Used(J3)
    check("size stays under the cap", used <= budget, True)
    check("the cap actually pruned something", used < full, True)

    def loot_ids(store):
        ids = []
        for ch in seq(store.chunks):
            for e in seq(ch.e):
                kind = e[1]
                if kind == 3:
                    ids.append(int(e[3]))
        return ids

    ids = loot_ids(TA3.db.journey)
    check("at least one raw entry remains", len(ids) > 0, True)
    check("remaining loot ids are a suffix (oldest pruned first)",
          ids, list(range(ids[0], int(L3.globals().LAST_ID) + 1)) if ids else [])
    check("the oldest loot id was pruned", ids[0] > 1, True)

    summary_ids = [int(s.i) for s in seq(TA3.db.journey.ses)]
    chunk_sessions = [int(ch.i) for ch in seq(TA3.db.journey.chunks)]
    check("summary ids are a suffix of the sessions that were opened",
          summary_ids, list(range(summary_ids[0], summary_ids[0] + len(summary_ids))) if summary_ids else [])
    check("every remaining chunk belongs to a kept summary",
          set(chunk_sessions) <= set(summary_ids), True)
    check("a summary outlives its raw chunk",
          len(set(summary_ids) - set(chunk_sessions)) >= 1, True)

    # Clear is two clicks, and it does not compile the store.
    before = len(seq(TA3.db.journey.chunks))
    first = J3.RequestClear(J3)
    check("first clear click asks for confirmation", first, False)
    check("first clear click keeps the data", len(seq(TA3.db.journey.chunks)), before)
    second = J3.RequestClear(J3)
    check("second clear click wipes the journal", second, True)
    check("chunks are gone", len(seq(TA3.db.journey.chunks)), 0)
    check("sessions are gone", len(seq(TA3.db.journey.ses)), 0)
    check("clear keeps the configured budget", J3.Budget(J3), budget)
    check("clear did not compile anything", L3.globals().loadstring_calls, 0)

    # Flights when the taxi events exist.
    L4, TA4 = boot("")
    J4 = TA4.Journey
    J4.Init(J4)
    check("flights are armed when TAXIMAP_OPENED registers", J4.FlightState(J4), "ready")
    J4.OnEvent(J4, "TAXIMAP_OPENED")
    L4.execute('ZONE_ID = 1455; ZONE_NAME = "Ironforge"')
    J4.OnEvent(J4, "PLAYER_CONTROL_LOST")
    J4.OnEvent(J4, "PLAYER_CONTROL_GAINED")
    sm4 = seq(TA4.db.journey.ses)[0]
    check("a flight was recorded", sm4.f, 1)
    flight = None
    for ch in seq(TA4.db.journey.chunks):
        for e in seq(ch.e):
            if e[1] == 8:
                flight = e
    check("flight entry exists", flight is not None, True)
    strings = seq(TA4.db.journey.s)
    start = strings[int(flight[3]) - 1] if flight is not None else None
    end = strings[int(flight[4]) - 1] if flight is not None else None
    check("flight starts where the taxi map opened", start, "Elwynn Forest")
    check("flight ends at the arrival zone", end, "Ironforge")

    # Retail flavor stands down and does not register.
    L5, TA5 = boot('ToonAge.flavor = "retail"')
    J5 = TA5.Journey
    J5.Init(J5)
    check("retail flavor does not register journal events", len(seq(TA5._tried)), 0)
    check("retail flavor does not create a journal store", TA5.db.journey, None)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
