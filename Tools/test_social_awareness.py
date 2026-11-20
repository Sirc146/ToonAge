#!/usr/bin/env python3
"""Social awareness must not read or keep a Battle.net account name.

The nearby list is session memory for a live party suggestion. It may show a
character name. It must not read an account name or a BattleTag, and it must
not keep an account id. A friend with no character name is recorded as Friend.

Usage:  python3 Tools/test_social_awareness.py [-v]
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERBOSE = "-v" in sys.argv
_res = []


def check(name, got, want=True):
    ok = got == want
    _res.append(ok)
    if not ok:
        print(f"[ FAIL ] {name}\n          got: {got!r} want: {want!r}")
    elif VERBOSE:
        print(f"[  ok  ] {name}")


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8").read()


def strip_comments(src):
    return "\n".join(re.sub(r"--.*$", "", line) for line in src.split("\n"))


src = read("Modules/Automation/SocialAwareness.lua")
code = strip_comments(src)
check("does not read an account name", "accountName" not in code)
check("does not read a BattleTag", "battleTag" not in code)
check("does not keep an account id", "bnetAccountID" not in code and "bnetID" not in code)

WORLD = r"""
ToonAge = { modules = {}, db = nil, LOG = { OUTPUT = 0 } }
function ToonAge:RegisterModule(name, mod) self.modules[name] = mod end
function ToonAge:Raw() end
ToonAge.Utils = { Glyph = function() return "" end }
function wipe(t) for k in pairs(t) do t[k] = nil end end
function GetRealZoneText() return "Elwynn Forest" end
function UnitLevel() return 20 end
function IsInGuild() return false end
function GetTime() return 0 end

ACCOUNT = "AccountLabel"
TAG = "TagHash"
CHAR = "CharLabel"
HAVE_CHAR = true

function BNGetNumFriends() return 1 end
C_BattleNet = {
    GetFriendNumGameAccounts = function() return 1 end,
    GetFriendAccountInfo = function()
        return {
            accountName = ACCOUNT,
            battleTag = TAG,
            bnetAccountID = 4242,
            gameAccountInfo = {
                isOnline = true,
                clientProgram = "WoW",
                areaName = "Elwynn Forest",
                characterLevel = 20,
                characterName = HAVE_CHAR and CHAR or nil,
            },
        }
    end,
}
"""


def boot():
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(WORLD)
    L.execute(read("Modules/Automation/SocialAwareness.lua"))
    return L, L.globals().ToonAge.modules.SocialAwareness


def fields(row):
    out = []
    if row is None:
        return out
    k = row.next
    # lupa tables iterate from Python via keys()
    return list(row.keys())


L, Social = boot()
Social.ScanNearbyPlayers(Social)
row = Social.nearbyFriends[1]
keys = fields(row)
check("a character name can be shown live", row.name, "CharLabel")
check("the live row has no account id", "bnetID" not in keys)
check("the live row is not the account name", row.name != "AccountLabel")
text = str(Social.GetSuggestion(Social))
check("the suggestion shows the character", "CharLabel" in text)
check("the suggestion omits the account name", "AccountLabel" not in text)
check("the suggestion omits the BattleTag", "TagHash" not in text)
check("scanning does not create a saved table", L.globals().ToonAge.db, None)

L.execute("HAVE_CHAR = false")
Social.ScanNearbyPlayers(Social)
row = Social.nearbyFriends[1]
text = str(Social.GetSuggestion(Social))
check("a missing character name becomes Friend", row.name, "Friend")
check("the fallback row has no account id", "bnetID" not in fields(row))
check("the fallback suggestion omits the account name", "AccountLabel" not in text)
check("the fallback suggestion omits the BattleTag", "TagHash" not in text)

passed, total = sum(_res), len(_res)
print(f"[{'OK' if passed == total else 'FAIL'}] {passed}/{total} assertions passed.")
sys.exit(0 if passed == total else 1)
