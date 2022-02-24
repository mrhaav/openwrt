Add bold parts:

target/linux/ramips/base-files/etc/board.d/01_leds

mr200)
        ucidef_set_led_netdev "lan" "lan" "$boardname:white:lan" "eth0.1"
        ucidef_set_led_netdev "wan" "wan" "$boardname:white:wan" "usb0"
        set_wifi_led "$boardname:white:wlan"
        ;;
**mr200v4)
        ucidef_set_led_netdev "lan" "lan" "$boardname:white:lan" "eth0.1"
        ucidef_set_led_netdev "wan" "wan" "$boardname:white:wan" "eth0.2"
        set_wifi_led "$boardname:white:wlan"
        ;;**
