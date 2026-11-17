#!/usr/bin/env python3
"""
ToonAge -- Forever and Retail offline replay
============================================
Boots ToonAge_Camelot.toc on the Forever snapshot and ToonAge_Mainline.toc
on the Retail snapshot, through Tools/harness/wowsim.py.

Asserts:
  * both snapshots load and the probe contract holds (a probed-missing
    global is nil; a probed-present global exists; non-probe rows are
    UNVERIFIED)
  * no Lua file fails to load, and OnLogin / module init do not fail,
    except ids listed in KNOWN_FAILURES with a reason
  * a JSON report is written and has one entry per check

Harness, tab-render, and safe-event results are in the report. They are
not load/init failures. A module that errors during init is a failure
unless its check id is listed below.

Usage:  python Tools/test_replay.py [-v]
"""

import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness.wowsim import World, load_snapshot  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
_results = []

# check id -> why this load or init failure is accepted.
# Empty means that boot is expected to be clean. Do not hide a new error
# by adding it here without a reason that names the snapshot gap.
KNOWN_FAILURES = {
    "forever": {},
    "retail": {},
}

# Probe 2026-09-28. These must be nil on that client, not a stub.
FOREVER_ABSENT = (
    "GetNumSkillLines",
    "GetSkillLineInfo",
    "UnitAttackBothHands",
    "UnitDefense",
    "UnitRangedAttack",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetTalentInfo",
    "GetItemInfo",
    "GetSpellInfo",
    "GetItemStats",
    "GetSpellCooldown",
    "GetItemInfoInstant",
    "PickupContainerItem",
    "GetSpecialization",
    "UnitAura",
    "GetPVPRankInfo",
    "UnitPVPRank",
)
RETAIL_ABSENT = (
    "GetSpellInfo",
    "UnitAura",
    "PickupContainerItem",
    "GetNumTalentTabs",
    "GetTalentTabInfo",
    "GetPVPRankInfo",
    "UnitPVPRank",
)
RETAIL_PRESENT = (
    "GetItemInfoInstant",
    "GetSpecialization",
    "C_AssistedCombat",
    "CreateFramePool",
)


def check(name, ok):
    _results.append(bool(ok))
    if VERBOSE or not ok:
        print("  %s  %s" % ("ok  " if ok else "FAIL", name))
    return ok


def assert_contract(snap):
    for group in (snap["apis"], snap["events"]):
        for name, entry in group.items():
            if entry["status"] not in ("present", "missing"):
                return False
            if entry["source"] not in ("probe", "ui-source", "wiki"):
                return False
            if not entry["build"]:
                return False
            if entry["source"] == "probe" and entry["unverified"]:
                return False
            if entry["source"] != "probe" and not entry["unverified"]:
                return False
            if entry["source"] == "probe" and name not in _probe_names(snap["id"]):
                return False
    return True


def _probe_names(client):
    if client == "forever":
        return set(FOREVER_ABSENT) | {"HONOR_CURRENCY_UPDATE", "PLAYER_PET_CHANGED"}
    if client == "retail":
        return set(RETAIL_ABSENT) | set(RETAIL_PRESENT)
    return set()


def globals_nil(world, names):
    for name in names:
        value = world.lua.eval(name)
        if value is not None:
            return False
    return True


def boot(snapshot):
    world = World(snapshot, root=ROOT)
    world.load()
    world.login()
    world.fire_safe_events()
    world.render_tabs()
    world.run_harness()
    return world


def main():
    for client in ("forever", "retail"):
        snap = load_snapshot(client)
        check(client + " snapshot rows carry status, source, build, UNVERIFIED", assert_contract(snap))
        counts = {"probe": 0, "wiki": 0, "ui-source": 0}
        unverified = {"probe": 0, "wiki": 0, "ui-source": 0}
        for group in (snap["apis"], snap["events"]):
            for entry in group.values():
                counts[entry["source"]] += 1
                if entry["unverified"]:
                    unverified[entry["source"]] += 1
        print(
            "%s snapshot  probe=%d wiki=%d ui-source=%d  UNVERIFIED wiki=%d ui-source=%d"
            % (client, counts["probe"], counts["wiki"], counts["ui-source"],
               unverified["wiki"], unverified["ui-source"])
        )

    world = boot("forever")
    check("Forever probed-missing globals are nil", globals_nil(world, FOREVER_ABSENT))
    check(
        "Forever probed-missing events are not fired",
        all(
            c["status"] == "skip"
            for c in world.checks
            if c["id"] in ("event:HONOR_CURRENCY_UPDATE", "event:PLAYER_PET_CHANGED")
        ),
    )
    _expect_boot(world, "forever")

    world = boot("retail")
    check("Retail probed-absent globals are nil", globals_nil(world, RETAIL_ABSENT))
    check(
        "Retail GetItemInfoInstant is present",
        world.lua.eval("type(GetItemInfoInstant)") == "function",
    )
    check(
        "Retail GetSpecialization is present",
        world.lua.eval("type(GetSpecialization)") == "function",
    )
    check(
        "Retail C_AssistedCombat is present",
        world.lua.eval("type(C_AssistedCombat)") == "table",
    )
    check(
        "Retail CreateFramePool is present",
        world.lua.eval("type(CreateFramePool)") == "function",
    )
    _expect_boot(world, "retail")

    pkg = (ROOT / ".pkgmeta").read_text(encoding="utf-8")
    check("pkgmeta ignores Tools", "\n    - Tools\n" in pkg or pkg.strip().endswith("- Tools"))

    passed = sum(_results)
    print("[%s] %d/%d assertions passed." % ("OK" if passed == len(_results) else "FAIL", passed, len(_results)))
    return 0 if passed == len(_results) else 1


def _expect_boot(world, client):
    known = KNOWN_FAILURES[client]
    unexpected = []
    for item in world.checks:
        if item["phase"] not in ("load", "init"):
            continue
        if item["status"] != "fail":
            continue
        if item["id"] not in known:
            unexpected.append(item)
    if unexpected and not VERBOSE:
        for item in unexpected:
            print("  FAIL  %s %s: %s" % (client, item["id"], item["detail"]))
    elif VERBOSE:
        for item in world.checks:
            if item["phase"] in ("load", "init") and item["status"] != "pass":
                print("  %s  %s %s" % (item["status"], item["id"], item["detail"]))
    check(client + " has no unexpected load or init errors", unexpected == [])
    for check_id, reason in known.items():
        check(client + " known failure has a reason: " + check_id, bool(reason))

    summary = world.summary()
    print(
        "%s replay  pass=%d fail=%d warn=%d skip=%d info=%d  load_errors=%d"
        % (
            client,
            summary.get("pass", 0),
            summary.get("fail", 0),
            summary.get("warn", 0),
            summary.get("skip", 0),
            summary.get("info", 0),
            len(world.load_errors),
        )
    )
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / (client + ".json")
        world.write_report(path)
        payload = json.loads(path.read_text(encoding="utf-8"))
    check(client + " report is a JSON object", isinstance(payload, dict))
    check(client + " report lists every check", len(payload.get("checks", [])) == len(world.checks))
    check(client + " report names the snapshot", payload.get("snapshot", "").endswith(client + ".lua"))
    if payload.get("checks"):
        check(
            client + " report checks carry unverified dependencies",
            "unverified" in payload["checks"][0],
        )
    else:
        check(client + " report has checks", False)


if __name__ == "__main__":
    sys.exit(main())
