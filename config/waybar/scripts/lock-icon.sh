#!/usr/bin/env bash
PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"
if [[ -f "$PINNED_FILE" ]] && [[ "$(cat "$PINNED_FILE" 2>/dev/null)" == "1" ]]; then
    echo -e "\uf023"
else
    echo -e "\uf09c"
fi
