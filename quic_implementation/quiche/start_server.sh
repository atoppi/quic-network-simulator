#!/bin/bash
set -e

# Set up the routing needed for the simulation
/setup.sh

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

run_quiche_server_tests() {
    $QUICHE_DIR/$QUICHE_SERVER $SERVER_PARAMS $QUICHE_SERVER_OPT >& $LOG
}

# Update config based on test case
check_testcase $TESTCASE

# Create quiche log directory
mkdir -p $LOG_DIR

if [ "$ROLE" == "server" ]; then
    echo "## Starting quiche server on $(hostname -I | cut -f1 -d" "):4000"
    echo "## Server params: $SERVER_PARAMS"
    echo "## QLOG dir: $QLOGDIR"
    echo "## SSL file: $SSLKEYLOGFILE"
    echo "## Test case: $TESTCASE"
    run_quiche_server_tests
fi
