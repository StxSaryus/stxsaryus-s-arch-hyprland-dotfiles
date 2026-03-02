# StxSaryus's Arch Hyprland Dotfiles

Minimal, modern and performance-tuned Arch Linux + Hyprland rice with Windows 11 style auto-hide Waybar.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)
![NVIDIA](https://img.shields.io/badge/NVIDIA_1050_Ti-76B900?style=for-the-badge&logo=nvidia&logoColor=white)

---

## System Specs

| Component | Detail |
|-----------|--------|
| **OS** | Arch Linux (rolling) |
| **WM** | Hyprland 0.54+ (Wayland) |
| **GPU** | NVIDIA GeForce GTX 1050 Ti Mobile (nvidia-dkms-tkg) |
| **CPU** | Intel Core i7-7700HQ @ 2.80GHz |
| **RAM** | 16 GB |
| **Kernel** | linux 6.18+ |
| **Bar** | Waybar (Win11-style auto-hide) |
| **Terminal** | Kitty |
| **Shell** | Zsh + Oh-My-Zsh + Powerlevel10k |
| **Launcher** | Rofi |
| **File Manager** | Thunar / Dolphin |
| **Browser** | Firefox |
| **Notifications** | Dunst / SwayNC |
| **Wallpaper** | Waypaper (+ hyprpaper backend) |
| **Lock Screen** | Hyprlock |
| **Power Menu** | nwg-bar |
| **Login Manager** | SDDM / greetd + tuigreet |
| **Audio** | PipeWire + WirePlumber |

---

## What's Included

```
.
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf          # Main Hyprland config (NVIDIA tuned)
│   │   ├── waybar-autohide.sh     # Win11-style show/hide script
│   │   └── brightness-osd.sh      # Brightness OSD notifications
│   ├── waybar/
│   │   ├── config.jsonc            # Waybar modules & layout
│   │   ├── style.css               # Waybar theme (dark glass)
│   │   ├── sys_stats.sh            # CPU/RAM/Temp combined widget
│   │   ├── gpu_stats.sh            # NVIDIA GPU stats widget
│   │   └── scripts/
│   │       ├── lock-icon.sh        # Waybar pin state indicator
│   │       └── lock-toggle.sh      # Toggle pin/auto-hide
├── zsh/
│   └── .zshrc                      # Zsh + Oh-My-Zsh + Powerlevel10k
├── bash/
│   └── .bashrc                     # Bash fallback config
├── greetd-config-fix/
│   └── config.toml                 # greetd + tuigreet config
└── boot-speed/
    └── ...                         # Fast boot (mkinitcpio tweaks)
```

---

## Features

### Waybar (Windows 11 Style)

- **Auto-hide**: Bar hides when mouse leaves, shows when mouse reaches top edge
- **Pin/Unpin**: Lock icon (🔒/🔓) on the far left — click to toggle between pinned (always visible) and auto-hide mode
- **Single bar**: All modules in one unified transparent bar with rounded corners
- **Dark glass theme**: `rgba(15, 15, 20, 0.75)` background with smooth hover effects

### Waybar Modules (Left → Right)

| Module | Description | Click Action |
|--------|-------------|--------------|
| 🔒 Lock | Pin/unpin bar | Toggle auto-hide |
|  Arch | Arch logo | **Left**: Rofi launcher · **Right**: Waypaper |
| Workspaces | 1-10 workspace indicators | Switch workspace |
| Window | Active window title | — |
| ▶ Media | Now playing (Spotify, Firefox...) | **Left**: Play/Pause · **Right**: Next |
| System | CPU / RAM / Temp stats | **Left**: Toggle detail · **Right**: Open btop |
| 󰕾 Volume | Audio volume % | **Left**: Pavucontrol · **Scroll**: ±2% |
| 󰃞 Brightness | Screen brightness % | **Scroll**: ±5% |
| 🔋 Battery | Charge % + icon | — |
| 󰸉 Wallpaper | Waypaper launcher | **Left**: Open Waypaper · **Right**: Kill Waypaper |
| Network | WiFi SSID / Ethernet | **Right**: nm-connection-editor |
| Bluetooth | Device name + battery | **Left**: Blueman manager |
| Updates | System update count | **Left**: Run system update |
|  Clock | Time (click for date) | **Left**: Toggle date/time |
| 󰐥 Power | Power menu | **Left**: nwg-bar power menu |

---

## Keyboard Shortcuts

### General

| Shortcut | Action |
|----------|--------|
| `Super + T` | Open Kitty terminal |
| `Super + B` | Open Firefox |
| `Super + E` | Open Dolphin file manager |
| `Super + Space` | Toggle Rofi launcher |
| `Super + C` | Close active window |
| `Super + V` | Toggle floating mode |
| `Super + L` | Lock screen (Hyprlock) |
| `Shift + F11` | Toggle fullscreen |

### Workspace Navigation

| Shortcut | Action |
|----------|--------|
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + 0` | Switch to workspace 10 |
| `Super + Scroll ↑/↓` | Next/previous workspace |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + ←/→/↑/↓` | Move focus (left/right/up/down) |
| `Super + Left Click` (drag) | Move window |
| `Super + Right Click` (drag) | Resize window |
| `Super + Alt + 1-9/0` | Send window to workspace (silent) |
| `Super + Shift + 1-9/0` | Move with window to workspace |
| `Super + Shift + Scroll ↑/↓` | Move with window to next/prev workspace |

### Media & Hardware

| Shortcut | Action |
|----------|--------|
| `Fn + Brightness ↑/↓` | Adjust screen brightness (with OSD) |
| `Fn + Volume ↑/↓` | Adjust volume (±5%) |
| `Fn + Mute` | Toggle mute |
| `Fn + Mic Mute` | Toggle microphone mute |
| `XF86AudioPlay` | Play/Pause media |
| `XF86AudioNext/Prev` | Next/Previous track |
| `XF86AudioStop` | Stop playback |

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Required packages

```bash
# Core (Hyprland + NVIDIA)
sudo pacman -S hyprland hyprlock hypridle hyprpaper hyprpicker hyprpolkitagent

# Bar & UI
sudo pacman -S waybar rofi dunst nwg-bar nwg-look brightnessctl

# Audio
sudo pacman -S pipewire-pulse pipewire-alsa pipewire-jack pavucontrol pamixer

# Bluetooth
sudo pacman -S bluez bluez-utils blueman

# Terminal & Shell
sudo pacman -S kitty zsh zsh-completions

# Portals (theme & file dialog support)
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Tools
sudo pacman -S grim slurp swappy cliphist jq imagemagick playerctl

# Fonts
sudo pacman -S ttf-jetbrains-mono otf-font-awesome ttf-fira-code

# AUR (via yay)
yay -S waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git
```

### 3. Link configs

```bash
REPO="$HOME/dotfiles"

# Zsh
mv ~/.zshrc ~/.zshrc.bak 2>/dev/null
ln -sf "$REPO/zsh/.zshrc" ~/.zshrc

# Bash
mv ~/.bashrc ~/.bashrc.bak 2>/dev/null
ln -sf "$REPO/bash/.bashrc" ~/.bashrc

# Waybar
mkdir -p ~/.config/waybar/scripts
for f in config.jsonc style.css gpu_stats.sh sys_stats.sh; do
  mv ~/.config/waybar/$f ~/.config/waybar/$f.bak 2>/dev/null
  ln -sf "$REPO/config/waybar/$f" ~/.config/waybar/$f
done
ln -sf "$REPO/config/waybar/scripts/lock-icon.sh" ~/.config/waybar/scripts/lock-icon.sh
ln -sf "$REPO/config/waybar/scripts/lock-toggle.sh" ~/.config/waybar/scripts/lock-toggle.sh
chmod +x ~/.config/waybar/scripts/*.sh ~/.config/waybar/*.sh

# Hyprland
mkdir -p ~/.config/hypr
for f in hyprland.conf waybar-autohide.sh brightness-osd.sh; do
  mv ~/.config/hypr/$f ~/.config/hypr/$f.bak 2>/dev/null
  ln -sf "$REPO/config/hypr/$f" ~/.config/hypr/$f
done
chmod +x ~/.config/hypr/waybar-autohide.sh ~/.config/hypr/brightness-osd.sh
```

### 4. Optional: greetd login screen

```bash
sudo pacman -S greetd greetd-tuigreet
sudo cp greetd-config-fix/config.toml /etc/greetd/config.toml
sudo systemctl enable greetd
```

### 5. Optional: Fast boot

See `boot-speed/` for mkinitcpio optimizations and bootloader timeout tweaks.

---

## NVIDIA Notes

This config is tuned for **NVIDIA GTX 1050 Ti** with proprietary drivers (`nvidia-dkms-tkg`). Key environment variables are set in `hyprland.conf`:

```ini
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = MOZ_ENABLE_WAYLAND,1
```

Hardware cursors are disabled (`no_hardware_cursors = true`) for NVIDIA compatibility. Blur and shadows are off to keep things smooth on a mobile 1050 Ti.

---

## Credits

Made by **StxSaryus** — feel free to fork, modify, and make it your own.
