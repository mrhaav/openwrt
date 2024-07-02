#!/bin/sh
#
# AT commands for Fibocom L850-GL modem
# 2024-06-23 by mrhaav
#


[ -n "$INCLUDE_ONLY" ] || {
    . /lib/functions.sh
    . ../netifd-proto.sh
    init_proto "$@"
}

update_IPv4 () {
    proto_init_update "$ifname" 1
    proto_set_keep 1
    proto_add_ipv4_address "$v4address" "$v4netmask"
    proto_add_ipv4_route "$v4gateway" "128"
    [ "$defaultroute" = 0 ] || proto_add_ipv4_route "0.0.0.0" 0 "$v4gateway"
    [ "$peerdns" = 0 ] || {
        proto_add_dns_server "$v4dns1"
        proto_add_dns_server "$v4dns2"
    }
    [ -n "$zone" ] && {
        proto_add_data
        json_add_string zone "$zone"
        proto_close_data
    }
    proto_send_update "$interface"
}

update_DHCPv6 () {
    json_init
    json_add_string name "${interface}6"
    json_add_string ifname "@$interface"
    json_add_string proto "dhcpv6"
    proto_add_dynamic_defaults
#    json_add_string noslaaconly 1
    json_add_string dhcpv6 0
    json_add_string extendprefix 1
    [ "$peerdns" = 0 ] || {
        json_add_array dns
        json_add_string "" "$v6dns1"
        json_add_string "" "$v6dns2"
        json_close_array
    }
    [ -n "$zone" ] && json_add_string zone "$zone"
    json_close_object
    [ "$atc_debug" -ge 1 ] && echo JSON: $(json_dump)
    ubus call network add_dynamic "$(json_dump)"
}

subnet_calc () {
    local IPaddr=$1
    local A B C D 
    local x y netaddr res subnet gateway

    A=$(echo $IPaddr | awk -F '.' '{print $1}')
    B=$(echo $IPaddr | awk -F '.' '{print $2}')
    C=$(echo $IPaddr | awk -F '.' '{print $3}')
    D=$(echo $IPaddr | awk -F '.' '{print $4}')

    x=1
    y=4
    netaddr=$((y-1))
    res=$((D%y))

    while [ $res -eq 0 ] || [ $res -eq $netaddr ]
    do
        x=$((x+1))
        y=$((y*2))
        netaddr=$((y-1))
        res=$((D%y))
    done

    subnet=$((31-x))
    gateway=$((D/y))
    [ $res -eq 1 ] && gateway=$((gateway*y+2)) || gateway=$((gateway*y+1))
    echo $subnet $A.$B.$C.$gateway
}

nb_rat () {
    local rat_nb=$1
    case $rat_nb in
        0|1|3 )
            rat_nb=GSM ;;
        2|4|5|6 )
            rat_nb=WCDMA ;;
        7 )
            rat_nb=LTE ;;
        11 )
            rat_nb=NR ;;
        13 )
            rat_nb=LTE-ENDC
    esac
    echo $rat_nb
}

CxREG () {
    local reg_string=$1
    local lac_tac g_cell_id rat reject_cause

    lac_tac=$(echo $reg_string | awk -F ',' '{print $2}')
    g_cell_id=$(echo $reg_string | awk -F ',' '{print $3}')
    rat=$(echo $reg_string | awk -F ',' '{print $4}')
    rat=$(nb_rat $rat)
    reject_cause=$(echo $reg_string | awk -F ',' '{print $6}')
    [ "$rat" = 'WCDMA' ] && {
        reg_string=', RNCid:'$(printf '%d' 0x${g_cell_id:: -4})' LAC:'$(printf '%d' 0x$lac_tac)' CellId:'$(printf '%d' 0x${g_cell_id: -4})
    }
    [ "${rat::3}" = 'LTE' ] && {
        reg_string=', TAC:'$(printf '%d' 0x$lac_tac)' eNodeB:'$(printf '%d' 0x${g_cell_id:: -2})'-'$(printf '%d' 0x${g_cell_id: -2})
    }
    [ "$reject_cause" -gt 0 ] && reg_string=$reg_string' - Reject cause: '$reject_cause
    [ "$reject_cause" -eq 0 -a "${reg_string::1}" = '0' ] && reg_string=''

    echo $reg_string
}

proto_atc_init_config() {
    no_device=1
    available=1
    proto_config_add_string "device:device"
    proto_config_add_string "apn"
    proto_config_add_string "pincode"
    proto_config_add_string "pdp"
    proto_config_add_string "auth"
    proto_config_add_string "username"
    proto_config_add_string "password"
    proto_config_add_string "atc_debug"
    proto_config_add_string "delay"
    proto_config_add_defaults
}

proto_atc_setup () {
    local interface="$1"
    local sms_rx_folder=/var/sms/rx
    local OK_received=0
    local nw_disconnect=0
    local atOut manufactor model rat new_rat plmn cops_format status sms_index sms_text sms_sender sms_date
    local firstASCII URCline URCcommand URCvalue conStatus operator IPv6 v6address
    local devpath device apn pdp pincode auth username password delay atc_debug $PROTO_DEFAULT_OPTIONS
    local hwaddr h devname

    json_get_vars device ifname apn pdp pincode auth username password delay atc_debug $PROTO_DEFAULT_OPTIONS

    devname=$(basename $device)
    case "$devname" in
        *ttyACM*)
            devpath="$(readlink -f /sys/class/tty/$devname/device)"
            hwaddr="$(ls -1 $devpath/../*/net/*/*address*)"
            for h in $hwaddr
            do
                if [ "$(cat ${h})" = "00:00:11:12:13:14" ]
                then
                    ifname=$(echo ${h} | awk -F [\/] '{print $(NF-1)}')
                fi
            done
        ;;
    esac

    [ -n "$ifname" ] || {
        echo "No interface could be found"
        proto_notify_error "$interface" NO_IFACE
        proto_block_restart "$interface"
        return 1
    }

    zone="$(fw3 -q network "$interface" 2>/dev/null)"

    echo Initiate modem with interface $ifname

# Set error codes to verbose
    atOut=$(COMMAND='AT+CMEE=2' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    while [ "$atOut" != 'OK' ]
    do
        echo 'Modem not ready yet: '$atOut
        sleep 1
        atOut=$(COMMAND='AT+CMEE=2' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    done

# Check SIMcard and PIN status
    atOut=$(COMMAND='AT+CPIN?' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep CPIN: | awk -F ' ' '{print $2 $3}' | sed -e 's/[\r\n]//g')
    while [ -z "$atOut" ]
    do
        atOut=$(COMMAND='AT+CPIN?' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep CPIN: | awk -F ' ' '{print $2 $3}' | sed -e 's/[\r\n]//g')
    done
    case $atOut in
        READY )
            echo SIMcard ready
            ;;
        SIMPIN )
            if [ -z "$pincode" ]
            then
                echo PINcode required but missing
                proto_notify_error "$interface" PINmissing
                proto_block_restart "$interface"
                return 1
            fi
            atOut=$(COMMAND='AT+CPIN="'$pincode'"' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep 'CME ERROR:')
            if [ -n "$atOut" ]
            then
                echo PINcode error: ${atOut:11}
                proto_notify_error "$interface" PINerror
                proto_block_restart "$interface"
                return 1
            fi
            echo PINcode verified
            ;;
        * )
            echo SIMcard error: $atOut
            proto_notify_error "$interface" PINerror
            proto_block_restart "$interface"
            return 1
            ;;
    esac

# Enable flightmode
    atOut=$(COMMAND='AT+CFUN=4' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut
    conStatus=offline
    echo Configure modem

# Get modem manufactor and model
    atOut=$(COMMAND='AT+CGMI' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep CGMI: | awk -F ' ' '{print $2}')
    manufactor=$(echo $atOut | sed -e 's/"//g')
    manufactor=$(echo $manufactor | sed -e 's/\r//g')
    atOut=$(COMMAND='AT+CGMM' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep CGMM: | awk -F ' ' '{print $2}')
    model=$(echo $atOut | sed -e 's/"//g')
    model=$(echo $model | sed -e 's/\r//g')
    [ "$manufactor" = 'Fibocom' -a "$model" = 'L850' ] || {
        echo 'Wrong script. This is optimized for: Fibocom, L850'
        proto_notify_error "$interface" MODEM
        proto_set_available "$interface" 0
    }

# URC, CREG, CGREG and CEREG
    atOut=$(COMMAND='AT+CREG=0' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut
    atOut=$(COMMAND='AT+CGREG=3' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut
    atOut=$(COMMAND='AT+CEREG=3' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut

# CGEREG, for URCcode +CGEV
    atOut=$(COMMAND='AT+CGEREP=2,1' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut

# Configure PDPcontext, profile 0
    atOut=$(COMMAND='AT+CGDCONT=0,"'$pdp'","'$apn'"' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut
    atOut=$(COMMAND='AT+XGAUTH=0,'$auth',"'$username'","'$password'"' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut

# Enable dynamic DNS
    atOut=$(COMMAND='AT+XDNS=0,1;+XDNS=0,2' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut

# Set IPv6 format
    atOut=$(COMMAND='AT+CGPIAF=1,1,0,1' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    [ "$atOut" != 'OK' ] && echo $atOut

# Disable flightmode
    echo Activate modem
    COMMAND='AT+CFUN=1' gcom -d "$device" -s /etc/gcom/at.gcom

    while read URCline
    do
        firstASCII=$(printf "%d" \'${URCline::1})
        if [ ${firstASCII} != 13 ] && [ ${firstASCII} != 32 ]
        then
            URCcommand=$(echo $URCline | awk -F ':' '{print $1}')
            URCcommand=$(echo $URCcommand | sed -e 's/[\r\n]//g')
            x=${#URCcommand}
            x=$(($x+2))
            URCvalue=${URCline:x}
            URCvalue=$(echo $URCvalue | sed -e 's/"//g' | sed -e 's/[\r\n]//g')

            case $URCcommand in
                +CGREG|+CEREG )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    status=$(echo $URCvalue | awk -F ',' '{print $1}')
                    [ ${#URCvalue} -gt 6 ] && {
                        new_rat=$(echo $URCvalue | awk -F ',' '{print $4}')
                        new_rat=$(nb_rat $new_rat)
                    }
                    case $status in
                        0 )
                            echo ' '$conStatus' -> notRegistered'$(CxREG $URCvalue)
                            conStatus='notRegistered'
                            ;;
                        1 )
                            if [ "$conStatus" = 'registered' ]
                            then
                                [ "$atc_debug" -ge 1 ] && echo 'Cell change'$(CxREG $URCvalue)
                                [ "$new_rat" != "$rat" -a -n "$rat" ] && {
                                    echo 'RATchange: '$rat' -> '$new_rat
                                    rat=$new_rat
                                }
                            else
                                echo ' '$conStatus' -> registered - home network'$(CxREG $URCvalue)
                                conStatus='registered'
                            fi
                            ;;
                        2 )
                            echo ' '$conStatus' -> searching '$(CxREG $URCvalue)
                            conStatus='searching'
                            ;;
                        3 )
                            echo 'Registration denied'
                            proto_notify_error "$interface" REG_DENIED
                            proto_block_restart "$interface"
                            return 1
                            ;;
                        4 )
                            echo ' '$conStatus' -> unknown'
                            conStatus='unknown'
                            ;;
                        5 )
                            if [ "$conStatus" = 'registered' ]
                            then
                                [ "$atc_debug" -ge 1 ] && echo 'Cell change'$(CxREG $URCvalue)
                                [ "$new_rat" != "$rat" -a -n "$rat" ] && {
                                    echo RATchange: $rat -> $new_rat
                                    rat=$new_rat
                                }
                            else
                                echo ' '$conStatus' -> registered - roaming'$(CxREG $URCvalue)
                                conStatus='registered'
                            fi
                            ;;
                        esac
                    ;;

                +COPS )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    cops_format=$(echo $URCvalue | awk -F ',' '{print $2}')
                    [ $cops_format -eq 0 ] && {
                        operator=$(echo $URCvalue | awk -F ',' '{print $3}' | sed -e 's/"//g')
                    }
                    [ $cops_format -eq 2 ] && {
                        plmn=$(echo $URCvalue | awk -F ',' '{print $3}' | sed -e 's/"//g')
                        rat=$(echo $URCvalue | awk -F ',' '{print $4}')
                        rat=$(nb_rat $rat)
                        echo 'Registered to '$operator' PLMN:'$plmn' on '$rat
                        echo Activate session
                        OK_received=1
                    }
                    ;;

                +CGEV )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    case $URCvalue in
                        'NW DETACH' )
                            nw_disconnect=1
                            ;;
                        'ME PDN DEACT 0' )
                            echo Session disconnected
                            proto_init_update "$ifname" 0
                            proto_send_update "$interface"
                            ;;
                        'ME PDN ACT 0' )
                            [ $nw_disconnect -eq 0 ] && {
                                COMMAND='AT+COPS=3,0;+COPS?;+COPS=3,2;+COPS?' gcom -d "$device" -s /etc/gcom/at.gcom
                            } || {
                                nw_disconnect=0
                                COMMAND='AT+CGCONTRDP=0' gcom -d "$device" -s /etc/gcom/at.gcom
                                OK_received=2
                            }
                            ;;
                    esac
                    ;;

                +CGCONTRDP )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    URCvalue=$(echo $URCvalue | sed -e 's/"//g')
                    IPv6=$(echo $URCvalue | grep -a ':')
                    if [ -z "$IPv6" ]
                    then
                        v4address=$(echo $URCvalue | awk -F ',' '{print $4}' | awk -F '.' '{print $1"."$2"."$3"."$4}')
                        v4netmask=$(subnet_calc $v4address)
                        v4gateway=$(echo $v4netmask | awk -F ' ' '{print $2}')
                        v4netmask=$(echo $v4netmask | awk -F ' ' '{print $1}')
                        v4dns1=$(echo $URCvalue | awk -F ',' '{print $6}')
                        v4dns2=$(echo $URCvalue | awk -F ',' '{print $7}')
                    else
                        v6address=$(echo $URCvalue | awk -F ',' '{print $4}')
                        v6dns1=$(echo $URCvalue | awk -F ',' '{print $6}')
                        v6dns2=$(echo $URCvalue | awk -F ',' '{print $7}')
                    fi
                    ;;

                CONNECT )
                    echo "Modem connected"
                    proto_init_update "$ifname" 1
                    proto_set_keep 1
                    proto_add_data
                    json_add_string "modem" "${model}"
                    proto_close_data
                    proto_send_update "$interface"
                    ip link set dev $ifname arp off
                    [ -n "$v4address" ] && update_IPv4
                    [ -n "$v6address" ] && update_DHCPv6
                    ;;

                OK )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    [ $OK_received -eq 3 ] && {
                        COMMAND='AT+CGDATA="M-RAW_IP",0' gcom -d "$device" -s /etc/gcom/at.gcom
                        OK_received=10
                    }
                    [ $OK_received -eq 2 ] && {
                        COMMAND='AT+XDATACHANNEL=1,1,"/USBCDC/0","/USBHS/NCM/0",2,0' gcom -d "$device" -s /etc/gcom/at.gcom
                        OK_received=3
                    }
                    [ $OK_received -eq 1 ] && {
                        COMMAND='AT+CGCONTRDP=0' gcom -d "$device" -s /etc/gcom/at.gcom
                        OK_received=2
                    }
                    ;;

                * )
                    [ "$atc_debug" -gt 1 ] && echo $URCline
                    ;;
            esac
        fi
	done < ${device}
}


proto_atc_teardown() {
    local interface="$1"
    local device
    device=$(uci -q get network.$interface.device)
    atOut=$(COMMAND='AT+XDATACHANNEL=0' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    atOut=$(COMMAND='AT+CGDATA=0' gcom -d "$device" -s /etc/gcom/run_at.gcom)
    echo $interface is disconnected
    proto_init_update "*" 0
    proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || {
    add_protocol atc
}
