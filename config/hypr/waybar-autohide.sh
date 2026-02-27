#!/usr/bin/env bash
# Win11 tarzı: fare üst kenara gelince waybar görünsün, ayrılınca gizlensin.
# Hyprland ile kullan (hyprctl cursorpos).

TOP_PX=55

# Waybar başlasın diye kısa bekle, sonra gizle
sleep 1.5
if pgrep -x waybar >/dev/null; then
    kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
    visible=0
else
    visible=1
fi

while true; do
    sleep 0.12
    pgrep -x waybar >/dev/null || continue
    y=$(hyprctl cursorpos 2>/dev/null | awk -F', ' '{print $2}' | tr -d ' ')
    [[ -z "$y" || ! "$y" =~ ^[0-9]+$ ]] && continue
    if (( y < TOP_PX )); then
        if (( visible == 0 )); then
            kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
            visible=1
        fi
    else
        if (( visible == 1 )); then
            kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
            visible=0
        fi
    fi
done
