#!/bin/sh
# LED script for TP-Link MR6400v5

rssi=$1

LED1=$(readlink -f /sys/class/leds/white:signal1)
LED2=$(readlink -f /sys/class/leds/white:signal2)
LED3=$(readlink -f /sys/class/leds/white:signal3)

if [ "${rssi}" -eq -200 ]
then
	echo 0 > $LED1/brightness
	echo 0 > $LED2/brightness
	echo 0 > $LED3/brightness
elif [ "${rssi}" -le -90 ]
then
	echo 255 > $LED1/brightness
	echo 0 > $LED2/brightness
	echo 0 > $LED3/brightness
elif [ "${rssi}" -le -70 ]
then
	echo 255 > $LED1/brightness
	echo 255 > $LED2/brightness
	echo 0 > $LED3/brightness
else
	echo 255 > $LED1/brightness
	echo 255 > $LED2/brightness
	echo 255 > $LED3/brightness
fi
