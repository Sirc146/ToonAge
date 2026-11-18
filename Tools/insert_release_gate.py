#!/usr/bin/env python3
"""Insert the pre-upload gate into a pinned BigWigs packager release.sh.

The packager writes the zip and then uploads it in the same process.
The gate runs after the archive exists and before that upload, so a
failed check exits before CurseForge, Wago, or the packager's own
GitHub release. Patching twice leaves the script unchanged.
"""
import sys
from pathlib import Path


ANCHOR = "if [[ -z $skip_upload && -n $archive && -s $archive ]]; then\n"
MARKER = "TOONAGE_PRE_UPLOAD_GATE"

GATE = """# TOONAGE_PRE_UPLOAD_GATE
# Runs Tools/check_release_zip.py on this zip. The same file is uploaded below.
if [[ -z "${TOONAGE_VERSION}" || -z "${TOONAGE_MANIFEST}" || -z "${TOONAGE_CHECKER}" ]]; then
	echo "TOONAGE_VERSION, TOONAGE_MANIFEST, and TOONAGE_CHECKER are required." >&2
	exit 1
fi
if [[ -z "${archive:-}" || ! -s "${archive}" ]]; then
	echo "The packager did not leave a zip to check." >&2
	exit 1
fi
if ! python3 "${TOONAGE_CHECKER}" --version "${TOONAGE_VERSION}" --manifest "${TOONAGE_MANIFEST}" "${archive}"; then
	echo "Release zip failed the pre-upload check. Nothing was uploaded." >&2
	exit 1
fi

"""


def insert_gate(text):
    if MARKER in text:
        return text, None
    count = text.count(ANCHOR)
    if count != 1:
        return None, "anchor" if count == 0 else "anchor"
    return text.replace(ANCHOR, GATE + ANCHOR, 1), None


def main(argv):
    if len(argv) != 2:
        print("usage: insert_release_gate.py <release.sh>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.is_file():
        print(f"no such file: {path}", file=sys.stderr)
        return 2
    updated, error = insert_gate(path.read_text(encoding="utf-8"))
    if error:
        print(f"refusing to patch: upload anchor count is not 1 ({error})", file=sys.stderr)
        return 1
    path.write_text(updated, encoding="utf-8")
    print(f"pre-upload gate is in place ({MARKER})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
