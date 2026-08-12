#!/usr/bin/env bash
# Pin / unpin the bar and refresh the indicator immediately.
PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"
mkdir -p "$(dirname "$PINNED_FILE")"

state=""
[[ -r "$PINNED_FILE" ]] && read -r state <"$PINNED_FILE" 2>/dev/null

if [[ "$state" == "1" ]]; then
    printf '0\n' >"$PINNED_FILE"
else
    printf '1\n' >"$PINNED_FILE"
fi

pkill -RTMIN+9 -x waybar 2>/dev/null || true
