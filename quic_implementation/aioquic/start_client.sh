REQUESTS="https://193.167.100.100:4000/$DIM_FILE"
LOG_FILE="client.log"

LOG_ARGS=""
if [ -n "$QLOGDIR" ]; then
	LOG_ARGS="$LOG_ARGS --quic-log $QLOGDIR"
	LOG_FILE="$(dirname "$QLOGDIR")"/$LOG_FILE
fi
if [ -n "$SSLKEYLOGFILE" ]; then
	LOG_ARGS="$LOG_ARGS --secrets-log $SSLKEYLOGFILE"
fi

CLIENT_BIN="python3 examples/http3_client.py"
CLIENT_ARGS="--insecure --output-dir /downloads --verbose $LOG_ARGS"

if [ -n "$TESTCASE" ]; then
	case "$TESTCASE" in
		"chacha20")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http --cipher-suites CHACHA20_POLY1305_SHA256"
			;;
		"handshake")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http"
			;;
		"http3")
			;;
		"multiconnect")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http"
			;;
		"resumption")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http --session-ticket session.ticket"
			;;
		"retry")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http"
			;;
		"transfer")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http --max-data 262144 --max-stream-data 262144"
			;;
		"zerortt")
			CLIENT_ARGS="$CLIENT_ARGS --legacy-http --session-ticket session.ticket --zero-rtt"
			;;
		*)
			exit 127
			;;
	esac
fi 

run_client() {
	echo "$CLIENT_BIN $CLIENT_ARGS $@"
	$CLIENT_BIN $CLIENT_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	sleep 5
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

	sleep 5
	echo "Client stopped"
fi
