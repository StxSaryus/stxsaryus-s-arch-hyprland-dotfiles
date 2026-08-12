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

- **One palette, everywhere** — bar, launcher, terminal, notifications, lock screen, session menu and GTK apps all read the same colours from [`config/theme/palette.conf`](config/theme/README.md)
- **Windows 11 style Waybar** — auto-hides at the top, shows on hover, pin/unpin with one click
- **NVIDIA optimized** — env vars, software cursors, blur and shadows off, `vfr` on
- **Cheap when idle** — the stats widget reads `/proc` instead of shelling out to `top`, and the auto-hide watcher polls adaptively with a single process
- **Instant wallpaper** — hyprpaper loads your wallpaper at boot with zero delay
- **One-command installer** — `./install.sh` handles packages, yay, fonts, configs, and the right NVIDIA driver (Pascal → `nvidia-580xx-dkms` per Arch News); see [INSTALL.md](INSTALL.md)
- **Tested** — `./tests/run-tests.sh` checks the things that otherwise fail silently

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
| **Idle Management** | Hypridle |
| **Power Menu** | nwg-bar |
| **Clipboard History** | cliphist + wl-clipboard |
| **Screenshots** | grim + slurp + swappy |
| **File Manager** | Thunar |
| **Browser** | Firefox |
| **Audio Server** | PipeWire |
| **Bluetooth Manager** | Blueman |

---

## The look

Colours, radii, fonts and icons are defined once and derived for every
application. The full reference lives in
**[config/theme/README.md](config/theme/README.md)**.

| | |
|---|---|
| Accent | `#33ccff` — Arch cyan |
| Surfaces | `#07080b` → `#262a36`, blue-tinted dark |
| Radii | `8px` pills · `12px` windows and cards · `16px` bar, launcher, panels |
| Font | JetBrainsMono Nerd Font |
| Icons | Material Design set only — one family, one stroke weight |

Change one line in `config/theme/palette.conf`, run
`./config/theme/build-theme.sh`, and the whole desktop follows.

---

## File Structure

```
.
├── config/
│   ├── theme/
│   │   ├── palette.conf              # THE colours — edit here
│   │   ├── build-theme.sh            # regenerates the four files below
│   │   ├── colors.css                # GTK: waybar, swaync, nwg-bar, waypaper
│   │   ├── colors.rasi               # rofi
│   │   ├── colors-kitty.conf         # kitty
│   │   └── colors-hypr.conf          # hyprland + hyprlock
│   ├── hypr/
│   │   ├── hyprland.conf             # main config (NVIDIA tuned)
│   │   ├── hyprlock.conf             # lock screen
│   │   ├── hypridle.conf             # dim → lock → screen off → suspend
│   │   ├── hyprpaper.conf            # wallpaper preload (copied, not linked)
│   │   ├── waybar-autohide.sh        # Win11-style show/hide watcher
│   │   ├── osd.sh                    # one OSD for brightness, volume and mic
│   │   ├── wallpaper-sync.sh         # waypaper choice → hyprpaper.conf
│   │   └── apply-dark-theme.sh       # tells portals/libadwaita it is dark
│   ├── waybar/
│   │   ├── config.jsonc              # modules and layout
│   │   ├── style.css                 # bar styling
│   │   ├── sys_stats.sh              # CPU / GPU / RAM from /proc and /sys
│   │   └── scripts/
│   │       ├── lock-icon.sh          # pin indicator (signal driven)
│   │       └── lock-toggle.sh        # pin / unpin the bar
│   ├── rofi/config.rasi              # launcher
│   ├── kitty/kitty.conf              # terminal
│   ├── swaync/                       # notifications + control centre
│   ├── nwg-bar/                      # session menu
│   ├── waypaper/                     # wallpaper picker + its GTK style
│   ├── gtk-2.0/ gtk-3.0/ gtk-4.0/    # dark theme + accent for GTK apps
│   └── local-bin/
│       ├── launcher-toggle.sh        # Rofi toggle (Super+Space)
│       ├── waypaper-toggle.sh        # wallpaper picker, open/close
│       ├── session-menu.sh           # power button → nwg-bar
│       └── systemupdate.sh           # update counter for the bar
├── tests/
│   ├── run-tests.sh                  # everything below, in one command
│   ├── check_*.py                    # json, palette, glyphs, css, references
│   ├── test-autohide.sh              # auto-hide behaviour, Hyprland stubbed
│   ├── bench-*.sh                    # before/after cost of the hot scripts
│   └── preview/run-preview.sh        # renders the rice headless, screenshots it
├── zsh/.zshrc                        # Zsh + Oh-My-Zsh + Powerlevel10k
├── bash/.bashrc                      # Bash fallback
├── greetd-config-fix/                # greetd + tuigreet
├── nvidia/                           # driver, DKMS and modprobe setup
├── boot-speed/                       # mkinitcpio fast boot tweaks
├── doctor.sh                         # checks a live install, says what is broken
├── install.sh                        # fully automatic installer
├── INSTALL.md                        # guide + official Arch/NVIDIA notices
└── README.md
```

---

## Keyboard Shortcuts

### Apps

| Shortcut | Action |
|----------|--------|
| `Super + T` | Terminal (Kitty) |
| `Super + B` | Browser (Firefox) |
| `Super + E` | File manager (Thunar) |
| `Super + Space` | App launcher (Rofi) |
| `Super + L` | Lock screen (Hyprlock) |
| `Super + W` | Wallpaper picker (Waypaper) |
| `Super + N` | Notification centre |
| `Super + P` | Pin / unpin the bar |
| `Super + X` | Clipboard history |

### Window Management

| Shortcut | Action |
|----------|--------|
| `Super + C` | Close window (graceful) |
| `Super + Shift + C` | Force kill window |
| `Super + V` | Toggle floating |
| `Super + F` / `Shift + F11` | Toggle fullscreen |
| `Super + J` | Toggle split direction |
| `Super + Arrows` | Move focus |
| `Super + Shift + Arrows` | Move the window |
| `Super + Ctrl + Arrows` | Resize the window |
| `Super + S` | Toggle the scratchpad |
| `Super + Shift + S` | Send window to the scratchpad |
| `Super + Left Click` (drag) | Move window |
| `Super + Right Click` (drag) | Resize window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-9, 0` | Switch to workspace 1-10 |
| `Super + Shift + 1-9, 0` | Move with the window |
| `Super + Alt + 1-9, 0` | Send the window, stay put |
| `Super + Scroll` | Next / previous workspace |
| `Super + Shift + Scroll` | Move with the window |

### Screenshots & Colour

| Shortcut | Action |
|----------|--------|
| `Print` | Whole screen → Swappy |
| `Shift + Print` | Select a region → Swappy |
| `Super + Shift + P` | Pick a colour (hyprpicker) |

### Media & Hardware Keys

| Shortcut | Action |
|----------|--------|
| `Brightness Up/Down` | Adjust brightness, with an OSD |
| `Volume Up/Down`, `Mute` | Adjust volume, with the same OSD |
| `Mic Mute` | Toggle the microphone |
| `Play / Pause / Next / Prev` | playerctl |

---

## Waybar Modules

The bar auto-hides like Windows 11 — move the pointer to the top edge to
reveal it, or pin it with the padlock on the far left.

### Left

| Module | Shows | Click | Right click |
|--------|-------|-------|-------------|
| **Pin** | Padlock, accent when pinned | Pin / unpin the bar | — |
| **Arch logo** | Arch mark | App launcher | Wallpaper picker |
| **Workspaces** | 1-10, current one in accent | Switch | — |
| **Window title** | Active window | — | — |
| **Media** | Player icon and track | Play / pause | Next track |

### Right

| Module | Shows | Click | Right click | Scroll |
|--------|-------|-------|-------------|--------|
| **System** | CPU / GPU / RAM | Switch load ⇄ temperature | btop | — |
| **Volume** | Level or muted | Pavucontrol | Mute | ±2% |
| **Brightness** | Level | — | — | ±5% |
| **Battery** | Charge and state | — | — | — |
| **Wallpaper** | Picker | Open the picker, or close it if open | Same | — |
| **Network** | SSID or interface | — | Connection editor | — |
| **Bluetooth** | Connected device | Blueman | — | — |
| **Updates** | Pending package count | Upgrade in a terminal | — | — |
| **Clock** | Time, calendar on hover | Switch to the date | — | Change month |
| **Notifications** | Bell, accent when unread | Control centre | Do not disturb | — |
| **Power** | Session menu | nwg-bar | — | — |

---

## Installation

### Quick Install (fully automatic)

```bash
git clone https://github.com/StxSaryus/stxsaryus-s-arch-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
sudo reboot
```

The installer:

1. Prints **official Arch / Hyprland / NVIDIA notices** (with source URLs)
2. Detects your NVIDIA GPU generation
3. Installs pacman + AUR packages (installs `yay` if missing)
4. Sets up the correct NVIDIA driver + DKMS + GRUB `nvidia_drm.modeset=1`
5. Links configs, Nerd Fonts, wallpaper defaults

| Flag | Behavior |
|------|----------|
| `./install.sh` | Auto defaults, one confirm |
| `./install.sh --auto` | No prompts |
| `./install.sh --interactive` | Choose apps / shortcuts |
| `./install.sh --configs` | Configs only |
| `./install.sh --packages` | Packages + NVIDIA only |

Application choices can also come from the environment, which is handy for
scripted reinstalls:

```bash
TERMINAL_CMD=alacritty KEY_TERMINAL=RETURN ./install.sh --configs
```

Details, shortcuts, and official quotes: **[INSTALL.md](INSTALL.md)**.

### What gets linked, and what gets copied

Configs are symlinked into `~/.config`, so `git pull` updates your desktop.
Two files are **copied** instead: `hypr/hyprpaper.conf` and
`waypaper/config.ini`. Their applications write to them, and a symlink would
have Waypaper editing your git checkout every time you picked a wallpaper.

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
sudo pacman -S kitty zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting lsd fzf

# Portals (needed for file dialogs and theme detection)
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Tools
sudo pacman -S grim slurp swappy cliphist wl-clipboard jq imagemagick btop fastfetch thunar

# Fonts (Nerd Font required for Waybar icons)
sudo pacman -S ttf-jetbrains-mono-nerd otf-font-awesome ttf-fira-code

# Themes
sudo pacman -S adw-gtk-theme papirus-icon-theme

# AUR (via yay)
yay -S waypaper-git oh-my-zsh-git zsh-theme-powerlevel10k-git
# Pascal / GTX 10xx only (Arch News NVIDIA 590):
# yay -S nvidia-580xx-dkms nvidia-580xx-utils
```

#### 2. Link configs

```bash
REPO="$HOME/dotfiles"

# Palette — every other config reads this
mkdir -p ~/.config/theme
for f in palette.conf build-theme.sh colors.css colors.rasi colors-kitty.conf colors-hypr.conf; do
  ln -sf "$REPO/config/theme/$f" ~/.config/theme/$f
done

# Hyprland
mkdir -p ~/.config/hypr
for f in hyprland.conf hyprlock.conf hypridle.conf waybar-autohide.sh osd.sh wallpaper-sync.sh apply-dark-theme.sh; do
  ln -sf "$REPO/config/hypr/$f" ~/.config/hypr/$f
done
cp -n "$REPO/config/hypr/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf

# Waybar
mkdir -p ~/.config/waybar/scripts
for f in config.jsonc style.css sys_stats.sh; do
  ln -sf "$REPO/config/waybar/$f" ~/.config/waybar/$f
done
for f in lock-icon.sh lock-toggle.sh; do
  ln -sf "$REPO/config/waybar/scripts/$f" ~/.config/waybar/scripts/$f
done

# Rofi, Kitty, SwayNC, nwg-bar, Waypaper
mkdir -p ~/.config/{rofi,kitty,swaync,nwg-bar,waypaper}
ln -sf "$REPO/config/rofi/config.rasi" ~/.config/rofi/config.rasi
ln -sf "$REPO/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$REPO/config/swaync/config.json" ~/.config/swaync/config.json
ln -sf "$REPO/config/swaync/style.css" ~/.config/swaync/style.css
ln -sf "$REPO/config/nwg-bar/bar.json" ~/.config/nwg-bar/bar.json
ln -sf "$REPO/config/nwg-bar/style.css" ~/.config/nwg-bar/style.css
ln -sf "$REPO/config/waypaper/style.css" ~/.config/waypaper/style.css
cp -n "$REPO/config/waypaper/config.ini" ~/.config/waypaper/config.ini

# GTK
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
for v in 3.0 4.0; do
  ln -sf "$REPO/config/gtk-$v/settings.ini" ~/.config/gtk-$v/settings.ini
  ln -sf "$REPO/config/gtk-$v/gtk.css" ~/.config/gtk-$v/gtk.css
done
ln -sf "$REPO/config/gtk-2.0/.gtkrc-2.0" ~/.gtkrc-2.0

# Scripts and shells
mkdir -p ~/.local/share/bin
for f in launcher-toggle.sh systemupdate.sh; do
  ln -sf "$REPO/config/local-bin/$f" ~/.local/share/bin/$f
done
ln -sf "$REPO/zsh/.zshrc" ~/.zshrc
ln -sf "$REPO/bash/.bashrc" ~/.bashrc

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

### Official Arch policy (NVIDIA 590+)

Arch Linux News:  
https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/

> NVIDIA 590 no longer supports Pascal (GTX 10xx) or older. Use **`nvidia-580xx-dkms`** from the AUR on those cards. Newer GPUs transition to **`nvidia-open`**.

`./install.sh` applies this automatically. Standalone re-fix:

```bash
sudo ~/dotfiles/nvidia/setup-nvidia.sh
sudo reboot
```

### Hyprland env (in `hyprland.conf`)

```ini
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = XDG_SESSION_TYPE,wayland
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto
```

Tweaks for mobile GPUs: software cursors, blur and shadows off, `vfr` on, Qt
Wayland with an XCB fallback.

> AMD/Intel only: comment out the NVIDIA `env` lines in `hyprland.conf`.
> Blur is off for the same reason; turn it on in `decoration:blur` if your
> card can spare the frame time.

### Hyprland 0.55+

- `dwindle:pseudotile` removed upstream — already gone from this repo.
- Autogenerated `hyprland.lua` beats `.conf`; installer relocates `.lua`.
- After install: **reboot** (NVIDIA) then log into Hyprland.

---

## Something is not working

```bash
./doctor.sh
```

Checks a live install and prints what is wrong, with the command that fixes
each thing: missing programs (a button that calls a program you do not have
looks exactly like a dead button), the Nerd Font, every config file and
symlink, `hyprctl configerrors`, the processes that should be running, and
the scripts behind the bar. It changes nothing.

---

## Tests

```bash
./tests/run-tests.sh
```

Eleven groups of checks, all aimed at the failures this kind of repo has that
never announce themselves:

| Check | Catches |
|-------|---------|
| shell syntax, shellcheck | broken and sloppy scripts |
| theme in sync | generated colour files that drifted from `palette.conf` |
| json configs | malformed JSON, modules placed but never defined, empty icons |
| palette discipline | any colour under `config/` that is not in the palette |
| nerd font glyphs | icons missing from the font, or from the wrong icon family |
| gtk stylesheets | CSS that GTK silently drops |
| cross references | a config pointing at a file the repo does not ship, or a file `install.sh` forgot |
| hyprland config | undeclared variables, unbalanced braces, duplicate keybinds |
| installer | broken links, unresolved imports, or the installer writing into the checkout |
| waybar autohide | show / hide / pin behaviour, and the idle poll budget |

Two benchmarks compare the hot scripts against any earlier revision:

```bash
./tests/bench-sysstats.sh 20 origin/main
./tests/bench-autohide.sh 10 origin/main
```

And the whole rice can be rendered without a login session — headless sway,
the real Waybar config, real stylesheets, screenshots at the end:

```bash
./tests/preview/run-preview.sh
```

---

## Customization

### Recolour everything

Edit `config/theme/palette.conf`, then:

```bash
./config/theme/build-theme.sh
```

Hyprland borders, the bar, launcher, terminal, notifications, lock screen,
session menu and GTK apps all pick up the change. See
[config/theme/README.md](config/theme/README.md).

### Change wallpaper

Click the wallpaper icon in the bar (or right-click the Arch logo). Your
choice is written to `hyprpaper.conf`, so it is on screen at next boot.

### Adjust auto-hide behaviour

`config/hypr/waybar-autohide.sh` — the reveal and hide zones and the two poll
intervals are named constants at the top.

### Pin the bar

Click the padlock at the far left, or press `Super + P`. Pinned, the bar stays
visible; unpinned, it hides when the pointer leaves.

### Change default apps and shortcuts

`./install.sh --interactive`, or edit the five variables at the top of
`~/.config/hypr/hyprland.conf`.

---

## Credits

Made by **[StxSaryus](https://github.com/StxSaryus)**

Feel free to fork, modify, and share.

---

<div align="center">

**If you like this rice, consider giving it a star!**

</div>
