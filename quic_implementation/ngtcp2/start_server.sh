SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=443

SERVER_BIN=""
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/server.log"
	LOG_ARGS="$LOG_ARGS --qlog-dir=$QLOGDIR"
fi
### cubic|reno|bbr|bbr2 default=cubic
SERVER_CC_ARGS="--cc cubic --initial-rtt 100ms"
SERVER_ARGS="$LOG_ARGS --htdocs /www --show-secret --verify-client $SERVER_CC_ARGS"

if [ -n "$TESTCASE" ]; then
	case "$TESTCASE" in
		"ecn")
			SERVER_BIN="./h09server"
			SERVER_ARGS="SERVER_ARGS --no-pmtud"
			;;
		"handshake")
			SERVER_BIN="./h09server"
			SERVER_ARGS="$SERVER_ARGS"
			;;
		"transfer")
			SERVER_BIN="./h09server"
			SERVER_ARGS="$SERVER_ARGS"
			;;
		"versionnegotiation")
			SERVER_BIN="./h09server"
			SERVER_ARGS="$SERVER_ARGS"
			;;
		"zerortt")
			SERVER_BIN="./h09server"
			SERVER_ARGS="SERVER_ARGS"
			;;
		*)
			exit 127
			;;
	esac
fi

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	$SERVER_BIN $SERVER_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	run_server $SERVER_HOST $SERVER_PORT /certs/cert.key /certs/cert.crt
fi
