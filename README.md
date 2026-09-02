# Omackey

Mac-style keyboard navigation for Omarchy, beginning with a fast, theme-aware per-window switcher.

## Switcher

- Hold `Super` and press `Tab` or `Shift+Tab` to move through windows.
- Hold `Super` and press `` ` `` or `Shift+\`` to move through windows of the current application.
- Release `Super` to focus the highlighted window.
- Press `Super+Escape` to cancel. The Omarchy System menu moves to `Super+Ctrl+Escape`.
- Every window remains visible in a stable grid with its title and application icon.

## Development install

```bash
./install.sh
```

The installer links this checkout into Omarchy, installs the managed Hyprland module, and preserves unrelated user configuration. Run `./uninstall.sh` to remove only Omackey-managed integration.

## Native Omarchy plugin install

Once published, the overlay can be installed with:

```bash
omarchy plugin add https://github.com/OWNER/omackey.git --enable
~/.config/omarchy/plugins/omackey.switcher/install.sh
```

The second command installs the Hyprland bindings; Omarchy's plugin manager currently manages shell plugins but not compositor bindings.

## License

MIT
