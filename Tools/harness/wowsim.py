#!/usr/bin/env python3
"""
ToonAge -- shared offline WoW client (lupa / Lua 5.1)
=====================================================
Loads the files a TOC lists, in that order, into one fake client whose
globals come from a snapshot in Tools/fixtures/api/. A name the snapshot
does not list is left nil, so a Retail-only call on the Forever snapshot
fails here the same way it would fail in that client.

The frame mock generalises the prelude that used to live in
Tools/test_tbc_boot.py: unknown widget methods return the frame, and a key
that starts with "_" is data, not a method.

Depends only on lupa. The standard-library json module writes the report.

    python Tools/harness/wowsim.py forever --report /tmp/forever.json
    python Tools/harness/wowsim.py retail
    python Tools/harness/wowsim.py tbc
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install -r Tools/requirements.txt")

HARNESS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = HARNESS_DIR.parent
ROOT = TOOLS_DIR.parent
API_DIR = TOOLS_DIR / "fixtures" / "api"
ENGINE_PATH = HARNESS_DIR / "engine.lua"

# Same safe list the in-game harness fires (Modules/Infrastructure/TestHarness.lua).
# These only ask modules to read. Loot, merchant, quest accept, and level-up
# are not here.
SAFE_EVENTS = (
    ("PLAYER_EQUIPMENT_CHANGED", 16, False),
    ("UNIT_INVENTORY_CHANGED", "player"),
    ("SKILL_LINES_CHANGED",),
    ("PLAYER_TALENT_UPDATE",),
    ("UNIT_PET", "player"),
    ("PLAYER_XP_UPDATE", "player"),
    ("UNIT_STATS", "player"),
    ("SPELLS_CHANGED",),
    ("ZONE_CHANGED_NEW_AREA",),
    ("GET_ITEM_INFO_RECEIVED", 6948, True),
)

HARNESS_SUITES = (
    "env", "gate", "api", "state", "guides", "events",
    "tabs", "settings", "bridge", "perf", "blocks",
)

_COLOR = re.compile(r"\|c[0-9A-Fa-f]{8}")
_RESULT = re.compile(r"^(PASS|FAIL|WARN|SKIP|INFO)\s+(\S+)\s+(.*)$")
_ALLOWED_STATUS = {"present", "missing"}
_ALLOWED_SOURCE = {"probe", "ui-source", "wiki"}


def lua_quote(text):
    return '"' + str(text).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def toc_lines(toc_path):
    return (ROOT / toc_path).read_text(encoding="utf-8").splitlines()


def toc_entries(toc_name):
    """(kind, relpath) in TOC order. kind is 'lua' or 'other'."""
    out = []
    for line in toc_lines(toc_name):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        token = s.split("[")[0].strip().replace("\\", "/")
        if not token or token.startswith("##"):
            continue
        kind = "lua" if token.lower().endswith(".lua") else "other"
        out.append((kind, token))
    return out


def toc_metadata(toc_name):
    meta = {}
    for line in toc_lines(toc_name):
        s = line.strip()
        if not s.startswith("##"):
            continue
        body = s[2:].strip()
        if ":" not in body:
            continue
        key, value = body.split(":", 1)
        meta[key.strip()] = value.strip()
    return meta


def _lua_table(value):
    """True when `value` is a lupa table."""
    return type(value).__name__ == "_LuaTable"


def _as_bool(value):
    if isinstance(value, bool):
        return value
    if value in (1, 1.0):
        return True
    if value in (0, 0.0, None):
        return False
    return bool(value)


def _entry(table, require_kind):
    status = str(table["status"] or "")
    source = str(table["source"] or "")
    build = str(table["build"] or "")
    if status not in _ALLOWED_STATUS:
        raise ValueError("status must be present or missing, got %r" % status)
    if source not in _ALLOWED_SOURCE:
        raise ValueError("source must be probe, ui-source, or wiki, got %r" % source)
    if not build:
        raise ValueError("snapshot entry is missing build")
    unverified = _as_bool(table["unverified"])
    if source == "probe" and unverified:
        raise ValueError("a probe entry cannot be UNVERIFIED")
    if source != "probe" and not unverified:
        raise ValueError("a %s entry must be UNVERIFIED" % source)
    kind = str(table["kind"] or "function") if require_kind else None
    out = {
        "status": status,
        "source": source,
        "build": build,
        "unverified": unverified,
    }
    if require_kind:
        out["kind"] = kind
    return out


def _walk_map(table, require_kind):
    out = {}
    if table is None:
        return out
    for key, value in table.items():
        out[str(key)] = _entry(value, require_kind)
    return out


def load_snapshot(name_or_path):
    path = Path(name_or_path)
    if not path.is_file():
        path = API_DIR / (str(name_or_path) + ".lua")
    if not path.is_file():
        raise FileNotFoundError("no snapshot at %s" % path)
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    table = lua.execute(path.read_text(encoding="utf-8"))
    if not _lua_table(table):
        raise ValueError("%s did not return a table" % path)
    player = table["player"]
    snap = {
        "path": path,
        "id": str(table["id"]),
        "label": str(table["label"] or table["id"]),
        "toc": str(table["toc"]),
        "interface": int(table["interface"]),
        "project_id": int(table["project_id"]),
        "version": str(table["version"]),
        "build": str(table["build"]),
        "build_date": str(table["build_date"]),
        "text_font": str(table["text_font"] or "Fonts\\FRIZQT__.TTF"),
        "enforce_events": _as_bool(table["enforce_events"]),
        "player": {
            "name": str(player["name"]),
            "realm": str(player["realm"]),
            "level": int(player["level"]),
            "class": str(player["class"]),
            "class_file": str(player["class_file"]),
            "race": str(player["race"]),
            "race_file": str(player["race_file"]),
        },
        "apis": _walk_map(table["apis"], True),
        "events": _walk_map(table["events"], False),
    }
    return snap


def _counts(snap):
    by_source = {"probe": 0, "ui-source": 0, "wiki": 0}
    unverified = {"probe": 0, "ui-source": 0, "wiki": 0}
    for group in (snap["apis"], snap["events"]):
        for entry in group.values():
            by_source[entry["source"]] = by_source.get(entry["source"], 0) + 1
            if entry["unverified"]:
                unverified[entry["source"]] = unverified.get(entry["source"], 0) + 1
    return {"by_source": by_source, "unverified_by_source": unverified}


def _lua_rows(snap):
    """Lua source for _wowsim_rows, the unverified set, and event statuses."""
    rows = []
    unverified = []
    for name in sorted(snap["apis"]):
        entry = snap["apis"][name]
        rows.append(
            "{ name = %s, status = %s, kind = %s }"
            % (lua_quote(name), lua_quote(entry["status"]), lua_quote(entry["kind"]))
        )
        if entry["unverified"]:
            unverified.append("[%s] = true" % lua_quote(name))
    events = []
    for name in sorted(snap["events"]):
        entry = snap["events"][name]
        events.append("[%s] = %s" % (lua_quote(name), lua_quote(entry["status"])))
        if entry["unverified"]:
            unverified.append("[%s] = true" % lua_quote(name))
    return (
        "_wowsim_rows = {\n" + ",\n".join(rows) + "\n}\n",
        "_wowsim_unverified = {\n" + ",\n".join(unverified) + "\n}\n",
        "_wowsim_event_status = {\n" + ",\n".join(events) + "\n}\n",
    )


def _list_from(table):
    if table is None:
        return []
    out = []
    i = 1
    while True:
        value = table[i]
        if value is None:
            break
        out.append(value)
        i += 1
    return out


class World:
    """One deterministic fake client."""

    def __init__(self, snapshot, toc=None, files=None, player=None, root=None):
        self.root = Path(root) if root else ROOT
        self.snap = load_snapshot(snapshot) if not isinstance(snapshot, dict) else snapshot
        self.snapshot_id = self.snap["id"]
        self.toc = toc or self.snap["toc"]
        self.files = files
        self.player = dict(self.snap["player"])
        if player:
            self.player.update(player)
        self.checks = []
        self.load_errors = []
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self._boot_runtime()

    def _boot_runtime(self):
        engine = ENGINE_PATH.read_text(encoding="utf-8")
        self.lua.execute(engine)
        meta = toc_metadata(self.toc) if self.toc else {}
        meta_src = ["_wowsim_meta = {"]
        for key, value in sorted(meta.items()):
            meta_src.append("[%s] = %s," % (lua_quote(key), lua_quote(value)))
        meta_src.append("}")
        player = self.player
        rows, unverified, events = _lua_rows(self.snap)
        prelude = "\n".join([
            "_wowsim_id = %s" % lua_quote(self.snapshot_id),
            "_wowsim_project_id = %d" % int(self.snap["project_id"]),
            "_wowsim_text_font = %s" % lua_quote(self.snap["text_font"]),
            "_wowsim_enforce_events = %s" % ("true" if self.snap["enforce_events"] else "false"),
            "_wowsim_player = { name = %s, realm = %s, level = %d, class = %s, class_file = %s, race = %s, race_file = %s }"
            % (
                lua_quote(player["name"]),
                lua_quote(player["realm"]),
                int(player["level"]),
                lua_quote(player["class"]),
                lua_quote(player["class_file"]),
                lua_quote(player["race"]),
                lua_quote(player["race_file"]),
            ),
            "_wowsim_build = { %s, %s, %s, %d }"
            % (
                lua_quote(self.snap["version"]),
                lua_quote(self.snap["build"]),
                lua_quote(self.snap["build_date"]),
                int(self.snap["interface"]),
            ),
            "\n".join(meta_src),
            rows,
            unverified,
            events,
            "_wowsim_install()",
        ])
        self.lua.execute(prelude)

    def add_check(self, check_id, status, detail, phase, unverified):
        self.checks.append({
            "id": check_id,
            "status": status,
            "detail": detail or "",
            "phase": phase,
            "unverified": list(unverified or []),
        })

    def _clear_calls(self):
        self.lua.execute("_wowsim_calls = {}")

    def take_unverified(self):
        table = self.lua.eval("_wowsim_take_unverified()")
        return [str(item) for item in _list_from(table)]

    def run_file(self, rel):
        path = self.root / rel
        if not path.is_file():
            return "MISSING FILE"
        src = path.read_text(encoding="utf-8")
        self.lua.globals()._wowsim_src = src
        self.lua.globals()._wowsim_name = "@" + rel.replace("\\", "/")
        try:
            self.lua.execute(
                "local fn, err = loadstring(_wowsim_src, _wowsim_name)\n"
                "if not fn then error(err, 0) end\n"
                "fn()\n"
            )
        except Exception as exc:
            text = str(exc).strip()
            return text.splitlines()[0] if text else "error"
        return None

    def load(self):
        """Execute the TOC (or `files`) in order. Records one check per file."""
        if self.files is not None:
            entries = [("lua", rel.replace("\\", "/")) for rel in self.files]
        else:
            entries = toc_entries(self.toc)
        for kind, rel in entries:
            if kind != "lua":
                self.add_check(
                    "load:" + rel,
                    "skip",
                    "not a Lua file; the offline client does not parse XML",
                    "load",
                    [],
                )
                continue
            self._clear_calls()
            err = self.run_file(rel)
            deps = self.take_unverified()
            if err:
                self.load_errors.append("%s: %s" % (rel, err))
                self.add_check("load:" + rel, "fail", err, "load", deps)
            else:
                self.add_check("load:" + rel, "pass", "", "load", deps)
        return self.load_errors

    def assign_saved(self, global_name, chunk):
        """Set a global from a Lua chunk that returns a table."""
        self.lua.globals()._wowsim_saved = chunk
        self.lua.execute(
            "%s = (function()\n" % global_name
            + "local fn, err = loadstring(_wowsim_saved)\n"
            + "if not fn then error(err, 0) end\n"
            + "return fn()\n"
            + "end)()"
        )

    def fire(self, event, *args):
        self.lua.globals()._wowsim_fire(event, *args)

    def drain(self, limit=8000):
        steps, left = self.lua.globals()._wowsim_drain(limit)
        return int(steps or 0), int(left or 0)

    def login(self, saved_chunk=None):
        """SavedVariables, then ADDON_LOADED and the first PLAYER_ENTERING_WORLD.

        That is the path Core/Init.lua uses to reach OnLogin. Timers queued
        during the login are drained afterwards.
        """
        self._clear_calls()
        if saved_chunk is not None:
            self.assign_saved("ToonAgeDB", saved_chunk)
        else:
            self.lua.execute("ToonAgeDB = nil")
        self.lua.execute("ToonAgeGuard = {}")
        self.fire("ADDON_LOADED", "ToonAge")
        self.fire("PLAYER_ENTERING_WORLD", True, False)
        steps, left = self.drain()
        deps = self.take_unverified()
        failures = self.lua.eval(
            "(ToonAge and ToonAge._loginFailures) and table.concat(ToonAge._loginFailures, ', ') or ''"
        )
        logged = self.lua.eval("ToonAge and ToonAge._loggedIn and true or false")
        detail = ""
        status = "pass"
        if not logged:
            status = "fail"
            detail = "PLAYER_ENTERING_WORLD did not reach OnLogin"
        if failures:
            status = "fail"
            detail = "login steps failed: " + str(failures)
        if left:
            detail = (detail + "; " if detail else "") + "timer queue still held %d callback(s)" % left
            if status == "pass":
                status = "warn"
        self.add_check("login:OnLogin", status, detail, "init", deps)
        self._module_checks()
        if steps or left:
            self.add_check(
                "login:timers",
                "warn" if left else "pass",
                "drained %d timer callback(s), %d left" % (steps, left),
                "init",
                [],
            )
        return status == "pass"

    def init_db(self):
        self._clear_calls()
        try:
            self.lua.execute("ToonAge:InitDB()")
            err = None
        except Exception as exc:
            err = str(exc).splitlines()[0]
        deps = self.take_unverified()
        self.add_check("init:InitDB", "fail" if err else "pass", err or "", "init", deps)
        return err

    def init_modules(self):
        self._clear_calls()
        try:
            self.lua.execute("ToonAge:InitModules()")
            err = None
        except Exception as exc:
            err = str(exc).splitlines()[0]
        deps = self.take_unverified()
        self.add_check(
            "init:InitModules",
            "fail" if err else "pass",
            err or "",
            "init",
            deps,
        )
        self._module_checks()
        return err

    def _module_checks(self):
        names = self.lua.eval(
            "(function()\n"
            "  local o = {}\n"
            "  if ToonAge and type(ToonAge.modules) == 'table' then\n"
            "    for k in pairs(ToonAge.modules) do o[#o + 1] = tostring(k) end\n"
            "  end\n"
            "  table.sort(o)\n"
            "  return o\n"
            "end)()"
        )
        for name in _list_from(names):
            name = str(name)
            skipped = self.lua.eval(
                "(function()\n"
                "  local m = ToonAge.modules[%s]\n" % lua_quote(name)
                + "  if m._profileSkipped then return 'profile' end\n"
                "  if m._disabled then return 'disabled' end\n"
                "  if m._initError then return 'error:' .. tostring(m._initError) end\n"
                "  return ''\n"
                "end)()"
            )
            skipped = str(skipped or "")
            if skipped == "profile":
                self.add_check("init:" + name, "skip", "not in this flavor profile", "init", [])
            elif skipped == "disabled":
                self.add_check("init:" + name, "skip", "disabled", "init", [])
            elif skipped.startswith("error:"):
                self.add_check("init:" + name, "fail", skipped[6:], "init", [])
            else:
                self.add_check("init:" + name, "pass", "", "init", [])

    def fire_safe_events(self):
        """Fire the safe event list. A snapshot entry of status missing is not fired."""
        for spec in SAFE_EVENTS:
            event = spec[0]
            args = spec[1:]
            entry = self.snap["events"].get(event)
            if entry is None:
                self.add_check(
                    "event:" + event,
                    "skip",
                    "not in the snapshot; not fired",
                    "event",
                    [],
                )
                continue
            if entry["status"] != "present":
                deps = [event] if entry["unverified"] else []
                self.add_check(
                    "event:" + event,
                    "skip",
                    "snapshot says missing (%s, build %s)" % (entry["source"], entry["build"]),
                    "event",
                    deps,
                )
                continue
            self._clear_calls()
            try:
                self.fire(event, *args)
                err = None
            except Exception as exc:
                err = str(exc).splitlines()[0]
            self.drain()
            deps = self.take_unverified()
            if entry["unverified"] and event not in deps:
                deps = sorted(set(deps + [event]))
            self.add_check(
                "event:" + event,
                "fail" if err else "pass",
                err or "",
                "event",
                deps,
            )

    def render_tabs(self):
        has_ui = self.lua.eval(
            "(ToonAge and ToonAge.UI and type(ToonAge.UI.SetTab) == 'function') and true or false"
        )
        if not has_ui:
            self.add_check("render:tabs", "skip", "TA.UI:SetTab is not available", "render", [])
            return
        ids = self.lua.eval(
            "(function()\n"
            "  local o = {}\n"
            "  local tabs = (ToonAge.ProfileTabs and ToonAge:ProfileTabs()) or {}\n"
            "  for i, tab in ipairs(tabs) do o[#o + 1] = tostring(tab.id or i) end\n"
            "  return o\n"
            "end)()"
        )
        tab_ids = [str(item) for item in _list_from(ids)]
        if not tab_ids:
            self.add_check("render:tabs", "skip", "profile has no tabs", "render", [])
            return
        for tab_id in tab_ids:
            self._clear_calls()
            try:
                self.lua.execute("ToonAge.UI:SetTab(%s)" % lua_quote(tab_id))
                err = None
            except Exception as exc:
                err = str(exc).splitlines()[0]
            self.drain()
            deps = self.take_unverified()
            self.add_check(
                "render:" + tab_id,
                "fail" if err else "pass",
                err or "",
                "render",
                deps,
            )

    def run_harness(self):
        """Run each TestHarness suite, if the file loaded and hooked Run.

        Unverified names touched while a suite runs are attached to every
        check that suite emitted. The harness keeps that list local, so the
        dependency is per suite rather than per line.
        """
        has = self.lua.eval(
            "(ToonAge and ToonAge.TestHarness and type(ToonAge.TestHarness.Run) == 'function') and true or false"
        )
        if not has:
            self.add_check("harness", "skip", "TestHarness is not loaded", "harness", [])
            return
        self.lua.execute("if ToonAge.db == nil then ToonAge.db = ToonAgeDB end")
        for suite in HARNESS_SUITES:
            self._clear_calls()
            self.lua.execute("if ToonAgeDB then ToonAgeDB.selfTest = nil end")
            try:
                self.lua.execute("ToonAge.TestHarness:Run(%s)" % lua_quote(suite))
            except Exception as exc:
                deps = self.take_unverified()
                self.add_check(
                    "harness:" + suite,
                    "fail",
                    str(exc).splitlines()[0],
                    "harness",
                    deps,
                )
                continue
            steps, left = self.drain()
            deps = self.take_unverified()
            lines = self.lua.eval(
                "(function()\n"
                "  local o = {}\n"
                "  local st = ToonAgeDB and ToonAgeDB.selfTest\n"
                "  if st and type(st.lines) == 'table' then\n"
                "    for i = 1, #st.lines do o[#o + 1] = st.lines[i] end\n"
                "  end\n"
                "  return o\n"
                "end)()"
            )
            parsed = []
            for raw in _list_from(lines):
                plain = _COLOR.sub("", str(raw)).replace("|r", "").strip()
                match = _RESULT.match(plain)
                if not match:
                    continue
                status, _suite, msg = match.group(1), match.group(2), match.group(3).strip()
                parsed.append((status.lower(), msg))
            if not parsed:
                detail = "suite produced no PASS/FAIL/WARN/SKIP/INFO lines"
                if left:
                    detail += "; %d timer callback(s) still queued after %d steps" % (left, steps)
                self.add_check("harness:" + suite, "fail", detail, "harness", deps)
                continue
            for status, msg in parsed:
                self.add_check("harness:%s:%s" % (suite, msg), status, msg, "harness", list(deps))

    def summary(self):
        counts = {"pass": 0, "fail": 0, "warn": 0, "skip": 0, "info": 0}
        for check in self.checks:
            counts[check["status"]] = counts.get(check["status"], 0) + 1
        return counts

    def report(self):
        counts = _counts(self.snap)
        return {
            "client": self.snapshot_id,
            "label": self.snap["label"],
            "toc": self.toc,
            "snapshot": str(self.snap["path"].relative_to(ROOT)).replace("\\", "/"),
            "simulated_build": self.snap["build"],
            "simulated_version": self.snap["version"],
            "interface": self.snap["interface"],
            "project_id": self.snap["project_id"],
            "checks": self.checks,
            "summary": self.summary(),
            "snapshot_counts": counts,
            "load_errors": list(self.load_errors),
        }

    def write_report(self, path):
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = self.report()
        # checks stay in run order; sort_keys orders the object keys only.
        path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        return path


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print("usage: python Tools/harness/wowsim.py <snapshot> [--report path]")
        return 0
    name = argv[1]
    report_path = None
    if "--report" in argv:
        report_path = argv[argv.index("--report") + 1]
    world = World(name)
    world.load()
    world.login()
    world.fire_safe_events()
    world.render_tabs()
    world.run_harness()
    report = world.report()
    counts = report["summary"]
    print(
        "%s  load_errors=%d  pass=%d fail=%d warn=%d skip=%d info=%d"
        % (
            name,
            len(world.load_errors),
            counts.get("pass", 0),
            counts.get("fail", 0),
            counts.get("warn", 0),
            counts.get("skip", 0),
            counts.get("info", 0),
        )
    )
    for err in world.load_errors:
        print("  LOAD", err)
    for check in world.checks:
        if check["phase"] == "init" and check["status"] == "fail":
            print("  INIT", check["id"], check["detail"])
    if report_path:
        written = world.write_report(report_path)
        print("report", written)
    return 1 if world.load_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
