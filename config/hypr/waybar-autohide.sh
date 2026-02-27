#!/usr/bin/env bash
# Waybar: üstte tetiklenir, fare barın altına inince kapanır.
# Tetikleme şeridi Firefox sekmelerinin üstünde kalacak şekilde ayarlı.

# Waybar config: margin top=6, height=40 → bar Y=6..46

# Waybar AÇILIR: sadece bu Y değerinin üstünde (ekranın en üst şeridi)
# 22px = sekme çubuğunun üstü, rahat tetiklenir
SHOW_WHEN_Y_BELOW=22
# Waybar KAPANIR: fare barın altına indiğinde
HIDE_WHEN_Y_ABOVE=48

# Açıldıktan sonra bu kadar döngü boyunca kapatma (titreme önleme, ~0.3 sn)
SKIP_HIDE_COUNT=3

# Waybar başlasın diye kısa bekle, sonra gizle
sleep 1.5
if pgrep -x waybar >/dev/null; then
    kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
    visible=0
else
    visible=1
fi
skip_hide=0

while true; do
    sleep 0.10
    pgrep -x waybar >/dev/null || continue
    y=$(hyprctl cursorpos 2>/dev/null | awk -F', ' '{print $2}' | tr -d ' ')
    [[ -z "$y" || ! "$y" =~ ^[0-9]+$ ]] && continue

    if (( visible == 0 )); then
        # Gizli: üst şeritte waybar aç
        if (( y < SHOW_WHEN_Y_BELOW )); then
            kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
            visible=1
            skip_hide=$SKIP_HIDE_COUNT
        fi
    else
        # Az önce açıldıysa birkaç döngü kapatma (titreme önleme)
        if (( skip_hide > 0 )); then
            (( skip_hide-- ))
        else
            # Fare barın altına inince kapat
            if (( y > HIDE_WHEN_Y_ABOVE )); then
                kill -SIGUSR1 "$(pgrep -x waybar)" 2>/dev/null
                visible=0
            fi
        fi
    fi
done
