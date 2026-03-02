#!/usr/bin/env bash

if pgrep -x rofi >/dev/null; then
  pkill -x rofi
else
  rofi -show drun -config ~/.config/rofi/config.rasi
fi
