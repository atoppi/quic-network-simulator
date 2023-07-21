#!/bin/bash -eu

export LC_ALL=C.UTF-8

PCAP_FILE_PATH=$(echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")")

#PROFILE=$(basename $(dirname "$PCAP_FILE_PATH"))
#STACK=$(basename $(dirname $(dirname "$PCAP_FILE_PATH")))

SIZE_BYTES=$(tshark -r $PCAP_FILE_PATH -q -z io,stat,0,"SUM(frame.len)frame.len && udp.srcport == 443" | tail -2 | head -1 | tr -s ' ' | awk '{ print $6 }')
DURATION_SECS=$(tshark -r $PCAP_FILE_PATH -q -z conv,udp | grep ":443" | awk '{ print $NF }')
THPUT_MBPS=$(echo "scale=2; ((8*$SIZE_BYTES)/($DURATION_SECS))/1000000" | bc)

printf '%.2f\n' $THPUT_MBPS
