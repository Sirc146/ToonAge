# ToonAge

One addon, every version of World of Warcraft. Character, gear, rotation,
professions, pets and weekly guidance in a single panel — with the game-rule
content researched separately for each expansion instead of guessed from
another one.

**Version:** 2.0.0 · **Author:** SIRC

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by
> Blizzard Entertainment.

---

## Supported clients

One folder, named `ToonAge`, works everywhere. WoW picks the matching `.toc`
and the addon names the client it detected in the addon list.

| Client | Addon list shows | State |
|---|---|---|
| Retail (Midnight) | ToonAge Midnight | Full feature set |
| TBC Classic / Anniversary | ToonAge TBC | Full advisory set — stat caps, weapon skill, cap-aware gear |
| Mists of Pandaria Classic | ToonAge Mists | Built, not yet verified on a live client |
| Classic Era | ToonAge Classic Era | Loads, core only |
| Cataclysm Classic | ToonAge Cataclysm | Loads, core only |
| Wrath Classic | ToonAge Wrath | Loads, core only |
| WoW Forever | ToonAge Forever | Loads, core only |

**"Core only"** means the engine loads, captures errors and reports its own
state, and gives no advice at all. That is deliberate: Midnight's gear scores
and rotations are wrong for a Vanilla-era character, and wrong advice is worse
than none. Those flavors become full products when their `Data/<Flavor>/` is
researched, not before.

WoW Forever (beta, folder `_classic_beta_`) is the newest case: it reports
`WOW_PROJECT_MAINLINE` with interface `16001` — Vanilla-era content on
Mainline's API — so it is detected by interface number rather than project id.

## Installing

Put the `ToonAge` folder in the AddOns directory of whichever client you play:

```
World of Warcraft\_retail_\Interface\AddOns\ToonAge\ToonAge.toc
World of Warcraft\_anniversary_\Interface\AddOns\ToonAge\ToonAge.toc
World of Warcraft\_classic_beta_\Interface\AddOns\ToonAge\ToonAge.toc
```

The folder must be named exactly `ToonAge`, with the `.toc` files directly
inside it. Extracting a release zip into a folder named after the zip is the
usual mistake — WoW will not see the addon.

Then `/reload`, or restart the client.

## Using it

`/ta` opens the main panel; every other command is a shortcut into it. Tabs
and buttons cover the same ground, so nothing requires typing.

| Command | |
|---|---|
| `/ta` | Open the panel (`/ta help` lists subcommands) |
| `/ta gear` · `talents` · `rotation` · `prof` · `pets` · `weekly` · `guide` | Jump to a tab |
| `/ta options` | Settings |
| `/ta layout` | Unified HUD ↔ fragmented windows |
| `/ta errors` | Recent errors — `copy` for a selectable window, `clear` to wipe |
| `/ta health` | What loaded, what was skipped, and why |
| `/ta reset` | Reset settings (follow with `/reload`) |

Settings are stored per account in `ToonAgeDB`, with per-character data keyed
by `Name-Realm`, and migrated forward automatically when the schema changes.

## Playing alongside other addons

ToonAge steps back rather than competing. When Zygor is loaded it stops
auto-accepting quests, picking quest rewards, drawing its arrow and equipping
looted upgrades, so the two don't fight over the same actions. That's a toggle
at the top of Settings → Quest Automation if you'd rather ToonAge kept doing
those jobs.

## Privacy

ToonAge has no network access. It cannot send anything anywhere, and it stores
your settings and character data only in your own `ToonAgeDB` saved-variables
file.

The one exception is optional usage reporting, and it needs three things to be
true at once before a single value is recorded:

1. You have the **Wago App** installed, with its data sharing switched on. The
   Wago App's own addon does the recording and the uploading — ToonAge just
   writes values into it, and with the app absent those calls do nothing.
2. The build carries a Wago project id in its `.toc`.
3. You have not turned it off in Settings → "Share anonymous usage stats".

What it records is fixed and coarse: which game version you are on, whether the
unified or fragmented layout is in use, whether auto-quest, auto-equip and
cutscene skip are enabled, whether Zygor is installed and whether ToonAge is
standing down for it, how many modules loaded, and how many errors were caught
this session. Booleans and counts, nothing else.

What it never records: character, realm, guild or account names, your spec,
gear, quests, coordinates, or anything else that could identify you or your
session. `Tools/test_analytics.py` enforces that — it fails the build if a
recorded key contains an identifying word or a recorded value is a string.

Everything is in [`Core/Analytics.lua`](Core/Analytics.lua), which is short and
worth reading if this matters to you. `/ta health` reports whether reporting is
on or off, and why.

## Reporting a bug

Open an issue: https://github.com/Sirc146/ToonAge/issues

Include:

1. **What happened**, and how to reproduce it.
2. **Addon version** and **client** (`/dump GetBuildInfo()`).
3. **`/ta errors` output** if anything was logged — it has a copy view.
4. A screenshot for anything visual.

Saved-variables files contain character and realm names; leave out anything
you'd rather not post publicly and say so in the issue.

## For developers

```
Core/        Shared engine: flavor detection, profiles, events, UI shell, stats
Data/        Per-flavor game-rule data (Retail, TBC, Mists, Shared)
Modules/     Features, grouped by area; per-flavor trees under Modules/TBC, /Mists
Libs/        Bundled libraries (LibStub, Public Domain)
Tools/       Python: data generators and the test suite — never loaded by the game
Docs/        Architecture, data sources, audits, tester setup
```

Two independent gates decide what runs: the flavor profile in
`Core/Profile.lua` ("is this module part of this client's product?") and
`Core/ApiGuard.lua` ("does the running client actually expose what it needs?").
A module must pass both. The `.toc` set is the packaging backstop for the same
rule, so a Classic install never ships Retail data.

Run the test suite before opening a pull request:

```
python Tools/test_toc_set.py      # one per area; all of Tools/test_*.py should pass
```

Also read [`.rules.md`](.rules.md) for style and conventions, and
[`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) for load order, the module
contract and event dispatch. Verify API claims against a live client rather
than assuming — Blizzard removed calls in 12.1 that fail silently behind
existence checks. Saying "written but not executed" in a PR is fine, and
useful.

## Releases

Tagging a version builds and publishes the zip:

```
git tag v2.0.0
git push origin v2.0.0
```

Tags containing `test`, `beta`, `alpha` or `dev` publish as pre-releases.
Testers can point WowUp at this repository with Install from URL; see
[`Docs/TESTER_SETUP.md`](Docs/TESTER_SETUP.md).

Branch history from before the unified trunk is preserved as `archive/*` tags.

## License

Personal, non-commercial use. Free of charge and unobfuscated, per Blizzard's
UI Addon Development Policy. See [LICENSE.md](LICENSE.md).

Bundles `Libs/LibStub.lua` (Public Domain).
