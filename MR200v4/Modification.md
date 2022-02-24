Add mr200v4 parts:

**file: target/linux/ramips/base-files/etc/board.d/01_leds**

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
\
\
**file: target/linux/ramips/base-files/etc/board.d/02_network**

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
\
\
**file: target/linux/ramips/base-files/lib/ramips.sh**

&emsp;*"MR200")  
&emsp;&emsp;name="mr200"  
&emsp;&emsp;;;  
```
        *"MR200 V4")
                name="mr200v4"
                ;;
```
\
\
**file: target/linux/ramips/image/mt76x8.mk**

define Device/tplink_c50-v4  
&emsp;$(Device/tplink)  
&emsp;DTS := ArcherC50V4  
&emsp;IMAGE_SIZE := 7616k  
&emsp;DEVICE_TITLE := TP-Link ArcherC50 v4  
&emsp;TPLINK_FLASHLAYOUT := 8MSUmtk  
&emsp;TPLINK_HWID := 0x001D589B  
&emsp;TPLINK_HWREV := 0x93  
&emsp;TPLINK_HWREVADD := 0x2  
&emsp;TPLINK_HVERSION := 3  
&emsp;DEVICE_PACKAGES := kmod-mt76x2  
&emsp;IMAGES := sysupgrade.bin  
endef  
TARGET_DEVICES += tplink_c50-v4  
```
define Device/tplink_mr200-v4
  $(Device/tplink)
  DTS := ArcherMR200v4
  SUPPORTED_DEVICES := mr200v4
  IMAGE_SIZE := 7872k
  DEVICE_TITLE := TP-Link ArcherMR200 v4
  TPLINK_FLASHLAYOUT := 8MLmtk
  TPLINK_HWID := 0x001D589B
  TPLINK_HWREV := 0x93
  TPLINK_HWREVADD := 0x13
  TPLINK_HVERSION := 3
  DEVICE_PACKAGES := kmod-mt76x0e kmod-usb-ohci kmod-usb2 kmod-usb-net kmod-usb-net-qmi-wwan uqmi
endef
TARGET_DEVICES += tplink_mr200-v4
```
