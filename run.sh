#!/bin/bash

echo "Ciao, questo è un testbed automatizzato per QUIC implementation."
echo -n "Quale test vuoi eseguire? (handshake, zerortt): "
read -r TESTCASE

echo -n "Confermi? (y/n): "
read -r RISPOSTA

declare -a IMPLEMETATION=(ngtcp2 aioquic)

case $RISPOSTA in
   "y")
      for impl in "${IMPLEMETATION[@]}"
      do
        echo "Testing implementazione $impl con $TESTCASE"
        
        echo "Building dell'immagine dei QUIC endpoint"
        CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" IPERF_CONGESTION=cubic \
        docker-compose build
        
        echo "Avvio dello stack per il testing"
        CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" IPERF_CONGESTION=cubic \
        SCENARIO="simple-p2p --delay=15ms --bandwidth=5Mbps --queue=25" \
        docker-compose up --abort-on-container-exit 2>/dev/null

        echo "Salvataggio risultati cattura... (directory risultati: /logs/)"
        mkdir "./logs/captures/$impl" 2>/dev/null
        mkdir "./logs/captures/$impl/$TESTCASE" 2>/dev/null
        cp -r ./logs/sim/trace_node_left.pcap ./logs/captures/$impl/$TESTCASE/cattura_client_"$TESTCASE"_$(date "+%s").pcap
        cp -r ./logs/sim/trace_node_right.pcap ./logs/captures/$impl/$TESTCASE/cattura_server_"$TESTCASE"_$(date "+%s").pcap
      done

      ;;
   "n")
      echo "Arrivederci"
      exit 0
      ;;
   *)
     exit 0
     ;;
esac