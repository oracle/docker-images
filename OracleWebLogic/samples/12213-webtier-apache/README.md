Apache Web Server with Oracle WebLogic Server Proxy Plugin on Docker
===============
This project includes a quick start Dockerfile and samples for standalone Apache Web Server with 12.2.1.3.0 Oracle WebLogic Server Proxy Plugin based on Oracle Linux and Oracle JDK 7 (Server). The certification of Apache on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## How to Build Apache With Plugin Docker Image

This project offers a Dockerfile for Apache Web Server with Oraacle WebLogic Server Proxy Plugin in standalone mode. To assist in building the images, you can use `buildDockerImage.sh` script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

IMPORTANT: You have to download the **Oracle WebLogic Server Proxy Plugin 12.2.1.3.0** package (see .download file) and drop them in this directory.

Run `buildDockerImage.sh` script.

        $ sh buildDockerImage.sh 

## How to run container 

Run an Apache container to access an admin server that is running on <host> and listening to <port>.

        $ docker run -d -e WEBLOGIC_HOST=i<host> WEBLOGIC_PORT=<port> -p 80:80 12213-apache

Run an Apache container to access and load balance to a list of managed servers running standalone 
 
        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port --net=<some net> -p 80:80 12213-apache

Run an Apache image to proxy and load balance to a list of managed servers in a cluster
     
        Use a list of hosts and ports.
        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port --net=<some net> -p 80:80 12213-apache

        or use a cluster URL if it is available

        $ docker run -d -e WEBLOGIC_CLUSTER=<cluster-url> --net=<some net> -p 80:80 12213-apache

The values of **WEBLOGIC_CLUSTER** must be valid, existing containers running WebLogic servers.

If you are using multihost network, remove --link and set `--net=<your net>`.

### Admin Server Only Example
 
First make sure you have the WebLogic Server 12.2.1.3 sample and build your own image 12213-domain at [https://github.com/oracle/docker-images/tree/master/OracleWebLogic/samples/12213-domain].

To start a containerized Admin Server, run:

        $ docker run -d --name wlsadmin -h wlsadmin -p 7001:7001 12213-domain

Start an Apache container by calling:

        $ docker run -d --name apache -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 7001. You can access the console from a remote machine using the weblgoic admin server's `<admin-host>` instead of `localhost`.

## Provide Your Own Apache Plugin Configuration
If you want to start the Apache container with some pre-specified mod_weblogic configuration:

* Create a `custom_mod_wl_apache.conf` file by referring to `custom_mod_wl_apache.conf.sample` and Chapter 3 @ Fusion Middleware Using Oracle WebLogic Server Proxy Plug-Ins documentation. [https://docs.oracle.com/middleware/12213/webtier/develop-plugin/apache.htm#GUID-231FB5FD-8D0A-492A-BBFD-DC12A31BF2DE]

* Place the `custom_mod_wl_apache.conf` file in a directory on the host machine (for example,`/scratch/apache-config`) and then mount this directory into the container at the location `/config`. By doing so, the contents of host directory `/scratch/apache-config` (and hence `custom_mod_wl_apache.conf`) will become available in the container at the mount point.

This mounting can be done by using the -v option with the `docker run` command as shown below. 

        $ docker run -v /scratch/apache-config:/config -w /config -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Note: you can also mount the file directly as follows.

        $ docker run -v /scratch/apache-config/custom_mod_wl_apache.conf:/config/custom_mod_wl_apache.conf -w /config -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Once the mounting is done, the custom_mod_wl_apache.conf will replace the built-in version of the file.

## Stopping the Apache instance

To stop the Apache instance, execute the following command:

  docker stop apache (Assuming the name of container is 'apache')

To look at the Docker Container logs run:

    $ docker logs --details <Container-id>


## Support
Oracle HTTP Server on Docker is supported by Oracle.


## License
To download and run Oracle WebLogic Server Proxy Plugins 12.2.1.3.0 Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that p

All scripts and files hosted in this project required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.


