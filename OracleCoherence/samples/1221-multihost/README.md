Oracle Coherence on Multihost Network Docker
==========
This sample demonstrates how to create a cluster of Coherence on a multihost network of Docker containers. To get this up and running, follow these steps:

 1. Install Docker 1.9+ and Docker Machine (as well VirtualBox)
 2. Checkout the **docker-images** repository and go into **OracleCoherence** folder
 3. Build the Docker images for Coherence 12.2.1 Quick Install, and then samples/1221-grid
 4. Go into samples/1221-multihost and run the **bootstrap.sh** script in your host environment
 6. Create a second Coherence Cache Server on a new Docker Machine by running **create-machine.sh**
 7. Create a Coherence Console instance 

Enjoy multihost Coherence on Docker.

# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
