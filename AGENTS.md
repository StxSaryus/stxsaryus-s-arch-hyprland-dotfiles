# AGENTS.md

## Cursor Cloud specific instructions

This repo is a **dotfiles / rice** for **Arch Linux + Hyprland (Wayland)**, not a client/server app. It is pure Bash scripts plus config files (`config/`, `zsh/`, `bash/`, `nvidia/`, `greetd-config-fix/`, `boot-speed/`). There is **no package manager manifest, no build step, no test suite, and no long-running service/port**. Entry point is `install.sh`; see `README.md` and `INSTALL.md`.

### Environment reality
- The cloud VM is **Ubuntu (headless, no NVIDIA GPU)**. Arch tooling (`pacman`, `yay`), Hyprland, and a Wayland display are **not available**, so the full `./install.sh`, `./install.sh --auto`, `./install.sh --packages`, and `nvidia/setup-nvidia.sh` **cannot run to completion here** (they call `pacman`/`sudo pacman`/DKMS). Do not attempt package/NVIDIA install in this VM.
- The graphical environment (Hyprland/Waybar) **cannot be launched headless** here, so there is nothing to "serve" or screenshot as a running desktop.

### Lint (the only automated check available)
- `shellcheck` is the linter (installed by the update script). Run: `shellcheck $(find . -name '*.sh' -not -path './.git/*')`.
- Syntax-only check: `for f in $(find . -name '*.sh' -not -path './.git/*'); do bash -n "$f"; done`.
- Known **pre-existing** warnings (safe to ignore, do not "fix" without reason): `SC2088` (intentional literal `~` in `install.sh` `LAUNCHER_CMD`, expanded later in `hyprland.conf`) and `SC2028` in `config/local-bin/systemupdate.sh` (echo used for Waybar JSON). `shellcheck` exits non-zero on warnings even when there are no errors.

### Running / demonstrating the "app"
- Safe, GPU-free way to exercise the core installer logic: run **configs-only** against a throwaway HOME so you don't clobber the VM shell:
  `rm -rf /tmp/hypr-home && mkdir -p /tmp/hypr-home && HOME=/tmp/hypr-home ./install.sh --configs`
  This symlinks all configs into `$HOME/.config`, copies+patches `hyprland.conf` (default apps/keybinds), writes `~/.config/waybar/.pinned`, and sets up the default wallpaper.
- Do **not** run `./install.sh --configs` with the real `$HOME`: it replaces `~/.bashrc` and `~/.zshrc` with symlinks to this repo's Arch-oriented shell configs (it backs up originals to `*.bak.<epoch>`), which can disrupt later shell sessions. Use the `HOME=/tmp/...` override instead.
- Waybar widget scripts (e.g. `config/waybar/sys_stats.sh`, `gpu_stats.sh`) run standalone and degrade gracefully without `sensors`/`nvidia-smi` (GPU fields report `0`). Handy for quick runtime sanity checks.
