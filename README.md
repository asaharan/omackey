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

## Updating

Omackey has no plugin registry — it's installed directly from this git repository, so
updates are pulled the same way.

If you installed via `omarchy plugin add` (or a manual `./install.sh` clone):

```bash
cd ~/.config/omarchy/plugins/omackey
git pull
./install.sh
```

`install.sh` is safe to re-run: it refreshes the Hyprland bindings and re-prompts for
the switcher UI. Run `omarchy-shell shell rescanPlugins` afterward if the plugin doesn't
pick up the change.

See [CHANGELOG.md](CHANGELOG.md) for what changed in each release.

## Releasing

Releases are cut manually and tagged with [semantic versioning](https://semver.org/).

1. Bump `"version"` in `manifest.json`.
2. Add a new entry at the top of `CHANGELOG.md`.
3. Commit, tag, and push:

   ```bash
   git commit -am "release: vX.Y.Z"
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main vX.Y.Z
   ```

4. Publish the GitHub release:

   ```bash
   gh release create vX.Y.Z --title vX.Y.Z --notes-from-tag
   ```

## License

MIT
