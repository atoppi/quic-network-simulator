SERVER_PORT=443

SERVER_BIN="/picoquic/picoquicdemo"
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/server.log"
	LOG_ARGS="$LOG_ARGS -L -l $LOG_FILE -q $QLOGDIR"
fi
### reno, cubic, bbr or fast. Defaults to bbr.
SERVER_CC_ARGS="-G bbr"
SERVER_ARGS="$LOG_ARGS -w /www -k /certs/cert.key -c /certs/cert.crt -p $SERVER_PORT -V -0 $SERVER_CC_ARGS"

case "$TESTCASE" in
	"retry") SERVER_ARGS="$SERVER_ARGS -r" ;;
	*) ;;
esac

RET=0

case "$TESTCASE" in
	"versionnegotiation") RET=0 ;;
	"handshake") RET=0 ;;
	"transfer") RET=0 ;;
	"retry") RET=0 ;;
	"resumption") RET=0 ;;
	"zerortt") RET=0 ;;
	"http3") RET=0 ;;
	"multiconnect") RET=0 ;;
	"chacha20") RET=0 ;;
	"ecn") RET=0;;
	"keyupdate") RET=0;;
	"v2") RET=0;;
	*) echo "Unsupported test case: $TESTCASE"; exit 127 ;;
esac

run_server() {
	echo "$SERVER_BIN $SERVER_ARGS $@"
	$SERVER_BIN $SERVER_ARGS $@ >> $LOG_FILE 2>&1
	echo $?
}

run_server
if [ $? != 0 ]; then
	RET=1
	echo "Could not start picoquicdemo"
fi

exit $RET
