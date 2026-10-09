#!/usr/bin/env python3
"""UI strings stay ASCII, apart from the em dash and the middle dot.

Plain symbols (checks, crosses, pips, arrows, emoji) belong in |T textures
via ToonAge.Utils.Glyph, not in the string. Comments are skipped. Libs/ is
skipped. A UTF-8 sequence written as decimal escapes (\\226\\156\\147) is
decoded before the check, so a smuggled symbol still fails.

Allowed in string literals:
  U+2014 EM DASH
  U+00B7 MIDDLE DOT
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP = {"Libs", "Tools", "docs", "Docs", "Art", ".git"}
ALLOW = {"\u2014", "\u00B7"}

_results = []


def check(name, got, want=True):
    ok = got == want
    _results.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}")
        if got != want:
            print(f"          got: {got!r}")
    return ok


def iter_lua():
    for p in ROOT.rglob("*.lua"):
        rel = p.relative_to(ROOT)
        if any(part in SKIP for part in rel.parts):
            continue
        yield rel, p.read_text(encoding="utf-8")


def lex_strings(src):
    """Yield (start, end) of string literals. Comments are not strings."""
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            j = i + 2
            if j < n and src[j] == "[":
                k = j + 1
                eqs = 0
                while k < n and src[k] == "=":
                    eqs += 1
                    k += 1
                if k < n and src[k] == "[":
                    close = "]" + ("=" * eqs) + "]"
                    end = src.find(close, k + 1)
                    if end < 0:
                        return
                    i = end + len(close)
                    continue
            end = src.find("\n", j)
            i = n if end < 0 else end
            continue
        if c in ("'", '"'):
            j = i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == c:
                    j += 1
                    break
                if src[j] == "\n":
                    break
                j += 1
            yield i, j
            i = j
            continue
        if c == "[":
            k = i + 1
            eqs = 0
            while k < n and src[k] == "=":
                eqs += 1
                k += 1
            if k < n and src[k] == "[":
                close = "]" + ("=" * eqs) + "]"
                end = src.find(close, k + 1)
                if end < 0:
                    yield i, n
                    return
                yield i, end + len(close)
                i = end + len(close)
                continue
        i += 1


def decode_short(raw):
    q = raw[0]
    body = raw[1:]
    if body.endswith(q):
        body = body[:-1]
    out = []
    i = 0
    while i < len(body):
        if body[i] == "\\" and i + 1 < len(body):
            nch = body[i + 1]
            mapping = {
                "n": "\n", "r": "\r", "t": "\t", "a": "\a", "b": "\b",
                "f": "\f", "v": "\v", "\\": "\\", "'": "'", '"': '"',
            }
            if nch in mapping:
                out.append(mapping[nch])
                i += 2
                continue
            if nch == "\n":
                i += 2
                continue
            if nch.isdigit():
                j = i + 1
                while j < len(body) and j < i + 4 and body[j].isdigit():
                    j += 1
                out.append(chr(int(body[i + 1:j])))
                i = j
                continue
            out.append(nch)
            i += 2
            continue
        out.append(body[i])
        i += 1
    return "".join(out)


def decode_long(raw):
    i = 1
    while i < len(raw) and raw[i] == "=":
        i += 1
    body = raw[i + 1:]
    body = body[: -(i + 1)]
    if body.startswith("\n"):
        body = body[1:]
    return body


def recover_utf8(s):
    """Turn a run of Latin-1 bytes that is valid UTF-8 back into characters.

    Lua decimal escapes (\\226\\156\\147) decode to those bytes. They are the
    symbol, not three innocent codepoints.
    """
    out = []
    i = 0
    while i < len(s):
        o = ord(s[i])
        if o < 128 or o > 255:
            out.append(s[i])
            i += 1
            continue
        if o & 0xE0 == 0xC0:
            need = 2
        elif o & 0xF0 == 0xE0:
            need = 3
        elif o & 0xF8 == 0xF0:
            need = 4
        else:
            out.append(s[i])
            i += 1
            continue
        chunk = s[i:i + need]
        if len(chunk) < need or any(ord(c) > 255 for c in chunk):
            out.append(s[i])
            i += 1
            continue
        try:
            out.append(bytes(ord(c) for c in chunk).decode("utf-8"))
            i += need
        except UnicodeDecodeError:
            out.append(s[i])
            i += 1
    return "".join(out)


def offenders():
    found = []
    for rel, src in iter_lua():
        for a, b in lex_strings(src):
            raw = src[a:b]
            text = decode_long(raw) if raw.startswith("[") else decode_short(raw)
            text = recover_utf8(text)
            bad = sorted({ch for ch in text if ord(ch) > 127 and ch not in ALLOW})
            if bad:
                line = src.count("\n", 0, a) + 1
                shown = "".join(f"U+{ord(ch):04X}" for ch in bad)
                found.append(f"{rel}:{line} {shown}")
    return found


def test_no_plain_symbols():
    bad = offenders()
    check("no non-ASCII UI symbols outside em dash and middle dot", bad, [])


def test_glyph_helper():
    src = (ROOT / "Core" / "Utils.lua").read_text(encoding="utf-8")
    check("U.Glyph is defined", "function U.Glyph(name, color)" in src)
    for name in (
        "util_pip_8.tga",
        "util_pip_8_ring.tga",
        "util_chevron_16.tga",
        "util_minimize_16.tga",
        "util_check_16.tga",
        "util_cross_16.tga",
        "util_warn_16.tga",
        "util_star_16.tga",
        "util_menu_16.tga",
        "util_flight_16.tga",
        "util_square_16.tga",
    ):
        check(f"glyph table names {name}", name in src)


def main():
    test_glyph_helper()
    test_no_plain_symbols()
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
