#!/bin/bash

_IP=$(hostname -I) || true
FILE="OK"
TMPDIR="/run/user/1000"
CMD_MOUNT="sudo modprobe g_mass_storage file=/rpius.bin stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUS\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUS\""
CMD_UNMOUNT="sudo modprobe -r g_mass_storage"
CMD_SYNC="sudo sync"
FTP_SERVER="ftp.example.com"
FTP_USER="login"
FTP_PASSWD="password"
RMTDIR="/private"
LOCDIR="/mnt/rpius"

lftp <<SCRIPT
set ftp:initial-prot ""
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate false
open ftp://$FTP_SERVER:21
user $FTP_USER $FTP_PASSWD
lcd $TMPDIR
cd $RMTDIR
get $FILE POWEROFF
mv $FILE DONE-$_IP
rm POWEROFF
exit
SCRIPT


if [[ -f "$TMPDIR/$FILE" ]]; then
[[ -d $LOCDIR ]] || mkdir $LOCDIR
rm -f -r $LOCDIR/*

lftp <<SCRIPT
set ftp:initial-prot ""
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate false
open ftp://$FTP_SERVER:21
user $FTP_USER $FTP_PASSWD
lcd $LOCDIR
cd $RMTDIR
mget *.nc
exit
SCRIPT
rm $TMPDIR/$FILE

eval $CMD_SYNC
sleep 1
eval $CMD_UNMOUNT
sleep 1
eval $CMD_SYNC
sleep 1
eval $CMD_MOUNT
sleep 1

fi


if [[ -f "$TMPDIR/POWEROFF" ]]; then
    rm $TMPDIR/POWEROFF
    sudo poweroff
fi
