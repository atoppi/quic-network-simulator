#!/bin/bash

# Set up the routing needed for the simulation.
/setup.sh

if [ -n "$QLOGDIR" ]; then
	rm -rf "$QLOGDIR"/*.*
fi
rm -rf /logs/qlog

echo "Using commit:" `cat commit.txt`

if [ "$ROLE" == "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	echo "Starting quic-go client ($TESTCASE)"
	./start_client.sh
elif [ "$ROLE" == "server" ]; then
	echo "Starting quic-go server ($TESTCASE)"
	./start_server.sh
fi
