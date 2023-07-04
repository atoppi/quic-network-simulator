# Set up the routing needed for the simulation.
/setup.sh

SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=4000
KEY=cert.key
CERT=cert.crt
SERVER_HTDOCS=/www
LOG_FILE="/logs/stout.log"

LOG_ARGS=""
if [ -n "$QLOGDIR" ]; then
	LOG_ARGS="--qlog-dir=$QLOGDIR"
fi

SERVER_BIN=""
#SERVER_CC_ARGS="--cc bbr2 --initial-rtt 100ms"
SERVER_ARGS="$SERVER_HOST $SERVER_PORT $KEY $CERT --htdocs $SERVER_HTDOCS --show-secret --verify-client $LOG_ARGS $SERVER_CC_ARGS"

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
	$SERVER_BIN $SERVER_ARGS $@ >> $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	echo "Starting server ($TESTCASE)"
	run_server
fi
