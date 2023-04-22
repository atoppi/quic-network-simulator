FROM debian:11 as build

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git g++ clang-11 make binutils autoconf automake autotools-dev libtool \
        pkg-config libev-dev libjemalloc-dev \
        ca-certificates mime-support && \
    git clone --depth 1 -b OpenSSL_1_1_1s+quic https://github.com/quictls/openssl && \
    cd openssl && ./config --openssldir=/etc/ssl && make -j$(nproc) && make install_sw && cd .. && rm -rf openssl && \
    git clone --depth 1 https://github.com/ngtcp2/nghttp3 && \
    cd nghttp3 && autoreconf -i && \
    ./configure --enable-lib-only CC=clang-11 CXX=clang++-11 && \
    make -j$(nproc) && make install-strip && cd .. && rm -rf nghttp3 && \
    git clone --depth 1 https://github.com/ngtcp2/ngtcp2 && \
    cd ngtcp2 && autoreconf -i && \
    ./configure \
        CC=clang-11 \
        CXX=clang++-11 \
        LIBTOOL_LDFLAGS="-static-libtool-libs" \
        OPENSSL_LIBS="-l:libssl.a -l:libcrypto.a -ldl -pthread" \
        LIBEV_LIBS="-l:libev.a" \
        JEMALLOC_LIBS="-l:libjemalloc.a -lm" && \
    make -j$(nproc) && \
    strip examples/client examples/server && \
    cp examples/client examples/server /usr/local/bin && \
    cd .. && rm -rf ngtcp2 && \
    apt-get -y purge \
        git g++ clang-11 make binutils autoconf automake autotools-dev libtool \
        pkg-config libev-dev libjemalloc-dev \
        ca-certificates && \
    apt-get -y autoremove --purge && \
    rm -rf /var/log/*
    
FROM martenseemann/quic-network-simulator-endpoint:latest

WORKDIR /ngtcp2

COPY --from=build /usr/local/bin/client /usr/local/bin/server /ngtcp2/
COPY --from=build /etc/mime.types /etc/

RUN openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 \
    -subj "/C=IT/ST=Italy/L=Italy/O=Unina/OU=../CN=.." \
    -keyout key_client.pem -out cert_client.pem

RUN mkdir /www
RUN mkdir /downloads

COPY start_server.sh .
RUN chmod +x start_server.sh

COPY start_client.sh .
RUN chmod +x start_client.sh

COPY cert.crt .
COPY cert.key .

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh
ENTRYPOINT [ "./run_endpoint.sh" ]