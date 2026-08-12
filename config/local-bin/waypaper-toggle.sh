#!/usr/bin/env bash
#
# Opens the wallpaper picker, or closes it if it is already open.
#
# Waybar throws away whatever its click command prints, so a missing or
# crashing Waypaper is indistinguishable from a dead button. This complains
# instead, through hyprctl notify, which is part of Hyprland itself and works
# whether or not a notification daemon is running.
set -uo pipefail

complain() {
    hyprctl notify 3 6000 "rgb(f38ba8)" "$1" >/dev/null 2>&1
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -a "Wallpaper" -u critical "Wallpaper picker" "$1"
    echo "waypaper-toggle: $1" >&2
}

if pgrep -x waypaper >/dev/null 2>&1; then
    pkill -x waypaper
    exit 0
fi

waypaper_bin=""
for candidate in waypaper "$HOME/.local/bin/waypaper" /usr/local/bin/waypaper; do
    if command -v "$candidate" >/dev/null 2>&1; then
        waypaper_bin="$candidate"
        break
    fi
done

if [[ -z "$waypaper_bin" ]]; then
    complain "Waypaper is not installed — run: yay -S waypaper-git"
    exit 1
fi

# Detached, so the picker outlives the bar's click handler. If it dies on
# the spot, say so rather than leaving the button looking broken.
log="${XDG_RUNTIME_DIR:-/tmp}/waypaper.log"
setsid "$waypaper_bin" >"$log" 2>&1 &
sleep 1.5
if ! pgrep -x waypaper >/dev/null 2>&1; then
    complain "Waypaper exited immediately — see $log"
    exit 1
fi
