Example of Oracle HTTP Server with Weblogic Proxy Plugin
===============
This Dockerfile extends the Oracle HTTP Install image by creating a sample OHSdomain .
During OHS container creation Oracle WebLogic Server Proxy Plug-In can be configured in order to load balance applications deployed onto either the Weblogic Admin Server, the Managed Servers or the  WebLogic cluster running on docker containers within the same network.

## How to build image and run container
First make sure you have the Oracle HTTP install image (oracle/ohs:12.2.1-sa) ready by running following command as root user
$ docker images

1.To build the OHS domain image using this sample Dockerfile, run command:

      $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

2. Run the below command to create a docker data volume.

       Eg:$ docker volume create --name volume

_This data volume will be created in "/var/lib/docker" directory or the location where "/var/lib/docker" points to._

3. Depending on your Weblogic environment , create a **custom_mod_wl_ohs.conf** file by referring to container-scripts/mod_wl_ohs.conf.sample and section 2.4 @ [OHS 12c Documentation](http://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553)

4. Place the custom_mod_wl_ohs.conf file in docker data volume directory . e.g /var/lib/docker/volume

5. To start the OHS Container with above sampleohs:12.2.1 image , run command  from data volume directory:

       $ cd /var/lib/docker/volume
       $ docker run -v `pwd`:/volume -w /volume -d --name ohs -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh

6. All applications will now be accessible via the OHS port 7777.

######NOTE: If custom_mod_wl_ohs.conf is not provided, then configureWLSProxyPlugin.sh will just start OHS which will be accessible @ http://localhost:7777/index.html.
######Later you can login to running container and configure Weblogic Server proxy plugin file and run restartOHS script.


## Configuring the Oracle WebLogic Server Proxy Plug-In with Oracle HTTP Server

Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs)is used for proxying requests from Oracle HTTP Server to Oracle WebLogic Server.
The Oracle WebLogic Server Proxy Plug-In is included in the Oracle HTTP Server 12c (12.2.1) installation by default.

A sample WebLogic Server Proxy Plug-In file has been provided @ **samples/1221-ohs-domain/container-scripts/mod_wl_ohs.conf.sample**
Refer [OHS 12c Documentation](http://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553) for more details and examples

Depending on the nature of your applications create your own "custom_mod_wl_ohs.conf" file.


### Example with WLS Docker Container

##### Assume you have :

1. WLS Container with Admin Servers running on 7001 port and console accessible via URL
   - http://myhost:7001/console

2. Two WLS Containers with Managed Servers running on 9001 and 9002 ports (inside same weblogic cluster).
   Assume some "sample" application is deployed on the weblogic cluster and are accessible via URLs
   - http://myhost:9001/sample
   - http://myhost:9002/sample

##### To configure Oracle WebLogic Server Proxy Plug-In inside OHS container

1. Create the custom_mod_wl_ohs.conf file by referring to container-scripts/mod_wl_ohs.conf.sample

       For e.g
       LoadModule weblogic_module   "/u01/oracle/ohssa/ohs/modules/mod_wl_ohs.so"
       <IfModule mod_weblogic.c>
       WebLogicHost myhost
       WebLogicPort 7001
       </IfModule>
       #
       # Directive for weblogic admin console deployed on Admin Server
       <Location /console>
       WLSRequest On
       WebLogicHost myhost
       WeblogicPort 7001
       </Location>
       #
       # Directive for all application deployed on weblogic cluster with prepath /weblogic
       <Location /weblogic>
       WLSRequest On
       WebLogicCluster myhost:9001,myhost:9002
       PathTrim /weblogic
       </Location>


2. Place it in docker data volume directory say /var/lib/docker/volume

3. From docker data volume directory run following docker run command

        For e.g
        $ cd /var/lib/docker/volume
        $ docker run -v `pwd`:/volume -w /volume -d --name ohs -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh

   The **configureWLSProxyPlugin.sh** script will be the first script to be run inside the OHS container .
   This script will perform the following actions:
   - Fetch the custom_mod_wl_ohs.conf file from mounted shared data volume
   - Place the custom_mod_wl_ohs.conf file under OHS INSTANCE home
   - Start Node Manager and OHS server

4. Now you will be able to access all the URLS via the OHS Listen Port 7777
    - http://localhost:7777/console
    - http://localhost:7777/weblogic/sample

 _NOTE: If custom_mod_wl_ohs.conf is not provided or not found under mounted shared data volume, then configureWLSProxyPlugin.sh will still start OHS server which will be accessible @ http://localhost:7777/index.html._
 _Later you can login to running container and configure Weblogic Server proxy plugin file and run **restartOHS.sh** script._


# Copyright
Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.