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
- **Interactive installer** — `install.sh` lets you choose terminal, browser, file manager, launcher, optional components, and keyboard shortcuts; see [INSTALL.md](INSTALL.md) for full details
- **10 workspaces** — full keyboard + mouse scroll navigation
- **Dark glass aesthetic** — translucent bar, rounded corners, minimal design

---

## Software Used

| Role | Software |
|------|----------|
| **Window Manager** | Hyprland (Wayland) |
| **Status Bar** | Waybar (auto-hide, Win11 style) |
| **Terminal** | Kitty |
| **Shell** | Zsh + Oh-My-Zsh + Powerlevel10k |
| **App Launcher** | Rofi |
| **Notification Center** | SwayNC |
| **Wallpaper Manager** | Waypaper + Hyprpaper |
| **Screen Lock** | Hyprlock |
| **Power Menu** | nwg-bar |
| **File Manager** | Thunar |
| **Browser** | Firefox |
| **Audio Server** | PipeWire |
| **Bluetooth Manager** | Blueman |

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
│   │       ├── lock-icon.sh          # Pin state indicator
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
├── install.sh                        # Interactive installer (apps + shortcuts)
├── INSTALL.md                        # Full install guide & shortcut reference
└── README.md
```

---

## Keyboard Shortcuts

### Apps

| Shortcut | Action |
|----------|--------|
| `Super + T` | Open terminal (Kitty) |
| `Super + B` | Open browser (Firefox) |
| `Super + E` | Open file manager (Thunar) |
| `Super + Space` | Open app launcher (Rofi) |
| `Super + L` | Lock screen (Hyprlock) |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + C` | Close window (graceful) |
| `Super + Shift + C` | Force kill window (kill -9) |
| `Super + V` | Toggle floating mode |
| `Shift + F11` | Toggle fullscreen |
| `Super + Arrow Keys` | Move focus between windows |
| `Super + Left Click` (drag) | Move window |
| `Super + Right Click` (drag) | Resize window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-9, 0` | Switch to workspace 1-10 |
| `Super + Alt + 1-9, 0` | Send window to workspace (silent) |
| `Super + Shift + 1-9, 0` | Move with window to workspace |
| `Super + Mouse Scroll` | Next / previous workspace |
| `Super + Shift + Mouse Scroll` | Move with window to next / prev workspace |

### Media & Hardware Keys

| Shortcut | Action |
|----------|--------|
| `Fn + Brightness Up/Down` | Adjust screen brightness (with OSD notification) |
| `Fn + Volume Up/Down` | Adjust volume by 5% |
| `Fn + Mute` | Toggle speaker mute |
| `Fn + Mic Mute` | Toggle microphone mute |
| `Media Play/Pause` | Play or pause current media |
| `Media Next / Previous` | Skip to next or previous track |

---

## Waybar Modules

The bar auto-hides like Windows 11 — move your mouse to the top edge to reveal it.

### Left Side

| Module | What it shows | Click action | Right-click action |
|--------|--------------|--------------|-------------------|
| **Pin Toggle** | Locked / Unlocked icon | Toggle between pinned bar and auto-hide | — |
| **Arch Logo** | Arch Linux icon | Open Rofi app launcher | Open Waypaper wallpaper picker |
| **Workspaces** | Workspace numbers 1-10 | Switch to that workspace | — |
| **Window Title** | Active window name | — | — |
| **Media Player** | Now playing track name | Play / Pause | Next track |

### Right Side

| Module | What it shows | Click action | Right-click action | Scroll action |
|--------|--------------|--------------|-------------------|---------------|
| **System Stats** | CPU / RAM / Temperature | Toggle between compact and detailed view | Open btop system monitor | — |
| **Volume** | Speaker volume percentage | Open Pavucontrol mixer | — | Adjust volume by 2% |
| **Brightness** | Screen brightness percentage | — | — | Adjust brightness by 5% |
| **Battery** | Battery percentage and state | — | — | — |
| **Wallpaper** | Wallpaper picker icon | Open Waypaper | Close Waypaper | — |
| **Network** | WiFi network name or Ethernet | — | Open network settings | — |
| **Bluetooth** | Connected device name | Open Blueman manager | — | — |
| **Updates** | Available update count | Run system update in terminal | — | — |
| **Clock** | Current time | Toggle between time and date | — | — |
| **Power** | Power icon | Open power menu (shutdown, reboot, etc.) | — | — |

---

## Installation

### Quick Install

```bash
git clone https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The installer offers three modes:
1. **Full install** — Interactive: choose terminal, browser, file manager, app launcher, optional components (Waypaper, Btop, greetd, nwg-look), and keyboard shortcuts; then install packages and link configs.
2. **Configs only** — Link/copy configs with default apps (Kitty, Firefox, Thunar, Rofi) and default shortcuts; no package install.
3. **Packages only** — Install the default package set only; no config linking.

For a detailed list of application choices, all keyboard shortcuts, and optional components, see **[INSTALL.md](INSTALL.md)**.

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

# Portals (needed for file dialogs and theme detection)
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Tools
sudo pacman -S grim slurp swappy cliphist jq imagemagick btop fastfetch thunar

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
mkdir -p ~/.config/rofi ~/.config/kitty ~/.config/swaync ~/.config/waypaper
ln -sf "$REPO/config/rofi/config.rasi" ~/.config/rofi/config.rasi
ln -sf "$REPO/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
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

This setup includes NVIDIA-specific environment variables in `hyprland.conf` for proprietary driver compatibility:

```ini
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = MOZ_ENABLE_WAYLAND,1
```

Additional tweaks:
- Hardware cursors disabled (`no_hardware_cursors = true`)
- Blur and shadows disabled for better performance on mobile GPUs
- Qt forced to Wayland with XCB fallback

> **Note:** If you use an AMD or Intel GPU, remove or comment out the NVIDIA env vars in `hyprland.conf`.

---

## Customization

### Change wallpaper
Click the wallpaper icon in the waybar (or right-click the Arch logo). Your new wallpaper is automatically saved to `hyprpaper.conf` so it loads instantly on next boot.

### Adjust auto-hide behavior
Edit `config/hypr/waybar-autohide.sh` to tweak sleep timers and mouse position thresholds.

### Pin the bar permanently
Click the lock icon on the far left of the bar. When locked, the bar stays visible at all times. When unlocked, it auto-hides when your mouse leaves.

### Change default apps and shortcuts
Re-run `./install.sh` and choose **Full install** to pick different apps and shortcuts. Or edit `~/.config/hypr/hyprland.conf` (keybind section) to change `exec` commands and key bindings. See [INSTALL.md](INSTALL.md) for the full shortcut list.

---

## Credits

Made by **[StxSaryus](https://github.com/StxSaryus)**

Feel free to fork, modify, and share.

---

<div align="center">

**If you like this rice, consider giving it a star!**

</div>
