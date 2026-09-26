#!/usr/bin/env python3
"""Quest reward choices pause for the player.

A reward choice is permanent and personal — the transmog, the offspec piece,
the one you meant to sell. Auto-clicking it is the kind of automation that
makes people switch automation off, so ToonAge stops and advises instead.
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


qt = open(os.path.join(ROOT, "Modules/Navigation/QuestTracker.lua"), encoding="utf-8").read()
st = open(os.path.join(ROOT, "Modules/Infrastructure/Settings.lua"), encoding="utf-8").read()

block = qt[qt.index('elseif event == "QUEST_COMPLETE"'):qt.index('elseif event == "GOSSIP_SHOW"')]

# One reward, or none: nothing to decide, so finishing it is still correct.
check("single/no-choice turn-ins still complete",
      "if numChoices <= 1 then" in block and "GetQuestReward(numChoices == 1 and 1 or nil)" in block)

# A guide that names a specific reward is an instruction from the player, so
# honouring it is not the same as choosing for them.
check("guide-specified reward is still honoured", "step.reward" in block)

# The default path must NOT click.
check("pausing is the default", 'autoRewardPick == true' in block)
check("opt-in auto-pick still exists", "if autoPick then" in block)
auto_idx = block.index("if autoPick then")
after = block[auto_idx:]
check("the only unconditional GetQuestReward is the single-reward case",
      block[:auto_idx].count("GetQuestReward(bestIdx)"), 0)
check("auto-pick path clicks the best choice", "GetQuestReward(bestIdx)" in after)

# When paused, say something useful rather than nothing.
check("paused state tells the player it paused", "paused for you" in block)
check("paused state names the best item", "Best for your spec looks like" in block)
check("paused state points at the setting", "Auto-pick quest rewards" in block)

check("setting exposed as a toggle", "Auto-pick quest rewards (off = pause" in st)
check("setting travels in profile export", '"tracker.autoRewardPick",' in st)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
