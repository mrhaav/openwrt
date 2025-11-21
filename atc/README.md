# atc

AT command based protocol

Don´t run any other application connected to the same port. The `atc` protocol listens to the received messages and react on the result.
When the modem is activated all messages are displayed in Syslog.

luci-proto-atc update 2025.01.10:\
Possibility to add custom AT-commands.\
Receive IPv6 DNS servers via Router Advertisment.


\
Download and install:


OPKG
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/luci-proto-atc_2025.01.10-r2_all.ipk
opkg install luci-proto-atc_2025.01.10-r2_all.ipk
```

APK
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/luci-proto-atc-2025.01.10-r2.apk
apk add --allow-untrusted luci-proto-atc-2025.01.10-r2.apk
```
