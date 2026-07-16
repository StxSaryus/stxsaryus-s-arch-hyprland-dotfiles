#!/usr/bin/env bash
#
# StxSaryus's Arch Hyprland Dotfiles — Comprehensive Interactive Installer
#
# This script lets you choose:
#   - Applications: terminal, browser, file manager, app launcher
#   - Optional components: Waypaper, Btop, greetd, nwg-look
#   - Keyboard shortcuts: use defaults or customize each keybind
#
# All choices are documented in INSTALL.md. After install, keybinds and
# app commands are written into ~/.config/hypr/hyprland.conf.
#
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

REPO="$(cd "$(dirname "$0")" && pwd)"
HYPR_DEST="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DEST/hyprland.conf"

# -----------------------------------------------------------------------------
# Defaults (used when user presses Enter)
# -----------------------------------------------------------------------------
TERMINAL_CMD="kitty"
BROWSER_CMD="firefox"
FILE_MANAGER_CMD="thunar"
LAUNCHER_CMD="~/.local/share/bin/launcher-toggle.sh"
KEY_TERMINAL="T"
KEY_BROWSER="B"
KEY_FILE_MANAGER="E"
KEY_LAUNCHER="SPACE"
KEY_LOCK="L"
MAIN_MOD="SUPER"

OPT_WAYPAPER=1
OPT_BTOP=1
OPT_GREETD=0
OPT_NWG_LOOK=1

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
print_header() {
    echo -e "\n${CYAN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}${BOLD}│  StxSaryus's Arch Hyprland Dotfiles — Interactive Installer        │${NC}"
    echo -e "${CYAN}${BOLD}│  Choose apps, shortcuts, and optional components.                  │${NC}"
    echo -e "${CYAN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}\n"
}

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Backup non-symlink file, then link or copy
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

# Copy file and optionally patch (for hyprland.conf we copy then sed)
copy_and_patch_hypr() {
    mkdir -p "$(dirname "$HYPR_CONF")"
    if [ -e "$HYPR_CONF" ] && [ ! -L "$HYPR_CONF" ]; then
        mv "$HYPR_CONF" "${HYPR_CONF}.bak.$(date +%s)"
        warn "Backed up existing: $HYPR_CONF"
    fi
    cp "$REPO/config/hypr/hyprland.conf" "$HYPR_CONF"
    success "Copied and patched: $HYPR_CONF"
}

# -----------------------------------------------------------------------------
# Interactive prompts
# -----------------------------------------------------------------------------
prompt_choices() {
    echo -e "${BOLD}── Application choices (press Enter for default) ──${NC}\n"

    # Terminal
    echo "Terminal emulator:"
    echo "  1) Kitty (default)    2) Alacritty    3) Foot    4) WezTerm"
    read -rp "Choice [1]: " c
    case "${c:-1}" in
        1) TERMINAL_CMD="kitty" ;;
        2) TERMINAL_CMD="alacritty" ;;
        3) TERMINAL_CMD="foot" ;;
        4) TERMINAL_CMD="wezterm" ;;
        *) TERMINAL_CMD="kitty" ;;
    esac

    # Browser
    echo ""
    echo "Web browser:"
    echo "  1) Firefox (default)  2) Chromium  3) Brave  4) Librewolf"
    read -rp "Choice [1]: " c
    case "${c:-1}" in
        1) BROWSER_CMD="firefox" ;;
        2) BROWSER_CMD="chromium" ;;
        3) BROWSER_CMD="brave-browser" ;;
        4) BROWSER_CMD="librewolf" ;;
        *) BROWSER_CMD="firefox" ;;
    esac

    # File manager
    echo ""
    echo "File manager:"
    echo "  1) Thunar (default)  2) Nautilus  3) Dolphin  4) Nemo  5) PCManFM"
    read -rp "Choice [1]: " c
    case "${c:-1}" in
        1) FILE_MANAGER_CMD="thunar" ;;
        2) FILE_MANAGER_CMD="nautilus" ;;
        3) FILE_MANAGER_CMD="dolphin" ;;
        4) FILE_MANAGER_CMD="nemo" ;;
        5) FILE_MANAGER_CMD="pcmanfm" ;;
        *) FILE_MANAGER_CMD="thunar" ;;
    esac

    # Launcher
    echo ""
    echo "App launcher (Super+Space):"
    echo "  1) Rofi (default)  2) Fuzzel  3) Wofi"
    read -rp "Choice [1]: " c
    case "${c:-1}" in
        1) LAUNCHER_CMD="~/.local/share/bin/launcher-toggle.sh" ;;
        2) LAUNCHER_CMD="fuzzel" ;;
        3) LAUNCHER_CMD="wofi --show drun" ;;
        *) LAUNCHER_CMD="~/.local/share/bin/launcher-toggle.sh" ;;
    esac

    # Optional components
    echo ""
    echo -e "${BOLD}── Optional components (y/n) ──${NC}"
    read -rp "Install Waypaper (wallpaper picker, AUR)? [Y/n]: " c
    OPT_WAYPAPER=1
    [[ "${c,,}" == "n" ]] && OPT_WAYPAPER=0
    read -rp "Install Btop (system monitor)? [Y/n]: " c
    OPT_BTOP=1
    [[ "${c,,}" == "n" ]] && OPT_BTOP=0
    read -rp "Install greetd + tuigreet (login manager)? [y/N]: " c
    OPT_GREETD=0
    [[ "${c,,}" == "y" ]] && OPT_GREETD=1
    read -rp "Install nwg-look (GTK theme switcher)? [Y/n]: " c
    OPT_NWG_LOOK=1
    [[ "${c,,}" == "n" ]] && OPT_NWG_LOOK=0

    # Shortcuts
    echo ""
    echo -e "${BOLD}── Keyboard shortcuts ──${NC}"
    echo "Default: Terminal=Super+T, Browser=Super+B, File manager=Super+E, Launcher=Super+Space, Lock=Super+L"
    read -rp "Use default shortcuts? [Y/n]: " c
    if [[ "${c,,}" == "n" ]]; then
        read -rp "Key for Terminal (e.g. T): " KEY_TERMINAL
        KEY_TERMINAL=${KEY_TERMINAL:-T}
        read -rp "Key for Browser (e.g. B): " KEY_BROWSER
        KEY_BROWSER=${KEY_BROWSER:-B}
        read -rp "Key for File manager (e.g. E): " KEY_FILE_MANAGER
        KEY_FILE_MANAGER=${KEY_FILE_MANAGER:-E}
        read -rp "Key for Launcher (e.g. SPACE or S): " KEY_LAUNCHER
        KEY_LAUNCHER=${KEY_LAUNCHER:-SPACE}
        read -rp "Key for Lock (e.g. L): " KEY_LOCK
        KEY_LOCK=${KEY_LOCK:-L}
    fi
}

# -----------------------------------------------------------------------------
# Patch hyprland.conf with chosen apps and keybinds
# -----------------------------------------------------------------------------
patch_hyprland_conf() {
    # Escape for sed: / and & need escaping
    local term_esc="${TERMINAL_CMD//\//\\/}"
    local browser_esc="${BROWSER_CMD//\//\\/}"
    local fm_esc="${FILE_MANAGER_CMD//\//\\/}"
    local launch_esc="${LAUNCHER_CMD//\//\\/}"
    launch_esc="${launch_esc//&/\\&}"

    sed -i "s/exec, kitty/exec, $term_esc/" "$HYPR_CONF"
    sed -i "s/exec, firefox/exec, $browser_esc/" "$HYPR_CONF"
    sed -i "s/exec, thunar/exec, $fm_esc/" "$HYPR_CONF"
    sed -i "s|exec, ~/.local/share/bin/launcher-toggle.sh|exec, $launch_esc|" "$HYPR_CONF"

    # Key bindings (bind = $mainMod, X, ...)
    sed -i "s/\$mainMod, T, exec,/\$mainMod, $KEY_TERMINAL, exec,/" "$HYPR_CONF"
    sed -i "s/\$mainMod, B, exec,/\$mainMod, $KEY_BROWSER, exec,/" "$HYPR_CONF"
    sed -i "s/\$mainMod, E, exec,/\$mainMod, $KEY_FILE_MANAGER, exec,/" "$HYPR_CONF"
    sed -i "s/\$mainMod, SPACE, exec,/\$mainMod, $KEY_LAUNCHER, exec,/" "$HYPR_CONF"
    sed -i "s/\$mainMod, L, exec,/\$mainMod, $KEY_LOCK, exec,/" "$HYPR_CONF"
}

# -----------------------------------------------------------------------------
# Package installation
# -----------------------------------------------------------------------------
install_packages() {
    info "Installing packages based on your choices..."

    PACMAN_PKGS=(
        hyprland hyprlock hypridle hyprpaper hyprpicker hyprpolkitagent
        waybar swaync nwg-bar brightnessctl
        pipewire-pulse pipewire-alsa pipewire-jack pavucontrol pamixer playerctl
        bluez bluez-utils blueman
        zsh zsh-completions
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        grim slurp swappy cliphist jq imagemagick
        ttf-jetbrains-mono otf-font-awesome ttf-fira-code
        network-manager-applet
        nvidia-open nvidia-utils libva-nvidia-driver
    )

    # Terminal
    case "$TERMINAL_CMD" in
        kitty)     PACMAN_PKGS+=(kitty) ;;
        alacritty) PACMAN_PKGS+=(alacritty) ;;
        foot)      PACMAN_PKGS+=(foot) ;;
        wezterm)   PACMAN_PKGS+=(wezterm) ;;
        *)         PACMAN_PKGS+=(kitty) ;;
    esac

    # Browser
    case "$BROWSER_CMD" in
        firefox)        PACMAN_PKGS+=(firefox) ;;
        chromium)       PACMAN_PKGS+=(chromium) ;;
        brave-browser)  PACMAN_PKGS+=(brave-browser) ;;
        librewolf)      PACMAN_PKGS+=(librewolf) ;;
        *)              PACMAN_PKGS+=(firefox) ;;
    esac

    # File manager
    case "$FILE_MANAGER_CMD" in
        thunar)   PACMAN_PKGS+=(thunar) ;;
        nautilus) PACMAN_PKGS+=(nautilus) ;;
        dolphin)  PACMAN_PKGS+=(dolphin) ;;
        nemo)     PACMAN_PKGS+=(nemo) ;;
        pcmanfm)  PACMAN_PKGS+=(pcmanfm-gtk3) ;;
        *)        PACMAN_PKGS+=(thunar) ;;
    esac

    # Launcher
    case "$LAUNCHER_CMD" in
        fuzzel) PACMAN_PKGS+=(fuzzel) ;;
        wofi*)  PACMAN_PKGS+=(wofi) ;;
        *)      PACMAN_PKGS+=(rofi) ;;
    esac

    # Optional
    [ "$OPT_BTOP" -eq 1 ]     && PACMAN_PKGS+=(btop fastfetch)
    [ "$OPT_NWG_LOOK" -eq 1 ] && PACMAN_PKGS+=(nwg-look)

    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
    success "Pacman packages installed"

    # AUR
    AUR_PKGS=()
    [ "$OPT_WAYPAPER" -eq 1 ] && AUR_PKGS+=(waypaper-git)
    AUR_PKGS+=(oh-my-zsh-git zsh-theme-powerlevel10k-git)

    if [ ${#AUR_PKGS[@]} -gt 0 ] && command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "${AUR_PKGS[@]}"
        success "AUR packages installed"
    elif [ "$OPT_WAYPAPER" -eq 1 ]; then
        warn "yay not found — install AUR manually: waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git"
    fi

    if [ "$OPT_GREETD" -eq 1 ]; then
        sudo pacman -S --needed --noconfirm greetd greetd-tuigreet
        [ -d "$REPO/greetd-config-fix" ] && sudo cp "$REPO/greetd-config-fix/config.toml" /etc/greetd/config.toml
        sudo systemctl enable greetd
        success "greetd enabled"
    fi
}

# -----------------------------------------------------------------------------
# Link configs (except hyprland.conf which we copy and patch)
# -----------------------------------------------------------------------------
link_configs() {
    info "Linking configuration files..."

    # Hyprland 0.55+ prefers hyprland.lua over hyprland.conf; remove autogenerated lua
    if [ -f "$HYPR_DEST/hyprland.lua" ]; then
        mv "$HYPR_DEST/hyprland.lua" "$HYPR_DEST/hyprland.lua.bak.$(date +%s)"
        warn "Moved autogenerated hyprland.lua aside (Hyprland 0.55+ prefers it over .conf)"
    fi

    for f in waybar-autohide.sh brightness-osd.sh wallpaper-sync.sh hyprpaper.conf; do
        backup_and_link "$REPO/config/hypr/$f" "$HOME/.config/hypr/$f"
    done

    mkdir -p "$HOME/.config/waybar/scripts"
    for f in config.jsonc style.css sys_stats.sh gpu_stats.sh; do
        backup_and_link "$REPO/config/waybar/$f" "$HOME/.config/waybar/$f"
    done
    for f in lock-icon.sh lock-toggle.sh; do
        backup_and_link "$REPO/config/waybar/scripts/$f" "$HOME/.config/waybar/scripts/$f"
    done

    backup_and_link "$REPO/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    backup_and_link "$REPO/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    for f in config.json style.css; do
        backup_and_link "$REPO/config/swaync/$f" "$HOME/.config/swaync/$f"
    done
    backup_and_link "$REPO/config/waypaper/config.ini" "$HOME/.config/waypaper/config.ini"

    mkdir -p "$HOME/.local/share/bin"
    for f in launcher-toggle.sh systemupdate.sh; do
        backup_and_link "$REPO/config/local-bin/$f" "$HOME/.local/share/bin/$f"
    done

    backup_and_link "$REPO/zsh/.zshrc" "$HOME/.zshrc"
    backup_and_link "$REPO/bash/.bashrc" "$HOME/.bashrc"

    # Hyprland: copy from repo then patch with user choices (do not link)
    copy_and_patch_hypr
    patch_hyprland_conf

    success "All configs linked and hyprland.conf patched"
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
             "$HOME/.local/share/bin/systemupdate.sh" \
             "$REPO/nvidia/setup-nvidia.sh" 2>/dev/null
    echo "1" > "$HOME/.config/waybar/.pinned"
    success "Permissions set"
}

setup_default_wallpaper() {
    local wp_dir="$HOME/Wallpapers"
    local wp_file="$wp_dir/default.png"
    mkdir -p "$wp_dir"
    if [ ! -f "$wp_file" ]; then
        if [ -f /usr/share/hypr/wall0.png ]; then
            cp /usr/share/hypr/wall0.png "$wp_file"
            success "Default wallpaper copied to $wp_file"
        else
            warn "No default wallpaper found — add one to ~/Wallpapers/default.png"
        fi
    fi
    # Expand ~ paths in hyprpaper for hyprpaper binary
    if [ -f "$HYPR_CONF" ]; then
        sed -i "s|~/Wallpapers|$wp_dir|g" "$HOME/.config/hypr/hyprpaper.conf" 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
print_header

echo -e "${BOLD}Install mode:${NC}"
echo "  1) Full install (interactive choices + packages + configs)"
echo "  2) Link configs only (use defaults for apps/shortcuts, no package install)"
echo "  3) Packages only (install default package set, no config link)"
echo ""
read -rp "Choose [1/2/3]: " mode

case "$mode" in
    1)
        prompt_choices
        install_packages
        link_configs
        set_permissions
        setup_default_wallpaper
        ;;
    2)
        link_configs
        set_permissions
        setup_default_wallpaper
        ;;
    3)
        TERMINAL_CMD=kitty
        BROWSER_CMD=firefox
        FILE_MANAGER_CMD=thunar
        LAUNCHER_CMD="~/.local/share/bin/launcher-toggle.sh"
        install_packages
        ;;
    *)
        error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
echo -e "${GREEN}${BOLD}│  Installation complete. See INSTALL.md for shortcut reference.    │${NC}"
echo -e "${GREEN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
info "Log out and back in (or reboot) for changes to take effect."
echo ""
info "NVIDIA: if nvidia-smi fails, run: sudo ~/dotfiles/nvidia/setup-nvidia.sh"
echo ""
