#!/usr/bin/env bash
#
# Renders the rice without a real login session and saves screenshots.
#
# Hyprland needs a seat and a GPU, so this drives a headless sway instead:
# same wlroots, same layer-shell, same GTK. Waybar, SwayNC and Kitty run
# their shipped configs unmodified — only the two compositor-specific Waybar
# modules are swapped (see make-preview-config.py). It is enough to catch
# what static checks cannot: a stylesheet rule that never matches, an icon
# that renders as an empty box, a module that quietly fails to appear.
#
#   ./tests/preview/run-preview.sh [output-dir]
#
# FAKE_HARDWARE=1 additionally bind-mounts a synthetic /sys/class/power_supply
# (needs sudo) so the battery module has something to show.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:-$ROOT/.preview}"
WORK="$(mktemp -d)"
STAGE="$WORK/home"

need() {
    local missing=()
    local cmd
    for cmd in "$@"; do command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd"); done
    if (( ${#missing[@]} )); then
        echo "missing: ${missing[*]}" >&2
        echo "install sway, waybar, grim and imagemagick to run the preview" >&2
        exit 1
    fi
}
need sway waybar grim convert python3

cleanup() {
    [[ -n "${WAYBAR_PID:-}" ]] && kill "$WAYBAR_PID" 2>/dev/null
    [[ -n "${SWAY_PID:-}" ]] && kill "$SWAY_PID" 2>/dev/null
    [[ "${FAKE_HARDWARE:-0}" == "1" ]] && sudo umount /sys/class/power_supply 2>/dev/null
    rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$OUT" "$WORK/run" "$STAGE"
chmod 700 "$WORK/run"

echo "── installing the dotfiles into a throwaway home ──"
HOME="$STAGE" "$ROOT/install.sh" --configs >"$WORK/install.log" 2>&1 || {
    tail -20 "$WORK/install.log"; exit 1
}
echo 1 >"$STAGE/.config/waybar/.pinned"     # pinned, so the bar is on screen
mkdir -p "$STAGE/.local/share"
[[ -d "$HOME/.local/share/fonts" ]] && ln -sfn "$HOME/.local/share/fonts" "$STAGE/.local/share/fonts"

python3 "$ROOT/tests/preview/make-preview-config.py" \
    "$STAGE/.config/waybar/config.jsonc" "$STAGE/.config/waybar/preview.jsonc"

if [[ "${FAKE_HARDWARE:-0}" == "1" ]]; then
    echo "── faking a battery ──"
    bat="$WORK/power/BAT0"
    mkdir -p "$bat"
    printf 'Battery\n' >"$bat/type"
    printf 'Discharging\n' >"$bat/status"
    printf '76\n' >"$bat/capacity"
    printf '45000000\n' >"$bat/energy_now"
    printf '60000000\n' >"$bat/energy_full"
    printf '11800000\n' >"$bat/power_now"
    printf 'POWER_SUPPLY_NAME=BAT0\nPOWER_SUPPLY_TYPE=Battery\n' >"$bat/uevent"
    sudo mount --bind "$WORK/power" /sys/class/power_supply
fi

echo "── starting headless sway ──"
cat >"$WORK/sway.conf" <<EOF
output HEADLESS-1 resolution 1920x1080
default_border pixel 2
client.focused #33ccff #33ccff #e6e9f0 #33ccff #33ccff
client.unfocused #3a4152 #3a4152 #b6bdcd #3a4152 #3a4152
gaps inner 6
gaps outer 12
seat * hide_cursor 1
EOF

export XDG_RUNTIME_DIR="$WORK/run"
export WLR_BACKENDS=headless
export WLR_LIBINPUT_NO_DEVICES=1
sway -c "$WORK/sway.conf" >"$WORK/sway.log" 2>&1 &
SWAY_PID=$!
sleep 5

export WAYLAND_DISPLAY=wayland-1
SWAYSOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' | head -1)"
export SWAYSOCK
[[ -S "${SWAYSOCK:-}" ]] || { echo "sway did not come up:"; tail -10 "$WORK/sway.log"; exit 1; }

export HOME="$STAGE"
export XDG_CONFIG_HOME="$STAGE/.config"

echo "── opening windows ──"
if command -v kitty >/dev/null 2>&1; then
    for ws in 1 3 4; do
        swaymsg "workspace $ws" >/dev/null
        setsid kitty -o confirm_os_window_close=0 bash -c 'exec sleep 900' >/dev/null 2>&1 &
        sleep 2
    done
    swaymsg "workspace 2" >/dev/null
    setsid kitty --title "dotfiles" -o confirm_os_window_close=0 \
        bash -c "cd '$ROOT'; git log --oneline -5; echo; ls --color=auto config; echo; exec bash --rcfile '$STAGE/.bashrc' -i" >/dev/null 2>&1 &
    sleep 3
fi

echo "── starting waybar ──"
waybar -c "$STAGE/.config/waybar/preview.jsonc" -s "$STAGE/.config/waybar/style.css" \
    >"$WORK/waybar.log" 2>&1 &
WAYBAR_PID=$!
sleep 5
pkill -SIGUSR1 -x waybar     # the same signal the auto-hide script sends
sleep 3

grim "$OUT/desktop.png"
convert "$OUT/desktop.png" -crop 960x48+0+0 -resize 200% "$WORK/l.png"
convert "$OUT/desktop.png" -crop 960x48+960+0 -resize 200% "$WORK/r.png"
convert "$WORK/l.png" "$WORK/r.png" -append "$OUT/waybar.png"

echo
echo "screenshots in $OUT:"
ls -1 "$OUT"
echo
echo "waybar had this to say:"
grep -vE "\[info\]" "$WORK/waybar.log" | sed 's/^/  /' | head -10
