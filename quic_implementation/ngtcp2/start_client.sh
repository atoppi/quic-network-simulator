REQUESTS="https://server4:443/sample.txt"
LOG_FILE="client.log"

LOG_ARGS=""
if [ -n "$QLOGDIR" ]; then
	LOG_ARGS="--qlog-dir=$QLOGDIR"
	LOG_FILE="$(dirname "$QLOGDIR")"/$LOG_FILE
fi

SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

CLIENT_BIN=""
#CLIENT_CC_ARGS="--cc bbr2 --initial-rtt 100ms"
CLIENT_ARGS="$SERVER_HOST $SERVER_PORT --key=key_client.pem --cert=cert_client.pem --download /downloads --show-secret --no-quic-dump --no-http-dump --exit-on-all-streams-close $LOG_ARGS $CLIENT_CC_ARGS"

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
	echo "$CLIENT_BIN $CLIENT_ARGS $@"
	$CLIENT_BIN $CLIENT_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	sleep 5

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
