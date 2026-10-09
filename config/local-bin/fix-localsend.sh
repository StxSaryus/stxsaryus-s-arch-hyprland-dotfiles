#!/usr/bin/env bash
# Fix LocalSend OS error 113 (No route to host) on this PC
set -euo pipefail

echo "==> Opening LocalSend ports in firewalld (53317 tcp/udp)"
sudo firewall-cmd --permanent --add-port=53317/tcp
sudo firewall-cmd --permanent --add-port=53317/udp
# LAN: accept from the local subnet
SUBNET="$(ip -4 route show default 2>/dev/null | awk '{print $3}' | sed 's/\.[0-9]*$/.0\/24/' || true)"
if [[ -n "$SUBNET" ]]; then
    sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$SUBNET\" accept" || true
fi
sudo firewall-cmd --reload

echo "==> Current allowed ports:"
sudo firewall-cmd --list-ports
echo "==> Rich rules:"
sudo firewall-cmd --list-rich-rules || true

pkill -x localsend 2>/dev/null || true
sleep 0.3
nohup localsend >/dev/null 2>&1 &

PC_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -I | awk '{print $1}')"
PC_NAME="$(hostname 2>/dev/null || echo "PC")"

echo ""
echo "Done. On your phone / other device:"
echo "  1) Connect to the same local network (PC IP: ${PC_IP:-unknown})"
echo "  2) Open LocalSend -> Select device (${PC_NAME})"
echo ""
echo "If 113 remains after this, the router is blocking Wi-Fi→Ethernet."
echo "Workaround: connect the PC to the same Wi-Fi, or send to the PC hotspot."
