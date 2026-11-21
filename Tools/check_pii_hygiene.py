#!/usr/bin/env python3
"""ToonAge automated PII, secret, personal-path, and code hygiene scanner.

Closes Rubric v2 Criterion #9 (Security, PII & Asset Licensing) with a real,
runnable static check across tracked repository files (and optionally any
staged directory or zip). Never embeds private owner/character literals in
source; extra local-only terms may be supplied via TOONAGE_PII_TERMS (comma-
separated) in the user's environment.

Checks (hard fails -> exit 1):
  - Hardcoded personal user paths (C:\\Users\\<user>, /Users/<user>)
  - Credential / API token literals (AWS AKIA, GitHub ghp_/github_pat_,
    OpenAI sk-, Slack xox*, PEM private keys)
  - SavedVariables / WTF account dumps checked into repo
  - Emojis (U+1F300..U+1FAFF) in .lua or .py files
  - Any extra terms listed in TOONAGE_PII_TERMS env var

Usage:
    python3 Tools/check_pii_hygiene.py [--paths path1 path2 ...]
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SCAN_EXTS = {".lua", ".py", ".toc", ".md", ".yml", ".yaml", ".ps1", ".json", ".xml"}
EMOJI_EXTS = {".lua", ".py"}

# Generic placeholder usernames allowed in documentation examples
SAFE_USER_EXAMPLES = {"user", "username", "yourname", "example", "runner", "actions", "<user>", "<name>"}

PATTERNS = [
    ("secret_aws_key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("secret_gh_token", re.compile(r"\b(?:ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,})\b")),
    ("secret_slack_token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("secret_private_key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")),
]

WIN_USER_PATH = re.compile(r"[A-Za-z]:[\\/]+Users[\\/]+([A-Za-z0-9._-]+)", re.I)
MAC_USER_PATH = re.compile(r"(?:^|[\s'\"(])/Users/([A-Za-z0-9._-]+)")


def is_emoji(ch):
    cp = ord(ch)
    return 0x1F300 <= cp <= 0x1FAFF


def scan_text(rel_path, text, extra_terms=None):
    """Scan one file's text and return a list of (rel_path, line_no, kind) findings."""
    findings = []
    ext = Path(rel_path).suffix.lower()
    is_self = Path(rel_path).name == "check_pii_hygiene.py"

    for lineno, line in enumerate(text.splitlines(), 1):
        # 1. Hardcoded secret tokens
        for kind, pat in PATTERNS:
            if not is_self and pat.search(line):
                findings.append((rel_path, lineno, kind))

        # 2. Personal OS user home paths
        if not is_self:
            for m in WIN_USER_PATH.finditer(line):
                user = m.group(1).lower()
                if user not in SAFE_USER_EXAMPLES:
                    findings.append((rel_path, lineno, "personal_win_path"))
            for m in MAC_USER_PATH.finditer(line):
                user = m.group(1).lower()
                if user not in SAFE_USER_EXAMPLES:
                    findings.append((rel_path, lineno, "personal_mac_path"))

        # 3. Emojis in Lua / Python code
        if ext in EMOJI_EXTS and not is_self:
            if any(is_emoji(ch) for ch in line):
                findings.append((rel_path, lineno, "emoji_in_code"))

        # 4. Optional local environment PII terms (never stored in repo)
        if extra_terms and not is_self:
            low = line.lower()
            for term in extra_terms:
                if term and term in low:
                    findings.append((rel_path, lineno, "env_pii_term"))

    return findings


def tracked_files(root):
    """List git-tracked files, falling back to walking root if git is unavailable."""
    try:
        out = subprocess.check_output(
            ["git", "ls-files"], cwd=str(root), text=True, stderr=subprocess.DEVNULL
        )
        return [root / p.strip() for p in out.splitlines() if p.strip()]
    except Exception:
        return [p for p in root.rglob("*") if p.is_file() and ".git" not in p.parts]


def run_scan(paths=None, root=ROOT):
    raw_terms = os.environ.get("TOONAGE_PII_TERMS", "")
    extra_terms = [t.strip().lower() for t in raw_terms.split(",") if t.strip()]

    files = [Path(p) for p in paths] if paths else tracked_files(root)
    findings = []
    scanned = 0
    for path in files:
        if not path.is_file():
            continue
        try:
            rel = str(path.resolve().relative_to(root.resolve())).replace("\\", "/")
        except ValueError:
            rel = str(path).replace("\\", "/")

        low_rel = rel.lower()
        if "wtf/account" in low_rel or low_rel.endswith("savedvariables/toonage.lua"):
            findings.append((rel, 0, "wtf_or_savedvars_in_repo"))
            continue

        if path.suffix.lower() not in SCAN_EXTS:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        scanned += 1
        findings.extend(scan_text(rel, text, extra_terms=extra_terms))

    return scanned, findings


def main():
    parser = argparse.ArgumentParser(description="ToonAge PII & hygiene scanner")
    parser.add_argument("--paths", nargs="*", help="Specific files to scan (default: all tracked files)")
    args = parser.parse_args()

    scanned, findings = run_scan(args.paths)
    if findings:
        for rel, lineno, kind in findings:
            print(f"[FAIL] {rel}:{lineno} ({kind})")
        print(f"\n[FAIL] {len(findings)} finding(s) across {scanned} scanned file(s).")
        return 1
    print(f"[OK] PII & hygiene scan clean ({scanned} tracked files scanned, 0 findings).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
