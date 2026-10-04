#!/usr/bin/env python3
"""The chores: auto-accept/turn-in, sell greys, repair.

Auto-accept used to live inside QuestTracker. Forever ships no guides, the
guide cut removed the tracker, and the feature went with it -- "auto accept
isn't working" was really "auto accept was never loaded". It is a standalone
module now. These assertions pin the two properties that make that safe:
it stands down wherever a real QuestTracker is present, and it never calls a
client API without checking the client has it.

VendorAssist is held to the destructive-action bar: poor quality only, never a
worthless item, capped and staggered, re-checked at fire time, and never a
repair the player cannot afford.
"""
import sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif "-v" in sys.argv:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


aq = read("Modules/Automation/AutoQuest.lua")
va = read("Modules/Automation/VendorAssist.lua")
pf = read("Core/Profile.lua")
ui = read("Core/UI.lua")

# ── AutoQuest: registration and standing down ────────────────────────────
check("AutoQuest registers itself", 'TA:RegisterModule("AutoQuest", AQ)' in aq)
check("it detects a live QuestTracker", 'TA:GetModule("QuestTracker")' in aq)
check("and stands down behind it", "if TrackerOwnsIt() then return false end" in aq)
check("Shift is an escape hatch", "IsShiftKeyDown" in aq)
check("Zygor still wins", "DeferToZygor" in aq)

# ── AutoQuest: every client call is guarded ──────────────────────────────
check("AutoQuest has a guarded caller", "local function Try(fn, ...)" in aq)
check("Try rejects non-functions", 'if type(fn) ~= "function" then return nil end' in aq)
for api in ("AcceptQuest", "CompleteQuest", "GetQuestReward", "IsQuestCompletable",
            "GetNumQuestChoices", "GetQuestItemLink", "GetQuestID"):
    check(f"{api} goes through Try", f"Try({api}" in aq)
check("C_GossipInfo presence is checked", "if not C_GossipInfo then return end" in aq)
check("C_Item is probed before use", "if C_Item and C_Item.GetItemInfo then" in aq)

# ── AutoQuest: nothing is on by default, and nothing is pre-created ──────
# charDB.tracker being nil is how onboarding knows no preset was applied, so
# the table may only be created where the player actually flips a switch.
check("reads never create the table", "TA.charDB.tracker = TA.charDB.tracker or {}" in
      aq[aq.index("local function Set("):aq.index("local function Toggle(")])
get_body = aq[aq.index("local function Get("):aq.index("local function Set(")]
check("Get does not create the table", "or {}" not in get_body)

# Reward choice stays the player's click unless they opt out.
check("reward pick is opt-in", 'if Get("autoRewardPick") then' in aq)
check("the paused case names its pick", "paused for you" in aq)

# ── AutoQuest: the safety lists survived the move ────────────────────────
check("NPC blocklist carried over", "[111243] = true" in aq)
check("quest blocklist carried over", "[62716] = true" in aq)
check("gold turn-ins are refused", "QuestProgressRequiresGold" in aq)
check("reagent turn-ins are refused", '"Tradeskill"' in aq and '"Reagent"' in aq)
check("stranger quest shares are refused", "UnitIsInMyGuild" in aq)

# ── VendorAssist ─────────────────────────────────────────────────────────
check("VendorAssist registers itself", 'TA:RegisterModule("VendorAssist", VA)' in va)
check("it only fires at a merchant", 'if event ~= "MERCHANT_SHOW" then return end' in va)
check("Shift skips it too", "IsShiftKeyDown" in va)

check("poor quality is the only target", "local POOR_QUALITY = 0" in va)
collect = va[va.index("local function CollectJunk"):va.index("function VA:SellJunk")]
check("quality must equal poor exactly", "quality == POOR_QUALITY" in collect)
check("worthless items are skipped", "not noValue" in collect)
check("an unknown quality is never sold", "quality == POOR_QUALITY" in collect
      and "quality >=" not in collect and "quality <=" not in collect)

sell = va[va.index("function VA:SellJunk"):va.index("-- ── Repairing")]
check("sales are capped per visit", "MAX_SELLS_PER_VISIT" in sell)
check("sales are staggered", "SELL_INTERVAL" in sell)
check("the merchant is re-checked at fire time", "MerchantFrame" in sell)
check("the slot is re-checked at fire time", "SlotInfo(entry.bag, entry.slot)" in sell)
check("it sells back to front", "for i = count, 1, -1 do" in sell)

rep = va[va.index("function VA:Repair"):va.index("-- ── Events")]
check("repair checks the merchant can", "CanMerchantRepair" in rep)
check("repair never overspends", "money < cost" in rep)
check("guild funds are opt-in", 'Get("repairFromGuild")' in rep)
check("guild allowance is checked", "GetGuildBankWithdrawMoney" in rep)

# Both container APIs, because the modern one only exists on newer clients.
check("modern container API is probed", "C_Container.GetContainerItemInfo" in va)
check("legacy container API is kept", "Try(GetContainerItemInfo" in va)

# ── Wiring ───────────────────────────────────────────────────────────────
# TBC and Mists ship the chores through their profiles (fixed 2026-09-27:
# both TOCs loaded them while the profile denied them). Forever does not.
check("tbc ships AutoQuest", "AutoQuest         = true," in pf)
check("tbc and mists ship VendorAssist", pf.count("VendorAssist") >= 2)

# Mists draws without Core/Layout.lua, so it cannot host the shared tab; it
# gets the vendor chores through its own Settings tab instead.
mists_toc = read("ToonAge_Mists.toc")
check("Mists ships VendorAssist", "Modules\\Automation\\VendorAssist.lua" in mists_toc)
check("Mists does not ship AutoQuest", "Modules\\Automation\\AutoQuest.lua" not in mists_toc)
ms = read("Modules/Mists/Settings.lua")
check("Mists exposes the vendor toggles", '"autoSellJunk"' in ms and '"autoRepair"' in ms)

# Every TOC that lists one of these must list the shared Layout it draws with.
for toc in ("ToonAge.toc", "ToonAge_Mainline.toc", "ToonAge_TBC.toc"):
    t = read(toc)
    check(f"{toc} lists AutoQuest", "Modules\\Automation\\AutoQuest.lua" in t)
    check(f"{toc} lists VendorAssist", "Modules\\Automation\\VendorAssist.lua" in t)
    check(f"{toc} lists Core\\Layout.lua", "Core\\Layout.lua" in t)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
