Oracle WebLogic on Multihost Network Docker
==========
This sample demonstrates how to create a cluster of WebLogic on a multihost network of Docker containers. To get this up and running, follow these steps:

 1. Install Docker 1.9+ and Docker Machine (as well VirtualBox)
 2. Checkout the `docker-images` repository and go into `OracleWebLogic` folder
 3. Build the Docker images for WebLogic 12.2.1 Developer distribution, and then `samples/1221-domain`
 4. Go into samples/1221-multihost and run the `bootstrap.sh` script in your host environment
 5. Find the IP address of the Docker Machine `weblogic-master` and go to http://<ip>:8001 to access the Admin Console
 6. Create a new Docker Machine to participate in the Swarm, by running `create-machine.sh`
 7. Create a new containerized WebLogic Managed Server to join the WebLogic domain of the Swarm above, by running `create-container.sh`
 8. Check the Admin Console to see the new Managed Server
 9. Create as many Managed Servers on the same Docker Machine as you want, by calling `create-container.sh [docker machine]`
 10. Check the web console again.

Enjoy multihost WebLogic on Docker.

# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
