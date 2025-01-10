# Raspberry Pi Zero W as a USB storage flash drive syncronized with ftp account 

## Installing

### Installing operating system images 

Download the image [Raspberry Pi OS](https://downloads.raspberrypi.org/raspios_armhf_latest)

To writing an image to the SD card, use [Imager](https://www.raspberrypi.org/downloads/)

In Imager use Shift + Ctrl + X to configure advanced options like WiFi, ssh, user and password before installation. 

### Run installation script

Running the following command will download and run the script.
```
curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/install.sh | bash
```

### How to force synchronization of files with the FTP server.

To make RPiUSB download files from the FTP server create a empty file in the /privater folder of the FTP server called OK.

Within a minute, RPiUSB will begin mirroring the remote /private directory from the FTP server to the local disk.

Then it will change the file name OK to DONE-ip-address.

