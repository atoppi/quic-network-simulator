#!/bin/bash

./setup.sh
./wait-for-it.sh sim:57832 -s -t 10

if [ "$IPERF_ACTIVATION" == "y" ]; then
  if [ "$ROLE" == "server" ]; then
    ./wait-for-it.sh $CLIENT:5001 -s -t 10
    iperf -c $CLIENT -t 3600 -e -i 1
  else
    iperf -i 1 -s -p 5001
  fi
else
  sleep infinity
fi