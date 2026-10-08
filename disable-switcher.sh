#!/bin/bash
set -euo pipefail

PATH=/usr/bin:/bin
export PATH

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Also restores Omarchy's Super+Tab / Super+` / Super+Escape bindings.
exec /bin/bash "$project_dir/install.sh" --disable-switcher
