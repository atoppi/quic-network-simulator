REQUESTS="https://server4:443/sample.txt"
LOG_FILE="client.log"

if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")"/$LOG_FILE
fi

CLIENT_BIN="./client"
CLIENT_ARGS=""

run_client() {
	echo "$CLIENT_BIN $CLIENT_ARGS $@"
	QUIC_GO_LOG_LEVEL=debug $CLIENT_BIN $CLIENT_ARGS $@ > $LOG_FILE 2>&1
}

if [ "$ROLE" = "client" ]; then
	# Wait for the simulator to start up.
	/wait-for-it.sh sim:57832 -s -t 30
	sleep 5

	case "$TESTCASE" in
	"zerortt")
		REQUESTS=("https://server4:443/sample.txt" "https://server4:443/sample.txt")
		run_client $REQUESTS
		;;
	*)
		run_client $REQUESTS
		;;
	esac

	sleep 5
	echo "Client stopped"
fi
