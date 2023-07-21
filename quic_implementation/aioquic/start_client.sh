REQUESTS="https://server4:443/$DIM_FILE"
SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

CLIENT_BIN="python3 examples/http3_client.py"
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/client.log"
	LOG_ARGS="$LOG_ARGS --quic-log $QLOGDIR --verbose"
fi
### unsupported
CLIENT_CC_ARGS=""
### aioquic logging/qlogging seems to be very inefficient, disable logging to unlock full speed transfer
CLIENT_ARGS="$LOG_ARGS --insecure --secrets-log $SSLKEYLOGFILE $CLIENT_CC_ARGS"

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
	sleep 2
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

	sleep 2
	echo "Client stopped"
fi
