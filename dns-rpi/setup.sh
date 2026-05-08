############################################
# ADGUARD HOME INSTALL (MODERN WAY)
############################################

log "Installing AdGuard Home"

ADGUARD_DIR="/opt/AdGuardHome"

if [[ ! -f /usr/local/bin/AdGuardHome ]]; then

  mkdir -p /tmp/adguard
  cd /tmp/adguard

  curl -fsSL https://static.adguard.com/adguardhome/release/AdGuardHome_linux_arm.tar.gz -o adguard.tar.gz

  tar -xzf adguard.tar.gz

  cd AdGuardHome

  ./AdGuardHome -s install

else
  echo "AdGuard Home already installed"
fi

############################################
# DNS STRATEGY NOTE (IMPORTANT)
############################################

cat <<EOF

AdGuard Home is now installed.

RECOMMENDED SETUP (IMPORTANT):

1. Do NOT use /etc/hosts for LAN resolution
   - use AdGuard "DNS rewrites" instead

2. Set router DNS to:
   - 192.168.1.229 (AdGuard)

3. Configure static hostnames inside AdGuard UI:
   Settings → DNS → DNS rewrites

EOF

############################################
# OPTIONAL LOCAL DNS FORWARDER (dnsmasq SAFE MODE)
############################################

log "Configuring optional dnsmasq (local only)"

apt install -y dnsmasq

DNSMASQ_CONF="/etc/dnsmasq.d/local.conf"

cat >"${DNSMASQ_CONF}" <<EOF
# Local DNS forwarder for custom resolution
listen-address=127.0.0.1
bind-interfaces
port=5553

# Forward everything to AdGuard
server=192.168.1.229
EOF

systemctl restart dnsmasq
