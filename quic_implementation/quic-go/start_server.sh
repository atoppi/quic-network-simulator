LOG_FILE="server.log"

LOG_ARGS=""
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")"/$LOG_FILE
fi

SERVER_BIN="./server"
SERVER_ARGS=""

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	QUIC_GO_LOG_LEVEL=debug $SERVER_BIN $SERVER_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	run_server
fi
