# Installing docker
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade

sudo apt-get install -y curl openssh-server git

sudo sed -i 's/Port 22/Port 2222/g' /etc/ssh/sshd_config
     
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update
sudo apt-get install docker-ce -y

sudo usermod -aG docker ${USER}
su - ${USER}

sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

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
    address 192.168.1.64
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

# On Ubuntu 16.04 LTS, I successfully used the following to disable suspend:
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# And this to re-enable it:
# sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Automount harddrive
echo "********************************  Setting hardrive automount  ********************************"
sudo mkdir -p /mnt/extHD
sudo mount -t ext4 UUID=3b3e573f-f3b5-410c-841a-0ee9949925f7 /mnt/extHD
export FSTAB_CONFIG="UUID=3b3e573f-f3b5-410c-841a-0ee9949925f7        /mnt/extHD      ext4    defaults          0       0"
grep -q -F "$FSTAB_CONFIG" /etc/fstab || echo "$FSTAB_CONFIG" | sudo tee --append /etc/fstab > /dev/null

sudo mkdir -p /mnt/extHD/raspberrypi/configs/{muximux,portainer,radarr,sonarr,jackett,mldonkey}
sudo chown -R roberto:roberto /mnt/extHD/raspberrypi

### Installing nfs
sudo apt-get install nfs-kernel-server -y
sudo service nfs-server stop

EXPORT_CONFIG="/mnt/extHD           192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async,all_squash)"
grep -q -F "$EXPORT_CONFIG" /etc/exports || echo "$EXPORT_CONFIG" | sudo tee --append /etc/exports > /dev/null
sudo service nfs-server start
