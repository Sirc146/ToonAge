# ToonAge — Anniversary Edition

A TBC-era character advisor for WoW Classic Anniversary — stat caps, weapon
skill, cap-aware gear scoring, racials, and profession perks.

**Author:** SIRC · **Version:** 2.2.1-anniversary · **Interface:** `20506`

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by
> Blizzard Entertainment.

---

## Scope

Advisory only — there is no guide engine, navigation, or arrow in this build.
It's designed to run alongside a guide addon (this client also runs Dugi's
Guide Viewer Z); ToonAge handles the character-math side (caps, gear, racials,
professions) rather than questing/navigation.

Interface `20506` was confirmed against three other addons running on this
same client: `ElvUI_TBC.toc`, `ZygorGuidesViewerClassicTBCAnniv.toc`, and
`DugisGuideViewerZ.toc`.

## Multi-flavor architecture

As of 2026-09-10, `ToonAge.toc` was renamed to `ToonAge_TBC.toc` — Blizzard's
recognized suffix for Burning Crusade Classic & Anniversary Edition — as the
first step toward the standard multi-TOC pattern (one repo, one release, a
`.toc` per game flavor, each parsed only by its matching client). A new
`Core/Environment.lua` now detects the running flavor from `WOW_PROJECT_ID`
instead of Init.lua hardcoding it.

This does **not** mean ToonAge runs on Retail or Cataclysm/Mists Classic yet.
Only the API surface (frame/global names) can be papered over with a compat
shim; this addon's real content — TBC's specific talent trees, hit/expertise
caps, rotations, PvP data — is game-design data that would need its own
research and its own `Data/*.lua` set per additional flavor before a
`ToonAge_Cata.toc` or `ToonAge_Mainline.toc` would be more than an empty
shell. See `Core/Environment.lua`'s header comment for the full reasoning.

## Installing

Copy or clone the `ToonAge` folder into your addons directory:

```
World of Warcraft/_anniversary_/Interface/AddOns/ToonAge
```

Then `/reload`, or restart the client.

## Using it

`/ta` opens the main panel. Everything else is a shortcut into it:

| Command | |
|---|---|
| `/ta` | Open the panel (`/ta help` lists subcommands) |
| `/ta gear` · `talents` · `prof` | Jump straight to a tab |
| `/ta options` | Options panel |
| `/ta errors` | Recent errors — `copy` for a selectable window, `clear` to wipe |
| `/ta reset` | Reset settings (follow with `/reload`) |

Settings are saved per account in `ToonAgeDB`, with per-character data keyed by
`Name-Realm`.

## Privacy

Nothing is collected and nothing is transmitted — the addon has no network
access and no telemetry of any kind.

## Reporting a bug

Open an issue: https://github.com/Sirc146/ToonAge/issues

Please include what happened and the steps to reproduce it, the addon version
and WoW build (`/dump GetBuildInfo()`), and `/ta errors` output if anything
was logged.

## Source

This build is exported from the main ToonAge monorepo (see the `_ptr_`
install for the full source, docs, and dev tooling — including
`Docs/CLASSIC_ANNIVERSARY_BRIEF.md`, which covers this client specifically).
Contribution guidelines and coding conventions live there, not in this
deployed copy.

## License

Personal, non-commercial use. Free of charge and unobfuscated, per Blizzard's
UI Addon Development Policy.

Bundles `Libs/LibStub.lua` (Public Domain) where present.
