FROM martenseemann/quic-network-simulator-endpoint:latest

# install binary and remove cache
RUN apt-get update \
    && apt-get install -y iperf3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY run_iperf.sh .
RUN chmod +x run_iperf.sh

ENTRYPOINT [ "./run_iperf.sh" ]
