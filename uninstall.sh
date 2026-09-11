#!/bin/bash
set -euo pipefail

# Closed, trusted PATH: every external tool below must resolve to a known
# system binary, never something earlier in an attacker-influenced PATH.
PATH=/usr/bin:/bin
export PATH

plugin_id="asaharan.omackey"
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
plugin_dir="$config_home/omarchy/plugins/$plugin_id"
hypr_dir="$config_home/hypr"
bindings_file="$hypr_dir/bindings.lua"
module_file="$hypr_dir/omackey.lua"

# Refuse to touch an existing path unless it is a plain regular file. A
# symlink or any other object is a foreign destination: never read through
# it or write through it.
guard_plain_file() {
  local path=$1
  if [[ -e $path && ( -L $path || ! -f $path ) ]]; then
    echo "Error: $path exists and is not a plain file" >&2
    exit 1
  fi
}
guard_plain_file "$bindings_file"
guard_plain_file "$module_file"

if [[ -f $bindings_file ]]; then
  # Stage the stripped content in a freshly created, exclusively named temp
  # file in the same directory, then rename it into place. rename() replaces
  # the destination atomically and never follows a symlink placed there.
  temporary=$(mktemp -- "$bindings_file.XXXXXX")
  awk '
    $0 == "-- BEGIN OMACKEY (managed by install.sh)" { managed = 1; next }
    $0 == "-- END OMACKEY" { managed = 0; next }
    !managed { print }
  ' "$bindings_file" > "$temporary"
  mv -f -- "$temporary" "$bindings_file"
fi

rm -f -- "$module_file"
omarchy plugin disable "$plugin_id" >/dev/null 2>&1 || true

if [[ -L $plugin_dir && $(readlink -f -- "$plugin_dir") == "$project_dir" ]]; then
  rm -- "$plugin_dir"
fi

omarchy-shell shell rescanPlugins >/dev/null

if ! hyprctl reload >/dev/null 2>&1; then
  echo "Warning: hyprctl reload failed after removing Omackey bindings." >&2
elif errors=$(hyprctl configerrors 2>/dev/null) && [[ -n $errors ]]; then
  echo "Warning: Hyprland reports config errors after removing Omackey bindings:" >&2
  printf '%s\n' "$errors" >&2
fi

echo "Omackey integration removed."
