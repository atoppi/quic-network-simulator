#!/bin/bash

./setup.sh

./wait-for-it.sh sim:57832 -s -t 10

start_iperf_server() {
    LABEL=$1
    TYPE=$2
    HOST=$3
    PORT=$4
    BAND=$5
    CCA=$6

    if [ "$TYPE" == "udp" ]; then
        OPTS="-c $HOST -p $PORT -T $LABEL -u -b ${BAND}M -l 1400 -i 2 -t 3600 --connect-timeout 5000"
        echo "iperf3 $OPTS"
        iperf3 $OPTS
    elif [ "$IPERF_TYPE" == "tcp" ]; then
        OPTS="-c $HOST -p $PORT -T $LABEL -b ${BAND}M -C $CCA -i 2 -t 3600 --connect-timeout 5000"
        echo "iperf3 $OPTS"
        iperf3 $OPTS
    fi
}

start_iperf_client() {
    PORT=$1
    OPTS="-s -p $PORT -i 2 --one-off"
    echo "iperf3 $OPTS"
    iperf3 $OPTS
}

IFS=', ' read -r -a IPERF_WAITS <<< $IPERF_WAITS
NUM=${#IPERF_WAITS[@]}
if [ "$NUM" -gt 3 ]; then
    NUM=3
fi
IPERF_PORTS=( $(seq 5001 $((5001 + $NUM - 1))) )

echo "Launching $NUM iperf $ROLE instances with delays: ${IPERF_WAITS[@]}"

for (( i=0; i<$NUM; i++ )); do
    WAIT_TIME=${IPERF_WAITS[$i]}
    PORT=${IPERF_PORTS[$i]}
	if [ "$ROLE" == "server" ]; then
        (sleep "${WAIT_TIME}.5"  && start_iperf_server "cross-traffic-$(($i + 1))" $IPERF_TYPE $IPERF_CLIENT $PORT $IPERF_BAND $IPERF_CCA) &
    elif [ "$ROLE" == "client" ]; then
        (sleep $WAIT_TIME && start_iperf_client $PORT) &
    fi
done

wait