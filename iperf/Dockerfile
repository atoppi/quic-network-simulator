# iperf3 in a container
#
# Run as Server:
# docker run  -it --rm --name=iperf3-srv -p 5201:5201 networkstatic/iperf3 -s
#
# Run as Client (first get server IP address):
# docker inspect --format "{{ .NetworkSettings.IPAddress }}" iperf3-srv
# docker run  -it --rm networkstatic/iperf3 -c <SERVER_IP>
#
FROM martenseemann/quic-network-simulator-endpoint:latest
# install binary and remove cache
RUN apt-get update \
    && apt-get install -y iperf3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Expose the default iperf3 server port
EXPOSE 5201

COPY run_iperf.sh .
RUN chmod +x run_iperf.sh

ENTRYPOINT [ "./run_iperf.sh" ]