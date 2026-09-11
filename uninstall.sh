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

# Refuse to operate on $hypr_dir unless it is a real directory we own. Never
# follow it if it turns out to be a symlink.
if [[ -L $hypr_dir || ! -d $hypr_dir || ! -O $hypr_dir ]]; then
  echo "Error: $hypr_dir is not a plain directory owned by the current user" >&2
  exit 1
fi

# Pin the directory's identity by opening it once, immediately after the
# check above, and route every later create/read/rename/unlink through this
# file descriptor (via /proc/self/fd) instead of re-resolving $hypr_dir by
# pathname. Without this, $hypr_dir could be renamed or replaced between the
# check and any of the operations below, redirecting our writes into a
# different, attacker-controlled tree.
exec {hypr_fd}<"$hypr_dir" || { echo "Error: unable to open $hypr_dir" >&2; exit 1; }
hypr_at="/proc/self/fd/$hypr_fd"
if [[ ! -d $hypr_at || $(stat -c '%u' -- "$hypr_at") != "$(id -u)" ]]; then
  echo "Error: could not verify ownership/type of the opened $hypr_dir" >&2
  exit 1
fi
bindings_file="$hypr_at/bindings.lua"
module_file="$hypr_at/omackey.lua"

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
