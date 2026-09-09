#!/usr/bin/env bash
set -euo pipefail

plugin_id="asaharan.omackey"
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$plugin_id"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
bindings_file="$hypr_dir/bindings.lua"
module_file="$hypr_dir/omackey.lua"

enable_switcher=""
case "${1:-}" in
  --enable-switcher) enable_switcher=y ;;
  --disable-switcher) enable_switcher=n ;;
  --help|-h)
    echo "Usage: $0 [--enable-switcher|--disable-switcher]"
    exit 0
    ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac
if (( $# > 1 )); then
  echo "Expected at most one option" >&2
  exit 1
fi
if [[ -z $enable_switcher ]]; then
  echo "Enable Omackey switcher UI? (y/n)"
  if ! read -r enable_switcher || [[ ! $enable_switcher =~ ^[YyNn]$ ]]; then
    echo "Choose y/n, or use --enable-switcher or --disable-switcher." >&2
    exit 1
  fi
fi

mkdir -p -- "$(dirname -- "$plugin_dir")" "$hypr_dir"

# Create symlink if not already present
if [[ $project_dir != "$plugin_dir" ]]; then
  if [[ -L $plugin_dir ]]; then
    # Symlink exists, check if it points to the right place
    if [[ $(readlink -f -- "$plugin_dir") != "$project_dir" ]]; then
      echo "Error: Plugin path exists but points elsewhere" >&2
      exit 1
    fi
  elif [[ -e $plugin_dir ]]; then
    echo "Omackey plugin path already exists: $plugin_dir" >&2
    exit 1
  else
    ln -s -- "$project_dir" "$plugin_dir"
  fi
fi

# Always install Mac key bindings
cp -- "$project_dir/hypr/omackey.lua" "$module_file"
touch "$bindings_file"

if ! grep -Fq 'require("hypr.omackey")' "$bindings_file"; then
  cp -- "$bindings_file" "$bindings_file.omackey-backup"
  printf '\n-- BEGIN OMACKEY (managed by install.sh)\nrequire("hypr.omackey")\n-- END OMACKEY\n' >> "$bindings_file"
fi

hyprctl reload >/dev/null

errors=$(hyprctl configerrors)
if [[ -n $errors ]]; then
  printf '%s\n' "$errors" >&2
  exit 1
fi

# Discover newly installed plugins before trying to enable them.
omarchy-shell shell rescanPlugins >/dev/null

if [[ "$enable_switcher" =~ ^[Yy]$ ]]; then
  omarchy plugin enable "$plugin_id" >/dev/null
  echo "Omackey switcher UI enabled. Hold Super and press Tab to switch windows."
else
  omarchy plugin disable "$plugin_id" >/dev/null 2>&1 || true
  echo "Omackey switcher UI disabled."
fi

echo "✓ Mac key bindings are active: Super+T (new tab), Super+W (close), Super+Q (quit), etc."
