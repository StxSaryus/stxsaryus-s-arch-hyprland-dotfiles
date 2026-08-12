#!/usr/bin/env bash
#
# One on-screen display for every hardware key, so brightness, volume and
# mute all look and behave the same.
#
#   osd.sh brightness up|down
#   osd.sh volume     up|down|mute
#   osd.sh mic        mute
#
set -uo pipefail

STEP=5
domain="${1:-}"
action="${2:-}"

notify() {
    # tag keeps a key repeat from stacking notifications
    local tag="$1" title="$2" body="$3" icon="$4" value="${5:-}"
    local args=(-a "osd" -u low -t 1500 -i "$icon"
                -h "string:x-canonical-private-synchronous:$tag"
                -h "string:synchronous:$tag")
    [[ -n "$value" ]] && args+=(-h "int:value:$value")

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "${args[@]}" "$title" "$body"
    elif command -v dunstify >/dev/null 2>&1; then
        dunstify -r 9111 "${args[@]}" "$title" "$body"
    fi
}

case "$domain" in
    brightness)
        case "$action" in
            up)   brightnessctl set "+${STEP}%" >/dev/null 2>&1 ;;
            down) brightnessctl set "${STEP}%-" >/dev/null 2>&1 ;;
        esac
        percent="$(brightnessctl -m | awk -F, '{ gsub("%","",$4); print $4 }')"
        icon="display-brightness-symbolic"
        (( percent < 34 )) && icon="display-brightness-low-symbolic"
        notify brightness "Brightness" "${percent}%" "$icon" "$percent"
        ;;

    volume)
        case "$action" in
            up)   pamixer -i "$STEP" >/dev/null 2>&1 ;;
            down) pamixer -d "$STEP" >/dev/null 2>&1 ;;
            mute) pamixer -t >/dev/null 2>&1 ;;
        esac
        percent="$(pamixer --get-volume 2>/dev/null || echo 0)"
        if [[ "$(pamixer --get-mute 2>/dev/null)" == "true" ]]; then
            notify volume "Volume" "Muted" "audio-volume-muted-symbolic" 0
        else
            icon="audio-volume-high-symbolic"
            (( percent < 34 )) && icon="audio-volume-low-symbolic"
            (( percent >= 34 && percent < 67 )) && icon="audio-volume-medium-symbolic"
            notify volume "Volume" "${percent}%" "$icon" "$percent"
        fi
        ;;

    mic)
        pamixer --default-source -t >/dev/null 2>&1
        if [[ "$(pamixer --default-source --get-mute 2>/dev/null)" == "true" ]]; then
            notify mic "Microphone" "Muted" "microphone-disabled-symbolic"
        else
            notify mic "Microphone" "Live" "microphone-sensitivity-high-symbolic"
        fi
        ;;

    *)
        echo "usage: osd.sh brightness up|down | volume up|down|mute | mic mute" >&2
        exit 1
        ;;
esac
