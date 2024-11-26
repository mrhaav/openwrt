# Huawei ME909s-120 modem

Tested on FW `11.617.01.00.00`

Package dependencies:
```
kmod-usb-serial-option
kmod-usb-net-cdc-ether
comgt
```
To be used with `luci-proto-atc`

Download and install with:

OPKG
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/hua-me909s_120/atc-hua-me909s_120_2024.11.26-1_all.ipk
opkg install atc-hua-me909s_120_2024.11.26-1_all.ipk
```


IPv6 not tested.
