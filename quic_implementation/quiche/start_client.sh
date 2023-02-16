#!/bin/bash
set -e

# Set up the routing needed for the simulation
/setup.sh

trap "exit" SIGINT SIGTERM

# The following variables are available for use:
# - ROLE contains the role of this execution context, client or server
# - SERVER_PARAMS contains user-supplied command line parameters
# - CLIENT_PARAMS contains user-supplied command line parameters

QUICHE_DIR=/quiche
WWW_DIR=/www
DOWNLOAD_DIR=/downloads
QUICHE_CLIENT=quiche-client
QUICHE_SERVER=quiche-server
QUICHE_CLIENT_OPT="--no-verify --dump-responses ${DOWNLOAD_DIR} --wire-version 00000001"
QUICHE_SERVER_OPT_COMMON="--listen [::]:4000 --root $WWW_DIR --cert cert.crt --key cert.key --disable-gso"
QUICHE_SERVER_OPT="$QUICHE_SERVER_OPT_COMMON --no-retry "
LOG_DIR=/logs
LOG=$LOG_DIR/log.txt

check_testcase () {
    case $1 in
        handshake | multiconnect | http3 )
            echo "supported"
            ;;

        transfer )
            echo "supported"
            ;;

        chacha20 )
            if [ "$ROLE" == "client" ]; then
                # We don't support selecting a cipher on the client-side.
                echo "unsupported"
                exit 127
            elif [ "$ROLE" == "server" ]; then
                echo "supported"
            fi
            ;;

        resumption )
            echo "supported"
            CLIENT_PARAMS="$CLIENT_PARAMS --session-file=session.bin"
            ;;

        zerortt )
            if [ "$ROLE" == "client" ]; then
                echo "supported"
                CLIENT_PARAMS="$CLIENT_PARAMS --session-file=session.bin --early-data"
            elif [ "$ROLE" == "server" ]; then
                echo "supported"
                SERVER_PARAMS="$SERVER_PARAMS --early-data"
            fi
            ;;

        retry )
            echo "supported"
            QUICHE_SERVER_OPT="$QUICHE_SERVER_OPT_COMMON"
            ;;

        *)
            echo "unsupported"
            exit 127
            ;;

    esac
}

REQUESTS="https://193.167.100.100:4000/sample.txt"
REQUESTS2="https://193.167.100.100:4000/index.html"

run_quiche_client_tests () {
    case $1 in
        multiconnect | resumption | zerortt )
            echo "Running test $TESTCASE to server $REQUESTS with $CLIENT_PARAMS (1/2)"
            $QUICHE_DIR/$QUICHE_CLIENT $QUICHE_CLIENT_OPT \
                $CLIENT_PARAMS $REQUESTS >> $LOG 2>&1
            
            echo "Session file generated. Resuming session (2/2) to server $REQUESTS2 with $CLIENT_PARAMS "
            $QUICHE_DIR/$QUICHE_CLIENT $QUICHE_CLIENT_OPT \
                $CLIENT_PARAMS $REQUESTS2 >> $LOG 2>&1
            
            echo "Test Completed: qlog files in $QLOGDIR | secrets file in $SSLKEYLOGFILE"     
            ;;
        *)
            $QUICHE_DIR/$QUICHE_CLIENT $QUICHE_CLIENT_OPT \
                $CLIENT_PARAMS $REQUESTS >& $LOG
            ;;

    esac


}

# Update config based on test case
check_testcase $TESTCASE

# Create quiche log directory
mkdir -p $LOG_DIR

if [ "$ROLE" == "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 30
    echo "## Starting quiche client..."
    echo "## Client params: $CLIENT_PARAMS"
    echo "## Requests: $REQUESTS"
    echo "## Test case: $TESTCASE"
    run_quiche_client_tests $TESTCASE
fi    

kill 1