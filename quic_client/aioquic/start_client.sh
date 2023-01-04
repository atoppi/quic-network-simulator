# Set up the routing needed for the simulation.
/setup.sh

# The following variables are available for use:
# - ROLE contains the role of this execution context, client or server
# - SERVER_PARAMS contains user-supplied command line parameters
# - CLIENT_PARAMS contains user-supplied command line parameters

LOG_PARAMS=""
if [ -n "$QLOGDIR" ]; then
    LOG_PARAMS="$LOG_PARAMS --quic-log $QLOGDIR"
fi
if [ -n "$SSLKEYLOGFILE" ]; then
    LOG_PARAMS="$LOG_PARAMS --secrets-log /logs/$SSLKEYLOGFILE"
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
            CLIENT_PARAMS="--session-ticket session.ticket --zero-rtt"
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
REQUESTS="https://193.167.100.100:4000/"

run_client() {
    python3 examples/http3_client.py \
        --ca-certs tests/pycacert.pem \
        --output-dir /downloads \
        --verbose \
        $LOG_PARAMS \
        $CLIENT_PARAMS \
        $@ 1>> /logs/stout.log
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
        ;;
    "resumption"|"zerortt")
        arr=($REQUESTS)
        echo ${arr[0]}
  #      run_client ${arr[0]}
        echo ${arr[@]}
 #       run_client ${arr[@]:1}
        ;;
    *)
        echo "Running test $TESTCASE to server $REQUEST"
        run_client $REQUESTS
        ;;
    esac
fi

/bin/bash
