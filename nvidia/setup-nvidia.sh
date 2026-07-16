#!/usr/bin/env bash
# NVIDIA driver setup for Arch + Hyprland (GTX 1050 Ti / nvidia-open)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$(id -u)" -ne 0 ]; then
    error "Run with sudo: sudo $REPO/nvidia/setup-nvidia.sh"
    exit 1
fi

info "Installing/updating NVIDIA packages..."
pacman -S --needed --noconfirm nvidia-open nvidia-utils libva-nvidia-driver

info "Installing modprobe and module-load configs..."
install -Dm644 "$REPO/nvidia/modprobe-nvidia.conf" /etc/modprobe.d/nvidia.conf
install -Dm644 "$REPO/nvidia/blacklist-nouveau.conf" /etc/modprobe.d/blacklist-nouveau.conf
install -Dm644 "$REPO/nvidia/modules-load-nvidia.conf" /etc/modules-load.d/nvidia.conf

if [ -f /etc/default/grub ]; then
    if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
        info "Adding nvidia_drm.modeset=1 to GRUB kernel parameters..."
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        success "GRUB updated"
    else
        info "GRUB already has nvidia_drm.modeset=1"
    fi
fi

info "Loading NVIDIA kernel modules..."
modprobe nvidia || true
modprobe nvidia_uvm || true
modprobe nvidia_drm || true
modprobe nvidia_modeset || true

if nvidia-smi &>/dev/null; then
    success "NVIDIA driver is working:"
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu --format=csv,noheader
else
    warn "nvidia-smi still failing — reboot after this script finishes"
    dmesg | tail -20 | grep -i nvidia || true
fi

success "Done. Reboot recommended if nvidia-smi did not succeed immediately."
