# Huawei E3372h-320 modem

Tested on FW `11.0.1.1(H697SP1C983)`\
\
Package dependencies:
```
kmod-usb-net-cdc-ncm
kmod-usb-serial-option
comgt
usb-modeswitch
```
Use the third `/dev/ttyUSBx` device with `atc`.

\
Download and install with:
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/hua-e3372h_320/atc-hua-e3372h_320_2025-11-20-r0.1_all.ipk
opkg install atc-hua-e3372h_320_2025-11-20-r0.1_all.ipk
```

\
Use usb-modeswitch to switch to NCM mode.\
You need to add a new message and change the device entry of 12d1:1f01.\
Thanks to to user `woec` at OpenWrt forum who provided the informtion, https://forum.openwrt.org/t/huawei-e3372h-320-in-ncm-mode/126018/12

Add message `"55534243123456780000000000000011063000000000010000000000000000"` at the end of the message block, in the begining of `/etc/usb-mode.json`, and modify device entry 12d1:1f01 to:
```
        "12d1:1f01": {
                "*": {
                        "t_vendor": 4817,
                        "t_product": [ 5339, 5340 ],
                        "mode": "HuaweiAlt",
                        "msg": [ xx ]
                }
        }
```
Where xx is the message entry of the newly added message. Verify with `jsonfilter -i /etc/usb-mode.json -e '@["messages"][xx]'`. In my case xx = 61.

\
`cat /sys/kernel/debug/usb/devices` after `usb-modeswitch`:
```
T:  Bus=01 Lev=01 Prnt=01 Port=00 Cnt=01 Dev#=  8 Spd=480  MxCh= 0
D:  Ver= 2.00 Cls=02(comm.) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
P:  Vendor=12d1 ProdID=155e Rev= 1.02
S:  Manufacturer=HUAWEI_MOBILE
S:  Product=HUAWEI_MOBILE
C:* #Ifs= 5 Cfg#= 1 Atr=80 MxPwr=  2mA
A:  FirstIf#= 3 IfCount= 2 Cls=02(comm.) Sub=0d Prot=00
I:* If#= 0 Alt= 0 #EPs= 3 Cls=ff(vend.) Sub=ff Prot=ff Driver=option
E:  Ad=83(I) Atr=03(Int.) MxPS=  10 Ivl=32ms
E:  Ad=82(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=02(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 1 Alt= 0 #EPs= 2 Cls=ff(vend.) Sub=ff Prot=ff Driver=option
E:  Ad=84(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=03(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 2 Alt= 0 #EPs= 2 Cls=ff(vend.) Sub=ff Prot=ff Driver=option
E:  Ad=85(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=04(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 3 Alt= 0 #EPs= 1 Cls=02(comm.) Sub=0d Prot=00 Driver=cdc_ncm
E:  Ad=87(I) Atr=03(Int.) MxPS=  16 Ivl=2ms
I:  If#= 4 Alt= 0 #EPs= 0 Cls=0a(data ) Sub=00 Prot=01 Driver=cdc_ncm
I:* If#= 4 Alt= 1 #EPs= 2 Cls=0a(data ) Sub=00 Prot=01 Driver=cdc_ncm
E:  Ad=86(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=05(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
```
