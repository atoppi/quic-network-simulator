FROM martenseemann/quic-network-simulator-endpoint:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -y build-essential git cmake software-properties-common \
    openssl libssl-dev pkg-config clang

RUN mkdir /src
WORKDIR /src

RUN git clone https://github.com/private-octopus/picoquic.git

# Perl stuff is for the picotls test code
RUN echo install Test::TCP | perl -MCPAN -
RUN echo install Scope::Guard | perl -MCPAN -

RUN git clone https://github.com/h2o/picotls.git && \
    cd picotls && \
    git submodule init && \
    git submodule update && \
    cmake . && \
    make && \
    make check

RUN cd /src/picoquic && \
    cmake . && \
    make

COPY start_server.sh .
RUN chmod +x start_server.sh

COPY start_client.sh .
RUN chmod +x start_client.sh

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh

ENTRYPOINT [ "./run_endpoint.sh" ]