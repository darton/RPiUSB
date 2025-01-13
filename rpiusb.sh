#!/bin/bash

#  Author : Dariusz Kowalczyk

DISK_IMAGE=rpiusb.bin
LOCAL_DIR="/mnt/rpiusb"

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=`dirname "$(realpath "$0")"`
CONFIG_FILE_PATH="$SCRIPT_DIR/rpiusb.conf"
TEMP_LOCAL_DIR=$(mktemp -d /dev/shm/$SCRIPT_NAME.XXXX || { echo "Unable to create TEMP_LOCAL_DIR"; exit 1; })

if [[ -f "$CONFIG_FILE_PATH" ]]; then
    source "$CONFIG_FILE_PATH"
    # Function to validate IP or FQDN
    validate_server_name() {
        local server_name="$1"
        if [[ $server_name =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
           [[ $server_name =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?$ ]]; then
            return 0
        else
            return 1
        fi
    }
    # Validation of variables
    if [[ -z "$FTP_SERVER" || -z "$FTP_USER" || -z "$FTP_PASSWD" || -z "$FTP_DIR" ]]; then
        echo "One or more variables were not correctly loaded from the configuration file."
        exit 1
    fi
    # Validation of server name
    if ! validate_server_name "$FTP_SERVER"; then
        echo "The FTP server name $FTP_SERVER is not a valid IP address or FQDN."
        exit 1
    fi
else
    echo "The configuration file $CONFIG_FILE does not exist."
    exit 1
fi

#List of commands
CMD_GET="OK"
CMD_POWEROFF="POWEROFF"
CMD_MOUNT="sudo modprobe g_mass_storage file=/$DISK_IMAGE stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\""
CMD_UNMOUNT="sudo modprobe -r g_mass_storage"
CMD_SYNC="sudo sync"

IP=$(hostname -I|awk '{print $1}') || true

lftp <<SCRIPT
set ftp:initial-prot ""
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate false
set net:reconnect-interval-base 2
open ftp://$FTP_SERVER:21
user $FTP_USER $FTP_PASSWD
lcd $TEMP_LOCAL_DIR
cd $FTP_DIR
cls -1 "$CMD_POWEROFF" && !touch "$CMD_POWEROFF"
cls -1 "$CMD_GET" && !touch "$CMD_GET"
exit
SCRIPT

ftp_to_usb(){
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
rm -f "$CMD_POWEROFF"
mirror --delete --parallel=4 --exclude OK --exclude DONE-* && mv "$CMD_GET" DONE-"$IP"
exit
SCRIPT
}

if [[ -f "$TEMP_LOCAL_DIR/$CMD_GET" ]] && [[ -f "$TEMP_LOCAL_DIR/$CMD_POWEROFF" ]]; then
    eval $CMD_SYNC
    sleep 2
    eval $CMD_UNMOUNT
    sleep 1
    rm "$TEMP_LOCAL_DIR/$CMD_POWEROFF"
    rm "$TEMP_LOCAL_DIR/$CMD_GET"
    eval $CMD_SYNC
    sleep 1
    sudo poweroff
fi

if [[ -f "$TEMP_LOCAL_DIR/$CMD_GET" ]]; then
    eval $CMD_SYNC
    sleep 2
    eval $CMD_UNMOUNT
    sleep 1
    sudo mount -o remount,rw $LOCAL_DIR
    ftp_to_usb
    rm "$TEMP_LOCAL_DIR/$CMD_GET"
    eval $CMD_SYNC
    sleep 2
    eval $CMD_MOUNT
    sleep 1
fi
