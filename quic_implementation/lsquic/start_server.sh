#!/bin/bash

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

if [ ! -z "$TESTCASE" ]; then
    case "$TESTCASE" in
        http3)
            VERSIONS='-o version=h3-29 -o version=h3'
            ;;
        v2)
            VERSIONS='-o version=h3-v2 -o version=h3 -Q hq-interop'
            ;;
        handshake|transfer|longrtt|resumption|blackhole|multiconnect|chacha20|zerortt)
            VERSIONS='-o version=h3-29 -o version=h3 -o scid_iss_rate=0 -o handshake_to=15000000 -Q hq-interop'
            ;;
        retry)
            VERSIONS='-o version=h3-29 -o version=h3 -o srej=1 -Q hq-interop'
            FORCE_RETRY=1
            ;;
        ecn)
            VERSIONS='-o version=h3-29 -o version=h3 -Q hq-interop'
            ECN='-o ecn=1'
            ;;
        *) exit 127 ;;
    esac
fi
echo SERVER_PARAMS: LSQUIC_FORCE_RETRY=$FORCE_RETRY $VERSIONS $ECN
LSQUIC_FORCE_RETRY=$FORCE_RETRY ./http_server $VERSIONS $ECN \
    -c server,/certs/cert.pem,/certs/priv.key \
    -c server4,/certs/cert.pem,/certs/priv.key \
    -s 193.167.100.100:4000 \
    -r /www -L debug 2>/logs/server_log.out
