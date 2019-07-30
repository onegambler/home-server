curl -O https://static.adguard.com/adguardhome/release/AdGuardHome_linux_arm.tar.gz
tar -xzvf AdGuardHome_linux_arm.tar.gz
sudo ./AdGuardHome
sudo ./AdGuardHome -s install

# Setting up /etc/hosts
HOSTS_CONFIG="127.0.1.1       raspberrypi
192.168.1.70    hass.home
192.168.1.254   router.home
192.168.1.229   adguard.home
192.168.1.226   lounge-camera.home
192.168.1.69    tv-switch.smart
192.168.1.65    lounge-light.home
192.168.1.71    stairs-light.home
192.168.1.128   android-tv.home
192.168.1.64    downloader.home"

grep -q -x "127.0.1.1       raspberrypi" /etc/hosts  || echo "$HOSTS_CONFIG" | sudo tee --append /etc/hosts > /dev/null 

sudo apt-get install dnsmasq

DNSMASQ_CONFIG="listen-address=127.0.0.1
port=5553"

touch /etc/dnsmasq.conf

grep -q -x "$DNSMASQ_CONFIG" /etc/dnsmasq.conf  || echo "$DNSMASQ_CONFIG" | sudo tee --append /etc/dnsmasq.conf > /dev/null 
sudo service dnsmasq restart
