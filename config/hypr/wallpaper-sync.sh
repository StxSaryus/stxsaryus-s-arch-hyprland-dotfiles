#!/usr/bin/env bash
# Runs as waypaper's post_command: writes the wallpaper you just picked into
# hyprpaper.conf, so it is already on screen the next time you log in.
set -uo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
WP="$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$CONF/waypaper/config.ini" 2>/dev/null | head -1)"
[[ -z "$WP" ]] && exit 0

WP="${WP/#\~/$HOME}"
[[ -f "$WP" ]] || exit 0

cat >"$CONF/hypr/hyprpaper.conf" <<EOF
preload = ${WP}
wallpaper = ,contain:${WP}
splash = false
EOF
