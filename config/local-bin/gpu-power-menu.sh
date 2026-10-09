#!/usr/bin/env bash
# ============================================================
# StxSaryus — GPU & Power Profile Switcher (Waybar / Rofi)
# ============================================================

set -euo pipefail

PROFILE="$(powerprofilesctl get 2>/dev/null || echo "balanced")"
BAT_CAP="$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "N/A")"
BAT_STAT="$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo "Unknown")"
GPU_TEMP="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")"
GPU_UTIL="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")"

# Mark active profile with bullet indicator
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
OPT_ROCKET="🎮 Launch Rocket League (Dedicated NVIDIA GTX 1050 Ti)"
OPT_STATUS="📊 Telemetry (Battery: ${BAT_CAP}% | GPU: ${GPU_TEMP}°C ${GPU_UTIL}%)"

MENU=$(printf "%s\n%s\n%s\n%s\n%s" \
    "$OPT_POWERSAVE" \
    "$OPT_BALANCED" \
    "$OPT_PERF" \
    "$OPT_ROCKET" \
    "$OPT_STATUS")

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
        notify-send -u normal -a "Power Manager" -i video-display "Power Mode: Performance" "High Performance mode activated. CPU & GPU tuned for maximum FPS."
        ;;
    *"Launch Rocket League"*)
        notify-send -u normal -a "Steam" -i steam "Rocket League" "Launching Rocket League with dedicated NVIDIA GTX 1050 Ti..."
        nohup prime-run steam steam://rungameid/252950 >/dev/null 2>&1 &
        ;;
    *"Telemetry"*)
        PROCS="$(nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader 2>/dev/null || true)"
        [[ -z "$PROCS" ]] && PROCS="No active 3D compute processes"
        notify-send -u normal -a "Hardware Telemetry" -i video-display \
            "Battery & GPU Status" \
            "Battery: ${BAT_CAP}% (${BAT_STAT})\nGPU Temp: ${GPU_TEMP}°C | Usage: ${GPU_UTIL}%\nProcesses:\n${PROCS}"
        ;;
esac
