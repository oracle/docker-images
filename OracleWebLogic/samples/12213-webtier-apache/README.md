Example of Apache Web Server with WebLogic 12.2.1.3.0 Plugin
=====
This sample shows how to run a load balancer for a WebLogic cluster, from inside a container in the same network as the WLS Cluster.

# How to build image
Download file **Oracle WebLogic Server Proxy Plugins 12.2.1** [fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip](http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html) (see .download file)

You may build this image with:

        $ docker build -t 12213-apache .

or
        $ sh build.sh

For Oracle developers, use build_internal.sh, which set up HTTP/HTTPS proxies.
        $ sh build_internal.sh

# How to run container
Run this image by calling:

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port --net=<some net> -p 80:80 12213-apache

The values of **WEBLOGIC_CLUSTER** must be valid, existing containers running WebLogic servers.

## Example
Start an AdminServer from the **12213-domain** sample by calling:

        $ docker run -d --name wlsadmin -h wlsadmin 12213-domain

Start the webtier container by calling:

        $ docker run -d --link wlsadmin:wlsadmin -e WEBLOGIC_HOST=wlsadmin -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 7001.

TODO (Dongbo): add an exmaple to deploy a webapp and access it 

If you are using multihost network, remove --link and set --net=<your net>

# Copyright
Copyright (c) 2016-2018 Oracle and/or its affiliates. All rights reserved.
