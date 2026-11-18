# ToonAge handover

Shared record for later work. Append a dated section. Do not rewrite an older section.

## November 17, 2026 — left-panel slot

The area under the character block is a slot a tab can opt into. Professions is the first user (Forever craft calculator, PR #101). Later tabs, including Casts, use this contract. Do not invent a second sidebar.

### API

Defined in `Core/LeftPanel.lua`. `Core/UI.lua` `SetTab` releases the previous slot before it rebuilds the panes, then mounts the new tab's slot after that tab renders.

```lua
TA:RegisterLeftPanel(tabKey, spec) -> boolean
TA:ClearLeftPanel(tabKey) -> boolean
TA:LeftPanelSpec(tabKey) -> spec or nil
TA:ReleaseLeftPanel(ui) -> boolean
TA:MountLeftPanel(ui, tabKey) -> boolean
TA:RefreshLeftPanel(ui) -> boolean
```

`spec.build(content, host)` is required. It draws into the slot's scroll child.

`spec.refresh(content, host)` is optional. It updates the slot without leaving the tab.

`spec.release(content, host)` is optional. It runs before pooled frames are returned.

`spec.place` is `"below"` (the default) or `"swap"`. `"below"` keeps the character block and anchors the slot under it. `"swap"` hides the character scroll and the slot fills the sidebar. Any other place is rejected and nothing is registered.

### Host

`host` fields are `scroll`, `content`, `sidebar`, `side`, `place`, `width`, and `tabKey`.

- `content` is the scroll child to draw into. It is marked `_laPane`.
- `scroll` is the slot's own scroll, created once per window.
- `sidebar` is the left-panel frame.
- `side` is the normal sidebar scroll child (the character block).
- `place` is the resolved `"below"` or `"swap"`.
- `width` is the slot content width (`ui.sideWidth`, or 184 when that is missing).
- `tabKey` is the tab id that was mounted.

### Cata and Wrath

Cata and Wrath load `Core/LeftPanel.lua` and do not load `Core/Layout.lua`. Release still runs the tab's `release` callback. The pool hand-back (`Layout:ReleasePane`, fed by `AcquireFrame`) is skipped when Layout is absent. The scroll host is still created once and reused. Flavors that load Layout return pooled rows to the pool on tab switch.

### Tabs that do not opt in

A tab that never calls `RegisterLeftPanel` is unchanged. Mount for an unknown tab is a no-op: it creates no frames and does not touch the character caption, the sidebar height, or the sidebar scroll. `_leftPanelTab` stays nil, so the empty-sidebar check is the one the window already used. Leaving an opted-in tab releases that slot and the next tab draws its own left panel.
