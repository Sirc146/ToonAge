# Claude specs — 2026-10-04

These specs await Christopher's review. Nothing in them is implemented yet.
Each spec has the same parts: evidence, requirements, design, tasks and how to verify it.
"Unverified" means no tool or in-game run has confirmed the point this session.

Already shipped to the trunk today, and not part of these specs: the self-test rows at 138 and 142-143 are now informational; there is a new Mists "spec readable" check; the settings suite now accepts the G9 rule (gear hidden when there is no Settings module); `frame.optionsBtn` is exposed for that check; the Mists Gear, Mists Pets and TBC Pets panes are now sized to their content; and the harvester export headers now say "interface".

---

## S1. Mists: read the spec on 5.5.4

**Evidence.** The Mists self-test on 2026-10-04 at 10:52 (client 5.5.4, build 70032) reported `GetSpecialization` and `GetSpecializationInfo` as **missing**.
- Every call site is guarded, so nothing crashes: `Core/Utils.lua` U.GetPlayerSpec does a type check plus pcall, and `Core/UI.lua` and `Mists/GuideParser.lua:313` are guarded too.
- But the spec reads as nil everywhere, and that causes four problems:
  - `Mists/Character.lua:289-290` `UpdateData` returns early, so the stat rows never fill.
  - `Mists/Gear.lua` scores items with no spec.
  - The Frost Mage / Unholy DK branch of `hasPetClass` (`UI.lua:161`) can never run.
  - `GuideParser`'s spec filter is skipped.
- The comment at `UI.lua:157` claims these functions exist from 5.0.4. That is wrong for 5.5.4.
- **Unverified:** whether `C_SpecializationInfo.GetSpecialization` and `C_SpecializationInfo.GetSpecializationInfo` exist on 5.5.4.

**Requirements.**
- On Mists, the spec ID and name can be read wherever the client offers any way to read them.
- If no way exists, the code still never errors, and the Character tab says the spec can't be read on this client instead of showing empty stats.

**Design.**
- U.GetPlayerSpec becomes the only resolver. It tries the global first, then `C_SpecializationInfo.*`, and keeps the pcall.
- Every caller goes through it instead of calling the globals directly: `UI.lua` hasPetClass and RetailPetTabWanted, and `GuideParser:313`.
- Fix the comment at `UI.lua:157`.

**Tasks.**
1. **Probe.** Add the two `C_SpecializationInfo` rows to `TestHarness` API_CHECKS as informational.
   - This needs a regenerated `Data/*/ApiManifest.lua`: test_enginegate fails until the manifest lists every C_ name the Forever files reference.
   - That generator and those manifests are inside G3's area, so coordinate with Kiro before regenerating.
   - Then Christopher runs Self-test on Mists.
2. If the namespaced functions are present, add the fallback to the resolver.
3. Route the three callers through U.GetPlayerSpec.
4. Add the "spec unreadable on this client" line to the Character tab.
5. Tests.

**Verify.**
- The Mists self-test shows "spec readable (id N)".
- The Character stat rows fill.
- Gear shows "Spec: N" in its mode line.

---

## S2. Mists Character: blank after a tab switch

**Evidence.**
- `Mists/Character.lua:421-426` `Render()` calls `BuildUI` only when `self.lastContent ~= content`.
- `UI.lua:51-103` `RebuildChild` hands the previous content frame back from the pool after purging its regions and children, and resets its height to 1.
- So from the second visit on, `content` is the same frame, `BuildUI` is skipped, and the pane is empty. The Mists self-test reports "[character] rendered nothing (content height 1)".

**Requirements.** The Character tab shows its full layout on every visit.

**Design.**
- `Render()` always calls `BuildUI` and then `UpdateData`, the same as every other tab.
- `BuildUI` already resets `self.widgets`.
- Drop the `lastContent` cache, including its reset at line 26.

**Tasks.**
1. Edit `Render()`.
2. Remove the cache field.
3. Test: render twice in a row on the same frame, and the second render has a height above 20.

**Verify.**
- Open Character, switch to Gear, then back to Character, and the layout is there.
- The self-test reports "[character] renders N px".
- The stat values also depend on S1.

---

## S3. Harvest stamps: date and channel

**Evidence.**
- Done today: the export headers (`DataHarvester.lua:1070, 1087, 1288`) now print "interface %s" for `select(4, GetBuildInfo())`.
- The generator's "interface 16001" label was already correct.
- Today the harvest stores no harvest date. The client build is stored only as `s.catalogBuild` (line 1237).
- Nothing in the addon tells beta from live. The realm name ("Classic Beta PvE") is the only hint.

**Requirements.** The generated `Data/Forever/*.lua` headers and the export headers state:
- the harvest date,
- the client build (e.g. 70205),
- the interface (16001),
- the channel (beta or live).

**Design.**
- The harvester records `s.harvestedAt` (the date of the most recent scan) and `s.clientBuild = select(2, GetBuildInfo())`.
- Channel has two options, and **this is Christopher's decision**:
  - (a) the generator takes it as a third argument: `lua gen_forever_data.lua <sv> <root> beta`. This is explicit and never wrong.
  - (b) the harvester infers it from the realm name containing "Beta". This is automatic but heuristic.
- The generator writes, for example: `-- Measured on the Forever client (build 70205, interface 16001, beta) on 2026-09-26; N records.`

**Tasks.**
1. Harvester fields.
2. Export header line.
3. Generator header and argument.
4. Update test_harvester.

**Verify.**
- An export shows all four values.
- Regenerating from an unchanged harvest still produces byte-identical files, apart from the header.

---

## S4. Retail Guide tab: 53.7 ms per render

**Evidence.**
- The Retail self-test reported `[guide] avg 53.7 ms, worst 55.0 ms, 311.0 frames discarded per re-render`.
- `QuestTracker.lua:2733-` `RenderMiddlePanel`, on every render:
  - walks every loaded guide and calls `ClassifyGuideExpansion` on each;
  - for every guide in the selected expansion, calls `C_QuestLog.IsQuestFlaggedCompleted` on every quest step. The Retail guide files hold about 21k quest-ID references in total, counted on an August copy of the files.
- It then creates a new card frame plus 1-2 buttons for every guide card, with no reuse.
- `QT:Render` (line 2560) also creates a new sidebar button for every expansion on every render.
- **Unverified:** which of these two costs dominates.

**Requirements.** A Guide tab render stays under one frame (16.7 ms) on Retail with every guide loaded.

**Design.**
1. **Measure first.** Time the gather loop and the card loop separately with `debugprofilestop()`, keep the two numbers on the module, and have the self-test perf line print them. Christopher runs it once.
2. **Cache completion counts per guide.** Invalidate on `QUEST_TURNED_IN` and, throttled, on `QUEST_LOG_UPDATE`. A render then reads counts instead of making thousands of C calls.
3. **Reuse the cards.** Pool card, follow and mode frames through the `Core/Layout.lua` pools (`RebuildChild` already calls `Layout:ReleasePane`), and reuse the sidebar expansion buttons.

**Tasks.** Do 1, then 2 or 3 depending on what step 1 shows, and re-measure after each.

**Verify.** The self-test shows the guide average under 16.7 ms, and the frames discarded per re-render near 0.

---

## S5. Settings drawer placement (#5)

**Evidence.**
- The drawer is anchored below the main window (`UI.lua` ToggleSettingsDrawer) and clamped to the screen.
- When there is less room than the drawer's height below the window, the clamp pushes the drawer up over the window: 233 px on Era, 60 px on Forever (stale install).
- Christopher's lean, which is also mine: anchor above when there's no room below.

**Requirements.** The drawer never overlaps the main window when the screen has room above or below it.

**Design.**
- Compute the room below (`main:GetBottom()`) and above (`screenH - main:GetTop()`), in UIParent units.
- If the drawer fits below, anchor `TOPLEFT` to the window's `BOTTOMLEFT` with a 2 px gap, as today.
- Else if it fits above, anchor `BOTTOMLEFT` to the window's `TOPLEFT` with a 2 px gap.
- Else keep today's clamped placement.
- Use the drawer's final height, which S6 may grow.

**Tasks.**
1. Positioning code (about 10 lines).
2. The self-test overlap check accepts "above" as a pass.

**Verify.** Drag the main window low and open the drawer. It sits above the window, and the self-test shows no overlap warning.

---

## S6. Retail drawer bleed (#3): sidebar overflow

**Evidence.**
- Computed from the code, not yet seen in game. The sidebar is a plain Frame, neither scrolled nor clipped. It is anchored `TOPRIGHT -8, -28` inside a drawer that is 400 px tall (`UI.lua` ToggleSettingsDrawer, about line 1397). It was a hidden 1x1 frame until 2026-09-28.
- On Retail, `Settings:RenderSidebar` (`Settings.lua:702-850`) draws:
  - 4 headers at 18 px each;
  - 18 buttons at 23 px each.
- The last button's bottom ends up about 519 px below the drawer's top.
- So about 119 px hang below the drawer's bottom border: Debug Mode, State Keys, SYSTEM, Reload UI and Reset All Settings.
- The content column itself scrolls correctly: the self-test reads 2010 px of content.

**Requirements.** Every sidebar button sits inside the drawer and can be clicked.

**Design options.**
- **(a)** Grow the drawer to `max(400, sidebarHeight + 36)` and let S5 place it. This is the simplest option, and every button stays visible.
- **(b)** Give the sidebar its own ScrollFrame.
- **(c)** Split the sidebar into two columns.
- Recommendation: (a).

**Tasks.**
1. Confirm against Christopher's Retail screenshot: buttons below the drawer's bottom border.
2. Implement the option chosen.
3. Add a self-test check: "sidebar fits inside the drawer" (`sidebar:GetBottom() >= drawer:GetBottom()`).

**Verify.** On Retail, Reset All Settings is inside the drawer border, and the new check passes.

---

## S7. Optional: a copy window the self-test always has

**Status: approved and implemented 2026-10-04.** `ShowReport` in TestHarness; the chat-print path is gone. Test: `Tools/test_selftest_window.py`.

**Evidence.**
- `TA:ShowCopyWindow` lives in `Core/UI.lua:981`, which every TOC loads.
- It is absent only when TestHarness runs on an older build, as on Forever today: the pre-09-22 install. The report then goes to chat, where it can't be copied.

**Design.** When `TA.ShowCopyWindow` is missing, TestHarness opens a small copy window of its own (an EditBox in a ScrollFrame, about 25 lines) instead of printing to chat.

**Tasks.** One function in TestHarness, plus a test with ShowCopyWindow set to nil.

**Verify.** Self-test on an old build opens a copy window.

---

## S8. Tab text laid out at the wrong width after a tab with no sidebar

**Evidence.** This is from Christopher's Forever screenshot on 2026-10-04 (Spells tab, right after a self-test), plus the code.
- The Spells intro ("Vanilla has no rotation ... Grouped the way the spellbook groups them.") runs as a single line and is clipped mid-word at the pane's right edge.
- `Core/UI.lua` SetTab renders the module into a content pane whose width is `self.contentWidth`. Only after the render (around line 520, "Dynamic panel resizing") does it decide whether the sidebar is empty. It then sets the pane to the full width (877) or the normal width (667) and stores that width for the next render.
- So the width a tab renders at is whatever the previous tab's sidebar decision left behind.
- On Forever, Harvest is the only tab that draws no sidebar (`DataHarvester.lua:1339`). Talents, Scrolls and Casts call `FC.RenderSidebarPublic`.
- Going from Harvest to any other tab therefore lays that tab's text out at 877 − 28 px. The pane then shrinks to 667, and the right side of every wrapped line is clipped.
- The self-test renders Harvest last and then restores the previous tab, which is exactly what the screenshot shows.
- The same ordering exists on every client. Whether a given client shows it depends on its tabs.

**Requirements.** Every tab lays out its text at the width it will actually be shown at.

**Design options.**
- **(a)** A tab declares that it has no sidebar (a `noSidebar = true` field on the profile tab entry). SetTab sets the width **before** rendering, and the after-render check stays as a fallback.
- **(b)** Keep the after-render decision, but when it changes the pane width, render the tab once more into a fresh pane. This doubles the cost, but only on the transitions that change the width.
- Recommendation: (a), with (b) as the safety net for tabs that leave the sidebar empty by accident.

**Tasks.**
1. Add `noSidebar` to Forever's Harvest tab entry (`Core/Profile.lua`), and to any other tab that never draws a sidebar.
2. SetTab sets the sidebar and pane width before calling Render.
3. Add the re-render safety net.
4. Self-test check: after SetTab, every FontString on the pane has a width no larger than the pane's width.

**Verify.** Open Harvest, then click Spells: the intro wraps to two lines and nothing is clipped. The self-test shows the new check passing.
