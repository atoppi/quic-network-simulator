FROM rust:1.66 as build


WORKDIR /build

RUN apt-get update && apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules -j8 https://github.com/cloudflare/quiche.git

RUN cargo build --manifest-path quiche/apps/Cargo.toml

##
## quiche-base: quiche image for apps
##
FROM debian:latest as quiche-base

RUN apt-get update && apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build \
     /build/quiche/target/debug/quiche-client \
     /build/quiche/target/debug/quiche-server \
     /usr/local/bin/

ENV PATH="/usr/local/bin/:${PATH}"
ENV RUST_LOG=info

ENTRYPOINT [ "/bin/bash" ]

##
## quiche-qns: quiche image for quic-interop-runner
## https://github.com/marten-seemann/quic-network-simulator
## https://github.com/marten-seemann/quic-interop-runner
##
FROM martenseemann/quic-network-simulator-endpoint:latest as quiche-qns

WORKDIR /quiche

COPY --from=build \
     /build/quiche/target/debug/quiche-client \
     /build/quiche/target/debug/quiche-server \
     /build/quiche/apps/src/bin/cert.crt \
     /build/quiche/apps/src/bin/cert.key \
     ./

ENV RUST_LOG=trace

RUN mkdir /www
RUN mkdir /downloads

COPY start_server.sh .
RUN chmod +x start_server.sh

COPY start_client.sh .
RUN chmod +x start_client.sh

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh

RUN openssl rand -out /www/sample.txt -base64 524288000 ; truncate -s-1 /www/sample.txt

ENTRYPOINT [ "./run_endpoint.sh" ]