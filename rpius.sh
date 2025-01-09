#!/bin/bash

#FTP server credentials
FTP_SERVER="isp.kowalczyk.it"
FTP_USER="default1"
FTP_PASSWD="passworddefault1"
FTP_DIR="/private"

#Local direcory
LOCAL_DIR="/mnt/rpius"

#List of commands
CMD_GET="OK"
CMD_POWEROFF="POWEROFF"
CMD_MOUNT="sudo modprobe g_mass_storage file=/rpius.bin stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUS\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUS\""
CMD_UNMOUNT="sudo modprobe -r g_mass_storage"
CMD_SYNC="sudo sync"

_IP=$(hostname -I|awk '{print $1}') || true

lftp <<SCRIPT
set ftp:initial-prot ""
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate false
set net:reconnect-interval-base 2
open ftp://$FTP_SERVER:21
user $FTP_USER $FTP_PASSWD
lcd $LOCAL_DIR
cd $FTP_DIR
find "$CMD_GET" && mirror --parallel=4 --exclude "$CMD_GET" --exclude DONE-* && mv "$CMD_GET" DONE-$_IP
rm -f "$CMD_POWEROFF"
exit
SCRIPT

sleep 2

eval $CMD_SYNC
sleep 1
eval $CMD_UNMOUNT
sleep 1
eval $CMD_SYNC
sleep 1
eval $CMD_MOUNT
sleep 1

if [[ -f "$LOCAL_DIR/$CMD_POWEROFF" ]]; then
    rm "$LOCAL_DIR/$CMD_POWEROFF"
    echo sudo poweroff
fi

