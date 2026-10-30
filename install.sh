#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root: sudo bash install.sh"
  exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="${SUDO_USER:-$(logname 2>/dev/null || echo pi)}"

echo "[1/7] Installing base packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  python3 python3-venv python3-pip python3-dev \
  firefox-esr hostapd dnsmasq iptables iproute2 git curl ca-certificates xvfb

ENV_FILE="$APP_DIR/config/.env"
if [ ! -f "$ENV_FILE" ]; then
  cp "$APP_DIR/config/.env.example" "$ENV_FILE"
fi

# shellcheck disable=SC1090
set +u
. "$ENV_FILE"
set -u

AP_SSID="${AP_SSID:-MosselTV}"
AP_PASSWORD="${AP_PASSWORD:-change-this}"
AP_INTERFACE="${AP_INTERFACE:-wlan0}"
AP_CHANNEL="${AP_CHANNEL:-6}"

python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --upgrade pip setuptools wheel
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

echo "[2/7] Installing systemd service from repo template..."
SYSTEMD_SRC="$APP_DIR/mosseltv.service"
SYSTEMD_TMP="$(mktemp)"
sed \
  -e "s|@APP_USER@|${APP_USER}|g" \
  -e "s|@APP_DIR@|${APP_DIR}|g" \
  "$SYSTEMD_SRC" > "$SYSTEMD_TMP"
install -m 0644 "$SYSTEMD_TMP" /etc/systemd/system/mosseltv.service
rm -f "$SYSTEMD_TMP"

systemctl daemon-reload

echo "[3/7] Configuring Wi-Fi access point from repo templates..."
mkdir -p /etc/hostapd /etc/dnsmasq.d

if [ -f /etc/default/hostapd ]; then
  sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
  if ! grep -q '^DAEMON_CONF=' /etc/default/hostapd; then
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
  fi
else
  printf '%s\n' 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
fi

sed \
  -e "s|\${AP_SSID}|${AP_SSID}|g" \
  -e "s|\${AP_PASSWORD}|${AP_PASSWORD}|g" \
  -e "s|\${AP_INTERFACE}|${AP_INTERFACE}|g" \
  -e "s|\${AP_CHANNEL}|${AP_CHANNEL}|g" \
  "$APP_DIR/network/hostapd.conf" > /etc/hostapd/hostapd.conf

sed \
  -e "s|\${AP_INTERFACE}|${AP_INTERFACE}|g" \
  "$APP_DIR/network/dnsmasq.conf" > /etc/dnsmasq.d/mosseltv.conf

sed \
  -e "s|\${AP_INTERFACE}|${AP_INTERFACE}|g" \
  "$APP_DIR/network/dhcpcd.conf" > /etc/dhcpcd.conf

systemctl enable hostapd dnsmasq dhcpcd
systemctl restart dhcpcd
systemctl restart dnsmasq
systemctl restart hostapd

echo "[4/7] Enabling MosselTV service..."
systemctl enable mosseltv.service
systemctl start mosseltv.service

echo "[5/7] Finalizing config..."
chown -R "${APP_USER}:${APP_USER}" "$APP_DIR"

cat > "$ENV_FILE" <<EOF
AP_SSID=${AP_SSID}
AP_PASSWORD=${AP_PASSWORD}
AP_INTERFACE=${AP_INTERFACE}
AP_CHANNEL=${AP_CHANNEL}
EOF

echo ""
echo "✅ Installatie afgerond."
echo ""
echo "Controleer of het Wi‑Fi AP werkt op ${AP_INTERFACE}."
echo "- AP SSID: ${AP_SSID}"
echo "- AP password: ${AP_PASSWORD}"
echo "- App URL: http://192.168.50.1:5000/display"
echo "- Manager URL: http://192.168.50.1:5000/manager"
echo ""
echo "Bekijk logs met: sudo journalctl -u mosseltv -f"
echo "Herstarten van de app: sudo systemctl restart mosseltv"
