#!/bin/bash

# Set up the routing needed for the simulation
/setup.sh

# The following variables are available for use:
# - ROLE contains the role of this execution context, client or server
# - SERVER_PARAMS contains user-supplied command line parameters
# - CLIENT_PARAMS contains user-supplied command line parameters

if [ "$ROLE" == "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 30
    echo "START QUIC CLIENT"
       sleep 30s
    ./start_client.sh
    
elif [ "$ROLE" == "server" ]; then
    echo "START QUIC SERVER"
    ./start_server.sh
fi

/bin/bash