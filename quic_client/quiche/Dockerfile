FROM rust:1.57 as build

WORKDIR /build

RUN git clone --recursive https://github.com/cloudflare/quiche
WORKDIR quiche

RUN apt-get update && apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/*

RUN cargo build --manifest-path apps/Cargo.toml

## quiche-qns: quiche image
FROM martenseemann/quic-network-simulator-endpoint:latest as quiche

WORKDIR /quiche

RUN apt-get update && apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build \
     /build/quiche/target/debug/quiche-client \
     /build/quiche/target/debug/quiche-server \     
     /build/quiche/apps/src/bin/cert.key \
     /build/quiche/apps/src/bin/cert.crt \
#     /build/quiche/apps/run_endpoint.sh \
     ./

ENV RUST_LOG=trace

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh
ENTRYPOINT [ "./run_endpoint.sh" ]