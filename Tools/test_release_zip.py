#!/usr/bin/env python3
"""
ToonAge -- release zip contains every TOC file
==============================================
Data/ is runtime data and must ship. Art, docs, and Tools stay out.
The release zip is rejected when a TOC lists a file the zip does not have.

Usage:  python3 Tools/test_release_zip.py [-v]
"""
import fnmatch
import hashlib
import io
import json
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


REQUIRED_TOCS = (
    "ToonAge.toc",
    "ToonAge_Camelot.toc",
    "ToonAge_Cata.toc",
    "ToonAge_Mainline.toc",
    "ToonAge_Mists.toc",
    "ToonAge_TBC.toc",
    "ToonAge_Vanilla.toc",
    "ToonAge_Wrath.toc",
)


def toc_bytes(version):
    return f"## Version: {version}\nCore/Init.lua\n".encode()


def good_entries(version="2.0.0-dev.1"):
    entries = {f"ToonAge/{name}": toc_bytes(version) for name in REQUIRED_TOCS}
    entries["ToonAge/Core/Init.lua"] = b"-- init\n"
    return entries


def write_zip(path, entries):
    with zipfile.ZipFile(path, "w") as zf:
        for name, data in entries.items():
            zf.writestr(name, data)


def test_release_rules_and_manifest():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        good = tmp / "good.zip"
        write_zip(good, good_entries())
        code, _out, _err = run_checker(str(good))
        check("a zip with the eight TOCs passes", code, 0)

        code, _out, _err = run_checker("--version", "2.0.0-dev.1", str(good))
        check("the stamped version passes", code, 0)

        code, out, err = run_checker("--version", "v9.9.9-test", str(good))
        check("a different version fails", code, 1)
        check("the failure says version", "version" in (out + err).lower(), True)

        missing = good_entries()
        del missing["ToonAge/ToonAge_Camelot.toc"]
        bad = tmp / "missing-toc.zip"
        write_zip(bad, missing)
        code, out, err = run_checker(str(bad))
        check("a missing TOC fails", code, 1)
        check("the failure names the TOC", "ToonAge_Camelot.toc" in (out + err), True)

        for rel in (
            "ToonAge/docs/notes.md",
            "ToonAge/Docs/notes.md",
            "ToonAge/Tools/check_release_zip.py",
            "ToonAge/tests/test_x.lua",
            "ToonAge/AGENTS.md",
        ):
            entries = good_entries()
            entries[rel] = b"dev\n"
            path = tmp / (rel.replace("/", "_") + ".zip")
            write_zip(path, entries)
            code, out, err = run_checker(str(path))
            check(f"dev file {rel} fails", code, 1)
            check(f"dev file {rel} is named", rel.split("/")[1] in (out + err), True)

        manifest = tmp / "manifest.json"
        code, _out, _err = run_checker(
            "--version", "2.0.0-dev.1", "--manifest", str(manifest), str(good))
        check("manifest write passes", code, 0)
        check("manifest file exists", manifest.is_file(), True)
        data = {}
        if manifest.is_file():
            data = json.loads(manifest.read_text(encoding="utf-8"))
        digest = hashlib.sha256(good.read_bytes()).hexdigest()
        check("manifest records the zip sha256", data.get("zip_sha256"), digest)
        files = data.get("files") or []
        check("manifest lists every file", len(files), 9)
        init = next((item for item in files if item["path"].endswith("Core/Init.lua")), {})
        check("manifest records a file sha256",
              init.get("sha256"), hashlib.sha256(b"-- init\n").hexdigest())

        code, _out, _err = run_checker("--require-zip-sha", str(manifest), str(good))
        check("the same zip matches the manifest", code, 0)

        altered = tmp / "altered.zip"
        raw = bytearray(good.read_bytes())
        raw[-2] ^= 0xFF
        altered.write_bytes(raw)
        code, out, err = run_checker("--require-zip-sha", str(manifest), str(altered))
        check("an altered zip fails the manifest", code, 1)
        check("the mismatch names sha256", "sha256" in (out + err).lower(), True)


def test_dir_rejects_dev_files():
    with tempfile.TemporaryDirectory() as tmp:
        pkg = Path(tmp) / "ToonAge"
        (pkg / "Core").mkdir(parents=True)
        (pkg / "Core" / "Init.lua").write_text("-- init\n", encoding="utf-8")
        body = "## Version: 2.0.0-dev.1\nCore/Init.lua\n"
        for name in REQUIRED_TOCS:
            (pkg / name).write_text(body, encoding="utf-8")
        code, _out, _err = run_checker("--dir", str(pkg))
        check("a complete folder passes", code, 0)
        (pkg / "Tools").mkdir()
        (pkg / "Tools" / "x.py").write_text("x\n", encoding="utf-8")
        code, out, err = run_checker("--dir", str(pkg))
        check("a folder with Tools fails", code, 1)
        check("the folder failure names Tools", "Tools" in (out + err), True)


def main():
    test_ignore_lists_keep_data()
    test_packaged_zip_has_every_toc_file()
    test_release_rules_and_manifest()
    test_dir_rejects_dev_files()
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
