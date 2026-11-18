#!/usr/bin/env python3
"""Insert the pre-upload gate into a pinned BigWigs packager release.sh.

The packager writes the zip and then uploads it in the same process.
The gate runs after the archive exists. On a tag push it publishes that
zip to GitHub and checks the downloaded asset before CurseForge or Wago.
A failed check exits before any store upload. Patching twice leaves the
script unchanged.
"""
import sys
from pathlib import Path


ANCHOR = "if [[ -z $skip_upload && -n $archive && -s $archive ]]; then\n"
MARKER = "TOONAGE_PRE_UPLOAD_GATE"

GATE = """# TOONAGE_PRE_UPLOAD_GATE
# Runs Tools/check_release_zip.py on this zip. The same file is uploaded below.
# On a tag push, the GitHub release is created and its asset is checked
# before CurseForge or Wago see the file. A failure here exits first.
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
if [[ "${GITHUB_EVENT_NAME:-}" == "push" ]]; then
	tag="${GITHUB_REF_NAME}"
	name="$(basename "${archive}")"
	if [[ "${name}" != "ToonAge-${TOONAGE_VERSION}.zip" ]]; then
		echo "The zip name does not match the stamped version. Store uploads were not started." >&2
		exit 1
	fi
	if [[ -z "${TOONAGE_RELEASE_JSON:-}" || ! -s "${TOONAGE_RELEASE_JSON}" ]]; then
		echo "release.json is missing. Store uploads were not started." >&2
		exit 1
	fi
	gh_args=(--title "${tag}" --generate-notes)
	case "${GITHUB_REF:-}" in
		*dev*|*alpha*|*beta*|*test*) gh_args+=(--prerelease) ;;
	esac
	released=0
	if gh release view "${tag}" >/dev/null 2>&1; then
		if gh release upload "${tag}" "${archive}" "${TOONAGE_MANIFEST}" "${TOONAGE_RELEASE_JSON}" --clobber; then
			released=1
		fi
	else
		if gh release create "${tag}" "${archive}" "${TOONAGE_MANIFEST}" "${TOONAGE_RELEASE_JSON}" "${gh_args[@]}"; then
			released=1
		fi
	fi
	if [[ "${released}" -ne 1 ]]; then
		echo "GitHub release failed. Store uploads were not started." >&2
		exit 1
	fi
	dest="$(mktemp -d)"
	ok=0
	for _try in 1 2 3 4 5; do
		if gh release download "${tag}" --repo "${GITHUB_REPOSITORY}" --pattern "${name}" --dir "${dest}" --clobber; then
			ok=1
			break
		fi
		sleep 5
	done
	if [[ "${ok}" -ne 1 ]]; then
		echo "The GitHub release zip was not available to verify. Store uploads were not started." >&2
		rm -rf "${dest}"
		exit 1
	fi
	if ! python3 "${TOONAGE_CHECKER}" --require-zip-sha "${TOONAGE_MANIFEST}" "${dest}/${name}"; then
		echo "The GitHub release zip does not match the manifest. Store uploads were not started." >&2
		rm -rf "${dest}"
		exit 1
	fi
	rm -rf "${dest}"
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
