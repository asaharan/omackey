#!/usr/bin/env bash
set -euo pipefail

plugin_id="asaharan.omackey"

omarchy plugin disable "$plugin_id" >/dev/null 2>&1 || true
omarchy-shell shell rescanPlugins >/dev/null

echo "Omackey switcher UI disabled. Mac key bindings remain active."
