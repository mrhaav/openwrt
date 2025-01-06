#!/bin/sh
#
# FCC unlock script for Fibocom FM350-GL modem
#
# Info from:
# ModemManger: https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/blob/main/data/dispatcher-fcc-unlock/14c3?ref_type=heads
# ROOter: https://github.com/ofmodemsandmen/RooterSource/blob/main/package/rooter/ext-rooter-basic/files/usr/lib/rooter/connect/create_hostless.sh#L237
#
# Lenovo (and others?): 3df8c719
# printf "%.8s" $(echo -n "KHOIHGIUCCHHII" | sha256sum | cut -d ' ' -f 1)
#
# Dell DW5931e / DW5931e-eSIM: 4909b5a4
# printf "%.8s" $(echo -n "DW5931EFCCLOCK" | sha256sum | cut -d ' ' -f 1)
#

device=$1
VENDOR_ID_HASH="3df8c719"

atOut=$(COMMAND='AT+GTFCCEFFSTATUS?' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep -o '[0-9,]\+')
mode_value=$(echo $atOut | awk -F ',' '{print $1}')
status_value=$(echo $atOut | awk -F ',' '{print $2}')

if [ "$mode_value" = '0' ]
then
    echo 'Modem is unlocked!'
elif [ "$mode_value" = '1' -o "$mode_value" = '2' ]
then
    xxd_installed=$(opkg info xxd | grep 'Status: install')
    if [ -z "$xxd_installed" ]
    then
        echo 'xxd is not installed'
        exit 1
    fi

    [ "$mode_value" = '1' ] && echo 'The modem has a One time lock'
    [ "$mode_value" = '2' ] && echo 'The modem has a Power-up lock'

    CHALLENGE=$(COMMAND='AT+GTFCCLOCKGEN' gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep -o '0x[0-9a-fA-F]\+' | awk '{print $1}')
    if [ -n "$CHALLENGE" ]
    then
        echo 'Got challenge from modem: '$CHALLENGE
        HEX_CHALLENGE=$(printf "%08x" "$CHALLENGE")
        COMBINED_CHALLENGE="${HEX_CHALLENGE}$(printf "%.8s" "${VENDOR_ID_HASH}")"
        RESPONSE_HASH=$(echo "$COMBINED_CHALLENGE" | xxd -r -p | sha256sum | cut -d ' ' -f 1)
        TRUNCATED_RESPONSE=$(printf "%.8s" "$RESPONSE_HASH")
        RESPONSE=$(printf "%d" "0x$TRUNCATED_RESPONSE")
        echo 'Sending response to modem: '$RESPONSE
        UNLOCK_RESPONSE=$(COMMAND='AT+GTFCCLOCKVER='$RESPONSE gcom -d "$device" -s /etc/gcom/getrun_at.gcom | grep -o '[0-9,]\+' | awk '{print $1}')

        if [ "$UNLOCK_RESPONSE" = '1' ]; then
            echo 'FCC unlock succeeded'

            if [ "$mode_value" = '2' ]
            then
                atOut=$(COMMAND='AT+GTFCCLOCKMODE=0' gcom -d "$device" -s /etc/gcom/run_at.gcom)
                [ "$atOut" = 'OK' ] && echo 'Power-up unlock succeeded' || echo 'Power-up unlock failed'
            fi
        else
            echo 'Unlock failed.'
        fi
    else
        echo 'Failed to obtain FCC challenge.'
    fi
else
    echo 'Make sure no application is using the AT-port: '$device
    echo 'run AT+GTFCCEFFSTATUS? manually'
fi
