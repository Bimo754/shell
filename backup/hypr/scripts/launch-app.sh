#!/usr/bin/env bash
# ==============================================================================
# launch-app.sh - App Launcher Wrapper with Balanced Split for Hyprland
#
# Usage:
#   launch-app.sh <command> [args...]
# ==============================================================================

if [ -x "/home/diamond/.config/hypr/scripts/workspace-ctl.py" ]; then
    /home/diamond/.config/hypr/scripts/auto-arranger.py prepare >/dev/null 2>&1 || true
fi

exec "$@"
