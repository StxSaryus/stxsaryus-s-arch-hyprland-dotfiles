#!/usr/bin/env bash
PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"
mkdir -p "$(dirname "$PINNED_FILE")"
if [[ -f "$PINNED_FILE" ]] && [[ "$(cat "$PINNED_FILE" 2>/dev/null)" == "1" ]]; then
    echo "0" > "$PINNED_FILE"
else
    echo "1" > "$PINNED_FILE"
fi
