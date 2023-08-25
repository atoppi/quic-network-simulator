FROM martenseemann/quic-network-simulator-endpoint:latest
ENV DEBIAN_FRONTEND noninteractive

# Install OpenJDK-17 JRE
RUN apt-get update && \
    apt-get install -y git openjdk-17-jre-headless unzip && \
    apt-get clean;

ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64/
RUN export JAVA_HOME

# Build flupke
RUN git clone https://github.com/ptrd/flupke.git
RUN cd flupke && git submodule update --init --recursive && ./gradlew build && ./gradlew flupkePlugin
RUN cp flupke/build/libs/flupke.jar /
RUN cp flupke/build/libs/flupke-plugin.jar /

# Build kwik
RUN git clone https://github.com/ptrd/kwik.git
WORKDIR /kwik
ADD patches patches
RUN git apply patches/*.patch
RUN git submodule update --init --recursive
RUN ./gradlew build
RUN cp ./build/libs/kwik.jar /
WORKDIR /

COPY certs /certs

RUN mkdir /www

# copy run script and run it
COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh
ENTRYPOINT [ "./run_endpoint.sh" ]
