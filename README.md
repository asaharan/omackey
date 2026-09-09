# Omackey

Mac-style keyboard navigation for Omarchy, beginning with a fast, theme-aware per-window switcher.

## Switcher

- Hold `Super` and press `Tab` or `Shift+Tab` to move through windows.
- Hold `Super` and press `` ` `` or `Shift+\`` to move through windows of the current application.
- Release `Super` to focus the highlighted window.
- Press `Super+Escape` to cancel. The Omarchy System menu moves to `Super+Ctrl+Escape`.
- Every window remains visible in a stable grid with its title and application icon.

## Window navigation

- Press `Ctrl+Left` or `Ctrl+Right` to focus the window in that direction. This
  also works across monitors and when full-width or fullscreen windows obscure
  other windows.
- Press `Super+Left` or `Super+Right` to move to the start or end of a line.
- Press `Super+Up` or `Super+Down` to focus the window in that direction.

## Application shortcuts

- Use `Super+T`, `W`, `Q`, `A`, `Z`, `F`, `S`, `O`, `P`, `N`, `R`, and `L`
  for their familiar macOS-style application actions.
- Use `Super+Shift+T` to reopen a closed tab, `Super+Shift+Z` to redo, and
  `Super+Shift+N` to open a private window.
- Use `Super+[` and `Super+]` for back and forward, and `Super+G` or
  `Super+Shift+G` for the next or previous match.
- Use `Super+Backspace` to delete to the start of the line.

## Installation

```bash
./install.sh
```

The installer:
- Links this checkout into Omarchy
- Installs Mac key bindings (always active)
- Optionally installs the switcher UI overlay

After installation, Mac key bindings are immediately active. You can manage the switcher UI overlay:

```bash
./enable-switcher.sh   # Enable switcher UI overlay
./disable-switcher.sh  # Disable switcher UI overlay
./install.sh           # Re-run install to be prompted
```

Run `./uninstall.sh` to remove all Omackey integration.

## Native Omarchy plugin install

Once published, the overlay can be installed with:

```bash
omarchy plugin add https://github.com/OWNER/omackey.git --enable
~/.config/omarchy/plugins/omackey/install.sh
```

The second command installs the Hyprland bindings; Omarchy's plugin manager currently manages shell plugins but not compositor bindings.

## License

MIT
