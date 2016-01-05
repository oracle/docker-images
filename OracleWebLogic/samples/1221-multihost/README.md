Oracle WebLogic on Multihost Network Docker
==========
This sample demonstrates how to create a cluster of WebLogic on a multihost network of Docker containers. To get this up and running, follow these steps:

 1. Install Docker 1.9+ and Docker Machine (as well VirtualBox)
 2. Checkout the **docker-images** repository and go into **OracleWebLogic** folder
 3. Build the Docker images for WebLogic 12.2.1 and 1221-domain
 4. Go into samples/1221-multihost and run the **bootstrap.sh** script in your host environment
 5. Find the IP address of the Docker Machine **weblogic-admin** and go to http://<ip>:8001 to access the Admin Console
 6. Create a Managed Server on a new Docker Machine by running **create-weblogic-machine.sh**
 7. Check the Admin Console to see the new Managed Server
 8. Create as many Managed Servers on the same Docker Machine you want, by calling **create-weblogic-server.sh [machine]**
 9. Check the web console again.

Enjoy multihost WebLogic on Docker.

# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
