REQUESTS="https://server4:443/sample.txt"
SERVER_HOST=$(echo ${REQUESTS} | sed -re 's|^https://([^/:]+)(:[0-9]+)?/.*$|\1|')
SERVER_PORT=$(echo ${REQUESTS} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')

CLIENT_BIN="/picoquic/picoquicdemo"
LOG_FILE="/dev/null"
if [ -n "$QLOGDIR" ]; then
	LOG_FILE="$(dirname "$QLOGDIR")/client.log"
	LOG_ARGS="$LOG_ARGS -L -l $LOG_FILE -q $QLOGDIR"
fi
### reno, cubic, bbr or fast. Defaults to bbr.
CLIENT_CC_ARGS="-G bbr"
CLIENT_ARGS="$LOG_ARGS -V -0 $CLIENT_CC_ARGS"

if [ "$TESTCASE" == "http3" ]; then
	CLIENT_ARGS="$CLIENT_ARGS -a h3";
else
	CLIENT_ARGS="$CLIENT_ARGS -a hq-interop";
fi
if [ "$TESTCASE" == "versionnegotiation" ]; then
	CLIENT_ARGS="$CLIENT_ARGS -v 5a6a7a8a";
else
	CLIENT_ARGS="$CLIENT_ARGS -v 00000001";
fi
if [ "$TESTCASE" == "chacha20" ]; then
	CLIENT_ARGS="$CLIENT_ARGS -C 20";
fi
if [ "$TESTCASE" == "keyupdate" ]; then
	CLIENT_ARGS="$CLIENT_ARGS -u 32";
fi
if [ "$CLIENT_ARGS" == "v2" ]; then
	CLIENT_ARGS="$CLIENT_ARGS -U 6b3343cf";
fi

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

run_client() {
	echo "$CLIENT_BIN $CLIENT_ARGS $@"
	$CLIENT_BIN $CLIENT_ARGS $@ >> $LOG_FILE 2>&1
}

if [ "$ROLE" == "client" ]; then
	sleep 2
	REQS=($REQUESTS)
	for REQ in $REQUESTS; do
		FILE=`echo $REQ | cut -f4 -d'/'`
		FILELIST=${FILELIST}"-:/"${FILE}";"
	done

	if [ "$TESTCASE" == "zerortt" ] ; then
		FILE1=`echo $FILELIST | cut -f1 -d";"`
		FILE2=$FILE1
		rm *.bin
		run_client $SERVER_HOST $SERVER_PORT $FILE1
		if [ $? != 0 ]; then
			RET=1
			echo "First call to picoquicdemo failed"
		else
			echo "Session file generated, resuming session"
			run_client $SERVER_HOST $SERVER_PORT $FILE2
			if [ $? != 0 ]; then
				RET=1
				echo "Second call to picoquicdemo failed"
			fi
		fi
	else
		run_client $SERVER_HOST $SERVER_PORT $FILELIST
		if [ $? != 0 ]; then
			RET=1
			echo "Call to picoquicdemo failed"
		fi
	fi
	
	sleep 5
	echo "Client stopped"
fi

exit $RET
