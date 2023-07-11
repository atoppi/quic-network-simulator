#!/bin/bash

# Set up the routing needed for the simulation
/setup.sh

if [ -n "$QLOGDIR" ]; then
	rm -rf "$QLOGDIR"/*.*
fi
rm -rf /logs/qlog

if [ "$ROLE" == "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	echo "Starting ngtcp2 client ($TESTCASE)"
	./start_client.sh
elif [ "$ROLE" == "server" ]; then
	echo "Starting ngtcp2 server ($TESTCASE)"
	./start_server.sh
fi
