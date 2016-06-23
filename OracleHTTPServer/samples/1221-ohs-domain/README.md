Example of Oracle HTTP Server with Weblogic Proxy Plugin
===============
This Dockerfile extends the Oracle HTTP Install image by creating a sample OHSdomain and configures Oracle WebLogic Server Proxy Plug-In  in order to load balance a WebLogic cluster, from inside a container in the same network as the WLS Cluster.

## How to build image and run container
First make sure you have the Oracle HTTP install image (oracle/ohs:12.2.1-sa) ready by running following command as root user
$ docker images

1.To build the domain image using this sample Dockerfile, run as root user:

    $ docker build --force-rm=true --no-cache=true --rm=true -t sampleohs:12.2.1 --build-arg NM_PASSWORD=welcome1 .

2.To start the Container with above image , run as root user :

    $ docker run -d --env-file ./env.list -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh



## Configuring the Oracle WebLogic Server Proxy Plug-In with Oracle HTTP Server
Oracle WebLogic Server Proxy Plug-In (mod_wl_ohs)is used for proxying requests from Oracle HTTP Server to Oracle WebLogic Server.
The Oracle WebLogic Server Proxy Plug-In is included in the Oracle HTTP Server 12c (12.2.1) installation.
Refer https://docs.oracle.com/middleware/1221/webtier/develop-plugin/oracle.htm#PLGWL553

To configure OHS server with WLS Proxy Plugin, a sample file mod_wl_ohs.conf.sample has been provided under **samples/1221-ohs-domain/container-scripts** folder.
The values for WEBLOGIC_HOST, WEBLOGIC_PORT and WEBLOGIC_CLUSTER will be used from values provided by user during docker run via the env.list

### Example with WLS Docker Container

##### Assume you have :

1. WLS Container with Admin Servers running on 7001 port and console accessible via URL
   - http://myhost:7001/console

2. Two WLS Containers with Managed Servers running on 9001 and 9002 ports (inside same weblogic cluster).
   Sample application is deployed on the cluster and  accessible via URLs
   - http://myhost:9001/sample
   - http://myhost:9002/sample

##### To configure Oracle WebLogic Server Proxy Plug-In inside OHS container

1.Edit the env.list file and provide values

        WEBLOGIC_HOST=myhost
        WEBLOGIC_PORT=7001
        WEBLOGIC_CLUSTER=myhost:9001,myhost:9002

2. As part of docker run command provide the env.file

        $ docker run -d --env-file ./env.list -p 7777:7777  sampleohs:12.2.1 configureWLSProxyPlugin.sh

   The **configureWLSProxyPlugin.sh** script will
   - Start the Node Manager and OHS server
   - Edit the mod_wl_ohs.conf.sample with right directives (based on values passed via env.list)
   - Copy the mod_wl_ohs.conf file under INSTANCE home
   - Restart OHS server

3. Now you will be able to access the URLS via the OHS Listen Port 7777
    - http://myhost:7777/console
    - http://myhost:7777/sample1
    - http://myhost:7777/sample2

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.