#!/usr/bin/env python3
"""
ToonAge -- release zip contains every TOC file
==============================================
Data/ is runtime data and must ship. Art, docs, and Tools stay out.
The release zip is rejected when a TOC lists a file the zip does not have.

Usage:  python3 Tools/test_release_zip.py [-v]
"""
import fnmatch
import io
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "-v" in sys.argv
CHECKER = ROOT / "Tools" / "check_release_zip.py"
_results = []


def check(name, got, want):
    ok = got == want
    _results.append(ok)
    if VERBOSE or not ok:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got:  {got!r}")
            print(f"        want: {want!r}")
    return ok


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def pkgmeta_ignores(text):
    names = []
    in_ignore = False
    for ln in text.splitlines():
        if ln.startswith("ignore:"):
            in_ignore = True
            continue
        if not in_ignore:
            continue
        if ln.startswith("    - "):
            names.append(ln.split("-", 1)[1].strip())
        elif ln.strip() and not ln.startswith("#"):
            in_ignore = False
    return names


def rsync_excludes(text):
    return [ln.split("--exclude='", 1)[1].split("'", 1)[0]
            for ln in text.splitlines() if "--exclude='" in ln]


def excluded(rel, patterns):
    parts = rel.split("/")
    leaf = parts[-1]
    for pat in patterns:
        if any(ch in pat for ch in "*?["):
            if fnmatch.fnmatch(leaf, pat):
                return True
        elif pat in parts:
            return True
    return False


def tracked_files():
    out = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        check=True, capture_output=True,
    )
    return [p for p in out.stdout.decode("utf-8").split("\0") if p]


def build_zip(patterns):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        for rel in tracked_files():
            rel_fwd = rel.replace("\\", "/")
            if excluded(rel_fwd, patterns):
                continue
            zf.write(ROOT / rel, "ToonAge/" + rel_fwd)
    buf.seek(0)
    return buf


def run_checker(*args):
    proc = subprocess.run(
        [sys.executable, str(CHECKER), *args],
        capture_output=True, text=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def test_ignore_lists_keep_data():
    meta = pkgmeta_ignores(read(".pkgmeta"))
    excludes = rsync_excludes(read(".github/workflows/release.yml"))
    layout = next(ln for ln in read("Tools/build_release_layout.ps1").splitlines()
                  if ln.strip().startswith("$ExcludeDirs"))
    for label, names in ((".pkgmeta", meta), ("release.yml", excludes)):
        check(f"{label} ships Data", "Data" in names, False)
        for kept in ("Art", "docs", "Tools"):
            check(f"{label} skips {kept}", kept in names, True)
    check("layout script ships Data", "'Data'" in layout, False)
    for kept in ("Art", "docs", "Tools"):
        check(f"layout script skips {kept}", f"'{kept}'" in layout, True)
    check("the release workflow runs the zip check",
          "check_release_zip.py" in read(".github/workflows/release.yml"), True)
    check("the layout script runs the zip check",
          "check_release_zip.py" in read("Tools/build_release_layout.ps1"), True)


def test_packaged_zip_has_every_toc_file():
    patterns = rsync_excludes(read(".github/workflows/release.yml"))
    buf = build_zip(patterns)
    good_bytes = buf.getvalue()
    with zipfile.ZipFile(io.BytesIO(good_bytes)) as zf:
        names = set(zf.namelist())
        held = io.BytesIO()
        with zipfile.ZipFile(held, "w") as broken:
            for info in zf.infolist():
                if info.filename == "ToonAge/Data/Retail/ApiManifest.lua":
                    continue
                broken.writestr(info, zf.read(info.filename))
        broken_bytes = held.getvalue()
    check("the release zip contains Data",
          "ToonAge/Data/Retail/ApiManifest.lua" in names, True)
    with tempfile.TemporaryDirectory() as tmp:
        good = Path(tmp) / "good.zip"
        bad = Path(tmp) / "bad.zip"
        good.write_bytes(good_bytes)
        code, _out, err = run_checker(str(good))
        check("a complete zip passes", code, 0)
        check("a complete zip reports no missing file", "missing" in err.lower(), False)
        bad.write_bytes(broken_bytes)
        code, _out, err = run_checker(str(bad))
        check("a zip missing a TOC file fails", code, 1)
        check("the failure names the missing file",
              "Data/Retail/ApiManifest.lua" in err, True)


def main():
    test_ignore_lists_keep_data()
    test_packaged_zip_has_every_toc_file()
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
