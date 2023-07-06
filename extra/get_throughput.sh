#!/bin/bash -eu

export LC_ALL=C.UTF-8

PCAP_FILE_PATH=$(echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")")

#PROFILE=$(basename $(dirname "$PCAP_FILE_PATH"))
#STACK=$(basename $(dirname $(dirname "$PCAP_FILE_PATH")))

SUMMARY=$(tshark -z conv,udp -r $PCAP_FILE_PATH -q | tail -2 | head -1 | tr -s ' ')
SIZE_BYTES=$(echo $SUMMARY | awk '{ print $5toupper(substr($6,1,1)) }' | numfmt --from=auto)
DURATION_SECS=$(echo $SUMMARY | awk '{ print $14 }')
THPUT_MBPS=$(echo "scale=2; ((8*$SIZE_BYTES)/($DURATION_SECS))/1000000" | bc)

echo $THPUT_MBPS
