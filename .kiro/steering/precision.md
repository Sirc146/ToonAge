---
inclusion: auto
---

# ToonAge — Decimal Precision & Formatting Spec

**This is a binding standard.** All code must conform. No exceptions without documented justification.

---

## 1. Navigation & Map Coordinates (CoordResolver, Arrow, NavHud, MapPins)

**Internal Logic** (C_Map calculations): `0.0001` (4 decimal places)
- WoW's API outputs coordinates on a 0.0000 to 1.0000 scale
- Precision beyond 4 decimal places generates useless micro-updates

**UI Display Formatting**: `0.01` (2 decimal places) converted to 0–100 scale
- Standard display: `45.12, 63.89`
- Anything tighter creates unreadable visual noise during movement
- Format: `string.format("%.2f, %.2f", x * 100, y * 100)`

---

## 2. Gear Scoring & Stat Weights (Gear, StatWeights, TooltipScorer, StatEngine)

**Internal Math** (DR calculations, weight derivatives): `0.001` (3 decimal places)
- A weight difference of 1.042 vs 1.048 matters when multiplying across large stat budgets
- StatEngine marginal values calculated to 3 places
- Item score comparisons use 3 decimal internal precision

**UI Display Formatting**: `0.01` (2 decimal places)
- Tooltip: `Score: +145.23`
- Upgrade badge: `+3.84% DPS gain`
- Stat weight display: `Haste: 1.04`
- Format: `string.format("%.2f", score)`

---

## 3. Execution Timers & OnUpdate Handlers (Core/Init, CombatState)

**Benchmarking & Profiling**: `0.001` seconds (millisecond precision)
- Using `debugprofilestop()` or `GetTime()`
- Tighter than 1ms captures random WoW engine frame-variance, not real code performance

**Event Throttling** (UI_REFRESH_DELAY, STATUS_UPDATE_HZ): `0.01` or `0.05` seconds
- Throttle tighter than 0.01 destroys the CPU-saving benefits of event coalescing
- Current values: UI refresh 0.15s, Arrow 0.03s, QT status 0.2s, CombatState 0.1s

---

## 4. UI Rendering, Layout, & Scaling (Core/UI, Core/UIModern)

**X/Y Pixel Positioning**: `0` decimal places (strict integers)
- Setting frame coordinates to a decimal (e.g., x = 14.35) forces sub-pixel rendering
- Sub-pixel = blurred fonts and torn borders
- **Always** `math.floor()` coordinates before SetPoint
- Exception: animation interpolation may use decimals internally but must floor on apply

**Alpha (Opacity) & Frame Scale**: `0.01` (2 decimal places)
- `frame:SetAlpha(0.85)` — correct
- `frame:SetAlpha(0.8537)` — wrong, truncate to 0.85
- `frame:SetScale(1.40)` — correct

---

## 5. Progress & Status Tracking (XPTracker, Weekly, GatherTracker)

**Percentages (UI display)**: `0.1` (1 decimal place)
- XP progress: `45.5%`
- Boss health: `23.1%`
- Drop rate: `12.3%`
- Two decimal places (45.54%) flicker too rapidly during active combat/movement
- Format: `string.format("%.1f%%", pct)`

**Percentages (internal logic)**: `0.01` (2 decimal places)
- Completion thresholds, progress calculations use 2 decimal internally
- Only display rounds to 1

---

## Quick Reference Table

| Context | Internal | Display | Format String |
|---|---|---|---|
| Map coordinates | 4 dp (0.0001) | 2 dp (45.12) | `"%.2f, %.2f"` |
| Stat weights | 3 dp (1.042) | 2 dp (1.04) | `"%.2f"` |
| Gear scores | 3 dp (145.237) | 2 dp (145.24) | `"%.2f"` |
| Upgrade % | 3 dp (3.847) | 2 dp (3.85%) | `"%.2f%%"` |
| Timer throttle | 2 dp (0.15) | N/A | — |
| Frame position | 0 dp (integer) | N/A | `math.floor()` |
| Alpha/scale | 2 dp (0.85) | N/A | — |
| Progress % | 2 dp (45.54) | 1 dp (45.5%) | `"%.1f%%"` |

---

## Enforcement

- `check_lua.py` cannot enforce this (runtime formatting)
- Code review: any `string.format` with `%f` (no width spec) is a violation — always specify precision
- Any `SetPoint` with a non-integer coordinate is a violation
- Any displayed percentage with 2+ decimal places in a live-updating context is a violation
