# RPiUSB is Raspberry Pi Zero W based a USB drive synchronized with an FTP Server account.

Ideal for old CNC machines and other industrial devices or all those that can only retrieve data from memory connected via USB and do not support Ethernet or Internet like old TV, audio or video player.

![RPiUSB](https://github.com/darton/RPiUSB/blob/master/IMG_1295.jpeg)

## Installing operating system images 

To writing an image to the SD card, use [Imager](https://www.raspberrypi.org/downloads/)

In Imager configure [advanced options](https://www.raspberrypi.com/documentation/computers/getting-started.html#installing-the-operating-system) like WiFi, ssh, user and password before installation. 


## Installing RPiUSB

Run the following command will download and run the installation script automatically,
```
curl -sS https://raw.githubusercontent.com/darton/RPiUSB/master/install.sh | bash
```
or clone repo from github and install from local drive

```
git clone https://github.com/darton/rpiusb.git

cd rpiusb

bash install.sh
```
Edit the rpiusb.conf config file located at /home/pi/scripts/RPiUSB/rpiusb.conf

```
nano /home/pi/scripts/RPiUSB/rpiusb.conf

#FTP server credentials
FTP_SERVER="ftp.example.com"
FTP_USER="ftpuser"
FTP_PASSWD="ftpuserpassword"
FTP_DIR="/private"

```

### How to force synchronization of files with the FTP server.

To make RPiUSB download files from the FTP server create a empty file OK in the /privater folder of the FTP server.
Within a minute, RPiUSB will begin mirroring the remote /private directory from the FTP server to the local disk.
Then it will change the file name OK to DONE-rpi-ip-address.

If you want to remotely turn off the Raspberry Pi, upload two files named POWEROFF and next OK to the /private directory on the FTP server."

If you want to turn RPiUSB back on, unplug and reconnect it to the USB port of the device or attach a momentary switch
to the GPIO3 and GROUND [pins](https://pinout.xyz/pinout/pin5_gpio3/). This switch can be used to turn the Raspberry Pi on and off.

This project has been used in production for several years in a large factory to deliver batch files to a CNC machine.
