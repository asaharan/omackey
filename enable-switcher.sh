#!/usr/bin/env bash
set -euo pipefail

plugin_id="omackey"

omarchy plugin enable "$plugin_id" >/dev/null
omarchy-shell shell rescanPlugins >/dev/null

echo "Omackey switcher UI enabled. Hold Super and press Tab to switch windows."
