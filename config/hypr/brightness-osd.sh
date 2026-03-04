#!/usr/bin/env bash

# usage: brightness-osd.sh up|down
step=5
case "$1" in
  up)   brightnessctl set +${step}% >/dev/null 2>&1 ;;
  down) brightnessctl set ${step}%- >/dev/null 2>&1 ;;
  *)    brightnessctl set +0% >/dev/null 2>&1 ;;
esac

# Get current brightness percentage
percent=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')

# Show notification via dunst (replace existing if any)
if command -v dunstify >/dev/null 2>&1; then
  dunstify -r 9111 -u low "Brightness" "${percent}%" \
    -h int:value:"${percent}" \
    -i display-brightness
fi
