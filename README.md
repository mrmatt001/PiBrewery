# Project Purpose
The aim is to use two thermometers to trigger relays which will turn on/off kettle elements in different phases of a HomeBrew mash to maintain a constant temperature while the mash / boil runs. 

I've written the main script using PowerShell core as this is something I've an interest in, and can code in. The plan has been to use a Raspberry Pi, thermometers and relays connected to kettle elements.

If there is only one thermometer connected then it will only run one phase based on that thermometer. 

Technologies used: PowerShell Core 6.2 (Preview 3), Postgres, Raspbian, NpgSQL.

## Database Info

### Brews
This table is used to record the date of the brew and the timings/temperatures

### Brewtemps
This table is used to record the temperatures during the brew and which phase it is. This and the brews table can be joined on the BrewDate columns

### Control
This table, not yet implemented, will be to allow control of the brew via a web interface / PowerShell WPF GUI 


## Hardware
Raspberry Pi 3 b

2 x DS18B20 Waterproof Temperature Sensors

1 x PiRelay EXPANSION BOARD FOR RASPBERRY PI Raspberry Pi A+/B+/2B/3B/3B Loads up to 250VAC/5A,30VDC/5A by SB Components

1 x Breadboard

2 x 4.7K ohm resistors

2 x Red LEDs

2 x 220 ohm resistors

WiringPi Pin layout as per https://github.com/PowerShell/PowerShell-IoT/blob/master/docs/rpi3_pin_layout.md

Thermometer wiring as per https://www.raspberrypi-spy.co.uk/2013/03/raspberry-pi-1-wire-digital-thermometer-sensor/
 
 Ground to Ground wire
 
 3.3v to 3.3v
 
 3.3v to one end of resistor
 
 GPIO 6/26 to other end of resistor

LED wiring as per https://github.com/PowerShell/PowerShell-IoT/tree/master/Examples/Microsoft.PowerShell.IoT.LED
 
 GPIO 16 / 18 to positive side of LED (translates to WiringPi 4 / 5)
 
 Negative side of LED to 220 ohm resistor
 
 Other end of resistor to Ground

## Operating System
Raspbian Stretch Lite (2018-11-13)

# Build Steps

## Manual Commands (with keyboard / monitor / network)
    sudo rpi-update           #Need the latest firmware to support more than 1 temperature sensor
    sudo apt-get install git
    sudo Raspi-config

:set new Password for Pi (option one)

:Set to autologon console (option three)

:enable ssh (option five | P2)

## Configure Different GPIO Pins for Temperature sensors
    sudo nano /boot/config.txt

At the end add the following lines (Change 6 and 26 to the GPIO Pins you're using):

    dtoverlay=w1-gpio,gpiopin=6
    dtoverlay=w1-gpio,gpiopin=26

Press CTRL+X > Y > return

## Install PowerShell Core

There will probably be an updated version for this by the time you read it - replace the version with the file available. I opened up a browser on a PC and went to https://github.com/PowerShell/PowerShell/releases then copied and pasted the latest version (Preview 3 at time of writing). Use the latest / released version and update the wget / tar / rm lines accordingly

    sudo apt-get install libunwind8
    wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.3/powershell-6.2.0-preview.3-linux-arm32.tar.gz
    mkdir /home/pi/powershell
    tar -xvf /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz -C /home/pi/powershell
    rm /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz
    sudo git clone https://github.com/mrmatt001/PiBrewery /home/pi/PiBrewery
    sudo apt-get update
    sudo apt-get upgrade

## Set PowerShell Core to Run at Logon
    
    sudo nano /home/pi/.bashrc

At the end of the file enter the following 2 lines...

    echo Launching PowerShell
    sudo /home/pi/powershell/pwsh

Press CTRL+X > Y > return

## Setup PowerShell IoT Module
    sudo apt-get install wiringpi
    sudo /home/pi/powershell/pwsh
    Install-Module -Name Microsoft.PowerShell.IoT
    echo "export WIRINGPI_CODES=1"|sudo tee -a /etc/profile.d/WiringPiCodes.sh
   
## Restart Pi into headless mode

Run ifconfig to get the IP address and use PuTTY or other to ssh to the Pi and ditch the screen / keyboard

Reboot the Raspberry Pi

    sudo reboot

Connect using the IP address / hostname either directly or over SSH. It should then launch into a PowerShell session.

To enable the Postgres database run the following commands:

    Import-Module /home/pi/PiBrewery/PiBrewery.psm1
    Install-Postgres
    
## Launch Brewery Script    
To run the Brewery script run:

    /home/pi/PiBrewery/Brewery.ps1