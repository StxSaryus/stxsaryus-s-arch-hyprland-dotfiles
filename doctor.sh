#!/usr/bin/env bash
#
# Checks a live installation of this rice and says what is wrong.
#
#   ./doctor.sh
#
# Read-only: it starts nothing, kills nothing and changes nothing. Every
# failure line ends with the command that fixes it.
#
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PROBLEMS=0
FIXES=()

ok()   { printf '  %b✔%b %s\n' "$GREEN" "$NC" "$1"; }
bad()  { printf '  %b✘%b %s\n' "$RED" "$NC" "$1"; (( PROBLEMS++ )); [[ -n "${2:-}" ]] && FIXES+=("$2"); }
warn() { printf '  %b!%b %s\n' "$YELLOW" "$NC" "$1"; }
note() { printf '    %b%s%b\n' "$DIM" "$1" "$NC"; }
head_() { printf '\n%b── %s ──%b\n' "$BOLD" "$1" "$NC"; }

CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/share/bin"

# ── The programs every shortcut and button depends on ────────
head_ "Programs"

check_cmd() {
    local cmd="$1" why="$2" fix="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd — $why"
    else
        bad "$cmd is missing — $why" "$fix"
    fi
}

check_cmd hyprctl      "Hyprland control"              "sudo pacman -S hyprland"
check_cmd waybar       "the bar"                       "sudo pacman -S waybar"
check_cmd rofi         "Super+Space launcher"          "sudo pacman -S rofi"
check_cmd kitty        "Super+T terminal"              "sudo pacman -S kitty"
check_cmd hyprlock     "Super+L lock screen"           "sudo pacman -S hyprlock"
check_cmd hypridle     "idle, dim and auto-lock"       "sudo pacman -S hypridle"
check_cmd hyprpaper    "the wallpaper on screen"       "sudo pacman -S hyprpaper"
check_cmd nwg-bar      "the power button"              "sudo pacman -S nwg-bar"
check_cmd waypaper     "the wallpaper button"          "yay -S waypaper-git"
check_cmd swaync       "notifications"                 "sudo pacman -S swaync"
check_cmd swaync-client "the bar's bell"               "sudo pacman -S swaync"
check_cmd notify-send  "the brightness and volume OSD" "sudo pacman -S libnotify"
check_cmd checkupdates "the update counter"            "sudo pacman -S pacman-contrib"
check_cmd pamixer      "volume keys"                   "sudo pacman -S pamixer"
check_cmd playerctl    "media keys"                    "sudo pacman -S playerctl"
check_cmd brightnessctl "brightness keys"              "sudo pacman -S brightnessctl"
check_cmd cliphist     "Super+X clipboard history"     "sudo pacman -S cliphist"
check_cmd wl-copy      "clipboard"                     "sudo pacman -S wl-clipboard"
check_cmd grim         "screenshots"                   "sudo pacman -S grim"
check_cmd slurp        "region screenshots"            "sudo pacman -S slurp"
check_cmd swappy       "the screenshot editor"         "sudo pacman -S swappy"
check_cmd hyprpicker   "the colour picker"             "sudo pacman -S hyprpicker"
check_cmd jq           "Super+Shift+C force kill"      "sudo pacman -S jq"
check_cmd pavucontrol  "the volume module's click"     "sudo pacman -S pavucontrol"
check_cmd blueman-manager "the bluetooth module's click" "sudo pacman -S blueman"
check_cmd nm-connection-editor "the network module's right click" "sudo pacman -S network-manager-applet"
check_cmd btop         "the system module's right click" "sudo pacman -S btop"

# ── The font the icons come from ─────────────────────────────
head_ "Font"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font is installed"
else
    bad "JetBrainsMono Nerd Font is missing — every icon will be an empty box" \
        "sudo pacman -S ttf-jetbrains-mono-nerd && fc-cache -f"
fi

# ── Installed configuration ──────────────────────────────────
head_ "Configuration"

check_file() {
    local path="$1" what="$2"
    if [[ -e "$path" ]]; then
        ok "$what"
    else
        bad "$what is missing (${path/#$HOME/\~})" "./install.sh --configs"
    fi
}

check_file "$CONF/hypr/hyprland.conf"   "hyprland.conf"
check_file "$CONF/hypr/hyprlock.conf"   "hyprlock.conf"
check_file "$CONF/hypr/hypridle.conf"   "hypridle.conf"
check_file "$CONF/theme/colors.css"     "the palette (every stylesheet imports it)"
check_file "$CONF/waybar/config.jsonc"  "waybar config"
check_file "$CONF/waybar/style.css"     "waybar stylesheet"
check_file "$CONF/nwg-bar/bar.json"     "session menu entries"
check_file "$CONF/nwg-bar/style.css"    "session menu stylesheet"
check_file "$CONF/rofi/config.rasi"     "rofi theme"
check_file "$BIN/session-menu.sh"       "the power button script"
check_file "$BIN/waypaper-toggle.sh"    "the wallpaper button script"

broken="$(find "$CONF" "$BIN" -maxdepth 3 -xtype l 2>/dev/null)"
if [[ -n "$broken" ]]; then
    bad "broken symlinks in your config:" "./install.sh --configs"
    echo "$broken" | sed 's/^/      /'
else
    ok "no broken symlinks"
fi

if [[ -f "$CONF/waypaper/config.ini" ]] && grep -q '^stylesheet[[:space:]]*=[[:space:]]*~' "$CONF/waypaper/config.ini"; then
    bad "waypaper/config.ini still has 'stylesheet = ~/...' — Waypaper cannot expand that" \
        "./install.sh --configs"
fi

if [[ -f "$CONF/hypr/hyprland.lua" ]]; then
    bad "hyprland.lua exists and Hyprland prefers it over hyprland.conf" \
        "mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak"
fi

# ── What Hyprland itself thinks ──────────────────────────────
head_ "Hyprland"
if ! command -v hyprctl >/dev/null 2>&1; then
    warn "hyprctl is missing, skipping"
elif ! hyprctl version >/dev/null 2>&1; then
    warn "not inside a running Hyprland session, skipping"
else
    ok "Hyprland $(hyprctl version -j 2>/dev/null | grep -oP '"tag":\s*"\K[^"]+' || echo '?')"
    errors="$(hyprctl configerrors 2>/dev/null)"
    if [[ -z "$errors" || "$errors" == *"no errors"* ]]; then
        ok "hyprland.conf parses with no errors"
    else
        bad "Hyprland reports config errors:" "fix the lines below, then: hyprctl reload"
        echo "$errors" | sed 's/^/      /'
    fi
fi

# ── Things that should be running ────────────────────────────
head_ "Running"
for proc in waybar swaync hyprpaper hypridle; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        ok "$proc"
    else
        bad "$proc is not running" "log out and back in, or start it by hand"
    fi
done
if pgrep -f "waybar-autohide.sh" >/dev/null 2>&1; then
    ok "the auto-hide watcher"
else
    bad "waybar-autohide.sh is not running — the bar will not appear on hover" \
        "log out and back in"
fi

# ── The scripts behind the bar ───────────────────────────────
head_ "Bar scripts"
check_json_script() {
    local path="$1" what="$2"
    if [[ ! -x "$path" ]]; then
        bad "$what is not executable" "chmod +x $path"
        return
    fi
    local out
    out="$("$path" 2>&1)"
    if [[ -z "$out" ]]; then
        warn "$what printed nothing (fine if you are not on Arch)"
    elif printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
        ok "$what → $(printf '%s' "$out" | jq -r '.text' 2>/dev/null)"
    else
        bad "$what did not print valid JSON:" "run it by hand: $path"
        printf '      %s\n' "$out"
    fi
}
check_json_script "$CONF/waybar/sys_stats.sh" "the CPU/GPU/RAM module"
check_json_script "$CONF/waybar/scripts/lock-icon.sh" "the pin indicator"

# ── Verdict ──────────────────────────────────────────────────
printf '\n%b────────────────────────────%b\n' "$BOLD" "$NC"
if (( PROBLEMS == 0 )); then
    printf '%bEverything checks out.%b\n' "$GREEN" "$NC"
    exit 0
fi

printf '%b%d problem(s).%b Suggested fixes, in order:\n\n' "$RED" "$PROBLEMS" "$NC"
printf '%s\n' "${FIXES[@]}" | awk '!seen[$0]++' | sed 's/^/  /'
printf '\n%bAfter installing anything, log out and back in.%b\n' "$CYAN" "$NC"
exit 1
