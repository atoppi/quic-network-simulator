# Network Simulator for QUIC benchmarking

This project builds a test framework that can be used for benchmarking and
measuring the performance of QUIC implementations under various network
conditions. It uses the [ns-3](https://www.nsnam.org/) network simulator for
simulating network conditions and cross-traffic, and for bridging the real world
with the simulated world. It uses docker for isolating and coercing traffic
between the client and server to flow through the simulated network.

## Framework

The framework uses docker-compose to compose three docker images: the network
simulator (as found in the [sim](sim) directory), and a client and a server (as
found in the individual QUIC implementation directories, or for a simple shell,
the [endpoint](endpoint) directory).

The framework uses two networks on the host machine: `leftnet` (IPv4
193.167.0.0/24, IPv6 fd00:cafe:cafe:0::/64) and `rightnet` (IPv4
193.167.100.0/24, IPv6 fd00:cafe:cafe:100::/64). `leftnet` is connected to the
client docker image, and `rightnet` is connected to the server. The ns-3
simulation sits in the middle and forwards packets between `leftnet` and
`rightnet`.

```
      +-----------------------+
      |      client eth0      |
      |                       |
      |     193.167.0.100     |
      | fd00:cafe:cafe:0::100 |
      +----------+------------+
                 |
                 |
      +----------+------------+
      |     docker-bridge     |
      |                       |
      |      193.167.0.1      |
      |  fd00:cafe:cafe:0::1  |
+-----------------------------------+
|     |         eth0          |     |
|     |                       |     |
|     |      193.167.0.2      |     |
|     |  fd00:cafe:cafe:0::2  |     |
|     +----------+------------+     |
|                |                  |
|                |                  |
|     +----------+------------+     |
|     |         ns3           |     |
|     +----------+------------+     |
|                |                  |
|                |                  |
|     +----------+------------+     |
|     |         eth1          |     |
|     |                       |     |
|     |     193.167.100.2     |     |
|     | fd00:cafe:cafe:100::2 |  sim|
+-----------------------------------+
      |     docker-bridge     |
      |                       |
      |     193.167.100.1     |
      | fd00:cafe:cafe:100::1 |
      +----------+------------+
                 |
                 |
      +----------+------------+
      |      server eth0      |
      |                       |
      |    193.167.100.100    |
      |fd00:cafe:cafe:100::100|
      +-----------------------+
```


## Building your own QUIC docker image

The [endpoint](endpoint) directory contains the base Docker image for an
endpoint Docker container.  The pre-built image of this container is available
on
[dockerhub](https://hub.docker.com/r/martenseemann/quic-network-simulator-endpoint).

Follow these steps to set up your own QUIC implementation:

1. Create a new directory for your implementation (say, my_quic_impl) under `quic_implementation`. You will
   create two files in this directory: `Dockerfile` and `run_endpoint.sh`, as
   described below.

1.  Copy the Dockerfile below and add the commands to build your QUIC
    implementation.

    ```dockerfile
    FROM martenseemann/quic-network-simulator-endpoint:latest

    # download and build your QUIC implementation
    # [ DO WORK HERE ]

    # copy run script and run it
    COPY run_endpoint.sh .
    RUN chmod +x run_endpoint.sh
    ENTRYPOINT [ "./run_endpoint.sh" ]
    ```

1. Now, copy the script below into `run_endpoint.sh`, and add commands as
   instructed. Logs should be recorded in `/logs` for them to be available
   after simulation completion (more on this later).

    ```bash
    #!/bin/bash
    
    # Set up the routing needed for the simulation
    /setup.sh

    # The following variables are available for use:
    # - ROLE contains the role of this execution context, client or server

    if [ "$ROLE" == "client" ]; then
        # Wait for the simulator to start up.
        /wait-for-it.sh sim:57832 -s -t 30
        [ INSERT COMMAND TO RUN YOUR QUIC CLIENT ]
    elif [ "$ROLE" == "server" ]; then
        [ INSERT COMMAND TO RUN YOUR QUIC SERVER ]
    fi
    ```

For an example, have a look at the [quic-go
setup](https://github.com/marten-seemann/quic-go-docker) or the [quicly
setup](https://github.com/h2o/h2o-qns).


## Running a simulation with start.sh script

The `start.sh` script will automate testing of all implementations under `quic_implementation`.
It will ask for all the needed parameters and will start a test with the customized `drop-rate` scenario.

Every test will produce packet captures, qlogs, SSL keylog file and csv files containing metrics under:
`logs/{client|server}/{implementation}/{scenario-folder}`


## Running a Simulation

1. From the quic-network-simulator directory, first build the necessary images:

   ```
   CLIENT=[client directory name] \
   SERVER=[server directory name] \
   docker-compose build
   ```

   Note that you will need to run this build command any time you change the
   client or server implementation, `Dockerfile`, or `run_endpoint.sh` file.

   For instance:

   ```
   CLIENT="my_quic_impl" \
   SERVER="another_quic_impl" \
   docker-compose build
   ```

1. You will want to run the setup with a scenario. The scenarios that are
   currently provided are listed under the [scenarios]sim/scenarios) folder.
   
   The `drop-rate` scenario has been customized to support other settings, namely:

   1. data rate for both directions of the link
   2. kind of queue (FIFO, CoDel)

   You can now run the experiment as follows:
   ```
   CLIENT=[client directory name] \
   SERVER=[server directory name] \
   SCENARIO=[scenario] \
   docker-compose up
   ```

   For instance, the following command runs a simple point-to-point scenario and
   specifies a command line parameter for only the client implementation:

   ```
   CLIENT="my_quic_impl" \
   SERVER="another_quic_impl" \
   SCENARIO="simple-p2p --delay=15ms --bandwidth=10Mbps --queue=25" \
   docker-compose up
   ```

   A mounted directory is provided for recording logs from the endpoints.
   docker-compose creates a `logs/server` and `logs/client` directory from
   the directory from which it is run. Inside the docker container, the
   directory is available as `/logs`.


## Debugging and FAQs

1. With the server (similarly for the client) up and running, you can get a root
   shell in the server docker container using the following:

   ```bash
   docker exec -it server /bin/bash
   ```
2. Before launching the quic-network-simulator, it is necessary to load the ip6table_filter module through the following command:
      ```bash
   sudo modprobe ip6table_filter
   ```
3. Install tshark:
   ```bash
   sudo apt update
   sudo apt install tshark
   ```
4. Install python3.10 or higher:
   ```bash
   sudo apt update
   sudo apt install software-properties-common -y
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt install python3.10
```
