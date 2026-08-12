#!/usr/bin/env bash
# Pin indicator for the auto-hide bar. Re-run on demand by lock-toggle.sh
# through RTMIN+9, never on a timer.
PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"

state=""
[[ -r "$PINNED_FILE" ]] && read -r state <"$PINNED_FILE" 2>/dev/null

if [[ "$state" == "1" ]]; then
    printf '{"text":"","class":"pinned","tooltip":"Bar pinned — click to auto-hide"}\n'
else
    printf '{"text":"","class":"unpinned","tooltip":"Bar auto-hides — click to pin"}\n'
fi
