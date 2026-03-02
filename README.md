<div align="center">

# StxSaryus's Arch Hyprland Dotfiles

**Minimal, modern and performance-tuned Arch Linux + Hyprland rice**
**with Windows 11 style auto-hide Waybar**

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)
![NVIDIA](https://img.shields.io/badge/NVIDIA-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

</div>

---

## Overview

A clean, dependency-free Hyprland setup built from scratch — no framework bloat, no leftover scripts, just what you need. Optimized for NVIDIA laptops with smooth animations and a Windows 11 inspired taskbar experience.

### Highlights

- **Windows 11 style Waybar** — auto-hides at the top, shows on hover, pin/unpin with one click
- **NVIDIA optimized** — env vars, no hardware cursors, blur/shadow disabled for smooth performance
- **Instant wallpaper** — hyprpaper loads your wallpaper at boot with zero delay
- **One-click installer** — `install.sh` handles packages, symlinks, and permissions
- **10 workspaces** — full keyboard + mouse scroll navigation
- **Dark glass aesthetic** — translucent bar, rounded corners, minimal icons

---

## System

| Component | Detail |
|-----------|--------|
| **OS** | Arch Linux (rolling) |
| **WM** | Hyprland (Wayland) |
| **GPU** | NVIDIA GeForce GTX 1050 Ti Mobile |
| **CPU** | Intel Core i7-7700HQ @ 2.80GHz |
| **RAM** | 16 GB |
| **Bar** | Waybar |
| **Terminal** | Kitty |
| **Shell** | Zsh + Oh-My-Zsh + Powerlevel10k |
| **Launcher** | Rofi |
| **Notifications** | SwayNC |
| **Wallpaper** | Waypaper + Hyprpaper |
| **Lock Screen** | Hyprlock |
| **Power Menu** | nwg-bar |
| **Audio** | PipeWire |

---

## File Structure

```
.
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf            # Main Hyprland config (NVIDIA tuned)
│   │   ├── hyprpaper.conf           # Wallpaper preload (instant boot wallpaper)
│   │   ├── waybar-autohide.sh       # Win11-style auto show/hide logic
│   │   ├── brightness-osd.sh        # Brightness change notifications
│   │   └── wallpaper-sync.sh        # Syncs waypaper choice to hyprpaper.conf
│   ├── waybar/
│   │   ├── config.jsonc              # Bar modules and layout
│   │   ├── style.css                 # Dark glass theme
│   │   ├── sys_stats.sh             # CPU / RAM / Temp widget
│   │   ├── gpu_stats.sh             # NVIDIA GPU widget
│   │   └── scripts/
│   │       ├── lock-icon.sh          # Pin state indicator (🔒/🔓)
│   │       └── lock-toggle.sh        # Toggle pin / auto-hide
│   ├── rofi/
│   │   └── config.rasi               # Launcher theme (dark glass)
│   ├── kitty/
│   │   └── kitty.conf                # Terminal config (transparent, beam cursor)
│   ├── swaync/
│   │   ├── config.json               # Notification center layout
│   │   └── style.css                 # Notification theme (dark glass)
│   ├── waypaper/
│   │   └── config.ini                # Wallpaper manager settings
│   └── local-bin/
│       ├── launcher-toggle.sh        # Rofi toggle (Super+Space)
│       └── systemupdate.sh           # Waybar update checker
├── zsh/
│   └── .zshrc                        # Zsh + Oh-My-Zsh + Powerlevel10k
├── bash/
│   └── .bashrc                       # Bash fallback
├── greetd-config-fix/
│   └── config.toml                   # greetd + tuigreet config
├── boot-speed/
│   └── ...                           # mkinitcpio fast boot tweaks
├── install.sh                        # One-click installer
└── README.md
```

---

## Keyboard Shortcuts

### Apps

| Shortcut | Action |
|----------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + B` | Browser (Firefox) |
| `Super + E` | File Manager (Dolphin) |
| `Super + Space` | App Launcher (Rofi) |
| `Super + L` | Lock Screen (Hyprlock) |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + C` | Close window |
| `Super + Shift + C` | Force kill window (kill -9) |
| `Super + V` | Toggle floating |
| `Shift + F11` | Toggle fullscreen |
| `Super + Arrow Keys` | Move focus |
| `Super + Left Click` | Drag to move window |
| `Super + Right Click` | Drag to resize window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-9, 0` | Switch to workspace 1-10 |
| `Super + Alt + 1-9, 0` | Send window to workspace (silent) |
| `Super + Shift + 1-9, 0` | Move with window to workspace |
| `Super + Scroll` | Next / previous workspace |
| `Super + Shift + Scroll` | Move with window to next / prev |

### Media & Hardware

| Shortcut | Action |
|----------|--------|
| `Fn + Brightness Up/Down` | Adjust brightness (with OSD) |
| `Fn + Volume Up/Down` | Adjust volume (±5%) |
| `Fn + Mute` | Toggle speaker mute |
| `Fn + Mic Mute` | Toggle microphone mute |
| `Media Play` | Play / Pause |
| `Media Next / Prev` | Next / Previous track |

---

## Waybar Modules

The bar auto-hides like Windows 11 — move your mouse to the top edge to reveal it.

**Left side:**

| Module | Icon | Click | Right-click |
|--------|------|-------|-------------|
| Lock | 🔒 / 🔓 | Toggle pin/auto-hide | — |
| Arch |  | Rofi launcher | Waypaper |
| Workspaces | 1-10 | Switch workspace | — |
| Window title | — | — | — |
| Media | ▶ / ⏸ | Play/Pause | Next track |

**Right side:**

| Module | Icon | Click | Right-click | Scroll |
|--------|------|-------|-------------|--------|
| System | CPU/RAM/Temp | Toggle detail | Open btop | — |
| Volume | 󰕾 | Pavucontrol | — | ±2% |
| Brightness | 󰃞 | — | — | ±5% |
| Battery | 🔋 | — | — | — |
| Wallpaper | 󰸉 | Open Waypaper | Kill Waypaper | — |
| Network | WiFi SSID | — | nm-connection-editor | — |
| Bluetooth | Device | Blueman | — | — |
| Updates | 󰮯 | Run update | — | — |
| Clock |  | Toggle date/time | — | — |
| Power | 󰐥 | Power menu (nwg-bar) | — | — |

---

## Installation

### Quick Install

```bash
git clone https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The installer gives you three options:
1. **Full install** — installs all packages + links configs
2. **Configs only** — just symlinks (if you already have the packages)
3. **Packages only** — just installs dependencies

### Manual Install

<details>
<summary>Click to expand manual steps</summary>

#### 1. Install packages

```bash
# Core
sudo pacman -S hyprland hyprlock hypridle hyprpaper hyprpicker hyprpolkitagent

# Bar & UI
sudo pacman -S waybar rofi swaync nwg-bar nwg-look brightnessctl

# Audio
sudo pacman -S pipewire-pulse pipewire-alsa pipewire-jack pavucontrol pamixer playerctl

# Bluetooth
sudo pacman -S bluez bluez-utils blueman

# Terminal & Shell
sudo pacman -S kitty zsh zsh-completions

# Portals
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Tools
sudo pacman -S grim slurp swappy cliphist jq imagemagick btop fastfetch

# Fonts
sudo pacman -S ttf-jetbrains-mono otf-font-awesome ttf-fira-code

# AUR (via yay)
yay -S waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git
```

#### 2. Link configs

```bash
REPO="$HOME/dotfiles"

# Hyprland
mkdir -p ~/.config/hypr
for f in hyprland.conf hyprpaper.conf waybar-autohide.sh brightness-osd.sh wallpaper-sync.sh; do
  ln -sf "$REPO/config/hypr/$f" ~/.config/hypr/$f
done

# Waybar
mkdir -p ~/.config/waybar/scripts
for f in config.jsonc style.css sys_stats.sh gpu_stats.sh; do
  ln -sf "$REPO/config/waybar/$f" ~/.config/waybar/$f
done
ln -sf "$REPO/config/waybar/scripts/lock-icon.sh" ~/.config/waybar/scripts/lock-icon.sh
ln -sf "$REPO/config/waybar/scripts/lock-toggle.sh" ~/.config/waybar/scripts/lock-toggle.sh

# Rofi, Kitty, SwayNC, Waypaper
ln -sf "$REPO/config/rofi/config.rasi" ~/.config/rofi/config.rasi
ln -sf "$REPO/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
mkdir -p ~/.config/swaync
ln -sf "$REPO/config/swaync/config.json" ~/.config/swaync/config.json
ln -sf "$REPO/config/swaync/style.css" ~/.config/swaync/style.css
ln -sf "$REPO/config/waypaper/config.ini" ~/.config/waypaper/config.ini

# Scripts
mkdir -p ~/.local/share/bin
ln -sf "$REPO/config/local-bin/launcher-toggle.sh" ~/.local/share/bin/launcher-toggle.sh
ln -sf "$REPO/config/local-bin/systemupdate.sh" ~/.local/share/bin/systemupdate.sh

# Shell
ln -sf "$REPO/zsh/.zshrc" ~/.zshrc
ln -sf "$REPO/bash/.bashrc" ~/.bashrc

# Permissions
chmod +x ~/.config/hypr/*.sh ~/.config/waybar/*.sh ~/.config/waybar/scripts/*.sh ~/.local/share/bin/*.sh
echo "1" > ~/.config/waybar/.pinned
```

</details>

### Optional: greetd Login Screen

```bash
sudo pacman -S greetd greetd-tuigreet
sudo cp greetd-config-fix/config.toml /etc/greetd/config.toml
sudo systemctl enable greetd
```

---

## NVIDIA Configuration

This setup is tuned for **NVIDIA GTX 1050 Ti** with proprietary drivers. The following environment variables are set in `hyprland.conf`:

```ini
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = MOZ_ENABLE_WAYLAND,1
```

Additional NVIDIA tweaks:
- Hardware cursors disabled (`no_hardware_cursors = true`)
- Blur and shadows disabled for smooth performance on mobile GPUs
- Qt forced to Wayland with XCB fallback

> **Note:** If you use a different GPU, remove or adjust the NVIDIA env vars in `hyprland.conf`.

---

## Customization

### Change wallpaper
Click the 󰸉 icon in waybar (or right-click the Arch icon). The new wallpaper is automatically saved to `hyprpaper.conf` so it loads instantly on next boot.

### Change wallpaper path
Edit `config/hypr/hyprpaper.conf` — set `preload` and `wallpaper` to your image path.

### Adjust auto-hide behavior
Edit `config/hypr/waybar-autohide.sh` — tweak the sleep timers and mouse position thresholds.

### Pin the bar permanently
Click the 🔒 icon on the far left of the bar. When locked (🔒), the bar stays visible. When unlocked (🔓), it auto-hides.

---

## Credits

Made by **[StxSaryus](https://github.com/StxSaryus)**

Feel free to fork, modify, and share.

---

<div align="center">

**If you like this rice, consider giving it a** ⭐

</div>
