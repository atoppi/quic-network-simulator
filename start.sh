#!/bin/bash

declare -a IMPLEMETATION=(aioquic ngtcp2 quic-go)

DEFAULT_TESTCASE=transfer
DEFAULT_IPERF_ACTIVATION=n
DEFAULT_IPERF_BAND=5
DEFAULT_DELAY=20
DEFAULT_BANDWIDTH=10
DEFAULT_LOSS=0
DEFAULT_QUEUE=25
DEFAULT_DIM_FILE=10M

echo -n "Please select a testcase ([h]andshake, [z]erortt, [t]ransfer) (default=$DEFAULT_TESTCASE): "
read -r TESTCASE
TESTCASE=${TESTCASE:-$DEFAULT_TESTCASE}

case $TESTCASE in
	"handshake"|"h")
		TESTCASE="handshake"
		;;
	"transfer"|"t")
		TESTCASE="transfer"
		;;
	"zerortt"|"z")
		TESTCASE="zerortt"
		;;
	*)
		echo "Invalid testcase"
		exit 0
		;;
esac

echo -n "Enable iperf for cross traffic [y/n] (default=$DEFAULT_IPERF_ACTIVATION): "
read -r IPERF_ACTIVATION
IPERF_ACTIVATION=${IPERF_ACTIVATION:-$DEFAULT_IPERF_ACTIVATION}

case $IPERF_ACTIVATION in
	"y"|"yes")
		echo -n "Set cross traffic bandwidth [Mbps]: "
		read -r IPERF_BAND
		IPERF_BAND=${IPERF_BAND:-$DEFAULT_IPERF_BAND}
		;;
	"n"|"no")
		;;
	*)
		echo "Invalid response"
		exit 0
		;;
esac

echo -n "Delay [ms] (default=$DEFAULT_DELAY): "
read -r DELAY
DELAY=${DELAY:-$DEFAULT_DELAY}

echo -n "Bandwidth [Mbps] (default=$DEFAULT_BANDWIDTH): "
read -r BANDWIDTH
BANDWIDTH=${BANDWIDTH:-$DEFAULT_BANDWIDTH}

echo -n "Packet loss (integer) [0-100] (default=$DEFAULT_LOSS): "
read -r LOSS
LOSS=${LOSS:-$DEFAULT_LOSS}

echo -n "Queue size [packets] (default=$DEFAULT_QUEUE): "
read -r QUEUE
QUEUE=${QUEUE:-$DEFAULT_QUEUE}

echo -n "File to be transfered size [bytes] (default=$DEFAULT_DIM_FILE): "
read -r DIM_FILE
DIM_FILE=${DIM_FILE:-$DEFAULT_DIM_FILE}
DIM_FILE=$(numfmt --from=auto $DIM_FILE)

echo
echo "--------------------------------------------------------"
echo -e "Testcase:\t ${TESTCASE}"
echo -e "Implementations: ${IMPLEMETATION[*]}"
echo -e "Delay:\t\t ${DELAY} ms"
echo -e "Bandwidth:\t ${BANDWIDTH} Mbps"
echo -e "Loss Rate:\t ${LOSS} %"
echo -e "Queue size:\t ${QUEUE} pkts"
echo -e "Transfer size:\t ${DIM_FILE} bytes"
case $IPERF_ACTIVATION in
	"y"|"yes")
		echo -e "Iperf:\t\t enabled ($IPERF_BAND Mbps)"
		;;
	"n"|"no")
		echo -e "Iperf:\t\t disabled"
		;;
esac
echo "--------------------------------------------------------"
echo

echo -n "Do you want to start the testbed? (y/n): "
read -r START
START=${START:-n}

case $START in
	"y"|"yes")
		# Generate a random file to be tranfered (this is needed for some QUIC stacks)
		mkdir -p ./www
		openssl rand -out ./www/sample.txt $DIM_FILE
		SCENARIO="drop-rate --delay=${DELAY}ms --bandwidth=${BANDWIDTH}Mbps --queue=${QUEUE} --rate_to_client=${LOSS} --rate_to_server=${LOSS}"
		for impl in "${IMPLEMETATION[@]}" 
		do
			echo
			echo "---------------------------------------------"
			echo ">>> Starting test: $impl"
			echo "---------------------------------------------"
			echo

			OUTPUT_FOLDER_NAME="$DELAY"ms_"$BANDWIDTH"Mbps_"$LOSS"loss_"$QUEUE"queue
			IPERF_PROFILE=""
			case $IPERF_ACTIVATION in
				"y"|"yes")
					OUTPUT_FOLDER_NAME=${OUTPUT_FOLDER_NAME}_with"$IPERF_BAND"Miperf
					IPERF_PROFILE="--profile with_iperf"
					;;
				*)
					;;
			esac
			CLIENT_FOLDER="./logs/client/$impl"
			CLIENT_OUTPUT_FOLDER="$CLIENT_FOLDER/$OUTPUT_FOLDER_NAME"
			CLIENT_QLOGS_FOLDER="$CLIENT_OUTPUT_FOLDER/qlog"
			SERVER_FOLDER="./logs/server/$impl"
			SERVER_OUTPUT_FOLDER="$SERVER_FOLDER/$OUTPUT_FOLDER_NAME"
			SERVER_QLOGS_FOLDER="$SERVER_OUTPUT_FOLDER/qlog"

			echo "Creating dir $CLIENT_QLOGS_FOLDER"
			mkdir -p $CLIENT_QLOGS_FOLDER 2>/dev/null
			echo "Creating dir $SERVER_QLOGS_FOLDER"
			mkdir -p $SERVER_QLOGS_FOLDER 2>/dev/null

			echo "Building images"
			CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/$OUTPUT_FOLDER_NAME/qlog" SSLKEYLOGFILE="/logs/$OUTPUT_FOLDER_NAME/sslkeylogfile" \
				IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND \
				DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $IPERF_PROFILE build

			echo "Starting containers"
			CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR="/logs/$OUTPUT_FOLDER_NAME/qlog" SSLKEYLOGFILE="/logs/$OUTPUT_FOLDER_NAME/sslkeylogfile" \
				IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND \
				DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $IPERF_PROFILE up --abort-on-container-exit

			echo "Saving packet captures"
			cp ./logs/sim/trace_node_left.pcap $CLIENT_OUTPUT_FOLDER/client.pcap
			cp ./logs/sim/trace_node_right.pcap $SERVER_OUTPUT_FOLDER/server.pcap

			RES=$(python3 extra/get_stats.py $CLIENT_QLOGS_FOLDER/* $SERVER_QLOGS_FOLDER/*)
			echo
			echo "---------------------------------------------"
			echo ">>> Completed test: $impl"
			echo
			echo "$RES"
			echo "---------------------------------------------"
			echo
		done
		;;
	*)
		echo "Goodbye!"
		exit 0
		;;
esac
