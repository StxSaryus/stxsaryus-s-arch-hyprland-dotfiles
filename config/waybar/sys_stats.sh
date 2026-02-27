#!/bin/bash
STATE_FILE="/tmp/waybar_stats_state"
[ ! -f "$STATE_FILE" ] && echo "perc" > "$STATE_FILE"

if [[ "$1" == "toggle" ]]; then
    [[ "$(cat $STATE_FILE)" == "perc" ]] && echo "temp" > "$STATE_FILE" || echo "perc" > "$STATE_FILE"
    pkill -RTMIN+8 waybar
    exit
fi

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | cut -d. -f1)
CPU_TEMP=$(sensors | grep "Core 0" | awk '{print $3}' | tr -d '+°C' | cut -d. -f1)
MEM_PERC=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
MEM_USED=$(free -m | awk '/Mem:/ {printf "%.1f", $3/1024}')
GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")

CUR=$(cat $STATE_FILE)

if [[ "$CUR" == "perc" ]]; then
    echo "󰻠 CPU:$CPU_USAGE% 󰢮 GPU:$GPU_USAGE% 󰍛 RAM:$MEM_PERC%"
else
    echo "󰻠 CPU:$CPU_TEMP° 󰢮 GPU:$GPU_TEMP° 󰍛 RAM:$MEM_USED GB"
fi
