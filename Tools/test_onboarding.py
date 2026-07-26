#!/usr/bin/env python3
"""
ToonAge -- Onboarding behaviour tests
=====================================
Executes the real Core/Init.lua and Modules/Onboarding.lua in an embedded
Lua 5.1 runtime (the same version WoW uses) against a stub WoW API, and asserts
on what they actually do.

check_lua.py proves a file parses. This proves the onboarding decides the right
thing -- which branch runs, what gets written to the DB, what gets printed, and
what stays shut.

Two things here cannot be checked any other way:

  * The module-init race. Arrow:Init and QuestTracker:Init sample their
    visibility flags once and never again, and module init order comes from
    pairs(), so it is not deterministic. The harness forces BOTH orders and
    asserts the end state is identical. A live client can only ever show you
    whichever order it happened to pick that login.

  * The migration. It deletes onboardScope/onboardedAccount once translated,
    so a wrong translation is silent and cannot be recovered from in-game.

Setup
-----
    python -m pip install --user lupa

Usage
-----
    python Tools/test_onboarding.py          # run all
    python Tools/test_onboarding.py -v       # show each assertion

What this does NOT cover
------------------------
Real frames, actual on-screen visibility, SavedVariables persistence across
sessions, and whether AltQuickStart's 2s timer genuinely lands before ours in a
live client. Those need the game. See the in-game checklist in the PR notes.
"""

import sys
from pathlib import Path

try:
    from lupa import lua51
except ImportError:
    sys.exit("lupa not installed.  python -m pip install --user lupa")

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv

# ── Stub WoW API ──────────────────────────────────────────────────────────────
# Frames respond to any method call and return themselves, so UI code runs
# without erroring. Show/Hide are tracked explicitly because they are what the
# assertions below actually care about.
PRELUDE = r"""
_printed = {}
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    _printed[#_printed + 1] = table.concat(parts, " ")
end

function MockFrame(name)
    local f = { _name = name, _shown = false }
    rawset(f, "_scripts", {})
    rawset(f, "_children", {})
    setmetatable(f, { __index = function(s, k)
        local fn = function(...) return s end
        rawset(s, k, fn)
        return fn
    end })
    f.Show      = function(s) rawset(s, "_shown", true);  return s end
    f.Hide      = function(s) rawset(s, "_shown", false); return s end
    f.IsShown   = function(s) return rawget(s, "_shown") end
    f.GetWidth  = function(s) return 400 end
    f.GetHeight = function(s) return 300 end
    -- Recorded so tests can drive real button handlers rather than trusting
    -- that a popup which was merely *created* also wires up correctly.
    f.SetScript = function(s, ev, fn) rawget(s, "_scripts")[ev] = fn; return s end
    f.GetScript = function(s, ev) return rawget(s, "_scripts")[ev] end
    -- CreateFontString is unstubbed, so it falls through to the generic
    -- __index and returns the frame itself -- which means a label's SetText
    -- lands on its owning frame. That is what makes buttons findable by text.
    f.SetText   = function(s, t) rawset(s, "_text", t); return s end
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

--- Fires every timer due at or before `target`, in scheduled order. Timers
--- scheduled by a timer are picked up by the same drain.
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

UnitName         = function() return "Testchar" end
GetRealmName     = function() return "Testrealm" end
time             = function() return 1750000000 end
InCombatLockdown = function() return false end
IsShiftKeyDown   = function() return false end
GetTime          = function() return _now end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UIParent = MockFrame("UIParent")
"""

# Fakes for the three modules Onboarding reconciles against. Deliberately not
# the real files: this tests Onboarding's contract (does it issue the calls?)
# without dragging 3300 lines of QuestTracker into the stub surface. Each
# mirrors only the init-time flag read that actually races.
FAKES = r"""
local TA = ToonAge

_toggleUICalls = 0
TA.ToggleUI = function(self) _toggleUICalls = _toggleUICalls + 1 end

FakeArrow = {
    frame = MockFrame("ArrowFrame"),
    -- mirrors Arrow:Init (Arrow.lua:830-834)
    Init = function(self)
        local saved = TA.charDB and TA.charDB.arrow
        if saved and saved.visible then self.frame:Show() end
    end,
}

FakeQT = {
    _updateCalls = 0,
    _blizzHidden = nil,
    -- mirrors QT:UpdateBlizzardTrackerVisibility (QuestTracker.lua:981-983)
    UpdateBlizzardTrackerVisibility = function(self)
        self._updateCalls = self._updateCalls + 1
        local t = TA.charDB and TA.charDB.tracker
        self._blizzHidden = (t and t.replaceBlizzTracker) and true or false
    end,
    Init = function(self) self:UpdateBlizzardTrackerVisibility() end,
}

FakeRot = { predictBar = MockFrame("PredictBar") }

FakeAQS = {
    _shown = false,
    Show = function(self) self._shown = true end,
}

TA.modules.Arrow         = FakeArrow
TA.modules.QuestTracker  = FakeQT
TA.modules.Rotation      = FakeRot
TA.modules.AltQuickStart = FakeAQS

-- AltQuickStart's real suppression check, as a probe. Records what the flag
-- looked like at t=2s, which is the contract Onboarding has to honour.
_flagAt2s = nil
C_Timer.After(2, function()
    _flagAt2s = TA._onboardingActive and true or false
end)
"""


class Harness:
    """One scenario. Fresh runtime every time -- ToonAgeDB, TA.modules and
    TA._onboardingActive are all globals that would otherwise leak between
    scenarios and produce failures that are pure contamination."""

    def __init__(self, db_literal="{}"):
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(PRELUDE)
        self.lua.execute(_read("Core/Init.lua"))
        self.lua.execute(f"ToonAgeDB = {db_literal}")
        self.TA = self.lua.globals().ToonAge
        self.TA.InitDB(self.TA)

    def load_onboarding(self):
        self.lua.execute(_read("Modules/Onboarding.lua"))
        self.lua.execute(FAKES)
        return self

    def load_real_altquickstart(self):
        """Loads the genuine AltQuickStart, replacing FakeAQS. Needed because
        IsReturningAlt is file-local -- AQS:Init is the only way to reach it."""
        self.lua.execute(_read("Modules/AltQuickStart.lua"))
        return self.TA.modules.AltQuickStart

    def click(self, frame, label):
        """Fires the OnClick of the child button whose label contains `label`."""
        kids = frame._children
        for i in range(1, len(kids) + 1):
            child = kids[i]
            text = getattr(child, "_text", None)
            if text and label in text:
                handler = child._scripts.OnClick
                if handler is None:
                    raise AssertionError(f"button {label!r} has no OnClick")
                handler()
                return child
        raise AssertionError(f"no child button matching {label!r}")

    @property
    def g(self):
        return self.lua.globals()

    @property
    def db(self):
        return self.TA.db

    @property
    def chardb(self):
        return self.TA.charDB

    @property
    def onboarding(self):
        return self.TA.modules.Onboarding

    def printed(self):
        p = self.g._printed
        return [p[i] for i in range(1, len(p) + 1)]

    def advance(self, t):
        self.g.AdvanceTo(t)


def _read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


# ── Tiny assertion framework ──────────────────────────────────────────────────
_results = []


def check(name, got, want):
    ok = got == want
    _results.append((ok, name, got, want))
    if VERBOSE or not ok:
        mark = "  ok  " if ok else " FAIL "
        print(f"[{mark}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def section(title):
    if VERBOSE:
        print(f"\n--- {title} " + "-" * max(0, 60 - len(title)))


# ══════════════════════════════════════════════════════════════════════════════
# Migration: the old two-flag model onto newCharBehavior.
# High stakes because InitDB deletes the old keys once translated.
# ══════════════════════════════════════════════════════════════════════════════
def test_migration():
    section("migration")

    h = Harness('{ onboardScope = "account", onboardedAccount = true }')
    check("account scope, already run -> off", h.db.newCharBehavior, "off")
    check("  old onboardScope cleared", h.db.onboardScope, None)
    check("  old onboardedAccount cleared", h.db.onboardedAccount, None)

    h = Harness('{ onboardScope = "account", onboardedAccount = false }')
    check("account scope, never run -> wizard", h.db.newCharBehavior, "wizard")

    h = Harness('{ onboardScope = "character", onboardedAccount = false }')
    check("character scope -> wizard", h.db.newCharBehavior, "wizard")

    h = Harness('{ onboardScope = "character", onboardedAccount = true }')
    check("character scope, flag set -> wizard", h.db.newCharBehavior, "wizard")

    # A user who already chose explicitly must not be overwritten by a stale key.
    h = Harness('{ newCharBehavior = "inherit", onboardScope = "account", onboardedAccount = true }')
    check("explicit choice survives stale keys", h.db.newCharBehavior, "inherit")
    check("  stale keys still cleared", h.db.onboardScope, None)

    # Idempotency: InitDB is the upgrade path and runs on every login.
    h = Harness('{ onboardScope = "account", onboardedAccount = true }')
    h.TA.InitDB(h.TA)
    h.TA.InitDB(h.TA)
    check("InitDB is idempotent", h.db.newCharBehavior, "off")

    h = Harness("{}")
    check("fresh install -> wizard", h.db.newCharBehavior, "wizard")
    check("fresh install -> preset auto", h.db.defaultPreset, "auto")


# ══════════════════════════════════════════════════════════════════════════════
# Branch selection on a new character.
# ══════════════════════════════════════════════════════════════════════════════
def test_off_does_nothing():
    section("newCharBehavior = off")

    h = Harness('{ newCharBehavior = "off" }').load_onboarding()
    h.onboarding.Init(h.onboarding)
    h.advance(6)

    check("off: character marked seen", h.chardb.onboarded, True)
    check("off: prints nothing", h.printed(), [])
    check("off: no main window", h.g._toggleUICalls, 0)
    check("off: no Quick Start panel", h.g.FakeAQS._shown, False)
    check("off: does not claim the login", bool(h.TA._onboardingActive), False)
    check("off: AltQuickStart unsuppressed at 2s", h.g._flagAt2s, False)
    check("off: writes no preset", h.chardb.tracker, None)


def test_inherit_auto():
    section("newCharBehavior = inherit, preset auto")

    h = Harness('{ newCharBehavior = "inherit", defaultPreset = "auto" }').load_onboarding()
    h.onboarding.Init(h.onboarding)

    # Config must be written synchronously, before any timer runs, so a module
    # whose Init happens later reads finished settings.
    check("inherit: autoQuest set before timers", h.chardb.tracker.autoQuest, True)
    check("inherit: silent until the timer", h.printed(), [])

    h.advance(2)
    check("inherit: suppresses AltQuickStart at 2s", h.g._flagAt2s, True)

    h.advance(6)
    check("inherit: cutsceneSkip on", h.chardb.tracker.cutsceneSkip, True)
    check("inherit: autoEquip on", h.chardb.tracker.autoEquip, True)
    check("inherit: hides Blizzard tracker", h.chardb.tracker.replaceBlizzTracker, True)
    check("inherit: prediction bar on", h.chardb.predictBar.visible, True)
    check("inherit: arrow on", h.chardb.arrow.visible, True)

    check("inherit: exactly one chat line", len(h.printed()), 1)
    check("inherit: names the preset", "Full Auto" in h.printed()[0], True)
    check("inherit: no main window", h.g._toggleUICalls, 0)
    check("inherit: no Quick Start panel", h.g.FakeAQS._shown, False)
    check("inherit: no wizard popup", h.onboarding.popup, None)
    check("inherit: releases the claim", bool(h.TA._onboardingActive), False)


def test_inherit_manual():
    section("newCharBehavior = inherit, preset manual")

    h = Harness('{ newCharBehavior = "inherit", defaultPreset = "manual" }').load_onboarding()
    h.onboarding.Init(h.onboarding)
    h.advance(6)

    check("manual: autoQuest off", h.chardb.tracker.autoQuest, False)
    check("manual: cutsceneSkip off", h.chardb.tracker.cutsceneSkip, False)
    check("manual: autoEquip off", h.chardb.tracker.autoEquip, False)
    check("manual: leaves Blizzard tracker", h.chardb.tracker.replaceBlizzTracker, False)
    # Passive info, on in both presets.
    check("manual: prediction bar still on", h.chardb.predictBar.visible, True)
    check("manual: names the preset", "Manual" in h.printed()[0], True)
    check("manual: no main window", h.g._toggleUICalls, 0)


def test_wizard_still_works():
    section("newCharBehavior = wizard")

    h = Harness('{ newCharBehavior = "wizard" }').load_onboarding()
    h.onboarding.Init(h.onboarding)
    check("wizard: claims the login", bool(h.TA._onboardingActive), True)

    h.advance(2)
    check("wizard: suppresses AltQuickStart at 2s", h.g._flagAt2s, True)

    h.advance(6)
    check("wizard: popup created", h.onboarding.popup is not None, True)
    check("wizard: opens no main window itself", h.g._toggleUICalls, 0)
    # The preset lines belong to the button handlers, not to arriving.
    check("wizard: applies no preset yet", h.chardb.tracker, None)


def test_already_onboarded():
    section("already-seen character")

    h = Harness('{ newCharBehavior = "inherit" }').load_onboarding()
    h.chardb.onboarded = True
    h.onboarding.Init(h.onboarding)
    h.advance(6)

    check("seen: prints nothing", h.printed(), [])
    check("seen: writes no preset", h.chardb.tracker, None)
    check("seen: no popup", h.onboarding.popup, None)


# ══════════════════════════════════════════════════════════════════════════════
# The module-init race. This is the test the harness exists for.
# ══════════════════════════════════════════════════════════════════════════════
def _run_race(arrow_qt_first):
    h = Harness('{ newCharBehavior = "inherit", defaultPreset = "auto" }').load_onboarding()
    arrow, qt = h.g.FakeArrow, h.g.FakeQT

    if arrow_qt_first:
        arrow.Init(arrow)
        qt.Init(qt)
        h.onboarding.Init(h.onboarding)
    else:
        h.onboarding.Init(h.onboarding)
        arrow.Init(arrow)
        qt.Init(qt)

    h.advance(6)
    return h, arrow, qt


def test_init_order_race():
    section("module init order race (pairs() is non-deterministic)")

    for label, first in (("Arrow/QT init first", True), ("Onboarding init first", False)):
        h, arrow, qt = _run_race(first)
        check(f"race [{label}]: arrow visible", arrow.frame._shown, True)
        check(f"race [{label}]: Blizzard tracker hidden", qt._blizzHidden, True)
        check(f"race [{label}]: prediction bar shown", h.g.FakeRot.predictBar._shown, True)
        check(f"race [{label}]: one chat line", len(h.printed()), 1)

    # State the invariant directly: order must not matter.
    a, _, qa = _run_race(True)
    b, _, qb = _run_race(False)
    check("race: end state identical either order",
          (qa._blizzHidden, a.chardb.tracker.autoQuest, len(a.printed())),
          (qb._blizzHidden, b.chardb.tracker.autoQuest, len(b.printed())))


# ══════════════════════════════════════════════════════════════════════════════
# Slash commands. The first is the regression test for the reported bug.
# ══════════════════════════════════════════════════════════════════════════════
def test_slash_dispatch():
    section("slash commands")

    h = Harness("{}").load_onboarding()
    # The reported bug: a trailing `Onboarding.SlashCommands = {}` discarded the
    # real table, so this key did not exist and /ta onboard fell through to the
    # fuzzy matcher.
    check("onboard handler is registered",
          h.onboarding.SlashCommands.onboard is not None, True)
    check("onboard appears in the command list",
          "onboard" in [h.TA.GetAllCommandNames(h.TA)[i]
                        for i in range(1, len(h.TA.GetAllCommandNames(h.TA)) + 1)], True)

    h = Harness("{}").load_onboarding()
    h.TA.SlashCommand(h.TA, "onboard")
    check("bare /ta onboard opens the wizard", h.onboarding.popup is not None, True)
    check("bare /ta onboard leaves the mode alone", h.db.newCharBehavior, "wizard")

    for arg, want in (("off", "off"), ("inherit", "inherit"), ("wizard", "wizard")):
        h = Harness("{}").load_onboarding()
        h.TA.SlashCommand(h.TA, f"onboard {arg}")
        check(f"/ta onboard {arg}", h.db.newCharBehavior, want)

    # Back-compat with the retired scope words.
    h = Harness("{}").load_onboarding()
    h.TA.SlashCommand(h.TA, "onboard account")
    check("/ta onboard account -> off", h.db.newCharBehavior, "off")

    h = Harness("{}").load_onboarding()
    h.TA.SlashCommand(h.TA, "onboard character")
    check("/ta onboard character -> wizard", h.db.newCharBehavior, "wizard")

    h = Harness("{}").load_onboarding()
    h.TA.SlashCommand(h.TA, "onboard preset manual")
    check("/ta onboard preset manual", h.db.defaultPreset, "manual")

    h = Harness("{}").load_onboarding()
    h.chardb.onboarded = True
    h.TA.SlashCommand(h.TA, "onboard reset")
    check("/ta onboard reset clears the char flag", h.chardb.onboarded, None)


def test_manual_override_burns_nothing():
    """The old CompleteFlow set onboardedAccount unconditionally, so opening the
    panel by hand disabled first-run for every future alt."""
    section("manual override does not burn flags")

    h = Harness('{ newCharBehavior = "wizard" }').load_onboarding()
    h.TA.SlashCommand(h.TA, "onboard")
    h.onboarding.CompleteFlow(h.onboarding)
    h.advance(6)

    check("manual run leaves mode intact", h.db.newCharBehavior, "wizard")
    check("manual run sets no account flag", h.db.onboardedAccount, None)


# ══════════════════════════════════════════════════════════════════════════════
def test_wizard_records_preset_for_alts():
    """The wizard's button handlers are what set db.defaultPreset -- the single
    thing that makes `inherit` inherit anything. Closes the feature's loop."""
    section("wizard button -> defaultPreset handoff")

    for label, want_preset, want_autoquest in (("Full Auto", "auto", True),
                                               ("Manual", "manual", False)):
        # Starts on "auto" both times, so the Manual case proves a real write
        # rather than agreeing with the pre-existing value.
        h = Harness('{ newCharBehavior = "wizard", defaultPreset = "auto" }').load_onboarding()
        h.onboarding.Init(h.onboarding)
        h.advance(4)
        h.click(h.onboarding.popup, label)

        check(f"wizard [{label}]: records preset for alts",
              h.db.defaultPreset, want_preset)
        check(f"wizard [{label}]: applies to this character",
              h.chardb.tracker.autoQuest, want_autoquest)
        check(f"wizard [{label}]: opens the main window", h.g._toggleUICalls, 1)
        check(f"wizard [{label}]: popup dismissed", h.onboarding.popup._shown, False)

        h.advance(8)
        check(f"wizard [{label}]: hands off to Quick Start",
              h.g.FakeAQS._shown, True)
        check(f"wizard [{label}]: releases the claim",
              bool(h.TA._onboardingActive), False)


def test_new_character_is_not_a_returning_alt():
    """Regression for AltQuickStart.lua:88. `lastLoginTime or 0` made a
    never-seen character look 56 years stale, so it cleared the returning-alt
    threshold and got welcomed back to a character it had never played. Latent
    before -- the wizard's suppression flag hid it -- but reachable the moment
    newCharBehavior = "off" leaves AltQuickStart unsuppressed."""
    section("brand-new character is not 'returning'")

    def welcomed(lines):
        return any("Welcome back" in ln for ln in lines)

    # Brand new character, off mode: AltQuickStart runs completely unsuppressed.
    h = Harness('{ newCharBehavior = "off" }').load_onboarding()
    aqs = h.load_real_altquickstart()
    h.onboarding.Init(h.onboarding)
    aqs.Init(aqs)
    h.advance(4)
    check("off + new char: not welcomed back", welcomed(h.printed()), False)
    check("off + new char: login time now recorded",
          h.chardb.lastLoginTime is not None, True)

    # A genuinely returning character must still be greeted, or the fix would
    # have simply disabled the feature.
    h = Harness('{ newCharBehavior = "off" }').load_onboarding()
    aqs = h.load_real_altquickstart()
    h.chardb.onboarded = True
    h.chardb.lastLoginTime = 1          # 1970: unambiguously a long time ago
    aqs.Init(aqs)
    h.advance(4)
    check("returning char: still welcomed back", welcomed(h.printed()), True)


def test_apply_preset_config_is_pure():
    section("ApplyPresetConfig writes only settings")

    h = Harness("{}").load_onboarding()
    h.onboarding.ApplyPresetConfig(h.onboarding, "auto")

    check("config half opens no window", h.g._toggleUICalls, 0)
    check("config half prints nothing", h.printed(), [])
    check("config half still writes settings", h.chardb.tracker.autoQuest, True)


def main():
    test_migration()
    test_off_does_nothing()
    test_inherit_auto()
    test_inherit_manual()
    test_wizard_still_works()
    test_already_onboarded()
    test_init_order_race()
    test_slash_dispatch()
    test_manual_override_burns_nothing()
    test_wizard_records_preset_for_alts()
    test_new_character_is_not_a_returning_alt()
    test_apply_preset_config_is_pure()

    passed = sum(1 for ok, *_ in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {total} checks passed.")
        print("     Behaviour only. Real frames and SavedVariables need the game.")
        return 0
    print(f"[FAIL] {total - passed} of {total} checks failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
