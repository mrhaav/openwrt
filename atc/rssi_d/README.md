# rssi daemon

Send `AT+CESQ` ever 60s to read the rsrp and send the value to `/usr/bin/modem_led`.

`modem_led` is created for ASUS 4G-AX56.\
The multi coloured LED is configured like this and controlled from the `atc` script:\
Red: booting\
Yellow: configuring\
Yellow-blinking: searcing\
White: connected to LTE\
Blue: connected to WCDMA

\
Download and install:
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/rssi_d/atc-rssi_d-2025.03.17-r1.apk
apk add --allow-untrusted atc-rssi_d-2025.03.17-r1.apk
```
