Example of Image with WLS Domain
This Dockerfile extends the Oracle HTTP Install image by creating a sample OHSdomain.

How to build and run
First make sure you have the Oracle HTTP insall image (oracle/ohs:12.2.1-sa) ready by running following command as root user
# docker images


1.To build the image using this sample Dockerfile, run as root user:

    #docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

2.To start the Container with above image (Container will have NM and OHS running), run as root user:

   #docker run -d --name ohssa --hostname ohssa -p 7777:7777 sampleohs:12.2.1

3. To login to running container as 'oracle' , run :
docker exec -i -t <cont_id> /bin/bash

4. To login with 'root' user privilege, run :
docker exec -u 0 -i -t <cont_id> /bin/bash

++----------------------------------------------------------------------------------++
Configuring the Oracle WebLogic Server Proxy Plug-In with Oracle HTTP Server
++----------------------------------------------------------------------------------++
Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs)is used for proxying requests from Oracle HTTP Server to Oracle WebLogic Server.
The Oracle WebLogic Server Proxy Plug-In is included in the Oracle HTTP Server 12c (12.2.1) installation. Refer https://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553,

To test the sample OHS server with WLS Proxy Plugin, a sample file mod_wl_ohs.conf.sample has been provided under /container-scripts folder for reference.

The mod_wl_ohs.conf.sample file assumes that
a) WLS Admin Servers is running and accessible @ http://myhost:8001/console
b) An application called chat is deployed on a cluster which has 2 WLS Managed server running under it and is accessible @ http://myhost:7001/chat and http://myhost:7004/chat

How to configure on OHS container :
1. Build your docker image and run docker contianer using sample file under samples/1221-OHS-domain
2. Login to the running OHS docker container by executing
# docker exec -i -t <container_id> /bin/bash

**container_id can be found by running command docker ps -a (as root user)

3. Navigate to /u01/oracle/container-scripts folder and edit the mod_wl_ohs.conf.sample file with correct directives . Refer section 2.4 in Oracle docs provided above
4. Run the script configureWLSProxyPlugin.sh . This will also restart the OHS server

Now you will be able to access all URLS via the OHS Listen Port 7777
http://myhost:7777/console
http://myhost:7777/consolehelp
http://myhost:7777/chat
