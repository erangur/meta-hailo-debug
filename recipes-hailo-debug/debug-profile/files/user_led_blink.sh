#!/bin/bash

gpio_chip="gpiochip1"
gpio_line=5

# Path for the flag file
flag_file="/tmp/user_led_flag"

# Creating a flag file to control the loop
touch "$flag_file"

# Infinite loop to toggle the user LED
while [ -f "$flag_file" ]; do
    gpioset $gpio_chip $gpio_line=1 # LED off
    # Ping the address 10.0.0.2 with a timeout of 1 second
    if ping -c 1 -W 1 10.0.0.2 &> /dev/null; then
        # If ping is successful, blink fast
        usleep 90000
	gpioset $gpio_chip $gpio_line=0
	usleep 90000
    else
        # If ping fails, blink at the regular rate
        usleep 350000 
	gpioset $gpio_chip $gpio_line=0
	usleep 350000
    fi
done > /dev/null 2>&1 &

