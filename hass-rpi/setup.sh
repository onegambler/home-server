# Installing docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
echo "deb [arch=armhf] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install docker-ce -y
sudo systemctl enable docker
sudo systemctl start docker
sudo apt install -y python python-pip
pip install docker-compose

sudo groupadd docker
sudo usermod -aG docker $USER

# Setting up .bashrc
EXPORT_CONFIG="export PATH=\$HOME/.local/bin:\$PATH"
grep -q -F "$EXPORT_CONFIG" /home/pi/.bashrc || echo "$EXPORT_CONFIG"  | sudo tee --append /home/pi/.bashrc > /dev/null
source /home/pi/.bashrc

# Setting up aliases
ALIASES="alias ll='ls -al'
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
alias dps='docker ps'
alias dprune='docker system prune'"

grep -q -F "$ALIASES" /home/pi/.bash_aliases || echo "$ALIASES" > /home/pi/.bash_aliases

# Setting up /etc/dhcpcd.conf
DHCP_CONFIG="interface eth0
static ip_address=192.168.1.70/24
static routers=192.168.1.1
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

# Creating config folders
mkdir -p /home/pi/docker/hass/{media,config}
mkdir -p /home/pi/docker/{nginx,mqtt}/config
mkdir -p /home/pi/docker/{mqtt,portainer}/{data,log}
mkdir -p /home/pi/docker/pure-ftpd/{data,config}


# Installing pure-ftp
sudo apt-get install pure-ftpd -y
sudo groupadd ftpgroup
sudo useradd ftpuser -g ftpgroup -s /sbin/nologin -d /dev/null
sudo mkdir /home/pi/FTP
sudo chown -R ftpuser:ftpgroup /home/pi/FTP
#sudo pure-pw useradd upload -u ftpuser -g ftpgroup -d /home/pi/FTP -m
sudo pure-pw mkdb
sudo ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/60puredb
sudo service pure-ftpd restart