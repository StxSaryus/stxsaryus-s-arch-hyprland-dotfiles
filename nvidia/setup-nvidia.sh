#!/usr/bin/env bash
# Standalone NVIDIA fix (same logic as install.sh setup_nvidia).
# Prefer: ./install.sh   — this is for re-runs after a failed driver step.
#
# Official: https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# Re-use the installer's NVIDIA path via sourcing would be heavy; call install packages mode? 
# Keep a thin wrapper that execs the installer's internal flow is hard.
# Instead duplicate the critical DKMS force-install and call via bash functions by running install --packages
# Simplest: document that install.sh owns this, and keep this script self-contained.

RED='\033[0;31m';GREEN='\033[0;32m';CYAN='\033[0;36m';YELLOW='\033[1;33m';NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

REAL_USER="${SUDO_USER:-}"
if [[ "$(id -u)" -ne 0 ]] || [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
    error "Run: sudo $REPO/nvidia/setup-nvidia.sh"
fi
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
export PATH="$USER_HOME/.local/bin:/usr/bin:$PATH"
YAY="$(command -v yay || true)"
[[ -x "${YAY:-}" ]] || YAY="$USER_HOME/.local/bin/yay"
[[ -x "$YAY" ]] || error "yay not found — run: cd ~/dotfiles && ./install.sh --auto"

info "Official Arch note: NVIDIA 590 dropped Pascal (GTX 10xx). Use nvidia-580xx-dkms from AUR."
info "Removing nvidia-open / conflicting nvidia-utils..."
pacman -Rns --noconfirm nvidia-open nvidia-open-dkms nvidia-open-lts 2>/dev/null || true
if pacman -Q nvidia-utils &>/dev/null && ! pacman -Q nvidia-580xx-utils &>/dev/null; then
    pacman -Rdd --noconfirm nvidia-utils 2>/dev/null || true
fi

info "Installing linux-headers + dkms..."
pacman -S --needed --noconfirm linux-headers dkms

info "Installing nvidia-580xx-dkms + nvidia-580xx-utils..."
sudo -u "$REAL_USER" env "HOME=$USER_HOME" "PATH=$USER_HOME/.local/bin:/usr/bin:$PATH" \
    "$YAY" -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils

install -Dm644 "$REPO/nvidia/modprobe-nvidia.conf" /etc/modprobe.d/nvidia.conf
install -Dm644 "$REPO/nvidia/blacklist-nouveau.conf" /etc/modprobe.d/blacklist-nouveau.conf
install -Dm644 "$REPO/nvidia/modules-load-nvidia.conf" /etc/modules-load.d/nvidia.conf

if [[ -f /etc/default/grub ]] && ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

info "DKMS install for kernel $(uname -r)..."
ver="$(dkms status 2>/dev/null | awk -F'[/,: ]+' '/^nvidia\//{print $2; exit}')"
if [[ -n "$ver" ]]; then
    dkms install "nvidia/${ver}" -k "$(uname -r)" || dkms autoinstall || true
else
    dkms autoinstall || true
fi
dkms status || true

modprobe nvidia 2>/dev/null || true
modprobe nvidia_uvm 2>/dev/null || true
modprobe nvidia_modeset 2>/dev/null || true
modprobe nvidia_drm 2>/dev/null || true

if nvidia-smi &>/dev/null; then
    success "Working: $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)"
else
    warn "nvidia-smi still failing — run: sudo reboot"
fi
success "Done."
