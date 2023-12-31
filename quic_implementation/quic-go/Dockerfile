FROM martenseemann/quic-network-simulator-endpoint:latest AS builder

ARG TARGETPLATFORM
RUN echo "TARGETPLATFORM: ${TARGETPLATFORM}"

RUN apt-get update && apt-get install -y wget tar git

ENV GOVERSION=1.20.2

RUN platform=$(echo ${TARGETPLATFORM} | tr '/' '-') && \
  filename="go${GOVERSION}.${platform}.tar.gz" && \
  wget https://dl.google.com/go/${filename} && \
  tar xfz ${filename} && \
  rm ${filename}

ENV PATH="/go/bin:${PATH}"

# build with --build-arg CACHEBUST=$(date +%s)
ARG CACHEBUST=1

RUN git clone https://github.com/quic-go/quic-go && \
  cd quic-go && \
  git fetch origin interop && git checkout -t origin/interop && \
  go get ./...

WORKDIR /quic-go

ADD patches patches
RUN git apply patches/*.patch

RUN git rev-parse HEAD > commit.txt
RUN go build -o server -ldflags="-X github.com/quic-go/quic-go/qlog.quicGoVersion=$(git describe --always --long --dirty)" interop/server/main.go
RUN go build -o client -ldflags="-X github.com/quic-go/quic-go/qlog.quicGoVersion=$(git describe --always --long --dirty)" interop/client/main.go

FROM martenseemann/quic-network-simulator-endpoint:latest

WORKDIR /quic-go

COPY --from=builder /quic-go/commit.txt /quic-go/server /quic-go/client ./

COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh

COPY start_server.sh .
RUN chmod +x start_server.sh

COPY start_client.sh .
RUN chmod +x start_client.sh

COPY certs /certs

RUN mkdir /www
RUN mkdir /downloads

ENTRYPOINT [ "./run_endpoint.sh" ]
