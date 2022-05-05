# uqmi

Downloading file to your router:

Go to the file, right click on Download button and select Copy link addess.\
Then paste the link in your router after wget. Install with opkg.

```
wget https://github.com/mrhaav/openwrt/raw/master/21.02.1/uqmi_2022-04-22-0.5_mips_24kc.ipk
opkg install uqmi_2022-04-22-0.5_mips_24kc.ipk
```

\
\
uqmi version 2022-04-22-0.5 includes a daemon that will check the connection every 30sec.
If the connection is released from the network, the daemon will re-connect the interface.

This daemon will also send the rssi value to /usr/bin/uqmi_led.sh for trigger signal strength LEDs.
When the daemon is stoped it will send rssi value = -200 to turn off all LEDs.

An SMS receiver will store received SMS in /var/sms folder. The daemon will send the file name to /usr/bin/uqmi_sms.sh.
The first row in the SMS file is the senders phone number and the following rows are the text message.

\
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

\
uqmi_sms.sh example
```
#!/bin/sh

receivedSMS=$1
Anumber=$(sed -n '1p' $receivedSMS)
if [ $Anumber = '+46123456' ]
then
	first_row=$(sed -n '2p' $receivedSMS)
	second_row=$(sed -n '3p' $receivedSMS)
#	Execute your commands
	rm $receivedSMS
else
	logger -t SMS Unauthorized Anumber
fi

