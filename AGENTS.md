# Omackey contributor guidelines

## Scope and architecture

- `OmackeySwitcher.qml` is the Quickshell overlay. It owns window discovery, MRU ordering, layout, keyboard focus, pointer handling, and activation.
- `hypr/omackey.lua` owns compositor-level bindings and behavior that QML cannot intercept.
- `install.sh` symlinks this checkout into `~/.config/omarchy/plugins/omackey.switcher`, copies the Hyprland module to `~/.config/hypr/omackey.lua`, enables the plugin, and reloads Hyprland. Preserve unrelated user configuration.
- The model is per-window, not per-application. Every toplevel exposed by `ToplevelManager.toplevels` must get its own tile, including multiple windows from one app and minimized windows.

## Switcher behavior invariants

- Keep the grid stationary. Do not automatically center, scroll to, or otherwise move the selected tile while cycling.
- Keep every modeled window visible whenever it can fit on the monitor. The layout may add columns beyond the preferred six to avoid unnecessary hidden rows.
- Treat `GridView` dimensions as cell dimensions, not delegate dimensions. Qt derives its column count with `floor(view width / cellWidth)`. Since `cellWidth` is `itemWidth + itemSpacing`, the viewport width must contain every complete cell: `gridWidth = gridColumns * itemStep`. Removing the final spacing unit can silently wrap the last tile into an invisible row while keyboard selection still reaches it.
- Calculate available space from the `PanelWindow`'s logical width and height. Test rotated and scaled monitors as well as ordinary landscape monitors.
- Constrain all variable text to an explicit width. Use plain text, single-line elision, and `Text.NoWrap` where appropriate so application names, window titles, headers, and hints cannot escape their elements.
- Preserve the MRU ordering and the initial selection semantics: forward switching starts at the second-most-recent window, and reverse switching starts at the final window.

## Input handling

- Overlay, card, and tile pointer handlers must retain the pointer grab with `preventStealing`, disable composed-event propagation, and explicitly accept press and release events. A tile activates only when release still occurs inside it.
- QML cannot suppress Hyprland's global `SUPER+mouse:272` move-window or `SUPER+mouse:273` resize-window bindings; the compositor handles them first. Enter the temporary `omackey` submap when opening the switcher so those default mouse bindings are absent while `Super` is held.
- The `omackey` submap must retain forward/reverse Tab navigation, cancel, and both Super-key release bindings. Every commit/cancel path handled by Hyprland must return to the `reset` submap. Never leave the user trapped in the Omackey submap.
- `Super+Q` is the compositor-level **Close window** action.
- `Super+W` must behave like `Ctrl+W` inside the focused application, not close the Hyprland window directly. Keep its explicit `hl.unbind("SUPER + W")`. Inject `Ctrl+W` using separate `send_key_state` down/up events and a short one-shot timer; sending through a virtual keyboard can merge the physically held Super modifier into the shortcut.
- When replacing any Omarchy default binding, inspect `omarchy menu keybindings --print`, explicitly `hl.unbind(...)` the old binding, and preserve a clear user-facing description.

## Validation

Run static checks after every relevant change:

```bash
qmllint OmackeySwitcher.qml
luac -p hypr/omackey.lua
git diff --check
```

For live verification:

```bash
omarchy-shell shell ping
omarchy plugin list --json
hyprctl reload
hyprctl configerrors
hyprctl submap
```

- An empty `hyprctl configerrors` result is success.
- Compare `hyprctl -j clients` with the visible tile count. Cycle through every entry and confirm that each selected tile is actually visible.
- When changing layout math, capture the open switcher on the affected monitor and count the rendered tiles; keyboard navigation alone will not reveal an invisibly wrapped delegate.
- Verify clicking a tile while Super remains physically held. The underlying window must not begin moving or resizing.

## Applying local changes

- QML is symlinked from this checkout, but filesystem watching through the symlink can leave the running component stale. `omarchy-shell shell rescanPlugins` may rediscover it without recreating the loaded component; use `omarchy restart shell` when visual behavior does not match the source on disk.
- Changes to `hypr/omackey.lua` are not live through the plugin symlink. Copy the updated module to `~/.config/hypr/omackey.lua` (or perform a clean reinstall), then run `hyprctl reload` and `hyprctl configerrors`.
- `install.sh` intentionally refuses to overwrite an existing plugin path. Do not delete or replace that path casually. For a clean reinstall, use the repository's `uninstall.sh` followed by `install.sh`.
- If installation reaches plugin enablement before the shell discovers the plugin, restart the shell, run `omarchy-shell shell rescanPlugins`, then enable `omackey.switcher` and verify it appears in `omarchy plugin list --json`.
