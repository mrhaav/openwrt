# Huawei E3372h-320 modem

Use usb-modeswitch to switch to NCM mode.
You need to add a new message and change device entry of 12d1:1f01.\
Thanks to to used `woec` at OpenWrt forum who provided the informtion, https://forum.openwrt.org/t/huawei-e3372h-320-in-ncm-mode/126018/12

Add message `"55534243123456780000000000000011063000000000010000000000000000"` at the end of the message block, in the begining of `/etc/usb-mode.json`.\
Modify device entry 12d1:1f01 to:
```
"12d1:1f01": {
                         "*": {
                                 "t_vendor": 4817,
                                 "t_product": [ 5339, 5340 ],
                                 "mode": "HuaweiAlt",
                                 "msg": [  xx ]
                    }
             }
```
Where xx is the message entry of the newly added message. Verify with `jsonfilter -i /etc/usb-mode.json -e '@["messages"][xx]'`. In my case xx = 61.
