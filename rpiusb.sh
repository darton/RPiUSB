#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_FILE_PATH="$SCRIPT_DIR/.config"

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
        echo "Jedna lub więcej zmiennych nie zostały poprawnie załadowane z pliku konfiguracyjnego."
        exit 1
    fi

    # Validation of server name
    if ! validate_server_name "$FTP_SERVER"; then
        echo "Nazwa serwera FTP $FTP_SERVER nie jest poprawnym adresem IP ani nazwą FQDN."
        exit 1
    fi
else
    echo "Plik konfiguracyjny $CONFIG_FILE nie istnieje."
    exit 1
fi

#Local direcory
LOCAL_DIR="/mnt/rpiusb"

#List of commands
CMD_GET="OK"
CMD_POWEROFF="POWEROFF"
CMD_MOUNT="sudo modprobe g_mass_storage file=/rpiusb.bin stall=0 removable=1 idVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\" iProduct=\"USB Storage\" iSerialNumber=\"1234567890\"5572 bcdDevice=0x011a iManufacturer=\"RPiUSB\""
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
cls -1 "$CMD_GET" && mirror --delete --parallel=4 --exclude DONE-* && mv "$CMD_GET" DONE-$_IP
rm -f "$CMD_POWEROFF"
exit
SCRIPT

if [[ -f "$LOCAL_DIR/$CMD_GET" ]]; then
    rm "$LOCAL_DIR/$CMD_GET"
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
        eval $CMD_SYNC
        sleep 1
        eval $CMD_UNMOUNT
        sleep 1
        eval $CMD_SYNC
        sleep 1
        sudo poweroff
    fi
fi
