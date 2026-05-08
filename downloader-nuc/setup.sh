#!/usr/bin/env bash

set -Eeuo pipefail

############################################
# CONFIGURATION
############################################

USERNAME="${SUDO_USER:-$USER}"

SSH_PORT="2222"

MOUNT_UUID="3b3e573f-f3b5-410c-841a-0ee9949925f7"
MOUNT_POINT="/mnt/extHD"

CONFIG_BASE="${MOUNT_POINT}/raspberrypi/configs"

NFS_NETWORK="192.168.1.0/24"

COMPOSE_DIR="/home/${USERNAME}/docker"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"

TIMEZONE="Europe/Madrid"

############################################
# HELPERS
############################################

log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

backup_file() {
  local file="$1"

  if [[ -f "$file" ]]; then
    cp "$file" "${file}.bak.$(date +%s)"
  fi
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo"
    exit 1
  fi
}

############################################
# START
############################################

require_root

log "Updating Ubuntu"

apt update
apt upgrade -y
apt autoremove -y

############################################
# PACKAGES
############################################

log "Installing packages"

apt install -y \
  ca-certificates \
  curl \
  fail2ban \
  git \
  gnupg \
  htop \
  iftop \
  iotop \
  jq \
  lsb-release \
  net-tools \
  nfs-kernel-server \
  nvme-cli \
  smartmontools \
  tmux \
  tree \
  ufw \
  unzip \
  vim \
  wget

############################################
# TIMEZONE
############################################

log "Setting timezone"

timedatectl set-timezone "${TIMEZONE}"

############################################
# SSH HARDENING
############################################

log "Configuring SSH"

mkdir -p /etc/ssh/sshd_config.d

cat >/etc/ssh/sshd_config.d/99-custom.conf <<EOF
Port ${SSH_PORT}

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no

PubkeyAuthentication yes
UsePAM yes

X11Forwarding no

MaxAuthTries 3

ClientAliveInterval 300
ClientAliveCountMax 2
EOF

sshd -t

systemctl restart ssh

############################################
# FIREWALL
############################################

# log "Configuring firewall"

# ufw default deny incoming
# ufw default allow outgoing

# ufw allow "${SSH_PORT}/tcp"

# ufw --force enable

############################################
# FAIL2BAN
############################################

log "Configuring fail2ban"

cat >/etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ${SSH_PORT}
EOF

systemctl enable fail2ban
systemctl restart fail2ban

############################################
# DOCKER
############################################

log "Installing Docker"

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list

apt update

apt install -y \
  containerd.io \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

if ! getent group docker >/dev/null; then
  groupadd docker
fi

usermod -aG docker "${USERNAME}"

############################################
# DOCKER DAEMON
############################################

log "Configuring Docker daemon"

mkdir -p /etc/docker

cat >/etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  },
  "features": {
    "buildkit": true
  },
  "live-restore": true
}
EOF

systemctl restart docker

############################################
# STORAGE
############################################

log "Configuring storage"

mkdir -p "${MOUNT_POINT}"

if ! blkid | grep -q "${MOUNT_UUID}"; then
  echo
  echo "ERROR: UUID not found:"
  echo "${MOUNT_UUID}"
  exit 1
fi

grep -q "${MOUNT_UUID}" /etc/fstab || cat >>/etc/fstab <<EOF

UUID=${MOUNT_UUID} ${MOUNT_POINT} ext4 defaults,nofail 0 2
EOF

mount -a

mkdir -p "${CONFIG_BASE}"

chown -R "${USERNAME}:${USERNAME}" "${MOUNT_POINT}"

############################################
# CREATE CONFIG DIRECTORIES FROM COMPOSE
############################################

log "Creating config directories from docker-compose.yml"

mkdir -p "${COMPOSE_DIR}"

if [[ ! -f "${COMPOSE_FILE}" ]]; then

  echo
  echo "No docker-compose.yml found:"
  echo "${COMPOSE_FILE}"
  echo
  echo "Skipping config directory creation."

else

  cd "${COMPOSE_DIR}"

  docker compose config 2>/dev/null \
    | awk '
      /^[[:space:]]*source:/ {
        print $2
      }
    ' \
    | while read -r path; do

        [[ -z "${path}" ]] && continue

        # Only manage config directories
        if [[ "${path}" == ${CONFIG_BASE}/* ]]; then

          # Ignore file mounts
          if [[ "${path}" =~ \.(yml|yaml|json|conf|env|txt|xml|ini|db)$ ]]; then
            continue
          fi

          if [[ ! -d "${path}" ]]; then
            echo "Creating: ${path}"
            mkdir -p "${path}"
          else
            echo "Exists: ${path}"
          fi
        fi

      done

fi

chown -R "${USERNAME}:${USERNAME}" "${CONFIG_BASE}"

############################################
# NFS
############################################

# log "Configuring NFS"

# backup_file /etc/exports

# EXPORT_LINE="${MOUNT_POINT} ${NFS_NETWORK}(rw,sync,no_subtree_check)"

# grep -qF "${EXPORT_LINE}" /etc/exports || echo "${EXPORT_LINE}" >>/etc/exports

# exportfs -ra

# systemctl enable nfs-server
# systemctl restart nfs-server

############################################
# DISABLE SUSPEND
############################################

log "Disabling suspend"

systemctl mask \
  sleep.target \
  suspend.target \
  hibernate.target \
  hybrid-sleep.target

############################################
# ALIASES
############################################

log "Configuring aliases"

ALIASES_FILE="/home/${USERNAME}/.bash_aliases"

touch "${ALIASES_FILE}"

grep -q "### SERVER ALIASES ###" "${ALIASES_FILE}" || cat >>"${ALIASES_FILE}" <<'EOF'

### SERVER ALIASES ###

############################
# GENERAL
############################

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'

############################
# SYSTEM
############################

alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean -y'

alias ports='ss -tulpen'
alias myip='curl -s ifconfig.me'

alias disks='df -h'
alias mem='free -h'

############################
# DOCKER
############################

alias d='docker'
alias dc='docker compose'

alias dps='docker ps'
alias dpsa='docker ps -a'

alias di='docker images'

alias dprune='docker system prune -af --volumes'

alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dcps='docker compose ps'
alias dclogs='docker compose logs -f'
alias dcpull='docker compose pull'

dbash() {
  docker exec -it "$(docker ps -qf "name=$1" | head -n1)" bash
}

dsh() {
  docker exec -it "$(docker ps -qf "name=$1" | head -n1)" sh
}

dlogsf() {
  docker logs -f "$(docker ps -qf "name=$1" | head -n1)"
}

############################
# SYSTEMD
############################

alias sstatus='systemctl status'
alias srestart='sudo systemctl restart'

alias jdocker='journalctl -u docker -f'

############################
# DIRECTORIES
############################

alias cddocker='cd ~/docker'
alias cdconfigs='cd /mnt/extHD/raspberrypi/configs'

EOF

chown "${USERNAME}:${USERNAME}" "${ALIASES_FILE}"

############################################
# SMART MONITORING
############################################

log "Enabling SMART monitoring"

systemctl enable smartmontools || true
systemctl start smartmontools || true

############################################
# FINAL
############################################

log "Setup complete"

echo
echo "IMPORTANT:"
echo
echo "- Reboot recommended"
echo "- SSH now runs on port ${SSH_PORT}"
echo "- Log out/in for docker group changes"
echo "- Docker Compose command is: docker compose"
echo
