# How make a Pi Zero W as a USB storage flash drive

## Installing

### Installing operating system images 

Download the image [Raspberry Pi OS](https://downloads.raspberrypi.org/raspios_armhf_latest)

To writing an image to the SD card, use [Etcher](https://etcher.io/) an image writing tool or use [Imager](https://www.raspberrypi.org/downloads/)

If you're not using Etcher, you'll need to unzip .zip downloads to get the image file (.img) to write to your SD card.

### Run installation script

Running the following command will download and run the script.
```
sudo curl -sS https://raw.githubusercontent.com/darton/RPiUS/master/install.sh | bash
```
