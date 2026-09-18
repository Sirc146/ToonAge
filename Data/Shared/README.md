# Data/Shared — truly cross-flavor tables only

This folder is for static data that is **identical across every WoW flavor** and
therefore should not be duplicated per flavor.

## The rule

- `Data/<Flavor>/` (Retail, TBC, Mists, Cata, Vanilla, Forever) holds
  **flavor-specific game-design data**: spell IDs, talent trees, stat caps,
  item levels, rotations, guides. These differ per expansion and are NOT shared
  (a TBC spell list is not a retail spell list). See `Docs/DATA_SOURCES.md`.
- `Data/Shared/` holds only data that is genuinely the same everywhere — e.g. a
  static color table, a units-of-measure table, or a mapping that is a fact of
  the addon rather than a fact of a particular game version.

## Why it's empty right now

At the point ToonAgeOne was assembled, the codebase was retail-only, so every
existing Data table is retail game-design data and lives in `Data/Retail/`.
There is no verified cross-flavor table yet. Do not move a file here just to
avoid duplication — if two flavors' versions of a table differ in any value,
they are two files under two `Data/<Flavor>/` folders, not one shared file.

## Load mechanism (why paths can move freely)

Data files register their table by NAME, not path:

```lua
local TA = ToonAge
TA.Data = TA.Data or {}
TA.Data.StatWeights = {}   -- consumers read TA.Data.StatWeights, never a path
```

So a file's TOC path (`Data/Retail/StatWeights.lua`) can change without touching
any consumer. The active flavor's TOC lists only that flavor's `Data/<Flavor>/`
files plus any `Data/Shared/` files; `Core/Profile.lua:TA:DataNamespace()`
reports which `<Flavor>` folder is active.
