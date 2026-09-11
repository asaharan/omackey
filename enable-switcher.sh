#!/bin/bash
set -euo pipefail

PATH=/usr/bin:/bin
export PATH

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Plugin-manager installs and updates do not install the compositor module.
exec /bin/bash "$project_dir/install.sh" --enable-switcher
