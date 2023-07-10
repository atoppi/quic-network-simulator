SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=443

SERVER_BIN="python3 examples/http3_server.py"
LOG_FILE="$(dirname "$QLOGDIR")/server.log"
LOG_ARGS="$LOG_ARGS --quic-log $QLOGDIR"
if [ -n "$SSLKEYLOGFILE" ]; then
	LOG_ARGS="$LOG_ARGS --secrets-log $SSLKEYLOGFILE"
fi
### unsupported
SERVER_CC_ARGS=""
### aioquic logging/qlogging seems to bevery inefficient, remove $LOG_ARGS and--verbose to unlock full speed transfer
SERVER_ARGS="$LOG_ARGS --verbose"
SERVER_ARGS="$SERVER_ARGS --host $SERVER_HOST --port $SERVER_PORT --certificate tests/ssl_cert.pem --private-key tests/ssl_key.pem $SERVER_CC_ARGS"

if [ -n "$TESTCASE" ]; then
	case "$TESTCASE" in
		"chacha20")
			;;
		"handshake")
			;;
		"http3")
			;;
		"multiconnect")
			;;
		"resumption")
			;;
		"retry")
			SERVER_ARGS="$SERVER_ARGS --retry"
			;;
		"transfer")
			;;
		"zerortt")
			;;
		*)
			exit 127
			;;
	esac

	if [ "$ROLE" = "server" ]; then
		export STATIC_ROOT="/www"
	fi
fi

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	$SERVER_BIN $SERVER_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	run_server
fi
