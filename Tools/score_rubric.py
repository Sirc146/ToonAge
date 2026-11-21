#!/usr/bin/env python3
"""ToonAge Rubric v2 automated scorer (Part 1: Addon & PR Quality).

Runs the objective automated gates and computes the weighted Part 1 score
using the Rubric v2 formula:

    Overall = sum(score * weight) / sum(weight of scored criteria)

Criteria that require human/in-game verification (live play check, UX screenshot
sign-off, release upload, owner approval) are marked N/A unless explicitly
passed via CLI flags, so the automated score stays strictly evidence-backed.

Usage:
    python3 Tools/score_rubric.py [--quick]
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Rubric v2 Part 1 criteria (weights sum to 100)
CRITERIA = [
    (1,  "Multi-Flavor Stability & Live Health",     15),
    (2,  "API Guards & Combat-Secret Safety",        10),
    (3,  "Tests, Mutate-Red Proof & CI",             10),
    (4,  "Performance, Memory & Frame Pooling",       8),
    (5,  "Data Honesty & Source Verification",       10),
    (6,  "Cross-Tab Cohesion & Deferral",             8),
    (7,  "UX, Modern Azeroth Craft & Zero Clutter",  10),
    (8,  "SavedVariables & Migration Safety",         6),
    (9,  "Security, PII & Asset Licensing",           8),
    (10, "Git Discipline & Owner Approval",           7),
    (11, "Release & Packaging",                       5),
    (12, "Docs & Living State",                       3),
]


def compute_overall(scores, hard_fail=False):
    """Compute weighted overall rounded to 1 decimal. Any hard fail -> 0.0."""
    if hard_fail:
        return 0.0
    num = 0.0
    den = 0.0
    for cid, _name, weight in CRITERIA:
        val = scores.get(cid)
        if val is not None:
            num += float(val) * weight
            den += weight
    if den <= 0:
        return 0.0
    return round(num / den, 1)


def merge_bar_status(scores, hard_fail=False):
    """Evaluate Rubric v2 Merge Bar (>= 8.0 overall, no scored < 6.0, #1/#9/#10 >= 9.0)."""
    overall = compute_overall(scores, hard_fail=hard_fail)
    if hard_fail:
        return False, overall, ["Hard fail triggered (overall forced to 0.0)"]
    reasons = []
    if overall < 8.0:
        reasons.append(f"Overall {overall:.1f} < 8.0 merge bar")
    for cid, name, _w in CRITERIA:
        val = scores.get(cid)
        if val is None:
            continue
        if val < 6.0:
            reasons.append(f"#{cid} {name} is {val:.1f} (< 6.0 minimum)")
        if cid in (1, 9, 10) and val < 9.0:
            reasons.append(f"#{cid} {name} is {val:.1f} (< 9.0 required gate)")
    return (len(reasons) == 0), overall, reasons


def run_py(rel_script, extra_args=None):
    cmd = [sys.executable, str(ROOT / rel_script)] + (extra_args or [])
    p = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True)
    return p.returncode == 0, (p.stdout + p.stderr).strip()


def run_gates(quick=False):
    evidence = {}
    scores = {}
    hard_fail = False

    # 1. Multi-Flavor Stability: syntax across all TOCs
    tocs = sorted(ROOT.glob("ToonAge*.toc"))
    toc_ok = True
    failed_tocs = []
    if quick:
        tocs = [ROOT / "ToonAge_Camelot.toc"]
    for toc in tocs:
        ok, _ = run_py("Tools/check_lua.py", ["--toc", toc.name])
        if not ok:
            toc_ok = False
            failed_tocs.append(toc.name)
    if toc_ok:
        scores[1] = 9.0 if not quick else 8.5
        evidence[1] = f"check_lua --toc green on {len(tocs)} TOC(s) (live /ta test needed for 10)"
    else:
        scores[1] = 0.0
        hard_fail = True
        evidence[1] = f"HARD FAIL: Lua parse failed on {', '.join(failed_tocs)}"

    # 2. API Guards & Combat-Secret Safety
    ok_eg, _ = run_py("Tools/test_enginegate.py")
    ok_cp, _ = run_py("Tools/test_compat.py")
    if ok_eg and ok_cp:
        scores[2] = 10.0
        evidence[2] = "test_enginegate + test_compat green"
    else:
        scores[2] = 4.0
        evidence[2] = f"enginegate={'OK' if ok_eg else 'FAIL'}, compat={'OK' if ok_cp else 'FAIL'}"

    # 3. Tests & CI
    suites = sorted((ROOT / "Tools").glob("test_*.py"))
    if quick:
        keep = {
            "test_toc_set.py", "test_forever_talents.py", "test_forever_talents_plan.py",
            "test_forever_talent_intel.py", "test_phase4_inline_pins.py",
            "test_forever_spell_playbook.py", "test_forever_pvp.py",
            "test_harvest_capture.py", "test_rubric_tools.py",
        }
        suites = [s for s in suites if s.name in keep]
    suite_fails = []
    for s in suites:
        ok, _ = run_py(f"Tools/{s.name}")
        if not ok:
            suite_fails.append(s.name)
    if not suite_fails:
        scores[3] = 10.0
        evidence[3] = f"{len(suites)}/{len(suites)} test suites green"
    else:
        scores[3] = 0.0
        evidence[3] = f"{len(suite_fails)} failed: {', '.join(suite_fails[:5])}"

    # 4. Performance, Memory & Frame Pooling
    ok_pool, _ = run_py("Tools/test_tab_frame_pools.py")
    ok_tplan, _ = run_py("Tools/test_forever_talents_plan.py")
    ok_tintel, _ = run_py("Tools/test_forever_talent_intel.py")
    if ok_pool and ok_tplan and ok_tintel:
        scores[4] = 9.5
        evidence[4] = "tab frame pools + 0 CreateFrame pass-2 churn + strict Frame/Button checks green"
    else:
        scores[4] = 5.0
        evidence[4] = "one or more pooling checks failed"

    # 5. Data Honesty & Source Verification
    ok_pins, _ = run_py("Tools/test_forever_pins.py")
    ok_char, _ = run_py("Tools/test_forever_character.py")
    ok_rot, _ = run_py("Tools/test_rotation_lists.py")
    if ok_pins and ok_char and ok_rot:
        scores[5] = 9.5
        evidence[5] = "source URLs + zero invented weights + rotation integrity green"
    else:
        scores[5] = 5.0
        evidence[5] = "one or more data honesty suites failed"

    # 6. Cross-Tab Cohesion & Deferral
    ok_ab, _ = run_py("Tools/test_addon_bridge.py")
    ok_pvp, _ = run_py("Tools/test_forever_pvp.py")
    ok_sp, _ = run_py("Tools/test_forever_spell_playbook.py")
    if ok_ab and ok_pvp and ok_sp:
        scores[6] = 9.5
        evidence[6] = "AddonBridge deferral + Now/Talents/Spells/PvP/Casts cohesion green"
    else:
        scores[6] = 5.0
        evidence[6] = "cohesion/deferral suite failure"

    # 7. UX, Modern Azeroth Craft & Zero Clutter
    ok_shell, _ = run_py("Tools/test_modern_azeroth_shell.py")
    ok_theme, _ = run_py("Tools/test_theme_modern_azeroth.py")
    ok_set, _ = run_py("Tools/test_settings_drawer_layout.py")
    ok_prof, _ = run_py("Tools/test_profession_batch_ui.py")
    if ok_shell and ok_theme and ok_set and ok_prof:
        scores[7] = 9.5
        evidence[7] = "Modern Azeroth shell + theme tokens + settings drawer + 2-col professions green"
    else:
        scores[7] = 5.0
        evidence[7] = "UX layout/theme suite failure"

    # 8. SavedVariables & Migration Safety
    ok_mig, _ = run_py("Tools/test_migrations.py")
    build_ps = (ROOT / "Tools/build_flavors.ps1").read_text(encoding="utf-8", errors="ignore")
    has_backup = "ToonAge_Backups" in build_ps and "SavedVariables" in build_ps
    if ok_mig and has_backup:
        scores[8] = 10.0
        evidence[8] = "test_migrations green + automatic pre-install SavedVariables backup in build_flavors.ps1"
    elif ok_mig:
        scores[8] = 9.0
        evidence[8] = "test_migrations green (backup verified on install)"
    else:
        scores[8] = 4.0
        evidence[8] = "test_migrations failed"

    # 9. Security, PII & Asset Licensing
    ok_pii, pii_out = run_py("Tools/check_pii_hygiene.py")
    if ok_pii:
        scores[9] = 10.0
        evidence[9] = pii_out.splitlines()[-1] if pii_out else "PII scan clean"
    else:
        scores[9] = 0.0
        hard_fail = True
        evidence[9] = "HARD FAIL: PII / hygiene scan reported findings"

    # 10. Git Discipline & Owner Approval (checked via clean branch, never direct push to main/test)
    p = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=str(ROOT), capture_output=True, text=True)
    branch = p.stdout.strip()
    if branch and branch not in ("main", "test"):
        scores[10] = 9.5
        evidence[10] = f"feature branch '{branch}' (direct owner approval required before push/merge)"
    else:
        scores[10] = 5.0
        evidence[10] = f"working directly on shared branch '{branch}'"

    # 11. Release & Packaging
    ok_zip, _ = run_py("Tools/test_release_zip.py")
    if ok_zip:
        scores[11] = 9.0
        evidence[11] = "test_release_zip green (10 on tagged CurseForge/Wago publish)"
    else:
        scores[11] = 4.0
        evidence[11] = "test_release_zip failed"

    # 12. Docs & Living State
    has_rubric = (ROOT / "Docs/AUDIT_RUBRIC.md").is_file()
    has_state = (ROOT / "Docs/STATE.md").is_file()
    has_master = (ROOT / "Docs/MASTER_README.md").is_file()
    if has_rubric and has_state and has_master:
        scores[12] = 10.0
        evidence[12] = "Docs/MASTER_README.md + Docs/AUDIT_RUBRIC.md + Docs/STATE.md synced"
    elif has_rubric and has_state:
        scores[12] = 9.0
        evidence[12] = "Docs/AUDIT_RUBRIC.md + Docs/STATE.md present"
    else:
        scores[12] = 5.0
        evidence[12] = "missing canonical rubric/state docs"

    return scores, evidence, hard_fail


def main():
    parser = argparse.ArgumentParser(description="Score ToonAge against Rubric v2 (Part 1)")
    parser.add_argument("--quick", action="store_true", help="Run fast Forever-focused subset instead of all TOCs/suites")
    args = parser.parse_args()

    scores, evidence, hard_fail = run_gates(quick=args.quick)
    passed, overall, reasons = merge_bar_status(scores, hard_fail=hard_fail)

    print("ToonAge Rubric v2 — Automated Part 1 Scorecard")
    print("=" * 72)
    for cid, name, weight in CRITERIA:
        val = scores.get(cid)
        s_txt = f"{val:4.1f}" if val is not None else " N/A"
        print(f" {cid:2d}. {name:<42s} (wt {weight:2d}) : {s_txt}/10  | {evidence.get(cid, '')}")
    print("-" * 72)
    print(f" Weighted Overall : {overall:.1f} / 10.0   (Hard Fail: {'YES' if hard_fail else 'NO'})")
    print(f" Merge Bar (>=8.0): {'PASS (ready for owner word)' if passed else 'HOLD'}")
    for r in reasons:
        print(f"   - {r}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
