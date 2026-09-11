#!/bin/bash
set -euo pipefail

PATH=/usr/bin:/bin
export PATH

plugin_id="asaharan.omackey"

omarchy plugin disable "$plugin_id" >/dev/null 2>&1 || true
omarchy-shell shell rescanPlugins >/dev/null

echo "Omackey switcher UI disabled. Mac key bindings remain active."
