#!/usr/bin/env python3
"""Fail a release package that is not the zip we intend to publish.

The package must contain every file a TOC lists, all eight flavor TOCs,
and none of the dev paths (docs/, Docs/, AGENTS.md, Tools/, tests).
Pass --version to require that stamped version in every flavor TOC.
Pass --manifest to write a SHA-256 manifest after the checks pass.
Pass --require-zip-sha to fail when a file is not the manifest's zip.

    python3 Tools/check_release_zip.py ToonAge-2.0.0.zip
    python3 Tools/check_release_zip.py --version v2.0.0 --manifest release-manifest.json ToonAge-v2.0.0.zip
    python3 Tools/check_release_zip.py --require-zip-sha release-manifest.json ToonAge-v2.0.0.zip
    python3 Tools/check_release_zip.py --dir release/ToonAge
"""
import hashlib
import json
import sys
import zipfile
from pathlib import Path


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
FORBIDDEN_SEGMENTS = ("docs", "Docs", "Tools", "tests")
FORBIDDEN_NAMES = ("AGENTS.md",)


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


def forbidden_reason(name):
    parts = [part for part in name.replace("\\", "/").split("/") if part]
    if not parts:
        return None
    if parts[-1] in FORBIDDEN_NAMES:
        return name
    for part in parts:
        if part in FORBIDDEN_SEGMENTS:
            return name
    return None


def root_tocs(names):
    found = {}
    for name in names:
        parts = name.replace("\\", "/").split("/")
        if parts[-1] not in REQUIRED_TOCS or len(parts) > 2:
            continue
        found.setdefault(parts[-1], []).append(name)
    return found


def version_line(text):
    lines = [ln.strip() for ln in text.splitlines() if ln.strip().startswith("## Version:")]
    if len(lines) != 1:
        return None
    return lines[0]


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_names(entries, read_text, version):
    """entries is a list of (name, payload) for files. payload is bytes or None when unread."""
    present = {name for name, _payload in entries}
    problems = []
    for name, _payload in entries:
        reason = forbidden_reason(name)
        if reason:
            problems.append(f"dev file: {reason}")

    found = root_tocs(present)
    for toc in REQUIRED_TOCS:
        hits = found.get(toc, [])
        if len(hits) != 1:
            problems.append(f"missing TOC: {toc}" if not hits else f"duplicate TOC: {toc}")

    missing = []
    checked = 0
    for toc in sorted(name for name in present if name.lower().endswith(".toc")):
        text = read_text(toc)
        prefix = toc.rsplit("/", 1)[0] + "/" if "/" in toc else ""
        part, count = _missing(toc, text, present, prefix)
        missing.extend(part)
        checked += count
        if version is not None and Path(toc).name in REQUIRED_TOCS and len(found.get(Path(toc).name, [])) == 1:
            got = version_line(text)
            want = f"## Version: {version}"
            if got != want:
                problems.append(f"version mismatch: {toc}: {got or 'no ## Version line'}")
    problems.extend(missing)
    return problems, checked, found


def file_manifest(entries, read_bytes):
    files = []
    for name, payload in sorted(entries, key=lambda item: item[0]):
        if name.endswith("/"):
            continue
        data = payload if payload is not None else read_bytes(name)
        files.append({"path": name.replace("\\", "/"), "sha256": sha256_bytes(data)})
    return files


def write_manifest(path, version, zip_path, files):
    body = {
        "file_count": len(files),
        "files": files,
        "version": version,
        "zip_sha256": sha256_file(zip_path),
    }
    text = json.dumps(body, indent=2, sort_keys=True) + "\n"
    Path(path).write_text(text, encoding="utf-8")


def check_zip(path, version=None, manifest=None):
    with zipfile.ZipFile(path) as zf:
        names = [n.replace("\\", "/") for n in zf.namelist() if not n.endswith("/")]
        entries = [(name, None) for name in names]

        def read_text(name):
            return zf.read(name).decode("utf-8")

        def read_bytes(name):
            return zf.read(name)

        problems, checked, found = check_names(entries, read_text, version)
        files = file_manifest(entries, read_bytes) if manifest and not problems else None
    if manifest and not problems:
        write_manifest(manifest, version, path, files)
    return problems, checked, [name for names in found.values() for name in names]


def check_dir(pkg, version=None):
    pkg = Path(pkg)
    entries = []
    texts = {}
    blobs = {}
    for path in sorted(pkg.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(pkg).as_posix()
        data = path.read_bytes()
        entries.append((rel, data))
        blobs[rel] = data
        if rel.lower().endswith(".toc"):
            texts[rel] = data.decode("utf-8")
    problems, checked, found = check_names(entries, texts.get, version)
    return problems, checked, [name for names in found.values() for name in names]


def report(problems, checked, tocs):
    if problems:
        print(f"{len(problems)} release check(s) failed:", file=sys.stderr)
        for line in problems:
            print(f"  {line}", file=sys.stderr)
        return 1
    if not tocs:
        print("the package contains no TOC", file=sys.stderr)
        return 1
    print(f"{checked} TOC files present across {len(tocs)} TOC(s).")
    return 0


def require_zip_sha(manifest_path, zip_path):
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    want = manifest.get("zip_sha256")
    got = sha256_file(zip_path)
    if not want or got != want:
        print(f"zip sha256 mismatch: {got} != {want}", file=sys.stderr)
        return 1
    print(f"zip sha256 matches {got}")
    return 0


def main(argv):
    args = argv[1:]
    version = None
    manifest = None
    expect = None
    directory = None
    positional = []
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--version" and index + 1 < len(args):
            version = args[index + 1]
            index += 2
            continue
        if arg == "--manifest" and index + 1 < len(args):
            manifest = args[index + 1]
            index += 2
            continue
        if arg == "--require-zip-sha" and index + 1 < len(args):
            expect = args[index + 1]
            index += 2
            continue
        if arg == "--dir" and index + 1 < len(args):
            directory = args[index + 1]
            index += 2
            continue
        if arg.startswith("--"):
            print("usage: check_release_zip.py [--version VER] [--manifest FILE] <zip>", file=sys.stderr)
            print("       check_release_zip.py --require-zip-sha <manifest> <zip>", file=sys.stderr)
            print("       check_release_zip.py --dir <addon folder>", file=sys.stderr)
            return 2
        positional.append(arg)
        index += 1

    if expect is not None:
        if len(positional) != 1 or directory or manifest or version:
            print("usage: check_release_zip.py --require-zip-sha <manifest> <zip>", file=sys.stderr)
            return 2
        zip_path = Path(positional[0])
        if not zip_path.is_file() or not Path(expect).is_file():
            print("manifest and zip must both exist", file=sys.stderr)
            return 2
        return require_zip_sha(expect, zip_path)

    if directory is not None:
        if positional or manifest or expect:
            print("usage: check_release_zip.py --dir <addon folder>", file=sys.stderr)
            return 2
        pkg = Path(directory)
        if not pkg.is_dir():
            print(f"no such directory: {pkg}", file=sys.stderr)
            return 2
        return report(*check_dir(pkg, version))

    if len(positional) != 1:
        print("usage: check_release_zip.py [--version VER] [--manifest FILE] <zip>", file=sys.stderr)
        return 2
    path = Path(positional[0])
    if not path.is_file():
        print(f"no such zip: {path}", file=sys.stderr)
        return 2
    return report(*check_zip(path, version, manifest))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
