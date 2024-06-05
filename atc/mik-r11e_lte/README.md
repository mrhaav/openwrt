# MikroTik R11e-LTE modem

Download and install with:
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/mik-r11e_lte/atc-mik-r11e_lte_2024-06-05-0.1_all.ipk
opkg install atc-mik-r11e_lte_2024-06-05-0.1_all.ipk
```
Source code available at: https://github.com/mrhaav/openwrt-packages/tree/main/atc-mik-r11e_lte
\
\
Tested on a MiktoTik wAP R, RBwARP-2nD.

Follow installation guide on: https://openwrt.org/toh/mikrotik/common

Install following packages:
```
kmod-usb-acm
kmod-mii
kmod-usb-net
kmod-usb-net-rndis
chat
comgt
```
then install:
```
atc-mik-r11e_lte
luci-proto-atc
```
You can use WinSCP to move files from your computer to the router.\
\
Reboot\
\
Use device `/dev/ttyACM1`\
\
\
\
I have seen some issue with modem crashes, so I added `/etc/hotplug.d/usb/10-r11e_lte`
```
[ $ACTION = 'add' -a $PRODUCT = '2cd2/1/100' -a $INTERFACE = '8/6/80' ] && {
        wanIface=$(uci show network | grep "proto='atc'" | awk -F '.' '{print $2}')
        modemStarted=$(ubus call network.interface.${wanIface} status | jsonfilter -e '@["data"].modem')
        [ -z "$modemStarted" ] && modemStarted=$(ubus call network.interface.${wanIface} status | jsonfilter -e '@["errors"].code')
        [ -n "$modemStarted" ] && {
                logger -p 3 -t modem_hotplug Modem crashed!
                ifup $wanIface
        }
}
```
\
*If you would like to install MikroTik sw:\
<https://wiki.mikrotik.com/wiki/Manual:Netinstall>\
and use your MAC-address to access your router.*
