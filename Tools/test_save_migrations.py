#!/usr/bin/env python3
"""
ToonAge -- old-save migration replay
====================================
Loads Core/Init.lua under the shared offline client and runs the synthetic
ToonAgeDB fixtures in Tools/fixtures/saves/ through ACCOUNT_MIGRATIONS.

  * an unstamped v0 save reaches the current schema
  * a schema-1 save reaches the current schema, and the analytics step
    turns off an unasked-for default without touching an explicit opt-in
  * a step that throws does not advance the version and does not run the
    next step (the throwing step is injected; the shipped steps are not
    rewritten)
  * a save from a newer build is left untouched

Names in the fixtures are fake. Nothing here is a copy of a WTF file.

Usage:  python Tools/test_save_migrations.py [-v]
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness.wowsim import World  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SAVES = ROOT / "Tools" / "fixtures" / "saves"
VERBOSE = "-v" in sys.argv
_results = []

PLAYER = {
    "name": "Pebble",
    "realm": "Fakeserver",
    "level": 42,
    "class": "Mage",
    "class_file": "MAGE",
    "race": "Human",
    "race_file": "Human",
}


def check(name, ok):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print("  %s  %s" % ("ok  " if ok else "FAIL", name))
    return ok


def boot(fixture_name):
    world = World("tbc", files=["Core/Init.lua"], player=PLAYER, root=ROOT)
    errors = world.load()
    if errors:
        raise RuntimeError("Init.lua failed to load: %s" % errors[0])
    chunk = (SAVES / fixture_name).read_text(encoding="utf-8")
    world.assign_saved("ToonAgeDB", chunk)
    world.lua.execute("ToonAge:InitDB()")
    return world


def main():
    world = boot("account_v0_onboarding.lua")
    lua = world.lua
    current = lua.eval("ToonAge.SCHEMA_VERSION")
    check("schema version is at least 1", current >= 1)
    check(
        "v0 save reaches current schema",
        lua.eval("ToonAgeDB.schemaVersion") == current,
    )
    check(
        "v0 onboarding became a hard off",
        lua.eval("ToonAgeDB.newCharBehavior") == "off",
    )
    check(
        "v0 dropped onboardScope",
        lua.eval("ToonAgeDB.onboardScope") is None,
    )
    check(
        "v0 dropped onboardedAccount",
        lua.eval("ToonAgeDB.onboardedAccount") is None,
    )

    world = boot("account_v1_analytics_on.lua")
    lua = world.lua
    check(
        "v1 default-on analytics reaches current schema",
        lua.eval("ToonAgeDB.schemaVersion") == current,
    )
    check(
        "v1 default-on analytics is turned off",
        lua.eval("ToonAgeDB.analytics") == False,  # noqa: E712
    )
    check(
        "v1 default-on analytics is stamped so it will not run again",
        lua.eval("ToonAgeDB.analyticsOptInMigration") == 1,
    )

    world = boot("account_v1_analytics_opted_in.lua")
    lua = world.lua
    check(
        "explicit analytics opt-in stays on",
        lua.eval("ToonAgeDB.analytics") == True  # noqa: E712
        and lua.eval("ToonAgeDB.schemaVersion") == current,
    )

    world = boot("account_newer_build.lua")
    lua = world.lua
    check(
        "newer schema version is not rewritten",
        lua.eval("ToonAgeDB.schemaVersion") == 999,
    )
    check(
        "newer save keeps onboardScope",
        lua.eval("ToonAgeDB.onboardScope") == "account",
    )
    check(
        "newer save keeps its marker",
        lua.eval("ToonAgeDB.marker") == "newer-build-synthetic",
    )
    check(
        "newer save records the downgrade guard",
        lua.eval("ToonAge._migrationError") is not None,
    )

    # Injected failure. The shipped migration list is not edited on disk;
    # the extra steps exist only in this runtime.
    lua.execute(
        """
        local list = ToonAge._AccountMigrations
        local cur = ToonAge.SCHEMA_VERSION
        list[cur + 1] = function() error("synthetic failure") end
        list[cur + 2] = function(db) db.shouldNotRun = true end
        db = { schemaVersion = cur, marker = "keep" }
        versionReached, err = ToonAge._RunMigrations(db, list, cur + 2, "account")
        """
    )
    check(
        "failed step does not advance the version",
        lua.eval("versionReached") == current
        and lua.eval("db.schemaVersion") == current,
    )
    check(
        "failed step returns the error",
        "synthetic failure" in str(lua.eval("err") or ""),
    )
    check(
        "a later step does not run after a failure",
        lua.eval("db.shouldNotRun") is None,
    )
    check(
        "a failed step leaves the save's other fields in place",
        lua.eval("db.marker") == "keep",
    )

    passed = sum(_results)
    print("[%s] %d/%d assertions passed." % ("OK" if passed == len(_results) else "FAIL", passed, len(_results)))
    return 0 if passed == len(_results) else 1


if __name__ == "__main__":
    sys.exit(main())
