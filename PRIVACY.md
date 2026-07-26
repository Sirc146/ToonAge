# Privacy

**Addon:** ToonAge
**Last reviewed:** 2026-07-26

---

## The short version

**ToonAge collects nothing and transmits nothing.** Everything it stores stays
in your own World of Warcraft installation, on your own machine.

This is not only a policy choice. World of Warcraft's addon environment has no
network access — no HTTP, no sockets, no external I/O of any kind. An addon
*cannot* send your data anywhere, and ToonAge contains no code that tries.

---

## What is stored, and where

Everything lives in the game's normal saved-variables file:

```
World of Warcraft/_ptr_/WTF/Account/<ACCOUNT>/SavedVariables/ToonAge.lua
```

It holds your preferences, UI positions, per-character notes and progress,
module on/off toggles, and a rolling error log capped at the most recent 200
entries. That file is written by the game, not uploaded by the addon.

To erase it, delete the file, or use `/ta reset` in-game followed by `/reload`.

## What is not present

For the avoidance of doubt, none of the following exist in ToonAge:

- No telemetry, analytics, or usage metrics — not even opt-in.
- No crash or error reporting to any server. The error log is local, viewable
  with `/ta errors`, and goes nowhere unless you choose to copy and paste it.
- No cloud sync, no accounts, no external servers, no uploads.
- No advertising, tracking, or third-party SDKs.

If any of that ever changes, it will be disclosed here and will be opt-in.

## Other players

ToonAge reads only what the game already exposes to addons. It does not record
or transmit other players' information.

A party-sync feature using Blizzard's in-game addon-message channel is
**planned but not built** (see `ARCHITECTURE.md`). If it ships, it will send
only guide progress, only to your own party, and only over Blizzard's own
channel — never to a third party. This document will be updated before that
happens, not after.

## Sharing something deliberately

If you copy an export string, an error log, or your saved-variables file and
send it to someone — for a bug report, for example — that is your action, and
what you share is whatever you chose to share. Saved variables can include
character names and realm names, so look before you paste.

## Developer tooling

The Python scripts in `Tools/` talk to Blizzard's Game Data API from a
developer's own machine, using that developer's own API credentials, to
generate static data files. They are not part of the addon, are never loaded by
the game, and involve no player data — the Game Data API serves game reference
data only, and the Profile API is not used. Nothing about this touches an
end user's installation.

---

Questions: https://github.com/Sirc146/ToonAge/issues
