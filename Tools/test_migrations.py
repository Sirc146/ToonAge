#!/usr/bin/env python3
"""
ToonAge -- SavedVariables schema migration tests
================================================
Exercises TA:InitDB's versioned migration runner (Core/Init.lua) with the real
file loaded under the onboarding test's WoW API prelude:

  * fresh install is stamped with the current schema, no migrations run
  * unstamped existing data is version 0 and is upgraded to current
  * a failing step stops at the last good version, logs, and does not abort
  * a later login retries the failed step
  * data from a newer build is left untouched (downgrade guard)
  * new characters are stamped; existing characters run CHAR_MIGRATIONS

Usage:  python Tools/test_migrations.py [-v]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_onboarding import PRELUDE, _read  # noqa: E402

from lupa import lua51

VERBOSE = "-v" in sys.argv
_results = []


def check(name, ok):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")


def boot(db_literal="nil", prep=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(_read("Core/Init.lua"))
    lua.execute(f"ToonAgeDB = {db_literal}")
    lua.execute("_logged = {}; ToonAge.ErrorLog = { Log = function(_, a, b) table.insert(_logged, b) end }")
    if prep:
        lua.execute(prep)
    TA = lua.globals().ToonAge
    TA.InitDB(TA)
    return lua, TA


lua, TA = boot()
cur = TA.SCHEMA_VERSION
check("schema version >= 1", cur >= 1)
check("fresh install stamped current", lua.eval("ToonAgeDB.schemaVersion") == cur)

lua, TA = boot('{ onboardScope = "account", onboardedAccount = true, char = {} }')
check("unstamped data upgraded to current", lua.eval("ToonAgeDB.schemaVersion") == cur)
check("migration 1 translated onboarding", lua.eval("ToonAgeDB.newCharBehavior") == "off")
check("migration 1 removed old keys", lua.eval("ToonAgeDB.onboardScope") is None)

# Downgrade guard
lua, TA = boot('{ schemaVersion = 999, onboardScope = "account", char = {} }')
check("newer schema left unchanged", lua.eval("ToonAgeDB.schemaVersion") == 999)
check("newer schema: migrations not run", lua.eval("ToonAgeDB.onboardScope") == "account")
check("newer schema: warning recorded", TA._migrationError is not None)

# Failure + retry, using an injected step beyond current
prep = f"""
    local list = ToonAge._AccountMigrations
    list[{cur + 1}] = function(db) if not db.allowStep then error("boom") end db.movedOK = true end
"""
lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(PRELUDE)
lua.execute(_read("Core/Init.lua"))
lua.execute(f"_logged = {{}}; ToonAge.ErrorLog = {{ Log = function(_, a, b) table.insert(_logged, b) end }}")
lua.execute(prep)
lua.execute(f"db = {{ schemaVersion = {cur} }}")
v, err = lua.eval(f"ToonAge._RunMigrations(db, ToonAge._AccountMigrations, {cur + 1}, 'account')")
check("failed step keeps last good version", v == cur and lua.eval("db.schemaVersion") == cur)
check("failed step returns error", err is not None and "boom" in err)
check("failed step logged", lua.eval("#_logged") == 1)
lua.execute("db.allowStep = true")
v, err = lua.eval(f"ToonAge._RunMigrations(db, ToonAge._AccountMigrations, {cur + 1}, 'account')")
check("retry succeeds next login", v == cur + 1 and err is None and lua.eval("db.movedOK"))
v, err = lua.eval(f"ToonAge._RunMigrations(db, ToonAge._AccountMigrations, {cur + 1}, 'account')")
check("already-current is a no-op", v == cur + 1 and err is None)

# Characters
lua, TA = boot("{ char = {} }")
check("new character stamped", lua.eval("ToonAge.charDB.schemaVersion") == TA.CHAR_SCHEMA_VERSION)
lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute(PRELUDE)
lua.execute(_read("Core/Init.lua"))
lua.execute("""
    local name = (UnitName("player") or "Unknown") .. "-" .. (GetRealmName() or "Unknown")
    ToonAgeDB = { schemaVersion = ToonAge.SCHEMA_VERSION, char = { [name] = { oldKey = 5 } } }
    local list = ToonAge._CharMigrations
    local n = #list + 1
    list[n] = function(c, key) c.newKey = c.oldKey; c.oldKey = nil; c.who = key end
    ToonAge.CHAR_SCHEMA_VERSION_TEST = n
""")
# CHAR_SCHEMA_VERSION is captured at load; run the runner directly for the char path
lua.execute("""
    local key = (UnitName("player") or "Unknown") .. "-" .. (GetRealmName() or "Unknown")
    local c = ToonAgeDB.char[key]
    ToonAge._RunMigrations(c, ToonAge._CharMigrations, ToonAge.CHAR_SCHEMA_VERSION_TEST, "character", key)
""")
check("existing character migrated", lua.eval(
    "(function() for _, c in pairs(ToonAgeDB.char) do return c.newKey == 5 and c.oldKey == nil and c.schemaVersion == ToonAge.CHAR_SCHEMA_VERSION_TEST end end)()"))

passed = sum(_results)
print(f"[{'OK' if passed == len(_results) else 'FAIL'}] {passed}/{len(_results)} assertions passed.")
sys.exit(0 if passed == len(_results) else 1)
