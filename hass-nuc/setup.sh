# Installing docker
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
     
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker ${USER}
su - ${USER}

# Setting up aliases
ALIASES="dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
alias dps='docker ps'
alias dprune='docker system prune'"

touch ~/.bash_aliases

grep -q -F "$ALIASES" ~/.bash_aliases || echo "$ALIASES" > ~/.bash_aliases

# Setting up /etc/network/interfaces
DHCP_CONFIG="
# The primary network interface
auto eno1
iface eno1 inet static
    address 192.168.1.70
    netmask 255.255.255.0
    network 192.168.1.0
    broadcast 192.168.1.255
    gateway 192.168.1.1
    dns-nameservers 1.1.1.1 1.0.0.1"

grep -q -x "iface eno1 inet static" /etc/network/interfaces  || echo "$DHCP_CONFIG" | sudo tee --append /etc/network/interfaces > /dev/null

# Setting up /etc/hosts
HOSTS_CONFIG="192.168.1.70    hass.home
192.168.1.254   router.home
192.168.1.229   adguard.home
192.168.1.226   lounge-camera.home
192.168.1.69    tv-switch.smart
192.168.1.65    lounge-light.home
192.168.1.71    stairs-light.home
192.168.1.128   android-tv.home
192.168.1.64    downloader.home"

grep -q -x "192.168.1.70    hass.home" /etc/hosts  || echo "$HOSTS_CONFIG" | sudo tee --append /etc/hosts > /dev/null 

# Installing pure-ftp
sudo mkdir -p /opt/conf/hass/media/
sudo apt-get install pure-ftpd -y
sudo groupadd ftpgroup
sudo useradd ftpuser -g ftpgroup -s /sbin/nologin -d /dev/null
sudo chown -R ftpuser:ftpgroup /opt/conf/hass/media/
sudo pure-pw useradd upload -u ftpuser -g ftpgroup -d /opt/conf/hass/media/ -m
sudo pure-pw mkdb
sudo ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/60puredb
sudo service pure-ftpd restart

# On Ubuntu 16.04 LTS, I successfully used the following to disable suspend:
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# And this to re-enable it:
# sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
