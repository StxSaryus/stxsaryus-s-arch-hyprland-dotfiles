#!/usr/bin/env bash
#
# CPU / GPU / RAM readout for Waybar.
#
# Everything comes straight out of /proc and /sys, so a refresh costs one
# bash process instead of the top + sensors + free + 2x nvidia-smi pipeline
# this used to run every two seconds. nvidia-smi is the only external
# command left and its result is cached, because it alone takes longer than
# all the /proc reads combined.
#
# Click the module to flip between load (%) and temperature.

set -uo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-sys-stats"
MODE_FILE="$STATE_DIR/mode"
CPU_FILE="$STATE_DIR/cpu"
GPU_FILE="$STATE_DIR/gpu"
GPU_TTL=5

mkdir -p "$STATE_DIR"

if [[ "${1:-}" == "toggle" ]]; then
    mode="perc"
    [[ -r "$MODE_FILE" ]] && read -r mode <"$MODE_FILE"
    [[ "$mode" == "perc" ]] && mode="temp" || mode="perc"
    printf '%s\n' "$mode" >"$MODE_FILE"
    pkill -RTMIN+8 -x waybar
    exit 0
fi

mode="perc"
[[ -r "$MODE_FILE" ]] && read -r mode <"$MODE_FILE"

# --- CPU load: delta of /proc/stat against the previous run -------------
read -r _ u n s i io irq sirq st _ </proc/stat
total=$((u + n + s + i + io + irq + sirq + st))
idle=$((i + io))

cpu_perc=0
if [[ -r "$CPU_FILE" ]]; then
    read -r prev_total prev_idle <"$CPU_FILE"
    d_total=$((total - prev_total))
    d_idle=$((idle - prev_idle))
    (( d_total > 0 )) && cpu_perc=$(( (100 * (d_total - d_idle) + d_total / 2) / d_total ))
fi
printf '%s %s\n' "$total" "$idle" >"$CPU_FILE"

# --- CPU temperature: first sensible hwmon/thermal zone -----------------
cpu_temp=""
for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    read -r hw_name <"$hw/name"
    case "$hw_name" in
        coretemp|k10temp|zenpower|cpu_thermal|acpitz)
            [[ -r "$hw/temp1_input" ]] && read -r cpu_temp <"$hw/temp1_input"
            ;;
    esac
    [[ -n "$cpu_temp" ]] && break
done
if [[ -z "$cpu_temp" && -r /sys/class/thermal/thermal_zone0/temp ]]; then
    read -r cpu_temp </sys/class/thermal/thermal_zone0/temp
fi
[[ -n "$cpu_temp" ]] && cpu_temp=$((cpu_temp / 1000))

# --- Memory from /proc/meminfo ------------------------------------------
mem_total=0 mem_avail=0
while read -r key value _; do
    case "$key" in
        MemTotal:)     mem_total=$value ;;
        MemAvailable:) mem_avail=$value; break ;;
    esac
done </proc/meminfo
mem_used=$((mem_total - mem_avail))
mem_perc=0
(( mem_total > 0 )) && mem_perc=$(( (100 * mem_used + mem_total / 2) / mem_total ))
mem_gib=$(( (mem_used * 10 + 524288) / 1048576 ))
mem_gib="${mem_gib:0:${#mem_gib}-1}.${mem_gib: -1}"
[[ "$mem_gib" == .* ]] && mem_gib="0$mem_gib"

# --- GPU, cached: nvidia-smi is by far the slowest call here ------------
gpu_util="" gpu_temp=""
if command -v nvidia-smi >/dev/null 2>&1; then
    now=$(printf '%(%s)T' -1)
    stamp=0
    if [[ -r "$GPU_FILE" ]]; then
        read -r stamp gpu_util gpu_temp <"$GPU_FILE" || stamp=0
    fi
    if (( now - stamp >= GPU_TTL )); then
        read -r gpu_util gpu_temp < <(
            nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
                       --format=csv,noheader,nounits 2>/dev/null | tr -d ' ' | tr ',' ' '
        )
        [[ -n "${gpu_util:-}" ]] && printf '%s %s %s\n' "$now" "$gpu_util" "$gpu_temp" >"$GPU_FILE"
    fi
fi

# --- Render --------------------------------------------------------------
if [[ "$mode" == "temp" ]]; then
    text="󰘚 ${cpu_temp:-–}°"
    [[ -n "$gpu_util" ]] && text+="  󰢮 ${gpu_temp:-–}°"
    text+="  󰍛 ${mem_gib}G"
else
    text="󰘚 ${cpu_perc}%"
    [[ -n "$gpu_util" ]] && text+="  󰢮 ${gpu_util}%"
    text+="  󰍛 ${mem_perc}%"
fi

tooltip="CPU  ${cpu_perc}%"
[[ -n "$cpu_temp" ]] && tooltip+="  ·  ${cpu_temp}°C"
if [[ -n "$gpu_util" ]]; then
    tooltip+="\nGPU  ${gpu_util}%"
    [[ -n "$gpu_temp" ]] && tooltip+="  ·  ${gpu_temp}°C"
fi
tooltip+="\nRAM  ${mem_perc}%  ·  ${mem_gib} GiB"
tooltip+="\n\nClick to switch to $([[ "$mode" == "temp" ]] && echo load || echo temperature)"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$mode"
