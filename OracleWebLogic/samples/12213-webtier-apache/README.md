Example of Apache Web Server with WebLogic 12.2.1.3.0 Plugin
=====
This sample shows how to run a load balancer for a WebLogic cluster, from inside a container in the same network as the WebLogic Server cluster.

# How to build image
Download file **Oracle WebLogic Server Proxy Plugins 12.2.1.3** [fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip](http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html) (see .download file)

You may build this image with:

        $ docker build -t 12213-apache .

or

        $ sh build.sh

If you need to set up HTTP/HTTPS proxies, build the image using script build_internal.sh.

        $ sh build_internal.sh

# How to run container
Run this image by calling:

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port --net=<some net> -p 80:80 12213-apache

The values of **WEBLOGIC_CLUSTER** must be valid, existing containers running WebLogic servers.

First make sure you have the WebLogic Server 12.2.1.3 install image, pull the WebLogic install image from the DockerStore store/oracle/weblogic:12.2.1.3, or build your own image oracle/weblogic:12.2.1.3-developer at [https://github.com/oracle/docker-images/tree/master/OracleWebLogic/dockerfiles/12.2.1.3].


## Example
Start a container from the WebLogic install image. You can override the default values of the following parameters during runtime with the -e option:

        ADMIN_NAME (default: AdminServer)
        ADMIN_PORT (default: 7001)
        ADMIN_USERNAME (default: weblogic)
        ADMIN_PASSWORD (default: Auto Generated)
        DOMAIN_NAME (default: base_domain)
        DOMAIN_HOME (default: /u01/oracle/user_projects/domains/base_domain)

NOTE: To set the DOMAIN_NAME, you must set both DOMAIN_NAME and DOMAIN_HOME.

        $ docker run -d -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=welcome1 -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain store/oracle/weblogic:12.2.1.3

Start the webtier container by calling:

        $ docker run -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 7001.

If you are using multihost network, remove --link and set "--net=<your net>".

## Advanced Use Cases
The Docker image supplies a simple Oracle WebLogic iServer Proxy Plugin configuraiton for Apache.

If you want to start the Apache container with some pre-specified mod_weblogic configuration:

* Depending on your weblogic environment , create a custom_mod_wl_apache.conf file by referring to custom_mod_wl_apache.conf.sample and Chapter 3 @ Fusion Middleware Using Oracle WebLogic Server Proxy Plug-Ins documentation.

* Place the custom_mod_wl_apache.conf file in a directory in the host, (for example, "/scratch/DockerVolume/ApacheVolume"),  and then mount this directory into the container at the location "/config". By doing so, the contents of host directory /scratch/DockerVolume/ApacheVolume(and hence custom_mod_wl_apache.conf) will become available in the container at the mount point.

This mounting can be done by using the -v option with the 'docker run' command as shown below. 

        $ docker run -v /scratch/DockerVolume/ApacheVolume:/config -w /config -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

# Copyright
Copyright (c) 2016-2018 Oracle and/or its affiliates. All rights reserved.
