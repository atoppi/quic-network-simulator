#!/bin/bash
chmod +x start.sh

cd .

echo "Ciao, questo è un testbed automatizzato per QUIC implementation."
echo -n "Quale test vuoi eseguire? ([h]andshake, [z]erortt): "
read -r TESTCASE

declare -a IMPLEMETATION=(aioquic picoquic quiche lsquic ngtcp2)
case $TESTCASE in
   "handshake"|"h")
      TESTCASE="handshake"
      ;;
   "zerortt"|"z")
      TESTCASE="zerortt"
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
      echo -n "Setta il target bandwidth (specificato in Mbps): "
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

echo -n "Dimensione del file da scambiare tra client e server (in bytes): "
read -r DIM_FILE

echo
echo "--------------------------------------------------------"
echo "Testcase: $TESTCASE"
echo "Implementazioni attive: ${IMPLEMETATION[*]}"
echo "Dimensione file da scambiare: ${DIM_FILE} bytes"


case $IPERF_ACTIVATION in
   "y")
      echo "Iperf: attivo ("$IPERF_BAND"Mbps)"
      ;;
   "n")
      echo "Iperf: non attivo"
      ;;
esac

echo "Scenario: ritardo "$DELAY"ms | banda "$BANDWIDTH"Mbps | coda "$QUEUE""
echo "--------------------------------------------------------"
echo

echo -n "Vuoi avviare il testbed? (y/n): "
read -r RISPOSTA

SCENARIO="simple-p2p --delay="$DELAY"ms --bandwidth="$BANDWIDTH"Mbps --queue="$QUEUE""

case $RISPOSTA in
   "y")
      mkdir -p ./www
      #dd if=/dev/urandom of=./www/sample.txt bs=1 count=$DIM_FILE
      openssl rand -out ./www/sample.txt $DIM_FILE
      for impl in "${IMPLEMETATION[@]}" 
      do
         echo
         echo "---------------------------------------------"
         echo "Testing implementazione $impl con $TESTCASE"
         echo "---------------------------------------------"
         echo

         echo "Building dell'immagine di $impl per i QUIC endpoint"
         CLIENT=$impl CLIENT_PARAMS="" SERVER=$impl SERVER_PARAMS="" TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" \
         IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO \
         docker-compose build
         
         for iter in {1..3} 
         do
            echo "Avvio dello stack per il testing di $impl ----- Iterazione numero $iter"
            CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/qlog/" SSLKEYLOGFILE="/logs/sslkeylogfile" \
            IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO \
            docker-compose up --abort-on-container-exit 2>/dev/null

            PCAP_FOLDER="./logs/captures/$impl/$TESTCASE"

            echo "Salvataggio risultati cattura... (directory risultati: $PCAP_FOLDER)"
            mkdir -p $PCAP_FOLDER 2>/dev/null
            
               case $IPERF_ACTIVATION in
                  "y")
                  cp -r ./logs/sim/trace_node_left.pcap $PCAP_FOLDER/client_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_iperf_"$IPERF_BAND".pcap
                  cp -r ./logs/sim/trace_node_right.pcap $PCAP_FOLDER/server_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_iperf_"$IPERF_BAND".pcap
                  ;;
                  "n")
                  cp -r ./logs/sim/trace_node_left.pcap $PCAP_FOLDER/client_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue.pcap
                  cp -r ./logs/sim/trace_node_right.pcap $PCAP_FOLDER/server_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue.pcap
                  ;;
                  *)
                  exit 0
                  ;;
               esac
            cd .
         done

         CLIENT_FOLDER="./logs/client/$impl"
         SERVER_FOLDER="./logs/server/$impl"

         case $IPERF_ACTIVATION in
            "y")
               mv $CLIENT_FOLDER/qlog/ $CLIENT_FOLDER/qlog_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_iperf_"$IPERF_BAND"
               mv $SERVER_FOLDER/qlog/ $SERVER_FOLDER/qlog_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue_iperf_"$IPERF_BAND"
               ;;
            "n")
               mv $CLIENT_FOLDER/qlog/ $CLIENT_FOLDER/qlog_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue
               mv $SERVER_FOLDER/qlog/ $SERVER_FOLDER/qlog_"$DELAY"ms_"$BANDWIDTH"Mbps_"$QUEUE"queue
               ;;
            *)
               exit 0
               ;;
         esac
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
