SERVER_BIN="./server"
LOG_FILE="/dev/null"
QUIC_GO_LOG_LEVEL=""
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/server.log"
	QUIC_GO_LOG_LEVEL="debug"
else
	QLOGDIR="/tmp"
fi
### unsupported
SERVER_CC_ARGS=""
SERVER_ARGS="$SERVER_CC_ARGS"

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	QUIC_GO_LOG_LEVEL=$QUIC_GO_LOG_LEVEL $SERVER_BIN $SERVER_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	run_server
fi
