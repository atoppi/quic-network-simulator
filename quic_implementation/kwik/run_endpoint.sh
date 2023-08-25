#!/bin/bash

# Set up the routing needed for the simulation
/setup.sh

if [ -n "$QLOGDIR" ]; then
	rm -rf "$QLOGDIR"/*.*
fi
rm -rf /logs/qlog

REQUESTS="https://server4:443/sample.txt"

logDownloads() {
	echo "Downloaded files:"
	ls -l /downloads
}

LOG_FILE="/dev/null"
if [ "$ROLE" == "client" ]; then
	if [ -n "$QLOGDIR" ]; then
		LOG_FILE="$(dirname "$QLOGDIR")/client.log"
	fi
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30

	if [ "$TESTCASE" == "handshake" ]; then
		echo "running kwik with $REQUESTS"
		java -jar kwik.jar -v
		java -ea -jar kwik.jar -v1 -A hq-interop --noCertificateCheck -l wi -O /downloads $REQUESTS > $LOG_FILE 2>&1
	elif [ "$TESTCASE" == "transfer" ]; then
		java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads transfer $REQUESTS > $LOG_FILE 2>&1
	elif [ "$TESTCASE" == "zerortt" ]; then
		java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads zerortt $REQUESTS > $LOG_FILE 2>&1
	else
		echo "Unsupported testcase: ${TESTCASE}"
		exit 127
	fi
elif [ "$ROLE" == "server" ]; then
	if [ -n "$QLOGDIR" ]; then
		LOG_FILE="$(dirname "$QLOGDIR")/server.log"
	fi
	if [ "$TESTCASE" == "handshake" ]; then
		echo "running kwik server version " `java -jar kwik.jar -v`
		java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www > $LOG_FILE 2>&1
	elif [[ "$TESTCASE" == "transfer" || "$TESTCASE" == "multiconnect" || "$TESTCASE" == "resumption" || "$TESTCASE" == "zerortt" || "$TESTCASE" == "chacha20" ]]; then
		java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www > $LOG_FILE 2>&1
	else
		echo "Unsupported testcase: ${TESTCASE}"
		exit 127
	fi
fi
