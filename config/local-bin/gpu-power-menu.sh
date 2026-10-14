#!/usr/bin/env bash
# ============================================================
# StxSaryus — Power & GPU Profile Switcher (Waybar / Rofi)
# ============================================================

set -euo pipefail

# 1. Current power profile
PROFILE="$(powerprofilesctl get 2>/dev/null || echo "balanced")"

# 2. Live CPU usage
CPU_UTIL="$(top -bn1 | grep 'Cpu(s)' | awk '{printf "%.0f%%", 100 - $8}' 2>/dev/null || echo "N/A")"

# 3. Live GPU stats
GPU_RAW="$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || true)"
if [[ -n "$GPU_RAW" ]]; then
    GPU_UTIL="$(echo "$GPU_RAW" | awk -F', ' '{print $1}')%"
    GPU_TEMP="$(echo "$GPU_RAW" | awk -F', ' '{print $2}')°C"
else
    GPU_UTIL="0%"
    GPU_TEMP="N/A"
fi

# 4. Live Battery stats
BAT_CAP="$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "N/A")"
BAT_STAT="$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo "Unknown")"

# 5. Active profile indicator
PS_ACTIVE=""
BAL_ACTIVE=""
PERF_ACTIVE=""

case "$PROFILE" in
    power-saver) PS_ACTIVE="  ● [Active]" ;;
    performance) PERF_ACTIVE="  ● [Active]" ;;
    *)           BAL_ACTIVE="  ● [Active]" ;;
esac

send_notification() {
    local title="$1" body="$2" icon="${3:-preferences-system-performance}" urgency="${4:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Power Manager" -i "$icon" -u "$urgency" "$title" "$body" 2>/dev/null || true
    else
        python3 - "$title" "$body" "$icon" <<'PYEOF' 2>/dev/null || true
import sys, dbus
title, body, icon = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    bus = dbus.SessionBus()
    notify_obj = bus.get_object('org.freedesktop.Notifications', '/org/freedesktop/Notifications')
    notify_iface = dbus.Interface(notify_obj, 'org.freedesktop.Notifications')
    notify_iface.Notify('Power Manager', 0, icon, title, body, [], {}, 6000)
except Exception:
    pass
PYEOF
    fi
}

OPT_POWERSAVE="🔋 Integrated Mode (Power Saver - iGPU Only)${PS_ACTIVE}"
OPT_BALANCED="⚖️ Hybrid Mode (Balanced - iGPU + dGPU On-Demand)${BAL_ACTIVE}"
OPT_PERF="🚀 Performance Mode (Dedicated GPU High-Power)${PERF_ACTIVE}"
OPT_STATS="📊 Telemetry: CPU ${CPU_UTIL} | GPU ${GPU_UTIL} (${GPU_TEMP}) | Battery ${BAT_CAP}% (${BAT_STAT})"
OPT_WIZARD="🔧 Hardware Wizard (Scan & Setup Drivers)"
OPT_SENTINEL="🛡️ Hardware Sentinel (Driver & Health Check)"

MENU=$(printf "%s\n%s\n%s\n%s\n%s\n%s" \
    "$OPT_POWERSAVE" \
    "$OPT_BALANCED" \
    "$OPT_PERF" \
    "$OPT_STATS" \
    "$OPT_WIZARD" \
    "$OPT_SENTINEL")

CHOICE=$(echo "$MENU" | rofi -dmenu -i -p "⚡ Power & GPU" -config "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi" || true)

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    *"Integrated Mode"*)
        powerprofilesctl set power-saver 2>/dev/null || true
        send_notification "Power Mode: Integrated" "Power Saver activated. Integrated GPU primary, discrete GPU idle." "battery" "low"
        ;;
    *"Hybrid Mode"*)
        powerprofilesctl set balanced 2>/dev/null || true
        send_notification "Power Mode: Hybrid" "Balanced profile activated. iGPU for desktop, dGPU available for offload (prime-run)." "preferences-system-performance" "normal"
        ;;
    *"Performance Mode"*)
        powerprofilesctl set performance 2>/dev/null || true
        send_notification "Power Mode: Performance" "High Performance mode activated. CPU & GPU tuned for maximum performance." "video-display" "normal"
        ;;
    *"Telemetry"*)
        PROCS="$(nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader 2>/dev/null || true)"
        [[ -z "$PROCS" ]] && PROCS="No active 3D compute processes"
        send_notification "Hardware Status" "CPU Usage: ${CPU_UTIL}\nGPU: ${GPU_UTIL} (${GPU_TEMP})\nBattery: ${BAT_CAP}% (${BAT_STAT})\nActive GPU Processes:\n${PROCS}" "video-display" "normal"
        ;;
    *"Hardware Sentinel"*)
        if [[ -x "$HOME/.local/share/bin/hardware-sentinel.sh" ]]; then
            "$HOME/.local/share/bin/hardware-sentinel.sh" --force &
        elif [[ -x "$HOME/dotfiles/config/local-bin/hardware-sentinel.sh" ]]; then
            "$HOME/dotfiles/config/local-bin/hardware-sentinel.sh" --force &
        fi
        ;;
    *"Hardware Wizard"*)
        if command -v kitty >/dev/null; then
            kitty --title "Hardware Wizard" -e bash -c "hardware-wizard.sh; echo ''; read -rp 'Press Enter to exit...' dummy" &
        elif command -v alacritty >/dev/null; then
            alacritty -t "Hardware Wizard" -e bash -c "hardware-wizard.sh; echo ''; read -rp 'Press Enter to exit...' dummy" &
        elif command -v foot >/dev/null; then
            foot -T "Hardware Wizard" bash -c "hardware-wizard.sh; echo ''; read -rp 'Press Enter to exit...' dummy" &
        else
            x-terminal-emulator -e bash -c "hardware-wizard.sh; echo ''; read -rp 'Press Enter to exit...' dummy" &
        fi
        ;;
esac
