
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

mkdir ./www
TEST_PARAMS="$SERVER_PARAMS -w ./www -L -l /logs/server_log.txt"
TEST_PARAMS="$TEST_PARAMS -k ./picoquic/certs/key.pem -c ./picoquic/certs/cert.pem"
TEST_PARAMS="$TEST_PARAMS -q $QLOGDIR" 
TEST_PARAMS="$TEST_PARAMS -p 4000 -V -0"


case "$TESTCASE" in
    "retry") TEST_PARAMS="$TEST_PARAMS -r" ;;
    *) ;;
esac

echo "Starting picoquic server ..."
echo "TEST_PARAMS: $TEST_PARAMS"
./picoquic/picoquicdemo $TEST_PARAMS
if [ $? != 0 ]; then
    RET=1
    echo "Could not start picoquicdemo"
fi
cp /var/crash/* /logs

else
echo "Unexpected role: $ROLE"
RET=1