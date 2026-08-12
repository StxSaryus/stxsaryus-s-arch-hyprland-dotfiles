#!/usr/bin/env bash
# Tells the GNOME/portal side of the world that this is a dark session, so
# libadwaita apps, file pickers and Flatpaks match the rest of the rice.
# Safe to run on every login. The GTK ini/css files themselves are installed
# by install.sh.
set -uo pipefail

command -v gsettings >/dev/null 2>&1 || exit 0

iface="org.gnome.desktop.interface"
gsettings set "$iface" color-scheme 'prefer-dark'
gsettings set "$iface" gtk-theme 'adw-gtk3-dark'
gsettings set "$iface" icon-theme 'Papirus-Dark'
gsettings set "$iface" cursor-theme 'Adwaita'
gsettings set "$iface" cursor-size 24
gsettings set "$iface" font-name 'JetBrainsMono Nerd Font 11'
gsettings set "$iface" monospace-font-name 'JetBrainsMono Nerd Font 11'
