#!/bin/bash

# Set up the routing needed for the simulation
/setup.sh

REQUESTS="https://server4:443/sample.txt"

logDownloads() {
    echo "Downloaded files:"
    ls -l /downloads
}

if [ "$ROLE" == "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 30

    if [ "$TESTCASE" == "versionnegotiation" ]; then
        echo "running kwik"
        java -jar kwik.jar -l n --reservedVersion $REQUESTS
        exit 0
    elif [ "$TESTCASE" == "handshake" ]; then
        echo "running kwik with $REQUESTS"
        java -jar kwik.jar -v
        java -ea -jar kwik.jar -v1 -A hq-interop --noCertificateCheck -l wi -O /downloads $REQUESTS
    elif [ "$TESTCASE" == "retry" ]; then
        java -ea -jar kwik.jar -v1 -A hq-interop --noCertificateCheck -l wip -O /downloads $REQUESTS
    elif [ "$TESTCASE" == "resumption" ]; then
        java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads resumption $REQUESTS
    elif [ "$TESTCASE" == "transfer" ]; then
        java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads transfer $REQUESTS
    elif [ "$TESTCASE" == "multiconnect" ]; then
        java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads multiconnect $REQUESTS
    elif [ "$TESTCASE" == "http3" ]; then
        java -ea -cp flupke.jar net.luminis.http3.sample.AsyncHttp3 --disableCertificateCheck /downloads $REQUESTS
    elif [ "$TESTCASE" == "zerortt" ]; then
        java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads zerortt $REQUESTS
    elif [ "$TESTCASE" == "chacha20" ]; then
        java -ea -jar kwik.jar -v1 -A hq-interop --chacha20 --noCertificateCheck -l wip -L /logs/kwik_client.log -O /downloads $REQUESTS
    elif [ "$TESTCASE" == "keyupdate" ]; then
        java -ea -cp kwik.jar net.luminis.quic.run.InteropRunner /downloads keyupdate $REQUESTS
    elif [ "$TESTCASE" == "v2" ]; then
	java -ea -jar kwik.jar -v1v2 -A hq-interop --noCertificateCheck --secrets $SSLKEYLOGFILE -l wip -O /downloads $REQUESTS
    else
        echo "Unsupported testcase: ${TESTCASE}"
        exit 127
    fi
elif [ "$ROLE" == "server" ]; then
    if [ "$TESTCASE" == "handshake" ]; then
        echo "running kwik server version " `java -jar kwik.jar -v`
        java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www
    elif [[ "$TESTCASE" == "transfer" || "$TESTCASE" == "multiconnect" || "$TESTCASE" == "resumption" || "$TESTCASE" == "zerortt" || "$TESTCASE" == "chacha20" ]]; then
        java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www
    elif [ "$TESTCASE" == "retry" ]; then
        java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer /certs/cert.pem /certs/priv.key 443 /www
    elif [ "$TESTCASE" == "http3" ]; then
        java -Duser.language=en -Duser.country=US -cp kwik.jar:flupke-plugin.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www
    elif [ "$TESTCASE" == "v2" ]; then
        java -Duser.language=en -Duser.country=US -cp kwik.jar -ea net.luminis.quic.run.InteropServer --noRetry /certs/cert.pem /certs/priv.key 443 /www
    else
        echo "Unsupported testcase: ${TESTCASE}"
        exit 127
    fi
fi