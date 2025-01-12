#!/bin/bash

installdir=/home/pi/scripts/RPiUSB
mntdir=/mnt/rpiusb
is_direct_execution="no"

echo "Do you want to install the RPiUSB software?"
read -r -p "$1 [y/N] " response < /dev/tty
if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    echo "Greats ! The installation has started."
else
    echo "OK. Exiting"
    exit
fi


if [[ "$0" != "bash" ]] ; then
    is_direct_execution="yes"
fi

[[ -d "$installdir" ]] || mkdir -p "$installdir"

if [[ "$is_direct_execution" == "no" ]]; then
    for file in $(curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/files.txt); do
        echo curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/"$file" > "$installdir"/"$file"
    done
else
    script_dir=$(dirname "$(realpath "$0")")
    for file in $(cat "$script_dir"/files.txt); do
        cp "$script_dir/$file"  "$installdir"
    done
fi

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
iSerialNumber="1234567890"' | sudo tee /etc/modprobe.d/g_mass_storage.conf


sudo mkdir -p "$mntdir"
echo "Starting the process of creating the file rpiusb.bin using the dd command. Please wait..."
sudo dd bs=1M if=/dev/zero of=/rpiusb.bin count=100 status=progress
echo "Creating the file system"
sudo mkdosfs /rpiusb.bin -F 32 -I
echo "/rpiusb.bin $mntdir vfat users,umask=000 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo ln -s "$mntdir" "$installdir"
sudo chmod 777 /mnt
sudo chmod 777 "$mntdir"

echo "# RPiUSB cron jobs"  |sudo tee /etc/cron.d/rpiusb
echo "* 6-22 * * 1-6 pi bash $installdir/rpiusb.sh > /dev/null 2>&1" |sudo tee -a /etc/cron.d/rpiusb

chmod u+x $installdir/*.sh

sudo raspi-config nonint do_ssh 0
sudo raspi-config nonint do_boot_behaviour B1

sudo apt update -y && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install lftp -y

echo ""
echo "-------------------------------------"
echo "Installation successfully completed !"
echo "-------------------------------------"
echo "Don't forget to set the variables FTP_SERVER, FTP_USER, FTP_PASSWD in the file $installdir/rpiusb.sh."
echo ""
echo "Do you want to set the variables now ?"
echo ""
read -r -p "$1 [y/N] " response < /dev/tty

if [[ $response =~ ^(yes|y|Y)$ ]]; then
    sh -c "nano $installdir/.config"
fi

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
