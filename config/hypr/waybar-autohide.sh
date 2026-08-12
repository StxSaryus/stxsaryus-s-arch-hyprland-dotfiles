#!/usr/bin/env bash
#
# Windows 11 style auto-hide for Waybar.
#
# Reveals the bar when the pointer reaches the top edge, hides it once the
# pointer moves away, and stays out of the way entirely while the bar is
# pinned. Polling is adaptive and everything except `hyprctl cursorpos` runs
# on bash builtins, so idling costs one short-lived process every quarter of
# a second instead of four of them ten times a second.

set -uo pipefail

PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-autohide.lock"

SHOW_ZONE=22        # pointer above this y reveals the bar
HIDE_ZONE=48        # pointer below this y hides it again
POLL_NEAR=0.08      # pointer close to the top edge, or bar visible
POLL_FAR=0.25       # pointer parked in the middle of the screen
NEAR_ZONE=240       # below this y we consider the pointer "close"
WAYBAR_CHECK=20     # re-check that waybar is alive every N iterations

# Only one watcher per session.
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# A read with a timeout on an idle fifo is a sleep that costs no process.
# At four polls a second that is ~350k processes a day not spawned.
SNOOZE_FIFO="${XDG_RUNTIME_DIR:-/tmp}/waybar-autohide.snooze.$$"
if mkfifo -m 600 "$SNOOZE_FIFO" 2>/dev/null && exec 8<>"$SNOOZE_FIFO"; then
    rm -f "$SNOOZE_FIFO"
    snooze() { read -r -t "$1" -u 8 _ || true; }
else
    snooze() { sleep "$1"; }
fi

show_bar() { pkill -SIGUSR1 -x waybar 2>/dev/null; }
hide_bar() { pkill -SIGUSR2 -x waybar 2>/dev/null; }

is_pinned() {
    local value=""
    [[ -r "$PINNED_FILE" ]] && read -r value <"$PINNED_FILE" 2>/dev/null
    [[ "$value" == "1" ]]
}

# Puts the pointer's y coordinate in $CURSOR_Y. Returns non-zero when
# Hyprland is not answering. Assigning a global rather than echoing keeps
# this to a single fork per poll.
CURSOR_Y=0
cursor_y() {
    local pos
    pos="$(hyprctl cursorpos 2>/dev/null)" || return 1
    pos="${pos#*,}"
    pos="${pos// /}"
    [[ "$pos" =~ ^[0-9]+$ ]] || return 1
    CURSOR_Y="$pos"
}

snooze 1.5

if is_pinned; then
    show_bar
    was_pinned=1
    visible=1
else
    was_pinned=0
    visible=0
fi

ticks=0
waybar_alive=1

while true; do
    (( ticks++ ))
    if (( ticks % WAYBAR_CHECK == 0 )); then
        pgrep -x waybar >/dev/null && waybar_alive=1 || waybar_alive=0
    fi
    if (( waybar_alive == 0 )); then
        snooze 1
        continue
    fi

    pinned=0
    is_pinned && pinned=1

    if (( pinned != was_pinned )); then
        if (( pinned == 1 )); then
            show_bar
            visible=1
        else
            # Unpinning should not yank the bar away from under the pointer.
            if cursor_y && (( CURSOR_Y > HIDE_ZONE )); then
                hide_bar
                visible=0
            fi
        fi
        was_pinned=$pinned
    fi

    if (( pinned == 1 )); then
        snooze 0.4
        continue
    fi

    cursor_y || { snooze "$POLL_FAR"; continue; }

    if (( visible == 0 )); then
        if (( CURSOR_Y < SHOW_ZONE )); then
            show_bar
            visible=1
        fi
    elif (( CURSOR_Y > HIDE_ZONE )); then
        hide_bar
        visible=0
    fi

    if (( visible == 1 || CURSOR_Y < NEAR_ZONE )); then
        snooze "$POLL_NEAR"
    else
        snooze "$POLL_FAR"
    fi
done
