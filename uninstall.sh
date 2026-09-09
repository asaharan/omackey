#!/usr/bin/env bash
set -euo pipefail

plugin_id="asaharan.omackey"
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$plugin_id"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
bindings_file="$hypr_dir/bindings.lua"
module_file="$hypr_dir/omackey.lua"

if [[ -f $bindings_file ]]; then
  temporary=$(mktemp)
  awk '
    $0 == "-- BEGIN OMACKEY (managed by install.sh)" { managed = 1; next }
    $0 == "-- END OMACKEY" { managed = 0; next }
    !managed { print }
  ' "$bindings_file" > "$temporary"
  cp -- "$temporary" "$bindings_file"
  rm -f -- "$temporary"
fi

rm -f -- "$module_file"
omarchy plugin disable "$plugin_id" >/dev/null 2>&1 || true

if [[ -L $plugin_dir && $(readlink -f -- "$plugin_dir") == "$project_dir" ]]; then
  rm -- "$plugin_dir"
fi

omarchy-shell shell rescanPlugins >/dev/null
hyprctl reload >/dev/null
echo "Omackey integration removed."
