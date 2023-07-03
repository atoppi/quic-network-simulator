# Set up the routing needed for the simulation.
/setup.sh

SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=4000
KEY=cert.key
CERT=cert.crt
SERVER_HTDOCS=/www

LOG_FILE="/logs/stout.log"

QLOG_ARG=""
if [ -n "$QLOGDIR" ]; then
	QLOG_ARG="--qlog-dir=$QLOGDIR"
fi

SERVER_BIN=""
#SERVER_CC_ARGS="--cc bbr2 --initial-rtt 100ms"
SERVER_ARGS="--htdocs $SERVER_HTDOCS --show-secret --verify-client $QLOG_ARG $SERVER_CC_ARGS"

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
	echo "$SERVER_BIN $SERVER_HOST $SERVER_PORT $KEY $CERT $SERVER_ARGS $SERVER_PARAMS $@"
	$SERVER_BIN $SERVER_HOST $SERVER_PORT $KEY $CERT $SERVER_ARGS $SERVER_PARAMS $@ >> $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	echo "Starting server ($TESTCASE)"
	run_server
fi
