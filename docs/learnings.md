# Application switcher input learnings

## Stable state

The current stability-first implementation does not use an Omackey Hyprland
submap. `Super+Tab` and `Super+Shift+Tab` summon the overlay, while the normal
global `Super` shortcuts remain available. Arrow-navigation functions and grid
math exist in QML, but `Super+Arrow` is still intercepted by Hyprland's normal
window-focus bindings and therefore does not navigate the switcher.

## What went wrong

Two compositor-side approaches were tested and caused input problems:

1. Directional submap bindings invoked
   `omarchy-shell shell call omackey.switcher ...` for every arrow press.
   This put process creation and an asynchronous IPC round trip on the input
   path. Repeated navigation could queue commands, delay visible selection,
   and allow late commands to run after the user had released `Super`.
2. Non-consuming no-op bindings passed Tab and arrow events through to QML.
   This avoided per-key processes, but the temporary `omackey` submap did not
   reliably return to the default map on this system. When it remained active,
   unrelated global shortcuts such as `Super+V` stopped working and the whole
   keyboard felt delayed or broken.

The concrete diagnostic for the second failure was:

```bash
hyprctl submap
```

It returned `omackey` while the switcher was closed. Resetting it with the
installed Lua-style dispatcher restored normal shortcuts immediately:

```bash
hyprctl dispatch 'hl.dsp.submap("reset")'
```

Reloading configuration does not reliably recover an already-stuck submap; an
explicit live reset may still be required.

## Directional grid math

Directional selection should be calculated from `gridColumns`, not from the
preferred six-column count:

- Left and right stay inside the current rendered row.
- Up and down preserve the current column.
- Moving into a partially populated final row clamps to that row's last real
  item rather than selecting an invalid index.
- Tab and Shift+Tab retain circular MRU navigation independently of spatial
  arrow navigation.

## Constraints for a future solution

A future implementation of `Super+Arrow` navigation must satisfy all of these:

- Normal `Super+Arrow` and all other global `Super` shortcuts must behave
  normally whenever the switcher is closed.
- No external process or shell IPC call should run for each navigation key.
- The switcher must never leave Hyprland in a non-default submap after commit,
  cancel, shell reload, configuration reload, keyboard reconnect, or an error.
- Both left and right `Super` release paths must be tested on the physical
  keyboard, including rapid press/release sequences.
- Verification must include `hyprctl submap` after every exit path, not only a
  visual check that the overlay disappeared.
- The compositor-level suppression of `Super+mouse:272/273` must be restored
  before declaring the submap design complete, because QML cannot suppress
  those global move/resize bindings itself.

## Useful verification

```bash
qmllint OmackeySwitcher.qml
luac -p hypr/omackey.lua
git diff --check
hyprctl reload
hyprctl configerrors
hyprctl submap
omarchy-shell shell ping
```

An empty `hyprctl configerrors` result is success. With the switcher closed,
`hyprctl submap` must report `default`.
