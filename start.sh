#!/bin/bash

trap "docker compose down > /dev/null 2>&1" EXIT

declare -a IMPLEMETATION=(aioquic ngtcp2 picoquic quic-go)

DEFAULT_TESTCASE=transfer
DEFAULT_IPERF_ACTIVATION=n
DEFAULT_IPERF_BAND=5
DEFAULT_DELAY=20
DEFAULT_BANDWIDTH=10
DEFAULT_LOSS=0
DEFAULT_QUEUE=25
DEFAULT_CODEL_ENABLE=n
DEFAULT_CODEL_TARGET=21
DEFAULT_CODEL_INTERVAL=310
DEFAULT_DIM_FILE=10M
DEFAULT_LOG_ENABLE=y

print_summary() {
    echo
    echo "--------------------------------------------------------"
    printf "%-12s %s %-12s\n" "Testcase" ":" "${TESTCASE}"
    printf "%-12s %s %-12s\n" "Stacks" ":" "${IMPLEMETATION[*]}"
    printf "%-12s %s %-12s\n" "Delay" ":" "${DELAY} ms"
    printf "%-12s %s %-12s\n" "Bandwidth" ":" "${BANDWIDTH} Mbps"
    printf "%-12s %s %-12s\n" "Pkt Loss" ":" "${LOSS} %"
    printf "%-12s %s %-12s\n" "Queue Size" ":" "${QUEUE} pkts"
    case $CODEL_ENABLE in
        "y")
            printf "%-12s %s %-12s\n" "CoDel queue" ":" "enabled"
            printf "%-12s %s %-12s\n" "CoDel target" ":" "${CODEL_TARGET} ms"
            printf "%-12s %s %-12s\n" "CoDel interval" ":" "${CODEL_INTERVAL} ms"
            ;;
        "n")
            printf "%-12s %s %-12s\n" "CoDel queue" ":" "disabled"
            ;;
    esac
    printf "%-12s %s %-12s\n" "File Size" ":" "${DIM_FILE} bytes"
    case $IPERF_ACTIVATION in
        "y")
            printf "%-12s %s %-12s\n" "Iperf" ":" "enabled ($IPERF_BAND Mbps)"
            ;;
        "n")
            printf "%-12s %s %-12s\n" "Iperf" ":" "disabled"
            ;;
    esac
    case $LOG_ENABLE in
        "y")
            printf "%-12s %s %-12s\n" "Logging" ":" "enabled"
            ;;
        "n")
            printf "%-12s %s %-12s\n" "Logging" ":" "disabled"
            ;;
    esac
    echo "--------------------------------------------------------"
    echo
}

print_results() {
    echo
    echo "---------------------------------------------"
    echo "                   Results                   "
    echo "---------------------------------------------"
    echo
    ROWS=("$@")
    printf "%-10s %-10s %-10s %-10s\n" "" "loss" "avg rtt" "avg rate"
    for row in ${ROWS[@]}
    do
         IFS=';' read IMPL LOSS RTT THR <<< "${row}"
         printf "%-10s %-10s %-10s %-10s\n" $IMPL $LOSS $RTT $THR
    done
}

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
    "y"|"Y"|"yes")
        IPERF_ACTIVATION=y
        echo -n "Set cross traffic bandwidth [Mbps] (default=$DEFAULT_IPERF_BAND): "
        read -r IPERF_BAND
        IPERF_BAND=${IPERF_BAND:-$DEFAULT_IPERF_BAND}
        ;;
    "n"|"N"|"no")
        IPERF_ACTIVATION=n
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

echo -n "Enable CoDel queue [y/n] (default=$DEFAULT_CODEL_ENABLE): "
read -r CODEL_ENABLE
CODEL_ENABLE=${CODEL_ENABLE:-$DEFAULT_CODEL_ENABLE}
case $CODEL_ENABLE in
    "y"|"Y"|"yes")
        CODEL_ENABLE=y
        echo -n "Set CoDel target [ms] (default=$DEFAULT_CODEL_TARGET): "
        read -r CODEL_TARGET
        CODEL_TARGET=${CODEL_TARGET:-$DEFAULT_CODEL_TARGET}
        echo -n "Set CoDel delay [ms] (default=$DEFAULT_CODEL_INTERVAL): "
        read -r CODEL_INTERVAL
        CODEL_INTERVAL=${CODEL_INTERVAL:-$DEFAULT_CODEL_INTERVAL}
        CODEL_SCENARIO="--use_codel --codel_target=$CODEL_TARGET --codel_interval=$CODEL_INTERVAL"
        ;;
    "n"|"N"|"no")
        CODEL_ENABLE=n
        ;;
    *)
        echo "Invalid response"
        exit 0
        ;;
esac

echo -n "File to be transfered size [bytes] (default=$DEFAULT_DIM_FILE): "
read -r DIM_FILE
DIM_FILE=${DIM_FILE:-$DEFAULT_DIM_FILE}
DIM_FILE=$(numfmt --from=auto $DIM_FILE)

echo -n "Enable logging (including qlogs) [y/n]: (default=$DEFAULT_LOG_ENABLE): "
read -r LOG_ENABLE
LOG_ENABLE=${LOG_ENABLE:-$DEFAULT_LOG_ENABLE}
case $LOG_ENABLE in
    "y"|"Y"|"yes")
        LOG_ENABLE=y
        ;;
    "n"|"N"|"no")
        LOG_ENABLE=n
        ;;
    *)
        echo "Invalid response"
        exit 0
        ;;
esac

print_summary

echo -n "Do you want to start the testbed? [y/n]: "
read -r START
START=${START:-n}

case $START in
    "y"|"yes")
        # Generate a random file to be tranfered (this is needed for some QUIC stacks)
        mkdir -p ./www
        openssl rand -out ./www/sample.txt $DIM_FILE
        SCENARIO="drop-rate --delay=${DELAY}ms --bandwidth_to_client=${BANDWIDTH}Mbps --bandwidth_to_server=${BANDWIDTH}Mbps --queue=${QUEUE} --rate_to_client=${LOSS} --rate_to_server=${LOSS} $CODEL_SCENARIO"
        RES=()
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
            if [ $LOG_ENABLE == "y" ]; then
                QLOGDIR="/logs/$OUTPUT_FOLDER_NAME/qlog"
            else
                QLOGDIR=""
            fi

            echo "Building images"
            CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR=$QLOGDIR SSLKEYLOGFILE="/logs/$OUTPUT_FOLDER_NAME/sslkeylogfile" \
                IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND \
                DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $IPERF_PROFILE build

            echo "Starting containers"
            CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR=$QLOGDIR SSLKEYLOGFILE="/logs/$OUTPUT_FOLDER_NAME/sslkeylogfile" \
                IPERF_ACTIVATION=$IPERF_ACTIVATION IPERF_BAND=$IPERF_BAND \
                DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $IPERF_PROFILE up --abort-on-container-exit

            echo "Saving packet captures"
            cp ./logs/sim/trace_node_left.pcap "$CLIENT_OUTPUT_FOLDER/client.pcap"
            cp ./logs/sim/trace_node_right.pcap "$SERVER_OUTPUT_FOLDER/server.pcap"

            OUT=$(python3 extra/get_stats.py $CLIENT_OUTPUT_FOLDER $SERVER_OUTPUT_FOLDER)
            RES+=("$impl;$OUT")
            echo
            echo "---------------------------------------------"
            echo ">>> Completed test: $impl"
            echo "---------------------------------------------"
            echo
        done
        print_results "${RES[@]}"
        ;;
    *)
        echo "Goodbye!"
        exit 0
        ;;
esac
