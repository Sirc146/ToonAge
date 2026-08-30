# License

**Addon:** ToonAge
**Author:** Chris
**Repository:** https://github.com/Sirc146/ToonAge
**Scope:** World of Warcraft (Retail). The TOC targets Interface `120007` and
`120100` — Midnight. There is no World of Warcraft Classic build.

---

## End User License Agreement

**Effective date:** 2026-07-26

### 1. Grant of License

Subject to your compliance with this agreement and with Blizzard
Entertainment's Terms of Service and UI Addon Development Policy, the author
grants you a non-exclusive, non-transferable, revocable license to use ToonAge
for personal, non-commercial use with your World of Warcraft client.

### 2. Permitted Uses

- Install and run the addon for personal gameplay assistance.
- Use it to display local UI elements, calculate stat weights, show rotation
  suggestions, and manage saved build data locally.
- Export or share builds and settings, where the addon offers that, when you
  explicitly initiate it.
- Fork and modify the addon for your own use.

### 3. Restrictions

You may not:

- **Charge for the addon, or any part of it.** Blizzard's UI Addon Development
  Policy requires addons be provided free of charge. This is not a permission
  the author is able to grant, so no arrangement with the author can authorise
  it. It also rules out paywalled features, subscriptions, and donation gates
  on functionality.
- Obfuscate the source, in whole or in part. Blizzard's policy requires addon
  code be distributed readable.
- **Automate play.** Specifically: simulating keyboard or mouse input, playing
  the character while unattended, or driving decisions the player did not
  initiate. Opt-in convenience features that act on an explicit player action
  — the addon's own auto-equip, auto-mount and cutscene-skip behaviours, each
  of which can be suppressed by holding Shift — are not what this prohibits.
- Read or write game client memory, or use external programs to modify the
  client.
- Collect or transmit another player's personal data without their explicit
  consent.
- Build UI that impersonates Blizzard messages or official Blizzard services.
- Remove or alter copyright, attribution, or license notices.
- Redistribute the addon under terms that conflict with this license or with
  the license of any included third-party component.

### 4. Third-Party Components

`Libs/LibStub.lua` — LibStub, **placed in the Public Domain** by its authors.
Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke.
See https://www.wowace.com/wiki/LibStub.

This is the only third-party component bundled with the addon.

### 5. Ownership

All original code and assets remain the property of the author and
contributors. This license transfers no ownership.

World of Warcraft, Battle.net, and Blizzard Entertainment are trademarks of
Blizzard Entertainment, Inc. ToonAge is an unofficial fan project and is not
affiliated with, endorsed by, or sponsored by Blizzard Entertainment.

### 6. Termination

This license terminates automatically if you breach it. On termination, stop
using the addon and delete your copies.

### 7. Disclaimer of Warranties

The addon is provided **AS IS**, without warranty of any kind. All implied
warranties, including merchantability and fitness for a particular purpose,
are disclaimed to the extent the law allows.

### 8. Limitation of Liability

To the maximum extent permitted by law, the author is not liable for any
indirect, incidental, special, consequential, or punitive damages arising from
your use of the addon.

---

## Developer tooling — Blizzard Game Data API

The scripts in `Tools/` are **developer-side only**. They are not part of the
shipped addon, are never loaded by the game, and the addon itself cannot reach
the network at all — World of Warcraft's Lua environment has no HTTP.

- **Client name:** ToonAge
- **Intended use:** Fetches World of Warcraft reference data — quest name,
  level requirements, zone — from the Game Data API via the OAuth client
  credentials flow, to generate offline leveling-guide data for this addon.
- **No player accounts, characters, or profile data are accessed.** No user
  authentication or login is involved. The Profile API is not used.
- Output is baked into static Lua files committed to this repository.

Anyone running these scripts needs their own client credentials from
https://develop.battle.net/ and is bound by Blizzard's Developer API Terms of
Use, including its rate limits. See `.rules.md` for the project's conventions
and `Tools/check_credentials.py` to verify a setup.

---

## Reporting

Bugs, security issues, and license questions:
https://github.com/Sirc146/ToonAge/issues
