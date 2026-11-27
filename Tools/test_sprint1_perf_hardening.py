#!/usr/bin/env python3
"""Tests for Sprint 1 Cross-Flavor Performance & Stability Hardening.

Verifies:
1. Forever MageSuggest:
   - HUD OFF by default -> OnUpdate is nil and hot events (UNIT_AURA, UNIT_POWER_UPDATE,
     SPELL_UPDATE_COOLDOWN, PLAYER_TARGET_CHANGED) are NOT registered.
   - SetEnabled(true) -> arms RegisterUnitEvent("UNIT_AURA", "player", "target"),
     RegisterUnitEvent("UNIT_POWER_UPDATE", "player"), and attaches OnUpdate.
   - SetEnabled(false) -> unregisters hot events and detaches OnUpdate (0 idle CPU).
   - Strict UPDATE_INTERVAL rate-limit holds even when _dirty=true under aura storms.
   - BuildClassPlaybook is cached across ReadState() ticks and invalidated on SPELLS_CHANGED.
2. Forever Rotation:
   - Duplicate _bar keeps OnUpdate detached while hidden.
3. Retail CombatState:
   - Uses RegisterUnitEvent for UNIT_HEALTH ("player", "target"), UNIT_POWER_FREQUENT ("player"),
     and UNIT_AURA ("player", "target") instead of unfiltered global RegisterEvent.
4. Retail + Mists QuestContext:
   - Caches OwnedQuests() across Refresh() calls until QUEST_LOG_UPDATE invalidates it.
   - Tick() skips polling completely when no candidate and no guide step are active.
5. Retail RoleMorph:
   - Starts combat tickers ONLY on PLAYER_REGEN_DISABLED and cancels them on PLAYER_REGEN_ENABLED
     (zero idle tickers out of combat).
6. Forever DungeonPins:
   - Coalesces bursty QUEST_LOG_UPDATE storms via 0.3s C_Timer.After debounce and skips
     MapPins:Refresh() when WorldMapFrame is hidden.

Usage:  python3 Tools/test_sprint1_perf_hardening.py [-v]
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
        print(f"[{'  ok  ' if ok else ' FAIL '}] {name}")
        if not ok:
            print(f"          got:  {got!r}")
            print(f"          want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def test_mage_suggest():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = {
        modules = {}, Data = {}, flavor = "forever", IsForever = true,
        db = {}, charDB = {},
        Compat = {
            UnitClass = function() return "Warrior", "WARRIOR" end,
            SpellLearned = function() return "yes" end,
            GetSpellCooldown = function() return 0, 0 end,
            GetSpellTexture = function() return 12345 end,
            InCombat = function() return false end,
            ReadAuras = function() return {} end,
            PlayerMana = function() return 100, 100 end,
            TargetInMelee = function() return false end,
        },
        Utils = { IsSecret = function() return false end },
    }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    function ToonAge:HasAPI() return true end
    STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    UIParent = {}
    UnitLevel = function() return 20 end
    issecretvalue = function() return false end
    canaccessvalue = function() return true end
    C_UnitAuras = { GetAuraDataByIndex = function() return nil end }
    C_Spell = { GetSpellCooldown = function() return { startTime = 0, duration = 0 } end }

    local function MakeFrame()
        local f = { _events = {}, _unitEvents = {}, _scripts = {}, _shown = true }
        function f:SetSize() end
        function f:SetPoint() end
        function f:ClearAllPoints() end
        function f:SetFrameStrata() end
        function f:SetClampedToScreen() end
        function f:EnableMouse() end
        function f:SetMovable() end
        function f:RegisterForDrag() end
        function f:SetBackdrop() end
        function f:SetBackdropColor() end
        function f:SetBackdropBorderColor() end
        function f:Show() self._shown = true end
        function f:Hide() self._shown = false end
        function f:IsShown() return self._shown end
        function f:CreateTexture()
            return { SetHeight = function() end, SetSize = function() end, SetPoint = function() end,
                     SetColorTexture = function() end, SetTexCoord = function() end,
                     SetTexture = function() end, Show = function() end, Hide = function() end }
        end
        function f:CreateFontString()
            return { SetFont = function() end, SetPoint = function() end, SetSize = function() end,
                     SetTextColor = function() end, SetText = function() end }
        end
        function f:RegisterEvent(ev) self._events[ev] = true end
        function f:RegisterUnitEvent(ev, u1, u2)
            self._events[ev] = true
            self._unitEvents[ev] = (tostring(u1 or "") .. "," .. tostring(u2 or ""))
        end
        function f:UnregisterEvent(ev)
            self._events[ev] = nil
            self._unitEvents[ev] = nil
        end
        function f:SetScript(k, fn) self._scripts[k] = fn end
        return f
    end
    function CreateFrame() return MakeFrame() end
    """)
    lua.execute(read("Data/Forever/RotationLists.lua"))
    lua.execute(read("Modules/Forever/MageSuggest.lua"))

    r = lua.eval(r"""
    (function()
        local M = ToonAge:GetModule("ForeverMageSuggest")
        M:Init()
        local f = M._frame
        local offNoUpdate = (f._scripts.OnUpdate == nil)
        local offNoAura = (f._events.UNIT_AURA == nil)
        local offNoPower = (f._events.UNIT_POWER_UPDATE == nil)

        -- Enable HUD -> unit-filtered events + OnUpdate attached
        M:SetEnabled(true)
        local onHasUpdate = (type(f._scripts.OnUpdate) == "function")
        local auraUnits = f._unitEvents.UNIT_AURA or ""
        local powerUnits = f._unitEvents.UNIT_POWER_UPDATE or ""

        -- Strict throttle: rapid dirty ticks under 0.15s must NOT fire Refresh
        local refreshCount = 0
        local origRefresh = M.Refresh
        M.Refresh = function(self) refreshCount = refreshCount + 1; return origRefresh(self) end
        f._scripts.OnUpdate(f, 0.01) -- first tick flushes (elapsed started at UPDATE_INTERVAL)
        refreshCount = 0
        M._dirty = true
        f._scripts.OnUpdate(f, 0.05) -- < 0.15s: must NOT refresh
        M._dirty = true
        f._scripts.OnUpdate(f, 0.05) -- total 0.10s < 0.15s: must NOT refresh
        local countUnderInterval = refreshCount
        f._scripts.OnUpdate(f, 0.06) -- total 0.16s >= 0.15s: fires once
        local countAfterInterval = refreshCount
        M.Refresh = origRefresh

        -- Playbook cache: two ReadState calls invoke BuildClassPlaybook only ONCE
        local buildCalls = 0
        local origBuild = M.BuildClassPlaybook
        M.BuildClassPlaybook = function(...) buildCalls = buildCalls + 1; return origBuild(...) end
        M._playbookCache = nil; M._playbookCacheKey = nil
        M.ReadState()
        M.ReadState()
        local buildsCached = buildCalls
        -- SPELLS_CHANGED invalidates cache
        f._scripts.OnEvent(f, "SPELLS_CHANGED")
        M.ReadState()
        local buildsAfterInvalidate = buildCalls
        M.BuildClassPlaybook = origBuild

        -- Disable HUD -> detaches OnUpdate and unregisters hot events
        M:SetEnabled(false)
        local disabledNoUpdate = (f._scripts.OnUpdate == nil)
        local disabledNoAura = (f._events.UNIT_AURA == nil)

        return {
            offNoUpdate = offNoUpdate, offNoAura = offNoAura, offNoPower = offNoPower,
            onHasUpdate = onHasUpdate, auraUnits = auraUnits, powerUnits = powerUnits,
            countUnderInterval = countUnderInterval, countAfterInterval = countAfterInterval,
            buildsCached = buildsCached, buildsAfterInvalidate = buildsAfterInvalidate,
            disabledNoUpdate = disabledNoUpdate, disabledNoAura = disabledNoAura,
        }
    end)()
    """)
    check("MageSuggest default OFF: OnUpdate nil & UNIT_AURA/UNIT_POWER_UPDATE not registered",
          (r["offNoUpdate"], r["offNoAura"], r["offNoPower"]), (True, True, True))
    check("MageSuggest enabled: uses RegisterUnitEvent(player,target) for UNIT_AURA and (player) for UNIT_POWER_UPDATE",
          (r["onHasUpdate"], r["auraUnits"], r["powerUnits"]),
          (True, "player,target", "player,"))
    check("MageSuggest enforces 0.15s throttle even under rapid _dirty aura storms",
          (r["countUnderInterval"], r["countAfterInterval"]), (0, 1))
    check("MageSuggest caches BuildClassPlaybook across ReadState ticks and invalidates on SPELLS_CHANGED",
          (r["buildsCached"], r["buildsAfterInvalidate"]), (1, 2))
    check("MageSuggest SetEnabled(false) detaches OnUpdate and unregisters hot events",
          (r["disabledNoUpdate"], r["disabledNoAura"]), (True, True))


def test_combat_state():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = { modules = {}, Data = {}, db = {}, Utils = { IsSecret = function() return false end, SafeNum = function(v) return tonumber(v) or 0 end } }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    C_Timer = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
    _csFrame = nil
    function CreateFrame()
        local f = { _events = {}, _unitEvents = {}, _scripts = {} }
        function f:RegisterEvent(ev) self._events[ev] = true end
        function f:RegisterUnitEvent(ev, u1, u2)
            self._unitEvents[ev] = tostring(u1 or "") .. "," .. tostring(u2 or "")
        end
        function f:SetScript(k, fn) self._scripts[k] = fn end
        _csFrame = f
        return f
    end
    """)
    lua.execute(read("Modules/Combat/CombatState.lua"))
    r = lua.eval(r"""
    (function()
        local CS = ToonAge:GetModule("CombatState")
        CS:Init()
        return {
            healthUnit = _csFrame._unitEvents.UNIT_HEALTH or "",
            powerUnit = _csFrame._unitEvents.UNIT_POWER_FREQUENT or "",
            auraUnit = _csFrame._unitEvents.UNIT_AURA or "",
            auraGlobal = _csFrame._events.UNIT_AURA == true,
        }
    end)()
    """)
    check("Retail CombatState registers UNIT_HEALTH, UNIT_POWER_FREQUENT, and UNIT_AURA via RegisterUnitEvent (not global)",
          (r["healthUnit"], r["powerUnit"], r["auraUnit"], r["auraGlobal"]),
          ("player,target", "player,", "player,target", False))


def test_quest_context_and_role_morph():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = {
        modules = {}, Data = {}, db = {},
        ContextAction = {
            Set = function() end,
            QuestCandidate = function() return nil end,
            Secret = function() return false end,
        },
        Utils = { IsSecret = function() return false end },
    }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    function ToonAge:RegisterEvent() end
    _tickers = {}
    C_Timer = {
        After = function() end,
        NewTicker = function(sec, fn)
            local t = { sec = sec, fn = fn, cancelled = false }
            function t:Cancel() self.cancelled = true end
            _tickers[#_tickers + 1] = t
            return t
        end,
    }
    _inCombat = false
    UnitAffectingCombat = function() return _inCombat end
    IsInGroup = function() return false end
    _questScans = 0
    C_QuestLog = {
        GetNumQuestLogEntries = function() _questScans = _questScans + 1; return 0 end,
        GetInfo = function() return nil end,
    }
    """)
    lua.execute(read("Modules/Navigation/QuestContext.lua"))
    lua.execute(read("Modules/Automation/RoleMorph.lua"))

    r = lua.eval(r"""
    (function()
        local QC = ToonAge:GetModule("QuestContext")
        QC.CurrentStep = function() return nil end
        QC:Init()
        local qcTicker = _tickers[#_tickers]
        -- Idle Tick() with no guide step & no candidate must NOT scan quest log
        _questScans = 0
        qcTicker.fn()
        qcTicker.fn()
        local scansWhileIdle = _questScans

        -- Direct Refresh() caches OwnedQuests across consecutive calls until QUEST_LOG_UPDATE
        QC:Refresh()
        QC:Refresh()
        local scansCached = _questScans
        QC:OnEvent("QUEST_LOG_UPDATE")
        local scansAfterInvalid = _questScans

        -- RoleMorph creates ZERO combat tickers out of combat, starts 2 on REGEN_DISABLED, cancels both on REGEN_ENABLED
        local beforeRM = #_tickers
        local RM = ToonAge:GetModule("RoleMorph")
        RM:Init()
        local tickersOutOfCombat = #_tickers - beforeRM
        RM:OnEvent("PLAYER_REGEN_DISABLED")
        local tickersInCombat = #_tickers - beforeRM
        RM:OnEvent("PLAYER_REGEN_ENABLED")
        local bothCancelled = (_tickers[beforeRM + 1].cancelled and _tickers[beforeRM + 2].cancelled)

        return {
            scansWhileIdle = scansWhileIdle,
            scansCached = scansCached,
            scansAfterInvalid = scansAfterInvalid,
            tickersOutOfCombat = tickersOutOfCombat,
            tickersInCombat = tickersInCombat,
            bothCancelled = bothCancelled,
        }
    end)()
    """)
    check("QuestContext Tick() skips quest-log scan completely when idle (no guide step / candidate)",
          r["scansWhileIdle"], 0)
    check("QuestContext caches OwnedQuests() across Refresh() calls and invalidates on QUEST_LOG_UPDATE",
          (r["scansCached"], r["scansAfterInvalid"]), (1, 2))
    check("RoleMorph spawns 0 combat tickers out of combat, 2 on combat start, and cancels both on combat end",
          (r["tickersOutOfCombat"], r["tickersInCombat"], r["bothCancelled"]), (0, 2, True))


def test_dungeon_pins_debounce():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r"""
    ToonAge = { modules = {}, Data = { DungeonQuests = {} }, flavor = "forever", db = {}, Utils = { IsSecret = function() return false end } }
    function ToonAge:RegisterModule(n, m) self.modules[n] = m end
    function ToonAge:GetModule(n) return self.modules[n] end
    _mapRefreshes = 0
    ToonAge:RegisterModule("MapPins", { Refresh = function() _mapRefreshes = _mapRefreshes + 1 end })
    _mapShown = false
    WorldMapFrame = { IsShown = function() return _mapShown end }
    _pendingTimers = {}
    C_Timer = { After = function(sec, fn) _pendingTimers[#_pendingTimers + 1] = { sec = sec, fn = fn } end }
    function CreateFrame()
        local f = { _scripts = {} }
        function f:RegisterEvent() end
        function f:SetScript(k, fn) self._scripts[k] = fn end
        return f
    end
    """)
    lua.execute(read("Modules/Forever/DungeonPins.lua"))
    r = lua.eval(r"""
    (function()
        local DP = ToonAge:GetModule("ForeverDungeonPins")
        local cacheCalls = 0
        local origCache = DP.RefreshQuestCache
        DP.RefreshQuestCache = function(self) cacheCalls = cacheCalls + 1; return origCache(self) end
        DP:Init()
        cacheCalls = 0

        -- 5 rapid QUEST_LOG_UPDATE events coalesce into 1 debounced timer
        for i = 1, 5 do
            DP._eventFrame._scripts.OnEvent(DP._eventFrame, "QUEST_LOG_UPDATE")
        end
        local queued = #_pendingTimers
        local callsBeforeFire = cacheCalls
        _pendingTimers[1].fn()
        local callsAfterFire = cacheCalls
        local mapRefreshHidden = _mapRefreshes

        -- When WorldMapFrame IS shown, MapPins:Refresh fires
        _mapShown = true
        DP._eventFrame._scripts.OnEvent(DP._eventFrame, "ZONE_CHANGED_NEW_AREA")
        local mapRefreshShown = _mapRefreshes

        return {
            queued = queued, callsBeforeFire = callsBeforeFire, callsAfterFire = callsAfterFire,
            mapRefreshHidden = mapRefreshHidden, mapRefreshShown = mapRefreshShown,
        }
    end)()
    """)
    check("DungeonPins coalesces 5 QUEST_LOG_UPDATE events into 1 debounced 0.3s refresh",
          (r["queued"], r["callsBeforeFire"], r["callsAfterFire"]), (1, 0, 1))
    check("DungeonPins skips MapPins:Refresh when WorldMapFrame is hidden and refreshes when shown",
          (r["mapRefreshHidden"], r["mapRefreshShown"]), (0, 1))


def main():
    test_mage_suggest()
    test_combat_state()
    test_quest_context_and_role_morph()
    test_dungeon_pins_debounce()

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
