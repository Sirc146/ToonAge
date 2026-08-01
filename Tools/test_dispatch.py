#!/usr/bin/env python3
"""
ToonAge 2.0 -- Core event dispatcher behaviour tests
====================================================
Executes Rebuild-2.0/Core/Init.lua in an embedded Lua 5.1 runtime (the version
WoW uses) against a stub WoW API, and asserts on what the dispatcher actually
does.

The 2.0 Core replaces 1.x's broadcast bus -- every persistent event walked all
55 registered modules -- with event -> subscriber lists in deterministic
registration order. That change has one catastrophic failure mode and it is
SILENT: a module that stops receiving events raises nothing and prints nothing,
it just quietly stops working. Same shape as the 12.1.0 C_Navigation.GetDestination
removal. So the single most important test in this file is not a performance
one, it is `undeclared_module_still_receives_everything`.

check_lua.py proves a file parses. This proves the dispatcher routes, orders,
isolates failures, and stays backward compatible.

Setup
-----
    python -m pip install --user lupa

Usage
-----
    python Tools/test_dispatch.py          # run all
    python Tools/test_dispatch.py -v       # show each assertion

What this does NOT cover
------------------------
Real frames, real taint, real SavedVariables persistence, and whether
UnitName("player") is actually populated at PLAYER_LOGIN on a cold login in a
live client. The boot-phase split is designed so that last question does not
need answering -- but the design is what is tested here, not the client.
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

TWO_OH = "Rebuild-2.0/Core/Init.lua"
LEGACY = "Core/Init.lua"


def _read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


# ── Stub WoW API ──────────────────────────────────────────────────────────────
# Frames respond to any method call and return themselves, so UI code runs
# without erroring. RegisterEvent is stubbed explicitly rather than falling
# through, for two reasons: the tests need to see which events Core actually
# registered, and RegisterEvent on an unknown event name is a real error in the
# live client -- which is the whole point of Core's SafeRegisterEvent.
PRELUDE = r"""
_printed = {}
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    _printed[#_printed + 1] = table.concat(parts, " ")
end

-- Event names the "client" does not know. Registering one errors, exactly as
-- the live API does for an event removed in a patch.
_badEvents = {}

function MockFrame(name)
    local f = { _name = name, _shown = false }
    rawset(f, "_scripts", {})
    rawset(f, "_children", {})
    rawset(f, "_events", {})
    setmetatable(f, { __index = function(s, k)
        local fn = function(...) return s end
        rawset(s, k, fn)
        return fn
    end })
    f.Show    = function(s) rawset(s, "_shown", true);  return s end
    f.Hide    = function(s) rawset(s, "_shown", false); return s end
    f.IsShown = function(s) return rawget(s, "_shown") end
    f.SetScript = function(s, ev, fn) rawget(s, "_scripts")[ev] = fn; return s end
    f.GetScript = function(s, ev) return rawget(s, "_scripts")[ev] end

    f.RegisterEvent = function(s, ev)
        if _badEvents[ev] then
            error("Attempt to register unknown event: " .. tostring(ev), 2)
        end
        rawget(s, "_events")[ev] = true
        return s
    end
    f.UnregisterEvent = function(s, ev)
        rawget(s, "_events")[ev] = nil
        return s
    end
    f.IsEventRegistered = function(s, ev)
        return rawget(s, "_events")[ev] and true or false
    end
    return f
end

CreateFrame = function(kind, name, parent, template)
    local f = MockFrame(name)
    if type(parent) == "table" and rawget(parent, "_children") then
        local kids = rawget(parent, "_children")
        kids[#kids + 1] = f
    end
    return f
end

-- ── Virtual clock ─────────────────────────────────────────────────────────
_timers = {}
_now = 0
C_Timer = {
    After = function(delay, fn)
        _timers[#_timers + 1] = { at = _now + delay, fn = fn, done = false }
    end,
}

function AdvanceTo(target)
    while true do
        local pick, pickAt
        for i, t in ipairs(_timers) do
            if not t.done and t.at <= target then
                if pickAt == nil or t.at < pickAt then pick, pickAt = i, t.at end
            end
        end
        if not pick then break end
        _timers[pick].done = true
        _now = pickAt
        _timers[pick].fn()
    end
    _now = target
end

-- Player identity, switchable per scenario so the "identity not ready" path
-- can actually be driven.
_unitName  = "Testchar"
_realmName = "Testrealm"
UnitName     = function() return _unitName end
GetRealmName = function() return _realmName end

_inCombat = false
InCombatLockdown = function() return _inCombat end

time    = function() return 1750000000 end
GetTime = function() return _now end
hooksecurefunc = function(name, fn) end
SlashCmdList = {}
NUM_CHAT_WINDOWS = 0
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UIParent = MockFrame("UIParent")
GameTooltip = MockFrame("GameTooltip")

-- ── Test module factories ─────────────────────────────────────────────────
-- Records every delivery with its full vararg payload, so both "did it arrive"
-- and "did it arrive intact" are answerable.
function MakeModule(name)
    local m = { _name = name, _got = {} }
    m.OnEvent = function(self, event, ...)
        local rec = { event = event, n = select('#', ...) }
        for i = 1, select('#', ...) do rec[i] = (select(i, ...)) end
        self._got[#self._got + 1] = rec
    end
    return m
end

--- Throws on every OnEvent. `_calls` counts attempts, which is what proves the
--- module was still *reached* after being muted or disabled.
function MakeThrower(name)
    local m = { _name = name, _calls = 0 }
    m.OnEvent = function(self, event, ...)
        self._calls = self._calls + 1
        error(name .. " boom")
    end
    return m
end

--- Counts deliveries only. For the broadcast-vs-subscriber measurement.
function MakeCounter(name)
    local m = { _name = name, _n = 0 }
    m.OnEvent = function(self) self._n = self._n + 1 end
    return m
end

-- Appends to one shared list as it is called, so the ORDER the dispatcher
-- actually delivered in is observable. Reading module registration state back
-- afterwards cannot see delivery order and would pass even if dispatch walked
-- pairs() -- that mistake let a pairs() mutation survive once already.
_deliveryOrder = {}
function MakeOrderedModule(name)
    local m = { _name = name }
    m.OnEvent = function(self, event, ...)
        _deliveryOrder[#_deliveryOrder + 1] = name
    end
    return m
end

-- Events the dispatch order test uses. Names chosen so that pairs() order over
-- them is not insertion order -- otherwise "we preserve order" would pass by
-- luck rather than by design.
_ORDER_NAMES = { "Zulu", "Alpha", "Mike", "Bravo", "Yankee", "Charlie", "Xray", "Delta" }

--- What pairs() would have given. Recorded for the ordering test's diagnostic.
function PairsOrder(tbl)
    local out = {}
    for k in pairs(tbl) do out[#out + 1] = k end
    return table.concat(out, ",")
end
"""

# Core siblings that 2.0's OnLogin calls but that live in other files. Stubbed
# rather than loaded: this suite tests Core/Init.lua's dispatcher, and dragging
# UI.lua and MinimapButton.lua in would test them too.
CORE_STUBS = r"""
local TA = ToonAge
_applyLayoutCalls = 0
TA.InitUI       = function(self) end
TA.InitMinimap  = function(self) end
TA.ApplyLayout  = function(self) _applyLayoutCalls = _applyLayoutCalls + 1 end
TA.ToggleOptionsPanel = function(self) end
TA.Utils = {
    GetPlayerClass = function() return "MONK" end,
    GetPlayerLevel = function() return 80 end,
    GetProfessions = function() return { "Mining", "Herbalism" } end,
}
"""


class Harness:
    """One scenario. Fresh runtime every time -- ToonAgeDB, TA.modules and the
    module registry are globals that would otherwise leak between scenarios and
    produce failures that are pure contamination."""

    def __init__(self, source=TWO_OH, bad_events=None, db_literal="{}"):
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(PRELUDE)
        if bad_events:
            for ev in bad_events:
                self.lua.execute(f'_badEvents["{ev}"] = true')
        self.lua.execute(_read(source))
        self.lua.execute(f"ToonAgeDB = {db_literal}")
        self.lua.execute(CORE_STUBS)
        self.TA = self.lua.globals().ToonAge

    # ── driving ──────────────────────────────────────────────────────────
    @property
    def g(self):
        return self.lua.globals()

    def register(self, name, events=None, kind="MakeModule"):
        """Registers a fake module. events=None -> legacy broadcast (2-arg call,
        exactly as all 55 real modules do today)."""
        if events is None:
            self.lua.execute(
                f'ToonAge:RegisterModule("{name}", {kind}("{name}"))')
        else:
            items = ", ".join(f'"{e}"' for e in events)
            self.lua.execute(
                f'ToonAge:RegisterModule("{name}", {kind}("{name}"), {{{items}}})')
        return self.TA.modules[name]

    def fire(self, event, *args):
        """Drives the real OnEvent script the way the client would."""
        frame = self.TA.eventFrame
        handler = frame._scripts.OnEvent
        if handler is None:
            raise AssertionError("Core never installed an OnEvent script")
        handler(frame, event, *args)

    def boot(self, through="world"):
        """Runs the boot sequence. 'db' | 'login' | 'world'."""
        self.fire("ADDON_LOADED", "ToonAge")
        if through in ("login", "world"):
            self.fire("PLAYER_LOGIN")
        if through == "world":
            self.fire("PLAYER_ENTERING_WORLD")
        return self

    def got(self, mod):
        """List of {event, args} deliveries recorded by a MakeModule fake."""
        out = []
        recs = mod._got
        for i in range(1, len(recs) + 1):
            rec = recs[i]
            args = [rec[j] for j in range(1, int(rec.n) + 1)]
            out.append({"event": rec.event, "args": args})
        return out

    def events_of(self, mod):
        return [d["event"] for d in self.got(mod)]

    def registered(self, event):
        return bool(self.TA.eventFrame.IsEventRegistered(self.TA.eventFrame, event))

    def printed(self):
        p = self.g._printed
        return [p[i] for i in range(1, len(p) + 1)]

    def order(self):
        mo = self.TA.moduleOrder
        return [mo[i] for i in range(1, len(mo) + 1)]

    def lua_list(self, expr):
        t = self.lua.eval(expr)
        return [t[i] for i in range(1, len(t) + 1)]


# ── assertion plumbing ────────────────────────────────────────────────────────
_checks = 0
_failures = []


def check(label, cond, detail=""):
    global _checks
    _checks += 1
    if cond:
        if VERBOSE:
            print(f"  ok    {label}")
    else:
        _failures.append(f"{label}\n        {detail}")
        print(f"  FAIL  {label}")
        if detail:
            print(f"        {detail}")


def eq(label, got, want):
    check(label, got == want, f"got {got!r}, want {want!r}")


def section(title):
    if VERBOSE:
        print(f"\n{title}")


# ══════════════════════════════════════════════════════════════════════════════
# 1. THE COMPATIBILITY GUARANTEE
# ══════════════════════════════════════════════════════════════════════════════
def test_undeclared_module_receives_everything():
    """The most important test in this file.

    All 55 real modules register with the 2-arg call and declare nothing. If the
    subscriber-list dispatcher gives them zero events, 35 OnEvent handlers go
    silently dead -- no error, no message, nothing in the error log. The
    dispatcher's default must be fail-OPEN."""
    section("compatibility: undeclared modules")
    h = Harness()
    legacy = h.register("LegacyMod")            # 2-arg, exactly like today
    h.boot()

    for ev in ("BAG_UPDATE", "PLAYER_LEVEL_UP", "ZONE_CHANGED", "CHAT_MSG_SYSTEM"):
        h.fire(ev)

    eq("undeclared module receives every non-core event",
       h.events_of(legacy),
       ["BAG_UPDATE", "PLAYER_LEVEL_UP", "ZONE_CHANGED", "CHAT_MSG_SYSTEM"])


def test_declared_module_receives_only_its_own():
    section("routing: declared modules")
    h = Harness()
    picky = h.register("Picky", ["BAG_UPDATE"])
    h.boot()

    for ev in ("BAG_UPDATE", "PLAYER_LEVEL_UP", "ZONE_CHANGED"):
        h.fire(ev)

    eq("declared module receives only its declared event",
       h.events_of(picky), ["BAG_UPDATE"])


def test_empty_declaration_is_not_no_declaration():
    """events={} means 'I want nothing'. events=nil means 'nobody has migrated
    me yet'. If those two look alike, the migration is unauditable."""
    section("routing: empty declaration")
    h = Harness()
    silent = h.register("SilentMod", [])        # explicit opt-out
    legacy = h.register("LegacyMod")            # never migrated
    h.boot()
    h.fire("BAG_UPDATE")

    eq("explicit empty declaration receives nothing", h.events_of(silent), [])
    eq("undeclared still receives", h.events_of(legacy), ["BAG_UPDATE"])

    declared, broadcast, _ = h.TA.GetDispatchReport(h.TA)
    dec_names = [declared[i].name for i in range(1, len(declared) + 1)]
    bc_names = [broadcast[i] for i in range(1, len(broadcast) + 1)]
    eq("report lists the opted-out module as declared", dec_names, ["SilentMod"])
    eq("report lists the unmigrated module as broadcast", bc_names, ["LegacyMod"])


def test_declared_event_outside_persistent_list():
    """1.x could only dispatch the 17 hardcoded PERSISTENT_EVENTS. A module
    wanting anything else had to have that array edited. Declaring it should be
    enough."""
    section("routing: events outside PERSISTENT_EVENTS")
    h = Harness()
    exotic = h.register("Exotic", ["ENCOUNTER_START"])
    h.boot()

    check("Core registered the frame for the declared event",
          h.registered("ENCOUNTER_START"))
    h.fire("ENCOUNTER_START", 42)
    eq("module receives an event that is not in PERSISTENT_EVENTS",
       h.events_of(exotic), ["ENCOUNTER_START"])


def test_core_events_not_broadcast():
    """Core registers PLAYER_REGEN_ENABLED for its own combat-deferral queue.
    Broadcast modules have never received it, and a dispatcher change must not
    hand them new events as a side effect."""
    section("routing: core-only events")
    h = Harness()
    legacy = h.register("LegacyMod")
    watcher = h.register("Watcher", ["PLAYER_REGEN_ENABLED", "PLAYER_LOGIN"])
    h.boot(through="login")

    h.fire("PLAYER_REGEN_ENABLED")

    eq("broadcast module does not receive core lifecycle events",
       h.events_of(legacy), [])
    eq("a module that explicitly declares them does",
       h.events_of(watcher), ["PLAYER_LOGIN", "PLAYER_REGEN_ENABLED"])


# ══════════════════════════════════════════════════════════════════════════════
# 2. ORDERING
# ══════════════════════════════════════════════════════════════════════════════
def test_registration_order_is_deterministic():
    """1.x walked pairs() for both init and dispatch, so module order varied
    between logins and any implicit inter-module dependency worked
    intermittently -- the worst class of bug to diagnose in the field."""
    section("ordering")
    names = ["Zulu", "Alpha", "Mike", "Bravo", "Yankee", "Charlie", "Xray", "Delta"]

    orders = []
    for _ in range(2):
        h = Harness()
        for n in names:
            h.register(n, kind="MakeOrderedModule")
        h.boot()
        h.fire("BAG_UPDATE")
        # The order the dispatcher actually called them in, recorded from
        # inside the handlers as they ran.
        orders.append(h.lua_list("_deliveryOrder"))

    eq("dispatch order equals registration order", orders[0], names)
    eq("order is identical across two independent runs", orders[0], orders[1])

    # Ordering must survive the cache being rebuilt, and a late registration
    # must land at the end rather than wherever the hash puts it.
    h = Harness()
    for n in names:
        h.register(n, kind="MakeOrderedModule")
    h.boot()
    h.register("LateComer", kind="MakeOrderedModule")
    h.lua.execute("_deliveryOrder = {}")
    h.fire("BAG_UPDATE")
    eq("a module registered later dispatches last",
       h.lua_list("_deliveryOrder"), names + ["LateComer"])

    # Diagnostic only: if pairs() happened to agree with insertion order, the
    # test above proved less than it looks. Report it either way.
    h = Harness()
    for n in names:
        h.register(n)
    hash_order = h.lua.eval("PairsOrder(ToonAge.modules)").split(",")
    if VERBOSE:
        same = hash_order == names
        print(f"        pairs() order was {'THE SAME as' if same else 'different from'} "
              f"insertion order: {','.join(hash_order)}")


def test_init_order_is_deterministic():
    section("ordering: InitModules")
    h = Harness()
    h.lua.execute("_initOrder = {}")
    for n in ["Zulu", "Alpha", "Mike", "Bravo"]:
        h.lua.execute(f"""
            local m = MakeModule("{n}")
            m.Init = function(self) _initOrder[#_initOrder+1] = "{n}" end
            ToonAge:RegisterModule("{n}", m)
        """)
    h.boot()
    eq("InitModules runs in registration order",
       h.lua_list("_initOrder"), ["Zulu", "Alpha", "Mike", "Bravo"])


def test_duplicate_registration_is_rejected():
    """moduleOrder is an append-only array shadowing a keyed map, which is a
    shape that corrupts quietly: a second registration under the same name
    would overwrite the map entry but append a *second* order entry, and the
    module would then be dispatched twice per event forever."""
    section("ordering: duplicate registration")
    h = Harness()
    h.register("Twice", kind="MakeOrderedModule")
    h.register("Twice", kind="MakeOrderedModule")
    h.boot()
    h.lua.execute("_deliveryOrder = {}")
    h.fire("BAG_UPDATE")

    eq("registry holds one entry", h.order(), ["Twice"])
    eq("and the module is dispatched exactly once",
       h.lua_list("_deliveryOrder"), ["Twice"])
    printed = " ".join(h.printed())
    check("the duplicate was reported, not silently ignored",
          "registered twice" in printed, printed[:300])


# ══════════════════════════════════════════════════════════════════════════════
# 3. FAULT ISOLATION
# ══════════════════════════════════════════════════════════════════════════════
def test_throwing_subscriber_does_not_block_siblings():
    section("fault isolation")
    h = Harness()
    a = h.register("Ayy")
    h.register("Boom", kind="MakeThrower")
    c = h.register("Cee")
    h.boot()
    h.fire("BAG_UPDATE")

    eq("module registered before the thrower still ran", h.events_of(a), ["BAG_UPDATE"])
    eq("module registered after the thrower still ran", h.events_of(c), ["BAG_UPDATE"])


def test_auto_disable_trips_at_ten_errors():
    section("fault isolation: auto-disable")
    h = Harness()
    boom = h.register("Boom", kind="MakeThrower")
    h.boot()

    for _ in range(9):
        h.fire("BAG_UPDATE")
    eq("still enabled after 9 errors", bool(boom._disabled), False)
    eq("error count tracked", int(boom._errorCount), 9)

    h.fire("BAG_UPDATE")
    eq("auto-disabled on the 10th error", bool(boom._disabled), True)
    eq("flagged as auto-disabled, not user-disabled", bool(boom._autoDisabled), True)

    calls_at_disable = int(boom._calls)
    h.fire("BAG_UPDATE")
    eq("a disabled module is not called again", int(boom._calls), calls_at_disable)

    printed = " ".join(h.printed())
    check("chat spam is capped, not the error log",
          printed.count("OnEvent error") == 3,
          f"printed {printed.count('OnEvent error')} error lines, want 3")


def test_auto_disable_mid_dispatch_does_not_skip_siblings():
    """The tenth error flips _disabled while the dispatch loop for that very
    event is still running. If the loop resolved _disabled when it built its
    list, or mutated the list, the modules queued behind the failing one would
    be skipped for that event."""
    section("fault isolation: mutation during iteration")
    h = Harness()
    m1 = h.register("One")
    m2 = h.register("Two")
    h.register("Three", kind="MakeThrower")     # the one that will trip
    m4 = h.register("Four")
    m5 = h.register("Five")
    h.boot()

    for _ in range(10):
        h.fire("BAG_UPDATE")

    three = h.TA.modules["Three"]
    eq("module three auto-disabled", bool(three._disabled), True)
    eq("module four received all 10, including the trip event", len(h.got(m4)), 10)
    eq("module five received all 10, including the trip event", len(h.got(m5)), 10)
    eq("modules ahead of it were unaffected", len(h.got(m1)), 10)
    eq("...both of them", len(h.got(m2)), 10)


def test_unknown_event_name_does_not_take_core_down():
    """RegisterEvent errors on an event the client does not know. With modules
    free to declare arbitrary events, one module naming an event removed in a
    12.x patch would otherwise stop the whole addon loading."""
    section("fault isolation: unknown event names")
    h = Harness(bad_events=["C_REMOVED_IN_1210"])
    doomed = h.register("Doomed", ["C_REMOVED_IN_1210", "BAG_UPDATE"])
    legacy = h.register("LegacyMod")
    h.boot()
    h.fire("BAG_UPDATE")

    check("Core survived and kept dispatching", h.events_of(legacy) == ["BAG_UPDATE"])
    eq("the module's surviving declaration still works",
       h.events_of(doomed), ["BAG_UPDATE"])
    printed = " ".join(h.printed())
    check("the rejection was reported, not swallowed",
          "C_REMOVED_IN_1210" in printed, printed[:200])


# ══════════════════════════════════════════════════════════════════════════════
# 4. PAYLOAD INTEGRITY
# ══════════════════════════════════════════════════════════════════════════════
def test_varargs_pass_through_intact():
    """Handlers read positionally -- GET_ITEM_INFO_RECEIVED takes (itemID,
    success). Packing `...` into a table on the way through would break every
    one of them."""
    section("payload integrity")
    h = Harness()
    m = h.register("Watcher")
    h.boot()

    h.fire("GET_ITEM_INFO_RECEIVED", 6948, True)
    h.fire("UNIT_PET", "player")
    h.fire("CHAT_MSG_SYSTEM", "a", "b", "c")

    got = h.got(m)
    eq("two-arg payload intact", got[0]["args"], [6948, True])
    eq("one-arg payload intact", got[1]["args"], ["player"])
    eq("three-arg payload intact", got[2]["args"], ["a", "b", "c"])


def test_nil_in_vararg_run_is_preserved():
    section("payload integrity: embedded nil")
    h = Harness()
    h.lua.execute("""
        _seen = nil
        local m = { }
        m.OnEvent = function(self, event, ...) _seen = select('#', ...) end
        ToonAge:RegisterModule("Counter", m)
    """)
    h.boot()
    h.lua.execute('ToonAge:Dispatch("BAG_UPDATE", 1, nil, 3)')
    eq("arity including embedded nil is preserved", int(h.g._seen), 3)


# ══════════════════════════════════════════════════════════════════════════════
# 5. THE BOOT SPLIT (F-1)
# ══════════════════════════════════════════════════════════════════════════════
def test_boot_phases_are_split_correctly():
    """1.x deferred everything to PLAYER_ENTERING_WORLD behind a comment that
    was factually wrong. Moving it all to ADDON_LOADED is the opposite trap:
    charKey would be built from unit data that is not ready, and the
    `or "Unknown"` fallback would have made that silent."""
    section("boot phases (F-1)")
    h = Harness()

    h.fire("ADDON_LOADED", "ToonAge")
    check("account DB exists after ADDON_LOADED", h.TA.db is not None)
    check("character key NOT built at ADDON_LOADED", h.TA.charKey is None,
          f"charKey was {h.TA.charKey!r}")

    h.fire("PLAYER_LOGIN")
    eq("character key built at PLAYER_LOGIN", h.TA.charKey, "Testchar-Testrealm")
    check("profession snapshot NOT taken at PLAYER_LOGIN",
          h.TA.charDB.professionSnapshot is None)

    h.fire("PLAYER_ENTERING_WORLD")
    check("profession snapshot taken at first world entry",
          h.TA.charDB.professionSnapshot is not None)
    eq("snapshot has real data", h.TA.charDB.professionSnapshot["class"], "MONK")


def test_legacy_initdb_shim():
    """1.x's InitDB was split into InitAccountDB + InitCharDB. The old name is
    kept for the same fail-open reason as UpdateModules -- a caller predating
    the boot split should not have to know about it. Verified by grep that no
    module calls it; kept anyway, because the failure mode is a broken login."""
    section("compatibility: the 1.x InitDB name")
    h = Harness()
    h.TA.InitDB(h.TA)
    check("InitDB still builds the account DB", h.TA.db is not None)
    eq("...and the character DB", h.TA.charKey, "Testchar-Testrealm")


def test_addon_loaded_ignores_other_addons():
    section("boot phases: foreign ADDON_LOADED")
    h = Harness()
    h.fire("ADDON_LOADED", "SomeOtherAddon")
    check("another addon's load does not initialise our DB", h.TA.db is None)
    h.fire("ADDON_LOADED", "ToonAge")
    check("our own load does", h.TA.db is not None)


def test_player_entering_world_is_idempotent():
    """PEW fires again on every zone and instance change. The snapshot must be
    taken once, not on every loading screen."""
    section("boot phases: repeated PLAYER_ENTERING_WORLD")
    h = Harness()
    h.boot()
    first = h.TA.charDB.professionSnapshot
    h.lua.execute('ToonAge.Utils.GetPlayerClass = function() return "CHANGED" end')
    h.fire("PLAYER_ENTERING_WORLD")
    h.fire("PLAYER_ENTERING_WORLD")
    eq("snapshot taken once, not re-taken per zone change",
       h.TA.charDB.professionSnapshot["class"], "MONK")


def test_missing_identity_is_loud():
    """The failure this must never repeat silently: a char["Unknown-Unknown"]
    bucket that swallows the character's settings with no visible symptom."""
    section("boot phases: identity unavailable")
    h = Harness()
    h.lua.execute("_unitName = nil")
    h.fire("ADDON_LOADED", "ToonAge")
    h.fire("PLAYER_LOGIN")

    printed = " ".join(h.printed())
    check("an unavailable character identity is reported at ERROR",
          "Character identity unavailable" in printed, printed[:300])
    eq("and it still degrades to a usable key", h.TA.charKey, "Unknown-Testrealm")


# ══════════════════════════════════════════════════════════════════════════════
# 6. THE SMALLER DEFECTS (F-2 .. F-7)
# ══════════════════════════════════════════════════════════════════════════════
def test_f2_command_list_has_no_second_source():
    """1.x kept a hardcoded array of built-in names in GetAllCommandNames
    alongside the real BUILTIN table, and they had already drifted: `verbose`
    was implemented but absent from the array, so `/ta verb` never matched."""
    section("F-2: single command registry")
    h = Harness()
    h.boot(through="login")
    names = h.lua_list("ToonAge:GetAllCommandNames()")

    check("verbose is discoverable (the 1.x drift bug)", "verbose" in names, str(names))
    check("dispatch is discoverable", "dispatch" in names, str(names))
    for expected in ("gear", "toggle", "health", "layout", "safemode", "reset"):
        check(f"{expected} is discoverable", expected in names)

    # The prefix path is what actually broke in 1.x.
    h.lua.execute('ToonAge:SlashCommand("verb")')
    printed = " ".join(h.printed())
    check("`/ta verb` prefix-resolves to verbose",
          "Chat verbosity" in printed, printed[-300:])


def test_f5_log_level_has_one_source_of_truth():
    section("F-5: single verbosity source")
    h = Harness()
    h.boot(through="login")

    eq("reads the saved value", int(h.TA.GetLogLevel(h.TA)), 2)
    h.lua.execute('ToonAge:SlashCommand("verbose debug")')
    eq("setting it updates the DB", int(h.TA.db.logLevel), 4)
    eq("and the accessor agrees", int(h.TA.GetLogLevel(h.TA)), 4)
    check("no second mirrored field remains", h.TA.logLevel is None,
          f"TA.logLevel is {h.TA.logLevel!r} -- the 1.x mirror is back")


def test_f5_boot_level_applies_before_db_exists():
    section("F-5: verbosity before the DB exists")
    h = Harness()
    eq("boot default is WARN with no DB loaded", int(h.TA.GetLogLevel(h.TA)), 2)
    h.lua.execute('ToonAge:Print(ToonAge.LOG.INFO, nil, "chatty")')
    eq("INFO output is suppressed at boot", h.printed(), [])
    h.lua.execute('ToonAge:Print(ToonAge.LOG.OUTPUT, nil, "answer")')
    eq("OUTPUT is never suppressed", len(h.printed()), 1)


def test_f4_frame_commands_are_combat_guarded():
    """/ta layout calls ApplyLayout, which moves frames, and is reachable from a
    SetItemRef hyperlink click -- a tainted path. 1.x had zero
    InCombatLockdown checks in this file."""
    section("F-4: combat guard")
    h = Harness()
    h.boot(through="login")
    before = int(h.g._applyLayoutCalls)

    h.lua.execute("_inCombat = true")
    h.lua.execute('ToonAge:SlashCommand("layout")')
    eq("layout does not touch frames during combat",
       int(h.g._applyLayoutCalls), before)
    printed = " ".join(h.printed())
    check("the user is told it was deferred, not silently dropped",
          "will run when you leave combat" in printed, printed[-300:])

    h.lua.execute("_inCombat = false")
    h.fire("PLAYER_REGEN_ENABLED")
    eq("and it runs once combat ends", int(h.g._applyLayoutCalls), before + 1)


def test_f4_out_of_combat_is_immediate():
    section("F-4: no deferral out of combat")
    h = Harness()
    h.boot(through="login")
    before = int(h.g._applyLayoutCalls)
    h.lua.execute('ToonAge:SlashCommand("layout")')
    eq("layout applies immediately out of combat",
       int(h.g._applyLayoutCalls), before + 1)


def test_f6_fuzzy_score_is_bounded():
    section("F-6: bounded fuzzy matching")
    h = Harness()
    eq("wildly mismatched lengths short-circuit to 0",
       float(h.TA.FuzzyScore(h.TA, "ab", "abcdefghijklmnop")), 0.0)
    eq("over-long input is rejected",
       float(h.TA.FuzzyScore(h.TA, "x" * 40, "x" * 40)), 0.0)
    check("a real near-match still scores above threshold",
          float(h.TA.FuzzyScore(h.TA, "helth", "health")) >= 0.6,
          str(float(h.TA.FuzzyScore(h.TA, "helth", "health"))))
    eq("an exact match is 1.0", float(h.TA.FuzzyScore(h.TA, "gear", "gear")), 1.0)


def test_f7_reset_repoints_accessors():
    section("F-7: reset does not orphan the DB")
    h = Harness()
    h.boot(through="login")
    h.lua.execute("ToonAge.db.logLevel = 4")
    h.lua.execute('ToonAge:SlashCommand("reset")')

    eq("reset restored defaults", int(h.TA.db.logLevel), 2)
    check("the accessor points at the live table, not the orphan",
          h.TA.GetDB(h.TA) is not None)
    eq("character data was rebuilt too", h.TA.charKey, "Testchar-Testrealm")
    check("charDB accessor is live", h.TA.GetCharDB(h.TA) is not None)


def test_safe_mode_still_works():
    """Carried forward from 1.x untouched, so it needs a regression test rather
    than a new one."""
    section("carried forward: Safe Mode")
    h = Harness(db_literal="{ safeMode = true }")
    h.register("Arrow")             # in SAFE_MODE_KEEP
    h.register("GatherTracker")     # not
    h.boot()

    eq("core module still initialised", bool(h.TA.modules["Arrow"]._disabled), False)
    eq("optional module skipped", bool(h.TA.modules["GatherTracker"]._disabled), True)
    eq("and marked as safe-skipped, not user-disabled",
       bool(h.TA.modules["GatherTracker"]._safeSkipped), True)


def test_user_disabled_module_is_not_dispatched():
    section("carried forward: /ta toggle")
    h = Harness(db_literal="{ modules = { NavHud = false } }")
    nav = h.register("NavHud")
    h.boot()
    h.fire("BAG_UPDATE")
    eq("a module turned off by the user receives nothing", h.events_of(nav), [])


# ══════════════════════════════════════════════════════════════════════════════
# 7. THE MEASUREMENT
# ══════════════════════════════════════════════════════════════════════════════
def test_dispatch_volume_against_legacy():
    """The rewrite's headline claim, measured rather than asserted.

    Same workload against both files: 55 registered modules, 35 with an OnEvent
    handler, BAG_UPDATE fired 5 times (roughly one loot -- it fires once per
    bag). 1.x delivers to all 35 every time. 2.0 delivers only to subscribers.

    Counted deliveries, not wall time: an invocation count is deterministic and
    cannot flake, and each avoided delivery is one avoided pcall plus its
    allocation, which is the GC-spike source DIRECTIVE 3.2 names."""
    section("measurement: dispatch volume")

    # --- 1.x baseline -------------------------------------------------------
    legacy = Harness(source=LEGACY)
    legacy.lua.execute("_total = 0")
    for i in range(35):
        legacy.lua.execute(f"""
            local m = {{}}
            m.OnEvent = function(self) _total = _total + 1 end
            ToonAge:RegisterModule("Mod{i}", m)
        """)
    for i in range(35, 55):
        legacy.lua.execute(f'ToonAge:RegisterModule("Inert{i}", {{}})')
    legacy.TA.InitDB(legacy.TA)
    for _ in range(5):
        legacy.TA.UpdateModules(legacy.TA, "BAG_UPDATE")
    legacy_calls = int(legacy.g._total)

    # --- 2.0, with three modules migrated ----------------------------------
    modern = Harness()
    modern.lua.execute("_total = 0")
    for i in range(35):
        events = '{"BAG_UPDATE"}' if i < 3 else "{}"
        modern.lua.execute(f"""
            local m = {{}}
            m.OnEvent = function(self) _total = _total + 1 end
            ToonAge:RegisterModule("Mod{i}", m, {events})
        """)
    for i in range(35, 55):
        modern.lua.execute(f'ToonAge:RegisterModule("Inert{i}", {{}}, {{}})')
    modern.boot()
    for _ in range(5):
        modern.fire("BAG_UPDATE")
    modern_calls = int(modern.g._total)

    eq("1.x delivers BAG_UPDATE to all 35 handlers, 5x", legacy_calls, 175)
    eq("2.0 delivers only to the 3 subscribers, 5x", modern_calls, 15)
    check("2.0 does strictly less dispatch work for the same events",
          modern_calls < legacy_calls,
          f"2.0 {modern_calls} vs 1.x {legacy_calls}")

    if VERBOSE:
        cut = 100 * (1 - modern_calls / legacy_calls)
        print(f"        {legacy_calls} -> {modern_calls} handler invocations "
              f"per simulated loot ({cut:.0f}% fewer)")


def test_fully_unmigrated_matches_legacy_volume():
    """The other half of the compatibility guarantee: before anyone migrates
    anything, 2.0 must do exactly what 1.x did. Not less."""
    section("measurement: unmigrated parity")
    modern = Harness()
    modern.lua.execute("_total = 0")
    for i in range(35):
        modern.lua.execute(f"""
            local m = {{}}
            m.OnEvent = function(self) _total = _total + 1 end
            ToonAge:RegisterModule("Mod{i}", m)
        """)
    modern.boot()
    for _ in range(5):
        modern.fire("BAG_UPDATE")
    eq("an unmigrated 2.0 matches 1.x delivery exactly",
       int(modern.g._total), 175)


# ══════════════════════════════════════════════════════════════════════════════
def main():
    # Declaration order, not alphabetical -- the file reads as a narrative and
    # the compatibility guarantee should be the first thing that fails.
    tests = [v for k, v in globals().items() if k.startswith("test_")]
    for t in tests:
        t()

    print()
    if _failures:
        print(f"[FAIL] {len(_failures)} of {_checks} checks failed:")
        for f in _failures:
            print(f"  - {f}")
        return 1
    print(f"[OK] {_checks} checks passed.")
    print("     Behaviour only. Real frames, real taint and real")
    print("     SavedVariables persistence still need the game.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
