Add bold parts:

file: target/linux/ramips/base-files/etc/board.d/01_leds

mr200)\
&emsp;ucidef_set_led_netdev "lan" "lan" "$boardname:white:lan" "eth0.1"\
&emsp;ucidef_set_led_netdev "wan" "wan" "$boardname:white:wan" "usb0"\
&emsp;set_wifi_led "$boardname:white:wlan"\
        ;;
```
mr200v4)
	ucidef_set_led_netdev "lan" "lan" "$boardname:white:lan" "eth0.1"
	ucidef_set_led_netdev "wan" "wan" "$boardname:white:wan" "eth0.2"
	set_wifi_led "$boardname:white:wlan"
;;
```


file: target/linux/ramips/base-files/etc/board.d/02_network

tplink,c20-v1)
&emsp;ucidef_add_switch "switch0" \
&emsp;&emsp;"1:lan:3" "2:lan:4" "3:lan:1" "4:lan:2" "0:wan" "6@eth0"
&emsp;;;
```
        mr200v4)
                ucidef_add_switch "switch0" \
                        "1:lan" "2:lan" "3:lan" "4:wan" "6t@eth0"
                ;;
```
