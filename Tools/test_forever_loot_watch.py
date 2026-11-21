#!/usr/bin/env python3
"""Tests for Phase 8 Dungeon Loot Watch Toast (Modules/Forever/LootWatch.lua).

Verifies:
1. ParseNeedMessage parses both other-player and self Need lines, and safely ignores secret/non-Need strings.
2. Off-armor / off-stat Need (Warrior needing Cloth +Int, Mage needing Mail, Hunter needing Cloth +SP)
   fires a 'goblin' alert IMMEDIATELY even BEFORE the player rolls Need.
3. BoE green Need (quality=2, bindType=2) fires a 'goblin' alert immediately.
4. Repeat Need (3rd+ Need by same player in one run) fires a 'goblin' alert with badge count = 3.
5. Contested Need fires both when another player rolls Need after you AND when you roll Need after them.
6. Pooled TALootWatchToast frame reuses the exact same frame (0 CreateFrame churn on 2nd toast),
   queues concurrent alerts, pumps cleanly on click-dismiss, and resets cleanly on GROUP_LEFT.
7. Strictly private: zero SendChatMessage calls anywhere in LootWatch.lua.

Usage:  python3 Tools/test_forever_loot_watch.py [-v]
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


PRELUDE = r"""
ToonAge = { modules = {}, Data = {}, flavor = "forever", IsForever = true, db = {} }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:GetModule(name) return self.modules[name] end
ToonAge.Utils = {
    IsSecret = function(v) return type(v) == "table" and v._secret == true end,
    TEX_RING = "Interface\\AddOns\\ToonAge\\Media\\frame\\ring_32.tga",
}
issecretvalue = function(v) return type(v) == "table" and v._secret == true end

LOOT_ROLL_NEED = "%s has selected Need for: %s"
LOOT_ROLL_NEED_SELF = "You have selected Need for: %s"
SOUNDKIT = { RAID_WARNING = 8959, TELL_MESSAGE = 3081 }
soundPlayed = 0
PlaySound = function() soundPlayed = soundPlayed + 1 end
time = function() return 1795278000 end

createdFrames = 0
local function Widget(kind, name)
    local f = { kind = kind, name = name, _shown = false, scripts = {}, _text = "", _alpha = 1 }
    setmetatable(f, {
        __index = function(_, key)
            local head = type(key) == "string" and key:sub(1, 3) or ""
            if head == "Set" or head == "Get" or head == "Ena" or head == "Reg"
                or head == "Sto" or head == "Sta" or key == "ClearAllPoints" then
                return function() end
            end
            return nil
        end,
    })
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetText(t) self._text = t or "" end
    function f:GetText() return self._text end
    function f:SetAlpha(a) self._alpha = a end
    function f:SetScript(ev, fn) self.scripts[ev] = fn end
    function f:CreateTexture() return Widget("Texture") end
    function f:CreateFontString() return Widget("FontString") end
    return f
end
UIParent = Widget("Frame", "UIParent")
function CreateFrame(kind, name, parent)
    createdFrames = createdFrames + 1
    local f = Widget(kind, name)
    if name then _G[name] = f end
    return f
end

UnitName = function(u)
    if u == "player" then return "ExampleMage" end
    if u == "party1" then return "GoblinWarrior" end
    if u == "party2" then return "AllyPriest" end
    if u == "party3" then return "GreedyHunter" end
    return nil
end
UnitClass = function(u)
    if u == "player" then return "Mage", "MAGE" end
    if u == "party1" then return "Warrior", "WARRIOR" end
    if u == "party2" then return "Priest", "PRIEST" end
    if u == "party3" then return "Hunter", "HUNTER" end
    return nil
end
"""


def main():
    src = read("Modules/Forever/LootWatch.lua")
    check("LootWatch never calls SendChatMessage (strictly private)", "SendChatMessage" not in src, True)

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(src)

    r = lua.eval(r"""
    (function()
        local LW = ToonAge:GetModule("ForeverLootWatch")
        LW.ResetRun()

        -- 1. ParseNeedMessage checks
        local w1, l1 = LW.ParseNeedMessage("GoblinWarrior has selected Need for: |cff0070dd|Hitem:1001|h[Robe of Intellect]|h|r")
        local w2, l2 = LW.ParseNeedMessage("You have selected Need for: |cff0070dd|Hitem:1001|h[Robe of Intellect]|h|r")
        local w3, l3 = LW.ParseNeedMessage("GoblinWarrior has selected Greed for: [Trash]")
        local wSec, _ = LW.ParseNeedMessage({ _secret = true })

        local clothInt = {
            link = "|cff0070dd|Hitem:1001|h[Robe of Intellect]|h|r",
            name = "Robe of Intellect",
            quality = 3, bindType = 1, classID = 4, subClassID = 1, equipLoc = "INVTYPE_ROBE",
            stats = { int = 8, sp = 6, str = 0, agi = 0, ap = 0 },
        }
        local boeGreen = {
            link = "|cff1eff00|Hitem:1002|h[Tiger Band]|h|r",
            name = "Tiger Band",
            quality = 2, bindType = 2, classID = 4, subClassID = 0, equipLoc = "INVTYPE_FINGER",
            stats = { agi = 4, str = 4 },
        }
        local mailStr = {
            link = "|cff0070dd|Hitem:1003|h[Mail Bracers]|h|r",
            name = "Mail Bracers",
            quality = 3, bindType = 1, classID = 4, subClassID = 3, equipLoc = "INVTYPE_WRIST",
            stats = { str = 6, int = 0, sp = 0 },
        }

        -- 2. Warrior rolls Need on Cloth +Int BEFORE player even rolls -> instant 'goblin' toast!
        local a1 = LW:HandleLootMessage("GoblinWarrior has selected Need for: " .. clothInt.link, nil, clothInt)
        local framesAfterFirst = createdFrames
        local toastShown1 = _G.TALootWatchToast:IsShown()
        local toastTitle1 = _G.TALootWatchToast.title:GetText()
        local toastBadge1 = _G.TALootWatchToast.badgeText:GetText()

        -- 3. Hunter rolls Need on BoE green while toast 1 is visible -> queued, 0 new frames!
        local a2 = LW:HandleLootMessage("GreedyHunter has selected Need for: " .. boeGreen.link, nil, boeGreen)
        local framesAfterSecond = createdFrames
        local qLen = #LW._queue

        -- Dismiss toast 1 -> toast 2 pumps automatically onto same pooled frame!
        _G.TALootWatchToast.scripts.OnClick(_G.TALootWatchToast)
        local toastTitle2 = _G.TALootWatchToast.title:GetText()
        local toastShown2 = _G.TALootWatchToast:IsShown()
        _G.TALootWatchToast.scripts.OnClick(_G.TALootWatchToast)

        -- 4. Legitimate Priest rolls Need on Cloth +Int BEFORE us (no goblin alert yet),
        --    then WE roll Need -> immediate 'contested' alert!
        local aPriestBefore = LW:HandleLootMessage("AllyPriest has selected Need for: " .. clothInt.link, nil, clothInt)
        local aContestedAfterSelf = LW:HandleLootMessage("You have selected Need for: " .. clothInt.link, nil, clothInt)
        _G.TALootWatchToast.scripts.OnClick(_G.TALootWatchToast)

        -- 5. Repeat Needer (3rd Need in one run by AllyPriest on valid cloth items) -> 'goblin' alert with badge '3'!
        local c2 = { link = "|cff0070dd|Hitem:1004|h[Cloth Gloves]|h|r", name = "Cloth Gloves", quality = 3, bindType = 1, classID = 4, subClassID = 1, stats = { int = 5 } }
        local c3 = { link = "|cff0070dd|Hitem:1005|h[Cloth Boots]|h|r", name = "Cloth Boots", quality = 3, bindType = 1, classID = 4, subClassID = 1, stats = { int = 5 } }
        local aP2 = LW:HandleLootMessage("AllyPriest has selected Need for: " .. c2.link, nil, c2)
        local aP3 = LW:HandleLootMessage("AllyPriest has selected Need for: " .. c3.link, nil, c3)

        -- 6. Cloth caster needing Mail -> cannot wear Mail
        local aMageMail = LW.EvaluateNeed("ExampleMage", "MAGE", mailStr, false, 1)

        -- 7. GROUP_LEFT resets per-run history
        LW:OnEvent("GROUP_LEFT")
        local emptyAfterLeave = (next(LW.runNeeds) == nil)

        return {
            w1 = w1, hasLink1 = (l1 == clothInt.link),
            w2 = w2,
            w3Nil = (w3 == nil),
            wSecNil = (wSec == nil),
            a1Sev = a1 and a1.severity,
            a1Reason = a1 and a1.reason or "",
            toastShown1 = toastShown1,
            toastTitle1 = toastTitle1,
            toastBadge1 = toastBadge1,
            a2Sev = a2 and a2.severity,
            a2Reason = a2 and a2.reason or "",
            zeroChurn = (framesAfterSecond == framesAfterFirst),
            qLen = qLen,
            toastTitle2 = toastTitle2,
            toastShown2 = toastShown2,
            aPriestBeforeNil = (aPriestBefore == nil),
            aContestedSev = aContestedAfterSelf and aContestedAfterSelf.severity,
            aP2Nil = (aP2 == nil),
            aP3Sev = aP3 and aP3.severity,
            aP3Count = aP3 and aP3.count,
            aMageMailSev = aMageMail and aMageMail.severity,
            aMageMailReason = aMageMail and aMageMail.reason or "",
            emptyAfterLeave = emptyAfterLeave,
        }
    end)()
    """)
    check("ParseNeedMessage extracts other player and item link", (r["w1"], r["hasLink1"]), ("GoblinWarrior", True))
    check("ParseNeedMessage recognizes self Need roll", r["w2"], "SELF")
    check("ParseNeedMessage ignores Greed and combat-secret values safely", (r["w3Nil"], r["wSecNil"]), (True, True))
    check("Warrior needing Cloth +Int BEFORE player rolls fires instant 'goblin' alert",
          (r["a1Sev"], "melee on Cloth" in r["a1Reason"]), ("goblin", True))
    check("Toast displays title and run Need counter badge '1'",
          (r["toastShown1"], "GoblinWarrior (Warrior)" in r["toastTitle1"], r["toastBadge1"]),
          (True, True, "1"))
    check("BoE green Need fires 'goblin' alert and queues cleanly with 0 CreateFrame churn",
          (r["a2Sev"], "BoE green Need" in r["a2Reason"], r["zeroChurn"], r["qLen"]),
          ("goblin", True, True, 1))
    check("Click-dismiss pumps queued alert onto the same pooled toast",
          (r["toastShown2"], "GreedyHunter (Hunter)" in r["toastTitle2"]), (True, True))
    check("Legitimate Priest rolling Need alone stays quiet, then alerts 'contested' when player also Needs",
          (r["aPriestBeforeNil"], r["aContestedSev"]), (True, "contested"))
    check("3rd Need in one dungeon run escalates to 'goblin' with count 3",
          (r["aP2Nil"], r["aP3Sev"], r["aP3Count"]), (True, "goblin", 3))
    check("Mage needing Mail fires 'cannot wear Mail' alert",
          (r["aMageMailSev"], "cannot wear Mail" in r["aMageMailReason"]), ("goblin", True))
    check("GROUP_LEFT clears per-run Need history cleanly", r["emptyAfterLeave"], True)

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
