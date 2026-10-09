#!/usr/bin/env python3
"""Fail when a TOC lists a file the release package does not contain.

Every *.toc at the addon root is read. A non-comment line that names a
.lua or .xml file must be in the zip (or in the unpacked addon folder).
Metadata lines (## Title and the rest) are not files.

    python3 Tools/check_release_zip.py ToonAge-2.0.0.zip
    python3 Tools/check_release_zip.py --dir release/ToonAge
"""
import sys
import zipfile
from pathlib import Path


def listed_files(text):
    out = []
    for ln in text.splitlines():
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        token = s.split("[", 1)[0].strip().replace("\\", "/")
        while token.startswith("./"):
            token = token[2:]
        if token.lower().endswith((".lua", ".xml")):
            out.append(token)
    return out


def _missing(toc_name, text, present, prefix):
    missing = []
    checked = 0
    for rel in listed_files(text):
        checked += 1
        full = prefix + rel
        if full not in present:
            missing.append(f"{toc_name}: {rel}")
    return missing, checked


def check_zip(path):
    with zipfile.ZipFile(path) as zf:
        names = [n.replace("\\", "/") for n in zf.namelist() if not n.endswith("/")]
        present = set(names)
        tocs = [n for n in names if n.lower().endswith(".toc") and n.count("/") == 1]
        if not tocs:
            tocs = [n for n in names if n.lower().endswith(".toc") and "/" not in n]
        missing = []
        checked = 0
        for toc in sorted(tocs):
            text = zf.read(toc).decode("utf-8")
            prefix = toc.rsplit("/", 1)[0] + "/" if "/" in toc else ""
            part, n = _missing(toc, text, present, prefix)
            missing.extend(part)
            checked += n
        return missing, checked, tocs


def check_dir(pkg):
    pkg = Path(pkg)
    tocs = sorted(p for p in pkg.glob("*.toc") if p.is_file())
    present = set()
    for path in pkg.rglob("*"):
        if path.is_file():
            present.add(path.relative_to(pkg).as_posix())
    missing = []
    checked = 0
    for toc in tocs:
        text = toc.read_text(encoding="utf-8")
        part, n = _missing(toc.name, text, present, "")
        missing.extend(part)
        checked += n
    return missing, checked, [t.name for t in tocs]


def report(missing, checked, tocs):
    if not tocs:
        print("the package contains no TOC", file=sys.stderr)
        return 1
    if missing:
        print(f"{len(missing)} TOC file(s) missing from the package:", file=sys.stderr)
        for line in missing:
            print(f"  {line}", file=sys.stderr)
        return 1
    print(f"{checked} TOC files present across {len(tocs)} TOC(s).")
    return 0


def main(argv):
    if len(argv) == 2 and argv[1] != "--dir":
        path = Path(argv[1])
        if not path.is_file():
            print(f"no such zip: {path}", file=sys.stderr)
            return 2
        return report(*check_zip(path))
    if len(argv) == 3 and argv[1] == "--dir":
        pkg = Path(argv[2])
        if not pkg.is_dir():
            print(f"no such directory: {pkg}", file=sys.stderr)
            return 2
        return report(*check_dir(pkg))
    print("usage: check_release_zip.py <zip> | --dir <addon folder>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
