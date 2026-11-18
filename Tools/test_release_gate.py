#!/usr/bin/env python3
"""The packager gate is inserted before any upload and refuses a bad zip."""
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GATE = ROOT / "Tools" / "insert_release_gate.py"
_results = []

ANCHOR = "if [[ -z $skip_upload && -n $archive && -s $archive ]]; then\n"


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if "-v" in sys.argv or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def run_gate(*args):
    return subprocess.run(
        [sys.executable, str(GATE), *args],
        capture_output=True, text=True,
    )


def sample(anchor_count=1):
    body = "echo build\n"
    body += ANCHOR * anchor_count
    body += "  upload_curseforge\n"
    return body


def test_gate_lands_before_upload():
    with tempfile.TemporaryDirectory() as tmp:
        script = Path(tmp) / "release.sh"
        script.write_text(sample(), encoding="utf-8")
        proc = run_gate(str(script))
        text = script.read_text(encoding="utf-8")
        check("a script with the upload anchor is patched", proc.returncode, 0)
        gate_at = text.find("TOONAGE_PRE_UPLOAD_GATE")
        anchor_at = text.find(ANCHOR.strip())
        check("the gate marker is present", gate_at >= 0, True)
        check("the gate is before the upload",
              gate_at >= 0 and anchor_at >= 0 and gate_at < anchor_at, True)
        check("the gate runs the zip checker", "check_release_zip.py" in text, True)
        check("a failed check stops the script", "exit 1" in text, True)
        check("the upload anchor is still there", text.count(ANCHOR.strip()), 1)

        again = run_gate(str(script))
        check("patching the same script again is safe", again.returncode, 0)
        check("the gate is not inserted twice",
              script.read_text(encoding="utf-8").count("TOONAGE_PRE_UPLOAD_GATE"), 1)


def test_gate_refuses_a_script_it_cannot_place():
    with tempfile.TemporaryDirectory() as tmp:
        missing = Path(tmp) / "missing.sh"
        missing.write_text("echo no upload hook\n", encoding="utf-8")
        proc = run_gate(str(missing))
        check("a script without the upload anchor fails", proc.returncode, 1)
        check("the failure says the anchor is missing",
              "anchor" in (proc.stdout + proc.stderr).lower(), True)

        twice = Path(tmp) / "twice.sh"
        twice.write_text(sample(2), encoding="utf-8")
        proc = run_gate(str(twice))
        check("two upload anchors fail", proc.returncode, 1)
        check("the unpatched script is left unchanged",
              twice.read_text(encoding="utf-8"), sample(2))


def main():
    test_gate_lands_before_upload()
    test_gate_refuses_a_script_it_cannot_place()
    passed = sum(1 for ok in _results if ok)
    total = len(_results)
    print()
    if passed == total:
        print(f"[OK] {passed}/{total} assertions passed.")
        return 0
    print(f"[FAIL] {passed}/{total} passed; {total - passed} failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
