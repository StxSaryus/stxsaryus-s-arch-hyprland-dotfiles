#!/usr/bin/env bash
# One-shot fix: Waybar icons (Nerd Font + yay) + NVIDIA driver load
set -euo pipefail

REPO="${REPO:-$HOME/dotfiles}"
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ "$(id -u)" -eq 0 ]] || error "Run with sudo: sudo $REPO/fix-icons-and-nvidia.sh"

# ── 1. Fonts for Waybar icons ─────────────────────────────
info "Installing icon fonts..."
pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    otf-font-awesome \
    base-devel git

fc-cache -fv >/dev/null
success "Fonts installed"

# ── 2. yay (AUR helper) ───────────────────────────────────
if ! command -v yay >/dev/null; then
    info "Installing yay to ~/.local/bin (no pacman required)..."
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    sudo -u "${SUDO_USER:-$USER}" git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    cd "$tmpdir/yay-bin"
    sudo -u "${SUDO_USER:-$USER}" makepkg --noconfirm
    pkg="$(ls "$tmpdir/yay-bin"/yay-bin-*.pkg.tar.zst | rg -v debug | head -1)"
    user_home="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"
    mkdir -p "$user_home/.local/bin"
    bsdtar -xf "$pkg" -C "$tmpdir/extract" usr/bin/yay 2>/dev/null || mkdir -p "$tmpdir/extract" && bsdtar -xf "$pkg" -C "$tmpdir/extract" usr/bin/yay
    install -m755 "$tmpdir/extract/usr/bin/yay" "$user_home/.local/bin/yay"
    chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$user_home/.local/bin/yay"
    success "yay installed to $user_home/.local/bin/yay"
else
    info "yay already installed"
fi

# ── 3. NVIDIA driver modules ──────────────────────────────
info "Setting up NVIDIA..."
"$REPO/nvidia/setup-nvidia.sh"

# ── 4. Sync waybar configs ────────────────────────────────
if [[ -n "${SUDO_USER:-}" ]]; then
    user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    ln -sf "$REPO/config/waybar/style.css" "$user_home/.config/waybar/style.css"
    ln -sf "$REPO/config/waybar/config.jsonc" "$user_home/.config/waybar/config.jsonc"
    sudo -u "$SUDO_USER" pkill -x waybar 2>/dev/null || true
    success "Waybar configs synced — bar will restart on next Hyprland reload"
fi

echo ""
success "All done. Reboot recommended, then: hyprctl reload (or log out/in)"
if command -v nvidia-smi >/dev/null; then
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || warn "nvidia-smi still failing — reboot and try again"
fi
