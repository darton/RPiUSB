#!/bin/bash

#  Author : Dariusz Kowalczyk

DISK_IMAGE=rpiusb.bin
LOCAL_DIR="/mnt/rpiusb"

G_MASS_STORAGE_MOUNT_READ_ONLY=true #true or false

SCRIPT_DIR=`dirname "$(realpath "$0")"`
SCRIPT_NAME=$(basename $0)
CONFIG_FILE_PATH="$SCRIPT_DIR/rpiusb.conf"
TEMP_LOCAL_DIR=$(mktemp -d /dev/shm/$SCRIPT_NAME.XXXX || { echo "Unable to create TEMP_LOCAL_DIR"; exit 1; })
PID_FILE_NAME="$(basename -s .sh "$0").pid"
LOCK_FILE_PATH="$SCRIPT_DIR/$PID_FILE_NAME"
LOG_DIR="$SCRIPT_DIR"
LOG_FILE_NAME="$(basename -s .sh "$0").log"
LOG_FILE_PATH="$LOG_DIR/$LOG_FILE_NAME"

DEBUG=true # true or false

Cleaning(){
rm -f "$LOCK_FILE_PATH"
rm -rf "$TEMP_LOCAL_DIR"
exit $?
}

Log(){
[[ -f "$LOG_FILE_PATH" ]] || touch $LOG_FILE_PATH
local message="${@:2}"
local flag="$1"
local logdate=$(date +"%F %T.%3N%:z")
MESSAGE_FORMAT="${logdate} SCRIPT_NAME:${SCRIPT_NAME}; LEVEL:${flag~}; MESSAGE:${message};"
if [[ "$DEBUG" == "true" ]]; then
    echo "${MESSAGE_FORMAT}" | tee -a "$LOG_FILE_PATH"
else
    if [[ "flag" == "error" ]]; then
        echo "${MESSAGE_FORMAT}"
    fi
fi
}

MakeLockFile(){
if [ -f $LOCK_FILE_PATH  ] && kill -0 $(cat "$LOCK_FILE_PATH") 2> /dev/null; then
    Log "error" "Script already running"
    exit 1
fi
echo $$ > $LOCK_FILE_PATH || { Log "error" "Can not create lock file"; exit 1; }
}

DestroyLockFile(){
rm -f "$LOCK_FILE_PATH" || { Log "error" "Can not remove lock file"; exit 1; }
}



#Trap to erasing file when receiving signals: IMT, TERM, EXIT
trap Cleaning INT TERM EXIT

MakeLockFile

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
        Log "error" "One or more variables were not correctly loaded from the configuration file."
        exit 1
    fi
    # Validation of server name
    if ! validate_server_name "$FTP_SERVER"; then
        Log "error" "The FTP server name $FTP_SERVER is not a valid IP address or FQDN."
        exit 1
    fi
else
    Log "error" "The configuration file $CONFIG_FILE does not exist."
    exit 1
fi

if [[ "$G_MASS_STORAGE_MOUNT_READ_ONLY" == "true" ]]; then
    RO=1
else
    RO=0
fi

#List of commands
CMD_GET="OK"
CMD_POWEROFF="POWEROFF"
CMD_MOUNT="sudo modprobe g_mass_storage \
file=/$DISK_IMAGE \
stall=0 \
removable=1 \
ro=$RO \
idVendor=0x0781 \
idProduct=0x5572 \
bcdDevice=0x011a \
iManufacturer=\"RPiUSB\" \
iProduct=\"USB Storage\" \
iSerialNumber=\"1234567890\""
CMD_UNMOUNT="sudo modprobe -r g_mass_storage"
CMD_SYNC="sudo sync"

IP=$(hostname -I|awk '{print $1}') || true

get_command_from_ftp(){
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
}

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

get_command_from_ftp 2&>1 && Log "info" "There are commands to execute." || Log "info" "Nothing to do."

if [[ -f "$TEMP_LOCAL_DIR/$CMD_GET" ]] && [[ -f "$TEMP_LOCAL_DIR/$CMD_POWEROFF" ]]; then
    eval $CMD_SYNC
    eval $CMD_UNMOUNT
    rm "$TEMP_LOCAL_DIR/$CMD_POWEROFF"
    rm "$TEMP_LOCAL_DIR/$CMD_GET"
    eval $CMD_SYNC
    sleep 5
    sudo poweroff
fi

if [[ -f "$TEMP_LOCAL_DIR/$CMD_GET" ]]; then
    eval $CMD_SYNC
    eval $CMD_UNMOUNT
    sudo mount -o remount,rw $LOCAL_DIR
    ftp_to_usb
    rm "$TEMP_LOCAL_DIR/$CMD_GET"
    eval $CMD_SYNC
    eval $CMD_MOUNT
fi

DestroyLockFile
