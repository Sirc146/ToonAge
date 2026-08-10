# ToonAge — Quality Audit Rubric

**Purpose:** Standard scoring method for assessing ToonAge after any major change.
Run this audit before each release tag. Score honestly — the number drives priorities.

**Last audit:** 2026-08-08, Score: 78/100 (v2.0.0-dev.1)
**Target:** 90+ before public release to CurseForge/Wago.

---

## How to Use

1. Read each checklist item
2. Test in-game where marked (T)
3. Code-review where marked (C)
4. Score each category out of its max
5. Calculate weighted total at the bottom
6. Record findings in the "Latest Audit Results" section
7. File issues for anything scoring below threshold

---

## 1. Functional Audit (30% of Technical)

| # | Check | Method | Pass? |
|---|---|---|---|
| 1.1 | Core features work as advertised | T | |
| 1.2 | Combat lockdown edge case — no errors entering/leaving combat | T | |
| 1.3 | Vehicle state — HUD hides when entering vehicle | T | |
| 1.4 | Pet battles — HUD hides during pet battles | T | |
| 1.5 | Loading screens — no errors on zone transitions | T | |
| 1.6 | Phasing — guide/arrow handles phase transitions gracefully | T | |
| 1.7 | No Lua errors after fresh install + /reload | T | |
| 1.8 | No Lua errors after 30 min normal play session | T | |
| 1.9 | No taint errors (check /ta errors AND Blizzard error frame) | T | |
| 1.10 | SavedVariables save correctly on /reload | T | |
| 1.11 | SavedVariables load correctly on fresh login | T | |
| 1.12 | No data corruption after forced disconnect | T | |
| 1.13 | No excessive SavedVariables growth (check file size after 1 week) | C/T | |

**Score: ___ / 13**

---

## 2. Performance Audit (25% of Technical)

### CPU
| # | Check | Method | Pass? |
|---|---|---|---|
| 2.1 | No unthrottled OnUpdate loops (all must have elapsed check) | C | |
| 2.2 | OnUpdate handlers disable when not visible/needed | C | |
| 2.3 | No unthrottled event handlers (high-freq events debounced) | C | |
| 2.4 | No expensive table creation in hot paths (OnUpdate, combat events) | C | |
| 2.5 | No combat log registration (restricted in 12.0+) | C | |

### Memory
| # | Check | Method | Pass? |
|---|---|---|---|
| 2.6 | No unbounded table growth (all caches have MAX caps) | C | |
| 2.7 | Frame pool used for Render() teardown/rebuild | C | |
| 2.8 | No frame leaks (orphaned frames accumulating) | C/T | |
| 2.9 | SavedVariables size stays under 500KB after extended use | T | |

### Load Time
| # | Check | Method | Pass? |
|---|---|---|---|
| 2.10 | Addon loads in under 100ms (check with /addon CPU profiling) | T | |
| 2.11 | No data file exceeds 200KB | C | |
| 2.12 | No unnecessary XML frames (only MapPins.xml) | C | |

**Score: ___ / 12**

---

## 3. Code Quality Audit (15% of Technical)

| # | Check | Method | Pass? |
|---|---|---|---|
| 3.1 | Modular architecture — clear module contract followed | C | |
| 3.2 | Logic/UI/Data separation — Data/ has no executable logic | C | |
| 3.3 | No file exceeds 2000 lines | C | |
| 3.4 | Meaningful naming (PascalCase modules, camelCase vars, UPPER constants) | C | |
| 3.5 | No unintended globals (only ToonAge, BINDING_*, SLASH_*, TAMapPinMixin) | C | |
| 3.6 | Proper event registration (no duplicates, no unnecessary events) | C | |
| 3.7 | Tables used efficiently (no repeated creation, proper reuse) | C | |
| 3.8 | Comments explain WHY, not just WHAT | C | |
| 3.9 | No outdated/stale comments (grep for TODO, FIXME, verify) | C | |

**Score: ___ / 9**

---

## 4. UI/UX Audit (part of Community score)

| # | Check | Method | Pass? |
|---|---|---|---|
| 4.1 | Clean layout — no overlapping elements | T | |
| 4.2 | Consistent spacing (14px sides, 8px rows per .rules.md) | C/T | |
| 4.3 | Proper alignment — elements line up across tabs | T | |
| 4.4 | Readable fonts at all sizes (no sub-8pt) | T | |
| 4.5 | Good contrast (text readable on all backdrops) | T | |
| 4.6 | Clear tooltips on interactive elements | T | |
| 4.7 | Smooth interactions (no flicker on tab switch) | T | |
| 4.8 | Intuitive options panel — findable without /ta help | T | |
| 4.9 | No hidden settings (everything accessible from panel) | C/T | |
| 4.10 | Cohesive visual identity across all 9 tabs | T | |
| 4.11 | Blizzard-style conventions (ESC closes, drag moves, tooltips) | T | |

**Score: ___ / 11**

---

## 5. Taint & Security Audit (part of Technical Stability)

| # | Check | Method | Pass? |
|---|---|---|---|
| 5.1 | No SetPoint/Show/Hide on secure frames without InCombatLockdown guard | C | |
| 5.2 | No SetAttribute on secure frames in combat | C | |
| 5.3 | No insecure code touching SecureActionButtonTemplate | C | |
| 5.4 | CombatState isolated on own frame (taint can't propagate) | C | |
| 5.5 | All API calls wrapped in pcall or SafeCall where taint is possible | C | |
| 5.6 | No taint errors visible in /ta errors after a full dungeon run | T | |

**Score: ___ / 6**

---

## 6. Compatibility Audit (15% of Community)

| # | Check | Method | Pass? |
|---|---|---|---|
| 6.1 | No conflicts with WeakAuras | T | |
| 6.2 | No conflicts with ElvUI | T | |
| 6.3 | No conflicts with Details! | T | |
| 6.4 | No conflicts with TomTom (if installed) | T | |
| 6.5 | No conflicts with HandyNotes | T | |
| 6.6 | No conflicts with DBM / BigWigs | T | |
| 6.7 | No conflicts with Auctionator / TSM | T | |
| 6.8 | No conflicts with Plater / Bartender / Dominos | T | |
| 6.9 | No global frame name collisions (all prefixed TA*) | C | |
| 6.10 | No overlapping UI with popular addons at default positions | T | |
| 6.11 | No excessive addon comm traffic | C | |

**Score: ___ / 11**

---

## 7. Packaging & Distribution Audit

| # | Check | Method | Pass? |
|---|---|---|---|
| 7.1 | TOC Interface number matches current live client | C | |
| 7.2 | No hard dependencies (LibStub only) | C | |
| 7.3 | Clean title and notes in TOC | C | |
| 7.4 | Semantic versioning in TOC and Init.lua | C | |
| 7.5 | No unused files in shipped package | C | |
| 7.6 | No dev-only scripts (Tools/, Docs/ excluded from deploy) | C | |
| 7.7 | Localization framework in place (even if English-only initially) | C | |
| 7.8 | Clear changelog (git tags, GitHub Releases) | C | |
| 7.9 | No breaking changes without version bump | C | |

**Score: ___ / 9**

---

## 8. User Experience Audit (20% of Community — "Solves Real Problem")

| # | Check | Method | Pass? |
|---|---|---|---|
| 8.1 | Easy to understand within 30 seconds of opening | T | |
| 8.2 | Works with zero configuration (Full Auto preset) | T | |
| 8.3 | No chat spam on login (healthy install is silent) | T | |
| 8.4 | No intrusive popups after first login | T | |
| 8.5 | No confusing menus (clear navigation between features) | T | |
| 8.6 | Solves a real problem players have (leveling, gearing, daily tasks) | T | |
| 8.7 | Feels valuable after 1 hour of use | T | |
| 8.8 | Reduces friction (auto-accept, auto-equip, smart waypoints) | T | |
| 8.9 | Saves time vs doing it manually | T | |
| 8.10 | Provides clarity (stat weights, upgrade %, vault scoring) | T | |

**Score: ___ / 10**

---

## 9-18. Community Compliance Checklist

### 9. UI Conventions (20% of Community)

| # | Check | Pass? |
|---|---|---|
| 9.1 | Right-click = options/context menu | |
| 9.2 | Shift-click = link to chat | |
| 9.3 | Ctrl-click = preview/inspect | |
| 9.4 | ESC closes all ToonAge windows | |
| 9.5 | Drag to move all frames | |
| 9.6 | Blizzard-style tooltips (GameTooltip) | |

**Score: ___ / 6**

### 10. Non-Intrusiveness (15% of Community)

| # | Check | Pass? |
|---|---|---|
| 10.1 | No chat spam | |
| 10.2 | No error spam (error printing capped at 3 per module) | |
| 10.3 | No popup spam (onboarding once only) | |
| 10.4 | No sound spam | |
| 10.5 | No combat text spam | |
| 10.6 | No update-available spam | |

**Score: ___ / 6**

### 11. Addon Coexistence (15% of Community)

| # | Check | Pass? |
|---|---|---|
| 11.1 | No UI takeover | |
| 11.2 | No hijacking fonts or textures | |
| 11.3 | No overwriting shared textures | |
| 11.4 | No stealing keybinds | |
| 11.5 | No interfering with other addon anchors | |

**Score: ___ / 5**

### 12. Predictability (10% of Community)

| # | Check | Pass? |
|---|---|---|
| 12.1 | No random setting resets | |
| 12.2 | No random frame repositioning | |
| 12.3 | No surprise features appearing without user action | |
| 12.4 | No unexpected animations | |

**Score: ___ / 4**

### 13. Configuration (10% of Community)

| # | Check | Pass? |
|---|---|---|
| 13.1 | Easy ON/OFF toggles for every feature | |
| 13.2 | Presets available (Full Auto / Manual) | |
| 13.3 | Per-character settings | |
| 13.4 | Profile import/export | |
| 13.5 | Minimal setup required | |
| 13.6 | No deep nested menu trees | |

**Score: ___ / 6**

### 14. Skill Level Respect

| # | Check | Pass? |
|---|---|---|
| 14.1 | Works for casual players | |
| 14.2 | Works for midcore players | |
| 14.3 | Works for hardcore players | |
| 14.4 | Works solo | |
| 14.5 | Works for raiders | |
| 14.6 | Works for collectors | |
| 14.7 | Works for farmers | |

**Score: ___ / 7**

### 15. Patch Responsiveness

| # | Check | Pass? |
|---|---|---|
| 15.1 | ApiGuard probes on login detect broken APIs | |
| 15.2 | Safe mode boot prevents total failure | |
| 15.3 | TOC numbers updated within 1 week of patch | |
| 15.4 | No features broken for more than 2 weeks | |

**Score: ___ / 4**

---

## SCORING FORMULA

```
Technical Score (max 60):
  Functionality:   (score/13) × 30 × 0.60 = ___
  Performance:     (score/12) × 25 × 0.60 = ___
  Code Quality:    (score/9)  × 15 × 0.60 = ___
  Stability:       (score/6)  × 10 × 0.60 = ___
                                    Technical Total: ___ / 60

Community Score (max 40):
  Solves Problem:  (score/10) × 20 × 0.40 = ___
  UI Conventions:  (score/6)  × 20 × 0.40 = ___
  Non-Intrusive:   (score/6)  × 15 × 0.40 = ___
  Compatibility:   (score/11) × 15 × 0.40 = ___
  Predictability:  (score/4)  × 10 × 0.40 = ___
  Configuration:   (score/6)  × 10 × 0.40 = ___
  Patch Response:  (score/4)  × 10 × 0.40 = ___
                                    Community Total: ___ / 40

FINAL SCORE: Technical + Community = ___ / 100
```

---

## Latest Audit Results

### v2.0.0-dev.1 — 2026-08-08

**Score: 78/100**

| Category | Raw | Weighted |
|---|---|---|
| Functionality | 24/30 | 7.2 |
| Performance | 22/25 | 5.5 |
| Code Quality | 14/15 | 2.1 |
| Stability & Compat | 8/10 | 0.8 |
| **Technical** | | **15.6 / 24** |
| Solves Problem | 17/20 | 3.4 |
| UI Conventions | 16/20 | 3.2 |
| Non-Intrusive | (merged) | — |
| Compatibility | 14/15 | 2.1 |
| Predictability | 9/10 | 0.9 |
| Configuration | (merged) | — |
| **Community** | | **9.6 / 16** |
| **TOTAL** | | **78 / 100** |

**Top blockers for 90+:**
1. Fill guide coordinates (87% stubs)
2. Add vehicle/pet-battle HUD suppression
3. Fix CombatState table garbage in combat
4. Auto-hide rotation bar OOC
5. Add BigWigs/DBM encounter bridge

---

## Thresholds

| Score | Release Gate |
|---|---|
| 90+ | Ready for CurseForge / Wago public release |
| 80-89 | Ready for controlled beta (WowUp private testers) |
| 70-79 | Internal dev build only (current state) |
| Below 70 | Not shippable — critical issues |
