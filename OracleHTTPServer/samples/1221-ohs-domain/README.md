Example of Image with WLS Domain
===============
This Dockerfile extends the Oracle HTTP Install image by creating a sample OHSdomain.

## How to build and run
First make sure you have the Oracle HTTP install image (oracle/ohs:12.2.1-sa) ready by running following command as root user
$ docker images


1.To build the domain image using this sample Dockerfile, run as root user:

    $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

2.To start the Container with above image (Container will have NM and OHS running), run as root user:

        $ docker run -d --name ohssa --hostname ohssa -p 7777:7777 sampleohs:12.2.1

3. To login to running container as 'oracle' , run :

        $ docker exec -i -t <container_id> /bin/bash

4. To login with 'root' user privilege, run :

        $ docker exec -u 0 -i -t <container_id> /bin/bash

    ** container_id can be found by running command $ docker ps -a



## Configuring the Oracle WebLogic Server Proxy Plug-In with Oracle HTTP Server
Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs)is used for proxying requests from Oracle HTTP Server to Oracle WebLogic Server.
The Oracle WebLogic Server Proxy Plug-In is included in the Oracle HTTP Server 12c (12.2.1) installation.
Refer https://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553

To configure OHS server with WLS Proxy Plugin, a sample file mod_wl_ohs.conf.sample has been provided under **samples/1221-ohs-domain/container-scripts** folder for reference.

### How to configure on OHS container :
1. Build your docker image and run docker container using sample Dockerfile under samples/1221-OHS-domain
2. Login to the running OHS docker container by executing

        $ docker exec -i -t <container_id> /bin/bash

**container_id can be found by running command docker ps -a (as root user)

3. Navigate to /u01/oracle/container-scripts folder and edit the mod_wl_ohs.conf.sample file with correct directives . Refer section 2.4 in Oracle docs provided above
4. Run the script configureWLSProxyPlugin.sh . This will also restart the OHS server
5. Now you will be able to access all URLS via the OHS Listen Port 7777


### Example with WLS Docker Container

##### Assume you have :

1. WLS Container with Admin Servers running on 8001 port and console accessible @ http://myhost:8001/console
2. Two WLS Containers with Managed Servers running on 7001 and 7001 ports (inside same docker-cluster). An application called chat is deployed on the cluster and  accessible via
   http://myhost:7001/chat
   and
   http://myhost:7004/chat

##### To configure on OHS container :

1. Login to the running OHS docker container by executing

        $ docker exec -i -t <container_id> /bin/bash

2. Navigate to /u01/oracle/container-scripts folder and edit the mod_wl_ohs.conf.sample file with correct directives . Sample below

   ```
   LoadModule weblogic_module   "/u01/oracle/ohssa/ohs/modules/mod_wl_ohs.so"
   <IfModule mod_weblogic.c>
     WebLogicHost **myhost**
     WebLogicPort **8001**
   </IfModule>

   #Admin Server Console
   <Location /console>
     SetHandler weblogic-handler
     WebLogicHost **myhost**
     WeblogicPort **8001**
   </Location>

   #Chat Application deployed on cluster
   <Location /chat>
     SetHandler weblogic-handler
     WebLogicCluster **myhost:7001,myhost:7004**
   </Location>
   ```


3. Run the script configureWLSProxyPlugin.sh . This will also restart the OHS server

4. Now you will be able to access the URLS via the OHS Listen Port 7777
    - http://myhost:7777/console
    - http://myhost:7777/chat
