FROM martenseemann/quic-network-simulator-endpoint:latest

ADD patches patches

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git gcc clang-12 make binutils autoconf automake autotools-dev libtool \
    pkg-config libev-dev libjemalloc-dev \
    libev4 libjemalloc2 ca-certificates mime-support \
    llvm-12 libasan5 libubsan1

RUN git clone --depth 1 -b OpenSSL_1_1_1v+quic https://github.com/quictls/openssl && \
    cd openssl && ./config --openssldir=/etc/ssl && make -j$(nproc) && make install_sw && cd .. && rm -rf openssl

RUN git clone --depth 1 https://github.com/ngtcp2/nghttp3 && \
    cd nghttp3 && autoreconf -i && \
    ./configure --enable-lib-only CC=clang-12 CXX=clang++-12 && \
    make -j$(nproc) && make install && cd .. && rm -rf nghttp3

ARG GITURL="https://github.com/ngtcp2/ngtcp2"
ARG GITREF="main"
RUN git clone ${GITURL} && \
    cd ngtcp2 && git checkout ${GITREF} && git apply ../patches/*.patch && autoreconf -i && \
    ./configure CC=clang-12 CXX=clang++-12 && \
    make -j$(nproc) && make install && \
    cp examples/qtlsserver examples/qtlsclient examples/h09qtlsserver examples/h09qtlsclient /usr/local/bin && \
    cd .. && \
    rm -rf ngtcp2 && \
    rm -rf /usr/local/lib/libssl.so /usr/local/lib/libcrypto.so /usr/local/lib/libssl.a /usr/local/lib/libcrypto.a /usr/local/lib/pkgconfig/*ssl.pc /usr/local/include/openssl/*

RUN apt-get -y purge git g++ clang-12 make binutils autoconf automake \
    autotools-dev libtool pkg-config \
    libev-dev libjemalloc-dev && \
    apt-get -y autoremove --purge && \
    rm -rf /var/log/*

RUN mkdir /ngtcp2
RUN cp /usr/local/bin/qtlsserver /usr/local/bin/qtlsclient /usr/local/bin/h09qtlsserver /usr/local/bin/h09qtlsclient /ngtcp2/

WORKDIR /ngtcp2

RUN openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 \
    -subj "/C=IT/ST=Italy/L=Italy/O=Unina/OU=../CN=.." \
    -keyout key_client.pem -out cert_client.pem

COPY start_server.sh .
RUN chmod +x start_server.sh

COPY start_client.sh .
RUN chmod +x start_client.sh

COPY certs /certs

RUN mkdir /www

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh

ENTRYPOINT [ "./run_endpoint.sh" ]
