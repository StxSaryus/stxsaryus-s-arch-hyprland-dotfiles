#!/usr/bin/env bash
# Enable LocalSend + Bluetooth photo receive (OBEX)
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

info "Installing Bluetooth file-receive (bluez-obex) + LocalSend..."
sudo pacman -S --needed --noconfirm bluez-obex localsend

info "Bluetooth adapter on + discoverable..."
sudo systemctl enable --now bluetooth
bluetoothctl power on >/dev/null
bluetoothctl pairable on >/dev/null
bluetoothctl discoverable on >/dev/null || true

# Trust already-paired phone if present
while read -r _ mac name; do
    [[ -z "${mac:-}" ]] && continue
    bluetoothctl trust "$mac" >/dev/null || true
    info "Trusted: $mac $name"
done < <(bluetoothctl devices 2>/dev/null | awk '{print $1,$2,substr($0,index($0,$3))}')

info "Starting OBEX (needed to receive photos over Bluetooth)..."
systemctl --user enable --now obex
systemctl --user is-active obex >/dev/null && success "obex running" || error "obex failed to start"

if systemctl is-active --quiet firewalld; then
    info "Opening LocalSend ports (53317/tcp+udp) in firewalld..."
    if [[ -f "$HOME/dotfiles/config/firewalld/localsend.xml" ]]; then
        sudo install -Dm644 "$HOME/dotfiles/config/firewalld/localsend.xml" /etc/firewalld/services/localsend.xml
        sudo firewall-cmd --reload || true
        sudo firewall-cmd --permanent --add-service=localsend || true
    fi
    sudo firewall-cmd --permanent --add-port=53317/tcp
    sudo firewall-cmd --permanent --add-port=53317/udp
    # ICMP unreachable (OS error 113) comes from REJECT; still need the port allowed
    sudo firewall-cmd --reload
    success "Firewall allows LocalSend"
    echo "Verify: sudo firewall-cmd --list-ports   (must include 53317/tcp 53317/udp)"
fi

mkdir -p "$HOME/Downloads"

if ! pgrep -x localsend >/dev/null; then
    nohup localsend >/dev/null 2>&1 &
    success "LocalSend started"
else
    success "LocalSend already running"
fi

echo ""
success "Ready to receive photos"
echo "  LocalSend: same Wi-Fi, PC name should appear. Save folder: ~/Downloads"
echo "  Bluetooth: phone → share via Bluetooth → $(hostname 2>/dev/null || echo "PC") (keep discoverable)"
echo "  Incoming BT files: ~/Downloads (or Blueman prompt)"
echo ""
echo "Keep Bluetooth visible for 3 min:"
echo "  bluetoothctl discoverable on"
echo ""
