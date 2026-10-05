# ToonAge

One addon, every version of World of Warcraft. Character, gear, talents,
rotation, professions, pets and PvP in one panel, with the game-rule content
researched separately for each expansion instead of borrowed from another one.

**Version:** see [Releases](https://github.com/Sirc146/ToonAge/releases). A
release stamps its tag into the `.toc`. · **Author:** Sirc

> Unofficial fan project. Not affiliated with, endorsed by, or sponsored by
> Blizzard Entertainment.

---

## Supported clients

One `ToonAge` folder carries a `.toc` for every client. WoW picks the one that
matches, and the addon list shows which edition loaded.

| Client | Addon list shows | What you get |
|---|---|---|
| Retail (Midnight) | ToonAge Retail | Character, Gear, Talents, Rotation, Delves, Weekly, Professions, Pets\*, Guide\*\* |
| TBC Anniversary | ToonAge TBC | Character, Stat Caps, Gear, Talents, Rotation, Spells, Weapons, Racials, Professions, Pets\*, PvP |
| Mists of Pandaria Classic | ToonAge Mists | Character, Gear, Pet Care\* (more in progress) |
| WoW Forever (beta) | ToonAge Forever | Character, Gear, Talents, Spells, Pets\*, PvP, Scrolls, Casts, Harvest. These are readouts of what the client itself reports. |
| Classic Era | ToonAge Classic Era | Core engine only |
| Cataclysm Classic | ToonAge Cataclysm | Core engine only |
| Wrath Classic | ToonAge Wrath | Core engine only |

\* Shown only for classes that keep a pet (Hunter, Warlock, and on Mists also
Frost Mage and Unholy Death Knight), or while a pet is out.
\*\* Shown only when a loaded guide has steps.

**Core engine only** means the addon loads, captures errors and reports its
own state, and gives no advice at all. That is deliberate. Retail's gear scores
and rotations are wrong for a Classic character, and wrong advice is worse than
none.

If the client ever loads another edition's file list, ToonAge stops every
feature and says so in chat ("This is a … client but the … build loaded"). It
won't run the wrong product quietly.

## Installing

**WowUp:** *Get Addons → Install from URL* →
`https://github.com/Sirc146/ToonAge`. WowUp reads the release's
`release.json` and installs the zip on Retail, PTR, Classic Era, TBC
Anniversary and Mists Classic. It prefers stable releases over pre-releases.

**Wago App:** search for ToonAge.

**By hand:** download the zip from
[Releases](https://github.com/Sirc146/ToonAge/releases) and extract it so the
folder is exactly `Interface\AddOns\ToonAge`, with the `.toc` files directly
inside it. Extracting into a folder named after the zip is the usual mistake;
WoW won't see the addon.

**WoW Forever (beta):** loading from the release zip is still being verified.
If ToonAge prints the "… build loaded" message on Forever, the client picked
another edition's file list. Please report it (see below).

Restart the client after installing; a `/reload` doesn't pick up new `.toc`
files.

## Using it

`/ta` opens the main panel; every command is a shortcut into it, so nothing
requires typing.

| Command | |
|---|---|
| `/ta` | Open the panel (`/ta help` lists everything) |
| `/ta options` | Settings (also the gear icon in the title bar) |
| `/ta toggle` | Turn individual modules on or off |
| `/ta layout` | Unified HUD ↔ fragmented windows |
| `/ta errors` | Recent errors: `copy` for a selectable window, `clear` to wipe |
| `/ta health` | What loaded, what was skipped, and why |
| `/ta test` or `/tatest` | Self-test (see below) |
| `/ta safemode` | Start with only the core modules, for troubleshooting |
| `/ta reset` | Reset settings (follow with a reload) |

Settings are stored per account in `ToonAgeDB`, with per-character data keyed
by `Name-Realm`, and migrated forward automatically when the schema changes.

### Self-test

The **Self-test** button in the title bar runs the addon's own checks on the
client you're playing: client detection, which modules loaded and why, which
game functions exist, whether every tab draws, and whether redraws leak
frames. The same checks run from `/ta test`, and from `/tatest`, which works
even if the addon failed partway through loading. The button shows on
development builds, or after `/ta debug`.

The report opens in a copyable window and is also saved to
`ToonAgeDB.selfTest` in your SavedVariables.

## Playing alongside other addons

ToonAge steps back rather than competing. When Zygor is loaded it stops
auto-accepting quests, picking quest rewards, drawing its arrow and equipping
looted upgrades, so the two don't fight over the same actions. If you'd rather
ToonAge kept doing those jobs, there's a toggle at the top of Settings → Quest
Automation.

## Privacy

ToonAge has no network access. It cannot send anything anywhere, and it stores
your settings and character data only in your own `ToonAgeDB` saved-variables
file.

The one exception is optional usage reporting, and it needs three things to be
true at once before a single value is recorded:

1. You have the **Wago App** installed, with its data sharing switched on. The
   Wago App's own addon does the recording and the uploading. ToonAge just
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
session. `Tools/test_analytics.py` enforces that: it fails the build if a
recorded key contains an identifying word or a recorded value is a string.

Everything is in [`Core/Analytics.lua`](Core/Analytics.lua), which is short and
worth reading if this matters to you. `/ta health` reports whether reporting is
on or off, and why.

## Reporting a bug

Open an issue: https://github.com/Sirc146/ToonAge/issues

Include:

1. **What happened**, and how to reproduce it.
2. **Client and addon version.** Both are in the panel's title bar.
3. **`/ta errors copy`** if anything was logged, and the **Self-test** report
   (copy it from its window).
4. A screenshot for anything visual.

Saved-variables files contain character and realm names; leave out anything
you'd rather not post publicly and say so in the issue.

## For developers

```
Core/        Shared engine: client detection, profiles, events, UI shell, stats
Data/        Per-client game-rule data (Retail, TBC, Mists, Forever, Shared)
Modules/     Features by area; per-client trees under Modules/TBC, /Mists, /Forever
Libs/        Bundled libraries (LibStub, Public Domain)
Tools/       Python tests and data generators, PowerShell build/repo scripts.
             Never loaded by the game.
Docs/        Architecture, data sources, audits, tester setup
```

**What runs where.** Each client's `.toc` decides what physically loads, and
the client's profile in `Core/Profile.lua` decides what may start. A module
must be in both. `Core/ApiGuard.lua` probes every game function the build
calls and reports what the running client lacks (`/ta health`, Self-test).
Gating modules on that report is planned, not done yet.

**Tests.** `python -m pip install -r Tools/requirements.txt` (luaparser and
lupa), then every `Tools/test_*.py` should pass. CI runs them all on each push.
Read [`.rules.md`](.rules.md) for conventions and
[`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) for load order, the module
contract and event dispatch. Verify API claims on a live client rather than
assuming. Blizzard removes calls that then fail silently behind existence
checks, and each client differs.

**Local builds (Windows, PowerShell).**

| Script | Does |
|---|---|
| `Tools\build_flavors.ps1` | Builds one clean folder per client from its `.toc`. `-Install` copies them into each WoW client; `-Check` says whether each install matches the source |
| `Tools\preflight.ps1` | Backs up SavedVariables and runs `-Check` before a test session |
| `Tools\build_release_layout.ps1` | Builds exactly what the release zip contains. `-InstallTo all` installs it into every client, to test what WowUp/Wago users get |
| `Tools\save_day.ps1` | After testing: commits, snapshots each tested client's build to its `live/` branch, pushes to the backup and (`-PushOrigin`) GitHub |
| `Tools\repo_status.ps1` | Read-only: is everything committed, pushed and installed? |

**Branches.** `main` is the source. `live/retail`, `live/forever`,
`live/anniversary`, `live/mists` and `live/classic-era` each hold the exact
built folder last tested on that client, one commit per save. Don't check
them out; they replace your working folder with build files. History from
before the unified source is kept as `archive/*` tags.

## Releases

Pushing a `v*` tag builds the zip, publishes a GitHub release with
`release.json` (for WowUp) and uploads to Wago.

```
git tag -a v2.0.4 -m "..."
git push origin v2.0.4
```

or `Tools\save_day.ps1 -Tag v2.0.4 -PushOrigin`, which pushes that one tag.

- **Push tags one at a time.** GitHub starts no workflows when more than three
  tags arrive in one push.
- Tags containing `test`, `beta`, `alpha` or `dev` publish as pre-releases,
  and WowUp prefers stable releases.
- The Wago upload needs the `WAGO_API_TOKEN` repository secret; without it
  that job skips itself.

Testers: see [`Docs/TESTER_SETUP.md`](Docs/TESTER_SETUP.md).

## License

Personal, non-commercial use. Free of charge and unobfuscated, per Blizzard's
UI Addon Development Policy. See [LICENSE.md](LICENSE.md).

Bundles `Libs/LibStub.lua` (Public Domain).
