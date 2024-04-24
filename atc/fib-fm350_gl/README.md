# Fibocom FM350-GL modem

Packet dependencies:
```
kmod-usb-serial-option
kmod-usb-net-rndis
comgt
```

USB hotplug script add Option driver. You can edit `/etc/hotplug.d/usb/50-fm350_driver` to use Generic driver.

Support dual stack and received SMS will be stored in `/tmp/sms/rx` folder and the full path is sent to `/usr/bin/atc_rx_sms.sh <full path>`. `atc_rx_sms.sh` is not included in the package.


Download and install with:

```
wget https://github.com/mrhaav/openwrt/raw/master/atc/fib-fm350_gl/atc-fib-fm350_gl_2024-04-24-0.1_all.ipk
opkg install atc-fib-fm350_gl_2024-04-24-0.1_all.ipk
```
