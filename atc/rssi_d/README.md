# rssi daemon

Send `AT+CESQ` ever 60s to read the rsrp and send the value to `/usr/bin/modem_led`.

`modem_led` is created for ASUS 4G-AX56.\
The multi coloured LED is configured like this and controlled from the `atc` script:\
Red: booting\
Yellow: configuring\
Yellow-blinking: searcing\
White: connected to LTE\
Blue: connected to WCDMA
