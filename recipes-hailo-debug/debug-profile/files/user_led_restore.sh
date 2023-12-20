#!/bin/bash

#Stop blinking
rm /tmp/user_led_flag

#Keep LED off
gpioset gpiochip1 5=0

