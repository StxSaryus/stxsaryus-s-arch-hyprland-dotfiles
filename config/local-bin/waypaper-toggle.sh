#!/usr/bin/env bash
#
# Opens the wallpaper picker, or closes it if it is already open.
#
# Waybar swallows anything its click command prints, so a missing or crashing
# Waypaper used to look exactly like a dead icon. This says so out loud
# instead.
set -uo pipefail

if pgrep -x waypaper >/dev/null 2>&1; then
    pkill -x waypaper
    exit 0
fi

if ! command -v waypaper >/dev/null 2>&1; then
    notify-send -a "Wallpaper" -u critical \
        "Waypaper is not installed" "Install it with: yay -S waypaper-git"
    exit 1
fi

# Detached, so the picker outlives the bar's click handler.
setsid waypaper >/dev/null 2>&1 &
