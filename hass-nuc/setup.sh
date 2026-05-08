#!/usr/bin/env bash

set -Eeuo pipefail

############################################
# CONFIG
############################################

USERNAME="${SUDO_USER:-$USER}"

SSH_PORT="2222"

STATIC_IP="192.168.1.70/24"
GATEWAY="192.168.1.1"
DNS="192.168.1.229"

INTERFACE="eno1"

############################################
# HELPERS
############################################

log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo"
    exit 1
  fi
}

############################################
# START
############################################

require_root

log "Updating system"

apt update
apt upgrade -y
apt autoremove -y

############################################
# BASE PACKAGES
############################################

log "Installing base packages"

apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  ufw \
  fail2ban \
  jq \
  git \
  vim \
  htop \
  net-tools \
  tmux \
  tree \
  unzip \
  wget

############################################
# SSH HARDENING
############################################

log "Hardening SSH"

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

log "Configuring firewall"

ufw default deny incoming
ufw default allow outgoing

ufw allow ${SSH_PORT}/tcp

ufw --force enable

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
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" \
> /etc/apt/sources.list.d/docker.list

apt update

apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker "${USERNAME}"

############################################
# DOCKER DAEMON CONFIG
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
  "live-restore": true,
  "features": {
    "buildkit": true
  }
}
EOF

systemctl restart docker

############################################
# NETWORK (NETPLAN)
############################################

log "Configuring static network"

cat >/etc/netplan/01-static.yaml <<EOF
network:
  version: 2
  ethernets:
    ${INTERFACE}:
      dhcp4: false
      addresses:
        - ${STATIC_IP}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS}]
EOF

netplan try

############################################
# DISABLE SLEEP
############################################

log "Disabling sleep"

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

############################################
# ALIASES (FULL SET)
############################################

log "Configuring aliases"

ALIASES_FILE="/home/${USERNAME}/.bash_aliases"

touch "${ALIASES_FILE}"

grep -q "### SERVER ALIASES ###" "${ALIASES_FILE}" || cat >>"${ALIASES_FILE}" <<'EOF'

### SERVER ALIASES ###

############################
# BASIC
############################

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias grep='grep --color=auto'

############################
# SYSTEM
############################

alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean -y'

alias ports='ss -tulpen'
alias myip='curl -s ifconfig.me'
alias localip='ip -4 addr show scope global'

alias disks='df -h'
alias usage='du -sh * | sort -h'
alias mem='free -h'
alias cpu='htop'

alias psg='ps aux | grep -i'

############################
# SYSTEMD / LOGS
############################

alias sstatus='systemctl status'
alias srestart='sudo systemctl restart'
alias sstart='sudo systemctl start'
alias sstop='sudo systemctl stop'

alias jctl='journalctl -xe'
alias jdocker='journalctl -u docker -f'
alias jssh='journalctl -u ssh -f'

############################
# DOCKER CORE
############################

alias d='docker'
alias dc='docker compose'

alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dnet='docker network ls'
alias dvol='docker volume ls'

alias dprune='docker system prune -af --volumes'

############################
# DOCKER COMPOSE
############################

alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dcps='docker compose ps'
alias dclogs='docker compose logs -f'
alias dcpull='docker compose pull'
alias dcbuild='docker compose build'
alias dcupd='docker compose up -d --remove-orphans'

############################
# DOCKER HELPERS
############################

dbash() {
  docker exec -it "$(docker ps -qf "name=$1" | head -n1)" bash
}

dsh() {
  docker exec -it "$(docker ps -qf "name=$1" | head -n1)" sh
}

dlogsf() {
  docker logs -f "$(docker ps -qf "name=$1" | head -n1)"
}

drestart() {
  docker restart "$(docker ps -qf "name=$1" | head -n1)"
}

dinspect() {
  docker inspect "$(docker ps -qf "name=$1" | head -n1)"
}

############################
# NAVIGATION
############################

alias cddocker='cd ~/docker'
alias cd..='cd ..'
alias cd...='cd ../..'

EOF

chown "${USERNAME}:${USERNAME}" "${ALIASES_FILE}"

############################################
# FINAL
############################################

log "Setup complete"

echo
echo "IMPORTANT:"
echo "- SSH port: ${SSH_PORT}"
echo "- Reboot recommended"
echo "- Log out/in for docker group changes"
echo "- Use: docker compose (not docker-compose)"
echo
