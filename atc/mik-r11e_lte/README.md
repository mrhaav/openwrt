# MikroTik R11e-LTE modem

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
Reboot\
\
Ipv6 is not verified.\
\
I have seen some issue with modem crashes, so I added `/etc/hotplug.d/usb/10-r11e_lte`
`10-r11e_lte`
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
and use your MAC-address to access.*
