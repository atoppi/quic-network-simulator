REQUESTS="https://server4:443/sample.txt"
SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

CLIENT_BIN=""
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/client.log"
	LOG_ARGS="$LOG_ARGS --qlog-dir=$QLOGDIR"
fi
### cubic|reno|bbr|bbr2 default=cubic
CLIENT_CC_ARGS="--cc cubic --initial-rtt 100ms"
CLIENT_ARGS="--key=key_client.pem --cert=cert_client.pem --show-secret --no-quic-dump --no-http-dump --exit-on-all-streams-close $LOG_ARGS $CLIENT_CC_ARGS"

if [ -n "$TESTCASE" ]; then
	case "$TESTCASE" in
		"ecn")
			CLIENT_BIN="./h09qtlsclient"
			CLIENT_ARGS="CLIENT_ARGS -v 0x1 --no-pmtud"
			;;
		"handshake")
			CLIENT_BIN="./h09qtlsclient"
			CLIENT_ARGS="$CLIENT_ARGS -v 0x1"
			;;
		"transfer")
			CLIENT_BIN="./h09qtlsclient"
			CLIENT_ARGS="$CLIENT_ARGS -v 0x1"
			;;
		"versionnegotiation")
			CLIENT_BIN="./h09qtlsclient"
			CLIENT_ARGS="$CLIENT_ARGS -v 0xaaaaaaaa"
			;;
		"zerortt")
			CLIENT_BIN="./h09qtlsclient"
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
	case "$TESTCASE" in
	"zerortt")
		run_client $SERVER_HOST $SERVER_PORT $REQUESTS
		echo "Session file generated, resuming session"
		run_client $SERVER_HOST $SERVER_PORT $REQUESTS
		;;
	*)
		run_client $SERVER_HOST $SERVER_PORT $REQUESTS
		;;
	esac

	sleep 5
	echo "Client stopped"
fi
