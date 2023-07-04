# Set up the routing needed for the simulation.
/setup.sh

SERVER_HOST=$(hostname -I | cut -f1 -d" ")
SERVER_PORT=4000
KEY=tests/ssl_key.pem
CERT=tests/ssl_cert.pem
SERVER_HTDOCS=/www
LOG_FILE="/logs/stout.log"

LOG_ARGS=""
if [ -n "$QLOGDIR" ]; then
	LOG_ARGS="$LOG_ARGS --quic-log $QLOGDIR"
fi
if [ -n "$SSLKEYLOGFILE" ]; then
	LOG_ARGS="$LOG_ARGS --secrets-log $SSLKEYLOGFILE"
fi

SERVER_BIN="python3 examples/http3_server.py"
SERVER_ARGS="--host $SERVER_HOST --port $SERVER_PORT --certificate $CERT --private-key $KEY --verbose $LOG_ARGS"

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
		export STATIC_ROOT="$SERVER_HTDOCS"
	fi
fi

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	$SERVER_BIN $SERVER_ARGS $@ >> $LOG_FILE 2>&1
}

if [ "$ROLE" = "server" ]; then
	echo "Starting server ($TESTCASE)"
	run_server
fi
