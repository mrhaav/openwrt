# openwrt - uqmi

Customized uqmi with APN profiles.
More information and source code: https://github.com/mrhaav/openwrt-packages/blob/main/README.md

Latest version: 2022-11-29-0.10

From version 2022-09-13-0.9, an SMS receive/send function and a connectivity daemon are included.\
The SMS is stored in /var/sms/received and the file name is sent to script /usr/bin/uqmi_sms.sh (uqmi_sms.sh is not included in the ipk file).
The daemon will run every 30sec and check the network connectivity and send the RSSI value to script /usr/bin/uqmi_led.sh to trigger signal strenght LEDs (uqmi_led.sh is not included in the ipk file).\
Don´t run other uqmi scripts in parallell. The modems are not able to handle multiple uqmi request at the same time.\
If you need some special uqmi command to be exequted every 30s, add them to the daemon, `/usr/bin/uqmi_d.sh`.\
\
Switches:\
`uci set network.<your interface>.ipv6profile=<ipv6 profile number>` If you need an other APN for IPv6. Configure you IPv4 APN with LuCI and add the IPv6 APN with uqmi command `--create-profile` or `--modify-profile`\
\
`uci set network.<your interface>.abort_search=false` If you have you modem in poor radio coverage, you can let the modem search for network for ever (default, it will search for 35 sec).\
\
`uci set network.<your interface>.daemon=false` If you would like to turn off the daemon.\
\
Don´t foget to run `uci commit network`.
\
\
Downloading file to your router:

Choose OpenWrt version and target.\
Go to the file, right click on Download button and select Copy link addess.\
Then paste the link in your router after wget.
```
wget https://github.com/mrhaav/openwrt/raw/master/22.03.2/uqmi_2022-09-13-0.9_mipsel_24kc.ipk
opkg install uqmi_2022-09-13-0.9_mipsel_24kc.ipk
```


\
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
\
uqmi_sms.sh example
```
#!/bin/sh

receivedSMS=$1
Bnumber=$(sed -n '1p' $receivedSMS)
if [ $Bnumber = '+46123456' ]
then
	first_row=$(sed -n '2p' $receivedSMS)
	second_row=$(sed -n '3p' $receivedSMS)
#	Execute your commands
	rm $receivedSMS
else
	logger -t SMS Unauthorized Anumber
	rm $receivedSMS
fi
```
