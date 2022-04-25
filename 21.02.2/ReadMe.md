# uqmi

Downloading file to your router:

Go to the file, right click on Download button and select Copy link addess.\
Then paste the link in your router after wget. Install with opkg.

```
wget https://github.com/mrhaav/openwrt/raw/master/21.02.2/uqmi_2022-03-15-0.4_mipsel_24kc.ipk
opkg install uqmi_2022-03-15-0.4_mipsel_24kc.ipk
```

\
\
uqmi version 2022-04-22-0.4 include a daemon how will check connection every 30sec.
If the connection is released from the network, the daemon will re-connect the interface.
This daemon will also send the rssi value to uqmi_led.sh for trigger signal strength LEDs.

uqmi_led.sh example for MR200v4
```
#!/bin/sh

rssi=$1

LED1=$(readlink -f /sys/class/leds/mr200v4:white:signal1)
LED2=$(readlink -f /sys/class/leds/mr200v4:white:signal2)
LED3=$(readlink -f /sys/class/leds/mr200v4:white:signal3)

if [ "${rssi}" -eq -200 ]
then
	echo none > $LED1/trigger
	echo none > $LED2/trigger
	echo none > $LED3/trigger
elif [ "${rssi}" -le -90 ]
then
	echo default-on > $LED1/trigger
	echo none > $LED2/trigger
	echo none > $LED3/trigger
elif [ "${rssi}" -le -70 ]
then
	echo default-on > $LED1/trigger
	echo default-on > $LED2/trigger
	echo none > $LED3/trigger
else
	echo default-on > $LED1/trigger
	echo default-on > $LED2/trigger
	echo default-on > $LED3/trigger
fi
```
