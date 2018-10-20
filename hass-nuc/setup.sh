# Installing docker
sudo apt-get update
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
     
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"sudo apt-get update

sudo apt-get install docker-ce -y
sudo systemctl enable docker
sudo systemctl start docker
sudo apt install -y python python-pip
pip install docker-compose

sudo groupadd docker
sudo usermod -aG docker $USER

# Setting up .bashrc
EXPORT_CONFIG="export PATH=\$HOME/.local/bin:\$PATH"
grep -q -F "$EXPORT_CONFIG" ~/.bashrc || echo "$EXPORT_CONFIG"  | sudo tee --append ~/.bashrc > /dev/null
source ~/.bashrc

# Setting up aliases
ALIASES="alias ll='ls -al'
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
alias dps='docker ps'
alias dprune='docker system prune'"

grep -q -F "$ALIASES" ~/.bash_aliases || echo "$ALIASES" > ~/.bash_aliases

# Setting up /etc/dhcpcd.conf
DHCP_CONFIG="interface eth0
static ip_address=192.168.1.70/24
static routers=192.168.1.254
static domain_name_servers=1.1.1.1 1.0.0.1"

grep -q -x "interface eth0" /etc/dhcpcd.conf  || echo "$DHCP_CONFIG" | sudo tee --append /etc/dhcpcd.conf > /dev/null

# Setting up /etc/hosts
HOSTS_CONFIG="192.168.1.70    hass.home
192.168.1.254   bthomehub.home
192.168.1.229   pi.hole
192.168.1.226   lounge-camera.home
192.168.1.69    tv-switch.smart
192.168.1.65    lounge-light.home
192.168.1.71    stairs-light.home
192.168.1.128   android-tv.home
192.168.1.64    downloader.home"

grep -q -x "192.168.1.70    hass.home" /etc/hosts  || echo "$HOSTS_CONFIG" | sudo tee --append /etc/hosts > /dev/null 

# Installing pure-ftp
sudo apt-get install pure-ftpd -y
sudo groupadd ftpgroup
sudo useradd ftpuser -g ftpgroup -s /sbin/nologin -d /dev/null
sudo mkdir ~/FTP
sudo chown -R ftpuser:ftpgroup ~/FTP
#sudo pure-pw useradd upload -u ftpuser -g ftpgroup -d ~/FTP -m
sudo pure-pw mkdb
sudo ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/60puredb
sudo service pure-ftpd restart