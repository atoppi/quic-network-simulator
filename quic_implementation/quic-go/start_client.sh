REQUESTS="https://server4:443/sample.txt"
SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

CLIENT_BIN="./client"
LOG_FILE="/dev/null"
QUIC_GO_LOG_LEVEL=""
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/client.log"
	QUIC_GO_LOG_LEVEL="debug"
else
	QLOGDIR=""
fi
CLIENT_ARGS=""

run_client() {
	echo "$CLIENT_BIN $CLIENT_ARGS $@"
	QUIC_GO_LOG_LEVEL=$QUIC_GO_LOG_LEVEL $CLIENT_BIN $CLIENT_ARGS $@ > $LOG_FILE 2>&1
}

sleep 2
case "$TESTCASE" in
"zerortt")
	REQUESTS=($REQUESTS $REQUESTS)
	run_client $REQUESTS
	;;
*)
	run_client $REQUESTS
	;;
esac

sleep 5
echo "Client stopped"
