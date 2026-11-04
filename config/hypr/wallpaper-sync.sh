#!/usr/bin/env bash
# Sync Waypaper choice → hyprpaper.conf (hyprpaper 0.8.4+ block syntax) and apply immediately
set -euo pipefail

INI="${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"

WP="${1:-}"
if [[ -z "$WP" && -f "$INI" ]]; then
    WP="$(grep -E '^wallpaper\s*=' "$INI" | head -1 | cut -d'=' -f2- | xargs || true)"
fi
[[ -z "$WP" ]] && exit 0

WP="${WP/#\~/$HOME}"
[[ -f "$WP" ]] || exit 0

# If conf is a symlink into the repo, replace with a real file so we don't dirty git
if [[ -L "$CONF" ]]; then
    rm -f "$CONF"
fi

cat > "$CONF" <<EOF
wallpaper {
    monitor =
    path = ${WP}
    fit_mode = cover
}
splash = false
EOF

# Restart hyprpaper so it loads the updated 0.8.4+ config block
pkill -x hyprpaper 2>/dev/null || true
sleep 0.15
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch 'hl.dsp.exec_cmd("hyprpaper")' >/dev/null 2>&1 \
        || (nohup hyprpaper >/dev/null 2>&1 &)
else
    nohup hyprpaper >/dev/null 2>&1 &
fi
