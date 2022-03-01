#!/bin/sh

pingWWAN=$(ping 8.8.8.8 -c 4 -W 1 -I wwan0 | grep packets | awk '{print $7 }' | sed s/%//g)

if [ "$pingWWAN" = 100 ] || [ -z "$pingWWAN" ]
then
	logger -t check_wwan wwan0 connection broken
	logger -t check_wwan Restart wwan0
	ifup wwan
fi
