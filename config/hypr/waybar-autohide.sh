#!/usr/bin/env bash
# Tek instance koruması
if pidof -x -o $$ "$(basename "$0")" > /dev/null 2>&1; then
    exit 0
fi

PINNED_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.pinned"
SHOW_ZONE=22
HIDE_ZONE=48

show_bar() { killall -SIGUSR1 waybar 2>/dev/null; }
hide_bar() { killall -SIGUSR2 waybar 2>/dev/null; }

is_pinned() {
    [[ -f "$PINNED_FILE" ]] && [[ "$(cat "$PINNED_FILE" 2>/dev/null)" == "1" ]]
}

sleep 1.5
if is_pinned; then
    show_bar
    was_pinned=1
    visible=1
else
    was_pinned=0
    visible=0
fi

while true; do
    sleep 0.10
    pgrep -x waybar >/dev/null || continue

    pinned=0
    is_pinned && pinned=1

    # Kilit durumu değiştiyse
    if (( pinned != was_pinned )); then
        if (( pinned == 1 )); then
            show_bar
            visible=1
        else
            # Kilitten çıkınca: hemen gizleme, fare pozisyonuna bak
            y=$(hyprctl cursorpos 2>/dev/null | awk -F', ' '{print $2}' | tr -d ' ')
            if [[ "$y" =~ ^[0-9]+$ ]] && (( y > HIDE_ZONE )); then
                hide_bar
                visible=0
            fi
        fi
        was_pinned=$pinned
    fi

    # Kilitliyse dokunma
    (( pinned == 1 )) && continue

    y=$(hyprctl cursorpos 2>/dev/null | awk -F', ' '{print $2}' | tr -d ' ')
    [[ -z "$y" || ! "$y" =~ ^[0-9]+$ ]] && continue

    if (( visible == 0 )); then
        if (( y < SHOW_ZONE )); then
            show_bar
            visible=1
        fi
    else
        if (( y > HIDE_ZONE )); then
            hide_bar
            visible=0
        fi
    fi
done
