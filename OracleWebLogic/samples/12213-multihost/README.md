# WebLogic-Swarm-Mode
This is an example of setting up a WebLogic Multi Host Cluster running in Docker Swarm Mode. 
It requires a minimum of three hosts: 
  one host is running WebLogic Admin Server, 
  two hosts are running WebLogic Managed Servers.
All serving the same sample application.
All three hosts must be able to talk to each other through some network.
To setup this cluster:
1.  Install Docker 17.03+
2.  Build the Docker Image for oracle/serverjre:8 \
    (https://github.com/oracle/docker-images/tree/master/OracleJava/java-8)
3.  Build the WebLogic Docker Image using this repository (see build.sh)
4.  Push this image to a Docker Registry that is available to all three hosts
5.  Initialize swarm mode on one of the hosts: \
    docker swarm init --advertise-addr \<ip-address\>
6.  Join the swarm worker nodes on the two other hosts using the output of the above command.
    "docker node ls" should show all three nodes as Ready and Active
7.  Create overlay network:\
    docker network create --driver overlay wls-network
8.  Create a Docker service for the Admin Server:\
    docker service create --name wlsadmin --publish 7001:7001 \\\
    --network wls-network \<docker-registry\>/oracle/weblogic:12.2.1.3-developer
9.  Create a Docker service for the Managed Servers. This will create two managed servers (replicas 2) using the createServer.sh from the Image:\
    docker service create --name wlsms --publish 7001:7001 --network wls-network --replicas 2 \\\
           -e ADMIN_PASSWORD=welcome1 \<docker-registry\>/oracle/weblogic:12.2.1.3-developer createServer.sh
10. Create a LoadBalancer Image using the http-server with WebLogic plugin from \
    https://github.com/oracle/docker-images/tree/master/OracleWebLogic/samples/1221-webtier-apache
11. Publish this image to the same registry as the WebLogic docker images    
11. Create another Docker service from this image using:\
    docker service create --name webtier --publish 80:80 --network wls-network \\\
    -e WEBLOGIC_CLUSTER=wlsms:7002 \<docker-registry\>/1221-webtier
12. That's it. Docker Swarm Mode creates routing rules to access the services through the published ports. 
    Those rules usually don't allow localhost access!
