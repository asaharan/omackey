# Switcher input lifecycle

## The rapid `Super+Tab` race

Opening the switcher crosses two processes. Hyprland launches
`omarchy-shell shell summon`, then the shell maps the layer and QML acquires
keyboard focus. Previously, only QML handled the release of `Super`. A quick
press and release could therefore complete before the layer existed, leaving
the newly opened switcher with no release event to close it.

Swapping global binding handles from `layer.opened` had the same vulnerable
window. Until the layer appeared, Hyprland's normal bindings were still active,
including the compositor-level `Super+mouse:272/273` move and resize actions.

## Approaches considered

### Compositor-owned raw-key state machine and submap

Enter a temporary `omackey` submap synchronously when the initial switching
binding runs, before starting the asynchronous shell command. A compositor-level
`input.keyboard.key` listener observes both physical Super-key releases before
Hyprland performs keybind matching; a Lua session flag makes it a no-op outside
a switcher session. The submap owns cancellation and suppression of the global
mouse actions. Navigation keys remain non-consuming no-ops so they reach the
focused QML item without starting a process for every key press.

If Super is released before the layer opens, record the requested exit and send
it only after `layer.opened`. This handshake prevents the exit command from
overtaking the open command. Reset the submap synchronously on every
compositor-owned exit and again when the layer closes.

This is the implemented approach because Hyprland observes the complete key
lifecycle even when QML does not yet exist.

### Modifier-only release bindings

This is the most direct design, but Hyprland 0.55.3 and later have a regression
where modifier-only bindings inside submaps can appear in `hyprctl binds`
without firing. Registering them as `submap_universal` also proved unreliable
on Hyprland 0.56.2. Omackey retains both submap release bindings as fallbacks,
but correctness does not depend on Hyprland matching them.

### QML modifier-state reconciliation

QML could try to query the current modifier state after gaining focus and close
when Super is no longer held. Under Wayland, an ordinary client does not have a
reliable global physical-key-state view, so this is not suitable as the primary
correctness mechanism.

### Timeout or watchdog

A timeout could eventually hide an abandoned overlay, but it would mask the
race, introduce load-dependent behavior, and interfere with intentionally
holding the switcher open.

## Implemented state transitions

```text
Super+Tab press
  -> mark the switcher active
  -> enter the omackey submap
  -> asynchronously summon the overlay

Super release or Escape
  -> the raw keyboard listener observes either Super key before bind matching
  -> synchronously return to the reset submap
  -> if the layer is open, send commit or cancel
  -> otherwise defer that action until layer.opened

layer.closed
  -> clear pending state
  -> force the omackey submap back to reset if necessary
```

The raw event provides `(keycode, timeMs, state)` using XKB keycodes. Left and
right Super are `133` and `134`; release is state `0`. The listener checks those
values only while `switcher_active` is true, so ordinary Super-key releases do
nothing. The `omackey` submap also retains `SUPER + SUPER_L` and
`SUPER + SUPER_R` release bindings as compatibility fallbacks.

QML continues to own MRU ordering, navigation, rendering, pointer handling, and
window activation. Its Super-release handler remains a secondary path; the
compositor normally consumes the release while the submap is active.

## Verification

Run the static checks:

```bash
qmllint OmackeySwitcher.qml
luac -p hypr/omackey.lua
git diff --check
```

After copying the Lua module into the live Hyprland configuration, run:

```bash
hyprctl reload
hyprctl configerrors
hyprctl submap
```

An empty `hyprctl configerrors` result is success. Exercise rapid taps with
left and right Super for `Super+Tab`, `Super+Shift+Tab`, and the application
scope bindings. Test Escape, Enter, clicking a tile while Super remains held,
and shell/configuration reloads. After every commit and cancel path,
`hyprctl submap` must report `default`.
