#!/usr/bin/env bash
set -e

# ╔══════════════════════════════════════════════════════════════╗
# ║  StxSaryus's Arch Hyprland Dotfiles — Installer             ║
# ╚══════════════════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

REPO="$(cd "$(dirname "$0")" && pwd)"

print_header() {
    echo -e "\n${CYAN}${BOLD}╭──────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}${BOLD}│  StxSaryus's Arch Hyprland Dotfiles      │${NC}"
    echo -e "${CYAN}${BOLD}│  Installer v2.0                          │${NC}"
    echo -e "${CYAN}${BOLD}╰──────────────────────────────────────────╯${NC}\n"
}

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

backup_and_link() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)"
        warn "Backed up existing: $dest"
    fi
    ln -sf "$src" "$dest"
    success "Linked: $dest"
}

install_packages() {
    info "Installing required packages..."

    local PACMAN_PKGS=(
        hyprland hyprlock hypridle hyprpaper hyprpicker hyprpolkitagent
        waybar rofi dunst swaync nwg-bar nwg-look brightnessctl
        pipewire-pulse pipewire-alsa pipewire-jack pavucontrol pamixer playerctl
        bluez bluez-utils blueman
        kitty zsh zsh-completions
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        grim slurp swappy cliphist jq imagemagick
        ttf-jetbrains-mono otf-font-awesome ttf-fira-code
        network-manager-applet
        btop fastfetch
    )

    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
    success "Pacman packages installed"

    if command -v yay &>/dev/null; then
        local AUR_PKGS=(waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git)
        yay -S --needed --noconfirm "${AUR_PKGS[@]}"
        success "AUR packages installed"
    else
        warn "yay not found — install AUR packages manually:"
        warn "  waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git"
    fi
}

link_configs() {
    info "Linking configuration files..."

    # Hyprland
    for f in hyprland.conf waybar-autohide.sh brightness-osd.sh wallpaper-sync.sh hyprpaper.conf; do
        backup_and_link "$REPO/config/hypr/$f" "$HOME/.config/hypr/$f"
    done

    # Waybar
    mkdir -p "$HOME/.config/waybar/scripts"
    for f in config.jsonc style.css sys_stats.sh gpu_stats.sh; do
        backup_and_link "$REPO/config/waybar/$f" "$HOME/.config/waybar/$f"
    done
    for f in lock-icon.sh lock-toggle.sh; do
        backup_and_link "$REPO/config/waybar/scripts/$f" "$HOME/.config/waybar/scripts/$f"
    done

    # Rofi
    backup_and_link "$REPO/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"

    # Kitty
    backup_and_link "$REPO/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

    # SwayNC
    for f in config.json style.css; do
        backup_and_link "$REPO/config/swaync/$f" "$HOME/.config/swaync/$f"
    done

    # Waypaper
    backup_and_link "$REPO/config/waypaper/config.ini" "$HOME/.config/waypaper/config.ini"

    # Scripts
    mkdir -p "$HOME/.local/share/bin"
    for f in launcher-toggle.sh systemupdate.sh; do
        backup_and_link "$REPO/config/local-bin/$f" "$HOME/.local/share/bin/$f"
    done

    # Shell
    backup_and_link "$REPO/zsh/.zshrc" "$HOME/.zshrc"
    backup_and_link "$REPO/bash/.bashrc" "$HOME/.bashrc"

    success "All configs linked"
}

set_permissions() {
    info "Setting executable permissions..."
    chmod +x "$HOME/.config/hypr/waybar-autohide.sh" \
             "$HOME/.config/hypr/brightness-osd.sh" \
             "$HOME/.config/hypr/wallpaper-sync.sh" \
             "$HOME/.config/waybar/sys_stats.sh" \
             "$HOME/.config/waybar/gpu_stats.sh" \
             "$HOME/.config/waybar/scripts/lock-icon.sh" \
             "$HOME/.config/waybar/scripts/lock-toggle.sh" \
             "$HOME/.local/share/bin/launcher-toggle.sh" \
             "$HOME/.local/share/bin/systemupdate.sh" 2>/dev/null
    # Pin state file
    echo "1" > "$HOME/.config/waybar/.pinned"
    success "Permissions set"
}

print_header

echo -e "${BOLD}What would you like to do?${NC}\n"
echo "  1) Full install (packages + configs)"
echo "  2) Link configs only (no package install)"
echo "  3) Install packages only"
echo ""
read -rp "Choose [1/2/3]: " choice

case "$choice" in
    1)
        install_packages
        link_configs
        set_permissions
        ;;
    2)
        link_configs
        set_permissions
        ;;
    3)
        install_packages
        ;;
    *)
        error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}${BOLD}╭──────────────────────────────────────────╮${NC}"
echo -e "${GREEN}${BOLD}│  Installation complete!                  │${NC}"
echo -e "${GREEN}${BOLD}╰──────────────────────────────────────────╯${NC}"
echo ""
info "Log out and back in (or reboot) for changes to take effect."
info "Optional: sudo cp greetd-config-fix/config.toml /etc/greetd/config.toml"
echo ""
