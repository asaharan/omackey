#!/usr/bin/env bash
set -euo pipefail

plugin_id="omackey.switcher"
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$plugin_id"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
bindings_file="$hypr_dir/bindings.lua"
module_file="$hypr_dir/omackey.lua"

mkdir -p -- "$(dirname -- "$plugin_dir")" "$hypr_dir"

if [[ $project_dir != "$plugin_dir" ]]; then
  if [[ -e $plugin_dir || -L $plugin_dir ]]; then
    echo "Omackey plugin path already exists: $plugin_dir" >&2
    exit 1
  fi
  ln -s -- "$project_dir" "$plugin_dir"
fi

cp -- "$project_dir/hypr/omackey.lua" "$module_file"
touch "$bindings_file"

if ! grep -Fq 'require("hypr.omackey")' "$bindings_file"; then
  cp -- "$bindings_file" "$bindings_file.omackey-backup"
  printf '\n-- BEGIN OMACKEY (managed by install.sh)\nrequire("hypr.omackey")\n-- END OMACKEY\n' >> "$bindings_file"
fi

omarchy-shell shell rescanPlugins >/dev/null
omarchy plugin enable "$plugin_id" >/dev/null
hyprctl reload >/dev/null

errors=$(hyprctl configerrors)
if [[ -n $errors ]]; then
  printf '%s\n' "$errors" >&2
  exit 1
fi

echo "Omackey installed. Hold Super and press Tab."
