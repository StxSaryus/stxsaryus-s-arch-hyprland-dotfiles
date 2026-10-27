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
STASHED=0
if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
    info "Stashing local changes before pull..."
    git stash push -m "autostash-update-$(date +%s)" >/dev/null 2>&1 && STASHED=1 || true
fi

PULL_SUCCESS=0
if git pull --rebase origin main >/dev/null 2>&1; then
    PULL_SUCCESS=1
elif git pull origin main >/dev/null 2>&1; then
    PULL_SUCCESS=1
elif git pull --rebase https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git main >/dev/null 2>&1; then
    PULL_SUCCESS=1
fi

if [[ "$STASHED" -eq 1 ]]; then
    git stash pop >/dev/null 2>&1 || warn "Stash pop had minor conflicts — local changes preserved in git stash"
fi

if [[ "$PULL_SUCCESS" -eq 1 ]]; then
    success "Dotfiles repo up to date: $(git log -1 --oneline)"
else
    warn "Could not fetch dotfiles from remote (offline or auth issue) — continuing with local update"
fi

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

# --- 6. Hardware & Driver Health Check ---
info "Running Universal Hardware & Driver Health Check..."
NVIDIA_MISMATCH=0
if [[ -f /proc/driver/nvidia/version ]]; then
    LOADED_NV="$(awk '/NVRM version:/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+/) {print $i; exit}}' /proc/driver/nvidia/version 2>/dev/null || true)"
    INSTALLED_NV="$(pacman -Q nvidia-580xx-utils nvidia-utils nvidia-470xx-utils 2>/dev/null | head -n1 | awk '{print $2}' | cut -d'-' -f1 || true)"
    if [[ -n "$LOADED_NV" && -n "$INSTALLED_NV" && "$LOADED_NV" != "$INSTALLED_NV"* ]]; then
        NVIDIA_MISMATCH=1
    fi
fi

if [[ -x "$REPO/config/local-bin/hardware-wizard.sh" ]]; then
    "$REPO/config/local-bin/hardware-wizard.sh" --check || {
        warn "Driver or hardware stack has missing packages or needs attention."
        info "Run 'hardware-wizard.sh' in terminal to automatically install missing packages."
    }
elif command -v nvidia-smi >/dev/null; then
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null && success "NVIDIA OK" || warn "nvidia-smi failed — reboot may fix"
fi

# --- 7. Hardware Sentinel Service ---
if [[ -f "$HOME/.config/systemd/user/hardware-sentinel.timer" ]]; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now hardware-sentinel.timer 2>/dev/null || true
    success "Hardware Sentinel background service active"
fi

banner "Update complete"
if [[ "$NVIDIA_MISMATCH" -eq 1 ]]; then
    echo -e "${YELLOW}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}${BOLD}│  [ACTION REQUIRED] NVIDIA DRIVER UPGRADE REBOOT NOTICE             │${NC}"
    echo -e "${YELLOW}${BOLD}├────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}${BOLD}│  • Kernel Module in RAM:  ${LOADED_NV}                                 │${NC}"
    echo -e "${YELLOW}${BOLD}│  • Updated on Disk:       ${INSTALLED_NV}                                 │${NC}"
    echo -e "${YELLOW}${BOLD}│                                                                    │${NC}"
    echo -e "${YELLOW}${BOLD}│  New driver & UKI images were built. Reboot to load the new driver:│${NC}"
    echo -e "${YELLOW}${BOLD}│    sudo reboot                                                     │${NC}"
    echo -e "${YELLOW}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}\n"
else
    echo -e "${BOLD}If the kernel or drivers were updated, reboot:${NC}  sudo reboot"
    echo ""
fi
