#!/usr/bin/env python3
"""Usage reporting is off unless the player opts in.

Christopher's decision (2026-11-12): "Opt in by choice". The shipped default
used to be analytics = true, and the collector treated every value except
false as on. These checks pin the opposite:

  * every profile / default table ships analytics = false
  * a saved analytics = true with no explicit opt-in is flipped off once
  * an explicit opt-in (analyticsOptedIn / analyticsOptInAt) is preserved
  * Switch, Count, Set, RecordSession and Init record nothing while off

Usage:  python Tools/test_analytics_opt_in.py [-v]
"""
import os
import re
import sys
from pathlib import Path

from lupa import lua51

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_onboarding import PRELUDE, _read  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_res = []

FLAVORS = ("retail", "tbc", "mists", "vanilla", "cata", "wrath", "forever", "unknown")


def check(name, got, want):
    ok = got == want
    _res.append(ok)
    if VERBOSE or not ok:
        print(("[  ok  ] " if ok else "[ FAIL ] ") + name)
        if not ok:
            print(f"          got:  {got!r}\n          want: {want!r}")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def extract_assigned_table(src, name):
    """Brace-matched table literal assigned to `name`, or None."""
    match = re.search(r"(?:local\s+)?" + re.escape(name) + r"\s*=\s*\{", src)
    if not match:
        return None
    start = match.end() - 1
    depth = 0
    for i in range(start, len(src)):
        ch = src[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return src[start:i + 1]
    return None


def assigned_table_names(src):
    names = set(re.findall(
        r"(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*(?:DEFAULTS|Defaults)|PROFILES)\s*=\s*\{",
        src,
    ))
    return names


# ── Shipped defaults: off in every profile / default table ────────────────
default_tables = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in {".git", "Libs", "Archive", "Tools"}]
    for filename in filenames:
        if not filename.endswith(".lua"):
            continue
        rel = os.path.relpath(os.path.join(dirpath, filename), ROOT)
        src = read(rel)
        for name in sorted(assigned_table_names(src)):
            body = extract_assigned_table(src, name)
            if body is None:
                continue
            default_tables.append((rel, name, body))

check("found at least one default table", len(default_tables) > 0, True)
saw_account_default = False
for rel, name, body in default_tables:
    if re.search(r"analytics\s*=\s*true", body):
        check(f"{rel} {name} does not default analytics on", False, True)
    if name == "DB_DEFAULTS":
        saw_account_default = True
        check(f"{rel} DB_DEFAULTS analytics is false",
              re.search(r"analytics\s*=\s*false", body) is not None, True)
check("account DB_DEFAULTS exists", saw_account_default, True)

profile_body = extract_assigned_table(read("Core/Profile.lua"), "PROFILES")
check("PROFILES table found", profile_body is not None, True)
if profile_body:
    check("no profile defaults analytics on",
          re.search(r"analytics\s*=\s*true", profile_body) is None, True)
    for flavor in FLAVORS:
        if flavor == "unknown":
            continue
        check(f"profile table has {flavor}",
              re.search(r"\b" + flavor + r"\s*=\s*\{", profile_body) is not None, True)


def boot(db_literal="nil", prep=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(f"ToonAgeDB = {db_literal}")
    if prep:
        lua.execute(prep)
    ta = lua.globals().ToonAge
    ta.InitDB(ta)
    return lua, ta


for flavor in FLAVORS:
    lua, _ta = boot("nil", prep=f"ToonAge.flavor = {flavor!r}")
    check(f"{flavor} fresh profile analytics is false",
          lua.eval("ToonAgeDB.analytics"), False)
    check(f"{flavor} fresh profile has no opt-in record",
          lua.eval("ToonAgeDB.analyticsOptedIn"), None)
    check(f"{flavor} fresh profile has no opt-in timestamp",
          lua.eval("ToonAgeDB.analyticsOptInAt"), None)


# ── Migration: default-on without a choice flips off once ─────────────────
KEPT = """
    analytics = true,
    schemaVersion = 1,
    logLevel = 0,
    safeMode = true,
    customNote = "leave-this",
    minimap = { minimized = true, position = 12 },
    modules = { NavHud = false, MapPins = true },
    char = { ["Keep-Me"] = { marker = 7, tracker = { autoRewardPick = true } } },
"""

lua, ta = boot("{" + KEPT + "}")
check("migration flips default-on to false", lua.eval("ToonAgeDB.analytics"), False)
check("migration stamps the one-time flag",
      lua.eval("ToonAgeDB.analyticsOptInMigration"), 1)
check("migration advances schema",
      lua.eval("ToonAgeDB.schemaVersion") == ta.SCHEMA_VERSION, True)
check("migration keeps customNote", lua.eval("ToonAgeDB.customNote"), "leave-this")
check("migration keeps logLevel", lua.eval("ToonAgeDB.logLevel"), 0)
check("migration keeps safeMode", lua.eval("ToonAgeDB.safeMode"), True)
check("migration keeps minimap position", lua.eval("ToonAgeDB.minimap.position"), 12)
check("migration keeps minimap minimized", lua.eval("ToonAgeDB.minimap.minimized"), True)
check("migration keeps module off choice", lua.eval("ToonAgeDB.modules.NavHud"), False)
check("migration keeps other character",
      lua.eval('ToonAgeDB.char["Keep-Me"].marker'), 7)
check("migration keeps nested character data",
      lua.eval('ToonAgeDB.char["Keep-Me"].tracker.autoRewardPick'), True)

# Second login must not run the flip again. A later edit of the boolean,
# without an opt-in record, is left alone because the flag already ran.
lua.execute("ToonAgeDB.analytics = true; ToonAgeDB.analyticsOptedIn = nil")
ta.InitDB(ta)
check("second login does not flip analytics again",
      lua.eval("ToonAgeDB.analytics"), True)
check("second login keeps the one-time flag",
      lua.eval("ToonAgeDB.analyticsOptInMigration"), 1)
check("second login still keeps customNote",
      lua.eval("ToonAgeDB.customNote"), "leave-this")

# Unstamped saves (schema 0) take the same one-time flip.
lua, _ta = boot("{ analytics = true, customNote = 'unstamped', char = {} }")
check("unstamped default-on flips to false", lua.eval("ToonAgeDB.analytics"), False)
check("unstamped save keeps other keys", lua.eval("ToonAgeDB.customNote"), "unstamped")
check("unstamped save stamps the flag",
      lua.eval("ToonAgeDB.analyticsOptInMigration"), 1)

# Calling the shipped step twice is a no-op the second time.
lua, ta = boot("nil")
has_step = lua.eval("type(ToonAge._AccountMigrations[2]) == 'function'")
check("account migration 2 is the opt-in step", has_step, True)
if has_step:
    lua.execute("""
        mig = {
            analytics = true,
            customNote = "direct",
            minimap = { position = 3 },
            char = { ["Keep-Me"] = { marker = 1 } },
        }
        ToonAge._AccountMigrations[2](mig)
        first = mig.analytics
        mig.analytics = true
        mig.analyticsOptedIn = nil
        ToonAge._AccountMigrations[2](mig)
    """)
    check("direct migration flips default-on the first time", lua.eval("first"), False)
    check("flagged migration does not flip a later true", lua.eval("mig.analytics"), True)
    check("direct second call keeps the flag", lua.eval("mig.analyticsOptInMigration"), 1)
    check("direct migration keeps customNote", lua.eval("mig.customNote"), "direct")
    check("direct migration keeps minimap", lua.eval("mig.minimap.position"), 3)
    check("direct migration keeps character", lua.eval('mig.char["Keep-Me"].marker'), 1)
else:
    for name in (
        "direct migration flips default-on the first time",
        "flagged migration does not flip a later true",
        "direct second call keeps the flag",
        "direct migration keeps customNote",
        "direct migration keeps minimap",
        "direct migration keeps character",
    ):
        check(name, None, False)


# ── Explicit opt-in is a real choice and is not undone ────────────────────
lua, _ta = boot("""{
    analytics = true,
    analyticsOptedIn = true,
    analyticsOptInAt = 1700000000,
    schemaVersion = 1,
    customNote = "opted",
    logLevel = 3,
    char = { ["Keep-Me"] = { marker = 9 } },
}""")
check("opt-in keeps analytics on", lua.eval("ToonAgeDB.analytics"), True)
check("opt-in record stays true", lua.eval("ToonAgeDB.analyticsOptedIn"), True)
check("opt-in timestamp stays", lua.eval("ToonAgeDB.analyticsOptInAt"), 1700000000)
check("opt-in migration still stamps the flag",
      lua.eval("ToonAgeDB.analyticsOptInMigration"), 1)
check("opt-in keeps customNote", lua.eval("ToonAgeDB.customNote"), "opted")
check("opt-in keeps logLevel", lua.eval("ToonAgeDB.logLevel"), 3)
check("opt-in keeps character", lua.eval('ToonAgeDB.char["Keep-Me"].marker'), 9)

if lua.eval("type(ToonAge._AccountMigrations[2]) == 'function'"):
    lua.execute("""
        opted = {
            analytics = true,
            analyticsOptedIn = true,
            analyticsOptInAt = 42,
            customNote = "still",
        }
        ToonAge._AccountMigrations[2](opted)
        ToonAge._AccountMigrations[2](opted)
    """)
    check("direct migration preserves explicit opt-in", lua.eval("opted.analytics"), True)
    check("direct migration preserves opt-in record", lua.eval("opted.analyticsOptedIn"), True)
    check("direct migration preserves opt-in time", lua.eval("opted.analyticsOptInAt"), 42)
    check("direct migration preserves opted note", lua.eval("opted.customNote"), "still")
else:
    for name in (
        "direct migration preserves explicit opt-in",
        "direct migration preserves opt-in record",
        "direct migration preserves opt-in time",
        "direct migration preserves opted note",
    ):
        check(name, None, False)


# ── Collection no-ops while off, at every entry point ─────────────────────
ANALYTICS_PRELUDE = r"""
ToonAge = { flavor = "retail", db = {}, charDB = { tracker = {} }, modules = { a = 1 },
            Utils = { ZygorLoaded = function() return false end,
                      DeferToZygor = function() return false end } }
recorded = {}
local function rec(kind)
    return function(_, name, value)
        recorded[#recorded + 1] = { kind = kind, name = name, value = value }
    end
end
fakeSink = {
    Switch = rec("switch"), IncrementCounter = rec("inc"),
    SetCounter = rec("set"), DecrementCounter = rec("dec"),
}
LibStub = function() return { RegisterAddon = function() return fakeSink end } end
time = function() return 1750000000 end
"""


def load_analytics(extra=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(ANALYTICS_PRELUDE)
    if extra:
        lua.execute(extra)
    lua.execute(_read("Core/Analytics.lua"))
    return lua, lua.globals().ToonAge.Analytics


def recorded_count(lua):
    return lua.eval("#recorded")


def exercise(analytics, lua):
    analytics.Init(analytics)
    analytics.Switch(analytics, "client:retail", True)
    analytics.Count(analytics, "errors:session", 1)
    analytics.Set(analytics, "modules:loaded", 3)
    analytics.RecordSession(analytics)


for label, extra in (
    ("analytics false", "ToonAge.db.analytics = false"),
    ("analytics nil", "ToonAge.db.analytics = nil"),
    ("analytics true without opt-in", "ToonAge.db.analytics = true"),
    ("opt-in record but analytics false",
     "ToonAge.db.analytics = false; ToonAge.db.analyticsOptedIn = true"),
):
    lua, analytics = load_analytics(extra)
    exercise(analytics, lua)
    check(f"{label}: collection records nothing", recorded_count(lua), 0)
    check(f"{label}: Init leaves reporting disabled", analytics.enabled, False)

# Live flag: Init already opened the sink, then the player turns it off
# without another Init. Every entry point must re-read the flag.
lua, analytics = load_analytics(
    "ToonAge.db.analytics = true; ToonAge.db.analyticsOptedIn = true")
analytics.Init(analytics)
check("opted in and Wago present enables", analytics.enabled, True)
analytics.RecordSession(analytics)
check("opted in records a session", recorded_count(lua) > 0, True)
lua.execute("recorded = {}")
lua.execute("ToonAge.db.analytics = false")
check("sink still enabled in memory", analytics.enabled, True)
for name in ("Switch", "Count", "Set", "RecordSession"):
    getattr(analytics, name)(analytics, "probe", 1)
check("Switch, Count, Set and RecordSession no-op when analytics is false",
      recorded_count(lua), 0)
analytics.Init(analytics)
check("Init disables when analytics is false", analytics.enabled, False)

lua, analytics = load_analytics(
    "ToonAge.db.analytics = true; ToonAge.db.analyticsOptedIn = true")
analytics.Init(analytics)
lua.execute("recorded = {}")
lua.execute("ToonAge.db.analyticsOptedIn = nil")
check("memory stays enabled until an entry point re-reads", analytics.enabled, True)
for name in ("Switch", "Count", "Set", "RecordSession"):
    getattr(analytics, name)(analytics, "probe", 1)
check("Switch, Count, Set and RecordSession no-op without the opt-in record",
      recorded_count(lua), 0)
analytics.Init(analytics)
check("Init disables without the opt-in record", analytics.enabled, False)


# ── The Settings toggle is what writes the opt-in record ──────────────────
lua, analytics = load_analytics("ToonAge.db = { customNote = 'keep', logLevel = 2 }")
has_setter = lua.eval("type(ToonAge.Analytics.SetOptIn) == 'function'")
check("Settings opt-in writer exists", has_setter, True)
if not has_setter:
    for name in (
        "turning on sets analytics",
        "turning on writes analyticsOptedIn",
        "turning on writes analyticsOptInAt",
        "turning on keeps other keys",
        "turning on allows collection",
        "turning off clears analytics",
        "turning off clears the opt-in record",
        "turning off does not delete the timestamp",
        "turning off keeps other keys",
        "turning off stops collection",
    ):
        check(name, None, False)
else:
    analytics.SetOptIn(analytics, True)
    check("turning on sets analytics", lua.eval("ToonAge.db.analytics"), True)
    check("turning on writes analyticsOptedIn", lua.eval("ToonAge.db.analyticsOptedIn"), True)
    check("turning on writes analyticsOptInAt", lua.eval("ToonAge.db.analyticsOptInAt"), 1750000000)
    check("turning on keeps other keys", lua.eval("ToonAge.db.customNote"), "keep")
    analytics.Init(analytics)
    analytics.RecordSession(analytics)
    check("turning on allows collection", recorded_count(lua) > 0, True)

    lua.execute("recorded = {}")
    analytics.SetOptIn(analytics, False)
    check("turning off clears analytics", lua.eval("ToonAge.db.analytics"), False)
    check("turning off clears the opt-in record", lua.eval("ToonAge.db.analyticsOptedIn"), False)
    check("turning off does not delete the timestamp",
          lua.eval("ToonAge.db.analyticsOptInAt"), 1750000000)
    check("turning off keeps other keys", lua.eval("ToonAge.db.logLevel"), 2)
    exercise(analytics, lua)
    check("turning off stops collection", recorded_count(lua), 0)

settings = read("Modules/Infrastructure/Settings.lua")
check("settings says usage stats are off unless you turn this on",
      "off unless you turn this on" in settings, True)
check("settings routes the toggle through SetOptIn",
      "TA.Analytics:SetOptIn(not TA.Analytics:IsOptedIn())" in settings, True)
check("settings no longer treats nil analytics as on",
      "not (TA.db and TA.db.analytics == false)" not in settings, True)

readme = read("README.md")
check("readme says reporting is off unless you turn it on",
      "off unless you turn it on" in readme, True)
check("readme no longer describes an opt-out default",
      "You have not turned it off" not in readme, True)

analytics_src = read("Core/Analytics.lua")
check("health line says off unless you turn it on",
      "off unless you turn it on in Settings" in analytics_src, True)

passed, total = sum(_res), len(_res)
print(f"\n[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
