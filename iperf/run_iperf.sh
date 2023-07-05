#!/bin/bash

./setup.sh

./wait-for-it.sh sim:57832 -s -t 10

if [ "$IPERF_ACTIVATION" == "y" ]; then
  if [ "$ROLE" == "server" ]; then
    ./wait-for-it.sh $CLIENT:5001 -s -t 10
    iperf3 -i 2 -p 5001 -u -c $CLIENT -b ${IPERF_BAND}M -t 3600 -l 1200
  else
    iperf3 -i 2 -p 5001 -s
  fi
else
  sleep infinity
fi
