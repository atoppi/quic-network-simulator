#!/bin/bash

echo "Ciao, questo è un testbed automatizzato per QUIC implementation."
echo -n "Quale test vuoi eseguire? (handshake, zerortt): "
read -r TESTCASE

declare -a IMPLEMETATION=(picoquic aioquic quiche)
case $TESTCASE in
   "handshake")
      ;;
   "zerortt")
      ;;
   *)
     echo "Scelta non valida..."
     exit 0
     ;;
esac

echo -n "Vuoi attivare iperf per la congestione della rete? (y/n): "
read -r IPERF_ACTIVATION

case $IPERF_ACTIVATION in
   "y")
      echo -n "Setta il target bandwidth (specificato in Mbits/s): "
      read -r IPERF_BAND
      ;;
   "n")
      ;;
   *)
     echo "Risposta non valida..."
     exit 0
     ;;
esac

echo "Inserisci i parametri dello scenario"

echo -n "Delay (in ms): "
read -r DELAY

echo -n "Larghezza di banda (in Mbps): "
read -r BANDWIDTH

echo -n "Dimensione delle code (in numero di pacchetti): "
read -r QUEUE

echo
echo "----------------RIEPILOGO----------------"
echo "Testcase: $TESTCASE"
echo "Implementazioni attive nel testbed: $IMPLEMENTATION"

case $IPERF_ACTIVATION in
   "y")
      echo "Iperf attivo con "$IPERF_BAND"Mbps/s di target bandwidth"
      ;;
   "n")
      echo "Iperf non attivo"
      ;;
esac

echo "Scenario: ritardo "$DELAY"ms | banda "$BANDWIDTH"Mbps | "$QUEUE" dimensione code buffer"

echo -n "Vuoi avviare il testbed? (y/n): "
read -r RISPOSTA

declare SCENARIO="simple-p2p --delay="$DELAY"ms --bandwidth="$BANDWIDTH"Mbps --queue="$QUEUE""

case $RISPOSTA in
   "y")
      for impl in "${IMPLEMETATION[@]}" 
      do
         echo "Testing implementazione $impl con $TESTCASE"
         
         echo "Building dell'immagine dei QUIC endpoint"
         CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" \
         IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND docker-compose build
         
         echo "Avvio dello stack per il testing"
         CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" \
         IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND  \
         SCENARIO=$SCENARIO \
         docker-compose up --abort-on-container-exit 2>/dev/null

         echo "Salvataggio risultati cattura... (directory risultati: /logs/)"
         mkdir "./logs/captures/$impl" 2>/dev/null
         mkdir "./logs/captures/$impl/$TESTCASE" 2>/dev/null
         
            case $IPERF_ACTIVATION in
                "y")
                cp -r ./logs/sim/trace_node_left.pcap ./logs/captures/$impl/$TESTCASE/client_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_$(date "+%s")_iperf_"$IPERF_BAND".pcap
                cp -r ./logs/sim/trace_node_right.pcap ./logs/captures/$impl/$TESTCASE/server_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_$(date "+%s")_iperf_"$IPERF_BAND".pcap
                ;;
                "n")
                cp -r ./logs/sim/trace_node_left.pcap ./logs/captures/$impl/$TESTCASE/client_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_$(date "+%s").pcap
                cp -r ./logs/sim/trace_node_right.pcap ./logs/captures/$impl/$TESTCASE/server_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_$(date "+%s").pcap
                ;;
                *)
                exit 0
                ;;
            esac
      cd .
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