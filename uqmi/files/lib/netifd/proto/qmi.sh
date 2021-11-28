#!/bin/sh

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_qmi_init_config() {
	available=1
	no_device=1
	proto_config_add_string "device:device"
	proto_config_add_string apn
	proto_config_add_string auth
	proto_config_add_string username
	proto_config_add_string password
	proto_config_add_string pincode
	proto_config_add_int delay
	proto_config_add_string modes
	proto_config_add_string pdptype
	proto_config_add_int profile
	proto_config_add_boolean dhcp
	proto_config_add_boolean dhcpv6
	proto_config_add_boolean autoconnect
	proto_config_add_int plmn
	proto_config_add_int timeout
	proto_config_add_int mtu
	proto_config_add_defaults
}

proto_qmi_setup() {
	local interface="$1"
	local dataformat connstat
	local device apn auth username password pincode delay modes pdptype
	local profile dhcp dhcpv6 autoconnect plmn timeout mtu $PROTO_DEFAULT_OPTIONS
	local ip4table ip6table
	local cid_4 pdh_4 cid_6 pdh_6
	local ip_6 ip_prefix_length gateway_6 dns1_6 dns2_6
	local update_default_apn=false
	local x=0

	json_get_vars device apn auth username password pincode delay modes
	json_get_vars pdptype profile dhcp dhcpv6 autoconnect plmn ip4table
	json_get_vars ip6table timeout mtu $PROTO_DEFAULT_OPTIONS

	[ "$timeout" = "" ] && timeout="10"

	[ "$metric" = "" ] && metric="0"

	[ -n "$ctl_device" ] && device=$ctl_device

	[ -n "$device" ] || {
		echo "No control device specified"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	[ -n "$delay" ] && sleep "$delay"

	device="$(readlink -f $device)"
	[ -c "$device" ] || {
		echo "The specified control device does not exist"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
	ifname="$( ls "$devpath"/net )"
	[ -n "$ifname" ] || {
		echo "The interface could not be found."
		proto_notify_error "$interface" NO_IFACE
		proto_set_available "$interface" 0
		return 1
	}

	[ -n "$mtu" ] && {
		echo "Setting MTU to $mtu"
		/sbin/ip link set dev $ifname mtu $mtu
	}

# Check PIN status
	pin_status=$(uqmi -s -d /dev/cdc-wdm0  --uim-get-sim-state -t 2000 2>&1)
	While [ ${pin_status:0:1} == 'R' ]
	do
		echo Wait for modem to initiate
		sleep 2
		pin_status=$(uqmi -s -d /dev/cdc-wdm0  --uim-get-sim-state -t 2000 2>&1)
	done
	if [ ${pin_status:0:1} != '{' ]
	then
		echo Can´t check the PINcode
		echo Make sure that PINcode is de-activated
	else
		json_load $pin_status
		json_get_var pin1_status pin1_status
		if [ $pin1_status != "disabled" ]
		then
			echo De-activate the PINcode
			return 1
		fi
	fi

# Check data format
	raw_ip=$(cat /sys/class/net/wwan0/qmi/raw_ip)
	echo $raw_ip
	uqmi -d /dev/cdc-wdm0  --wda-set-data-format 802.3
	data_format=$(uqmi -d /dev/cdc-wdm0 --wda-get-data-format)
	if [ $data_format == '"raw-ip"' ]
	then
		echo Data foramt set to raw-ip
		[ $raw_ip == 'N' ] && echo "Y" > /sys/class/net/wwan0/qmi/raw_ip
	else
		echo Data foramt set to 802.3
	fi

# Check default APN profile
	json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-default-profile-num 3gpp)"
	json_get_var default_profile default-profile
	json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-profile-settings 3gpp,$default_profile)"
	json_get_var def_apn apn
	json_get_var def_pdptype pdp-type
	json_get_var def_username username
	json_get_var def_password password
	json_get_var def_auth auth
	[ "$def_apn" != "$apn" ] && update_default_apn=true
	[ "$def_pdptype" != "$pdptype" ] && update_default_apn=true
	[ "$def_username" != "$username" ] && update_default_apn=true
	[ "$def_password" != "$password" ] && update_default_apn=true
	[ "$def_auth" != "$auth" ]  && update_default_apn=true
	if [ $update_default_apn = true ]
	then
		op_mode=$(uqmi -d /dev/cdc-wdm0 --get-device-operating-mode)
		if [ $op_mode = '"online"' ]
		then
			echo Initiate flight mode
			uqmi -d /dev/cdc-wdm0 --set-device-operating-mode low_power
			sleep 1
			json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-serving-system)"
			json_get_var registration registration
			while [ $registration = registered ]
			do
				sleep 2
				json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-serving-system)"
				json_get_var registration registration
			done
		fi
		echo Change default APN profile
		uqmi -d /dev/cdc-wdm0 --modify-profile 3gpp,$default_profile \
			--apn "$apn" \
			--pdp-type "$pdptype" \
			--username "$username" \
			--password "$password" \
			--auth "$auth"
	fi
	op_mode=$(uqmi -d /dev/cdc-wdm0 --get-device-operating-mode)
	if [ $op_mode != '"online"' ]
	then
		echo Flight mode off
		uqmi -d /dev/cdc-wdm0 --set-device-operating-mode online
		sleep 1
	fi
# Check registered network and used radio technology
	json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-serving-system)"
	json_get_var registration registration
	json_get_var operator plmn_description
	while [ $registration != registered ] && [ $x -lt 3 ]
	do
		sleep 2
		x=$((x+1))
		json_load "$(uqmi -s -d /dev/cdc-wdm0 --get-serving-system)"
		json_get_var registration registration
		json_get_var operator plmn_description
	done
	signal_info=$(uqmi -s -d /dev/cdc-wdm0 --get-signal-info)
	while [ ${signal_info:0:1} != '{' ]
	do
		sleep 1
		signal_info=$(uqmi -s -d /dev/cdc-wdm0 --get-signal-info)
	done
	json_load $signal_info
	json_get_var radio_type type
	if [ $x -eq 3 ]
	then
		echo Can´t register to $operator on $radio_type
		echo Check subscription or APN settings
		return 1
	fi
	echo Registered to $operator on $radio_type
# Start network interface
	cid_4=$(uqmi -s -d /dev/cdc-wdm0 --get-client-id wds)
	pdh_4=$(uqmi -s -d /dev/cdc-wdm0 --set-client-id wds,"$cid" \
					--start-network \
					--profile $default_profile)
	
	if ! [ "$pdh_4" -eq "$pdh_4" ] 2> /dev/null
	then
		echo Can´t connect, check APN settnings
		return 1
	fi

# Start interface
	echo "Setting up $ifname"
	proto_init_update "$ifname" 1
	proto_set_keep 1
	proto_add_data
	[ -n "$pdh_4" ] && {
		json_add_string "cid_4" "$cid_4"
		json_add_string "pdh_4" "$pdh_4"
	}
	[ -n "$pdh_6" ] && {
		json_add_string "cid_6" "$cid_6"
		json_add_string "pdh_6" "$pdh_6"
	}
	proto_close_data
	proto_send_update "$interface"

	local zone="$(fw3 -q network "$interface" 2>/dev/null)"

	[ -n "$pdh_6" ] && {
		if [ -z "$dhcpv6" -o "$dhcpv6" = 0 ]; then
			json_load "$(uqmi -s -d $device --set-client-id wds,$cid_6 --get-current-settings)"
			json_select ipv6
			json_get_var ip_6 ip
			json_get_var gateway_6 gateway
			json_get_var dns1_6 dns1
			json_get_var dns2_6 dns2
			json_get_var ip_prefix_length ip-prefix-length

			proto_init_update "$ifname" 1
			proto_set_keep 1
			proto_add_ipv6_address "$ip_6" "128"
			proto_add_ipv6_prefix "${ip_6}/${ip_prefix_length}"
			proto_add_ipv6_route "$gateway_6" "128"
			[ "$defaultroute" = 0 ] || proto_add_ipv6_route "::0" 0 "$gateway_6" "" "" "${ip_6}/${ip_prefix_length}"
			[ "$peerdns" = 0 ] || {
				proto_add_dns_server "$dns1_6"
				proto_add_dns_server "$dns2_6"
			}
			[ -n "$zone" ] && {
				proto_add_data
				json_add_string zone "$zone"
				proto_close_data
			}
			proto_send_update "$interface"
		else
			json_init
			json_add_string name "${interface}_6"
			json_add_string ifname "@$interface"
			json_add_string proto "dhcpv6"
			[ -n "$ip6table" ] && json_add_string ip6table "$ip6table"
			proto_add_dynamic_defaults
			# RFC 7278: Extend an IPv6 /64 Prefix to LAN
			json_add_string extendprefix 1
			[ -n "$zone" ] && json_add_string zone "$zone"
			json_close_object
			ubus call network add_dynamic "$(json_dump)"
		fi
	}

	[ -n "$pdh_4" ] && {
		if [ "$dhcp" = 0 ]; then
			json_load "$(uqmi -s -d $device --set-client-id wds,$cid_4 --get-current-settings)"
			json_select ipv4
			json_get_var ip_4 ip
			json_get_var gateway_4 gateway
			json_get_var dns1_4 dns1
			json_get_var dns2_4 dns2
			json_get_var subnet_4 subnet

			proto_init_update "$ifname" 1
			proto_set_keep 1
			proto_add_ipv4_address "$ip_4" "$subnet_4"
			proto_add_ipv4_route "$gateway_4" "128"
			[ "$defaultroute" = 0 ] || proto_add_ipv4_route "0.0.0.0" 0 "$gateway_4"
			[ "$peerdns" = 0 ] || {
				proto_add_dns_server "$dns1_4"
				proto_add_dns_server "$dns2_4"
			}
			[ -n "$zone" ] && {
				proto_add_data
				json_add_string zone "$zone"
				proto_close_data
			}
			proto_send_update "$interface"
		else
			json_init
			json_add_string name "${interface}_4"
			json_add_string ifname "@$interface"
			json_add_string proto "dhcp"
			[ -n "$ip4table" ] && json_add_string ip4table "$ip4table"
			proto_add_dynamic_defaults
			[ -n "$zone" ] && json_add_string zone "$zone"
			json_close_object
			ubus call network add_dynamic "$(json_dump)"
		fi
	}
}

qmi_wds_stop() {
	local cid="$1"
	local pdh="$2"

	[ -n "$cid" ] || return

	uqmi -s -d "$device" --set-client-id wds,"$cid" \
		--stop-network 0xffffffff \
		--autoconnect > /dev/null 2>&1

	[ -n "$pdh" ] && {
		uqmi -s -d "$device" --set-client-id wds,"$cid" \
			--stop-network "$pdh" > /dev/null 2>&1
	}

	uqmi -s -d "$device" --set-client-id wds,"$cid" \
		--release-client-id wds > /dev/null 2>&1
}

proto_qmi_teardown() {
	local interface="$1"

	local device cid_4 pdh_4 cid_6 pdh_6
	json_get_vars device

	[ -n "$ctl_device" ] && device=$ctl_device

	echo "Stopping network $interface"

	json_load "$(ubus call network.interface.$interface status)"
	json_select data
	json_get_vars cid_4 pdh_4 cid_6 pdh_6

	qmi_wds_stop "$cid_4" "$pdh_4"
	qmi_wds_stop "$cid_6" "$pdh_6"

	proto_init_update "*" 0
	proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol qmi
}
