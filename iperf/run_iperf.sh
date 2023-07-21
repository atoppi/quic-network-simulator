#!/bin/bash

./setup.sh

./wait-for-it.sh sim:57832 -s -t 10

PORT=5001

if [ "$ROLE" == "server" ]; then
    sleep 1
    if [ "$IPERF_TYPE" == "udp" ]; then
        OPTS="-c $CLIENT -p $PORT -u -b ${IPERF_BAND}M -l 1400 -i 2 -t 3600 --connect-timeout 5000"
        echo "iperf3 $OPTS"
        iperf3 $OPTS
    elif [ "$IPERF_TYPE" == "tcp" ]; then
        OPTS="-c $CLIENT -p $PORT -b ${IPERF_BAND}M -C $IPERF_CCA -i 2 -t 3600 --connect-timeout 5000"
        echo "iperf3 $OPTS"
        iperf3 $OPTS
    fi
elif [ "$ROLE" == "client" ]; then
    OPTS="-s -p $PORT -i 2"
    echo "iperf3 $OPTS"
    iperf3 $OPTS
fi
