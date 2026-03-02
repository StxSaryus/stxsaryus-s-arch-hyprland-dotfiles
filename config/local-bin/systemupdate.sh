#!/usr/bin/env bash

if [ ! -f /etc/arch-release ]; then
    exit 0
fi

aurhlpr="yay"
which paru &>/dev/null && aurhlpr="paru"

if [ "$1" == "up" ]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    command="
    fastfetch
    $aurhlpr -Syu
    read -n 1 -p 'Press any key to continue...'
    "
    kitty --title systemupdate sh -c "${command}"
    exit 0
fi

aur=$($aurhlpr -Qua 2>/dev/null | wc -l)
ofc=$( (while pgrep -x checkupdates > /dev/null; do sleep 1; done); checkupdates 2>/dev/null | wc -l)

upd=$(( ofc + aur ))

if [ "$1" == "upgrade" ]; then
    printf "[Official] %-10s\n[AUR]      %-10s\n" "$ofc" "$aur"
    exit 0
fi

if [ $upd -eq 0 ]; then
    echo '{"text":"", "tooltip":" Packages are up to date"}'
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\"}"
fi
