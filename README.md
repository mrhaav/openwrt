# openwrt - uqmi

Customized uqmi with APN profiles.
More information and source code: https://github.com/mrhaav/openwrt-packages/blob/main/README.md

Version 2022-09-13-0.9 includes receive and send SMS function and a connectivity daemon. 
The SMS is stored in /var/sms/received and the file name is sent to script /usr/bin/uqmi_sms.sh. (uqmi_sms.sh is not included in the ipk file)
The daemon will send the RSSI value to script /usr/bin/uqmi_led.sh to trigger signal strenght LEDs. (uqmi_led.sh is not included in the ipk file) 




Downloading file to your router:

Go to the file, right click on Download button and select Copy link addess.\
Then paste the link in your router after wget.

`wget https://github.com/mrhaav/openwrt/raw/master/19.07.8/uqmi_2021-12-22-0.3_mipsel_24kc.ipk`
