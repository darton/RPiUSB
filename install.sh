#!/bin/bash

installdir=/home/pi/scripts/RPiUS

[[ -d $installdir ]] || mkdir -p $installdir

for file in $(curl -sS https://raw.githubusercontent.com/darton/RPiUS/master/files.txt); do
   curl -sS https://raw.githubusercontent.com/darton/RPiUS/master/$file > $installdir/$file
done

sudo mv $installdir/wpa_supplicant.conf /etc/wpa_supplicant/
sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
sudo wpa_cli -i wlan0 reconfigure
sudo wpa_cli -i wlan0 reconnect

sudo echo "interface wlan0" >> /etc/dhcpcd.conf
sudo echo "env ifwireless=1" >> /etc/dhcpcd.conf
sudo echo "env wpa_supplicant_driver=wext,nl80211" >> /etc/dhcpcd.conf

sudo echo "dtoverlay=dwc2" >> /boot/config.txt
sudo echo "dtoverlay=gpio-shutdown,gpio_pin=4" >> /boot/config.txt
sudo echo "dwc2" >> /etc/modules

sudo mkdir /mnt/rpiusb
sudo dd bs=1M if=/dev/zero of=/rpius.bin count=2048
sudo mkdosfs /rpius.bin -F 32 -I
sudo echo "/rpius.bin /mnt/rpius vfat users,umask=000 0 0" >> /etc/fstab
sudo mount -a
sudo ln -s /mnt/rpius /home/pi/rpius
sudo chmod 777 /mnt
sudo chmod 777 /mnt/rpius

sudo apt-get remove --purge libreoffice* -y
sudo apt-get purge wolfram-engine -y
sudo apt-get clean
sudo apt-get autoremove -y

cat $installdir/cron |sudo tee /etc/cron.d/rpius
rm $installdir/cron

echo 'sudo modprobe g_mass_storage file=/rpius.bin stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUS\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUS\"' | sudo tee -a /etc/rc.local

