#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be executed as root or using sudo"
  exit 99
fi


sudo apt update -y && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install lftp -y

installdir=/home/pi/scripts/RPiUSB

[[ -d $installdir ]] || mkdir -p $installdir

for file in $(curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/files.txt); do
   curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/$file > $installdir/$file
done

#sudo mv $installdir/wpa_supplicant.conf /etc/wpa_supplicant/
#sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
#sudo wpa_cli -i wlan0 reconfigure
#sudo wpa_cli -i wlan0 reconnect

#echo "interface wlan0" | sudo tee -a /etc/dhcpcd.conf
#echo "env ifwireless=1" | sudo tee -a /etc/dhcpcd.conf
#echo "env wpa_supplicant_driver=wext,nl80211" | sudo tee -a /etc/dhcpcd.conf

echo "dtoverlay=dwc2" | sudo tee -a /boot/firmware/config.txt
echo "dtoverlay=gpio-shutdown" | sudo tee -a /boot/firmware/config.txt
echo "dwc2" | sudo tee -a /etc/modules
echo "g_mass_storage" | sudo tee -a /etc/modules-load.d/modules.conf
echo 'options g_mass_storage \
file=/rpiusb.bin \
stall=0 \
removable=1 \
idVendor=0x0781 \
idProduct=0x5572 \
bcdDevice=0x011a \
iManufacturer="RPiUSB" \
iProduct="USB Storage" \
iSerialNumber="1234567890"' | sudo tee -a /etc/modprobe.d/g_mass_storage.conf


sudo mkdir /mnt/rpiusb
sudo dd bs=1M if=/dev/zero of=/rpiusb.bin count=4K status=progress
sudo mkdosfs /rpiusb.bin -F 32 -I
echo "/rpiusb.bin /mnt/rpiusb vfat users,umask=000 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo ln -s /mnt/rpiusb /home/pi/rpiusb
sudo chmod 777 /mnt
sudo chmod 777 /mnt/rpiusb


cat $installdir/cron |sudo tee /etc/cron.d/rpiusb
rm $installdir/cron
chmod u+x $installdir/*.sh

#echo 'sudo modprobe g_mass_storage file=/rpiusb.bin stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\"' | sudo tee -a /etc/rc.local
sudo raspi-config nonint do_ssh 0
sudo raspi-config nonint do_boot_behaviour B1
