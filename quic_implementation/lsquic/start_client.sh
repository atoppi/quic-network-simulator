#!/bin/bash

trap "exit" SIGINT SIGTERM

export REQUESTS="https://193.167.100.100:4000/sample.txt"

eval $(perl <<'PERL'
    @paths = split /\s+/, $ENV{REQUESTS};
    s~^https?://[^/]+~-p ~ for @paths;
    print "PATHS='@paths'\n";
    $server = $ENV{REQUESTS};
    $server =~ s~^https?://~~;
    $server =~ s~/.*~~;
    ($server, $port) = split /:/, $server;
    print "SERVER=$server\n";
    print "PORT=$port\n";
    print "N_REQS=", scalar(@paths), "\n";
    print "N_reqs=", scalar(@paths), "\n";
    if (@paths > 100) {
        print "W=100\n";
    } else {
        print "W=1\n";
    }
PERL
)
echo paths: $PATHS
echo server: $SERVER
echo port: $PORT

function maybe_create_keylog() {
    local NAME=/logs/keys.log
    if ls /logs/*.keys; then
        # There may be more than one of these, as one file is created per
        # connection.
        cat /logs/*.keys > $NAME
    fi
    if [ -f $NAME ]; then
        echo $NAME exists
    else
        echo $NAME does not exit
    fi
}

if [ ! -z "$TESTCASE" ]; then
    case "$TESTCASE" in
        http3)
            VERSIONS='-o version=h3'
            ;;
        v2)
            VERSIONS='-o version=h3-v2 -o version=h3 -Q hq-interop'
            ;;
        handshake|transfer|longrtt|retry|multiplexing|blackhole)
            VERSIONS='-o version=h3 -Q hq-interop'
            ;;
        multiconnect)
            VERSIONS='-o version=h3 -Q hq-interop'
            N_REQS=1
            ;;
        ecn)
            VERSIONS='-o version=h3 -Q hq-interop'
            ECN='-o ecn=1'
            ;;
        resumption)
            VERSIONS='-o version=h3 -Q hq-interop'
            RESUME='-0 /logs/resume.file'
            ;;
        *) exit 127 ;;
    esac
fi
if [ "$TESTCASE" = resumption ]; then
    # Fetch first file:
    ./http_client $VERSIONS -s $SERVER:$PORT $PATHS \
        -r 1 -R 1 $RESUME \
    -o scid_iss_rate=0 \
        -B -7 /downloads -G /logs \
        -L debug 2>/logs/client_log-req1.out || exit $?
    PATHS=`echo "$PATHS" | sed 's~-p /[^ ]* ~~'`
    N_REQS=1
    N_reqs=1
    W=1
    echo "first request successful, new args: $N_REQS; $N_reqs; $PATHS"
fi
./http_client $VERSIONS -s $SERVER:$PORT $PATHS -H server\
    -r $N_reqs -R $N_REQS -w $W $ECN $RESUME \
    -o scid_iss_rate=0 \
    -B -7 /downloads -G /logs \
    -L debug 2>/logs/$TESTCASE.out
EXIT_CODE=$?
maybe_create_keylog
sync
echo $EXIT_CODE
kill 1