#!/usr/bin/env python3
"""Tests for Rubric v2 automation tools (Tools/check_pii_hygiene.py & Tools/score_rubric.py).

Includes mutate-red proof: feeds synthetic secret tokens, personal OS user paths,
emojis in code, and env PII terms into check_pii_hygiene.scan_text and proves
each is caught, while clean code passes with 0 findings.

Usage:  python3 Tools/test_rubric_tools.py [-v]
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Tools"))

import check_pii_hygiene as pii
import score_rubric as sr

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


def main():
    # 1. check_pii_hygiene mutate-red detection checks
    clean = pii.scan_text("Modules/Forever/Sample.lua", "local x = 42\n-- example C:\\Users\\username\\file\n")
    check("clean Lua with placeholder username passes", clean, [])

    win_hit = pii.scan_text("Modules/Forever/Sample.lua", r'local p = "C:\Users\alice\Desktop\secret"')
    check("detects personal Windows user path", [f[2] for f in win_hit], ["personal_win_path"])

    mac_hit = pii.scan_text("Docs/SAMPLE.md", "file at /Users/bob/Documents/notes.md")
    check("detects personal macOS user path", [f[2] for f in mac_hit], ["personal_mac_path"])

    aws_hit = pii.scan_text("Tools/sample.py", 'KEY = "AKIAIOSFODNN7EXAMPLE"')
    check("detects AWS access key token", [f[2] for f in aws_hit], ["secret_aws_key"])

    gh_hit = pii.scan_text("Tools/sample.py", 'TOK = "ghp_' + ('a' * 36) + '"')
    check("detects GitHub PAT token", [f[2] for f in gh_hit], ["secret_gh_token"])

    emoji_hit = pii.scan_text("Modules/Forever/Sample.lua", 'local s = "boom \U0001F525"')
    check("detects emoji in Lua code", [f[2] for f in emoji_hit], ["emoji_in_code"])

    env_hit = pii.scan_text("Docs/SAMPLE.md", "Character ExampleSecretName logged in", extra_terms=["examplesecretname"])
    check("detects custom TOONAGE_PII_TERMS hit", [f[2] for f in env_hit], ["env_pii_term"])

    # 2. score_rubric weighted math, N/A handling, hard-fail zeroing, merge bar
    total_wt = sum(w for _, _, w in sr.CRITERIA)
    check("Rubric v2 Part 1 weights sum to exactly 100", total_wt, 100)

    all_ten = {cid: 10.0 for cid, _, _ in sr.CRITERIA}
    check("all 10s yield 10.0 overall", sr.compute_overall(all_ten), 10.0)
    check("hard fail forces overall to 0.0 regardless of scores", sr.compute_overall(all_ten, hard_fail=True), 0.0)

    partial = {1: 10.0, 2: 8.0}  # weights 15 and 10 -> (150 + 80) / 25 = 9.2
    check("N/A criteria drop cleanly out of denominator (10*15 + 8*10)/25 = 9.2",
          sr.compute_overall(partial), 9.2)

    ok_bar, ov_bar, _ = sr.merge_bar_status({1: 9.0, 2: 8.5, 9: 9.5, 10: 9.0})
    check("passing merge bar returns True", (ok_bar, ov_bar), (True, 9.0))

    fail_low, _, reasons_low = sr.merge_bar_status({1: 10.0, 2: 5.5, 9: 10.0, 10: 10.0})
    check("criterion below 6.0 blocks merge bar even when overall >= 8.0",
          (fail_low, any("< 6.0" in r for r in reasons_low)), (False, True))

    fail_gate, _, reasons_gate = sr.merge_bar_status({1: 8.5, 2: 10.0, 9: 10.0, 10: 10.0})
    check("#1 Stay-working below 9.0 blocks merge bar",
          (fail_gate, any("< 9.0" in r for r in reasons_gate)), (False, True))

    passed = sum(1 for x in _results if x)
    total = len(_results)
    print(f"{passed}/{total} passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
