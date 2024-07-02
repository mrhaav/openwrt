# Fibocom L850-GL modem

Package dependencies:
```
kmod-usb-acm
kmod-usb-net-cdc-ncm
comgt
```
To be used with `luci-proto-atc`\
\
Download and install with:

```
wget https://github.com/mrhaav/openwrt/raw/master/atc/fib-l850_gl/atc-fib-l850_gl_2024-06-23-0.2_all.ipk
opkg install atc-fib-fm350_gl_2024-06-15-0.2_all.ipk
```
\
Change to NCM mode with `AT+GTUSBMODE=0`
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

