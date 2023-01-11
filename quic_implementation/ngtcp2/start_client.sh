# Set up the routing needed for the simulation.
/setup.sh

trap "exit" SIGINT SIGTERM

# The following variables are available for use:
# - ROLE contains the role of this execution context, client or server
# - SERVER_PARAMS contains user-supplied command line parameters
# - CLIENT_PARAMS contains user-supplied command line parameters

LOG_PARAMS=""
if [ -n "$QLOGDIR" ]; then
    LOG_PARAMS="$LOG_PARAMS --qlog-dir=$QLOGDIR"
fi

if [ -n "$TESTCASE" ]; then
    # interop runner
    case "$TESTCASE" in
        "chacha20")
            CLIENT_PARAMS="--cipher-suites CHACHA20_POLY1305_SHA256"
            ;;
        "handshake")
            CLIENT_PARAMS=""
            ;;
        "http3")
            ;;
        "multiconnect")
            CLIENT_PARAMS=""
            ;;
        "resumption")
            CLIENT_PARAMS=" --session-ticket session.ticket"
            ;;
        "retry")
            CLIENT_PARAMS=""
            SERVER_PARAMS="--retry"
            ;;
        "transfer")
            CLIENT_PARAMS="--max-data 262144 --max-stream-data 262144"
            ;;
        "zerortt")
            CLIENT_PARAMS="--session-file=session_ticket.txt --tp-file=tp_file.txt"
            ;;
        *)
            exit 127
            ;;
    esac

    if [ "$ROLE" = "server" ]; then
        export STATIC_ROOT=/www
    fi
fi 

# network simulator
REQUESTS="193.167.100.100 4000"

run_client() {
    ./client \
        --show-secret \
        --key=key_client.pem \
        --cert=cert_client.pem \
        $LOG_PARAMS \
        $CLIENT_PARAMS \
        $@ 2>> /logs/stout.log
}

if [ "$ROLE" = "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 30
    echo "Starting client"
    case "$TESTCASE" in
    "multiconnect")
        for req in $REQUESTS; do
            echo $req
            run_client $req
        done
        kill 1
        ;;
    "resumption"|"zerortt")
        echo "Running test $TESTCASE to server $REQUESTS with $CLIENT_PARAMS (1/2)"
        run_client $REQUESTS
        echo "Session file generated. Resuming session (2/2)"
        run_client $REQUESTS
        echo "Test Completed: qlog files in $QLOGDIR | secrets file in $SSLKEYLOGFILE"
        kill 1
        ;;
    *)
        echo "Running test $TESTCASE to server $REQUESTS"
        run_client $REQUESTS
        echo "Test Completed: qlog files in $QLOGDIR | secrets file in $SSLKEYLOGFILE"
        kill 1
        ;;
    esac
fi