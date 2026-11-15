# ToonAge — History archive

Dated archive of superseded or already-tried items, so nothing is re-attempted blindly. Before trying a path that may already have been tried, read this file **from the repo**. Current rules and the live plan live in [AGENTS.md](../AGENTS.md) and [HANDOVER.md](HANDOVER.md). Box copies are drafts only.

Each entry says what was recorded, the date, and what replaced it.

## Current team versus earlier tools

**Current (November 9, 2026):** Riley, Glitch, Warden, Gilder, Chronicler and Conductor, with Christopher (Sirc) as final authority.

**ARCHIVED (history, November 9, 2026):** Earlier ToonAge tools and roles were Claude, Kiro, Pepper who later named herself Muse, Gemini, Copilot and DeepSeek. CLAUDE.md, tool-specific recipes and workspace-export instructions are historical, not the current team or process. The prior Gemini/Copilot transition framing is retired. Do not treat those exports as the current workflow.

Muse is authoritative for prior direction, authority, roles, branches and gates; do not retain another export’s missing-context UNKNOWN when Muse supplies the decision. Source note retained from the shared record: **Copilot export of prior chats, dated 2026-09-26**; additional July 26/31 entries relayed November 9 at 8:46 PM PST. Only the expressly supplied project additions were imported; the casing decision remains **Sirc**.

## Pepper, who later named herself Muse

**November 9, 2026.** Christopher said Pepper named herself the way the bots named themselves. Record as: Pepper, who later named herself Muse. Pepper and Muse are the same assistant. Muse’s ToonAge context export (`Muse-ToonAge-Context-Export.txt`, covering October 3–November 8; read in full November 9 at 8:26 PM PST; SHA256 `5e6e522e6cfe9fab6b81ae43406c9edbc794305bd3c280dc9f3d069ec9cf929f`) is the authoritative prior-context source. Historical reports in it are not promoted to current verification.

## Vespera character state

**ARCHIVED (superseded November 9, 2026):** November 6, 2026, 6:30 PM PST live Forever probe: Vespera Mage level 5, build 70840 / interface 16001, Mining 1/75 and Skinning 55/75, with root/child skill-line pairs (186/2946 and 393/2947). Later that evening (6:58 PM PST) Christopher confirmed he unlearned Mining and learned Tailoring, retaining Skinning.

**Current (November 9, 2026, 7:36 PM PST live export):** Vespera is a level 15 Mage on Forever 70862 / interface 16001. Professions recorded in current memory and the live-fix context: Skinning 116/150, and in the level-15 replacement note Tailoring 49/75, First Aid 24/75, Fishing 20/75, Cooking 15/75, Comprehension 14/75 (Comprehend Scroll known); Mining remains unlearned. Comprehension 3012 native 14/75, minLevel 6, and Comprehend Scroll 1296017 known are also in the current HANDOVER live-fix list. Do not reuse the level-5 Mining 1/75 snapshot as current.

## Duplicate profession bars

**ARCHIVED (superseded November 8, 2026):** November 6 instruction that duplicate Skinning/Mining profession bars were report-only, with no ToonAge fix authorized. Christopher identified a Forever-side display issue to track (screenshot pending at that time); cause was not independently verified.

**Replaced by:** On November 8 Christopher authorized scoped fixes, and the duplicate-profession fix became PR59 (merge `74f54bdc72…`, 100 checks reported, installed). Current boundary: Vespera single rows appear to hold, not all-toon certification. Drop child only if displayed parent AND name/rank/max match. Keep roots 393/197/185; matching children 2947/2945/2948 are examples. Remaining semantic/edge-case work is G18; live result is not all-toon certified.

## Dugi to Zygor

**ARCHIVED:** Christopher previously used Dugi for questing. Older repo docs and tests assumed that split: `Docs/CLASSIC_ANNIVERSARY_BRIEF.md` said “NO guide/navigation system for Anniversary. Player uses Dugi for questing.” `Tools/test_tab_set.py` checks `tbc: no 'guide' tab (Dugi handles questing)`.

**Replaced by:** Christopher switched from Dugi to Zygor for questing guides and uses WowUp to manage addons (imported from Claude; exact switch date UNKNOWN). Current standing rule, verbatim: “He uses Zygor and WowUp; don't duplicate them.” Do not revive Dugi-specific assumptions, and do not add a quest-guide tab because the old specialist changed.

## Quest/guide split

**Still standing, specialist updated:** An imported September 2026 direction (Claude) was that ToonAge should focus on character stats, gear, talents (PvE and PvP), and a state-aware rotation assist — not the quest tracker or guides. The Dugi-era “no guide tab” split is superseded only in the specialist named (Dugi → Zygor). The product still does not rebuild quest-guide or navigation systems. Coexist and step back for Zygor and hard specialties. Do not treat the specialist change as permission to build a ToonAge quest guide.

## Historical CharacterAdvisor

Historical CharacterAdvisor used Blizzard Game Data API client-credentials for offline quest reference data, no player data accessed; relation to ToonAge **UNCONFIRMED**. Only the expressly supplied project additions were imported; the casing decision remains **Sirc**. Do not assume CharacterAdvisor is ToonAge or merge its scope without Sirc.

## Dual-gate wording (retained, not superseded)

Retained verbatim from the Copilot-export history and still the packaging/runtime rule (see [architecture.md](architecture.md)):

**“the TOC file is the packaging backstop (what actually gets loaded), and Core/Profile.lua is the runtime backstop (what is allowed to initialize).”**

Retail data/modules must never pollute other clients. The historical G3/profile-requires gap was unbuilt at the October 24 audit; present full contract/export-button coverage remains UNKNOWN pending audit. Do not reopen settled attune relevance or the old bare-backup replacement decision without Sirc. Old backup verdict UNKNOWN.

## First-task order and PR62 status

**ARCHIVED (superseded November 9, 2026, 8:21 PM PST delivery):** An earlier Kanban first-three plan used Training provenance, then PR62 recovery/integration after a hold, then optional wand DPS. Historical PR62 prepared/hold states, and the recovered-head work through 8:12 PM PST, are not current.

**Replaced by:** Riley reports PR62 merged to `test` as `c9c5308a` and installed on Jarvis Forever November 9, 8:21 PM PST. Current first three tasks are (1) Spells acceptance of installed `c9c5308a` (G01), (2) Attack Rank 1@10 provenance (G03), (3) ApiGuard build/interface labels (G02), because G02 is a P0/quick win and frame regressions (G04/G05) follow after. PR62 is Stage 4 / 8/10 delivery index, **NOT live-validated**. Do not keep a completed merge waiting, and do not reinstall an older candidate to “recover” it.

Baseline “0 guides resident” was generic-stack state, not a dedicated MageGuidance loading test; PR62 is now reported installed.

## Vespera spec selector

Frost was selector demonstration, not a chosen spec. **November 9, 2026, 8:02 PM PST:** Vespera has no chosen spec. Explicit selection controls guidance; none defaults to Fire. That decision is closed. Do not silently select Frost or any spec from demonstration, casts or gear.

## Muse-export verbatim quotes (October 3–8)

Stored verbatim words (line wrapping normalized only). These remain the prior-context quotes; they are not current completion claims.

- “my Friday and Jarvis to Iron Man” — October 4.
- “the trusted advisor from gear to journey.” — October 4, clarified October 7/8.
- “a key factor to how we can build the others the way we want them” — October 4, Harvest.
- “i like the role choice but its not guiding me in the right direction for spell” — October 8.
- “Launch day: re-source every guide reference for cap 60” — October 3; completion UNKNOWN.
- “Every tab ends in a next step.” — October 3.

## Other imported items still current unless Sirc changes them

These were imported into the shared record (July 26/31, 2026, relayed November 9 at 8:46 PM PST) and are not archived as replaced:

- “dont break down in days just phases”
- “I need to see whats replaced and what is not and what is partial. and I need to know what the reasoning it cannot be replaced”
- “I dont want block i want a modern ux look like wow does and i want the layout how they do”
- “I won't design against a guess.”
- Requested policy copy, not verified behavior: “Use this addon at your own risk.” “Do not use it to automate gameplay or to collect other players' personal data.” “Saved variables are stored locally.” “Optional telemetry is opt-in only.”

**UNKNOWN, not invented:** the exact July 31 talent-tree verbatim quote was not supplied in the handoff (paraphrase only: build/test an interactive tree in game and see +/- DPS or stat-weight effects). Transparent-mode exact behavior, settings and current implementation are UNKNOWN. Gathering Radar current implementation UNKNOWN; requested behaviors remain **UNVERIFIED**.
