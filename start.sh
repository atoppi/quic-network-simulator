#!/bin/bash

trap "docker compose down > /dev/null 2>&1; exit" SIGINT SIGTERM

export LC_ALL=C.UTF-8

declare -a IMPLEMETATION=(aioquic ngtcp2 picoquic quic-go)

DEFAULT_TESTCASE=transfer
DEFAULT_IPERF_ENABLE=n
DEFAULT_IPERF_NUM=1
DEFAULT_IPERF_WAIT=( 0 10 30 )
DEFAULT_IPERF_NUM=1
DEFAULT_IPERF_BAND=5
DEFAULT_IPERF_TYPE=tcp
DEFAULT_IPERF_CCA=cubic
DEFAULT_DELAY=20
DEFAULT_BANDWIDTH=10
DEFAULT_LOSS=0
DEFAULT_QUEUE_TYPE=fifo
DEFAULT_QUEUE_SIZE=25
DEFAULT_CODEL_TARGET=21
DEFAULT_CODEL_INTERVAL=310
DEFAULT_DIM_FILE=10M
DEFAULT_LOG_ENABLE=y

monitor_node() {
    CONTAINER=$1
    OUT_FILE=$2

    END_TIME=$(( $(date +%s) + 5 ))
    IS_ACTIVE=""

    while [ $(date +%s) -lt $END_TIME ]; do
        IS_ACTIVE=$(docker ps | grep $CONTAINER)
        if [ ! -z "$IS_ACTIVE" ]; then
            break
        else
            sleep 0.5
        fi
    done

    if [ -z "$IS_ACTIVE" ]; then
        exit 1
    else
        echo "curr_time;abs_time_ms;curr_cpu;curr_mem" > "$OUT_FILE"
        docker stats $CONTAINER --format "{{.CPUPerc}};{{.MemPerc}}" | stdbuf -oL cut -c8- | stdbuf -oL sed "s/%//g" |
        while IFS= read -r line; do if [ -z "$START_TIME" ]; then START_TIME=$(date +%s%N) ; CURR_TIME="$START_TIME" ; else CURR_TIME=$(date +%s%N); fi; printf '%.6f;%d;%s\n' "$(( ($CURR_TIME - $START_TIME) ))e-9" "$(( $CURR_TIME / 1000000 ))" "$line"; done >> "$OUT_FILE"
    fi
}

print_summary() {
    echo
    echo "--------------------------------------------------------"
    printf "%-25s %s %-12s\n" "Testcase" ":" "${TESTCASE}"
    printf "%-25s %s %-12s\n" "Stacks" ":" "${IMPLEMETATION[*]}"
    printf "%-25s %s %-12s\n" "Link delay" ":" "${DELAY} ms"
    printf "%-25s %s %-12s\n" "Bandwidth (toward client)" ":" "${BANDWIDTH_TO_CLIENT} Mbps"
    printf "%-25s %s %-12s\n" "Bandwidth (toward server)" ":" "${BANDWIDTH_TO_SERVER} Mbps"
    printf "%-25s %s %-12s\n" "Pkt Loss (toward client)" ":" "${LOSS_TO_CLIENT} per thousand"
    printf "%-25s %s %-12s\n" "Pkt Loss (toward server)" ":" "${LOSS_TO_SERVER} per thousand"
    printf "%-25s %s %-12s\n" "Queue type" ":" "$QUEUE_TYPE"
    case $QUEUE_TYPE in
        "codel")
            printf "%-25s %s %-12s\n" "codel target" ":" "${CODEL_TARGET} ms"
            printf "%-25s %s %-12s\n" "codel interval" ":" "${CODEL_INTERVAL} ms"
            ;;
        esac
    printf "%-25s %s %-12s\n" "Queue Size" ":" "${QUEUE_SIZE} pkts"
    printf "%-25s %s %-12s\n" "File Size" ":" "${DIM_FILE} bytes"
    case $IPERF_ENABLE in
        "y")
            printf "%-25s %s %-12s\n" "Iperf" ":" "enabled ($IPERF_NUM x $IPERF_BAND Mbps, $IPERF_TYPE/$IPERF_CCA, delays: $IPERF_WAITS)"
            ;;
        "n")
            printf "%-25s %s %-12s\n" "Iperf" ":" "disabled"
            ;;
    esac
    case $LOG_ENABLE in
        "y")
            printf "%-25s %s %-12s\n" "Logging" ":" "enabled"
            ;;
        "n")
            printf "%-25s %s %-12s\n" "Logging" ":" "disabled"
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
    printf "%-10s %-10s %-10s %-10s\n" "" "loss%" "avg rtt" "avg rate"
    for row in ${ROWS[@]}
    do
         IFS=';' read IMPL LOSS RTT THR <<< "${row}"
         printf "%-10s %-10.2f %-10.2f %-10.2f\n" $IMPL $LOSS $RTT $THR
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

echo -n "Enable iperf for cross traffic (y, n) (default=$DEFAULT_IPERF_ENABLE): "
read -r IPERF_ENABLE
IPERF_ENABLE=${IPERF_ENABLE:-$DEFAULT_IPERF_ENABLE}
case $IPERF_ENABLE in
    "y"|"Y")
        IPERF_ENABLE=y
        echo -n "Set iperf transport ([t]cp, [u]dp) (default=$DEFAULT_IPERF_TYPE): "
        read -r IPERF_TYPE
        IPERF_TYPE=${IPERF_TYPE:-$DEFAULT_IPERF_TYPE}
        case $IPERF_TYPE in
            "t"|"T"|"tcp")
                IPERF_TYPE="tcp"
                IPERF_CCA=$DEFAULT_IPERF_CCA
                ;;
            "u"|"U"|"udp")
                IPERF_TYPE="udp"
                IPERF_CCA=""
                ;;
            *)
                echo "Invalid iperf type"
                exit 0
            ;;
        esac
        echo -n "Set cross traffic bandwidth [Mbps] (default=$DEFAULT_IPERF_BAND): "
        read -r IPERF_BAND
        IPERF_BAND=${IPERF_BAND:-$DEFAULT_IPERF_BAND}
        echo -n "Set number of iperf instances to start (1,2,3) (default=$DEFAULT_IPERF_NUM): "
        read -r IPERF_NUM
        IPERF_NUM=${IPERF_NUM:-$DEFAULT_IPERF_NUM}
        if [ "$IPERF_NUM" -gt 3 ] || [ "$IPERF_NUM" -lt 1 ]; then
            echo "Invalid value"
            exit 0
        fi
        IPERF_WAITS=""
        for (( i=0; i<$IPERF_NUM; i++ )); do
            echo -n "Set start delay for iperf instance #$i (default=${DEFAULT_IPERF_WAIT[$i]}): "
            read -r WAIT_TIME
            WAIT_TIME=${WAIT_TIME:-${DEFAULT_IPERF_WAIT[$i]}}
            IPERF_WAITS+="$WAIT_TIME",
        done
        IPERF_WAITS=$(echo $IPERF_WAITS | sed 's/,$//g')
        WITH_IPERF_PROFILE="--profile with_iperf"
        ;;
    "n"|"N")
        IPERF_ENABLE=n
        WITH_IPERF_PROFILE=""
        ;;
    *)
        echo "Invalid response"
        exit 0
        ;;
esac

echo -n "Link delay [ms] (default=$DEFAULT_DELAY): "
read -r DELAY
DELAY=${DELAY:-$DEFAULT_DELAY}

echo -n "Bandwidth toward client [Mbps] (default=$DEFAULT_BANDWIDTH): "
read -r BANDWIDTH_TO_CLIENT
BANDWIDTH_TO_CLIENT=${BANDWIDTH_TO_CLIENT:-$DEFAULT_BANDWIDTH}

echo -n "Bandwidth toward server [Mbps] (default=$DEFAULT_BANDWIDTH): "
read -r BANDWIDTH_TO_SERVER
BANDWIDTH_TO_SERVER=${BANDWIDTH_TO_SERVER:-$DEFAULT_BANDWIDTH}

echo -n "Packet loss toward client (per thousand, integer) [0-1000] (default=$DEFAULT_LOSS): "
read -r LOSS_TO_CLIENT
LOSS_TO_CLIENT=${LOSS_TO_CLIENT:-$DEFAULT_LOSS}

echo -n "Packet loss toward server (per thousand, integer) [0-1000] (default=$DEFAULT_LOSS): "
read -r LOSS_TO_SERVER
LOSS_TO_SERVER=${LOSS_TO_SERVER:-$DEFAULT_LOSS}

echo -n "Queue type ([f]ifo, [c]odel) (default=$DEFAULT_QUEUE_TYPE): "
read -r QUEUE_TYPE
QUEUE_TYPE=${QUEUE_TYPE:-$DEFAULT_QUEUE_TYPE}
case $QUEUE_TYPE in
    "c"|"C"|"codel")
        QUEUE_TYPE=codel
        echo -n "Set codel queue target [ms] (default=$DEFAULT_CODEL_TARGET): "
        read -r CODEL_TARGET
        CODEL_TARGET=${CODEL_TARGET:-$DEFAULT_CODEL_TARGET}
        echo -n "Set codel queue interval [ms] (default=$DEFAULT_CODEL_INTERVAL): "
        read -r CODEL_INTERVAL
        CODEL_INTERVAL=${CODEL_INTERVAL:-$DEFAULT_CODEL_INTERVAL}
        QUEUE_SCENARIO="--queue_type=codel --codel_target=$CODEL_TARGET --codel_interval=$CODEL_INTERVAL"
        ;;
    "f"|"F"|"fifo")
        QUEUE_TYPE=fifo
        QUEUE_SCENARIO="--queue_type=pfifo"
        ;;
    *)
        echo "Invalid queue type"
        exit 0
        ;;
esac

echo -n "Queue size [packets] (default=$DEFAULT_QUEUE_SIZE): "
read -r QUEUE_SIZE
QUEUE_SIZE=${QUEUE_SIZE:-$DEFAULT_QUEUE_SIZE}
QUEUE_SCENARIO="$QUEUE_SCENARIO --queue_size=$QUEUE_SIZE"

echo -n "File to be transferred size [bytes] (default=$DEFAULT_DIM_FILE): "
read -r DIM_FILE
DIM_FILE=${DIM_FILE:-$DEFAULT_DIM_FILE}
DIM_FILE=$(numfmt --from=auto $DIM_FILE)

echo -n "Enable logging (including qlogs) (y, n): (default=$DEFAULT_LOG_ENABLE): "
read -r LOG_ENABLE
LOG_ENABLE=${LOG_ENABLE:-$DEFAULT_LOG_ENABLE}
case $LOG_ENABLE in
    "y"|"Y")
        LOG_ENABLE=y
        ;;
    "n"|"N")
        LOG_ENABLE=n
        ;;
    *)
        echo "Invalid response"
        exit 0
        ;;
esac

print_summary

echo -n "Do you want to start the testbed? (y, n): "
read -r START
START=${START:-n}

case $START in
    "y"|"Y")
        # Generate a random file to be tranfered (this is needed for some QUIC stacks)
        mkdir -p ./www
        openssl rand -out ./www/sample.txt $DIM_FILE
        SCENARIO="drop-rate --delay=${DELAY}ms --bandwidth_to_client=${BANDWIDTH_TO_CLIENT}Mbps --bandwidth_to_server=${BANDWIDTH_TO_SERVER}Mbps --rate_to_client=${LOSS_TO_CLIENT} --rate_to_server=${LOSS_TO_SERVER} $QUEUE_SCENARIO"
        RES=()
        for impl in "${IMPLEMETATION[@]}"
        do
            echo
            echo "---------------------------------------------"
            echo ">>> Starting test: $impl"
            echo "---------------------------------------------"
            echo

            OUTPUT_FOLDER_NAME="$DELAY"ms_"$BANDWIDTH_TO_CLIENT"Mbps_"$BANDWIDTH_TO_SERVER"Mbps_"$LOSS_TO_CLIENT"loss_"$LOSS_TO_SERVER"loss_"$QUEUE_TYPE"Qtype_"$QUEUE_SIZE"Qsize
            case $IPERF_ENABLE in
                "y")
                    OUTPUT_FOLDER_NAME=${OUTPUT_FOLDER_NAME}_"$IPERF_NUM"x"$IPERF_BAND"crossMbps
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
                IPERF_BAND=$IPERF_BAND IPERF_TYPE=$IPERF_TYPE IPERF_CCA=$IPERF_CCA IPERF_WAITS=$IPERF_WAITS \
                DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $WITH_IPERF_PROFILE build

            monitor_node "server" "$SERVER_OUTPUT_FOLDER/server_cpu_mem.csv" &
            MONITOR_S_PID=$!
            monitor_node "client" "$CLIENT_OUTPUT_FOLDER/client_cpu_mem.csv" &
            MONITOR_C_PID=$!
            echo "Started cpu/mem monitors ($MONITOR_S_PID) ($MONITOR_C_PID)"

            echo "Starting containers"
            CLIENT=$impl SERVER=$impl TESTCASE=$TESTCASE QLOGDIR=$QLOGDIR SSLKEYLOGFILE="/logs/$OUTPUT_FOLDER_NAME/sslkeylogfile" \
                IPERF_BAND=$IPERF_BAND IPERF_TYPE=$IPERF_TYPE IPERF_CCA=$IPERF_CCA IPERF_WAITS=$IPERF_WAITS \
                DIM_FILE=$DIM_FILE SCENARIO=$SCENARIO docker compose $WITH_IPERF_PROFILE up --abort-on-container-exit

            echo "Stopping cpu/mem monitors ($MONITOR_S_PID) ($MONITOR_C_PID)"
            if [ ! -z "$MONITOR_S_PID" ]; then
                pkill -P $MONITOR_S_PID
                MONITOR_S_PID=""

            fi
            if [ ! -z "$MONITOR_C_PID" ]; then
                pkill -P $MONITOR_C_PID
                MONITOR_C_PID=""
            fi

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
