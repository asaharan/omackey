# Application switcher input learnings

> Historical note: the layer-lifecycle design below was replaced by the
> compositor-owned handshake documented in [switcher-working.md](switcher-working.md).

## Previous stable state

The implementation does not use an Omackey Hyprland submap. Instead, it watches
the `macos-application-switcher` layer lifecycle and swaps binding handles only
while that layer is mapped. `Super+Tab` and `Super+Shift+Tab` summon the overlay;
while open, Tab and `Super+Arrow` pass directly to QML and `Super+mouse:272/273`
are consumed. When the layer closes, the normal focus and move/resize bindings
are restored immediately.

This avoids both release-dependent cleanup and per-navigation shell IPC. Two
complete programmatic open/close cycles confirmed that the bindings swapped in
both directions while `hyprctl submap` remained `default` throughout.

## What went wrong

Two compositor-side approaches were tested and caused input problems:

1. Directional submap bindings invoked
   `omarchy-shell shell call omackey ...` for every arrow press.
   This put process creation and an asynchronous IPC round trip on the input
   path. Repeated navigation could queue commands, delay visible selection,
   and allow late commands to run after the user had released `Super`.
2. Non-consuming no-op bindings passed Tab and arrow events through to QML.
   This avoided per-key processes, but the temporary `omackey` submap did not
   reliably return to the default map on this system. When it remained active,
   unrelated global shortcuts such as `Super+V` stopped working and the whole
   keyboard felt delayed or broken.
3. Binding bare `SUPER_L` and `SUPER_R` release events with `ignore_mods` did
   not make the exit reliable. After selecting a window, the live compositor
   again remained in `omackey`, disabling `Super+Tab`, `Super+F`, and other
   global shortcuts. This design was rolled back immediately.

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
