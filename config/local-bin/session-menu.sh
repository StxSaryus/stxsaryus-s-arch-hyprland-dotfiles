#!/usr/bin/env bash
#
# Opens the nwg-bar session menu.
#
# Waybar throws away whatever its click command prints, so a missing nwg-bar
# is indistinguishable from a dead button. This complains instead, through
# hyprctl notify, which is part of Hyprland itself and works whether or not
# a notification daemon is running.
set -uo pipefail

complain() {
    hyprctl notify 3 6000 "rgb(f38ba8)" "$1" >/dev/null 2>&1
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -a "Session" -u critical "Session menu" "$1"
    echo "session-menu: $1" >&2
}

# nwg-bar toggles itself: a second instance signals the first to quit.
for candidate in nwg-bar "$HOME/.local/bin/nwg-bar" "$HOME/go/bin/nwg-bar" /usr/local/bin/nwg-bar; do
    if command -v "$candidate" >/dev/null 2>&1; then
        exec "$candidate" -f -p center
    fi
done

complain "nwg-bar is not installed — run: sudo pacman -S nwg-bar"
exit 1
