# ToonAge — Classic Edition

A leveling companion for WoW Classic — navigation, gear scoring, and quest
guidance.

**Author:** Chris · **Version:** 2.0.0-classic · **Interface:** `50504`

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by
> Blizzard Entertainment.

---

## Installing

Copy or clone the `ToonAge` folder into your addons directory:

```
World of Warcraft/_classic_/Interface/AddOns/ToonAge
```

Then `/reload`, or restart the client.

## Using it

`/ta` opens the main panel. Everything else is a shortcut into it:

| Command | |
|---|---|
| `/ta` | Open the panel (`/ta help` lists subcommands) |
| `/ta gear` · `guide` | Jump straight to a tab |
| `/ta options` | Options panel |
| `/ta errors` | Recent errors — `copy` for a selectable window, `clear` to wipe |
| `/ta reset` | Reset settings (follow with `/reload`) |
| `/farm` · `/farmreset` | Farming session tracking |

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
install for the full source, docs, and dev tooling). Contribution guidelines
and coding conventions live there, not in this deployed copy.

## License

Personal, non-commercial use. Free of charge and unobfuscated, per Blizzard's
UI Addon Development Policy.

Bundles `Libs/LibStub.lua` (Public Domain).
