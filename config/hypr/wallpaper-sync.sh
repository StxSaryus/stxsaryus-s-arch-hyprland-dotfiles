#!/usr/bin/env bash
# Sync Waypaper choice → hyprpaper.conf and apply immediately
set -euo pipefail

INI="${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"

[[ -f "$INI" ]] || exit 0

WP="$(grep -E '^wallpaper\s*=' "$INI" | head -1 | cut -d'=' -f2- | xargs || true)"
[[ -z "$WP" ]] && exit 0

WP="${WP/#\~/$HOME}"
[[ -f "$WP" ]] || exit 0

# If conf is a symlink into the repo, replace with a real file so we don't dirty git
if [[ -L "$CONF" ]]; then
    rm -f "$CONF"
fi

cat > "$CONF" <<EOF
preload = ${WP}
wallpaper = ,${WP}
splash = false
EOF

# Apply live (Hyprland IPC) then fall back to restart
if command -v hyprctl >/dev/null && pgrep -x hyprpaper >/dev/null; then
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true
    hyprctl hyprpaper preload "$WP" >/dev/null 2>&1 || true
    hyprctl hyprpaper wallpaper ",$WP" >/dev/null 2>&1 || true
else
    pkill -x hyprpaper 2>/dev/null || true
    sleep 0.2
    hyprpaper >/dev/null 2>&1 &
fi
