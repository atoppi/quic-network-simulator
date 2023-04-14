# Set up the routing needed for the simulation.
/setup.sh

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
            CLIENT_PARAMS="--session-ticket session.ticket --zero-rtt"
            ;;
        *)
            exit 127
            ;;
    esac

    if [ "$ROLE" = "server" ]; then
        export STATIC_ROOT=/www
    fi
else
    # network simulator
    REQUESTS="https://193.167.100.100:4000/"
fi

if [ "$ROLE" = "server" ]; then
    echo "Starting server active on $(hostname -I | cut -f1 -d" "):4000"
    echo "QLOG DIR: $QLOGDIR"
    echo "SSL FILE: $SSLKEYLOGFILE"
    echo "ROOT DIR: /www"

    ./server $(hostname -I | cut -f1 -d" ") 4000 \
        cert.key \
        cert.crt \
        --show-secret \
        --verify-client \
        -d /www \
        $LOG_PARAMS \
        $SERVER_PARAMS 2>> /logs/stout.log
fi

/bin/bash
