#!/usr/bin/env bash
# ==============================================================================
# StxSaryus — Autonomous Hardware & Driver Sentinel
#
# Background service to continuously monitor:
#  1. Hardware acceleration stack (Vulkan ICDs, VA-API drivers, missing packages)
#  2. DKMS kernel module status for the running kernel
#  3. Upstream driver and kernel updates (Arch official repos + AUR)
#  4. Display topology & Hyprland environment synchronization
#
# Designed to run periodically via systemd user timer (or on login).
# Sends actionable desktop notifications via SwayNC / notify-send.
#
# Usage:
#   hardware-sentinel.sh             # Normal periodic check (respects cooldown)
#   hardware-sentinel.sh --force     # Bypass cooldown and force notification check
#   hardware-sentinel.sh --status    # Print current sentinel status and exit
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD_BIN="$SCRIPT_DIR/hardware-wizard.sh"

# Fallbacks if called from different PATH
if [[ ! -x "$WIZARD_BIN" ]]; then
    if command -v hardware-wizard.sh >/dev/null 2>&1; then
        WIZARD_BIN="$(command -v hardware-wizard.sh)"
    elif [[ -x "$HOME/.local/bin/hardware-wizard.sh" ]]; then
        WIZARD_BIN="$HOME/.local/bin/hardware-wizard.sh"
    elif [[ -x "$HOME/.local/share/bin/hardware-wizard.sh" ]]; then
        WIZARD_BIN="$HOME/.local/share/bin/hardware-wizard.sh"
    fi
fi

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hardware-sentinel"
STATE_FILE="$STATE_DIR/state"
COOLDOWN_SECONDS=43200  # 12 hours cooldown for repeating notifications

MODE="normal"

case "${1:-}" in
    --force)
        MODE="force"
        ;;
    --status)
        MODE="status"
        ;;
    "")
        MODE="normal"
        ;;
    *)
        echo "Usage: hardware-sentinel.sh [--force|--status]"
        exit 1
        ;;
esac

if [[ ! -x "$WIZARD_BIN" ]]; then
    echo "[ERROR] hardware-wizard.sh not found or not executable"
    exit 1
fi

mkdir -p "$STATE_DIR"

# 1. Query Hardware Wizard Status
STATUS_RAW="$("$WIZARD_BIN" --check-status 2>/dev/null || true)"
eval "$STATUS_RAW"

# 2. Query Upstream Updates
DRIVER_UPDATES="$("$WIZARD_BIN" --check-updates 2>/dev/null || true)"

# 3. Analyze Health State
NEEDS_ATTENTION=0
ISSUES=()
NOTIF_TITLE="⚡ Hardware & Driver Sentinel"
NOTIF_BODY=""

if [[ "${DKMS_OK:-1}" -eq 0 ]]; then
    NEEDS_ATTENTION=1
    ISSUES+=("DKMS Kernel Module mismatch for $(uname -r)")
fi

if [[ "${MISSING_COUNT:-0}" -gt 0 ]]; then
    NEEDS_ATTENTION=1
    ISSUES+=("Missing Acceleration Package(s): ${MISSING_PKGS:-}")
fi

if [[ -n "$DRIVER_UPDATES" && "$DRIVER_UPDATES" != "No driver updates available" ]]; then
    NEEDS_ATTENTION=1
    UPDATE_COUNT="$(echo "$DRIVER_UPDATES" | wc -l)"
    ISSUES+=("Upstream driver/kernel updates available ($UPDATE_COUNT pkg)")
fi

if [[ "$MODE" == "status" ]]; then
    echo "=== Hardware Sentinel Status ==="
    echo "Topology:        ${TOPOLOGY:-UNKNOWN}"
    echo "CPU Vendor:      ${CPU_VENDOR:-UNKNOWN}"
    echo "NVIDIA Branch:   ${NVIDIA_BRANCH:-none}"
    echo "DKMS OK:         ${DKMS_OK:-1}"
    echo "Missing Packages: ${MISSING_PKGS:-none}"
    echo "Driver Updates:  ${DRIVER_UPDATES:-none}"
    echo "Needs Attention: $NEEDS_ATTENTION"
    exit 0
fi

# If everything is optimal, clear state and exit cleanly
if [[ "$NEEDS_ATTENTION" -eq 0 ]]; then
    rm -f "$STATE_FILE"
    exit 0
fi

# 4. State Hashing & Cooldown Check
CURRENT_HASH="$(printf '%s\n' "${ISSUES[@]}" "$DRIVER_UPDATES" | sha256sum | awk '{print $1}')"
NOW="$(date +%s)"

if [[ "$MODE" != "force" && -f "$STATE_FILE" ]]; then
    LAST_HASH="$(head -n 1 "$STATE_FILE" 2>/dev/null || echo "")"
    LAST_TIME="$(tail -n 1 "$STATE_FILE" 2>/dev/null || echo "0")"

    if [[ "$CURRENT_HASH" == "$LAST_HASH" ]]; then
        TIME_DIFF=$((NOW - LAST_TIME))
        if [[ $TIME_DIFF -lt $COOLDOWN_SECONDS ]]; then
            # Still in cooldown, stay silent
            exit 0
        fi
    fi
fi

# Save current state
printf "%s\n%s\n" "$CURRENT_HASH" "$NOW" > "$STATE_FILE"

# 5. Format and Send Notification
NOTIF_BODY="$(printf '• %s\n' "${ISSUES[@]}")"
NOTIF_BODY+=$'\nRun Hardware Wizard or System Update to apply.'

send_notification() {
    local title="$1" body="$2" icon="${3:-video-display}" urgency="${4:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            -a "Hardware Sentinel" \
            -i "$icon" \
            -u "$urgency" \
            -c "device" \
            "$title" \
            "$body" 2>/dev/null || true
    else
        python3 - "$title" "$body" "$icon" <<'PYEOF' 2>/dev/null || true
import sys, dbus
title, body, icon = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    bus = dbus.SessionBus()
    notify_obj = bus.get_object('org.freedesktop.Notifications', '/org/freedesktop/Notifications')
    notify_iface = dbus.Interface(notify_obj, 'org.freedesktop.Notifications')
    notify_iface.Notify('Hardware Sentinel', 0, icon, title, body, [], {}, 8000)
except Exception:
    pass
PYEOF
    fi
}

send_notification "$NOTIF_TITLE" "$NOTIF_BODY" "video-display" "normal"
