#!/usr/bin/env bash
# Full system + dotfiles update (Arch + AUR + repo sync)
# Usage: ./update.sh
#
# Pascal GTX 10xx: keeps nvidia-580xx-* — never replaces with nvidia-utils 610
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

REPO="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

banner() {
    echo -e "\n${CYAN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    printf "${CYAN}${BOLD}│  %-66s │${NC}\n" "$1"
    echo -e "${CYAN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}\n"
}

guard_nvidia_580xx() {
    if pacman -Q nvidia-580xx-utils &>/dev/null; then
        info "Pascal GPU: nvidia-580xx branch detected — blocking nvidia-utils 610 swap"
        if pacman -Qu 2>/dev/null | grep -qE '^nvidia-utils |^nvidia-open '; then
            warn "Update wants nvidia-utils/nvidia-open — skipping those (use yay for 580xx AUR updates)"
        fi
    fi
}

banner "System + dotfiles update"

# --- 1. Dotfiles repo ---
info "Pulling latest dotfiles from GitHub..."
cd "$REPO"
git pull --rebase origin main || git pull origin main
success "Dotfiles repo up to date: $(git log -1 --oneline)"

# --- 2. Official packages ---
info "Updating official packages (pacman -Syu)..."
guard_nvidia_580xx
sudo pacman -Syu --noconfirm
success "Pacman upgrade done"

# --- 3. AUR ---
if command -v yay >/dev/null; then
    info "Updating AUR packages (yay -Syu)..."
    yay -Syu --noconfirm --needed
    success "AUR upgrade done"
else
    warn "yay not found — skip AUR. Install: ./install.sh --auto"
fi

# --- 4. Sync configs from repo ---
info "Syncing configs from dotfiles..."
"$REPO/install.sh" --configs
success "Configs synced"

# --- 5. DKMS (Pascal NVIDIA) ---
if pacman -Q nvidia-580xx-dkms &>/dev/null; then
    info "Rebuilding NVIDIA DKMS for kernel $(uname -r)..."
    sudo dkms autoinstall || warn "DKMS autoinstall had warnings"
    dkms status 2>/dev/null | grep nvidia || true
fi

# --- 6. Verify ---
echo ""
if command -v nvidia-smi >/dev/null; then
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null && success "NVIDIA OK" || warn "nvidia-smi failed — reboot may fix"
fi

banner "Update complete"
echo -e "${BOLD}If the kernel was updated, reboot:${NC}  sudo reboot"
echo ""
