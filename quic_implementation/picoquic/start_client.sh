# Set up the routing needed for the simulation.

trap "exit" SIGINT SIGTERM

# The following variables are available for use:
# - ROLE contains the role of this execution context, client or server
# - SERVER_PARAMS contains user-supplied command line parameters
# - CLIENT_PARAMS contains user-supplied command line parameters

RET=0
# Verify that the test case is supported 
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

# setup default parameters
mkdir ./downloads
LOGFILE="/logs/test_log.txt"
TEST_PARAMS="$CLIENT_PARAMS -L -l $LOGFILE -o ./downloads -V -0"
if [ -n "$QLOGDIR" ]; then
    TEST_PARAMS="$TEST_PARAMS -q $QLOGDIR"
fi

if [ "$TESTCASE" == "http3" ]; then
    TEST_PARAMS="$TEST_PARAMS -a h3";
else
    TEST_PARAMS="$TEST_PARAMS -a hq-interop";
fi

if [ "$TESTCASE" == "versionnegotiation" ]; then
    TEST_PARAMS="$TEST_PARAMS -v 5a6a7a8a";
else
    TEST_PARAMS="$TEST_PARAMS -v 00000001";
fi

if [ "$TESTCASE" == "chacha20" ]; then
    TEST_PARAMS="$TEST_PARAMS -C 20";
fi

if [ "$TESTCASE" == "keyupdate" ]; then
    TEST_PARAMS="$TEST_PARAMS -u 32";
fi

if [ "$TESTCASE" == "v2" ]; then
    TEST_PARAMS="$TEST_PARAMS -U 709a50c4";
fi

# network simulator
REQUESTS="https://server4:4000/$DIM_FILE"
REQUESTS2="https://server4:4000/5000000"
SERVER="server"

if [ ! -z "$REQUESTS" ]; then
    # Get the server ID out of the first request
    REQS=($REQUESTS)
    REQ1=${REQS[0]}
    echo "Parsing server name from first request: $REQ1"
    SERVER=$(echo $REQ1 | cut -d/ -f3 | cut -d: -f1)
    echo "Server set to: $SERVER"

    # pull requests out of param
    echo "Requests: " $REQUESTS
    for REQ in $REQUESTS; do
        FILE=`echo $REQ | cut -f4 -d'/'`
        echo "parsing <$REQ> as <$FILE>"
        FILELIST=${FILELIST}"-:/"${FILE}";"
    done

    for REQ in $REQUESTS2; do
        FILE=`echo $REQ | cut -f4 -d'/'`
        echo "parsing <$REQ> as <$FILE>"
        FILELIST2=${FILELIST2}"-:/"${FILE}";"
    done

    if [ "$TESTCASE" == "resumption" ] || [ "$TESTCASE" == "zerortt" ] ; then
        FILE1=`echo $FILELIST | cut -f1 -d";"`
        FILE2=`echo $FILELIST2 | cut -f1- -d";"`
        L1="/logs/first_log.txt"
        L2="/logs/second_log.txt"
        echo "File1: $FILE1"
        echo "File2: $FILE2"
        rm *.bin
        echo "/picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILE1"
        ./picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILE1
        if [ $? != 0 ]; then
            RET=1
            echo "First call to picoquicdemo failed"
        else
            mv $LOGFILE $L1
            echo "/picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILE2"
            ./picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILE2
            if [ $? != 0 ]; then
                RET=1
                echo "Second call to picoquicdemo failed"
            fi
            mv $LOGFILE $L2
        fi
        sleep 15s
        kill 1

    elif [ "$TESTCASE" == "multiconnect" ]; then
        for CREQ in $REQUESTS; do
            CFILE=`echo $CREQ | cut -f4 -d'/'`
            CFILEX="/$CFILE"
            echo "/picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $CFILEX"
            ./picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $CFILEX
            if [ $? != 0 ]; then
                RET=1
                echo "Call to picoquicdemo failed"
            fi
            MCLOG="/logs/mc-$CFILE.txt"
            echo "mv $LOGFILE  $MCLOG"
            mv $LOGFILE $MCLOG
        done
        kill 1

    else
        if [ "$TESTCASE" == "retry" ]; then
            rm *.bin
        fi
        echo "./picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILELIST"
        ./picoquic/picoquicdemo $TEST_PARAMS $SERVER 4000 $FILELIST
        if [ $? != 0 ]; then
            RET=1
            echo "Call to picoquicdemo failed"
        fi
        kill 1
    fi
fi