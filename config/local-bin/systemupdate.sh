#!/usr/bin/env bash
#
# Pending-update counter for Waybar.
#
#   systemupdate.sh          JSON for the bar
#   systemupdate.sh up       run the upgrade in a terminal
#   systemupdate.sh upgrade  plain text summary
#
set -uo pipefail

[[ -f /etc/arch-release ]] || exit 0

aurhlpr="yay"
command -v paru >/dev/null 2>&1 && aurhlpr="paru"
terminal="${TERMINAL:-kitty}"

if [[ "${1:-}" == "up" ]]; then
    trap 'pkill -RTMIN+20 -x waybar' EXIT
    "$terminal" --title systemupdate sh -c "
        command -v fastfetch >/dev/null && fastfetch
        $aurhlpr -Syu
        read -n 1 -r -p 'Press any key to close...'
    "
    exit 0
fi

aur=$($aurhlpr -Qua 2>/dev/null | wc -l)
ofc=$( (while pgrep -x checkupdates >/dev/null; do sleep 1; done); checkupdates 2>/dev/null | wc -l)
upd=$(( ofc + aur ))

if [[ "${1:-}" == "upgrade" ]]; then
    printf '[Official] %-10s\n[AUR]      %-10s\n' "$ofc" "$aur"
    exit 0
fi

if (( upd == 0 )); then
    printf '{"text":"󰸟","tooltip":"System is up to date","class":"empty"}\n'
else
    printf '{"text":"󰮯 %d","tooltip":"%d official · %d AUR\\nClick to upgrade","class":"pending"}\n' \
        "$upd" "$ofc" "$aur"
fi
