Example of Apache Web Server with WebLogic Plugin
=====
This sample shows how to run a load balancer for a WebLogic cluster, from inside a container in the same network as the WLS Cluster.

# How to build image
Download file **Oracle WebLogic Server Proxy Plugins 12.2.1** [fmw_12.2.1.0.0_wlsplugins_Disk1_1of1.zip](http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html) and extract the ZIP file **WLSPlugin12.2.1-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.0.0.zip** into this same folder.

You may build this image with:

        $ docker build -t webtier .

# How to run container
Run this image by calling:

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port --net=<some net> -p 80:80 webtier

The values of **WEBLOGIC_CLUSTER** must be valid, existing containers running WebLogic servers.

## Example
Start an AdminServer from the **1221-domain** sample by calling:

        $ docker run -d --name wlsadmin -h wlsadmin 1221-domain

Start the webtier container by calling:

        $ docker run -d --link wlsadmin:wlsadmin -e WEBLOGIC_CLUSTER=wlsadmin:8001 -p 80:80 webtier

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 8001.

If you are using multihost network, remove --link and set --net=<your net>
