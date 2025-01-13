#!/bin/bash

installdir=/home/pi/scripts/RPiUSB
mntdir=/mnt/rpiusb
disk_image=rpiusb.img

echo "Do you want to install the RPiUSB software?"
read -r -p "$1 [y/N] " response < /dev/tty
if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    echo "Greats ! The installation has started."
else
    echo "OK. Exiting"
    exit
fi

is_direct_execution="no"
if [[ "$0" != "bash" ]] ; then
    is_direct_execution="yes"
fi

[[ -d "$installdir" ]] || mkdir -p "$installdir"

if [[ "$is_direct_execution" == "no" ]]; then
    for file in $(curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/files.txt); do
        curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/"$file" > "$installdir"/"$file"
    done
else
    script_dir=$(dirname "$(realpath "$0")")
    for file in $(cat "$script_dir"/files.txt); do
        cp "$script_dir/$file"  "$installdir"
    done
fi

if ! grep -q '^dtoverlay=dwc2$' /boot/firmware/config.txt; then
    echo "dtoverlay=dwc2" | sudo tee -a /boot/firmware/config.txt
fi

if ! grep -q '^dtoverlay=gpio-shutdown$' /boot/firmware/config.txt; then
    echo "dtoverlay=gpio-shutdown" | sudo tee -a /boot/firmware/config.txt
fi

echo "dwc2" | sudo tee /etc/modules-load.d/rpiusb-modules.conf
echo "g_mass_storage" | sudo tee -a /etc/modules-load.d/rpiusb-modules.conf
echo "options g_mass_storage \
file=/$disk_image \
stall=0 \
removable=1 \
idVendor=0x0781 \
idProduct=0x5572 \
bcdDevice=0x011a \
iManufacturer="RPiUSB" \
iProduct="USB Storage" \
iSerialNumber='1234567890'" | sudo tee /etc/modprobe.d/g_mass_storage.conf


sudo mkdir -p "$mntdir"
echo "Starting the process of creating the file $disk_image using the dd command. Please wait..."
sudo dd bs=1M if=/dev/zero of=/$disk_image count=4K status=progress
echo "Done"
echo "Creating the file system"
sudo mkdosfs /$disk_image -F 32 -I
echo "/$disk_image $mntdir vfat users,umask=000 0 0" | sudo tee -a /etc/fstab
sudo chmod 777 /mnt
sudo chmod 777 "$mntdir"
sudo chown -R pi:pi "$mntdir"
sudo mount -a
sudo ln -s "$mntdir" "$installdir"

echo "# RPiUSB cron jobs"  |sudo tee /etc/cron.d/rpiusb
echo "* * * * * pi bash $installdir/rpiusb.sh > /dev/null 2>&1" |sudo tee -a /etc/cron.d/rpiusb

chmod u+x $installdir/*.sh

sudo raspi-config nonint do_ssh 0
sudo raspi-config nonint do_boot_behaviour B2

sudo apt update -y && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install lftp -y

echo ""
echo "-------------------------------------"
echo "Installation successfully completed !"
echo "-------------------------------------"
echo ""
echo "Don't forget to set the variables FTP_SERVER, FTP_USER, FTP_PASSWD in the config file $installdir/rpiusb.conf"
echo "Use the command nano $installdir/rpiusb.conf"
echo ""
echo "Reboot is necessary for proper RPiUSB operation."
echo "Do you want to reboot now ?"
echo ""
read -r -p "$1 [y/N] " response < /dev/tty

if [[ $response =~ ^(yes|y|Y)$ ]]; then
    sudo reboot
else
    echo ""
    echo "Run this command manually: sudo reboot"
    echo ""
    exit
fi
