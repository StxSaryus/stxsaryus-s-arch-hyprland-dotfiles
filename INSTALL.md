# Installation Guide — StxSaryus Arch Hyprland Dotfiles

This document describes the **interactive installer** (`install.sh`), all **application choices**, **keyboard shortcuts**, and **optional components**. Use it as a reference when installing or customizing the setup.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Install Modes](#install-modes)
3. [Application Choices](#application-choices)
4. [Optional Components](#optional-components)
5. [Keyboard Shortcuts](#keyboard-shortcuts)
6. [Customizing Shortcuts](#customizing-shortcuts)
7. [What Gets Installed](#what-gets-installed)
8. [After Installation](#after-installation)

---

## Quick Start

```bash
git clone https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Choose **1) Full install** to go through application and shortcut choices, then install packages and link configs. You can press **Enter** at each prompt to accept defaults.

---

## Install Modes

| Mode | Description |
|------|-------------|
| **1) Full install** | Interactive: choose terminal, browser, file manager, launcher, optional components, and shortcuts. Then install packages and link/copy all configs. Best for first-time setup. |
| **2) Link configs only** | No package installation. Copies/links configs using **default** apps (Kitty, Firefox, Thunar, Rofi) and default shortcuts. Use if you already have the packages. |
| **3) Packages only** | Installs the **default** package set only. No config linking. Use if you want to manage configs yourself. |

---

## Application Choices

During **Full install**, you are asked to pick one application per category. These choices are written into `~/.config/hypr/hyprland.conf` so keybinds launch the correct program.

### Terminal Emulator

| Option | Package | Command | Notes |
|--------|---------|---------|--------|
| 1) Kitty (default) | `kitty` | `kitty` | GPU-accelerated, good Unicode and theme support. |
| 2) Alacritty | `alacritty` | `alacritty` | Fast, minimal. |
| 3) Foot | `foot` | `foot` | Lightweight, Wayland-native. |
| 4) WezTerm | `wezterm` | `wezterm` | Feature-rich, cross-platform. |

**Shortcut (default):** `Super + T` — Opens the chosen terminal.

---

### Web Browser

| Option | Package | Command | Notes |
|--------|---------|---------|--------|
| 1) Firefox (default) | `firefox` | `firefox` | Works well with Wayland (`MOZ_ENABLE_WAYLAND=1` in config). |
| 2) Chromium | `chromium` | `chromium` | Chromium with Wayland support. |
| 3) Brave | `brave-browser` | `brave-browser` | Privacy-focused Chromium-based. |
| 4) Librewolf | `librewolf` | `librewolf` | Firefox fork, privacy-focused. |

**Shortcut (default):** `Super + B` — Opens the chosen browser.

---

### File Manager

| Option | Package | Command | Notes |
|--------|---------|---------|--------|
| 1) Thunar (default) | `thunar` | `thunar` | Lightweight, GTK. |
| 2) Nautilus | `nautilus` | `nautilus` | GNOME Files. |
| 3) Dolphin | `dolphin` | `dolphin` | KDE file manager (Qt). |
| 4) Nemo | `nemo` | `nemo` | Cinnamon file manager. |
| 5) PCManFM | `pcmanfm-gtk3` | `pcmanfm` | Very lightweight. |

**Shortcut (default):** `Super + E` — Opens the chosen file manager.

---

### App Launcher

| Option | Package | Command | Notes |
|--------|---------|---------|--------|
| 1) Rofi (default) | `rofi` | `~/.local/share/bin/launcher-toggle.sh` | Toggle behavior: run again to close. Uses `rofi -show drun`. |
| 2) Fuzzel | `fuzzel` | `fuzzel` | Wayland-native, minimal. |
| 3) Wofi | `wofi` | `wofi --show drun` | Wayland-native menu. |

**Shortcut (default):** `Super + Space` — Opens the chosen launcher.

---

## Optional Components

| Component | Prompt | Package(s) | Description |
|-----------|--------|------------|-------------|
| **Waypaper** | Install Waypaper (wallpaper picker, AUR)? [Y/n] | `waypaper-git` (AUR) | GUI to pick wallpapers; syncs with hyprpaper. Recommended. |
| **Btop** | Install Btop (system monitor)? [Y/n] | `btop`, `fastfetch` | System monitor (click system stats in Waybar) and fetch. |
| **greetd** | Install greetd + tuigreet (login manager)? [y/N] | `greetd`, `greetd-tuigreet` | TUI/graphical login. Copies `greetd-config-fix/config.toml` and enables service. |
| **nwg-look** | Install nwg-look (GTK theme switcher)? [Y/n] | `nwg-look` | Switch GTK themes and fonts from a small GUI. |

---

## Keyboard Shortcuts

All shortcuts use **Super** (Windows key) as the main modifier unless you change it. The installer can patch **only** the five application keybinds (terminal, browser, file manager, launcher, lock); the rest are fixed as below.

### Application Launchers (configurable keys)

| Shortcut | Default key | Action |
|----------|-------------|--------|
| Terminal | `Super + T` | Open terminal (Kitty / Alacritty / Foot / WezTerm) |
| Browser | `Super + B` | Open browser (Firefox / Chromium / Brave / Librewolf) |
| File manager | `Super + E` | Open file manager (Thunar / Nautilus / etc.) |
| App launcher | `Super + Space` | Open app launcher (Rofi / Fuzzel / Wofi) |
| Lock screen | `Super + L` | Lock with Hyprlock |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + C` | Close window (graceful) |
| `Super + Shift + C` | Force kill window (kill -9) |
| `Super + V` | Toggle floating mode |
| `Shift + F11` | Toggle fullscreen |
| `Super + Arrow keys` | Move focus (left / right / up / down) |
| `Super + Left click` (drag) | Move window |
| `Super + Right click` (drag) | Resize window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1` … `Super + 9`, `Super + 0` | Switch to workspace 1–10 |
| `Super + Alt + 1` … `0` | Send window to workspace (no focus change) |
| `Super + Shift + 1` … `0` | Move window to workspace and follow |
| `Super + Mouse scroll` | Next / previous workspace |
| `Super + Shift + Mouse scroll` | Move window to next / previous workspace |

### Media & Hardware Keys

| Shortcut | Action |
|----------|--------|
| `Fn + Brightness Up/Down` | Adjust brightness (with OSD) |
| `Fn + Volume Up/Down` | Volume ±5% |
| `Fn + Mute` | Toggle speaker mute |
| `Fn + Mic Mute` | Toggle microphone mute |
| Media Play/Pause | Play / pause (playerctl) |
| Media Next / Previous | Next / previous track |
| Media Stop | Stop playback |

---

## Customizing Shortcuts

During **Full install**, if you answer **n** to “Use default shortcuts?”, you are asked for:

- **Key for Terminal** (default: `T`) → e.g. `Super + T`
- **Key for Browser** (default: `B`) → e.g. `Super + B`
- **Key for File manager** (default: `E`) → e.g. `Super + E`
- **Key for Launcher** (default: `SPACE`) → e.g. `Super + Space` or `Super + S`
- **Key for Lock** (default: `L`) → e.g. `Super + L`

Use a single letter (e.g. `T`, `B`, `S`) or special key names such as `SPACE`, `RETURN`, `ESCAPE`. The installer writes these into `~/.config/hypr/hyprland.conf`. To change them later, edit that file and adjust the `bind = $mainMod, KEY, exec, ...` lines.

---

## What Gets Installed

### Core (always with Full or Packages-only install)

- **Hyprland stack:** hyprland, hyprlock, hypridle, hyprpaper, hyprpicker, hyprpolkitagent  
- **Bar & UI:** waybar, swaync, nwg-bar, brightnessctl  
- **Audio:** pipewire-pulse, pipewire-alsa, pipewire-jack, pavucontrol, pamixer, playerctl  
- **Bluetooth:** bluez, bluez-utils, blueman  
- **Shell:** zsh, zsh-completions  
- **Portals:** xdg-desktop-portal, xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk  
- **Tools:** grim, slurp, swappy, cliphist, jq, imagemagick, network-manager-applet  
- **Fonts:** ttf-jetbrains-mono, otf-font-awesome, ttf-fira-code  

Plus the **one** terminal, **one** browser, **one** file manager, and **one** launcher you chose.

### Optional (by choice)

- Waypaper (AUR), Btop + Fastfetch, nwg-look, greetd + tuigreet  

### AUR (if `yay` is available)

- waypaper-git (if selected), oh-my-zsh-git, zsh-theme-powerlevel10k-git  

---

## After Installation

1. **Log out and log back in** (or reboot) so Hyprland and the new configs are used.
2. **Optional — greetd:** If you enabled greetd, the script enables the service and copies `greetd-config-fix/config.toml`. Restart to use the new login manager.
3. **Wallpaper:** If Waypaper is installed, use the Waybar wallpaper icon or right-click the Arch icon to set a wallpaper; it is synced to hyprpaper and persists across reboots.
4. **Shortcuts:** See the tables above. Your chosen app keybinds are in `~/.config/hypr/hyprland.conf`.

For manual install steps and file layout, see the main [README.md](README.md).
