This is how I've built things:
==============================
Hardware
========
Raspberry Pi 3 b
2 x DS18B20 Waterproof Temperature Sensors
1 x PiRelay EXPANSION BOARD FOR RASPBERRY PI Raspberry Pi A+/B+/2B/3B/3B Loads up to 250VAC/5A,30VDC/5A by SB Components

Operating System
================
Raspbian Stretch Lite (2018-11-13)

Manual Commands (with keyboard / monitor / network)
===================================================
sudo rpi-update           #Need the latest firmware to support more than 1 temperature sensor
sudo apt-get install git

sudo Raspi-config
:set new Password for Pi (option one)
:Set to autologon console (option three)
:enable ssh (option five | P2)

Configue Different GPIO Pins for Temperature sensors
====================================================
sudo nano /boot/config.txt
At the end add the following lines (Change 6 and 26 to the GPIO Pins you're using):
   dtoverlay=w1-gpio,gpiopin=6
   dtoverlay=w1-gpio,gpiopin=26
Press CTRL+X > Y > return

Install PowerShell
==================

There will be a later version - replace the version with the file available. I opened up a browser on a PC and went to https://github.com/PowerShell/PowerShell/releases then copied and pasted the latest version (Preview 3 at time of writing). Use the latest / released version and update the wget / tar / rm lines accordingly

sudo apt-get install libunwind8
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.3/powershell-6.2.0-preview.3-linux-arm32.tar.gz

mkdir /home/pi/powershell
tar -xvf /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz -C /home/pi/powershell

rm /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz
sudo git clone https://github.com/mrmatt001/PiBrewery /home/pi/PiBrewery

sudo apt-get update
sudo apt-get upgrade

sudo nano /home/pi/.bashrc

At the end of the file enter the following 2 lines...
    echo Launching PowerShell
    sudo /home/pi/powershell/pwsh
Press CTRL+X > Y > return

Run ifconfig to get the IP address and use PuTTY or other to ssh to the Pi and ditch the screen / keyboard

sudo reboot
