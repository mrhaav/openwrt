# SMS

SMS support to the atc protocol.\
\
Download and install with:
```
wget https://github.com/mrhaav/openwrt/raw/master/atc/sms/atc-sms_2025.01.30-r1_all.ipk
opkg install atc-sms_2025.01.30-r1_all.ipk
```
\
**Receiving SMS**\
Received SMS are stored in `/var/sms/rx` folder.
The SMS is stored as sender number in the first line and the text in the following lines.
```
+46708123456
Reset router
```
The file name is sent to `/usr/bin/atc_sms_user`. Create your own SMS based commands in `/usr/bin/atc_sms_user`.\
`/usr/bin/atc_sms_user` is not included.\
\
\
**Sending SMS**\
Send SMS with string: `/usr/bin/atc_tx_pdu_sms $'+46708123456\nHello'`
or send SMS from file `/usr/bin/atc_tx_pdu_sms <file name>`
```
+46708123456
Hello
```


##
\
atc-sms only support ascii characters h'20 - h'7E, but not h'60.

![image](https://github.com/user-attachments/assets/36c0b645-99a9-4293-84d3-14f4d254d14d)

Concatenated SMS are not assembled.
