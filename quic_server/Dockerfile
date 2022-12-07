FROM martenseemann/quic-network-simulator-endpoint:latest


RUN apt-get update && apt-get install -y apt-transport-https ca-certificates git-core libssl-dev python3-dev python3-pip
RUN pip3 install asgiref dnslib "flask<2.2" httpbin starlette "werkzeug<2.1" wsproto

RUN git clone https://github.com/aiortc/aioquic && cd /aioquic && git checkout 0.9.20
WORKDIR /aioquic
RUN pip3 install -e .

RUN mkdir /www
RUN mkdir /downloads

COPY run_endpoint1.sh .
RUN chmod +x run_endpoint1.sh

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh

ENTRYPOINT [ "./run_endpoint.sh" ]