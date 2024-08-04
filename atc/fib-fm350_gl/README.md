# Fibocom FM350-GL modem

Package dependencies:
```
kmod-usb-serial-option
kmod-usb-net-rndis
comgt
```
To be used with `luci-proto-atc`\
\
USB hotplug script add Option driver. You can edit `/etc/hotplug.d/usb/50-fm350_driver` to use Generic driver.

AT command base script. Handles network disconnections if your service provider use NITZ. The FM350-GL modem has a limitied support for AT command and the only trigger for reconnection is the indication of received NITZ information, `+CTZV`.\
Support dual stack and received SMS will be stored in `/tmp/sms/rx` folder and the full path is sent to `/usr/bin/atc_rx_sms.sh <full path>`. `atc_rx_sms.sh` is not included in the package.


Download and install with:

```
wget https://github.com/mrhaav/openwrt/raw/master/atc/fib-fm350_gl/atc-fib-fm350_gl_2024-08-04-0.2_all.ipk
opkg install atc-fib-fm350_gl_2024-08-04-0.2_all.ipk
```
\
In `AT+GTUSBMODE=40` (0e8d:7126) then the AT-command port is USB interface 4 and in `AT+GTUSBMODE=41` (0e8d:7127) the AT-command port is USB interface 6.
If you don´t have any other serial USB interfaces connected it will be `/dev/ttyUSB2` and `/dev/ttyUSB4`.

\
If the script doesn´t work, check in syslog. If it stops at ` offline -> registered - .....` then your service provider doesn´t use NITZ and disconnections can´t be detected. You can use `atc-fib-fm350_gl_2024-04-24-0.2_all.ipk` instead, but you have to check network connectivity by your self.

\
IPv6:\
To be able to receive Router Advertisment you need to open a Firewall - Trafic rule that allows ICMP from wan.
```
firewall.@rule[x]=rule
firewall.@rule[x].name='Allow modem RA'
firewall.@rule[x].family='ipv6'
firewall.@rule[x].proto='icmp'
firewall.@rule[x].src_ip='fe80::1'
firewall.@rule[x].target='ACCEPT'
firewall.@rule[x].src='wan'
```
![image](https://github.com/mrhaav/openwrt/assets/62175065/1f65d67c-15fa-40f6-b693-44752998327d)

\
If you have problems with modem crashes this hotplug script may help to re-start the interface.

`/etc/hotplug.d/usb/60-fm350_crash`
```
if ([ "$PRODUCT" = 'e8d/7126/1' ] || [ "$PRODUCT" = 'e8d/7127/1' ]) && [ "${DEVICENAME: -3}" = '1.6' ] && [ "$ACTION" = 'bind' ] && [ -f /tmp/fm350.status ] && [ $(cat /tmp/fm350.status) != 'boot' ]
then
    logger -t fm350-gl 'Modem has crashed'
    echo $((1+$(cat /tmp/fm350.status))) > /tmp/fm350.status
    wanIface=$(uci show network | grep "proto='atc'" | awk -F '.' '{print $2}')
    ifup $wanIface
fi
```

Source code at: https://github.com/mrhaav/openwrt-packages/tree/main/atc-fib-fm350_gl
