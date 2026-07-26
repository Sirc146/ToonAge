# ToonAge

A character scanner and leveling companion for World of Warcraft — gear,
talents, rotation, professions, pets, and weekly guidance in one panel.

**Author:** Chris · **Version:** 1.0.0 · **Interface:** `120007`, `120100` (Midnight)

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by
> Blizzard Entertainment.

---

## Installing

Copy or clone the `ToonAge` folder into your addons directory:

```
World of Warcraft/_ptr_/Interface/AddOns/ToonAge
```

Then `/reload`, or restart the client. Retail only — there is no Classic build.

## Using it

`/ta` opens the main panel. Everything else is a shortcut into it:

| Command | |
|---|---|
| `/ta` | Open the panel (`/ta help` lists subcommands) |
| `/ta gear` · `talents` · `rotation` · `prof` · `pets` · `weekly` · `guide` | Jump straight to a tab |
| `/ta options` | Options panel |
| `/ta layout` | Toggle Unified HUD ↔ Fragmented Windows |
| `/ta errors` | Recent errors — `copy` for a selectable window, `clear` to wipe |
| `/ta reset` | Reset settings (follow with `/reload`) |
| `/farm` · `/farmreset` | Farming session tracking |

Developer and data-capture commands: `/coord`, `/taquestscan`, `/tarecord`,
`/tateleports`, `/taweekly`, `/tadev`.

Settings are saved per account in `ToonAgeDB`, with per-character data keyed by
`Name-Realm`.

## Privacy

Nothing is collected and nothing is transmitted — the addon has no network
access and no telemetry of any kind. See [PRIVACY.md](PRIVACY.md).

## Reporting a bug

Open an issue: https://github.com/Sirc146/ToonAge/issues

Please include:

1. **What happened**, and the steps to reproduce it.
2. **Addon version** and **WoW build** (`/dump GetBuildInfo()`).
3. **`/ta errors` output** if anything was logged — it has a copy view, so you
   can paste it directly.
4. A screenshot, for anything visual.

If a report would contain something you'd rather not post publicly, say so in
the issue and leave the details out; saved-variables files can include
character and realm names.

## Contributing

Pull requests welcome. Before opening one:

- Read [`.rules.md`](.rules.md) — Lua style, module contract, naming, event and
  performance conventions.
- Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the module system, event
  dispatch and data layer fit together.
- **Verify API claims against a live client.** Blizzard removed APIs in 12.1.0
  that failed *silently* rather than erroring, because the calls sat behind
  existence checks. `.rules.md` records what's confirmed dead and what's still
  unverified. A `/dump` costs nothing; a guessed signature costs a session.
- Say how you tested it. "Written but not executed" is a valid note, and a
  useful one.

## Project docs

| File | |
|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Load order, module contract, event dispatch, data layer |
| [`.rules.md`](.rules.md) | Coding style, conventions, verified/removed APIs, dev tooling |
| [`TODO.md`](TODO.md) | Working queue, in priority order |
| [`IMPROVEMENT_PLAN.md`](IMPROVEMENT_PLAN.md) | Strategic roadmap |
| [`.bootstrap.md`](.bootstrap.md) | Orientation, and the licensing rules for reference addons |

`Tools/` holds developer-side Python that generates static data from Blizzard's
Game Data API. It is never loaded by the game. See `.rules.md` for setup.

## License

Personal, non-commercial use. Free of charge and unobfuscated, per Blizzard's
UI Addon Development Policy. See [LICENSE.md](LICENSE.md).

Bundles `Libs/LibStub.lua` (Public Domain).
