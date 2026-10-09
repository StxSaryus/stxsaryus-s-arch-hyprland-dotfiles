#!/usr/bin/env bash
# Apply system dark theme (GTK / icons / portals). Safe to run every login.
set -euo pipefail

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# libadwaita / xdg-desktop-portal
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
fi

mkdir -p "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_CONFIG_HOME/gtk-4.0" \
         "$XDG_CONFIG_HOME/xdg-desktop-portal" "$XDG_CONFIG_HOME/environment.d" \
         "$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d"

# Always rewrite GTK settings so apps cannot fall back to light
for ver in 3.0 4.0; do
    cat > "$XDG_CONFIG_HOME/gtk-${ver}/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=menu:
EOF
done

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
[[ -f "$REPO/config/kdeglobals" ]] && cp -f "$REPO/config/kdeglobals" "$XDG_CONFIG_HOME/kdeglobals"
[[ -f "$REPO/config/xdg-desktop-portal/portals.conf" ]] && \
    cp -f "$REPO/config/xdg-desktop-portal/portals.conf" "$XDG_CONFIG_HOME/xdg-desktop-portal/portals.conf"
[[ -f "$REPO/config/environment.d/90-dark-theme.conf" ]] && \
    cp -f "$REPO/config/environment.d/90-dark-theme.conf" "$XDG_CONFIG_HOME/environment.d/90-dark-theme.conf"
[[ -f "$REPO/config/wireplumber/wireplumber.conf.d/51-disable-hfp-autoswitch.conf" ]] && \
    cp -f "$REPO/config/wireplumber/wireplumber.conf.d/51-disable-hfp-autoswitch.conf" \
       "$XDG_CONFIG_HOME/wireplumber/wireplumber.conf.d/51-disable-hfp-autoswitch.conf"
