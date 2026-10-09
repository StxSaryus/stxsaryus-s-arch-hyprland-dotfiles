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

OPT_POWERSAVE="🔋 Integrated Mode (Power Saver - Intel Only)${PS_ACTIVE}"
OPT_BALANCED="⚖️ Hybrid Mode (Balanced - Intel + NVIDIA On-Demand)${BAL_ACTIVE}"
OPT_PERF="🚀 Performance Mode (Dedicated NVIDIA High-Power)${PERF_ACTIVE}"
OPT_STATS="📊 Telemetry: CPU ${CPU_UTIL} | GPU ${GPU_UTIL} (${GPU_TEMP}) | Battery ${BAT_CAP}% (${BAT_STAT})"

MENU=$(printf "%s\n%s\n%s\n%s" \
    "$OPT_POWERSAVE" \
    "$OPT_BALANCED" \
    "$OPT_PERF" \
    "$OPT_STATS")

CHOICE=$(echo "$MENU" | rofi -dmenu -i -p "⚡ Power & GPU" -config "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi" || true)

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    *"Integrated Mode"*)
        powerprofilesctl set power-saver 2>/dev/null || true
        notify-send -u low -a "Power Manager" -i battery "Power Mode: Integrated" "Power Saver activated. Intel HD 630 primary, NVIDIA discrete GPU idle."
        ;;
    *"Hybrid Mode"*)
        powerprofilesctl set balanced 2>/dev/null || true
        notify-send -u normal -a "Power Manager" -i preferences-system-performance "Power Mode: Hybrid" "Balanced profile activated. Intel for desktop, NVIDIA available for offload (prime-run)."
        ;;
    *"Performance Mode"*)
        powerprofilesctl set performance 2>/dev/null || true
        notify-send -u normal -a "Power Manager" -i video-display "Power Mode: Performance" "High Performance mode activated. CPU & GPU tuned for maximum performance."
        ;;
    *"Telemetry"*)
        PROCS="$(nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader 2>/dev/null || true)"
        [[ -z "$PROCS" ]] && PROCS="No active 3D compute processes"
        notify-send -u normal -a "Hardware Telemetry" -i video-display \
            "Hardware Status" \
            "CPU Usage: ${CPU_UTIL}\nGPU: ${GPU_UTIL} (${GPU_TEMP})\nBattery: ${BAT_CAP}% (${BAT_STAT})\nActive GPU Processes:\n${PROCS}"
        ;;
esac
