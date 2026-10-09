#!/usr/bin/env bash
# Connect JBL (or first A2DP headset) and force SBC playback
set -euo pipefail

# Device MAC from argument, environment variable, or auto-detect paired audio headset
MAC="${1:-${BT_HEADSET_MAC:-}}"
if [[ -z "$MAC" ]]; then
    MAC="$(bluetoothctl devices 2>/dev/null | grep -iE 'headset|headphone|jbl|buds|ear|sony|airpod|wh-|wf-|audio' | head -1 | awk '{print $2}' || true)"
    if [[ -z "$MAC" ]]; then
        MAC="$(bluetoothctl devices 2>/dev/null | head -1 | awk '{print $2}' || true)"
    fi
fi

if [[ -z "$MAC" ]]; then
    echo "No paired Bluetooth audio device found. Usage: $0 [MAC]"
    exit 0
fi

bluetoothctl power on >/dev/null
bluetoothctl connect "$MAC" >/dev/null || true

for _ in $(seq 1 15); do
    if pactl list short cards 2>/dev/null | grep -q bluez; then
        break
    fi
    sleep 0.4
done

CARD="$(pactl list short cards | awk '/bluez/{print $2; exit}')"
[[ -n "${CARD:-}" ]] || { echo "No Bluetooth audio card yet — wait 3s and retry"; exit 1; }

pactl set-card-profile "$CARD" a2dp-sink-sbc 2>/dev/null \
    || pactl set-card-profile "$CARD" a2dp-sink-sbc_xq 2>/dev/null \
    || pactl set-card-profile "$CARD" a2dp-sink

sleep 0.4
SINK="$(pactl list short sinks | awk '/bluez/{print $2; exit}')"
[[ -n "${SINK:-}" ]] || exit 1

pactl set-default-sink "$SINK"
pactl set-sink-mute "$SINK" 0
pactl set-sink-volume "$SINK" 80%
wpctl set-default "$(wpctl status | awk '/bluez_output|JBL/{print $1}' | tr -d '*.' | head -1)" 2>/dev/null || true

for i in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$i" "$SINK" 2>/dev/null || true
done

echo "Output: $SINK (profile A2DP/SBC)"
