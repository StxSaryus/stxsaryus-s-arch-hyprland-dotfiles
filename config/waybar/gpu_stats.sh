#!/bin/bash
# NVIDIA GPU - kullanım % ve sıcaklık

GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')

if [ -z "$GPU_UTIL" ]; then
    echo "󰾲 N/A"
    exit 0
fi

echo "󰾲 ${GPU_UTIL}%  ${GPU_TEMP}°C"
