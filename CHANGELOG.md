# Changelog

All notable changes to Omackey are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Enabling the switcher now installs or refreshes its Hyprland bindings, including
  stale plugin IDs left behind by plugin-manager updates.
- Discover the plugin before enabling it during installation, and validate the
  switcher choice before changing configuration. Explicit `--enable-switcher`
  and `--disable-switcher` installer options support setup without a prompt.
- Clarify the required setup step after Omarchy's Plugin from repo installation.

### Added

- `Alt+Left`/`Alt+Right` move by word, sending `Ctrl+Left`/`Ctrl+Right` to
  most apps and `Alt+B`/`Alt+F` to windows tagged `terminal`.

## [0.1.0] - 2026-09-09

Initial release.

### Added

- Mac-style per-window switcher overlay (`Super+Tab` / `Super+Shift+Tab`), with
  an app-scoped mode (`` Super+` `` / `` Super+Shift+` ``).
- Stable grid layout showing every window with its title and application icon.
- Click-to-select and release-to-focus behavior for the switcher.
- `Ctrl+Left`/`Ctrl+Right` and `Super+Up/Down/Left/Right` directional window
  navigation, including across monitors and around full-width/fullscreen windows.
- Mac-style application shortcuts (`Super+T/W/Q/A/Z/F/S/O/P/N/R/L` and friends).
- `Super+Escape` to cancel the switcher; Omarchy's System menu moved to
  `Super+Ctrl+Escape`.
- `install.sh`, `uninstall.sh`, `enable-switcher.sh`, and `disable-switcher.sh`
  for managing the Hyprland bindings and the optional switcher overlay.
- Native Omarchy plugin manifest (`manifest.json`) for installation via
  `omarchy plugin add`.

[0.1.0]: https://github.com/asaharan/omackey/releases/tag/v0.1.0
