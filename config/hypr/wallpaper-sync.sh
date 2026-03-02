#!/usr/bin/env bash
# waypaper post_command: seçilen wallpaper'ı hyprpaper.conf'a yaz
WP=$(grep "^wallpaper" ~/.config/waypaper/config.ini | cut -d'=' -f2 | xargs)
[ -z "$WP" ] && exit 0
WP="${WP/#\~/$HOME}"
cat > ~/.config/hypr/hyprpaper.conf << EOF
preload = ${WP}
wallpaper = ,${WP}
splash = false
EOF
