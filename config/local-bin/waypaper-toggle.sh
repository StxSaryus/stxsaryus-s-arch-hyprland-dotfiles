#!/usr/bin/env bash
# Toggle Waypaper from Waybar (do not pgrep -f "waypaper" — it matches this script)
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/bin:$PATH"

if ! command -v waypaper >/dev/null 2>&1; then
    notify-send -u critical "Waypaper missing" "Install: yay -S waypaper-git" 2>/dev/null || true
    exit 1
fi

if pgrep -x waypaper >/dev/null 2>&1; then
    pkill -x waypaper 2>/dev/null || true
    exit 0
fi

# Launch detached so Waybar does not kill the GTK window
if command -v hyprctl >/dev/null; then
    hyprctl dispatch exec "uwsm app -- waypaper" >/dev/null 2>&1 \
        || hyprctl dispatch exec waypaper >/dev/null 2>&1
else
    waypaper >/dev/null 2>&1 &
    disown || true
fi
