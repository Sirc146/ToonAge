# ToonAge

ToonAge is a multi-client World of Warcraft addon by Sirc (repo [Sirc146/ToonAge](https://github.com/Sirc146/ToonAge)). It uses a shared Lua engine, per-client data, modules and TOCs, Python verification, and observed client data to feed advice. It is for Christopher (Sirc) and players who want optional, skippable guidance — what, why, and alternatives — not an automated rotation and not a replacement for Zygor, WowUp, or other specialist tools. Readouts are not the same as reliable personalized guidance.

Installs come from the `test` branch. The repo is the single source of truth; box copies of these docs are drafts only until they are approved and committed.

## Quick start

Close World of Warcraft first. Christopher runs his own SavedVariables backup PowerShell, with each command explained, before every test. Confirm the installed files and version match the agreed trunk before measuring. **Trunk mapping is UNKNOWN:** some scripts assume `main`; Sirc must confirm the agreed trunk. Do not silently change branches.

### Approved Forever install

Forever installation is only `Tools/build_flavors.ps1 -Install`, never the all-client release ZIP. Target:

`C:\Program Files (x86)\World of Warcraft\_<flavor>_\Interface\AddOns\ToonAge`

Confirm the real client and avoid nested AddOns folders. `Tools/build_flavors.ps1 -Check` is report-only: it compares installed clients against the trunk and does not install. `Tools/deploy.ps1` is not the Forever method; its `robocopy /MIR` can be destructive. The reported November 9, 2026, 8:21 PM PST install method is UNKNOWN, not presumed compliant. No install commands are run from this document.

### `Update-ToonAge.ps1` flow (not an approved Forever path)

This script was found locally at `/workspace/toonage-install/Update-ToonAge.ps1`. It is not in the pinned repo root or `Tools`, and it is **not an approved Forever install path**. It is multi-client, follows a moving `test` branch, does not run CI or live tests, and is not an atomic rollback system. It does not intentionally write settings back. Explained here so the steps are visible, not as permission to run it.

1. **Refuse a running client.** The script stops if a WoW process is open, so close the game first.
2. **Resolve the current `test` SHA.** It asks GitHub for the latest commit on `Sirc146/ToonAge` `test`, then says which short SHA it will download.
3. **Download and unpack.** It saves `ToonAge-test.zip` in the temp folder, unpacks it, and uses the unpacked repo root as the copy source.
4. **For each client folder** (`_retail_`, `_forever_`, `_classic_beta_`, `_classic_`, `_anniversary_`, `_classic_era_`) under `C:\Program Files (x86)\World of Warcraft`:
   - Skip that folder if the client is not installed.
   - If a `WTF` folder exists, copy it into a dated `ToonAge-backups\<stamp>\<client>-WTF` folder under the user profile. This is the SavedVariables backup. A failed backup stops the script; nothing is copied forward.
   - Skip if the existing `Interface\AddOns\ToonAge` folder is itself a git repo.
   - If an addon folder already exists, move it aside into the same backup stamp.
   - Copy the unpacked addon in, skipping `Tools`, `Docs`, `.github`, `.git`, `CLAUDE.md`, and git metadata.
5. **Clean up.** It deletes the temp zip and unpack folder, then prints the short commit and the backup path.

After an approved install, use in-addon buttons (Reload UI, Spells, Module Health, Error Log). Diagnostic results stay in a copyable window. Do not type `/dump` or `/run`.

## Docs in this repo

| File | Who it is for |
|---|---|
| [AGENTS.md](AGENTS.md) | Bot standing rules and workflow |
| [docs/HANDOVER.md](docs/HANDOVER.md) | Current plan, delivery state, G-cards and work log |
| [docs/HISTORY.md](docs/HISTORY.md) | Dated archive of superseded or already-tried items |
| [docs/architecture.md](docs/architecture.md) | Clients, TOCs, modules, dual-gate and API audit |

All plans, decisions and final approvals lead to Sirc.
