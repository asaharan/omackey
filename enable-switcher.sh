#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Plugin-manager installs and updates do not install the compositor module.
exec bash "$project_dir/install.sh" --enable-switcher
