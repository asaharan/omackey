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

# Refuse to write into $hypr_dir unless it is a real directory we own.
# Never follow it if it turns out to be a symlink.
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

# Refuse to treat an existing path as one of our managed files unless it is
# a plain regular file. A symlink or any other object is a foreign
# destination and must not be read from or written through.
guard_plain_file() {
  local path=$1
  if [[ -e $path && ( -L $path || ! -f $path ) ]]; then
    echo "Error: $path exists and is not a plain file" >&2
    exit 1
  fi
}
guard_plain_file "$module_file"
guard_plain_file "$bindings_file"

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

# Stage the new module + bindings content in freshly created, exclusively
# named temp files in the same directory, and keep a copy of whatever they
# previously contained so a failed reload can be rolled back atomically.
new_module_tmp=$(mktemp -- "$module_file.XXXXXX")
cp -- "$project_dir/hypr/omackey.lua" "$new_module_tmp"

module_backup=""
if [[ -e $module_file ]]; then
  module_backup=$(mktemp -- "$module_file.rollback.XXXXXX")
  cp -- "$module_file" "$module_backup"
fi

bindings_existed=0
bindings_backup=""
if [[ -e $bindings_file ]]; then
  bindings_existed=1
  bindings_backup=$(mktemp -- "$bindings_file.rollback.XXXXXX")
  cp -- "$bindings_file" "$bindings_backup"
fi

new_bindings_tmp=$(mktemp -- "$bindings_file.XXXXXX")
if [[ $bindings_existed -eq 1 ]]; then
  cp -- "$bindings_file" "$new_bindings_tmp"
fi
if ! grep -Fq 'require("hypr.omackey")' "$new_bindings_tmp"; then
  printf '\n-- BEGIN OMACKEY (managed by install.sh)\nrequire("hypr.omackey")\n-- END OMACKEY\n' >> "$new_bindings_tmp"
fi

cleanup_backups() {
  [[ -n $module_backup ]] && rm -f -- "$module_backup"
  [[ -n $bindings_backup ]] && rm -f -- "$bindings_backup"
}

rollback() {
  if [[ -n $module_backup ]]; then
    mv -f -- "$module_backup" "$module_file"
  else
    rm -f -- "$module_file"
  fi
  if [[ -n $bindings_backup ]]; then
    mv -f -- "$bindings_backup" "$bindings_file"
  elif [[ $bindings_existed -eq 0 ]]; then
    rm -f -- "$bindings_file"
  fi
  hyprctl reload >/dev/null 2>&1 || true
}

# Commit atomically: rename() replaces the destination in place and never
# follows a symlink that might appear there, so this is safe even if the
# guard above raced with something recreating the path.
mv -f -- "$new_module_tmp" "$module_file"
mv -f -- "$new_bindings_tmp" "$bindings_file"

reload_ok=1
hyprctl reload >/dev/null 2>&1 || reload_ok=0
errors=$(hyprctl configerrors 2>/dev/null || true)

if [[ $reload_ok -eq 0 || -n $errors ]]; then
  rollback
  echo "Error: Hyprland reload/config validation failed; previous configuration restored." >&2
  [[ -n $errors ]] && printf '%s\n' "$errors" >&2
  exit 1
fi

cleanup_backups

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
