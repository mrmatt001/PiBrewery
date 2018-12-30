#!/usr/bin/python

# Library for PiRelay
# Developed by: SB Components
# Author: Ankur
# Project: PiRelay
# Python: 3.4.2

import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)

class Relay:
    ''' Class to handle Relay
    Arguments:
    relay = string Relay label (i.e. "RELAY1","RELAY2","RELAY3","RELAY4")
    '''
    relaypins = {"RELAY1":15, "RELAY2":13, "RELAY3":11, "RELAY4":7}


    def __init__(self, relay):
        self.pin = self.relaypins[relay]
        self.relay = relay
        GPIO.setup(self.pin,GPIO.OUT)
        GPIO.output(self.pin, GPIO.LOW)

    def on(self):
        GPIO.output(self.pin,GPIO.HIGH)

    def off(self):
        GPIO.output(self.pin,GPIO.LOW)

r3 = Relay("RELAY3")
r3.off()
r4 = Relay("RELAY4")
r4.off()
