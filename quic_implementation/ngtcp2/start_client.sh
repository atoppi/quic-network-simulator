# Set up the routing needed for the simulation.
/setup.sh

REQUESTS="https://193.167.100.100:4000/sample.txt"
SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

LOG_FILE="/logs/stout.log"

QLOG_ARG=""
if [ -n "$QLOGDIR" ]; then
	QLOG_ARG="--qlog-dir=$QLOGDIR"
fi

CLIENT_BIN=""
#CLIENT_CC_ARGS="--cc bbr2 --initial-rtt 100ms"
CLIENT_ARGS="--key=key_client.pem --cert=cert_client.pem --download /downloads --show-secret --no-quic-dump --no-http-dump --exit-on-all-streams-close $QLOG_ARG $CLIENT_CC_ARGS"

if [ -n "$TESTCASE" ]; then
	case "$TESTCASE" in
			"ecn")
			CLIENT_BIN="./h09client"
			CLIENT_ARGS="CLIENT_ARGS -v 0x1 --no-pmtud"
			;;
		"handshake")
			CLIENT_BIN="./h09client"
			CLIENT_ARGS="$CLIENT_ARGS -v 0x1"
			;;
		"transfer")
			CLIENT_BIN="./h09client"
			CLIENT_ARGS="$CLIENT_ARGS -v 0x1"
			;;
		"versionnegotiation")
			CLIENT_BIN="./h09client"
			CLIENT_ARGS="$CLIENT_ARGS -v 0xaaaaaaaa"
			;;
		"zerortt")
			CLIENT_BIN="./h09client"
			CLIENT_ARGS="CLIENT_ARGS -v 0x1 --no-pmtud --session-file session.txt --tp-file tp.txt --wait-for-ticket"
			;;
		*)
			exit 127
			;;
	esac
fi

run_client() {
	echo "$CLIENT_BIN $SERVER_HOST $SERVER_PORT $CLIENT_ARGS $CLIENT_PARAMS $@"
	$CLIENT_BIN $SERVER_HOST $SERVER_PORT $CLIENT_ARGS $CLIENT_PARAMS $@ >> $LOG_FILE 2>&1
}

if [ "$ROLE" = "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	echo "Starting client ($TESTCASE)"

	case "$TESTCASE" in
	"zerortt")
		run_client $REQUESTS
		echo "Session file generated, resuming session"
		run_client $REQUESTS
		;;
	*)
		run_client $REQUESTS
		;;
	esac
	
	echo "Test Completed: qlog files in $QLOGDIR | secrets file in $SSLKEYLOGFILE"
fi

