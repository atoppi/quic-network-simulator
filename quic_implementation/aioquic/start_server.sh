SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=443

SERVER_BIN="python3 examples/http3_server.py"
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/server.log"
	LOG_ARGS="$LOG_ARGS --quic-log $QLOGDIR --verbose"
fi
### unsupported
SERVER_CC_ARGS=""
### aioquic logging/qlogging seems to be very inefficient, disable logging to unlock full speed transfer
SERVER_ARGS="$LOG_ARGS --host $SERVER_HOST --port $SERVER_PORT --certificate tests/ssl_cert.pem --private-key tests/ssl_key.pem --secrets-log $SSLKEYLOGFILE $SERVER_CC_ARGS"

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

run_server
